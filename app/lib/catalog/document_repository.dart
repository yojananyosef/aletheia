/// Repositorio de documentos del catálogo.
///
/// Interfaz única que consumen los paneles del lector; hay dos fuentes:
/// - [AssetDocumentRepository]: recursos empaquetados en la app (M1).
/// - [RemoteDocumentRepository]: servicio `catalog/` (M2, contrato v1).
///
/// [FallbackDocumentRepository] combina ambas según el modo de los ajustes
/// («auto»: servicio si está disponible; «local»: solo assets; «remoto»:
/// los errores del servicio se propagan).
library;

import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show AssetBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'catalog_asset_source.dart';
import 'catalog_client.dart';
import 'catalog_gateway.dart';
import 'document_models.dart';

abstract class DocumentRepository {
  Future<DocumentManifest> loadManifest(String resourceId);

  Future<BookDocument> loadBook(String resourceId, String bookCode);
}

/// Recursos del catálogo leídos de una fuente (assets o `aletheia-mods`).
class AssetDocumentRepository implements DocumentRepository {
  AssetDocumentRepository({AssetBundle? bundle, CatalogAssetSource? source})
    : _source = source ?? AssetCatalogSource(bundle: bundle);

  final CatalogAssetSource _source;
  final Map<String, DocumentManifest> _manifestCache = {};
  final Map<String, BookDocument> _bookCache = {};

  /// `bible.rv1909` → `rv1909`.
  /// Directorio de assets del recurso. Los recursos de M5 (`devotional.daily`,
  /// `factbook.core`) usan el id completo porque su último segmento («daily»,
  /// «core») no identifica al recurso.
  static const _dirOverrides = {
    'devotional.daily': 'devotional.daily',
    'factbook.core': 'factbook.core',
    'lexicon.strongs': 'lexicon.strongs',
  };

  static String dirFor(String resourceId) {
    final override = _dirOverrides[resourceId];
    if (override != null) return override;
    return resourceId.contains('.') ? resourceId.split('.').last : resourceId;
  }

  @override
  Future<DocumentManifest> loadManifest(String resourceId) async {
    final cached = _manifestCache[resourceId];
    if (cached != null) return cached;
    final raw = await _source.loadText(
      'assets/catalog/${dirFor(resourceId)}/manifest.json',
    );
    final manifest = DocumentManifest.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    _manifestCache[resourceId] = manifest;
    return manifest;
  }

  @override
  Future<BookDocument> loadBook(String resourceId, String bookCode) async {
    final key = '$resourceId/$bookCode';
    final cached = _bookCache[key];
    if (cached != null) return cached;
    final raw = await _source.loadText(
      'assets/catalog/${dirFor(resourceId)}/books/$bookCode.json.gz',
    );
    final book = BookDocument.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    _bookCache[key] = book;
    return book;
  }
}

/// Servicio de catálogo (`catalog/`).
class RemoteDocumentRepository implements DocumentRepository {
  RemoteDocumentRepository(this._client);

  final CatalogClient _client;

  @override
  Future<DocumentManifest> loadManifest(String resourceId) async =>
      DocumentManifest.fromJson(await _client.fetchManifestJson(resourceId));

  @override
  Future<BookDocument> loadBook(String resourceId, String bookCode) async =>
      BookDocument.fromJson(await _client.fetchBookJson(resourceId, bookCode));
}

/// Intenta el servicio y, si falla, usa los recursos locales (modo «auto»).
class FallbackDocumentRepository implements DocumentRepository {
  FallbackDocumentRepository({required this.remote, required this.local});

  final DocumentRepository remote;
  final DocumentRepository local;

  @override
  Future<DocumentManifest> loadManifest(String resourceId) =>
      _withFallback((repository) => repository.loadManifest(resourceId));

  @override
  Future<BookDocument> loadBook(String resourceId, String bookCode) =>
      _withFallback((repository) => repository.loadBook(resourceId, bookCode));

  Future<T> _withFallback<T>(
    Future<T> Function(DocumentRepository repository) call,
  ) async {
    try {
      return await call(remote);
    } on Exception catch (error) {
      debugPrint(
        'catálogo remoto no disponible ($error); uso recursos locales',
      );
      return call(local);
    }
  }
}

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  final gateway = ref.watch(catalogGatewayProvider);
  final local = AssetDocumentRepository(source: gateway.source);
  if (gateway.localOnly) return local;
  final remote = RemoteDocumentRepository(gateway.client);
  if (gateway.mode == 'remote') return remote;
  return FallbackDocumentRepository(remote: remote, local: local);
});

final manifestProvider = FutureProvider.family<DocumentManifest, String>(
  (ref, resourceId) =>
      ref.watch(documentRepositoryProvider).loadManifest(resourceId),
);

final bookDocumentProvider =
    FutureProvider.family<BookDocument, (String resourceId, String code)>(
      (ref, key) =>
          ref.watch(documentRepositoryProvider).loadBook(key.$1, key.$2),
    );
