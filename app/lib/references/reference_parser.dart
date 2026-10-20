/// Parser de referencias bíblicas (M0).
///
/// Acepta formas como: "Jn 1:1", "Juan 1:1-3", "1 Corintios 13:4-7",
/// "Romanos 8:28", "Salmo 23", "salmos 23:1", "sanjuan 3:16" y la forma
/// canónica interna "JHN.1.1".
library;

class ParsedReference {
  const ParsedReference({
    required this.bookCode,
    required this.chapter,
    this.verseStart,
    this.verseEnd,
  });

  final String bookCode;
  final int chapter;
  final int? verseStart;
  final int? verseEnd;

  String get canonical {
    var s = '$bookCode.$chapter';
    if (verseStart != null) {
      s += '.$verseStart';
      if (verseEnd != null) s += '-$verseEnd';
    }
    return s;
  }

  String get display => displayIn('es');

  /// Referencia legible en el idioma indicado (`es`/`en`).
  String displayIn(String lang) {
    var s = '${bookDisplayName(bookCode, lang: lang)} $chapter';
    if (verseStart != null) {
      s += ':$verseStart';
      if (verseEnd != null) s += '-$verseEnd';
    }
    return s;
  }
}

/// Nombres para mostrar (es).
const Map<String, String> _bookDisplayNames = {
  'GEN': 'Génesis',
  'EXO': 'Éxodo',
  'LEV': 'Levítico',
  'NUM': 'Números',
  'DEU': 'Deuteronomio',
  'JOS': 'Josué',
  'JDG': 'Jueces',
  'RUT': 'Rut',
  '1SA': '1 Samuel',
  '2SA': '2 Samuel',
  '1KI': '1 Reyes',
  '2KI': '2 Reyes',
  '1CH': '1 Crónicas',
  '2CH': '2 Crónicas',
  'EZR': 'Esdras',
  'NEH': 'Nehemías',
  'EST': 'Ester',
  'JOB': 'Job',
  'PSA': 'Salmos',
  'PRO': 'Proverbios',
  'ECC': 'Eclesiastés',
  'SNG': 'Cantares',
  'ISA': 'Isaías',
  'JER': 'Jeremías',
  'LAM': 'Lamentaciones',
  'EZK': 'Ezequiel',
  'DAN': 'Daniel',
  'HOS': 'Oseas',
  'JOL': 'Joel',
  'AMO': 'Amós',
  'OBA': 'Obadías',
  'JON': 'Jonás',
  'MIC': 'Miqueas',
  'NAM': 'Nahúm',
  'HAB': 'Habacuc',
  'ZEP': 'Sofonías',
  'HAG': 'Hageo',
  'ZEC': 'Zacarías',
  'MAL': 'Malaquías',
  'MAT': 'Mateo',
  'MRK': 'Marcos',
  'LUK': 'Lucas',
  'JHN': 'Juan',
  'ACT': 'Hechos',
  'ROM': 'Romanos',
  '1CO': '1 Corintios',
  '2CO': '2 Corintios',
  'GAL': 'Gálatas',
  'EPH': 'Efesios',
  'PHP': 'Filipenses',
  'COL': 'Colosenses',
  '1TH': '1 Tesalonicenses',
  '2TH': '2 Tesalonicenses',
  '1TI': '1 Timoteo',
  '2TI': '2 Timoteo',
  'TIT': 'Tito',
  'PHM': 'Filemón',
  'HEB': 'Hebreos',
  'JAS': 'Santiago',
  '1PE': '1 Pedro',
  '2PE': '2 Pedro',
  '1JN': '1 Juan',
  '2JN': '2 Juan',
  '3JN': '3 Juan',
  'JUD': 'Judas',
  'REV': 'Apocalipsis',
};

