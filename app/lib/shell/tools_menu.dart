/// Menú de herramientas de la barra lateral y la barra superior (M6.3).
///
/// Réplica del menú del original (según la evidencia de reconocimiento):
/// tarjeta bajo el ítem `Tools` con las filas Atlas, Cursos, Documentos, Temas,
/// Información, Medios, Comparación de textos y Planes de lectura. Las
/// herramientas que el clon ya tiene abren su panel; las que dependen de datos
/// que no poseemos (atlas, cursos, documentos, medios) se muestran con `Pronto`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization.dart';
import '../core/theme.dart';
import '../library/library_overlay.dart';
import '../workspace/models.dart';
import '../workspace/workspace_controller.dart';

class ToolsMenuButton extends ConsumerWidget {
  const ToolsMenuButton({
    super.key,
    required this.menuKey,
    required this.trigger,
  });

  final String menuKey;
  final Widget trigger;

  void _select(BuildContext context, WidgetRef ref, String value) {
    final ctrl = ref.read(workspaceProvider.notifier);
    switch (value) {
      case 'factbook':
        ctrl.openTab(const TabSpec(kind: PanelKind.factbook));
      case 'compare':
        ctrl.openTab(const TabSpec(kind: PanelKind.textComparison));
      case 'plans':
        ctrl.openTab(const TabSpec(kind: PanelKind.readingPlans));
      case 'info':
        ref.read(libraryOverlayVisibleProvider.notifier).open();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final rows = <(String, IconData, String, bool)>[
      ('atlas', Icons.public, l10n.toolsAtlas, false),
      ('courses', Icons.school_outlined, l10n.toolsCourses, false),
      ('documents', Icons.description_outlined, l10n.toolsDocuments, false),
      ('factbook', Icons.fact_check_outlined, l10n.panelTitleFactbook, true),
      ('info', Icons.info_outline, l10n.toolsInfo, true),
      ('media', Icons.perm_media_outlined, l10n.toolsMedia, false),
      ('compare', Icons.compare_arrows, l10n.panelTitleTextComparison, true),
      ('plans', Icons.calendar_month_outlined, l10n.toolsPlans, true),
    ];
    return PopupMenuButton<String>(
      key: ValueKey(menuKey),
      tooltip: l10n.navTools,
      position: PopupMenuPosition.under,
      onSelected: (value) => _select(context, ref, value),
      itemBuilder: (context) => [
        for (final (id, icon, label, enabled) in rows)
          PopupMenuItem<String>(
            value: id,
            key: ValueKey('tool-$id'),
            enabled: enabled,
            height: 34,
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: enabled
                      ? kTextSecondary
                      : kTextSecondary.withValues(alpha: 0.55),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: enabled ? kTextPrimary : kTextSecondary,
                    ),
                  ),
                ),
                if (!enabled)
                  Text(
                    l10n.toolsSoon,
                    style: TextStyle(fontSize: 10.5, color: kTextSecondary),
                  ),
              ],
            ),
          ),
      ],
      child: trigger,
    );
  }
}
