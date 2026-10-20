import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database.dart';
import 'models.dart';

/// Persistencia del workspace en SQLite (`aletheia.db`, tablas `tiles` y
/// `tabs` más los ajustes en `settings`).
class WorkspaceStore {
  WorkspaceStore._(this._db, this.initial);

  final AletheiaDatabase? _db;
  final WorkspaceState initial;

  /// Abre el almacén sobre la base ya migrada (estado inicial desde SQLite).
  static WorkspaceStore onDatabase(AletheiaDatabase db) =>
      WorkspaceStore._(db, db.loadWorkspace() ?? WorkspaceState.fresh());

  /// Para tests y entornos sin sistema de archivos.
  static WorkspaceStore inMemory([WorkspaceState? state]) =>
      WorkspaceStore._(null, state ?? WorkspaceState.fresh());

  Future<void> save(WorkspaceState state) async {
    try {
      _db?.saveWorkspace(state);
    } catch (_) {
      // Cierre de la app o base bloqueada: la persistencia es best-effort y el
      // siguiente cambio vuelve a intentarlo.
    }
  }
}

final workspaceStoreProvider = Provider<WorkspaceStore>(
  (ref) => throw UnimplementedError(
    'workspaceStoreProvider debe sobreescribirse en main()',
  ),
);
