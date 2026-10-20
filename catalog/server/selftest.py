#!/usr/bin/env python3
"""Autoprueba del servicio de catálogo (sin dependencias externas).

Uso:
  python3 catalog/server/selftest.py [--data catalog/data]

Levanta el servidor en un puerto efímero y comprueba endpoints, ETag,
paginación, facets, diacríticos y sintaxis de búsqueda.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import threading
import urllib.error
import urllib.request
from pathlib import Path
from urllib.parse import quote

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))

from catalog_server import Catalog, Handler, Server  # noqa: E402

CHECKS: list[tuple[str, bool, str]] = []


def check(name: str, condition: bool, detail: str = "") -> None:
    CHECKS.append((name, bool(condition), detail))


class Client:
    def __init__(self, base: str):
        self.base = base

    def get(self, path: str, headers: dict | None = None):
        request = urllib.request.Request(self.base + path, headers=headers or {})
        try:
            with urllib.request.urlopen(request, timeout=15) as response:
                body = response.read()
                return response.status, (json.loads(body) if body else None), dict(response.headers)
        except urllib.error.HTTPError as error:
            body = error.read()
            return error.code, (json.loads(body) if body else None), dict(error.headers)


def run(client: Client, catalog: Catalog) -> None:
    ids = sorted(catalog.resources)
    summary = catalog.summary(catalog.resources["bible.rv1909"]["manifest"])

    status, health, _ = client.get("/v1/health")
    check("health 200/ok", status == 200 and health["status"] == "ok", str(health))
    check("health recuento de recursos", health["resources"] == len(ids), str(health))
    check(
        "health separa versículos y secciones",
        health.get("verses", 0) > 120000 and health.get("sections", 0) >= 5000,
        str(health),
    )
    check(
        "health informa de las referencias cruzadas",
        health.get("crossReferences", 0) > 300000,
        str(health),
    )

    status, listing, _ = client.get("/v1/resources?pageSize=50")
    check("lista de recursos", status == 200 and listing["total"] == len(ids))
    check(
        "facets por tipo",
        listing["facets"]["type"].get("bible") == 9
        and listing["facets"]["type"].get("devotional") == 1
        and listing["facets"]["type"].get("factbook") == 1
        and listing["facets"]["type"].get("commentary") == 1
        and listing["facets"]["type"].get("dictionary") == 2
        and listing["facets"]["language"].get("es") == 7
        and listing["facets"]["language"].get("he") == 1
        and listing["facets"]["language"].get("grc") == 1
        and listing["facets"]["language"].get("mul") == 1,
        str(listing["facets"]),
    )
    check("resumen con licencia", summary["license"]["kind"] == "public-domain", str(summary["license"]))

    status, bible, _ = client.get("/v1/resources?type=bible")
    check("filtro por tipo", status == 200 and bible["total"] == 9)
    status, spanish, _ = client.get("/v1/resources?language=es")
    check("filtro por idioma", status == 200 and spanish["total"] == 7)

    status, manifest, headers = client.get("/v1/resources/bible.rv1909")
    check(
        "manifiesto rv1909",
        status == 200
        and manifest["title"] == "Reina-Valera 1909"
        and manifest["stats"]["verses"] == 31102
        and manifest["stats"]["sections"] == 1189,
        f"stats={manifest.get('stats')}",
    )
    etag = headers.get("ETag")
    status, _, _ = client.get("/v1/resources/bible.rv1909", {"If-None-Match": etag})
    check("ETag → 304", status == 304, f"etag={etag} status={status}")

    status, book, _ = client.get("/v1/resources/bible.rv1909/books/JHN")
    check("libro JHN", status == 200 and len(book["chapters"]) == 21)

    status, section, _ = client.get("/v1/resources/bible.rv1909/sections/JHN.1")
    check(
        "sección JHN.1",
        status == 200 and section["title"] == "Juan 1" and len(section["blocks"]) > 0,
    )

    status, stream, _ = client.get("/v1/resources/bible.rv1909/sections?from=0&limit=3")
    check("stream de secciones", status == 200 and stream["total"] == 1189 and len(stream["items"]) == 3)

    status, dev, _ = client.get("/v1/resources/devotional.daily/sections/dayofyear.10.19")
    check(
        "devocional de hoy",
        status == 200 and dev["day"] == "10.19" and len(dev["blocks"]) > 0,
        str(dev)[:120],
    )
    status, dev_stream, _ = client.get("/v1/resources/devotional.daily/sections?from=0&limit=2")
    check(
        "stream del devocional sin bloques",
        status == 200 and dev_stream["total"] == 366
        and all("blocks" not in item for item in dev_stream["items"]),
    )

    status, topic, _ = client.get("/v1/resources/factbook.core/sections/gracia")
    check(
        "artículo del Factbook",
        status == 200 and topic["title"] == "Gracia" and "fe" in topic["related"],
    )

    status, commentary_manifest, _ = client.get(
        "/v1/resources/commentary.matthew-henry-concise"
    )
    check(
        "manifiesto del comentario",
        status == 200
        and commentary_manifest["stats"]["sections"] == 1189
        and commentary_manifest["license"]["kind"] == "public-domain",
        str(commentary_manifest.get("stats")),
    )
    status, commentary, _ = client.get(
        "/v1/resources/commentary.matthew-henry-concise/sections/JHN.3"
    )
    check(
        "comentario de Juan 3",
        status == 200
        and commentary["title"] == "John 3"
        and len(commentary["blocks"]) > 0,
        str(commentary)[:120],
    )
    status, commentary_stream, _ = client.get(
        "/v1/resources/commentary.matthew-henry-concise/sections?from=0&limit=2"
    )
    check(
        "stream del comentario sin bloques",
        status == 200
        and commentary_stream["total"] == 1189
        and all("blocks" not in item for item in commentary_stream["items"]),
    )

    status, dictionary_manifest, _ = client.get(
        "/v1/resources/dictionary.easton"
    )
    check(
        "manifiesto del diccionario",
        status == 200
        and dictionary_manifest["stats"]["sections"] > 3900
        and dictionary_manifest["license"]["kind"] == "public-domain",
        str(dictionary_manifest.get("stats")),
    )
    status, dictionary, _ = client.get(
        "/v1/resources/dictionary.easton/sections/grace"
    )
    check(
        "entrada del diccionario",
        status == 200 and dictionary["title"] == "Grace"
        and len(dictionary["blocks"]) > 0,
        str(dictionary)[:120],
    )

    status, xrefs, _ = client.get("/v1/cross-references?ref=JHN.3.16")
    xref_items = {item["ref"] for item in (xrefs.get("items") or [])}
    check(
        "referencias cruzadas de Juan 3:16",
        status == 200
        and xrefs.get("source") == "Treasury of Scripture Knowledge"
        and "ROM.5.8" in xref_items,
        str(sorted(xref_items)[:5]),
    )
    status, chapter_xrefs, _ = client.get("/v1/cross-references?ref=JHN.3&limit=20")
    check(
        "referencias cruzadas por capítulo",
        status == 200
        and chapter_xrefs["total"] >= 20
        and len(chapter_xrefs["items"]) == 20,
        str(chapter_xrefs.get("total")),
    )
    status, bad_xrefs, _ = client.get("/v1/cross-references?ref=")
    check("referencia cruzada inválida → 400", status == 400)

    status, unknown, _ = client.get("/v1/resources/bible.nope")
    check("recurso desconocido → 404", status == 404)

    status, bad, _ = client.get('/v1/search?q="sin%20cerrar')
    check("consulta inválida → 400", status == 400, str(bad))

    status, hits, _ = client.get("/v1/search?q=Verbo&scope=bible&pageSize=5")
    first = (hits["hits"] or [{}])[0]
    check("búsqueda simple con resultados", status == 200 and hits["total"] > 0, f"total={hits.get('total')}")
    check(
        "resultado con ref/cita/snippet",
        bool(re.match(r"^[A-Z0-9]+\.\d+\.\d+$", first.get("ref", "")))
        and ":" in first.get("citation", "")
        and "<em>" in first.get("snippet", ""),
        str(first),
    )
    check("paginación devuelve pageSize", len(hits["hits"]) == 5)

    status, phrase, _ = client.get('/v1/search?q=%22en%20el%20principio%22&scope=bible')
    check("frase entre comillas", status == 200 and phrase["total"] > 0, f"total={phrase.get('total')}")

    status, conjunction, _ = client.get("/v1/search?q=Verbo%20AND%20principio&scope=bible")
    refs = {h["ref"] for h in conjunction["hits"]}
    check("AND con resultado esperado", status == 200 and "JHN.1.1" in refs, str(sorted(refs)[:5]))

    status, near, _ = client.get("/v1/search?q=principio%20WITHIN%205%20WORDS%20Verbo&scope=bible")
    check("WITHIN n WORDS", status == 200 and near["total"] > 0, f"total={near.get('total')}")

    status, negated, _ = client.get("/v1/search?q=Verbo%20NOT%20principio&scope=bible")
    check(
        "NOT reduce resultados",
        0 < negated["total"] < hits["total"],
        f"con={hits['total']} sin={negated['total']}",
    )

    status, books, _ = client.get("/v1/search?q=Dios&scope=books&pageSize=50")
    book_types = {h["resourceType"] for h in books["hits"]}
    check(
        "scope books incluye Factbook y devocional",
        status == 200
        and books["total"] > 0
        and {"factbook", "devotional"} <= book_types,
        f"total={books.get('total')} types={book_types}",
    )
    check(
        "resultado no bíblico usa section id como referencia",
        all(
            (h["ref"] == h["sectionId"] and h["book"] == "")
            for h in books["hits"]
            if h["resourceType"] != "bible"
        ),
        str(books["hits"][:2]),
    )
    check(
        "facets de búsqueda",
        books.get("facets", {}).get("type", {}).get("factbook", 0) > 0
        and books.get("facets", {}).get("type", {}).get("devotional", 0) > 0,
        str(books.get("facets")),
    )

    status, content_search, _ = client.get(
        "/v1/search?q=Nicodemus&scope=books&pageSize=10"
    )
    check(
        "scope books incluye el comentario",
        status == 200
        and any(
            hit["resourceType"] == "commentary"
            for hit in content_search["hits"]
        ),
        str([h["resourceType"] for h in content_search["hits"][:5]]),
    )
    status, dictionary_search, _ = client.get(
        "/v1/search?q=grace&resource=dictionary.easton&pageSize=5"
    )
    check(
        "búsqueda dentro del diccionario",
        status == 200
        and dictionary_search["total"] > 0
        and {h["resourceType"] for h in dictionary_search["hits"]}
        == {"dictionary"},
        f"total={dictionary_search.get('total')}",
    )

    status, near2, _ = client.get(
        "/v1/search?q=principio%20NEAR%20Verbo&scope=bible"
    )
    check("NEAR simple", status == 200 and near2["total"] > 0, f"total={near2.get('total')}")

    status, near5, _ = client.get(
        "/v1/search?q=" + quote("principio NEAR/5 Verbo") + "&scope=bible"
    )
    check(
        "NEAR/5 con distancia explícita",
        status == 200 and near5["total"] > 0,
        f"total={near5.get('total')}",
    )

    status, field, _ = client.get(
        "/v1/search?q=" + quote('bible:"Jn 3"') + "&pageSize=100"
    )
    check(
        "campo bible: limita al pasaje",
        status == 200
        and field["total"] > 0
        and {h["book"] for h in field["hits"]} == {"JHN"}
        and {h["chapter"] for h in field["hits"]} == {3},
        f"total={field.get('total')} refs={[h['ref'] for h in field['hits'][:3]]}",
    )

    status, typed, _ = client.get(
        "/v1/search?q=" + quote("type:factbook gracia") + "&pageSize=10"
    )
    check(
        "campo type:",
        status == 200
        and typed["total"] > 0
        and {h["resourceType"] for h in typed["hits"]} == {"factbook"},
        f"total={typed.get('total')}",
    )

    status, english, _ = client.get(
        "/v1/search?q=" + quote("beginning language:en") + "&pageSize=100"
    )
    english_ids = {h["resourceId"] for h in english["hits"]}
    check(
        "campo language:",
        status == 200
        and english["total"] > 0
        and {"bible.kjv", "bible.asv"} <= english_ids
        and english_ids
        <= {
            "bible.kjv",
            "bible.asv",
            "commentary.matthew-henry-concise",
            "dictionary.easton",
        },
        f"total={english.get('total')} ids={english_ids}",
    )

    status, filtered, _ = client.get(
        "/v1/search?q=principio&book=JHN&pageSize=10"
    )
    check(
        "filtro por libro",
        status == 200
        and filtered["total"] > 0
        and {h["book"] for h in filtered["hits"]} == {"JHN"},
        f"total={filtered.get('total')}",
    )
    check(
        "faceta de libro",
        filtered.get("facets", {}).get("book", {}).get("JHN", 0) > 0,
        str(filtered.get("facets")),
    )

    status, plain, _ = client.get("/v1/search?q=corazon&scope=bible")
    status2, accented, _ = client.get("/v1/search?q=coraz%C3%B3n&scope=bible")
    check(
        "diacríticos (corazon ≈ corazón)",
        status == 200 and plain["total"] > 0 and plain["total"] == accented["total"],
        f"sin={plain.get('total')} con={accented.get('total')}",
    )

    if "bible.kjv" in catalog.resources:
        status, kjv, _ = client.get("/v1/search?q=beginning&scope=bible&pageSize=30")
        resources = {h["resourceId"] for h in kjv["hits"]}
        check("KJV participa en la búsqueda", "bible.kjv" in resources, str(resources))

        # `resource=` limita a un recurso (búsqueda dentro del panel).
        status, only_kjv, _ = client.get(
            "/v1/search?q=beginning&scope=bible&resource=bible.kjv&pageSize=30"
        )
        check(
            "búsqueda dentro de un recurso",
            status == 200
            and only_kjv["total"] > 0
            and {h["resourceId"] for h in only_kjv["hits"]} == {"bible.kjv"},
            f"total={only_kjv.get('total')}",
        )
        status, only_rv, _ = client.get(
            "/v1/search?q=beginning&scope=bible&resource=bible.rv1909"
        )
        check(
            "resource= excluye otros recursos",
            status == 200 and only_rv["total"] == 0,
            f"total={only_rv.get('total')}",
        )
        status, missing, _ = client.get("/v1/search?q=beginning&resource=bible.nope")
        check("resource= desconocido → 404", status == 404)

        status, both, _ = client.get("/v1/resources?query=biblia")
        check("búsqueda de metadatos en español", status == 200 and both["total"] >= 2, f"total={both.get('total')}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--data", default="catalog/data")
    args = ap.parse_args()

    data_dir = Path(args.data)
    if not data_dir.is_absolute():
        data_dir = ROOT / data_dir

    Handler.catalog = Catalog(data_dir)
    server = Server(("127.0.0.1", 0), Handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    client = Client(f"http://127.0.0.1:{server.server_address[1]}")
    try:
        run(client, Handler.catalog)
    finally:
        server.shutdown()
        server.server_close()

    failures = [c for c in CHECKS if not c[1]]
    for name, ok, detail in CHECKS:
        mark = "✓" if ok else "✗"
        print(f" {mark} {name}" + (f"  [{detail}]" if detail and not ok else ""))
    print(f"{len(CHECKS) - len(failures)}/{len(CHECKS)} comprobaciones correctas")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
