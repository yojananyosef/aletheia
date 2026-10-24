#!/usr/bin/env python3
"""Construye `catalog/data/` a partir de recursos en formato de app.

Entrada (config en `catalog/config/resources.json`):
  - `inputDir`: directorio con `manifest.json` + `books/<CODE>.json`
    (formato de app generado por `import_ebible_usfm.py`) o con
    `sections.json` + `sections/<ID>.json` (comentario y diccionario).
  - `ingest` (opcional): si falta `inputDir`, descarga el zip USFM y lo convierte.
  - `ingest.importer`: `commentary` o `dictionary`; se prepara con
    `import_content.py` antes de construir el recurso.

Salida (`catalog/data/`):
  catalog.json                              lista de recursos
  resources/<id>/manifest.json              manifiesto (contrato v1)
  resources/<id>/books/<CODE>.json          contenido (formato de app)
  resources/<id>/sections/<B>.<N>.json      secciones (contrato v1)
  resources/<id>/sections.json              orden de secciones
  index/search.sqlite                       FTS5: recursos, secciones,
                                            versículos y referencias cruzadas

Uso:
  python3 catalog/tools/build_catalog.py [--only bible.rv1909] [--skip-index]
"""
from __future__ import annotations

import argparse
import gzip
import json
import shutil
import sqlite3
import subprocess
import sys
import urllib.request
import zipfile
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TOOLS = Path(__file__).resolve().parent
MAPS_CONFIG = ROOT / "catalog" / "config" / "maps.json"

# Mapas que se insertan al final de capítulos concretos del comentario.
COMMENTARY_MAPS = {
    "JHN.3": "jerusalen",
    "LUK.2": "belen",
    "MAT.2": "mat_2",
    "ACT.9": "act_9",
}

# Texto máximo por sección no bíblica en el índice FTS (el cuerpo completo
# vive en sections/<id>.json). Mantiene search.sqlite.gz por debajo del
# límite de 100 MB de GitHub.
SECTION_INDEX_CHARS = 1200


def log(message: str) -> None:
    print(message, flush=True)


def write_json(path: Path, payload) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )


def read_json(path: Path):
    """Lee JSON plano o `.json.gz` (assets comprimidos de la app)."""
    if path.exists():
        return json.loads(path.read_text(encoding="utf-8"))
    compressed = Path(f"{path}.gz")
    if compressed.exists():
        return json.loads(gzip.decompress(compressed.read_bytes()).decode("utf-8"))
    raise FileNotFoundError(path)


def prune(value):
    """Elimina claves con valor None (manifiestos más limpios)."""
    if isinstance(value, dict):
        return {k: prune(v) for k, v in value.items() if v is not None}
    if isinstance(value, list):
        return [prune(v) for v in value]
    return value


# ------------------------------------------------------------------ ingesta


def ensure_input(resource: dict, sources_dir: Path) -> Path:
    input_dir = ROOT / resource["inputDir"]
    if (input_dir / "manifest.json").exists():
        return input_dir

    ingest = resource.get("ingest")
    if not ingest:
        raise SystemExit(
            f"ERROR: falta {input_dir}/manifest.json y {resource['resourceId']} "
            "no define 'ingest' para generarlo"
        )

    importer = ingest.get("importer")
    if importer in ("commentary", "dictionary"):
        log(f"· preparando contenido de {resource['resourceId']}")
        subprocess.run(
            [
                sys.executable,
                str(TOOLS / "import_content.py"),
                "--only", importer,
            ],
            check=True,
        )
        if (input_dir / "manifest.json").exists():
            return input_dir
        raise SystemExit(
            f"ERROR: import_content.py no generó {input_dir}/manifest.json"
        )

    slug = resource["resourceId"].split(".", 1)[-1]
    work = sources_dir / slug
    work.mkdir(parents=True, exist_ok=True)
    zip_path = work / "_source.zip"
    usfm_dir = work / "_usfm"

    if not zip_path.exists():
        log(f"· descargando {ingest['usfmZip']}")
        request = urllib.request.Request(
            ingest["usfmZip"],
            headers={"User-Agent": "AletheiaCatalog/1.0"},
        )
        with urllib.request.urlopen(request, timeout=180) as response:
            zip_path.write_bytes(response.read())
    if not any(usfm_dir.glob("*.usfm")):
        log(f"· descomprimiendo en {usfm_dir}")
        usfm_dir.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(zip_path) as archive:
            archive.extractall(usfm_dir)

    log(f"· convirtiendo USFM → {resource['inputDir']}")
    subprocess.run(
        [
            sys.executable,
            str(TOOLS / "import_ebible_usfm.py"),
            "--usfm-dir", str(usfm_dir),
            "--out-dir", str(input_dir),
            "--resource-id", resource["resourceId"],
            "--title", ingest["title"],
            "--abbrev", ingest["abbrev"],
            "--language", ingest.get("language", "es"),
            "--source-url", ingest["sourceUrl"],
            "--license", ingest["license"],
        ],
        check=True,
    )
    return input_dir


