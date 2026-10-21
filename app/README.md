# app — Cliente Flutter (Aletheia)

Aplicación Flutter **para escritorio y web** de Aletheia, con catálogo de recursos desacoplado.

- **Estado:** M1 (lector) completado — además de M0 (shell + workspace de tiles/pestañas + omnibox + persistencia con layout adaptativo): lector real de la RV1909 con índice, historial, caja de referencia, notas al pie y cross-refs.
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

- **Compilación ligera:** `bash tool/build_web_release.sh`. Genera un `pubspec.yaml` temporal con solo mapas, `index.json`, RV1909 y morfología; el resto del catálogo se descarga de [`aletheia-mods`](https://github.com/yojananyosef/aletheia-mods). El resultado queda en `build/web`.
- **Despliegue:** el workflow de la raíz, `.github/workflows/pages.yml`, publica el build en GitHub Pages en cada push a `main`.
- **SQLite:** `web/sqlite3.wasm` (757.984 bytes) procede del release `sqlite3-3.7.1`; no se descarga en tiempo de ejecución.
- **Persistencia:** workspace y notas en IndexedDB (`aletheia_app`). El índice FTS5 se descarga comprimido, se descomprime en memoria al buscar por primera vez y queda en la caché del service worker.
- **Catálogo:** `lib/catalog/mods_catalog_source.dart` descarga los recursos con progreso y cancelación; `lib/catalog/catalog_asset_source.dart` abstrae assets y HTTP con respaldo local de RV1909/metadatos. En web, el modo `auto` usa el catálogo remoto y cae al núcleo empaquetado si no hay red.
- **PWA/offline:** `web/sw.js` se activa en cuanto el navegador lo registra (≈0,5 s local; 5–8 s desde la navegación en producción, porque el registro ocurre tras cargar el shell). Precarga en segundo plano 97 archivos (20,4 MB) del shell esencial y cachea el catálogo. Se omiten los renderizadores opcionales (`skwasm`, `wimp`, `webparagraph`), que no usa el build. Tras la primera visita, recargar sin red mantiene la búsqueda y los libros ya descargados.
- **Limitación:** la primera búsqueda sigue descargando ~48,8 MB y necesita ~190-250 MB de heap. En la URL publicada tardó ~10,5 s en escritorio y ~11,3 s en Chromium emulando un iPhone 13 (heap ~196 MB) el 2026-10-21; la recarga offline fue correcta en ambos. Safari/WebKit real sigue pendiente: el WebKit de Playwright no arranca en este entorno por dependencias del sistema.

## Estructura (M1)

```
lib/
  main.dart                 # arranque + ProviderScope
  core/theme.dart           # tokens visuales + breakpoints de layout
  core/panel_meta.dart      # iconos por tipo de panel
  references/               # parser de referencias bíblicas (ES/EN)
  shell/                    # sidebar, topbar (banner), omnibox
  workspace/                # modelos, controlador, persistencia, vista de tiles
  catalog/                  # modelos del documento + DocumentRepository (M1: assets)
  reader/                   # panel del lector: toolbars, cuerpo, índice, cambiar libro
  panels/                   # panel host (placeholders + Settings + Search)
assets/catalog/rv1909/      # RV1909 (dominio público): manifest.json + books/<CODE>.json
test/                       # parser, layouts, repositorio de documentos y lector
```

El contenido se genera desde el USFM de eBible.org con `catalog/tools/import_ebible_usfm.py`
(ver `catalog/tools/README.md`); en M2 lo servirá el servicio `catalog/` sin cambiar la UI.

## Arquitectura

Sigue la guía `flutter-apply-architecture-best-practices` (repo `flutter/agent-plugins`):

- **Modelos de dominio** (`workspace/models.dart`, `references/reference_parser.dart`): clases inmutables, sin dependencias de UI.
- **Capa de datos** (`workspace/persistence.dart`): `WorkspaceStore` aísla el acceso a disco (JSON hoy; drift/SQLite cuando lleguen notas en M4).
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

- `flutter test` — pruebas unitarias y de widgets (guía `flutter-add-widget-test`): parser de referencias,
  layout de tiles y **ausencia de overflow** con ventanas de 320 a 1532 px, repositorio de documentos
  (conteos y textos de la RV1909) y lector (navegación, índice, historial, steppers, notas/xrefs sintéticas).
- `flutter test integration_test -d linux` — prueba de integración sobre el binario real
  (guía `flutter-add-integration-test`): arranca la app completa (assets, `path_provider`,
  persistencia) y comprueba que el workspace se restaura en un segundo arranque
  (`integration_test/persistence_test.dart`); respalda y restaura el `workspace.json` real.
  Abre una ventana real y deja el bundle compilado con el entrypoint de prueba: después,
  reconstruir con `flutter build linux --debug` para relanzar la app.
- `flutter test test/reader_screens.dart` — herramienta de desarrollo: capturas PNG del lector
  (inicio, índice, historial) en `/tmp/opencode/reader-*.png` para revisión visual.
- **Web:** no se usa `flutter test --platform chrome` porque el harness no sirve bien los assets del catálogo. La comprobación se hace en Chromium contra `build/web` servido bajo `/aletheia/`: arranque, lector, búsqueda FTS5 remota (`principio` → 436 resultados), apertura de `bll/books/ISA.json.gz`, cancelación/reintento del índice, service worker, recarga offline y consola sin errores.

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

Próximos milestones (ver `docs/spec/02-arquitectura-flutter.md`): M2 catálogo v1 + Library + Search.
