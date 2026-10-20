#!/usr/bin/env python3
"""Servicio de catálogo de Aletheia — contrato v1.

Implementado con la biblioteca estándar de Python (`http.server` + `sqlite3`
con FTS5); el contrato REST es el mismo que serviría una implementación Dart.

Uso:
  python3 catalog/server/catalog_server.py --data catalog/data --port 8787

Endpoints:
  GET /v1/health
  GET /v1/resources?query=&type=&language=&author=&sort=&page=&pageSize=
  GET /v1/resources/{id}
  GET /v1/resources/{id}/books/{CODE}
  GET /v1/resources/{id}/sections/{SECTION}
  GET /v1/resources/{id}/sections?from=&limit=   (metadatos, sin bloques)
  GET /v1/search?q=&scope=all|bible|books|factbook|devotional
      &resource=&type=&language=&book=&page=&pageSize=
  GET /v1/cross-references?ref=JHN.3.16&limit=40

Sintaxis de búsqueda: palabras y "frases", AND / OR / NOT, NEAR (10 palabras)
o NEAR/5, WITHIN n WORDS y campos `bible:"Jn 3"`, `book:JHN`, `type:factbook`,
`language:es` y `resource:bible.kjv`. Los parámetros `type`, `language` y
`book` aplican los mismos filtros desde la UI. La respuesta incluye facetas
por tipo, idioma y libro. `resource=` limita la búsqueda a un recurso
(búsqueda dentro del panel del lector) y admite el mismo `scope`.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sqlite3
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

from book_refs import parse_reference, resolve_book

OPERATORS = {"AND", "OR", "NOT"}
FIELD_NAMES = {"bible", "book", "type", "language", "resource"}
_NEAR = re.compile(r"^NEAR(?:/(\d+))?$")


class QueryError(Exception):
    """Consulta de búsqueda inválida (400)."""


# ------------------------------------------------------------------ búsqueda


def split_query_fields(query: str) -> tuple[str, dict[str, str]]:
    """Separa los campos (`bible:"Jn 3"`, `type:factbook`) del texto libre.

    Los campos se reconocen fuera de las comillas; una frase como
    `"type:amor"` sigue siendo texto. Los campos desconocidos se dejan tal cual
    para que el tokenizador los trate como una palabra.
    """
    text: list[str] = []
    fields: dict[str, str] = {}
    i = 0
    length = len(query)
    while i < length:
        ch = query[i]
        if ch == '"':
            end = query.find('"', i + 1)
            if end < 0:
                text.append(query[i:])
                break
            text.append(query[i:end + 1])
            i = end + 1
            continue
        if ch.isalpha() or ch == "_":
            end = i + 1
            while end < length and (query[end].isalnum() or query[end] in "_-"):
                end += 1
            if end < length and query[end] == ":":
                name = query[i:end].lower()
                if name in FIELD_NAMES:
                    value_start = end + 1
                    if value_start < length and query[value_start] == '"':
                        value_end = query.find('"', value_start + 1)
                        if value_end < 0:
                            raise QueryError("comilla sin cerrar en la consulta")
                        value = query[value_start + 1:value_end]
                        i = value_end + 1
                    else:
                        value_end = value_start
                        while value_end < length and not query[value_end].isspace():
                            value_end += 1
                        value = query[value_start:value_end]
                        i = value_end
                    value = value.strip()
                    if not value:
                        raise QueryError(f"el campo «{name}» está vacío")
                    fields[name] = value
                    continue
        text.append(ch)
        i += 1
    return "".join(text).strip(), fields


def tokenize_query(query: str) -> list[tuple[str, str]]:
    """Trocea la consulta en (kind, valor): word | phrase | op | num | kw | near."""
    tokens: list[tuple[str, str]] = []
    buf: list[str] = []
    in_quote = False

    def flush() -> None:
        if not buf:
            return
        word = "".join(buf)
        buf.clear()
        upper = word.upper()
        near = _NEAR.match(upper)
        if upper in OPERATORS:
            tokens.append(("op", upper))
        elif near:
            tokens.append(("near", near.group(1) or "10"))
        elif upper in ("WITHIN", "WORDS"):
            tokens.append(("kw", upper))
        elif word.isdigit():
            tokens.append(("num", word))
        else:
            tokens.append(("word", word))

    for ch in query:
        if in_quote:
            if ch == '"':
                tokens.append(("phrase", "".join(buf).strip()))
                buf.clear()
                in_quote = False
            else:
                buf.append(ch)
        elif ch == '"':
            flush()
            in_quote = True
        elif ch.isspace():
            flush()
        else:
            buf.append(ch)
    flush()
    if in_quote:
        raise QueryError('comilla sin cerrar en la consulta')
    return [t for t in tokens if not (t[0] in ("word", "phrase") and not t[1])]


def _quoted(value: str) -> str:
    return '"' + value.replace('"', '""') + '"'


def fts_expression(query: str) -> str:
    """Convierte la consulta del usuario en una expresión MATCH de FTS5."""
    tokens = tokenize_query(query)
    if not tokens:
        raise QueryError("consulta vacía")

    def term(tok: tuple[str, str]) -> str:
        kind, value = tok
        if kind not in ("word", "phrase", "num"):
            raise QueryError(f"se esperaba un término, no «{value}»")
        return _quoted(value)

    out: list[str] = []
    i = 0
    while i < len(tokens):
        kind, value = tokens[i]
        if kind == "kw" and value == "WITHIN":
            if not out:
                raise QueryError("WITHIN necesita un término delante")
            if i + 3 >= len(tokens):
                raise QueryError("WITHIN necesita «WITHIN n WORDS término»")
            num, words, right = tokens[i + 1], tokens[i + 2], tokens[i + 3]
            if num[0] != "num" or (words[0], words[1]) != ("kw", "WORDS"):
                raise QueryError("WITHIN necesita «WITHIN n WORDS término»")
            left = out.pop()
            out.append(f"NEAR({left} {term(right)}, {num[1]})")
            i += 4
            continue
        if kind == "near":
            if not out:
                raise QueryError("NEAR necesita un término delante")
            if i + 1 >= len(tokens):
                raise QueryError("NEAR necesita un término a la derecha")
            right = tokens[i + 1]
            if right[0] not in ("word", "phrase", "num"):
                raise QueryError("NEAR necesita un término a la derecha")
            left = out.pop()
            out.append(f"NEAR({left} {term(right)}, {value})")
            i += 2
            continue
        if kind == "op":
            if not out:
                raise QueryError(f"«{value}» no puede ir al principio")
            out.append(value)
        elif kind == "kw":
            raise QueryError(f"palabra clave inesperada: {value}")
        else:
            out.append(term(tokens[i]))
        i += 1

    if out and out[-1] in OPERATORS:
        raise QueryError("la consulta no puede terminar en operador")
    return " ".join(out)


# ------------------------------------------------------------------ catálogo


def read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


class Catalog:
    def __init__(self, data_dir: Path):
        self.data = data_dir
        self.index_path = data_dir / "index" / "search.sqlite"
        catalog_path = data_dir / "catalog.json"
        if not (self.index_path.exists() and catalog_path.exists()):
            raise SystemExit(
                f"ERROR: falta el catálogo construido en {data_dir}\n"
                "  ejecuta: python3 catalog/tools/build_catalog.py"
            )
        self.resources: dict[str, dict] = {}
        for entry in read_json(catalog_path)["resources"]:
            base = data_dir / entry["path"]
            manifest = read_json(base / "manifest.json")
            self.resources[manifest["id"]] = {
                "base": base,
                "manifest": manifest,
                "sections": read_json(base / "sections.json"),
            }

    # -------------------------------------------------------------- recursos

    def summary(self, m: dict) -> dict:
        return {
            "id": m["id"],
            "type": m["type"],
            "title": m["title"],
            "subtitle": m.get("subtitle"),
            "abbrev": m.get("abbrev"),
            "authors": m.get("authors", []),
            "language": m.get("language"),
            "publisher": m.get("publisher"),
            "edition": m.get("edition"),
            "license": m.get("license"),
            "description": m.get("description"),
            "tags": m.get("tags", []),
            "stats": m.get("stats", {}),
            "source": m.get("source"),
            "updatedAt": m.get("updatedAt"),
            "locked": False,
        }

    @staticmethod
    def _text_match(m: dict, query: str) -> bool:
        haystack = " ".join([
            m.get("title", ""), m.get("subtitle") or "", m.get("abbrev") or "",
            " ".join(m.get("authors", [])), " ".join(m.get("tags", [])),
            m.get("description") or "",
        ]).casefold()
        return all(word in haystack for word in query.casefold().split())

    def _filtered(self, params: dict, skip: str | None = None) -> list[dict]:
        query = (params.get("query") or [""])[0].strip()
        type_ = (params.get("type") or [None])[0]
        language = (params.get("language") or [None])[0]
        author = (params.get("author") or [None])[0]
        result = []
        for entry in self.resources.values():
            m = entry["manifest"]
            if type_ and skip != "type" and m["type"] != type_:
                continue
            if language and skip != "language" and m.get("language") != language:
                continue
            if author and skip != "author" and author not in m.get("authors", []):
                continue
            if query and not self._text_match(m, query):
                continue
            result.append(m)
        return result

    @staticmethod
    def _counts(values) -> dict[str, int]:
        counts: dict[str, int] = {}
        for value in values:
            counts[value] = counts.get(value, 0) + 1
        return dict(sorted(counts.items(), key=lambda kv: (-kv[1], kv[0].casefold())))

    def list_resources(self, params: dict) -> dict:
        page = max(int((params.get("page") or ["1"])[0]), 1)
        page_size = min(max(int((params.get("pageSize") or ["50"])[0]), 1), 200)
        sort = (params.get("sort") or ["title"])[0]

        items = self._filtered(params)
        if sort == "author":
            items.sort(key=lambda m: ((m.get("authors") or [""])[0].casefold(), m["title"].casefold()))
        elif sort == "updated":
            items.sort(key=lambda m: m.get("updatedAt") or "", reverse=True)
        else:
            items.sort(key=lambda m: m["title"].casefold())

        facets = {
            "type": self._counts(m["type"] for m in self._filtered(params, skip="type")),
            "language": self._counts(
                m.get("language") or "—" for m in self._filtered(params, skip="language")
            ),
            "author": self._counts(
                a for m in self._filtered(params, skip="author")
                for a in m.get("authors", [])
            ),
        }
        offset = (page - 1) * page_size
        return {
            "total": len(items),
            "page": page,
            "pageSize": page_size,
            "items": [self.summary(m) for m in items[offset:offset + page_size]],
            "facets": facets,
        }

    # -------------------------------------------------------------- búsqueda

    def search(self, params: dict) -> dict:
        query = (params.get("q") or [""])[0].strip()
        text_query, fields = split_query_fields(query)
        expression = fts_expression(text_query) if text_query else None
        scope = (params.get("scope") or ["all"])[0] or "all"
        resource = (params.get("resource") or [None])[0]
        page = max(int((params.get("page") or ["1"])[0]), 1)
        page_size = min(max(int((params.get("pageSize") or ["20"])[0]), 1), 100)

        type_filter = (params.get("type") or [None])[0] or fields.get("type")
        language_filter = (params.get("language") or [None])[0] or fields.get(
            "language"
        )
        book_filter = (params.get("book") or [None])[0] or fields.get("book")

        if not text_query and not fields and not any(
            (scope != "all", resource, type_filter, language_filter, book_filter)
        ):
            raise QueryError("consulta vacía")

        scope_sql = {
            "all": "",
            "bible": "r.type = 'bible'",
            "books": "r.type != 'bible'",
            "factbook": "r.type = 'factbook'",
            "devotional": "r.type = 'devotional'",
        }.get(scope)
        if scope_sql is None:
            raise QueryError(f"scope no soportado: {scope}")

        conditions: list[tuple[str, str, tuple]] = []

        def add(name: str, sql: str, values: tuple = ()) -> None:
            conditions.append((name, sql, values))

        if expression is not None:
            add("match", "verses MATCH ?", (expression,))
        if scope_sql:
            add("scope", scope_sql)
        if resource:
            if resource not in self.resources:
                raise KeyError(resource)
            add("resource", "verses.resource_id = ?", (resource,))
        field_resource = fields.get("resource")
        if field_resource:
            if field_resource not in self.resources:
                raise KeyError(field_resource)
            add("resource_field", "verses.resource_id = ?", (field_resource,))
        if type_filter:
            add("type", "r.type = ?", (type_filter,))
        if language_filter:
            add("language", "r.language = ?", (language_filter,))

        field_book = fields.get("book")
        if field_book:
            code = resolve_book(field_book)
            if code is None:
                parsed = parse_reference(field_book)
                code = parsed[0] if parsed else None
            if code is None:
                raise QueryError(f"libro no encontrado: {field_book}")
            add("book", "verses.book = ?", (code,))
        if book_filter:
            code = resolve_book(book_filter)
            if code is None:
                parsed = parse_reference(book_filter)
                code = parsed[0] if parsed else None
            if code is None:
                raise QueryError(f"libro no encontrado: {book_filter}")
            add("book_param", "verses.book = ?", (code,))

        bible = fields.get("bible")
        if bible:
            parsed = parse_reference(bible)
            if parsed is None:
                raise QueryError(f"referencia bíblica no válida: {bible}")
            code, chapter, verse_start, verse_end = parsed
            parts = ["r.type = 'bible'", "verses.book = ?"]
            values: list = [code]
            if chapter is not None:
                parts.append("verses.chapter = ?")
                values.append(chapter)
            if verse_start is not None:
                parts.append("verses.verse >= ?")
                values.append(verse_start)
            if verse_end is not None:
                parts.append("verses.verse <= ?")
                values.append(verse_end)
            add("bible", " AND ".join(parts), tuple(values))

        def where(skip: set[str] | None = None, extra: str = "") -> tuple[str, tuple]:
            skip = skip or set()
            parts = [sql for name, sql, _ in conditions if name not in skip]
            if extra:
                parts.append(extra)
            values = tuple(
                value
                for name, _, vals in conditions
                if name not in skip
                for value in vals
            )
            return (" WHERE " + " AND ".join(parts) if parts else ""), values

        base = "FROM verses JOIN resources r ON r.id = verses.resource_id"
        con = self.connect()
        try:
            where_sql, where_values = where()
            total = con.execute(
                "SELECT COUNT(*) " + base + where_sql, where_values
            ).fetchone()[0]

            if expression is not None:
                snippet_sql = "snippet(verses, 6, '<em>', '</em>', '…', 14)"
                order_sql = "ORDER BY bm25(verses)"
            else:
                snippet_sql = "substr(verses.text, 1, 200)"
                order_sql = "ORDER BY r.title, verses.section_id"
            rows = con.execute(
                "SELECT verses.resource_id AS resource_id, verses.section_id AS section_id, "
                "verses.book AS book, verses.book_name AS book_name, "
                "verses.chapter AS chapter, verses.verse AS verse, "
                f"{snippet_sql} AS snippet, r.title AS resource_title, "
                "r.abbrev AS abbrev, r.type AS resource_type "
                + base + where_sql + f" {order_sql} LIMIT ? OFFSET ?",
                (*where_values, page_size, (page - 1) * page_size),
            ).fetchall()

            facets: dict[str, dict[str, int]] = {}
            facet_specs = (
                ("type", "r.type", {"type"}, ""),
                ("language", "COALESCE(NULLIF(r.language, ''), '—')", {"language"}, ""),
                ("book", "verses.book", {"book", "book_param"}, "verses.book != ''"),
            )
            for key, column, skip, extra in facet_specs:
                facet_where, facet_values = where(skip, extra)
                facet_rows = con.execute(
                    f"SELECT {column} AS k, COUNT(*) AS n "
                    + base + facet_where + " GROUP BY k ORDER BY n DESC, k",
                    facet_values,
                ).fetchall()
                facets[key] = {row["k"]: row["n"] for row in facet_rows if row["k"]}
        finally:
            con.close()

        hits = []
        for row in rows:
            if row["book"]:
                ref = f"{row['book']}.{row['chapter']}.{row['verse']}"
                citation = f"{row['book_name']} {row['chapter']}:{row['verse']}"
            else:
                ref = row["section_id"]
                citation = row["book_name"]
            hits.append({
                "resourceId": row["resource_id"],
                "resourceTitle": row["resource_title"],
                "resourceType": row["resource_type"],
                "abbrev": row["abbrev"],
                "sectionId": row["section_id"],
                "book": row["book"],
                "bookName": row["book_name"],
                "chapter": row["chapter"],
                "verse": row["verse"],
                "ref": ref,
                "citation": citation,
                "snippet": row["snippet"],
                "locked": False,
            })
        return {
            "query": query,
            "expression": expression,
            "scope": scope,
            "resource": resource,
            "filters": {
                "type": type_filter,
                "language": language_filter,
                "book": book_filter,
                "bible": bible,
            },
            "facets": facets,
            "total": total,
            "page": page,
            "pageSize": page_size,
            "hits": hits,
        }

    # ---------------------------------------------------------------- índice

    def connect(self) -> sqlite3.Connection:
        con = sqlite3.connect(f"file:{self.index_path}?mode=ro", uri=True)
        con.row_factory = sqlite3.Row
        return con

    def cross_references(self, params: dict) -> dict:
        """Referencias cruzadas del TSK para un versículo o capítulo."""
        raw = (params.get("ref") or [""])[0]
        parsed = parse_reference(raw)
        if parsed is None or parsed[1] is None:
            raise QueryError("referencia no válida")
        book, chapter, verse_start, _verse_end = parsed
        limit = min(max(int((params.get("limit") or ["40"])[0]), 1), 200)
        con = self.connect()
        try:
            if verse_start is None:
                rows = con.execute(
                    "SELECT target_ref FROM cross_references "
                    "WHERE source_ref LIKE ? ORDER BY source_ref, rank",
                    (f"{book}.{chapter}.%",),
                ).fetchall()
                reference = f"{book}.{chapter}"
            else:
                rows = con.execute(
                    "SELECT target_ref FROM cross_references "
                    "WHERE source_ref = ? ORDER BY rank",
                    (f"{book}.{chapter}.{verse_start}",),
                ).fetchall()
                reference = f"{book}.{chapter}.{verse_start}"
        finally:
            con.close()
        items = []
        seen = set()
        for row in rows:
            target = row[0]
            if target in seen:
                continue
            seen.add(target)
            if len(items) < limit:
                items.append({"ref": target})
        return {
            "reference": reference,
            "source": "Treasury of Scripture Knowledge",
            "license": "Public Domain",
            "total": len(seen),
            "items": items,
        }

    def health(self) -> dict:
        con = self.connect()
        try:
            verses = con.execute(
                "SELECT COUNT(*) FROM verses WHERE book != ''"
            ).fetchone()[0]
            sections = con.execute(
                "SELECT COUNT(*) FROM verses WHERE book = ''"
            ).fetchone()[0]
            cross_references = con.execute(
                "SELECT COUNT(*) FROM cross_references"
            ).fetchone()[0]
        finally:
            con.close()
        return {
            "status": "ok",
            "service": "aletheia-catalog",
            "version": "1.0-m7",
            "resources": len(self.resources),
            "verses": verses,
            "sections": sections,
            "crossReferences": cross_references,
        }


# -------------------------------------------------------------------- HTTP


class Handler(BaseHTTPRequestHandler):
    server_version = "AletheiaCatalog/1.0"
    protocol_version = "HTTP/1.1"
    catalog: Catalog

    # Silencia el log por petición salvo errores.
    def log_message(self, fmt: str, *args) -> None:  # noqa: A003
        if args and str(args[1]).startswith(("4", "5")):
            print(f"[{self.address_string()}] {fmt % args}", flush=True)

    def do_GET(self) -> None:  # noqa: N802
        try:
            self._route()
        except QueryError as exc:
            self._json(400, {"error": str(exc)})
        except KeyError as exc:
            self._json(404, {"error": f"no encontrado: {exc}"})
        except sqlite3.OperationalError as exc:
            self._json(400, {"error": f"consulta no válida: {exc}"})
        except (BrokenPipeError, ConnectionResetError):
            pass
        except Exception as exc:  # pragma: no cover - red de seguridad del servicio local
            self._json(500, {"error": f"error interno: {exc}"})

    def _route(self) -> None:
        parsed = urlparse(self.path)
        parts = [p for p in parsed.path.split("/") if p]
        params = parse_qs(parsed.query)

        if parts == ["v1", "health"]:
            return self._json(200, self.catalog.health())
        if parts == ["v1", "search"]:
            return self._json(200, self.catalog.search(params))
        if parts == ["v1", "cross-references"]:
            return self._json(200, self.catalog.cross_references(params))
        if parts[:2] == ["v1", "resources"]:
            if len(parts) == 2:
                return self._json(200, self.catalog.list_resources(params))
            resource_id = parts[2]
            if resource_id not in self.catalog.resources:
                raise KeyError(resource_id)
            entry = self.catalog.resources[resource_id]
            if len(parts) == 3:
                return self._send_file(entry["base"] / "manifest.json")
            if len(parts) == 5 and parts[3] == "books":
                return self._send_file(entry["base"] / "books" / f"{parts[4]}.json")
            if len(parts) == 5 and parts[3] == "sections":
                # Recursos con secciones en archivo propio (Biblia) y recursos
                # pequeños con las secciones embebidas en `sections.json`
                # (devocional y Factbook, M5).
                section_id = parts[4]
                section_file = entry["base"] / "sections" / f"{section_id}.json"
                if section_file.exists():
                    return self._send_file(section_file)
                for section in entry["sections"]:
                    if section["id"] == section_id:
                        return self._json(200, section)
                raise KeyError(section_id)
            if len(parts) == 4 and parts[3] == "sections":
                return self._json(200, self._section_stream(entry, params))
        self._json(404, {"error": f"ruta desconocida: {parsed.path}"})

    @staticmethod
    def _section_stream(entry: dict, params: dict) -> dict:
        start = max(int((params.get("from") or ["0"])[0]), 0)
        limit = min(max(int((params.get("limit") or ["50"])[0]), 1), 200)
        sections = entry["sections"]
        chunk = sections[start:start + limit]
        # El stream devuelve metadatos (sin bloques): el contenido se pide con
        # `/sections/{id}`. Sirve para índices grandes como el devocional.
        items = [{k: v for k, v in section.items() if k != "blocks"} for section in chunk]
        return {"total": len(sections), "from": start, "items": items}

    def _send_file(self, path: Path) -> None:
        data = path.read_bytes()
        etag = '"' + hashlib.md5(data).hexdigest() + '"'
        if self.headers.get("If-None-Match") == etag:
            self.send_response(304)
            self.send_header("ETag", etag)
            self.send_header("Content-Length", "0")
            self.end_headers()
            return
        self._json(200, json.loads(data.decode("utf-8")), etag=etag)

    def _json(self, status: int, payload, etag: str | None = None) -> None:
        body = json.dumps(payload, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        if etag:
            self.send_header("ETag", etag)
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(body)


class Server(ThreadingHTTPServer):
    daemon_threads = True


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--data", default="catalog/data")
    ap.add_argument("--host", default="127.0.0.1")
    ap.add_argument("--port", type=int, default=8787)
    args = ap.parse_args()

    data_dir = Path(args.data)
    if not data_dir.is_absolute():
        data_dir = Path(__file__).resolve().parents[2] / data_dir

    Handler.catalog = Catalog(data_dir)
    health = Handler.catalog.health()
    try:
        server = Server((args.host, args.port), Handler)
    except OSError as exc:
        raise SystemExit(f"ERROR: no se pudo abrir {args.host}:{args.port} — {exc}")

    print(
        f"catálogo en http://{args.host}:{server.server_address[1]} "
        f"({health['resources']} recursos, {health['verses']} versículos indexados)",
        flush=True,
    )
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\ncatálogo detenido", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
