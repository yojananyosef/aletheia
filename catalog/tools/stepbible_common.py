#!/usr/bin/env python3
"""Utilidades compartidas para las fuentes STEPBible.

Las fuentes TAHOT/TAGNT/TBESH/TBESG/TEHMC/TEGMC se publican bajo
CC BY 4.0 por STEPBible.org y Tyndale House Cambridge. Este módulo no
redistribuye los archivos: solo los lee desde ``catalog/sources/stepbible``
para generar el catálogo de la app.
"""
from __future__ import annotations

import html
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
STEP_DIR = ROOT / "catalog" / "sources" / "stepbible"

# Abreviaturas de STEPBible -> códigos USFM/OSIS de la app.
BOOK_MAP = {
    "Gen": "GEN", "Exo": "EXO", "Lev": "LEV", "Num": "NUM", "Deu": "DEU",
    "Jos": "JOS", "Jdg": "JDG", "Rut": "RUT", "1Sa": "1SA", "2Sa": "2SA",
    "1Ki": "1KI", "2Ki": "2KI", "1Ch": "1CH", "2Ch": "2CH", "Ezr": "EZR",
    "Neh": "NEH", "Est": "EST", "Job": "JOB", "Psa": "PSA", "Pro": "PRO",
    "Ecc": "ECC", "Sng": "SNG", "Isa": "ISA", "Jer": "JER", "Lam": "LAM",
    "Ezk": "EZK", "Dan": "DAN", "Hos": "HOS", "Jol": "JOL", "Amo": "AMO",
    "Oba": "OBA", "Jon": "JON", "Mic": "MIC", "Nam": "NAM", "Hab": "HAB",
    "Zep": "ZEP", "Hag": "HAG", "Zec": "ZEC", "Mal": "MAL",
    "Mat": "MAT", "Mrk": "MRK", "Luk": "LUK", "Jhn": "JHN", "Act": "ACT",
    "Rom": "ROM", "1Co": "1CO", "2Co": "2CO", "Gal": "GAL", "Eph": "EPH",
    "Php": "PHP", "Col": "COL", "1Th": "1TH", "2Th": "2TH", "1Ti": "1TI",
    "2Ti": "2TI", "Tit": "TIT", "Phm": "PHM", "Heb": "HEB", "Jas": "JAS",
    "1Pe": "1PE", "2Pe": "2PE", "1Jn": "1JN", "2Jn": "2JN", "3Jn": "3JN",
    "Jud": "JUD", "Rev": "REV",
}

BOOK_NAMES_ES = {
    "GEN": "Génesis", "EXO": "Éxodo", "LEV": "Levítico", "NUM": "Números",
    "DEU": "Deuteronomio", "JOS": "Josué", "JDG": "Jueces", "RUT": "Rut",
    "1SA": "1 Samuel", "2SA": "2 Samuel", "1KI": "1 Reyes", "2KI": "2 Reyes",
    "1CH": "1 Crónicas", "2CH": "2 Crónicas", "EZR": "Esdras",
    "NEH": "Nehemías", "EST": "Ester", "JOB": "Job", "PSA": "Salmos",
    "PRO": "Proverbios", "ECC": "Eclesiastés", "SNG": "Cantares",
    "ISA": "Isaías", "JER": "Jeremías", "LAM": "Lamentaciones",
    "EZK": "Ezequiel", "DAN": "Daniel", "HOS": "Oseas", "JOL": "Joel",
    "AMO": "Amós", "OBA": "Obadías", "JON": "Jonás", "MIC": "Miqueas",
    "NAM": "Nahúm", "HAB": "Habacuc", "ZEP": "Sofonías", "HAG": "Hageo",
    "ZEC": "Zacarías", "MAL": "Malaquías", "MAT": "Mateo", "MRK": "Marcos",
    "LUK": "Lucas", "JHN": "Juan", "ACT": "Hechos", "ROM": "Romanos",
    "1CO": "1 Corintios", "2CO": "2 Corintios", "GAL": "Gálatas",
    "EPH": "Efesios", "PHP": "Filipenses", "COL": "Colosenses",
    "1TH": "1 Tesalonicenses", "2TH": "2 Tesalonicenses",
    "1TI": "1 Timoteo", "2TI": "2 Timoteo", "TIT": "Tito", "PHM": "Filemón",
    "HEB": "Hebreos", "JAS": "Santiago", "1PE": "1 Pedro", "2PE": "2 Pedro",
    "1JN": "1 Juan", "2JN": "2 Juan", "3JN": "3 Juan", "JUD": "Judas",
    "REV": "Apocalipsis",
}

