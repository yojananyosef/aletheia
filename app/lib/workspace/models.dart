/// Modelos del workspace (M0): layout → tiles → pestañas.
library;

import 'dart:ui' show Locale;

/// Tipos de panel soportados (M0: la mayoría son placeholders).
enum PanelKind {
  dashboard,
  library,
  store,
  search,
  bible,
  resource,
  studyAssistant,
  factbook,
  guidedStudy,
  notes,
  readingPlans,
  tools,
  textComparison,
  devotional,
  settings,
}

/// URL y modos por defecto del servicio de catálogo (M2).
const kDefaultCatalogUrl = 'http://127.0.0.1:8787';
const kCatalogModes = ['auto', 'local', 'remote'];

/// Biblia por defecto de la app (pestañas sin `resourceId` explícito).
const kDefaultBibleResourceId = 'bible.rv1909';

/// Ubicación de la barra de aplicaciones (Ajustes 8.1).
const kToolbarLocations = ['left', 'top'];

/// Estilos de cita del clon (Ajustes 8.6).
const kCitationStyles = ['turabian', 'sbl', 'chicago', 'plain'];

/// Conjuntos de vínculos entre paneles (A–F, como el original).
const kLinkSetIds = ['A', 'B', 'C', 'D', 'E', 'F'];

/// Tema de la interfaz (Ajustes 8.7): sistema, claro u oscuro.
const kThemeModes = ['system', 'light', 'dark'];

/// Ajustes de presentación de una pestaña del lector (M3).
///
/// Son los paneles del original: Formato → Reformato/Marcadores y
/// Vista → Vista paginada/Barra de ubicación/Zoom. Se persisten con el
/// workspace (cada panel conserva los suyos).
class TabDisplay {
  const TabDisplay({
    this.reformat = false,
    this.bibleTextFormatting = true,
    this.numbers = true,
    this.footnoteIndicators = true,
    this.nonBibleText = true,
    this.oneVersePerLine = false,
    this.sameSurfaceText = false,
    this.markers = false,
    this.markerNotebooks = const [],
    this.markerTags = const [],
    this.paged = false,
    this.columns = 'auto',
    this.footnotesOnPage = false,
    this.zoom = 100,
    this.locationBar = true,
    this.secondaryToolbar = true,
  });

  static const defaults = TabDisplay();

  /// Interruptor maestro de «Reformato»: con él apagado el lector usa el
  /// formato por defecto del recurso.
  final bool reformat;
  final bool bibleTextFormatting;
  final bool numbers;
  final bool footnoteIndicators;
  final bool nonBibleText;
  final bool oneVersePerLine;

  /// «Palabras correspondientes ▸ Mismo texto superficial» (sin datasets de
  /// morfología todavía: la opción se muestra deshabilitada).
  final bool sameSurfaceText;

  /// Marcadores (M6.2): filtro visual de las anotaciones por cuaderno y
  /// etiqueta. Con `markers` apagado o sin filtros se muestran todas.
  final bool markers;
  final List<String> markerNotebooks;
  final List<String> markerTags;

  /// Vista paginada (Ctrl+Shift+P) con 1/2/3 columnas (`auto` según el ancho).
  final bool paged;
  final String columns;
  final bool footnotesOnPage;

  /// Zoom del panel en porcentaje (100 = tamaño normal).
  final int zoom;

  /// Barra de ubicación visible (View → Locator bar).
  final bool locationBar;

  /// Barra de herramientas secundaria visible (círculo «^» de la fila A).
  final bool secondaryToolbar;

  /// Números de capítulo/versículo efectivos.
  bool get showNumbers => !reformat || numbers;

  /// Indicadores de notas al pie efectivos.
  bool get showFootnoteIndicators => !reformat || footnoteIndicators;

  /// Un versículo por línea efectivo.
  bool get oneVersePerLineEffective => reformat && oneVersePerLine;

  /// Formato del texto bíblico (poesía, sangrías, párrafos) efectivo.
  bool get formattedBibleText => !reformat || bibleTextFormatting;

  /// ¿Se pinta la anotación (nota o resaltado) con los filtros actuales?
  ///
  /// Con `markers` apagado, o sin ningún cuaderno/etiqueta marcado, se pintan
  /// todas. Un cuaderno y una etiqueta marcados a la vez exigen ambos.
  bool markerFilterMatches(List<String> notebooks, List<String> tags) {
    if (!markers) return true;
    if (markerNotebooks.isEmpty && markerTags.isEmpty) return true;
    final notebookOk =
        markerNotebooks.isEmpty || notebooks.any(markerNotebooks.contains);
    final tagOk = markerTags.isEmpty || tags.any(markerTags.contains);
    return notebookOk && tagOk;
  }

