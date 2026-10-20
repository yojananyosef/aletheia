import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database.dart';
import 'plan_models.dart';

/// Persistencia del plan de lectura activo en SQLite (`aletheia.db`, tabla
/// `reading_plans`). El plan es pequeño: sólo plantilla, inicio y día actual;
/// los capítulos de cada día se calculan desde el manifiesto de la Biblia.
class ReadingPlansStore {
  ReadingPlansStore._(this._db, this.initial);

  final AletheiaDatabase? _db;
  final ReadingPlan? initial;

  static ReadingPlansStore onDatabase(AletheiaDatabase db) =>
      ReadingPlansStore._(db, db.loadActivePlan());

  /// Para tests y entornos sin sistema de archivos.
  static ReadingPlansStore inMemory([ReadingPlan? plan]) =>
      ReadingPlansStore._(null, plan);

  Future<void> save(ReadingPlan? plan) async {
    try {
      _db?.saveActivePlan(plan);
    } catch (_) {
      // Persistencia best-effort, como el resto de almacenes locales.
    }
  }
}

final readingPlansStoreProvider = Provider<ReadingPlansStore>(
  // `main()` lo sustituye por el almacén sobre SQLite; sin él (pruebas y
  // entornos sin disco) el plan funciona igual, sólo que en memoria.
  (ref) => ReadingPlansStore.inMemory(),
);