# ------------------------------------------------------------------ recursos


def inline_text(inline: dict) -> str:
    kind = inline.get("t")
    if kind in ("text", "span"):
        return inline.get("v", "")
    if kind == "xref":
        return inline.get("label") or inline.get("ref", "")
    if kind == "line":
        return " "
    return ""


def block_text(block: dict) -> str:
    if block.get("type") in ("heading", "paragraph"):
        if "text" in block:
            return block["text"]
        return " ".join(
            inline_text(inline) for inline in block.get("inlines", [])
        )
    if block.get("type") == "verseGroup":
        return " ".join(
            " ".join(inline_text(inline) for inline in verse.get("inlines", []))
            for verse in block.get("verses", [])
        )
    return ""


def section_text(section: dict) -> str:
    """Texto plano de una sección no bíblica (Factbook, devocional).

    Además del cuerpo, indexa los metadatos que el usuario ve en la lista y
    en el artículo: título, tema, resumen, etiquetas y referencias.
    """
    parts = [
        section.get("title", ""),
        section.get("theme", ""),
        section.get("summary", ""),
        section.get("reference", ""),
        section.get("referenceLabel", ""),
    ]
    parts.extend(section.get("tags", []))
    parts.extend(section.get("references", []))
    parts.extend(block_text(block) for block in section.get("blocks", []))
    return " ".join(part.strip() for part in parts if part and part.strip())


def verse_text(verse: dict) -> str:
    """Texto plano de un versículo (sin marcadores) para el índice."""
    return " ".join(
        inline_text(inline).strip()
        for inline in verse.get("inlines", [])
        if inline_text(inline).strip()
    )


def license_text(value) -> str:
    """Normaliza la licencia del manifiesto de app (texto o mapa anidado)."""
    while isinstance(value, dict):
        value = value.get("text")
    return value if isinstance(value, str) else ""


def build_resource(resource: dict, input_dir: Path, data_dir: Path) -> dict:
    app_manifest = read_json(input_dir / "manifest.json")
    meta = resource.get("metadata", {})
    res_dir = data_dir / "resources" / resource["resourceId"]
    (res_dir / "books").mkdir(parents=True, exist_ok=True)
    (res_dir / "sections").mkdir(parents=True, exist_ok=True)

    books_index = []
    sections_index = []
    total_verses = 0
    books_source = app_manifest.get("books") or []

    if books_source:
        # Biblia: un libro por archivo y una sección por capítulo.
        for book in books_source:
            code = book["code"]
            book_path = input_dir / "books" / f"{code}.json"
            book_doc = read_json(book_path)
            write_json(res_dir / "books" / f"{code}.json", book_doc)
            books_index.append(book)

            for chapter in book_doc["chapters"]:
                section_id = f"{code}.{chapter['n']}"
                section = {
                    "id": section_id,
                    "resourceId": resource["resourceId"],
                    "title": f"{book['name']} {chapter['n']}",
                    "book": code,
                    "chapter": chapter["n"],
                    "blocks": chapter["blocks"],
                }
                if chapter.get("footnotes"):
                    section["footnotes"] = chapter["footnotes"]
                write_json(res_dir / "sections" / f"{section_id}.json", section)
                sections_index.append(
                    {"id": section_id, "book": code, "chapter": chapter["n"],
                     "title": section["title"]}
                )
                total_verses += sum(
                    len(block["verses"])
                    for block in chapter["blocks"]
                    if block.get("type") == "verseGroup"
                )
    else:
        # Comentario o diccionario: índice de metadatos + una sección por
        # archivo. Así el panel carga solo la entrada que muestra y el índice
        # de búsqueda puede leer el texto completo al construirse.
        input_index = input_dir / "sections.json"
        if not input_index.exists() and not Path(f"{input_index}.gz").exists():
            raise SystemExit(
                f"ERROR: {input_dir} no es una Biblia ni tiene sections.json"
            )
        input_sections = read_json(input_index)
        for entry in input_sections:
            section_id = entry.get("id")
            if not section_id:
                raise SystemExit(f"ERROR: sección sin id en {input_index}")
            section_path = input_dir / "sections" / f"{section_id}.json"
            if section_path.exists():
                full_section = read_json(section_path)
            elif isinstance(entry.get("blocks"), list):
                # Recursos con secciones embebidas (léxico Strong): el cuerpo
                # viaja en sections.json para no crear miles de archivos.
                full_section = dict(entry)
            else:
                raise SystemExit(f"ERROR: falta la sección {section_path}")
            if resource["resourceId"] == "commentary.matthew-henry-concise":
                map_key = COMMENTARY_MAPS.get(section_id)
                if map_key:
                    maps = read_json(MAPS_CONFIG).get("maps", {})
                    if map_key in maps:
                        blocks = full_section.setdefault("blocks", [])
                        if not any(
                            block.get("type") == "map" for block in blocks
                        ):
                            blocks.append({"type": "map", **maps[map_key]})
            write_json(
                res_dir / "sections" / f"{section_id}.json", full_section
            )
            metadata = dict(entry)
            metadata.setdefault("title", full_section.get("title", section_id))
            sections_index.append(metadata)

    manifest = prune({
        "id": resource["resourceId"],
        "resourceId": resource["resourceId"],
        "type": resource.get("type", "document"),
        "title": app_manifest.get("title"),
        "subtitle": meta.get("subtitle"),
        "abbrev": app_manifest.get("abbrev"),
        "authors": meta.get("authors", []),
        "language": app_manifest.get("language"),
        "publisher": meta.get("publisher"),
        "edition": meta.get("edition"),
        "source": app_manifest.get("source"),
        "license": {
            "kind": meta.get("licenseKind", "unknown"),
            "text": license_text(app_manifest.get("license")),
        },
        "description": meta.get("description"),
        "tags": meta.get("tags", []),
        "attributes": meta.get("attributes", {}),
        "stats": {
            "books": len(books_index),
            "sections": len(sections_index),
            "verses": total_verses,
        },
        "updatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "books": books_index,
    })
    write_json(res_dir / "manifest.json", manifest)
    write_json(res_dir / "sections.json", sections_index)
    log(
        f"· {manifest['id']}: {manifest['stats']['books']} libros, "
        f"{manifest['stats']['sections']} secciones, "
        f"{manifest['stats']['verses']} versículos"
    )
    return manifest