  TabDisplay copyWith({
    bool? reformat,
    bool? bibleTextFormatting,
    bool? numbers,
    bool? footnoteIndicators,
    bool? nonBibleText,
    bool? oneVersePerLine,
    bool? sameSurfaceText,
    bool? markers,
    List<String>? markerNotebooks,
    List<String>? markerTags,
    bool? paged,
    String? columns,
    bool? footnotesOnPage,
    int? zoom,
    bool? locationBar,
    bool? secondaryToolbar,
  }) => TabDisplay(
    reformat: reformat ?? this.reformat,
    bibleTextFormatting: bibleTextFormatting ?? this.bibleTextFormatting,
    numbers: numbers ?? this.numbers,
    footnoteIndicators: footnoteIndicators ?? this.footnoteIndicators,
    nonBibleText: nonBibleText ?? this.nonBibleText,
    oneVersePerLine: oneVersePerLine ?? this.oneVersePerLine,
    sameSurfaceText: sameSurfaceText ?? this.sameSurfaceText,
    markers: markers ?? this.markers,
    markerNotebooks: markerNotebooks ?? this.markerNotebooks,
    markerTags: markerTags ?? this.markerTags,
    paged: paged ?? this.paged,
    columns: columns ?? this.columns,
    footnotesOnPage: footnotesOnPage ?? this.footnotesOnPage,
    zoom: zoom ?? this.zoom,
    locationBar: locationBar ?? this.locationBar,
    secondaryToolbar: secondaryToolbar ?? this.secondaryToolbar,
  );

  Map<String, dynamic> toJson() => {
    'reformat': reformat,
    'bibleTextFormatting': bibleTextFormatting,
    'numbers': numbers,
    'footnoteIndicators': footnoteIndicators,
    'nonBibleText': nonBibleText,
    'oneVersePerLine': oneVersePerLine,
    if (sameSurfaceText) 'sameSurfaceText': true,
    if (markers) 'markers': true,
    if (markerNotebooks.isNotEmpty) 'markerNotebooks': markerNotebooks,
    if (markerTags.isNotEmpty) 'markerTags': markerTags,
    if (paged) 'paged': true,
    if (columns != 'auto') 'columns': columns,
    if (footnotesOnPage) 'footnotesOnPage': true,
    if (zoom != 100) 'zoom': zoom,
    if (!locationBar) 'locationBar': false,
    if (!secondaryToolbar) 'secondaryToolbar': false,
  };

  static TabDisplay fromJson(Map<String, dynamic> json) => TabDisplay(
    reformat: json['reformat'] as bool? ?? false,
    bibleTextFormatting: json['bibleTextFormatting'] as bool? ?? true,
    numbers: json['numbers'] as bool? ?? true,
    footnoteIndicators: json['footnoteIndicators'] as bool? ?? true,
    nonBibleText: json['nonBibleText'] as bool? ?? true,
    oneVersePerLine: json['oneVersePerLine'] as bool? ?? false,
    sameSurfaceText: json['sameSurfaceText'] as bool? ?? false,
    markers: json['markers'] as bool? ?? false,
    markerNotebooks: ((json['markerNotebooks'] as List?) ?? const [])
        .whereType<String>()
        .toList(),
    markerTags: ((json['markerTags'] as List?) ?? const [])
        .whereType<String>()
        .toList(),
    paged: json['paged'] as bool? ?? false,
    columns: json['columns'] as String? ?? 'auto',
    footnotesOnPage: json['footnotesOnPage'] as bool? ?? false,
    zoom: json['zoom'] as int? ?? 100,
    locationBar: json['locationBar'] as bool? ?? true,
    secondaryToolbar: json['secondaryToolbar'] as bool? ?? true,
  );
}

/// Especificación para abrir una pestaña.
class TabSpec {
  const TabSpec({
    required this.kind,
    this.title,
    this.reference,
    this.query,
    this.resourceType,
    this.resourceId,
  });

  final PanelKind kind;
  final String? title;
  final String? reference;
  final String? query;
  final String? resourceType;

  /// Recurso del catálogo que muestra la pestaña (p. ej. `bible.kjv`).
  final String? resourceId;
}

/// Pestaña abierta dentro de un tile.
class WorkspaceTab {
  const WorkspaceTab({
    required this.id,
    required this.kind,
    required this.title,
    this.reference,
    this.query,
    this.resourceType,
    this.resourceId,
    this.linkSet,
    this.history = const [],
    this.historyIndex = -1,
    this.display = TabDisplay.defaults,
  });

  final String id;
  final PanelKind kind;
  final String title;
  final String? reference;
  final String? query;
  final String? resourceType;
  final String? resourceId;

