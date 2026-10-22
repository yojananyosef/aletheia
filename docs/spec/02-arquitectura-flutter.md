# Arquitectura — Aletheia en Flutter

Objetivo: paridad funcional/UX con la web app original, en Flutter desktop, con **catálogo desacoplado** y contenido de dominio público/propio.

## 1. Stack y decisiones base

| Área | Elección | Motivo |
|---|---|---|
| UI | Flutter (Linux/Windows/macOS) | Un solo código para desktop |
| Estado | Riverpod (providers por panel/módulo) | Granularidad fina, testeable |
| Local DB | **SQLite** (`aletheia.db`, paquete `sqlite3`) | Offline-first, un archivo, migraciones versionadas; ver §11 |
| HTTP | `dio` + cliente generado | API del catálogo |
| Modelos | `freezed` + `json_serializable` | DTOs inmutables compartibles |
| i18n | `flutter_localizations` + ARB (plantilla `es`, traducción `en`) | UI en español por defecto, con inglés e «idioma del sistema»; el contenido va aparte |
| Ventana | `window_manager` (+ `hotkey_manager`) | Atajos (`Ctrl+Shift+P`, etc.) |
| Router | mínimo propio (la app es un workspace con estado, no rutas) | Fiel al original (`?layout`, `activeMenu` como estado) |

Monorepo:

```
app/                        # Flutter desktop
catalog/                    # servicio de catálogo (Python stdlib + sqlite3/FTS5) + ingesta
packages/
  document_model/           # modelo de documento/recursos (Dart puro, compartido)
  catalog_client/           # cliente REST tipado del catálogo
  references/               # parser/formateador de referencias bíblicas
```

## 2. Módulos de la app

```
lib/
  shell/         # sidebar, topbar (omnibox, banner), menú de cuenta
  workspace/     # motor de tiles/pestañas + persistencia + menús de pestaña
  reader/        # panel de recurso: modos, toolbar 2, drawers (Contents,
                 # Ideas, Información), formatting/view, contenido relacionado
  library/       # overlay de biblioteca + detalle
  search/        # panel de búsqueda, scopes, resultados, historial
  notes/         # panel, editor, notebooks, trash
  panels/        # paneles de herramientas (M5): host + Factbook, comparación,
                 # devocional, render de secciones y diff de palabras
  guides/        # estudio guiado: plantillas propias (guías y flujos)
  reading_plans/ # planes de lectura locales (plantillas + SQLite)
  dashboard/     # panel de inicio (tarjetas locales)
  courses/       # Cursos propios (catálogo, panel y progreso)
  documents/     # Documentos propios (guías, línea de tiempo, glosario)
  favorites/     # Favoritos de pasajes y mapas (modelo, controlador, SQLite)
  maps/          # Atlas/Medios, manifiesto map_sections y BibleMap
  psalms/        # Explorador de Salmos (clasificación propia + RV1909)
  assistant/     # Study Assistant (plugin IA)
  settings/      # /settings
  core/          # catálogo (catalog_client), db local, i18n, tema, refs, analytics-off
```

**i18n (M3).** Fuente única en ARB: `lib/l10n/app_es.arb` es la **plantilla** y `app_en.arb` la traducción; `flutter gen-l10n` (sin `synthetic-package`) genera `lib/l10n/app_localizations*.dart`, que sí se versionan. `context.l10n` (en `core/localization.dart`) resuelve los textos y **cae al español** cuando el widget está fuera del alcance de los delegados (capturas y pruebas). El idioma se elige en Ajustes ▸ Idioma de la interfaz (`system | es | en`, por defecto `es`: el idioma de diseño del clon), y el `MaterialApp` lo aplica con `fixedLocale`. Los datos de catálogo también se localizan (`languageLabel`, `resourceTypeLabel`, `SearchScope.labelIn(lang)`) sin tocar el contenido. Los **títulos de pestaña genéricos no se persisten**: se resuelven con `tabTitle(context, tab)` / `panelKindTitle` para que sobrevivan a un cambio de idioma.

## 3. Modelo del workspace

