# 04 — Mejoras de diseño (repaso visual del clon contra el original)

Fecha: 2026-10-19. Método: comparación lado a lado de las capturas del original
(capturas del original en ventanas de 1440–1915 px) con las capturas del clon
(`test/*_screens.dart` → `/tmp/opencode/*.png`, 1400×900) y medición de píxeles
(color, alturas, anchos) sobre ambos juegos de imágenes. Los montajes del repaso
están en `/tmp/opencode/cmp/*.png` (no se versionan).

La base funcional está cerrada (M0–M6); esto es la lista de trabajo para la fase
de acabado visual, por paquetes y con prioridad.

## Evidencia medida

| Elemento | Original | Clon | Nota |
|---|---|---|---|
| Color de chrome (barra lateral, tira de pestañas, fondo alrededor de paneles) | `#EEEEEE` | `#EDEFF2` | El original es neutro; el clon tira a azul |
| Fondo de la tira de pestañas | `#EEEEEE` | `#FFFFFF` | Diferencia clara |
| Pestaña activa | Cuerpo blanco, esquinas superiores redondeadas y **borde superior de 3 px del color del recurso** (RVR60 = `#FF6600`) | Blanca con **subrayado azul inferior** | Cambia el lenguaje visual de la tira |
| Alto de la pestaña | ~31 px + tira de ~40 | ~40 px + tira de ~48 | |
| Rótulo de la pestaña de recurso | Abreviatura del recurso («RVR60») con chip de color | Referencia («Efesios 2:8») | La referencia vive en la caja del panel |
| Ómnibus | Dentro de la cabecera de la barra lateral (≈195 px), sin icono de lupa | Barra superior a todo el ancho (≈326 px), con icono de lupa | Cambia la estructura del shell |
| Banner | Columna del área de trabajo, encima de la tira de pestañas; navy `#00042F`, texto blanco 15 px w600, botón blanco | Barra superior, `#182240`, texto 12.5 px y enlace azul | |
| Filas de la barra lateral | Paso ~47 px; iconos rellenos ~22 px; etiquetas 15 px w600 | Paso ~37 px; iconos outlined 17 px; etiquetas 13.5 px w400 | |
| Ítem activo de la barra lateral | Fondo blanco redondeado | Sin resalte | |
| Caja de referencia del panel | Alto ~32 px, borde claro, 15 px | Alto ~40 px, borde más marcado | |
| Modo activo del panel (Home/Search/…) | Texto azul + subrayado | Solo subrayado (texto negro) | |
| Fila secundaria (Contents/History/Article/…) | ~34 px con separadores verticales entre grupos | ~40 px sin separadores | |
| Título de sección en el lector | Centrado, serif ~17 px w700 | 15.5 px w700 centrado | Nuestra RV1909 no trae `\s`, así que el caso raro es que haya títulos |
| Número de capítulo | Serif ~30 px | 27 px | |
| Comparación de textos | Por versículo: chip de versión en columna izquierda + texto con resaltado por palabra; % a la derecha | Etiqueta encima del texto y tinte de fila completa | |
| Filas de menús (Herramientas, Diseños…) | ~34 px de alto, ~180–200 px de ancho | ~42 px, ~200–220 px | |

> **Nota de escala.** Las capturas `ux2/*` (1915×934) están a ~1,2× respecto de
> las de 1440×900 (`public/settle_bible.png`): el mismo shell mide allí ~250 px
> de barra lateral, pestañas de ~45 px y etiquetas de ~15 px, mientras que a
> 1440 mide ~210 px, ~37 px y ~12,5–13 px. La tabla mezcla ambas; al aplicar el
> paquete A se tomó la captura de 1440 como referencia de tamaño y se mantuvo
> algo más de aire (44/14,5) para las etiquetas en español, más largas.

## Diferencias deliberadas (no se «arreglan»)

- **Portadas reales**: el original muestra la portada del libro; el clon usa un
  chip con la abreviatura (sin activos licenciados).
