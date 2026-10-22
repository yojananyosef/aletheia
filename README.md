# Aletheia (Flutter) — lector bíblico para escritorio y web

Lector bíblico con **catálogo de recursos desacoplado**, implementado en **Flutter** para Linux/Windows/macOS y web. Aletheia se inspira en los patrones de UX de las aplicaciones web modernas de estudio bíblico, sin copiar contenido licenciado ni activos de terceros.

> **Alcance:** solo se replican funcionalidad y patrones de UX. El contenido licenciado (ESV, NIV, etc.), los formatos propietarios, las marcas y los activos originales **no** se copian. El catálogo se alimenta con contenido de dominio público, CC BY, CC BY-SA y propio.

## Estado

- [x] **Fase 1 — Reconocimiento público** (Free Edition): shell, workspace de tiles, lector, herramientas, store, arquitectura de red.
- [x] **Fase 2 — Análisis autenticado** (2026-10-18): Library personal (170 recursos), Search v2 + Synopsis IA, lector RVR60, Study Assistant (research mode), Notes, Factbook, devocional, Text Comparison.
- [x] **Fase 3 — UX detallada** (recon 2026-10-19): paneles del lector (Home/Formatting/View con Reformat/Markers/Paged view), drawers (Contents/Insights/Info/History), menús de panel/pestaña, overlays de sidebar (Tools/Guided study/Layouts/More options), omnibox, Change book, Store y `/settings`. Lo implementado quedó cerrado en M0–M6, los paquetes A–E y el paquete de paridad 1; la red autenticada y la accesibilidad/rendimiento medido siguen como mejoras opcionales.
- [x] **Fase 4 — Spec & arquitectura** (2026-10-18): inventario funcional priorizado (`docs/spec/01`), arquitectura Flutter (`docs/spec/02`) y contrato del catálogo v1 (`docs/spec/03`).
- [x] **Fase 5 — Implementación (2026-10-20):** **M0–M6 ✅** — shell + workspace de tiles/pestañas + omnibox + persistencia; lector de la RV1909 y la KJV; catálogo v1 + Biblioteca + Búsqueda; Formatting/View + Ajustes + i18n; Notas; Comparación, Factbook, Devocional y diseños guardados; e Ideas/Información, Marcadores, Herramientas, Estudio guiado, Planes de lectura, Inicio y Asistente. Acabado visual **A–E ✅** (repaso contra el original). **Autonomía local ✅**: nueve Biblias (incluidos TAHOT y TAGNT), léxico Strong, comentario, diccionario, devocional, Factbook e índice FTS5 van empaquetados; Biblioteca, lector, comparación y Búsqueda funcionan sin arrancar el servicio. **Búsqueda de estudio ✅**: `NEAR`, `WITHIN`, `BEFORE` (orden de términos en el índice local), campos (`bible:`, `type:`, `language:`, `book:`), filtros, facetas, agrupación por recurso y salto a comentario, diccionario, Factbook/devocional. Los ámbitos **Morfología**, **Multimedia** y **Mapas** funcionan sin descargar el índice FTS5; el teclado griego/hebreo inserta letras en la consulta. **Profundidad de contenido ✅**: ASV 1901, BLL, SBLM, BES y VBL; textos originales TAHOT/TAGNT con Strong, morfología y léxico; comentario conciso de Matthew Henry, diccionario de Easton y 376 083 referencias cruzadas del TSK, con panel propio y apertura desde Ideas, Búsqueda y Biblioteca. **Paridad 1 ✅**: conjuntos de vínculos A–F entre paneles bíblicos, Tienda local real, pantalla completa por panel y tema claro/oscuro/sistema persistido. **Mapas bíblicos ✅**: 18 mapas esquemáticos offline (Factbook y comentario) con Natural Earth y OpenBible.info; la búsqueda por Mapas/Multimedia lista las **23 entradas** de mapa (19 del Factbook + 4 del comentario).
- [x] **Fase 6 — Web y GitHub Pages** (2026-10-20): compilación web en `app/web/`, persistencia del workspace y las notas en IndexedDB, lector y búsqueda FTS5 con SQLite WASM, catálogo desacoplado en [`aletheia-mods`](https://github.com/yojananyosef/aletheia-mods), descarga asíncrona con progreso/cancelación, caché del service worker y despliegue automático con GitHub Actions. La web baja de **136 MB a 45 MB**; el escritorio conserva el catálogo completo empaquetado.
- [x] **Fase 7 — Herramientas de estudio web** (2026-10-21): Atlas y Medios con los 23 mapas del catálogo, Cursos con progreso persistido, Documentos propios, Favoritos de pasajes y mapas, y Explorador de Salmos con clasificación por géneros. El menú **Herramientas** ya abre las seis herramientas; el esquema SQLite sube a **v5** (`favorites` y `course_progress`).
- [x] **Fase 8 — Escritorio Windows/macOS** (2026-10-21): el workflow [`desktop.yml`](.github/workflows/desktop.yml) compila Linux, Windows y macOS en CI y ejecuta la suite de pruebas en los tres sistemas; los builds de Windows y macOS pasan. En macOS se añadió `com.apple.security.network.client` al sandbox para que el catálogo remoto y el servicio local funcionen. El smoke manual con ventana real queda pendiente en equipos de esas plataformas.
- [x] **Fase 9 — Panel de pestañas, resaltados y binario Linux** (2026-10-21): las pestañas nuevas abren en el panel correcto (el chrome usa el primer panel vacío; desde dentro de un panel se abre en el otro, sin tapar el origen) y se **arrastran** entre paneles. Los resaltados se **actualizan in situ** en vez de apilarse, el menú de selección marca el color activo y ofrece **Quitar resaltado**; además cada lector pinta sólo las anotaciones ancladas a su recurso (los «resaltados fantasma» de otra versión ya no aparecen ni bloquean la acción). El binario de **Linux x64** probado en este equipo se publica en **GitHub Releases** con [`release.yml`](.github/workflows/release.yml) al etiquetar (`v*`).
- [ ] **Siguiente:** smoke manual en Windows/macOS y mejoras opcionales (exportar/imprimir, respaldo/sincronización sin cuenta y RAG local).

## Autonomía local y profundidad

- `app/assets/catalog/` incluye **nueve Biblias** (RV1909, KJV, ASV, BLL, SBLM, BES, VBL, TAHOT y TAGNT), el **léxico Strong**, el comentario de Matthew Henry, el diccionario de Easton, el devocional y el Factbook. El texto original enlaza cada palabra con Strong, morfología y léxico; las fuentes y licencias están en [`NOTICE.md`](NOTICE.md).
- `search.sqlite.gz` (48,8 MB) es un índice FTS5 precompilado de **272 503 entradas** (248 870 versículos + 23 633 secciones no bíblicas) y **376 083 referencias cruzadas**; se extrae una vez a `catalog.search.<hash>.sqlite` y se abre en solo lectura. La búsqueda local acepta `"frases"`, `AND`/`OR`/`NOT`, `NEAR`, `WITHIN n WORDS`, `BEFORE` (solo índice local), campos como `bible:"Jn 3"` y filtros `type`/`language`/`book`. Los ámbitos Morfología, Multimedia y Mapas se resuelven con `morphology.json` y `map_sections.json`, sin abrir el índice.
- El comentario y el diccionario usan un índice de metadatos y un archivo por entrada (`sections/`), que se carga solo al abrirla. El léxico Strong usa secciones embebidas y se abre desde el popover de estudio de cada palabra. Las referencias bíblicas del cuerpo abren el lector.
- Los **18 mapas** se definen en `catalog/config/maps.json` y se dibujan localmente con `app/lib/maps/bible_map.dart`: geometría de Natural Earth (dominio público), coordenadas de OpenBible.info (CC BY 4.0), zoom/desplazamiento y marcadores que abren su pasaje. No hay teselas ni red; la atribución aparece al pie de cada mapa.
- Los libros de las Biblias y los índices de secciones se guardan como `.json.gz`; la app los descomprime en memoria. Los assets ocupan **92 MB**, de los cuales 48,8 MB son el índice FTS5 comprimido; la geometría de los mapas añade unos 171 KB.
- En escritorio, el modo `auto` usa el servicio si está disponible y cae al índice empaquetado si no; `local` no necesita Python. En web, `auto` usa `aletheia-mods` y conserva RV1909/metadatos como respaldo inmediato. En Ajustes el estado aparece como **Modo local**.
- Regeneración: `python3 catalog/tools/import_stepbible.py --all`, `python3 catalog/tools/import_strongs_lexicon.py`, `python3 catalog/tools/import_content.py --all`, `python3 catalog/tools/build_catalog.py`, `python3 catalog/tools/seed_m5.py` y `python3 catalog/tools/sync_app_catalog.py`.
- Verificación: `flutter analyze` limpio; suite completa de **182 pruebas** unitarias/widget (incluye mapas, teclados, ámbitos de búsqueda, las seis herramientas, el destino/arrastre de pestañas y el comportamiento de resaltados por recurso) y las integraciones Linux `persistence_test`, `catalog_flow_test`, `offline_catalog_test` y `panels_highlights_flow_test`. La autoprueba del servicio cubre **52/52** comprobaciones.

## Web

La versión web está en **<https://yojananyosef.github.io/aletheia/>**. Es la misma aplicación Flutter, sin el servicio Python local. El catálogo completo vive en **<https://yojananyosef.github.io/aletheia-mods/v1/>**: la web descarga los recursos que necesita, muestra el progreso y los cachea para volver a usarlos sin red.

- **Catálogo remoto:** [`aletheia-mods`](https://github.com/yojananyosef/aletheia-mods) publica `mods.json`, `index.json`, `search.meta.json`, `search.sqlite.gz`, `morphology.json` y los 14 recursos. GitHub Pages los sirve con CORS y `Accept-Ranges`.
- **Build ligero:** `app/tool/build_web_release.sh` genera un `pubspec.yaml` temporal que solo empaqueta mapas, `index.json`, `search.meta.json`, `map_sections.json`, RV1909 y morfología. El resto se descarga. El build pasa de **136 MB a 45 MB** (2,4 MB de catálogo empaquetado).
- **Persistencia:** SQLite WASM sobre `IndexedDbFileSystem` (base `aletheia_app`, esquema **v5**). El workspace, las notas, los favoritos y el progreso de Cursos sobreviven a una recarga; el índice de búsqueda se descarga comprimido, se descomprime con `DecompressionStream` y se monta en un VFS de solo lectura.
- **Búsqueda:** la primera búsqueda FTS descarga `search.sqlite.gz` (~48,8 MB) con un banner de progreso y botón **Cancelar**; Morfología y Mapas no descargan el índice. Si se cancela o falla, «Reintentar» vuelve a empezar. En la prueba real del 2026-10-21 tardó ~10,5 s en escritorio y ~11,3 s en móvil emulado; el service worker conserva el índice y los libros en caché.
- **PWA/offline:** `app/web/sw.js` se activa en cuanto el navegador lo registra (≈0,5 s local; 5–8 s desde la navegación en producción) y precarga en segundo plano el shell esencial (98 archivos, ~20,5 MB: CanvasKit base/Chromium, `main.dart.js`, RV1909, mapas, morfología y `map_sections.json`). El catálogo se cachea con URLs versionadas (`?v=<mods.version>`). Tras una primera visita se puede recargar sin red y repetir la búsqueda o abrir un libro ya descargado. El service worker se registra desde `app/web/index.html`.
- **Build:** requiere Flutter 3.47.7 y `app/web/sqlite3.wasm` (del paquete `sqlite3` 3.7.1).
  ```bash
  cd app
  flutter pub get
  bash tool/build_web_release.sh
  ```
  Para apuntar a otra copia del catálogo: `ALETHEIA_MODS_URL=https://... bash tool/build_web_release.sh`.
- **Despliegue:** `.github/workflows/pages.yml` ejecuta el build ligero en cada push a `main` y publica `app/build/web` con `upload-pages-artifact` y `deploy-pages`. GitHub Pages sirve el sitio como artefacto estático; no ejecuta `catalog/server`. Pages debe habilitarse una vez en **Settings → Pages → GitHub Actions** (ya está habilitado en este repositorio).
- **Actualizar el catálogo:** publicar `app/assets/catalog/` con el script de `aletheia-mods`; después, la web detecta la nueva versión de `mods.json` y revalida el índice la próxima vez.

## Estructura

- `NOTICE.md` — fuentes, licencias y atribución del contenido
- `docs/spec/` — inventario funcional, arquitectura Flutter, contrato del catálogo y fuentes
- `app/` — aplicación Flutter (escritorio con catálogo completo; web con catálogo remoto y núcleo mínimo)
- [`aletheia-mods`](https://github.com/yojananyosef/aletheia-mods) — artefactos publicados del catálogo (`docs/v1/`, `mods.json`, índice FTS5)
- `catalog/` — servicio de catálogo desacoplado (API de recursos/metadatos/contenido) y herramientas de ingesta/sincronización

## Método de análisis

Reconocimiento realizado con **REA** (`rea` MCP) sobre Chromium vía CDP (`capture_browser_scenario`), con evidencia exportable en bundles `*.reabundle` (fuera de git).

- Fase 1: modo *launch* (perfil temporal, sin cuenta).
- Fase 2: modo *connect* sobre Chromium con perfil persistente y sesión del servicio de referencia iniciada por el usuario (CDP `127.0.0.1:9222`, `service_workers: allow`).
