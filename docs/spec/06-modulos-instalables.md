# Catálogo desacoplado en módulos instalables (fase actual)

Principio: **la app no auto-instala nada**. El contenido empieza a ser un
conjunto de módulos que el usuario elige desde la Tienda; la app de escritorio
es ligera (solo lo esencial empaquetado) y arranca rápido, y la web funciona
con descarga bajo demanda + service worker.

## 1. Manifiesto `mods.json` (esquema 2) — `aletheia-mods`

`aletheia-mods` publica en Pages `docs/v1/mods.json` con la misma estructura de
recurso del contrato v1 (`docs/spec/03-contrato-catalogo.md`) y, además, el
listado verificable de archivos:

```jsonc
{
  "schema": 2,
  "version": "2026.05",          // versión del catálogo publicado
  "publishedAt": "…",
  "resources": [
    {
      "id": "bible.kjv",
      "type": "bible",
      "title": "…", "language": "en",
      "size": 2140000,           // suma de files[].bytes (para la Tienda)
      "files": [                 // obligatorio en v2
        { "path": "kjv/manifest.json", "bytes": 5612, "sha256": "…" },
        { "path": "kjv/books/GEN.json.gz", "bytes": …, "sha256": "…" }
      ]
    }
  ]
}
```

- Cada archivo se declara con **tamaño y sha256**; la app verifica la descarga
  y rechaza el módulo completo si algo no coincide
  (`ModuleVerificationException`).
- El índice de búsqueda FTS5 es el módulo especial `catalog.search`
  (`search.sqlite.gz` + `search.meta.json`, en la raíz del catálogo): así el
  manifiesto y el índice siempre viajan juntos (evita hash mismatch).
- Los metadatos compartidos (`index.json`, `morphology.json`,
  `map_sections.json`) **no son módulos**: siempre van empaquetados con la
  app; el espejo estático queda en `docs/v1/` para la web.

## 2. Instalación en disco (`app/lib/catalog/install/`)

- **`mods_manifest.dart`**: modelos (`ModuleFile`, `ModuleEntry`,
  `CatalogModulesManifest`) + mapeo bidireccional ruta↔módulo
  (`idForPath` / `dirFor`; las Bibliias nuevas salen por regla
  `bible.<carpeta>` sin tocar código).
- **`modules_store.dart`** (`ModulesStore`): descarga archivo por archivo a
  `<datos>/modules/<ruta relativa del catálogo>` (escritura atómica
  `.part` → renombrar), verifica sha256, muestra progreso
  (`transfers` ValueNotifier) y permite cancelar (`cancel` cierra el cliente
  HTTP y aborta el chunk en vuelo). El estado persiste en
  `<datos>/modules/modules.json` (índice de módulos: id, versión, archivos,
  bytes, fecha) escrito atómicamente. `install()` es idempotente (reinstalar
  = actualizar) y falla en su tarjeta, no en un toast.
- **`disk_catalog_source.dart`** (`DiskCatalogSource`): lee módulos
  instalados con las mismas rutas lógicas que el catálogo empaquetado.
- **`routing_catalog_source.dart`** (`RoutingCatalogSource`): router de
  escritorio por ruta — módulo instalado → empaquetado → *no instalado*.
  Los empaquetados (enfrío sin red ni instalación) están en
  `kBundledCatalogModules` (`bible.rv1909`, `lexicon.strongs`,
  `devotional.daily`, `factbook.core`) en el bundle publicado (slim) y el
  árbol entero en desarrollo/pruebas:`app/tool/slim_release_bundle.py`
  recorta el bundle compilado del release; el `search.meta.json` y el
  índice FTS5 viajan como el módulo `catalog.search` (coherencia
  meta-hash ↔ índice).
- **`module_install_card.dart`**: tarjeta compartida Lector/Búsqueda/Tienda
  con estado instalando (barra + bytes + cancelar), error reintente y `onDone`
  para que la vista reintente la lectura al terminar.

## 3. Cableado por plataforma (`app/lib/catalog/catalog_source_providers.dart`)

| provider | comportamiento |
|---|---|
| `modsCatalogSourceProvider` | solo web (lectura remota); escritorio `null` |
| `catalogTransferProvider` | banner de descarga del índice (web) |
| `catalogModulesManifestProvider` | Tienda: listado remoto; vía el store propio |
| `modulesStoreProvider` | `main()` lo crea en escritorio; `null` en web y tests |
| `catalogAssetSourceProvider` | web: `mods → assets`; escritorio: `RoutingCatalogSource` |

`main()` (solo `!kIsWeb`) crea un `ModsCatalogSource` + `ModulesStore` con
`<appSupport>/modules` y los expone por override, estilo *stores*. En web no
hay tienda instalable: el service worker cachea lo descargado al usarlo.

## 4. Bundle slim (escritorio y `pubspec.yaml`)

Empaquetado: `assets/maps/`, `index.json`, `map_sections.json`,
`morphology.json`, `rv1909/` y `lexicon.strongs/`. El resto (8 Bibliias,
TAHOT/TAGNT, comentario, diccionario, devocional, Factbook, FTS5) solo vive
en `aletheia-mods`. `tool/build_web_release.sh` reescribe el bloque de assets
propio de la web y no se toca.

## 5. Lecturas sobre contenido ausente (UX)

- Excepciones tipadas desde la fuente (`CatalogNotInstalledException`,
  `FileNotFoundError`).
- **Lector**: si el recurso existe pero el libro no (p. ej. Génesis en TAGNT),
  el precheck del manifest evita «Unable to load asset» y muestra
  «Génesis no está disponible en …» con CTA que abre el recurso equivalente
  (TAHOT/TAGNT) en el mismo pasaje.
- **Búsqueda**: sin módulo `catalog.search` instalado, la tarjeta ofrece
  instalarlo (hint: la búsqueda en frío depende del índice).
- **Tienda**: chips `Instalado` / `Actualización disponible` /
  `No instalado`, instalar con progreso y desinstalar con confirmación.

## 6. Pruebas

- `test/catalog_modules_test.dart`: store contra HTTPServer efímero
  (instalar, sha corrupto, cancelar a mitad, sin manifiesto, desinstalar,
  persistencia del índice) + mapeos del router.
- `test/reader_catalog_states_test.dart`: tarjetas del lector (libro
  ausente + CTA equivalente; módulo ausente).
- `test/support/catalog_fixtures.dart`: `DiskCatalogSource` sobre
  `app/assets/catalog` para los tests de contenido (la copia íntegra sigue
  ahí como material de mods).
- `integration_test/support/catalog_fixture.dart`: mismo override para los
  flows de Linux. `catalog_flow_test` sigue necesitando el servicio local
  con `catalog/data` completo (no versionado).

## 7. Publicación

`aletheia-mods` (Pages) se actualiza con `tools/import_assets.py` + commit
del `mods.json` verificado. La app comprueba `version` para el chip
«Actualización disponible» y reinstala el módulo al pulsar el botón.
