/// Factbook / Enciclopedia bíblica (M5).
///
/// Artículos propios del recurso `factbook.core`: búsqueda por tema o
/// referencia, lentes por categoría, cuerpo del artículo, referencias
/// bíblicas y temas relacionados. El original añade fuentes de la biblioteca
/// del usuario y una linea de tiempo; aquí el alcance es el contenido propio.
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

const kFactbookResourceId = 'factbook.core';

enum _Lens { all, biblical, library, theology, counseling, discover }

class FactbookPanel extends ConsumerStatefulWidget {
  const FactbookPanel({super.key, required this.tile, required this.tab});

  final WorkspaceTile tile;
  final WorkspaceTab tab;

  @override
  ConsumerState<FactbookPanel> createState() => _FactbookPanelState();
}

class _FactbookPanelState extends ConsumerState<FactbookPanel> {
  late final TextEditingController _controller;
  final ScrollController _scrollController = ScrollController();
  _Lens _lens = _Lens.all;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.tab.query ?? '');
    _selectedId = widget.tab.reference;
  }

  @override
  void didUpdateWidget(covariant FactbookPanel oldWidget) {
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

  // ------------------------------------------------------------ filtros

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

  bool _matchesLens(SectionSummary topic) {
    final tags = topic.tags.toSet();
    return switch (_lens) {
      _Lens.all || _Lens.discover => true,
      _Lens.biblical => tags.intersection(const {
        'Personas',
        'Lugares',
        'Historia',
        'Antiguo Testamento',
        'Evangelios',
        'Nuevo Testamento',
      }).isNotEmpty,
      _Lens.theology => tags.contains('Teología'),
      _Lens.counseling =>
        tags.contains('Consuelo') || tags.contains('Práctica'),
      // Sin biblioteca conectada ni motor de descubrimiento todavía.
      _Lens.library => false,
    };
  }

  List<SectionSummary> _visible(List<SectionSummary> all) {
    final query = _fold(_controller.text.trim());
    return all.where((topic) {
      if (!_matchesLens(topic)) return false;
      if (query.isEmpty) return true;
      final haystack = _fold(
        [
          topic.title,
          topic.summary ?? '',
          ...topic.tags,
          ...topic.references,
        ].join(' '),
      );
      return haystack.contains(query);
    }).toList();
  }

  void _submit(List<SectionSummary> all) {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() => _selectedId = null);
      return;
    }
    final visible = _visible(all);
    final exact = visible.where((topic) => _fold(topic.title) == _fold(query));
    final match = exact.isNotEmpty
        ? exact.first
        : (visible.length == 1 ? visible.first : null);
    if (match != null) {
      _select(match);
    } else {
      setState(() => _selectedId = null);
    }
  }

  void _select(SectionSummary topic) {
    setState(() {
      _selectedId = topic.id;
      _controller.text = topic.title;
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

  // ------------------------------------------------------------ construir

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final asyncIndex = ref.watch(sectionsIndexProvider(kFactbookResourceId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
          child: TextField(
            key: const ValueKey('factbook-search'),
            controller: _controller,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              final all = asyncIndex.asData?.value;
              if (all != null) _submit(all);
            },
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: l10n.factbookSearchHint,
              isDense: true,
              prefixIcon: const Icon(Icons.search, size: 17),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      key: const ValueKey('factbook-clear'),
                      iconSize: 15,
                      tooltip: l10n.close,
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _selectedId = null);
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
        _buildLenses(l10n),
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
                    onPressed: () => ref.invalidate(
                      sectionsIndexProvider(kFactbookResourceId),
                    ),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
            data: (topics) {
              final selected = _selectedId == null
                  ? null
                  : topics
                        .where((topic) => topic.id == _selectedId)
                        .firstOrNull;
              if (selected != null) {
                return _buildArticle(selected, topics);
              }
              return _buildTopics(topics, l10n);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLenses(AppLocalizations l10n) {
    final labels = <(_Lens, String)>[
      (_Lens.all, l10n.factbookLensAll),
      (_Lens.biblical, l10n.factbookLensBiblical),
      (_Lens.library, l10n.factbookLensLibrary),
      (_Lens.theology, l10n.factbookLensTheology),
      (_Lens.counseling, l10n.factbookLensCounseling),
      (_Lens.discover, l10n.factbookLensDiscover),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: Row(
        children: [
          for (final (lens, label) in labels) ...[
            ChoiceChip(
              key: ValueKey('factbook-lens-${lens.name}'),
              label: Text(label, style: const TextStyle(fontSize: 11.5)),
              selected: _lens == lens,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              onSelected: (_) => setState(() {
                _lens = lens;
                _selectedId = null;
              }),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _buildTopics(List<SectionSummary> topics, AppLocalizations l10n) {
    final visible = _visible(topics);
    if (visible.isEmpty) {
      final reference = parseReference(_controller.text);
      if (reference != null) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.menu_book_outlined, size: 30, color: kTextSecondary),
                const SizedBox(height: 10),
                Text(
                  displayFromCanonical(
                    reference.canonical,
                    lang: context.l10nLang,
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  key: const ValueKey('factbook-open-passage'),
                  onPressed: () => _openReference(reference.canonical),
                  icon: const Icon(Icons.menu_book_outlined, size: 16),
                  label: Text(l10n.factbookOpenPassage),
                ),
              ],
            ),
          ),
        );
      }
      return SectionEmptyState(
        icon: Icons.search_off,
        title: l10n.factbookNoResults,
        detail: l10n.factbookSearchHint,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Text(
            l10n.factbookTopicsCount(visible.length),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: kTextSecondary,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            key: const ValueKey('factbook-topics'),
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: visible.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, indent: 14, endIndent: 14),
            itemBuilder: (context, index) {
              final topic = visible[index];
              return InkWell(
                key: ValueKey('factbook-topic-${topic.id}'),
                onTap: () => _select(topic),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (topic.summary != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          topic.summary!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: kTextSecondary,
                          ),
                        ),
                      ],
                      if (topic.tags.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 5,
                          children: [
                            for (final tag in topic.tags.take(3))
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: kSidebarBg,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: kBorder),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: kTextSecondary,
                                  ),
                                ),
                              ),
                          ],
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

  Widget _buildArticle(SectionSummary topic, List<SectionSummary> topics) {
    final l10n = context.l10n;
    final asyncSection = ref.watch(
      sectionProvider((kFactbookResourceId, topic.id)),
    );
    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        key: const ValueKey('factbook-article'),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  key: const ValueKey('factbook-back'),
                  onPressed: () => setState(() => _selectedId = null),
                  icon: const Icon(Icons.arrow_back, size: 15),
                  label: Text(
                    l10n.factbookBack,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  topic.title,
                  style: readerBodyStyle(size: 24)
                      .copyWith(fontWeight: FontWeight.w700, height: 1.25),
                ),
                if (topic.summary != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    topic.summary!,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: kTextSecondary,
                    ),
                  ),
                ],
                if (topic.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tag in topic.tags)
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
                          sectionProvider((kFactbookResourceId, topic.id)),
                        ),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                  data: (section) {
                    if (section == null) {
                      return Text(
                        l10n.factbookLoadError,
                        style: const TextStyle(fontSize: 13),
                      );
                    }
                    final blocks = [...section.blocks];
                    if (blocks.isNotEmpty &&
                        blocks.first is HeadingBlock &&
                        (blocks.first as HeadingBlock).text == topic.title) {
                      blocks.removeAt(0);
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionBlocksView(
                          blocks: blocks,
                          onNavigate: _openReference,
                        ),
                        if (topic.references.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text(
                            l10n.factbookReferences,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final reference in topic.references)
                                ActionChip(
                                  key: ValueKey(
                                    'factbook-reference-$reference',
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  label: Text(
                                    displayFromCanonical(
                                      reference,
                                      lang: context.l10nLang,
                                    ),
                                    style: const TextStyle(fontSize: 11.5),
                                  ),
                                  onPressed: () => _openReference(reference),
                                ),
                            ],
                          ),
                        ],
                        if (topic.related.isNotEmpty) ...[
                          const SizedBox(height: 22),
                          Text(
                            l10n.factbookRelated,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final id in topic.related)
                                if (topics
                                        .where((item) => item.id == id)
                                        .firstOrNull
                                    case final related?)
                                  ActionChip(
                                    key: ValueKey('factbook-related-$id'),
                                    visualDensity: VisualDensity.compact,
                                    avatar: const Icon(
                                      Icons.topic_outlined,
                                      size: 14,
                                    ),
                                    label: Text(
                                      related.title,
                                      style: const TextStyle(fontSize: 11.5),
                                    ),
                                    onPressed: () => _select(related),
                                  ),
                            ],
                          ),
                        ],
                      ],
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
