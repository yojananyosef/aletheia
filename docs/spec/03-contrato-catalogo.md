# Contrato del catálogo desacoplado (v1)

Principios: **la app puede incluir un subconjunto de contenido de dominio público, CC BY o CC BY-SA, o propio** para funcionar sin servicio; el resto de recursos, índices y anotaciones vive detrás de esta API. No se admite contenido NC ni ND. La API es offline-friendly (caché local) y versionada (`/v1`).

## 1. Modelo de dominio

```jsonc
// Resource (manifiesto)
{
  "id": "bible.rv1909",                    // slug estable  <tipo>.<slug>
  "type": "bible",                         // bible|commentary|dictionary|encyclopedia|devotional|dataset|guide|workflow|document
  "title": "Reina-Valera 1909",
  "subtitle": "Spanish Bible",
  "authors": ["Reina, Casiodoro de", "Valera, Cipriano de"],
  "language": "es",
  "publisher": "Public domain",
  "edition": "1909",
  "license": { "kind": "public-domain", "text": "Dominio público" },
  "cover": "/assets/bible.rv1909/cover.jpg",
  "tags": ["Bible", "Spanish"],
  "attributes": { "versification": "standard", "bookOrder": "protestant66", "calendar": null },
  "stats": { "sections": 1189, "verses": 31102, "footnotes": 0, "crossrefs": 2100 },
  "updatedAt": "2026-10-18T00:00:00Z"
}
```

- **Divisiones** (árbol): `book → chapter` (Biblia), `month → day` (devocional), `chapter → section` (libro). El comentario y el diccionario usan `sections.json` como índice plano, sin árbol de divisiones.
- **Sección**: unidad renderizable (capítulo o artículo).

```jsonc
// Section (contenido)
{
  "id": "JHN.1",
  "resourceId": "bible.rv1909",
  "title": "San Juan 1",
  "blocks": [
    { "type": "heading", "text": "El Verbo hecho carne" },
    { "type": "chapterNumber", "value": 1 },
    { "type": "verseGroup", "verses": [
      { "n": 1, "inlines": [ { "t": "text", "v": "En el principio era el Verbo…" },
                             { "t": "footnote", "id": "fn.JHN.1.6a" },
                             { "t": "xref", "ref": "GEN.1.1-3", "label": "Gn 1:1-3" } ] }
    ]}
  ]
}
```

- **Bloques**: `heading` (con `style` `section|psalmTitle`), `chapterNumber`, `verseGroup` (con `style` `paragraph|poetry|list` e `indent`; las continuaciones de versículo tras un salto se expresan repitiendo el mismo `n`, que solo se numera la primera vez), `paragraph`, `poetry`, `list`, `table`, `figure`, `rule`, `map`.
- **Inline**: `text` (`v`, con `style` opcional `italic|red`), `span` (`v` + `style`, para adiciones), `footnote` (`id` + `label` opcional), `xref` (`ref` canónica + `label`), `line` (salto de poesía).
- **Notas**: el texto de las notas vive en `footnotes` de la sección (`{id: {label, text}}`); el inline solo lleva la referencia. Los números de versículo **no** son inlines: el lector los dibuja desde `n`.
- Ejemplo generado (RV1909, M1): `{"t":"span","style":"italic","v":"las cosas de"}`.

### Secciones embebidas (M5)

Los recursos pequeños (devocional fechado y Factbook) guardan **todas** sus secciones en un único `sections.json` (`{"resourceId": …, "title": …, "sections": [ … ]}`) en lugar de un archivo por sección:

- `/v1/resources/{id}/sections/{sectionId}` sirve el bloque desde memoria (mismo formato de `Section`).
- El stream `/v1/resources/{id}/sections?from=&limit=` devuelve **solo metadatos** (sin `blocks`): es el índice que consumen los paneles.
- Los ítems del índice (`SectionSummary`) llevan: `id`, `title`, `day` (`MM.DD`), `theme`, `summary`, `reference`, `referenceLabel`, `tags`, `related` (ids de otras secciones del recurso) y `references` (referencias canónicas citadas).
- Identificadores del devocional: `dayofyear.MM.DD` (incluye `02.29`); el tema y la lectura propia viven en los bloques de la sección.
- `factbook.core`: 32 artículos propios con `summary`, `tags`, `related` y `references`; 19 terminan con un bloque `map`. El bloque `heading` inicial repite el título del artículo (la app lo omite al pintar la cabecera). El léxico Strong (`lexicon.strongs`) usa el mismo mecanismo de secciones embebidas y añade 18 085 entradas.

