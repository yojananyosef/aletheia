# catalog — Servicio de catálogo desacoplado

Servicio/API que sirve el **catálogo de recursos** (metadatos, TOC, contenido en formato propio) desacoplado de la app, con una separación estricta entre cliente, API y recursos.

## Responsabilidad

- Catálogo: metadatos de recursos, categorías/facetas y orden (lo que consume la Biblioteca)
- Contenido: manifiesto, divisiones y secciones en el formato del contrato (`docs/spec/03-contrato-catalogo.md`)
- Búsqueda: índice FTS5 por recurso (sintaxis v1 — ver §7 del contrato)
- Versionado e independencia de la app: nuevos recursos sin actualizar el cliente

Fuentes de contenido: dominio público, CC BY, CC BY-SA y propio.

## Estructura

```
config/resources.json         # qué recursos entran al catálogo (fuente + metadatos)
config/maps.json              # 18 mapas: encuadre, marcadores y referencias
tools/import_ebible_usfm.py   # USFM de eBible.org → formato de app (manifiesto + books/)
tools/stepbible_common.py     # utilidades y morfología de STEPBible
tools/import_stepbible.py     # TAHOT/TAGNT → formato de app con Strong y morfología
tools/import_strongs_lexicon.py # léxico Strong hebreo/griego (TBESH/TBESG + PD)
tools/import_content.py       # comentario, diccionario y TSK desde fuentes públicas
tools/build_catalog.py        # construye data/ a partir de config/resources.json
tools/seed_m5.py              # añade devotional.daily y factbook.core (M5, 32 artículos y 19 mapas)
tools/sync_app_catalog.py     # sincroniza data/ → assets de la app + índice FTS5 comprimido
server/catalog_server.py      # servicio HTTP v1 (stdlib, sin dependencias)
server/selftest.py            # autoprueba end-to-end del servicio (puerto efímero)
data/                         # artefactos construidos (ignorado en git)
sources/                      # fuentes crudas descargadas (ignorado en git)
```

## Construir y ejecutar

```bash
# 0) Contenido de profundidad (mejora 3): descarga y normaliza el comentario
#    de Matthew Henry, el diccionario de Easton y las referencias del TSK.
#    También se ejecuta automáticamente si build_catalog.py no encuentra
#    el recurso declarado con `ingest.importer`.
python3 catalog/tools/import_content.py --all

# 0b) Textos originales y léxico: descarga TAHOT/TAGNT de STEPBible y el
#     módulo StrongsHebrew de CrossWire; genera bible.tahot, bible.tagnt y
#     lexicon.strongs en catalog/sources/ y catalog/data/.
python3 catalog/tools/import_stepbible.py --all
python3 catalog/tools/import_strongs_lexicon.py

# 1) Construir los datos del catálogo (desde la raíz del repo).
#    RV1909 se toma de los assets de la app; KJV, ASV, BLL, SBLM, BES y VBL se
#    descargan de eBible.org la primera vez y quedan en catalog/sources/.
python3 catalog/tools/build_catalog.py

# 1b) Recursos propios de M5 (devocional diario y Factbook): actualiza
#     catalog/data/ y los assets de la app (app/assets/catalog/). Reejecutable.
python3 catalog/tools/seed_m5.py

# 1c) Autonomía local: copia los catorce recursos a los assets de la app y
#     empaqueta el índice FTS5 comprimido (con hash) para el modo sin servicio.
python3 catalog/tools/sync_app_catalog.py

# 2) Autoprueba del servicio (levanta un servidor en un puerto efímero).
python3 catalog/server/selftest.py            # 52/52

# 3) Arrancar el servicio.
python3 catalog/server/catalog_server.py --port 8787

# 4) Sonda rápida del contrato.
curl -s http://127.0.0.1:8787/v1/health
curl -s 'http://127.0.0.1:8787/v1/search?q=%22In%20the%20beginning%22&scope=bible&pageSize=3'
# Búsqueda dentro de un recurso (la usa el modo «Buscar» del panel del lector):
curl -s 'http://127.0.0.1:8787/v1/search?q=principio&resource=bible.rv1909&pageSize=3'
```

La app apunta por defecto a `http://127.0.0.1:8787`; en **Ajustes → Catálogo** se puede cambiar la dirección y alternar entre `auto` (servicio con respaldo local), `local` (solo assets, con búsqueda FTS5 incluida) y `remote` (solo servicio). El modo local no necesita el servicio para Biblioteca, lector, comparación ni Búsqueda.

## Estado