# Glosas españolas propias para las voces más frecuentes. No se toman de
# TBESH/TBESG: son una ayuda editorial breve y el resto conserva la glosa
# original en inglés, claramente etiquetada en la interfaz.
SPANISH_GLOSS = {
    "H0001": "padre", "H0002": "padre", "H0136": "Señor", "H0410": "Dios",
    "H0430": "Dios", "H0776": "tierra", "H0802": "mujer", "H0834": "que",
    "H0853": "objeto directo", "H1121": "hijo", "H1130": "hijo de",
    "H1201": "hijo de", "H1254": "crear", "H1285": "pacto",
    "H1323": "hija", "H1697": "palabra", "H1732": "David",
    "H1755": "generación", "H1931": "él", "H1961": "ser, suceder",
    "H2009": "he aquí", "H2142": "recordar", "H2233": "descendencia",
    "H2372": "ver", "H2421": "vivir", "H2617": "misericordia",
    "H2896": "bueno", "H3027": "mano", "H3063": "Judá", "H3068": "Señor",
    "H3117": "día", "H3190": "hacer bien", "H3212": "ir", "H3318": "salir",
    "H3389": "Jerusalén", "H3411": "lugar", "H3478": "Israel",
    "H3548": "sacerdote", "H3588": "porque, que", "H3605": "todo",
    "H3701": "plata", "H376": "hombre", "H3820": "corazón",
    "H3915": "noche", "H4100": "qué", "H4150": "tiempo señalado",
    "H4300": "fuego", "H4325": "agua", "H4428": "rey", "H4467": "reino",
    "H4480": "de, desde", "H4714": "Egipto", "H4872": "Moisés",
    "H5030": "profeta", "H517": "madre", "H5315": "alma, ser",
    "H5414": "dar", "H559": "decir", "H5612": "libro, escrito",
    "H5650": "siervo", "H5769": "siempre, eterno", "H5971": "pueblo",
    "H6213": "hacer", "H6440": "rostro, delante", "H6635": "ejército",
    "H6680": "mandar", "H7200": "ver", "H7225": "principio",
    "H7307": "espíritu, viento", "H7725": "volver", "H7843": "destruir",
    "H7971": "enviar", "H8064": "cielos", "H8085": "oír",
    "H8104": "guardar", "H835": "bienaventurado", "H8451": "ley",
    "H0853": "objeto directo", "H0898": "obrar con engaño",
    "H9002": "y", "H9003": "en", "H9005": "a, para", "H9006": "de",
    "H9009": "el, la", "H9010": "el, la", "H9014": "y", "H9016": "y",
    "G0025": "amar", "G0026": "amor", "G0080": "hermano",
    "G0093": "injusticia", "G0165": "siglo, eternidad", "G0166": "eterno",
    "G0175": "inútil", "G0225": "verdad", "G0235": "pero",
    "G0237": "de otro lugar", "G0243": "otro", "G0255": "inútil",
    "G0288": "viña", "G0294": "sin", "G0305": "subir",
    "G0321": "llevar", "G0386": "resurrección", "G0399": "presentar",
    "G0400": "ser", "G0435": "hombre", "G0444": "hombre",
    "G0456": "reconstruir", "G0478": "resistir", "G0520": "llevar",
    "G0599": "morir", "G0616": "dar a luz", "G0649": "enviar",
    "G0652": "apóstol", "G0907": "bautizar", "G0932": "reino",
    "G0976": "libro", "G1078": "origen, genealogía", "G1080": "engendrar",
    "G1135": "mujer", "G1242": "pacto", "G1249": "servir",
    "G1290": "dispersión", "G1391": "gloria", "G1417": "dos",
    "G1484": "gentes, naciones", "G1515": "paz", "G1519": "a, para",
    "G1537": "de, desde", "G1577": "iglesia", "G1656": "misericordia",
    "G1680": "esperanza", "G1722": "en", "G1860": "promesa",
    "G1909": "sobre", "G1930": "enderezar", "G2018": "traer",
    "G2036": "decir", "G2064": "venir", "G2098": "evangelio",
    "G2192": "tener", "G2222": "vida", "G2250": "día",
    "G2288": "muerte", "G2316": "Dios", "G2424": "Jesús",
    "G2453": "judío", "G2532": "y", "G2588": "corazón",
    "G2596": "según", "G266": "pecado", "G2889": "mundo",
    "G2962": "Señor", "G2983": "tomar", "G3056": "palabra",
    "G3106": "testificar", "G3141": "testimonio", "G3179": "mover",
    "G3306": "permanecer", "G3326": "con, después", "G3361": "no",
    "G3439": "unigénito", "G3450": "mi", "G3498": "muerto",
    "G3551": "ley", "G3624": "casa", "G3686": "nombre",
    "G3704": "para que", "G3739": "que, quien", "G3751": "lomos",
    "G3756": "no", "G3772": "cielo", "G3866": "depósito",
    "G3875": "consolador", "G3952": "venida", "G3962": "padre",
    "G3972": "Pablo", "G4074": "Pedro", "G4151": "espíritu",
    "G4160": "hacer", "G4396": "profeta", "G4442": "fuego",
    "G4459": "cómo", "G4521": "sábado", "G4561": "carne",
    "G4582": "luna", "G4655": "tinieblas", "G4716": "cruz",
    "G4982": "salvar", "G5023": "estas cosas", "G5083": "guardar",
    "G5207": "hijo", "G5457": "luz", "G5485": "gracia",
    "G5547": "Cristo", "G5590": "alma, vida", "G5610": "hora",
    "G5613": "como", "G575": "de, desde", "G0932": "reino",
}