### Secciones grandes por archivo (mejora 3)

El comentario y el diccionario no caben en un único `sections.json` sin cargar
megabytes al abrir el panel. Usan el mismo contrato con carga perezosa:

- `sections.json` contiene solo el índice de metadatos (`id`, `title`,
  `summary`, `reference`, `tags`…).
- `sections/<id>.json` contiene la sección completa con `blocks`.
- El servicio y `AssetSectionsRepository` cargan el cuerpo al seleccionar la
  entrada; el stream devuelve solo el índice.

Identificadores: `JHN.3` (una sección por capítulo de comentario) y `grace`
(slug de la entrada del diccionario). El comentario cubre 1 189 capítulos;
el diccionario, 3 961 entradas.

### Referencias

- Canónico interno: `BIBLE.{BOOK}.{CHAPTER}.{VERSE}` con códigos de 3 letras (estándar protestante 66) — p. ej. `JHN.1.1`, `LUK.23.48-49`.
- En el original: `bible+{versión}.{libro}.{cap}.{vers}` (63=Lucas, 64=Juan) y `dayofyear.MM.DD` para devocionales → **nuestra** representación: `ref` canónica + `dayofyear` como atributo de sección (`MM.DD`).
- Rangos: `A-B`; listas: `A,B`; capítulo completo: `JHN.1`.
- Parser/formateador en `packages/references` (aliases por idioma: "San Juan", "Jn", "Juan"…).

### Referencias cruzadas (TSK)

`catalog/data/index/search.sqlite` incluye la tabla auxiliar
`cross_references(source_ref, target_ref, rank)`. No es un recurso de la
Biblioteca: alimenta el drawer «Ideas» y la API.

```jsonc
// GET /v1/cross-references?ref=JHN.3.16&limit=40
{ "reference": "JHN.3.16", "source": "Treasury of Scripture Knowledge",
  "license": "Public Domain", "total": 17,
  "items": [ { "ref": "ROM.5.8" }, { "ref": "2CO.5.21" } ] }
```

- Acepta versículo (`JHN.3.16`) o capítulo (`JHN.3`); el capítulo se agrega
  por `source_ref LIKE 'JHN.3.%'` y se deduplica.
- `limit` se limita a 1–200; una referencia inválida devuelve `400`.
- En modo local, `LocalCatalogIndex.crossReferences` consulta la misma tabla.
- Procedencia y licencia: [`NOTICE.md`](../../NOTICE.md).

### Datasets (marcadores y anotaciones editoriales)

```jsonc
// MarkerDataset
{ "id": "ds.sermons", "resourceId": "bible.rv1909", "kind": "marker",
  "label": "Sermons", "ranges": [ { "ref": "JHN.1.1", "attrs": {"color": "blue"} } ] }
```

- `kind`: `marker` | `crossref` | `footnote` | `timeline` | `people` | `places`.