- **M1 (lector):** la RV1909 está empaquetada como assets de la app (`app/assets/catalog/rv1909/`), generada con [`tools/import_ebible_usfm.py`](tools/README.md). El cliente la consume con `DocumentRepository` con el formato del contrato, sin saber de dónde viene.
- **M2 (catálogo v1):** el servicio sirve las nueve Biblias (RV1909, KJV, ASV, BLL, SBLM, BES, VBL, TAHOT y TAGNT) con lista de recursos + facetas, manifiesto, divisiones, secciones, búsqueda FTS5 (con `resource=` para buscar dentro de un recurso) y `ETag`. Detalle en `docs/spec/03-contrato-catalogo.md` §7. La app añade la capa `lib/catalog/` (cliente + gateway + repositorios) y las vistas Biblioteca y Búsqueda reales.
- **M5 (herramientas):** `devotional.daily` (366 secciones fechadas `dayofyear.MM.DD` con 30 lecturas propias y versículo de la RV1909) y `factbook.core` (32 artículos propios, 19 con mapa) con las secciones **embebidas** en `sections.json`; el servicio las sirve en memoria y el stream devuelve solo metadatos. La app añade los paneles de devocional, Factbook y comparación de textos, y los diseños guardados en local. Los 18 mapas de `config/maps.json` se copian a 19 artículos del Factbook y a `JHN.3`, `LUK.2`, `MAT.2` y `ACT.9` del comentario; la app los dibuja offline con Natural Earth y OpenBible.info. Detalle en `docs/spec/01-inventario-funcional.md` §13 y `docs/spec/03-contrato-catalogo.md` §7.
- **Mejora 3 (profundidad):** comentario de Matthew Henry (1 189 capítulos), diccionario de Easton (3 961 entradas) y 376 083 referencias cruzadas del TSK. **Mejora 4 (originales):** TAHOT y TAGNT con Strong desambiguado y morfología, más un léxico de 18 085 entradas; el lector muestra un popover de estudio y abre el léxico encuadrado en la palabra. El comentario y el diccionario usan índice + `sections/<id>.json`; el TSK vive en la tabla `cross_references` y se sirve en `GET /v1/cross-references`. `selftest.py` sube a 52 comprobaciones. Fuentes y licencias en `NOTICE.md` y `docs/spec/05-fuentes-contenido.md`.

**Nota de implementación:** el diseño original proponía Dart + shelf (`docs/spec/02-arquitectura-flutter.md` §7); la v1 se implementó en **Python 3 (stdlib) + sqlite3/FTS5** para no añadir dependencias ni duplicar el modelo de documento en dos lenguajes. El contrato HTTP es el mismo y el cliente de la app no cambia si se reescribe el servicio.

### Autonomía local (mejora 1)

`app/assets/catalog/` incluye los **14 recursos** (nueve Biblias, dos diccionarios, comentario, devocional y Factbook) y un **índice FTS5 precompilado** (`search.sqlite.gz`, 48,8 MB; 272 503 entradas: 248 870 versículos + 23 633 secciones no bíblicas; 376 083 referencias cruzadas). Los libros y los índices de secciones se guardan comprimidos como `.json.gz`. El índice se extrae en el primer uso a `catalog.search.<hash>.sqlite` en el directorio de datos y la app lo abre en solo lectura. Así la Biblioteca, el lector, la comparación, los paneles de comentario/diccionario, «Ideas» y la Búsqueda funcionan **sin arrancar el servicio**; la búsqueda de estudio incluye `NEAR`, `WITHIN`, campos (`bible:`, `type:`, `language:`, `book:`) y facetas. `sync_app_catalog.py` mantiene sincronizados contenido e índice, y el hash del índice evita reutilizar copias viejas tras una actualización.

### Fuentes y licencias

| Recurso | Fuente | Licencia |
|---|---|---|
| RV1909, KJV, ASV, BLL, SBLM, BES | eBible.org (USFM) | Dominio público |
| VBL | eBible.org (USFM) | CC BY-SA 4.0 |
| TAHOT, TAGNT, TBESH/TBESG | STEPBible.org / Tyndale House Cambridge | CC BY 4.0 |
| Léxico Strong (definiciones hebreas) | CrossWire StrongsHebrew | Dominio público |
| Matthew Henry conciso | `lyteword/mhenry-concise` (Markdown) | CC0-1.0; texto original PD |
| Easton 1897 | `JWBickel/BibleDictionaries` (JSONL) | Texto original PD |
| TSK | `ariseshinestudio/TSK` / JustVerses.com | Dominio público |
| Geometría de mapas | Natural Earth (`ne_110m_land`, `ne_110m_lakes`) | Dominio público |
| Coordenadas de lugares | OpenBible.info Bible Geocoding | CC BY 4.0 |
| Devocional, Factbook y mapas (selección y encuadre) | Aletheia | Propio |

La atribución completa, las URLs y las salvedades (incluida la transcripción de Easton y el borrador BLL) están en [`../NOTICE.md`](../NOTICE.md) y [`../docs/spec/05-fuentes-contenido.md`](../docs/spec/05-fuentes-contenido.md). Los manifiestos de cada recurso guardan `source` y `license`.
