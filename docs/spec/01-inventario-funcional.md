# Inventario funcional priorizado — Aletheia

Derivado del reconocimiento de las fases 1–3. Las columnas:
**P** = prioridad (P0 = MVP, P1 = esencial, P2 = avanzado, P3 = posterior/opcional).
**Ev.** = fuente de evidencia (ledger / captura).

## 1. Shell y navegación

| # | Función | P | Ev. | Notas |
|---|---|---|---|---|
| 1.1 | Sidebar fijo: Dashboard, Library, Search, Bible, Study Assistant, Factbook, Guided study, Notes, Tools | P0 | L1/L2 | Íconos + labels; colapsable |
| 1.2 | Quick actions: Open a Commentary / Study Bible / Compare Bible Versions / Bible Dictionary / Today's Devotional | P1 | L1/L2 | Abren recursos por "tipo" desde el catálogo |
| 1.3 | Store, Layouts, Close all tabs (pie de sidebar) | P2 | L2/L3 | **Hecho (paridad 1)**: Tienda local con búsqueda, filtro por tipo, licencia y apertura de los 14 recursos incluidos; sin compras |
| 1.4 | Menú de cuenta (kebab): Profile, Help Center, Settings, Shop, Download | P1 | L2/L3 | Settings = `/settings` |
| 1.5 | Banner promocional descartable | P3 | L2 | No replicar up-sells de pago; opcional banner propio |
| 1.6 | Omnilox "Passage or topic": parser de referencias + lookup + búsqueda | P0 | L2/L3 | Opciones: "Look up …", "Search top Bible for …", "Search all resources for …", "Go to" |
| 1.7 | i18n UI (EN/ES) y contenido multi-idioma | P1 | L2/L3 | UI EN por defecto en el original; catálogo con idiomas |
| 1.8 | Modo de accesibilidad "limited view mode" | P2 | L3 | Settings → Enable limited view mode |

## 2. Workspace (tiles y pestañas)

| # | Función | P | Ev. | Notas |
|---|---|---|---|---|
| 2.1 | Sistema de **tiles** (1–4) con stack de pestañas por tile | P0 | L1/L2 | Presets `?layout=one|two|threeColumns|threeColumnsSplitRight|twoRows|three|twoColumnsSplitLeft|four` |
| 2.2 | Pestañas: título + ✕; selección; persistencia por cuenta | P0 | L2/L3 | Estado inicial vacío; se restaura el layout |
| 2.3 | Menú contextual de pestaña: Duplicate / Close this / Close to the right / Close others / Close all | P1 | L3 | "Panel commands"; además **Pantalla completa** por panel |
| 2.4 | "Close all tabs" global | P1 | L3 | Sin confirmación en el original |
| 2.5 | Layouts: presets + guardados por cuenta | P1 | L1/L3 | **Hecho (M5)**: presets + diseños guardados **en local** (SQLite); el original los asocia a la cuenta; ver §13 |
| 2.6 | Link sets (A–F / None) por panel: sincroniza posiciones entre recursos | P2 | L2/L3 | **Hecho (paridad 1)**: A–F, persistido por pestaña; sincroniza paneles bíblicos del mismo grupo (original: `zzls`/`linkSetId`) |
| 2.7 | Historial back/forward por panel + "List all history" | P1 | L2/L3 | |

## 3. Lector de recursos

| # | Función | P | Ev. | Notas |
|---|---|---|---|---|
| 3.1 | Render de documento estructurado (capítulos, versículos, párrafos, poesía, listas, tablas, figuras) | P0 | L1/L2 | Original: canvas propio (Sinai); el clon usará widgets/rich text |
| 3.2 | Numeración de versículos, notas al pie inline (ᵃ), cross-references | P0 | L2/L3 | Enlaces internos a referencias |
| 3.3 | Reference box editable + "Change book" (selector de traducción/recurso) | P0 | L2/L3 | Diálogo con Find + lista con portadas |
| 3.4 | Barra de ubicación descartable ("San Juan" / "OCTOBER › Morning, October 18") | P1 | L3 | Muestra la división actual; ✕ |
| 3.5 | Toolbar primaria (tabs de modo): Home · Search · Notes · Formatting · View · More | P0 | L3 | En libros: Home · Search · Notes · View · Tools · Share |
| 3.6 | Toolbar secundaria: Contents · History · Article (steppers ◀▶) · Link set · Insights · Info | P1 | L2/L3 | |
| 3.7 | **Contents**: drawer izquierdo con buscador + árbol libro→capítulos | P0 | L3 | |
| 3.8 | **History**: dropdown con entradas del panel | P1 | L3 | |
| 3.9 | **Formatting → Reformat**: switch + árbol de checkboxes (`Bible text` ▸ formatting/Chapter-Verse numbers/Footnote indicators; `Non-Bible text`; `One verse per line`; `Corresponding Words` ▸ `Same surface text`) | P1 | L3 | **Hecho (M3)**: el interruptor maestro y las casillas cambian el render de verdad; `Same surface text` deshabilitado (sin datasets); ver §11 |
| 3.10 | **Formatting → Markers**: filtros visuales por datasets (`Sermons`, `Bible Studies`) | P2 | L3 | **Hecho (M6.2)**: nuestros datasets son los cuadernos y las etiquetas de Notas; ver §15 |
| 3.11 | **View**: Paged view (`Ctrl+Shift+P`; Columns 1/2/3/Auto; Show footnotes on page), Locator bar, Zoom, Full screen | P1 | L3 | **Hecho (M3 + paridad 1)**: paginado, barra descartable y zoom; pantalla completa **del panel** (oculta sidebar/chrome, `Esc` sale); ver §11 |
| 3.12 | **Insights** (drawer derecho): tabs `Book info` + referencia actual; Related books, Related passages/Cross References, "Start reading plan" | P2 | L3 | **Hecho (M6.1)**: libros relacionados = secciones propias que citan la referencia; pasajes = co-referencias del catálogo; plan de lectura deshabilitado hasta M6.3; ver §14 |
| 3.13 | **Info** → mismo drawer en `Book info` | P2 | L3 | **Hecho (M6.1)**: drawer propio con ficha, `Información auxiliar` y `Copyright`; ver §14 |
| 3.14 | **Article ▾**: modo "Step to next/previous article" | P2 | L3 | **Hecho (M6.1)**: pasos por encabezados del documento (RV1909 sin encabezados → capítulos); ver §14 |
| 3.15 | Selección de texto + acciones (copiar, resaltar, nota, búsqueda) | P1 | — | **Hecho (M4)**: menú contextual propio (Copiar · Resaltar · Nota · Buscar · Copiar cita) sobre `SelectableRegion`; diseño propio — el original no se pudo capturar; ver §12 |
| 3.16 | Notas/annotations inline y paneles de notas del recurso | P1 | L2 | **Hecho (M4)**: indicadores de nota inline, resaltados por rango y modo «Notas» del panel; ver §12 |
| 3.17 | Temas claro/oscuro y tipografías por recurso | P1 | — | **Hecho (paridad 1)**: claro/oscuro/sistema persistido en SQLite; tipografías por recurso pendientes |