## 2. API REST (v1)

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/v1/resources?query=&type=&language=&owned=&page=` | Lista/búsqueda de metadatos (Library) |
| GET | `/v1/resources/{id}` | Manifiesto |
| GET | `/v1/resources/{id}/divisions` | Árbol de navegación (Contents) |
| GET | `/v1/resources/{id}/sections/{sectionId}` | Contenido (bloques) |
| GET | `/v1/resources/{id}/sections?from=&limit=` | Stream secuencial (scroll infinito) |
| GET | `/v1/references/resolve?ref=JHN.1.1&resource=bible.rv1909` | `{sectionId, offset, label}` |
| GET | `/v1/search?q=&scope=all|bible|books|factbook|devotional&resource=&type=&language=&book=&page=&pageSize=` | Resultados con `resourceId, resourceType, ref, snippet, citation` y facetas |
| GET | `/v1/cross-references?ref=&limit=` | Referencias cruzadas del TSK para un versículo o capítulo |
| GET | `/v1/insights/related-books?resource=&ref=` | Tarjetas "Related books" |
| GET | `/v1/insights/cross-references?ref=&limit=` | Cross references del pasaje |
| GET | `/v1/factbook/{slug}` | Artículo + related topics |
| GET | `/v1/devotionals/{id}?date=MM-DD` | Devocional del día |
| GET | `/v1/plans`, `POST /v1/plans/{id}/progress` | Reading plans |
| GET/POST/PATCH/DELETE | `/v1/notes` (`?notebook=&trash=`) | Notas (soft delete → Trash) |
| GET/PUT | `/v1/layouts`, `/v1/layouts/{id}` | Layouts guardados |
| GET/PUT | `/v1/positions` | Últimas posiciones por panel/link set |
| POST | `/v1/assistant/ask` *(plugin)* | Respuesta IA con citas (stream) |
| POST | `/v1/synopsis` *(plugin)* | Tarjeta Synopsis de una consulta |

Ejemplo de resultado de búsqueda:

```jsonc
{ "query": "amor al prójimo", "scope": "all", "total": 42,
  "facets": { "type": {"bible": 20, "commentary": 22},
              "language": {"es": 30, "en": 12},
              "book": {"MAT": 8, "JHN": 5} },
  "hits": [ { "resourceId": "comment.rec61", "resourceTitle": "Comentario…",
              "resourceType": "commentary", "sectionId": "JHN.1",
              "ref": "JHN.1.1", "citation": "Juan 1:1",
              "snippet": "…<em>amor al prójimo</em>…", "locked": false } ] }
```

## 3. Almacenamiento (servicio `catalog/`)

```
catalog-data/
  resources/{resourceId}/manifest.json
  resources/{resourceId}/cover.jpg
  resources/{resourceId}/sections/{sectionId}.json     # o NDJSON por streaming
  resources/{resourceId}/sections.json                 # o secciones embebidas (M5)
  datasets/{datasetId}.json
  meta/catalog.sqlite        # metadatos + licencias + notas + layouts + posiciones
  index/search.sqlite        # FTS5 (tokenizador por idioma)
  assets/                    # fuentes, imágenes, mapas
