"""Resolución de libros y referencias bíblicas para la búsqueda.

El índice FTS5 guarda el código de libro (`JHN`), pero la sintaxis de estudio
acepta el mismo tipo de referencias que el lector: `Jn 3`, `Juan 3:16`,
`1 Corintios 13`, `John 1`, etc. Este módulo comparte esa resolución con el
servidor; la app replica la misma lógica en `reference_parser.dart`.
"""
from __future__ import annotations

import re
import unicodedata

# Código → alias separados por espacios. Incluye nombres españoles, ingleses
# y abreviaturas habituales. La búsqueda no distingue mayúsculas ni acentos.
_BOOK_ALIASES = {
    "GEN": "genesis gen gn",
    "EXO": "exodo ex exod exodus",
    "LEV": "levitico lev lv leviticus",
    "NUM": "numeros num nm numbers",
    "DEU": "deuteronomio deut dt deuteronomy",
    "JOS": "josue jos js joshua",
    "JDG": "jueces jue judg jc judges",
    "RUT": "rut rt ruth",
    "1SA": "1samuel 1sam 1sa 1sm 1samuel",
    "2SA": "2samuel 2sam 2sa 2sm 2samuel",
    "1KI": "1reyes 1rey 1re 1ki 1kings",
    "2KI": "2reyes 2rey 2re 2ki 2kings",
    "1CH": "1cronicas 1cro 1cr 1ch 1chronicles",
    "2CH": "2cronicas 2cro 2cr 2ch 2chronicles",
    "EZR": "esdras esd ezr ezra",
    "NEH": "nehemias neh ne nehemiah",
    "EST": "ester est esther",
    "JOB": "job jb",
    "PSA": "salmos salmo salm sal psa ps psalms psalm",
    "PRO": "proverbios prov pro pr proverbs",
    "ECC": "eclesiastes ecl ecc ec ecclesiastes",
    "SNG": "cantares cantar canticos cantico cnt sng songofsongs",
    "ISA": "isaias isa is isaiah",
    "JER": "jeremias jer jr jeremiah",
    "LAM": "lamentaciones lam lm lamentations",
    "EZK": "ezequiel eze ezk ez ezekiel",
    "DAN": "daniel dan dn",
    "HOS": "oseas ose hos os hosea",
    "JOL": "joel jol jl",
    "AMO": "amos amo am amos",
    "OBA": "obadias oba ob abd obadiah",
    "JON": "jonas jon jns jonah",
    "MIC": "miqueas miq mic mi micah",
    "NAM": "nahum nah nam",
    "HAB": "habacuc hab hb habakkuk",
    "ZEP": "sofonias sof zep so zephaniah",
    "HAG": "hageo hag hg haggai",
    "ZEC": "zacarias zac zec zc zechariah",
    "MAL": "malaquias mal ml malachi",
    "MAT": "mateo mat mt matthew",
    "MRK": "marcos mar mrk mr mc mark",
    "LUK": "lucas luc luk lc luke",
    "JHN": "juan jhn jn sanjuan john",
    "ACT": "hechos hch act hec acts",
    "ROM": "romanos rom ro rm romans",
    "1CO": "1corintios 1cor 1co 1corinthians",
    "2CO": "2corintios 2cor 2co 2corinthians",
    "GAL": "galatas gal ga galatians",
    "EPH": "efesios efe eph ef ephesians",
    "PHP": "filipenses fil flp php philippians",
    "COL": "colosenses col clo colossians",
    "1TH": "1tesalonicenses 1tes 1ts 1th 1thessalonians",
    "2TH": "2tesalonicenses 2tes 2ts 2th 2thessalonians",
    "1TI": "1timoteo 1tim 1ti 1tm 1timothy",
    "2TI": "2timoteo 2tim 2ti 2tm 2timothy",
    "TIT": "tito tit ti titus",
    "PHM": "filemon flm phm philemon",
    "HEB": "hebreos heb he hebrews",
    "JAS": "santiago sant stg jas jm james",
    "1PE": "1pedro 1ped 1pe 1pd 1p 1peter",
    "2PE": "2pedro 2ped 2pe 2pd 2p 2peter",
    "1JN": "1juan 1jn 1jhn 1john",
    "2JN": "2juan 2jn 2jhn 2john",
    "3JN": "3juan 3jn 3jhn 3john",
    "JUD": "judas jud jude",
    "REV": "apocalipsis apoc apo ap rev revelation",
}

_CANONICAL = re.compile(r"^([1-3]?[A-Za-z]{2,3})\.(\d+)(?:\.(\d+)(?:-(\d+))?)?$")


def compact(value: str) -> str:
    """Minúsculas sin acentos ni puntuación: «1 Corintios» → «1corintios»."""
    decomposed = unicodedata.normalize("NFKD", value)
    return "".join(
        ch for ch in decomposed.lower() if ch.isalnum() and not unicodedata.combining(ch)
    )


def _build_alias_index() -> dict[str, str]:
    index: dict[str, str] = {}
    for code, aliases in _BOOK_ALIASES.items():
        index[compact(code)] = code
        for alias in aliases.split():
            index[compact(alias)] = code
    return index


_ALIASES = _build_alias_index()
_ALIASES_BY_LENGTH = sorted(_ALIASES, key=len, reverse=True)


def resolve_book(value: str) -> str | None:
    """Devuelve el código de libro para un nombre, abreviatura o código."""
    compressed = compact(value)
    if not compressed:
        return None
    direct = _ALIASES.get(compressed)
    if direct:
        return direct
    for alias in _ALIASES_BY_LENGTH:
        if compressed.startswith(alias):
            return _ALIASES[alias]
    return None


def parse_reference(value: str) -> tuple[str, int | None, int | None, int | None] | None:
    """Resuelve «Jn 3:16», «Juan 3», «JHN.3.16» o «Juan».

    Devuelve `(book_code, chapter, verse_start, verse_end)`; el capítulo y los
    versículos son opcionales.
    """
    raw = " ".join(value.strip().split())
    if not raw:
        return None

    canonical = _CANONICAL.match(raw)
    if canonical:
        code = canonical.group(1).upper()
        if code in _BOOK_ALIASES:
            return (
                code,
                int(canonical.group(2)),
                int(canonical.group(3)) if canonical.group(3) else None,
                int(canonical.group(4)) if canonical.group(4) else None,
            )

    chapter = None
    verse_start = None
    verse_end = None
    book_part = raw

    verse_match = re.search(
        r"(\d+)\s*:\s*(\d+)\s*(?:[-–]\s*(\d+))?\s*$", raw
    )
    if verse_match:
        chapter = int(verse_match.group(1))
        verse_start = int(verse_match.group(2))
        verse_end = int(verse_match.group(3)) if verse_match.group(3) else None
        book_part = raw[: verse_match.start()].strip()
    else:
        chapter_match = re.search(r"(\d+)\s*$", raw)
        if chapter_match:
            chapter = int(chapter_match.group(1))
            book_part = raw[: chapter_match.start()].strip()

    code = resolve_book(book_part)
    if code is None:
        return None
    return (code, chapter, verse_start, verse_end)