## 4. Library

| # | Función | P | Ev. | Notas |
|---|---|---|---|---|
| 4.1 | Overlay de biblioteca: Find + contador + lista de recursos (portada, título, tipo·autor) | P0 | L2 | |
| 4.2 | Panel de detalle: portada, título, autor, descripción, `More »`, `Start reading plan`, acordeones Copyright/Series | P1 | L2 | |
| 4.3 | Facetas: Subject, Type, Author, Series, Publisher, Language | P1 | L2 | |
| 4.4 | Orden (by Title…) y "Load more" | P1 | L2 | |
| 4.5 | Tabs Library / Store | P2 | L2 | **Hecho (paridad 1)**: la pestaña Store abre la Tienda local |
| 4.6 | Distinción licencia/poseído (candado en resultados) | P1 | L2 | En el clon: `public-domain` vs `locked` |

## 5. Búsqueda

| # | Función | P | Ev. | Notas |
|---|---|---|---|---|
| 5.1 | Caja de búsqueda con scopes: All · Bible · Books · Factbook · Morph · Media · Maps | P0 (All/Bible/Books) | L2 | **Hecho**: los siete ámbitos están habilitados; Morph/Media/Maps usan `morphology.json`/`map_sections.json` y no abren el índice FTS |
| 5.2 | Sintaxis v2 (OR/AND/NEAR/WITHIN n WORDS, frases, campos `bible:"Jn 3"`, `book:`, `type:`, `language:`, `resource:`) | P1 | L1/L2 | **Hecho**; `BEFORE` se evalúa en el índice local (el servicio remoto no lo implementa) |
| 5.3 | Resultados: título→`offset+textranges`, snippet con énfasis, fuente, cita (ref, vol/pág), candado | P0 | L2 | |
| 5.4 | Historial y back/forward | P1 | L2 | |
| 5.5 | Tarjeta **Synopsis** (IA) con citas numeradas y medición/upsell | P3 | L2 | Plugin IA opcional |
| 5.6 | Smart Search (preview) y "Books Search" restringida a biblioteca | P3/P1 | L2 | |
| 5.7 | Teclados bíblicos (griego/hebreo) para consultas morfológicas | P3 | L2 | **Hecho**: diálogo con pestañas Griego/Hebreo, inserción en la consulta, borrado y previsualización |

## 6. Notas

| # | Función | P | Ev. | Notas |
|---|---|---|---|---|
| 6.1 | Panel: Find, New note, Share, ajustes | P1 | L2 | **Hecho (M4)**: campo Find, Compartir (Markdown/texto) y menú ⋮ (cuaderno nuevo, orden, vaciar papelera); ver §12 |
| 6.2 | Filtros All/Filters/Notebooks; Trash; orden by Date Modified | P1 | L2 | **Hecho (M4)**: ámbitos Todas/Filtros/Cuadernos, filtros por tipo/etiqueta/recurso, papelera y orden por modificación/creación/título |
| 6.3 | Editor de nota (título, cuerpo, anclaje a referencia, notebooks, tags, compartir) | P1 | — | **Hecho (M4)** con diseño propio (flujo no capturado): formato markdown-lite, vista previa, anclaje, cuadernos, etiquetas y compartir; ver §12 |
| 6.4 | Anclas a recursos y creación desde el lector | P1 | — | **Hecho (M4)**: anclaje a la referencia/versículo actual o al rango seleccionado, con marcadores y resaltados en el lector |

## 7. Herramientas y contenido

| # | Función | P | Ev. | Notas |
|---|---|---|---|---|
| 7.1 | Text Comparison: referencia + set de versiones (botón "RVR60, ESV, NASB95, NIV, KJV 1900") + columnas por versión + links por versículo | P1 | L2 | **Hecho (M5)**: filas por versículo con «% de diferencia» y palabras divergentes resaltadas; ver §13 |
| 7.2 | Factbook: box "Topic or reference" + artículo con secciones, related topics | P2 | L1/L2 | **Hecho (M5)**: búsqueda, lentes, artículo, referencias y temas relacionados; ver §13 |
| 7.3 | Study Assistant (research mode): chat con toolbar (Recent/New/Copy link/Copy all/…), input, adjuntos, scope "All books", respuestas con citas | P2 | L2 | Plugin IA opcional |
| 7.4 | Guided study: Guides (Bible Word Study, Exegetical, Passage, Sermon Starter) + Workflows (Basic Bible Study, Devocional, Devotional, English Word Study, Estudio bíblico inductivo) | P2 | L3 | Sistema de plantillas guiadas |
| 7.5 | Tools hub: Atlas, Courses, Documents, Factbook, Favorites, Information, Media, Psalms Explorer, Reading Plan Manager, Text Comparison | P2 | L3 | **Hecho (M6.5)**: Atlas, Cursos, Documentos, Medios, Favoritos y Explorador de Salmos son paneles propios; Factbook, Información, Comparación y Planes ya existían. Ver §21 |
| 7.6 | Devocional del día (recurso fechado `dayofyear.MM.DD`) | P1 | L2 | **Hecho (M5)**: 366 secciones + 30 lecturas propias; ver §13 |
| 7.7 | Reading plans (manager + "Start reading plan") | P2 | L3 | |
| 7.8 | Dashboard | P1 | L1/L2 | En el original: vacío si no hay pestañas; banner configurable |

