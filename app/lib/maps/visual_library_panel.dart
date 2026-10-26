/// Atlas y Medios (M6.4).
///
/// Ambas herramientas parten del mismo manifiesto empaquetado
/// (`map_sections.json`): Atlas ofrece una lista de mapas con su sección de
/// origen y Medios una galería visual. El detalle dibuja el mapa offline con
/// [BibleMap] y permite abrir la sección original en el recurso.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/document_models.dart';

import 'package:aletheia/catalog/sections_repository.dart';
import 'package:aletheia/core/localization.dart';
import 'package:aletheia/core/theme.dart';
import 'package:aletheia/favorites/favorites_controller.dart';
import 'package:aletheia/favorites/favorites_models.dart';
import 'package:aletheia/panels/section_view.dart';
import 'package:aletheia/references/reference_parser.dart';
import 'package:aletheia/workspace/models.dart';

import '../workspace/workspace_controller.dart';
import 'bible_map.dart';
import 'visual_sections.dart';

enum VisualLibraryMode { atlas, media }

class VisualLibraryPanel extends ConsumerStatefulWidget {
  const VisualLibraryPanel({
    super.key,
    required this.mode,
    required this.tile,
    required this.tab,
  });

  final VisualLibraryMode mode;
  final WorkspaceTile tile;
  final WorkspaceTab tab;

  @override
  ConsumerState<VisualLibraryPanel> createState() => _VisualLibraryPanelState();
}

