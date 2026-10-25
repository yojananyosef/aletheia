#!/usr/bin/env python3
"""Convierte módulos SWORD (CrossWire) al formato de documento del catálogo.

Fuentes auditadas (licencia y formato en el `.conf` del paquete):
  - `SpaPlatense`    Biblia Platense (Straubinger)      PD   zText4  es
  - `SME`            Spurgeon, Morning & Evening        PD   zLD     en
  - `Webster1828`    Webster, diccionario 1828          PD/CC zLD    en
  - `Josephus`       Obras de Flavio Josefo             PD   GenBook en
  - `Didache`        Didaché                            PD   GenBook en
  - `Wesley`         Comentarios de John Wesley         PD   zCom4   en
  - `Clarke`         Comentario de Adam Clarke          PD   zCom4   en
  - `CalvinCommentaries` Comentarios de Calvino         PD   zCom4   en
  - `Catena`         Catena Aurea (Aquino)              PD   zCom-c  en
  - `Luther`         Comentarios de Lutero              PD   zCom-c  en

Formatos decodificados en Python puro (sin dependencias externas):

  * `zText4`/`zCom4` (CompressType=ZIP) — por testamento `ot/nt`:
      `.bzs` (índice de bloques: tripletas blockStart/blockSize/uncompSize),
      `.bzz` (streams zlib consecutivos) y `.bzv` (índice por slot:
      bloque u32 + inicio u32 + largo u16). Cada slot cubre: cabeza de
      capítulo, título preverso, notas y el texto del versículo. Los slots
      siguen la versificación del módulo (Vulgata en Platense, KJV en los
      comentarios); dos slots de cabecera abren cada testamento.

  * `zCom` antiguo (Catena/Luther) — mismo esquema con extensiones
      `.czs`/`.czv`/`.czz` y bloques por capítulo (BlockType=CHAPTER).

  * `zLD` (SME, Webster) —
      `.idx` 8 B/entrada (offset u32 + size u32), `.dat` registro
      clave + 0xCRLF + (bloque u32 + ordinal u32), `.zdx` 8 B/bloque
      (blockStart u32 + compSize u32) y `.zdt` (bloques zlib; descomprimido:
      u32 count + tabla start/size + bytes NUL-terminados).

  * `RawGenBook` (Josephus, Didaché) —
      `.idx` offsets u32 a registros `.dat`: (parent, next, firstChild) u32 +
      nombre NUL-terminado + u16 userDataSize + userData 8 B (start/size en
      `.bdt`).

Contratos de salida (ver `import_ebible_usfm.py` y los recursos existentes):
  * Biblia: `manifest.json` + `books/<CODE>.json`
    (bloques heading/chapterNumber/verseGroup; inlines text/span).
  * Devocional/diccionario/comentario/documento: `manifest.json` +
    `sections.json` (+ `sections/<ID>.json` en los grandes).

Uso:
  python3 catalog/tools/import_sword.py --list
  python3 catalog/tools/import_sword.py --selfcheck [--module NAME]
  python3 catalog/tools/import_sword.py --module SpaPlatense --module SME
"""
from __future__ import annotations

import argparse
import html
import json
import re
import struct
import sys
import unicodedata
import zlib
import zipfile
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_ZIPS = Path("/tmp/opencode")
DEFAULT_OUT = ROOT / "catalog" / "sources"
TODAY = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

# ---------------------------------------------------------------------------
# Tablas de libros
# ---------------------------------------------------------------------------

# Códigos y nombres del catálogo (mismo orden que import_ebible_usfm.BOOK_ORDER).
PROT_ORDER = [
    ("GEN", "Gen", "Génesis", "Genesis"),
    ("EXO", "Exod", "Éxodo", "Exodus"),
    ("LEV", "Lev", "Levítico", "Leviticus"),
    ("NUM", "Num", "Números", "Numbers"),
    ("DEU", "Deut", "Deuteronomio", "Deuteronomy"),
    ("JOS", "Josh", "Josué", "Joshua"),
    ("JDG", "Judg", "Jueces", "Judges"),
    ("RUT", "Ruth", "Rut", "Ruth"),
    ("1SA", "1Sam", "1 Samuel", "I Samuel"),
    ("2SA", "2Sam", "2 Samuel", "II Samuel"),
    ("1KI", "1Kgs", "1 Reyes", "I Kings"),
    ("2KI", "2Kgs", "2 Reyes", "II Kings"),
    ("1CH", "1Chr", "1 Crónicas", "I Chronicles"),
    ("2CH", "2Chr", "2 Crónicas", "II Chronicles"),
    ("EZR", "Ezra", "Esdras", "Ezra"),
    ("NEH", "Neh", "Nehemías", "Nehemiah"),
    ("EST", "Esth", "Ester", "Esther"),
    ("JOB", "Job", "Job", "Job"),
    ("PSA", "Ps", "Salmos", "Psalms"),
    ("PRO", "Prov", "Proverbios", "Proverbs"),
    ("ECC", "Eccl", "Eclesiastés", "Ecclesiastes"),
    ("SNG", "Song", "Cantar de los Cantares", "Song of Solomon"),
    ("ISA", "Isa", "Isaías", "Isaiah"),
    ("JER", "Jer", "Jeremías", "Jeremiah"),
    ("LAM", "Lam", "Lamentaciones", "Lamentations"),
    ("EZK", "Ezek", "Ezequiel", "Ezekiel"),
    ("DAN", "Dan", "Daniel", "Daniel"),
    ("HOS", "Hos", "Oseas", "Hosea"),
    ("JOL", "Joel", "Joel", "Joel"),
    ("AMO", "Amos", "Amós", "Amos"),
    ("OBA", "Obad", "Obadías", "Obadiah"),
    ("JON", "Jonah", "Jonás", "Jonah"),
    ("MIC", "Mic", "Miqueas", "Micah"),
    ("NAM", "Nah", "Nahúm", "Nahum"),
    ("HAB", "Hab", "Habacuc", "Habakkuk"),
    ("ZEP", "Zeph", "Sofonías", "Zephaniah"),
    ("HAG", "Hag", "Hageo", "Haggai"),
    ("ZEC", "Zech", "Zacarías", "Zechariah"),
    ("MAL", "Mal", "Malaquías", "Malachi"),
    ("MAT", "Matt", "Mateo", "Matthew"),
    ("MRK", "Mark", "Marcos", "Mark"),
    ("LUK", "Luke", "Lucas", "Luke"),
    ("JHN", "John", "Juan", "John"),
    ("ACT", "Acts", "Hechos", "Acts"),
    ("ROM", "Rom", "Romanos", "Romans"),
    ("1CO", "1Cor", "1 Corintios", "I Corinthians"),
    ("2CO", "2Cor", "2 Corintios", "II Corinthians"),
    ("GAL", "Gal", "Gálatas", "Galatians"),
    ("EPH", "Eph", "Efesios", "Ephesians"),
    ("PHP", "Phil", "Filipenses", "Philippians"),
    ("COL", "Col", "Colosenses", "Colossians"),
    ("1TH", "1Thess", "1 Tesalonicenses", "I Thessalonians"),
    ("2TH", "2Thess", "2 Tesalonicenses", "II Thessalonians"),
    ("1TI", "1Tim", "1 Timoteo", "I Timothy"),
    ("2TI", "2Tim", "2 Timoteo", "II Timothy"),
    ("TIT", "Titus", "Tito", "Titus"),
    ("PHM", "Phlm", "Filemón", "Philemon"),
    ("HEB", "Heb", "Hebreos", "Hebrews"),
    ("JAS", "Jas", "Santiago", "James"),
    ("1PE", "1Pet", "1 Pedro", "I Peter"),
    ("2PE", "2Pet", "2 Pedro", "II Peter"),
    ("1JN", "1John", "1 Juan", "I John"),
    ("2JN", "2John", "2 Juan", "II John"),
    ("3JN", "3John", "3 Juan", "III John"),
    ("JUD", "Jude", "Judas", "Jude"),
    ("REV", "Rev", "Apocalipsis", "Revelation"),
]

# Deuterocanónicos de la Vulgata (entran en Biblia Platense).
DEUTEROCANONICAL = [
    ("TOB", "Tob", "Tobías", "Tobit"),
    ("JDT", "Jdt", "Judit", "Judith"),
    ("WIS", "Wis", "Sabiduría", "Wisdom"),
    ("SIR", "Sir", "Eclesiástico", "Sirach"),
    ("BAR", "Bar", "Baruc", "Baruch"),
    ("1MA", "1Mac", "1 Macabeos", "I Maccabees"),
    ("2MA", "2Mac", "2 Macabeos", "II Maccabees"),
]

# Alias OSIS → código; `None` = pseudo-libro del material V: se descarta.
OSIS_ALIASES = {
    "Pss": "PSA", "Psalm": "PSA", "Psalms": "PSA",
    "Cant": "SNG", "Canticles": "SNG",
    "Eccles": "ECC", "Qo": "ECC",
    "Esther": "EST",
    "Macc1": "1MA", "Macc2": "2MA", "1Macc": "1MA", "2Macc": "2MA",
    "Mac1": "1MA", "Mac2": "2MA",
    "2Par": "2CH", "1Par": "1CH", "WisSol": "WIS",
    # pseudo-libros V: se descartan (slots vacíos o apócrifos menores)
    "PrMan": None, "Esdr1": None, "Esdr2": None, "AddPs": None,
    "AddEsth": None, "EpLao": None, "3Cor": None, "3Pet": None,
}

PROT_OT_ORDER = [c for c, _, _, _ in PROT_ORDER[:39]]
PROT_NT_ORDER = [c for c, _, _, _ in PROT_ORDER[39:]]

# Orden canónico OT Vulgata — la Biblia Platense los recorre en este orden.
VULG_OT_ORDER = [
    "GEN", "EXO", "LEV", "NUM", "DEU", "JOS", "JDG", "RUT",
    "1SA", "2SA", "1KI", "2KI", "1CH", "2CH", "EZR", "NEH",
    "TOB", "JDT", "EST", "JOB", "PSA", "PRO", "ECC", "SNG",
    "WIS", "SIR", "ISA", "JER", "LAM", "BAR", "EZK", "DAN",
    "HOS", "JOL", "AMO", "OBA", "JON", "MIC", "NAM", "HAB",
    "ZEP", "HAG", "ZEC", "MAL", "1MA", "2MA",
]

