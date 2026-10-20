// Persistencia SQLite (M4.3): ida y vuelta de workspace y notas, e importación
// de los JSON de M0–M4.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:aletheia/core/database.dart';
import 'package:aletheia/notes/notes_models.dart';
import 'package:aletheia/notes/notes_persistence.dart';
import 'package:aletheia/workspace/models.dart';
import 'package:aletheia/workspace/persistence.dart';

void main() {
  group('SQLite', () {
    test('el workspace sobrevive con tiles, pestañas, historial y vista', () {
      final db = AletheiaDatabase.memory();
      addTearDown(db.close);

      final state = WorkspaceState(
        layoutId: 'four',
        toolbarLocation: 'top',
        locale: 'en',
        themeMode: 'dark',
        citationStyle: 'sbl',
        limitedView: true,
        catalogMode: 'local',
        savedLayouts: [
          SavedLayout(
            id: 'layout_1',
            name: 'Estudio',
            layoutId: 'three',
            tiles: [
              WorkspaceTile(
                id: 'ls1',
                tabs: [
                  WorkspaceTab(
                    id: 'lt1',
                    kind: PanelKind.factbook,
                    title: 'Temas',
                  ),
                ],
              ),
            ],
          ),
        ],
        tiles: [
          WorkspaceTile(
            id: 't1',
            activeIndex: 1,
            tabs: [
              WorkspaceTab(
                id: 'a',
                kind: PanelKind.bible,
                title: 'RV1909',
                reference: 'JHN.1.2',
                resourceId: 'bible.rv1909',
                linkSet: 'B',
                history: ['JHN.1.1', 'JHN.1.2'],
                historyIndex: 1,
              ),
              WorkspaceTab(
                id: 'b',
                kind: PanelKind.notes,
                title: 'Notas',
                display: const TabDisplay(paged: true, columns: '2', zoom: 150),
              ),
            ],
          ),
          WorkspaceTile(id: 't2'),
        ],
      );

      db.saveWorkspace(state);
      final restored = WorkspaceStore.onDatabase(db).initial;

      expect(restored.layoutId, 'four');
      expect(restored.toolbarLocation, 'top');
      expect(restored.locale, 'en');
      expect(restored.themeMode, 'dark');
      expect(restored.citationStyle, 'sbl');
      expect(restored.limitedView, isTrue);
      expect(restored.catalogMode, 'local');
      expect(restored.tiles, hasLength(2));
      expect(restored.tiles.first.activeIndex, 1);
      final bible = restored.tiles.first.tabs.first;
      expect(bible.kind, PanelKind.bible);
      expect(bible.reference, 'JHN.1.2');
      expect(bible.resourceId, 'bible.rv1909');
      expect(bible.linkSet, 'B');
      expect(bible.history, ['JHN.1.1', 'JHN.1.2']);
      expect(bible.historyIndex, 1);
      final notes = restored.tiles.first.tabs.last;
      expect(notes.kind, PanelKind.notes);
      expect(notes.display.paged, isTrue);
      expect(notes.display.columns, '2');
      expect(notes.display.zoom, 150);
      expect(restored.tiles.last.tabs, isEmpty);
      final saved = restored.savedLayouts.single;
      expect(saved.name, 'Estudio');
      expect(saved.layoutId, 'three');
      expect(saved.tiles.single.tabs.single.kind, PanelKind.factbook);
    });

    test('las notas, anclajes, cuadernos y etiquetas sobreviven', () {
      final db = AletheiaDatabase.memory();
      addTearDown(db.close);

      final state = NotesState(
        notebooks: [
          Notebook(
            id: 'nb1',
            name: 'Sermones',
            createdAt: DateTime(2026, 1, 2),
          ),
        ],
        notes: [
          Note(
            id: 'n1',
            title: 'Gracia',
            body: 'Cuerpo **con formato**',
            anchors: const [
              NoteAnchor(
                resourceId: 'bible.rv1909',
                reference: 'JHN.1.8',
                bookCode: 'JHN',
                chapter: 1,
                verse: 8,
                verseEnd: 9,
                startOffset: 3,
                endOffset: 12,
                quote: 'no era la luz',
              ),
              NoteAnchor(resourceId: 'bible.kjv', reference: 'GEN.1.1'),
            ],
            notebooks: const ['nb1'],
            tags: const ['fe', 'gracia'],
            color: 'green',
            style: kHighlightStyleUnderline,
            createdAt: DateTime(2026, 2, 3, 4, 5),
            updatedAt: DateTime(2026, 2, 3, 4, 6),
          ),
          Note(
            id: 'n2',
            kind: 'highlight',
            color: 'orange',
            createdAt: DateTime(2026, 2, 4),
            updatedAt: DateTime(2026, 2, 5),
            deletedAt: DateTime(2026, 2, 6),
          ),
        ],
      );

      db.saveNotes(state);
      final restored = NotesStore.onDatabase(db).initial;

      expect(restored.notebooks.single.name, 'Sermones');
      expect(restored.notes, hasLength(2));
      final note = restored.notes.firstWhere((n) => n.id == 'n1');
      expect(note.title, 'Gracia');
      expect(note.body, contains('**con formato**'));
      expect(note.color, 'green');
      expect(note.style, kHighlightStyleUnderline);
      expect(note.isUnderline, isTrue);
      expect(note.notebooks, ['nb1']);
      expect(note.tags, ['fe', 'gracia']);
      expect(note.anchors, hasLength(2));
      expect(note.anchors.first.reference, 'JHN.1.8');
      expect(note.anchors.first.verseEnd, 9);
      expect(note.anchors.first.startOffset, 3);
      expect(note.anchors.first.quote, 'no era la luz');
      expect(note.anchors.last.resourceId, 'bible.kjv');
      final trashed = restored.notes.firstWhere((n) => n.id == 'n2');
      expect(trashed.isTrashed, isTrue);
      expect(trashed.deletedAt, DateTime(2026, 2, 6));

      // Guardar de nuevo no duplica filas.
      db.saveNotes(restored);
      expect(NotesStore.onDatabase(db).initial.notes, hasLength(2));
    });

    test('importa los JSON antiguos una sola vez y los archiva', () async {
      final dir = await Directory.systemTemp.createTemp('aletheia-import');
      addTearDown(() => dir.delete(recursive: true));

      File('${dir.path}/workspace.json').writeAsStringSync(
        jsonEncode(WorkspaceState.fresh(layoutId: 'three').toJson()),
      );
      File('${dir.path}/notes.json').writeAsStringSync(
        jsonEncode(
          NotesState(
            notes: [
              Note(
                id: 'imported',
                title: 'Nota antigua',
                createdAt: DateTime(2026, 3, 1),
                updatedAt: DateTime(2026, 3, 1),
              ),
            ],
          ).toJson(),
        ),
      );

      final db = AletheiaDatabase.memory();
      addTearDown(db.close);

      final result = await AletheiaDatabase.importLegacyJson(db, dir);
      expect(result.workspace, isTrue);
      expect(result.notes, isTrue);
      expect(db.loadWorkspace()!.layoutId, 'three');
      expect(db.loadNotes().notes.single.title, 'Nota antigua');

      expect(File('${dir.path}/workspace.json').existsSync(), isFalse);
      expect(File('${dir.path}/workspace.json.imported').existsSync(), isTrue);
      expect(File('${dir.path}/notes.json').existsSync(), isFalse);
      expect(File('${dir.path}/notes.json.imported').existsSync(), isTrue);

      // Segunda pasada: ya no hay nada que importar.
      final again = await AletheiaDatabase.importLegacyJson(db, dir);
      expect(again.workspace, isFalse);
      expect(again.notes, isFalse);
    });
  });
}
