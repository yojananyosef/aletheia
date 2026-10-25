#!/usr/bin/env python3
"""Recorta los assets del catálogo en un bundle de release (slim).

La app no debe crecer: el release de escritorio se publica con el catálogo
liviano (RV1909 + léxico Strong + devocional diario + Factbook + metadatos
compartidos). El resto de los 27 recursos y el índice FTS5 (`catalog.search`,
~76 MB) se instalan desde `aletheia-mods` a demanda desde la Tienda, con
progreso, cancelación, sha256 y actualizaciones delta.

El árbol de desarrollo/tests mantiene el catálogo completo: el recorte sólo
aplica al bundle compilado (igual que `build_web_release.sh` para web).

Uso:
  python3 tool/slim_release_bundle.py <build-dir>...

Busca en cada directorio dado los subdirectorios llamados `flutter_assets`
(/bundle/data/flutter_assets en Linux; data/flutter_assets en Windows o
`Contents/...` en macOS) y aplica el recorte a cada uno.
"""
from __future__ import annotations

import shutil
import sys
from pathlib import Path

# Carpetas de módulos (bajo assets/catalog/) que SÍ viajan dentro del
# ejecutable: misma lista que `kBundledCatalogModules` en
# lib/catalog/install/routing_catalog_source.dart.
KEEP_MODULES = {
    "rv1909",          # bible.rv1909
    "lexicon.strongs",  # lexicon.strongs
    "devotional.daily",  # devotional.daily (Inicio, en frío)
    "factbook.core",    # factbook.core (Ideas/Mapas, en frío)
}

# Archivos compartidos a nivel catálogo (sin módulo): siempre empaquetados.
KEEP_FILES = {
    "index.json",
    "search.meta.json",
    "map_sections.json",
    "morphology.json",
}


def prune(assets: Path) -> None:
    catalog = assets / "assets" / "catalog"
    if not catalog.exists():
        return
    for entry in catalog.iterdir():
        if entry.is_dir():
            if entry.name in KEEP_MODULES:
                continue
            shutil.rmtree(entry, ignore_errors=True)
            continue
        if entry.name in KEEP_FILES:
            continue
        entry.unlink(missing_ok=True)


def main(argv: list[str]) -> int:
    found = 0
    for root in argv:
        base = Path(root)
        if base.name == "flutter_assets":
            prune(base)
            found += 1
            continue
        for nested in base.rglob("flutter_assets"):
            if nested.is_dir():
                prune(nested)
                found += 1
    print(f"OK: {found} bundle(s) recortados (slim: RV1909, Strong, devocional, Factbook + metadatos)")
    return 0 if found else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
