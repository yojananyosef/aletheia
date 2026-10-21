# app — Cliente Flutter (Aletheia)

Aplicación Flutter **para escritorio y web** de Aletheia, con catálogo de recursos desacoplado.

- **Estado:** M0–M6.5 completados y build web publicado. Incluye lector, catálogo local/remoto, búsqueda FTS5 con ámbitos de estudio, morfología, mapas, notas, comparación, Factbook, devocional, las seis herramientas de estudio (Atlas, Cursos, Documentos, Medios, Favoritos y Explorador de Salmos) y persistencia SQLite/IndexedDB.
- **Requisitos:** Flutter 3.47+ (instalado en `~/.local/share/flutter`), y para Linux desktop:
  `clang cmake ninja pkgconf gtk3` (cmake/ninja vía mise: `mise use -g cmake ninja`).

## Ejecutar

```bash
export PATH="$HOME/.local/share/flutter/bin:$PATH"
cd app
flutter run -d linux
```

Para navegador:

```bash
cd app
flutter run -d chrome
```

## Web

- **Compilación ligera:** `bash tool/build_web_release.sh`. Genera un `pubspec.yaml` temporal con solo mapas, `index.json`, `search.meta.json`, `map_sections.json`, RV1909 y morfología; el resto del catálogo se descarga de [`aletheia-mods`](https://github.com/yojananyosef/aletheia-mods). El resultado queda en `build/web`.
- **Despliegue:** el workflow de la raíz, `.github/workflows/pages.yml`, publica el build en GitHub Pages en cada push a `main`.
- **SQLite:** `web/sqlite3.wasm` (757.984 bytes) procede del release `sqlite3-3.7.1`; no se descarga en tiempo de ejecución.
- **Persistencia:** workspace, notas, favoritos y progreso de Cursos en SQLite (esquema **v5**) sobre IndexedDB (`aletheia_app`). El índice FTS5 se descarga comprimido, se descomprime en memoria al buscar por primera vez y queda en la caché del service worker.
- **Catálogo:** `lib/catalog/mods_catalog_source.dart` descarga los recursos con progreso y cancelación; `lib/catalog/catalog_asset_source.dart` abstrae assets y HTTP con respaldo local de RV1909/metadatos. En web, el modo `auto` usa el catálogo remoto y cae al núcleo empaquetado si no hay red.
- **PWA/offline:** `web/sw.js` es el único service worker (el build usa `--pwa-strategy=none` para no registrar el de Flutter). Se activa en cuanto el navegador lo registra (≈0,5 s local; 5–8 s desde la navegación en producción, porque el registro ocurre tras cargar el shell). Precarga en segundo plano 98 archivos (~20,5 MB) del shell esencial y cachea el catálogo. Se omiten los renderizadores opcionales (`skwasm`, `wimp`, `webparagraph`), que no usa el build. Tras la primera visita, recargar sin red mantiene la búsqueda, los libros ya descargados y las herramientas locales.
- **Búsqueda:** `BEFORE` se resuelve en el índice local (los términos deben aparecer en orden). Los ámbitos **Morfología**, **Multimedia** y **Mapas** usan `morphology.json` y `map_sections.json` y no descargan `search.sqlite.gz`; el teclado griego/hebreo inserta letras en la consulta. En la prueba en Chromium, `Vqp3ms` devolvió 21 códigos, Mapas listó 23 entradas y `principio BEFORE Verbo` devolvió 4 resultados (incluido Juan 1:1).
- **Limitación:** la primera búsqueda FTS sigue descargando ~48,8 MB y necesita ~190-250 MB de heap. En la URL publicada tardó ~10,5 s en escritorio y ~11,3 s en Chromium emulando un iPhone 13 (heap ~196 MB) el 2026-10-21; la recarga offline fue correcta en ambos. Safari/WebKit real sigue pendiente: el WebKit de Playwright no arranca en este entorno por dependencias del sistema.

## Herramientas de estudio (M6.5)

El menú **Herramientas** de la barra lateral y de la barra superior abre seis paneles propios:

- **Atlas** y **Medios** (`lib/maps/`): lista o galería de las **23 entradas** de `map_sections.json` (19 del Factbook y 4 del comentario), filtros por tipo, detalle con `BibleMap` (Natural Earth + OpenBible.info), favorito de mapa y apertura de la sección de origen.
- **Cursos** (`lib/courses/`): tres cursos con tres lecciones cada uno; el progreso se guarda en la tabla `course_progress` y cada lección abre su pasaje en el lector.
- **Documentos** (`lib/documents/`): tres guías propias (lectura, línea de tiempo y glosario) con navegación interna.
- **Favoritos** (`lib/favorites/`): alta por referencia (`Juan 3:16`), persistencia en `favorites`, apertura en el lector y borrado; la estrella del lector vive en la barra de ubicación. También se pueden guardar mapas.
- **Explorador de Salmos** (`lib/psalms/`): los 150 salmos de la RV1909 con clasificación propia por géneros, búsqueda, salmo del día y apertura en el lector.
- En ventanas estrechas, elegir una herramienta pliega la barra lateral antes de navegar; el rail se puede desplegar de nuevo con **Expandir barra lateral**.

La persistencia de Favoritos y del progreso de Cursos sube el esquema SQLite a **v5** (`favorites` y `course_progress`; ver `lib/core/database.dart`). Las pruebas están en `test/m6_tools_test.dart` (15, incluidas las seis herramientas en móvil) y `test/sqlite_persistence_test.dart` (5).

## Estructura

```
lib/
  main.dart                 # arranque + ProviderScope
  core/                     # tema, i18n, base SQLite, panel_meta
  references/               # parser de referencias bíblicas (ES/EN)
  shell/                    # sidebar, topbar, omnibox, menú Herramientas
  workspace/                # modelos, controlador, persistencia, tiles
  catalog/                  # modelos, gateway local/remoto, fuentes de assets
  reader/                   # lector: toolbars, cuerpo, índice, estudio
  library/ search/ notes/   # Biblioteca, Búsqueda, Notas
  panels/                   # Factbook, comparación, devocional, secciones
  courses/ documents/       # Cursos y Documentos propios
  favorites/                # Favoritos de pasajes y mapas (SQLite)
  maps/                     # Atlas/Medios, map_sections y BibleMap
  psalms/                   # Explorador de Salmos
  guides/ reading_plans/    # Estudio guiado, Planes
  dashboard/ assistant/     # Inicio y Study Assistant
  settings/                 # /settings
assets/catalog/             # RV1909, índice, metadatos y map_sections
test/                       # unitarias/widget, herramientas y persistencia
```

El contenido se genera desde el USFM de eBible.org con `catalog/tools/import_ebible_usfm.py`
(ver `catalog/tools/README.md`); en M2 lo servirá el servicio `catalog/` sin cambiar la UI.

## Arquitectura

Sigue la guía `flutter-apply-architecture-best-practices` (repo `flutter/agent-plugins`):

- **Modelos de dominio** (`workspace/models.dart`, `references/reference_parser.dart`): clases inmutables, sin dependencias de UI.
- **Capa de datos** (`workspace/persistence.dart`, `notes/notes_persistence.dart`, `favorites/favorites_persistence.dart`): los stores aíslan el acceso a SQLite (`aletheia.db`); la base usa migraciones versionadas (esquema v5).
- **"ViewModel"** (`workspace/workspace_controller.dart`): `WorkspaceController extends Notifier<WorkspaceState>` expone estado inmutable + comandos (`openTab`, `setLayout`, …).
- **Vistas** (`shell/`, `workspace/workspace_view.dart`, `panels/`): widgets sin lógica de negocio; leen estado y emiten comandos.

## Layout adaptativo

Sigue la guía `flutter-build-responsive-layout`; los errores de constraints se diagnostican con
`flutter-fix-layout-issues` (skills globales en `~/.agents/skills/`). Breakpoints en `core/theme.dart`,
evaluados sobre el ancho de **ventana** (no hardware):

| Ancho de ventana | Comportamiento |
| --- | --- |
| < 880 px | sidebar se colapsa a rail de iconos (sin cambiar la preferencia) |
| < 780 px | los tiles se apilan en una columna |
| < 760 px | el banner superior se oculta |
| ventana mínima | 560×420 (GTK); tests cubren 320–1532 px sin overflow |

## Pruebas

- `flutter test` — **173 pruebas** unitarias y de widgets (guía `flutter-add-widget-test`): parser de referencias y sintaxis FTS (`BEFORE`), layout de tiles y **ausencia de overflow** con ventanas de 320 a 1532 px, repositorio de documentos, lector, teclado griego/hebreo, ámbitos de búsqueda, morfología, mapas y las seis herramientas (Atlas, Cursos, Documentos, Medios, Favoritos y Salmos), incluida su navegación en móvil. El workflow `.github/workflows/desktop.yml` repite la suite en Linux, Windows y macOS y compila los tres escritorios.
- `flutter test integration_test -d linux` — prueba de integración sobre el binario real
  (guía `flutter-add-integration-test`): arranca la app completa (assets, `path_provider`,
  persistencia) y comprueba que el workspace se restaura en un segundo arranque
  (`integration_test/persistence_test.dart`); respalda y restaura el `workspace.json` real.
  Abre una ventana real y deja el bundle compilado con el entrypoint de prueba: después,
  reconstruir con `flutter build linux --debug` para relanzar la app.
- `flutter test test/reader_screens.dart` — herramienta de desarrollo: capturas PNG del lector
  (inicio, índice, historial) en `/tmp/opencode/reader-*.png` para revisión visual.
- **Web:** no se usa `flutter test --platform chrome` porque el harness no sirve bien los assets del catálogo. La comprobación se hace en Chromium contra `build/web` servido bajo `/aletheia/`: arranque, lector, búsqueda FTS5 remota (`principio` → 436 resultados), `principio BEFORE Verbo` → 4 resultados, morfología sin índice, mapas sin índice, teclado griego/hebreo, apertura de `bll/books/ISA.json.gz`, cancelación/reintento del índice, service worker, recarga offline y consola sin errores.

## Funcionalidad M1 (lector)

- Lector de la RV1909 (`bible.rv1909`): versículos numerados en párrafos justificados,
  capítulos con numeral grande, lectura continua (carga el siguiente capítulo/libro al
  llegar al final) y selección de texto.
- Toolbar primaria: atrás/adelante, **cambiar libro**, caja de referencia editable
  ("Juan 1:1", "Salmo 23", "sanjuan 3:16"; inválida = borde rojo) y modos
  (Inicio activo; Buscar/Notas/Formato/Vista/Más reservados a M2–M3).
- Toolbar secundaria (modo Inicio): **Índice** (drawer con árbol libro → capítulo,
  buscador y salto al capítulo), **Historial** (por pestaña, persistido en el
  workspace, con ◀/▶ y menú), steppers de capítulo, y botones de Análisis/Información
  reservados a M5.
- Barra de ubicación descartable con el libro actual.
- Notas al pie (popup al tocar el marcador) y referencias cruzadas navegables; en la
  RV1909 no hay notas/xrefs, así que se cubren con documentos sintéticos en tests
  (los modelos y el renderer ya los soportan).
- Itálicas de las adiciones del traductor (`\add`), p. ej. "las cosas de" en Abdías 6.

## Funcionalidad M0

- Workspace con presets de layout (`one|two|twoRows|three|four`), tiles con stack de pestañas.
- Menú de pestaña: duplicar / cerrar / cerrar a la derecha / cerrar otras / cerrar todas.
- Sidebar con navegación y quick actions; banner descartable; footer (settings/catálogo/colapsar).
- Omnibox: escribe una referencia ("Jn 1:1", "Romanos 8:28", "sanjuan 3:16") → abre pestaña de lectura;
  texto libre → abre pestaña de búsqueda.
- Persistencia del workspace (JSON en el directorio de soporte de la app).

Próximo paso: smoke manual en Windows/macOS (los builds y la suite ya pasan en CI) y mejoras opcionales (exportar/imprimir, respaldo sin cuenta y RAG local); los milestones cerrados están en `docs/spec/02-arquitectura-flutter.md`.
