#!/usr/bin/env bash
# Chequeo de badges vivos: todo badge dinamico de Shields.io del README tiene
# que renderizar un valor real. Existe porque el link-check no lo ve: un badge
# retirado o roto responde 200 con un SVG gris que dice "retired badge" o
# "repo not found", y en el perfil eso se lee como roto (paso con los badges
# de YouTube en 2026-10).
#
# Como: cada URL de img.shields.io se pide en su variante .json (mismo badge,
# mismo valor) y se rechaza si el mensaje es uno de los estados de error de
# Shields. Los badges estaticos (/badge/...) no tienen dato que se rompa y se
# saltean.
#
# Alcance honesto: necesita red. En CI corre en cada push y en el cron
# semanal, que es lo que atrapa un badge que Shields retira sin que haya
# commits.
#
# Uso: scripts/badge-check.sh [README]
# BADGE_FETCH reemplaza el fetch (lo usa el self-test para no tocar la red).
set -euo pipefail

readme="${1:-$(cd "$(dirname "$0")/.." && pwd)/README.md}"
fetch="${BADGE_FETCH:-curl -fsS --max-time 15 --retry 3 --retry-all-errors --retry-delay 5}"

# grep sale 1 sin matches (legitimo: un README sin badges) y >1 ante error.
set +e
urls=$(grep -oE 'https://img\.shields\.io/[^) "]+' "$readme" | grep -v '^https://img\.shields\.io/badge/' | sort -u)
st=$?
set -e
if [ "$st" -gt 1 ]; then
  echo "badges: fallo el escaneo del README (codigo $st)" >&2
  exit "$st"
fi

fail=0
n=0
for u in $urls; do
  n=$((n + 1))
  base="${u%%\?*}"
  json_url="${base}.json"
  if ! body=$($fetch "$json_url" 2>/dev/null); then
    echo "badges: no se pudo leer $json_url"
    fail=1
    continue
  fi
  msg=$(printf '%s' "$body" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{process.stdout.write(String(JSON.parse(s).message??""))}catch{process.stdout.write("")}})')
  shopt -s nocasematch
  case "$msg" in
    "" | *retired* | *invalid* | *"not found"* | *inaccessible* | *deprecated* | *error* | *unknown* | *"no longer available"*)
      echo "badges: $base renderiza '${msg:-<vacio>}'"
      fail=1
      ;;
  esac
  shopt -u nocasematch
done

if [ "$fail" -ne 0 ]; then
  exit 1
fi
echo "OK: $n badge(s) dinamicos con valor real."
