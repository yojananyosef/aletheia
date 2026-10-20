import 'dart:convert';

import 'package:sqlite3/common.dart';

import '../notes/notes_models.dart';
import '../reading_plans/plan_models.dart';
import '../workspace/models.dart';
import 'database_legacy.dart' as legacy;
import 'database_platform.dart' as platform;

/// Base de datos local de Aletheia (SQLite).
///
/// Sustituye a los `workspace.json` / `notes.json` de M0–M4 (ver
/// `docs/spec/02-arquitectura-flutter.md` §11). Un único archivo
/// (`aletheia.db`) guarda:
///
/// - `settings`: ajustes del workspace como JSON por clave (layout, idioma,
///   catálogo, banners…) — son valores escalares sin consultas.
/// - `tiles` / `tabs`: pestañas normalizadas (posición, tipo, referencia,
///   historial y presentación del panel en JSON).
/// - `notebooks`, `notes`, `note_anchors`, `note_notebooks`, `note_tags`: notas
///   normalizadas, con los anclajes en su propia tabla para poder consultarlos.
///
/// La escritura es por transacción y "snapshot" (borra y reinserta): el estado
/// es pequeño y así no hay que sincronizar filas sueltas. El esquema se
/// versiona con `PRAGMA user_version`.
class AletheiaDatabase {
  AletheiaDatabase._(this.db);

  final CommonDatabase db;

  /// Versión del esquema. Subir y añadir el paso en [_migrate].
  static const int schemaVersion = 3;

  static AletheiaDatabase open(String path) {
    final instance = AletheiaDatabase._(platform.openDatabaseFile(path));
    instance._configure();
    return instance;
  }

  /// Para pruebas y entornos sin sistema de archivos.
  static AletheiaDatabase memory() {
    final instance = AletheiaDatabase._(platform.openMemoryDatabase());
    instance._configure();
    return instance;
  }

  /// Envuelve una base ya abierta por la fábrica de la plataforma (web).
  factory AletheiaDatabase.fromDatabase(CommonDatabase db) {
    final instance = AletheiaDatabase._(db);
    instance._configure();
    return instance;
  }

  void _configure() {
    db.execute('PRAGMA foreign_keys = ON');
    if (db.select('PRAGMA journal_mode').first.values.first != 'memory') {
      db.execute('PRAGMA journal_mode = WAL');
    }
    _migrate();
  }

  void _migrate() {
    final version = db.userVersion;
    if (version >= schemaVersion) return;

    if (version < 1) {
      db.execute('''
        CREATE TABLE settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        );

        CREATE TABLE tiles (
          id TEXT PRIMARY KEY,
          position INTEGER NOT NULL,
          active_index INTEGER NOT NULL
        );

        CREATE TABLE tabs (
          id TEXT PRIMARY KEY,
          tile_id TEXT NOT NULL REFERENCES tiles(id) ON DELETE CASCADE,
          position INTEGER NOT NULL,
          kind TEXT NOT NULL,
          title TEXT NOT NULL,
          reference TEXT,
          query TEXT,
          resource_type TEXT,
          resource_id TEXT,
          history_json TEXT,
          history_index INTEGER NOT NULL DEFAULT -1,
          display_json TEXT
        );

        CREATE TABLE notebooks (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          created_at TEXT NOT NULL
        );

        CREATE TABLE notes (
          id TEXT PRIMARY KEY,
          kind TEXT NOT NULL,
          title TEXT NOT NULL DEFAULT '',
          body TEXT NOT NULL DEFAULT '',
          color TEXT NOT NULL,
          style TEXT NOT NULL DEFAULT 'highlight',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT
        );

        CREATE TABLE note_anchors (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          note_id TEXT NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
          position INTEGER NOT NULL,
          resource_id TEXT NOT NULL,
          reference TEXT,
          book_code TEXT,
          chapter INTEGER,
          verse INTEGER,
          verse_end INTEGER,
          start_offset INTEGER,
          end_offset INTEGER,
          quote TEXT
        );

        CREATE TABLE note_notebooks (
          note_id TEXT NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
          notebook_id TEXT NOT NULL,
          position INTEGER NOT NULL,
          PRIMARY KEY (note_id, notebook_id)
        );

        CREATE TABLE note_tags (
          note_id TEXT NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
          tag TEXT NOT NULL,
          position INTEGER NOT NULL,
          PRIMARY KEY (note_id, tag)
        );

        CREATE INDEX note_anchors_note ON note_anchors(note_id);
        CREATE INDEX note_anchors_ref ON note_anchors(book_code, chapter);
      ''');
    }

    if (version < 2) {
      db.execute('''
        CREATE TABLE reading_plans (
          id TEXT PRIMARY KEY,
          template TEXT NOT NULL,
          resource_id TEXT NOT NULL,
          started_at TEXT NOT NULL,
          day_index INTEGER NOT NULL DEFAULT 0,
          last_read_at TEXT
        );
      ''');
    }

    if (version < 3) {
      db.execute('ALTER TABLE tabs ADD COLUMN link_set TEXT');
    }

    db.userVersion = schemaVersion;
  }