- **Cuenta y tienda**: el clon no tiene sesión, sincronización ni compras; el
  Inicio usa datos locales y Tienda queda como escaparate del catálogo propio.
- **Idioma de la interfaz**: el original deja en inglés las etiquetas del panel
  (Home, Contents, Insights…); el clon las traduce (Inicio, Índice, Análisis…)
  por la i18n propia.
- **Banner**: el original anuncia promociones de la tienda; el clon anuncia el
  build/catálogo y abre la Biblioteca (mismo sitio y estilo, contenido propio).
- **Referencia en la caja del panel**: el original la muestra en inglés
  («John 1:1») aunque el contenido esté en español; el clon la localiza.

## Paquetes de mejora, por prioridad

### A. Shell (máximo impacto visual) — P0

Archivos: `lib/shell/shell.dart`, `lib/workspace/workspace_view.dart`,
`lib/core/theme.dart`, `lib/catalog/*` (color por recurso).

1. **Ómnibus dentro de la barra lateral**: mover `Omnibox` a la cabecera de la
   barra (logo + campo), ancho ≈ barra − logo − márgenes, sin icono de lupa.
   Con la barra colapsada, mantener el ómnibus accesible (barra superior mínima
   o el propio rail con el logo).
2. **Banner a la columna del área de trabajo**, encima de la tira de pestañas,
   con el estilo del original (`#00042F`, texto 15 px w600, botón blanco).
3. **Tira de pestañas**: fondo de chrome `#EEEEEE`; pestaña activa blanca con
   esquinas superiores redondeadas y borde superior de 3 px **del color del
   recurso**; alto ~32 px. Las pestañas de recurso se rotulan con la abreviatura
   y un chip de color. Añadir el color por recurso (derivado por tipo/id en el
   catálogo o declarado en los metadatos).
4. **Barra lateral**: paso de fila ~46 px, iconos **rellenos** de ~20-22 px y
   etiquetas 15 px w600; ítem activo con fondo blanco redondeado; logo de 32 px
   con radio 8; ancho de barra a ~232-240 px para las etiquetas largas.
5. **Chrome neutro `#EEEEEE`** para barra lateral, tira de pestañas y fondo
   alrededor de paneles (sustituir `kWorkspaceBg`/`kSidebarBg` por el token
   neutro).

### B. Lector — P1

Archivos: `lib/reader/reader_panel.dart`, `lib/reader/reader_body.dart`,
`lib/reader/reader_style.dart`.

6. Alturas: fila A y caja de referencia a ~34/32 px; fila B a ~34 px con
   **separadores verticales** entre grupos; modo activo en azul.
7. Tipografía: título de sección a ~17 px y número de capítulo a ~30 px.
   (La RV1909 no trae títulos de sección; el renderizado ya existe para cuando
   el catálogo los traiga.)

### C. Comparación de textos — P2

Archivos: `lib/panels/text_comparison_panel.dart`.

8. Estructura por versículo en **dos columnas** (chip de versión a la izquierda
   con ancho fijo, texto a la derecha).
9. Resaltado **por palabra** (el diff ya se calcula) en vez de teñir la fila
   entera; porcentaje a la derecha de la primera fila del versículo y atenuado
   cuando las versiones son de idiomas distintos (hoy RV1909 vs KJV da 100 %).

### D. Detalles menores — P3

10. Tarjetas (Inicio y paneles): radio 8, borde `#E3E3E3`, etiqueta de sección
    en mayúsculas 12 px con tracking.
11. Menús contextuales (Herramientas, Diseños, Artículo ▾): filas ~34 px y
    tipografías 13.5–14 px.
12. Chips de recurso (lector y fichas) con el color del recurso, en vez del
    icono azul genérico.

## Orden propuesto

1. **Paquete A** (1–5) en un solo cambio: es lo que más se nota al abrir la app
   y comparte archivos.
2. **Paquete B** (6–7).
3. **Paquete C** (8–9).
4. **Paquete D** (10–12).

Cada paquete: pruebas (suite actual como red de seguridad + capturas nuevas),
`flutter analyze` limpio y captura comparativa en `/tmp/opencode/cmp/`.

