import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization.dart';
import '../core/theme.dart';
import '../library/library_overlay.dart';
import '../panels/panel_host.dart';
import '../workspace/models.dart';
import '../workspace/panel_fullscreen.dart';
import '../workspace/workspace_controller.dart';
import '../workspace/workspace_view.dart';
import 'layouts_menu.dart';
import 'tools_menu.dart';
import 'omnibox.dart';

/// Plegado manual de la barra lateral: `null` = automático según el ancho de
/// la ventana; un valor explícito (elegido con la flecha del pie del rail)
/// manda sobre el automatismo.
class SidebarCollapsed extends Notifier<bool?> {
  @override
  bool? build() => null;

  void setCollapsed(bool value) => state = value;
}

final sidebarCollapsedProvider = NotifierProvider<SidebarCollapsed, bool?>(
  SidebarCollapsed.new,
);

/// Definición de un ítem de navegación, compartida por la barra lateral
/// (izquierda) y la barra horizontal (arriba, Ajustes 8.1).
class _NavDef {
  const _NavDef(this.icon, this.label, this.onTap, {this.key, this.id = ''});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Key? key;

  /// Identificador para el resalte del ítem activo (barra lateral).
  final String id;
}

class Shell extends ConsumerWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workspaceProvider);
    final fullscreenId = ref.watch(panelFullscreenProvider);
    if (fullscreenId != null) {
      for (final tile in state.tiles) {
        for (final tab in tile.tabs) {
          if (tab.id == fullscreenId) {
            return _FullscreenPanel(tile: tile, tab: tab);
          }
        }
      }
    }
    final topToolbar = state.toolbarLocation == 'top';
    return Scaffold(
      backgroundColor: kWorkspaceBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final showBanner =
              state.layoutBannersVisible &&
              constraints.maxWidth >= kBannerMinWidth;
          if (topToolbar) {
            // Ajuste «barra de aplicaciones arriba»: navegación horizontal,
            // sin barra lateral.
            return Column(
              children: [
                const _TopHeader(),
                const _TopNavBar(),
                Expanded(child: _WorkspaceColumn(showBanner: showBanner)),
              ],
            );
          }
          final autoCollapsed =
              constraints.maxWidth < kSidebarAutoCollapseWidth;
          final collapsed =
              ref.watch(sidebarCollapsedProvider) ?? autoCollapsed;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: collapsed ? kSidebarRailWidth : kSidebarWidth,
                child: _SidebarColumn(collapsed: collapsed),
              ),
              Expanded(child: _WorkspaceColumn(showBanner: showBanner)),
            ],
          );
        },
      ),
    );
  }
}

/// Un panel ocupa toda la ventana, sin barra lateral ni chrome del workspace.
/// Es distinto de la pantalla completa del sistema operativo: el botón de la
/// barra superior y `Esc` restauran el workspace.
class _FullscreenPanel extends ConsumerWidget {
  const _FullscreenPanel({required this.tile, required this.tab});