  void _transaction(void Function() body) {
    db.execute('BEGIN');
    try {
      body();
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  void close() => db.close();

  // ------------------------------------------------------------- workspace

  /// `null` si la base todavía no tiene ningún workspace guardado.
  WorkspaceState? loadWorkspace() {
    final settings = db.select('SELECT value FROM settings WHERE key = ?', [
      'workspace',
    ]);
    final tiles = db.select(
      'SELECT id, active_index FROM tiles ORDER BY position',
    );
    if (settings.isEmpty && tiles.isEmpty) return null;

    final base = settings.isEmpty
        ? <String, dynamic>{}
        : (jsonDecode(settings.first['value'] as String) as Map)
              .cast<String, dynamic>();

    final tabs = <String, List<Map<String, dynamic>>>{};
    for (final row in db.select(
      'SELECT * FROM tabs ORDER BY tile_id, position',
    )) {
      final tab = <String, dynamic>{
        'id': row['id'],
        'kind': row['kind'],
        'title': row['title'],
        if (row['reference'] != null) 'reference': row['reference'],
        if (row['query'] != null) 'query': row['query'],
        if (row['resource_type'] != null) 'resourceType': row['resource_type'],
        if (row['resource_id'] != null) 'resourceId': row['resource_id'],
        if (row['link_set'] != null) 'linkSet': row['link_set'],
        'history': jsonDecode((row['history_json'] as String?) ?? '[]'),
        'historyIndex': row['history_index'],
        'display': jsonDecode((row['display_json'] as String?) ?? '{}'),
      };
      tabs.putIfAbsent(row['tile_id'] as String, () => []).add(tab);
    }

    return WorkspaceState.fromJson({
      ...base,
      'tiles': [
        for (final row in tiles)
          {
            'id': row['id'],
            'activeIndex': row['active_index'],
            'tabs': tabs[row['id']] ?? const [],
          },
      ],
    });
  }

  void saveWorkspace(WorkspaceState state) {
    final json = Map<String, dynamic>.from(state.toJson()..remove('tiles'));

    _transaction(() {
      db.execute('DELETE FROM tabs');
      db.execute('DELETE FROM tiles');

      final insertTile = db.prepare(
        'INSERT INTO tiles (id, position, active_index) VALUES (?, ?, ?)',
      );
      final insertTab = db.prepare('''
        INSERT INTO tabs (id, tile_id, position, kind, title, reference, query,
          resource_type, resource_id, link_set, history_json, history_index,
          display_json)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''');
      try {
        for (var t = 0; t < state.tiles.length; t++) {
          final tile = state.tiles[t];
          insertTile.execute([tile.id, t, tile.activeIndex]);
          for (var i = 0; i < tile.tabs.length; i++) {
            final tab = tile.tabs[i];
            insertTab.execute([
              tab.id,
              tile.id,
              i,
              tab.kind.name,
              tab.title,
              tab.reference,
              tab.query,
              tab.resourceType,
              tab.resourceId,
              tab.linkSet,
              jsonEncode(tab.history),
              tab.historyIndex,
              jsonEncode(tab.display.toJson()),
            ]);
          }
        }
      } finally {
        insertTile.close();
        insertTab.close();
      }

      db.execute('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)', [
        'workspace',
        jsonEncode(json),
      ]);
    });
  }

  // ----------------------------------------------------------------- notas

  NotesState loadNotes() {
    final notebooks = [
      for (final row in db.select(
        'SELECT id, name, created_at FROM notebooks ORDER BY created_at',
      ))
        Notebook(
          id: row['id'] as String,
          name: row['name'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
        ),
    ];

    final anchorsByNote = <String, List<NoteAnchor>>{};
    for (final row in db.select(
      'SELECT * FROM note_anchors ORDER BY note_id, position',
    )) {
      anchorsByNote
          .putIfAbsent(row['note_id'] as String, () => [])
          .add(
            NoteAnchor.fromJson({
              'resourceId': row['resource_id'],
              'reference': row['reference'],
              'bookCode': row['book_code'],
              'chapter': row['chapter'],
              'verse': row['verse'],
              'verseEnd': row['verse_end'],
              'startOffset': row['start_offset'],
              'endOffset': row['end_offset'],
              'quote': row['quote'],
            }),
          );
    }

    final notebooksByNote = <String, List<String>>{};
    for (final row in db.select(
      'SELECT note_id, notebook_id FROM note_notebooks ORDER BY note_id, position',
    )) {
      notebooksByNote
          .putIfAbsent(row['note_id'] as String, () => [])
          .add(row['notebook_id'] as String);
    }

    final tagsByNote = <String, List<String>>{};
    for (final row in db.select(
      'SELECT note_id, tag FROM note_tags ORDER BY note_id, position',
    )) {
      tagsByNote
          .putIfAbsent(row['note_id'] as String, () => [])
          .add(row['tag'] as String);
    }

    final notes = [
      for (final row in db.select('SELECT * FROM notes ORDER BY created_at'))
        Note(
          id: row['id'] as String,
          kind: row['kind'] as String,
          title: row['title'] as String,
          body: row['body'] as String,
          color: row['color'] as String,
          style: row['style'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
          updatedAt: DateTime.parse(row['updated_at'] as String),
          deletedAt: row['deleted_at'] == null
              ? null
              : DateTime.parse(row['deleted_at'] as String),
          anchors: anchorsByNote[row['id']] ?? const [],
          notebooks: notebooksByNote[row['id']] ?? const [],
          tags: tagsByNote[row['id']] ?? const [],
        ),
    ];

    return NotesState(notes: notes, notebooks: notebooks);
  }

  void saveNotes(NotesState state) {
    _transaction(() {
      db.execute('DELETE FROM note_anchors');
      db.execute('DELETE FROM note_notebooks');
      db.execute('DELETE FROM note_tags');
      db.execute('DELETE FROM notes');
      db.execute('DELETE FROM notebooks');

      final insertNotebook = db.prepare(
        'INSERT INTO notebooks (id, name, created_at) VALUES (?, ?, ?)',
      );
      final insertNote = db.prepare('''
        INSERT INTO notes (id, kind, title, body, color, style, created_at,
          updated_at, deleted_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''');
      final insertAnchor = db.prepare('''
        INSERT INTO note_anchors (note_id, position, resource_id, reference,
          book_code, chapter, verse, verse_end, start_offset, end_offset, quote)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''');
      final insertNotebookRef = db.prepare(
        'INSERT INTO note_notebooks (note_id, notebook_id, position) VALUES (?, ?, ?)',
      );
      final insertTag = db.prepare(
        'INSERT INTO note_tags (note_id, tag, position) VALUES (?, ?, ?)',
      );

      try {
        for (final notebook in state.notebooks) {
          insertNotebook.execute([
            notebook.id,
            notebook.name,
            notebook.createdAt.toIso8601String(),
          ]);
        }
        for (final note in state.notes) {
          insertNote.execute([
            note.id,
            note.kind,
            note.title,
            note.body,
            note.color,
            note.style,
            note.createdAt.toIso8601String(),
            note.updatedAt.toIso8601String(),
            note.deletedAt?.toIso8601String(),
          ]);
          for (var i = 0; i < note.anchors.length; i++) {
            final anchor = note.anchors[i];
            insertAnchor.execute([
              note.id,
              i,
              anchor.resourceId,
              anchor.reference,
              anchor.bookCode,
              anchor.chapter,
              anchor.verse,
              anchor.verseEnd,
              anchor.startOffset,
              anchor.endOffset,
              anchor.quote,
            ]);
          }
          for (var i = 0; i < note.notebooks.length; i++) {
            insertNotebookRef.execute([note.id, note.notebooks[i], i]);
          }
          for (var i = 0; i < note.tags.length; i++) {
            insertTag.execute([note.id, note.tags[i], i]);
          }
        }
      } finally {
        insertNotebook.close();
        insertNote.close();
        insertAnchor.close();
        insertNotebookRef.close();
        insertTag.close();
      }
    });
  }

  // --------------------------------------------------------- planes de lectura

  /// Plan de lectura activo (el clon guarda uno por instalación).
  ReadingPlan? loadActivePlan() {
    final rows = db.select('SELECT * FROM reading_plans LIMIT 1');
    if (rows.isEmpty) return null;
    final row = rows.first;
    return ReadingPlan.fromJson({
      'id': row['id'],
      'templateId': row['template'],
      'resourceId': row['resource_id'],
      'startedAt': row['started_at'],
      'dayIndex': row['day_index'],
      if (row['last_read_at'] != null) 'lastReadAt': row['last_read_at'],
    });
  }

  void saveActivePlan(ReadingPlan? plan) {
    _transaction(() {
      db.execute('DELETE FROM reading_plans');
      if (plan == null) return;
      db.execute(
        'INSERT INTO reading_plans (id, template, resource_id, started_at, '
        'day_index, last_read_at) VALUES (?, ?, ?, ?, ?, ?)',
        [
          plan.id,
          plan.templateId,
          plan.resourceId,
          plan.startedAt.toIso8601String(),
          plan.dayIndex,
          plan.lastReadAt?.toIso8601String(),
        ],
      );
    });
  }

  // ------------------------------------------------------- importación M4→DB

  /// Importa una sola vez los `workspace.json` / `notes.json` de M0–M4 y los
  /// archiva como `.imported` (no se borran: son el respaldo del usuario).
  ///
  /// [dir] es un `Directory` en plataformas nativas. En web no hay archivos
  /// heredados y la implementación no hace nada.
  static Future<LegacyImport> importLegacyJson(
    AletheiaDatabase db,
    Object dir,
  ) => legacy.importLegacyJson(db, dir);
}

/// Resultado de [AletheiaDatabase.importLegacyJson].
class LegacyImport {
  const LegacyImport({required this.workspace, required this.notes});

  final bool workspace;
  final bool notes;

  @override
  String toString() => 'LegacyImport(workspace: $workspace, notes: $notes)';
}