```dart
WorkspaceState {
  String layoutId;            // one | two | threeColumns | ... (presets) o custom
  List<TileState> tiles;      // 1..4
  List<SavedLayout> saved;    // layouts guardados por usuario
}

TileState { String id; List<TabState> tabs; int activeIndex; }

TabState {                    // WorkspaceTab en el código
  String id;
  PanelKind kind;             // reader | search | library | notes | factbook | comparison | ...
  PanelArgs args;             // resourceId, reference, query, …
  String title;               // p.ej. "RVR60", "Jesus Christ" (vacío = título traducido por tipo)
  TabDisplay display;         // presentación propia de la pestaña (M3)
  PanelHistory history;       // back/forward
  LinkSet linkSet;            // None | A..F
}

TabDisplay {                  // una por pestaña, persistida con el workspace
  bool reformat;              // interruptor maestro de Formato ▸ Reformato
  bool bibleTextFormatting, numbers, footnoteIndicators, nonBibleText;
  bool oneVersePerLine;       // + sameSurfaceText (deshabilitado sin datasets)
  bool markers;               // reservado a M6
  bool paged; String columns; // paged: 1 | 2 | 3 | auto
  bool footnotesOnPage; int zoom; bool locationBar;
}
```

Además del `display` por pestaña, `WorkspaceState` guarda los **ajustes globales** de M3: `toolbarLocation` (`left | top`), `locale`, `citationStyle` (`turabian | sbl | chicago | plain`), `copyCitations`, `hyperlinkCitations`, `limitedView` y los dos banners (`bannerVisible` del panel Inicio y `layoutBannersVisible` del chrome). `Restablecer valores` devuelve el estado por defecto sin tocar tiles ni pestañas.

- **Presets** replican `?layout=` del original; "Close all tabs" vacía tiles sin diálogo.
- **Adaptativo (área de trabajo):** los tiles van **siempre lado a lado** (el original nunca apila; ver la evidencia de reconocimiento §1). Si el área no da para todos con `kMinTileWidth = 320` px por panel, se muestran sólo los que caben —en orden y salteando tiles vacíos, para no gastar ancho en paneles sin pestañas— y el resto reaparece al ensanchar. El original encoge los paneles hasta ~120 px antes de plegar a un solo panel: aquí se usa un mínimo legible por decisión del usuario («adáptalo a lo recomendado»). `kSidebarAutoCollapseWidth = 880` es sólo el valor por defecto de la barra lateral (la flecha del pie fija la preferencia explícita del usuario y manda sobre el automatismo); el original no auto-pliega la barra, es una mejora adaptativa deliberada del clon.
- Menú de pestaña: Duplicate / Close this / Close to the right / Close others / Close all.
- **Destino y arrastre de pestañas:** abrir desde el chrome (sidebar, acciones rápidas) usa el primer panel vacío y, si no hay, el primero; abrir desde dentro de un panel (enlaces, resultados, herramientas) usa otro panel libre o el otro para no tapar el origen. El panel activo es transitorio (`WorkspaceController.focusTile`/`clearActiveTile`, se limpia al tocar el chrome) y decide ese destino. Las chips de pestaña se arrastran entre paneles (`Draggable`/`DragTarget`) y el panel destino queda activo.
- **Persistencia:** cada cambio (debounced ~500 ms) → SQLite (`aletheia.db` en el directorio de datos de la app; tablas `tiles`/`tabs` + ajustes en `settings`, ver §11). Sincronización opcional al catálogo (server-side `layouts` endpoint) pendiente.
- **Link sets**: mapa `LinkSet → referencia actual`; los paneles con el mismo set se siguen entre sí (equivalente funcional de `zzls`).

## 4. Lector (corazón del clon)

Motor propio de documento estructurado (el original usa canvas; el clon usará widgets, accesible por defecto):

```dart
Resource { id, type, title, authors, language, license, divisions: [Division] }
Division { id, title, kind: book|chapter|article|day, children|sectionRef }
Section { id, title, blocks: [Block] }
Block = Heading | Paragraph | VerseGroup | Poetry | ListBlock | Table | Figure | Rule
Inline = Text | VerseNumber(n) | FootnoteMarker(id) | CrossRefMarker(ref,target)
```

