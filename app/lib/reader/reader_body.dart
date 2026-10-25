/// Cuerpo del lector: capítulos con versículos numerados, notas al pie,
/// referencias cruzadas y lectura continua con carga incremental.
///
/// M3: además del flujo continuo (M1) aplica las opciones de **Formato →
/// Reformato** (números, indicadores de notas, un versículo por línea, formato
/// del texto bíblico) y dibuja la **Vista paginada** (View → Paged view) con
/// 1–3 columnas y notas al pie de página.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    show RenderAbstractViewport, RenderParagraph, SelectedContent;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/document_models.dart';
import '../catalog/document_repository.dart';
import '../catalog/catalog_asset_source.dart';
import '../catalog/install/module_install_card.dart';
import '../core/localization.dart';
import '../core/theme.dart';
import '../notes/notes_controller.dart';
import '../notes/notes_models.dart';
import '../notes/notes_query.dart';
import '../notes/selection_resolver.dart';
import '../references/reference_parser.dart';
import '../workspace/workspace_controller.dart';
import 'selection_toolbar.dart';
import '../workspace/models.dart';
import 'reader_style.dart';
import 'word_study_dialog.dart';

class ReaderBody extends ConsumerStatefulWidget {
  const ReaderBody({
    super.key,
    required this.resourceId,
    required this.reference,
    required this.onNavigate,
    this.display = TabDisplay.defaults,
    this.limitedView = false,
    this.onNoteSelection,
    this.onHighlightSelection,
    this.onRemoveHighlightSelection,
    this.onSearchSelection,
    this.onOpenVerseNotes,
    this.citationBuilder,
  });

  final String resourceId;

  /// Referencia canónica (`JHN.1.1`, `PSA.23`).
  final String reference;

  /// Navegación interna (cross-refs, …) con referencia canónica.
  final ValueChanged<String> onNavigate;

  /// Opciones de presentación del panel (Formato/Vista).
  final TabDisplay display;

  /// Modo de vista limitada (Ajustes 8.4): sin paginación y con las notas al
  /// pie como lista al final de cada capítulo.
  final bool limitedView;

  /// Acciones sobre una selección del texto (M4): crear nota, resaltar,
  /// buscar el texto o abrir las notas de un versículo.
  final void Function(SelectionMatch? match, String quote)? onNoteSelection;
  final void Function(
    SelectionMatch match,
    String quote,
    String color,
    String style,
  )?
  onHighlightSelection;

  /// Quita los resaltados que cubren la selección.
  final void Function(SelectionMatch match)? onRemoveHighlightSelection;
  final ValueChanged<String>? onSearchSelection;
  final void Function(List<Note> notes)? onOpenVerseNotes;

  /// Cita del pasaje visible (la construye el panel con el estilo activo).
  final String Function()? citationBuilder;

  @override
  ConsumerState<ReaderBody> createState() => _ReaderBodyState();
}

class _ChapterSection {
  const _ChapterSection({required this.bookCode, required this.chapter});

  final String bookCode;
  final ChapterDocument chapter;
}

/// Opciones efectivas del texto (reformato + vista limitada).
class _TextOptions {
  const _TextOptions({
    required this.numbers,
    required this.footnoteIndicators,
    required this.oneVersePerLine,
    required this.formattedBibleText,
    required this.limitedView,
  });

  factory _TextOptions.from(TabDisplay display, bool limitedView) =>
      _TextOptions(
        numbers: display.showNumbers,
        footnoteIndicators: display.showFootnoteIndicators,
        oneVersePerLine: display.oneVersePerLineEffective,
        formattedBibleText: display.formattedBibleText,
        limitedView: limitedView,
      );

  final bool numbers;
  final bool footnoteIndicators;
  final bool oneVersePerLine;
  final bool formattedBibleText;
  final bool limitedView;

  _TextOptions copyWith({bool? numbers}) => _TextOptions(
    numbers: numbers ?? this.numbers,
    footnoteIndicators: footnoteIndicators,
    oneVersePerLine: oneVersePerLine,
    formattedBibleText: formattedBibleText,
    limitedView: limitedView,
  );
}

/// Anotaciones de un capítulo (M4): notas por versículo y resaltados.
class _ChapterNotes {
  const _ChapterNotes({this.byVerse = const {}, this.highlights = const {}});

  final Map<int, List<Note>> byVerse;
  final Map<int, List<VerseHighlight>> highlights;

  bool get isEmpty => byVerse.isEmpty && highlights.isEmpty;
}

/// Trozo medible dentro de la vista paginada.
class _FlowChunk {
  _FlowChunk({
    required this.height,
    required this.build,
    this.book,
    this.chapter,
    this.verseStart,
    this.verseEnd,
    this.notes = const [],
  });

  final double height;
  final Widget Function() build;
  final String? book;
  final int? chapter;
  final int? verseStart;
  final int? verseEnd;
  final List<String> notes;

  bool contains(String bookCode, int chapter, int verse) =>
      book == bookCode &&
      this.chapter == chapter &&
      verseStart != null &&
      verse >= verseStart! &&
      verse <= (verseEnd ?? verseStart!);
}

/// Página de la vista paginada: columnas de trozos.
class _ReaderPage {
  _ReaderPage(this.columns, {this.notes = const []});

  final List<List<_FlowChunk>> columns;
  final List<String> notes;
}

class _ReaderBodyState extends ConsumerState<ReaderBody> {
  final ScrollController _scroll = ScrollController();
  final PageController _pages = PageController();
  final List<_ChapterSection> _sections = [];
  final GlobalKey _targetParagraphKey = GlobalKey();

  /// Reconocedores de las palabras enlazadas al léxico, por instancia.
  final Map<String, TapGestureRecognizer> _wordRecognizers = {};
  bool _rtl = false;

  bool _loading = false;
  bool _atEnd = false;
  String? _error;

  /// El recurso existe pero el libro no está en su manifest (p. ej. un
  /// Antiguo Testamento pedido en TAGNT): mensaje claro y CTA equivalente.
  bool _bookUnavailable = false;

  /// El módulo del recurso no está instalado (catálogo desacoplado): se
  /// muestra la tarjeta de instalación con progreso.
  CatalogNotInstalledException? _notInstalled;

  /// Manifest del recurso actual, cacheado por el repositorio entre
  /// navegaciones.
  DocumentManifest? _manifest;

  String? get _resourceTitle => _manifest?.title;

  /// Nombre del libro para los mensajes de indisponibilidad.
  String get _bookNameForDisplay {
    final book = _targetBook;
    final name = _manifest?.bookByCode(book ?? '')?.name;
    if (name != null && name.isNotEmpty) return name;
    // El manifest del recurso puede no contener el libro (es justamente el
    // caso de la tarjeta): nombre canónico del canon, o el código.
    return bookDisplayName(book ?? '', lang: context.l10nLang);
  }

  /// Contrapartida de idioma original si esta pestaña es TAHOT/TAGNT: el
  /// libro ausente casi siempre significa «viajaste al testamento equivocado».
  String? _equivalentResourceId() {
    if (widget.resourceId == 'bible.tahot') return 'bible.tagnt';
    if (widget.resourceId == 'bible.tagnt') return 'bible.tahot';
    return null;
  }

  /// Abre (o reactiva) la pestaña del recurso equivalente en el mismo
  /// pasaje, punto de entrada del CTA de la tarjeta.
  void _openInEquivalent(String resourceId) {
    final ctrl = ref.read(workspaceProvider.notifier);
    final reference = '$_targetBook.$_targetChapter.1';
    if (ctrl.openInResource(resourceId: resourceId, reference: reference)) {
      return;
    }
    ctrl.openTab(
      TabSpec(
        kind: PanelKind.bible,
        title: resourceId == 'bible.tagnt' ? 'TAGNT' : 'TAHOT',
        reference: reference,
        resourceType: 'bible',
        resourceId: resourceId,
      ),
    );
  }

  int _limit = 60;
  int _navToken = 0;
  int _pageIndex = 0;
  int _pageCount = 0;

  // Objetivo de desplazamiento por versículo (se limpia tras usarlo).
  String? _targetBook;
  int? _targetChapter;
  int? _targetVerse;
  int? _targetCharOffset;

  /// Anotaciones de Notas (M4) por capítulo («LIBRO.capítulo»).
  Map<String, _ChapterNotes> _annotations = const {};

