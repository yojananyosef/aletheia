#!/usr/bin/env python3
"""Prepara contenido público adicional para el catálogo.

Genera entradas en formato de app para los recursos de profundidad:

  commentary.matthew-henry-concise  Comentario conciso de Matthew Henry (CC0)
  dictionary.easton                 Diccionario bíblico de Easton (dominio público)
  catalog/data/cross_references.json
                                    Referencias cruzadas del Treasury of
                                    Scripture Knowledge (dominio público)

Las fuentes se descargan a `catalog/sources/` (ignorado por git) y el
resultado se escribe en el mismo directorio de fuentes. `build_catalog.py`
consume esos recursos declarados en `catalog/config/resources.json`.

Uso:
  python3 catalog/tools/import_content.py --only commentary
  python3 catalog/tools/import_content.py --only dictionary
  python3 catalog/tools/import_content.py --only xrefs
  python3 catalog/tools/import_content.py --all
"""
from __future__ import annotations

import argparse
import json
import re
import shutil
import tarfile
import urllib.request
import unicodedata
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCES = ROOT / "catalog" / "sources"
DATA = ROOT / "catalog" / "data"

COMMENTARY_ID = "commentary.matthew-henry-concise"
DICTIONARY_ID = "dictionary.easton"

COMMENTARY_URL = (
    "https://codeload.github.com/lyteword/mhenry-concise/tar.gz/refs/heads/main"
)
COMMENTARY_FALLBACK_URL = (
    "https://raw.githubusercontent.com/lyteword/mhenry-complete/"
    "main/volume-2/2-kings/chapter-1.md"
)
DICTIONARY_URL = (
    "https://huggingface.co/datasets/JWBickel/BibleDictionaries/"
    "resolve/main/Easton%27s%20Bible%20Dictionary.jsonl"
)
TSK_URL = "https://raw.githubusercontent.com/ariseshinestudio/TSK/main/tskxref.txt"

# (slug del repositorio, código USFM, nombre inglés)
COMMENTARY_BOOKS = [
    ("genesis", "GEN", "Genesis"),
    ("exodus", "EXO", "Exodus"),
    ("leviticus", "LEV", "Leviticus"),
    ("numbers", "NUM", "Numbers"),
    ("deuteronomy", "DEU", "Deuteronomy"),
    ("joshua", "JOS", "Joshua"),
    ("judges", "JDG", "Judges"),
    ("ruth", "RUT", "Ruth"),
    ("1-samuel", "1SA", "1 Samuel"),
    ("2-samuel", "2SA", "2 Samuel"),
    ("1-kings", "1KI", "1 Kings"),
    ("2-kings", "2KI", "2 Kings"),
    ("1-chronicles", "1CH", "1 Chronicles"),
    ("2-chronicles", "2CH", "2 Chronicles"),
    ("ezra", "EZR", "Ezra"),
    ("nehemiah", "NEH", "Nehemiah"),
    ("esther", "EST", "Esther"),
    ("job", "JOB", "Job"),
    ("psalms", "PSA", "Psalms"),
    ("proverbs", "PRO", "Proverbs"),
    ("ecclesiastes", "ECC", "Ecclesiastes"),
    ("song-of-solomon", "SNG", "Song of Solomon"),
    ("isaiah", "ISA", "Isaiah"),
    ("jeremiah", "JER", "Jeremiah"),
    ("lamentations", "LAM", "Lamentations"),
    ("ezekiel", "EZK", "Ezekiel"),
    ("daniel", "DAN", "Daniel"),
    ("hosea", "HOS", "Hosea"),
    ("joel", "JOL", "Joel"),
    ("amos", "AMO", "Amos"),
    ("obadiah", "OBA", "Obadiah"),
    ("jonah", "JON", "Jonah"),
    ("micah", "MIC", "Micah"),
    ("nahum", "NAM", "Nahum"),
    ("habakkuk", "HAB", "Habakkuk"),
    ("zephaniah", "ZEP", "Zephaniah"),
    ("haggai", "HAG", "Haggai"),
    ("zechariah", "ZEC", "Zechariah"),
    ("malachi", "MAL", "Malachi"),
    ("matthew", "MAT", "Matthew"),
    ("mark", "MRK", "Mark"),
    ("luke", "LUK", "Luke"),
    ("john", "JHN", "John"),
    ("acts", "ACT", "Acts"),
    ("romans", "ROM", "Romans"),
    ("1-corinthians", "1CO", "1 Corinthians"),
    ("2-corinthians", "2CO", "2 Corinthians"),
    ("galatians", "GAL", "Galatians"),
    ("ephesians", "EPH", "Ephesians"),
    ("philippians", "PHP", "Philippians"),
    ("colossians", "COL", "Colossians"),
    ("1-thessalonians", "1TH", "1 Thessalonians"),
    ("2-thessalonians", "2TH", "2 Thessalonians"),
    ("1-timothy", "1TI", "1 Timothy"),
    ("2-timothy", "2TI", "2 Timothy"),
    ("titus", "TIT", "Titus"),
    ("philemon", "PHM", "Philemon"),
    ("hebrews", "HEB", "Hebrews"),
    ("james", "JAS", "James"),
    ("1-peter", "1PE", "1 Peter"),
    ("2-peter", "2PE", "2 Peter"),
    ("1-john", "1JN", "1 John"),
    ("2-john", "2JN", "2 John"),
    ("3-john", "3JN", "3 John"),
    ("jude", "JUD", "Jude"),
    ("revelation", "REV", "Revelation"),
]