- **Render**: virtualizado por secciones (ListView + slivers) con **estados de presentación que reformatean de verdad** (M3, `TabDisplay`): Formato ▸ Reformato con `Bible text` (formato del texto bíblico, `one verse per line`), `Chapter/Verse numbers`, `Footnote indicators`, `Text not Bible`, `Markers` (activo desde M6.2) y «Mismo texto superficial» deshabilitado hasta que existan datasets. Con el maestro apagado se usa el párrafo del recurso.
- **Paged view (M3)**: `reader_body.dart` trocea el capítulo en *chunks* medidos con `TextPainter` (por versículo, con la sangría de la poesía), los reparte en columnas/páginas 1–3/`auto` (auto: 3 con ≥1000 px, 2 con ≥640) y los muestra en un `PageView` con footer «Página x de y» ◀▶ y notas al pie por página. Nunca parte un bloque; al llegar a la última página se añade el capítulo siguiente (mismo «cargar más» que el flujo continuo). `Ctrl+Shift+P` alterna.
- **View (M3)**: `Barra de ubicación` descartable (✕ → `TabDisplay.locationBar`), `Zoom` 50–300 % con `Ctrl+±` y `Ctrl+0` (restablecer al 100 %), y `Pantalla completa` (`window_manager`, `core/window.dart`).
- **Vista limitada (Ajustes 8.4)**: con `limitedView` el lector fuerza el modo continuo, desactiva la paginación y muestra las notas al pie como lista (`Notas al pie`) al final de cada capítulo, con los indicadores como texto llano.
- **Copiar cita (M3)**: Formato ▸ Más ▸ Copiar cita / Copiar pasaje y cita usan `references/citation.dart` con el estilo elegido (`turabian` = nota completa con título, `sbl`, `chicago` abreviatura, `plain` = `—`); `hyperlinkCitations` produce `[cita](ref:CANÓNICO)` (las Notas de M4 resolverán esos enlaces).
- **Modos del panel** (tabs que reconfiguran la toolbar 2):
  - Home → Contents · History · Article(◀▶) · Link set · Insights · Info
  - Search → búsqueda dentro del recurso del panel (`/v1/search?resource=`, M2): consulta, resultados con cita y fragmento, clic → navega y vuelve a Home (el texto del lector se conserva con `IndexedStack`).
  - Formatting → Markers · Reformato (flyout con interruptor maestro, casillas y nota al pie; réplica de `ux2/reformat.png`)
  - View → flyout con Vista paginada · Barra de ubicación · Zoom · Pantalla completa (réplica de `ux2/paged.png`)
  - Notes → panel propio (M4): «Inicio» (notas del recurso agrupadas por referencia), «Buscar» (búsqueda en el recurso), «Notas» (lista + editor, M4) y More ▾ → {Tools, Share, Copiar …}
- **Navegación**: Reference box (parser `references`), Change book (selector con Find + portadas), tap en cross-ref → misma pestaña o tile según modificador; History back/forward.
- **Location bar** descartable con la división actual.
- **Selection toolbar (M4)**: menú contextual propio sobre `SelectableRegion` con `Copiar · [Consultar] · Buscar · Más opciones` y `Agregar nota · colores · Subrayado rojo`; «Resaltar» abre la paleta y pinta el rango, «Nota» crea la nota anclada a versículo+rango y abre su editor, «Buscar» lanza la consulta del panel. Si la selección solapa resaltados del recurso, el swatch marca el color activo y elegir otro actualiza esos resaltados in situ; `Quitar resaltado` purga todos los solapados y el texto deja de estar pintado. La selección se resuelve a `(libro, capítulo, versículo, rango)` con `selection_resolver.dart` (coincidencia exacta → fragmentos decrecientes → primera palabra). Diseño propio: el menú del original no se pudo capturar (ver `01` §12).
- **Drawers derechos (M6.1)**: `💡 Ideas` y `ⓘ Información` son exclusivos y reacomodan el cuerpo (`Row` con anchura `(maxWidth*0.46).clamp(230,380)`), implementados en `reader/insights_drawer.dart`. Ideas: pestañas `Información del libro` y `<referencia actual>`; `Libros relacionados` (secciones propias del Factbook/devocional/comentario que citan la referencia, con `Más »` que abre el panel) y `Pasajes relacionados` (referencias cruzadas del TSK combinadas con las citadas por el contenido propio) desde `reader/related_content.dart` (`relatedContentProvider`, `referencesOverlap`); la ficha usa `catalog/resource_metadata.dart` (`resourceSummaryProvider` sobre `listResources`) con caída al manifiesto. `Artículo ▾`: menú con anterior/siguiente artículo; los pasos salen de `HeadingBlock` y, sin encabezados (RV1909), caen a capítulo. `Comenzar plan de lectura` abre el panel de planes (M6.3) y cambia a `Ver plan de lectura` con un plan activo.

