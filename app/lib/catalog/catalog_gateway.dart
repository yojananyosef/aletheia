/// Acceso unificado al catálogo (M2).
///
/// La Biblioteca y la Búsqueda hablan con este gateway: si el servicio
/// `catalog/` está disponible se usa; si no, y el modo lo permite, se cae a
/// los recursos y al índice FTS5 empaquetados en la app. Desde la mejora de
/// autonomía, el modo local también busca: no hace falta arrancar Python.
library;

import 'dart:convert';
import 'dart:math' show min;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../workspace/workspace_controller.dart' show workspaceProvider;
import 'catalog_client.dart';
import 'catalog_models.dart';
import 'local_catalog_index.dart';

/// Detalle del error de búsqueda para la UI.
String searchErrorMessage(AppLocalizations l10n, Object? error) {
  if (error is LocalSearchUnavailableException) {
    return l10n.searchIndexUnavailable;
  }
  if (error is CatalogException) return error.message;
  return '$error';
}

class CatalogGateway {
  CatalogGateway({
    required this.mode,
    required this.client,
    this.bundle,
    LocalCatalogIndex? localIndex,
  }) : localIndex = localIndex ?? LocalCatalogIndex(bundle: bundle);

  /// `auto` (servicio con respaldo local) | `local` | `remote`.
  final String mode;
  final CatalogClient client;
  final AssetBundle? bundle;
  final LocalCatalogIndex localIndex;

  /// En web no hay servicio Python local: `auto` equivale a `local` para no
  /// intentar (y bloquear la UI con) conexiones a `127.0.0.1`. El modo
  /// `remote` explícito sigue intentando el servicio configurado.
  bool get localOnly => mode == 'local' || (kIsWeb && mode == 'auto');

  /// Estado del catálogo. En modo local, o en automático sin servicio, el
  /// estado corresponde al índice incluido en la app (`CatalogHealth.local`).
  Future<CatalogHealth?> health() async {
    if (localOnly) return _localHealth();
    final remote = await client.health();
    if (remote != null) return remote;
    if (mode == 'auto') return _localHealth();
    return null;
  }

  Future<CatalogHealth> _localHealth() async {
    final resources = (await bundledResources()).length;
    final verses = await localIndex.verseCount();
    final sections = await localIndex.sectionCount();
    final crossReferences = await localIndex.crossReferenceCount();
    return CatalogHealth(
      resources: resources,
      verses: verses,
      sections: sections,
      crossReferences: crossReferences,
      local: true,
    );
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
    if (!localOnly) {
      try {
        return await client.listResources(
          query: query,
          type: type,
          language: language,
          author: author,
          sort: sort,
          page: page,
          pageSize: pageSize,
        );
      } on CatalogException {
        if (mode == 'remote') rethrow;
      }
    }
    return _localListing(
      query: query,
      type: type,
      language: language,
      author: author,
      sort: sort,
      page: page,
      pageSize: pageSize,
    );
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
    if (!localOnly) {
      try {
        return await client.search(
          query: query,
          scope: scope,
          resource: resource,
          type: type,
          language: language,
          book: book,
          page: page,
          pageSize: pageSize,
        );
      } on CatalogException {
        if (mode == 'remote') rethrow;
      }
    }
    return localIndex.search(
      query: query,
      scope: scope,
      resource: resource,
      type: type,
      language: language,
      book: book,
      page: page,
      pageSize: pageSize,
    );
  }

  /// Referencias cruzadas reales (TSK) para el drawer de Ideas.
  Future<List<CrossReference>> crossReferences(
    String reference, {
    int limit = 40,
  }) async {
    if (!localOnly) {
      try {
        return await client.fetchCrossReferences(reference, limit: limit);
      } on CatalogException {
        if (mode == 'remote') rethrow;
      }
    }
    return localIndex.crossReferences(reference, limit: limit);
  }

  // ------------------------------------------------------------- modo local

  void dispose() {
    client.close();
    localIndex.close();
  }

  List<ResourceSummary>? _bundledCache;

  Future<List<ResourceSummary>> bundledResources() async {
    final cached = _bundledCache;
    if (cached != null) return cached;
    final raw = await (bundle ?? rootBundle).loadString(
      'assets/catalog/index.json',
    );
    final list = (jsonDecode(raw) as List)
        .map((e) => ResourceSummary.fromJson(e as Map<String, dynamic>))
        .toList();
    _bundledCache = list;
    return list;
  }

  Future<ResourceListing> _localListing({
    required String query,
    required String? type,
    required String? language,
    required String? author,
    required String sort,
    required int page,
    required int pageSize,
  }) async {
    final all = await bundledResources();

    bool matches(ResourceSummary r, {String? skip}) {
      if (type != null && skip != 'type' && r.type != type) return false;
      if (language != null && skip != 'language' && r.language != language) {
        return false;
      }
      if (author != null && skip != 'author' && !r.authors.contains(author)) {
        return false;
      }
      if (query.trim().isNotEmpty && !_textMatch(r, query)) return false;
      return true;
    }

    final filtered = all.where((r) => matches(r)).toList()
      ..sort(switch (sort) {
        'author' => (a, b) => _firstAuthor(a).compareTo(_firstAuthor(b)),
        _ => (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      });
    final start = (page - 1) * pageSize;
    final items = start < filtered.length
        ? filtered.sublist(start, min(start + pageSize, filtered.length))
        : <ResourceSummary>[];

    return ResourceListing(
      total: filtered.length,
      page: page,
      pageSize: pageSize,
      items: items,
      facets: {
        'type': _counts(
          all.where((r) => matches(r, skip: 'type')).map((r) => r.type),
        ),
        'language': _counts(
          all
              .where((r) => matches(r, skip: 'language'))
              .map((r) => r.language.isEmpty ? '—' : r.language),
        ),
        'author': _counts([
          for (final r in all.where((r) => matches(r, skip: 'author')))
            ...r.authors,
        ]),
      },
    );
  }

  static String _firstAuthor(ResourceSummary r) =>
      r.authors.isEmpty ? '' : r.authors.first.toLowerCase();

  static bool _textMatch(ResourceSummary r, String query) {
    final haystack = [
      r.title,
      r.subtitle ?? '',
      r.abbrev ?? '',
      r.authors.join(' '),
      r.tags.join(' '),
      r.description ?? '',
    ].join(' ').toLowerCase();
    return query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .every(haystack.contains);
  }

  static Map<String, int> _counts(Iterable<String> values) {
    final counts = <String, int>{};
    for (final value in values) {
      counts[value] = (counts[value] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0
            ? byCount
            : a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });
    return {for (final e in entries) e.key: e.value};
  }
}

final catalogGatewayProvider = Provider<CatalogGateway>((ref) {
  final (url, mode) = ref.watch(
    workspaceProvider.select((s) => (s.catalogUrl, s.catalogMode)),
  );
  final client = CatalogClient(baseUrl: url);
  final gateway = CatalogGateway(mode: mode, client: client);
  ref.onDispose(gateway.dispose);
  return gateway;
});

/// Estado del servicio para Ajustes/indicadores (se refresca con `invalidate`).
final catalogHealthProvider = FutureProvider<CatalogHealth?>(
  (ref) => ref.watch(catalogGatewayProvider).health(),
);