## 8. Settings (`/settings`)

| # | Función | P | Ev. |
|---|---|---|---|
| 8.1 | Application toolbar location: Left/Top | P2 | L3 | **Hecho (M3)** |
| 8.2 | Show quick actions: Yes/No | P2 | L3 | **Hecho (M3)** |
| 8.3 | Show banners (Dashboard / Layout): Yes/No | P3 | L3 | **Hecho (M3)**: dos filas con efecto real (panel Inicio y chrome) |
| 8.4 | Enable limited view mode (a11y) | P2 | L3 | **Hecho (M3)**: sin paginación + notas como lista al final del capítulo |
| 8.5 | Language | P1 | L3 | **Hecho (M3)**: `Sistema/Español/English`, por defecto español |
| 8.6 | Citation style (p. ej. Turabian 9th footnote) + Copy citations + Hyperlink copied citations | P2 | L3 | **Hecho (M3)**: 4 estilos con `?` de ayuda y copia desde el lector |

## 9. Fuera de alcance del clon

- Tienda/compras reales, licencias DRM, telemetría/upsells del original, contenido licenciado (ESV, NIV, RVR60, NASB95…), formatos propietarios, marcas y activos originales (logotipos, portadas, fuentes propietarias).
- Todo contenido debe ser de dominio público o propio (ver `03-contrato-catalogo.md`, apéndice de licencias).

## 10. Criterio de aceptación del MVP (P0)

1. Shell con sidebar, omnibox funcional (referencia → abre pasaje; término → búsqueda) y workspace de tiles/pestañas con persistencia.
2. Lector de Biblia y de libros con numeración de versículos, notas al pie y cross-refs navegables, Reference box y Change book.
3. Library con Find + lista + detalle desde el catálogo propio (≥ 2 Biblias PD + 1 comentario PD).
4. Búsqueda All/Bible/Books con resultados navegables a offset.
5. Contents drawer y History.
6. Settings mínimos (idioma, estilo de cita, copy citations) y i18n ES/EN.

## 11. M3 implementado — Formatting/View, Ajustes e i18n

Referencia visual: capturas del original para vista paginada, marcadores, localizador y ajustes. Capturas propias: `test/m3_screens.dart` → `/tmp/opencode/m3-*.png` (y las de la app real por bloques de Ajustes y lector paginado).

**Formato ▸ Reformato.** Flyout en tarjeta bajo la toolbar secundaria, igual al original: título + ✕, interruptor maestro `Reformato del texto` y árbol por tipo de recurso (`Texto bíblico` ▸ `Formato del texto bíblico`, `Números de capítulo y versículo`, `Indicadores de notas`; `Texto no bíblico`; `Un versículo por línea`; `Marcadores`; pie «Reformatea el cuerpo principal del libro.»). Todo se persiste por pestaña (`TabDisplay`) y cambia el render: los números/indicadores se calculan en el cuerpo del lector y `un versículo por línea` rompe el párrafo por versículo. Desviaciones: `Palabras correspondientes ▸ Mismo texto superficial` se muestra **deshabilitado** (necesita datasets de morfología, M6) y `Marcadores` filtra de verdad desde M6.2 (§15).

**Vista ▸ Vista paginada.** Flyout con `Vista paginada` (maestro), `Columnas` 1/2/3/`Auto` (auto: 3 con ≥1000 px de panel, 2 con ≥640), `Mostrar notas en la página`, `Barra de ubicación` y el bloque `Zoom`/`Pantalla completa`. El paginado trocea el capítulo en *chunks* medidos con `TextPainter` (un versículo por chunk, con sangría de poesía) y los reparte en columnas; nunca parte un bloque a mitad de versículo, y al llegar a la última página carga el capítulo siguiente (mismo botón `Cargar más capítulos` del flujo continuo). Footer `Página x de y` con ◀▶. Desviaciones: la paginación es por bloques de versículo (no hay corte a mitad de verso) y se recalcula al cambiar el ancho; con capítulos muy largos conviene añadir caché (ver §9 de `02`).

**Barra de ubicación, zoom y pantalla completa.** La barra (`San Juan`) se descarta con ✕ y se recupera desde Vista ▸ `Barra de ubicación`. El zoom (50–300 %) escala el texto del panel con `Ctrl+±`/`Ctrl+0` y el botón `%` restablece a 100. `Pantalla completa` es **por panel**: `panelFullscreenProvider` oculta sidebar y chrome del workspace y `PanelHost` ocupa la ventana; se sale con el botón, el mismo ítem de Vista o `Esc`. El menú de pestaña también ofrece `Pantalla completa` para cualquier panel.

**Vista limitada (8.4).** Con `limitedView` el panel fuerza el modo continuo (ignora el paginado y `un versículo por línea`), muestra las notas al pie como lista `Notas al pie` al final de cada capítulo y los indicadores de nota como texto llano (accesible).

**Citas (8.6).** `references/citation.dart` formatea cuatro estilos: `turabian` (`Juan 1:1 (Reina-Valera 1909).`, título completo), `sbl` (`Juan 1:1 (RV1909)`), `chicago` (`Juan 1:1 (RV1909).`) y `plain` (`Juan 1:1 — RV1909`, con raya). `Formato ▸ Más` ofrece `Copiar referencia`, `Copiar cita`, `Copiar pasaje y cita`. Con `Enlazar las citas copiadas` la cita copiada acaba en `[cita](ref:CANÓNICO)` (convención propia; los enlaces `ref:` los resolverán los paneles/notas de M4, no son un formato propietario).