# ------------------------------------------------------------------- índice

SCHEMA = """
CREATE TABLE resources(
  id TEXT PRIMARY KEY, type TEXT NOT NULL, title TEXT NOT NULL, abbrev TEXT,
  language TEXT, authors TEXT, tags TEXT, verse_count INTEGER
);
CREATE TABLE sections(
  resource_id TEXT NOT NULL, section_id TEXT NOT NULL, ord INTEGER NOT NULL,
  book TEXT NOT NULL, book_name TEXT NOT NULL, chapter INTEGER NOT NULL,
  title TEXT NOT NULL,
  PRIMARY KEY(resource_id, section_id)
);
CREATE TABLE cross_references(
  source_ref TEXT NOT NULL, target_ref TEXT NOT NULL, rank INTEGER NOT NULL,
  PRIMARY KEY(source_ref, target_ref)
);
CREATE INDEX cross_references_source ON cross_references(source_ref);
CREATE VIRTUAL TABLE verses USING fts5(
  resource_id UNINDEXED, section_id UNINDEXED, book UNINDEXED,
  book_name UNINDEXED, chapter UNINDEXED, verse UNINDEXED, text,
  tokenize = 'unicode61 remove_diacritics 2'
);
"""


def build_index(data_dir: Path, manifests: list[dict]) -> tuple[int, int]:
    index_dir = data_dir / "index"
    index_dir.mkdir(parents=True, exist_ok=True)
    db_path = index_dir / "search.sqlite"
    if db_path.exists():
        db_path.unlink()

    con = sqlite3.connect(db_path)
    con.executescript(SCHEMA)
    total_sections = 0
    total_entries = 0

    for manifest in manifests:
        rid = manifest["id"]
        con.execute(
            "INSERT INTO resources VALUES(?,?,?,?,?,?,?,?)",
            (rid, manifest["type"], manifest["title"], manifest.get("abbrev"),
             manifest.get("language"), ", ".join(manifest.get("authors", [])),
             ", ".join(manifest.get("tags", [])), 0),
        )
        order = 0
        entries = 0

        if manifest.get("books"):
            # Biblia: una fila FTS por versículo.
            for book in manifest["books"]:
                book_doc = read_json(
                    data_dir / "resources" / rid / "books" / f"{book['code']}.json"
                )
                for chapter in book_doc["chapters"]:
                    section_id = f"{book['code']}.{chapter['n']}"
                    con.execute(
                        "INSERT INTO sections VALUES(?,?,?,?,?,?,?)",
                        (rid, section_id, order, book["code"], book["name"],
                         chapter["n"], f"{book['name']} {chapter['n']}"),
                    )
                    order += 1
                    total_sections += 1
                    for block in chapter["blocks"]:
                        if block.get("type") != "verseGroup":
                            continue
                        for verse in block["verses"]:
                            text = verse_text(verse)
                            if not text:
                                continue
                            con.execute(
                                "INSERT INTO verses(resource_id,section_id,book,book_name,"
                                "chapter,verse,text) VALUES(?,?,?,?,?,?,?)",
                                (rid, section_id, book["code"], book["name"],
                                 chapter["n"], verse["n"], text),
                            )
                            entries += 1
                            total_entries += 1
        else:
            # Comentario, diccionario, Factbook y devocional: una fila FTS
            # por sección. Los recursos grandes guardan el cuerpo en
            # `sections/<id>.json`; el índice solo trae los metadatos.
            # Para que el .sqlite.gz siga siendo publicable (<100 MB en
            # GitHub/Pages), el texto indexado por sección se acota: el
            # cuerpo completo vive en la sección que la app carga por id.
            sections = read_json(data_dir / "resources" / rid / "sections.json")
            for section in sections:
                section_id = section["id"]
                title = section.get("title") or section_id
                section_path = (
                    data_dir / "resources" / rid / "sections"
                    / f"{section_id}.json"
                )
                full_section = (
                    read_json(section_path) if section_path.exists() else section
                )
                con.execute(
                    "INSERT INTO sections VALUES(?,?,?,?,?,?,?)",
                    (rid, section_id, order, "", title, 0, title),
                )
                order += 1
                total_sections += 1
                text = section_text(full_section)[:SECTION_INDEX_CHARS]
                if text:
                    con.execute(
                        "INSERT INTO verses(resource_id,section_id,book,book_name,"
                        "chapter,verse,text) VALUES(?,?,?,?,?,?,?)",
                        (rid, section_id, "", title, 0, 0, text),
                    )
                    entries += 1
                    total_entries += 1

        con.execute(
            "UPDATE resources SET verse_count = ? WHERE id = ?", (entries, rid)
        )

    # Referencias cruzadas del TSK. Es una tabla auxiliar del lector; no
    # genera resultados de búsqueda por sí misma.
    xrefs_path = data_dir / "cross_references.json"
    xref_links = 0
    if xrefs_path.exists():
        payload = read_json(xrefs_path)
        for entry in payload.get("entries", []):
            source = entry.get("ref")
            if not source:
                continue
            for rank, target in enumerate(entry.get("targets", [])):
                if not target:
                    continue
                con.execute(
                    "INSERT OR IGNORE INTO cross_references VALUES(?,?,?)",
                    (source, target, rank),
                )
                xref_links += 1

    con.execute("INSERT INTO verses(verses) VALUES('optimize')")
    con.commit()
    con.close()
    log(
        f"· índice: {total_sections} secciones, {total_entries} entradas "
        f"(versículos y artículos), {xref_links} referencias cruzadas "
        f"→ {db_path}"
    )
    return total_sections, total_entries