  static Map<String, _ChapterNotes> _buildAnnotations(
    Iterable<Note> notes,
    String resourceId,
  ) {
    final pairs = <(String, int)>{};
    for (final note in notes) {
      if (note.isTrashed) continue;
      for (final anchor in note.anchors) {
        if (!anchorMatchesResource(anchor, resourceId)) continue;
        final book = anchor.bookCode;
        final chapter = anchor.chapter;
        if (book != null && chapter != null) pairs.add((book, chapter));
      }
    }
    final map = <String, _ChapterNotes>{};
    for (final (book, chapter) in pairs) {
      map['$book.$chapter'] = _ChapterNotes(
        byVerse: notesByVerse(
          notes,
          resourceId: resourceId,
          bookCode: book,
          chapter: chapter,
        ),
        highlights: highlightsByVerse(
          notes,
          resourceId: resourceId,
          bookCode: book,
          chapter: chapter,
        ),
      );
    }
    return map;
  }

  _ChapterNotes? _annosFor(String? bookCode, int? chapter) =>
      bookCode == null || chapter == null
      ? null
      : _annotations['$bookCode.$chapter'];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _pages.addListener(_hideFloatingOnPageChange);
    // Clic en cualquier parte que no sea la capa abierta la cierra (el
    // barrier modal que tenía `showMenu` para las notas al pie).
    GestureBinding.instance.pointerRouter.addGlobalRoute(_outsideLayersRoute);
    _beginReset(widget.reference, notify: false);
  }

  @override
  void didUpdateWidget(covariant ReaderBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resourceId != oldWidget.resourceId) {
      // Otro recurso en el mismo panel (cambiar libro u abrir otra versión):
      // las secciones cargadas son del recurso anterior; se recargan.
      _beginReset(widget.reference);
      return;
    }
    if (widget.reference != oldWidget.reference) {
      _handleReferenceChange(widget.reference);
    }
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(
      _outsideLayersRoute,
    );
    _pages.removeListener(_hideFloatingOnPageChange);
    _footnoteOpenTimer?.cancel();
    _footnoteCloseTimer?.cancel();
    _disposeWordRecognizers();
    _scroll.dispose();
    _pages.dispose();
    super.dispose();
  }

  /// Al cambiar de página, la selección sigue pero el menú flotante anclado
  /// al punto de soltar queda desfasado: se cierra (lo reabre el próximo
  /// gesto de selección). La tarjeta de nota al pie también, porque su
  /// marcador ya no está en la página visible.
  void _hideFloatingOnPageChange() {
    if (mounted && _floatingSelectionAnchor != null) {
      setState(() => _floatingSelectionAnchor = null);
    }
    _closeFootnoteCard();
  }

  /// Descarta la capa abierta (nota al pie o menú flotante) con un clic en
  /// cualquier lugar que no sea ella misma.
  void _outsideLayersRoute(PointerEvent event) {
    if (event is! PointerDownEvent || !mounted) return;
    _dismissFootnoteIfOutside(event.position);
    if (_floatingSelectionAnchor != null &&
        !_containsGlobalKey(_floatingToolbarKey, event.position)) {
      setState(() => _floatingSelectionAnchor = null);
    }
  }

  void _disposeWordRecognizers() {
    for (final recognizer in _wordRecognizers.values) {
      recognizer.dispose();
    }
    _wordRecognizers.clear();
  }

  TabDisplay get _display => widget.display;

  /// Pila tipográfica del recurso (3.17).
  String get _font => _display.font;

  bool get _paged => widget.display.paged && !widget.limitedView;

  _TextOptions get _options =>
      _TextOptions.from(widget.display, widget.limitedView);

  // ------------------------------------------------------------ navegación

  void _handleReferenceChange(String reference) {
    final parsed = parseReference(reference);
    if (parsed == null) {
      setState(() => _error = context.l10n.readerInvalidReference(reference));
      return;
    }
    final first = _sections.isEmpty ? null : _sections.first;
    final sameSection =
        first != null &&
        first.bookCode == parsed.bookCode &&
        first.chapter.n == parsed.chapter;
    if (sameSection && parsed.verseStart != null) {
      setState(() {
        _targetBook = parsed.bookCode;
        _targetChapter = parsed.chapter;
        _targetVerse = parsed.verseStart;
        _targetCharOffset = null;
      });
      _jumpToVerseIfNeeded();
      return;
    }
    _beginReset(reference);
  }

  void _beginReset(String reference, {bool notify = true}) {
    void apply() {
      final parsed = parseReference(reference);
      if (parsed == null) {
        _error = context.l10n.readerInvalidReference(reference);
        _bookUnavailable = false;
        _notInstalled = null;
        return;
      }
      _navToken++;
      _targetBook = parsed.bookCode;
      _targetChapter = parsed.chapter;
      _targetVerse = parsed.verseStart;
      _targetCharOffset = null;
      _disposeWordRecognizers();
      _sections.clear();
      _atEnd = false;
      _error = null;
      _bookUnavailable = false;
      _notInstalled = null;
      _loading = true;
    }

    if (notify) {
      setState(apply);
    } else {
      apply();
    }
    if (_error == null) _loadInitial(_navToken);
  }

  Future<void> _loadInitial(int token) async {
    final book = _targetBook!;
    final chapter = _targetChapter!;
    try {
      // Catálogo desacoplado: comprueba primero si el recurso contiene el
      // libro (TAGNT no trae Génesis y el error no debe ser «asset no
      // encontrado»). El manifest queda cacheado en el repositorio.
      final repository = ref.read(documentRepositoryProvider);
      final manifest = await repository.loadManifest(widget.resourceId);
      if (!mounted || token != _navToken) return;
      _manifest = manifest;
      if (manifest.bookByCode(book) == null) {
        setState(() {
          _loading = false;
          _bookUnavailable = true;
        });
        return;
      }
      final section = await _loadSection(book, chapter);
      if (!mounted || token != _navToken) return;
      setState(() {
        _loading = false;
        if (section != null) {
          _sections.add(section);
        } else {
          _error = context.l10n.readerSectionMissing(book, chapter);
        }
      });
      _jumpToVerseIfNeeded();
      _maybeFill();
    } on CatalogNotInstalledException catch (issue) {
      if (!mounted || token != _navToken) return;
      setState(() {
        _loading = false;
        _notInstalled = issue;
      });
    } catch (e) {
      if (!mounted || token != _navToken) return;
      setState(() {
        _loading = false;
        _error = context.l10n.readerLoadError('$e');
      });
    }
  }

  Future<_ChapterSection?> _loadSection(String bookCode, int chapter) async {
    final book = await ref
        .read(documentRepositoryProvider)
        .loadBook(widget.resourceId, bookCode);
    final ch = book.chapter(chapter);
    if (ch == null) return null;
    return _ChapterSection(bookCode: bookCode, chapter: ch);
  }

  // ------------------------------------------------------- lectura continua

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.extentAfter < 600) _appendNext();
    // El menú flotante pierde sentido al desplazarse (el framework hace lo
    // propio con su toolbar) y la tarjeta de nota al pie quedaría anclada a
    // una posición fija de la ventana: se cierran ambas.
    if (_floatingSelectionAnchor != null) {
      setState(() => _floatingSelectionAnchor = null);
    }
    _closeFootnoteCard();
  }

  void _maybeFill() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _atEnd || _loading) return;
      if (_sections.length >= _limit) return;
      if (_paged) {
        if (_pageCount <= 1) _appendNext();
        return;
      }
      if (!_scroll.hasClients) return;
      final position = _scroll.position;
      if (position.maxScrollExtent - position.pixels < 600) _appendNext();
    });
  }

  Future<void> _appendNext() async {
    if (_loading || _atEnd || _sections.isEmpty) return;
    if (_sections.length >= _limit) return;
    final token = _navToken;
    final manifest = await ref.read(manifestProvider(widget.resourceId).future);
    if (!mounted || token != _navToken) return;
    final last = _sections.last;
    final next = manifest.nextLocation(last.bookCode, last.chapter.n);
    if (next == null) {
      setState(() => _atEnd = true);
      return;
    }
    setState(() => _loading = true);
    try {
      final section = await _loadSection(next.book, next.chapter);
      if (!mounted || token != _navToken) return;
      setState(() {
        _loading = false;
        if (section != null) {
          _sections.add(section);
        } else {
          _atEnd = true;
        }
      });
      _maybeFill();
    } catch (_) {
      if (!mounted || token != _navToken) return;
      setState(() => _loading = false);
    }
  }

  // --------------------------------------------------- scroll por versículo

  bool _isTargetSection(_ChapterSection section) =>
      _targetVerse != null &&
      section.bookCode == _targetBook &&
      section.chapter.n == _targetChapter;

  void _jumpToVerseIfNeeded() {
    if (_targetVerse == null) return;
    if (_paged) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToTargetPage());
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _targetVerse == null) return;
      final ctx = _targetParagraphKey.currentContext;
      final ro = ctx?.findRenderObject();
      if (ro is! RenderParagraph || !_scroll.hasClients) return;
      final caret = ro.getOffsetForCaret(
        TextPosition(offset: _targetCharOffset ?? 0),
        Rect.zero,
      );
      final viewport = RenderAbstractViewport.maybeOf(ro);
      if (viewport == null) return;
      final target = viewport.getOffsetToReveal(
        ro,
        0.12,
        rect: Rect.fromLTWH(0, caret.dy, ro.size.width, 24),
      );
      final position = _scroll.position;
      _scroll.jumpTo(
        target.offset.clamp(position.minScrollExtent, position.maxScrollExtent),
      );
      setState(() => _targetVerse = null);
    });
  }

  /// En la vista paginada, la navegación lleva a la página que contiene el
  /// versículo (las páginas se calculan en el build, así que se reintenta).
  void _jumpToTargetPage({List<_ReaderPage>? pages}) {
    if (!mounted || _targetVerse == null) return;
    final list = pages ?? _lastPages;
    if (list == null || list.isEmpty) return;
    final book = _targetBook;
    final chapter = _targetChapter;
    final verse = _targetVerse!;
    if (book == null || chapter == null) return;
    for (var i = 0; i < list.length; i++) {
      for (final column in list[i].columns) {
        for (final chunk in column) {
          if (!chunk.contains(book, chapter, verse)) continue;
          if (_pages.hasClients) _pages.jumpToPage(i);
          setState(() => _targetVerse = null);
          return;
        }
      }
    }
    setState(() => _targetVerse = null);
  }

  // -------------------------------------------------------------- construir

  @override
  Widget build(BuildContext context) {
    final manifest = ref.watch(manifestProvider(widget.resourceId)).value;
    _rtl = manifest?.rtl ?? widget.resourceId == 'bible.tahot';
    // recalcula al cargar el manifest
    // Anotaciones de Notas (M4): marcadores y resaltados del texto.
    final notes = ref.watch(notesProvider).notes;
    // Marcadores (M6.2): el filtro por cuadernos/etiquetas decide qué
    // indicadores y resaltados se pintan en el texto.
    _annotations = _buildAnnotations(
      notes.where(
        (note) => widget.display.markerFilterMatches(note.notebooks, note.tags),
      ),
      widget.resourceId,
    );

    final notInstalled = _notInstalled;
    if (notInstalled != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ModuleInstallCard(
              key: const ValueKey('reader-module-missing'),
              moduleId: notInstalled.moduleId,
              onDone: () => _beginReset(widget.reference, notify: false),
            ),
          ),
        ),
      );
    }

    final error = _error;
    if (error != null || _bookUnavailable) {
      final l10n = context.l10n;
      final altResourceId = _equivalentResourceId();
      final bookName = _bookNameForDisplay;
      return Center(
        key: const ValueKey('reader-book-unavailable'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: 30, color: kTextSecondary),
              const SizedBox(height: 10),
              if (_bookUnavailable)
                Text(
                  l10n.readerBookNotAvailable(
                    bookName,
                    _resourceTitle ?? widget.resourceId,
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: kTextSecondary,
                  ),
                )
              else
                Text(
                  error ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: kTextSecondary),
                ),
              if (altResourceId != null && _bookUnavailable) ...[
                const SizedBox(height: 14),
                FilledButton.tonal(
                  key: const ValueKey('reader-open-equivalent'),
                  onPressed: () => _openInEquivalent(altResourceId),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(
                    l10n.readerOpenEquivalent(
                      bookName,
                      altResourceId == 'bible.tagnt'
                          ? 'TAGNT'
                          : altResourceId == 'bible.tahot'
                          ? 'TAHOT'
                          : altResourceId,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (_sections.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      );
    }

    if (_paged) return _withDirectionality(_buildPaged(context));

    return _withDirectionality(
      _withMouseSelectionOffsets(
        SelectionArea(
          contextMenuBuilder: _selectionMenu,
          onSelectionChanged: _onSelectionChanged,
          child: Stack(
            key: _selectionStackKey,
            children: [
              SingleChildScrollView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final section in _sections)
                      _buildChapterSection(
                        section,
                        isTarget: _isTargetSection(section),
                      ),
                    _buildFooter(),
                  ],
                ),
              ),
              _buildFloatingSelectionMenu(),
              _buildFootnoteCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _withDirectionality(Widget child) => _rtl
      ? Directionality(textDirection: TextDirection.rtl, child: child)
      : child;

  // -------------------------------------------------------- vista paginada

  List<_ReaderPage>? _lastPages;

  Widget _buildPaged(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const footHeight = 34.0;
        const hPadding = 18.0;
        const vPadding = 10.0;
        final width = constraints.maxWidth;
        final height = constraints.maxHeight - footHeight - vPadding * 2;
        final columns = _columnsFor(width);
        const gap = 22.0;
        final columnWidth =
            (width - hPadding * 2 - gap * (columns - 1)) / columns;

        final chunks = _flowChunks(columnWidth);
        final pages = _paginate(
          chunks,
          columns: columns,
          columnHeight: height,
          columnWidth: columnWidth,
        );
        _lastPages = pages;
        _pageCount = pages.length;
        if (_targetVerse != null) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _jumpToTargetPage(pages: pages),
          );
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) => _maybeFill());
        }

        return _withMouseSelectionOffsets(
          SelectionArea(
            contextMenuBuilder: _selectionMenu,
            onSelectionChanged: _onSelectionChanged,
            child: Stack(
              key: _selectionStackKey,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: PageView.builder(
                        key: const ValueKey('reader-pages'),
                        controller: _pages,
                        itemCount: pages.length,
                        onPageChanged: (index) {
                          setState(() => _pageIndex = index);
                          if (index >= pages.length - 1) _appendNext();
                        },
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.fromLTRB(
                            hPadding,
                            vPadding,
                            hPadding,
                            0,
                          ),
                          child: _buildPage(pages[index], gap),
                        ),
                      ),
                    ),
                    _buildPageFooter(pages.length),
                  ],
                ),
                _buildFloatingSelectionMenu(),
                _buildFootnoteCard(),
              ],
            ),
          ),
        );
      },
    );
  }

  int _columnsFor(double width) {
    switch (_display.columns) {
      case '1':
        return 1;
      case '2':
        return 2;
      case '3':
        return 3;
      default:
        if (width >= 1000) return 3;
        if (width >= 640) return 2;
        return 1;
    }
  }

  Widget _buildPage(_ReaderPage page, double gap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < page.columns.length; i++) ...[
                if (i > 0) SizedBox(width: gap),
                Expanded(
                  child: ClipRect(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final chunk in page.columns[i]) chunk.build(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (page.notes.isNotEmpty) ...[
          const Divider(height: 17),
          Text(
            context.l10n.readerFootnoteList,
            style: readerBodyStyle(
              size: 11,
              font: _font,
            ).copyWith(color: kTextSecondary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          for (final note in page.notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                note,
                style: readerBodyStyle(
                  size: 11.5,
                  font: _font,
                ).copyWith(color: kTextSecondary),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildPageFooter(int total) {
    return SizedBox(
      height: 34,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: context.l10n.viewPrevPage,
            iconSize: 17,
            onPressed: _pageIndex > 0
                ? () => _pages.previousPage(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                  )
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            context.l10n.viewPageOf(_pageIndex + 1, total),
            key: const ValueKey('reader-page-indicator'),
            style: TextStyle(fontSize: 12, color: kTextSecondary),
          ),
          IconButton(
            tooltip: context.l10n.viewNextPage,
            iconSize: 17,
            onPressed: _pageIndex < total - 1
                ? () => _pages.nextPage(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                  )
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }

  /// Trozos medibles de los capítulos cargados (uno por bloque, o por
  /// versículo si el reformato pide un versículo por línea).
  List<_FlowChunk> _flowChunks(double columnWidth) {
    final options = _options;
    final scaler = MediaQuery.textScalerOf(context);
    final chunks = <_FlowChunk>[];

    double measure(String text, TextStyle style, double width) {
      if (width <= 0) return 0;
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: null,
      )..layout(maxWidth: width);
      return painter.height;
    }

    for (final section in _sections) {
      final chapter = section.chapter;
      for (final block in chapter.blocks) {
        switch (block) {
          case HeadingBlock h:
            final style = h.style == 'psalmTitle'
                ? readerBodyStyle(
                    size: 14.5,
                    font: _font,
                  ).copyWith(fontStyle: FontStyle.italic)
                : readerSectionHeadingStyle(font: _font);
            chunks.add(
              _FlowChunk(
                height:
                    measure(h.text, style, columnWidth) +
                    (h.style == 'psalmTitle' ? 14 : 16),
                book: section.bookCode,
                chapter: chapter.n,
                build: () => _buildHeading(h),
              ),
            );
          case ChapterNumberBlock c:
            chunks.add(
              _FlowChunk(
                height:
                    measure(
                      '${c.value}',
                      readerChapterNumberStyle(font: _font),
                      columnWidth,
                    ) +
                    16,
                book: section.bookCode,
                chapter: chapter.n,
                build: () => _buildChapterNumber(c),
              ),
            );
          case VerseGroupBlock g:
            // El flujo paginado trocea por versículo (los números son el
            // punto de corte natural) y la poesía conserva su sangría.
            final base = options.formattedBibleText && g.style != 'paragraph'
                ? 12 + g.indent * 18.0
                : 0.0;
            for (final verse in g.verses) {
              final text = _plainVerseText(verse, options);
              chunks.add(
                _FlowChunk(
                  height:
                      measure(
                        text,
                        readerBodyStyle(font: _font),
                        columnWidth - base,
                      ) +
                      3,
                  book: section.bookCode,
                  chapter: chapter.n,
                  verseStart: verse.n == 0 ? null : verse.n,
                  verseEnd: verse.n == 0 ? null : verse.n,
                  notes: _notesOf(VerseGroupBlock(verses: [verse]), chapter),
                  build: () => _buildVerseLine(
                    verse,
                    chapter,
                    left: base,
                    bookCode: section.bookCode,
                  ),
                ),
              );
            }
          case RuleBlock _:
            chunks.add(
              _FlowChunk(
                height: 21,
                book: section.bookCode,
                chapter: chapter.n,
                build: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),
              ),
            );
          case MapBlock _:
            break;
        }
      }
      if (options.limitedView && chapter.footnotes.isNotEmpty) {
        for (final footnote in chapter.footnotes.values) {
          chunks.add(
            _FlowChunk(
              height:
                  measure(
                    '${footnote.label} ${footnote.text}',
                    readerBodyStyle(size: 11.5, font: _font),
                    columnWidth,
                  ) +
                  4,
              book: section.bookCode,
              chapter: chapter.n,
              build: () => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${footnote.label} ${footnote.text}',
                  style: readerBodyStyle(
                    size: 11.5,
                    font: _font,
                  ).copyWith(color: kTextSecondary),
                ),
              ),
            ),
          );
        }
      }
    }
    return chunks;
  }

  List<String> _notesOf(VerseGroupBlock group, ChapterDocument chapter) {
    if (!_display.footnotesOnPage) return const [];
    final out = <String>[];
    for (final verse in group.verses) {
      // Mismo símbolo que el indicador en el versículo (v1.0.3: en vez de la
      // letra «a», que se confunde con texto).
      var ordinal = 0;
      for (final inline in verse.inlines) {
        if (inline is! FootnoteRef) continue;
        final footnote = chapter.footnotes[inline.id];
        if (footnote == null) continue;
        out.add(
          '${_footnoteGlyph(ordinal++)} '
          '${inline.label ?? footnote.label}: ${footnote.text}',
        );
      }
    }
    return out;
  }

  String _plainVerseText(Verse verse, _TextOptions options) {
    final buffer = StringBuffer();
    if (verse.n != 0 && options.numbers) buffer.write('${verse.n} ');
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
    return buffer.toString();
  }

  List<_ReaderPage> _paginate(
    List<_FlowChunk> chunks, {
    required int columns,
    required double columnHeight,
    required double columnWidth,
  }) {
    final pages = <_ReaderPage>[];
    var pageColumns = <List<_FlowChunk>>[];
    var column = <_FlowChunk>[];
    var pageNotes = <String>[];
    var used = 0.0;

    void closeColumn() {
      if (column.isNotEmpty) pageColumns.add(column);
      column = [];
      used = 0;
    }

    void closePage() {
      closeColumn();
      if (pageColumns.isNotEmpty) {
        pages.add(_ReaderPage(List.of(pageColumns), notes: List.of(pageNotes)));
      }
      pageColumns = [];
      pageNotes = [];
    }

    for (final chunk in chunks) {
      final height = chunk.height;
      if (column.isNotEmpty && used + height > columnHeight) {
        closeColumn();
        if (pageColumns.length >= columns) closePage();
      }
      column.add(chunk);
      used += height;
      if (_display.footnotesOnPage) pageNotes.addAll(chunk.notes);
    }
    closePage();
    return pages.isEmpty
        ? [
            _ReaderPage(const [[]]),
          ]
        : pages;
  }

  // ------------------------------------------------------- flujo continuo

  Widget _buildChapterSection(
    _ChapterSection section, {
    required bool isTarget,
  }) {
    final options = _options;
    final children = <Widget>[];
    for (final block in section.chapter.blocks) {
      switch (block) {
        case HeadingBlock h:
          children.add(_buildHeading(h));
        case ChapterNumberBlock c:
          if (options.numbers) children.add(_buildChapterNumber(c));
        case VerseGroupBlock g:
          // Con «Formato del texto bíblico» activo, los grupos de párrafo
          // fluyen y la poesía conserva sus líneas; sin él todo fluye.
          final grouped = options.oneVersePerLine
              ? false
              : (g.style == 'paragraph' || !options.formattedBibleText);
          if (grouped) {
            children.add(
              _buildParagraphGroup(
                g,
                section.chapter,
                isTarget: isTarget,
                bookCode: section.bookCode,
              ),
            );
          } else {
            children.add(
              _buildLineGroup(
                g,
                section.chapter,
                isTarget: isTarget,
                bookCode: section.bookCode,
              ),
            );
          }
        case RuleBlock _:
          children.add(
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1),
            ),
          );
        case MapBlock _:
          break;
      }
    }
    if (options.limitedView && section.chapter.footnotes.isNotEmpty) {
      children.add(_buildFootnoteList(section.chapter));
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildHeading(HeadingBlock h) {
    return Padding(
      padding: EdgeInsets.only(
        top: h.style == 'psalmTitle' ? 12 : 14,
        bottom: 2,
      ),
      child: h.style == 'psalmTitle'
          ? Text(
              h.text,
              style: readerBodyStyle(
                size: 14.5,
                font: _font,
              ).copyWith(fontStyle: FontStyle.italic, color: kTextSecondary),
            )
          // La RV1909 del original centra el título de sección (home2); la
          // KJV de `settle_bible` lo alinea a la izquierda: es un rasgo de la
          // tipografía de cada recurso. Seguimos la RV1909 (nuestro catálogo).
          : Center(
              child: Text(
                h.text,
                textAlign: TextAlign.center,
                style: readerSectionHeadingStyle(font: _font),
              ),
            ),
    );
  }

  Widget _buildChapterNumber(ChapterNumberBlock c) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 2),
      child: Align(
        alignment: _rtl ? Alignment.centerRight : Alignment.centerLeft,
        child: Text('${c.value}', style: readerChapterNumberStyle(font: _font)),
      ),
    );
  }

  /// Notas al pie como lista (modo de vista limitada, Ajustes 8.4).
  Widget _buildFootnoteList(ChapterDocument chapter) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 6),
          Text(
            context.l10n.readerFootnoteList,
            style: readerBodyStyle(
              size: 11,
              font: _font,
            ).copyWith(color: kTextSecondary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          for (final footnote in chapter.footnotes.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                '${footnote.label} ${footnote.text}',
                style: readerBodyStyle(
                  size: 12,
                  font: _font,
                ).copyWith(color: kTextSecondary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildParagraphGroup(
    VerseGroupBlock group,
    ChapterDocument chapter, {
    required bool isTarget,
    String? bookCode,
  }) {
    final options = _options;
    final spans = <InlineSpan>[];
    var pos = 0;
    var offsetRecorded = false;
    int? printedVerse;
    GlobalKey? paragraphKey;
    final targetVerse = isTarget ? _targetVerse : null;

    for (final verse in group.verses) {
      final showNumber =
          options.numbers && verse.n != 0 && verse.n != printedVerse;
      if (targetVerse != null && verse.n == targetVerse && !offsetRecorded) {
        _targetCharOffset = pos;
        offsetRecorded = true;
        paragraphKey = _targetParagraphKey;
      }
      if (spans.isNotEmpty) {
        spans.add(const TextSpan(text: ' '));
        pos += 1;
      }
      for (final span in _spansForVerse(
        verse,
        chapter,
        withNumber: showNumber,
        bookCode: bookCode,
      )) {
        spans.add(span);
        pos += _spanLength(span);
      }
      if (showNumber) printedVerse = verse.n;
    }

    // Sangría de primera línea: el original (home2) deja ~22 CSS px, que a
    // la fuente del lector son 1,5 em. Se usa un `WidgetSpan` para que no
    // forme parte del texto copiado ni de las referencias de selección. Con
    // «Formato del texto bíblico» apagado no hay sangría.
    final indent = options.formattedBibleText
        ? (readerBodyStyle(font: _font).fontSize ?? 15.5) * 1.5
        : 0.0;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text.rich(
        TextSpan(
          style: readerBodyStyle(font: _font),
          children: [
            WidgetSpan(child: SizedBox(width: indent)),
            ...spans,
          ],
        ),
        textAlign: TextAlign.justify,
        key: paragraphKey,
      ),
    );
  }

  Widget _buildLineGroup(
    VerseGroupBlock group,
    ChapterDocument chapter, {
    required bool isTarget,
    String? bookCode,
  }) {
    final targetVerse = isTarget ? _targetVerse : null;
    final options = _options;
    // La poesía y las listas van sangradas; un grupo de párrafo partido en
    // versículos (un versículo por línea) no.
    final left = options.formattedBibleText && group.style != 'paragraph'
        ? 12 + group.indent * 18.0
        : 0.0;
    final lines = <Widget>[];
    for (final verse in group.verses) {
      final isTargetLine = targetVerse != null && verse.n == targetVerse;
      if (isTargetLine) _targetCharOffset = 0;
      lines.add(
        _buildVerseLine(
          verse,
          chapter,
          left: left,
          bookCode: bookCode,
          targetKey: isTargetLine ? _targetParagraphKey : null,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines,
    );
  }

  Widget _buildVerseLine(
    Verse verse,
    ChapterDocument chapter, {
    double left = 0,
    Key? targetKey,
    String? bookCode,
  }) {
    final options = _options;
    return Padding(
      padding: EdgeInsets.only(left: left, top: 3),
      child: Text.rich(
        TextSpan(
          style: readerBodyStyle(font: _font),
          children: _spansForVerse(
            verse,
            chapter,
            withNumber: options.numbers && verse.n != 0,
            bookCode: bookCode,
          ),
        ),
        key: targetKey,
      ),
    );
  }

  List<InlineSpan> _spansForVerse(
    Verse verse,
    ChapterDocument chapter, {
    required bool withNumber,
    String? bookCode,
  }) {
    final options = _options;
    final spans = <InlineSpan>[];
    final annotations = _annosFor(bookCode, chapter.n);
    final verseNotes = annotations?.byVerse[verse.n] ?? const <Note>[];
    final highlights =
        annotations?.highlights[verse.n] ?? const <VerseHighlight>[];

    if (verseNotes.isNotEmpty && !options.limitedView) {
      spans.add(_noteMarkerSpan(verseNotes));
    }
    if (withNumber) spans.add(_verseNumberSpan(verse.n));

    var plain = 0;
    // Los indicadores de nota al pie se difieren al final del versículo:
    // junto al número del versículo se confunden con una sigla y el usuario
    // los confunde con letras del texto (feedback v1.0.2).
    final deferredFootnotes = <FootnoteRef>[];
    for (var index = 0; index < verse.inlines.length; index++) {
      final inline = verse.inlines[index];
      switch (inline) {
        case TextInline t:
          final recognizer = t.isStudyWord
              ? _wordRecognizer(
                  '${bookCode ?? ''}.${chapter.n}.${verse.n}.$index',
                  t,
                )
              : null;
          _emitSpansWithHighlights(
            spans,
            t.text,
            _textInlineStyle(t),
            highlights,
            plain,
            recognizer: recognizer,
          );
          plain += t.text.length;
        case LineInline _:
          // Sin formato de texto bíblico las líneas de la poesía fluyen.
          final separator = options.formattedBibleText ? '\n' : ' ';
          _emitSpansWithHighlights(spans, separator, null, highlights, plain);
          plain += separator.length;
        case FootnoteRef f:
          if (options.footnoteIndicators) deferredFootnotes.add(f);
        case XrefLink x:
          spans.add(_xrefSpan(x));
      }
    }
    for (var ordinal = 0; ordinal < deferredFootnotes.length; ordinal++) {
      spans.add(_footnoteSpan(deferredFootnotes[ordinal], chapter, ordinal));
    }
    return spans;
  }

  /// Emite [text] (que empieza en el desplazamiento [start] del texto plano del
  /// versículo) troceado por los resaltados que lo cruzan.
  void _emitSpansWithHighlights(
    List<InlineSpan> spans,
    String text,
    TextStyle? style,
    List<VerseHighlight> highlights,
    int start, {
    TapGestureRecognizer? recognizer,
  }) {
    if (text.isEmpty) return;
    if (highlights.isEmpty) {
      spans.add(
        TextSpan(
          text: text,
          style: style,
          recognizer: recognizer,
          mouseCursor: recognizer == null ? null : SystemMouseCursors.click,
        ),
      );
      return;
    }
    final end = start + text.length;
    var cursor = start;
    for (final range in highlights) {
      if (range.end <= cursor || range.start >= end) continue;
      final from = range.start < cursor ? cursor : range.start;
      final to = range.end > end ? end : range.end;
      if (to <= from) continue;
      if (from > cursor) {
        spans.add(
          TextSpan(
            text: text.substring(cursor - start, from - start),
            style: style,
            recognizer: recognizer,
            mouseCursor: recognizer == null ? null : SystemMouseCursors.click,
          ),
        );
      }
      spans.add(
        TextSpan(
          text: text.substring(from - start, to - start),
          style: range.isUnderline
              ? (style ?? const TextStyle()).copyWith(
                  decoration: TextDecoration.underline,
                  decorationColor: highlightColor(range.color),
                  decorationThickness: 2,
                )
              : (style ?? const TextStyle()).copyWith(
                  backgroundColor: highlightColor(range.color),
                ),
          recognizer: recognizer,
          mouseCursor: recognizer == null ? null : SystemMouseCursors.click,
        ),
      );
      cursor = to;
    }
    if (cursor < end) {
      spans.add(
        TextSpan(
          text: text.substring(cursor - start),
          style: style,
          recognizer: recognizer,
          mouseCursor: recognizer == null ? null : SystemMouseCursors.click,
        ),
      );
    }
  }

  TapGestureRecognizer _wordRecognizer(String key, TextInline word) {
    final recognizer = _wordRecognizers.putIfAbsent(
      key,
      TapGestureRecognizer.new,
    );
    recognizer.onTap = () => _showWordStudy(word);
    return recognizer;
  }

  void _showWordStudy(TextInline word) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (_) =>
          WordStudyDialog(word: word, sourceResourceId: widget.resourceId),
    );
  }

  /// Marcador de nota en el texto (M4): abre las notas del versículo.
  InlineSpan _noteMarkerSpan(List<Note> notes) => WidgetSpan(
    alignment: PlaceholderAlignment.top,
    child: Padding(
      padding: const EdgeInsets.only(right: 3),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Tooltip(
          message: context.l10n.readerNoteMarker,
          child: GestureDetector(
            key: Key('verse-note-marker-${notes.first.id}'),
            onTap: () => widget.onOpenVerseNotes?.call(notes),
            child: Icon(
              Icons.sticky_note_2_outlined,
              size: 11,
              color: kAccent.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
    ),
  );

  // ------------------------------------------------------------- selección

  /// Último texto seleccionado (lo entrega `SelectionArea`). No usa
  /// `setState`: solo se leerá al construir el menú contextual.
  String _selectionText = '';

  // --- Menú de selección flotante (ratón en escritorio/web) ---------------
  // En la web el menú del navegador tapa al de la app y en escritorio el
  // framework no muestra toolbar tras un arrastre de ratón; aquí la
  // mostramos anclada al punto de soltar. Las vías nativas (clic derecho,
  // pulsación larga táctil) siguen funcionando con `_selectionMenu`.

  /// Anclaje del menú flotante, en coordenadas locales del Stack del lector
  /// (`null` = cerrado).
  Offset? _floatingSelectionAnchor;

  /// La selección cambió durante el gesto en curso (lo entrega
  /// `onSelectionChanged`); se reinicia en cada `PointerDownEvent` y evita
  /// mostrar el menú en arrastres que no seleccionan (p. ej. páginas).
  bool _selectionChangedDuringGesture = false;

  /// El último `pointer down` fue de botón primario de ratón (sin botón
  /// secundario): habilita el disparo del menú en el `up`.
  bool _mousePrimaryDown = false;

  final GlobalKey _selectionStackKey = GlobalKey();
  final GlobalKey _floatingToolbarKey = GlobalKey();

  /// Handler común de `onSelectionChanged`: registra el texto, marca si la
  /// selección cambió en el gesto actual y cierra el menú flotante al
  /// vaciarse (clic en otra parte limpia la selección).
  void _onSelectionChanged(SelectedContent? content) {
    final text = content?.plainText ?? '';
    _selectionText = text;
    if (text.trim().isEmpty) {
      _selectionChangedDuringGesture = false;
      if (mounted && _floatingSelectionAnchor != null) {
        setState(() => _floatingSelectionAnchor = null);
      }
    } else {
      _selectionChangedDuringGesture = true;
    }
  }

  /// Menú contextual de una selección del texto (M4), con la estructura del
  /// original (ver la evidencia de reconocimiento §2): una
  /// fila de acciones (Copiar · [Consultar] · Buscar · Más opciones) y otra de
  /// anotaciones (Agregar nota + colores de resaltado + Subrayado rojo).
  ///
  /// No usa `AdaptiveTextSelectionToolbar.buttonItems` porque su contenedor
  /// limita el alto a una sola fila; se coloca con el delegado de Flutter.
  Widget _selectionMenu(BuildContext context, SelectableRegionState state) {
    final text = _selectionText.trim();
    if (text.isEmpty) return const SizedBox.shrink();
    final match = _resolveSelection(text);
    final highlights = match == null
        ? const <Note>[]
        : _highlightsForMatch(match);
    final anchors = state.contextMenuAnchors;
    const screenPadding = 8.0;
    return Padding(
      padding: const EdgeInsets.all(screenPadding),
      child: CustomSingleChildLayout(
        delegate: TextSelectionToolbarLayoutDelegate(
          anchorAbove:
              anchors.primaryAnchor -
              const Offset(screenPadding, screenPadding),
          anchorBelow:
              (anchors.secondaryAnchor ?? anchors.primaryAnchor) -
              const Offset(screenPadding, screenPadding),
        ),
        child: _buildSelectionToolbar(
          onDismiss: () => state.hideToolbar(),
          match: match,
          highlights: highlights,
        ),
      ),
    );
  }

  /// Barra de acciones de la selección, compartida por el menú del framework
  /// (`_selectionMenu`) y el menú flotante de ratón; cada quién cierra de su
  /// manera vía [onDismiss].
  Widget _buildSelectionToolbar({
    required VoidCallback onDismiss,
    required SelectionMatch? match,
    required List<Note> highlights,
  }) {
    final text = _selectionText.trim();
    return SelectionToolbar(
      singleWord: !text.contains(RegExp(r'\s')),
      activeColor: _activeHighlightColor(highlights),
      canRemoveHighlight: highlights.isNotEmpty,
      onRemoveHighlight: highlights.isEmpty
          ? null
          : () {
              onDismiss();
              if (match != null) {
                widget.onRemoveHighlightSelection?.call(match);
              }
            },
      onCopy: () {
        onDismiss();
        Clipboard.setData(ClipboardData(text: text));
      },
      onLookUp: () {
        onDismiss();
        widget.onSearchSelection?.call(text);
      },
      onSearch: () {
        onDismiss();
        widget.onSearchSelection?.call(text);
      },
      onNote: () {
        onDismiss();
        widget.onNoteSelection?.call(_resolveSelection(text), text);
      },
      onHighlight: (color, style) {
        onDismiss();
        _highlightFromSelection(text, color, style);
      },
      onVisualCopy: () {
        onDismiss();
        _copyCurrentCitation();
      },
    );
  }

  /// Envuelve el `SelectionArea` con el guardia de puntero del ratón que
  /// decide cuándo abrir el menú flotante (después de seleccionar arrastrando
  /// o por doble clic con el ratón).
  Widget _withMouseSelectionOffsets(Widget selectionArea) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (event) {
      _selectionChangedDuringGesture = false;
      _mousePrimaryDown =
          event.kind == PointerDeviceKind.mouse &&
          event.buttons & kPrimaryMouseButton != 0 &&
          event.buttons & kSecondaryMouseButton == 0;
    },
    onPointerUp: (event) {
      if (event.kind != PointerDeviceKind.mouse || !_mousePrimaryDown) {
        return;
      }
      _mousePrimaryDown = false;
      final release = event.position;
      // Un `addPostFrameCallback` desde un handler de puntero no dispara en
      // web: el mote sucio continúa fragmentado. Un timer corto hera el
      // disparo después de que el framework finalice la selección (y
      // entregue el texto vía `onSelectionChanged`).
      Future.delayed(const Duration(milliseconds: 60), () {
        if (mounted) _showFloatingSelectionMenu(release);
      });
    },
    child: selectionArea,
  );

  /// Abre el menú flotante si el gesto terminado en [globalPosition] cambió
  /// la selección con texto (arrastró o doble clic); en el caso contrario, como
  /// un arrastre para desplazarse o un clic simple, no se muestra.
  void _showFloatingSelectionMenu(Offset globalPosition) {
    if (!mounted || _floatingSelectionAnchor != null) return;
    if (_selectionText.trim().isEmpty || !_selectionChangedDuringGesture) {
      return;
    }
    final stackBox =
        _selectionStackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || !stackBox.attached) return;
    setState(
      () => _floatingSelectionAnchor = stackBox.globalToLocal(globalPosition),
    );
  }

  /// Capa flotante, overlay del SelectionArea y persistente del texto en
  /// pantalla (para ambos modos).
  Widget _buildFloatingSelectionMenu() {
    final anchor = _floatingSelectionAnchor;
    if (anchor == null) return const SizedBox.shrink();
    final match = _resolveSelection(_selectionText.trim());
    final highlights = match == null
        ? const <Note>[]
        : _highlightsForMatch(match);
    return Positioned.fill(
      child: CustomSingleChildLayout(
        delegate: TextSelectionToolbarLayoutDelegate(
          anchorAbove: anchor - const Offset(8, 26),
          anchorBelow: anchor,
        ),
        child: SelectionContainer.disabled(
          // La key vive acá (capa flotante) y no en `SelectionToolbar` para
          // que el menú del framework, si coexistiera un frame, no choque.
          child: KeyedSubtree(
            key: _floatingToolbarKey,
            child: _buildSelectionToolbar(
              onDismiss: () => setState(() => _floatingSelectionAnchor = null),
              match: match,
              highlights: highlights,
            ),
          ),
        ),
      ),
    );
  }

  /// ¿La caja del `[GlobalKey.key]`(un `Material`/widget con RenderBox) incluía
  /// al punto global [position]?
  bool _containsGlobalKey(GlobalKey key, Offset position) {
    final context = key.currentContext;
    if (context == null) return false;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return false;
    return box.paintBounds
        .shift(box.localToGlobal(Offset.zero))
        .contains(position);
  }

  /// Resaltados que se solapan con la selección en el mismo versículo y
  /// recurso. Se usan para cambiar su color en vez de crear otro encima y para
  /// ofrecer la acción de quitarlos.
  List<Note> _highlightsForMatch(SelectionMatch match) => highlightsForRange(
    ref.read(notesProvider).notes,
    resourceId: widget.resourceId,
    bookCode: match.bookCode,
    chapter: match.chapter,
    verse: match.verse,
    start: match.start,
    end: match.end,
    verseEnd: match.verseEnd,
  );

  /// Color activo de la selección cuando todos los resaltados solapados
  /// comparten color y son de fondo (`null` si hay estilos mezclados).
  static String? _activeHighlightColor(List<Note> highlights) {
    String? color;
    for (final note in highlights) {
      if (note.isUnderline) return null;
      if (color == null) {
        color = note.color;
      } else if (color != note.color) {
        return null;
      }
    }
    return color;
  }

  /// Resuelve una selección a un versículo y rango del texto (o `null`).
  SelectionMatch? _resolveSelection(String text) {
    final verses = <SelectionVerse>[];
    final plainOptions = _options.copyWith(numbers: false);
    for (final section in _sections) {
      for (final block in section.chapter.blocks) {
        if (block is! VerseGroupBlock) continue;
        for (final verse in block.verses) {
          if (verse.n == 0) continue;
          verses.add(
            SelectionVerse(
              bookCode: section.bookCode,
              chapter: section.chapter.n,
              verse: verse.n,
              text: _plainVerseText(verse, plainOptions),
            ),
          );
        }
      }
    }
    return resolveSelection(selection: text, verses: verses);
  }

  Future<void> _highlightFromSelection(
    String text,
    String color,
    String style,
  ) async {
    final match = _resolveSelection(text);
    if (match == null || !mounted) return;
    widget.onHighlightSelection?.call(match, text, color, style);
  }

  void _copyCurrentCitation() {
    final text = widget.citationBuilder?.call() ?? widget.reference;
    Clipboard.setData(ClipboardData(text: text));
  }

  int _spanLength(InlineSpan span) =>
      span is TextSpan ? (span.text ?? '').length : 1;

  TextStyle? _textInlineStyle(TextInline t) {
    final base = switch (t.style) {
      'italic' => const TextStyle(fontStyle: FontStyle.italic),
      'red' => TextStyle(color: kDangerText),
      _ => null,
    };
    if (!t.isStudyWord) return base;
    // Ayuda visual discreta: las palabras con Strong llevan un subrayado
    // punteado tenue y cursor de enlace.
    return (base ?? const TextStyle()).copyWith(
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.dotted,
      decorationColor: kAccent.withValues(alpha: 0.28),
      decorationThickness: 1,
    );
  }

  InlineSpan _verseNumberSpan(int n) => WidgetSpan(
    alignment: PlaceholderAlignment.top,
    child: Padding(
      padding: const EdgeInsets.only(right: 1),
      child: Text('$n', style: readerMarkerStyle(font: _font)),
    ),
  );

  // --- Tarjeta de nota al pie (hover con ratón, click fija) ---------------

  final Map<String, GlobalKey> _footnoteMarkerKeys = {};

  /// Key estable por marcador (misma instancia entre builds: `GlobalObjectKey`
  /// usa identidad del valor, no igualdad de string).
  GlobalKey _footnoteMarkerKey(String id) => _footnoteMarkerKeys.putIfAbsent(
    id,
    () => GlobalObjectKey('reader-footnote-$id'),
  );
  Timer? _footnoteOpenTimer;
  Timer? _footnoteCloseTimer;

  /// Última posición global conocida del puntero (enter/exit del marcador y
  /// de la tarjeta): permite confirmar una salida real antes de cerrar.
  Offset? _footnotePointer;
  bool _footnotePinned = false;
  bool _footnoteOpen = false;
  String? _activeFootnoteId;
  String? _footnoteLabel; // etiqueta original del módulo (semántica, a11y)
  String _activeFootnoteGlyph = '*'; // símbolo visible en el marcador
  String? _footnoteText;

  /// Símbolo del indicador según el orden de la nota dentro del versículo.
  /// La «a» original se confunde con el texto; el asterisco es la convención
  /// clásica de notas del traductor.
  String _footnoteGlyph(int ordinal) {
    const glyphs = ['*', '†', '‡', '§', '¶'];
    if (ordinal < glyphs.length) return glyphs[ordinal];
    return '*';
  }

  InlineSpan _footnoteSpan(
    FootnoteRef f,
    ChapterDocument chapter,
    int ordinal,
  ) {
    final footnote = chapter.footnotes[f.id];
    final label = f.label ?? footnote?.label ?? '*';
    final glyph = _footnoteGlyph(ordinal);
    final text = footnote?.text ?? context.l10n.readerFootnoteUnavailable;
    if (_options.limitedView) {
      // Vista limitada: indicadores como texto llano (sin superposición).
      return TextSpan(
        text: ' ($text)',
        style: readerBodyStyle(
          size: 12.5,
          font: _font,
        ).copyWith(color: kTextSecondary),
      );
    }
    return WidgetSpan(
      alignment: PlaceholderAlignment.top,
      child: Padding(
        padding: const EdgeInsets.only(left: 1, right: 1),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (event) {
            _footnotePointer = event.position;
            _scheduleFootnoteHover(f.id, glyph, label, text);
          },
          onExit: (event) {
            _footnotePointer = event.position;
            _onFootnoteMarkerExit();
          },
          child: GestureDetector(
            onTapDown: (details) => _toggleFootnote(f.id, glyph, label, text),
            child: KeyedSubtree(
              // Para el cierre por clic fuera: el tap que abre/fija al
              // marcador no debe descartar su propia tarjeta.
              key: _footnoteMarkerKey(f.id),
              child: Semantics(
                button: true,
                label: context.l10n.readerFootnoteA11y(label, text),
                onTapHint: context.l10n.readerFootnoteOpenHint,
                excludeSemantics: true,
                child: Text(
                  glyph,
                  style: readerMarkerStyle(font: _font)
                      .copyWith(color: kAccent, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Hover en el marcador: con una demora breve (evita el parpadeo al pasar
  /// por encima leyendo) muestra la tarjeta sin fijar. Cancela un cierre
  /// pendiente: re-entrar al glifo mantiene la tarjeta abierta.
  void _scheduleFootnoteHover(
    String id,
    String glyph,
    String label,
    String text,
  ) {
    _footnoteCloseTimer?.cancel();
    _footnoteOpenTimer?.cancel();
    if (_footnoteOpen && _footnotePinned) return; // una fijada manda
    _footnoteOpenTimer = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      _openFootnoteCard(
        id: id,
        glyph: glyph,
        label: label,
        text: text,
        pinned: false,
      );
    });
  }

  /// Sale del glifo: si la tarjeta no está fijada se cierra con una demora
  /// breve. La salida del glifo es habitual (área mínima) y el cierre
  /// instantáneo parpadeaba en bucle; la gracia permite salir y volver.
  void _onFootnoteMarkerExit() {
    _footnoteOpenTimer?.cancel();
    if (!_footnoteOpen || _footnotePinned) return;
    _scheduleFootnoteClose();
  }

  /// Cierre diferido del hover. Al dispararse confirma que el puntero ya no
  /// está sobre el marcador ni la tarjeta: el framework entrega exits
  /// sintéticos al re-apilarse widgets (la tarjeta aparece sobre texto) y
  /// cerrar en ese punto produciría un ciclo abrir/cerrar.
  void _scheduleFootnoteClose() {
    _footnoteCloseTimer?.cancel();
    _footnoteCloseTimer = Timer(const Duration(milliseconds: 180), () {
      if (!mounted || !_footnoteOpen || _footnotePinned) return;
      final pointer = _footnotePointer;
      if (pointer != null) {
        final id = _activeFootnoteId;
        if (id != null && _containsGlobalKey(_footnoteMarkerKey(id), pointer)) {
          return;
        }
        if (_containsGlobalKey(_footnoteCardKey, pointer)) return;
      }
      _closeFootnoteCard();
    });
  }

  void _cancelFootnoteTimers() {
    _footnoteOpenTimer?.cancel();
    _footnoteCloseTimer?.cancel();
  }

  void _toggleFootnote(String id, String glyph, String label, String text) {
    _cancelFootnoteTimers();
    if (_footnoteOpen && _footnotePinned && _activeFootnoteId == id) {
      // Segundo clic sobre el mismo marcador: se desfija y cierra.
      _closeFootnoteCard();
      return;
    }
    _openFootnoteCard(
      id: id,
      glyph: glyph,
      label: label,
      text: text,
      pinned: true,
    );
  }

  /// Abre la tarjeta fijada o en hover. Antes de abrir recalcula el anclaje
  /// del marcador; si el marcador ya no está en el árbol (p. ej. cambió la
  /// página) no abre nada.
  void _openFootnoteCard({
    required String id,
    required String glyph,
    required String label,
    required String text,
    required bool pinned,
  }) {
    if (_markerLocalRect(id) == null) return;
    setState(() {
      _footnoteOpen = true;
      _activeFootnoteId = id;
      _activeFootnoteGlyph = glyph;
      _footnoteLabel = label;
      _footnoteText = text;
      _footnotePinned = pinned;
      _footnoteCardHeight = null; // se re-mide post-frame
    });
    _measureFootnoteCardAfterFrame();
  }

  void _closeFootnoteCard() {
    if (!_footnoteOpen) return;
    setState(() {
      _footnoteOpen = false;
      _footnotePinned = false;
      _activeFootnoteId = null;
      _footnoteCardHeight = null;
      _footnoteLabel = null;
      _footnoteText = null;
    });
  }

  /// Clic fuera de la tarjeta o del marcador activo cierra (aunque esté
  /// fijada). Se llama desde el guardia de punteros del lector.
  void _dismissFootnoteIfOutside(Offset position) {
    if (!_footnoteOpen) return;
    final id = _activeFootnoteId;
    if (id != null) {
      if (_containsGlobalKey(_footnoteMarkerKey(id), position)) {
        return; // clic en el propio marcador: el onTap alterna.
      }
    }
    if (_containsGlobalKey(_footnoteCardKey, position)) return;
    _closeFootnoteCard();
  }

  final GlobalKey _footnoteCardKey = GlobalKey();

  /// Rect del marcador [id] en coordenadas del Stack del lector. Se consulta
  /// en cada build (barato) para que el clamp sea fresco si algo se reajusta.
  Rect? _markerLocalRect(String id) {
    final markerEntry = _footnoteMarkerKey(id).currentContext;
    final stackEntry = _selectionStackKey.currentContext;
    if (markerEntry == null || stackEntry == null) return null;
    final markerBox = markerEntry.findRenderObject() as RenderBox?;
    final stackBox = stackEntry.findRenderObject() as RenderBox?;
    if (markerBox == null || stackBox == null) return null;
    if (!markerBox.attached || !stackBox.attached || !stackBox.hasSize) {
      return null;
    }
    final topLeft = stackBox.globalToLocal(
      markerBox.localToGlobal(Offset.zero),
    );
    final bottomRight = stackBox.globalToLocal(
      markerBox.localToGlobal(markerBox.size.bottomRight(Offset.zero)),
    );
    return Rect.fromPoints(topLeft, bottomRight);
  }

  static const double _footnoteCardMaxWidth = 360;
  static const double _footnoteCardGap = 10;
  static const double _footnoteCardMargin = 8;

  /// Posición (left, top, width) de la tarjeta, centrada sobre el marcador y
  /// clampada a los bordes del lector en ambos ejes. Con el alto ya medido
  /// post-frame, si desborda por abajo se coloca encima del marcador.
  (double, double, double)? _footnoteCardLayout(Rect marker) {
    final stackBox =
        _selectionStackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || !stackBox.hasSize) return null;
    final stackW = stackBox.size.width;
    final stackH = stackBox.size.height;
    if (stackW <= _footnoteCardMargin * 2) return null;
    var cardW = _footnoteCardMaxWidth;
    if (cardW > stackW - _footnoteCardMargin * 2) {
      cardW = stackW - _footnoteCardMargin * 2;
    }
    final left = (marker.center.dx - cardW / 2).clamp(
      _footnoteCardMargin,
      stackW - cardW - _footnoteCardMargin,
    );
    final h = _footnoteCardHeight;
    var top = marker.bottom + _footnoteCardGap;
    if (h != null && top + h > stackH - _footnoteCardMargin) {
      // Encima del marcador, sin pasar del borde superior.
      top = math.max(_footnoteCardMargin, marker.top - h - _footnoteCardGap);
    }
    return (left, top, cardW);
  }

  /// Mide el alto real de la tarjeta tras el frame en que abre: con el alto
  /// conocido el clamp vertical (flip por encima del marcador) es exacto.
  void _measureFootnoteCardAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_footnoteOpen) return;
      final cardEntry = _footnoteCardKey.currentContext;
      if (cardEntry == null) return;
      final cardBox = cardEntry.findRenderObject() as RenderBox?;
      if (cardBox == null || !cardBox.hasSize) return;
      final h = cardBox.size.height;
      final pending = _footnoteCardHeight;
      if (pending != null && (pending - h).abs() < 0.5) return;
      setState(() => _footnoteCardHeight = h);
      setState(() => _footnoteCardHeight = h);
    });
  }

  double? _footnoteCardHeight;

  Widget _buildFootnoteCard() {
    if (!_footnoteOpen) return const SizedBox.shrink();
    final label = _footnoteLabel;
    final text = _footnoteText;
    final id = _activeFootnoteId;
    if (label == null || text == null || id == null) {
      return const SizedBox.shrink();
    }
    final marker = _markerLocalRect(id);
    if (marker == null) {
      // El marcador desapareció del árbol (página cambiada, capítulo nuevo):
      // no mostrar una tarjeta huérfana desanclada.
      return const SizedBox.shrink();
    }
    final layout = _footnoteCardLayout(marker);
    if (layout == null) return const SizedBox.shrink();
    final (left, top, cardW) = layout;
    return Positioned(
      left: left,
      top: top,
      width: cardW,
      child: MouseRegion(
        cursor: SystemMouseCursors.basic,
        onEnter: (event) {
          _footnotePointer = event.position;
          // Entrar a la tarjeta cancela el cierre diferido: se puede leer o
          // seleccionar su contenido sin que se cierre.
          _footnoteCloseTimer?.cancel();
        },
        onExit: (event) {
          _footnotePointer = event.position;
          if (_footnotePinned) return;
          // Salir de la tarjeta reagenda el cierre con la misma gracia del
          // marcador; si el puntero vuelve (marcador o tarjeta) se cancela.
          _scheduleFootnoteClose();
        },
        child: KeyedSubtree(
          key: _footnoteCardKey,
          child: Material(
            key: const ValueKey('footnote-card'),
            color: kPanelBg,
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.readerFootnote(_activeFootnoteGlyph),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    text,
                    style: readerBodyStyle(size: 12.5, font: _font),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InlineSpan _xrefSpan(XrefLink x) {
    final canonical = parseReference(x.ref ?? x.label)?.canonical;
    final marker = Text(
      x.label,
      style: readerMarkerStyle(font: _font)
          .copyWith(color: kAccent, fontWeight: FontWeight.w600),
    );
    if (canonical == null) {
      return WidgetSpan(alignment: PlaceholderAlignment.top, child: marker);
    }
    return WidgetSpan(
      alignment: PlaceholderAlignment.top,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => widget.onNavigate(canonical),
          child: Tooltip(
            message: displayFromCanonical(canonical, lang: context.l10nLang),
            child: Semantics(
              onTapHint: context.l10n.readerXrefOpenHint,
              child: marker,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 26),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (!_atEnd && _sections.length >= _limit) {
      return Padding(
        padding: const EdgeInsets.only(top: 22),
        child: Center(
          child: TextButton(
            onPressed: () {
              setState(() => _limit += 60);
              _maybeFill();
            },
            child: Text(context.l10n.readerLoadMoreChapters),
          ),
        ),
      );
    }
    if (_atEnd) {
      return Padding(
        padding: const EdgeInsets.only(top: 30),
        child: Center(
          child: Text(
            context.l10n.readerEnd,
            style: TextStyle(fontSize: 12.5, color: kTextSecondary),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