TABLE_BY_CODE: dict[str, tuple[str, str, str]] = {}
for _code, _osis, _es, _en in PROT_ORDER:
    TABLE_BY_CODE[_code] = (_osis, _es, _en)
for _code, _osis, _es, _en in DEUTEROCANONICAL:
    TABLE_BY_CODE[_code] = (_osis, _es, _en)

OSIS_BY_CODE = {code: osis for code, (osis, _, _) in TABLE_BY_CODE.items()}
CODE_BY_OSIS = {osis: code for code, (osis, _, _) in TABLE_BY_CODE.items()}
CODE_BY_OSIS.update({alias: code for alias, code in OSIS_ALIASES.items() if code})
EN_BY_CODE = {code: en for code, (_, _, en) in TABLE_BY_CODE.items()}
ES_BY_CODE = {code: es for code, (_, es, _) in TABLE_BY_CODE.items()}

# Versificaciones (versículos por capítulo); KJV para comentarios, Vulgata
# para la Biblia Platense.
KJV_OT = [
  (31,25,24,26,32,22,24,22,29,32,32,20,18,24,21,16,27,33,38,18,34,24,20,67,34,35,46,22,35,43,55,32,20,31,29,43,36,30,23,23,57,38,34,34,28,34,31,22,33,26),
  (22,25,22,31,23,30,25,32,35,29,10,51,22,31,27,36,16,27,25,26,36,31,33,18,40,37,21,43,46,38,18,35,23,35,35,38,29,31,43,38),
  (17,16,17,35,19,30,38,36,24,20,47,8,59,57,33,34,16,30,37,27,24,33,44,23,55,46,34),
  (54,34,51,49,31,27,89,26,23,36,35,16,33,45,41,50,13,32,22,29,35,41,30,25,18,65,23,31,40,16,54,42,56,29,34,13),
  (46,37,29,49,33,25,26,20,29,22,32,32,18,29,23,22,20,22,21,20,23,30,25,22,19,19,26,68,29,20,30,52,29,12),
  (18,24,17,24,15,27,26,35,27,43,23,24,33,15,63,10,18,28,51,9,45,34,16,33),
  (36,23,31,24,31,40,25,35,57,18,40,15,25,20,20,31,13,31,30,48,25),
  (22,23,18,22),
  (28,36,21,22,12,21,17,22,27,27,15,25,23,52,35,23,58,30,24,42,15,23,29,22,44,25,12,25,11,31,13),
  (27,32,39,12,25,23,29,18,13,19,27,31,39,33,37,23,29,33,43,26,22,51,39,25),
  (53,46,28,34,18,38,51,66,28,29,43,33,34,31,34,34,24,46,21,43,29,53),
  (18,25,27,44,27,33,20,29,37,36,21,21,25,29,38,20,41,37,37,21,26,20,37,20,30),
  (54,55,24,43,26,81,40,40,44,14,47,40,14,17,29,43,27,17,19,8,30,19,32,31,31,32,34,21,30),
  (17,18,17,22,14,42,22,18,31,19,23,16,22,15,19,14,19,34,11,37,20,12,21,27,28,23,9,27,36,27,21,33,25,33,27,23),
  (11,70,13,24,17,22,28,36,15,44),
  (11,20,32,23,19,19,73,18,38,39,36,47,31),
  (22,23,15,17,14,14,10,17,32,3),
  (22,13,26,21,27,30,21,22,35,22,20,25,28,22,35,22,16,21,29,29,34,30,17,25,6,14,23,28,25,31,40,22,33,37,16,33,24,41,30,24,34,17),
  (6,12,8,8,12,10,17,9,20,18,7,8,6,7,5,11,15,50,14,9,13,31,6,10,22,12,14,9,11,12,24,11,22,22,28,12,40,22,13,17,13,11,5,26,17,11,9,14,20,23,19,9,6,7,23,13,11,11,17,12,8,12,11,10,13,20,7,35,36,5,24,20,28,23,10,12,20,72,13,19,16,8,18,12,13,17,7,18,52,17,16,15,5,23,11,13,12,9,9,5,8,28,22,35,45,48,43,13,31,7,10,10,9,8,18,19,2,29,176,7,8,9,4,8,5,6,5,6,8,8,3,18,3,3,21,26,9,8,24,13,10,7,12,15,21,10,20,14,9,6),
  (33,22,35,27,23,35,27,36,18,32,31,28,25,35,33,33,28,24,29,30,31,29,35,34,28,28,27,28,27,33,31),
  (18,26,22,16,20,12,29,17,18,20,10,14),
  (17,17,11,16,16,13,13,14),
  (31,22,26,6,30,13,25,22,21,34,16,6,22,32,9,14,14,7,25,6,17,25,18,23,12,21,13,29,24,33,9,20,24,17,10,22,38,22,8,31,29,25,28,28,25,13,15,22,26,11,23,15,12,17,13,12,21,14,21,22,11,12,19,12,25,24),
  (19,37,25,31,31,30,34,22,26,25,23,17,27,22,21,21,27,23,15,18,14,30,40,10,38,24,22,17,32,24,40,44,26,22,19,32,21,28,18,16,18,22,13,30,5,28,7,47,39,46,64,34),
  (22,22,66,22,22),
  (28,10,27,17,17,14,27,18,11,22,25,28,23,23,8,63,24,32,14,49,32,31,49,27,17,21,36,26,21,26,18,32,33,31,15,38,28,23,29,49,26,20,27,31,25,24,23,35),
  (21,49,30,37,31,28,28,27,27,21,45,13),
  (11,23,5,19,15,11,16,14,17,15,12,14,16,9),
  (20,32,21),
  (15,16,15,13,27,14,17,14,15),
  (21,),
  (17,10,10,11),
  (16,13,12,13,15,16,20),
  (15,13,19),
  (17,20,19),
  (18,15,20),
  (15,23),
  (21,13,10,14,11,15,14,23,17,12,17,14,9,21),
  (14,17,18,6),
]
KJV_NT = [
  (25,23,17,25,48,34,29,34,38,42,30,50,58,36,39,28,27,35,30,34,46,46,39,51,46,75,66,20),
  (45,28,35,41,43,56,37,38,50,52,33,44,37,72,47,20),
  (80,52,38,44,39,49,50,56,62,42,54,59,35,35,32,31,37,43,48,47,38,71,56,53),
  (51,25,36,54,47,71,53,59,41,42,57,50,38,31,27,33,26,40,42,31,25),
  (26,47,26,37,42,15,60,40,43,48,30,25,52,28,41,40,34,28,41,38,40,30,35,27,27,32,44,31),
  (32,29,31,25,21,23,25,39,33,21,36,21,14,23,33,27),
  (31,16,23,21,13,20,40,13,27,33,34,31,13,40,58,24),
  (24,17,18,18,21,18,16,24,15,18,33,21,14),
  (24,21,29,31,26,18),
  (23,22,21,32,33,24),
  (30,30,21,23),
  (29,23,25,18),
  (10,20,13,18,28),
  (12,17,18),
  (20,15,16,16,25,21),
  (18,26,17,22),
  (16,15,15),
  (25,),
  (14,18,19,16,14,20,28,13,28,39,40,29,25),
  (27,26,18,17,20),
  (25,25,22,19,14),
  (21,22,18),
  (10,29,24,21,21),
  (13,),
  (14,),
  (25,),
  (20,29,22,11,14,17,17,13,21,11,19,17,18,20,8,21,18,24,21,15,27,21),
]

