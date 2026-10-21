/// Menú de herramientas de la barra lateral y la barra superior (M6.3).
///
/// Réplica del menú del original (según la evidencia de reconocimiento):
/// tarjeta bajo el ítem `Tools` con las filas Atlas, Cursos, Documentos,
/// Favoritos, Temas, Información, Medios, Explorador de Salmos, Comparación de
/// textos y Planes de lectura. Todas abren una herramienta real; las que
/// dependen de contenido propio (cursos y documentos) lo indican en su panel.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization.dart';
import '../core/theme.dart';
import '../library/library_overlay.dart';
import '../workspace/models.dart';
import '../workspace/workspace_controller.dart';
import 'sidebar_state.dart';

class ToolsMenuButton extends ConsumerWidget {
  const ToolsMenuButton({
    super.key,
    required this.menuKey,
    required this.trigger,
  });

  final String menuKey;
  final Widget trigger;

  void _select(BuildContext context, WidgetRef ref, String value) {
    void open() {
      final ctrl = ref.read(workspaceProvider.notifier);
      switch (value) {
        case 'atlas':
          ctrl.openTab(const TabSpec(kind: PanelKind.atlas));
        case 'courses':
          ctrl.openTab(const TabSpec(kind: PanelKind.courses));
        case 'documents':
          ctrl.openTab(const TabSpec(kind: PanelKind.documents));
        case 'media':
          ctrl.openTab(const TabSpec(kind: PanelKind.media));
        case 'favorites':
          ctrl.openTab(const TabSpec(kind: PanelKind.favorites));
        case 'psalms':
          ctrl.openTab(const TabSpec(kind: PanelKind.psalmsExplorer));
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

    // En ventanas estrechas el menú vive en la barra lateral expandida:
    // plegarla después de elegir devuelve el ancho al workspace.
    if (MediaQuery.sizeOf(context).width < kSidebarAutoCollapseWidth) {
      ref.read(sidebarCollapsedProvider.notifier).setCollapsed(true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) open();
      });
      return;
    }
    open();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final rows = <(String, IconData, String, bool)>[
      ('atlas', Icons.public, l10n.toolsAtlas, true),
      ('courses', Icons.school_outlined, l10n.toolsCourses, true),
      ('documents', Icons.description_outlined, l10n.toolsDocuments, true),
      ('favorites', Icons.star_outline, l10n.toolsFavorites, true),
      ('factbook', Icons.fact_check_outlined, l10n.panelTitleFactbook, true),
      ('info', Icons.info_outline, l10n.toolsInfo, true),
      ('media', Icons.perm_media_outlined, l10n.toolsMedia, true),
      ('psalms', Icons.music_note_outlined, l10n.toolsPsalms, true),
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