- **Herramientas, estudio guiado, planes e inicio (M6.3)**: el menú `Herramientas` de la barra lateral y superior (`shell/tools_menu.dart`) replica las filas del original — Atlas, Cursos, Documentos, Temas, Información, Medios, Comparación y Planes — y las seis que antes dependían de datos ausentes están implementadas desde M6.5 (`courses/`, `documents/`, `favorites/`, `maps/`, `psalms/`). El panel `Estudio guiado` (`guides/guided_study_panel.dart`) es un hub con filtro y cuatro guías más tres flujos propios (`guides/guides_data.dart`); la guía en ejecución guarda su id en `tab.reference` y su parámetro en `tab.query` (así sobrevive al cambio de pestaña) y cada paso abre una herramienta real (lector, comparación, Temas, búsqueda o Notas). Los `Planes de lectura` (`reading_plans/`) son plantillas propias calculadas desde el manifiesto (Biblia en un año, Evangelios en 30 días, Salmos y Proverbios en 31, NT en 90): el plan activo sólo guarda plantilla, inicio y día (`reading_plans` en `aletheia.db`) y `PlanSchedule` reparte los capítulos del día. El `Inicio` (`dashboard/dashboard_panel.dart`) reúne tarjetas locales: continuar la lectura (historial de las pestañas), plan activo, Notas, devocional, accesos a las guías y a las herramientas.

## 5. Búsqueda

- Parser de sintaxis de estudio (palabras, frases, `AND/OR/NOT`, `NEAR`, `WITHIN n WORDS`, `BEFORE` local, campos `bible:`/`book:`/`type:`/`language:`/`resource:`).
- Backend: FTS5 en el servicio de catálogo **y en el índice local empaquetado**;
  respuesta con `resourceId, ref, citation, snippet` (los `offset/textRanges`
  del borrador se sustituyen por `ref` — ver `03` §7). La sintaxis se replica en
  `lib/catalog/local_search_query.dart`; el modo `auto` cae al índice local si
  el servicio no responde.
- UI: scopes (Todo/Biblia/Libros/Temas/Morfología/Multimedia/Mapas), filtros de tipo/idioma/libro con facetas, ayuda de sintaxis, historial y teclado griego/hebreo. Los resultados se agrupan por recurso; un hit bíblico abre el versículo, Factbook/devocional abre su sección, comentario/diccionario abre `CatalogResourcePanel` y morfología muestra el código y su descripción. Morfología y Mapas/Multimedia no abren el índice FTS: usan `morphology.json` y `map_sections.json`.
- **Búsqueda dentro del panel** (`resource=`): cada panel busca solo en su versión; reutiliza el mismo render de resultados (`SearchHitTile`/`SnippetText` en `lib/search/`) y el gateway con respaldo local.
- Placeholder para proveedores IA (Synopsis/Smart search) como plugins.

## 6. Notas y anotaciones (local-first) — M4

```dart
Note {
  String id; String kind;            // note | highlight
  String title; String body;         // body en markdown-lite propio
  List<NoteAnchor> anchors;          // hooks[{resourceId, reference?, bookCode?, chapter?, verse?, verseEnd?, startOffset?, endOffset?, quote?}]
  List<String> notebooks; List<String> tags;
  String color;                      // id de la paleta de resaltado
  DateTime createdAt, updatedAt; DateTime? deletedAt;   // deletedAt = papelera
}
Notebook { String id; String name; DateTime createdAt; }
NotesState { List<Note> notes; List<Notebook> notebooks; }   // tablas de aletheia.db
```

- **Persistencia**: `NotesStore` (`lib/notes/notes_persistence.dart`) delega en `AletheiaDatabase` (`lib/core/database.dart`): tablas `notes`, `note_anchors`, `note_notebooks`, `note_tags` y `notebooks` de `aletheia.db`, con carga *eager* en `main()` (igual que `WorkspaceStore`) y el estado inicial expuesto de forma síncrona por el provider. `NotesController` aplica los cambios en memoria (fuente de verdad para la UI) y guarda con 400 ms de retardo.
- **Editor**: markdown-lite propio (`markdown_lite.dart`: `**b**`, `*i*`/`_i_`, `<u>u</u>`, `==h==`, listas, `>`, `[texto](ref:JHN.1.1)`) con barra de formato que envuelve la selección y vista previa alternable; el editor debouncea 300 ms los campos de texto.
- **Panel** (`notes_browser.dart`, compartido por `NotesPanel` y el modo Notas del lector), alineado en M4.1 con el original (según la evidencia de reconocimiento §3):
  - Barra: `☰` (muestra/oculta la barra lateral interna) · buscador · Compartir · **Nueva nota con botón dividido** (la acción principal ancla a la referencia/selección del lector y la flecha permite crearla en blanco) · `⋮` (cuadernos y vaciar papelera).
  - Fila de ámbito con recuento: `Todos (N resultados)` / `Papelera (N)`; tocarla quita los filtros (conserva el texto buscado).
  - Fila de vista: densidad (`Predeterminado | Compacto`) y orden `por Fecha de creación | Fecha de modificación | Cuaderno`. El orden por cuaderno sólo se habilita cuando hay un cuaderno seleccionado, con la ayuda del original.
  - Barra lateral interna de 200 px con pestañas `Filtros | Cuadernos` (barrido por tipo/etiqueta/recurso y lista de cuadernos con creación y gestión) y `Papelera` al pie con su recuento.
  - Tarjetas con cita del anclaje y acciones por nota. La consulta se aplica con `applyNotesQuery` (función pura) y se mantiene en estado local del widget (no en el provider) para que cada panel tenga su vista.
  - Desviaciones pendientes: el `⋮` del original ofrece `Entrar en pantalla completa` / `Cerrar pestaña` (el clon aún no tiene pantalla completa por panel) y el icono de vista de lista no se replica.
