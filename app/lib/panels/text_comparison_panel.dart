/// Comparación de textos (M5).
///
/// Referencia + conjunto configurable de versiones. Cada versículo muestra
/// una fila por versión (chip + texto) con el porcentaje en línea y las
/// palabras divergentes en azul, precedidas por un circulito rojo, como en el
/// original. El porcentaje se omite entre versiones de idiomas distintos.
library;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/catalog_gateway.dart';
import '../catalog/catalog_models.dart';
import '../catalog/document_models.dart';
import '../catalog/document_repository.dart';
import '../core/localization.dart';
import '../core/theme.dart';
import '../reader/reader_style.dart';
import '../references/reference_parser.dart';
import '../workspace/models.dart';
import '../workspace/workspace_controller.dart';
import 'section_view.dart';
import 'text_diff.dart';

/// Rojo del circulito que abre cada tramo de palabras cambiado.
const _diffMarker = Color(0xFFCC3333);

/// Biblias disponibles para comparar (servicio con respaldo local).
final bibleVersionsProvider = FutureProvider<List<ResourceSummary>>((
  ref,
) async {
  final listing = await ref
      .watch(catalogGatewayProvider)
      .listResources(type: 'bible', pageSize: 50, sort: 'title');
  return listing.items;
});

class TextComparisonPanel extends ConsumerStatefulWidget {
  const TextComparisonPanel({super.key, required this.tile, required this.tab});

  final WorkspaceTile tile;
  final WorkspaceTab tab;

  @override
  ConsumerState<TextComparisonPanel> createState() =>
      _TextComparisonPanelState();
}

class _TextComparisonPanelState extends ConsumerState<TextComparisonPanel> {
  late final TextEditingController _controller;
  final ScrollController _scrollController = ScrollController();
  late ParsedReference _reference;
  List<String>? _selectedVersions;

  final List<String> _history = [];
  int _historyIndex = -1;

  @override
  void initState() {
    super.initState();
    _reference =
        parseReference(widget.tab.reference ?? '') ??
        parseReference('JHN.1.1')!;
    _controller = TextEditingController(text: _reference.canonical);
    _history.add(_reference.canonical);
    _historyIndex = 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ navegación

  void _apply(ParsedReference reference, {required bool record}) {
    setState(() {
      _reference = reference;
      _controller.text = displayFromCanonical(
        reference.canonical,
        lang: context.l10nLang,
      );
    });
    if (!record) return;
    if (_historyIndex >= 0 && _historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    if (_history.isEmpty || _history.last != reference.canonical) {
      _history.add(reference.canonical);
    }
    _historyIndex = _history.length - 1;
    ref
        .read(workspaceProvider.notifier)
        .navigateTabReference(
          tileId: widget.tile.id,
          tabId: widget.tab.id,
          reference: reference.canonical,
        );
  }

  void _submit() {
    final parsed = parseReference(_controller.text);
    if (parsed == null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(context.l10n.compareInvalidReference),
            duration: const Duration(seconds: 2),
          ),
        );
      return;
    }
    _apply(parsed, record: true);
  }

  void _historyGo(int index) {
    if (index < 0 || index >= _history.length) return;
    final parsed = parseReference(_history[index]);
    if (parsed == null) return;
    _historyIndex = index;
    _apply(parsed, record: false);
  }