  final WorkspaceTile tile;
  final WorkspaceTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            ref.read(panelFullscreenProvider.notifier).clear(),
      },
      child: Focus(
        autofocus: true,
        child: Material(
          key: const ValueKey('panel-fullscreen'),
          color: kPanelBg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 32,
                padding: const EdgeInsets.only(left: 12, right: 4),
                decoration: BoxDecoration(
                  color: kSidebarBg,
                  border: Border(bottom: BorderSide(color: kBorder)),
                ),
                child: Row(
                  children: [
                    Text(
                      l10n.panelFullscreenEnter,
                      style: TextStyle(
                        fontSize: 12,
                        color: kTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: IconButton(
                        key: const ValueKey('panel-fullscreen-exit'),
                        padding: EdgeInsets.zero,
                        iconSize: 16,
                        tooltip: l10n.panelFullscreenExit,
                        onPressed: () =>
                            ref.read(panelFullscreenProvider.notifier).clear(),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PanelHost(tile: tile, tab: tab),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Columna de la barra lateral: cabecera (logo + ómnibus) y navegación.
class _SidebarColumn extends ConsumerWidget {
  const _SidebarColumn({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SidebarHeader(collapsed: collapsed),
        Expanded(child: _Sidebar(collapsed: collapsed)),
      ],
    );
  }
}

/// Área de trabajo: banner (si está activo) sobre la tira de pestañas.
class _WorkspaceColumn extends ConsumerWidget {
  const _WorkspaceColumn({required this.showBanner});

  final bool showBanner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showBanner) const _Banner(),
        Expanded(
          child: Stack(
            children: [
              const WorkspaceView(),
              if (ref.watch(libraryOverlayVisibleProvider))
                const LibraryOverlay(),
            ],
          ),
        ),
      ],
    );
  }
}

List<_NavDef> _navDefs(BuildContext context, WidgetRef ref) {
  final l10n = context.l10n;
  final ctrl = ref.read(workspaceProvider.notifier);
  return [
    _NavDef(
      Icons.dashboard,
      l10n.navHome,
      () => ctrl.openTab(const TabSpec(kind: PanelKind.dashboard)),
      id: 'dashboard',
    ),
    _NavDef(
      Icons.local_library,
      l10n.navLibrary,
      () => ref.read(libraryOverlayVisibleProvider.notifier).open(),
      key: const ValueKey('nav-library'),
      id: 'library',
    ),
    _NavDef(
      Icons.search,
      l10n.navSearch,
      () => ctrl.openTab(const TabSpec(kind: PanelKind.search)),
      key: const ValueKey('nav-search'),
      id: 'search',
    ),
    _NavDef(
      Icons.book,
      l10n.navBible,
      () {
        // Como el original: si ya hay una Biblia abierta se activa tal cual
        // (sin mover su ubicación); si no, se abre.
        if (!ctrl.revealResourceTab(kDefaultBibleResourceId)) {
          ctrl.openTab(
            const TabSpec(
              kind: PanelKind.bible,
              title: 'RV1909',
              reference: 'GEN.1.1',
              resourceId: kDefaultBibleResourceId,
            ),
          );
        }
      },
      key: const ValueKey('nav-bible'),
      id: 'bible',
    ),
    _NavDef(
      Icons.chat_bubble,
      l10n.navAssistant,
      () => ctrl.openTab(const TabSpec(kind: PanelKind.studyAssistant)),
      id: 'assistant',
    ),
    _NavDef(
      Icons.fact_check,
      l10n.navTopics,
      () => ctrl.openTab(const TabSpec(kind: PanelKind.factbook)),
      key: const ValueKey('nav-topics'),
      id: 'topics',
    ),
    _NavDef(
      Icons.explore,
      l10n.navGuidedStudy,
      () => ctrl.openTab(const TabSpec(kind: PanelKind.guidedStudy)),
      id: 'guided',
    ),
    _NavDef(
      Icons.sticky_note_2,
      l10n.navNotes,
      () => ctrl.openTab(const TabSpec(kind: PanelKind.notes)),
      key: const ValueKey('nav-notes'),
      id: 'notes',
    ),
  ];
}

/// Acciones rápidas del original (`Show quick actions`, Ajustes 8.2).
List<_NavDef> _quickActionDefs(BuildContext context, WidgetRef ref) {
  final l10n = context.l10n;
  final ctrl = ref.read(workspaceProvider.notifier);
  return [
    _NavDef(
      Icons.auto_stories,
      l10n.quickOpenCommentary,
      () => ctrl.openTab(
        const TabSpec(kind: PanelKind.resource, resourceType: 'commentary'),
      ),
      key: const ValueKey('quick-commentary'),
    ),
    _NavDef(
      Icons.menu_book,
      l10n.quickOpenStudyBible,
      () => ctrl.openTab(
        const TabSpec(kind: PanelKind.resource, resourceType: 'studyBible'),
      ),
      key: const ValueKey('quick-study-bible'),
    ),
    _NavDef(
      Icons.compare_arrows,
      l10n.quickCompareBibles,
      () => ctrl.openTab(const TabSpec(kind: PanelKind.textComparison)),
      key: const ValueKey('quick-compare'),
    ),
    _NavDef(
      Icons.import_contacts,
      l10n.quickOpenDictionary,
      () => ctrl.openTab(
        const TabSpec(kind: PanelKind.resource, resourceType: 'dictionary'),
      ),
      key: const ValueKey('quick-dictionary'),
    ),
    _NavDef(
      Icons.wb_twilight,
      l10n.quickOpenDevotional,
      () => ctrl.openTab(const TabSpec(kind: PanelKind.devotional)),
      key: const ValueKey('quick-devotional'),
    ),
  ];
}

/// Cabecera de la barra lateral: logo + ómnibus (como el original).
class _SidebarHeader extends ConsumerWidget {
  const _SidebarHeader({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Row(
        children: [
          _Logo(collapsed: collapsed),
          if (!collapsed) ...[
            const SizedBox(width: 9),
            const Expanded(child: Omnibox()),
          ],
        ],
      ),
    );
  }
}

/// Cabecera de la barra de aplicaciones cuando la navegación va arriba.
class _TopHeader extends StatelessWidget {
  const _TopHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          _Logo(collapsed: false),
          SizedBox(width: 9),
          SizedBox(width: 340, child: Omnibox()),
        ],
      ),
    );
  }
}

