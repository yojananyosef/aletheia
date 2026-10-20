import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';
import 'persistence.dart';

class WorkspaceController extends Notifier<WorkspaceState> {
  Timer? _saveTimer;
  int _seq = 0;

  @override
  WorkspaceState build() {
    ref.onDispose(() => _saveTimer?.cancel());
    return ref.read(workspaceStoreProvider).initial;
  }

  String _newId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_seq++}';

  void _commit(WorkspaceState next) {
    state = next;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), () {
      ref.read(workspaceStoreProvider).save(state);
    });
  }

  WorkspaceState _copy({
    List<WorkspaceTile>? tiles,
    String? layoutId,
    bool? bannerVisible,
    bool? quickActionsVisible,
    bool? layoutBannersVisible,
    String? toolbarLocation,
    String? locale,
    String? themeMode,
    String? citationStyle,
    bool? copyCitations,
    bool? hyperlinkCitations,
    bool? limitedView,
    String? catalogUrl,
    String? catalogMode,
    List<SavedLayout>? savedLayouts,
  }) => WorkspaceState(
    layoutId: layoutId ?? state.layoutId,
    tiles: tiles ?? state.tiles,
    bannerVisible: bannerVisible ?? state.bannerVisible,
    quickActionsVisible: quickActionsVisible ?? state.quickActionsVisible,
    layoutBannersVisible: layoutBannersVisible ?? state.layoutBannersVisible,
    toolbarLocation: toolbarLocation ?? state.toolbarLocation,
    locale: locale ?? state.locale,
    themeMode: themeMode ?? state.themeMode,
    citationStyle: citationStyle ?? state.citationStyle,
    copyCitations: copyCitations ?? state.copyCitations,
    hyperlinkCitations: hyperlinkCitations ?? state.hyperlinkCitations,
    limitedView: limitedView ?? state.limitedView,
    catalogUrl: catalogUrl ?? state.catalogUrl,
    catalogMode: catalogMode ?? state.catalogMode,
    savedLayouts: savedLayouts ?? state.savedLayouts,
  );

  static WorkspaceTile _tileWith(
    WorkspaceTile tile, {
    List<WorkspaceTab>? tabs,
    int? activeIndex,
  }) => WorkspaceTile(
    id: tile.id,
    tabs: tabs ?? tile.tabs,
    activeIndex: activeIndex ?? tile.activeIndex,
  );

  static const _toolKinds = {
    PanelKind.dashboard,
    PanelKind.library,
    PanelKind.store,
    PanelKind.search,
    PanelKind.settings,
    PanelKind.tools,
    PanelKind.notes,
  };

  // ------------------------------------------------------------------ tabs

  /// Abre una pestaña según la semántica del original:
  /// herramientas (Search/Library/Dashboard/Settings/Store) → tile izquierdo;
  /// recursos (Bible, Factbook, Notes, …) → tile derecho.
  void openTab(TabSpec spec) {
    // Un workspace sin tiles (estado inicial mínimo) crea el suyo: así el
    // panel siempre tiene dónde abrirse.
    if (state.tiles.isEmpty) {
      _commit(_copy(tiles: [WorkspaceTile(id: _newId('tile'))]));
    }
    final tiles = state.tiles;
    if (tiles.isEmpty) return;

    // Reutilizar la pestaña existente del mismo tipo (y referencia y recurso,
    // si aplica): abrir otra versión no debe quedarse con el panel anterior.
    for (final tile in tiles) {
      for (var i = 0; i < tile.tabs.length; i++) {
        final tab = tile.tabs[i];
        if (tab.kind != spec.kind) continue;
        final sameRef =
            spec.reference == null || tab.reference == spec.reference;
        final sameResource =
            spec.resourceId == null ||
            (tab.resourceId ?? kDefaultBibleResourceId) == spec.resourceId;
        final reusable =
            _toolKinds.contains(spec.kind) || (sameRef && sameResource);
        if (!reusable) continue;

        var updated = tab;
        if (spec.kind == PanelKind.search &&
            spec.query != null &&
            spec.query != tab.query) {
          updated = _tabWithQuery(updated, spec.query!);
        }
        updated = updated.copyWith(
          title: spec.title ?? updated.title,
          reference: spec.reference ?? updated.reference,
          query: spec.query ?? updated.query,
          resourceType: spec.resourceType ?? updated.resourceType,
          resourceId: spec.resourceId ?? updated.resourceId,
        );
        final newTabs = [...tile.tabs]..[i] = updated;
        final newTiles = [
          for (final t in tiles)
            t.id == tile.id ? _tileWith(t, tabs: newTabs, activeIndex: i) : t,
        ];
        _commit(_copy(tiles: newTiles));
        return;
      }
    }

    final preferLeft = const {
      PanelKind.dashboard,
      PanelKind.library,
      PanelKind.store,
      PanelKind.search,
      PanelKind.settings,
    }.contains(spec.kind);
    final target = preferLeft ? tiles[0] : tiles[tiles.length - 1];

    // El historial de una pestaña de búsqueda guarda consultas.
    final seed = spec.kind == PanelKind.search ? spec.query : spec.reference;
    final tab = WorkspaceTab(
      id: _newId('tab'),
      kind: spec.kind,
      // Sin título almacenado: se muestra el del tipo en el idioma activo.
      title: spec.title ?? '',
      reference: spec.reference,
      query: spec.query,
      resourceType: spec.resourceType,
      resourceId: spec.resourceId,
      // Una pestaña que nace en una ubicación ya la tiene en su historial.
      history: seed == null ? const [] : [seed],
      historyIndex: seed == null ? -1 : 0,
    );
    final newTiles = [
      for (final t in tiles)
        t.id == target.id
            ? _tileWith(t, tabs: [...t.tabs, tab], activeIndex: t.tabs.length)
            : t,
    ];
    _commit(_copy(tiles: newTiles));
  }

  void activateTab(String tileId, int index) {
    final newTiles = [
      for (final t in state.tiles)
        t.id == tileId ? _tileWith(t, activeIndex: index) : t,
    ];
    _commit(_copy(tiles: newTiles));
  }

  void closeTab(String tileId, int index) {
    final newTiles = [
      for (final t in state.tiles)
        if (t.id == tileId)
          _tileWith(
            t,
            tabs: [...t.tabs]..removeAt(index),
            activeIndex: index >= t.tabs.length - 1 && index > 0
                ? index - 1
                : index,
          )
        else
          t,
    ];
    _commit(_copy(tiles: newTiles));
  }

  void closeOtherTabs(String tileId, int index) {
    final newTiles = [
      for (final t in state.tiles)
        if (t.id == tileId)
          _tileWith(t, tabs: [t.tabs[index]], activeIndex: 0)
        else
          t,
    ];
    _commit(_copy(tiles: newTiles));
  }

  void closeTabsToRight(String tileId, int index) {
    final newTiles = [
      for (final t in state.tiles)
        if (t.id == tileId)
          _tileWith(t, tabs: t.tabs.sublist(0, index + 1), activeIndex: index)
        else
          t,
    ];
    _commit(_copy(tiles: newTiles));
  }

  void duplicateTab(String tileId, int index) {
    final newTiles = [
      for (final t in state.tiles)
        if (t.id == tileId)
          () {
            final source = t.tabs[index];
            final copy = WorkspaceTab(
              id: _newId('tab'),
              kind: source.kind,
              title: source.title,
              reference: source.reference,
              query: source.query,
              resourceType: source.resourceType,
              resourceId: source.resourceId,
              linkSet: source.linkSet,
              history: source.history,
              historyIndex: source.historyIndex,
            );
            final tabs = [...t.tabs]..insert(index + 1, copy);
            return _tileWith(t, tabs: tabs, activeIndex: index + 1);
          }()
        else
          t,
    ];
    _commit(_copy(tiles: newTiles));
  }

  void closeAllTabs() {
    final newTiles = [
      for (final t in state.tiles) _tileWith(t, tabs: const [], activeIndex: 0),
    ];
    _commit(_copy(tiles: newTiles));
  }

  /// Actualiza la consulta y/o la referencia de una pestaña (Estudio guiado).
  void updateTab({
    required String tileId,
    required String tabId,
    String? query,
    String? reference,
  }) {
    _updateTab(
      tileId,
      tabId,
      (tab) => tab.copyWith(
        query: query ?? tab.query,
        reference: reference ?? tab.reference,
      ),
    );
  }

  /// Navega el lector de una pestaña y registra la referencia en su historial.
  ///
  /// Si la pestaña pertenece a un conjunto de vínculos, el resto de paneles
  /// bíblicos con la misma letra siguen la navegación (como «Link set» en el
  /// original). La propagación es de una sola dirección: los paneles
  /// seguidores no vuelven a emitir la referencia.
  void navigateTabReference({
    required String tileId,
    required String tabId,
    required String reference,
  }) {
    final source = _findTab(tileId, tabId);
    if (source == null) return;
    _navigateLinked(tileId, tabId, reference, linkSet: source.linkSet);
  }

  void _navigateLinked(
    String tileId,
    String tabId,
    String reference, {
    String? linkSet,
  }) {
    final newTiles = [
      for (final tile in state.tiles)
        _tileWith(
          tile,
          tabs: [
            for (final tab in tile.tabs)
              if (tile.id == tileId && tab.id == tabId)
                _tabWithReference(tab, reference)
              else if (linkSet != null &&
                  tab.kind == PanelKind.bible &&
                  tab.linkSet == linkSet)
                _tabWithReference(tab, reference)
              else
                tab,
          ],
        ),
    ];
    _commit(_copy(tiles: newTiles));
  }

  /// Asigna (o quita, con `null`) el conjunto de vínculos de una pestaña.
  ///
  /// Al entrar en un conjunto, la pestaña comparte su ubicación actual con
  /// los demás paneles bíblicos que ya estén en ese conjunto.
  void setTabLinkSet({
    required String tileId,
    required String tabId,
    required String? linkSet,
  }) {
    if (linkSet != null && !kLinkSetIds.contains(linkSet)) return;
    final source = _findTab(tileId, tabId);
    if (source == null) return;
    final reference = source.reference;
    final newTiles = [
      for (final tile in state.tiles)
        _tileWith(
          tile,
          tabs: [
            for (final tab in tile.tabs)
              if (tile.id == tileId && tab.id == tabId)
                tab.copyWith(linkSet: linkSet, clearLinkSet: linkSet == null)
              else if (linkSet != null &&
                  reference != null &&
                  tab.kind == PanelKind.bible &&
                  tab.linkSet == linkSet)
                _tabWithReference(tab, reference)
              else
                tab,
          ],
        ),
    ];
    _commit(_copy(tiles: newTiles));
  }

  /// Devuelve la pestaña con [reference] como ubicación actual, registrándola
  /// en el historial (recortando el "futuro" si se venía navegando hacia atrás).
  static WorkspaceTab _tabWithReference(WorkspaceTab tab, String reference) {
    if (tab.reference == reference) return tab;
    var base = tab.history;
    var index = tab.historyIndex;
    if (base.isEmpty && tab.reference != null) {
      base = [tab.reference!];
      index = 0;
    }
    final truncated = index >= 0 && index < base.length
        ? base.sublist(0, index + 1)
        : [...base];
    truncated.add(reference);
    return tab.copyWith(
      reference: reference,
      history: truncated,
      historyIndex: truncated.length - 1,
    );
  }

  /// Devuelve la pestaña con [query] como consulta actual de búsqueda,
  /// registrándola en el historial (en las pestañas de búsqueda el historial
  /// guarda consultas en lugar de referencias).
  static WorkspaceTab _tabWithQuery(WorkspaceTab tab, String query) {
    if (tab.query == query) return tab;
    var base = tab.history;
    var index = tab.historyIndex;
    if (base.isEmpty && tab.query != null) {
      base = [tab.query!];
      index = 0;
    }
    final truncated = index >= 0 && index < base.length
        ? base.sublist(0, index + 1)
        : [...base];
    truncated.add(query);
    return tab.copyWith(
      query: query,
      history: truncated,
      historyIndex: truncated.length - 1,
    );
  }

  /// Salta a una entrada del historial del panel (atrás/adelante y menú).
  void historyGo({
    required String tileId,
    required String tabId,
    required int index,
  }) {
    final source = _findTab(tileId, tabId);
    if (source == null || index < 0 || index >= source.history.length) return;
    if (index == source.historyIndex) return;
    final reference = source.history[index];
    final linkSet = source.linkSet;
    final newTiles = [
      for (final tile in state.tiles)
        _tileWith(
          tile,
          tabs: [
            for (final tab in tile.tabs)
              if (tile.id == tileId && tab.id == tabId)
                tab.copyWith(reference: reference, historyIndex: index)
              else if (linkSet != null &&
                  tab.kind == PanelKind.bible &&
                  tab.linkSet == linkSet)
                _tabWithReference(tab, reference)
              else
                tab,
          ],
        ),
    ];
    _commit(_copy(tiles: newTiles));
  }

  /// Registra una búsqueda en el historial de la pestaña (M2).
  void recordSearch({
    required String tileId,
    required String tabId,
    required String query,
  }) {
    _updateTab(tileId, tabId, (tab) => _tabWithQuery(tab, query));
  }

  /// Salta a una consulta del historial de la pestaña de búsqueda.
  void searchHistoryGo({
    required String tileId,
    required String tabId,
    required int index,
  }) {
    _updateTab(tileId, tabId, (tab) {
      if (index < 0 || index >= tab.history.length) return tab;
      if (index == tab.historyIndex) return tab;
      return tab.copyWith(query: tab.history[index], historyIndex: index);
    });
  }

  /// Activa la primera pestaña del recurso sin cambiar su ubicación.
  /// Devuelve `false` si no había ninguna abierta.
  bool revealResourceTab(String resourceId) {
    for (final tile in state.tiles) {
      for (var i = 0; i < tile.tabs.length; i++) {
        if (tile.tabs[i].resourceId != resourceId) continue;
        _commit(
          _copy(
            tiles: [
              for (final t in state.tiles)
                t.id == tile.id ? _tileWith(t, activeIndex: i) : t,
            ],
          ),
        );
        return true;
      }
    }
    return false;
  }

  /// Abre [reference] en una pestaña ya abierta del recurso (la activa y
  /// navega). Devuelve `false` si no había ninguna.
  ///
  /// [kind] distingue Biblia, Factbook y devocional; los paneles sin
  /// `resourceId` propio usan su recurso por defecto.
  bool openInResource({
    required String resourceId,
    required String reference,
    PanelKind kind = PanelKind.bible,
  }) {
    for (final tile in state.tiles) {
      for (var i = 0; i < tile.tabs.length; i++) {
        final tab = tile.tabs[i];
        if (tab.kind != kind) continue;
        final activeResource =
            tab.resourceId ??
            switch (tab.kind) {
              PanelKind.bible => kDefaultBibleResourceId,
              PanelKind.factbook => 'factbook.core',
              PanelKind.devotional => 'devotional.daily',
              _ => null,
            };
        if (activeResource != resourceId) continue;
        final linkSet = tab.linkSet;
        _commit(
          _copy(
            tiles: [
              for (final t in state.tiles)
                _tileWith(
                  t,
                  tabs: [
                    for (final candidate in t.tabs)
                      if (t.id == tile.id && candidate.id == tab.id)
                        _tabWithReference(candidate, reference)
                      else if (linkSet != null &&
                          candidate.kind == PanelKind.bible &&
                          candidate.linkSet == linkSet)
                        _tabWithReference(candidate, reference)
                      else
                        candidate,
                  ],
                  activeIndex: t.id == tile.id ? i : null,
                ),
            ],
          ),
        );
        return true;
      }
    }
    return false;
  }

  /// Ajustes del catálogo (M2): dirección del servicio y modo.
  void setCatalogSettings({String? url, String? mode}) {
    final nextMode = mode != null && kCatalogModes.contains(mode) ? mode : null;
    if (url != null && url.trim() == state.catalogUrl && nextMode == null) {
      return;
    }
    _commit(_copy(catalogUrl: url?.trim(), catalogMode: nextMode));
  }

  /// Ajustes de la aplicación (M3, filas de Ajustes 8.x).
  void setToolbarLocation(String location) {
    if (!kToolbarLocations.contains(location)) return;
    _commit(_copy(toolbarLocation: location));
  }

  void setLocale(String locale) {
    if (!const {'system', 'es', 'en'}.contains(locale)) return;
    _commit(_copy(locale: locale));
  }

  void setThemeMode(String mode) {
    if (!kThemeModes.contains(mode)) return;
    _commit(_copy(themeMode: mode));
  }

  void setCitationSettings({String? style, bool? copy, bool? hyperlink}) {
    _commit(
      _copy(
        citationStyle: style != null && kCitationStyles.contains(style)
            ? style
            : null,
        copyCitations: copy,
        hyperlinkCitations: hyperlink,
      ),
    );
  }

  void setLimitedView(bool value) => _commit(_copy(limitedView: value));

  void setLayoutBannersVisible(bool value) =>
      _commit(_copy(layoutBannersVisible: value));

  /// Fila «Restablecer valores» de Ajustes: vuelve a los valores por defecto
  /// sin tocar el workspace (pestañas, diseños ni catálogo).
  void resetSettings() {
    _commit(
      _copy(
        quickActionsVisible: true,
        bannerVisible: true,
        layoutBannersVisible: true,
        toolbarLocation: 'left',
        locale: 'system',
        themeMode: 'system',
        citationStyle: 'turabian',
        copyCitations: true,
        hyperlinkCitations: false,
        limitedView: false,
      ),
    );
  }

  /// Presentación de una pestaña del lector (M3): reformato, vista y zoom.
  void updateTabDisplay({
    required String tileId,
    required String tabId,
    required TabDisplay display,
  }) {
    _updateTab(tileId, tabId, (tab) => tab.copyWith(display: display));
  }

  /// Cambia la Biblia que muestra una pestaña del lector (M2).
  void switchBibleResource({
    required String tileId,
    required String tabId,
    required String resourceId,
    required String title,
  }) {
    _updateTab(
      tileId,
      tabId,
      (tab) => tab.copyWith(resourceId: resourceId, title: title),
    );
  }

  WorkspaceTab? _findTab(String tileId, String tabId) {
    for (final tile in state.tiles) {
      if (tile.id != tileId) continue;
      for (final tab in tile.tabs) {
        if (tab.id == tabId) return tab;
      }
    }
    return null;
  }

  void _updateTab(
    String tileId,
    String tabId,
    WorkspaceTab Function(WorkspaceTab tab) transform,
  ) {
    var found = false;
    final newTiles = [
      for (final t in state.tiles)
        if (t.id == tileId)
          () {
            var tileFound = false;
            final newTabs = [
              for (final tab in t.tabs)
                if (tab.id == tabId)
                  () {
                    tileFound = true;
                    return transform(tab);
                  }()
                else
                  tab,
            ];
            if (!tileFound) return t;
            found = true;
            return _tileWith(t, tabs: newTabs);
          }()
        else
          t,
    ];
    if (found) _commit(_copy(tiles: newTiles));
  }

  // ---------------------------------------------------------------- layout

  /// Guarda el diseño actual (preset + tiles) con un nombre (M5).
  void saveCurrentLayout(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final saved = SavedLayout(
      id: _newId('layout'),
      name: trimmed,
      layoutId: state.layoutId,
      tiles: state.tiles
          .map((tile) => WorkspaceTile.fromJson(tile.toJson()))
          .toList(),
    );
    _commit(_copy(savedLayouts: [...state.savedLayouts, saved]));
  }

  /// Restaura un diseño guardado, con copias independientes de sus tiles.
  bool applySavedLayout(String id) {
    SavedLayout? saved;
    for (final layout in state.savedLayouts) {
      if (layout.id == id) {
        saved = layout;
        break;
      }
    }
    if (saved == null) return false;
    final tiles = saved.tiles
        .map((tile) => WorkspaceTile.fromJson(tile.toJson()))
        .toList();
    _commit(_copy(layoutId: saved.layoutId, tiles: tiles));
    return true;
  }

  void deleteSavedLayout(String id) {
    final next = [
      for (final layout in state.savedLayouts)
        if (layout.id != id) layout,
    ];
    if (next.length == state.savedLayouts.length) return;
    _commit(_copy(savedLayouts: next));
  }

  void setLayout(String layoutId) {
    final pattern = kLayoutPatterns[layoutId];
    if (pattern == null) return;
    final targetCount = pattern.fold<int>(0, (a, columns) => a + columns);

    final tiles = [...state.tiles];
    while (tiles.length > targetCount) {
      final removed = tiles.removeLast();
      if (tiles.isEmpty) break;
      final last = tiles.last;
      tiles[tiles.length - 1] = _tileWith(
        last,
        tabs: [...last.tabs, ...removed.tabs],
        activeIndex: last.tabs.isEmpty ? removed.activeIndex : last.activeIndex,
      );
    }
    while (tiles.length < targetCount) {
      tiles.add(WorkspaceTile(id: _newId('tile')));
    }
    _commit(_copy(layoutId: layoutId, tiles: tiles));
  }

  void setBannerVisible(bool visible) => _commit(_copy(bannerVisible: visible));

  void setQuickActionsVisible(bool visible) =>
      _commit(_copy(quickActionsVisible: visible));
}

final workspaceProvider = NotifierProvider<WorkspaceController, WorkspaceState>(
  WorkspaceController.new,
);