# Traducciones de la morfología. Los códigos y sus expansiones en inglés
# provienen de TEHMC/TEGMC (CC BY 4.0); esta traducción es propia.
_KEY_ES = {
    "Function": "función", "Form": "forma", "Gender": "género",
    "Number": "número", "State": "estado", "Stem": "tema",
    "Action": "acción", "Voice": "voz", "Tense": "tiempo", "Mood": "modo",
    "Person": "persona", "Case": "caso", "Extra": "extra",
    "Name type": "tipo de nombre", "Language": "idioma",
}
_VALUE_ES = {
    "Conjunction": "conjunción", "Preposition": "preposición",
    "Particle": "partícula", "Definite article (Hebrew)": "artículo definido",
    "Definite": "definido", "Object indicator": "marcador de objeto",
    "Noun": "sustantivo", "Verb": "verbo", "Adjective": "adjetivo",
    "Adverb": "adverbio", "Pronoun": "pronombre", "Name": "nombre propio",
    "Interjection": "interjección", "Conditional": "condicional",
    "Negative": "negativo", "Common": "común", "Masculine": "masculino",
    "Feminine": "femenino", "Neuter": "neutro", "Singular": "singular",
    "Plural": "plural", "Dual": "dual", "Absolute": "absoluto",
    "Construct": "constructo", "Emphatic": "enfático",
    "Perfect": "perfecto", "Imperfect": "imperfecto",
    "Imperative": "imperativo", "Jussive": "yusivo",
    "Cohortative": "cohortativo", "Infinitive": "infinitivo",
    "Participle": "participio", "Indicative": "indicativo",
    "First": "primera", "Second": "segunda", "Third": "tercera",
    "Nominative": "nominativo", "Accusative": "acusativo",
    "Genitive": "genitivo", "Dative": "dativo", "Vocative": "vocativo",
    "Active": "activo", "Passive": "pasivo", "Middle": "medio",
    "Reflexive": "reflexivo", "Simple": "simple",
    "Intensive": "intensivo", "Causative": "causativo",
    "Location": "lugar", "Person": "persona", "Gentilic": "gentilicio",
    "Title": "título", "Comparative": "comparativo",
    "Superlative": "superlativo", "Contracted form": "forma contracta",
    "Past/present": "pasado/presente", "Future": "futuro",
    "Qal": "qal", "Niphal": "nifal", "Piel": "piel", "Pual": "pual",
    "Hiphil": "hifil", "Hophal": "hofal", "Hithpael": "hitpael",
    "Aramaic": "arameo", "Hebrew": "hebreo", "Greek": "griego",
    "article": "artículo", "Either gender": "género común",
    "Either": "cualquiera", "Suffix": "sufijo", "Personal": "personal",
    "Action": "acción", "Voice": "voz", "Tense": "tiempo", "Mood": "modo",
    "Stem": "tema", "Form": "forma", "Function": "función",
    "Gender": "género", "Number": "número", "State": "estado",
    "Person": "persona", "Case": "caso", "Extra": "extra",
}