TSK_BOOKS = [
    "GEN", "EXO", "LEV", "NUM", "DEU", "JOS", "JDG", "RUT",
    "1SA", "2SA", "1KI", "2KI", "1CH", "2CH", "EZR", "NEH",
    "EST", "JOB", "PSA", "PRO", "ECC", "SNG", "ISA", "JER",
    "LAM", "EZK", "DAN", "HOS", "JOL", "AMO", "OBA", "JON",
    "MIC", "NAM", "HAB", "ZEP", "HAG", "ZEC", "MAL",
    "MAT", "MRK", "LUK", "JHN", "ACT", "ROM", "1CO", "2CO",
    "GAL", "EPH", "PHP", "COL", "1TH", "2TH", "1TI", "2TI",
    "TIT", "PHM", "HEB", "JAS", "1PE", "2PE", "1JN", "2JN",
    "3JN", "JUD", "REV",
]

TSK_ABBREVIATIONS = {
    "ge": "GEN", "ex": "EXO", "le": "LEV", "nu": "NUM", "de": "DEU",
    "jos": "JOS", "jud": "JDG", "ru": "RUT", "1sa": "1SA", "2sa": "2SA",
    "1ki": "1KI", "2ki": "2KI", "1ch": "1CH", "2ch": "2CH", "ezr": "EZR",
    "ne": "NEH", "es": "EST", "job": "JOB", "ps": "PSA", "pr": "PRO",
    "ec": "ECC", "so": "SNG", "isa": "ISA", "jer": "JER", "la": "LAM",
    "eze": "EZK", "da": "DAN", "ho": "HOS", "joe": "JOL", "am": "AMO",
    "ob": "OBA", "jon": "JON", "mic": "MIC", "na": "NAM", "hab": "HAB",
    "zep": "ZEP", "hag": "HAG", "zec": "ZEC", "mal": "MAL", "mt": "MAT",
    "mr": "MRK", "lu": "LUK", "joh": "JHN", "ac": "ACT", "ro": "ROM",
    "1co": "1CO", "2co": "2CO", "ga": "GAL", "eph": "EPH", "php": "PHP",
    "col": "COL", "1th": "1TH", "2th": "2TH", "1ti": "1TI", "2ti": "2TI",
    "tit": "TIT", "phm": "PHM", "heb": "HEB", "jas": "JAS", "1pe": "1PE",
    "2pe": "2PE", "1jo": "1JN", "2jo": "2JN", "3jo": "3JN", "jude": "JUD",
    "re": "REV",
}


def log(message: str) -> None:
    print(message, flush=True)


def write_json(path: Path, payload) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )


def download(url: str, path: Path, *, force: bool = False) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and path.stat().st_size > 0 and not force:
        return path
    log(f"· descargando {url}")
    request = urllib.request.Request(
        url, headers={"User-Agent": "AletheiaCatalog/1.0"}
    )
    with urllib.request.urlopen(request, timeout=180) as response:
        data = response.read()
    path.write_bytes(data)
    return path


def slugify(value: str) -> str:
    normalized = unicodedata.normalize("NFKD", value)
    ascii_value = "".join(c for c in normalized if not unicodedata.combining(c))
    ascii_value = ascii_value.lower()
    ascii_value = re.sub(r"[^a-z0-9]+", "-", ascii_value).strip("-")
    return ascii_value or "entrada"