**Ajustes.** El panel sigue el orden y los controles del original: `Ubicación de la barra de aplicaciones` (`Izquierda|Arriba`), `Mostrar acciones rápidas`, `Mostrar banners en el panel de inicio` (?), `Mostrar banners en los diseños` (?), `Activar el modo de vista limitada` (?), `Idioma de la interfaz` (desplegable `Sistema|Español|English`), `Tema de la interfaz` (desplegable `Sistema|Claro|Oscuro`), `Estilo de citas` (desplegable con `?`), `Copiar la cita con el texto` (?), `Enlazar las citas copiadas` (?) y `Restablecer valores` arriba a la izquierda, más el menú `⋮` de opciones. Debajo, la sección propia `Catálogo` (dirección del servicio, modo `Automático|Solo incluidos|Solo servicio` y estado con recursos/versículos indexados), que no existe en el original (nuestro catálogo es desacoplado). Los `?` son tooltips con texto de ayuda.

**i18n.** ARB con el español como plantilla y el inglés como traducción; `context.l10n` con respaldo en español; nombres de libros, tipos de recurso, idiomas y scopes localizados; los títulos de pestaña genéricos se traducen al vuelo en vez de persistirse; y las pruebas de widget fijan el locale de plataforma a `es`.

## 12. M4 implementado — Notas (local-first)

Referencia visual: estructura del panel de Notas con sesión iniciada en el original. Capturas propias: `test/m4_screens.dart` → `/tmp/opencode/m4-*.png` (lista, filtros, editor, papelera, anotaciones del lector y modo Notas).

**Panel de Notas (6.1–6.2).** Alineado con el original en M4.2. Toolbar con `☰` (muestra/oculta la barra lateral interna), campo de búsqueda, `Compartir` (exporta la nota abierta en Markdown o texto plano y la copia al portapapeles), **`Nueva nota` con botón dividido** (la acción principal ancla a la referencia/selección del lector y la flecha permite crearla en blanco) y menú `⋮` (cuaderno nuevo, cuadernos y vaciar la papelera). Debajo: fila de ámbito con recuento `Todos (N resultados)` / `Papelera (N)` —tocarla quita los filtros— y fila de vista con densidad `Predeterminado | Compacto` y orden `por Fecha de creación | Fecha de modificación | Cuaderno` (el orden por cuaderno sólo se habilita con un cuaderno seleccionado, con la ayuda del original). Barra lateral interna de 200 px con pestañas `Filtros | Cuadernos` y `Papelera` al pie con recuento. Los filtros (tipo nota/resaltado, etiquetas presentes, recurso) y el orden viven en el estado local del navegador, no en el provider. La lista muestra por nota: color (resaltados), título, vista previa, cita del anclaje, cuaderno(s), etiquetas, fecha y acciones `Editar · Compartir · Enviar a la papelera`; en la papelera, `Restaurar · Eliminar definitivamente`.

**Editor (6.3).** Tarjeta de anclaje (`Juan 1:1`, `Mostrar en el lector`), campos de título y cuerpo, barra de formato markdown-lite (`**negrita**`, `*cursiva*`, `__subrayado__`, `==resaltado==`, listas `- `/`1. `, `> `, `[texto](ref:JHN.1.1)`), paleta de resaltado para los resaltados, selector de cuadernos (con alta rápida), editor de etiquetas, pie `Guardado`/`Modificada el …` y acciones `Duplicar · Compartir · Enviar a la papelera`. El cuerpo se guarda en un subconjunto markdown propio; el botón de vista previa lo renderiza. Los campos de texto se guardan con 300 ms de retardo y el estado con 400 ms.

**Selección y anotaciones en el lector (3.15–3.16, 6.4).** Al seleccionar texto aparece el menú del original (medido el 2026-10-19; la evidencia de reconocimiento §2), en dos filas: `Copiar · [Consultar] · Buscar · Mostrar más opciones` y `Agregar nota · Resaltado amarillo/verde/azul/rojo/anaranjado · Subrayado rojo`. `Consultar` sólo aparece con una palabra seleccionada; «Mostrar más opciones» ofrece `Copia visual` y el subrayado. Los colores pintan el rango al instante (sin diálogo), el subrayado se dibuja con `TextDecoration.underline` y `Agregar nota` crea una nota anclada al versículo y rango seleccionados (y abre su editor); `Buscar` lanza la consulta. En el texto, cada versículo con notas muestra un icono inline y los resaltados se pintan partiendo los spans por offsets; el icono se omite en vista limitada. El modo `Notas` del panel lista las notas del recurso (agrupadas por referencia) o de todo el catálogo, con la misma lista y editor que el panel global.

**Persistencia.** `NotesStore` (como `WorkspaceStore`) guarda en **SQLite** (`aletheia.db` en el directorio de datos de la app; ver `02-arquitectura-flutter.md` §11): notas, anclajes, cuadernos, etiquetas, pestañas y ajustes, con carga *eager* antes de `runApp`. Los `workspace.json`/`notes.json` de M0–M4 se importan una sola vez al arrancar y se archivan como `.imported`.

**Desviaciones.** El menú de selección ya está alineado con el original; se omiten las acciones que dependen de IA (`Explicar`, `Preguntar`) y `Estudio de palabra bíblica`, y el menú completo no replica la columna de *sujetos del contexto* (entidades detectadas). El editor de notas del original es Quill con medios y formato enriquecido; el clon usa markdown-lite (desviación documentada). No hay `Palabras correspondientes`/marcadores por dataset (M6) ni sincronización de notas con el servicio (previsto, mismo contrato REST).

## 13. M5 implementado — Comparación de textos, Factbook, Devocional y diseños guardados

Recon del original (2026-10-19, navegador con CDP; scripts en `/tmp/opencode/pw/m5*.js`): las capturas propias quedaron en `/tmp/opencode/m5-compare.png`, `m5-factbook.png` y `m5-devotional.png`. Rutas observadas: `/tools/text-comparison?…&view=Verses`, `/tools/factbook?title=…&lens=all` y el devocional como recurso-libro abierto en `references/dayofyear.10.19`. El clon se capturó con `test/m5_screens.dart` en `/tmp/opencode/m5-app-*.png`.

**Catálogo (M5).** Dos recursos propios de contenido, generados con `catalog/tools/seed_m5.py` (reejecutable) e incorporados al catálogo y a los assets de la app:

