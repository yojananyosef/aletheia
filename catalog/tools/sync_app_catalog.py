#!/usr/bin/env python3
"""Sincroniza el catálogo construido con los assets de la app.

Toma `catalog/data/` (creado por `build_catalog.py` y `seed_m5.py`) y deja en
`app/assets/catalog/`:

  index.json                 summaries de todos los recursos (Biblioteca local)
  <recurso>/manifest.json    manifiesto en formato de app
  <recurso>/books/*.json.gz  contenido comprimido de las Biblias
  <recurso>/sections.json.gz índice de secciones (Factbook, devocional,
                             comentario, diccionario y léxico)
  <recurso>/sections/*.json  cuerpo de comentario y diccionario
  search.sqlite.gz           índice FTS5 comprimido (búsqueda sin servicio)
  search.meta.json           hash y tamaño para extraer/verificar el índice

El nombre del archivo extraído en tiempo de ejecución incluye el hash del
índice: al cambiar el catálogo, la app no reutiliza una copia vieja.

Uso (desde la raíz del repo):
  python3 catalog/tools/import_content.py --all
  python3 catalog/tools/build_catalog.py
  python3 catalog/tools/seed_m5.py
  python3 catalog/tools/sync_app_catalog.py
"""
from __future__ import annotations

import gzip
import hashlib
import json
import shutil
import sqlite3
from datetime import datetime, timezone
from pathlib import Path

from build_catalog import build_index

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "catalog" / "data"
ASSETS = ROOT / "app" / "assets" / "catalog"

# El id del recurso no siempre coincide con el directorio histórico de assets.
DIRECTORIES = {
    "bible.rv1909": "rv1909",
    "bible.kjv": "kjv",
    "bible.asv": "asv",
    "bible.bll": "bll",
    "bible.tahot": "tahot",
    "bible.tagnt": "tagnt",
    "bible.sblm": "sblm",
    "bible.bes": "bes",
    "bible.vbl": "vbl",
    "lexicon.strongs": "lexicon.strongs",
    "devotional.daily": "devotional.daily",
    "factbook.core": "factbook.core",
    "commentary.matthew-henry-concise": "matthew-henry-concise",
    "dictionary.easton": "easton",
}


def read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, ensure_ascii=False, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )


def summary(manifest: dict) -> dict:
    """Ficha plana que consume `ResourceSummary.fromJson` en modo local."""
    return {
        "id": manifest["id"],
        "resourceId": manifest["id"],
        "type": manifest.get("type", "document"),
        "title": manifest.get("title", ""),
        "subtitle": manifest.get("subtitle"),
        "abbrev": manifest.get("abbrev"),
        "authors": manifest.get("authors", []),
        "language": manifest.get("language", ""),
        "publisher": manifest.get("publisher"),
        "edition": manifest.get("edition"),
        "license": manifest.get("license", {}),
        "description": manifest.get("description"),
        "tags": manifest.get("tags", []),
        "stats": manifest.get("stats", {}),
        "updatedAt": manifest.get("updatedAt"),
        "books": [],
    }


def write_gzip(source: Path, dest: Path) -> None:
    """Escribe JSON comprimido y elimina una copia plana anterior."""
    dest.write_bytes(gzip.compress(source.read_bytes(), compresslevel=9, mtime=0))
    plain = dest.with_suffix("")
    if plain != dest and plain.exists():
        plain.unlink()


def copy_resource(resource_id: str, base: Path, manifest: dict) -> Path:
    dest = ASSETS / DIRECTORIES.get(resource_id, resource_id.split(".")[-1])
    dest.mkdir(parents=True, exist_ok=True)
    write_json(dest / "manifest.json", manifest)

    books = manifest.get("books") or []
    if books:
        # Los libros completos (especialmente TAHOT/TAGNT) comprimen muy bien
        # y se leen de forma transparente con `loadCatalogAssetText`.
        book_dir = dest / "books"
        book_dir.mkdir(exist_ok=True)
        for book in books:
            code = book["code"]
            write_gzip(
                base / "books" / f"{code}.json",
                book_dir / f"{code}.json.gz",
            )
    else:
        sections = base / "sections.json"
        if not sections.exists():
            raise SystemExit(f"ERROR: falta {sections} para {resource_id}")
        write_gzip(sections, dest / "sections.json.gz")
        section_dir = base / "sections"
        embedded = bool((manifest.get("attributes") or {}).get("embeddedSections"))
        if section_dir.exists() and not embedded:
            target = dest / "sections"
            if target.exists():
                shutil.rmtree(target)
            shutil.copytree(section_dir, target)
    return dest