---

## Estado de aplicación

### A. Shell — aplicado (2026-10-19)

Capturas: `/tmp/opencode/m6-app-dashboard.png`,
`m6-app-shell-narrow.png`, `m6-app-shell-narrow-omnibox.png` y el montaje
`/tmp/opencode/cmp/cmp-shell-b.png`.

- **Cabecera lateral**: logo de 32 px (radio 8) + ómnibus a su derecha, sin
  lupa; la barra lateral mide 232 px y el campo ocupa el resto. Con el rail
  (ventanas < 880 px o plegado manual) el logo abre el ómnibus en un diálogo
  con foco automático; así la búsqueda sigue disponible sin ensanchar el rail.
- **Banner**: columna del workspace, encima de la tira, a sangre, alto 48 px,
  navy `#00042F`, texto 14,5 px w600 centrado y botón gris claro (`#EDEDED`,
  radio 4) con el ✕ a la derecha.
- **Tira de pestañas**: chrome `#EEEEEE`, alto 36 px (la pestaña ocupa la tira
  completa). Activa: cuerpo blanco, esquinas superiores de 7 px y borde
  superior de 3 px del color del recurso; inactiva: transparente. Las pestañas
  de recurso muestran chip de color + abreviatura (`RV1909`), tomada del
  manifiesto y con respaldo derivado del id; las herramientas usan su icono en
  azul. Si la pestaña activa queda fuera de la tira, se desplaza lo justo para
  mostrarla. El panel ya no lleva borde superior bajo la pestaña activa: el
  cuerpo blanco de la pestaña y el del panel se leen como una pieza.
- **Color por recurso**: `lib/core/resource_colors.dart` (mapa para los
  recursos conocidos + paleta estable por hash para el resto). Se usa en la
  pestaña, en el chip de portada y como base para el resto de los paquetes.
- **Barra lateral**: filas principales de 44 px + 1 px de margen (paso 46),
  iconos rellenos de 20 px y etiquetas 14,5 px w600; acciones rápidas y pie de
  30/36 px con etiquetas de 12,5–13 px. El ítem activo lleva fondo blanco
  redondeado, icono y rótulo en azul; los iconos de sección son rellenos. El
  pie agrupa ⋮ y «?» a la izquierda y la flecha de plegado a la derecha.
- **Chrome neutro**: `kWorkspaceBg` pasa a `#EEEEEE` (barra lateral, tira y
  fondo de paneles). `kBannerBg` pasa a `#00042F`.

Pendiente al cerrar A: el resalte del ítem activo combina fondo blanco (del
repaso) con texto azul (estado del original); el original a 1440 no usa fondo,
solo color en el ítem. Se mantiene el fondo por claridad y porque estaba en el
plan aprobado.

### B. Lector — aplicado (2026-10-19)

Capturas: `/tmp/opencode/reader-1-home.png` (640 px), `-w700` y `-w900`,
`/tmp/opencode/m6-app-insights-reference.png` y los montajes
`/tmp/opencode/cmp/cmp-reader-bars.png` y `cmp-reader-body.png`.
`test/reader_screens.dart` acepta `SCREEN_WIDTH` y `SCREEN_SUFFIX` para sacar
el panel a otros anchos.

- **Alturas**: fila A de 42 → **36 px**, fila B en **36 px** (ya lo estaba) y
  barra de ubicación de 30 → **36 px**. Medido en `settle_bible` (1440: bordes
  en y=72 y y=109; barra hasta 146) y en `home2` (1915, ×1,2: 43 y 45 px → 36
  y 37,5 CSS). La estimación del repaso (~34/32) se queda corta.
- **Fila A**: la caja de referencia pasa a ser un **campo gris** `#F2F3F4` de
  28 px, radio 4 y sin borde (como el original), con la **portada del recurso**
  de 13×16, su ▾ y un separador vertical dentro de la caja. El campo de texto
  va sin borde; al enfocar, la caja dibuja un anillo azul, y en error, rojo
  (`kError`). Los modos bajan a 36 px, con subrayado activo de **3 px** y
  etiquetas de 13 px; el inactivo deja de ser gris al 55 % (se leía demasiado
  tenue) y pasa a `#3C4043`, con hover azul muy claro (`#E9F5FF`) como el
  original. Retroceso/avance con densidad compacta.
