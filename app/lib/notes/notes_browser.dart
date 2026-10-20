/// Navegador de Notas (M4): barra de búsqueda, filtros, papelera, lista y
/// editor. Lo comparten el panel global de Notas y el modo «Notas» del lector;
/// el padre decide el ámbito (`resourceId`) y qué hacer al mostrar en el lector.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization.dart';
import '../core/theme.dart';
import 'markdown_lite.dart';
import 'note_editor.dart';
import 'notes_controller.dart';
import 'notes_models.dart';
import 'notes_query.dart';
import 'notes_ui.dart';

class NotesBrowser extends ConsumerStatefulWidget {
  const NotesBrowser({
    super.key,
    this.resourceId,
    this.defaultAnchor,
    this.onShowInReader,
    this.groupByReference = false,
    this.emptyTitle,
    this.emptyHint,
    this.showToolbar = true,
    this.focusNoteId,
  });

  /// Si no es `null`, el navegador queda fijado a las notas de ese recurso.
  final String? resourceId;

  /// Anclaje de las notas nuevas (referencia actual del lector).
  final NoteAnchor? defaultAnchor;

  /// Navega al anclaje en el lector.
  final void Function(Note note)? onShowInReader;

  /// Agrupa por referencia (modo del lector).
  final bool groupByReference;

  final String? emptyTitle;
  final String? emptyHint;

  /// La barra superior (Buscar/Compartir/Nueva nota/⋮).
  final bool showToolbar;

  /// Abre el editor de esa nota al aparecer (o al cambiar de nota).
  final String? focusNoteId;

  @override
  ConsumerState<NotesBrowser> createState() => _NotesBrowserState();
}

class _NotesBrowserState extends ConsumerState<NotesBrowser> {
  final _findController = TextEditingController();
  NotesQuery _query = const NotesQuery();
  String? _editingId;

  /// Barra lateral interna (Filtros | Cuadernos), como el panel del original.
  bool _sidebarOpen = false;
  String _sidebarTab = 'filters';

  /// Densidad de la lista: `Predeterminado` o `Compacto`.
  bool _compactDensity = false;

  @override
  void initState() {
    super.initState();
    _query = NotesQuery(resourceId: widget.resourceId);
    _editingId = widget.focusNoteId;
  }