```

- **Auth** (opcional en modo local): JWT; el clon funciona 100% local sin servidor remoto.
- **Caché cliente**: respuestas ETag + caché en disco en la app (`catalog_client`).

## 4. Ingesta

1. **Fuentes**: USFM/USFX, OSIS, ThML, HTML, JSON, texto plano (CCEL/eBible/CrossWire/Gutenberg).
2. **Normalización**: versificación → esquema canónico; notas al pie → `footnote`; cross-refs → `xref` (USFM `\xref`).
3. **Segmentación**: manifiesto + divisiones + secciones (JSON).
4. **Índices**: FTS5 por recurso y global; índices de referencias (ref → sección+offset).
5. **Datasets**: marcadores (p. ej. sermones), timelines, people/places si la fuente lo permite.
6. **Validación**: esquema JSON + conteos (`stats`), licencia obligatoria.

## 5. Compatibilidad con referencias del original

| Original | Nuestro esquema |
|---|---|
| `/references/bible+rvr60.64.1.1` | `ref: JHN.1.1` + `resource: bible.rv60` (solo si aplica) |
| `/books/LLS:1.0.502/references/bible+rvr60.63.23.48` | `resource: bible.rv1909`, `ref: LUK.23.48` |
| `dayofyear.10.18.1` | `section: 10-18`, devocional `devotional.morning-evening` |
| `zzls` / `linkSetId` | `LinkSet A–F` internos del workspace |
| `?layout=one|two|…` | mismos presets, `layoutId` propio |
| `activeMenu=library|tools|guided|layouts|over` | overlays equivalentes |

## 6. Apéndice — catálogo semilla (dominio público)

| Tipo | Candidatos PD | Licencia/fuente |
|---|---|---|
| Biblias | KJV, ASV, Darby, WEB, Reina-Valera 1909/1602, Almeida 1911, Segond 1910, Luther 1912, Vulgata Clementina, LXX (Swete 1909), TR, Tischendorf, Nestle 1904, SBLGNT, WLC | PD; SBLGNT CC-BY 4.0; WLC libre (verificar) |
| Comentarios | JFB, Matthew Henry, Adam Clarke, Barnes, Pulpit Commentary, Cambridge Bible, Expositor's Bible, Ellicott, Bengel, Calvino | PD |
| Diccionarios | Easton, Smith's, ISBE (1915), Nave's, BDB, Thayer, Strong's, Hitchcock | PD |
| Referencias cruzadas | Treasury of Scripture Knowledge (TSK) | PD |
| Devocionales | Spurgeon *Morning and Evening*, *Faith's Checkbook*, *Daily Light* (1900) | PD |
| Historia/referencia | Josefo, Eusebio, Padres Apostólicos, *Institutes* (Calvino) | PD |

> **Prohibido en el catálogo**: ESV, NIV, NASB95, RVR60, NLT, CSB… y cualquier formato propietario, activo de marca o recurso licenciado del original.

## 7. Estado de implementación (servicio v1, M2–M6)

Implementado en `catalog/server/catalog_server.py` (Python 3 stdlib + sqlite3/FTS5) sobre los datos que construye `catalog/tools/build_catalog.py` desde `catalog/config/resources.json` (y `catalog/tools/seed_m5.py` para el devocional y el Factbook). El índice incluye **14 recursos**: 9 Biblias (RV1909, KJV, ASV, BLL, SBLM, BES, VBL, TAHOT y TAGNT), 2 diccionarios (Easton y léxico Strong), comentario, devocional y Factbook; además de **376 083 referencias cruzadas** del TSK. Autoprueba end-to-end: `python3 catalog/server/selftest.py` (52 comprobaciones). Guía de build/run en `catalog/README.md`.

| Endpoint | Estado | Notas |
|---|---|---|
| `GET /v1/health` | ✅ | `{status, service, version: "1.0-m7", resources, verses, sections, crossReferences}`; `verses` cuenta filas bíblicas y `sections` todas las no bíblicas (comentario, diccionario, devocional y Factbook) |
| `GET /v1/resources` | ✅ | `query`, `type`, `language`, `author`, `sort=title\|author\|updated`, `page`, `pageSize`; devuelve `total`, `page`, `items` y `facets` (tipo, idioma, autor — calculados con el resto de filtros aplicados). Incluye Biblias, `commentary`, `dictionary`, `devotional` y `factbook` |
| `GET /v1/resources/{id}` | ✅ | Manifiesto en formato de app (`resourceId, title, abbrev, language, source, license, books[]`); `ETag` + `304` |
| `GET /v1/resources/{id}/books/{CODE}` | ✅ *(extensión v1)* | Libro completo en formato de app (`{code, name, chapters[]}`). Es lo que consume el lector; añadido al contrato base, que solo definía secciones |
| `GET /v1/resources/{id}/sections/{S}` | ✅ | Sección suelta (contrato §1); `ETag` + `304`. Si el recurso tiene las secciones embebidas (M5) se sirve desde `sections.json`; si usa `sections/<id>.json`, se carga perezosamente |
| `GET /v1/resources/{id}/sections?from=&limit=` | ✅ | Stream secuencial (scroll infinito); máx. 200 por página. Devuelve metadatos sin `blocks` |
| `GET /v1/search` | ✅ | `q`, `scope=all\|bible\|books\|factbook\|devotional`, `resource=` *(extensión v1)*, `type`, `language`, `book`, `page`, `pageSize`; facetas de tipo/idioma/libro y sintaxis abajo. Los ámbitos `morph`, `media` y `maps` son una extensión **solo local** de la app |
| `GET /v1/cross-references` | ✅ | `ref` (versículo o capítulo) y `limit` 1–200; devuelve `source`, `license`, `total` e `items[]` del TSK |
| `/v1/references/resolve`, `/v1/divisions`, `insights/*`, `notes`, `layouts`, `assistant`… | — | M6+ (el árbol de Contents sale hoy de `books[]` del manifiesto) |

### Búsqueda de estudio

- **Sintaxis:** palabras sueltas (AND implícito), `"frases"`, `AND` / `OR` / `NOT`, `NEAR` (10 palabras), `NEAR/5` (distancia explícita), `WITHIN n WORDS` (equivalente a `NEAR(..., n)`) y `BEFORE` (el término izquierdo debe aparecer antes que el derecho; se evalúa en el índice local). Diacríticos y mayúsculas son indiferentes.
- **Campos:** `bible:"Jn 3"` limita a un pasaje (libro y capítulo, con rango de versículos opcional), `book:JHN` filtra por libro, `type:factbook`, `language:es` y `resource:bible.kjv`. Una consulta puede contener solo campos para listar un pasaje o un tipo.
- **Filtros de UI:** `type`, `language` y `book` aplican los mismos filtros que los campos; se combinan con `scope`. La respuesta devuelve `facets` (`type`, `language`, `book`) calculadas excluyendo el propio filtro para poder cambiar de opción.
- **Scopes:** `all` recorre todo; `bible` solo Biblias; `books` todo lo que no es Biblia (comentario, diccionario, Factbook y devocional); `factbook` y `devotional` son ámbitos específicos. En la app, `morph` busca códigos/descripciones de `morphology.json`, y `maps`/`media` listan las entradas de `map_sections.json` (23 entradas de mapa: 19 del Factbook y 4 del comentario; Multimedia incluye los mapas mientras no haya otros bloques visuales) sin descargar el índice FTS.
- **`resource=` *(extensión v1)*:** limita la búsqueda a un recurso concreto; es lo que usa el modo **Buscar dentro del panel del lector** (cada panel busca solo en su versión). Devuelve el campo `resource` en la respuesta, `404` si el recurso no existe y respeta `scope`.
- **Agrupación:** la UI agrupa los hits por `resourceId` y muestra la cabecera del recurso; al pulsar un hit bíblico salta al versículo, Factbook/devocional abre su sección y comentario/diccionario abre el panel genérico en la entrada.
- **No soportado todavía:** paréntesis explícitos. El servicio remoto no implementa `BEFORE` ni los ámbitos `morph`/`media`/`maps`; la app los resuelve localmente.
- **Forma del hit implementada:**

```jsonc
{ "resourceId": "bible.kjv", "resourceTitle": "King James Version",
  "resourceType": "bible", "abbrev": "KJV",
  "sectionId": "JHN.1", "book": "JHN", "bookName": "John", "chapter": 1, "verse": 2,
  "ref": "JHN.1.2",                        // canónica interna, navegable en el lector
  "citation": "John 1:2",                  // nombre del libro del recurso + cap:vers
  "snippet": "The same was <em>in the beginning</em> with God.",
  "locked": false }
```

Para Factbook/devocional/comentario/diccionario, `resourceType` es
`factbook`/`devotional`/`commentary`/`dictionary`, `book` queda vacío, `ref` es
el `sectionId` (p. ej. `gracia`, `dayofyear.10.19`, `JHN.3`, `grace`) y
`citation` es el título de la sección.

> **Desviación deliberada:** `offset`/`textRanges` del borrador se sustituyen por `ref` + `citation`. El lector del clon navega por referencia (abre el recurso en `ref`) y la vista de resultados usa el `snippet` con `<em>`.

### Modo local de la app (autonomía sin servicio)

La app incluye un subconjunto de dominio público, CC BY, CC BY-SA y propio para
funcionar sin arrancar Python:

- `app/assets/catalog/index.json` — summaries y facetas de los **14 recursos**
  empaquetados (nueve Biblias, dos diccionarios, comentario, devocional y
  Factbook). La Biblioteca filtra y faceta en memoria con el mismo formato de
  respuesta del servicio.
- `app/assets/catalog/{rv1909,kjv,asv,bll,sblm,bes,vbl,tahot,tagnt}/` —
  manifiesto y libros completos de las nueve Biblias. Los libros se guardan
  como `books/<CODE>.json.gz`; el lector y la comparación los leen con
  `AssetDocumentRepository` y `loadCatalogAssetText`.
- `app/assets/catalog/{devotional.daily,factbook.core,lexicon.strongs}/sections.json.gz`
  — las secciones embebidas de M5 y el léxico.
- `app/assets/catalog/{matthew-henry-concise,easton}/sections.json.gz` + `sections/`
  — índice y cuerpo por entrada del comentario y del diccionario; la app carga
  solo la entrada abierta.
- `app/assets/maps/ne_110m_land.geojson` y `ne_110m_lakes.geojson` — geometría
  de Natural Earth (dominio público) para los mapas; las coordenadas de los
  lugares vienen de OpenBible.info (CC BY 4.0).
- `app/assets/catalog/search.sqlite.gz` + `search.meta.json` — índice FTS5
  precompilado (esquema idéntico al del servicio) con la tabla
  `cross_references` y su hash de contenido. En el primer uso la app lo extrae a
  `catalog.search.<hash>.sqlite` en el directorio de datos y lo abre en modo
  lectura. No hay indexación en tiempo de ejecución.
- `app/assets/catalog/morphology.json` y `map_sections.json` — descripciones
  de morfología y manifiesto de mapas/contenido visual; se empaquetan y
  alimentan los ámbitos `morph`/`maps`/`media` sin abrir el índice.

El gateway (`lib/catalog/catalog_gateway.dart`) usa `auto` (servicio con
respaldo local), `local` (solo assets) o `remote` (solo servicio). En `auto`, si
el servicio no responde, tanto la Biblioteca como la Búsqueda caen al índice
local, y `crossReferences` cae a la tabla local. La sintaxis es la misma
(`lib/catalog/local_search_query.dart` replica `tokenize_query` +
`fts_expression` del servidor): palabras, `"frases"`, `AND`/`OR`/`NOT`, `NEAR`,
`WITHIN n WORDS`, `BEFORE` (local), campos, `scope`, filtros
`type`/`language`/`book` y `resource=`.

El índice contiene **248 870 versículos** de las nueve Biblias y **23 633
secciones no bíblicas** (272 503 entradas FTS5), más **376 083** enlaces de
referencias cruzadas. `scope=books`, `scope=factbook` y `scope=devotional`
devuelven resultados reales. Ajustes muestra `Modo local` con recursos,
versículos y secciones indexadas cuando no hay servicio; las referencias
cruzadas se consultan desde «Ideas» y la API.

### Bloques de mapa

Un bloque `map` tiene esta forma:

```jsonc
{ "type": "map", "title": "Jerusalén, Belén y Judea",
  "caption": "…", "center": [31.80, 35.24],
  "latSpan": 1.45, "lonSpan": 1.75,
  "markers": [
    { "name": "Jerusalén", "lat": 31.776667, "lon": 35.234167,
      "ref": "JHN.2.13" }
  ] }
```

`center` es `[latitud, longitud]`; `latSpan`/`lonSpan` definen el encuadre en
grados. La app ajusta la relación de aspecto con `cos(latitud)` para no deformar el ancho, dibuja
costas/lagos con `CustomPainter` y superpone los marcadores. Si un marcador
tiene `ref`, al pulsarlo se abre el pasaje. Los mapas se definen una sola vez en
`catalog/config/maps.json`: `seed_m5.py` los copia a 19 artículos del Factbook y
`build_catalog.py` los inserta al final de `JHN.3`, `LUK.2`, `MAT.2` y `ACT.9`
del comentario. No hay teselas, red ni dependencias de mapas.

`sync_app_catalog.py` resume estos bloques en `map_sections.json` (23
entradas: 19 del Factbook y 4 del comentario). Ese manifiesto empaquetado
alimenta los ámbitos Mapas/Multimedia de la Búsqueda y las herramientas
**Atlas** y **Medios** de la app (M6.5). **Cursos**, **Documentos**,
**Favoritos** y la clasificación de **Salmos** son contenido propio de la app
y no forman parte del contrato del catálogo; el Explorador de Salmos usa la
RV1909 empaquetada.

Para regenerar todo:

```bash
python3 catalog/tools/import_stepbible.py --all
python3 catalog/tools/import_strongs_lexicon.py
python3 catalog/tools/import_content.py --all   # comentario, diccionario y TSK
python3 catalog/tools/build_catalog.py
python3 catalog/tools/seed_m5.py
python3 catalog/tools/sync_app_catalog.py
```
