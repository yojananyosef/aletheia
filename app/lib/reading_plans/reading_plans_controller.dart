import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../workspace/models.dart';
import 'plan_models.dart';
import 'reading_plans_persistence.dart';

/// Estado del plan de lectura activo (uno por instalación).
class ReadingPlansController extends Notifier<ReadingPlan?> {
  @override
  ReadingPlan? build() => ref.read(readingPlansStoreProvider).initial;

  void _save() => ref.read(readingPlansStoreProvider).save(state);

  /// Comienza una plantilla (reemplaza el plan anterior si lo había).
  void start(String templateId) {
    final now = DateTime.now();
    state = ReadingPlan(
      id: 'plan-${now.millisecondsSinceEpoch}',
      templateId: templateId,
      resourceId: kDefaultBibleResourceId,
      startedAt: now,
      dayIndex: 0,
    );
    _save();
  }

  /// Marca el día actual como leído y avanza al siguiente.
  void advance() {
    final plan = state;
    if (plan == null) return;
    state = plan.copyWith(
      dayIndex: plan.dayIndex + 1,
      lastReadAt: DateTime.now(),
    );
    _save();
  }

  /// Detiene y elimina el plan activo.
  void stop() {
    state = null;
    _save();
  }
}

final readingPlansProvider =
    NotifierProvider<ReadingPlansController, ReadingPlan?>(
  ReadingPlansController.new,
);