# Vulgata OT — las filas siguen el orden VULG_OT_ORDER.
VULG_OT = [
  (31,25,24,26,31,22,24,22,29,32,32,20,18,24,21,16,27,33,38,18,34,24,20,67,34,35,46,22,35,43,55,32,20,31,29,43,36,30,23,23,57,38,34,34,28,34,31,22,32,25),
  (22,25,22,31,23,30,25,32,35,29,10,51,22,31,27,36,16,27,25,26,36,31,33,18,40,37,21,43,46,38,18,35,23,35,35,38,29,31,43,36),
  (17,16,17,35,19,30,38,36,24,20,47,8,59,57,33,34,16,30,37,27,24,33,44,23,55,45,34),
  (54,34,51,49,31,27,89,26,23,36,34,15,34,45,41,50,13,32,22,30,35,41,30,25,18,65,23,31,39,17,54,42,56,29,34,13),
  (46,37,29,49,33,25,26,20,29,22,32,32,18,29,23,22,20,22,21,20,23,30,25,22,19,19,26,68,29,20,30,52,29,12),
  (18,24,17,25,16,27,26,35,27,43,23,24,33,15,63,10,18,28,51,9,43,34,16,33),
  (36,23,31,24,32,40,25,35,57,18,40,15,25,20,20,31,13,31,30,48,24),
  (22,23,18,22),
  (28,36,21,22,12,21,17,22,27,27,15,25,23,52,35,23,58,30,24,43,15,23,28,23,44,25,12,25,11,31,13),
  (27,32,39,12,25,23,29,18,13,19,27,31,39,33,37,23,29,33,43,26,22,51,39,25),
  (53,46,28,34,18,38,51,66,28,29,43,33,34,31,34,34,24,46,21,43,29,54),
  (18,25,27,44,27,33,20,29,37,36,21,21,25,29,38,20,41,37,37,21,26,20,37,20,30),
  (54,55,24,43,26,81,40,40,44,14,46,40,14,17,29,43,27,17,19,7,30,19,32,31,31,32,34,21,30),
  (17,18,17,22,14,42,22,18,31,19,23,16,22,15,19,14,19,34,11,37,20,12,21,27,28,23,9,27,36,27,21,33,25,33,27,23),
  (11,70,13,24,17,22,28,36,15,44),
  (11,20,31,23,19,19,73,18,38,39,36,46,31),
  (25,23,25,23,28,22,20,24,12,13,21,22,23,17),
  (12,18,15,17,29,21,25,34,19,20,21,20,31,18,15,31),
  (22,23,15,17,14,14,10,17,32,13,12,6,18,19,19,24),
  (22,13,26,21,27,30,21,22,35,22,20,25,28,22,35,23,16,21,29,29,34,30,17,25,6,14,23,28,25,31,40,22,33,37,16,33,24,41,35,28,25,16),
  (6,13,9,10,13,11,18,10,39,8,9,6,7,5,11,15,51,15,10,14,32,6,10,22,12,14,9,11,13,25,11,22,23,28,13,40,23,14,18,14,12,6,26,18,12,10,15,21,23,21,11,7,9,24,13,12,12,18,14,9,13,12,11,14,20,8,36,37,6,24,20,28,23,11,13,21,72,13,20,17,8,19,13,14,17,7,19,53,17,16,16,5,23,11,13,12,9,9,5,8,29,22,35,45,48,43,14,31,7,10,10,9,26,9,10,2,29,176,7,8,9,4,8,5,7,5,6,8,8,3,18,3,3,21,27,9,8,24,14,10,8,12,15,21,10,11,9,14,9,6),
  (33,22,35,27,23,35,27,36,18,32,31,28,25,35,33,33,28,24,29,30,31,29,35,34,28,28,27,28,27,33,31),
  (18,26,22,17,19,11,30,17,18,20,10,14),
  (16,17,11,16,17,12,13,14),
  (16,25,19,20,24,27,30,21,19,21,27,27,19,31,19,29,20,25,20),
  (40,23,34,36,18,37,40,22,25,34,36,19,32,27,22,31,31,33,28,33,31,33,38,47,36,28,33,30,35,27,42,28,33,31,26,28,34,39,41,32,28,26,37,27,31,23,31,28,19,31,38),
  (31,22,26,6,30,13,25,22,21,34,16,6,22,32,9,14,14,7,25,6,17,25,18,23,12,21,13,29,24,33,9,20,24,17,10,22,38,22,8,31,29,25,28,28,26,13,15,22,26,11,23,15,12,17,13,12,21,14,21,22,11,12,19,12,25,24),
  (19,37,25,31,31,30,34,22,26,25,23,17,27,22,21,21,27,23,15,18,14,30,40,10,38,24,22,17,32,24,40,44,26,22,19,32,20,28,18,16,18,22,13,30,5,28,7,47,39,46,64,34),
  (22,22,66,22,22),
  (22,35,38,37,9,72),
  (28,9,27,17,17,14,27,18,11,22,25,28,23,23,8,63,24,32,14,49,32,31,49,27,17,21,36,26,21,26,18,32,33,31,15,38,28,23,29,49,26,20,27,31,25,24,23,35),
  (21,49,100,34,31,28,28,27,27,21,45,13,65,42),
  (11,24,5,19,15,11,16,14,17,15,12,14,15,10),
  (20,32,21),
  (15,16,15,13,27,15,17,14,15),
  (21,),
  (16,11,10,11),
  (16,13,12,13,14,16,20),
  (15,13,19),
  (17,20,19),
  (18,15,20),
  (14,24),
  (21,13,10,14,11,15,14,23,17,12,17,14,9,21),
  (14,17,18,6),
  (67,70,60,61,68,63,50,32,73,89,74,54,54,49,41,24),
  (36,33,40,50,27,31,42,36,29,38,38,46,26,46,40),
]

KJV_OT_BY_CODE = dict(zip(PROT_OT_ORDER, KJV_OT))
KJV_NT_BY_CODE = dict(zip(PROT_NT_ORDER, KJV_NT))
VULG_OT_BY_CODE = dict(zip(VULG_OT_ORDER, VULG_OT))


def kjv_v11n() -> dict[str, list[int]]:
    """KJV (comentarios): código → versículos por capítulo."""
    return {**KJV_OT_BY_CODE, **KJV_NT_BY_CODE}


def vulg_v11n() -> dict[str, list[int]]:
    """Vulgata (Biblia Platense): código → versículos por capítulo."""
    return {**VULG_OT_BY_CODE, **KJV_NT_BY_CODE}


# ---------------------------------------------------------------------------
# Registro de módulos
# ---------------------------------------------------------------------------

MODULES: dict[str, dict] = {
    "SpaPlatense": {
        "kind": "bible", "lang": "es", "v11n": "vulg",
        "resource": "bible.platense",
        "meta": {
            "title": "Biblia Platense",
            "subtitle": "Biblia traducida al estilo rioplatense",
            "abbrev": "PLAT",
            "authors": ["Straubinger, Justino"],
            "edition": "1941–1958",
            "publisher": "Club de Amigos del Nuevo Testamento",
            "description": (
                "Traducción al español rioplatense desde los originales por el sacerdote "
                "Justino Straubinger (1941–1958)."
            ),
            "tags": ["Biblia", "Español", "Rioplatense", "Dominio público"],
            "license": {"kind": "public-domain", "text": "Dominio público"},
        },
    },
    "SME": {
        "kind": "devotional", "lang": "en",
        "resource": "devotional.sme",
        "meta": {
            "title": "Morning and Evening",
            "subtitle": "Devocionales diarios de Charles Spurgeon",
            "abbrev": "SME",
            "authors": ["Spurgeon, Charles Haddon"],
            "edition": "1866",
            "publisher": "CrossWire (módulo SWORD)",
            "description": (
                "Devocionales diarios de Spurgeon: una lectura para la mañana y otra para la "
                "tarde por cada día del año (366 entradas), en inglés de dominio público."
            ),
            "tags": ["Devocional", "Inglés", "Dominio público", "Spurgeon"],
            "license": {"kind": "public-domain", "text": "Dominio público"},
            "attributes": {"calendar": "MM.DD"},
        },
    },
    "Webster1828": {
        "kind": "dictionary", "lang": "en",
        "resource": "dictionary.webster1828",
        "meta": {
            "title": "Webster 1828",
            "subtitle": "Diccionario Webster de 1828",
            "abbrev": "W1828",
            "authors": ["Webster, Noah"],
            "edition": "1828",
            "publisher": "CrossWire (módulo SWORD)",
            "description": (
                "An American Dictionary of the English Language (1828) de Noah Webster: "
                "definiciones del vocabulario inglés de su época, útil para leer los "
                "comentarios clásicos en inglés."
            ),
            "tags": ["Diccionario", "Inglés", "Referencia", "CC BY-SA"],
            "license": {"kind": "cc-by-sa", "text": "CC BY-SA 4.0"},
            "attributes": {"entries": "alphabetical"},
        },
    },
    "Josephus": {
        "kind": "genbook", "lang": "en",
        "resource": "document.josephus",
        "meta": {
            "title": "Obras de Flavio Josefo",
            "subtitle": "Antigüedades judías y Guerra de los judíos",
            "abbrev": "JOSE",
            "authors": ["Josefo, Flavio", "Whiston, William (trad.)"],
            "edition": "Whiston, 1737",
            "publisher": "CrossWire (módulo SWORD)",
            "description": (
                "Historia judía del siglo I: Antigüedades judías, Guerra de los judíos, "
                "Autobiografía y Contra Apión, en la traducción de William Whiston."
            ),
            "tags": ["Documento", "Inglés", "Historia", "Dominio público", "Josefo"],
            "license": {"kind": "public-domain", "text": "Dominio público"},
        },
    },
    "Didache": {
        "kind": "genbook", "lang": "grc",
        "resource": "document.didache",
        "meta": {
            "title": "Didaché",
            "subtitle": "Enseñanza de los doce apóstoles (texto griego)",
            "abbrev": "DIDA",
            "authors": [],
            "edition": "s. I–II (texto griego)",
            "publisher": "CrossWire (módulo SWORD)",
            "description": (
                "Manual cristiano de los primeros siglos, de los más antiguos que se han "
                "conservado, en su texto griego original (módulo Didache de CrossWire)."
            ),
            "tags": ["Documento", "Griego", "Padres apostólicos", "Dominio público"],
            "license": {"kind": "public-domain", "text": "Dominio público"},
        },
    },
    "Wesley": {
        "kind": "commentary", "lang": "en",
        "resource": "commentary.wesley",
        "meta": {
            "title": "Comentario de Wesley",
            "subtitle": "Explanatory Notes upon the Scriptures",
            "abbrev": "WES",
            "authors": ["Wesley, John"],
            "edition": "1754–1765",
            "publisher": "CrossWire (módulo SWORD)",
            "description": (
                "Notas expositivas de John Wesley, versículo por versículo: el Nuevo "
                "Testamento completo y buena parte del Antiguo (Génesis a Rut, Samuel y "
                "más), en inglés de dominio público."
            ),
            "tags": ["Comentario", "Inglés", "Dominio público", "Wesley"],
            "license": {"kind": "public-domain", "text": "Dominio público"},
            "attributes": {"coverage": "partial"},
        },
    },
    "Clarke": {
        "kind": "commentary", "lang": "en",
        "resource": "commentary.clarke",
        "meta": {
            "title": "Comentario de Clarke",
            "subtitle": "Commentary and Critical Notes",
            "abbrev": "CLA",
            "authors": ["Clarke, Adam"],
            "edition": "1810–1826",
            "publisher": "CrossWire (módulo SWORD)",
            "description": (
                "Comentario crítico de Adam Clarke sobre toda la Biblia, versículo por "
                "versículo, en inglés de dominio público."
            ),
            "tags": ["Comentario", "Inglés", "Dominio público", "Clarke"],
            "license": {"kind": "public-domain", "text": "Dominio público"},
            "attributes": {"coverage": "protestant66"},
        },
    },
    "CalvinCommentaries": {
        "kind": "commentary", "lang": "en",
        "resource": "commentary.calvincommentaries",
        "meta": {
            "title": "Comentarios de Calvino",
            "subtitle": "Calvin's Commentaries",
            "abbrev": "CAL",
            "authors": ["Calvino, Juan"],
            "edition": "1550s (trad. inglesa PD)",
            "publisher": "CrossWire (módulo SWORD)",
            "description": (
                "Comentarios bíblicos de Juan Calvino, versículo por versículo, en inglés de "
                "dominio público."
            ),
            "tags": ["Comentario", "Inglés", "Dominio público", "Calvino"],
            "license": {"kind": "public-domain", "text": "Dominio público"},
            "attributes": {"coverage": "protestant66"},
        },
    },
    "Catena": {
        "kind": "commentary", "lang": "en", "old_c": True,
        "resource": "commentary.catena",
        "meta": {
            "title": "Catena Aurea",
            "subtitle": "La cadena dorada de los Padres (NT)",
            "abbrev": "CAT",
            "authors": ["Aquino, Tomás de", "Newman, John Henry (trad.)"],
            "edition": "s. XIII (trad. 1841–1842)",
            "publisher": "CrossWire (módulo SWORD)",
            "description": (
                "Compilación de Tomás de Aquino con comentarios de los Padres griegos y "
                "latinos sobre los cuatro Evangelios, versículo por versículo, en inglés de "
                "dominio público."
            ),
            "tags": ["Comentario", "Inglés", "Padres", "Dominio público", "Aquino"],
            "license": {"kind": "public-domain", "text": "Dominio público"},
            "attributes": {"coverage": "gospels"},
        },
    },
    "Luther": {
        "kind": "commentary", "lang": "en", "old_c": True,
        "resource": "commentary.luther",
        "meta": {
            "title": "Comentarios de Lutero",
            "subtitle": "Comentarios bíblicos de Martín Lutero",
            "abbrev": "LUT",
            "authors": ["Lutero, Martín"],
            "edition": "s. XVI (trad. inglesa PD)",
            "publisher": "CrossWire (módulo SWORD)",
            "description": (
                "Comentarios bíblicos de Martín Lutero sobre parte del AT y del NT, en "
                "inglés de dominio público."
            ),
            "tags": ["Comentario", "Inglés", "Dominio público", "Lutero"],
            "license": {"kind": "public-domain", "text": "Dominio público"},
            "attributes": {"coverage": "partial"},
        },
    },
}