  /// Conjunto de vínculos (`A`–`F`) para sincronizar la navegación entre
  /// paneles bíblicos; `null` = sin enlace.
  final String? linkSet;

  /// Referencias canónicas visitadas en el panel (lector).
  final List<String> history;

  /// Posición actual dentro de [history] (-1 si vacío).
  final int historyIndex;

  /// Presentación del panel (M3): reformato, vista paginada, zoom, barra de
  /// ubicación.
  final TabDisplay display;

  WorkspaceTab copyWith({
    String? title,
    String? reference,
    String? query,
    String? resourceType,
    String? resourceId,
    String? linkSet,
    bool clearLinkSet = false,
    List<String>? history,
    int? historyIndex,
    TabDisplay? display,
  }) => WorkspaceTab(
    id: id,
    kind: kind,
    title: title ?? this.title,
    reference: reference ?? this.reference,
    query: query ?? this.query,
    resourceType: resourceType ?? this.resourceType,
    resourceId: resourceId ?? this.resourceId,
    linkSet: clearLinkSet ? null : (linkSet ?? this.linkSet),
    history: history ?? this.history,
    historyIndex: historyIndex ?? this.historyIndex,
    display: display ?? this.display,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'title': title,
    if (reference != null) 'reference': reference,
    if (query != null) 'query': query,
    if (resourceType != null) 'resourceType': resourceType,
    if (resourceId != null) 'resourceId': resourceId,
    if (linkSet != null) 'linkSet': linkSet,
    if (history.isNotEmpty) 'history': history,
    if (historyIndex >= 0) 'historyIndex': historyIndex,
    if (display != TabDisplay.defaults) 'display': display.toJson(),
  };

  static WorkspaceTab fromJson(Map<String, dynamic> json) => WorkspaceTab(
    id: json['id'] as String,
    kind: PanelKind.values.firstWhere(
      (k) => k.name == json['kind'],
      orElse: () => PanelKind.dashboard,
    ),
    title: json['title'] as String? ?? '',
    reference: json['reference'] as String?,
    query: json['query'] as String?,
    resourceType: json['resourceType'] as String?,
    resourceId: json['resourceId'] as String?,
    linkSet: json['linkSet'] as String?,
    history: ((json['history'] as List?) ?? const []).cast<String>(),
    historyIndex: json['historyIndex'] as int? ?? -1,
    display: json['display'] is Map
        ? TabDisplay.fromJson((json['display'] as Map).cast<String, dynamic>())
        : TabDisplay.defaults,
  );
}

class WorkspaceTile {
  WorkspaceTile({
    required this.id,
    List<WorkspaceTab>? tabs,
    this.activeIndex = 0,
  }) : tabs = tabs ?? [];

  final String id;
  final List<WorkspaceTab> tabs;
  final int activeIndex;

