import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/document_repository.dart';
import '../core/localization.dart';
import '../core/panel_meta.dart';
import '../core/resource_colors.dart';
import '../core/theme.dart';
import '../panels/panel_host.dart';
import 'models.dart';
import 'panel_fullscreen.dart';
import 'workspace_controller.dart';

/// Área de trabajo: filas de tiles según el preset de layout.
///
/// Adaptativo (ver skill `flutter-build-responsive-layout`): los tiles se
/// mantienen **siempre lado a lado** (igual que el original), pero si el área
/// de trabajo no alcanza para todos con [kMinTileWidth] cada uno, se muestran
/// solo los que caben —en orden y salteando tiles vacíos— y el resto vuelve a
/// aparecer al ensanchar la ventana. Se mide sobre el ancho del *workspace*
/// (no de la ventana) para que la decisión siga al espacio real disponible.
class WorkspaceView extends ConsumerWidget {
  const WorkspaceView({super.key});

  /// Separación entre tiles.
  static const double _gap = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workspaceProvider);

    return Container(
      color: kWorkspaceBg,
      padding: const EdgeInsets.fromLTRB(0, 0, 8, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final widest = state.pattern.fold<int>(0, (m, c) => c > m ? c : m);
          if (state.tiles.isEmpty ||
              _fittingColumns(constraints.maxWidth) >= widest) {
            return Column(children: _rows(state));
          }
          return Row(
            children: _visibleTiles(
              state,
              _fittingColumns(constraints.maxWidth),
            ),
          );
        },
      ),
    );
  }

  /// Cuántas columnas caben conservando [kMinTileWidth] por panel.
  int _fittingColumns(double width) {
    final fit = ((width + _gap) / (kMinTileWidth + _gap)).floor();
    return fit < 1 ? 1 : fit;
  }

  /// Ventana de tiles visible cuando no caben todos: primero los que tienen
  /// pestañas abiertas, para no gastar espacio en tiles vacíos.
  List<Widget> _visibleTiles(WorkspaceState state, int columns) {
    final withTabs = state.tiles.where((t) => t.tabs.isNotEmpty).toList();
    final ordered = withTabs.isEmpty ? state.tiles : withTabs;
    final visible = ordered.take(columns).toList();

    final children = <Widget>[];
    for (final tile in visible) {
      if (children.isNotEmpty) children.add(const SizedBox(width: _gap));
      children.add(
        Expanded(
          child: _TileView(key: ValueKey('tile-${tile.id}'), tile: tile),
        ),
      );
    }
    return children;
  }

  List<Widget> _rows(WorkspaceState state) {
    var index = 0;
    final rows = <Widget>[];
    for (final columns in state.pattern) {
      final rowChildren = <Widget>[];
      for (var c = 0; c < columns; c++) {
        final tile = index < state.tiles.length ? state.tiles[index] : null;
        index++;
        if (tile == null) continue;
        if (rowChildren.isNotEmpty) {
          rowChildren.add(const SizedBox(width: _gap));
        }
        rowChildren.add(
          Expanded(
            child: _TileView(key: ValueKey('tile-${tile.id}'), tile: tile),
          ),
        );
      }
      if (rows.isNotEmpty) rows.add(const SizedBox(height: _gap));
      rows.add(Expanded(child: Row(children: rowChildren)));
    }
    return rows;
  }
}

class _TileView extends ConsumerWidget {
  const _TileView({super.key, required this.tile});