# ---------------------------------------------------------------------------
# Carga de paquetes
# ---------------------------------------------------------------------------


def write_json(path: Path, payload) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )


def open_module(name: str, zips_dir: Path) -> dict[str, bytes]:
    """Lee `{name}.zip` y devuelve {ruta relativa dentro del módulo: bytes}."""
    path = zips_dir / f"{name}.zip"
    if not path.is_file():
        raise FileNotFoundError(
            f"falta el paquete {path} (URL: "
            f"https://www.crosswire.org/ftpmirror/pub/sword/packages/rawzip/{name}.zip)")
    with zipfile.ZipFile(path) as z:
        names = [n for n in z.namelist() if not n.endswith(".conf")]
        head = _common_dir_prefix(names)
        return {n[len(head):]: z.read(n) for n in names}


def _common_dir_prefix(names: list[str]) -> str:
    if len(names) == 1:
        n = names[0]
        return n[:n.rfind("/") + 1]
    prefix = names[0]
    for n in names[1:]:
        i = 0
        while i < min(len(prefix), len(n)) and prefix[i] == n[i]:
            i += 1
        prefix = prefix[:i]
    return prefix[:prefix.rfind("/") + 1]


def _family(data: dict[str, bytes]) -> str:
    """Prefijo común de los ficheros del módulo ('sme', 'dict', ...)."""
    idx = next(k for k in data if k.endswith(".idx") or k.endswith(".bzs") or k.endswith(".czs"))
    stem = idx.rsplit("/", 1)[-1]
    return stem.rsplit(".", 1)[0]


# ---------------------------------------------------------------------------
# Lectores SWORD
# ---------------------------------------------------------------------------


