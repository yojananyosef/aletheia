/// Índice FTS5 incluido en la app para buscar sin servicio.
///
/// El índice se genera con `catalog/tools/build_catalog.py` y se empaqueta
/// comprimido (`assets/catalog/search.sqlite.gz`) junto con un manifiesto
/// (`search.meta.json`) que identifica su contenido por hash. En el primer
/// uso se extrae al directorio de datos de la app y se abre en modo lectura.
///
/// El esquema es el mismo que usa el servicio (`resources`, `sections` y la
/// tabla virtual `verses`), de modo que la consulta y la forma de los
/// resultados son idénticas en ambos modos.
library;

import 'dart:math' show max, min;

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:sqlite3/common.dart';

import '../references/reference_parser.dart'
    show bookCodeForInput, parseReference;
import 'catalog_client.dart';
import 'catalog_models.dart';
import 'local_search_platform.dart';
import 'local_search_query.dart';

const kLocalSearchUnavailableMessage =
    'No se pudo abrir el índice de búsqueda incluido en la app.';

/// El índice local no existe, está corrupto o no se pudo extraer.
class LocalSearchUnavailableException extends CatalogException {
  LocalSearchUnavailableException([this.cause])
    : super(kLocalSearchUnavailableMessage);

  final Object? cause;
}

class LocalCatalogIndex {
  LocalCatalogIndex({AssetBundle? bundle, this.cacheDirectoryProvider})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  /// Directorio de caché en plataformas nativas; `null` usa el directorio de
  /// datos de la app. En web se ignora (el índice vive en memoria).
  /// Inyectable en pruebas para no depender de los canales de plataforma.
  final Future<String> Function()? cacheDirectoryProvider;

  Future<CommonDatabase>? _opening;
  CommonDatabase? _database;

  Future<CommonDatabase> _db() => _opening ??= _open();

  Future<CommonDatabase> _open() async {
    try {
      final db = await openLocalSearchDatabase(
        bundle: _bundle,
        cacheDirectoryProvider: cacheDirectoryProvider,
      );
      db.execute('PRAGMA query_only = ON');
      // El VFS web es de solo lectura y no admite archivos temporales.
      db.execute('PRAGMA temp_store = MEMORY');
      // Comprueba que el archivo es el índice esperado (y que este SQLite
      // incluye FTS5) antes de exponerlo.
      db.select('SELECT COUNT(*) FROM verses').first;
      _database = db;
      return db;
    } on LocalSearchUnavailableException {
      rethrow;
    } catch (error) {
      throw LocalSearchUnavailableException(error);
    }
  }

  /// Número de versículos bíblicos indexados (para el estado de Ajustes).
  Future<int> verseCount() async {
    final db = await _db();
    return db
            .select("SELECT COUNT(*) AS n FROM verses WHERE book != ''")
            .first['n']
        as int;
  }

  /// Número de entradas no bíblicas (recursos de sección).
  Future<int> sectionCount() async {
    final db = await _db();
    return db
            .select("SELECT COUNT(*) AS n FROM verses WHERE book = ''")
            .first['n']
        as int;
  }

  /// Número de enlaces de referencias cruzadas del índice.
  Future<int> crossReferenceCount() async {
    final db = await _db();
    return db.select('SELECT COUNT(*) AS n FROM cross_references').first['n']
        as int;
  }

  /// Referencias cruzadas del TSK para un versículo (o para un capítulo).
  Future<List<CrossReference>> crossReferences(
    String reference, {
    int limit = 40,
  }) async {
    final parsed = parseReference(reference);
    if (parsed == null) return const [];
    final safeLimit = min(max(limit, 1), 200);
    final db = await _db();
    final chapter = '${parsed.bookCode}.${parsed.chapter}';
    final rows = parsed.verseStart == null
        ? db.select(
            'SELECT target_ref FROM cross_references '
            'WHERE source_ref LIKE ? ORDER BY source_ref, rank LIMIT ?',
            ['$chapter.%', safeLimit * 4],
          )
        : db.select(
            'SELECT target_ref FROM cross_references '
            'WHERE source_ref = ? ORDER BY rank LIMIT ?',
            ['$chapter.${parsed.verseStart}', safeLimit],
          );
    final seen = <String>{};
    final result = <CrossReference>[];
    for (final row in rows) {
      final target = row['target_ref'] as String? ?? '';
      if (target.isEmpty || !seen.add(target)) continue;
      result.add(CrossReference(reference: target));
      if (result.length >= safeLimit) break;
    }
    return result;
  }