def normalize_strong(tag: str | None) -> str | None:
    """H0430G / H430 / {H0430} -> H0430; G26 -> G0026."""
    if not tag:
        return None
    m = re.search(r"([HG])\s*0*(\d{1,4})", tag)
    if not m:
        return None
    return f"{m.group(1)}{int(m.group(2)):04d}"


def root_strong(dstrong: str | None) -> tuple[str | None, str | None]:
    """Devuelve (Strong base, etiqueta completa) de un campo dStrong.

    En hebreo se prefiere la raíz entre llaves (p. ej. H9003/{H7225G} ->
    H7225/H7225G) y se descartan los prefijos no léxicos H9xxx si hay una
    alternativa. En griego el campo suele ser G0976=N-NSF.
    """
    if not dstrong:
        return None, None
    tags = re.findall(r"([HG]\d{1,4}[A-Z]?)", dstrong)
    if not tags:
        return None, None
    braced = re.findall(r"\{([HG]\d{1,4}[A-Z]?)\}", dstrong)
    candidates = braced + tags
    chosen = None
    for tag in candidates:
        m = re.match(r"[HG]9\d{3}", tag)
        if not m:
            chosen = tag
            break
    if chosen is None:
        chosen = candidates[0]
    return normalize_strong(chosen), chosen


def clean_hebrew(value: str) -> str:
    value = value.replace("/", "").replace("\\", "")
    return re.sub(r"\s+", " ", value).strip()


def clean_greek(value: str) -> tuple[str, str | None]:
    """Separa «Βίβλος (Biblos)» en texto griego y transliteración."""
    value = value.strip()
    m = re.match(r"^(.*?)\s*\(([^()]*)\)\s*$", value)
    if m:
        return m.group(1).strip(), m.group(2).strip() or None
    return value, None


def clean_gloss(value: str) -> str:
    value = value.replace("/", " ")
    value = value.replace("<", "").replace(">", "")
    value = value.replace("[", "").replace("]", "")
    value = html.unescape(value)
    return re.sub(r"\s+", " ", value).strip(" ;,.")


def clean_definition(value: str) -> str:
    value = re.sub(r"<br\s*/?>", "\n", value, flags=re.I)
    value = re.sub(r"<[^>]+>", " ", value)
    value = html.unescape(value)
    value = re.sub(r"[ \t]+", " ", value)
    value = re.sub(r"\n\s*\n+", "\n\n", value)
    return value.strip()


def _split_top_level(value: str, sep: str = ";") -> list[str]:
    out: list[str] = []
    depth = 0
    start = 0
    for i, ch in enumerate(value):
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth = max(depth - 1, 0)
        elif ch == sep and depth == 0:
            out.append(value[start:i].strip())
            start = i + 1
    out.append(value[start:].strip())
    return [part for part in out if part]


def _translate_terms(value: str) -> str:
    # Primero las expresiones más largas para no romper «Definite article».
    for en in sorted(_VALUE_ES, key=len, reverse=True):
        es = _VALUE_ES[en]
        if re.fullmatch(r"\w+", en):
            value = re.sub(rf"\b{re.escape(en)}\b", es, value)
        else:
            value = value.replace(en, es)
    value = value.replace("hence ", "por tanto, ")
    value = value.replace("with ", "con ")
    return re.sub(r"\s+", " ", value).strip()


