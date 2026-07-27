#!/usr/bin/env bash
# Gate de higiene: falla si el repo publica algo que nunca deberia publicarse.
#
# Tres capas, cada una ejercitada en su direccion de falla por el self-test
# (scripts/hygiene-check.test.sh). Un gate que solo se probo pasando no esta
# probado.
#
#   1. NOMBRES: archivos trackeados cuyo nombre delata una credencial o un
#      descartable de sesion (.env*, claude-scratch-*, id_rsa, *.pem, ...).
#   2. CONTENIDO: tokens con formato conocido pegados dentro de archivos
#      trackeados (ghp_, github_pat_, AKIA, AIza, xoxb, PEM, ...), y rayas em
#      (U+2014) en el texto trackeado (regla de escritura del autor).
#   3. HISTORIAL: los mismos nombres y tokens en TODOS los commits, porque un
#      secreto commiteado y borrado despues sigue siendo clonable del historial
#      publico. Requiere historial completo (fetch-depth: 0 en CI).
#
# Alcance honesto de lo que garantiza: la capa de contenido detecta FORMATOS de
# token conocidos, no entropia arbitraria; un secreto sin prefijo reconocible
# pasa. La raya em se chequea solo en el indice actual (el historial viejo la
# tiene y no se reescribe).
#
# Uso:
#   scripts/hygiene-check.sh           # nombres + contenido + historial
#   scripts/hygiene-check.sh --stdin   # solo nombres, sobre la lista por stdin
set -euo pipefail

# El patron matchea la PROPIEDAD ("esto es una credencial o un descartable"), no
# un nombre exacto: por eso `.env` cubre tambien `.env.local` y `.env.production`,
# y `claude-scratch-` cubre el directorio ademas del archivo suelto.
NAME_PATTERN='(^|/)\.env($|\.)|(^|/)claude-scratch-|(^|/)claude-orch-|(^|/)temp_|(^|/)rewrite[0-9]+\.py$|(^|/)\.npmrc$|(^|/)id_(rsa|dsa|ecdsa|ed25519)($|\.)|\.(pem|p12|pfx|key)$|(^|/)[^/]*credentials?\.json$|(^|/)\.claude/settings\.local\.json$'

# Formatos de token conocidos. Ninguna alternativa matchea su propia definicion
# (el literal "ghp_[A-Za-z0-9]{36}" no es un token), asi que este archivo no se
# marca a si mismo.
SECRET_PATTERN='gh[oprsu]_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{22,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}|xox[abprs]-[0-9A-Za-z-]{10,}|npm_[A-Za-z0-9]{36}|sk-[A-Za-z0-9_-]{32,}|-----BEGIN [A-Z ]*PRIVATE KEY-----'

EMDASH=$(printf '\342\200\224')

fail=0

# grep sale 0 = hubo match, 1 = no hubo (caso feliz), >1 = error real del
# comando. Esta funcion distingue los tres: reportar OK cuando el comando de
# abajo fallo es exactamente el falso verde que este gate vino a matar.
grep_o_muere() {
  local status=$1 contexto=$2
  if [ "$status" -gt 1 ]; then
    echo "hygiene-check: fallo el chequeo de $contexto (codigo $status)" >&2
    exit "$status"
  fi
}

# --- capa 1: nombres trackeados -----------------------------------------------
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
matches=$(printf '%s\n' "$files" | grep -E "$NAME_PATTERN")
grep_status=$?
set -e
grep_o_muere "$grep_status" "nombres trackeados"

if [ -n "$matches" ]; then
  echo "Archivos trackeados que no deberian estar en el repo:"
  printf '%s\n' "$matches"
  fail=1
fi

# Modo lista: solo la capa de nombres (lo usa el self-test de rutas, que no
# tiene un repo git atras).
if [ "${1:-}" = "--stdin" ]; then
  if [ "$fail" -ne 0 ]; then
    exit 1
  fi
  echo "OK: ningun patron prohibido trackeado."
  exit 0
fi

# --- capa 2: contenido de los archivos trackeados ------------------------------
set +e
secretos=$(git grep -I -n -E "$SECRET_PATTERN" -- .)
grep_status=$?
set -e
grep_o_muere "$grep_status" "contenido (tokens)"

if [ -n "$secretos" ]; then
  echo "Tokens con formato de credencial dentro de archivos trackeados:"
  printf '%s\n' "$secretos"
  fail=1
fi

set +e
rayas=$(git grep -I -n -F "$EMDASH" -- .)
grep_status=$?
set -e
grep_o_muere "$grep_status" "contenido (raya em)"

if [ -n "$rayas" ]; then
  echo "Raya em (U+2014) en texto trackeado (regla de escritura del autor):"
  printf '%s\n' "$rayas"
  fail=1
fi

# --- capa 3: historial completo -------------------------------------------------
# Solo si hay commits: en un repo recien inicializado no hay historial que mirar.
revs=$(git rev-list --all)
if [ -n "$revs" ]; then
  # Si git log falla, set -e aborta aca: no se absorbe dentro del pipe del grep.
  hist_lista=$(git -c core.quotePath=false log --all --format= --name-only --diff-filter=A)

  set +e
  hist_nombres=$(printf '%s\n' "$hist_lista" | grep -E "$NAME_PATTERN" | sort -u)
  grep_status=$?
  set -e
  grep_o_muere "$grep_status" "historial (nombres)"

  if [ -n "$hist_nombres" ]; then
    echo "Archivos prohibidos en el HISTORIAL (borrarlos del indice no alcanza, siguen clonables):"
    printf '%s\n' "$hist_nombres"
    fail=1
  fi

  set +e
  # shellcheck disable=SC2086
  hist_secretos=$(git grep -I -l -E "$SECRET_PATTERN" $revs)
  grep_status=$?
  set -e
  grep_o_muere "$grep_status" "historial (tokens)"

  if [ -n "$hist_secretos" ]; then
    echo "Tokens con formato de credencial en el HISTORIAL (commit:archivo):"
    printf '%s\n' "$hist_secretos"
    fail=1
  fi
fi

if [ "$fail" -ne 0 ]; then
  exit 1
fi
echo "OK: higiene en verde (nombres, contenido e historial)."