- `devotional.daily` — 366 secciones fechadas (`dayofyear.MM.DD`, incluye `02.29`), 30 lecturas propias rotativas y versículo de la RV1909 (dominio público). Cada sección lleva `day`, `theme`, `reference` y `referenceLabel`.
- `factbook.core` — 32 artículos propios (temas, personas y lugares; 19 incluyen un mapa esquemático) con `summary`, `tags`, `related` y `references`. Los artículos cubren temas, personas y lugares: gracia, fe, esperanza, amor, oración, arrepentimiento, justificación, santificación, pacto, reino de Dios, Jesucristo, Juan el Bautista, Pablo, Pedro, María, Jerusalén, Belén, Galilea, Nazaret, Cafarnaún, Roma, Éfeso, Corinto, Atenas, Damasco, Jericó, Samaria, Monte Sinaí, Mar de Galilea, Río Jordán, Egipto y Judea.

Ambos usan **secciones embebidas** en un único `sections.json` (ver `03-contrato-catalogo.md` §1): el servicio las resuelve en memoria, el stream devuelve solo metadatos y la app las sirve desde assets con el mismo formato. El servicio evolucionó a `1.0-m7`; la autoprueba cubre **52** comprobaciones.

**Mapas (7.2 y comentarios).** El bloque `map` añade un mapa esquemático a 19 artículos del Factbook y al final de `JHN.3`, `LUK.2`, `MAT.2` y `ACT.9` del comentario. Hay **18 mapas** definidos en `catalog/config/maps.json`; el lector los dibuja con la geometría de Natural Earth (dominio público) y las coordenadas de OpenBible.info (CC BY 4.0), sin teselas ni red. Se puede hacer zoom y arrastrar; los marcadores con referencia abren el pasaje. La atribución aparece al pie. La app usa `lib/maps/bible_map.dart` y `test/maps_test.dart` cubre parseo, renderizado, error de geometría y navegación.

**Comparación de textos (7.1).** Panel con campo de referencia, botón del conjunto de versiones (casillas de multi-selección, mínimo una), atrás/adelante con historial propio y menú ⋮ (`Copiar comparación`). Cada versículo muestra una fila por versión con la etiqueta, el texto y `N% de diferencia` respecto de la base (la base, 0 %); las palabras que difieren se resaltan con fondo ámbar. El cálculo es un LCS sobre palabras normalizadas (`panels/text_diff.dart`), sin dependencias. Las referencias de versículo abren el pasaje en el lector. Hay nueve versiones (RV1909, KJV, ASV, BLL, SBLM, BES, VBL, TAHOT y TAGNT), todas empaquetadas; el aviso de «solo una versión» ya no aparece en modo local. Desviaciones: sin selector de «view» (el original tiene `Verses`/`Aligned`), sin arrastrar versiones entre columnas y sin sincronizar con el panel de al lado.

**Factbook (7.2).** Buscador `Tema o referencia`, fila de lentes (`Todo · Bíblico · Biblioteca · Teológico · Consejería · Descubra`, como el original) y lista de temas con recuento, resumen y etiquetas. El artículo muestra resumen, etiquetas, cuerpo por bloques, `Referencias` (chips que abren el pasaje) y `Temas relacionados` (chips que navegan al artículo). Buscar una referencia bíblica sin tema ofrece `Abrir pasaje`. Desviaciones: `Biblioteca` y `Consejería` no tienen datos propios (quedan vacías con su estado); no hay panel de fuentes de la biblioteca del usuario, línea de tiempo ni sujetos del contexto.

**Devocional (7.6).** Panel con navegación por día (`‹`, `›`, `Hoy` y selector de fecha), fecha legible, cuerpo por bloques con las referencias cruzadas clicables y pie `Abrir <referencia>`. La ubicación vive en `WorkspaceTab.reference` como `dayofyear.MM.DD`, igual que el original. Las lecturas son propias (no se copia ningún devocional licenciado) y el versículo, de la RV1909.

**Diseños guardados (2.5).** El menú de diseños (barra superior y barra lateral) añade, sobre los presets, `Guardar el diseño actual…` (nombre en un diálogo), la lista de diseños guardados (se aplican al tocarlos, con aviso) y `Eliminar diseño…` (diálogo con papelera por diseño). Se guardan en el workspace (SQLite, `savedLayouts`) con una copia profunda de los tiles; el original los asocia a la cuenta, el clon los guarda en local. El web app del original no mostraba el menú de diseños en el recon, así que el diseño del menú es propio.

**Pruebas.** `test/m5_text_diff_test.dart` (LCS y porcentajes) y `test/m5_tools_test.dart` (devocional, Factbook, comparación y diseños, incluido el menú lateral); la suite queda en 86 pruebas. La integración de Linux (`integration_test/catalog_flow_test.dart`) cubre además, contra el servicio real: devocional de hoy, búsqueda de `Jesucristo` en el Factbook y comparación con RV1909 + KJV.

## 14. M6.1 implementado — Ideas, Información y Artículo ▾

Recon del original (2026-10-19): capturas del panel de Ideas e Información conservadas con la evidencia de reconocimiento. Las capturas del clon se generan con `test/m6_screens.dart` en `/tmp/opencode/m6-app-*.png`.

**Drawers derechos exclusivos (3.12–3.13).** `💡 Ideas` y `ⓘ Información` viven al lado derecho del panel y reacomodan el lector (no son overlays); abrir uno cierra el otro y cambiar de modo del panel los cierra. Comparten cabecera (icono, título y ✕) y se implementan en `lib/reader/insights_drawer.dart`:

- `Ideas` abre en la pestaña de la **referencia actual** (`TabSpec.reference` → `Efesios 2:8`), con `Información del libro` como otra pestaña; sin referencia (p. ej. un recurso no bíblico) muestra solo la ficha.
  - `▾ Libros relacionados` (abierto por defecto): tarjetas de las secciones propias que citan la referencia — artículo del Factbook o lectura del devocional — con chip de portada (abreviatura del recurso), título, subtipo/tema/referencia, fragmento `summary` y `Más »`. Tocar la tarjeta abre el panel del recurso en esa sección (el Factbook ahora refleja cambios de `tab.reference` con `didUpdateWidget`).
  - `▾ Pasajes relacionados` ▸ `Referencias cruzadas` (abierto por defecto): co-referencias que el catálogo propio cita junto a la actual, con el texto del versículo desde la RV1909 cuando existe y el recurso de origen a la derecha. Tocar la referencia navega el lector.
  - Sin dataset de referencias cruzadas: el USFM de la RV1909 no trae marcadores `\x` (verificado, 0); `lib/reader/related_content.dart` alimenta ambos apartados con las secciones propias y está listo para un dataset dedicado (p. ej. TSK).
