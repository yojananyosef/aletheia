/// Lector genérico de recursos de sección (comentario y diccionario).
///
/// El catálogo describe estos recursos con un índice de metadatos y un
/// archivo por entrada. El panel muestra el índice filtrable a la izquierda y
/// la entrada seleccionada a la derecha; en anchos estrechos alterna entre
/// ambos. Las referencias bíblicas del cuerpo se abren en el lector.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/document_models.dart';
import '../catalog/sections_repository.dart';
import '../core/localization.dart';
import '../core/theme.dart';
import '../reader/reader_style.dart';
import '../references/reference_parser.dart';
import '../workspace/models.dart';
import '../workspace/workspace_controller.dart';
import 'section_view.dart';

class CatalogResourcePanel extends ConsumerStatefulWidget {
  const CatalogResourcePanel({
    super.key,
    required this.tile,
    required this.tab,
  });

  final WorkspaceTile tile;
  final WorkspaceTab tab;

  @override
  ConsumerState<CatalogResourcePanel> createState() =>
      _CatalogResourcePanelState();
}

class _CatalogResourcePanelState extends ConsumerState<CatalogResourcePanel> {
  late final TextEditingController _controller;
  final ScrollController _scrollController = ScrollController();
  String? _selectedId;

  String get _resourceId => widget.tab.resourceId ?? '';
  String get _title => widget.tab.title;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _selectedId = widget.tab.reference;
  }

  @override
  void didUpdateWidget(covariant CatalogResourcePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tab.reference != oldWidget.tab.reference) {
      setState(() => _selectedId = widget.tab.reference);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
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

  List<SectionSummary> _visible(List<SectionSummary> all) {
    final query = _fold(_controller.text.trim());
    if (query.isEmpty) return all;
    return all.where((entry) {
      final haystack = _fold(
        [
          entry.title,
          entry.summary ?? '',
          entry.referenceLabel ?? '',
          entry.reference ?? '',
          ...entry.tags,
        ].join(' '),
      );
      return haystack.contains(query);
    }).toList();
  }

  void _select(SectionSummary entry) {
    setState(() => _selectedId = entry.id);
    final current = widget.tab.reference;
    if (current == entry.id) return;
    ref
        .read(workspaceProvider.notifier)
        .navigateTabReference(
          tileId: widget.tile.id,
          tabId: widget.tab.id,
          reference: entry.id,
        );
  }

  void _back() {
    setState(() => _selectedId = null);
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final asyncIndex = ref.watch(sectionsIndexProvider(_resourceId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
          child: Row(
            children: [
              Icon(
                Icons.auto_stories_outlined,
                size: 17,
                color: kTextSecondary,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  _title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          child: TextField(
            key: const ValueKey('catalog-resource-filter'),
            controller: _controller,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: l10n.catalogFilterHint,
              isDense: true,
              prefixIcon: const Icon(Icons.search, size: 17),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      iconSize: 15,
                      tooltip: l10n.close,
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _controller.clear();
                        setState(() {});
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
        const Divider(height: 1),
        Expanded(
          child: asyncIndex.when(
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
                    l10n.factbookLoadError,
                    style: const TextStyle(fontSize: 13.5),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () =>
                        ref.invalidate(sectionsIndexProvider(_resourceId)),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
            data: (entries) {
              final visible = _visible(entries);
              SectionSummary? selected;
              if (_selectedId != null) {
                for (final entry in entries) {
                  if (entry.id == _selectedId) {
                    selected = entry;
                    break;
                  }
                }
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 640;
                  if (selected != null && wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 270,
                          child: _buildList(visible, selected.id, l10n),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: _buildEntry(selected, l10n)),
                      ],
                    );
                  }
                  if (selected != null) {
                    return _buildEntry(selected, l10n);
                  }
                  return _buildList(visible, null, l10n);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildList(
    List<SectionSummary> entries,
    String? selectedId,
    AppLocalizations l10n,
  ) {
    if (entries.isEmpty) {
      return SectionEmptyState(
        icon: Icons.search_off,
        title: l10n.factbookNoResults,
        detail: l10n.catalogFilterHint,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
          child: Text(
            l10n.catalogEntriesCount(entries.length),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: kTextSecondary,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            key: const ValueKey('catalog-resource-index'),
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: entries.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, indent: 14, endIndent: 14),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final active = entry.id == selectedId;
              return InkWell(
                key: ValueKey('catalog-entry-${entry.id}'),
                onTap: () => _select(entry),
                child: Container(
                  color: active ? kSidebarBg : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (entry.referenceLabel != null &&
                              entry.referenceLabel!.trim().toLowerCase() !=
                                  entry.title.trim().toLowerCase())
                            Text(
                              entry.referenceLabel!,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: kTextSecondary,
                              ),
                            ),
                        ],
                      ),
                      if (entry.summary != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          entry.summary!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: kTextSecondary,
                          ),
                        ),
                      ],
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

  Widget _buildEntry(SectionSummary entry, AppLocalizations l10n) {
    final asyncSection = ref.watch(sectionProvider((_resourceId, entry.id)));
    final reference = entry.reference;
    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        key: const ValueKey('catalog-resource-detail'),
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  key: const ValueKey('catalog-resource-back'),
                  onPressed: _back,
                  icon: const Icon(Icons.arrow_back, size: 15),
                  label: Text(
                    l10n.catalogBackToIndex,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.title,
                  style: readerBodyStyle(size: 23)
                      .copyWith(fontWeight: FontWeight.w700, height: 1.25),
                ),
                if (reference != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        displayFromCanonical(reference, lang: context.l10nLang),
                        style: TextStyle(fontSize: 12.5, color: kTextSecondary),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        key: const ValueKey('catalog-open-passage'),
                        onPressed: () => _openReference(reference),
                        icon: const Icon(Icons.menu_book_outlined, size: 15),
                        label: Text(
                          l10n.factbookOpenPassage,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
                if (entry.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tag in entry.tags)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: kSidebarBg,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: kBorder),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: kTextSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                asyncSection.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  error: (error, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.factbookLoadError,
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(
                          sectionProvider((_resourceId, entry.id)),
                        ),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                  data: (section) {
                    if (section == null || section.blocks.isEmpty) {
                      return Text(
                        l10n.factbookNoResults,
                        style: const TextStyle(fontSize: 13),
                      );
                    }
                    final blocks = [...section.blocks];
                    if (blocks.isNotEmpty &&
                        blocks.first is HeadingBlock &&
                        (blocks.first as HeadingBlock).text == entry.title) {
                      blocks.removeAt(0);
                    }
                    return SectionBlocksView(
                      blocks: blocks,
                      onNavigate: _openReference,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