- **Lector**: los anclajes con versículo/rango se pintan como indicador inline (icono tras el número de versículo) y resaltado por rango (los spans se parten por offsets en `_emitSpansWithHighlights`); sólo se tienen en cuenta las anotaciones cuyo `resourceId` coincide con la pestaña (`anchorMatchesResource`, con las anclas vacías como comodín), porque los offsets pertenecen al texto de esa versión. El modo «Notas» del panel lista y edita las notas del recurso. Crear nota/resaltado desde la selección resuelve el versículo y el rango con `selection_resolver.dart`; los resaltados solapados se actualizan y `Quitar` los purga.
- Sync opcional con el servicio (mismo contrato REST): pendiente (M6).

## 7. Catálogo e ingesta

- Servicio `catalog/`: recursos, contenido, referencias, búsqueda, insights, notas, layouts (implementado en Python 3 stdlib + sqlite3/FTS5 — desviación del Dart + shelf previsto; ver `catalog/README.md`).
- Almacenamiento: contenido en archivos (manifiesto + secciones), índice FTS5, metadatos en SQLite (dev) / Postgres (prod).
- Ingesta: USFM/OSIS/plain/JSON → `document_model` → manifiesto + secciones + índice de referencias + datasets (marcadores, cross-refs, devocionales con calendario `MM.DD`).
- Cliente en app: `lib/catalog/` — `CatalogClient` (dart:io) + `CatalogGateway` con modos `auto|local|remote`, respaldo de assets (`assets/catalog/index.json`) y caché en disco pendiente (M4).

## 8. Milestones

| M | Entregable | Cubre |
|---|---|---|
| M0 ✅ | Shell + workspace (tiles/tabs/persistencia) + sidebar + omnibox | 1.1–1.6, 2.1–2.4 |
| M1 ✅ | Lector: documento, Contents, History, Reference box, Change book, location bar | 3.1–3.8 |
| M2 ✅ | Catálogo v1 + Library + Search (All/Bible/Books) | 4.1–4.4, 5.1–5.4 |
| M3 ✅ | Formatting/View (Reformato, Paged view, Zoom, pantalla completa) + Ajustes + i18n | 3.9–3.11, 8.x |
| M4 ✅ | Notes (local-first) + anclas desde el lector | 6.x, 3.15–3.16 |
| M5 ✅ | Text Comparison + Factbook + Devocional + Layouts | 7.1, 7.2, 7.6, 2.5 |
| M6 ✅ | Insights, Markers/datasets, Guided study, Reading plans | 3.10, 3.12–3.14, 7.4–7.7 |
| M6.1 ✅ | Ideas/Información + Artículo ▾ | 3.12–3.14 |
| M6.2 ✅ | Markers/datasets (cuadernos y etiquetas de Notas) | 3.10 |
| M6.3 ✅ | Guided study + Tools hub + Reading plans + Dashboard | 7.4–7.7 |
| M6.4 ✅ | Study Assistant (motor de IA como plugin; sin proveedor muestra el estado «sin sesión» del original) | 7.3 |
| M6.5 ✅ | Herramientas de estudio: Atlas y Medios (23 mapas), Cursos, Documentos, Favoritos y Explorador de Salmos; esquema SQLite v5 | 7.5 |
| Plugin | Synopsis (proveedor IA intercambiable) | 5.5 |

## 9. Riesgos y preguntas abiertas