/// Logo de la app (32 px). Con la barra plegada abre el ómnibus en un
/// diálogo, porque el rail no tiene ancho para el campo.
class _Logo extends StatelessWidget {
  const _Logo({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final logo = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: kAccent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.menu_book, color: Colors.white, size: 18),
    );
    if (!collapsed) return logo;
    return Tooltip(
      message: context.l10n.omniboxHint,
      child: InkWell(
        key: const ValueKey('sidebar-omnibox'),
        borderRadius: BorderRadius.circular(8),
        onTap: () => _openOmniboxDialog(context),
        child: logo,
      ),
    );
  }
}

Future<void> _openOmniboxDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Omnibox(
            autofocus: true,
            onNavigated: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
    ),
  );
}

class _Banner extends ConsumerWidget {
  const _Banner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Container(
      key: const ValueKey('app-banner'),
      height: 48,
      color: kBannerBg,
      padding: const EdgeInsets.only(left: 16, right: 4),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                l10n.bannerDev,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          FilledButton(
            onPressed: () =>
                ref.read(libraryOverlayVisibleProvider.notifier).open(),
            style: FilledButton.styleFrom(
              backgroundColor: kFieldFill,
              foregroundColor: kBannerBg,
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              textStyle: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            child: Text(l10n.bannerOpenLibrary),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            iconSize: 16,
            tooltip: l10n.bannerClose,
            onPressed: () => ref
                .read(workspaceProvider.notifier)
                .setLayoutBannersVisible(false),
            icon: const Icon(Icons.close, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

/// Barra de aplicaciones horizontal (Ajustes 8.1 = Arriba).
class _TopNavBar extends ConsumerWidget {
  const _TopNavBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workspaceProvider);
    final ctrl = ref.read(workspaceProvider.notifier);
    final l10n = context.l10n;
    final items = _navDefs(context, ref);

    return Container(
      key: const ValueKey('top-nav-bar'),
      height: 40,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  for (final item in items)
                    InkWell(
                      key: item.key,
                      onTap: item.onTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        child: Row(
                          children: [
                            Icon(item.icon, size: 17, color: kTextSecondary),
                            const SizedBox(width: 7),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 13,
                                color: kTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ToolsMenuButton(
                    menuKey: 'tools-menu-top',
                    trigger: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.grid_view_outlined,
                            size: 17,
                            color: kTextSecondary,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            l10n.navTools,
                            style: TextStyle(fontSize: 13, color: kTextPrimary),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 17,
                            color: kTextSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (state.quickActionsVisible)
            PopupMenuButton<int>(
              tooltip: l10n.navQuickActions,
              position: PopupMenuPosition.under,
              itemBuilder: (context) => [
                for (final (i, item) in _quickActionDefs(context, ref).indexed)
                  PopupMenuItem(
                    value: i,
                    child: Row(
                      children: [
                        Icon(item.icon, size: 16, color: kTextSecondary),
                        const SizedBox(width: 9),
                        Text(item.label, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
              ],
              onSelected: (index) =>
                  _quickActionDefs(context, ref)[index].onTap(),
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.bolt_outlined,
                  size: 17,
                  color: kTextSecondary,
                ),
              ),
            ),
          LayoutsMenuButton(
            menuKey: 'layouts-menu-top',
            trigger: Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.grid_view_rounded,
                size: 17,
                color: kTextSecondary,
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.navCloseAllTabs,
            iconSize: 17,
            onPressed: ctrl.closeAllTabs,
            icon: Icon(Icons.close_fullscreen, color: kTextSecondary),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.collapsed});

  /// Ventana estrecha: por defecto se muestra como rail de iconos; la flecha
  /// del pie fija la preferencia explícita del usuario (que manda sobre el
  /// automatismo).
  final bool collapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workspaceProvider);
    final ctrl = ref.read(workspaceProvider.notifier);
    final l10n = context.l10n;
    // Resalte del ítem activo (como el original): la Biblioteca manda cuando
    // su overlay está abierto y, si no, el panel activo del workspace.
    final selectedId = ref.watch(libraryOverlayVisibleProvider)
        ? 'library'
        : _activeNavId(state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in _navDefs(context, ref))
                  _navItem(
                    collapsed,
                    item.icon,
                    item.label,
                    () => _runSidebarAction(context, ref, item.onTap),
                    key: item.key,
                    selected: item.id == selectedId,
                  ),
                ToolsMenuButton(
                  menuKey: 'tools-menu-sidebar',
                  trigger: _navTrigger(
                    collapsed,
                    Icons.grid_view,
                    l10n.navTools,
                  ),
                ),
                if (state.quickActionsVisible) ...[
                  const _SideDivider(),
                  if (!collapsed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(17, 6, 16, 3),
                      child: Text(
                        l10n.navQuickActions,
                        style: TextStyle(
                          fontSize: 12,
                          color: kTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (collapsed) const SizedBox(height: 6),
                  for (final item in _quickActionDefs(context, ref))
                    _navItem(
                      collapsed,
                      item.icon,
                      item.label,
                      () => _runSidebarAction(context, ref, item.onTap),
                      key: item.key,
                      compact: true,
                    ),
                ],
                const _SideDivider(),
                _navItem(
                  collapsed,
                  Icons.storefront,
                  l10n.navStore,
                  () => _runSidebarAction(
                    context,
                    ref,
                    () => ctrl.openTab(const TabSpec(kind: PanelKind.store)),
                  ),
                  compact: true,
                ),
                if (!collapsed)
                  LayoutsMenuButton(
                    menuKey: 'layouts-menu-sidebar',
                    trigger: _navTrigger(
                      collapsed,
                      Icons.grid_view_rounded,
                      l10n.navLayouts,
                      compact: true,
                    ),
                  ),
                _navItem(
                  collapsed,
                  Icons.close_fullscreen,
                  l10n.navCloseAllTabs,
                  ctrl.closeAllTabs,
                  compact: true,
                ),
              ],
            ),
          ),
        ),
        _SideFooter(collapsed: collapsed),
      ],
    );
  }
}

/// En ventanas estrechas la barra lateral se expande como panel temporal:
/// tras abrir un destino se pliega para devolver el ancho al workspace.
void _runSidebarAction(
  BuildContext context,
  WidgetRef ref,
  VoidCallback action,
) {
  // Plegar antes de abrir el destino evita un fotograma intermedio con el
  // panel comprimido entre la barra expandida y el borde de la ventana.
  if (MediaQuery.sizeOf(context).width < kSidebarAutoCollapseWidth) {
    ref.read(sidebarCollapsedProvider.notifier).setCollapsed(true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) action();
    });
    return;
  }
  action();
}

/// Id del ítem de navegación que corresponde al panel activo.
String? _activeNavId(WorkspaceState state) {
  const byKind = <PanelKind, String>{
    PanelKind.dashboard: 'dashboard',
    PanelKind.library: 'library',
    PanelKind.search: 'search',
    PanelKind.bible: 'bible',
    PanelKind.resource: 'bible',
    PanelKind.studyAssistant: 'assistant',
    PanelKind.factbook: 'topics',
    PanelKind.guidedStudy: 'guided',
    PanelKind.notes: 'notes',
    PanelKind.tools: 'tools',
  };
  for (final tile in state.tiles) {
    final kind = tile.activeTab?.kind;
    final id = kind == null ? null : byKind[kind];
    if (id != null) return id;
  }
  return null;
}

class _SideDivider extends StatelessWidget {
  const _SideDivider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    child: Divider(height: 1),
  );
}

/// Fila de la barra lateral que abre un menú (Herramientas, Diseños).
Widget _navTrigger(
  bool collapsed,
  IconData icon,
  String label, {
  bool compact = false,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
    child: SizedBox(
      height: compact ? 30 : 44,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 9),
        child: Row(
          mainAxisAlignment: collapsed
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Icon(icon, size: compact ? 18 : 20, color: kTextSecondary),
            if (!collapsed) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 13 : 14.5,
                    fontWeight: compact ? FontWeight.w500 : FontWeight.w600,
                    color: kTextSecondary,
                  ),
                ),
              ),
              Icon(Icons.arrow_drop_down, size: 18, color: kTextSecondary),
            ],
          ],
        ),
      ),
    ),
  );
}