- **Fila B**: etiquetas de 12,5 → **14 px** e iconos de 15 → 16 px;
  **separadores verticales** de 24 px entre «Historial | Artículo ▾ ↑ ↓ |
  Conjunto de vínculos» (medidos en x=397 y x=537 de `settle_bible`).
  **Análisis** e **Información** quedan anclados al borde derecho (en `home2`
  hay un hueco de ~117 CSS px tras «Link set»); el resto de la fila se
  desplaza si no cabe.
- **Adaptación responsive** (propia; el original recorta): con menos de 800 px
  de panel, «Artículo», «Conjunto de vínculos», «Análisis» e «Información»
  pasan a **icono + tooltip** para que todo siga accesible sin scroll. A 1159
  px (captura de app) se ven todas las etiquetas.
- **Tipografía**: título de sección 15,5 → **17 px** y número de capítulo 27 →
  **30 px**. El título sigue **centrado** (la RV1909 de `home2` lo centra; la
  KJV de `settle_bible` lo alinea a la izquierda: es tipografía del recurso, y
  la RV1909 es la nuestra). Nuestra RV1909 no trae títulos `\s`, así que el
  cambio se ve cuando el catálogo los traiga.
- **Adelanto de D-12**: el chip de portada del lector ya usa
  `resourceColorFor`.
- **Pruebas**: `flutter analyze` limpio; **110** pruebas en verde. Se añadió
  `ValueKey('reader-article')` y los tests de Artículo (M6.1 y capturas) pulsan
  por clave, no por etiqueta, para que sigan funcionando en paneles estrechos.

Los tres pendientes que quedaron fuera de B se resolvieron después, en la
sección **E** (sangría de primera línea, círculo + ⋮ de la fila A y «San Juan»
en la barra de ubicación).

### C. Comparación de textos — aplicado (2026-10-19)

Capturas: `/tmp/opencode/m5-app-compare.png` (catálogo real: RV1909 + KJV),
`m5-app-compare-diff.png` (ESP2 sintética, para ver el resaltado entre versiones
del mismo idioma; la genera `test/m5_compare_diff_screens.dart`) y el montaje
`/tmp/opencode/cmp/cmp-compare-rows.png`.

- **Dos columnas por fila**: chip de versión de ancho fijo (**66 px**, 11,5 px
  w500, azul) + texto (serif 14 px, altura 1,45). El porcentaje deja de ocupar
  una tercera columna fija de 104 px y pasa **en línea** al final del texto,
  como el original; es un `WidgetSpan` para que «0 % de diferencia» no se parta
  y, si no cabe, baje entero a la línea siguiente (en el original le ocurre a
  «La Palabra», la etiqueta más larga). Filas con 2 px verticales y 18 px entre
  versículos.
- **Resaltado por palabra**: las palabras que difieren se tiñen de azul
  (`kAccent`) y el **inicio de cada tramo** lleva un circulito rojo hueco de
  5 px (`#CC3333`, medido en el original), desplazado sobre la primera letra.
  Se elimina el fondo ámbar que teñía la fila entera. La referencia del
  versículo sube a 12,5 px.
- **Idiomas distintos**: el original no compara RVR60 con ESV (fila inglesa sin
  resaltado, sin circulito y **sin porcentaje**). El clon hacía lo contrario:
  «100 % de diferencia» con toda la fila en ámbar. Ahora se omite el diff
  completo (resaltado y %) cuando la versión no comparte idioma con la base; la
  base siempre muestra su «0 %». El repaso hablaba de «atenuar» el porcentaje,
  pero la evidencia muestra que el original lo omite.
