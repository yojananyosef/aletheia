import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'course_progress_persistence.dart';

/// Lecciones completadas por curso. Las claves son el id del curso y el id de
/// la lección; el valor es el conjunto de lecciones completadas.
final courseProgressProvider =
    NotifierProvider<CourseProgressController, Map<String, Set<String>>>(
      CourseProgressController.new,
    );

class CourseProgressController extends Notifier<Map<String, Set<String>>> {
  @override
  Map<String, Set<String>> build() {
    final initial = ref.read(courseProgressStoreProvider).initial;
    return {
      for (final entry in initial.entries) entry.key: {...entry.value},
    };
  }

  bool isDone(String courseId, String lessonId) =>
      state[courseId]?.contains(lessonId) ?? false;

  void toggle(String courseId, String lessonId) {
    final next = {
      for (final entry in state.entries) entry.key: {...entry.value},
    };
    final lessons = next.putIfAbsent(courseId, () => <String>{});
    if (!lessons.add(lessonId)) lessons.remove(lessonId);
    if (lessons.isEmpty) next.remove(courseId);
    state = next;
    ref.read(courseProgressStoreProvider).save(next);
  }
}