- **Textos PD suficientes**: catálogo semilla (apéndice en `03`); RVR60/ESV/NIV **no** son reutilizables.
- **Selección de texto y notas del original**: capturadas en la ronda de 2026-10-19 (ver la evidencia de reconocimiento §2–4): menú de selección en dos filas (Copiar · [Consultar] · Buscar · Más opciones + Agregar nota, cinco colores de resaltado y Subrayado rojo), menú contextual completo, panel de Notas con barra lateral `Filtros | Cuadernos`, orden por fecha/cuaderno y editor con formato. El clon omite lo que depende de IA (`Explicar`, `Preguntar`, `Estudio de palabra bíblica`) y el editor sigue siendo markdown-lite (no Quill) — desviaciones documentadas; el resto se alineó en M4.1.
- **Dark mode** y tipografías exactas: sin capturar; se definirán con tokens propios (no copiar activos originales).
- **Rendimiento** en paged view con textos largos: la paginación mide con `TextPainter` en cada build del capítulo; con capítulos muy largos tocará caché de layout por página (o isolates) — pendiente de medir con datos reales.
- **Atajos**: confirmados `Ctrl+Shift+P` (paged), `Ctrl+±` (zoom), `Ctrl+0` (zoom 100 %) y `Ctrl+Shift+F` (pantalla completa); el resto por definir (Fase 3.2).
- **Responsive del original**: medido y documentado (nunca apila; colapsa a un panel al bajar de ~248 px de área). El clon adopta la parte sensata (lado a lado siempre) con un mínimo legible de 320 px y prioridad a los paneles con pestañas (decisión del usuario).
- **Smoke manual de escritorio**: los builds y las 182 pruebas pasan en CI para Linux, Windows y macOS, pero no se abrió la ventana real en Windows/macOS en este entorno; falta comprobar allí el arranque, el diálogo de archivos, el service worker (solo web) y la integración con el escritorio.
- **Escritura por snapshot**: cada guardado borra y reinserta las filas en una transacción; con miles de notas convendrá pasar a escrituras incrementales y a consultas SQL/FTS5 (ver §11).

## 10. Pruebas

