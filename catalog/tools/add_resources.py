#!/usr/bin/env python3
"""Sincroniza recursos concretos hacia app/assets sin regenerar los demás.

`sync_app_catalog.py` replica el catálogo completo desde `catalog/data`;
este script es el camino quirúrgico cuando los assets del resto de recursos
ya están publicados y solo se añaden módulos nuevos: reutiliza las mismas
funciones (`copy_resource`, `summary`) sobre los recursos indicados, pega sus
fichas al final de `index.json` y refresca el módulo de búsqueda
(`search.sqlite.gz` + `search.meta.json`) a partir del índice ya construido.

Uso:
  python3 catalog/tools/add_resources.py \
      --only bible.bsb --only bible.web --only dataset.gazetteer
"""
from __future__ import annotations

import argparse
import gzip
import hashlib
import sqlite3
import sys
from datetime import datetime, timezone
from pathlib import Path

from sync_app_catalog import (
    ASSETS,
    DATA,
    copy_resource,
    read_json,
    summary,
    write_json,
)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--only",
        action="append",
        default=None,
        help="resourceId a publicar (repetible; por defecto los tres de esta pasada)",
    )
    args = parser.parse_args()
    # `action="append"` acumula sobre el default en vez de reemplazarlo: se
    # normaliza aquí para que --only sea quirúrgico de verdad.
    if args.only is None:
        args.only = ["bible.bsb", "bible.web", "dataset.gazetteer"]

    catalog_path = DATA / "catalog.json"
    index_path = DATA / "index" / "search.sqlite"
    if not catalog_path.exists() or not index_path.exists():
        raise SystemExit(
            "ERROR: falta el catálogo construido en catalog/data/.\n"
            "  ejecuta: python3 catalog/tools/build_catalog.py [--only ...]"
        )

    entries = {e["id"]: e for e in read_json(catalog_path)["resources"]}
    missing = [rid for rid in args.only if rid not in entries]
    if missing:
        raise SystemExit(
            f"ERROR: no están en catalog/data: {', '.join(missing)}"
        )

    summaries = read_json(ASSETS / "index.json")
    known = {s["id"] for s in summaries}
    unknown_new = [rid for rid in args.only if rid not in known]
    if any(rid in known for rid in args.only):
        raise SystemExit(
            "ERROR: el recurso ya está publicado en index.json; el sync "
            "dirigido solo añade módulos nuevos (usa sync_app_catalog.py "
            "para regenerar el catálogo completo)."
        )
    if unknown_new != args.only:
        print(f"· avisando: solo se añaden {unknown_new}")

    for rid in args.only:
        base = DATA / entries[rid]["path"]
        manifest = read_json(base / "manifest.json")
        assert manifest["id"] == rid, f"manifest {manifest['id']} != {rid}"
        dest = copy_resource(rid, base, manifest)
        summaries.append(summary(manifest))
        print(
            f"· {rid} → {dest.name}: "
            f"{manifest.get('stats', {}).get('books', 0)} libros, "
            f"{manifest.get('stats', {}).get('sections', 0)} secciones"
        )

    write_json(ASSETS / "index.json", summaries)

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

    expected = {e["id"] for e in read_json(catalog_path)["resources"]}
    missing_ids = sorted(expected - indexed_ids)
    if missing_ids or indexed_verses <= 0 or indexed_sections <= 0:
        raise SystemExit(
            f"ERROR: el índice no cubre el catálogo (faltan: "
            f"{', '.join(missing_ids) or 'ninguna'}). "
            "Vuelve a correr build_catalog.py."
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
    print(f"OK: index.json ahora lista {len(summaries)} recursos")
    return 0


if __name__ == "__main__":
    sys.exit(main())