  final WorkspaceTile tile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = tile.activeTab;
    // La tira de pestañas vive sobre el chrome del workspace y el panel es
    // una tarjeta blanca aparte (como en el original): así la pestaña activa
    // «se apoya» en el panel y el fondo gris se ve alrededor.
    return Listener(
      behavior: HitTestBehavior.translucent,
      // Tocar cualquier punto del panel lo vuelve el destino de las pestañas
      // nuevas y de los arrastres.
      onPointerDown: (_) =>
          ref.read(workspaceProvider.notifier).focusTile(tile.id),
      child: DragTarget<_TabDragData>(
        onWillAcceptWithDetails: (details) => details.data.tileId != tile.id,
        onAcceptWithDetails: (details) => ref
            .read(workspaceProvider.notifier)
            .moveTab(
              fromTileId: details.data.tileId,
              tabId: details.data.tabId,
              toTileId: tile.id,
            ),
        builder: (context, candidates, rejected) {
          final hovering = candidates.isNotEmpty;
          return Container(
            // El borde de destino no altera el layout (foregroundDecoration).
            foregroundDecoration: hovering
                ? BoxDecoration(
                    border: Border.all(color: kAccent, width: 2),
                    borderRadius: BorderRadius.circular(6),
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (tile.tabs.isNotEmpty) _TabStrip(tile: tile),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: kPanelBg,
                      // Sin borde superior: la pestaña activa (blanca) se apoya
                      // en el panel y el conjunto se lee como una sola pieza,
                      // igual que en el original.
                      border: Border(
                        left: BorderSide(color: kBorder),
                        right: BorderSide(color: kBorder),
                        bottom: BorderSide(color: kBorder),
                      ),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(6),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: tab == null
                        ? const _EmptyTile()
                        : PanelHost(tile: tile, tab: tab),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Datos que viajan al arrastrar una pestaña entre paneles.
class _TabDragData {
  const _TabDragData({required this.tileId, required this.tabId});

  final String tileId;
  final String tabId;
}

class _EmptyTile extends StatelessWidget {
  const _EmptyTile();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_box_outlined,
              size: 34,
              color: kTextSecondary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.workspaceEmptyTile,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: kTextSecondary.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabStrip extends ConsumerStatefulWidget {
  const _TabStrip({required this.tile});

  final WorkspaceTile tile;

  @override
  ConsumerState<_TabStrip> createState() => _TabStripState();
}

class _TabStripState extends ConsumerState<_TabStrip> {
  final _controller = ScrollController();
  final _scrollKey = GlobalKey();
  final _chipKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _revealActive();
  }

  @override
  void didUpdateWidget(covariant _TabStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Claves de pestañas cerradas: no hacen falta y no deben acumularse.
    _chipKeys.removeWhere(
      (id, _) => !widget.tile.tabs.any((tab) => tab.id == id),
    );
    // Al abrir o activar una pestaña que quedó fuera de la tira, se desplaza
    // lo justo para dejarla a la vista (como el original).
    if (oldWidget.tile.activeIndex != widget.tile.activeIndex ||
        oldWidget.tile.tabs.length != widget.tile.tabs.length) {
      _revealActive();
    }
  }

  void _revealActive() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tab = widget.tile.activeTab;
      if (tab == null) return;
      final chipContext = _chipKeys[tab.id]?.currentContext;
      final viewportContext = _scrollKey.currentContext;
      if (chipContext == null || viewportContext == null) return;
      final chip = chipContext.findRenderObject();
      final viewport = viewportContext.findRenderObject();
      if (chip is! RenderBox || viewport is! RenderBox) return;
      final chipLeft = chip.localToGlobal(Offset.zero).dx;
      final chipRight = chipLeft + chip.size.width;
      final viewportLeft = viewport.localToGlobal(Offset.zero).dx;
      final viewportRight = viewportLeft + viewport.size.width;
      double? alignment;
      if (chipLeft < viewportLeft) {
        alignment = 0;
      } else if (chipRight > viewportRight) {
        alignment = 1;
      }
      if (alignment == null) return;
      Scrollable.ensureVisible(
        chipContext,
        alignment: alignment,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tile = widget.tile;
    return SizedBox(
      height: 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: SingleChildScrollView(
              key: _scrollKey,
              controller: _controller,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < tile.tabs.length; i++)
                    _TabChip(
                      key: _chipKeys.putIfAbsent(
                        tile.tabs[i].id,
                        () => GlobalKey(debugLabel: 'tab-${tile.tabs[i].id}'),
                      ),
                      tile: tile,
                      index: i,
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: SizedBox(
              width: 28,
              height: 28,
              child: IconButton(
                padding: EdgeInsets.zero,
                tooltip: context.l10n.panelCommands,
                iconSize: 16,
                onPressed: () => _showTabMenu(
                  context,
                  ref,
                  tile,
                  tile.activeIndex.clamp(0, tile.tabs.length - 1),
                ),
                icon: const Icon(Icons.more_horiz),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends ConsumerWidget {
  const _TabChip({super.key, required this.tile, required this.index});

  final WorkspaceTile tile;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = tile.tabs[index];
    final active = index == tile.activeIndex;
    // Las pestañas de Biblia abiertas sin recurso usan el recurso por
    // defecto (el lector hace lo mismo).
    final resourceId =
        tab.resourceId ??
        (tab.kind == PanelKind.bible ? kDefaultBibleResourceId : null);
    final isResource = resourceId != null;
    final manifest = isResource
        ? ref.watch(manifestProvider(resourceId)).value
        : null;
    // Color de acento por recurso (en el original lo pone la portada); las
    // herramientas usan el azul de la app.
    final accent = isResource
        ? resourceColorFor(resourceId, resourceType: tab.resourceType)
        : kAccent;
    // La pestaña de un recurso se rotula con su abreviatura (como el
    // original); la referencia vive en la caja del panel.
    final fallbackAbbrev = (resourceId ?? '').split('.').last.toUpperCase();
    final label = isResource
        ? (manifest != null && manifest.abbrev.isNotEmpty
              ? manifest.abbrev
              : fallbackAbbrev)
        : tabTitle(context, tab);
    final chip = InkWell(
      key: ValueKey('tab-chip-${tab.id}'),
      onTap: () =>
          ref.read(workspaceProvider.notifier).activateTab(tile.id, index),
      onSecondaryTap: () => _showTabMenu(context, ref, tile, index),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        height: 36,
        margin: const EdgeInsets.only(right: 2),
        padding: const EdgeInsets.only(left: 8, right: 2),
        decoration: BoxDecoration(
          color: active ? kPanelBg : Colors.transparent,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(7),
            topRight: Radius.circular(7),
          ),
          border: Border(
            top: BorderSide(
              color: active ? accent : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isResource)
              Container(
                width: 16,
                height: 18,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Icon(
                  Icons.menu_book,
                  size: 10,
                  color: Colors.white,
                ),
              )
            else
              Icon(iconForKind(tab.kind), size: 16, color: kAccent),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: active ? kTextPrimary : kTextSecondary,
                ),
              ),
            ),
            SizedBox(
              width: 22,
              height: 22,
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 13,
                tooltip: context.l10n.tabClose,
                onPressed: () => ref
                    .read(workspaceProvider.notifier)
                    .closeTab(tile.id, index),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
    // La pestaña se puede arrastrar a otro panel (el propio DragTarget del
    // tile lo recibe). Se conserva el chip original cuando no se arrastra.
    return Draggable<_TabDragData>(
      data: _TabDragData(tileId: tile.id, tabId: tab.id),
      maxSimultaneousDrags: 1,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: kPanelBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(7),
              topRight: Radius.circular(7),
            ),
            border: Border(top: BorderSide(color: accent, width: 3)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isResource)
                Container(
                  width: 16,
                  height: 18,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Icon(
                    Icons.menu_book,
                    size: 10,
                    color: Colors.white,
                  ),
                )
              else
                Icon(iconForKind(tab.kind), size: 16, color: kAccent),
              const SizedBox(width: 7),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 190),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: chip),
      child: chip,
    );
  }
}

Future<void> _showTabMenu(
  BuildContext context,
  WidgetRef ref,
  WorkspaceTile tile,
  int index,
) async {
  if (tile.tabs.isEmpty || index < 0 || index >= tile.tabs.length) return;
  final box = context.findRenderObject() as RenderBox?;
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
  final position = box != null && overlay != null
      ? RelativeRect.fromRect(
          box.localToGlobal(Offset.zero, ancestor: overlay) & box.size,
          Offset.zero & overlay.size,
        )
      : const RelativeRect.fromLTRB(200, 200, 200, 200);

  final ctrl = ref.read(workspaceProvider.notifier);
  final l10n = context.l10n;
  final choice = await showMenu<String>(
    context: context,
    position: position,
    items: [
      PopupMenuItem(
        value: 'duplicate',
        height: 34,
        child: Text(l10n.tabDuplicate),
      ),
      PopupMenuItem(
        value: 'fullscreen',
        height: 34,
        child: Text(l10n.tabFullscreen),
      ),
      PopupMenuItem(value: 'close', height: 34, child: Text(l10n.tabCloseThis)),
      PopupMenuItem(
        value: 'right',
        height: 34,
        child: Text(l10n.tabCloseToRight),
      ),
      PopupMenuItem(
        value: 'others',
        height: 34,
        child: Text(l10n.tabCloseOthers),
      ),
      PopupMenuItem(value: 'all', height: 34, child: Text(l10n.tabCloseAll)),
    ],
  );
  switch (choice) {
    case 'duplicate':
      ctrl.duplicateTab(tile.id, index);
    case 'fullscreen':
      ref.read(panelFullscreenProvider.notifier).show(tile.tabs[index].id);
    case 'close':
      ctrl.closeTab(tile.id, index);
    case 'right':
      ctrl.closeTabsToRight(tile.id, index);
    case 'others':
      ctrl.closeOtherTabs(tile.id, index);
    case 'all':
      ctrl.closeAllTabs();
  }
}
