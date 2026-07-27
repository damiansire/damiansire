#!/usr/bin/env bash
# Chequeo ejecutable de coherencia doc-manifest: el gate que CLAUDE.md declara
# en su seccion Documentacion. Tres aserciones deterministas:
#
#   1. El name del package.json coincide con el handle github.com/<handle> al
#      que rutean los links del README (el perfil habla de si mismo).
#   2. El manifest declara una description no vacia.
#   3. Todo comando `pnpm <script>` que los docs prometen existe en
#      package.json: un doc que documenta un gate inexistente falla aca,
#      no cuando alguien lo intenta correr.
#
# Alcance honesto: la description y los topics del repo en GitHub no se
# chequean (necesitan red/API); esto cubre lo verificable offline.
#
# Uso: scripts/doc-manifest-check.sh [dir]   # default: raiz del repo
set -euo pipefail

dir="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$dir"

fail=0

name=$(node -p "require('./package.json').name || ''")
desc=$(node -p "require('./package.json').description || ''")

if [ -z "$name" ]; then
  echo "doc-manifest: package.json no declara name"
  fail=1
fi
if [ -z "$desc" ]; then
  echo "doc-manifest: package.json no declara description"
  fail=1
fi

# grep sale 1 cuando no hay matches (legitimo) y >1 ante error real: solo lo
# segundo aborta. Mismo criterio que el hygiene gate: no confundir "no
# encontre" con "no pude buscar".

# 1. Los links github.com/<handle> del README apuntan al name del manifest.
set +e
handles=$(grep -ohE 'github\.com/[A-Za-z0-9-]+' README.md | sed 's#github\.com/##' | sort -u)
st=$?
set -e
if [ "$st" -gt 1 ]; then
  echo "doc-manifest: fallo el escaneo de handles del README (codigo $st)" >&2
  exit "$st"
fi
for h in $handles; do
  if [ "$h" != "$name" ]; then
    echo "doc-manifest: el README rutea a github.com/$h pero el manifest se llama '$name'"
    fail=1
  fi
done

# 3. Scripts prometidos en los docs vs scripts reales del manifest.
set +e
prometidos=$(grep -ohE 'pnpm (run )?[a-z][a-z:-]*' README.md CLAUDE.md 2>/dev/null | sed -E 's/^pnpm (run )?//' | sort -u)
st=$?
set -e
if [ "$st" -gt 1 ]; then
  echo "doc-manifest: fallo el escaneo de comandos pnpm en los docs (codigo $st)" >&2
  exit "$st"
fi
for s in $prometidos; do
  # Comandos builtin de pnpm: no son scripts del manifest.
  case "$s" in install | i | ci | add | up | dlx | run) continue ;; esac
  existe=$(node -p "Object.prototype.hasOwnProperty.call(require('./package.json').scripts || {}, '$s')")
  if [ "$existe" != "true" ]; then
    echo "doc-manifest: los docs prometen 'pnpm $s' pero package.json no tiene ese script"
    fail=1
  fi
done

if [ "$fail" -ne 0 ]; then
  exit 1
fi
echo "OK: doc y manifest coherentes (handle, description, scripts prometidos)."
