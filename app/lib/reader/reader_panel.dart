/// Panel del lector.
///
/// Estructura (fiel al original, ver la evidencia de reconocimiento):
/// - Toolbar primaria: atrás · cambiar libro · caja de referencia · modos.
/// - Toolbar secundaria según el modo: Inicio (Índice · Historial · Artículo ·
///   ◀▶ · Conjunto de vínculos · Análisis · Información), Formato (Marcadores ·
///   Reformato) y Vista (Vista paginada · Barra de ubicación · Zoom · Pantalla
///   completa).
/// - Barra de ubicación descartable (View → Locator bar).
/// - Cuerpo: capítulos con versículos numerados (ReaderBody).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/catalog_gateway.dart';
import '../catalog/catalog_models.dart';
import '../catalog/document_models.dart';
import '../catalog/document_repository.dart';
import '../core/localization.dart';
import '../core/resource_colors.dart';
import '../core/theme.dart';
import '../favorites/favorites_controller.dart';
import '../favorites/favorites_models.dart';
import '../notes/notes_controller.dart';
import '../notes/notes_models.dart';
import '../notes/notes_query.dart';
import '../notes/notes_ui.dart';
import '../notes/reader_notes_view.dart';
import '../notes/selection_resolver.dart';
import '../references/citation.dart';
import '../references/reference_parser.dart';
import '../workspace/models.dart';
import '../workspace/panel_fullscreen.dart';
import '../workspace/workspace_controller.dart';
import 'change_book_dialog.dart';
import 'contents_drawer.dart';
import 'insights_drawer.dart';
import 'reader_body.dart';
import 'reader_display_flyouts.dart';
import 'reader_search_view.dart';
import 'related_content.dart';

class ReaderPanel extends ConsumerStatefulWidget {
  const ReaderPanel({super.key, required this.tile, required this.tab});

  final WorkspaceTile tile;
  final WorkspaceTab tab;

  /// Recurso que muestra el panel (de la pestaña; RV1909 por defecto).
  String get resourceId => tab.resourceId ?? kDefaultBibleResourceId;

  static const _defaultReference = 'GEN.1.1';

  @override
  ConsumerState<ReaderPanel> createState() => _ReaderPanelState();
}

class _ReaderPanelState extends ConsumerState<ReaderPanel> {
  final _refController = TextEditingController();
  final _refFocus = FocusNode();

  bool _contentsOpen = false;

  /// Drawer derecho abierto: `ideas` (💡) | `info` (ⓘ) | `null` (M6.1).
  String? _rightDrawer;
  bool _refInvalid = false;

  /// Modo activo de la toolbar primaria: `inicio` | `buscar` | `notas` |
  /// `formato` | `vista`.
  String _mode = 'inicio';

  /// Flyout abierto de Formato/Vista: `marcadores` | `reformato` | `paginada`.
  String? _flyout;

  /// Nota que el modo «Notas» debe abrir en el editor (M4).
  String? _notesFocusNoteId;

  // Búsqueda dentro del panel (modo «Buscar»).
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  SearchResult? _searchResult;
  Object? _searchError;
  bool _searchLoading = false;
  int _searchSeq = 0;

  String get _reference =>
      widget.tab.reference ?? ReaderPanel._defaultReference;

  TabDisplay get _display => widget.tab.display;