- Unit/widget (`flutter test`): parser de referencias, renderer del lector (versículos, notas, poesía), workspace (tiles/tabs), cliente del catálogo (contra un `HttpServer` real, sin binding para no bloquear HTTP), gateway local (`rootBundle`), widgets de Biblioteca/Búsqueda con servicios falsos y panel del lector (cambio de versión, modo Buscar, barra lateral y layout adaptativo). `test/catalog_content_test.dart` cubre el índice y el detalle del comentario y del diccionario, incluida la navegación atrás y la apertura del pasaje; `test/m6_insights_test.dart` añade el comentario y las referencias del TSK a «Ideas». Desde la autonomía local, `test/local_search_query_test.dart` (7) cubre el port de la sintaxis FTS5 (`NEAR`, campos y filtros) y `test/catalog_gateway_local_test.dart` (13) la extracción del índice comprimido, la búsqueda offline en las nueve Biblias y en Factbook/devocional/comentario/diccionario, las referencias del TSK, los filtros `type`/`language`/`book`, las facetas, la paginación, los errores y la caída de `auto` al índice local; `test/document_repository_test.dart` comprueba la KJV empaquetada, TAHOT/TAGNT y el léxico; `test/reader_study_test.dart` cubre el botón «Original», el popover de estudio y la apertura del léxico. `test/m3_display_test.dart` (M3) cubre con un repositorio sintético los estilos de cita y la copia con enlace, el reformato real, la vista limitada, el zoom y los ajustes. `test/notes_core_test.dart` (M4, 23) cubre el núcleo puro (modelo, consulta/orden, papelera, cuadernos/etiquetas, markdown-lite y `resolveSelection`, incluido el filtrado de anotaciones por recurso) y `test/m4_notes_panel_test.dart` (M4, 11) el panel (incluida la cabecera con recuento, la densidad y el orden por cuaderno), el editor, los filtros, la papelera, compartir y la integración con el lector (marcadores, resaltados, modo Notas, nota anclada a la referencia actual, creación de nota desde una selección por pulsación larga, menú de selección con colores y subrayado, actualización in situ de resaltados solapados, `Quitar` y aislamiento por recurso). `test/workspace_panels_test.dart` (6) cubre el destino de pestañas por origen, el panel activo transitorio, el chrome y el arrastre entre paneles. `test/sqlite_persistence_test.dart` (M4.3–M6.5, 5) cubre la ida y vuelta del workspace (incluidos los **diseños guardados**, M5), de las notas, de los **favoritos** y del **progreso de Cursos** en SQLite y la importación de los JSON antiguos. `test/m5_text_diff_test.dart` (M5, 6) cubre el diff por palabras (LCS, porcentajes, signos) `test/m5_tools_test.dart` (M5, 7) los paneles de devocional (navegación por días), Factbook (búsqueda, lentes, artículo y relacionados), comparación (porcentajes, cambio de referencia y quitar versión) y diseños guardados (guardar/aplicar/eliminar desde la barra superior y lateral); `test/m6_insights_test.dart` (M6.1, 5) los drawers Ideas/Información (pestañas, libros y pasajes relacionados, navegación, apertura del Factbook, ficha e información auxiliar, plan de lectura deshabilitado) y el menú Artículo, `test/m6_markers_test.dart` (M6.2, 3) el filtro de marcadores por cuaderno y etiqueta (puro, en el lector y estado vacío), `test/m6_guided_test.dart` (M6.3, 4) el hub del Estudio guiado (guía con parámetro, acciones que abren cada herramienta y un flujo con la referencia del lector), `test/m6_plans_test.dart` (M6.3, 5) el calendario de planes (reparto, etiquetas y filtros), el panel (comenzar, avanzar, abrir la lectura, detener y confirmación al reemplazar), el botón de la ficha y la ida y vuelta en SQLite, `test/m6_dashboard_test.dart` (M6.3, 1) las tarjetas del Inicio y sus accesos a las herramientas y `test/m6_assistant_test.dart` (M6.4, 3) el estado sin proveedor del Asistente (invitación con sugerencias deshabilitadas, aviso de IA y diálogo del plugin) y el chat con un motor falso (citas que abren el lector, `Recientes`, «Copiar todo», alcance y fallo del proveedor). Las pruebas que montan la app fijan el **locale de plataforma a `es`** para no depender del idioma del entorno. `test/m6_tools_test.dart` (M6.5, 15) cubre Atlas (lista, detalle y mapa), Medios (galería y detalle), Cursos (lección en el lector), Documentos, Favoritos (altas, tipos, estrella del lector y borrado) y Explorador de Salmos (filtro por género y apertura), más el plegado de la barra lateral al elegir una herramienta y la ausencia de overflow de las seis a 390×844; la suite completa queda en **182 pruebas**.
- Integración en Linux real (`flutter test integration_test/… -d linux`): `persistence_test` (el workspace **y las notas** sobreviven al relanzamiento; usa una base temporal propia y no toca la del usuario), `catalog_flow_test` (Biblioteca → lector con la KJV servida por HTTP real, búsqueda por frase, búsqueda dentro del panel y apertura de resultados; levanta el servicio si no está corriendo) más el tramo M5: devocional de hoy desde la acción rápida, búsqueda de `Jesucristo` en el Factbook y comparación RV1909 + KJV; `catalog_flow_test` comprueba además los 14 recursos y los títulos del comentario y del diccionario. `offline_catalog_test` recorre Biblioteca, lector, búsqueda global y de panel, salto a Factbook/devocional/comentario/diccionario, RV1909 e «Ideas» con TSK **sin servicio**. `panels_highlights_flow_test` (3) ejercita gestos reales de selección: crear, cambiar y quitar un resaltado; comprueba que un resaltado anclado a otra versión no se pinta, no ofrece «Quitar» y no se modifica al resaltar en el recurso actual; y abre/arrastra pestañas entre paneles.
- CI de escritorio: `.github/workflows/desktop.yml` ejecuta `flutter analyze` en Linux y las **182 pruebas** en Linux, Windows y macOS, y compila `flutter build linux/windows/macos --release` con Flutter 3.47.7. El build de macOS usa el sandbox con `com.apple.security.network.client`; el smoke manual con ventana real sigue pendiente en hardware Windows/macOS.
- Capturas: `test/reader_screens.dart` (M1), `test/m2_screens.dart` (Biblioteca/Búsqueda), `test/fix_screens.dart` (modo Buscar del panel y ventana estrecha con la barra expandida), `test/m3_screens.dart` (Formato, Vista paginada y Ajustes), `test/m4_screens.dart` (panel de Notas, filtros, editor, papelera, anotaciones del lector y modo Notas) `test/m5_screens.dart` (devocional, Factbook y comparación dentro de la app) y `test/m6_screens.dart` (Ideas en sus dos pestañas, Información, menú Artículo, Marcadores, menú Herramientas, Estudio guiado en hub y en ejecución, Planes de lectura, Inicio y Asistente sin proveedor y en chat) generan PNG en `/tmp/opencode` con datos reales incrustados; las de M5 van con prefijo `m5-app-` para no pisar las capturas del original y las de M6 con `m6-app-*`; las capturas del original se conservan fuera del repositorio.
- Autoprueba del servicio: `python3 catalog/server/selftest.py` (52 comprobaciones; incluye `resource=`, campos, filtros, facetas, `NEAR`, los recursos no bíblicos, el comentario/diccionario y las referencias cruzadas del TSK).