const Map<String, List<String>> _bookAliases = {
  'GEN': ['genesis', 'gen', 'gn'],
  'EXO': ['exodo', 'ex', 'exod'],
  'LEV': ['levitico', 'lev', 'lv'],
  'NUM': ['numeros', 'num', 'nm'],
  'DEU': ['deuteronomio', 'deut', 'dt'],
  'JOS': ['josue', 'jos', 'js'],
  'JDG': ['jueces', 'jue', 'judg', 'jc'],
  'RUT': ['rut', 'rt'],
  '1SA': ['1samuel', '1sam', '1sa', '1sm'],
  '2SA': ['2samuel', '2sam', '2sa', '2sm'],
  '1KI': ['1reyes', '1rey', '1re', '1ki'],
  '2KI': ['2reyes', '2rey', '2re', '2ki'],
  '1CH': ['1cronicas', '1cro', '1cr', '1ch'],
  '2CH': ['2cronicas', '2cro', '2cr', '2ch'],
  'EZR': ['esdras', 'esd', 'ezr'],
  'NEH': ['nehemias', 'neh', 'ne'],
  'EST': ['ester', 'est'],
  'JOB': ['job', 'jb'],
  'PSA': ['salmos', 'salmo', 'salm', 'sal', 'psa', 'ps'],
  'PRO': ['proverbios', 'prov', 'pro', 'pr'],
  'ECC': ['eclesiastes', 'ecl', 'ecc', 'ec'],
  'SNG': ['cantares', 'cantar', 'canticos', 'cantico', 'cnt', 'sng'],
  'ISA': ['isaias', 'isa', 'is'],
  'JER': ['jeremias', 'jer', 'jr'],
  'LAM': ['lamentaciones', 'lam', 'lm'],
  'EZK': ['ezequiel', 'eze', 'ezk', 'ez'],
  'DAN': ['daniel', 'dan', 'dn'],
  'HOS': ['oseas', 'ose', 'hos', 'os'],
  'JOL': ['joel', 'jol', 'jl'],
  'AMO': ['amos', 'amo', 'am'],
  'OBA': ['obadias', 'oba', 'ob', 'abd'],
  'JON': ['jonas', 'jon', 'jns'],
  'MIC': ['miqueas', 'miq', 'mic', 'mi'],
  'NAM': ['nahum', 'nah', 'nam'],
  'HAB': ['habacuc', 'hab', 'hb'],
  'ZEP': ['sofonias', 'sof', 'zep', 'so'],
  'HAG': ['hageo', 'hag', 'hg'],
  'ZEC': ['zacarias', 'zac', 'zec', 'zc'],
  'MAL': ['malaquias', 'mal', 'ml'],
  'MAT': ['mateo', 'mat', 'mt'],
  'MRK': ['marcos', 'mar', 'mrk', 'mr', 'mc'],
  'LUK': ['lucas', 'luc', 'luk', 'lc'],
  'JHN': ['juan', 'jhn', 'jn', 'sanjuan'],
  'ACT': ['hechos', 'hch', 'act', 'hec'],
  'ROM': ['romanos', 'rom', 'ro', 'rm'],
  '1CO': ['1corintios', '1cor', '1co'],
  '2CO': ['2corintios', '2cor', '2co'],
  'GAL': ['galatas', 'gal', 'ga'],
  'EPH': ['efesios', 'efe', 'eph', 'ef'],
  'PHP': ['filipenses', 'fil', 'flp', 'php'],
  'COL': ['colosenses', 'col', 'clo'],
  '1TH': ['1tesalonicenses', '1tes', '1ts', '1th'],
  '2TH': ['2tesalonicenses', '2tes', '2ts', '2th'],
  '1TI': ['1timoteo', '1tim', '1ti', '1tm'],
  '2TI': ['2timoteo', '2tim', '2ti', '2tm'],
  'TIT': ['tito', 'tit', 'ti'],
  'PHM': ['filemon', 'flm', 'phm'],
  'HEB': ['hebreos', 'heb', 'he'],
  'JAS': ['santiago', 'sant', 'stg', 'jas', 'jm'],
  '1PE': ['1pedro', '1ped', '1pe', '1pd', '1p'],
  '2PE': ['2pedro', '2ped', '2pe', '2pd', '2p'],
  '1JN': ['1juan', '1jn', '1jhn'],
  '2JN': ['2juan', '2jn', '2jhn'],
  '3JN': ['3juan', '3jn', '3jhn'],
  'JUD': ['judas', 'jud'],
  'REV': ['apocalipsis', 'apoc', 'apo', 'ap', 'rev'],
};