def clean_markdown(value: str) -> str:
    value = re.sub(r"!\[([^\]]*)\]\([^)]*\)", r"\1", value)
    value = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", value)
    value = re.sub(r"<[^>]+>", "", value)
    value = value.replace("**", "").replace("__", "").replace("`", "")
    value = re.sub(r"(?<!\w)[*_](\S.*?\S)[*_](?!\w)", r"\1", value)
    value = value.replace("\u00a0", " ")
    value = re.sub(r"[ \t]+", " ", value)
    return value.strip()


def paragraph(text: str) -> dict:
    return {"type": "paragraph", "inlines": [{"t": "text", "v": text}]}


def heading(text: str) -> dict:
    return {"type": "heading", "text": text, "style": "section"}


def parse_front_matter(text: str) -> tuple[dict, str]:
    if not text.startswith("---"):
        return {}, text
    end = text.find("\n---", 3)
    if end == -1:
        return {}, text
    raw = text[3:end]
    body = text[end + 4 :]
    meta: dict[str, str] = {}
    lines = raw.splitlines()
    index = 0
    while index < len(lines):
        line = lines[index]
        if ":" not in line:
            index += 1
            continue
        key, value = line.split(":", 1)
        key = key.strip()
        value = value.strip()
        if value in (">", "|", ">-", "|-"):
            parts = []
            index += 1
            while index < len(lines) and (
                lines[index].startswith(" ") or not lines[index].strip()
            ):
                parts.append(lines[index].strip())
                index += 1
            meta[key] = " ".join(part for part in parts if part)
            continue
        if (value.startswith('"') and value.endswith('"')) or (
            value.startswith("'") and value.endswith("'")
        ):
            value = value[1:-1]
        meta[key] = value
        index += 1
    return meta, body


def markdown_blocks(body: str) -> tuple[list[dict], str]:
    """Convierte el cuerpo Markdown en bloques del contrato de secciones."""
    blocks: list[dict] = []
    first_paragraph = ""
    current: list[str] = []
    current_heading: str | None = None
    skipping_outline = False

    def flush() -> None:
        nonlocal first_paragraph
        text = clean_markdown(" ".join(current))
        current.clear()
        if not text:
            return
        if not first_paragraph:
            first_paragraph = text
        blocks.append(paragraph(text))

    for raw in body.splitlines():
        line = raw.strip()
        if not line:
            flush()
            continue
        if line.startswith("## "):
            flush()
            title = clean_markdown(line[3:].strip())
            if title.lower().endswith("outline"):
                skipping_outline = True
                current_heading = None
                continue
            skipping_outline = False
            current_heading = title
            blocks.append(heading(title))
            continue
        if line.startswith("# "):
            flush()
            skipping_outline = False
            current_heading = None
            continue
        if skipping_outline:
            continue
        if line.startswith("- ") or line.startswith("* "):
            # Las listas del sumario no aportan al cuerpo; el resumen ya las
            # recoge en los metadatos de la sección.
            continue
        if line.startswith(">"):
            line = line.lstrip("> ").strip()
        current.append(line)
    flush()
    return blocks, first_paragraph


def build_sections_resource(
    resource_id: str,
    title: str,
    abbrev: str,
    language: str,
    source_url: str,
    description: str,
    sections: list[dict],
    out_dir: Path,
    *,
    license_text: str = "Public Domain",
) -> None:
    if out_dir.exists():
        shutil.rmtree(out_dir)
    (out_dir / "sections").mkdir(parents=True)
    index = []
    for section in sections:
        section_id = section["id"]
        write_json(out_dir / "sections" / f"{section_id}.json", section)
        index.append(
            {
                key: section[key]
                for key in (
                    "id", "title", "summary", "reference", "referenceLabel",
                    "tags", "references", "day", "theme", "related",
                )
                if key in section
            }
        )
    write_json(out_dir / "sections.json", index)
    write_json(
        out_dir / "manifest.json",
        {
            "resourceId": resource_id,
            "id": resource_id,
            "title": title,
            "abbrev": abbrev,
            "language": language,
            "source": source_url,
            "license": license_text,
            "description": description,
            "books": [],
        },
    )
    log(f"· {resource_id}: {len(sections)} secciones → {out_dir}")


# ------------------------------------------------------------- comentario


def commentary_file_map(root: Path) -> dict[tuple[str, int], Path]:
    files: dict[tuple[str, int], Path] = {}
    for slug, code, _name in COMMENTARY_BOOKS:
        directory = root / slug
        if not directory.is_dir():
            continue
        for path in directory.glob("*.md"):
            if path.name == "_index.md":
                continue
            match = re.match(r"^(?:chapter|psalm)-(\d+)\.md$", path.name)
            if match:
                files[(code, int(match.group(1)))] = path
    return files


