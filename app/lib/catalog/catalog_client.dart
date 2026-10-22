/// Cliente HTTP del servicio de catálogo (contrato v1).
///
/// Usa `package:http`, compatible con escritorio y web. Lanza
/// [CatalogException] en cualquier respuesta no-2xx o error de red (los
/// llamadores deciden el respaldo local).
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'catalog_models.dart';

class CatalogException implements Exception {
  const CatalogException(this.message, {this.status});

  final String message;
  final int? status;

  @override
  String toString() => status == null
      ? 'CatalogException: $message'
      : 'CatalogException($status): $message';
}

class CatalogClient {
  CatalogClient({required String baseUrl, http.Client? httpClient})
    : baseUrl = normalizeBaseUrl(baseUrl),
      _http = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _http;

  static String normalizeBaseUrl(String url) {
    var value = url.trim();
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

  void close() => _http.close();

  /// Comprueba el servicio; devuelve `null` si no está disponible.
  Future<CatalogHealth?> health() async {
    try {
      final json = await _getJson(
        '/v1/health',
        timeout: const Duration(seconds: 2),
      );
      return CatalogHealth(
        resources: json['resources'] as int? ?? 0,
        verses: json['verses'] as int? ?? 0,
        sections: json['sections'] as int? ?? 0,
        crossReferences: json['crossReferences'] as int? ?? 0,
      );
    } on Exception {
      return null;
    }
  }

  Future<ResourceListing> listResources({
    String query = '',
    String? type,
    String? language,
    String? author,
    String sort = 'title',
    int page = 1,
    int pageSize = 50,
  }) async {
    final params = <String, String>{
      'sort': sort,
      'page': '$page',
      'pageSize': '$pageSize',
      if (query.trim().isNotEmpty) 'query': query.trim(),
      'type': ?type,
      'language': ?language,
      'author': ?author,
    };
    final json = await _getJson(
      '/v1/resources?${Uri(queryParameters: params).query}',
    );
    return ResourceListing.fromJson(json);
  }

  Future<SearchResult> search({
    required String query,
    String scope = 'all',
    String? resource,
    String? type,
    String? language,
    String? book,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = {
      'q': query,
      'scope': scope,
      if (resource != null && resource.isNotEmpty) 'resource': resource,
      if (type != null && type.isNotEmpty) 'type': type,
      if (language != null && language.isNotEmpty) 'language': language,
      if (book != null && book.isNotEmpty) 'book': book,
      'page': '$page',
      'pageSize': '$pageSize',
    };
    final json = await _getJson(
      '/v1/search?${Uri(queryParameters: params).query}',
    );
    return SearchResult.fromJson(json);
  }

  Future<Map<String, dynamic>> fetchManifestJson(String resourceId) =>
      _getJson('/v1/resources/$resourceId');

  Future<Map<String, dynamic>> fetchBookJson(String resourceId, String code) =>
      _getJson('/v1/resources/$resourceId/books/$code');

  /// Índice de secciones (metadatos, sin bloques).
  Future<Map<String, dynamic>> fetchSectionsJson(
    String resourceId, {
    int from = 0,
    int limit = 200,
  }) => _getJson('/v1/resources/$resourceId/sections?from=$from&limit=$limit');

  Future<Map<String, dynamic>> fetchSectionJson(
    String resourceId,
    String sectionId,
  ) => _getJson('/v1/resources/$resourceId/sections/$sectionId');

  Future<List<CrossReference>> fetchCrossReferences(
    String reference, {
    int limit = 40,
  }) async {
    final encoded = Uri.encodeQueryComponent(reference);
    final json = await _getJson(
      '/v1/cross-references?ref=$encoded&limit=$limit',
    );
    final items = (json['items'] as List?) ?? const [];
    return items
        .map((e) => CrossReference.fromJson(e as Map<String, dynamic>))
        .where((e) => e.reference.isNotEmpty)
        .toList();
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final response = await _http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(timeout);
      final body = utf8.decode(response.bodyBytes, allowMalformed: true);
      if (response.statusCode != 200) {
        throw CatalogException(
          _errorMessage(body, response.statusCode),
          status: response.statusCode,
        );
      }
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw CatalogException('respuesta inesperada de $path');
      }
      return decoded;
    } on CatalogException {
      rethrow;
    } on http.ClientException catch (error) {
      throw CatalogException(
        'no se pudo conectar con el catálogo en $baseUrl (${error.message})',
      );
    } on TimeoutException {
      throw CatalogException(
        'tiempo de espera agotado al conectar con $baseUrl',
      );
    } on FormatException catch (error) {
      throw CatalogException(
        'respuesta no válida del catálogo: ${error.message}',
      );
    }
  }

  static String _errorMessage(String body, int status) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {
      // cuerpo no-JSON: se usa el código
    }
    return 'HTTP $status';
  }
}

class CatalogHealth {
  const CatalogHealth({
    required this.resources,
    required this.verses,
    this.sections = 0,
    this.crossReferences = 0,
    this.local = false,
  });

  final int resources;
  final int verses;

  /// Entradas no bíblicas indexadas (Factbook, devocional, comentario y
  /// diccionario).
  final int sections;

  /// Enlaces de referencias cruzadas disponibles en el índice.
  final int crossReferences;

  /// `true` cuando el estado viene del índice incluido en la app, no del
  /// servicio HTTP.
  final bool local;
}