def main() -> int:
    catalog_path = DATA / "catalog.json"
    index_path = DATA / "index" / "search.sqlite"
    if not catalog_path.exists() or not index_path.exists():
        raise SystemExit(
            "ERROR: falta el catálogo construido en catalog/data/.\n"
            "  ejecuta: python3 catalog/tools/build_catalog.py\n"
            "           python3 catalog/tools/seed_m5.py"
        )

    entries = read_json(catalog_path)["resources"]
    summaries = []
    manifests = []
    for entry in entries:
        base = DATA / entry["path"]
        manifest = read_json(base / "manifest.json")
        resource_id = manifest["id"]
        manifests.append(manifest)
        copy_resource(resource_id, base, manifest)
        summaries.append(summary(manifest))
        print(
            f"· {resource_id}: {manifest.get('stats', {}).get('books', 0)} libros, "
            f"{manifest.get('stats', {}).get('sections', 0)} secciones"
        )

    morph = DATA / "morphology.json"
    if morph.exists():
        shutil.copyfile(morph, ASSETS / "morphology.json")

    write_json(ASSETS / "index.json", summaries)

    # Reconstruye el índice con todos los recursos (Biblias + Factbook +
    # devocional) para no depender de que el último build haya incluido M5.
    build_index(DATA, manifests)

    db_bytes = index_path.read_bytes()
    digest = hashlib.sha256(db_bytes).hexdigest()[:16]
    compressed = gzip.compress(db_bytes, compresslevel=9, mtime=0)
    (ASSETS / "search.sqlite.gz").write_bytes(compressed)

    con = sqlite3.connect(f"file:{index_path}?mode=ro", uri=True)
    try:
        indexed_verses = con.execute(
            "SELECT COUNT(*) FROM verses WHERE book != ''"
        ).fetchone()[0]
        indexed_sections = con.execute(
            "SELECT COUNT(*) FROM verses WHERE book = ''"
        ).fetchone()[0]
        indexed_entries = indexed_verses + indexed_sections
        indexed_cross_references = con.execute(
            "SELECT COUNT(*) FROM cross_references"
        ).fetchone()[0]
        indexed_ids = {row[0] for row in con.execute("SELECT id FROM resources")}
        indexed_resources = len(indexed_ids)
    finally:
        con.close()

    expected_ids = {manifest["id"] for manifest in manifests}
    missing = sorted(expected_ids - indexed_ids)
    if missing or indexed_verses <= 0 or indexed_sections <= 0:
        raise SystemExit(
            "ERROR: el índice no contiene todos los recursos del catálogo "
            f"(faltan: {', '.join(missing) or 'ninguna'}).\n"
            "  vuelve a ejecutar build_catalog.py y seed_m5.py."
        )

    write_json(
        ASSETS / "search.meta.json",
        {
            "schema": 1,
            "indexHash": digest,
            "bytes": len(db_bytes),
            "compressedBytes": len(compressed),
            "indexedResources": indexed_resources,
            "indexedVerses": indexed_verses,
            "indexedSections": indexed_sections,
            "indexedEntries": indexed_entries,
            "indexedCrossReferences": indexed_cross_references,
            "builtAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        },
    )
    print(
        f"· índice: {indexed_resources} recursos, {indexed_verses} versículos, "
        f"{indexed_sections} secciones no bíblicas, "
        f"{indexed_cross_references} referencias cruzadas "
        f"({len(compressed) / 1_000_000:.1f} MB comprimido, hash {digest})"
    )
    print(f"OK: {len(summaries)} recursos sincronizados en {ASSETS}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