def import_commentary(force: bool = False) -> None:
    work = SOURCES / "_raw" / "mhenry-concise"
    archive = work / "mhenry-concise.tar.gz"
    download(COMMENTARY_URL, archive, force=force)
    extracted = work / "tree"
    if not extracted.exists() or force:
        if extracted.exists():
            shutil.rmtree(extracted)
        extracted.mkdir(parents=True)
        log(f"· extrayendo {archive.name}")
        with tarfile.open(archive, "r:gz") as tar:
            members = []
            for member in tar.getmembers():
                parts = Path(member.name).parts[1:]  # quita la raíz del tar
                if not parts:
                    continue
                target = extracted.joinpath(*parts)
                if member.isdir():
                    target.mkdir(parents=True, exist_ok=True)
                elif member.isfile() and parts[-1].endswith(".md"):
                    target.parent.mkdir(parents=True, exist_ok=True)
                    source = tar.extractfile(member)
                    if source is not None:
                        target.write_bytes(source.read())
    else:
        log(f"· usando fuentes ya extraídas en {extracted}")

    files = commentary_file_map(extracted)
    sections: list[dict] = []
    for slug, code, name in COMMENTARY_BOOKS:
        found = sorted(
            chapter for (book, chapter) in files if book == code
        )
        if not found:
            log(f"AVISO: el comentario no trae capítulos de {name} ({slug})")
            continue
        for chapter in found:
            path = files[(code, chapter)]
            meta, body = parse_front_matter(
                path.read_text(encoding="utf-8", errors="replace")
            )
            blocks, first_paragraph = markdown_blocks(body)
            if not blocks:
                continue
            summary = clean_markdown(meta.get("description", ""))
            summary = re.sub(r"^In this chapter:\s*", "", summary, flags=re.I)
            if not summary:
                summary = first_paragraph[:240]
            section_id = f"{code}.{chapter}"
            sections.append(
                {
                    "id": section_id,
                    "title": f"{name} {chapter}",
                    "summary": summary[:600],
                    "reference": section_id,
                    "referenceLabel": f"{name} {chapter}",
                    "tags": ["Comentario", "Matthew Henry"],
                    "blocks": blocks,
                }
            )

    # El repositorio conciso omite 2 Reyes 1. Se completa con el mismo autor
    # desde la edición completa (también CC0), sin inventar contenido.
    if ("2KI", 1) not in files:
        fallback = work / "2-kings-1.md"
        download(COMMENTARY_FALLBACK_URL, fallback, force=force)
        _meta, body = parse_front_matter(
            fallback.read_text(encoding="utf-8", errors="replace")
        )
        blocks, first_paragraph = markdown_blocks(body)
        if blocks:
            sections.append(
                {
                    "id": "2KI.1",
                    "title": "2 Kings 1",
                    "summary": (
                        "Capítulo tomado de la edición completa de Matthew "
                        "Henry porque falta en la edición concisa de origen."
                    ),
                    "reference": "2KI.1",
                    "referenceLabel": "2 Kings 1",
                    "tags": ["Comentario", "Matthew Henry"],
                    "blocks": blocks,
                }
            )
            log("· completado 2 Reyes 1 desde la edición completa")

    sections.sort(
        key=lambda section: (
            next(
                i for i, (_, code, _) in enumerate(COMMENTARY_BOOKS)
                if code == section["id"].split(".", 1)[0]
            ),
            int(section["id"].rsplit(".", 1)[1]),
        )
    )
    if len(sections) != 1189:
        log(f"AVISO: el comentario tiene {len(sections)} secciones (esperadas 1189)")

    build_sections_resource(
        COMMENTARY_ID,
        "Matthew Henry — Comentario conciso",
        "MHC",
        "en",
        "https://github.com/lyteword/mhenry-concise",
        (
            "Comentario conciso de Matthew Henry sobre los 66 libros de la "
            "Biblia, en inglés. Edición Markdown CC0 basada en el texto de "
            "dominio público; 2 Reyes 1 se completa desde la edición completa "
            "del mismo autor."
        ),
        sections,
        SOURCES / COMMENTARY_ID,
        license_text="CC0-1.0 (texto original de dominio público)",
    )


# ------------------------------------------------------------- diccionario


