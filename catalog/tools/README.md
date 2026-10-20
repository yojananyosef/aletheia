# catalog/tools — Ingesta de contenido (dominio público)

Herramientas para convertir fuentes de **dominio público** al formato de documento
del catálogo (`docs/spec/03-contrato-catalogo.md`). En M1 la app sirve el resultado
como *assets* locales; desde M2 lo servirá el servicio `catalog/`.

## import_ebible_usfm.py

Convierte una Biblia en **USFM** publicada por [eBible.org](https://ebible.org/) al
formato de documento (manifest + un JSON por libro).

### Fuente usada en M1: RV1909

| Campo | Valor |
| --- | --- |
| Recurso | `bible.rv1909` — *Reina-Valera 1909* (*Santa Biblia — Reina Valera 1909*) |
| Origen | <https://ebible.org/spaRV1909/> · zip: <https://ebible.org/Scriptures/spaRV1909_usfm.zip> |
| Licencia | **Dominio público** (declarado en `copr.htm` del propio paquete y en la ficha de eBible) |
| Contenido | 66 libros, 1 189 capítulos, 31 102 versículos (verificado contra el USFM de origen) |
| Notas | Esa edición no trae notas al pie (`\f`) ni referencias cruzadas (`\x`); los marcadores de palabras (`\w …|strong="…"\w*`, 390 755) se descartan conservando solo el texto |

Procedencia registrada también en el manifest generado (`source`, `license`).

### Uso

```bash
# 1) Descargar y descomprimir la fuente
mkdir -p /tmp/rv1909 && cd /tmp/rv1909
curl -L -o usfm.zip https://ebible.org/Scriptures/spaRV1909_usfm.zip
unzip -o usfm.zip -d usfm

# 2) Convertir (desde la raíz del monorepo)
python3 catalog/tools/import_ebible_usfm.py \
  --usfm-dir /tmp/rv1909/usfm \
  --out-dir  app/assets/catalog/rv1909 \
  --resource-id bible.rv1909 \
  --title "Reina-Valera 1909" \
  --abbrev RV1909 \
  --source-url https://ebible.org/Scriptures/spaRV1909_usfm.zip \
  --license "Dominio público"
# → OK bible.rv1909: 66 libros, 1189 capítulos, 31102 versículos
```

### Salida

```
app/assets/catalog/rv1909/
  manifest.json         metadatos + índice de libros/capítulos
  books/<CODE>.json     bloques por capítulo (GEN.json … REV.json)
```

### Marcadores USFM soportados

- `\id` → código canónico (3 letras: `JHN`, `PSA`, …), `\h`/`\toc2` → nombre en español.
- `\c` → bloque `chapterNumber`; `\p`/`\m` (y variantes) → nuevo `verseGroup` (`paragraph`).
- `\q` (niveles) → `verseGroup` `poetry` con `indent`; `\li` → `list`; `\s`/`\d` → `heading` (`section`/`psalmTitle`).
- `\v` → versículo `{n, inlines}` (las continuaciones de línea se acumulan al versículo).
- `\w texto|strong="…"\w*` → solo `texto`; `\add …\add*` → `span` con `style: "italic"`.
- `\f …\f*` y `\x …\x*` → se descartan en M1 (la ingesta de notas/xrefs llega con el
  servicio de catálogo en M2; los modelos y el renderer del lector ya los soportan).

### Verificación

Los tests del cliente (`app/test/document_repository_test.dart`) comprueban los conteos,
el texto de `JHN.1.1` y la conversión de `\add` a itálicas sobre los assets generados.

## import_content.py

Prepara el contenido de profundidad de la mejora 3:

```bash
python3 catalog/tools/import_content.py --all
# o --only commentary | dictionary | xrefs
```

| Recurso | Fuente | Licencia |
|---|---|---|
| `commentary.matthew-henry-concise` | `lyteword/mhenry-concise`; `2 Reyes 1` desde `mhenry-complete` | CC0-1.0; texto original PD |
| `dictionary.easton` | `JWBickel/BibleDictionaries` (`Easton's Bible Dictionary.jsonl`) | Texto de 1897, dominio público |
| TSK (`cross_references.json`) | `ariseshinestudio/TSK` / JustVerses.com | Dominio público |

Salidas:

```
catalog/sources/commentary.matthew-henry-concise/
  manifest.json
  sections.json              # 1 189 metadatos de capítulo
  sections/JHN.3.json        # cuerpo por capítulo
catalog/sources/dictionary.easton/
  manifest.json
  sections.json              # 3 961 entradas
  sections/grace.json
catalog/data/cross_references.json
```

- El comentario se parsea desde Markdown; se omiten los sumarios y se conservan
  los párrafos y encabezados. `2 Reyes 1` se completa con la edición completa
  porque falta en la concisa.
- El diccionario agrupa definiciones por término y genera slugs estables
  (`grace`, `grace-means-of`…).
- El TSK se decodifica como `cp1252`; se normalizan abreviaturas y rangos, y se
  deduplican los destinos por versículo fuente.
- La tabla `cross_references` se construye en `build_catalog.py` y se empaqueta
  en el índice local con `sync_app_catalog.py`.

La ficha completa de fuentes y licencias está en
[`NOTICE.md`](../../NOTICE.md) y
[`docs/spec/05-fuentes-contenido.md`](../../docs/spec/05-fuentes-contenido.md).
