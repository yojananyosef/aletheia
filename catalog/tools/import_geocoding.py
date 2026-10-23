#!/usr/bin/env python3
"""Genera el gazetteer bíblico (dataset.gazetteer) para el catálogo.

Fuente: Bible-Geocoding-Data de OpenBible.info, CC BY 4.0.
  https://github.com/openbibleinfo/Bible-Geocoding-Data
  (archivo `data/ancient.jsonl`, lugares antiguos con coordenadas)

El archivo fuente no se redistribuye: se descarga a
`catalog/sources/geocoding/ancient.jsonl` y la herramienta lo convierte al
formato de documento del catálogo, estilo diccionario: `sections.json` con el
índice (id, título, resumen, etiquetas) y `sections/<id>.json` con los bloques
de cada lugar. Solo se conservan lugares con coordenadas de resolución
(`identifications[0].resolutions[0].lonlat`, orden «lon,lat» en la fuente) y
referencias con código reconocido por la app (`verses[].usx`, que coincide con
los códigos canónicos de la app).

Los nombres de libro en español salen del manifest de bible.rv1909 (assets).

Uso:
  python3 catalog/tools/import_geocoding.py
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

GEO_DIR = ROOT / "catalog" / "sources" / "geocoding"
DATA_MANIFEST = ROOT / "catalog" / "data" / "resources" / "bible.rv1909" / "manifest.json"
ASSETS_MANIFEST = ROOT / "app" / "assets" / "catalog" / "rv1909" / "manifest.json"

SOURCE_URL = "https://github.com/openbibleinfo/Bible-Geocoding-Data"
LICENSE_TEXT = (
    "CC BY 4.0 — OpenBible.info (Bible-Geocoding-Data); "
    "geometría de OpenStreetMap (ODbL)"
)

TAGS = ["Lugares"]

# Etiquetas en español para los tipos del dataset (los menos frecuentes se
# muestran tal cual si no están en la tabla).
TYPE_LABELS = {
    "settlement": "poblado",
    "region": "región",
    "special": "lugar singular",
    "mountain": "monte",
    "river": "río",
    "valley": "valle",
    "campsite": "campamento",
    "gate": "puerta",
    "island": "isla",
    "hill": "colina",
    "spring": "manantial",
    "body of water": "cuerpo de agua",
    "natural area": "área natural",
    "structure": "estructura",
    "wadi": "wadi",
    "mountain range": "cordillera",
    "tree": "árbol",
    "pool": "estanque",
    "road": "camino",
    "people group": "pueblo",
    "altar": "altar",
    "well": "pozo",
    "district in settlement": "barrio",
    "field": "campo",
    "garden": "huerto",
    "hall": "salón",
    "mountain ridge": "crestería",
    "ford": "vado",
    "cliff": "acantilado",
    "rock": "roca",
    "stone heap": "mojón de piedras",
    "room": "cámara",
    "fortification": "fortificación",
    "mine": "mina",
    "promontory": "promontorio",
    "canal": "canal",
    "mountain pass": "paso de montaña",
    "forest": "bosque",
}

USX_RE = re.compile(r"^(?P<code>[A-Z0-9]{3})\s+(?P<ch>\d{1,3}):(?P<vs>\d{1,3})$")
MAX_REFS = 10


def log(message: str) -> None:
    print(f"· {message}")


def read_json(path: Path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def write_json(path: Path, payload) -> None:
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Path(path).write_text(
        json.dumps(payload, ensure_ascii=False, indent=1) + "\n",
        encoding="utf-8",
    )


def asciifold(text: str) -> str:
    decomposed = unicodedata.normalize("NFKD", text)
    return "".join(ch for ch in decomposed if not unicodedata.combining(ch))


def load_book_names() -> dict[str, str]:
    """Códigos de libro de la app → nombre en español (manifest RV1909)."""
    source = DATA_MANIFEST if DATA_MANIFEST.exists() else ASSETS_MANIFEST
    if not source.exists():
        raise SystemExit(f"ERROR: no hay manifest rv1909 en {source}")
    names = {}
    for book in read_json(source).get("books") or []:
        code, name = book.get("code"), book.get("name")
        if code and name:
            names[code] = name
    if len(names) != 66:
        raise SystemExit(f"ERROR: rv1909 con {len(names)} libros (esperados 66)")
    return names


def parse_lonlat(record: dict) -> tuple[float, float] | None:
    try:
        lonlat = record["identifications"][0]["resolutions"][0]["lonlat"]
    except (KeyError, IndexError, TypeError):
        return None
    if not isinstance(lonlat, str) or "," not in lonlat:
        return None
    try:
        lon, lat = (float(part) for part in lonlat.split(",")[:2])
    except ValueError:
        return None
    return lat, lon


def parse_refs(record: dict, book_names: dict[str, str]) -> list[dict]:
    refs, unknown = [], set()
    for verse in record.get("verses") or []:
        match = USX_RE.match(str(verse.get("usx") or ""))
        if not match:
            continue
        code = match.group("code")
        if code not in book_names:
            unknown.add(code)
            continue
        refs.append(
            {
                "sort": int(str(verse.get("sort") or "0")),
                "ref": code,
                "book": code,
                "chapter": int(match.group("ch")),
                "verse": int(match.group("vs")),
            }
        )
    if unknown:
        log(f"tipos desconocidos en {record.get('friendly_id')}: {sorted(unknown)}")
    refs.sort(key=lambda item: (item["sort"], item["ref"], item["chapter"], item["verse"]))
    return refs


def display_ref(ref: dict, book_names: dict[str, str]) -> str:
    return f"{book_names[ref['book']]} {ref['chapter']}:{ref['verse']}"


def blocks_for(record: dict, lat: float, lon: float, refs: list[dict],
               book_names: dict[str, str]) -> list[dict]:
    def paragraph(text: str) -> dict:
        return {"type": "paragraph", "inlines": [{"t": "text", "v": text}]}

    raw_types = list(record.get("types") or [])
    types = [
        TYPE_LABELS.get(item, item) for item in raw_types
    ] or ["lugar"]

    blocks = [
        paragraph(
            f"Lugar bíblico ({', '.join(types)}). "
            f"Coordenadas: {lat:.4f}, {lon:.4f} (latitud, longitud)."
        )
    ]
    if refs:
        shown = [display_ref(ref, book_names) for ref in refs[:MAX_REFS]]
        rest = len(refs) - len(shown)
        text = "Aparece en: " + "; ".join(shown)
        if rest > 0:
            noun = "menciones" if rest != 1 else "mención"
            text += f" y {rest} {noun} más"
        text += "."
        blocks.append(paragraph(text))
    return blocks


def build(in_path: Path, out_dir: Path) -> None:
    if not in_path.exists():
        raise SystemExit(
            f"ERROR: falta {in_path}. Descarga data/ancient.jsonl de\n"
            f"  {SOURCE_URL}\ny colócalo en esa ruta (no se redistribuye)."
        )
    book_names = load_book_names()
    latlon_dir = out_dir / "sections"
    latlon_dir.mkdir(parents=True, exist_ok=True)

    index: list[dict] = []
    kept, skipped_geo = 0, 0
    for line in in_path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        record = json.loads(line)
        name = str(record.get("friendly_id") or "").strip()
        if not name:
            continue
        coords = parse_lonlat(record)
        if coords is None:
            skipped_geo += 1
            continue
        lat, lon = coords
        refs = parse_refs(record, book_names)
        slug = asciifold(str(record.get("url_slug") or name)).strip().lower()
        slug = re.sub(r"[^a-z0-9-]+", "-", slug).strip("-")
        if not slug:
            slug = f"lugar-{len(index) + 1:04d}"

        primary = display_ref(refs[0], book_names) if refs else "sin referencia"
        more = len(refs) - 1
        summary = (
            f"Lugar bíblico en {lat:.4f}, {lon:.4f}. "
            f"Aparece en {primary}"
            + (f" y {more} más" if more > 0 else "")
            + "."
        )
        section = {
            "id": slug,
            "title": name,
            "summary": summary,
            "tags": TAGS,
            "blocks": blocks_for(record, lat, lon, refs, book_names),
        }
        write_json(latlon_dir / f"{slug}.json", section)
        index.append(
            {
                "id": slug,
                "title": name,
                "summary": summary,
                "tags": TAGS,
            }
        )
        kept += 1

    index.sort(key=lambda entry: asciifold(entry["title"]).casefold())
    manifest = {
        "resourceId": "dataset.gazetteer",
        "id": "dataset.gazetteer",
        "title": "Gazetteer bíblico",
        "abbrev": "GAZ",
        "language": "es",
        "source": SOURCE_URL,
        "license": LICENSE_TEXT,
        "description": (
            "Gazetteer de lugares bíblicos antiguos con coordenadas, tipo de "
            "emplazamiento y referencias donde aparecen. Datos de "
            "OpenBible.info (Bible-Geocoding-Data, CC BY 4.0); coordenadas "
            "derivadas de OpenStreetMap (ODbL)."
        ),
        "books": [],
    }
    write_json(out_dir / "manifest.json", manifest)
    write_json(out_dir / "sections.json", index)
    log(
        f"OK dataset.gazetteer: {kept} lugares "
        f"({skipped_geo} descartados sin coordenadas)"
    )
    log(f"Salida: {out_dir}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--in", dest="source", default=str(GEO_DIR / "ancient.jsonl"))
    ap.add_argument(
        "--out-dir", default=str(ROOT / "catalog" / "sources" / "gazetteer")
    )
    args = ap.parse_args()
    build(Path(args.source), Path(args.out_dir))
    return 0


if __name__ == "__main__":
    sys.exit(main())