  @override
  void initState() {
    super.initState();
    _refController.text = displayFromCanonical(_reference);
    _refFocus.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant ReaderPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tab.reference != oldWidget.tab.reference) _syncReferenceText();
    if (widget.resourceId != oldWidget.resourceId) {
      // Otro recurso en la misma pestaña (cambiar libro): la búsqueda anterior
      // ya no aplica.
      _searchSeq++;
      _searchResult = null;
      _searchError = null;
      _searchLoading = false;
      _searchController.clear();
      _mode = 'inicio';
      _flyout = null;
    }
  }

  @override
  void dispose() {
    _refController.dispose();
    _refFocus.removeListener(_onFocusChange);
    _refFocus.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_refFocus.hasFocus) _syncReferenceText();
  }

  void _syncReferenceText() {
    if (_refFocus.hasFocus) return;
    final parsed = parseReference(_reference);
    _refController.text = parsed == null
        ? _reference
        : parsed.displayIn(context.l10nLang);
    if (_refInvalid) setState(() => _refInvalid = false);
  }

  // ------------------------------------------------------------ navegación

  void _navigate(String reference) {
    ref
        .read(workspaceProvider.notifier)
        .navigateTabReference(
          tileId: widget.tile.id,
          tabId: widget.tab.id,
          reference: reference,
        );
  }

  void _submitReference(String value) {
    final parsed = parseReference(value);
    if (parsed == null) {
      setState(() => _refInvalid = true);
      return;
    }
    setState(() => _refInvalid = false);
    if (parsed.canonical != _reference) _navigate(parsed.canonical);
    _refFocus.unfocus();
  }

  bool get _canGoBack => widget.tab.historyIndex > 0;

  bool get _canGoForward =>
      widget.tab.historyIndex >= 0 &&
      widget.tab.historyIndex < widget.tab.history.length - 1;

  void _historyGo(int index) {
    ref
        .read(workspaceProvider.notifier)
        .historyGo(tileId: widget.tile.id, tabId: widget.tab.id, index: index);
  }

  Future<void> _openChangeBook() async {
    final selected = await showDialog<ResourceSummary>(
      context: context,
      builder: (_) => ChangeBookDialog(currentResourceId: widget.resourceId),
    );
    if (selected == null || selected.id == widget.resourceId) return;
    ref
        .read(workspaceProvider.notifier)
        .switchBibleResource(
          tileId: widget.tile.id,
          tabId: widget.tab.id,
          resourceId: selected.id,
          title: selected.abbrev ?? selected.title,
        );
  }

  void _stepChapter(DocumentManifest manifest, {required bool forward}) {
    final parsed = parseReference(_reference);
    if (parsed == null) return;
    final location = forward
        ? manifest.nextLocation(parsed.bookCode, parsed.chapter)
        : manifest.previousLocation(parsed.bookCode, parsed.chapter);
    if (location == null) return;
    _navigate('${location.book}.${location.chapter}');
  }

  /// Artículo ▾: encabezados del documento si los hay; la RV1909 no trae
  /// encabezados, así que cae a capítulo siguiente/anterior (M6.1).
  Future<void> _stepArticle(
    DocumentManifest manifest, {
    required bool forward,
  }) async {
    final parsed = parseReference(_reference);
    if (parsed == null) return;
    final articles = await _articleLocations(parsed.bookCode);
    if (articles.isEmpty) {
      _stepChapter(manifest, forward: forward);
      return;
    }
    final chapter = parsed.chapter;
    final verse = parsed.verseStart ?? 0;
    _ArticleLoc? target;
    if (forward) {
      for (final loc in articles) {
        if (loc.chapter > chapter ||
            (loc.chapter == chapter && loc.verse > verse)) {
          target = loc;
          break;
        }
      }
    } else {
      for (final loc in articles.reversed) {
        if (loc.chapter < chapter ||
            (loc.chapter == chapter && loc.verse < verse)) {
          target = loc;
          break;
        }
      }
    }
    if (target == null) {
      _stepChapter(manifest, forward: forward);
      return;
    }
    _navigate(
      target.verse > 0
          ? '${parsed.bookCode}.${target.chapter}.${target.verse}'
          : '${parsed.bookCode}.${target.chapter}',
    );
  }

  Future<List<_ArticleLoc>> _articleLocations(String bookCode) async {
    BookDocument document;
    try {
      document = await ref.read(
        bookDocumentProvider((widget.resourceId, bookCode)).future,
      );
    } on Object {
      return const [];
    }
    final locations = <_ArticleLoc>[];
    for (final chapter in document.chapters) {
      var headingPending = false;
      for (final block in chapter.blocks) {
        if (block is HeadingBlock) {
          headingPending = true;
        } else if (block is VerseGroupBlock) {
          final first = block.verses
              .firstWhere(
                (v) => v.n > 0,
                orElse: () => const Verse(n: 0, inlines: []),
              )
              .n;
          if (headingPending && first > 0) {
            locations.add(_ArticleLoc(chapter.n, first));
            headingPending = false;
          }
        }
      }
    }
    return locations;
  }

  /// Abre una sección propia (Factbook / devocional / comentario) citada por
  /// la referencia.
  void _openRelatedSection(RelatedSection section) {
    final ctrl = ref.read(workspaceProvider.notifier);
    if (section.resourceId == 'commentary.matthew-henry-concise') {
      if (ctrl.openInResource(
        resourceId: section.resourceId,
        reference: section.section.id,
        kind: PanelKind.resource,
      )) {
        return;
      }
      ctrl.openTab(
        TabSpec(
          kind: PanelKind.resource,
          title: section.section.title,
          reference: section.section.id,
          resourceId: section.resourceId,
          resourceType: 'commentary',
        ),
      );
      return;
    }
    final kind = section.resourceId == 'devotional.daily'
        ? PanelKind.devotional
        : PanelKind.factbook;
    ctrl.openTab(TabSpec(kind: kind, reference: section.section.id));
  }

  Widget _buildRightDrawer() {
    if (_rightDrawer == 'info') {
      return InfoDrawer(
        resourceId: widget.resourceId,
        onClose: () => setState(() => _rightDrawer = null),
      );
    }
    return InsightsDrawer(
      resourceId: widget.resourceId,
      reference: _reference,
      onClose: () => setState(() => _rightDrawer = null),
      onNavigate: _navigate,
      onOpenSection: _openRelatedSection,
    );
  }

  // ------------------------------------------------- Formato y Vista (M3)

  void _updateDisplay(TabDisplay display) {
    ref
        .read(workspaceProvider.notifier)
        .updateTabDisplay(
          tileId: widget.tile.id,
          tabId: widget.tab.id,
          display: display,
        );
  }

  void _setMode(String mode) {
    setState(() {
      _mode = mode;
      _flyout = null;
      _rightDrawer = null;
    });
  }

  void _toggleFlyout(String flyout) {
    setState(() => _flyout = _flyout == flyout ? null : flyout);
  }

  void _togglePagedView() {
    final next = _display.copyWith(paged: !_display.paged);
    _updateDisplay(next);
    if (next.paged && _mode != 'vista') setState(() => _mode = 'vista');
  }

  void _zoomBy(int delta) => _setZoom(_display.zoom + delta);

  void _setZoom(int value) {
    final zoom = value.clamp(50, 300);
    if (zoom == _display.zoom) return;
    _updateDisplay(_display.copyWith(zoom: zoom));
  }

  void _toggleFullScreen() {
    ref.read(panelFullscreenProvider.notifier).toggle(widget.tab.id);
  }

  // ------------------------------------------------------------- copias

  String _displayRef() {
    final parsed = parseReference(_reference);
    return parsed == null ? _reference : parsed.displayIn(context.l10nLang);
  }

  String _citation({required bool hyperlink}) {
    final state = ref.read(workspaceProvider);
    // Título y sigla del recurso (manifiesto); si aún no está cargado, el de
    // la pestaña.
    final manifest = ref.read(manifestProvider(widget.resourceId)).value;
    return formatCitation(
      reference: _displayRef(),
      title: manifest?.title ?? widget.tab.title,
      abbrev: manifest?.abbrev ?? widget.tab.title,
      style: state.citationStyle,
      hyperlink: hyperlink && state.hyperlinkCitations,
      canonical: parseReference(_reference)?.canonical,
    );
  }

  Future<void> _copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(context.l10n.readerCopied),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Copia el pasaje tal como se ve (capítulo actual) más la cita si Ajustes
  /// lo pide (8.6 «Copiar la cita con el texto»).
  Future<void> _copyPassageAndCitation() async {
    final parsed = parseReference(_reference);
    if (parsed == null) return;
    final state = ref.read(workspaceProvider);
    final buffer = StringBuffer();
    try {
      final book = await ref
          .read(documentRepositoryProvider)
          .loadBook(widget.resourceId, parsed.bookCode);
      final chapter = book.chapter(parsed.chapter);
      if (chapter != null) {
        for (final block in chapter.blocks) {
          final text = _plainBlock(block);
          if (text.isEmpty) continue;
          buffer
            ..write(text)
            ..write('\n\n');
        }
      }
    } catch (_) {
      // Sin texto: se copia solo la cita.
    }
    final reference = _displayRef();
    buffer.write(reference);
    if (state.copyCitations) {
      buffer
        ..write('\n')
        ..write(_citation(hyperlink: true));
    }
    await _copyText(buffer.toString().trim());
  }

  String _plainBlock(BookBlock block) {
    switch (block) {
      case HeadingBlock h:
        return h.text;
      case ChapterNumberBlock c:
        return '${c.value}';
      case RuleBlock _:
        return '';
      case MapBlock map:
        return [map.title, if (map.caption != null) map.caption!].join('. ');
      case VerseGroupBlock g:
        final buffer = StringBuffer();
        for (final verse in g.verses) {
          if (buffer.isNotEmpty) buffer.write(' ');
          if (verse.n != 0) buffer.write('${verse.n} ');
          for (final inline in verse.inlines) {
            switch (inline) {
              case TextInline t:
                buffer.write(t.text);
              case LineInline _:
                buffer.write(' ');
              case FootnoteRef _:
              case XrefLink _:
                break;
            }
          }
        }
        return buffer.toString().trim();
    }
  }

  // ------------------------------------------------- búsqueda en el panel

  void _openSearchMode() {
    setState(() => _mode = 'buscar');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  Future<void> _runPanelSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final seq = ++_searchSeq;
    setState(() {
      _searchLoading = true;
      _searchError = null;
    });
    try {
      final result = await ref
          .read(catalogGatewayProvider)
          .search(query: trimmed, resource: widget.resourceId, pageSize: 50);
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _searchResult = result;
        _searchLoading = false;
      });
    } catch (error) {
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _searchError = error;
        _searchLoading = false;
      });
    }
  }

  void _openSearchHit(SearchHit hit) {
    // Navega al versículo y vuelve a Inicio; los resultados quedan guardados
    // por si se quiere seguir recorriendo la lista.
    _navigate(hit.ref);
    setState(() => _mode = 'inicio');
  }

  // ------------------------------------------------------------------ notas

  /// Anclaje de una nota nueva: la referencia actual del panel.
  NoteAnchor? _currentAnchor() {
    final parsed = parseReference(_reference);
    if (parsed == null) return null;
    return NoteAnchor(
      resourceId: widget.resourceId,
      reference: parsed.canonical,
      bookCode: parsed.bookCode,
      chapter: parsed.chapter,
      verse: parsed.verseStart,
      verseEnd: parsed.verseEnd,
    );
  }

  void _openNotes({String? noteId}) {
    setState(() {
      _mode = 'notas';
      _flyout = null;
      if (noteId != null) _notesFocusNoteId = noteId;
    });
  }

  NoteAnchor _anchorForMatch(SelectionMatch match, String quote) => NoteAnchor(
    resourceId: widget.resourceId,
    reference: '${match.bookCode}.${match.chapter}.${match.verse}',
    bookCode: match.bookCode,
    chapter: match.chapter,
    verse: match.verse,
    startOffset: match.start,
    endOffset: match.end,
    quote: quote,
  );

  /// Nota creada desde una selección del texto (se abre su editor).
  void _createNoteFromSelection(SelectionMatch? match, String quote) {
    final anchors = <NoteAnchor>[];
    if (match != null) {
      anchors.add(_anchorForMatch(match, quote));
    } else {
      final current = _currentAnchor();
      if (current != null) {
        anchors.add(
          NoteAnchor(
            resourceId: current.resourceId,
            reference: current.reference,
            bookCode: current.bookCode,
            chapter: current.chapter,
            verse: current.verse,
            verseEnd: current.verseEnd,
            quote: quote,
          ),
        );
      }
    }
    final id = ref.read(notesProvider.notifier).createNote(anchors: anchors);
    if (!mounted) return;
    _openNotes(noteId: id);
  }

  /// Resaltados vigentes que se solapan con la selección.
  List<Note> _highlightsForMatch(SelectionMatch match) => highlightsForRange(
    ref.read(notesProvider).notes,
    resourceId: widget.resourceId,
    bookCode: match.bookCode,
    chapter: match.chapter,
    verse: match.verse,
    start: match.start,
    end: match.end,
  );

  /// Resaltado creado o actualizado desde una selección (sin abrir el editor).
  ///
  /// Si la selección ya tiene resaltados, cambia su color y estilo en vez de
  /// apilar otro encima (el original cambia el resaltado existente).
  void _createHighlightFromSelection(
    SelectionMatch match,
    String quote,
    String color,
    String style,
  ) {
    final notifier = ref.read(notesProvider.notifier);
    final existing = _highlightsForMatch(match);
    if (existing.isNotEmpty) {
      for (final note in existing) {
        notifier.updateNote(note.id, color: color, style: style);
      }
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(context.l10n.readerHighlightUpdated),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    notifier.createHighlight(
      anchor: _anchorForMatch(match, quote),
      color: color,
      style: style,
    );
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(context.l10n.readerHighlightCreated),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Quita los resaltados que cubren la selección.
  void _removeHighlightFromSelection(SelectionMatch match) {
    final notifier = ref.read(notesProvider.notifier);
    final existing = _highlightsForMatch(match);
    if (existing.isEmpty) return;
    for (final note in existing) {
      notifier.purgeNote(note.id);
    }
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(context.l10n.readerHighlightRemoved),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Busca el texto seleccionado dentro del recurso.
  void _searchSelection(String text) {
    _searchController.text = text;
    _openSearchMode();
    _runPanelSearch(text);
  }

  /// Lista de notas de un versículo (marcador del texto).
  Future<void> _showVerseNotes(List<Note> notes) async {
    final l10n = context.l10n;
    final lang = context.l10nLang;
    final selected = await showDialog<Note>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(
          l10n.readerNoteMarker,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
        ),
        children: [
          for (final note in notes)
            SimpleDialogOption(
              key: Key('verse-note-option-${note.id}'),
              onPressed: () => Navigator.of(context).pop(note),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.headline.isEmpty ? l10n.noteKindNote : note.headline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kTextPrimary,
                    ),
                  ),
                  if (note.preview.isNotEmpty)
                    Text(
                      note.preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: kTextSecondary),
                    ),
                  if (note.mainAnchor?.reference != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        noteAnchorLabel(note.mainAnchor, lang: lang),
                        style: TextStyle(fontSize: 11.5, color: kTextSecondary),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
    if (selected == null || !mounted) return;
    _openNotes(noteId: selected.id);
  }

  // --------------------------------------------------------------- construir

  @override
  Widget build(BuildContext context) {
    final manifest = ref.watch(manifestProvider(widget.resourceId)).value;
    final limitedView = ref.watch(workspaceProvider).limitedView;
    final parsed = parseReference(_reference);
    final showLocationBar =
        _display.locationBar &&
        parsed != null &&
        _mode != 'buscar' &&
        _mode != 'formato' &&
        _mode != 'notas';

    return CallbackShortcuts(
      bindings: {
        // View → Paged view (Ctrl+Shift+P) y zoom del panel.
        const SingleActivator(
          LogicalKeyboardKey.keyP,
          shift: true,
          control: true,
        ): _togglePagedView,
        const SingleActivator(LogicalKeyboardKey.equal, control: true): () =>
            _zoomBy(10),
        const SingleActivator(LogicalKeyboardKey.minus, control: true): () =>
            _zoomBy(-10),
        const SingleActivator(LogicalKeyboardKey.digit0, control: true): () =>
            _setZoom(100),
      },
      child: Focus(
        // Los atajos de la Vista (Ctrl+Shift+P, Ctrl+±) requieren que el
        // panel tenga el foco al abrirse.
        autofocus: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPrimaryToolbar(),
            if (_mode != 'notas' && _display.secondaryToolbar)
              _buildSecondaryToolbar(manifest),
            if (showLocationBar) _buildLocationBar(parsed.bookCode, manifest),
            Expanded(
              child: MediaQuery(
                // Vista → Zoom (porcentaje del panel).
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(_display.zoom / 100)),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final drawerWidth = (constraints.maxWidth * 0.42).clamp(
                      220.0,
                      330.0,
                    );
                    final sideDrawerWidth = (constraints.maxWidth * 0.46).clamp(
                      230.0,
                      380.0,
                    );
                    return Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_flyout != null) setState(() => _flyout = null);
                          },
                          child: IndexedStack(
                            index: _mode == 'buscar'
                                ? 1
                                : (_mode == 'notas' ? 2 : 0),
                            sizing: StackFit.expand,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (_contentsOpen && manifest != null)
                                    SizedBox(
                                      width: drawerWidth,
                                      child: ContentsDrawer(
                                        manifest: manifest,
                                        currentBook: parsed?.bookCode ?? '',
                                        currentChapter: parsed?.chapter ?? 0,
                                        onSelectChapter: (code, chapter) =>
                                            _navigate('$code.$chapter'),
                                        onClose: () => setState(
                                          () => _contentsOpen = false,
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: ReaderBody(
                                      resourceId: widget.resourceId,
                                      reference: _reference,
                                      onNavigate: _navigate,
                                      display: _display,
                                      limitedView: limitedView,
                                      citationBuilder: () =>
                                          _citation(hyperlink: true),
                                      onNoteSelection: _createNoteFromSelection,
                                      onHighlightSelection:
                                          _createHighlightFromSelection,
                                      onRemoveHighlightSelection:
                                          _removeHighlightFromSelection,
                                      onSearchSelection: _searchSelection,
                                      onOpenVerseNotes: _showVerseNotes,
                                    ),
                                  ),
                                  if (_rightDrawer != null)
                                    SizedBox(
                                      width: sideDrawerWidth,
                                      child: _buildRightDrawer(),
                                    ),
                                ],
                              ),
                              ReaderSearchView(
                                resourceTitle: widget.tab.title,
                                controller: _searchController,
                                focusNode: _searchFocus,
                                onSubmit: _runPanelSearch,
                                onOpenHit: _openSearchHit,
                                loading: _searchLoading,
                                error: _searchError,
                                result: _searchResult,
                              ),
                              ReaderNotesView(
                                resourceId: widget.resourceId,
                                anchor: _currentAnchor(),
                                focusNoteId: _notesFocusNoteId,
                                onShowInReader: (note) {
                                  final reference = note.mainAnchor?.reference;
                                  if (reference == null) return;
                                  _navigate(reference);
                                  setState(() => _mode = 'inicio');
                                },
                              ),
                            ],
                          ),
                        ),
                        if (_flyout != null)
                          Positioned(top: 6, left: 6, child: _buildFlyout()),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlyout() {
    switch (_flyout) {
      case 'marcadores':
        return MarkersFlyout(
          display: _display,
          onChanged: _updateDisplay,
          onClose: () => setState(() => _flyout = null),
        );
      case 'paginada':
        return PagedViewFlyout(
          display: _display,
          onChanged: _updateDisplay,
          onClose: () => setState(() => _flyout = null),
        );
      default:
        return ReformatFlyout(
          display: _display,
          onChanged: _updateDisplay,
          onClose: () => setState(() => _flyout = null),
        );
    }
  }

  Widget _buildPrimaryToolbar() {
    final l10n = context.l10n;
    return Container(
      // Evidencia (settle_bible, 1440): las dos barras del lector miden 36 px.
      height: 36,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: l10n.readerBack,
                    iconSize: 18,
                    visualDensity: VisualDensity.compact,
                    onPressed: _canGoBack
                        ? () => _historyGo(widget.tab.historyIndex - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  if (_canGoForward)
                    IconButton(
                      tooltip: l10n.readerForward,
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _historyGo(widget.tab.historyIndex + 1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  const SizedBox(width: 2),
                  // Caja de referencia: en el original es **un solo campo gris**
                  // (sin borde) que empieza con la portada del recurso.
                  AnimatedBuilder(
                    animation: _refFocus,
                    builder: (context, _) => Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: kFieldFill,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _refInvalid
                              ? kError
                              : (_refFocus.hasFocus
                                    ? kAccent
                                    : Colors.transparent),
                        ),
                      ),
                      child: Row(
                        children: [
                          Tooltip(
                            message: l10n.readerChangeBook,
                            child: InkWell(
                              key: const ValueKey('reader-change-book'),
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(4),
                              ),
                              onTap: _openChangeBook,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 5,
                                  right: 1,
                                ),
                                child: Row(
                                  children: [
                                    _CoverChip(
                                      resourceId: widget.resourceId,
                                      width: 13,
                                      height: 16,
                                    ),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      size: 15,
                                      color: kTextSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(width: 1, height: 16, color: kBorder),
                          SizedBox(
                            width: 148,
                            child: TextField(
                              key: const ValueKey('reader-reference-box'),
                              controller: _refController,
                              focusNode: _refFocus,
                              textInputAction: TextInputAction.go,
                              onSubmitted: _submitReference,
                              onChanged: (_) {
                                if (_refInvalid) {
                                  setState(() => _refInvalid = false);
                                }
                              },
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 7,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _ModeButton(
                    key: const ValueKey('reader-mode-home'),
                    label: l10n.readerModeHome,
                    active: _mode == 'inicio',
                    onTap: () => _setMode('inicio'),
                  ),
                  _ModeButton(
                    label: l10n.readerModeSearch,
                    active: _mode == 'buscar',
                    tooltip: l10n.readerSearchInResource,
                    onTap: _openSearchMode,
                  ),
                  _ModeButton(
                    key: const ValueKey('reader-mode-notes'),
                    label: l10n.readerModeNotes,
                    active: _mode == 'notas',
                    tooltip: l10n.readerNotesView,
                    onTap: () => _openNotes(),
                  ),
                  _ModeButton(
                    key: const ValueKey('reader-mode-format'),
                    label: l10n.readerModeFormat,
                    active: _mode == 'formato',
                    onTap: () => _setMode('formato'),
                  ),
                  _ModeButton(
                    key: const ValueKey('reader-mode-view'),
                    label: l10n.readerModeView,
                    active: _mode == 'vista',
                    onTap: () => _setMode('vista'),
                  ),
                  PopupMenuButton<String>(
                    key: const ValueKey('reader-more-menu'),
                    tooltip: l10n.readerModeMore,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'reference',
                        height: 34,
                        child: Text(
                          l10n.readerCopyReference,
                          style: const TextStyle(fontSize: 13.5),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'citation',
                        height: 34,
                        child: Text(
                          l10n.readerCopyCitation,
                          style: const TextStyle(fontSize: 13.5),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'passage',
                        height: 34,
                        child: Text(
                          l10n.readerCopyPassageAndCitation,
                          style: const TextStyle(fontSize: 13.5),
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        enabled: false,
                        height: 34,
                        child: Text(
                          l10n.readerToolsSoon,
                          style: const TextStyle(fontSize: 13.5),
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'reference':
                          _copyText(_displayRef());
                        case 'citation':
                          _copyText(_citation(hyperlink: true));
                        case 'passage':
                          _copyPassageAndCitation();
                      }
                    },
                    child: _ModeButton(
                      label: l10n.readerModeMore,
                      trailingArrow: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _SecondaryToolbarToggle(
            visible: _display.secondaryToolbar,
            onTap: () => _updateDisplay(
              _display.copyWith(secondaryToolbar: !_display.secondaryToolbar),
            ),
          ),
          _PanelCommandsButton(tile: widget.tile, tab: widget.tab),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildSecondaryToolbar(DocumentManifest? manifest) {
    // Evidencia (settle_bible, 1440): 36 px; Análisis e Información van
    // anclados al borde derecho (en `home2`, 685 px, hay un hueco de ~117
    // CSS px entre «Link set» y «Insights»), el resto se desplaza si no cabe.
    // Adaptación propia: en paneles estrechos las etiquetas largas pasan a
    // icono + tooltip (el original directamente recorta).
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 800;
        return Container(
          height: 36,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: kBorder)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: switch (_mode) {
                    'formato' => _buildFormattingToolbar(),
                    'vista' => _buildViewToolbar(),
                    _ => _buildHomeToolbar(manifest, compact: compact),
                  },
                ),
              ),
              if (_mode != 'formato' && _mode != 'vista') ...[
                _ToolButton(
                  key: const ValueKey('reader-insights'),
                  icon: Icons.tips_and_updates_outlined,
                  label: context.l10n.readerInsights,
                  iconOnly: compact,
                  active: _rightDrawer == 'ideas',
                  pill: true,
                  tooltip: context.l10n.readerInsights,
                  onTap: () => setState(
                    () =>
                        _rightDrawer = _rightDrawer == 'ideas' ? null : 'ideas',
                  ),
                ),
                _ToolButton(
                  key: const ValueKey('reader-info'),
                  icon: Icons.info,
                  label: context.l10n.readerInfo,
                  iconOnly: compact,
                  active: _rightDrawer == 'info',
                  pill: true,
                  tooltip: context.l10n.readerInfo,
                  onTap: () => setState(
                    () => _rightDrawer = _rightDrawer == 'info' ? null : 'info',
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHomeToolbar(DocumentManifest? manifest, {bool compact = false}) {
    final l10n = context.l10n;
    return Row(
      children: [
        _ToolButton(
          icon: Icons.segment,
          label: l10n.readerContents,
          active: _contentsOpen,
          tooltip: l10n.readerContentsTooltip,
          onTap: () => setState(() => _contentsOpen = !_contentsOpen),
        ),
        _HistoryButton(
          history: widget.tab.history,
          historyIndex: widget.tab.historyIndex,
          onSelect: _historyGo,
          resourceLabel: widget.tab.title,
        ),
        // Separadores entre grupos, como el original.
        const _ToolDivider(),
        _ArticleButton(
          enabled: manifest != null,
          iconOnly: compact,
          onPrevious: manifest == null
              ? null
              : () => _stepArticle(manifest, forward: false),
          onNext: manifest == null
              ? null
              : () => _stepArticle(manifest, forward: true),
        ),
        IconButton(
          tooltip: l10n.readerPrevChapter,
          iconSize: 17,
          visualDensity: VisualDensity.compact,
          onPressed: manifest != null
              ? () => _stepChapter(manifest, forward: false)
              : null,
          icon: const Icon(Icons.keyboard_arrow_up),
        ),
        IconButton(
          tooltip: l10n.readerNextChapter,
          iconSize: 17,
          visualDensity: VisualDensity.compact,
          onPressed: manifest != null
              ? () => _stepChapter(manifest, forward: true)
              : null,
          icon: const Icon(Icons.keyboard_arrow_down),
        ),
        const _ToolDivider(),
        _buildLinkSetButton(compact),
        if (_originalResourceId() != null) ...[
          const _ToolDivider(),
          _ToolButton(
            key: const ValueKey('reader-original'),
            icon: Icons.auto_stories_outlined,
            label: l10n.readerOriginal,
            iconOnly: compact,
            tooltip: l10n.readerOriginalTooltip,
            onTap: () => _openOriginal(_originalResourceId()!),
          ),
        ],
      ],
    );
  }

  /// Recurso original correspondiente al libro actual, si la pestaña es una
  /// Biblia de traducción. Los propios originales no muestran el botón.
  String? _originalResourceId() {
    if (!widget.resourceId.startsWith('bible.')) return null;
    if (widget.resourceId == 'bible.tahot' ||
        widget.resourceId == 'bible.tagnt') {
      return null;
    }
    final parsed = parseReference(_reference);
    if (parsed == null) return null;
    return isNewTestamentBook(parsed.bookCode) ? 'bible.tagnt' : 'bible.tahot';
  }

  void _toggleFavorite() {
    final l10n = context.l10n;
    final parsed = parseReference(_reference);
    final canonical = parsed?.canonical ?? _reference;
    final title = parsed?.displayIn(context.l10nLang) ?? _reference;
    final saved = ref
        .read(favoritesProvider.notifier)
        .togglePassage(
          reference: canonical,
          title: title,
          subtitle: l10n.favoritesPassageSubtitle,
        );
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(saved ? l10n.favoritesAdded : l10n.favoritesRemoved),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openOriginal(String resourceId) {
    final ctrl = ref.read(workspaceProvider.notifier);
    if (ctrl.openInResource(resourceId: resourceId, reference: _reference)) {
      return;
    }
    ctrl.openTab(
      TabSpec(
        kind: PanelKind.bible,
        title: resourceId == 'bible.tagnt' ? 'TAGNT' : 'TAHOT',
        reference: _reference,
        resourceType: 'bible',
        resourceId: resourceId,
      ),
    );
  }

  Widget _buildLinkSetButton(bool compact) {
    final l10n = context.l10n;
    final linkSet = widget.tab.linkSet;
    return PopupMenuButton<String>(
      key: const ValueKey('reader-link-set'),
      tooltip: l10n.readerLinkSetHelp,
      position: PopupMenuPosition.under,
      onSelected: (value) => ref
          .read(workspaceProvider.notifier)
          .setTabLinkSet(
            tileId: widget.tile.id,
            tabId: widget.tab.id,
            linkSet: value == 'none' ? null : value,
          ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'none',
          height: 34,
          child: Row(
            children: [
              Icon(
                linkSet == null ? Icons.check : Icons.link_off,
                size: 15,
                color: linkSet == null ? kAccent : kTextSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.readerLinkSetNone,
                style: const TextStyle(fontSize: 13.5),
              ),
            ],
          ),
        ),
        for (final id in kLinkSetIds)
          PopupMenuItem(
            value: id,
            height: 34,
            child: Row(
              children: [
                Icon(
                  linkSet == id ? Icons.check : Icons.link,
                  size: 15,
                  color: linkSet == id ? kAccent : kTextSecondary,
                ),
                const SizedBox(width: 8),
                Text(id, style: const TextStyle(fontSize: 13.5)),
              ],
            ),
          ),
      ],
      child: _ToolButton(
        icon: Icons.link,
        label: linkSet == null
            ? l10n.readerLinkSet
            : '${l10n.readerLinkSet} $linkSet',
        trailingArrow: !compact,
        iconOnly: compact,
        active: linkSet != null,
        tooltip: l10n.readerLinkSetHelp,
      ),
    );
  }

  /// Formato ▸ Marcadores · Reformato.
  Widget _buildFormattingToolbar() {
    final l10n = context.l10n;
    return Row(
      children: [
        _ToolButton(
          key: const ValueKey('reader-markers'),
          icon: Icons.label_outline,
          label: l10n.fmtMarkers,
          trailingArrow: true,
          active: _flyout == 'marcadores',
          onTap: () => _toggleFlyout('marcadores'),
        ),
        _ToolButton(
          key: const ValueKey('reader-reformat'),
          icon: Icons.format_align_left,
          label: l10n.fmtReformat,
          trailingArrow: true,
          active: _flyout == 'reformato',
          onTap: () => _toggleFlyout('reformato'),
        ),
      ],
    );
  }

  /// Vista ▸ Vista paginada · Barra de ubicación · Zoom · Pantalla completa.
  Widget _buildViewToolbar() {
    final l10n = context.l10n;
    final fullscreen = ref.watch(panelFullscreenProvider) == widget.tab.id;
    return Row(
      children: [
        _ToolButton(
          key: const ValueKey('reader-paged-view'),
          icon: Icons.auto_stories_outlined,
          label: l10n.viewPagedView,
          trailingArrow: true,
          active: _display.paged,
          onTap: () => _toggleFlyout('paginada'),
        ),
        _ToolButton(
          key: const ValueKey('reader-locator-bar'),
          icon: Icons.crop_16_9_outlined,
          label: l10n.viewLocatorBar,
          active: _display.locationBar,
          onTap: () => _updateDisplay(
            _display.copyWith(locationBar: !_display.locationBar),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          l10n.viewZoom,
          style: TextStyle(fontSize: 12.5, color: kTextSecondary),
        ),
        IconButton(
          key: const ValueKey('reader-zoom-out'),
          tooltip: l10n.viewZoom,
          iconSize: 17,
          visualDensity: VisualDensity.compact,
          onPressed: _display.zoom > 50 ? () => _zoomBy(-10) : null,
          icon: const Icon(Icons.remove),
        ),
        Tooltip(
          message: l10n.viewZoomReset,
          child: InkWell(
            onTap: _display.zoom == 100 ? null : () => _setZoom(100),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text(
                '${_display.zoom}%',
                key: const ValueKey('reader-zoom-value'),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        IconButton(
          key: const ValueKey('reader-zoom-in'),
          tooltip: l10n.viewZoom,
          iconSize: 17,
          visualDensity: VisualDensity.compact,
          onPressed: _display.zoom < 300 ? () => _zoomBy(10) : null,
          icon: const Icon(Icons.add),
        ),
        const SizedBox(width: 14),
        _ToolButton(
          key: const ValueKey('reader-full-screen'),
          icon: fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
          label: fullscreen
              ? l10n.panelFullscreenExit
              : l10n.panelFullscreenEnter,
          active: fullscreen,
          tooltip: fullscreen
              ? l10n.panelFullscreenExit
              : l10n.panelFullscreenEnter,
          onTap: _toggleFullScreen,
        ),
      ],
    );
  }

  Widget _buildLocationBar(String bookCode, DocumentManifest? manifest) {
    final canonical = parseReference(_reference)?.canonical ?? _reference;
    final saved = ref
        .watch(favoritesProvider)
        .any(
          (favorite) =>
              favorite.kind == FavoriteKind.passage &&
              favorite.reference == canonical,
        );
    return Container(
      // Medido en el original (home2 y settle_bible): 36 px.
      height: 36,
      padding: const EdgeInsets.only(left: 14, right: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Row(
        children: [
          Text(
            // El título del artículo lo dicta el recurso (KJV → «Genesis»);
            // en español los evangelios llevan «San» (home2 → «San Juan»).
            readerArticleTitle(
              bookCode,
              lang: context.l10nLang,
              resourceName: manifest?.bookByCode(bookCode)?.name,
            ),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: kTextPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            key: const ValueKey('reader-favorite'),
            tooltip: saved
                ? context.l10n.favoritesRemove
                : context.l10n.favoritesAdd,
            iconSize: 16,
            visualDensity: VisualDensity.compact,
            onPressed: _toggleFavorite,
            icon: Icon(saved ? Icons.star : Icons.star_border),
          ),
          Tooltip(
            message: context.l10n.readerHideLocationBar,
            child: IconButton(
              key: const ValueKey('reader-hide-location-bar'),
              iconSize: 14,
              visualDensity: VisualDensity.compact,
              onPressed: () =>
                  _updateDisplay(_display.copyWith(locationBar: false)),
              icon: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- componentes

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    super.key,
    required this.label,
    this.active = false,
    this.tooltip,
    this.trailingArrow = false,
    this.onTap,
  });

  final String label;
  final bool active;
  final String? tooltip;
  final bool trailingArrow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? kTextPrimary : kTextSecondary;
    return Tooltip(
      message: tooltip ?? label,
      child: InkWell(
        onTap: onTap,
        // El original tiñe de azul muy claro la pestaña al pasar el cursor
        // (settle_bible: #E9F5FF sobre «Home»).
        hoverColor: kAccent.withValues(alpha: 0.08),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? kAccent : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: color,
                ),
              ),
              if (trailingArrow)
                Icon(Icons.arrow_drop_down, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    super.key,
    required this.icon,
    required this.label,
    this.active = false,
    this.enabled = true,
    this.tooltip,
    this.onTap,
    this.trailingArrow = false,
    this.iconOnly = false,
    this.pill = false,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool enabled;
  final String? tooltip;
  final VoidCallback? onTap;
  final bool trailingArrow;

  /// En paneles estrechos se oculta la etiqueta (queda el icono + tooltip).
  final bool iconOnly;

  /// Fondo claro cuando está activo (Análisis/Información del original).
  final bool pill;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? kTextSecondary.withValues(alpha: 0.55)
        : (active ? kAccent : kTextSecondary);
    return Tooltip(
      message: tooltip ?? label,
      child: Container(
        decoration: active && pill
            ? BoxDecoration(
                color: kAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              )
            : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          hoverColor: kAccent.withValues(alpha: 0.08),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: iconOnly ? 11 : 9,
              vertical: 6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                if (!iconOnly) ...[
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: color,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (trailingArrow)
                    Icon(Icons.arrow_drop_down, size: 16, color: color),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Separador vertical entre grupos de la barra secundaria (24 px de alto,
/// como el original: `settle_bible`, x=397 y x=537).
class _ToolDivider extends StatelessWidget {
  const _ToolDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 24,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    color: kBorder,
  );
}

/// Mini portada del recurso (color propio, sin copiar portadas reales).
class _CoverChip extends StatelessWidget {
  const _CoverChip({
    required this.resourceId,
    this.width = 16,
    this.height = 18,
  });

  final String? resourceId;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: resourceColorFor(resourceId),
      borderRadius: BorderRadius.circular(2),
    ),
    child: Icon(Icons.menu_book, size: height * 0.55, color: Colors.white),
  );
}

class _HistoryButton extends StatelessWidget {
  const _HistoryButton({
    required this.history,
    required this.historyIndex,
    required this.onSelect,
    required this.resourceLabel,
  });

  final List<String> history;
  final int historyIndex;
  final ValueChanged<int> onSelect;

  /// Abreviatura del recurso del panel (p. ej. `RV1909`).
  final String resourceLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = context.l10nLang;
    return PopupMenuButton<int>(
      tooltip: l10n.readerHistoryPanel,
      onSelected: onSelect,
      itemBuilder: (context) => [
        PopupMenuItem<int>(
          enabled: false,
          height: 30,
          child: Text(
            l10n.readerHistoryPanel,
            style: TextStyle(fontSize: 11.5, color: kTextSecondary),
          ),
        ),
        if (history.isEmpty)
          PopupMenuItem<int>(
            enabled: false,
            child: Text(
              l10n.readerHistoryEmpty,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        for (var i = history.length - 1; i >= 0; i--)
          PopupMenuItem<int>(
            value: i,
            child: Row(
              children: [
                Icon(
                  i == historyIndex ? Icons.check : Icons.history,
                  size: 14,
                  color: i == historyIndex ? kAccent : kTextSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  displayFromCanonical(history[i], lang: lang),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: i == historyIndex
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  resourceLabel,
                  style: TextStyle(fontSize: 11.5, color: kTextSecondary),
                ),
              ],
            ),
          ),
      ],
      child: _ToolButton(
        icon: Icons.history,
        label: l10n.readerHistory,
        trailingArrow: true,
      ),
    );
  }
}

/// `Artículo ▾`: paso al artículo siguiente/anterior (M6.1).
class _ArticleButton extends StatelessWidget {
  const _ArticleButton({
    required this.enabled,
    this.iconOnly = false,
    this.onPrevious,
    this.onNext,
  });

  final bool enabled;
  final bool iconOnly;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<int>(
      key: const ValueKey('reader-article'),
      tooltip: l10n.readerArticle,
      enabled: enabled,
      onSelected: (value) => value == 0 ? onPrevious?.call() : onNext?.call(),
      itemBuilder: (context) => [
        PopupMenuItem<int>(
          enabled: false,
          height: 30,
          child: Text(
            l10n.readerArticleStepTo,
            style: TextStyle(fontSize: 11.5, color: kTextSecondary),
          ),
        ),
        PopupMenuItem<int>(
          value: 0,
          height: 34,
          child: Row(
            children: [
              Icon(Icons.keyboard_arrow_up, size: 15, color: kTextSecondary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.readerArticlePrevious,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5),
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: 1,
          height: 34,
          child: Row(
            children: [
              Icon(Icons.keyboard_arrow_down, size: 15, color: kTextSecondary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.readerArticleNext,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5),
                ),
              ),
            ],
          ),
        ),
      ],
      child: _ToolButton(
        icon: Icons.article_outlined,
        label: l10n.readerArticle,
        trailingArrow: !iconOnly,
        iconOnly: iconOnly,
        enabled: enabled,
      ),
    );
  }
}

/// Ubicación de un artículo (encabezado del documento) dentro de un libro.
class _ArticleLoc {
  const _ArticleLoc(this.chapter, this.verse);

  final int chapter;
  final int verse;
}

/// Círculo «^» de la fila A: oculta o muestra la barra secundaria (fila B).
///
/// Evidencia: `home2`/`settle_bible.a11y.txt` lo anuncian como «Hide
/// secondary toolbar»; al ocultarla queda solo la fila A.
class _SecondaryToolbarToggle extends StatelessWidget {
  const _SecondaryToolbarToggle({required this.visible, required this.onTap});

  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Tooltip(
      message: visible
          ? l10n.readerHideSecondaryToolbar
          : l10n.readerShowSecondaryToolbar,
      child: InkWell(
        key: const ValueKey('reader-secondary-toolbar-toggle'),
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                // El original dibuja el círculo en azul pizarra (#63728C).
                color: kTextSecondary,
                width: 1.5,
              ),
            ),
            child: Icon(
              visible ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 15,
              color: kTextSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// ⋮ de la fila A: comandos del panel (duplicar y cerrar pestañas).
///
/// Evidencia: `ledger-03-detalle-ux.md` («Panel commands»).
class _PanelCommandsButton extends ConsumerWidget {
  const _PanelCommandsButton({required this.tile, required this.tab});

  final WorkspaceTile tile;
  final WorkspaceTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final index = tile.tabs.indexWhere((t) => t.id == tab.id);
    return PopupMenuButton<String>(
      key: const ValueKey('reader-panel-commands'),
      tooltip: l10n.panelCommands,
      position: PopupMenuPosition.under,
      icon: Icon(Icons.more_vert, size: 20, color: kTextSecondary),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'duplicate',
          height: 34,
          child: Text(l10n.tabDuplicate),
        ),
        PopupMenuItem(
          value: 'close',
          height: 34,
          child: Text(l10n.tabCloseThis),
        ),
        PopupMenuItem(
          value: 'right',
          height: 34,
          child: Text(l10n.tabCloseToRight),
        ),
        PopupMenuItem(
          value: 'others',
          height: 34,
          child: Text(l10n.tabCloseOthers),
        ),
        PopupMenuItem(value: 'all', height: 34, child: Text(l10n.tabCloseAll)),
      ],
      onSelected: (value) {
        if (index < 0) return;
        final ctrl = ref.read(workspaceProvider.notifier);
        switch (value) {
          case 'duplicate':
            ctrl.duplicateTab(tile.id, index);
          case 'close':
            ctrl.closeTab(tile.id, index);
          case 'right':
            ctrl.closeTabsToRight(tile.id, index);
          case 'others':
            ctrl.closeOtherTabs(tile.id, index);
          case 'all':
            ctrl.closeAllTabs();
        }
      },
    );
  }
}