final Map<String, String> _aliasIndex = () {
  final map = <String, String>{};
  for (final entry in _bookAliases.entries) {
    map[_compress(entry.key)] = entry.key; // p.ej. "1CO"
    for (final alias in entry.value) {
      map[_compress(alias)] = entry.key;
    }
  }
  // Nombres en inglés (el lector puede mostrar "John 1:2" con la interfaz en
  // inglés): se aceptan al escribir la referencia.
  for (final entry in _bookDisplayNamesEn.entries) {
    map.putIfAbsent(_compress(entry.value), () => entry.key);
  }
  return map;
}();

final List<String> _aliasesByLength = _aliasIndex.keys.toList()
  ..sort((a, b) => b.length.compareTo(a.length));

String _deaccent(String input) {
  const repl = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
    'à': 'a',
    'è': 'e',
    'ì': 'i',
    'ò': 'o',
    'ù': 'u',
  };
  final sb = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    sb.write(repl[ch] ?? ch);
  }
  return sb.toString();
}

String _compress(String s) => _deaccent(s).replaceAll(RegExp(r'[^a-z0-9]'), '');

String bookDisplayName(String code, {String lang = 'es'}) => lang == 'en'
    ? (_bookDisplayNamesEn[code] ?? _bookDisplayNames[code] ?? code)
    : (_bookDisplayNames[code] ?? code);
/// Libros del Nuevo Testamento (canon protestante).
const Set<String> kNewTestamentBooks = {
  'MAT', 'MRK', 'LUK', 'JHN', 'ACT', 'ROM', '1CO', '2CO', 'GAL', 'EPH',
  'PHP', 'COL', '1TH', '2TH', '1TI', '2TI', 'TIT', 'PHM', 'HEB', 'JAS',
  '1PE', '2PE', '1JN', '2JN', '3JN', 'JUD', 'REV',
};

bool isNewTestamentBook(String code) => kNewTestamentBooks.contains(code);


/// Resuelve un nombre, abreviatura o código de libro a su código canónico.
///
/// Acepta «Juan», «Jn», «JHN» o «1 Corintios»; devuelve `null` si no lo
/// reconoce. Se usa en la sintaxis de búsqueda (`book:Jn`, `bible:"Jn 3"`).
String? bookCodeForInput(String input) {
  final compressed = _compress(input);
  if (compressed.isEmpty) return null;
  final direct = _aliasIndex[compressed];
  if (direct != null) return direct;
  for (final alias in _aliasesByLength) {
    if (compressed.startsWith(alias)) return _aliasIndex[alias];
  }
  return null;
}

/// Nombres en inglés (KJV): el lector muestra la referencia en el idioma de la
/// interfaz, igual que el original.
const Map<String, String> _bookDisplayNamesEn = {
  'GEN': 'Genesis',
  'EXO': 'Exodus',
  'LEV': 'Leviticus',
  'NUM': 'Numbers',
  'DEU': 'Deuteronomy',
  'JOS': 'Joshua',
  'JDG': 'Judges',
  'RUT': 'Ruth',
  '1SA': '1 Samuel',
  '2SA': '2 Samuel',
  '1KI': '1 Kings',
  '2KI': '2 Kings',
  '1CH': '1 Chronicles',
  '2CH': '2 Chronicles',
  'EZR': 'Ezra',
  'NEH': 'Nehemiah',
  'EST': 'Esther',
  'JOB': 'Job',
  'PSA': 'Psalms',
  'PRO': 'Proverbs',
  'ECC': 'Ecclesiastes',
  'SNG': 'Song of Songs',
  'ISA': 'Isaiah',
  'JER': 'Jeremiah',
  'LAM': 'Lamentations',
  'EZK': 'Ezekiel',
  'DAN': 'Daniel',
  'HOS': 'Hosea',
  'JOL': 'Joel',
  'AMO': 'Amos',
  'OBA': 'Obadiah',
  'JON': 'Jonah',
  'MIC': 'Micah',
  'NAM': 'Nahum',
  'HAB': 'Habakkuk',
  'ZEP': 'Zephaniah',
  'HAG': 'Haggai',
  'ZEC': 'Zechariah',
  'MAL': 'Malachi',
  'MAT': 'Matthew',
  'MRK': 'Mark',
  'LUK': 'Luke',
  'JHN': 'John',
  'ACT': 'Acts',
  'ROM': 'Romans',
  '1CO': '1 Corinthians',
  '2CO': '2 Corinthians',
  'GAL': 'Galatians',
  'EPH': 'Ephesians',
  'PHP': 'Philippians',
  'COL': 'Colossians',
  '1TH': '1 Thessalonians',
  '2TH': '2 Thessalonians',
  '1TI': '1 Timothy',
  '2TI': '2 Timothy',
  'TIT': 'Titus',
  'PHM': 'Philemon',
  'HEB': 'Hebrews',
  'JAS': 'James',
  '1PE': '1 Peter',
  '2PE': '2 Peter',
  '1JN': '1 John',
  '2JN': '2 John',
  '3JN': '3 John',
  'JUD': 'Jude',
  'REV': 'Revelation',
};