- `Información` abre la ficha del recurso: chip de portada, `Acerca de <título>`, subtítulo y descripción, filas de autor/editorial/edición/idioma/tipo/estadísticas, `Comenzar plan de lectura` (presente y deshabilitado hasta M6.3, con tooltip), `▾ Copyright` y `▾ Información auxiliar` (identificador y tipo). La ficha se resuelve con `resourceSummaryProvider` (`lib/catalog/resource_metadata.dart`, `listResources`) y cae al `DocumentManifest` si el servicio no está disponible.

**Artículo ▾ (3.14).** Menú con `Ir a artículo` (cabecera no interactiva), `Artículo anterior` y `Artículo siguiente`. Los pasos salen de los encabezados del documento (`HeadingBlock` → primer versículo siguiente); la RV1909 no trae encabezados, así que cae a capítulo siguiente/anterior como los ◀▶.

**Pruebas.** `test/m6_insights_test.dart` (4): superposición de referencias (pura), pestañas y tarjetas del drawer, navegación de un pasaje, apertura del Factbook desde `Más »`/tarjeta, ficha e información auxiliar con el botón de plan deshabilitado, cierre y menú Artículo. La suite queda en 91 pruebas. La herramienta `test/m6_screens.dart` captura los cuatro estados con el catálogo real.

## 15. M6.2 implementado — Marcadores (Formato ▸ Marcadores)

El panel del original (según la evidencia de reconocimiento): interruptor maestro `Mostrar marcadores` («Show markers»), casillas de datasets con un ✳ a la derecha (`Sermons`, `Bible Studies`, deshabilitadas sin datos) y la nota «Adds markers to show hidden data in the book.» con barra azul. El clon no tiene datasets de etiquetado de recursos, así que **nuestros datasets son los cuadernos y las etiquetas de Notas** (adaptación documentada en la evidencia de reconocimiento).

`TabDisplay` añade `markerNotebooks` y `markerTags` (persistidos con el panel). `markerFilterMatches(notebooks, tags)` decide qué se pinta: con el maestro apagado —o sin ningún filtro marcado— se ven todas las anotaciones; con filtros, un cuaderno y una etiqueta marcados a la vez exigen ambas condiciones (los demás indicadores y resaltados desaparecen del texto). El cuerpo del lector aplica el filtro antes de construir las anotaciones (`reader_body.dart`), así que afecta a los indicadores de nota, a los resaltados por rango y al modo paginado.

El flyout (`MarkersFlyout` ahora es `ConsumerWidget`, lee `notesProvider`) muestra el interruptor, los grupos `Cuadernos` y `Etiquetas` con el recuento de notas de cada uno y ✳ a la derecha, las casillas deshabilitadas mientras el maestro está apagado (como el original) y la nota al pie con barra azul (widget nuevo `FlyoutNote`). Sin cuadernos ni etiquetas informa de que hay que crear una nota con cuaderno o etiqueta.

**Pruebas.** `test/m6_markers_test.dart` (3): filtro puro y persistencia JSON de `TabDisplay`, filtrado real en el lector (cuaderno, etiqueta y ambos; el maestro apagado pinta todo y recuerda los filtros) y estado vacío. La suite queda en 94 pruebas; `test/m6_screens.dart` captura el panel en `/tmp/opencode/m6-app-markers.png`.

## 16. M6.3 implementado — Herramientas, Estudio guiado, Planes de lectura e Inicio

Recon del original (2026-10-19): diálogo `Guided Study` y hub de herramientas, además del plan por sub-hitos conservado con la evidencia de reconocimiento. Las capturas del clon se generan con `test/m6_screens.dart` en `/tmp/opencode/m6-app-*.png`.

**Menú Herramientas (7.4–7.6).** El menú de la barra lateral y de la barra superior (`lib/shell/tools_menu.dart`) replica las filas del original con sus iconos: Atlas, Cursos, Documentos, Temas (Factbook), Información, Medios, Comparación de textos y Planes de lectura. Las seis herramientas que antes estaban deshabilitadas ya están implementadas (M6.5, §21); `Temas` abre el Factbook, `Información` el panel de información, `Comparación` la comparación de textos y `Planes` el panel de planes de lectura.

**Estudio guiado (7.7).** El original es un diálogo con `Find`, secciones (`Workflows`, `Guías`) y filas con descripción y acción (`Start`). El clon lo convierte en **panel** (`lib/guides/`) con la misma estructura (caja `Find`, secciones y filas navegables) y con **plantillas propias** cuyos pasos abren herramientas reales:

- Guías: `Estudio de palabras bíblicas` (pide una palabra), `Guía exegética`, `Guía de pasajes` y `Guía para sermones` (piden la referencia activa del lector).
- Flujos: `Devocional y oración`, `Lectura del día` y `Repaso de mis notas`.
- Cada paso es una tarjeta con casilla `hecho`, título y detalle; si el paso tiene acción, un botón a la derecha abre el lector, la comparación, el Factbook (Temas), la búsqueda o las Notas. La guía en ejecución vive en la pestaña del panel (id en `tab.reference`, parámetro en `tab.query`), así que no se pierde al cambiar de panel, y `Volver` regresa al listado.

**Planes de lectura (7.6).** Cuatro plantillas propias calculadas desde el manifiesto de la RV1909 — `Biblia en un año` (3–4 capítulos al día), `Evangelios en 30 días`, `Salmos y Proverbios en 31 días` y `Nuevo Testamento en 90 días` — con la tarjeta del plan activo (barra de progreso, `Día X de Y`, `Lectura de hoy: Génesis 1—3`), `Abrir la lectura de hoy`, `Marcar día como leído`, `Detener plan` y `Otros planes` (empezar otro pide confirmación si hay uno en curso). Es la adaptación local del gestor de planes de la cuenta del original (que requiere sesión) y es lo que habilita el botón `Comenzar plan de lectura` de la ficha del recurso, que cambia a `Ver plan de lectura` con un plan activo.