- **Pruebas**: los porcentajes viven ahora en `Text.rich`/`WidgetSpan`, así que
  los finders pasan a `find.textContaining(..., findRichText: true)`; el test
  comprueba que la base muestra 0 % dos veces y que la KJV no muestra ninguno.
  `flutter analyze` limpio; **110 pruebas** en verde.

Con C cerrado, el siguiente paquete era **D — detalles menores** (aplicado
abajo).

### D. Detalles menores — aplicado (2026-10-20)

Capturas: `/tmp/opencode/m6-app-dashboard.png`, `m6-app-tools-menu.png`,
`m6-app-article-menu.png`, `m6-app-insights-book.png`, `m6-app-info.png`,
`m2-library.png` y `m6-app-guided-run.png`; montaje
`/tmp/opencode/cmp/cmp-menus.png`.

- **Tarjetas**: borde `#E3E3E3` (`kCardBorder`, nuevo token) y radio 8 en
  Inicio, Planes y los pasos de Estudio guiado (suben de radio 6 a 8). Las
  etiquetas de las tarjetas de Inicio pasan a **MAYÚSCULAS 12 px w600 con
  tracking 0,7**, como el «EXPLORE» del original; el icono baja a 16 px.
- **Menús**: tema global `popupMenuTheme` (blanco, radio 8, elevación 3,
  sombra al 20 %, texto 13,5 px e iconos 16). Las filas bajan a **34 px** en
  Herramientas, Diseños, Artículo ▾ y «Más» (antes 39–44 px), con la misma
  altura en el menú de pestaña, Ajustes y «Copiar» de la comparación.
- **Chips de recurso**: el chip de «Libros relacionados» (Ideas), la portada
  de Biblioteca, el selector de libro del lector y el chip del lector (que ya
  venía de B) usan `resourceColorFor`; se acaban las portadas/iconos azules
  genéricos. En Biblioteca, KJV queda azul y RV1909 naranja.
- **Fila B del lector**: Información pasa al **círculo relleno** (`Icons.info`,
  como el original) y Análisis al bombillo con rayos
  (`tips_and_updates_outlined`). Con el panel abierto, el botón lleva el
  **fondo azul claro** `#E8F0FE` del original (antes solo cambiaba el color
  del texto). El original dibuja el círculo de Información en gris pizarra,
  no en azul: se mantiene gris cuando está inactivo.
- **Pruebas**: `flutter analyze` limpio; **110 pruebas** en verde. En las
  capturas sin GPU la sombra de los menús se rasteriza como un contorno
  duro; se suavizó con `shadowColor` al 20 % (en la app real es difusa).

Con D se cierra la lista priorizada **A–D** del repaso.

### E. Cierre de los pendientes de B — aplicado (2026-10-20)

Capturas: `/tmp/opencode/reader-1-home.png` y `m6-app-insights-book.png`;
montajes `/tmp/opencode/cmp/cmp-reader-indent.png` y
`/tmp/opencode/cmp/cmp-reader-toolbar-right.png`.

- **Sangría de primera línea**: los grupos de párrafo del lector llevan
  **1,5 em** (≈23 px) de sangría mediante un `WidgetSpan`, que no forma parte
  del texto copiado ni de los índices de selección. La medición de `home2` da
  ~22 CSS px. El justificado ya estaba aplicado. El original abre párrafos
  editoriales dentro de un mismo bloque (v. 6) que el JSON de la RV1909 trae
  como un solo `verseGroup`: se indenta el grupo completo, no cortes internos
  que el dato no declara.
- **Fila A**: se añaden los dos botones que faltaban, anclados a la derecha
  (fuera del scroll): el **círculo `^`** «Ocultar la barra secundaria»
  (`a11y: Hide secondary toolbar`; `#63728C`, 20 px) y el **⋮** «Comandos del
  panel» (duplicar, cerrar esta / a la derecha / las otras / todas). El ajuste
  se guarda en `TabDisplay.secondaryToolbar` (persistido con la pestaña); al
  ocultarla, el círculo pasa a `v` y la fila B desaparece. El menú «Más ▾» se
  conserva como el «More» del original.