/// Título del artículo para la barra de ubicación.
///
/// La RV1909 del original titula los evangelios «San Juan» (home2), mientras
/// que las citas siguen usando [bookDisplayName] («Juan 3:16»). En inglés se
/// respeta el nombre del recurso (KJV → «John»).
String readerArticleTitle(
  String code, {
  String lang = 'es',
  String? resourceName,
}) {
  if (lang == 'es') {
    const gospels = <String, String>{
      'MAT': 'San Mateo',
      'MRK': 'San Marcos',
      'LUK': 'San Lucas',
      'JHN': 'San Juan',
    };
    final title = gospels[code];
    if (title != null) return title;
  }
  return resourceName ?? bookDisplayName(code, lang: lang);
}

/// "JHN.1.1" → "Juan 1:1" (`lang: 'en'` → "John 1:1").
String displayFromCanonical(String canonical, {String lang = 'es'}) {
  final m = RegExp(r'^([1-3]?[A-Z]{2,3})\.(\d+)(?:\.(\d+)(?:-(\d+))?)?$')
      .firstMatch(canonical.toUpperCase());
  if (m == null) return canonical;
  var s = '${bookDisplayName(m.group(1)!, lang: lang)} ${m.group(2)}';
  if (m.group(3) != null) {
    s += ':${m.group(3)}';
    if (m.group(4) != null) s += '-${m.group(4)}';
  }
  return s;
}

ParsedReference? parseReference(String input) {
  final raw = input.trim();
  if (raw.isEmpty) return null;
  final s = _deaccent(raw).replaceAll(RegExp(r'\s+'), ' ').trim();

  // Forma canónica: "JHN.1.1", "1CO.13.4-7".
  final canon = RegExp(r'^([1-3]?[a-z]{2,3})\.(\d+)(?:\.(\d+)(?:-(\d+))?)?$')
      .firstMatch(s);
  if (canon != null) {
    final code = canon.group(1)!.toUpperCase();
    if (_bookDisplayNames.containsKey(code)) {
      return ParsedReference(
        bookCode: code,
        chapter: int.parse(canon.group(2)!),
        verseStart: canon.group(3) != null ? int.parse(canon.group(3)!) : null,
        verseEnd: canon.group(4) != null ? int.parse(canon.group(4)!) : null,
      );
    }
  }

  // "libro cap:vers" / "libro cap" — se extrae primero el tramo numérico final.
  int? chapter;
  int? verseStart;
  int? verseEnd;
  var bookPart = s;

  final verseMatch = RegExp(r'(\d+)\s*:\s*(\d+)\s*(?:[-–]\s*(\d+))?\s*$')
      .firstMatch(s);
  if (verseMatch != null) {
    chapter = int.parse(verseMatch.group(1)!);
    verseStart = int.parse(verseMatch.group(2)!);
    verseEnd = verseMatch.group(3) != null
        ? int.parse(verseMatch.group(3)!)
        : null;
    bookPart = s.substring(0, verseMatch.start).trim();
  } else {
    final chapterMatch = RegExp(r'(\d+)\s*$').firstMatch(s);
    if (chapterMatch != null) {
      chapter = int.parse(chapterMatch.group(1)!);
      bookPart = s.substring(0, chapterMatch.start).trim();
    }
  }

  if (chapter == null) return null;
  final compressed = _compress(bookPart);
  if (compressed.isEmpty) return null;

  String? code = _aliasIndex[compressed];
  if (code == null) {
    for (final alias in _aliasesByLength) {
      if (compressed.startsWith(alias)) {
        code = _aliasIndex[alias];
        break;
      }
    }
  }
  if (code == null) return null;

  return ParsedReference(
    bookCode: code,
    chapter: chapter,
    verseStart: verseStart,
    verseEnd: verseEnd,
  );
}
