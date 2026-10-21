import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database.dart';

/// Persistencia del progreso de Cursos (`course_progress` en SQLite).
class CourseProgressStore {
  CourseProgressStore._(this._db, this.initial);

  final AletheiaDatabase? _db;
  final Map<String, Set<String>> initial;

  static CourseProgressStore onDatabase(AletheiaDatabase db) =>
      CourseProgressStore._(db, db.loadCourseProgress());

  static CourseProgressStore inMemory([
    Map<String, Set<String>> progress = const {},
  ]) => CourseProgressStore._(null, progress);

  Future<void> save(Map<String, Set<String>> progress) async {
    try {
      _db?.saveCourseProgress(progress);
    } catch (_) {
      // Persistencia best-effort.
    }
  }
}

final courseProgressStoreProvider = Provider<CourseProgressStore>(
  (ref) => CourseProgressStore.inMemory(),
);