# -------------------------------------------------------------------- main


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--config", default="catalog/config/resources.json")
    ap.add_argument("--data", default="catalog/data")
    ap.add_argument("--only", action="append", default=None,
                    help="construir solo estos resourceId (repetible)")
    ap.add_argument("--skip-index", action="store_true")
    args = ap.parse_args()

    config_path = Path(args.config)
    if not config_path.is_absolute():
        config_path = ROOT / config_path
    data_dir = Path(args.data)
    if not data_dir.is_absolute():
        data_dir = ROOT / data_dir
    sources_dir = ROOT / "catalog" / "sources"

    config = read_json(config_path)
    resources = [
        r for r in config["resources"]
        if not args.only or r["resourceId"] in args.only
    ]
    if not resources:
        raise SystemExit("ERROR: no hay recursos que construir")

    manifests = []
    for resource in resources:
        log(f"→ {resource['resourceId']}")
        input_dir = ensure_input(resource, sources_dir)
        manifests.append(build_resource(resource, input_dir, data_dir))

    # Conserva e indexa los recursos ya presentes que no se reconstruyen en
    # esta pasada (p. ej. Factbook y devocional generados por `seed_m5.py`).
    built_ids = {m["id"] for m in manifests}
    catalog_path = data_dir / "catalog.json"
    if catalog_path.exists():
        for entry in read_json(catalog_path).get("resources", []):
            if entry["id"] in built_ids:
                continue
            manifest_path = data_dir / entry["path"] / "manifest.json"
            if manifest_path.exists():
                manifests.append(read_json(manifest_path))
                built_ids.add(entry["id"])

    write_json(
        catalog_path,
        {
            "generatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "resources": [
                {"id": m["id"], "path": f"resources/{m['id']}"} for m in manifests
            ],
        },
    )

    if not args.skip_index:
        xrefs_path = data_dir / "cross_references.json"
        if not xrefs_path.exists():
            log("· preparando referencias cruzadas del TSK")
            subprocess.run(
                [
                    sys.executable,
                    str(TOOLS / "import_content.py"),
                    "--only", "xrefs",
                ],
                check=True,
            )
        build_index(data_dir, manifests)

    log(f"OK: {len(manifests)} recursos en {data_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
