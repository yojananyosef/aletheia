#!/usr/bin/env python3
"""Genera el léxico Strong hebreo/griego para el catálogo.

Fuentes:
- TBESH/TBESG de STEPBible.org (CC BY 4.0): lema, transliteración,
  morfología breve y glosa. De TBESH **no** se usa la columna ``Meaning``
  (procede del Abridged BDB de Online Bible y STEPBible pide permiso aparte).
- Strong's Hebrew Dictionary de CrossWire (dominio público): definición
  hebrea en inglés. La definición griega se toma de TBESG (CC BY 4.0).

El resultado es un recurso de secciones embebidas: ``sections.json`` contiene
metadatos y bloques de cada entrada. Así se evita distribuir ~17.000 archivos.
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

from stepbible_common import (
    SPANISH_GLOSS,
    STEP_DIR,
    clean_definition,
    clean_gloss,
    clean_hebrew,
    write_morphology_map,
)

ROOT = Path(__file__).resolve().parents[2]
LEXICON_SOURCE = ROOT / "catalog" / "sources" / "lexicon"
MORPH_PATH = ROOT / "catalog" / "data" / "morphology.json"

STRONGS_HEBREW_URL = (
    "https://www.crosswire.org/sword/modules/ModInfo.jsp?modName=StrongsHebrew"
)
STEP_URL = "https://github.com/STEPBible/STEPBible-Data"


def parse_strongs_hebrew(path: Path) -> dict[str, str]:
    """Devuelve H0001..H8674 -> definición de Strong (inglés, PD)."""
    text = path.read_text(encoding="utf-8", errors="replace")
    out: dict[str, str] = {}
    for match in re.finditer(
        r"\$\$T(\d{7})\s*\n\\\d{5}\\\s*\n(.*?)(?=\$\$T|\Z)",
        text,
        re.S,
    ):
        number = int(match.group(1))
        body = match.group(2)
        lines = body.splitlines()
        # Primera línea: número, lema ASCII y pronunciación.
        if lines and re.match(r"^\s*\d+\s", lines[0]):
            lines = lines[1:]
        definition = "\n".join(lines)
        definition = re.sub(
            r"(?im)^\s*see (?:HEBREW|GREEK) for .*$", "", definition
        )
        definition = re.sub(r"\n{3,}", "\n\n", definition).strip()
        out[f"H{number:04d}"] = definition
    return out


def parse_brief_lexicon(path: Path) -> dict[str, list[dict]]:
    rows: dict[str, list[dict]] = {}
    for line in path.read_text(encoding="utf-8-sig").splitlines():
        if "\t" not in line:
            continue
        cols = line.split("\t")
        if len(cols) < 7 or not re.match(r"^[HG]\d{4}[a-z]?$", cols[0]):
            continue
        # TBESH usa subentradas H0122a/H0122b para los matices de un mismo
        # Strong. El texto enlaza al Strong base, así que se agrupan aquí y
        # los matices aparecen en «Sentidos».
        strong = cols[0][:5]
        rows.setdefault(strong, []).append(
            {
                "dstrong": cols[1].strip(),
                "lemma": cols[3].strip(),
                "translit": cols[4].strip(),
                "morph": cols[5].strip(),
                "gloss": clean_gloss(cols[6]),
                "meaning": cols[7] if len(cols) > 7 else "",
            }
        )
    return rows


def main_row(rows: list[dict]) -> dict:
    for row in rows:
        if row["lemma"] and "Part of" not in row["dstrong"]:
            return row
    return rows[0]


def senses_for(rows: list[dict], main: dict) -> list[str]:
    out: list[str] = []
    for row in rows:
        if "Part of" in row["dstrong"]:
            continue
        # En hebreo, las filas con otro lema suelen ser compuestos o
        # homógrafos; se conservan solo si la glosa aporta un sentido.
        gloss = row["gloss"]
        if not gloss:
            continue
        if row["lemma"] != main["lemma"] and row["dstrong"].startswith(
            main["lemma"]
        ):
            continue
        if gloss not in out:
            out.append(gloss)
        if len(out) >= 8:
            break
    return out


def build_entry(strong: str, rows: list[dict], strongs_def: str | None) -> dict:
    main = main_row(rows)
    lemma = clean_hebrew(main["lemma"]) if strong.startswith("H") else main["lemma"]
    translit = main["translit"]
    morph = main["morph"]
    gloss = main["gloss"]
    gloss_es = SPANISH_GLOSS.get(strong)
    summary = gloss_es or gloss or lemma
    title = strong
    if lemma:
        title += f" · {lemma}"
    elif translit:
        title += f" · {translit}"

    is_hebrew = strong.startswith("H")
    language = "Hebreo" if is_hebrew else "Griego"
    definition = ""
    definition_source = ""
    if is_hebrew:
        definition = (strongs_def or "").strip()
        definition_source = "Strong's Hebrew Dictionary (dominio público, inglés)"
    else:
        definition = clean_definition(main.get("meaning", ""))
        definition_source = "TBESG, STEPBible.org (CC BY 4.0, inglés)"
    if not definition:
        definition = gloss or "Sin definición disponible en la fuente."
        definition_source = "Glosa de la fuente"

    blocks: list[dict] = []
    head = []
    if lemma:
        head.append({"t": "span", "style": "italic", "v": lemma})
    if translit:
        if head:
            head.append({"t": "text", "v": f" · {translit}"})
        else:
            head.append({"t": "text", "v": translit})
    if morph:
        if head:
            head.append({"t": "text", "v": f" · {morph}"})
        else:
            head.append({"t": "text", "v": morph})
    if head:
        blocks.append({"type": "paragraph", "inlines": head})

    blocks.append({"type": "heading", "style": "section", "text": "Glosa"})
    gloss_parts = []
    if gloss_es:
        gloss_parts.append(gloss_es)
    if gloss and gloss.casefold() != (gloss_es or "").casefold():
        suffix = " (glosa de la fuente en inglés)" if gloss_es else ""
        gloss_parts.append(gloss + suffix)
    blocks.append(
        {
            "type": "paragraph",
            "inlines": [{"t": "text", "v": "; ".join(gloss_parts) or summary}],
        }
    )

    senses = senses_for(rows, main)
    if len(senses) > 1 or (senses and senses[0].casefold() != gloss.casefold()):
        blocks.append(
            {"type": "heading", "style": "section", "text": "Sentidos"}
        )
        numbered = "; ".join(
            f"{index}. {value}" for index, value in enumerate(senses, 1)
        )
        blocks.append(
            {"type": "paragraph", "inlines": [{"t": "text", "v": numbered}]}
        )

    blocks.append({"type": "heading", "style": "section", "text": "Definición"})
    blocks.append(
        {
            "type": "paragraph",
            "inlines": [
                {"t": "text", "v": definition.replace("\n", " ")},
                {"t": "text", "v": f"\n\n{definition_source}"},
            ],
        }
    )

    blocks.append(
        {"type": "heading", "style": "section", "text": "Fuente y licencia"}
    )
    source_lines = [
        "Lema, transliteración, morfología y glosa: "
        + ("TBESH" if is_hebrew else "TBESG")
        + ", STEPBible.org / Tyndale House Cambridge, CC BY 4.0."
    ]
    if is_hebrew:
        source_lines.append(
            "Definición: Strong's Hebrew Dictionary, dominio público "
            "(módulo StrongsHebrew de CrossWire)."
        )
    else:
        source_lines.append(
            "Definición: TBESG, STEPBible.org, CC BY 4.0."
        )
    source_lines.append(f"Fuente: {STEP_URL}")
    if is_hebrew:
        source_lines.append(f"Módulo: {STRONGS_HEBREW_URL}")
    blocks.append(
        {
            "type": "paragraph",
            "inlines": [{"t": "text", "v": "\n".join(source_lines)}],
        }
    )

    return {
        "id": strong,
        "title": title,
        "summary": (summary or lemma or strong)[:220],
        "referenceLabel": strong,
        "tags": [language, "Léxico", "Strong"],
        "blocks": blocks,
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--out-dir",
        default="catalog/sources/lexicon.strongs",
        help="Directorio de salida del recurso",
    )
    ap.add_argument(
        "--strongs-hebrew",
        default=str(LEXICON_SOURCE / "strongshebrew.dat"),
    )
    args = ap.parse_args()
    out_dir = Path(args.out_dir)
    if not out_dir.is_absolute():
        out_dir = ROOT / out_dir

    tbesh_path = next(STEP_DIR.glob("TBESH*.txt"))
    tbesg_path = next(STEP_DIR.glob("TBESG*.txt"))
    strongs_path = Path(args.strongs_hebrew)
    if not strongs_path.exists():
        raise SystemExit(
            f"ERROR: falta {strongs_path}. Descarga StrongsHebrew de CrossWire."
        )

    hebrew_rows = parse_brief_lexicon(tbesh_path)
    greek_rows = parse_brief_lexicon(tbesg_path)
    strongs_defs = parse_strongs_hebrew(strongs_path)

    entries: list[dict] = []
    morph_codes: set[str] = set()
    for strong in sorted(hebrew_rows):
        entry = build_entry(strong, hebrew_rows[strong], strongs_defs.get(strong))
        entries.append(entry)
        for row in hebrew_rows[strong]:
            if row["morph"]:
                morph_codes.add(row["morph"])
    for strong in sorted(greek_rows):
        entry = build_entry(strong, greek_rows[strong], None)
        entries.append(entry)
        for row in greek_rows[strong]:
            if row["morph"]:
                morph_codes.add(row["morph"])

    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "sections.json").write_text(
        json.dumps(entries, ensure_ascii=False, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )
    manifest = {
        "resourceId": "lexicon.strongs",
        "title": "Léxico Strong hebreo y griego",
        "abbrev": "Strong",
        "language": "mul",
        "source": STEP_URL,
        "license": (
            "TBESH/TBESG CC BY 4.0 (STEPBible.org / Tyndale House Cambridge); "
            "definiciones hebreas: Strong's Hebrew Dictionary, dominio público "
            "(CrossWire)."
        ),
        "attributes": {"embeddedSections": True, "strongs": True},
        "books": [],
    }
    (out_dir / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )
    write_morphology_map(morph_codes, greek=True, path=MORPH_PATH)
    size_mb = (out_dir / "sections.json").stat().st_size / (1024 * 1024)
    print(
        f"OK lexicon.strongs: {len(entries)} entradas "
        f"({len(hebrew_rows)} hebreas, {len(greek_rows)} griegas), "
        f"{size_mb:.1f} MB"
    )
    print(f"Salida: {out_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