  @override
  void didUpdateWidget(NotesBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resourceId != oldWidget.resourceId) {
      setState(
        () => _query = _query.copyWith(
          resourceId: widget.resourceId,
          clearResource: widget.resourceId == null,
        ),
      );
    }
    if (widget.focusNoteId != null &&
        widget.focusNoteId != oldWidget.focusNoteId) {
      setState(() => _editingId = widget.focusNoteId);
    }
  }

  @override
  void dispose() {
    _findController.dispose();
    super.dispose();
  }

  void _setQuery(NotesQuery query) => setState(() => _query = query);

  void _createNote({bool anchored = true}) {
    final anchor = anchored ? widget.defaultAnchor : null;
    final id = ref
        .read(notesProvider.notifier)
        .createNote(anchors: anchor == null ? const [] : [anchor]);
    setState(() {
      _editingId = id;
      if (anchor != null) {
        // Una nota nueva se ve aunque haya filtros de texto o papelera.
        _query = _query.copyWith(text: '', trash: false);
        _findController.clear();
      }
    });
  }

  void _shareEditing(bool markdown) {
    final id = _editingId;
    if (id == null) return;
    final note = ref.read(notesProvider.notifier).noteById(id);
    if (note == null) return;
    final buffer = StringBuffer();
    if (note.title.trim().isNotEmpty) {
      buffer.writeln('# ${note.title.trim()}\n');
    }
    if (note.quote != null) buffer.writeln('> ${note.quote}\n');
    if (note.body.trim().isNotEmpty) buffer.writeln(note.body.trim());
    final anchor = note.mainAnchor;
    if (anchor?.reference != null) {
      buffer.writeln('\n— ${noteAnchorLabel(anchor, lang: context.l10nLang)}');
    }
    final clipboardText = markdown
        ? buffer.toString().trim()
        : markdownToPlain(buffer.toString());
    Clipboard.setData(ClipboardData(text: clipboardText));
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(context.l10n.noteShareCopied),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _newNotebook() async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.notesNewNotebook),
        content: SizedBox(
          width: 320,
          child: TextField(
            key: const Key('notebook-name-field'),
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.notesNotebookName,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (text) => Navigator.of(context).pop(text),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
          FilledButton(
            key: const Key('notebook-create'),
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l10n.notesNotebookCreate),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    ref.read(notesProvider.notifier).addNotebook(name);
    if (mounted) setState(() {});
  }

  /// Gestión mínima de cuadernos: renombrar o eliminar (las notas no se
  /// eliminan, solo se quitan del cuaderno).
  Future<void> _manageNotebooks() async {
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(notesProvider);
          return AlertDialog(
            title: Text(l10n.notesNotebooks),
            content: SizedBox(
              width: 360,
              child: state.notebooks.isEmpty
                  ? Text(l10n.notesNotebookEmpty)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final notebook in state.notebooks)
                          ListTile(
                            key: Key('notebook-row-${notebook.id}'),
                            dense: true,
                            title: Text(
                              notebook.name,
                              style: const TextStyle(fontSize: 13.5),
                            ),
                            subtitle: Text(
                              l10n.notesNotebookNotes(
                                state.notes
                                    .where(
                                      (n) => n.notebooks.contains(notebook.id),
                                    )
                                    .length,
                              ),
                              style: const TextStyle(fontSize: 11.5),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  key: Key('notebook-rename-${notebook.id}'),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                  ),
                                  tooltip: l10n.notesRename,
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                    _promptRename(notebook.id, notebook.name);
                                  },
                                ),
                                IconButton(
                                  key: Key('notebook-delete-${notebook.id}'),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                  ),
                                  tooltip: l10n.notesPurge,
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                    _confirmDeleteNotebook(
                                      notebook.id,
                                      notebook.name,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.close),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _promptRename(String id, String current) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.notesRename),
        content: SizedBox(
          width: 320,
          child: TextField(
            key: const Key('notebook-rename-field'),
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            onSubmitted: (text) => Navigator.of(context).pop(text),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
          FilledButton(
            key: const Key('notebook-rename-save'),
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l10n.notesRename),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    ref.read(notesProvider.notifier).renameNotebook(id, name);
  }

  Future<void> _confirmDeleteNotebook(String id, String name) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.notesNotebookDeleteTitle(name)),
        content: Text(l10n.notesNotebookDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.close),
          ),
          FilledButton(
            key: const Key('notebook-delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.notesPurge),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    ref.read(notesProvider.notifier).deleteNotebook(id);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notesProvider);
    final l10n = context.l10n;

    if (_editingId != null) {
      final exists = state.notes.any((note) => note.id == _editingId);
      if (!exists) _editingId = null;
    }

    final notebookNames = {
      for (final notebook in state.notebooks) notebook.id: notebook.name,
    };
    final notes = applyNotesQuery(
      state.notes,
      _query,
      notebookNames: notebookNames,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showToolbar) _buildToolbar(state),
        if (_editingId == null) ...[
          _buildHeader(notes.length),
          _buildControls(state),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_sidebarOpen) ...[
                  SizedBox(width: 200, child: _buildSidebar(state)),
                  VerticalDivider(width: 1, thickness: 1, color: kBorder),
                ],
                Expanded(
                  child: notes.isEmpty
                      ? _EmptyState(
                          title: _query.trash
                              ? l10n.notesTrashEmpty
                              : (widget.emptyTitle ?? l10n.notesEmpty),
                          hint: _query.trash
                              ? l10n.notesTrashHint
                              : (widget.emptyHint ?? l10n.notesEmptyHint),
                        )
                      : _buildList(notes, notebookNames),
                ),
              ],
            ),
          ),
        ] else
          Expanded(
            child: NoteEditorView(
              key: ValueKey(_editingId),
              noteId: _editingId!,
              defaultResourceId: widget.resourceId,
              onClose: () => setState(() => _editingId = null),
              onShowInReader: widget.onShowInReader == null
                  ? null
                  : () {
                      final note = ref
                          .read(notesProvider.notifier)
                          .noteById(_editingId!);
                      if (note != null) widget.onShowInReader!(note);
                    },
            ),
          ),
      ],
    );
  }

  // --------------------------------------------------------------- barras

  Widget _buildToolbar(NotesState state) {
    final l10n = context.l10n;
    final lang = context.l10nLang;
    final anchor = widget.defaultAnchor;
    final anchorRef = anchor == null ? '' : noteAnchorLabel(anchor, lang: lang);
    final newNoteLabel = anchorRef.isEmpty
        ? l10n.notesNewNote
        : l10n.notesNewNoteInRef(anchorRef);

    return LayoutBuilder(
      builder: (context, constraints) {
        // En paneles angostos la etiqueta de «Nueva nota» no entra: queda el
        // icono con tooltip (el panel se puede redimensionar).
        final compact = constraints.maxWidth < 470;
        return Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: kBorder)),
          ),
          child: Row(
            children: [
              IconButton(
                key: const Key('notes-sidebar-toggle'),
                tooltip: l10n.notesSidebarToggle,
                onPressed: () => setState(() => _sidebarOpen = !_sidebarOpen),
                icon: const Icon(Icons.menu, size: 17),
                color: _sidebarOpen ? kAccent : kTextSecondary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 30,
                  height: 28,
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 28,
                  child: TextField(
                    key: const Key('notes-find-field'),
                    controller: _findController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: l10n.notesFindHint,
                      hintStyle: TextStyle(fontSize: 13, color: kTextSecondary),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 16,
                        color: kTextSecondary,
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) =>
                        _setQuery(_query.copyWith(text: value)),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                key: const Key('notes-share-menu'),
                tooltip: l10n.notesShare,
                enabled: _editingId != null,
                padding: EdgeInsets.zero,
                onSelected: (value) => _shareEditing(value == 'markdown'),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'markdown',
                    child: Text(
                      l10n.noteShareMarkdown,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'text',
                    child: Text(
                      l10n.noteShareText,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  child: Icon(
                    Icons.ios_share,
                    size: 16,
                    color: _editingId == null ? kTextSecondary : kAccent,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              if (compact)
                IconButton.filled(
                  key: const Key('notes-new-note'),
                  onPressed: _createNote,
                  tooltip: newNoteLabel,
                  icon: const Icon(Icons.add, size: 16),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 30,
                    height: 26,
                  ),
                )
              else
                // Botón dividido del original: la acción principal crea la nota
                // en el contexto actual y la flecha permite crearla en blanco.
                Container(
                  height: 27,
                  decoration: BoxDecoration(
                    color: kAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        key: const Key('notes-new-note'),
                        onTap: _createNote,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.add,
                                size: 15,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 190,
                                ),
                                child: Text(
                                  newNoteLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(width: 1, height: 15, color: Colors.white30),
                      PopupMenuButton<bool>(
                        key: const Key('notes-new-note-menu'),
                        tooltip: l10n.notesNewNote,
                        padding: EdgeInsets.zero,
                        onSelected: (anchored) =>
                            _createNote(anchored: anchored),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: false,
                            child: Text(
                              l10n.notesNewNote,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          if (anchor != null)
                            PopupMenuItem(
                              value: true,
                              child: Text(
                                newNoteLabel,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                        ],
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 3),
                          child: Icon(
                            Icons.arrow_drop_down,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              PopupMenuButton<String>(
                key: const Key('notes-panel-menu'),
                tooltip: l10n.panelCommands,
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (value) {
                  switch (value) {
                    case 'notebook':
                      _newNotebook();
                    case 'manage-notebooks':
                      _manageNotebooks();
                    case 'empty-trash':
                      ref.read(notesProvider.notifier).emptyTrash();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'notebook',
                    child: Text(
                      l10n.notesNewNotebook,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'manage-notebooks',
                    child: Text(
                      l10n.notesNotebooks,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'empty-trash',
                    child: Text(
                      l10n.notesEmptyTrashAction,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Fila del ámbito con el recuento, como «Todos (1 resultado)» del original.
  Widget _buildHeader(int count) {
    final l10n = context.l10n;
    final filters = _query.activeFilterCount;
    final label =
        '${_query.trash ? l10n.notesTrash : l10n.notesAll} (${l10n.notesResults(count)})';

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              key: const Key('notes-scope-all'),
              onTap: () => _setQuery(
                NotesQuery(
                  text: _query.text,
                  sort: _query.sort,
                  resourceId: widget.resourceId,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                  ),
                ),
              ),
            ),
          ),
          if (filters > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                l10n.notesFiltersActive(filters),
                style: const TextStyle(fontSize: 11.5, color: kAccent),
              ),
            ),
        ],
      ),
    );
  }

  /// Densidad de la lista y orden (fecha de creación / modificación / cuaderno).
  Widget _buildControls(NotesState state) {
    final l10n = context.l10n;
    final sortLabel = switch (_query.sort) {
      NotesSort.created => l10n.notesByCreated,
      NotesSort.modified => l10n.notesByModified,
      NotesSort.notebook => l10n.notesByNotebook,
    };
    const item = TextStyle(fontSize: 13);

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Row(
        children: [
          PopupMenuButton<bool>(
            key: const Key('notes-density'),
            tooltip: l10n.notesDensity,
            padding: EdgeInsets.zero,
            onSelected: (compact) => setState(() => _compactDensity = compact),
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: false,
                checked: !_compactDensity,
                child: Text(l10n.notesDensityDefault, style: item),
              ),
              CheckedPopupMenuItem(
                value: true,
                checked: _compactDensity,
                child: Text(l10n.notesDensityCompact, style: item),
              ),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.filter_alt_outlined,
                  size: 15,
                  color: kTextSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _compactDensity
                      ? l10n.notesDensityCompact
                      : l10n.notesDensityDefault,
                  style: TextStyle(fontSize: 12, color: kTextSecondary),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 15,
                  color: kTextSecondary,
                ),
              ],
            ),
          ),
          const Spacer(),
          PopupMenuButton<NotesSort>(
            key: const Key('notes-sort-button'),
            tooltip: l10n.notesSortBy(sortLabel),
            padding: EdgeInsets.zero,
            onSelected: (sort) => _setQuery(_query.copyWith(sort: sort)),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: NotesSort.created,
                child: Text(l10n.notesByCreated, style: item),
              ),
              PopupMenuItem(
                value: NotesSort.modified,
                child: Text(l10n.notesByModified, style: item),
              ),
              PopupMenuItem(
                value: NotesSort.notebook,
                enabled: _query.notebooks.isNotEmpty,
                child: Tooltip(
                  message: _query.notebooks.isEmpty
                      ? l10n.notesSortNotebookHint
                      : '',
                  child: Text(
                    l10n.notesByNotebook,
                    style: TextStyle(
                      fontSize: 13,
                      color: _query.notebooks.isEmpty
                          ? kTextSecondary
                          : kTextPrimary,
                    ),
                  ),
                ),
              ),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 170),
                  child: Text(
                    l10n.notesSortBy(sortLabel),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: kTextSecondary),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 15,
                  color: kTextSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Barra lateral interna de 200 px: Filtros | Cuadernos y Papelera al pie.
  Widget _buildSidebar(NotesState state) {
    final l10n = context.l10n;
    final trashed = state.notes.where((note) => note.isTrashed).length;
    return Container(
      color: kPanelBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 32,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: kBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SidebarTab(
                    key: const Key('notes-filters-button'),
                    label: l10n.notesFilters,
                    active: _sidebarTab == 'filters',
                    onTap: () => setState(() => _sidebarTab = 'filters'),
                  ),
                ),
                Expanded(
                  child: _SidebarTab(
                    key: const Key('notes-notebooks-button'),
                    label: l10n.notesNotebooks,
                    active: _sidebarTab == 'notebooks',
                    onTap: () => setState(() => _sidebarTab = 'notebooks'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
              child: _sidebarTab == 'filters'
                  ? _filtersBody(state)
                  : _notebooksBody(state),
            ),
          ),
          Divider(height: 1, color: kBorder),
          InkWell(
            key: const Key('notes-trash-toggle'),
            onTap: () => _setQuery(_query.copyWith(trash: !_query.trash)),
            child: Container(
              color: _query.trash
                  ? kAccent.withValues(alpha: 0.12)
                  : Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 15,
                    color: _query.trash ? kAccent : kTextSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.notesTrash,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: _query.trash ? kAccent : kTextPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '$trashed',
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

  Widget _filtersBody(NotesState state) => _FiltersBody(
    kinds: _query.kinds,
    tags: allTags(state.notes),
    selectedTags: _query.tags,
    resources: widget.resourceId == null
        ? anchoredResourceIds(state.notes)
        : const [],
    selectedResource: _query.resourceId,
    onToggleKind: (kind) =>
        _setQuery(_query.copyWith(kinds: _toggle(_query.kinds, kind))),
    onToggleTag: (tag) =>
        _setQuery(_query.copyWith(tags: _toggle(_query.tags, tag))),
    onToggleResource: (id) => _setQuery(
      _query.resourceId == id
          ? _query.copyWith(clearResource: true, resourceId: widget.resourceId)
          : _query.copyWith(resourceId: id),
    ),
    onClear: () => _setQuery(
      NotesQuery(
        text: _query.text,
        trash: _query.trash,
        sort: _query.sort,
        resourceId: widget.resourceId,
      ),
    ),
  );

  Widget _notebooksBody(NotesState state) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final notebook in state.notebooks)
          _KindRow(
            key: Key('notes-notebook-filter-${notebook.id}'),
            label: notebook.name,
            checked: _query.notebooks.contains(notebook.id),
            onTap: () => _setQuery(
              _query.copyWith(
                notebooks: _toggle(_query.notebooks, notebook.id),
              ),
            ),
          ),
        if (state.notebooks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              l10n.notesNotebookEmpty,
              style: TextStyle(fontSize: 12, color: kTextSecondary),
            ),
          ),
        const SizedBox(height: 8),
        InkWell(
          key: const Key('notes-notebook-create'),
          onTap: _newNotebook,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.add, size: 15, color: kAccent),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    l10n.notesNewNotebook,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: kAccent),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (state.notebooks.isNotEmpty)
          InkWell(
            key: const Key('notes-notebook-manage'),
            onTap: _manageNotebooks,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.settings_outlined,
                    size: 15,
                    color: kTextSecondary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      l10n.notesRename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: kTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ----------------------------------------------------------------- lista

  Widget _buildList(List<Note> notes, Map<String, String> notebookNames) {
    final cards = <Widget>[];
    if (!widget.groupByReference) {
      for (final note in notes) {
        cards.add(_card(note, notebookNames));
      }
      return ListView(children: cards);
    }

    // Agrupadas por referencia (modo del lector).
    final l10n = context.l10n;
    final lang = context.l10nLang;
    final groups = <String, List<Note>>{};
    for (final note in notes) {
      final label = note.mainAnchor == null
          ? l10n.notesNoAnchor
          : noteAnchorLabel(note.mainAnchor, lang: lang);
      groups.putIfAbsent(label, () => []).add(note);
    }
    for (final entry in groups.entries) {
      cards.add(
        Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
          child: Text(
            entry.key,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kTextSecondary,
            ),
          ),
        ),
      );
      for (final note in entry.value) {
        cards.add(_card(note, notebookNames));
      }
    }
    return ListView(children: cards);
  }

  Widget _card(Note note, Map<String, String> notebookNames) => NoteCard(
    note: note,
    dense: _compactDensity,
    showAnchor: !widget.groupByReference,
    notebookNames: [
      for (final id in note.notebooks)
        if (notebookNames[id] != null) notebookNames[id]!,
    ],
    onTap: () => setState(() => _editingId = note.id),
    onEdit: () => setState(() => _editingId = note.id),
    onShowInReader: widget.onShowInReader == null
        ? null
        : () => widget.onShowInReader!(note),
    onTrash: () => ref.read(notesProvider.notifier).trashNote(note.id),
    onRestore: () => ref.read(notesProvider.notifier).restoreNote(note.id),
    onPurge: () => ref.read(notesProvider.notifier).purgeNote(note.id),
  );
}

Set<String> _toggle(Set<String> set, String value) {
  final next = {...set};
  next.contains(value) ? next.remove(value) : next.add(value);
  return next;
}

class _FiltersBody extends StatelessWidget {
  const _FiltersBody({
    required this.kinds,
    required this.tags,
    required this.selectedTags,
    required this.resources,
    required this.selectedResource,
    required this.onToggleKind,
    required this.onToggleTag,
    required this.onToggleResource,
    required this.onClear,
  });

  final Set<String> kinds;
  final List<String> tags;
  final Set<String> selectedTags;
  final List<String> resources;
  final String? selectedResource;
  final ValueChanged<String> onToggleKind;
  final ValueChanged<String> onToggleTag;
  final ValueChanged<String> onToggleResource;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasFilters =
        kinds.isNotEmpty || selectedTags.isNotEmpty || selectedResource != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              l10n.notesFilters,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
            const Spacer(),
            if (hasFilters)
              Flexible(
                child: InkWell(
                  key: const Key('notes-filters-clear'),
                  onTap: onClear,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      l10n.notesFiltersClear,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: kAccent),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.notesFilterKind,
          style: TextStyle(fontSize: 11.5, color: kTextSecondary),
        ),
        _KindRow(
          key: const Key('notes-filter-kind-note'),
          label: l10n.notesFilterKindNote,
          checked: kinds.contains('note'),
          onTap: () => onToggleKind('note'),
        ),
        _KindRow(
          key: const Key('notes-filter-kind-highlight'),
          label: l10n.notesFilterKindHighlight,
          checked: kinds.contains('highlight'),
          onTap: () => onToggleKind('highlight'),
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            l10n.notesFilterTag,
            style: TextStyle(fontSize: 11.5, color: kTextSecondary),
          ),
          for (final tag in tags)
            _KindRow(
              key: Key('notes-filter-tag-$tag'),
              label: '#$tag',
              checked: selectedTags.contains(tag),
              onTap: () => onToggleTag(tag),
            ),
        ],
        if (resources.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            l10n.notesFilterResource,
            style: TextStyle(fontSize: 11.5, color: kTextSecondary),
          ),
          for (final resource in resources)
            _KindRow(
              key: Key('notes-filter-resource-$resource'),
              label: resource,
              checked: selectedResource == resource,
              onTap: () => onToggleResource(resource),
            ),
        ],
      ],
    );
  }
}

/// Pestaña de la barra lateral interna (Filtros | Cuadernos).
class _SidebarTab extends StatelessWidget {
  const _SidebarTab({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? kAccent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? kAccent : kTextSecondary,
          ),
        ),
      ),
    );
  }
}

class _KindRow extends StatelessWidget {
  const _KindRow({
    super.key,
    required this.label,
    required this.checked,
    this.onTap,
  });

  final String label;
  final bool checked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(
              checked ? Icons.check_box : Icons.check_box_outline_blank,
              size: 15,
              color: checked ? kAccent : kTextSecondary,
            ),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12.5, color: kTextPrimary)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sticky_note_2_outlined, size: 34, color: kTextSecondary),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: kTextSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
