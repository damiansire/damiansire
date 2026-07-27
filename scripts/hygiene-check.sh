#!/usr/bin/env bash
# Gate de higiene: falla si el repo tiene TRACKEADO un archivo que nunca deberia
# publicarse (credenciales) o un descartable de sesion.
#
# Por que vive en un script y no inline en el workflow: para que se pueda correr
# en local (`pnpm hygiene`) antes de commitear, y sobre todo para que se pueda
# EJERCITAR EN SU DIRECCION DE FALLA (`pnpm hygiene:test`). Un gate que solo se
# probo pasando no esta probado.
#
# Alcance honesto de lo que garantiza: mira NOMBRES de archivo del indice actual.
# No inspecciona contenido ni historial, asi que no detecta un token pegado
# dentro de un archivo legitimo ni uno commiteado y borrado despues.
#
# Uso:
#   scripts/hygiene-check.sh           # revisa los archivos trackeados por git
#   scripts/hygiene-check.sh --stdin   # revisa la lista de rutas que llega por stdin
set -euo pipefail

# El patron matchea la PROPIEDAD ("esto es una credencial o un descartable"), no
# un nombre exacto: por eso `.env` cubre tambien `.env.local` y `.env.production`,
# y `claude-scratch-` cubre el directorio ademas del archivo suelto.
PATTERN='(^|/)\.env($|\.)|(^|/)claude-scratch-|(^|/)claude-orch-|(^|/)temp_|(^|/)rewrite[0-9]+\.py$|(^|/)\.npmrc$|(^|/)id_(rsa|dsa|ecdsa|ed25519)($|\.)|\.(pem|p12|pfx|key)$|(^|/)[^/]*credentials?\.json$'

if [ "${1:-}" = "--stdin" ]; then
  files=$(cat)
else
  # core.quotePath=false + -z: sin esto git escapa las rutas con acentos como
  # "Ram\303\263n/.env" (con comillas incluidas) y el patron no matchea, o sea
  # que cualquier ruta no-ASCII evadia el gate.
  # Y sin `|| true` colgando del pipe: si git falla, pipefail + set -e abortan
  # aca en vez de reportar "OK" y salir 0.
  files=$(git -c core.quotePath=false ls-files -z | tr '\0' '\n')
fi

set +e
matches=$(printf '%s\n' "$files" | grep -E "$PATTERN")
grep_status=$?
set -e

# grep: 0 = hubo match, 1 = no hubo (caso feliz), >1 = error real del comando.
if [ "$grep_status" -gt 1 ]; then
  echo "hygiene-check: grep fallo con codigo $grep_status" >&2
  exit "$grep_status"
fi

if [ -n "$matches" ]; then
  echo "Archivos trackeados que no deberian estar en el repo:"
  printf '%s\n' "$matches"
  exit 1
fi

echo "OK: ningun patron prohibido trackeado."