def translate_expansion(description: str) -> str:
    parts = _split_top_level(description)
    out: list[str] = []
    for part in parts:
        if "=" in part:
            key, value = part.split("=", 1)
            key_es = _KEY_ES.get(key.strip(), key.strip().lower())
            out.append(f"{key_es}: {_translate_terms(value.strip())}")
        else:
            out.append(_translate_terms(part))
    return "; ".join(out)


_EXPANSIONS: dict[str, str] | None = None


def load_morphology_expansions() -> dict[str, str]:
    global _EXPANSIONS
    if _EXPANSIONS is not None:
        return _EXPANSIONS
    expansions: dict[str, str] = {}
    for name in (
        "TEHMC - Translators Expansion of Hebrew Morphology Codes - STEPBible.org CC BY.txt",
        "TEGMC - Translators Expansion of Greek Morphhology Codes - STEPBible.org CC BY.txt",
    ):
        path = STEP_DIR / name
        if not path.exists():
            continue
        for line in path.read_text(encoding="utf-8-sig").splitlines():
            if "\t" not in line:
                continue
            code, description = line.split("\t", 1)
            code = code.strip()
            description = description.strip()
            if code and description.startswith("Function="):
                expansions[code] = translate_expansion(description)
    _EXPANSIONS = expansions
    return expansions


def translate_brief_morph(code: str) -> str:
    """Traduce códigos breves de léxico como H:N-M o N:N-M-P."""
    code = code.strip()
    if not code:
        return ""
    if ":" not in code:
        return code
    language, rest = code.split(":", 1)
    lang = {"H": "hebreo", "A": "arameo", "G": "griego", "N": "nombre"}.get(
        language, language
    )
    function_map = {
        "N": "sustantivo", "A": "adjetivo", "V": "verbo",
        "Adv": "adverbio", "Art": "artículo", "Conj": "conjunción",
        "Prep": "preposición", "Part": "partícula", "Neg": "negativo",
        "PerP": "pronombre personal", "PosP": "pronombre posesivo",
        "RefP": "pronombre reflexivo", "RelP": "pronombre relativo",
        "DemP": "pronombre demostrativo", "Intg": "interrogativo",
        "Intj": "interjección", "Cond": "condicional", "Cor": "correlativo",
        "ImpP": "pronombre impersonal",
    }
    gender_map = {
        "M": "masculino", "F": "femenino", "N": "neutro",
        "C": "común",
    }
    extra_map = {
        "S": "singular", "P": "plural", "D": "dual",
        "L": "lugar", "G": "gentilicio", "T": "título",
        "LG": "gentilicio", "LI": "letra", "P": "persona",
    }
    tokens = [token for token in rest.split("-") if token]
    bits: list[str] = []
    if tokens:
        bits.append(function_map.get(tokens[0], tokens[0]))
    if len(tokens) > 1:
        bits.append(gender_map.get(tokens[1], tokens[1]))
    for token in tokens[2:]:
        bits.append(extra_map.get(token, token))
    return f"{lang}: " + ", ".join(bits)


def translate_full_morph(code: str, *, greek: bool) -> str:
    expansions = load_morphology_expansions()
    code = code.strip()
    if not code:
        return ""
    if ":" in code and "=" not in code:
        return translate_brief_morph(code)
    parts: list[str] = []
    for segment in code.split("/"):
        segment = segment.strip()
        if not segment:
            continue
        expansion = expansions.get(segment)
        if expansion is None and not greek:
            expansion = expansions.get("H" + segment) or expansions.get("A" + segment)
        if expansion is None and greek:
            expansion = expansions.get("G" + segment)
        parts.append(expansion or segment)
    return " + ".join(parts)


def write_morphology_map(codes: set[str], *, greek: bool, path: Path) -> None:
    """Fusiona códigos nuevos en ``morphology.json``."""
    existing: dict[str, str] = {}
    if path.exists():
        try:
            existing = json.loads(path.read_text(encoding="utf-8"))
        except (ValueError, OSError):
            existing = {}
    for code in codes:
        if not code:
            continue
        translated = translate_full_morph(code, greek=greek)
        if translated and translated != code:
            existing.setdefault(code, translated)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(existing, ensure_ascii=False, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )
