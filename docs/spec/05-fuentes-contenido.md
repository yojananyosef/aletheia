# Fuentes, licencias y atribución del contenido

Este documento registra el proceso reproducible de las fuentes, las
verificaciones y las limitaciones conocidas. La tabla de atribución resumida
está en [`NOTICE.md`](../../NOTICE.md).

## 1. Recursos empaquetados

| id | tipo | idioma | contenido | fuente |
|---|---|---|---|---|
| `bible.rv1909` | bible | es | 66 libros, 31 102 versículos | eBible.org `spaRV1909_usfm.zip` |
| `bible.kjv` | bible | en | 66 libros, 31 102 versículos | eBible.org `eng-kjv_usfm.zip` |
| `bible.asv` | bible | en | 66 libros, 31 102 versículos | eBible.org `eng-asv_usfm.zip` |
| `bible.bll` | bible | es | 66 libros, 31 103 versículos | eBible.org `spabll_usfm.zip` |
| `bible.sblm` | bible | es | 66 libros, 31 103 versículos | eBible.org `spablm_usfm.zip` |
| `bible.bes` | bible | es | 66 libros, 31 102 versículos | eBible.org `spabes_usfm.zip` |
| `bible.vbl` | bible | es | 66 libros, 31 102 versículos | eBible.org `spavbl_usfm.zip` |
| `bible.tahot` | bible | he | 39 libros, 929 capítulos, 23 261 versículos (con títulos de salmos), 305 417 palabras | STEPBible TAHOT |
| `bible.tagnt` | bible | grc | 27 libros, 260 capítulos, 7 953 versículos, 138 140 palabras | STEPBible TAGNT |
| `lexicon.strongs` | dictionary | mul | 18 085 entradas (8 723 hebreas y 9 362 griegas) | STEPBible TBESH/TBESG + Strong's Hebrew Dictionary |
| `commentary.matthew-henry-concise` | commentary | en | 1 189 capítulos | `lyteword/mhenry-concise` (CC0) |
| `dictionary.easton` | dictionary | en | 3 961 entradas | `JWBickel/BibleDictionaries` (texto de 1897) |
| `devotional.daily` | devotional | es | 366 lecturas propias | Aletheia |
| `factbook.core` | factbook | es | 32 artículos propios (19 con mapa) | Aletheia |

Además, el índice contiene **376 083 enlaces** del *Treasury of Scripture
Knowledge* (TSK) para **29 055 versículos fuente**.

## 2. Base de licencia

Solo se admite **dominio público**, **CC BY 4.0**, **CC BY-SA 4.0** o contenido
propio. Las licencias CC BY permiten uso comercial con atribución; CC BY-SA
añade compartir igual. No se usa material NC ni ND.

- **eBible.org (RV1909, KJV, ASV, BLL, SBLM y BES):** los paquetes USFM
  incluyen `copr.htm` con la declaración *Public Domain*. BLL y SBLM se
  identifican además como borradores de traducción; se distribuyen tal como los
  publica la fuente.
- **VBL:** el paquete de eBible.org declara **CC BY-SA 4.0**. Se incluye como
  texto de lectura y se conserva la atribución a Jonathan Gallagher y Shelly
  Barrios de Ávila. No se usan sus etiquetas Strong porque la alineación de la
  fuente es irregular; el lector no muestra el botón «Original» para esta
  edición.
- **TAHOT/TAGNT:** STEPBible.org / Tyndale House Cambridge, **CC BY 4.0**. Se
  conserva el texto hebreo/griego, la morfología ETCBC/TAGNT, el Strong
  desambiguado y las glosas inglesas de la fuente. La traducción española de la
  columna de OpenGNT no se usa; las glosas españolas del popover son propias y
  solo cubren voces frecuentes. El manifiesto y la ficha muestran la
  atribución.
- **Léxico Strong:** las entradas, lemas, transliteraciones, morfología y
  glosas de TBESH/TBESG son **CC BY 4.0** de STEPBible.org / Tyndale House
  Cambridge. Las definiciones hebreas proceden del *Strong's Hebrew
  Dictionary* de CrossWire, **dominio público**. Las definiciones griegas son
  TBESG, CC BY 4.0. Las entradas se agrupan por Strong base (`H0122a` y
  `H0122b` → `H0122`).
- **Matthew Henry conciso:** texto original de dominio público; la edición
  Markdown de `lyteword/mhenry-concise` declara **CC0-1.0** en GitHub. El
  capítulo `2 Reyes 1`, ausente en la edición concisa, se toma de
  `lyteword/mhenry-complete`, también CC0.
- **Easton:** el diccionario de Matthew George Easton se publicó en 1897 y su
  texto es de dominio público. La transcripción JSONL usada como fuente no
  declara una licencia adicional en su ficha; se distribuye únicamente el texto
  normalizado, no la base de datos original.
- **TSK:** la ficha de `ariseshinestudio/TSK` indica «Provider: JustVerses.com ·
  License: Public Domain». El TSK original es una obra del siglo XIX. El
  endpoint devuelve `source` y `license` junto con los enlaces.
- **Devocional y Factbook:** lecturas y artículos propios de Aletheia; los
  versículos citados proceden de la RV1909. Los mapas del Factbook y del
  comentario son propios en su selección, encuadre y textos.
- **Natural Earth:** la geometría de costas y lagos (`ne_110m_land` y
  `ne_110m_lakes`, escala 1:110m) es de **dominio público**. Se distribuye en
  `app/assets/maps/` y se dibuja localmente; no se usan teselas ni imágenes.
- **OpenBible.info Bible Geocoding:** las coordenadas de los lugares son
  **CC BY 4.0**. Se usan para situar los marcadores; la atribución aparece al
  pie de cada mapa y en `NOTICE.md`.

No se distribuyen escaneos, portadas, fuentes tipográficas ni activos de las
obras originales. Las fuentes crudas viven en `catalog/sources/` y no se
versionan; los artefactos intermedios, en `catalog/data/`.

## 3. Proceso de ingesta

### 3.1 Textos originales y léxico

Los archivos de STEPBible se descargan en `catalog/sources/stepbible/` y el
módulo `StrongsHebrew` de CrossWire en `catalog/sources/lexicon/`. Después:

```bash
python3 catalog/tools/import_stepbible.py --all
python3 catalog/tools/import_strongs_lexicon.py
```

`import_stepbible.py` genera `bible.tahot` (39 libros) y `bible.tagnt` (27
libros) con:

- versificación alineada con la RV1909/KJV; las referencias alternativas de
  TAGNT se conservan entre corchetes;
- títulos de los salmos como versículo `0` en TAHOT;
- `TextInline` con `strong`, `strongFull`, `morph`, `lemma`, `translit`,
  `gloss` y, cuando existe, `glossEs`;
- morfología legible en `catalog/data/morphology.json`, copiada a los assets.

`import_strongs_lexicon.py` genera `lexicon.strongs` con secciones embebidas en
`sections.json`; cada entrada lleva definición, fuente y licencia. Las
definiciones hebreas se toman del diccionario de Strong (PD); las griegas, de
TBESG (CC BY 4.0). El texto completo no se duplica en el índice FTS: solo se
indexan los metadatos de la entrada.

### 3.2 Biblias españolas adicionales

SBLM, BES y VBL se descargan del catálogo USFM de eBible.org:

```bash
python3 catalog/tools/build_catalog.py
```

`build_catalog.py` detecta los `ingest` de `catalog/config/resources.json` y
convierte los paquetes con `import_ebible_usfm.py`. SBLM conserva la variante de
versificación de Romanos 14:24-26 y 16:25; BES y VBL siguen la versificación de
31 102 versículos.

### 3.3 Comentario, diccionario y TSK

`catalog/tools/import_content.py` descarga y normaliza las tres fuentes de la
mejora de profundidad:

```bash
# Todo (comentario, diccionario y TSK)
python3 catalog/tools/import_content.py --all

# O por separado
python3 catalog/tools/import_content.py --only commentary
python3 catalog/tools/import_content.py --only dictionary
python3 catalog/tools/import_content.py --only xrefs
```

El resultado se escribe en `catalog/sources/`:

- `commentary.matthew-henry-concise/manifest.json` + `sections.json` +
  `sections/<CODE>.<N>.json`, una sección por capítulo.
- `dictionary.easton/manifest.json` + `sections.json` + `sections/<slug>.json`,
  una sección por entrada.
- `catalog/data/cross_references.json` con `{source, sourceUrl, license,
  entries:[{ref, targets[]}]}`.

### 3.4 Construcción y assets

```bash
python3 catalog/tools/seed_m5.py
python3 catalog/tools/build_catalog.py
python3 catalog/tools/sync_app_catalog.py
```