class _VisualLibraryPanelState extends ConsumerState<VisualLibraryPanel> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  String _source = 'all';
  String? _selectedSection;
  String? _selectedResource;

  bool get _isAtlas => widget.mode == VisualLibraryMode.atlas;

  @override
  void initState() {
    super.initState();
    _selectedSection = widget.tab.reference;
    _selectedResource = widget.tab.resourceId;
  }

  @override
  void didUpdateWidget(covariant VisualLibraryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tab.reference != oldWidget.tab.reference) {
      _selectedSection = widget.tab.reference;
      _selectedResource = widget.tab.resourceId;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _fold(String value) {
    const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const to = 'aaaaaeeeeiiiiooooouuuunc';
    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      final index = from.indexOf(char);
      buffer.write(index == -1 ? char : to[index]);
    }
    return buffer.toString();
  }

  bool _matchesSource(VisualSectionEntry entry) => switch (_source) {
    'factbook' => !entry.isCommentary && entry.kind != 'journey',
    'commentary' => entry.isCommentary,
    _ => true,
  };

  List<VisualSectionEntry> _visible(List<VisualSectionEntry> all) {
    final query = _fold(_query.trim());
    return [
      for (final entry in all)
        if (_matchesSource(entry) &&
            (query.isEmpty ||
                _fold(
                  [
                    entry.title,
                    entry.caption ?? '',
                    entry.resourceTitle,
                    entry.section,
                  ].join(' '),
                ).contains(query)))
          entry,
    ];
  }

  VisualSectionEntry? _selected(List<VisualSectionEntry> all) {
    final section = _selectedSection;
    if (section == null || section.isEmpty) return null;
    for (final entry in all) {
      if (entry.section == section &&
          (_selectedResource == null ||
              _selectedResource!.isEmpty ||
              entry.resource == _selectedResource)) {
        return entry;
      }
    }
    for (final entry in all) {
      if (entry.section == section) return entry;
    }
    return null;
  }

  void _select(VisualSectionEntry entry) {
    setState(() {
      _selectedSection = entry.section;
      _selectedResource = entry.resource;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedSection = null;
      _selectedResource = null;
    });
  }

  void _openReference(String canonical) {
    final ctrl = ref.read(workspaceProvider.notifier);
    if (ctrl.openInResource(
      resourceId: kDefaultBibleResourceId,
      reference: canonical,
    )) {
      return;
    }
    ctrl.openTab(
      TabSpec(
        kind: PanelKind.bible,
        reference: canonical,
        resourceId: kDefaultBibleResourceId,
      ),
    );
  }

  void _toggleMapFavorite(VisualSectionEntry entry) {
    final l10n = context.l10n;
    final ctrl = ref.read(favoritesProvider.notifier);
    final existing = ctrl.find(
      FavoriteKind.map,
      entry.section,
      resourceId: entry.resource,
    );
    if (existing != null) {
      ctrl.remove(existing.id);
    } else {
      ctrl.add(
        kind: FavoriteKind.map,
        title: entry.title,
        subtitle: entry.resourceTitle,
        resourceId: entry.resource,
        reference: entry.section,
      );
    }
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          existing != null ? l10n.favoritesRemoved : l10n.favoritesAdded,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openSection(VisualSectionEntry entry) {
    ref
        .read(workspaceProvider.notifier)
        .openTab(
          TabSpec(
            kind: PanelKind.resource,
            title: entry.resourceTitle,
            resourceId: entry.resource,
            reference: entry.section,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final async = ref.watch(visualSectionsProvider);
    final title = _isAtlas ? l10n.panelTitleAtlas : l10n.panelTitleMedia;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: Row(
            children: [
              Icon(
                _isAtlas ? Icons.public : Icons.perm_media_outlined,
                size: 18,
                color: kAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: Text(
            _isAtlas ? l10n.atlasIntro : l10n.mediaIntro,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: kTextSecondary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
          child: TextField(
            key: ValueKey(_isAtlas ? 'atlas-search' : 'media-search'),
            controller: _search,
            onChanged: (value) => setState(() => _query = value),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: _isAtlas ? l10n.atlasSearchHint : l10n.mediaSearchHint,
              isDense: true,
              prefixIcon: const Icon(Icons.search, size: 17),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      iconSize: 15,
                      tooltip: l10n.close,
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: kAccent),
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: Row(
            children: [
              for (final source in const ['all', 'factbook', 'commentary'])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    key: ValueKey(
                      '${_isAtlas ? 'atlas' : 'media'}-source-$source',
                    ),
                    label: Text(switch (source) {
                      'factbook' => l10n.atlasSourceFactbook,
                      'commentary' => l10n.atlasSourceCommentary,
                      _ => l10n.atlasSourceAll,
                    }, style: const TextStyle(fontSize: 11.5)),
                    selected: _source == source,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    onSelected: (_) => setState(() {
                      _source = source;
                      _clearSelection();
                    }),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: async.when(
            loading: () => const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isAtlas ? l10n.atlasLoadError : l10n.mediaLoadError,
                    style: const TextStyle(fontSize: 13.5),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(visualSectionsProvider),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
            data: (catalog) {
              final entries = _isAtlas
                  ? [
                      ...catalog.journeys.map((journey) => journey.entry),
                      ...catalog.maps,
                    ]
                  : catalog.media;
              final visible = _visible(entries);
              final selected = _selected(entries);
              if (entries.isEmpty) {
                return SectionEmptyState(
                  icon: _isAtlas ? Icons.public_off : Icons.perm_media_outlined,
                  title: _isAtlas ? l10n.atlasEmpty : l10n.mediaEmpty,
                  detail: l10n.atlasAttribution,
                );
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 720;
                  if (selected != null) {
                    final list = _buildList(visible, selected, l10n);
                    final detail = _buildDetail(selected, catalog, l10n);
                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(width: 310, child: list),
                          const VerticalDivider(width: 1),
                          Expanded(child: detail),
                        ],
                      );
                    }
                    return detail;
                  }
                  if (_isAtlas) {
                    return _buildList(visible, null, l10n);
                  }
                  return _buildGallery(visible, l10n);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildList(
    List<VisualSectionEntry> entries,
    VisualSectionEntry? selected,
    AppLocalizations l10n,
  ) {
    if (entries.isEmpty) {
      return SectionEmptyState(
        icon: Icons.search_off,
        title: l10n.atlasNoResults,
        detail: l10n.atlasSearchHint,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
          child: Text(
            l10n.atlasCount(entries.length),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: kTextSecondary,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: entries.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, indent: 14, endIndent: 14),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final active =
                  selected != null &&
                  selected.section == entry.section &&
                  selected.resource == entry.resource;
              return InkWell(
                key: ValueKey(
                  '${_isAtlas ? 'atlas' : 'media'}-entry-'
                  '${entry.resource}-${entry.section}',
                ),
                onTap: () => _select(entry),
                child: Container(
                  color: active ? kFieldFill : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        switch (entry.kind) {
                          'journey' => Icons.route,
                          'map' => Icons.map_outlined,
                          _ => Icons.image_outlined,
                        },
                        size: 17,
                        color: kAccent,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.title,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              entry.resourceTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: kTextSecondary,
                              ),
                            ),
                            if (entry.caption != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                entry.caption!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  height: 1.35,
                                  color: kTextSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 17,
                        color: kTextSecondary,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGallery(
    List<VisualSectionEntry> entries,
    AppLocalizations l10n,
  ) {
    if (entries.isEmpty) {
      return SectionEmptyState(
        icon: Icons.search_off,
        title: l10n.atlasNoResults,
        detail: l10n.mediaSearchHint,
      );
    }
    return GridView.builder(
      key: const ValueKey('media-gallery'),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisExtent: 124,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return InkWell(
          key: ValueKey('media-entry-${entry.resource}-${entry.section}'),
          onTap: () => _select(entry),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPanelBg,
              border: Border.all(color: kCardBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.map_outlined, size: 16, color: kAccent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    entry.caption ?? entry.resourceTitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: kTextSecondary,
                    ),
                  ),
                ),
                Text(
                  l10n.mediaOpenMap,
                  style: const TextStyle(fontSize: 11, color: kAccent),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetail(
    VisualSectionEntry entry,
    VisualSectionCatalog catalog,
    AppLocalizations l10n,
  ) {
    if (entry.kind == 'journey') {
      return _buildJourneyDetail(entry, catalog, l10n);
    }
    final async = ref.watch(sectionProvider((entry.resource, entry.section)));
    final mapSaved = ref
        .watch(favoritesProvider)
        .any(
          (favorite) =>
              favorite.kind == FavoriteKind.map &&
              favorite.reference == entry.section &&
              favorite.resourceId == entry.resource,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 8, 4),
          child: Row(
            children: [
              IconButton(
                key: ValueKey('${_isAtlas ? 'atlas' : 'media'}-detail-back'),
                iconSize: 18,
                tooltip: l10n.readerBack,
                onPressed: _clearSelection,
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      entry.resourceTitle,
                      style: TextStyle(fontSize: 11.5, color: kTextSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('${_isAtlas ? 'atlas' : 'media'}-favorite'),
                iconSize: 17,
                tooltip: mapSaved ? l10n.favoritesRemove : l10n.favoritesAdd,
                onPressed: () => _toggleMapFavorite(entry),
                icon: Icon(mapSaved ? Icons.star : Icons.star_border),
              ),
              TextButton(
                key: ValueKey('${_isAtlas ? 'atlas' : 'media'}-open-section'),
                onPressed: () => _openSection(entry),
                child: Text(
                  l10n.atlasOpenResource,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: async.when(
            loading: () => const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.atlasLoadError,
                    style: const TextStyle(fontSize: 13.5),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(
                      sectionProvider((entry.resource, entry.section)),
                    ),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
            data: (section) {
              if (section == null) {
                return SectionEmptyState(
                  icon: Icons.map_outlined,
                  title: l10n.atlasLoadError,
                  detail: entry.resourceTitle,
                );
              }
              final maps = section.blocks.whereType<MapBlock>().toList();
              if (maps.isEmpty) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                  child: SectionBlocksView(
                    blocks: section.blocks,
                    onNavigate: _openReference,
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  for (final map in maps) ...[
                    if (map.caption != null && map.caption!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          map.caption!,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: kTextSecondary,
                          ),
                        ),
                      ),
                    BibleMap(
                      block: map,
                      onNavigate: _openReference,
                      expandable: true,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// Detalle de una ruta del Atlas (`journey`): no consulta secciones
  /// remotas, dibuja el bloque derivado de los datos empaquetados.
  Widget _buildJourneyDetail(
    VisualSectionEntry entry,
    VisualSectionCatalog catalog,
    AppLocalizations l10n,
  ) {
    final journey = catalog.journeys
        .where((j) => j.id == entry.section)
        .firstOrNull;
    final block = journey?.toMapBlock();
    if (journey == null || block == null) {
      return SectionEmptyState(
        icon: Icons.route,
        title: l10n.atlasLoadError,
        detail: entry.title,
      );
    }
    final mapSaved = ref
        .watch(favoritesProvider)
        .any(
          (favorite) =>
              favorite.kind == FavoriteKind.map &&
              favorite.reference == entry.section &&
              favorite.resourceId == entry.resource,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 8, 4),
          child: Row(
            children: [
              IconButton(
                key: const ValueKey('journey-detail-back'),
                iconSize: 18,
                tooltip: l10n.readerBack,
                onPressed: _clearSelection,
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      entry.resourceTitle,
                      style: TextStyle(fontSize: 11.5, color: kTextSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const ValueKey('journey-favorite'),
                iconSize: 17,
                tooltip: mapSaved ? l10n.favoritesRemove : l10n.favoritesAdd,
                onPressed: () => _toggleMapFavorite(entry),
                icon: Icon(mapSaved ? Icons.star : Icons.star_border),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildJourneyMap(journey, block, l10n)),
      ],
    );
  }

  Widget _buildJourneyMap(
    VisualJourney journey,
    MapBlock block,
    AppLocalizations l10n,
  ) {
    // Con alto disponible suficiente (el detalle del mapa ya viene dentro de
    // un Expanded) el mapa encaja completo sin scroll: caption y referencias
    // arriba, el mapa ocupando el resto del panel y las atribuciones abajo.
    // En ventanas muy chicas se conserva la lista desplazable de siempre.
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool fitsPanel =
            constraints.maxHeight.isFinite && constraints.maxHeight > 420.0;
        if (fitsPanel) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (journey.caption != null &&
                    journey.caption!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      journey.caption!,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: kTextSecondary,
                      ),
                    ),
                  ),
                if (journey.refs.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final ref in journey.refs)
                        OutlinedButton(
                          key: ValueKey('journey-ref-$ref'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => _openReference(ref),
                          child: Text(
                            displayFromCanonical(ref, lang: context.l10nLang),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 10),
                // El mapa aprovecha todo el alto libre del panel: al dejar
                // una sola atribución interna sobraba espacio vacío abajo y
                // se veía raro. El detalle completo adicional vive en el
                // modal de mapa completo.
                Expanded(
                  child: BibleMap(
                    block: block,
                    onNavigate: _openReference,
                    expandable: true,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            if (journey.caption != null && journey.caption!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  journey.caption!,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: kTextSecondary,
                  ),
                ),
              ),
            if (journey.refs.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final ref in journey.refs)
                    OutlinedButton(
                      key: ValueKey('journey-ref-$ref'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _openReference(ref),
                      child: Text(
                        displayFromCanonical(ref, lang: context.l10nLang),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            BibleMap(
              block: block,
              onNavigate: _openReference,
              expandable: true,
            ),
          ],
        );
      },
    );
  }
}
