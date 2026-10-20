// Pruebas del núcleo de Notas (M4): modelo/persistencia, consultas, resolución
// de selecciones y markdown-lite. Sin widgets.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aletheia/notes/markdown_lite.dart';
import 'package:aletheia/notes/notes_controller.dart';
import 'package:aletheia/notes/notes_models.dart';
import 'package:aletheia/notes/notes_persistence.dart';
import 'package:aletheia/notes/notes_query.dart';
import 'package:aletheia/notes/selection_resolver.dart';

Note _note({
  String id = 'n1',
  String kind = 'note',
  String title = '',
  String body = '',
  List<NoteAnchor> anchors = const [],
  List<String> notebooks = const [],
  List<String> tags = const [],
  String color = 'yellow',
  DateTime? updatedAt,
  DateTime? deletedAt,
}) =>
    Note(
      id: id,
      kind: kind,
      title: title,
      body: body,
      anchors: anchors,
      notebooks: notebooks,
      tags: tags,
      color: color,
      createdAt: updatedAt ?? DateTime(2026, 1, 1),
      updatedAt: updatedAt ?? DateTime(2026, 1, 1),
      deletedAt: deletedAt,
    );

void main() {
  group('modelo y persistencia', () {
    test('Note/Notebook sobreviven al JSON', () {
      final state = NotesState(
        notes: [
          _note(
            id: 'a',
            title: 'Título',
            body: 'Cuerpo con **negrita**',
            anchors: const [
              NoteAnchor(
                resourceId: 'bible.rv1909',
                reference: 'JHN.1.8',
                bookCode: 'JHN',
                chapter: 1,
                verse: 8,
                startOffset: 3,
                endOffset: 12,
                quote: 'no era la luz',
              ),
            ],
            notebooks: ['nb1'],
            tags: ['fe'],
            updatedAt: DateTime(2026, 2, 3, 4, 5),
            deletedAt: DateTime(2026, 2, 4),
          ),
        ],
        notebooks: [Notebook(id: 'nb1', name: 'Sermones', createdAt: DateTime(2026))],
      );

      final restored = NotesState.fromJson(
        Map<String, dynamic>.from(state.toJson()),
      );
      expect(restored.notes, hasLength(1));
      final note = restored.notes.first;
      expect(note.id, 'a');
      expect(note.title, 'Título');
      expect(note.body, contains('**negrita**'));
      expect(note.anchors.first.reference, 'JHN.1.8');
      expect(note.anchors.first.startOffset, 3);
      expect(note.anchors.first.quote, 'no era la luz');
      expect(note.notebooks, ['nb1']);
      expect(note.tags, ['fe']);
      expect(note.updatedAt, DateTime(2026, 2, 3, 4, 5));
      expect(note.isTrashed, isTrue);
      expect(restored.notebooks.single.name, 'Sermones');
    });

    test('headline y preview derivan de título/cita/cuerpo', () {
      expect(_note(title: 'Hola', body: 'Línea 1\nLínea 2').headline, 'Hola');
      expect(_note(title: 'Hola', body: 'Línea 1\nLínea 2').preview, 'Línea 1');
      final quoted = _note(
        body: 'Comentario',
        anchors: const [
          NoteAnchor(resourceId: 'r', quote: 'En el principio'),
        ],
      );
      expect(quoted.headline, 'En el principio');
      expect(quoted.preview, 'Comentario');
    });
  });

  group('consultas', () {
    final notes = [
      _note(
        id: 'a',
        title: 'Gracia',
        body: 'nota sobre la gracia',
        tags: ['fe'],
        notebooks: ['nb1'],
        anchors: const [NoteAnchor(resourceId: 'bible.rv1909', reference: 'JHN.1.1')],
        updatedAt: DateTime(2026, 3, 3),
      ),
      _note(
        id: 'b',
        kind: 'highlight',
        color: 'green',
        anchors: const [
          NoteAnchor(
            resourceId: 'bible.kjv',
            reference: 'GEN.1.1',
            quote: 'In the beginning',
            startOffset: 0,
            endOffset: 3,
          ),
        ],
        updatedAt: DateTime(2026, 3, 5),
      ),
      _note(id: 'c', title: 'Vieja', deletedAt: DateTime(2026, 3, 6),
          updatedAt: DateTime(2026, 3, 6)),
    ];

    test('por defecto: activas, más recientes primero', () {
      final result = applyNotesQuery(notes, const NotesQuery());
      expect(result.map((n) => n.id), ['b', 'a']);
    });

    test('busca en título, cuerpo, cita, referencia y etiquetas', () {
      expect(applyNotesQuery(notes, const NotesQuery(text: 'gracia')).single.id, 'a');
      expect(applyNotesQuery(notes, const NotesQuery(text: 'JHN')).single.id, 'a');
      expect(applyNotesQuery(notes, const NotesQuery(text: 'beginning')).single.id, 'b');
      expect(applyNotesQuery(notes, const NotesQuery(text: 'fe')).single.id, 'a');
      expect(applyNotesQuery(notes, const NotesQuery(text: 'zzz')), isEmpty);
    });

    test('papelera, tipo, cuaderno, etiqueta y recurso', () {
      expect(applyNotesQuery(notes, const NotesQuery(trash: true)).single.id, 'c');
      expect(
        applyNotesQuery(notes, const NotesQuery(kinds: {'highlight'})).single.id,
        'b',
      );
      expect(
        applyNotesQuery(notes, const NotesQuery(notebooks: {'nb1'})).single.id,
        'a',
      );
      expect(applyNotesQuery(notes, const NotesQuery(tags: {'fe'})).single.id, 'a');
      expect(
        applyNotesQuery(notes, const NotesQuery(resourceId: 'bible.kjv')).single.id,
        'b',
      );
    });

    test('orden por creación y por cuaderno', () {
      final byCreated = applyNotesQuery(
        notes,
        const NotesQuery(sort: NotesSort.created),
      );
      expect(byCreated.map((n) => n.id), ['b', 'a']);
      // Por cuaderno: primero las notas de «Sermones» y al final las que no
      // tienen cuaderno (como el orden de cuadernos del original).
      final byNotebook = applyNotesQuery(
        notes,
        const NotesQuery(sort: NotesSort.notebook),
        notebookNames: const {'nb1': 'Sermones'},
      );
      expect(byNotebook.map((n) => n.id), ['a', 'b']);
    });

    test('etiquetas y recursos presentes', () {
      expect(allTags(notes), ['fe']);
      expect(anchoredResourceIds(notes), ['bible.kjv', 'bible.rv1909']);
    });

    test('proyecciones por versículo para el lector', () {
      final withHighlight = _note(
        id: 'h',
        kind: 'highlight',
        anchors: const [
          NoteAnchor(
            resourceId: 'r',
            bookCode: 'JHN',
            chapter: 1,
            verse: 1,
            startOffset: 0,
            endOffset: 5,
            reference: 'JHN.1.1',
          ),
        ],
      );
      final anchored = _note(
        id: 'n',
        anchors: const [
          NoteAnchor(
            resourceId: 'r',
            bookCode: 'JHN',
            chapter: 1,
            verse: 1,
            reference: 'JHN.1.1',
          ),
        ],
      );
      final other = _note(
        id: 'o',
        anchors: const [
          NoteAnchor(
            resourceId: 'r',
            bookCode: 'JHN',
            chapter: 2,
            verse: 3,
            reference: 'JHN.2.3',
          ),
        ],
      );
      final all = [withHighlight, anchored, other];
      final markers = notesByVerse(all, bookCode: 'JHN', chapter: 1);
      expect(markers[1]!.map((n) => n.id), ['n']);
      final highlights = highlightsByVerse(all, bookCode: 'JHN', chapter: 1);
      expect(highlights[1]!.single.noteId, 'h');
      expect(highlights[1]!.single.start, 0);
      expect(highlights[1]!.single.end, 5);
      expect(highlightsByVerse(all, bookCode: 'JHN', chapter: 1)[2], isNull);
    });
  });

  group('resolución de selecciones', () {
    const verses = [
      SelectionVerse(
        bookCode: 'JHN',
        chapter: 1,
        verse: 1,
        text: 'En el principio era el Verbo',
      ),
      SelectionVerse(
        bookCode: 'JHN',
        chapter: 1,
        verse: 2,
        text: 'Este era en el principio con Dios',
      ),
    ];

    test('coincidencia exacta con rango', () {
      final match = resolveSelection(selection: 'el principio', verses: verses);
      expect(match, isNotNull);
      expect(match!.verse, 1);
      expect(match.start, 3);
      expect(match.end, 15);
      expect(match.exact, isTrue);
    });

    test('normaliza espacios y salta de versículo', () {
      final match = resolveSelection(
        selection: 'Este   era en el principio',
        verses: verses,
      );
      expect(match!.verse, 2);
      expect(match.exact, isTrue);
    });

    test('selección larga que cruza versículos: ancla al primer versículo', () {
      final match = resolveSelection(
        selection: 'En el principio era el Verbo Este era en el principio con Dios',
        verses: verses,
      );
      expect(match, isNotNull);
      expect(match!.verse, 1);
      expect(match.exact, isFalse);
      expect(match.quote, contains('En el principio'));
    });

    test('sin coincidencia devuelve null', () {
      expect(resolveSelection(selection: 'nada que ver', verses: verses), isNull);
      expect(resolveSelection(selection: '   ', verses: verses), isNull);
    });
  });

  group('markdown-lite', () {
    test('wrapSelection envuelve, desenvuelve e inserta el par vacío', () {
      final wrapped = wrapSelection(
          'Hola mundo', const TextSelection(baseOffset: 0, extentOffset: 4), '**');
      expect(wrapped.text, '**Hola** mundo');
      expect(wrapped.selection.textInside(wrapped.text), 'Hola');

      final unwrapped = wrapSelection('**Hola** mundo',
          const TextSelection(baseOffset: 0, extentOffset: 8), '**');
      expect(unwrapped.text, 'Hola mundo');

      final empty = wrapSelection('abc', const TextSelection.collapsed(offset: 1), '*');
      expect(empty.text, 'a**bc');
      expect(empty.selection.baseOffset, 2);
    });

    test('prefixLines añade y quita prefijos', () {
      const source = 'uno\ndos';
      const sel = TextSelection(baseOffset: 0, extentOffset: 7);
      final bullets = prefixLines(source, sel, '- ');
      expect(bullets.text, '- uno\n- dos');
      final removed = prefixLines(bullets.text,
          const TextSelection(baseOffset: 0, extentOffset: 11), '- ');
      expect(removed.text, 'uno\ndos');
    });

    test('markdownToPlain limpia marcadores y viñetas', () {
      expect(
        markdownToPlain('**uno** y ==dos==\n- tres\n> cuatro'),
        'uno y dos\n• tres\n▏ cuatro',
      );
    });

    test('markdownSpans aplica estilos y prefijos', () {
      final spans = markdownSpans('a **b** <u>c</u> ==d== *e*',
          const TextStyle(fontSize: 12),
          highlightColor: const Color(0xFFFFF0A8));
      final texts = spans.whereType<TextSpan>().toList();
      TextSpan find(String text) => texts.firstWhere((s) => s.text == text);
      expect(find('a ').style!.fontWeight, isNull);
      expect(find('b').style!.fontWeight, FontWeight.w600);
      expect(find('c').style!.decoration, TextDecoration.underline);
      expect(find('d').style!.backgroundColor, isNotNull);
      expect(find('e').style!.fontStyle, FontStyle.italic);
      final bullets = markdownSpans('- item', const TextStyle());
      expect(bullets.whereType<TextSpan>().first.text, '• item');
    });
  });

  group('controlador', () {
    ProviderContainer container({NotesState? initial}) {
      final c = ProviderContainer(overrides: [
        notesStoreProvider.overrideWithValue(NotesStore.inMemory(initial)),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    test('crear, actualizar, papelera y restaurar', () {
      final c = container();
      final notifier = c.read(notesProvider.notifier);
      final id = notifier.createNote(title: 'Primera', body: 'texto');
      expect(c.read(notesProvider).notes.single.id, id);

      notifier.updateNote(id, body: 'texto editado');
      expect(c.read(notesProvider).notes.single.body, 'texto editado');

      notifier.trashNote(id);
      expect(c.read(notesProvider).notes.single.isTrashed, isTrue);
      expect(c.read(notesProvider).trashCount, 1);

      notifier.restoreNote(id);
      expect(c.read(notesProvider).notes.single.isTrashed, isFalse);

      notifier.purgeNote(id);
      expect(c.read(notesProvider).notes, isEmpty);
    });

    test('vaciar papelera respeta las notas activas', () {
      final c = container();
      final notifier = c.read(notesProvider.notifier);
      final a = notifier.createNote(title: 'A');
      final b = notifier.createNote(title: 'B');
      notifier.trashNote(b);
      notifier.emptyTrash();
      expect(c.read(notesProvider).notes.single.id, a);
    });

    test('duplicar copia el cuerpo y anota «(copia)»', () {
      final c = container();
      final notifier = c.read(notesProvider.notifier);
      final id = notifier.createNote(title: 'Original', body: 'x');
      final copy = notifier.duplicateNote(id)!;
      final note = notifier.noteById(copy)!;
      expect(note.title, 'Original (copia)');
      expect(note.body, 'x');
    });

    test('cuadernos: crear, asignar, renombrar y eliminar', () {
      final c = container();
      final notifier = c.read(notesProvider.notifier);
      final note = notifier.createNote(title: 'N');
      final nb = notifier.addNotebook('Sermones');
      notifier.toggleNotebookOnNote(note, nb);
      expect(notifier.noteById(note)!.notebooks, [nb]);

      notifier.renameNotebook(nb, 'Estudio');
      expect(notifier.notebookById(nb)!.name, 'Estudio');

      notifier.deleteNotebook(nb);
      expect(c.read(notesProvider).notebooks, isEmpty);
      expect(notifier.noteById(note)!.notebooks, isEmpty);
    });

    test('etiquetas y anclajes', () {
      final c = container();
      final notifier = c.read(notesProvider.notifier);
      final note = notifier.createNote(title: 'N');
      notifier.addTag(note, 'fe');
      notifier.addTag(note, ' fe '); // duplicada: se ignora
      notifier.addTag(note, 'esperanza');
      expect(notifier.noteById(note)!.tags, ['fe', 'esperanza']);
      notifier.removeTag(note, 'fe');
      expect(notifier.noteById(note)!.tags, ['esperanza']);

      notifier.setPrimaryAnchor(
        note,
        const NoteAnchor(resourceId: 'r', reference: 'JHN.1.1'),
      );
      notifier.addAnchor(
        note,
        const NoteAnchor(resourceId: 'r', reference: 'ROM.8.28'),
      );
      expect(notifier.noteById(note)!.anchors, hasLength(2));
      notifier.removeAnchor(note, 1);
      expect(notifier.noteById(note)!.anchors, hasLength(1));
    });

    test('resaltado creado con color', () {
      final c = container();
      final notifier = c.read(notesProvider.notifier);
      final id = notifier.createHighlight(
        anchor: const NoteAnchor(
          resourceId: 'r',
          bookCode: 'JHN',
          chapter: 1,
          verse: 1,
          startOffset: 0,
          endOffset: 4,
          reference: 'JHN.1.1',
        ),
        color: 'blue',
      );
      final note = notifier.noteById(id)!;
      expect(note.isHighlight, isTrue);
      expect(note.color, 'blue');
    });
  });
}
