/// Panel de inicio (M6.3).
///
/// El original (con sesión) muestra un `Panel de Control` con tarjetas de la
/// cuenta: continuar la lectura, plan, devocional, notas… y el clon lo adapta
/// a los datos locales: referencias recientes (historial de las pestañas),
/// plan de lectura activo, resumen de Notas, devocional del día, accesos al
/// Estudio guiado y a las herramientas reales.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/document_repository.dart';
import '../core/localization.dart';
import '../core/theme.dart';
import '../guides/guides_data.dart';
import '../notes/notes_controller.dart';
import '../reading_plans/plan_models.dart';
import '../reading_plans/reading_plans_controller.dart';
import '../references/reference_parser.dart';
import '../workspace/models.dart';
import '../workspace/workspace_controller.dart';

class DashboardPanel extends ConsumerWidget {
  const DashboardPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Container(
      color: kPanelBg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        children: [
          Text(
            l10n.navHome,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.dashboardSubtitle,
            style: TextStyle(fontSize: 12.5, color: kTextSecondary),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              // Tarjetas adaptativas: 1–3 columnas según el ancho del panel.
              final columns = constraints.maxWidth >= 1080
                  ? 3
                  : (constraints.maxWidth >= 700 ? 2 : 1);
              final width =
                  (constraints.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(width: width, child: const _ContinueCard()),
                  SizedBox(width: width, child: const _PlanCard()),
                  SizedBox(width: width, child: const _NotesCard()),
                  SizedBox(width: width, child: const _DevotionalCard()),
                  SizedBox(width: width, child: const _GuidedCard()),
                  SizedBox(width: width, child: const _ToolsCard()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Tarjeta del panel (título con icono + contenido).
class _Card extends StatelessWidget {
  const _Card({required this.icon, required this.title, required this.child});

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
              Icon(icon, size: 16, color: kAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.7,
                    color: kTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// Referencias recientes del espacio de trabajo (historial de las pestañas).
List<String> _recentReferences(WorkspaceState state) {
  final refs = <String>[];
  for (final tile in state.tiles) {
    for (final tab in tile.tabs) {
      if (tab.kind != PanelKind.bible && tab.kind != PanelKind.resource) {
        continue;
      }
      for (final entry in [...tab.history, ?tab.reference]) {
        if (entry.isNotEmpty && !refs.contains(entry)) refs.add(entry);
      }
    }
  }
  return refs.reversed.take(4).toList();
}

class _ContinueCard extends ConsumerWidget {
  const _ContinueCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final lang = context.l10nLang;
    final state = ref.watch(workspaceProvider);
    final recents = _recentReferences(state);
    return _Card(
      icon: Icons.history,
      title: l10n.dashboardContinue,
      child: recents.isEmpty
          ? Text(
              l10n.dashboardContinueEmpty,
              style: TextStyle(fontSize: 12.5, color: kTextSecondary),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final (index, reference) in recents.indexed)
                  OutlinedButton(
                    key: ValueKey('dashboard-continue-$index'),
                    onPressed: () => ref
                        .read(workspaceProvider.notifier)
                        .openTab(
                          TabSpec(kind: PanelKind.bible, reference: reference),
                        ),
                    child: Text(
                      displayFromCanonical(reference, lang: lang),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _PlanCard extends ConsumerWidget {
  const _PlanCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final lang = context.l10nLang;
    final plan = ref.watch(readingPlansProvider);
    final manifest = ref.watch(manifestProvider(kDefaultBibleResourceId)).value;

    if (plan == null) {
      return _Card(
        icon: Icons.calendar_month_outlined,
        title: l10n.dashboardPlan,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dashboardPlanEmpty,
              style: TextStyle(fontSize: 12.5, color: kTextSecondary),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const ValueKey('dashboard-plan-choose'),
              onPressed: () => ref
                  .read(workspaceProvider.notifier)
                  .openTab(const TabSpec(kind: PanelKind.readingPlans)),
              child: Text(
                l10n.dashboardPlanChoose,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    final def = planTemplates(l10n)
        .where((d) => d.id == plan.templateId)
        .firstOrNull;
    final schedule = (def == null || manifest == null)
        ? null
        : PlanSchedule.build(manifest, def);
    final total = schedule?.length ?? def?.days ?? 0;
    final done = total > 0 && plan.dayIndex >= total;
    final today = done ? total - 1 : plan.dayIndex;
    final label = schedule?.dayLabel(today, lang: lang) ?? '';
    final reference = schedule?.dayReference(today);
    final progress = total == 0 ? 0.0 : (plan.dayIndex / total).clamp(0.0, 1.0);

    return _Card(
      icon: Icons.calendar_month_outlined,
      title: l10n.dashboardPlan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            def?.title ?? plan.templateId,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: kBorder,
              valueColor: const AlwaysStoppedAnimation(kAccent),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            done
                ? l10n.plansCompleted
                : l10n.plansDayOf(plan.dayIndex + 1, total),
            style: TextStyle(fontSize: 11.5, color: kTextSecondary),
          ),
          if (!done && label.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '${l10n.plansToday}: $label',
              style: TextStyle(fontSize: 12, color: kTextPrimary),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              if (!done && reference != null)
                FilledButton(
                  key: const ValueKey('dashboard-plan-open'),
                  onPressed: () => ref
                      .read(workspaceProvider.notifier)
                      .openTab(
                        TabSpec(kind: PanelKind.bible, reference: reference),
                      ),
                  child: Text(
                    l10n.plansOpenToday,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              OutlinedButton(
                key: const ValueKey('dashboard-plan-view'),
                onPressed: () => ref
                    .read(workspaceProvider.notifier)
                    .openTab(const TabSpec(kind: PanelKind.readingPlans)),
                child: Text(
                  l10n.dashboardPlanView,
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

class _NotesCard extends ConsumerWidget {
  const _NotesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notes = ref.watch(notesProvider).notes.where((n) => !n.isTrashed);
    final total = notes.length;
    final highlights = notes.where((n) => n.isHighlight).length;
    return _Card(
      icon: Icons.sticky_note_2_outlined,
      title: l10n.dashboardNotes,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboardNotesCount(total - highlights, highlights),
            style: TextStyle(fontSize: 12.5, color: kTextSecondary),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const ValueKey('dashboard-notes-open'),
            onPressed: () => ref
                .read(workspaceProvider.notifier)
                .openTab(const TabSpec(kind: PanelKind.notes)),
            child: Text(
              l10n.dashboardNotesOpen,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _DevotionalCard extends ConsumerWidget {
  const _DevotionalCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return _Card(
      icon: Icons.wb_twilight,
      title: l10n.dashboardDevotional,
      child: OutlinedButton(
        key: const ValueKey('dashboard-devotional-open'),
        onPressed: () => ref
            .read(workspaceProvider.notifier)
            .openTab(const TabSpec(kind: PanelKind.devotional)),
        child: Text(
          l10n.dashboardDevotionalOpen,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

class _GuidedCard extends ConsumerWidget {
  const _GuidedCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final guides = guidedDefinitions(l10n)
        .where((def) => def.kind == GuideKind.guide)
        .toList();
    return _Card(
      icon: Icons.explore_outlined,
      title: l10n.dashboardGuided,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final def in guides)
                OutlinedButton(
                  key: ValueKey('dashboard-guide-${def.id}'),
                  onPressed: () => _openGuide(ref, def.id),
                  child: Text(def.title, style: const TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            key: const ValueKey('dashboard-guides-open'),
            onPressed: () => ref
                .read(workspaceProvider.notifier)
                .openTab(const TabSpec(kind: PanelKind.guidedStudy)),
            child: Text(
              l10n.dashboardGuidedOpen,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Abre el Estudio guiado con una guía ya en marcha.
  void _openGuide(WidgetRef ref, String guideId) {
    final ctrl = ref.read(workspaceProvider.notifier);
    ctrl.openTab(const TabSpec(kind: PanelKind.guidedStudy));
    final state = ref.read(workspaceProvider);
    for (final tile in state.tiles) {
      for (final tab in tile.tabs) {
        if (tab.kind == PanelKind.guidedStudy) {
          ctrl.updateTab(tileId: tile.id, tabId: tab.id, reference: guideId);
          return;
        }
      }
    }
  }
}

class _ToolsCard extends ConsumerWidget {
  const _ToolsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return _Card(
      icon: Icons.grid_view_outlined,
      title: l10n.dashboardTools,
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          OutlinedButton(
            key: const ValueKey('dashboard-tool-factbook'),
            onPressed: () => ref
                .read(workspaceProvider.notifier)
                .openTab(const TabSpec(kind: PanelKind.factbook)),
            child: Text(
              l10n.panelTitleFactbook,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          OutlinedButton(
            key: const ValueKey('dashboard-tool-compare'),
            onPressed: () => ref
                .read(workspaceProvider.notifier)
                .openTab(const TabSpec(kind: PanelKind.textComparison)),
            child: Text(
              l10n.panelTitleTextComparison,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          OutlinedButton(
            key: const ValueKey('dashboard-tool-plans'),
            onPressed: () => ref
                .read(workspaceProvider.notifier)
                .openTab(const TabSpec(kind: PanelKind.readingPlans)),
            child: Text(
              l10n.panelTitleReadingPlans,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
