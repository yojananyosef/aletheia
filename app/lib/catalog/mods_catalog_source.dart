/// Cliente del catálogo estático publicado en `aletheia-mods`.
///
/// GitHub Pages sirve los archivos con CORS y `Accept-Ranges`, así que la app
/// web puede descargar un recurso o el índice FTS5 directamente. El service
/// worker de `web/sw.js` se encarga de cachear las respuestas entre sesiones;
/// este cliente solo informa del progreso y permite cancelar.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show ValueNotifier, debugPrint;
import 'package:http/http.dart' as http;

import 'catalog_asset_source.dart';
import 'catalog_client.dart' show CatalogException;
import 'gzip_platform.dart';

/// URL del catálogo desacoplado.
///
/// Se puede cambiar en tiempo de compilación con
/// `--dart-define=ALETHEIA_MODS_URL=...` para probar una copia local.
const kDefaultModsBaseUrl = String.fromEnvironment(
  'ALETHEIA_MODS_URL',
  defaultValue: 'https://yojananyosef.github.io/aletheia-mods/v1',
);

/// Progreso de una transferencia del catálogo.
class CatalogTransfer {
  const CatalogTransfer({
    required this.received,
    this.total,
    this.cancelling = false,
  });

  final int received;
  final int? total;
  final bool cancelling;

  double? get fraction {
    final max = total;
    if (max == null || max <= 0) return null;
    return (received / max).clamp(0, 1);
  }

  CatalogTransfer copyWith({int? received, int? total, bool? cancelling}) =>
      CatalogTransfer(
        received: received ?? this.received,
        total: total ?? this.total,
        cancelling: cancelling ?? this.cancelling,
      );
}

/// Fuente HTTP del catálogo desacoplado.
class ModsCatalogSource implements CatalogAssetSource {
  ModsCatalogSource({String baseUrl = kDefaultModsBaseUrl, http.Client? client})
    : _baseUrl = _normalize(baseUrl),
      _client = client ?? http.Client() {
    // La versión se usa para invalidar la caché cuando cambia el catálogo.
    // No bloquea las primeras lecturas si el manifiesto tarda en llegar.
    unawaited(_loadVersion());
  }

  final String _baseUrl;
  final ValueNotifier<CatalogTransfer?> transfer = ValueNotifier(null);
  http.Client _client;
  String? _version;
  Future<void>? _versionLoading;
  bool _cancelRequested = false;
  bool _disposed = false;

  static String _normalize(String value) {
    var url = value.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  /// `assets/catalog/rv1909/books/GEN.json.gz` → `rv1909/books/GEN.json.gz`.
  static String _relative(String path) {
    const prefix = 'assets/catalog/';
    return path.startsWith(prefix) ? path.substring(prefix.length) : path;
  }

  Future<void> _loadVersion() {
    final existing = _versionLoading;
    if (existing != null) return existing;
    return _versionLoading = () async {
      try {
        final response = await _client
            .get(Uri.parse('$_baseUrl/mods.json'))
            .timeout(const Duration(seconds: 4));
        if (response.statusCode != 200) return;
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        if (json is Map && json['version'] is String) {
          _version = json['version'] as String;
        }
      } on Object catch (error) {
        debugPrint('no se pudo leer la versión de aletheia-mods: $error');
      }
    }();
  }

  Uri _uri(String path) {
    final uri = Uri.parse('$_baseUrl/${_relative(path)}');
    final version = _version;
    if (version == null || version.isEmpty) return uri;
    return uri.replace(queryParameters: {...uri.queryParameters, 'v': version});
  }

  @override
  Future<String> loadText(String path) async {
    await _loadVersion();
    final bytes = await _download(_uri(path), progress: false);
    final data = path.endsWith('.gz') ? await decompressGzip(bytes) : bytes;
    return utf8.decode(data);
  }

  @override
  Future<Uint8List> loadBytes(String path) async {
    await _loadVersion();
    return _download(_uri(path), progress: true);
  }

  Future<Uint8List> _download(Uri uri, {required bool progress}) async {
    _cancelRequested = false;
    _setTransfer(progress ? const CatalogTransfer(received: 0) : null);
    final request = http.Request('GET', uri)..headers['Accept'] = '*/*';
    try {
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        if (response.statusCode == 404) {
          throw CatalogException('no encontrado: $uri', status: 404);
        }
        throw CatalogException(
          'no se pudo descargar el catálogo (HTTP ${response.statusCode})',
          status: response.statusCode,
        );
      }
      final total = response.contentLength;
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response.stream) {
        if (_cancelRequested) throw const CatalogDownloadCancelled();
        builder.add(chunk);
        if (progress) {
          _setTransfer(
            CatalogTransfer(
              received: builder.length,
              total: total != null && total > 0 ? total : null,
            ),
          );
        }
      }
      if (_cancelRequested) throw const CatalogDownloadCancelled();
      return builder.takeBytes();
    } on CatalogDownloadCancelled {
      rethrow;
    } on CatalogException {
      rethrow;
    } on http.ClientException catch (error) {
      if (_cancelRequested) throw const CatalogDownloadCancelled();
      throw CatalogException(
        'no se pudo conectar con aletheia-mods: ${error.message}',
      );
    } on TimeoutException {
      throw CatalogException('tiempo de espera agotado al descargar $uri');
    } finally {
      if (progress) _setTransfer(null);
    }
  }

  void _setTransfer(CatalogTransfer? value) {
    if (!_disposed) transfer.value = value;
  }

  /// Cancela la transferencia en curso. La siguiente búsqueda puede reintentar.
  void cancelTransfer() {
    if (_cancelRequested || _disposed) return;
    _cancelRequested = true;
    _client.close();
    _client = http.Client();
    _setTransfer(null);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _cancelRequested = true;
    transfer.dispose();
    _client.close();
  }
}