def import_dictionary(force: bool = False) -> None:
    work = SOURCES / "_raw" / "easton"
    raw_path = work / "easton.jsonl"
    download(DICTIONARY_URL, raw_path, force=force)
    entries: dict[str, list[str]] = {}
    for line in raw_path.read_text(encoding="utf-8", errors="replace").splitlines():
        if not line.strip():
            continue
        try:
            item = json.loads(line)
        except json.JSONDecodeError:
            continue
        term = str(item.get("term", "")).strip()
        definitions = item.get("definitions") or []
        if not term or not isinstance(definitions, list):
            continue
        clean_definitions = [
            clean_markdown(str(definition))
            for definition in definitions
            if str(definition).strip()
        ]
        if clean_definitions:
            entries.setdefault(term, []).extend(clean_definitions)

    used_ids: dict[str, int] = {}
    sections: list[dict] = []
    for term in sorted(entries, key=lambda value: value.casefold()):
        base_id = slugify(term)
        count = used_ids.get(base_id, 0)
        used_ids[base_id] = count + 1
        section_id = base_id if count == 0 else f"{base_id}-{count + 1}"
        definitions = entries[term]
        blocks = [paragraph(definition) for definition in definitions]
        summary = definitions[0][:260]
        sections.append(
            {
                "id": section_id,
                "title": term,
                "summary": summary,
                "tags": ["Diccionario", "Easton"],
                "blocks": blocks,
            }
        )

    build_sections_resource(
        DICTIONARY_ID,
        "Diccionario bíblico de Easton",
        "EBD",
        "en",
        "https://huggingface.co/datasets/JWBickel/BibleDictionaries",
        (
            "Diccionario bíblico de Matthew George Easton (1897), en inglés. "
            "Contiene nombres propios, lugares, objetos y temas de la Biblia; "
            "el texto original es de dominio público."
        ),
        sections,
        SOURCES / DICTIONARY_ID,
    )


# ------------------------------------------------------ referencias cruzadas


def parse_tsk_targets(raw: str) -> list[str]:
    targets: list[str] = []
    for part in raw.split(";"):
        part = part.strip().lower()
        if not part:
            continue
        match = re.match(r"^([1-3]?[a-z]{2,4})\s+(\d+):(.+)$", part)
        if not match:
            continue
        code = TSK_ABBREVIATIONS.get(match.group(1))
        if code is None:
            continue
        chapter = int(match.group(2))
        for segment in match.group(3).split(","):
            segment = segment.strip()
            verse_match = re.match(r"^(\d+)(?:-(\d+))?$", segment)
            if not verse_match:
                continue
            start = int(verse_match.group(1))
            end = int(verse_match.group(2)) if verse_match.group(2) else None
            if start <= 0 or (end is not None and end < start):
                continue
            target = f"{code}.{chapter}.{start}"
            if end is not None:
                target += f"-{end}"
            if target not in targets:
                targets.append(target)
    return targets


def import_xrefs(force: bool = False) -> None:
    work = SOURCES / "_raw" / "tsk"
    raw_path = work / "tskxref.txt"
    download(TSK_URL, raw_path, force=force)
    text = raw_path.read_bytes().decode("cp1252", errors="replace")
    by_source: dict[str, list[str]] = {}
    for line in text.splitlines():
        parts = line.split("\t", 5)
        if len(parts) != 6:
            continue
        try:
            book_key = int(parts[0])
            chapter = int(parts[1])
            verse = int(parts[2])
        except ValueError:
            continue
        if not 1 <= book_key <= len(TSK_BOOKS) or chapter <= 0 or verse <= 0:
            continue
        source = f"{TSK_BOOKS[book_key - 1]}.{chapter}.{verse}"
        targets = by_source.setdefault(source, [])
        for target in parse_tsk_targets(parts[5]):
            if target not in targets:
                targets.append(target)
    entries = [
        {"ref": source, "targets": targets}
        for source, targets in sorted(by_source.items())
        if targets
    ]
    payload = {
        "source": "Treasury of Scripture Knowledge",
        "sourceUrl": TSK_URL,
        "license": "Public Domain",
        "generatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "entries": entries,
    }
    out = DATA / "cross_references.json"
    write_json(out, payload)
    log(
        f"· referencias cruzadas: {len(entries)} versículos, "
        f"{sum(len(e['targets']) for e in entries)} enlaces → {out}"
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--only",
        choices=("commentary", "dictionary", "xrefs"),
        action="append",
        default=None,
    )
    parser.add_argument("--all", action="store_true")
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()
    selected = set(args.only or [])
    if args.all or not selected:
        selected = {"commentary", "dictionary", "xrefs"}
    if "commentary" in selected:
        import_commentary(force=args.force)
    if "dictionary" in selected:
        import_dictionary(force=args.force)
    if "xrefs" in selected:
        import_xrefs(force=args.force)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
