/// Traducción de la consulta de búsqueda del usuario a una expresión MATCH
/// de FTS5.
///
/// Es un port fiel del tokenizador del servicio (`catalog/server/catalog_server.py`,
/// `tokenize_query` + `fts_expression`) para que el modo local y el remoto
/// acepten exactamente la misma sintaxis:
///
/// - palabras sueltas (AND implícito) y `"frases"`;
/// - `AND`, `OR`, `NOT`;
/// - `NEAR` (distancia 10) y `NEAR/5` (distancia explícita);
/// - `WITHIN n WORDS` (se convierte en `NEAR(..., n)`);
/// - campos `bible:"Jn 3"`, `book:JHN`, `type:factbook`, `language:es` y
///   `resource:bible.kjv`.
///
/// Cualquier consulta inválida lanza [CatalogException] con el mismo mensaje
/// que devolvería el servicio.
library;

import '../references/reference_parser.dart';
import 'catalog_client.dart';

const _operators = {'AND', 'OR', 'NOT'};
const _keywords = {'WITHIN', 'WORDS'};
const _fieldNames = {'bible', 'book', 'type', 'language', 'resource'};

enum _TokenKind { word, phrase, op, num, kw, near }

class _Token {
  const _Token(this.kind, this.value);

  final _TokenKind kind;
  final String value;
}

/// Filtro de pasaje bíblico de `bible:"Jn 3:16"`.
class LocalBibleFilter {
  const LocalBibleFilter({
    required this.bookCode,
    this.chapter,
    this.verseStart,
    this.verseEnd,
  });

  final String bookCode;
  final int? chapter;
  final int? verseStart;
  final int? verseEnd;
}

/// Consulta local ya separada en texto FTS y filtros de estudio.
class LocalSearchQuery {
  const LocalSearchQuery({
    required this.text,
    required this.expression,
    this.bible,
    this.book,
    this.type,
    this.language,
    this.resource,
  });

  final String text;

  /// Expresión MATCH; `null` cuando la consulta solo tiene filtros.
  final String? expression;

  final LocalBibleFilter? bible;
  final String? book;
  final String? type;
  final String? language;
  final String? resource;

  bool get hasFilters =>
      bible != null ||
      book != null ||
      type != null ||
      language != null ||
      resource != null;
}

List<_Token> _tokenize(String query) {
  final tokens = <_Token>[];
  final buffer = StringBuffer();
  var inQuote = false;

  void flush() {
    if (buffer.isEmpty) return;
    final word = buffer.toString();
    buffer.clear();
    final upper = word.toUpperCase();
    final near = RegExp(r'^NEAR(?:/([0-9]+))?$').firstMatch(upper);
    final kind = _operators.contains(upper)
        ? _TokenKind.op
        : near != null
        ? _TokenKind.near
        : _keywords.contains(upper)
        ? _TokenKind.kw
        : RegExp(r'^[0-9]+$').hasMatch(word)
        ? _TokenKind.num
        : _TokenKind.word;
    tokens.add(
      _Token(
        kind,
        kind == _TokenKind.op || kind == _TokenKind.kw
            ? upper
            : kind == _TokenKind.near
            ? (near!.group(1) ?? '10')
            : word,
      ),
    );
  }

  for (final code in query.runes) {
    final ch = String.fromCharCode(code);
    if (inQuote) {
      if (ch == '"') {
        final phrase = buffer.toString().trim();
        buffer.clear();
        inQuote = false;
        if (phrase.isNotEmpty) tokens.add(_Token(_TokenKind.phrase, phrase));
      } else {
        buffer.write(ch);
      }
    } else if (ch == '"') {
      flush();
      inQuote = true;
    } else if (RegExp(r'\s').hasMatch(ch)) {
      flush();
    } else {
      buffer.write(ch);
    }
  }
  flush();
  if (inQuote) {
    throw CatalogException('comilla sin cerrar en la consulta');
  }
  return tokens;
}

String _quoted(String value) => '"${value.replaceAll('"', '""')}"';

String _term(_Token token) {
  if (token.kind != _TokenKind.word &&
      token.kind != _TokenKind.phrase &&
      token.kind != _TokenKind.num) {
    throw CatalogException('se esperaba un término, no «${token.value}»');
  }
  return _quoted(token.value);
}

