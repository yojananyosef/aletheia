import 'dart:convert';
import 'dart:io';

import '../notes/notes_models.dart';
import '../workspace/models.dart';
import 'database.dart';

/// Importa una sola vez los `workspace.json` / `notes.json` de M0–M4 y los
/// archiva como `.imported` (no se borran: son el respaldo del usuario).
Future<LegacyImport> importLegacyJson(AletheiaDatabase db, Object dir) async {
  final directory = dir as Directory;
  var workspace = false;
  var notes = false;

  final workspaceFile = File('${directory.path}/workspace.json');
  if (db.loadWorkspace() == null && await workspaceFile.exists()) {
    try {
      final raw = jsonDecode(await workspaceFile.readAsString());
      if (raw is Map<String, dynamic>) {
        db.saveWorkspace(WorkspaceState.fromJson(raw));
        await workspaceFile.rename('${workspaceFile.path}.imported');
        workspace = true;
      }
    } catch (_) {
      // JSON ilegible: se deja el archivo y se arranca con el estado limpio.
    }
  }

  final notesFile = File('${directory.path}/notes.json');
  final stored = db.loadNotes();
  if (stored.notes.isEmpty &&
      stored.notebooks.isEmpty &&
      await notesFile.exists()) {
    try {
      final raw = jsonDecode(await notesFile.readAsString());
      if (raw is Map<String, dynamic>) {
        db.saveNotes(NotesState.fromJson(raw));
        await notesFile.rename('${notesFile.path}.imported');
        notes = true;
      }
    } catch (_) {
      // Igual que el workspace: se conserva el archivo original.
    }
  }

  return LegacyImport(workspace: workspace, notes: notes);
}