  /// Búsqueda con el mismo contrato y sintaxis que `GET /v1/search`.
  Future<SearchResult> search({
    required String query,
    String scope = 'all',
    String? resource,
    String? type,
    String? language,
    String? book,
    int page = 1,
    int pageSize = 20,
  }) async {
    final hasParamFilters =
        scope != 'all' ||
        (type != null && type.isNotEmpty) ||
        (language != null && language.isNotEmpty) ||
        (book != null && book.isNotEmpty) ||
        (resource != null && resource.isNotEmpty);
    final parsed = parseLocalSearchQuery(query, allowEmpty: hasParamFilters);
    final expression = parsed.expression;
    final scopeSql = switch (scope) {
      'all' => '',
      'bible' => "r.type = 'bible'",
      'books' => "r.type != 'bible'",
      'factbook' => "r.type = 'factbook'",
      'devotional' => "r.type = 'devotional'",
      _ => throw CatalogException('scope no soportado: $scope'),
    };
    final safePage = max(page, 1);
    final safePageSize = min(max(pageSize, 1), 100);
    final db = await _db();

    final conditions = <_SearchCondition>[];
    if (expression != null) {
      conditions.add(_SearchCondition('match', 'verses MATCH ?', [expression]));
    }
    if (scopeSql.isNotEmpty) {
      conditions.add(_SearchCondition('scope', scopeSql, const []));
    }

    void addResource(String name, String value) {
      final exists = db.select('SELECT 1 FROM resources WHERE id = ? LIMIT 1', [
        value,
      ]);
      if (exists.isEmpty) {
        throw CatalogException('no encontrado: $value', status: 404);
      }
      conditions.add(_SearchCondition(name, 'verses.resource_id = ?', [value]));
    }

    if (resource != null && resource.isNotEmpty) {
      addResource('resource', resource);
    }
    if (parsed.resource != null && parsed.resource!.isNotEmpty) {
      addResource('resource_field', parsed.resource!);
    }

    final typeFilter = (type != null && type.isNotEmpty) ? type : parsed.type;
    if (typeFilter != null && typeFilter.isNotEmpty) {
      conditions.add(_SearchCondition('type', 'r.type = ?', [typeFilter]));
    }
    final languageFilter = (language != null && language.isNotEmpty)
        ? language
        : parsed.language;
    if (languageFilter != null && languageFilter.isNotEmpty) {
      conditions.add(
        _SearchCondition('language', 'r.language = ?', [languageFilter]),
      );
    }

    String? bookParam;
    if (book != null && book.isNotEmpty) {
      bookParam = bookCodeForInput(book);
      if (bookParam == null) {
        throw CatalogException('libro no encontrado: $book');
      }
    }
    if (parsed.book != null && parsed.book!.isNotEmpty) {
      conditions.add(
        _SearchCondition('book', 'verses.book = ?', [parsed.book]),
      );
    }
    if (bookParam != null && bookParam != parsed.book) {
      conditions.add(
        _SearchCondition('book_param', 'verses.book = ?', [bookParam]),
      );
    }

    final bible = parsed.bible;
    if (bible != null) {
      final parts = ["r.type = 'bible'", 'verses.book = ?'];
      final values = <Object?>[bible.bookCode];
      if (bible.chapter != null) {
        parts.add('verses.chapter = ?');
        values.add(bible.chapter);
      }
      if (bible.verseStart != null) {
        parts.add('verses.verse >= ?');
        values.add(bible.verseStart);
      }
      if (bible.verseEnd != null) {
        parts.add('verses.verse <= ?');
        values.add(bible.verseEnd);
      }
      conditions.add(_SearchCondition('bible', parts.join(' AND '), values));
    }

    if (conditions.isEmpty) {
      throw CatalogException('consulta vacía');
    }

    String whereSql(Set<String> skip, {String extra = ''}) {
      final parts = [
        for (final condition in conditions)
          if (!skip.contains(condition.name)) condition.sql,
        if (extra.isNotEmpty) extra,
      ];
      return parts.isEmpty ? '' : ' WHERE ${parts.join(' AND ')}';
    }

    List<Object?> whereValues(Set<String> skip) => [
      for (final condition in conditions)
        if (!skip.contains(condition.name)) ...condition.values,
    ];

    final from = 'FROM verses JOIN resources r ON r.id = verses.resource_id';
    final total =
        db
                .select(
                  'SELECT COUNT(*) AS n $from${whereSql(const {})}',
                  whereValues(const {}),
                )
                .first['n']
            as int;

    final snippetSql = expression != null
        ? "snippet(verses, 6, '<em>', '</em>', '…', 14)"
        : 'substr(verses.text, 1, 200)';
    final orderSql = expression != null
        ? 'ORDER BY bm25(verses)'
        : 'ORDER BY r.title, verses.section_id';
    final offset = (safePage - 1) * safePageSize;
    final rows = db.select(
      'SELECT verses.resource_id AS resource_id, '
      'verses.section_id AS section_id, verses.book AS book, '
      'verses.book_name AS book_name, verses.chapter AS chapter, '
      'verses.verse AS verse, $snippetSql AS snippet, '
      'r.title AS resource_title, r.abbrev AS abbrev, '
      'r.type AS resource_type '
      '$from${whereSql(const {})} $orderSql LIMIT ? OFFSET ?',
      [...whereValues(const {}), safePageSize, offset],
    );

    final hits = <SearchHit>[];
    for (final row in rows) {
      final book = row['book'] as String;
      final chapter = row['chapter'] as int;
      final verse = row['verse'] as int;
      final bookName = row['book_name'] as String;
      final sectionId = row['section_id'] as String;
      final isBible = book.isNotEmpty;
      hits.add(
        SearchHit(
          resourceId: row['resource_id'] as String,
          resourceTitle: row['resource_title'] as String,
          resourceType: row['resource_type'] as String? ?? 'bible',
          abbrev: row['abbrev'] as String?,
          sectionId: sectionId,
          book: book,
          bookName: bookName,
          chapter: chapter,
          verse: verse,
          ref: isBible ? '$book.$chapter.$verse' : sectionId,
          citation: isBible ? '$bookName $chapter:$verse' : bookName,
          snippet: (row['snippet'] as String?) ?? '',
        ),
      );
    }

    final facets = <String, Map<String, int>>{};
    final facetSpecs = <(String, String, Set<String>, String)>[
      ('type', 'r.type', {'type'}, ''),
      ('language', "COALESCE(NULLIF(r.language, ''), '—')", {'language'}, ''),
      ('book', 'verses.book', {'book', 'book_param'}, "verses.book != ''"),
    ];
    for (final (key, column, skip, extra) in facetSpecs) {
      final facetRows = db.select(
        'SELECT $column AS k, COUNT(*) AS n $from'
        '${whereSql(skip, extra: extra)} GROUP BY k ORDER BY n DESC, k',
        whereValues(skip),
      );
      facets[key] = {
        for (final row in facetRows)
          if ((row['k'] as String?)?.isNotEmpty ?? false)
            row['k'] as String: row['n'] as int,
      };
    }

    return SearchResult(
      query: query,
      scope: scope,
      total: total,
      page: safePage,
      pageSize: safePageSize,
      hits: hits,
      facets: facets,
    );
  }

  void close() {
    final db = _database;
    _database = null;
    _opening = null;
    db?.close();
  }
}

class _SearchCondition {
  const _SearchCondition(this.name, this.sql, this.values);

  final String name;
  final String sql;
  final List<Object?> values;
}