String _buildExpression(List<_Token> tokens) {
  if (tokens.isEmpty) {
    throw CatalogException('consulta vacía');
  }

  final out = <String>[];
  var i = 0;
  while (i < tokens.length) {
    final token = tokens[i];
    if (token.kind == _TokenKind.kw && token.value == 'WITHIN') {
      if (out.isEmpty) {
        throw CatalogException('WITHIN necesita un término delante');
      }
      if (i + 3 >= tokens.length) {
        throw CatalogException('WITHIN necesita «WITHIN n WORDS término»');
      }
      final number = tokens[i + 1];
      final words = tokens[i + 2];
      final right = tokens[i + 3];
      if (number.kind != _TokenKind.num ||
          words.kind != _TokenKind.kw ||
          words.value != 'WORDS') {
        throw CatalogException('WITHIN necesita «WITHIN n WORDS término»');
      }
      final left = out.removeLast();
      out.add('NEAR($left ${_term(right)}, ${number.value})');
      i += 4;
      continue;
    }

    if (token.kind == _TokenKind.near) {
      if (out.isEmpty) {
        throw CatalogException('NEAR necesita un término delante');
      }
      if (i + 1 >= tokens.length) {
        throw CatalogException('NEAR necesita un término a la derecha');
      }
      final right = tokens[i + 1];
      if (right.kind != _TokenKind.word &&
          right.kind != _TokenKind.phrase &&
          right.kind != _TokenKind.num) {
        throw CatalogException('NEAR necesita un término a la derecha');
      }
      final left = out.removeLast();
      out.add('NEAR($left ${_term(right)}, ${token.value})');
      i += 2;
      continue;
    }

    if (token.kind == _TokenKind.op) {
      if (out.isEmpty) {
        throw CatalogException('«${token.value}» no puede ir al principio');
      }
      out.add(token.value);
    } else if (token.kind == _TokenKind.kw) {
      throw CatalogException('palabra clave inesperada: ${token.value}');
    } else {
      out.add(_term(token));
    }
    i++;
  }

  if (out.isNotEmpty && _operators.contains(out.last)) {
    throw CatalogException('la consulta no puede terminar en operador');
  }
  return out.join(' ');
}

/// Convierte la consulta del usuario en una expresión MATCH de FTS5.
String buildLocalFtsExpression(String query) =>
    _buildExpression(_tokenize(query));

bool _isFieldStart(String ch) => RegExp(r'[A-Za-z_]').hasMatch(ch);

bool _isFieldPart(String ch) => RegExp(r'[A-Za-z0-9_-]').hasMatch(ch);

/// Separa los campos de la consulta fuera de las comillas.
(String, Map<String, String>) _extractFields(String query) {
  final text = StringBuffer();
  final fields = <String, String>{};
  var i = 0;
  while (i < query.length) {
    final ch = query[i];
    if (ch == '"') {
      final end = query.indexOf('"', i + 1);
      if (end < 0) {
        text.write(query.substring(i));
        break;
      }
      text.write(query.substring(i, end + 1));
      i = end + 1;
      continue;
    }
    if (_isFieldStart(ch)) {
      var end = i + 1;
      while (end < query.length && _isFieldPart(query[end])) {
        end++;
      }
      if (end < query.length && query[end] == ':') {
        final name = query.substring(i, end).toLowerCase();
        if (_fieldNames.contains(name)) {
          var valueStart = end + 1;
          String value;
          if (valueStart < query.length && query[valueStart] == '"') {
            final valueEnd = query.indexOf('"', valueStart + 1);
            if (valueEnd < 0) {
              throw CatalogException('comilla sin cerrar en la consulta');
            }
            value = query.substring(valueStart + 1, valueEnd);
            i = valueEnd + 1;
          } else {
            var valueEnd = valueStart;
            while (valueEnd < query.length &&
                !RegExp(r'\s').hasMatch(query[valueEnd])) {
              valueEnd++;
            }
            value = query.substring(valueStart, valueEnd);
            i = valueEnd;
          }
          value = value.trim();
          if (value.isEmpty) {
            throw CatalogException('el campo «$name» está vacío');
          }
          fields[name] = value;
          continue;
        }
      }
    }
    text.write(ch);
    i++;
  }
  return (text.toString().trim(), fields);
}

String? _bookCode(String value) {
  final direct = bookCodeForInput(value);
  if (direct != null) return direct;
  return parseReference(value)?.bookCode;
}

/// Parsea texto y campos de una consulta de estudio.
///
/// [allowEmpty] permite que el llamador aplique filtros de la URL sin texto
/// (`type=factbook`); si no hay ni texto ni filtros y es `false`, se lanza
/// `consulta vacía`.
LocalSearchQuery parseLocalSearchQuery(
  String query, {
  bool allowEmpty = false,
}) {
  final (text, fields) = _extractFields(query);
  final tokens = _tokenize(text);
  if (tokens.isEmpty && fields.isEmpty && !allowEmpty) {
    throw CatalogException('consulta vacía');
  }

  LocalBibleFilter? bible;
  final bibleValue = fields['bible'];
  if (bibleValue != null) {
    final ref = parseReference(bibleValue);
    if (ref != null) {
      bible = LocalBibleFilter(
        bookCode: ref.bookCode,
        chapter: ref.chapter,
        verseStart: ref.verseStart,
        verseEnd: ref.verseEnd,
      );
    } else {
      final code = bookCodeForInput(bibleValue);
      if (code == null) {
        throw CatalogException('referencia bíblica no válida: $bibleValue');
      }
      bible = LocalBibleFilter(bookCode: code);
    }
  }

  String? book;
  final bookValue = fields['book'];
  if (bookValue != null) {
    book = _bookCode(bookValue);
    if (book == null) {
      throw CatalogException('libro no encontrado: $bookValue');
    }
  }

  return LocalSearchQuery(
    text: text,
    expression: tokens.isEmpty ? null : _buildExpression(tokens),
    bible: bible,
    book: book,
    type: fields['type'],
    language: fields['language'],
    resource: fields['resource'],
  );
}