def _decompress_blocks(index: bytes, data: bytes) -> list[bytes]:
    """bzs/czs: tripletas (blockStart, compSize, uncompSize) encadenadas."""
    blocks = []
    for i in range(len(index) // 12):
        start, comp, _unc = struct.unpack_from("<III", index, i * 12)
        chunk = data[start:start + comp]
        try:
            blocks.append(zlib.decompress(chunk))
        except zlib.error as err:
            # streams con relleno: probamos recortes
            done = False
            for pad in (16, 32, 64):
                try:
                    blocks.append(zlib.decompress(data[start:start + comp + pad]))
                    done = True
                    break
                except zlib.error:
                    continue
            if not done:
                raise zlib.error(f"bloque {i}@{start}: {err}") from err
    return blocks


def _read_verse_slots(verse_index: bytes) -> list[tuple[int, int, int]]:
    """bzv/czv. Detecta el ancho de registro: 10 B (u16) o 12 B (u32)."""
    for entry, fmt in ((10, "<IIH"), (12, "<III")):
        n = len(verse_index) // entry
        if n == 0:
            return []
        slots = []
        ok = True
        for i in range(n):
            blk, off, size = struct.unpack_from(fmt, verse_index, i * entry)
            if blk > 200000 or (size and off > 1 << 30):
                ok = False
                break
            slots.append((blk, off, size))
        if ok:
            return slots
    raise ValueError("índice de versos (bzv/czv) no reconocido")


def read_zverse(data: dict[str, bytes], part: str) -> tuple[list[bytes], list[tuple[int, int, int]]]:
    """Parte (`ot`/`nt`) de un módulo bzs/bzv/bzz o czs/czv/czz."""
    if f"{part}.bzv" in data:
        blocks = _decompress_blocks(data[f"{part}.bzs"], data[f"{part}.bzz"])
        slots = _read_verse_slots(data[f"{part}.bzv"])
    elif f"{part}.czv" in data:
        blocks = _decompress_blocks(data[f"{part}.czs"], data[f"{part}.czz"])
        slots = _read_verse_slots(data[f"{part}.czv"])
    else:
        raise KeyError(f"sin índices de versos para la parte {part}")
    return blocks, slots


def slot_text(blocks: list[bytes], slot: tuple[int, int, int]) -> str:
    blk, off, size = slot
    if not size or blk >= len(blocks):
        return ""
    block = blocks[blk]
    if off >= len(block):
        return ""
    raw = block[off:off + size]
    try:
        return raw.decode("utf-8")
    except UnicodeDecodeError:
        return raw.decode("utf-8", "replace")


def read_zld(data: dict[str, bytes]) -> list[tuple[str, str]]:
    """zLD: entradas [(clave, contenido)]. SME y Webster1828."""
    prefix = _family(data)
    idx = data[prefix + ".idx"]
    dat = data[prefix + ".dat"]
    zdx = data[prefix + ".zdx"]
    zdt = data[prefix + ".zdt"]

    block_cache: dict[int, bytes] = {}

    def block(n: int) -> bytes:
        if n not in block_cache:
            start, comp = struct.unpack_from("<II", zdx, n * 8)
            block_cache[n] = zlib.decompress(zdt[start:start + comp])
        return block_cache[n]

    out: list[tuple[str, str]] = []
    for i in range(len(idx) // 8):
        off, size = struct.unpack_from("<II", idx, i * 8)
        key, ref = dat[off:off + size].split(b"\r\n", 1)
        block_num, block_entry = struct.unpack_from("<II", ref, 0)
        payload = block(block_num)
        count = struct.unpack_from("<I", payload, 0)[0]
        if block_entry >= count:
            continue
        start, esize = struct.unpack_from("<II", payload, 4 + 8 * block_entry)
        text = payload[start:start + esize]
        if text.endswith(b"\x00"):
            text = text[:-1]
        out.append(
            (key.decode("utf-8", "replace"), text.decode("utf-8", "replace")))
    return out


def read_genbook(data: dict[str, bytes]) -> list[tuple[list[str], str]]:
    """RawGenBook: pre-orden [(ruta de nombres, texto)].

    `.idx` = pool de u32 (cada uno un offset en `.dat`); los campos
    parent/next/firstChild de cada registro apuntan a posiciones EN BYTES
    dentro de `.idx` (0xFFFFFFFF = ninguno). El registro en `.dat` es:
    (parent, next, firstChild) u32 + nombre NUL + u16 userDataSize +
    userData (start u32 + size u32 en `.bdt`).
    """
    prefix = _family(data)
    idx = data[prefix + ".idx"]
    dat = data[prefix + ".dat"]
    bdt = data[prefix + ".bdt"]

    NONE = 0xFFFFFFFF

    def node(byte_pos: int) -> tuple[str, bytes, int]:
        pos = struct.unpack_from("<I", idx, byte_pos)[0]
        _parent, nxt, child = struct.unpack_from("<III", dat, pos)
        end = dat.index(b"\x00", pos + 12)
        name = dat[pos + 12:end].decode("utf-8", "replace")
        (ud_size,) = struct.unpack_from("<H", dat, end + 1)
        ud = dat[end + 3:end + 3 + ud_size]
        return name, ud, (nxt, child)

    flat: list[tuple[list[str], str]] = []
    idx_len = len(idx)

    def walk(byte_pos: int, path: list[str]) -> None:
        while byte_pos != NONE and byte_pos + 4 <= idx_len and byte_pos % 4 == 0:
            name, ud, (nxt, child) = node(byte_pos)
            here = path + [name] if name else list(path)
            text = ""
            if len(ud) >= 8:
                start, size = struct.unpack_from("<II", ud, 0)
                if 0 <= start <= len(bdt) and size:
                    text = bdt[start:start + size].decode("utf-8", "replace")
            flat.append((here, text))
            if child != NONE and child + 4 <= idx_len and child % 4 == 0:
                walk(child, here)
            byte_pos = nxt

    walk(0, [])
    return flat


# ---------------------------------------------------------------------------
# Conversión OSIS → inlines
# ---------------------------------------------------------------------------

TAG_RE = re.compile(r"<(/?)([a-zA-Z][a-zA-Z0-9._-]*)([^<>]*?)(/?)>", re.S)
ATTR_RE = re.compile(r'([a-zA-Z0-9._-]+)\s*=\s*"([^"]*)"')

DROP_TAGS = {"note", "reference", "w", "catchWord", "inscription",
             "milestone", "milestoneStart", "milestoneEnd"}
STRUCT_TAGS = {"p", "div", "lg", "l", "title", "verse", "chapter", "q"}


class OsisProcessor:
    """Convierte un fragmento OSIS/HTML en unidades estructuradas.

    `units`  : [{'kind': 'p'|'poem', 'level': int, 'runs': [...]},
                ...parágrafos en orden]
    `headings`: [(style, texto)] con style ∈ {'section', 'psalmTitle'}
    `sections`: modo devocional: [{'osisID', 'title', 'units': [...]}]
    `xrefs`  : [{label, ref}] referencias OSIS encontradas (devocional).
    """

    def __init__(self, mode: str = "bible"):
        assert mode in ("bible", "devotional", "plain")
        self.mode = mode
        self.reset()

    def reset(self) -> None:
        self.units: list[dict] = []
        self.headings: list[tuple[str, str]] = []
        self.sections: list[dict] = []
        self.xrefs: list[dict] = []
        self.footnotes: list[dict] = []   # [{id, label, text}] capturadas
        self._skip: list[str] = []       # tags cuyo contenido se descarta
        self._fmt: list[str] = []        # pila de estilos de texto
        self._buf: list[str | dict] = []  # tramos en construcción
        self._poem = False
        self._level = 0
        self._in_title: str | None = None
        self._title_text: list[str] = []
        self._section: dict | None = None
        self._ref_attrs: dict | None = None  # <reference osisRef=...> abierto
        self._note_depth = 0             # profundidad de <note> en captura
        self._note_buffer: list[str] | None = None  # texto de la nota abierta
        self._note_label = ""            # atributo n= de la nota en captura
        self._note_seq = 0               # contador de notas de esta llamada
        self._note_scope = ""            # prefijo de id (verso del módulo)

    # -- primitivas ----------------------------------------------------------

    def _text(self, piece: str) -> None:
        if self._note_depth > 0 and self._note_buffer is not None:
            if piece:
                self._note_buffer.append(piece.replace("\xa0", " "))
            return
        if self._skip:
            return
        if self._in_title is not None:
            self._title_text.append(piece)
            return
        if piece:
            self._buf.append(piece.replace("\xa0", " "))

    def _runs_from_buf(self) -> list[dict]:
        runs: list[dict] = []
        style = self._fmt[-1] if self._fmt else None
        text_parts: list[str] = []
        for piece in self._buf:
            if isinstance(piece, dict):
                if text_parts:
                    runs.extend(self._finalize_style(style, "".join(text_parts)))
                    text_parts = []
                runs.append(dict(piece))
            else:
                text_parts.append(piece)
        runs.extend(self._finalize_style(style, "".join(text_parts)))
        self._buf = []
        return [r for r in runs
                if r.get("v") or r.get("t") in ("footnote", "xref")]

    def _finalize_style(self, style: str | None, text: str) -> list[dict]:
        text = re.sub(r"\s+", " ", text)
        if not text:
            return []
        if style:
            return [{"t": "span", "style": style, "v": text}]
        return [{"t": "text", "v": text}]

    def flush(self) -> None:
        if self._in_title is not None:
            self._buf = []
            return
        runs = self._runs_from_buf()
        if not runs:
            return
        unit = {"kind": "poem" if self._poem else "p",
                "level": self._level if self._poem else 0,
                "runs": runs}
        if self._section is not None:
            self._section["units"].append(unit)
        else:
            self.units.append(unit)

    def flush_all(self) -> None:
        self.flush()
        self._poem = False
        self._level = 0

    # -- analizador ----------------------------------------------------------

    def _handle(self, tag: str, attrs: dict, closing: bool, self_done: bool) -> None:
        # notas al pie: se capturan (texto plano) y se emite un marcador inline
        # en la posición donde acaba la nota (su contenido no entra al flujo).
        if tag == "note":
            if closing or self_done:
                self._note_depth = max(0, self._note_depth - 1)
                if self._note_depth == 0 and self._note_buffer is not None:
                    body = re.sub(r"\s+", " ", " ".join(self._note_buffer)).strip()
                    self._note_buffer = None
                    if body:
                        self._note_seq += 1
                        note_id = f"{self._note_scope}n{self._note_seq}"
                        self.footnotes.append(
                            {"id": note_id, "label": self._note_label, "text": body}
                        )
                        self._buf.append(
                            {"t": "footnote", "id": note_id, "label": self._note_label}
                        )
                return
            if self._note_depth == 0:
                self._note_depth = 1
                self._note_buffer = []
                self._note_label = attrs.get("n", "") or "a"
            else:
                self._note_depth += 1
            return
        if self._note_depth > 0:
            # dentro de una nota: solo el texto fluye; etiquetas ignoradas
            # (con <lb> suave como separador).
            if tag == "lb" and not closing and self._note_buffer is not None:
                self._note_buffer.append(" ")
            return
        # contenido descartado (notas, w, referencias…)
        if self._skip:
            if closing or self_done:
                if tag == self._skip[-1]:
                    self._skip.pop()
                elif tag in self._skip:
                    self._skip.remove(tag)
            elif tag in DROP_TAGS:
                self._skip.append(tag)
            return
        if tag in DROP_TAGS and not (tag == "reference" and self.mode == "devotional"):
            if not self_done:
                self._skip.append(tag)
            return

        # estilos de texto
        if tag in ("hi", "add", "ins"):
            if closing:
                if self._fmt:
                    self._fmt.pop()
                return
            if not self_done:
                style = attrs.get("type", "") or attrs.get("rend", "")
                if "italic" in style or "oblique" in style:
                    self._fmt.append("italic")
                elif "bold" in style:
                    self._fmt.append("bold")
                else:
                    self._fmt.append("")
            return
        if tag == "transChange":
            if closing:
                if self._fmt and self._fmt[-1] == "italic":
                    self._fmt.pop()
                return
            if not self_done and "add" in attrs.get("type", ""):
                self._fmt.append("italic")
            return

        # título preverso (primero: cambia el destino del texto)
        if tag == "title":
            if closing:
                self.flush_all()
                text = re.sub(r"\s+", " ", " ".join(self._title_text)).strip()
                self._title_text = []
                style = self._in_title or "section"
                self._in_title = None
                if text:
                    if self._section is not None and self._section.get("title") is None:
                        self._section["title"] = text
                    else:
                        self.headings.append((style, text))
            elif not self_done:
                kind = attrs.get("type", "")
                self._in_title = ("section" if kind in ("x-ms", "x-s", "section", "ms")
                                  else "psalmTitle")
                self._title_text = []
            return

        # saltos de línea suaves
        if tag == "lb":
            if not closing:
                self._text(" ")
            return

        # estructura
        if closing:
            if tag in ("p", "q", "div"):
                self.flush_all()
            elif tag == "lg":
                self.flush_all()
                self._poem = False
            elif tag == "l":
                self.flush_all()
            if tag != "reference":
                return
        if tag in ("p", "q"):
            self.flush_all()
            return
        if tag == "div":
            dtype = attrs.get("type", "")
            if dtype in ("x-p", "p", "x-indent", "x-section"):
                self.flush_all()
                return
            if self.mode == "devotional" and dtype == "section":
                self.flush_all()
                self._section = {"osisID": attrs.get("osisID", ""),
                                 "title": None, "units": []}
                self.sections.append(self._section)
                return
            return
        if tag == "lg":
            self.flush_all()
            self._poem = True
            return
        if tag == "l":
            self.flush_all()
            self._poem = True
            if not self_done:
                try:
                    level = int(re.search(r"\d+", attrs.get("level", "1")).group(0))
                except ValueError:
                    level = 1
                self._level = max(level - 1, 0)
            return

        # referencias (solo el modo devocional emite xref)
        if tag == "reference":
            if closing or self_done:
                if self.mode == "devotional" and self._ref_attrs is not None:
                    label_runs = self._runs_from_buf()
                    label = "".join(r.get("v", "") for r in label_runs).strip()
                    code = osis_ref_to_code(self._ref_attrs.get("osisRef", ""))
                    if label and code:
                        self._buf.append({"t": "xref", "label": label, "ref": code})
                        self.xrefs.append({"label": label, "ref": code})
                    else:
                        self._buf.extend(label_runs)
                self._ref_attrs = None
                return
            self.flush_all()
            if "osisRef" in attrs:
                self._ref_attrs = attrs
            return
        return

    def feed(self, text: str) -> None:
        pos = 0
        for m in TAG_RE.finditer(text):
            if m.start() > pos:
                self._text(html.unescape(text[pos:m.start()]))
            closing, tag = m.group(1) == "/", m.group(2)
            self_done = m.group(4) == "/"
            self._handle(tag, dict(ATTR_RE.findall(m.group(3))), closing, self_done)
            pos = m.end()
        if pos < len(text):
            self._text(html.unescape(text[pos:]))
        self.flush_all()

def osis_runs(text: str, mode: str = "bible", note_scope: str = "") -> OsisProcessor:
    proc = OsisProcessor(mode)
    proc._note_scope = note_scope
    proc.feed(text)
    return proc


def runs_text(runs: list[dict]) -> str:
    return "".join(r.get("v", "") for r in runs)


def osis_ref_to_code(osis_ref: str) -> str | None:
    """'Matt.1.2' / 'Bible:Josh.5.12' → 'MAT.1.2' (rango: toma el verso inicial)."""
    stem = osis_ref.split("-")[0].strip()
    if stem.lower().startswith("bible:"):
        stem = stem[6:]
    parts = stem.split(".")
    if not parts or not parts[0]:
        return None
    code = CODE_BY_OSIS.get(parts[0].replace("_", ""))
    if not code:
        return None
    rest = [p for p in parts[1:] if p.isdigit()] or [""]
    return ".".join([code] + rest)


def strip_verse_marker(units: list[dict]) -> tuple[list[dict], list[dict]]:
    """Separa unidades previas a un marcador de verso 'Verse N' en negrita.

    (pre)._ — devuelve (previas, resto). Si no hay marcador: ([], units).
    """
    for i, unit in enumerate(units):
        if unit.get("kind") != "p" or len(unit["runs"]) != 1:
            continue
        run = unit["runs"][0]
        head = str(run.get("v", "")).strip()
        if run.get("style") == "bold" and re.fullmatch(r"(?i)verse\s*\d+", head):
            return units[:i], units[i + 1:]
    return [], units


def clean_runs(runs: list[dict]) -> list[dict]:
    """Une tramos contiguos del mismo estilo, colapsando espacios."""
    out: list[dict] = []
    for chunk in runs:
        if chunk.get("t") in ("footnote", "xref"):
            out.append(chunk)
            continue
        text = chunk.get("v", "")
        if not text:
            continue
        if out:
            prev = out[-1]
            if prev.get("t") == chunk.get("t") and prev.get("style") == chunk.get("style") and prev.get("t") not in ("xref", "footnote"):
                prev["v"] += text
                continue
        out.append(dict(chunk))
    for r in out:
        if r.get("t") in ("text", "span"):
            r["v"] = re.sub(r"\s+", " ", r.get("v", ""))
    if out:
        first, last = out[0], out[-1]
        if "v" in first:
            first["v"] = first["v"].lstrip()
        if "v" in last:
            last["v"] = last["v"].rstrip()
    return [r for r in out if r.get("t") in ("footnote", "xref")
            or (r.get("v") and r.get("v").strip())]


# ---------------------------------------------------------------------------
# Biblia (zText4)
# ---------------------------------------------------------------------------

OSISID_RE = re.compile(r'osisID="([\w.]+)"')
N_ATTR_RE = re.compile(r'\bn="(\d+)"')


def slot_kind(text: str) -> str:
    t = text.strip()
    if not t:
        return "empty"
    if t.startswith("<chapter"):
        return "chapter"
    head = t[:700]
    if 'type="book"' in head or 'type="bookGroup"' in head:
        if OSISID_RE.search(head):
            return "book"
    return "verse"


def parse_bible(data: dict[str, bytes], v11n_code: str) -> dict:
    """Recorre los slots del módulo bible y extrae libros/capítulos/versos."""
    order = (VULG_OT_ORDER if v11n_code == "vulg" else PROT_OT_ORDER) + PROT_NT_ORDER
    books_out: dict[str, dict] = {}
    skipped_osis: set[str] = set()

    for part in ("ot", "nt"):
        if not (f"{part}.bzv" in data or f"{part}.czv" in data):
            if part == "nt" and "ot.czv" in data:
                continue
        if f"{part}.bzv" not in data and f"{part}.czv" not in data:
            continue
        blocks, slots = read_zverse(data, part)
        cur_code: str | None = None
        chapter: dict | None = None
        verse_n = 0
        for i, slot in enumerate(slots):
            if i < 2:  # slots de cabecera de cada testamento
                continue
            text = slot_text(blocks, slot)
            kind = slot_kind(text)

            if kind == "book":
                osis = (OSISID_RE.search(text[:700]).group(1).split(".")[0]
                        if OSISID_RE.search(text[:700]) else "")
                code = CODE_BY_OSIS.get(osis)
                if code is None:
                    if osis:
                        skipped_osis.add(osis)
                    cur_code = None
                    chapter = None
                    continue
                cur_code = code
                chapter = None
                verse_n = 0
                continue
            if kind == "chapter":
                osis_match = OSISID_RE.search(text[:700])
                n_match = N_ATTR_RE.search(text[:700])
                osis = (osis_match.group(1).split(".")[0] if osis_match else "")
                code = CODE_BY_OSIS.get(osis)
                if code is None or n_match is None:
                    if osis and code is None:
                        skipped_osis.add(osis)
                    cur_code = None if osis and code is None else cur_code
                    chapter = None
                    continue
                cur_code = code
                n = int(n_match.group(1))
                book = books_out.setdefault(code, {"name": ES_BY_CODE[code], "chapters": []})
                chapter = {"n": n, "blocks": [{"type": "chapterNumber", "value": n}]}
                book["chapters"].append(chapter)
                verse_n = 0
                # títulos incluidos en la cabeza del capítulo
                proc = osis_runs(text, note_scope=f"{code}.{n}.")
                for style, head in proc.headings:
                    chapter["blocks"].append({"type": "heading", "style": style, "text": head})
                continue

            if cur_code is None or chapter is None:
                continue
            if kind == "empty":
                continue
            verse: dict | None = None
            proc = osis_runs(text, note_scope=f"{code}.{chapter['n']}.{verse_n + 1}.")
            for style, head in proc.headings:
                chapter["blocks"].append({"type": "heading", "style": style, "text": head})
            for note in proc.footnotes:
                chapter.setdefault("footnotes", {}).setdefault(
                    note["id"], {"label": note["label"], "text": note["text"]}
                )
            units = [u for u in proc.units if u.get("runs")]
            if not units:
                continue
            verse_n += 1
            runs = clean_runs(
                [run for unit in units for run in unit["runs"]])
            if not runs:
                continue
            poem_levels = [u.get("level", 0) for u in units if u.get("kind") == "poem"]
            if poem_levels:
                level = max(poem_levels)
                last = chapter["blocks"][-1]
                if last.get("type") == "verseGroup" and last.get("style") == "poetry" \
                        and last.get("indent") == level:
                    group = last
                else:
                    group = {"type": "verseGroup", "style": "poetry",
                             "indent": level, "verses": []}
                    chapter["blocks"].append(group)
            else:
                last = chapter["blocks"][-1]
                if last.get("type") == "verseGroup" and last.get("style") != "poetry":
                    group = last
                else:
                    group = {"type": "verseGroup", "verses": []}
                    chapter["blocks"].append(group)
            group["verses"].append({"n": verse_n, "inlines": runs})

    return {"books": books_out, "skipped": sorted(skipped_osis), "order": order}


def write_bible(out: Path, data: dict[str, bytes], module: str) -> dict:
    mod = MODULES[module]
    v11n_code = "vulg" if mod.get("v11n") == "vulg" else "kjv"
    parsed = parse_bible(data, v11n_code)
    books = parsed["books"]

    v11n_order = (VULG_OT_ORDER if v11n_code == "vulg" else PROT_OT_ORDER) + \
        (PROT_NT_ORDER if v11n_code != "vulg" else [])
    books_dir = out / "books"
    manifest_books = []
    total_chapters = 0
    total_verses = 0
    order = (VULG_OT_ORDER if v11n_code == "vulg" else PROT_OT_ORDER)
    order = [c for c in order if books.get(c, {}).get("chapters")] + \
        [c for c in PROT_NT_ORDER if books.get(c, {}).get("chapters")]

    for code in order:
        entry = books[code]
        # capítulos sin ningún verso (fusiones de la propia edición, p. ej.
        # Éxodo 7+8 en Platense): se descartan
        chapters = [ch for ch in entry["chapters"]
                    if any(g.get("verses") for g in ch["blocks"]
                           if g["type"] == "verseGroup")]
        if not chapters:
            continue
        counts = [sum(len(g["verses"]) for g in ch["blocks"] if g["type"] == "verseGroup")
                  for ch in chapters]
        total_chapters += len(chapters)
        total_verses += sum(counts)
        manifest_books.append({"code": code, "name": entry["name"], "chapters": [
            {"n": ch["n"], "verses": v} for ch, v in zip(chapters, counts)]})
        write_json(books_dir / f"{code}.json", {"code": code, "name": entry["name"],
                                                "chapters": chapters})

    meta = dict(mod["meta"])
    if v11n_code == "vulg":
        deuter = {c for c, *_ in DEUTEROCANONICAL}
        has_deut = any(c in books for c in deuter)
        meta = dict(mod["meta"])
        meta.setdefault("attributes", {})
        meta["attributes"] = {**meta.get("attributes", {}),
                              "coverage": "catholic73" if has_deut else "protestant66"}
    write_resource_manifest(out, module, "bible", meta,
                            {"books": len(manifest_books), "sections": total_chapters,
                             "verses": total_verses},
                            books=manifest_books)
    if parsed["skipped"]:
        print(f"aviso {module}: slots de libros no mapeados descartados: "
              f"{', '.join(parsed['skipped'][:12])}")
    missing = [c for c in ((VULG_OT_ORDER if v11n_code == "vulg" else PROT_OT_ORDER) +
                           PROT_NT_ORDER) if c not in books]
    if missing:
        print(f"aviso {module}: libros de la tabla sin contenido: {missing}")
    return {"books": len(manifest_books), "chapters": total_chapters, "verses": total_verses}


def write_resource_manifest(out: Path, module: str, kind: str, meta: dict, stats: dict,
                            books: list | None = None) -> None:
    mod = MODULES[module]
    manifest = {
        "id": mod["resource"],
        "resourceId": mod["resource"],
        "type": kind,
        "title": meta["title"],
        "subtitle": meta.get("subtitle", ""),
        "abbrev": meta.get("abbrev", ""),
        "authors": meta.get("authors", []),
        "language": mod["lang"],
        "publisher": meta.get("publisher", ""),
        "edition": meta.get("edition", ""),
        "source": f"https://www.crosswire.org/sword/modules/ModDisp.jsp?modName={module}",
        "license": meta["license"],
        "description": meta.get("description", ""),
        "tags": meta.get("tags", []),
        "attributes": meta.get("attributes", {}),
        "stats": stats,
        "updatedAt": TODAY,
    }
    if books is not None:
        manifest["books"] = books
    write_json(out / "manifest.json", manifest)


# ---------------------------------------------------------------------------
# Devocional (SME → sections.json con bloques embebidos)
# ---------------------------------------------------------------------------

ES_MONTHS = {1: "enero", 2: "febrero", 3: "marzo", 4: "abril", 5: "mayo", 6: "junio",
             7: "julio", 8: "agosto", 9: "septiembre", 10: "octubre",
             11: "noviembre", 12: "diciembre"}


def write_devotional(out: Path, data: dict[str, bytes], module: str) -> dict:
    entries = read_zld(data)
    sections: list[dict] = []
    total_blocks = 0
    for key, text in entries:
        m = re.fullmatch(r"(\d\d)\.(\d\d)", key)
        if m:
            mon, day = int(m.group(1)), int(m.group(2))
        else:
            mon, day = 0, len(sections) + 1
        proc = osis_runs(text, mode="devotional")
        blocks: list[dict] = []
        ref = ""
        ref_label = ""
        for sec in proc.sections:
            title = sec.get("title")
            if title:
                blocks.append({"type": "heading", "text": title, "style": "section"})
            for unit in sec.get("units", []):
                runs = clean_runs(unit["runs"])
                if runs:
                    blocks.append({"type": "paragraph", "inlines": runs})
            if not ref and sec.get("units"):
                for x in proc.xrefs:
                    ref = x["ref"]
                    ref_label = x["label"]
                    break
        title = f"{day} de {ES_MONTHS.get(mon, '')}".strip()
        sections.append({
            "id": f"dayofyear.{mon:02d}.{day:02d}",
            "day": f"{mon:02d}.{day:02d}",
            "title": title,
            "theme": None,
            "reference": ref or None,
            "referenceLabel": ref_label or None,
            "blocks": blocks,
        })
        total_blocks += len(blocks)
    write_resource_manifest(out, module, "devotional", MODULES[module]["meta"],
                            {"books": 0, "sections": len(sections), "verses": 0})
    write_json(out / "sections.json", sections)
    return {"sections": len(sections), "blocks": total_blocks}


# ---------------------------------------------------------------------------
# Diccionario (Webster1828 → sections.json índice + sections/<ID>.json)
# ---------------------------------------------------------------------------


def slug_for(value: str, used: set[str], fallback_n: int) -> str:
    value = unicodedata.normalize("NFKD", value).encode("ascii", "ignore").decode("ascii")
    value = re.sub(r"[^A-Za-z0-9]+", "-", value).strip("-").lower()
    if not value:
        value = f"entry-{fallback_n}"
    slug = value
    k = 2
    while slug in used:
        slug = f"{value}-{k}"
        k += 1
    return slug


def write_dictionary(out: Path, data: dict[str, bytes], module: str) -> dict:
    entries = read_zld(data)
    sections_dir = out / "sections"
    index: list[dict] = []
    used: set[str] = set()
    for n, (key, text) in enumerate(entries):
        headword = key.strip()
        slug = slug_for(headword, used, n + 1)
        used.add(slug)
        proc = osis_runs(text, mode="plain")
        blocks = [{"type": "paragraph", "inlines": clean_runs(u["runs"])}
                  for u in proc.units if u.get("runs")]
        if not blocks:
            flat = re.sub(r"<[^>]+>", " ", text)
            flat = re.sub(r"\s+", " ", flat).strip()
            blocks = [{"type": "paragraph", "inlines": [{"t": "text", "v": flat}]}] if flat else []
        if not blocks:
            continue
        summary = runs_text(blocks[0]["inlines"])[:200]
        title = headword.title() if headword.isupper() or headword.islower() else headword
        section = {"id": slug, "title": title, "summary": summary, "tags": [],
                   "blocks": blocks}
        write_json(sections_dir / f"{slug}.json", section)
        index.append({"id": slug, "title": title, "summary": summary, "tags": []})
    write_resource_manifest(out, module, "dictionary", MODULES[module]["meta"],
                            {"books": 0, "sections": len(index), "verses": 0})
    write_json(out / "sections.json", index)
    return {"sections": len(index)}


# ---------------------------------------------------------------------------
# Documentos (RawGenBook: Josephus, Didaché)
# ---------------------------------------------------------------------------

HTML_BLOCK_RE = re.compile(r"<(?:div\b|p\b|br\b|hr\b|h[1-6]\b)[^>]*>", re.I)
HTML_TAG_RE = re.compile(r"<[^>]+>")


def html_units(text: str, headings: bool = True) -> list[dict]:
    text = re.sub(r"(?is)<!DOCTYPE.*?>", "", text)
    text = re.sub(r"(?is)<head\b.*?</head>", "", text)
    text = re.sub(r"(?is)<title\b.*?</title>", "", text)
    blocks: list[dict] = []

    def push(para: str, style: str | None = None) -> None:
        clean = re.sub(r"\s+", " ", re.sub(HTML_TAG_RE, " ", para)).strip()
        clean = html.unescape(clean)
        if not clean:
            return
        if style == "section":
            blocks.append({"type": "heading", "style": "section", "text": clean})
        else:
            blocks.append({"type": "paragraph", "inlines": [{"t": "text", "v": clean}]})

    # sepáramos por bloques HTML penetrantes
    segments = []
    last = 0
    for m in re.finditer(r"<h([1-6])[^>]*>(.*?)</h\1>", text, re.I | re.S):
        if m.start() > last:
            segments.append((None, text[last:m.start()]))
        segments.append(("section", m.group(2)))
        last = m.end()
    if last < len(text):
        segments.append((None, text[last:]))
    for style, seg in segments:
        toks = HTML_BLOCK_RE.split(seg)
        for tok in toks:
            push(tok, style)
    if not blocks:
        push(text, None)
    return blocks


def slugify(value: str) -> str:
    value = unicodedata.normalize("NFKD", value).encode("ascii", "ignore").decode("ascii")
    value = re.sub(r"[^A-Za-z0-9]+", "-", value).strip("-").lower()
    return value or "node"


def write_genbook(out: Path, data: dict[str, bytes], module: str) -> dict:
    tree = read_genbook(data)
    sections_dir = out / "sections"
    index: list[dict] = []
    used: set[str] = set()
    generic_re = re.compile(r"^(Section|Chapter|Book|Part|Paragraph)\s+\d+$", re.I)
    for path, text in tree:
        name = path[-1] if path else MODULES[module]["resource"]
        if not text.strip():
            continue
        display = name
        if generic_re.match(name) and len(path) >= 2:
            display = f"{path[-2]} — {name}"
        slug = slugify(display)
        base = slug
        k = 2
        while slug in used:
            slug = f"{base}-{k}"
            k += 1
        used.add(slug)
        blocks = html_units(text)
        summary = ""
        for b in blocks:
            if b["type"] == "paragraph" and b["inlines"]:
                summary = b["inlines"][0]["v"][:200]
                break
        section = {"id": slug, "title": display, "summary": summary, "tags": [],
                   "blocks": blocks}
        write_json(sections_dir / f"{slug}.json", section)
        index.append({"id": slug, "title": display, "summary": summary, "tags": []})
    write_resource_manifest(out, module, "document", MODULES[module]["meta"],
                            {"books": 0, "sections": len(index), "verses": 0})
    write_json(out / "sections.json", index)
    return {"sections": len(index)}


# ---------------------------------------------------------------------------
# Comentarios (zCom4 y zCom clásico): per-verse → secciones per-chapter
# ---------------------------------------------------------------------------


FILLER_RE = re.compile(r"No Commentary on these verses is yet included", re.I)
TESTAMENT_PREFACE_RE = re.compile(r"<title>\s*(Old|New) Testament\s*</title>", re.I)


def clean_units(units: list[dict]) -> list[dict]:
    """Normaliza unidades: runs limpios, sin párrafos vacíos."""
    out: list[dict] = []
    for u in units:
        runs = clean_runs(u.get("runs") or [])
        if runs:
            out.append({"kind": u.get("kind", "p"), "level": u.get("level", 0),
                        "runs": runs})
    return out


def units_from_text(text: str) -> list[dict]:
    """Unidades limpias de un slot (sin marcadores de verso)."""
    proc = osis_runs(text)
    return clean_units(proc.units)


def split_intro(text: str, verse: int) -> tuple[list[dict], list[tuple[str, str]], list[dict]]:
    """Separa el material previo al marcador 'Verse N' del verso N.

    Devuelve (previas, headings_capturados, unidades_del_verso). Las previas
    (prólogos de libro/capítulo) solo se usan para verse == 1.
    """
    proc = osis_runs(text)
    units = proc.units
    for i, unit in enumerate(units):
        if len(unit["runs"]) != 1:
            continue
        run = unit["runs"][0]
        head = str(run.get("v", "")).strip()
        m = re.fullmatch(r"(?i)verse\s+(\d+)", head)
        if m and int(m.group(1)) == verse:
            return units[:i], proc.headings, units[i + 1:]
    return [], proc.headings, units


def walk_commentary(data: dict[str, bytes], verbose: bool = False) -> dict[str, dict]:
    """Slots zCom (KJV) → {code: {'intro': [...], 'chapters': {n: [...]}}}.

    El layout por testamento lleva dos slots de cabecera; después: un slot
    por libro y, por cada capítulo: un slot de cabeza + un slot por versículo
    (KJV v11n). Los módulos antiguos (Catena, Luther) repiten el mismo span
    para rangos de versos: la primera ocurrencia lleva el contenido y el resto
    se deduplica. Los preámbulos del testamento van a la introducción del
    libro y el texto de relleno del módulo se descarta.
    """
    v11n = kjv_v11n()
    books_out: dict[str, dict] = {}
    for part in ("ot", "nt"):
        if f"{part}.bzv" not in data and f"{part}.czv" not in data:
            continue
        blocks, slots = read_zverse(data, part)
        order = PROT_OT_ORDER if part == "ot" else PROT_NT_ORDER
        seen_spans: set[tuple[int, int, int]] = set()
        i = 2  # cabecera del testamento
        for code in order:
            counts = v11n.get(code, [])
            if i >= len(slots):
                break
            if not counts:
                continue
            book = books_out.setdefault(code, {"chapters": {}})
            # slot del libro: a veces lleva introducción del libro
            book_text = slot_text(blocks, slots[i]) if i < len(slots) else ""
            i += 1
            book_intro = [u for u in units_from_text(book_text)
                          if not FILLER_RE.search(runs_text(u["runs"]))]
            if book_intro:
                book.setdefault("intro", []).extend(book_intro)
            for ch, n_max in enumerate(counts, 1):
                head_text = slot_text(blocks, slots[i]) if i < len(slots) else ""
                i += 1
                chapter: list[dict] = []
                chapter_headings: list[tuple[str, str]] = []
                if head_text.strip() and not head_text.strip().startswith("<chapter"):
                    chapter.extend(u for u in units_from_text(head_text)
                                   if not FILLER_RE.search(runs_text(u["runs"])))
                for v in range(1, n_max + 1):
                    if i >= len(slots):
                        break
                    span = tuple(slots[i])
                    text = slot_text(blocks, slots[i])
                    i += 1
                    if not text.strip():
                        continue
                    if span[2] and span in seen_spans:
                        continue  # span repetido (módulos antiguos)
                    seen_spans.add(span)
                    if TESTAMENT_PREFACE_RE.search(text[:300]):
                        book.setdefault("intro", []).extend(units_from_text(text))
                        continue
                    pre, headings, units = split_intro(text, v)
                    units = clean_units(units)
                    units = [u for u in units
                             if not FILLER_RE.search(runs_text(u["runs"]))]
                    if pre and v == 1:
                        chapter.extend(clean_units(pre))
                        chapter_headings.extend(headings)
                    if units:
                        chapter.append({"verse": v, "units": units})
                if chapter or chapter_headings:
                    book["chapters"][ch] = {
                        "intro": [e for e in chapter if not e.get("verse")],
                        "headings": chapter_headings,
                        "verses": [e for e in chapter if e.get("verse")],
                    }
    return books_out


def write_commentary(out: Path, data: dict[str, bytes], module: str) -> dict:
    comments = walk_commentary(data)
    sections_dir = out / "sections"
    index: list[dict] = []
    used_books = []
    total = 0
    for code in PROT_OT_ORDER + PROT_NT_ORDER:
        book = comments.get(code)
        if not book or not book.get("chapters"):
            continue
        used_books.append(code)
        book_name = EN_BY_CODE.get(code, code)
        first_chapter = True
        for ch, data_ch in sorted(book["chapters"].items()):
            blocks: list[dict] = []
            if first_chapter and book.get("intro"):
                blocks.append({"type": "heading", "text": "Introduction",
                               "style": "section"})
                for unit in book["intro"]:
                    runs = clean_runs(unit["runs"])
                    if runs:
                        blocks.append({"type": "paragraph", "inlines": runs})
                first_chapter = False
            if data_ch.get("headings"):
                for _style, text in data_ch["headings"]:
                    blocks.append({"type": "heading", "text": text, "style": "section"})
            elif data_ch.get("intro"):
                blocks.append({"type": "heading", "text": "Introduction",
                               "style": "section"})
            for unit in data_ch.get("intro", []):
                runs = clean_runs(unit["runs"])
                if runs:
                    blocks.append({"type": "paragraph", "inlines": runs})
            for entry in data_ch.get("verses", []):
                blocks.append({"type": "heading",
                               "text": f"Verse {entry['verse']}", "style": "section"})
                for unit in entry["units"]:
                    runs = clean_runs(unit["runs"])
                    if runs:
                        blocks.append({"type": "paragraph", "inlines": runs})
            if not blocks:
                continue
            sid = f"{code}.{ch}"
            summary = ""
            for b in blocks:
                if b["type"] == "paragraph" and b["inlines"]:
                    summary = runs_text(b["inlines"])[:200]
                    break
            section = {"id": sid, "title": f"{book_name} {ch}",
                       "summary": summary, "reference": sid,
                       "referenceLabel": f"{book_name} {ch}", "tags": [],
                       "blocks": blocks}
            write_json(sections_dir / f"{sid}.json", section)
            index.append({"id": sid, "title": section["title"], "summary": summary,
                          "reference": sid,
                          "referenceLabel": section["referenceLabel"], "tags": []})
            total += 1
    write_resource_manifest(out, module, "commentary", MODULES[module]["meta"],
                            {"books": len(used_books), "sections": total, "verses": 0})
    write_json(out / "sections.json", index)
    return {"books": len(used_books), "sections": total}


# ---------------------------------------------------------------------------
# CLI / self-check
# ---------------------------------------------------------------------------


def html_of(text: str, n: int = 90) -> str:
    return re.sub(r"\s+", " ", text)[:n].strip()


def selfcheck_module(name: str, zips_dir: Path) -> None:
    data = open_module(name, zips_dir)
    mod = MODULES[name]
    kind = mod["kind"]

    if kind == "bible":
        v11n = vulg_v11n() if mod.get("v11n") == "vulg" else kjv_v11n()
        blocks, slots = read_zverse(data, "ot")
        parsed = parse_bible(data, mod["v11n"])
        books = parsed["books"]
        total_c = sum(len(b["chapters"]) for b in books.values())
        total_v = sum(sum(len(g["verses"]) for g in ch["blocks"] if g["type"] == "verseGroup")
                      for b in books.values() for ch in b["chapters"])
        print(f"[{name}] {kind}: {len(books)} libros, {total_c} caps, {total_v} versos "
              f"(tabla: expected {sum(len(v) for v in v11n.values())} caps en "
              f"{len(v11n)} libros)")
        gen1 = next((g for g in books.get("GEN", {}).get("chapters", []) if g["n"] == 1), None)
        if gen1:
            for g in gen1["blocks"]:
                if g["type"] == "verseGroup":
                    guts = "<|>".join(
                        (v["inlines"][0]["v"] if "v" in v["inlines"][0]
                         else f'<{v["inlines"][0].get("t")}>')
                        for v in g["verses"])
                    print("  GEN 1:", guts[:160])
        exo8 = next((ch for ch in books.get("EXO", {}).get("chapters", []) if ch["n"] == 8), None)
        if exo8:
            verses = [v for g in exo8["blocks"] if g["type"] == "verseGroup" for v in g["verses"]]
            print(f"  EXO 8: {len(verses)} versos; v1:", runs_text(verses[0]["inlines"])[:110])
        psa1 = next((ch for ch in books.get("PSA", {}).get("chapters", []) if ch["n"] == 1), None)
        if psa1:
            asks = [(g.get("style"), g.get("indent"), len(g["verses"]))
                    for g in psa1["blocks"] if g["type"] == "verseGroup"]
            print("  PSA 1 grupos:", asks[:4])
        return

    if kind == "devotional":
        entries = read_zld(data)
        print(f"[{name}] zLD: {len(entries)} entradas")
        key, text = entries[0]
        proc = osis_runs(text, mode="devotional")
        print(f"  {key}: {len(proc.sections)} secciones",
              [s.get("title") for s in proc.sections])
        for sec in proc.sections:
            for unit in sec["units"][:1]:
                print("    >", runs_text(unit["runs"])[:110])
        print("  xrefs:", proc.xrefs[:2])
        return

    if kind == "dictionary":
        entries = read_zld(data)
        print(f"[{name}] zLD: {len(entries)} entradas")
        for probe in (0, len(entries) // 2, len(entries) - 1):
            key, text = entries[probe]
            proc = osis_runs(text, mode="plain")
            units = [u for u in proc.units if u.get("runs")]
            sample = runs_text(units[0]["runs"]) if units else ""
            print(f"  {key}: {len(units)} párrafos |", html_of(sample, 100))
        return

    if kind == "genbook":
        tree = read_genbook(data)
        filled = [(p, t) for p, t in tree if t.strip()]
        print(f"[{name}] genbook: {len(tree)} nodos, {len(filled)} con texto")
        for path, text in filled[:2]:
            sample = re.sub(HTML_TAG_RE, " ", text)
            print("   ", "/".join(path)[:80], "→", html_of(sample, 90))
        return

    if kind == "commentary":
        comments = walk_commentary(data)
        total = sum(len(d["verses"]) for b in comments.values()
                    for d in b["chapters"].values())
        per_book = {code: sum(len(d["verses"]) for d in b["chapters"].values())
                    for code, b in comments.items()}
        filled = sum(1 for b in comments.values() for d in b["chapters"].values()
                     if d["verses"] or d["intro"])
        print(f"[{name}] commentary: libros {len(comments)}, capítulos {filled}, "
              f"versos con notas {total}")
        for code in ("MAT", "GEN", "JHN"):
            book = comments.get(code)
            if not book:
                continue
            d1 = book["chapters"].get(1)
            if not d1:
                continue
            if d1["intro"]:
                print(f"  {code}.1 intro:", html_of(runs_text(d1["intro"][0]["runs"]), 90))
            for e in d1["verses"][:2]:
                sample = runs_text(e["units"][0]["runs"]) if e["units"] else ""
                print(f"  {code}.1 v{e['verse']}: {html_of(sample, 100)}")
        print("  por libro (10):", list(per_book.items())[:10])
        return


def module_files(zips_dir: Path) -> list[tuple[str, Path]]:
    out = []
    if zips_dir.is_dir():
        for mod in MODULES:
            p = zips_dir / f"{mod}.zip"
            if p.is_file():
                out.append((mod, p))
    return sorted(out)


def list_modules(zips_dir: Path) -> int:
    found = module_files(zips_dir)
    print(f"Paquetes en {zips_dir}: {len(found)}/{len(MODULES)}")
    for mod, path in found:
        print(f"  {mod:22s} {MODULES[mod]['kind']:11s} → {MODULES[mod]['resource']}")
    missing = [m for m in MODULES if m not in {f[0] for f in found}]
    if missing:
        print("  faltantes:", ", ".join(missing))
    return 0


def import_module(name: str, out_dir: Path, zips_dir: Path) -> dict:
    mod = MODULES[name]
    target = out_dir / mod["resource"]
    target.mkdir(parents=True, exist_ok=True)
    data = open_module(name, zips_dir)
    kind = mod["kind"]
    if kind == "bible":
        return write_bible(target, data, name)
    if kind == "devotional":
        return write_devotional(target, data, name)
    if kind == "dictionary":
        return write_dictionary(target, data, name)
    if kind == "genbook":
        return write_genbook(target, data, name)
    if kind == "commentary":
        return write_commentary(target, data, name)
    raise ValueError(f"kind desconocido {kind}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--zips", default=str(DEFAULT_ZIPS),
                    help=f"directorio con los {len(MODULES)} zips de CrossWire")
    ap.add_argument("--out", default=str(DEFAULT_OUT), help="raíz de salida")
    ap.add_argument("--list", action="store_true", help="lista paquetes disponibles")
    ap.add_argument("--selfcheck", action="store_true", help="valida lectores")
    ap.add_argument("--module", action="append", help="módulo a importar (repetible)")
    args = ap.parse_args()
    zips_dir = Path(args.zips)
    out_dir = Path(args.out)

    if args.list:
        return list_modules(zips_dir)
    if args.selfcheck:
        names = args.module if args.module else [m for m, _ in module_files(zips_dir)]
        for name in names:
            try:
                selfcheck_module(name, zips_dir)
            except Exception as exc:  # noqa: BLE001
                print(f"[{name}] FALLO: {exc}")
                if args.module:
                    raise
        return 0
    if not args.module:
        ap.print_usage()
        print("usá --module, --list o --selfcheck", file=sys.stderr)
        return 2
    for name in args.module:
        stats = import_module(name, out_dir, zips_dir)
        print(f"OK {name} → {out_dir / MODULES[name]['resource']}: {stats}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
