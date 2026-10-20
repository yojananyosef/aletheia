/// Biblioteca (M2): panel flotante sobre el espacio de trabajo.
///
/// Fiel a la referencia del original
/// (según la evidencia de reconocimiento): hamburguesa de facetas,
/// caja «Find», contador de recursos, pestañas Biblioteca / Tienda, orden
/// «por Título», lista con portada ficticia y autor, y panel de detalle con
/// «Abrir» y «Más »».
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/catalog_gateway.dart';
import '../catalog/catalog_models.dart';
import '../catalog/resource_launcher.dart';
import '../core/localization.dart';
import '../core/resource_colors.dart';
import '../core/theme.dart';
import '../workspace/models.dart';
import '../workspace/workspace_controller.dart';

/// Visibilidad del overlay de la Biblioteca.
class LibraryOverlayVisible extends Notifier<bool> {
  @override
  bool build() => false;

  void open() => state = true;
  void close() => state = false;
}

final libraryOverlayVisibleProvider =
    NotifierProvider<LibraryOverlayVisible, bool>(LibraryOverlayVisible.new);

class LibraryOverlay extends ConsumerStatefulWidget {
  const LibraryOverlay({super.key});

  @override
  ConsumerState<LibraryOverlay> createState() => _LibraryOverlayState();
}

class _LibraryOverlayState extends ConsumerState<LibraryOverlay> {
  static const _pageSize = 50;

  /// Claves de orden (`por Título`, `por Autor`, `por Fecha` traducidos).
  static const _sortKeys = ['title', 'author', 'updated'];

  final _findController = TextEditingController();
  Timer? _findDebounce;

  bool _facetsOpen = true;
  String _query = '';
  String _sort = 'title';
  String? _type;
  String? _language;
  String? _author;
  int _page = 1;

  ResourceListing? _listing;
  Object? _error;
  bool _loading = true;