**Inicio (7.8).** El `Inicio` del clon es un panel con tarjetas adaptativas (1–3 columnas) construidas sólo con datos locales: `Continuar la lectura` (referencias recientes del historial de las pestañas), `Plan de lectura` (progreso y lectura de hoy, o elegir plan), `Notas` (recuento de notas y resaltados), `Devocional de hoy`, `Estudio guiado` (una entrada por guía, que abre el panel ya en marcha) y `Herramientas` (Temas, Comparación y Planes). El original muestra este panel con la sesión iniciada (actividad de la cuenta, compras, favoritos); el clon lo sustituye por lo que existe en local.

**Pruebas.** `test/m6_guided_test.dart` (4), `test/m6_plans_test.dart` (5, incluida la ida y vuelta del plan en SQLite y el botón de la ficha) y `test/m6_dashboard_test.dart` (1); la suite queda en 104 pruebas y `test/m6_screens.dart` captura el menú de herramientas, el Estudio guiado (hub y ejecución), los planes y el Inicio.

## 17. M6.4 implementado — Asistente de estudio (plugin de IA opcional)

Recon del original (2026-10-19): la evidencia de reconocimiento captura el estado **sin sesión**: icono, invitación a preguntar con libros de la aplicación, tres preguntas de ejemplo deshabilitadas, un aviso de que la función usa IA y recomienda verificar los resultados, y el bloque para iniciar sesión o crear una cuenta. El chat con sesión no se pudo capturar porque requiere una cuenta real.

El clon sustituye la sesión por el **plugin de IA** (`lib/assistant/`): `assistant_models.dart` define el contrato del motor (`StudyAssistantEngine.ask(question, scope)` → texto con referencias citadas) y `assistant_controller.dart` la conversación de la sesión y el proveedor conectado (`assistantEngineProvider`, sin ninguno por defecto porque el plugin es opcional).

- **Sin proveedor** (`study_assistant_panel.dart`): reproducción del estado sin sesión con textos propios — invitación `Solo pregunta. Usaré tu biblioteca…`, las tres preguntas de ejemplo deshabilitadas, el aviso de IA y un bloque `Conectar un proveedor de IA para empezar la conversación.` que abre un diálogo explicando el plugin y ofreciendo el `Estudio guiado` como alternativa local.
- **Con proveedor** (integraciones futuras y pruebas): chat con barra (`Nuevo`, `Recientes` con las preguntas anteriores, `Copiar todo` al portapapeles), alcance `Todos los libros` / `La Biblia`, nombre del proveedor, sugerencias activas cuando no hay mensajes, burbujas de usuario y respuestas con citas que abren el lector, `Pensando…` y aviso de fallo del proveedor.

**Pruebas.** `test/m6_assistant_test.dart` (3): estado sin proveedor y diálogo del plugin, chat completo con un motor falso (sugerencia, cita que abre el lector, `Recientes`, `Copiar todo`, cambio de alcance y `Nuevo`) y fallo del proveedor. La suite queda en 128 pruebas; `test/m6_screens.dart` captura `/tmp/opencode/m6-app-{assistant,assistant-chat-empty,assistant-chat}.png`.

## 18. Autonomía local implementada — catálogo e índice FTS5 dentro de la app

La app ya no depende del servicio Python para el uso normal. `app/assets/catalog/` incluye las nueve Biblias completas (RV1909, KJV, ASV, BLL, SBLM, BES, VBL, TAHOT y TAGNT), el léxico Strong, el comentario, el diccionario, el devocional y el Factbook, además de:

- `index.json` con los catorce summaries (Biblioteca local, 14 recursos);
- `search.sqlite.gz` (48,8 MB comprimido) con el índice FTS5 de 248 870 versículos y 23 633 secciones no bíblicas (272 503 entradas), la tabla `cross_references` con 376 083 enlaces y `search.meta.json` con su hash y tamaño.

En el primer uso, `LocalCatalogIndex` extrae el índice a `catalog.search.<hash>.sqlite` en el directorio de datos y lo abre en solo lectura. El hash en el nombre evita reutilizar una copia vieja. La búsqueda local replica exactamente la sintaxis del servicio (palabras, frases, `AND`/`OR`/`NOT`, `NEAR`, `WITHIN n WORDS`, campos `bible:`/`book:`/`type:`/`language:`/`resource:`, filtros y facetas) y el modo `auto` cae a ella si el servicio no responde; Ajustes muestra `Modo local: 14 recursos, 248 870 versículos y 23 633 secciones indexadas` en vez de «Sin conexión».

`catalog/tools/sync_app_catalog.py` sincroniza contenido e índice desde `catalog/data/`. Pruebas: `local_search_query_test.dart` (7, parser), `catalog_gateway_local_test.dart` (extracción/búsqueda/facetas/TSK/auto), `catalog_content_test.dart` (índice y detalle del comentario/diccionario) y `document_repository_test.dart` (KJV empaquetada); la integración `offline_catalog_test.dart` recorre Biblioteca → KJV → búsqueda global → búsqueda en el panel → Factbook y devocional → comentario y diccionario → RV1909 → Ideas con TSK **sin servicio**.

## 19. Profundidad de contenido implementada (mejora 3)

Se añadieron dos traducciones y tres capas de estudio, todas con fuente y licencia registradas en [`NOTICE.md`](../../NOTICE.md):