## 11. Persistencia local: SQLite (M4.3)

M0–M4 guardaban el estado en dos JSON (`workspace.json`, `notes.json`). Desde
M4.3 el estado del usuario vive en **un archivo SQLite**, `aletheia.db`, en
el directorio de datos de la app (`~/.local/share/dev.aletheia.aletheia/`
en Linux). Paquete: `sqlite3` 3.x (usa SQLite del sistema; sin `drift` ni
generación de código).

Desde la mejora de autonomía hay un **segundo archivo SQLite de solo lectura**,
`catalog.search.<hash>.sqlite`, con el índice FTS5 empaquetado de las cuatro
Biblias, el comentario, el diccionario, el Factbook, el devocional y la tabla
`cross_references` del TSK. No se indexa al arrancar: se extrae una vez de
`assets/catalog/search.sqlite.gz` (48,8 MB) y se verifica su
tamaño contra
`search.meta.json`. El hash forma parte del nombre, de modo que una actualización
del catálogo usa un archivo nuevo y no una copia vieja. `LocalCatalogIndex`
(`lib/catalog/local_catalog_index.dart`) lo abre con `OpenMode.readOnly` y
`PRAGMA query_only=ON`; el estado del usuario nunca se mezcla con el índice.

Esquema (versionado con `PRAGMA user_version`, migración en
`lib/core/database.dart`):

- `settings(key, value)`: ajustes del workspace en JSON por clave (layout,
  idioma, tema claro/oscuro/sistema, estilo de cita, banners, catálogo) —
  escalares sin consultas.
- `tiles(id, position, active_index)` y `tabs(id, tile_id, position, kind,
  title, reference, query, resource_type, resource_id, history_json,
  history_index, display_json)`: pestañas normalizadas; historial y
  presentación del panel quedan como JSON porque son listas/estructuras de UI.
- `notebooks(id, name, created_at)`.
- `notes(id, kind, title, body, color, style, created_at, updated_at,
  deleted_at)`: incluye el estilo de resaltado (fondo/subrayado).
- `note_anchors(note_id, position, resource_id, reference, book_code, chapter,
  verse, verse_end, start_offset, end_offset, quote)` con índices por nota y
  por referencia.
- `note_notebooks(note_id, notebook_id, position)` y `note_tags(note_id, tag,
  position)`.
- `reading_plans(id, template, resource_id, started_at, day_index,
  last_read_at)` (esquema v2): el plan de lectura activo, uno por instalación;
  los capítulos de cada día se calculan desde el manifiesto.
- `favorites(id, kind, title, subtitle, resource_id, reference, created_at)`
  (esquema v4): Favoritos de pasajes y mapas, con su tipo (`passage`/`map`) y
  la referencia, ordenados por fecha.
- `course_progress(course_id, lesson_id, completed_at)` (esquema v5, clave
  primaria compuesta): lecciones completadas de los Cursos.

El esquema actual es **v5** y `AletheiaDatabase.schemaVersion` es la única
fuente de verdad: cada versión añade su paso en `_migrate` (v2 planes, v3
`link_set`, v4 favoritos, v5 progreso de Cursos).

Escritura: transacción con *snapshot* (borra y reinserta el estado) porque el
volumen es pequeño y así no hay que sincronizar filas sueltas; `PRAGMA
foreign_keys=ON` y `journal_mode=WAL`. Los modelos (`WorkspaceState`,
`NotesState`, `Note`…) siguen siendo la capa de dominio y `WorkspaceStore` /
`NotesStore` sólo delegan en `AletheiaDatabase`.

**Importación M0→M4**: al arrancar, `AletheiaDatabase.importLegacyJson`
lee `workspace.json` / `notes.json` si la base está vacía, los escribe en
SQLite y los renombra a `.imported` (se conservan como respaldo). Es
idempotente y tolerante a JSON corrupto.

Pendiente: `note_tags`/`note_anchors` aún no alimentan consultas SQL desde el
panel (la búsqueda sigue aplicándose en memoria con `applyNotesQuery`); el
siguiente paso natural es un índice FTS5 cuando el volumen lo justifique.