`build_catalog.py` crea el índice FTS5 con una fila por versículo de las nueve
Biblias, una fila por sección del comentario, diccionario, devocional, Factbook
y léxico, y la tabla `cross_references(source_ref, target_ref, rank)` del TSK.

`sync_app_catalog.py`:

- escribe los manifiestos y comprime los libros de las Biblias como
  `books/<CODE>.json.gz`;
- comprime los índices de secciones como `sections.json.gz` (los cuerpos
  individuales de comentario y diccionario siguen en JSON plano);
- copia `morphology.json`;
- actualiza `index.json` y `search.meta.json`, y comprime el índice en
  `app/assets/catalog/search.sqlite.gz`.

La app lee los assets con `loadCatalogAssetText`, que intenta el JSON plano y,
si no existe, descomprime el `.json.gz` en memoria. El texto no se altera.

### 3.5 Mapas

`catalog/config/maps.json` define 18 mapas con un `title`, un `caption`, un
`center` `[latitud, longitud]`, `latSpan`/`lonSpan` y una lista de `markers`
(`name`, `lat`, `lon` y `ref` opcional). `seed_m5.py` los copia a 19 artículos
del Factbook; `build_catalog.py` inserta un bloque al final de `JHN.3`, `LUK.2`,
`MAT.2` y `ACT.9` del comentario. El bloque resultante tiene la forma:

```jsonc
{ "type": "map", "title": "Jerusalén, Belén y Judea",
  "center": [31.8, 35.24], "latSpan": 1.45, "lonSpan": 1.75,
  "markers": [{ "name": "Jerusalén", "lat": 31.776667,
                "lon": 35.234167, "ref": "JHN.2.13" }] }
```

La app descarga una sola vez `app/assets/maps/ne_110m_land.geojson` y
`ne_110m_lakes.geojson`, proyecta las coordenadas con el encuadre del bloque y
dibuja costas, lagos y marcadores con `CustomPainter`. `InteractiveViewer`
permite zoom y desplazamiento; un marcador con `ref` abre el pasaje. No hay
teselas, red ni servicio de mapas. La atribución de Natural Earth y
OpenBible.info se muestra bajo cada mapa.

## 4. Verificación

- `python3 catalog/server/selftest.py`: **52/52** comprobaciones; incluye
  comentario de `JHN.3`, entrada `grace` del diccionario, `ROM.5.8` en las
  referencias de `JHN.3.16`, búsqueda por tipo y recuentos de `health`.
- `flutter analyze`: sin incidencias.
- `flutter test`: suite completa de pruebas unitarias y de widget; incluye las
  pruebas de TAHOT/TAGNT/léxico, el botón «Original», el popover de estudio, la
  apertura de la entrada del léxico y los mapas (parseo, renderizado, error de
  geometría y navegación por marcador).
- `flutter test integration_test/offline_catalog_test.dart -d linux`: recorre
  los 14 recursos sin servicio y abre comentario, diccionario, originales y
  TSK.
- `flutter test integration_test/catalog_flow_test.dart -d linux`: comprueba
  los 14 recursos y sus metadatos contra el servicio real.

## 5. Limitaciones conocidas

- La edición concisa de Matthew Henry omite `2 Reyes 1`; el texto se completa
  desde la edición completa del mismo autor. El resumen de esa sección lo
  advierte.
- La BLL y la SBLM son borradores de traducción de la fuente; no se corrigen
  editorialmente.
- El repositorio de la transcripción de Easton no declara una licencia
  adicional; la base es el texto de 1897, de dominio público.
- El TSK se decodifica como `cp1252`; las abreviaturas anómalas de la fuente se
  resuelven con un mapa explícito en `import_content.py`.
- Las referencias cruzadas del TSK no se presentan como un recurso de la
  Biblioteca: son datos auxiliares del lector y de «Ideas».
- TAGNT no contiene Juan 7:53 ni Romanos 16:25-27 porque el texto crítico de la
  fuente no los incluye; el lector tolera referencias sin texto original.
- La VBL no muestra etiquetas Strong ni el botón «Original»; se ofrece como
  texto de lectura.
- Los mapas son esquemáticos: no representan fronteras históricas ni la
  cartografía exacta de cada época. El encuadre y los marcadores son una
  selección editorial propia; la geometría solo aporta costas y lagos.
- La validación de distribución en Windows/macOS, los instaladores y la firma
  de código siguen pendientes; Linux es la plataforma verificada.
