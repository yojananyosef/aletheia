/// Panel «Planes de lectura» (M6.3).
///
/// El original abre el gestor de planes de la cuenta desde la barra y desde el
/// botón «Comenzar plan de lectura» de la ficha del recurso. El clon ofrece
/// cuatro plantillas propias calculadas sobre la RV1909 y guarda el plan
/// activo en SQLite; «Abrir la lectura de hoy» navega el lector y «Marcar día
/// como leído» avanza el progreso.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/document_models.dart';
import '../catalog/document_repository.dart';
import '../core/localization.dart';
import '../core/theme.dart';
import '../workspace/models.dart';
import '../workspace/workspace_controller.dart';
import 'plan_models.dart';
import 'reading_plans_controller.dart';

class ReadingPlansPanel extends ConsumerWidget {
  const ReadingPlansPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final plan = ref.watch(readingPlansProvider);
    final templates = planTemplates(l10n);
    final manifestAsync = ref.watch(manifestProvider(kDefaultBibleResourceId));
    final manifest = manifestAsync.value;

    return Container(
      color: kPanelBg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        children: [
          Text(
            l10n.panelTitleReadingPlans,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.plansIntro,
            style: TextStyle(fontSize: 12.5, color: kTextSecondary),
          ),
          const SizedBox(height: 14),
          if (plan != null)
            _ActivePlanCard(plan: plan, manifest: manifest)
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kPanelBg,
                border: Border.all(color: kCardBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_note_outlined,
                    size: 18,
                    color: kTextSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.plansEmpty,
                      style: TextStyle(fontSize: 12.5, color: kTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          Text(
            plan == null ? l10n.plansAvailable : l10n.plansOther,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          for (final def in templates)
            _TemplateCard(def: def, current: plan?.templateId == def.id),
        ],
      ),
    );
  }
}

class _ActivePlanCard extends ConsumerWidget {
  const _ActivePlanCard({required this.plan, required this.manifest});

  final ReadingPlan plan;
  final DocumentManifest? manifest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final lang = context.l10nLang;
    final def = planTemplates(l10n)
        .where((d) => d.id == plan.templateId)
        .firstOrNull;
    if (def == null) {
      // Plantilla desconocida (versión futura): se ofrece detener el plan.
      return TextButton(
        onPressed: () => ref.read(readingPlansProvider.notifier).stop(),
        child: Text(l10n.plansStop),
      );
    }
    final schedule = manifest == null
        ? null
        : PlanSchedule.build(manifest!, def);
    final total = schedule?.length ?? def.days;
    final done = plan.dayIndex >= total;
    final today = done ? total - 1 : plan.dayIndex;
    final label = schedule?.dayLabel(today, lang: lang) ?? '';
    final reference = schedule?.dayReference(today);
    final progress = total == 0 ? 0.0 : (plan.dayIndex / total).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: kPanelBg,
        border: Border.all(color: kCardBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(def.icon, size: 17, color: kAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  def.title,
                  key: const ValueKey('plan-active-title'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: kAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  l10n.plansInProgress,
                  style: const TextStyle(fontSize: 10.5, color: kAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            key: const ValueKey('plan-progress'),
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: kBorder,
              valueColor: const AlwaysStoppedAnimation(kAccent),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            done
                ? l10n.plansCompleted
                : l10n.plansDayOf(plan.dayIndex + 1, total),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
            ),
          ),
          if (!done && label.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '${l10n.plansToday}: $label',
              key: const ValueKey('plan-today'),
              style: TextStyle(fontSize: 12.5, color: kTextSecondary),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (!done && reference != null)
                FilledButton.icon(
                  key: const ValueKey('plan-open-today'),
                  onPressed: () => ref
                      .read(workspaceProvider.notifier)
                      .openTab(
                        TabSpec(kind: PanelKind.bible, reference: reference),
                      ),
                  icon: const Icon(Icons.menu_book_outlined, size: 15),
                  label: Text(
                    l10n.plansOpenToday,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              if (!done)
                OutlinedButton.icon(
                  key: const ValueKey('plan-advance'),
                  onPressed: () =>
                      ref.read(readingPlansProvider.notifier).advance(),
                  icon: const Icon(Icons.check, size: 15),
                  label: Text(
                    l10n.plansMarkRead,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              TextButton(
                key: const ValueKey('plan-stop'),
                onPressed: () => ref.read(readingPlansProvider.notifier).stop(),
                child: Text(
                  l10n.plansStop,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  const _TemplateCard({required this.def, required this.current});

  final PlanTemplateDef def;
  final bool current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: kPanelBg,
        border: Border.all(color: kCardBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(def.icon, size: 17, color: kAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  def.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${l10n.plansDays(def.days)} · ${def.description}',
                  style: TextStyle(fontSize: 11.5, color: kTextSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (current)
            Text(
              l10n.plansInProgress,
              style: TextStyle(fontSize: 11, color: kTextSecondary),
            )
          else
            OutlinedButton(
              key: ValueKey('plan-start-${def.id}'),
              onPressed: () => _start(context, ref),
              child: Text(
                l10n.plansStart,
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final plan = ref.read(readingPlansProvider);
    if (plan != null) {
      final l10n = context.l10n;
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.plansReplaceTitle),
          content: Text(l10n.plansReplaceBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.plansReplace),
            ),
          ],
        ),
      );
      if (replace != true) return;
    }
    ref.read(readingPlansProvider.notifier).start(def.id);
  }
}
