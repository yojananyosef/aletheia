import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notes_models.dart';
import 'notes_persistence.dart';

/// Estado y operaciones de Notas (M4).
///
/// Guardado debounced (400 ms) igual que el workspace: cada mutación actualiza
/// el estado y programa la escritura del JSON completo.
final notesProvider = NotifierProvider<NotesController, NotesState>(
  NotesController.new,
);

class NotesController extends Notifier<NotesState> {
  Timer? _saveTimer;
  int _seq = 0;

  @override
  NotesState build() {
    ref.onDispose(() => _saveTimer?.cancel());
    // El almacén se carga (async) en `main()` y se inyecta por override, igual
    // que el workspace.
    return ref.read(notesStoreProvider).initial;
  }

  String _newId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_seq++}';

  void _commit(NotesState next) {
    state = next;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), () {
      ref.read(notesStoreProvider).save(state);
    });
  }

  // ------------------------------------------------------------------ notas

  String createNote({
    String kind = 'note',
    String title = '',
    String body = '',
    List<NoteAnchor> anchors = const [],
    List<String> notebooks = const [],
    List<String> tags = const [],
    String color = kDefaultHighlightColor,
    String style = kHighlightStyleHighlight,
  }) {
    final now = DateTime.now();
    final note = Note(
      id: _newId('note'),
      kind: kind,
      title: title,
      body: body,
      anchors: anchors,
      notebooks: notebooks,
      tags: tags,
      color: color,
      style: style,
      createdAt: now,
      updatedAt: now,
    );
    _commit(
      NotesState(notes: [...state.notes, note], notebooks: state.notebooks),
    );
    return note.id;
  }

  /// Crea un resaltado para una selección (sin abrir el editor).
  String createHighlight({
    required NoteAnchor anchor,
    String color = kDefaultHighlightColor,
    String style = kHighlightStyleHighlight,
    List<String> notebooks = const [],
  }) => createNote(
    kind: 'highlight',
    anchors: [anchor],
    color: color,
    style: style,
    notebooks: notebooks,
  );

  void updateNote(
    String id, {
    String? title,
    String? body,
    List<NoteAnchor>? anchors,
    List<String>? notebooks,
    List<String>? tags,
    String? color,
    String? style,
  }) {
    _commit(
      NotesState(
        notes: [
          for (final note in state.notes)
            note.id == id
                ? note.copyWith(
                    title: title,
                    body: body,
                    anchors: anchors,
                    notebooks: notebooks,
                    tags: tags,
                    color: color,
                    style: style,
                    updatedAt: DateTime.now(),
                  )
                : note,
        ],
        notebooks: state.notebooks,
      ),
    );
  }

  void addAnchor(String id, NoteAnchor anchor) {
    final note = noteById(id);
    if (note == null) return;
    updateNote(id, anchors: [...note.anchors, anchor]);
  }

  void removeAnchor(String id, int index) {
    final note = noteById(id);
    if (note == null || index < 0 || index >= note.anchors.length) return;
    final anchors = [...note.anchors]..removeAt(index);
    updateNote(id, anchors: anchors);
  }

  /// Sustituye el anclaje principal (cambio de referencia desde el editor).
  void setPrimaryAnchor(String id, NoteAnchor anchor) {
    final note = noteById(id);
    if (note == null) return;
    final anchors = [...note.anchors];
    if (anchors.isEmpty) {
      anchors.add(anchor);
    } else {
      anchors[0] = anchor;
    }
    updateNote(id, anchors: anchors);
  }

  void trashNote(String id) {
    _commit(
      NotesState(
        notes: [
          for (final note in state.notes)
            note.id == id
                ? note.copyWith(
                    deletedAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  )
                : note,
        ],
        notebooks: state.notebooks,
      ),
    );
  }

  void restoreNote(String id) {
    _commit(
      NotesState(
        notes: [
          for (final note in state.notes)
            note.id == id
                ? note.copyWith(clearDeletedAt: true, updatedAt: DateTime.now())
                : note,
        ],
        notebooks: state.notebooks,
      ),
    );
  }

  void purgeNote(String id) {
    _commit(
      NotesState(
        notes: [
          for (final note in state.notes)
            if (note.id != id) note,
        ],
        notebooks: state.notebooks,
      ),
    );
  }

  void emptyTrash() {
    _commit(
      NotesState(
        notes: [
          for (final note in state.notes)
            if (!note.isTrashed) note,
        ],
        notebooks: state.notebooks,
      ),
    );
  }

  /// Duplica una nota (título «(copia)», sin cuadernos del original).
  String? duplicateNote(String id) {
    final note = noteById(id);
    if (note == null) return null;
    final now = DateTime.now();
    final copy = Note(
      id: _newId('note'),
      kind: note.kind,
      title: note.title.isEmpty ? '' : '${note.title} (copia)',
      body: note.body,
      anchors: note.anchors,
      tags: note.tags,
      color: note.color,
      createdAt: now,
      updatedAt: now,
    );
    _commit(
      NotesState(notes: [...state.notes, copy], notebooks: state.notebooks),
    );
    return copy.id;
  }

  void toggleNotebookOnNote(String noteId, String notebookId) {
    final note = noteById(noteId);
    if (note == null) return;
    final notebooks = [...note.notebooks];
    notebooks.contains(notebookId)
        ? notebooks.remove(notebookId)
        : notebooks.add(notebookId);
    updateNote(noteId, notebooks: notebooks);
  }

  void addTag(String noteId, String tag) {
    final clean = tag.trim();
    if (clean.isEmpty) return;
    final note = noteById(noteId);
    if (note == null || note.tags.contains(clean)) return;
    updateNote(noteId, tags: [...note.tags, clean]);
  }

  void removeTag(String noteId, String tag) {
    final note = noteById(noteId);
    if (note == null) return;
    updateNote(noteId, tags: [...note.tags]..remove(tag));
  }

  Note? noteById(String id) {
    for (final note in state.notes) {
      if (note.id == id) return note;
    }
    return null;
  }

  // -------------------------------------------------------------- cuadernos

  String addNotebook(String name) {
    final clean = name.trim();
    final now = DateTime.now();
    final notebook = Notebook(
      id: _newId('nb'),
      name: clean.isEmpty ? 'Cuaderno' : clean,
      createdAt: now,
    );
    _commit(
      NotesState(notes: state.notes, notebooks: [...state.notebooks, notebook]),
    );
    return notebook.id;
  }

  void renameNotebook(String id, String name) {
    final clean = name.trim();
    if (clean.isEmpty) return;
    _commit(
      NotesState(
        notes: state.notes,
        notebooks: [
          for (final notebook in state.notebooks)
            notebook.id == id
                ? Notebook(
                    id: notebook.id,
                    name: clean,
                    createdAt: notebook.createdAt,
                  )
                : notebook,
        ],
      ),
    );
  }

  /// Elimina un cuaderno y lo quita de las notas.
  void deleteNotebook(String id) {
    _commit(
      NotesState(
        notes: [
          for (final note in state.notes)
            note.notebooks.contains(id)
                ? note.copyWith(notebooks: [...note.notebooks]..remove(id))
                : note,
        ],
        notebooks: [
          for (final notebook in state.notebooks)
            if (notebook.id != id) notebook,
        ],
      ),
    );
  }

  Notebook? notebookById(String id) {
    for (final notebook in state.notebooks) {
      if (notebook.id == id) return notebook;
    }
    return null;
  }
}