  String? _selectedId;
  bool _descriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _findDebounce?.cancel();
    _findController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- datos

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final listing = await ref
          .read(catalogGatewayProvider)
          .listResources(
            query: _query,
            type: _type,
            language: _language,
            author: _author,
            sort: _sort,
            page: _page,
            pageSize: _pageSize,
          );
      if (!mounted) return;
      setState(() {
        _listing = listing;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _onFindChanged(String value) {
    _findDebounce?.cancel();
    _findDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted || value == _query) return;
      setState(() {
        _query = value;
        _page = 1;
      });
      _load();
    });
  }

  void _selectSort(String sort) {
    if (sort == _sort) return;
    setState(() {
      _sort = sort;
      _page = 1;
    });
    _load();
  }

  void _toggleFacet(String dimension, String value) {
    setState(() {
      switch (dimension) {
        case 'type':
          _type = _type == value ? null : value;
        case 'language':
          _language = _language == value ? null : value;
        case 'author':
          _author = _author == value ? null : value;
      }
      _page = 1;
    });
    _load();
  }

  void _clearFilters() {
    setState(() {
      _type = null;
      _language = null;
      _author = null;
      _page = 1;
    });
    _load();
  }

  bool get _hasFilters => _type != null || _language != null || _author != null;

  String _sortLabel(AppLocalizations l10n, String sort) => switch (sort) {
    'author' => l10n.librarySortAuthor,
    'updated' => l10n.librarySortDate,
    _ => l10n.librarySortTitle,
  };

  // -------------------------------------------------------------- acciones

  void _open(ResourceSummary resource) {
    ref.read(libraryOverlayVisibleProvider.notifier).close();
    openCatalogResource(ref, resource);
  }

  ResourceSummary? get _selected {
    final items = _listing?.items ?? const <ResourceSummary>[];
    for (final item in items) {
      if (item.id == _selectedId) return item;
    }
    return null;
  }

  // -------------------------------------------------------------- construir

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          GestureDetector(
            onTap: () =>
                ref.read(libraryOverlayVisibleProvider.notifier).close(),
            child: Container(color: Colors.black.withValues(alpha: 0.22)),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Material(
                elevation: 14,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                color: kPanelBg,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1010,
                    maxHeight: 690,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildToolbar(),
                      const Divider(height: 1),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final narrow = constraints.maxWidth < 900;
                            final selected = _selected;
                            // En ventanas estrechas el detalle sustituye a la
                            // lista (colección → elemento) con un botón volver.
                            if (narrow && selected != null) {
                              return _buildDetail(selected, showBack: true);
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_facetsOpen) _buildFacets(),
                                Expanded(child: _buildList()),
                                if (selected != null)
                                  SizedBox(
                                    width: 300,
                                    child: _buildDetail(selected),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    final l10n = context.l10n;
    final total = _listing?.total;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Sin espacio, se ocultan los elementos decorativos de la derecha.
        final compact = constraints.maxWidth < 820;
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Row(
            children: [
              IconButton(
                key: const ValueKey('library-facets-toggle'),
                iconSize: 19,
                tooltip: l10n.libraryFacets,
                onPressed: () => setState(() => _facetsOpen = !_facetsOpen),
                icon: const Icon(Icons.menu),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 210),
                  child: TextField(
                    key: const ValueKey('library-find'),
                    controller: _findController,
                    onChanged: _onFindChanged,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: l10n.libraryFind,
                      isDense: true,
                      prefixIcon: const Icon(Icons.search, size: 16),
                      suffixIcon: _findController.text.isEmpty
                          ? null
                          : IconButton(
                              iconSize: 14,
                              tooltip: l10n.libraryClear,
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _findController.clear();
                                _onFindChanged('');
                              },
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(7),
                        borderSide: BorderSide(color: kBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(7),
                        borderSide: BorderSide(color: kBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(7),
                        borderSide: const BorderSide(color: kAccent),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  total == null
                      ? l10n.libraryLoading
                      : l10n.libraryCount(total),
                  key: const ValueKey('library-count'),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: kTextSecondary),
                ),
              ),
              const Spacer(),
              if (!compact) ...[
                _buildTab(l10n.libraryTabLibrary, selected: true),
                _buildTab(
                  l10n.libraryTabStore,
                  selected: false,
                  tooltip: l10n.storeTitle,
                  onTap: () {
                    ref.read(libraryOverlayVisibleProvider.notifier).close();
                    ref
                        .read(workspaceProvider.notifier)
                        .openTab(const TabSpec(kind: PanelKind.store));
                  },
                ),
                const SizedBox(width: 6),
              ],
              PopupMenuButton<String>(
                key: const ValueKey('library-sort-menu'),
                tooltip: l10n.librarySort,
                onSelected: _selectSort,
                icon: compact ? const Icon(Icons.sort, size: 19) : null,
                itemBuilder: (context) => [
                  for (final key in _sortKeys)
                    PopupMenuItem(
                      value: key,
                      child: Row(
                        children: [
                          Icon(
                            key == _sort ? Icons.check : Icons.sort,
                            size: 14,
                            color: key == _sort ? kAccent : kTextSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _sortLabel(l10n, key),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                ],
                child: compact
                    ? null
                    : Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _sortLabel(l10n, _sort),
                              key: const ValueKey('library-sort'),
                              style: TextStyle(
                                fontSize: 12.5,
                                color: kTextPrimary,
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              size: 17,
                              color: kTextSecondary,
                            ),
                          ],
                        ),
                      ),
              ),
              IconButton(
                key: const ValueKey('library-close'),
                iconSize: 18,
                tooltip: l10n.close,
                onPressed: () =>
                    ref.read(libraryOverlayVisibleProvider.notifier).close(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab(
    String label, {
    required bool selected,
    String? tooltip,
    VoidCallback? onTap,
  }) {
    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: selected ? kAccent : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected
              ? kTextPrimary
              : kTextSecondary.withValues(alpha: 0.7),
        ),
      ),
    );
    final interactive = onTap == null
        ? body
        : InkWell(onTap: onTap, child: body);
    if (tooltip == null) return interactive;
    return Tooltip(message: tooltip, child: interactive);
  }

  Widget _buildFacets() {
    final l10n = context.l10n;
    final lang = context.l10nLang;
    final facets = _listing?.facets ?? const <String, Map<String, int>>{};
    return Container(
      width: 208,
      decoration: BoxDecoration(
        color: kSidebarBg,
        border: Border(right: BorderSide(color: kBorder)),
      ),
      child: ListView(
        key: const ValueKey('library-facets'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        children: [
          if (_hasFilters)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 15),
                label: Text(
                  l10n.libraryClearFilters,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          _facetSection(
            l10n.libraryFacetType,
            'type',
            facets['type'] ?? const {},
            lang: lang,
          ),
          _facetSection(
            l10n.libraryFacetLanguage,
            'language',
            facets['language'] ?? const {},
            lang: lang,
          ),
          _facetSection(
            l10n.libraryFacetAuthor,
            'author',
            facets['author'] ?? const {},
            lang: lang,
          ),
        ],
      ),
    );
  }

  Widget _facetSection(
    String title,
    String dimension,
    Map<String, int> values, {
    String lang = 'es',
  }) {
    if (values.isEmpty) return const SizedBox.shrink();
    final selected = switch (dimension) {
      'type' => _type,
      'language' => _language,
      _ => _author,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: kTextSecondary,
              ),
            ),
          ),
          for (final entry in values.entries)
            InkWell(
              key: ValueKey('facet-$dimension-${entry.key}'),
              borderRadius: BorderRadius.circular(5),
              onTap: () => _toggleFacet(dimension, entry.key),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                child: Row(
                  children: [
                    Icon(
                      selected == entry.key
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 15,
                      color: selected == entry.key ? kAccent : kTextSecondary,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        dimension == 'language'
                            ? languageLabel(entry.key, lang: lang)
                            : dimension == 'type'
                            ? resourceTypeLabel(entry.key, lang: lang)
                            : entry.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: kTextPrimary,
                          fontWeight: selected == entry.key
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    Text(
                      '${entry.value}',
                      style: TextStyle(fontSize: 11.5, color: kTextSecondary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final l10n = context.l10n;
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      );
    }
    final error = _error;
    if (error != null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined, size: 34, color: kTextSecondary),
              const SizedBox(height: 10),
              Text(
                l10n.libraryErrorTitle,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: kTextSecondary),
              ),
              const SizedBox(height: 10),
              FilledButton.tonal(
                onPressed: _load,
                child: Text(l10n.retry, style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
      );
    }

    final listing = _listing;
    final items = listing?.items ?? const <ResourceSummary>[];
    if (items.isEmpty) {
      return Center(
        child: Text(
          l10n.libraryEmpty,
          style: TextStyle(fontSize: 13, color: kTextSecondary),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            key: const ValueKey('library-list'),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) => _resourceRow(items[index]),
          ),
        ),
        if (listing != null && listing.hasMore)
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextButton(
              onPressed: () {
                setState(() => _page += 1);
                _load();
              },
              child: Text(
                l10n.libraryLoadMore,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
      ],
    );
  }

  Widget _resourceRow(ResourceSummary resource) {
    final selected = resource.id == _selectedId;
    return InkWell(
      key: ValueKey('library-row-${resource.id}'),
      onTap: () => setState(() {
        _selectedId = resource.id;
        _descriptionExpanded = false;
      }),
      onDoubleTap: () => _open(resource),
      child: Container(
        color: selected ? kAccent.withValues(alpha: 0.07) : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            _Cover(
              abbrev: resource.abbrev ?? resource.title,
              resourceId: resource.id,
              width: 34,
              height: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      resource.typeLabelIn(context.l10nLang),
                      if (resource.authors.isNotEmpty) resource.authorsLabel,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: kTextSecondary),
                  ),
                ],
              ),
            ),
            if (resource.locked)
              Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.lock_outline,
                  size: 15,
                  color: kTextSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(ResourceSummary resource, {bool showBack = false}) {
    final l10n = context.l10n;
    final lang = context.l10nLang;
    final stats = resource.verses > 0
        ? l10n.libraryStats(
            formatCount(resource.verses),
            formatCount(resource.sections),
          )
        : null;
    return Container(
      decoration: BoxDecoration(
        color: kSidebarBg,
        border: Border(left: BorderSide(color: kBorder)),
      ),
      child: ListView(
        key: const ValueKey('library-detail'),
        padding: const EdgeInsets.all(16),
        children: [
          if (showBack)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _selectedId = null),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: Text(
                  l10n.libraryBack,
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
            ),
          Center(
            child: _Cover(
              abbrev: resource.abbrev ?? resource.title,
              resourceId: resource.id,
              width: 92,
              height: 122,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            resource.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
          ),
          if (resource.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              resource.subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: kTextSecondary),
            ),
          ],
          if (resource.authors.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              resource.authorsLabel,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: kTextPrimary),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              _Chip(label: resource.typeLabelIn(lang)),
              if (resource.language.isNotEmpty)
                _Chip(label: languageLabel(resource.language, lang: lang)),
              if (resource.licenseText.isNotEmpty)
                _Chip(label: resource.licenseText),
            ],
          ),
          if (stats != null) ...[
            const SizedBox(height: 10),
            Text(
              stats,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: kTextSecondary),
            ),
          ],
          if (resource.description != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Text(
              resource.description!,
              maxLines: _descriptionExpanded ? 12 : 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: kTextPrimary,
              ),
            ),
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            key: const ValueKey('library-open'),
            onPressed: () => _open(resource),
            icon: Icon(
              resource.isBible
                  ? Icons.menu_book_outlined
                  : Icons.article_outlined,
              size: 17,
            ),
            label: Text(
              l10n.libraryOpen,
              style: const TextStyle(fontSize: 13.5),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: resource.description == null
                ? null
                : () => setState(
                    () => _descriptionExpanded = !_descriptionExpanded,
                  ),
            child: Text(
              _descriptionExpanded ? l10n.libraryLess : l10n.libraryMore,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Portada ficticia hasta que el catálogo sirva imágenes (M2).
class _Cover extends StatelessWidget {
  const _Cover({
    required this.abbrev,
    required this.resourceId,
    required this.width,
    required this.height,
  });

  final String abbrev;
  final String resourceId;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    // El color identifica al recurso, como en la pestaña y el lector (D-12).
    final color = resourceColorFor(resourceId);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        border: Border.all(color: color.withValues(alpha: 0.30)),
        borderRadius: BorderRadius.circular(3),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(3),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          abbrev,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: width < 50 ? 10 : 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(12),
        color: kPanelBg,
      ),
      child: Text(label, style: TextStyle(fontSize: 11.5, color: kTextPrimary)),
    );
  }
}
