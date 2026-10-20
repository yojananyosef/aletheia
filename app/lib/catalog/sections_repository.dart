/// Repositorio de secciones del catálogo: devocional, Factbook, comentario y
/// diccionario.
///
/// Los recursos pequeños traen las secciones embebidas en `sections.json`;
/// los grandes (comentario y diccionario) guardan un índice de metadatos y el
/// cuerpo en `sections/<id>.json`, que se carga solo al abrir una entrada. El
/// formato es el mismo que sirve el servicio (ver
/// `docs/spec/03-contrato-catalogo.md`).
library;

import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'asset_json.dart';
import 'catalog_client.dart';
import 'catalog_gateway.dart';
import 'document_models.dart';
import 'document_repository.dart';

abstract class SectionsRepository {
  Future<List<SectionSummary>> loadIndex(String resourceId);

  Future<CatalogSection?> loadSection(String resourceId, String sectionId);
}

/// Secciones incluidas como assets (`assets/catalog/<dir>/sections.json`).
class AssetSectionsRepository implements SectionsRepository {
  AssetSectionsRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final Map<String, List<Map<String, dynamic>>> _raw = {};
  final Map<String, CatalogSection?> _sections = {};

  Future<List<Map<String, dynamic>>> _entries(String resourceId) async {
    final cached = _raw[resourceId];
    if (cached != null) return cached;
    final dir = AssetDocumentRepository.dirFor(resourceId);
    final text = await loadCatalogAssetText(
      _bundle,
      'assets/catalog/$dir/sections.json',
    );
    final list = (jsonDecode(text) as List).cast<Map<String, dynamic>>();
    _raw[resourceId] = list;
    return list;
  }

  @override
  Future<List<SectionSummary>> loadIndex(String resourceId) async => [
        for (final entry in await _entries(resourceId))
          SectionSummary.fromJson(entry),
      ];

  @override
  Future<CatalogSection?> loadSection(
    String resourceId,
    String sectionId,
  ) async {
    final key = '$resourceId/$sectionId';
    if (_sections.containsKey(key)) return _sections[key];
    Map<String, dynamic>? entry;
    for (final candidate in await _entries(resourceId)) {
      if (candidate['id'] == sectionId) {
        entry = candidate;
        break;
      }
    }
    if (entry == null) {
      _sections[key] = null;
      return null;
    }
    if (entry['blocks'] is List) {
      final section = CatalogSection.fromJson(entry);
      _sections[key] = section;
      return section;
    }
    final dir = AssetDocumentRepository.dirFor(resourceId);
    try {
      final text = await loadCatalogAssetText(
        _bundle,
        'assets/catalog/$dir/sections/$sectionId.json',
      );
      final section = CatalogSection.fromJson(
        (jsonDecode(text) as Map).cast<String, dynamic>(),
      );
      _sections[key] = section;
      return section;
    } on Object {
      _sections[key] = null;
      return null;
    }
  }
}

/// Secciones servidas por el servicio de catálogo.
class RemoteSectionsRepository implements SectionsRepository {
  RemoteSectionsRepository(this._client);

  final CatalogClient _client;
  final Map<String, List<SectionSummary>> _index = {};
  final Map<String, CatalogSection?> _sections = {};

  @override
  Future<List<SectionSummary>> loadIndex(String resourceId) async {
    final cached = _index[resourceId];
    if (cached != null) return cached;
    final all = <SectionSummary>[];
    var from = 0;
    while (true) {
      final json = await _client.fetchSectionsJson(resourceId, from: from);
      final items = ((json['items'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(SectionSummary.fromJson)
          .toList();
      all.addAll(items);
      final total = json['total'] as int? ?? all.length;
      if (items.isEmpty || all.length >= total) break;
      from += items.length;
    }
    _index[resourceId] = all;
    return all;
  }

  @override
  Future<CatalogSection?> loadSection(
    String resourceId,
    String sectionId,
  ) async {
    final key = '$resourceId/$sectionId';
    if (_sections.containsKey(key)) return _sections[key];
    try {
      final json = await _client.fetchSectionJson(resourceId, sectionId);
      final section = CatalogSection.fromJson(json);
      _sections[key] = section;
      return section;
    } on CatalogException catch (error) {
      if (error.status == 404) {
        _sections[key] = null;
        return null;
      }
      rethrow;
    }
  }
}

/// Servicio si está disponible; assets si no (modo «auto»).
class FallbackSectionsRepository implements SectionsRepository {
  FallbackSectionsRepository({required this.remote, required this.local});

  final SectionsRepository remote;
  final SectionsRepository local;

  Future<T> _fallback<T>(Future<T> Function(SectionsRepository) call) async {
    try {
      return await call(remote);
    } on Exception catch (error) {
      debugPrint('catálogo remoto no disponible ($error); uso secciones locales');
      return call(local);
    }
  }

  @override
  Future<List<SectionSummary>> loadIndex(String resourceId) =>
      _fallback((repository) => repository.loadIndex(resourceId));

  @override
  Future<CatalogSection?> loadSection(String resourceId, String sectionId) =>
      _fallback((repository) => repository.loadSection(resourceId, sectionId));
}

final sectionsRepositoryProvider = Provider<SectionsRepository>((ref) {
  final gateway = ref.watch(catalogGatewayProvider);
  final local = AssetSectionsRepository();
  if (gateway.localOnly) return local;
  final remote = RemoteSectionsRepository(gateway.client);
  if (gateway.mode == 'remote') return remote;
  return FallbackSectionsRepository(remote: remote, local: local);
});

final sectionsIndexProvider =
    FutureProvider.family<List<SectionSummary>, String>(
  (ref, resourceId) =>
      ref.watch(sectionsRepositoryProvider).loadIndex(resourceId),
);

final sectionProvider =
    FutureProvider.family<CatalogSection?, (String resourceId, String id)>(
  (ref, key) =>
      ref.watch(sectionsRepositoryProvider).loadSection(key.$1, key.$2),
);