- **Barra de ubicación**: en español los evangelios se titulan **«San Juan»**
  (también San Mateo, San Marcos y San Lucas) mediante `readerArticleTitle`;
  las citas siguen usando `bookDisplayName` («Juan 3:16»). En inglés manda el
  nombre del recurso (KJV → «John»).
- **Pruebas**: `flutter analyze` limpio; **111 pruebas** en verde (nueva:
  círculo + ⋮ + «San Juan» en `reader_panel_test.dart`).

**Opcional (datos, no diseño)**: el JSON de la RV1909 trae cada capítulo como
un solo `verseGroup`, mientras que la edición de `home2` abre párrafos
editoriales internos (p. ej. el v. 6) con su propia sangría. Añadir esos cortes
al catálogo permitiría que el lector los reproduzca; no se inventan en la UI.

### Mejora sustancial 1 — Autonomía local (aplicada, 2026-10-20)

No es un paquete visual, pero cierra la dependencia más grande del clon: ya no
hay que arrancar el servicio Python para usar la app.

- **Contenido**: se empaqueta la KJV completa (manifiesto + 66 libros, 7,8 MB)
  junto a la RV1909, el devocional y el Factbook. La Biblioteca local pasa de 3
  a **4 recursos** y la comparación de textos ya tiene dos versiones sin
  servicio.
- **Índice**: `catalog/tools/sync_app_catalog.py` sincroniza `catalog/data/` y
  comprime el FTS5 en `assets/catalog/search.sqlite.gz` (7,4 MB; 62 186
  versículos + 384 secciones = 62 570 entradas). El `search.meta.json` lleva el
  hash; en el primer uso se extrae a `catalog.search.<hash>.sqlite` y se abre en
  solo lectura. Sin indexación en runtime y sin reutilizar índices viejos.
- **Búsqueda**: `local_search_query.dart` replica el tokenizador del servidor;
  `LocalCatalogIndex` ejecuta la misma consulta y devuelve el mismo `SearchHit`.
  El modo `auto` cae al índice local si el servicio no responde; el modo `local`
  ya no lanza `SearchServiceOfflineException`.
- **Ajustes**: el estado distingue `Conectado` (servicio) de `Modo local` con
  recursos, versículos y entradas indexadas. El aviso de búsqueda sin servicio se
  sustituye por un error de índice local solo para instalaciones dañadas.
- **Pruebas**: `flutter analyze` limpio; **128 pruebas** (parser FTS5, gateway
  local con extracción real, KJV empaquetada, Factbook/devocional y caída de
  `auto`) e integración Linux `offline_catalog_test.dart` sin servicio. La app
  crece ~15 MB de assets (KJV 7,8 MB + índice comprimido 7,4 MB).

### Mejora sustancial 2 — Búsqueda de estudio (aplicada, 2026-10-20)

La búsqueda deja de ser una consulta simple y se convierte en herramienta de
estudio, con la misma semántica en servidor y modo local:

- **Sintaxis**: `AND` / `OR` / `NOT`, `"frases"`, `NEAR` (10 palabras),
  `NEAR/5` y `WITHIN n WORDS`; antes solo existían los operadores básicos.
- **Campos**: `bible:"Jn 3"` (pasaje, con capítulo y rango opcionales),
  `book:JHN`, `type:factbook`, `language:es` y `resource:bible.kjv`. Una consulta
  puede ser solo un campo (`bible:"Jn 3"`) y lista el pasaje completo.
- **Filtros y facetas**: `type`, `language` y `book` en la API y en la barra de
  filtros de la UI; los menús se alimentan de facetas calculadas excluyendo su
  propio filtro, de modo que siempre se puede cambiar de opción.
- **Resultados**: agrupados por recurso con cabecera e icono; un hit bíblico
  salta al versículo, uno del Factbook abre el artículo y uno del devocional abre
  el día. Todo funciona también sin servicio.
- **Cobertura**: el índice incluye Factbook (32 artículos, 19 con mapa) y devocional (366
  secciones), así que `scope=books` ya no devuelve vacío. `scope=factbook` y
  `scope=devotional` están disponibles.
