#!/usr/bin/env bash
# Compila la web con un catálogo mínimo empaquetado.
#
# El contenido completo (Biblias adicionales, comentario, diccionario,
# devocional, Factbook e índice FTS5) vive en `aletheia-mods` y se descarga
# bajo demanda. En el bundle web solo quedan:
#   - la geometría de mapas (pequeña y necesaria offline);
#   - el índice de recursos (10 KB);
#   - la RV1909 como lectura inicial sin red;
#   - las descripciones de morfología.
#
# El pubspec original se restaura incluso si la compilación falla. El catálogo
# completo sigue disponible para escritorio, pruebas e integraciones.
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PUBSPEC="$APP_DIR/pubspec.yaml"
BACKUP="$(mktemp "${TMPDIR:-/tmp}/aletheia-pubspec.XXXXXX")"

cleanup() {
  cp "$BACKUP" "$PUBSPEC"
  rm -f "$BACKUP"
}
trap cleanup EXIT

cp "$PUBSPEC" "$BACKUP"

python3 - "$PUBSPEC" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
start = text.find("\n  assets:\n")
end = text.find("\n  # To add assets to your application", start)
if start < 0 or end < 0:
    raise SystemExit("no se encontró el bloque de assets en pubspec.yaml")

block = """
  assets:
    - assets/maps/
    - assets/catalog/index.json
    - assets/catalog/search.meta.json
    - assets/catalog/map_sections.json
    - assets/catalog/rv1909/
    - assets/catalog/rv1909/books/
    - assets/catalog/morphology.json
"""
path.write_text(text[:start] + block + text[end:], encoding="utf-8")
PY

cd "$APP_DIR"
DEFINES=()
if [[ -n "${ALETHEIA_MODS_URL:-}" ]]; then
  DEFINES+=("--dart-define=ALETHEIA_MODS_URL=${ALETHEIA_MODS_URL}")
fi

flutter build web \
  --release \
  --base-href /aletheia/ \
  --no-web-resources-cdn \
  --pwa-strategy=none \
  "${DEFINES[@]}"

# El service worker propio (sw.js) reemplaza al de Flutter; se elimina el
# artefacto por si una compilación anterior lo dejó en build/web.
rm -f build/web/flutter_service_worker.js

# Genera la lista de archivos que el service worker precarga para que la app
# pueda arrancar sin red después de la primera visita.
python3 - "$APP_DIR/build/web" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
selected = []
seen = set()

def add(relative: str) -> None:
    if relative in seen:
        return
    if relative == "":
        # La URL raíz del ámbito también debe estar en caché: una navegación
        # offline a /aletheia/ no coincide con /aletheia/index.html.
        seen.add(relative)
        selected.append(relative)
        return
    if (root / relative).is_file():
        seen.add(relative)
        selected.append(relative)

# El documento raíz y los archivos que Flutter necesita para arrancar.
for name in (
    "",
    "index.html",
    "flutter_bootstrap.js",
    "flutter.js",
    "main.dart.js",
    "manifest.json",
    "favicon.png",
    "sqlite3.wasm",
):
    add(name)

# CanvasKit base (Safari/Firefox) y Chromium, los dos renderizadores que
# Flutter puede cargar en producción. Se omiten skwasm, wimp, webparagraph y
# los símbolos de depuración: no se usan y sumaban casi 20 MB a la precarga.
for name in (
    "canvaskit/canvaskit.js",
    "canvaskit/canvaskit.wasm",
    "canvaskit/chromium/canvaskit.js",
    "canvaskit/chromium/canvaskit.wasm",
):
    add(name)

for directory in ("icons", "assets/shaders"):
    base = root / directory
    if not base.exists():
        continue
    for path in sorted(base.rglob("*")):
        if path.is_file() and path.suffix not in {".symbols", ".map"}:
            add(path.relative_to(root).as_posix())

# Manifiestos, fuentes y el catálogo mínimo empaquetado.
for name in (
    "assets/AssetManifest.bin",
    "assets/AssetManifest.bin.json",
    "assets/FontManifest.json",
    "assets/assets/catalog/index.json",
    "assets/assets/catalog/search.meta.json",
    "assets/assets/catalog/map_sections.json",
    "assets/assets/catalog/morphology.json",
):
    add(name)

for directory in (
    "assets/fonts",
    "assets/packages",
    "assets/assets/maps",
    "assets/assets/catalog/rv1909",
):
    base = root / directory
    if not base.exists():
        continue
    for path in sorted(base.rglob("*")):
        if path.is_file() and path.suffix not in {".symbols", ".map"}:
            add(path.relative_to(root).as_posix())

lines = [
    "/* Generado por tool/build_web_release.sh. */",
    "self.ALETHEIA_SHELL_ASSETS = [",
]
lines.extend(f"  {path!r}," for path in selected)
lines.extend(["];", ""])
(root / "sw-manifest.js").write_text("\n".join(lines), encoding="utf-8")
total = sum((root / path).stat().st_size for path in selected if path)
print(f"Service worker: {len(selected)} archivos de shell, {total / 1_000_000:.1f} MB")
PY

# Fuerza una comprobación de actualización del worker en cada build.
python3 - "$APP_DIR/build/web" <<'PY'
from pathlib import Path
import hashlib
import re
import sys

root = Path(sys.argv[1])
manifest = root / "sw-manifest.js"
version = hashlib.sha256(
    (root / "sw.js").read_bytes()
    + manifest.read_bytes()
    + (root / "main.dart.js").read_bytes()
    + (root / "flutter_bootstrap.js").read_bytes()
).hexdigest()[:12]
index = root / "index.html"
text = index.read_text(encoding="utf-8")
text = re.sub(r"register\('sw\.js(?:\?v=[^']*)?'\)", f"register('sw.js?v={version}')", text)
index.write_text(text, encoding="utf-8")
print(f"Service worker: versión de actualización {version}")
PY

# GitHub Pages no debe procesar el sitio con Jekyll.
touch build/web/.nojekyll