  void _openVerse(int verse) {
    final canonical = '${_reference.bookCode}.${_reference.chapter}.$verse';
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

  // ------------------------------------------------------------- versiones

  List<String> _effectiveVersions(List<ResourceSummary> available) {
    final ids = available.map((resource) => resource.id).toList();
    final selected = _selectedVersions;
    if (selected == null) return ids.take(5).toList();
    final filtered = selected.where(ids.contains).toList();
    return filtered.isEmpty ? ids.take(1).toList() : filtered;
  }

  void _setVersions(List<String> versions) {
    setState(() => _selectedVersions = [...versions]);
  }

  String _versionLabel(ResourceSummary resource) =>
      resource.abbrev ?? resource.title;

  // -------------------------------------------------------------- construir

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final asyncVersions = ref.watch(bibleVersionsProvider);
    final available = asyncVersions.asData?.value ?? const <ResourceSummary>[];
    final effective = _effectiveVersions(available);
    final baseId = effective.isEmpty
        ? kDefaultBibleResourceId
        : effective.first;

    final docs = <String, AsyncValue<BookDocument>>{
      for (final id in effective)
        id: ref.watch(bookDocumentProvider((id, _reference.bookCode))),
    };
    final baseChapter = docs[baseId]?.asData?.value.chapter(_reference.chapter);
    final verses = baseChapter == null
        ? const <Verse>[]
        : _versesOf(baseChapter);
    final byVersion = <String, Map<int, String>>{
      for (final id in effective)
        id: _verseTexts(docs[id]?.asData?.value.chapter(_reference.chapter)),
    };
    // El porcentaje solo tiene sentido entre versiones del mismo idioma (el
    // original lo omite, p. ej., en la fila ESV de una base española).
    final languages = <String, String?>{
      for (final resource in available) resource.id: resource.language,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToolbar(l10n, available, effective, baseId),
        const Divider(height: 1),
        if (effective.length < 2)
          Container(
            key: const ValueKey('compare-single-version'),
            width: double.infinity,
            color: kFieldFill,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Text(
              l10n.compareSingleVersion,
              style: TextStyle(fontSize: 11.5, color: kTextSecondary),
            ),
          ),
        Expanded(
          child: asyncVersions.isLoading && available.isEmpty
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _buildBody(l10n, docs, effective, byVersion, verses, languages),
        ),
      ],
    );
  }

  Widget _buildToolbar(
    AppLocalizations l10n,
    List<ResourceSummary> available,
    List<String> effective,
    String baseId,
  ) {
    final canBack = _historyIndex > 0;
    final canForward =
        _historyIndex >= 0 && _historyIndex < _history.length - 1;

    final referenceField = TextField(
      key: const ValueKey('compare-reference'),
      controller: _controller,
      onSubmitted: (_) => _submit(),
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: l10n.compareReferenceHint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
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
    );

    final language =
        available
            .where((resource) => resource.id == baseId)
            .firstOrNull
            ?.language ??
        'es';

    final versionButton = _VersionButton(
      available: available,
      selected: effective,
      label: available.isEmpty
          ? l10n.compareVersions
          : available
                .where((resource) => effective.contains(resource.id))
                .map(_versionLabel)
                .join(', '),
      onChanged: _setVersions,
      onOpenCatalog: () {
        ref
            .read(workspaceProvider.notifier)
            .openTab(const TabSpec(kind: PanelKind.library));
      },
    );

    final history = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const ValueKey('compare-back'),
          iconSize: 17,
          tooltip: l10n.searchBack,
          onPressed: canBack ? () => _historyGo(_historyIndex - 1) : null,
          icon: const Icon(Icons.arrow_back),
        ),
        IconButton(
          key: const ValueKey('compare-forward'),
          iconSize: 17,
          tooltip: l10n.readerForward,
          onPressed: canForward ? () => _historyGo(_historyIndex + 1) : null,
          icon: const Icon(Icons.arrow_forward),
        ),
      ],
    );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: kBorder),
          ),
          child: Text(
            language,
            style: TextStyle(fontSize: 10.5, color: kTextSecondary),
          ),
        ),
        PopupMenuButton<int>(
          key: const ValueKey('compare-menu'),
          tooltip: l10n.panelCommands,
          position: PopupMenuPosition.under,
          onSelected: (value) {
            if (value == 0) _copyComparison();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 0,
              height: 34,
              child: Row(
                children: [
                  Icon(
                    Icons.copy_all_outlined,
                    size: 16,
                    color: kTextSecondary,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    l10n.compareCopy,
                    style: const TextStyle(fontSize: 13.5),
                  ),
                ],
              ),
            ),
          ],
          iconSize: 19,
          icon: const Icon(Icons.more_vert),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 470) {
            return Column(
              children: [
                Row(
                  children: [
                    history,
                    const SizedBox(width: 2),
                    Expanded(child: referenceField),
                    actions,
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const SizedBox(width: 4),
                    Expanded(child: versionButton),
                  ],
                ),
              ],
            );
          }
          return Row(
            children: [
              history,
              const SizedBox(width: 2),
              SizedBox(width: 190, child: referenceField),
              const SizedBox(width: 6),
              Expanded(child: versionButton),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(
    AppLocalizations l10n,
    Map<String, AsyncValue<BookDocument>> docs,
    List<String> effective,
    Map<String, Map<int, String>> byVersion,
    List<Verse> verses,
    Map<String, String?> languages,
  ) {
    if (effective.isEmpty) {
      return SectionEmptyState(
        icon: Icons.compare_arrows,
        title: l10n.compareNoVersions,
        detail: l10n.compareSingleVersion,
      );
    }
    final baseId = effective.first;
    final baseLoaded = docs[baseId]?.asData?.value;
    if (docs[baseId]?.hasError == true) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.compareLoadError, style: const TextStyle(fontSize: 13.5)),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => ref.invalidate(
                bookDocumentProvider((baseId, _reference.bookCode)),
              ),
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }
    if (baseLoaded == null) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (verses.isEmpty) {
      return SectionEmptyState(
        icon: Icons.menu_book_outlined,
        title: l10n.compareNoChapter,
        detail: displayFromCanonical(
          '${_reference.bookCode}.${_reference.chapter}',
          lang: context.l10nLang,
        ),
      );
    }

    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        key: const ValueKey('compare-body'),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayFromCanonical(
                '${_reference.bookCode}.${_reference.chapter}',
                lang: context.l10nLang,
              ),
              style: readerBodyStyle(size: 23)
                  .copyWith(fontWeight: FontWeight.w700, height: 1.2),
            ),
            const SizedBox(height: 3),
            Text(
              l10n.compareVersionsCount(effective.length),
              style: TextStyle(fontSize: 11.5, color: kTextSecondary),
            ),
            const SizedBox(height: 14),
            for (final verse in verses) ...[
              _buildVerse(l10n, verse, effective, byVersion, baseId, languages),
              const SizedBox(height: 18),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVerse(
    AppLocalizations l10n,
    Verse verse,
    List<String> effective,
    Map<String, Map<int, String>> byVersion,
    String baseId,
    Map<String, String?> languages,
  ) {
    final reference = '${_reference.bookCode}.${_reference.chapter}.${verse.n}';
    final baseText = byVersion[baseId]?[verse.n] ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          key: ValueKey('compare-verse-${verse.n}'),
          onTap: () => _openVerse(verse.n),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Text(
              displayFromCanonical(reference, lang: context.l10nLang),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: kAccent,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        for (final id in effective)
          _buildVersionRow(
            l10n,
            id,
            byVersion[id]?[verse.n],
            baseText,
            showDiff: _sameLanguage(languages[baseId], languages[id]),
          ),
      ],
    );
  }

  /// El porcentaje solo se muestra entre versiones del mismo idioma.
  bool _sameLanguage(String? base, String? other) =>
      base == null || other == null || base == other;

  Widget _buildVersionRow(
    AppLocalizations l10n,
    String versionId,
    String? text,
    String baseText, {
    required bool showDiff,
  }) {
    final shortId = versionId.split('.').last.toUpperCase();
    if (text == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 66,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  shortId,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: kTextSecondary,
                    height: 1.3,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Text(
                l10n.compareVersionUnavailable,
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: kTextSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }
    final isBase = identical(text, baseText) || text == baseText;
    // Entre idiomas distintos no se calcula diff: el original deja el texto
    // normal, sin resaltado ni porcentaje (la comparación no es significativa).
    final diff = (isBase || !showDiff) ? null : compareWords(baseText, text);
    final words = splitWords(text);
    final spans = <InlineSpan>[];
    // El original marca la primera palabra de cada tramo cambiado con un
    // circulito rojo (superíndice) y tiñe de azul el tramo completo.
    var inRun = false;
    for (var i = 0; i < words.length; i++) {
      final changed =
          diff != null && i < diff.changed.length && diff.changed[i];
      if (changed && !inRun) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: SizedBox(
              width: 5,
              height: 5,
              // El circulito del original va sobre la primera letra del tramo;
              // se desplaza para acercarlo sin mover el texto.
              child: Transform.translate(
                offset: const Offset(2, 2),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _diffMarker, width: 1),
                  ),
                ),
              ),
            ),
          ),
        );
      }
      inRun = changed;
      spans.add(
        TextSpan(
          text: words[i],
          style: changed ? const TextStyle(color: kAccent) : null,
        ),
      );
    }
    // Dos columnas: chip de versión (ancho fijo) + texto; el porcentaje va en
    // línea al final, como el original (no en una tercera columna). Es un
    // widget para que no se parta entre líneas.
    if (showDiff) {
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              l10n.compareDifference(diff?.percent ?? 0),
              style: TextStyle(fontSize: 11, color: kTextSecondary),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 66,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                shortId,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: kAccent,
                  letterSpacing: 0.2,
                  height: 1.3,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(children: spans),
              style: readerBodyStyle(size: 14).copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- datos

  List<Verse> _versesOf(ChapterDocument chapter) {
    final verses = <Verse>[];
    for (final block in chapter.blocks) {
      if (block is! VerseGroupBlock) continue;
      for (final verse in block.verses) {
        if (verse.n > 0) verses.add(verse);
      }
    }
    return verses;
  }

  Map<int, String> _verseTexts(ChapterDocument? chapter) {
    if (chapter == null) return const {};
    final map = <int, String>{};
    for (final block in chapter.blocks) {
      if (block is! VerseGroupBlock) continue;
      for (final verse in block.verses) {
        if (verse.n == 0) continue;
        final buffer = StringBuffer();
        for (final inline in verse.inlines) {
          switch (inline) {
            case TextInline text:
              buffer.write(text.text);
            case LineInline _:
              buffer.write(' ');
            case FootnoteRef _:
            case XrefLink _:
              break;
          }
        }
        map[verse.n] = buffer.toString().trim();
      }
    }
    return map;
  }

  Future<void> _copyComparison() async {
    final l10n = context.l10n;
    final buffer = StringBuffer()
      ..writeln(
        displayFromCanonical(
          '${_reference.bookCode}.${_reference.chapter}',
          lang: context.l10nLang,
        ),
      );
    final docs = <String, AsyncValue<BookDocument>>{
      for (final id in _effectiveVersions(
        ref.read(bibleVersionsProvider).asData?.value ??
            const <ResourceSummary>[],
      ))
        id: ref.read(bookDocumentProvider((id, _reference.bookCode))),
    };
    final effective = _effectiveVersions(
      ref.read(bibleVersionsProvider).asData?.value ??
          const <ResourceSummary>[],
    );
    final baseId = effective.isEmpty
        ? kDefaultBibleResourceId
        : effective.first;
    final byVersion = <String, Map<int, String>>{
      for (final id in effective)
        id: _verseTexts(docs[id]?.asData?.value.chapter(_reference.chapter)),
    };
    final verses = _verseTexts(
      docs[baseId]?.asData?.value.chapter(_reference.chapter),
    );
    for (final entry in verses.entries) {
      buffer.writeln();
      buffer.writeln(
        displayFromCanonical(
          '${_reference.bookCode}.${_reference.chapter}.${entry.key}',
          lang: context.l10nLang,
        ),
      );
      for (final id in effective) {
        buffer.writeln(
          '${id.split('.').last.toUpperCase()}: '
          '${byVersion[id]?[entry.key] ?? ''}',
        );
      }
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.compareCopied),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

/// Botón con la lista de versiones y sus casillas (multi-selección).
class _VersionButton extends StatefulWidget {
  const _VersionButton({
    required this.available,
    required this.selected,
    required this.label,
    required this.onChanged,
    required this.onOpenCatalog,
  });

  final List<ResourceSummary> available;
  final List<String> selected;
  final String label;
  final ValueChanged<List<String>> onChanged;
  final VoidCallback onOpenCatalog;

  @override
  State<_VersionButton> createState() => _VersionButtonState();
}

class _VersionButtonState extends State<_VersionButton> {
  late List<String> _selection = [...widget.selected];

  @override
  void didUpdateWidget(covariant _VersionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.selected, oldWidget.selected)) {
      _selection = [...widget.selected];
    }
  }

  void _toggle(String id) {
    final next = [..._selection];
    if (next.contains(id)) {
      if (next.length == 1) return;
      next.remove(id);
    } else {
      next.add(id);
    }
    setState(() => _selection = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<void>(
      key: const ValueKey('compare-versions-button'),
      tooltip: l10n.compareVersions,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        PopupMenuItem<void>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: StatefulBuilder(
            builder: (context, setMenuState) => SizedBox(
              width: 280,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                    child: Text(
                      l10n.compareVersions,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (widget.available.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
                      child: Text(
                        l10n.compareNoVersions,
                        style: TextStyle(fontSize: 12.5, color: kTextSecondary),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 290),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final resource in widget.available)
                              CheckboxListTile(
                                key: ValueKey('compare-version-${resource.id}'),
                                value: _selection.contains(resource.id),
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: Text(
                                  resource.abbrev ?? resource.title,
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                                subtitle: Text(
                                  resource.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10.5),
                                ),
                                onChanged: (checked) {
                                  _toggle(resource.id);
                                  setMenuState(() {});
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  const Divider(height: 1),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: const ValueKey('compare-open-library'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onOpenCatalog();
                      },
                      child: Text(
                        l10n.compareAddVersions,
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: kBorder),
          color: kPanelBg,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: kTextPrimary),
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 18, color: kTextSecondary),
          ],
        ),
      ),
    );
  }
}