- **Pruebas**: selftest del servidor **41/41**; **128 pruebas** unitarias/widget
  (parser local con NEAR/campos/frases, gateway local con pasaje, filtros,
  facetas y tipos, widget con filtros + grupos + salto a Factbook/devocional) y
  la integración Linux `offline_catalog_test.dart` recorre ambos paneles sin
  servicio. Las referencias bíblicas de las secciones también se indexan.

### Mejora sustancial 3 — Profundidad de contenido (aplicada, 2026-10-20)

La app deja de tener solo dos Biblias y contenido devocional: incorpora
traducciones y herramientas de estudio reales, todas de dominio público o con
licencia compatible, y las integra en los flujos existentes.

- **Traducciones**: ASV 1901 (inglés) y BLL (español latinoamericano) completas;
  la Biblioteca local pasa a **14 recursos** y la comparación de textos a nueve
  versiones. Ambas entran en el índice y en los filtros de idioma.
- **Comentario**: Matthew Henry conciso, **1 189 capítulos**; el índice es
  filtrable y el detalle carga solo el capítulo abierto. Se abre desde
  Biblioteca, Búsqueda, «Ideas» y las referencias del lector.
- **Diccionario**: Easton 1897, **3 961 entradas**; búsqueda por título, detalle
  perezoso y apertura del pasaje cuando la entrada lo cita. El panel es genérico
  (`CatalogResourcePanel`) y se comparte con el comentario.
- **Referencias cruzadas**: TSK, **29 055 versículos fuente y 376 083 enlaces**;
  se guardan en `cross_references` y se consultan con
  `GET /v1/cross-references` o con el índice local. «Ideas» combina TSK,
  Factbook, devocional y comentario; el panel de recursos abre la referencia en
  la Biblia por defecto.
- **Carga y rendimiento**: los recursos grandes usan `sections.json` (metadatos)
  + `sections/<id>.json` (bloques); el índice FTS5 indexa el texto completo sin
  cargar todos los cuerpos en memoria. El asset comprimido pasa a **48,8 MB**
  (índice descomprimido 87,8 MB, hash `7effef44a0faa8ea`).
- **Atribución**: cada manifiesto lleva `source` y `license`; la ficha del
  recurso muestra la licencia. Fuentes, fechas y salvedades en
  [`NOTICE.md`](../../NOTICE.md) y en
  [`05-fuentes-contenido.md`](05-fuentes-contenido.md).
- **Pruebas**: selftest **52/52**; suite completa de Flutter (panel del
  comentario/diccionario, TSK en el gateway, Ideas con comentario y referencias)
  e integraciones Linux `catalog_flow_test` y `offline_catalog_test` con los
  recursos nuevos.

### Mejora sustancial 5 — Mapas bíblicos offline (aplicada, 2026-10-20)

Los mapas se integran como contenido del catálogo, no como una herramienta
aparte: un bloque `map` puede aparecer en cualquier sección con bloques.

- **Definición única**: `catalog/config/maps.json` contiene 18 mapas con
  encuadre, título, pie y marcadores. `seed_m5.py` los copia a 19 artículos del
  Factbook; `build_catalog.py` los inserta en cuatro capítulos del comentario.
- **Renderizado**: `app/lib/maps/bible_map.dart` descarga una sola vez la
  geometría de Natural Earth (1:110m, dominio público), ajusta la relación de
  aspecto con `cos(latitud)` y pinta costas, lagos y una rejilla con
  `CustomPainter`. `InteractiveViewer` aporta zoom y desplazamiento.
- **Interacción**: los marcadores muestran el nombre y su referencia; al
  pulsarlos se abre el pasaje en el lector. La atribución de Natural Earth y
  OpenBible.info (CC BY 4.0) se muestra bajo cada mapa.
- **Pruebas**: `test/maps_test.dart` (parseo, renderizado, error y navegación),
  el mapa del Factbook en `m5_tools_test.dart` y el del comentario en
  `catalog_content_test.dart`. La integración con assets reales abre los mapas
  sin servicio.