- **Biblias:** ASV 1901 y Santa Biblia libre Latinoamericano (BLL), desde eBible.org; la comparación y la búsqueda ya las incluyen. La Biblioteca local pasa a 14 recursos y 9 Biblias.
- **Comentario:** Matthew Henry, edición concisa (CC0, 1 189 capítulos). Se muestra en un panel genérico con índice filtrable, detalle y apertura del pasaje; `2 Reyes 1`, ausente en la edición concisa, se completa desde la edición completa del mismo autor.
- **Diccionario:** Easton (1897, dominio público; 3 961 entradas) con el mismo panel; el índice local permite `type:dictionary` y la búsqueda abre la entrada.
- **Referencias cruzadas:** TSK (376 083 enlaces; 29 055 versículos fuente) en la tabla `cross_references`; «Ideas» las combina con Factbook, devocional y comentario, y `GET /v1/cross-references` las expone con `source` y `license`.
- **Carga perezosa:** comentario y diccionario guardan `sections.json` (metadatos) y `sections/<id>.json` (bloques); el índice FTS5 sigue indexando el texto completo de cada entrada.
- **Atribución:** los manifiestos incluyen `source` y `license`; la ficha del recurso muestra la licencia. El detalle técnico y los comandos de regeneración están en [`05-fuentes-contenido.md`](05-fuentes-contenido.md).

Verificación de la mejora: `selftest.py` **52/52**, suite completa de Flutter y las integraciones Linux `catalog_flow_test` y `offline_catalog_test` (incluida la apertura de comentario y diccionario y el TSK en «Ideas»).


## 20. Paridad 1 implementada — Link sets, Tienda local, pantalla completa y tema oscuro

- **Link sets A–F.** `WorkspaceTab.linkSet` se persiste en `tabs.link_set` (esquema SQLite v3). El botón «Conjunto de vínculos» del lector abre un menú con `Sin conjunto` y A–F; al asignar una letra, los paneles bíblicos de ese grupo adoptan la referencia actual y siguen cualquier navegación posterior (referencia, historial o apertura desde búsqueda). El seguimiento es unidireccional para no crear bucles y no incluye paneles que no son Biblia.
- **Tienda local.** `StorePanel` lista los 14 recursos incluidos con búsqueda, filtro por tipo, licencia, tipo/idioma/autor y botón `Abrir`; también se llega desde la pestaña `Store` de la Biblioteca. No hay compras, descargas ni telemetría: es un catálogo de descubrimiento de lo ya empaquetado.
- **Pantalla completa por panel.** Estado transitorio en `workspace/panel_fullscreen.dart`; `Shell` renderiza solo el panel elegido, con una barra mínima y salida por botón o `Esc`. Sustituye a la pantalla completa de la ventana anterior.
- **Tema claro/oscuro/sistema.** `WorkspaceState.themeMode` se persiste en SQLite; `AletheiaApp` usa `theme`/`darkTheme`/`themeMode` y una paleta activa (`AletheiaPalette`) que adapta fondos, bordes, textos, campos y menús. El cambio recrea el subárbol para que los widgets `const` recalculen sus colores.
- **Corrección de runtime.** Los cuatro `Scrollbar` explícitos (devocional, Factbook, comparación y comentario/diccionario) usan ahora su propio `ScrollController`, eliminando el error «Scrollbar's ScrollController has no ScrollPosition attached» detectado en la prueba manual.

**Pruebas.** `test/workspace_features_test.dart` (7): propagación y limpieza de link sets, ida y vuelta JSON, Tienda local (lista, filtro y apertura), pantalla completa con botón y con `Esc`, selector de link set y cambio de tema. `sqlite_persistence_test.dart` verifica `linkSet` y `themeMode` en SQLite. La suite completa incluye las pruebas de originales, léxico y estudio.

## 21. M6.5 implementado — Atlas, Cursos, Documentos, Medios, Favoritos y Explorador de Salmos

Las seis herramientas que quedaban pendientes en el menú **Herramientas** ya están implementadas con datos locales y abren paneles reales en el workspace (no hay etiquetas `Pronto`):

- **Atlas y Medios** (`lib/maps/visual_library_panel.dart`, `visual_sections.dart`). Ambos leen `map_sections.json` (23 entradas: 19 artículos del Factbook con mapa y 4 capítulos del comentario). Atlas muestra una lista con filtros; Medios, una galería adaptativa (tarjetas o lista según el ancho). El detalle carga la sección de origen, dibuja el mapa con `BibleMap` (Natural Earth + OpenBible.info) y ofrece favorito del mapa y `Abrir la sección`.
- **Cursos** (`lib/courses/`). Tres cursos propios (Panorama, Evangelios y Oración) con tres lecciones cada uno; cada lección tiene cuerpo, referencias y apertura en el lector. El progreso (`course_progress`, esquema SQLite v5) marca las lecciones completadas y sobrevive a la recarga, también en web.
- **Documentos** (`lib/documents/`). Tres guías propias (lectura, línea de tiempo y glosario) con cuerpo markdown-lite y navegación interna; también enlazan al lector.
- **Favoritos** (`lib/favorites/`). Alta por referencia con validación del parser (`Juan 3:16`), lista ordenada por fecha, apertura en el lector y borrado. Se guarda en la tabla `favorites` (esquema v5) con tipo `passage` o `map`; el mapa se puede guardar desde el detalle del Atlas y el pasaje desde la **estrella de la barra de ubicación** del lector (no en la toolbar principal, para no desplazar botones).
- **Explorador de Salmos** (`lib/psalms/`). Los 150 salmos de la RV1909 con clasificación propia por géneros (alabanza, lamento, confianza, sabiduría, realeza y acción de gracias), búsqueda por título y texto, tarjeta de **Salmo del día** y apertura directa en el lector.

**Móvil.** En ventanas estrechas elegir una herramienta pliega la barra lateral antes de navegar (`sidebarCollapsedProvider`, `lib/shell/sidebar_state.dart`), el menú Herramientas también la pliega y el rail se despliega con `Expandir barra lateral`. Las capturas y el smoke real en Chromium a 390×844 no muestran overflow ni errores de consola.

**Pruebas.** `test/m6_tools_test.dart` (15): las seis herramientas abren y navegan, el favorito de mapa conserva su tipo, la estrella del lector guarda/quita el pasaje, el menú pliega la barra en móvil y las seis herramientas no desbordan a 390×844. `test/sqlite_persistence_test.dart` (5) añade la ida y vuelta de favoritos y del progreso de Cursos. La suite queda en **173 pruebas** y `flutter analyze` está limpio; el smoke de Playwright cubre escritorio y móvil con las seis herramientas.