Widget _navItem(
  bool collapsed,
  IconData icon,
  String label,
  VoidCallback onTap, {
  Key? key,
  bool selected = false,
  bool compact = false,
}) {
  final radius = BorderRadius.circular(8);
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
    child: Material(
      color: selected ? kPanelBg : Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        // La key se conserva con el sidebar colapsado (el texto desaparece),
        // para poder apuntar al ítem desde pruebas de integración.
        key: key,
        onTap: onTap,
        borderRadius: radius,
        hoverColor: kPanelBg.withValues(alpha: 0.65),
        child: SizedBox(
          height: compact ? 30 : 44,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 9),
            child: Row(
              mainAxisAlignment: collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: compact ? 16 : 20,
                  color: selected ? kAccent : kTextSecondary,
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 12.5 : 14.5,
                        fontWeight: compact ? FontWeight.w500 : FontWeight.w600,
                        color: selected ? kAccent : kTextSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _SideFooter extends ConsumerWidget {
  const _SideFooter({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(workspaceProvider.notifier);
    final l10n = context.l10n;

    final more = PopupMenuButton<String>(
      tooltip: l10n.moreOptions,
      position: PopupMenuPosition.under,
      onSelected: (value) {
        if (value == 'settings') {
          ctrl.openTab(const TabSpec(kind: PanelKind.settings));
        } else if (value == 'store') {
          ctrl.openTab(const TabSpec(kind: PanelKind.store));
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'settings',
          height: 34,
          child: Text(
            l10n.menuSettings,
            style: const TextStyle(fontSize: 13.5),
          ),
        ),
        PopupMenuItem(
          value: 'store',
          height: 34,
          child: Text(
            l10n.menuResourceCatalog,
            style: const TextStyle(fontSize: 13.5),
          ),
        ),
        PopupMenuItem(
          enabled: false,
          height: 34,
          child: Text(
            l10n.menuOriginalStore,
            style: const TextStyle(fontSize: 13.5),
          ),
        ),
        PopupMenuItem(
          enabled: false,
          height: 34,
          child: Text(
            l10n.menuDownloadApp,
            style: const TextStyle(fontSize: 13.5),
          ),
        ),
      ],
      child: Padding(
        padding: EdgeInsets.all(6),
        child: Icon(Icons.more_vert, size: 17, color: kTextSecondary),
      ),
    );

    final toggle = Tooltip(
      message: collapsed ? l10n.sidebarExpand : l10n.sidebarCollapse,
      child: InkWell(
        // Alterna la preferencia explícita: en ventanas estrechas el usuario
        // puede expandirla igualmente (y al contrario).
        onTap: () => ref
            .read(sidebarCollapsedProvider.notifier)
            .setCollapsed(!collapsed),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            collapsed ? Icons.chevron_right : Icons.chevron_left,
            size: 17,
            color: kTextSecondary,
          ),
        ),
      ),
    );

    if (collapsed) {
      // Rail angosto: apilar verticalmente para no desbordar el ancho.
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(mainAxisSize: MainAxisSize.min, children: [more, toggle]),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        children: [
          more,
          const SizedBox(width: 2),
          Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.help_outline, size: 17, color: kTextSecondary),
          ),
          const Spacer(),
          toggle,
        ],
      ),
    );
  }
}