  WorkspaceTab? get activeTab => (activeIndex >= 0 && activeIndex < tabs.length)
      ? tabs[activeIndex]
      : null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'activeIndex': activeIndex,
    'tabs': tabs.map((t) => t.toJson()).toList(),
  };

  static WorkspaceTile fromJson(Map<String, dynamic> json) => WorkspaceTile(
    id: json['id'] as String,
    activeIndex: json['activeIndex'] as int? ?? 0,
    tabs: ((json['tabs'] as List?) ?? const [])
        .map((e) => WorkspaceTab.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// Diseño guardado por el usuario (M5): preset + disposición de paneles.
///
/// Es local (SQLite); el original los asocia a la cuenta. Guarda una copia
/// profunda de los tiles para que editar el workspace actual no lo modifique.
class SavedLayout {
  const SavedLayout({
    required this.id,
    required this.name,
    required this.layoutId,
    required this.tiles,
  });

  final String id;
  final String name;
  final String layoutId;
  final List<WorkspaceTile> tiles;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'layoutId': layoutId,
    'tiles': tiles.map((tile) => tile.toJson()).toList(),
  };

  static SavedLayout fromJson(Map<String, dynamic> json) => SavedLayout(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    layoutId: json['layoutId'] as String? ?? 'two',
    tiles: ((json['tiles'] as List?) ?? const [])
        .map((e) => WorkspaceTile.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// Presets de layout (equivalen a `?layout=` del original).
///
/// Cada valor es la lista de filas; cada fila indica su cantidad de columnas.
/// P. ej. `[2]` = una fila de dos columnas; `[2, 2]` = cuadrícula 2×2.
const Map<String, List<int>> kLayoutPatterns = {
  'one': [1],
  'two': [2],
  'twoRows': [1, 1],
  'three': [3],
  'four': [2, 2],
};

class WorkspaceState {
  const WorkspaceState({
    required this.layoutId,
    required this.tiles,
    this.quickActionsVisible = true,
    this.bannerVisible = true,
    this.layoutBannersVisible = true,
    this.toolbarLocation = 'left',
    // El idioma de diseño del clon es el español: «Sistema» se elige en
    // Ajustes ▸ Idioma de la interfaz (M3).
    this.locale = 'es',
    this.themeMode = 'system',
    this.citationStyle = 'turabian',
    this.copyCitations = true,
    this.hyperlinkCitations = false,
    this.limitedView = false,
    this.catalogUrl = kDefaultCatalogUrl,
    this.catalogMode = 'auto',
    this.savedLayouts = const [],
  });

  factory WorkspaceState.fresh({String layoutId = 'two'}) {
    final pattern = kLayoutPatterns[layoutId] ?? kLayoutPatterns['two']!;
    final count = pattern.fold<int>(0, (a, columns) => a + columns);
    return WorkspaceState(
      layoutId: layoutId,
      tiles: List.generate(count, (i) => WorkspaceTile(id: 'tile_$i')),
    );
  }

  final String layoutId;
  final List<WorkspaceTile> tiles;
  final bool quickActionsVisible;
  final bool bannerVisible;

  /// Banners en los diseños (Ajustes 8.3, segunda fila del original).
  final bool layoutBannersVisible;

  /// `left` | `top` (Ajustes 8.1).
  final String toolbarLocation;

  /// `system` | `es` | `en` (Ajustes 8.5).
  final String locale;

  /// `system` | `light` | `dark` (Ajustes 8.7).
  final String themeMode;

  /// `turabian` | `sbl` | `chicago` | `plain` (Ajustes 8.6).
  final String citationStyle;
  final bool copyCitations;
  final bool hyperlinkCitations;

  /// Modo de vista limitada (Ajustes 8.4): vista accesible.
  final bool limitedView;

  /// Dirección del servicio de catálogo (M2).
  final String catalogUrl;

  /// `auto` | `local` | `remote` (M2).
  final String catalogMode;

  /// Diseños guardados por el usuario (M5, locales).
  final List<SavedLayout> savedLayouts;

  List<int> get pattern => kLayoutPatterns[layoutId] ?? kLayoutPatterns['two']!;

  /// Idioma fijado por el usuario (`null` = seguir al sistema).
  Locale? get fixedLocale => switch (locale) {
    'es' => const Locale('es'),
    'en' => const Locale('en'),
    _ => null,
  };

  Map<String, dynamic> toJson() => {
    'layoutId': layoutId,
    'quickActionsVisible': quickActionsVisible,
    'bannerVisible': bannerVisible,
    'layoutBannersVisible': layoutBannersVisible,
    'toolbarLocation': toolbarLocation,
    'locale': locale,
    'themeMode': themeMode,
    'citationStyle': citationStyle,
    'copyCitations': copyCitations,
    'hyperlinkCitations': hyperlinkCitations,
    'limitedView': limitedView,
    'catalogUrl': catalogUrl,
    'catalogMode': catalogMode,
    if (savedLayouts.isNotEmpty)
      'savedLayouts': savedLayouts.map((count) => count.toJson()).toList(),
    'tiles': tiles.map((t) => t.toJson()).toList(),
  };

  static WorkspaceState fromJson(Map<String, dynamic> json) => WorkspaceState(
    layoutId: json['layoutId'] as String? ?? 'two',
    quickActionsVisible: json['quickActionsVisible'] as bool? ?? true,
    bannerVisible: json['bannerVisible'] as bool? ?? true,
    layoutBannersVisible: json['layoutBannersVisible'] as bool? ?? true,
    toolbarLocation: json['toolbarLocation'] as String? ?? 'left',
    locale: json['locale'] as String? ?? 'es',
    themeMode: json['themeMode'] as String? ?? 'system',
    citationStyle: json['citationStyle'] as String? ?? 'turabian',
    copyCitations: json['copyCitations'] as bool? ?? true,
    hyperlinkCitations: json['hyperlinkCitations'] as bool? ?? false,
    limitedView: json['limitedView'] as bool? ?? false,
    catalogUrl: json['catalogUrl'] as String? ?? kDefaultCatalogUrl,
    catalogMode: json['catalogMode'] as String? ?? 'auto',
    savedLayouts: ((json['savedLayouts'] as List?) ?? const [])
        .map((e) => SavedLayout.fromJson(e as Map<String, dynamic>))
        .toList(),
    tiles: ((json['tiles'] as List?) ?? const [])
        .map((e) => WorkspaceTile.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
