import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database.dart';
import 'notes_models.dart';

/// Persistencia de Notas en SQLite (`aletheia.db`, tabla `notes` y anexas).
///
/// M4 fue *local-first* con `notes.json`; desde M4.3 todo vive en la base
/// compartida con el workspace (ver `docs/spec/02-arquitectura-flutter.md`
/// §11). La importación de los JSON antiguos la hace
/// [AletheiaDatabase.importLegacyJson] al arrancar.
class NotesStore {
  NotesStore._(this._db, this.initial);

  final AletheiaDatabase? _db;
  final NotesState initial;

  /// Abre el almacén sobre la base ya migrada (estado inicial desde SQLite).
  static NotesStore onDatabase(AletheiaDatabase db) =>
      NotesStore._(db, db.loadNotes());

  /// Para tests y entornos sin sistema de archivos.
  static NotesStore inMemory([NotesState? state]) =>
      NotesStore._(null, state ?? const NotesState());

  Future<void> save(NotesState state) async {
    try {
      _db?.saveNotes(state);
    } catch (_) {
      // Cierre de la app o base bloqueada: la persistencia es best-effort y el
      // siguiente cambio vuelve a intentarlo.
    }
  }
}

final notesStoreProvider = Provider<NotesStore>(
  (ref) => throw UnimplementedError('notesStoreProvider debe sobreescribirse'),
);
