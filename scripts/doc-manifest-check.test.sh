#!/usr/bin/env bash
# Self-test del chequeo doc-manifest: lo ejercita RECHAZANDO (regla 2 del
# CLAUDE.md del repo: todo chequeo nuevo viene con un fixture que DEBE hacerlo
# salir 1). Tres fixtures: uno coherente que tiene que pasar, y dos rotos que
# tienen que fallar cada uno por su causa.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
check="$here/doc-manifest-check.sh"
failures=0

fix=$(mktemp -d)
trap 'rm -rf "$fix"' EXIT

escribir_fixture() { # $1 = name del manifest, $2 = handle del README, $3 = script prometido
  cat >"$fix/package.json" <<JSON
{
  "name": "$1",
  "description": "fixture de prueba del chequeo doc-manifest",
  "scripts": { "lint": "true" }
}
JSON
  cat >"$fix/README.md" <<MD
# Fixture

Trabajo en [github.com/$2](https://github.com/$2/proyecto).
MD
  cat >"$fix/CLAUDE.md" <<MD
# Fixture

En local corre \`pnpm $3\`.
MD
}

echo "== fixture coherente: tiene que pasar =="
escribir_fixture perfil-x perfil-x lint
if bash "$check" "$fix" >/dev/null 2>&1; then
  echo "ok  acepta   manifest, README y docs coherentes"
else
  echo "FALLA: el chequeo rechazo un fixture coherente"
  failures=$((failures + 1))
fi

echo
echo "== README ruteando a otro handle: tiene que fallar =="
escribir_fixture perfil-x otro-handle lint
salida=$(bash "$check" "$fix" 2>&1) && estado=0 || estado=$?
if [ "$estado" -ne 0 ] && printf '%s\n' "$salida" | grep -q "rutea a github.com/otro-handle"; then
  echo "ok  rechaza  handle del README distinto del name del manifest"
else
  echo "FALLA: un handle divergente paso el chequeo (salio $estado)"
  failures=$((failures + 1))
fi

echo
echo "== doc que promete un gate inexistente: tiene que fallar =="
escribir_fixture perfil-x perfil-x fantasma
salida=$(bash "$check" "$fix" 2>&1) && estado=0 || estado=$?
if [ "$estado" -ne 0 ] && printf '%s\n' "$salida" | grep -q "pnpm fantasma"; then
  echo "ok  rechaza  script prometido en docs que no existe en el manifest"
else
  echo "FALLA: un gate prometido e inexistente paso el chequeo (salio $estado)"
  failures=$((failures + 1))
fi

echo
if [ "$failures" -ne 0 ]; then
  echo "self-test doc-manifest: $failures caso(s) en falla"
  exit 1
fi
echo "self-test doc-manifest: todo en verde"
