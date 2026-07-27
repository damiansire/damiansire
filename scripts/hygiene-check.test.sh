#!/usr/bin/env bash
# Self-test del gate de higiene: lo ejercita RECHAZANDO, que es la direccion en
# la que un gate falla en silencio. Cubre las regresiones concretas que las
# auditorias encontraron: exito falso si git falla, evasion por ruta no-ASCII,
# variantes de .env que pasaban limpio, y las capas de contenido e historial
# (un token pegado en un archivo legitimo, o commiteado y borrado despues,
# pasaba el gate de nombres en verde).
#
# Los tokens de prueba se construyen por partes en runtime: si estuvieran
# literales aca, la capa de contenido marcaria este archivo (con razon).
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
check="$here/hygiene-check.sh"
failures=0

# Un lote por asercion (no una corrida por ruta): en Windows cada spawn de bash
# cuesta segundos y el self-test es lo que se corre antes de cada commit.
debe_rechazar='.env
.env.local
.env.production
config/.env
claude-scratch-notas.md
notas/claude-scratch-2026/dump.txt
claude-orch-run/driver.mjs
temp_salida.txt
rewrite2.py
.npmrc
id_rsa
keys/id_ed25519.pub
certs/server.pem
service-credentials.json
.claude/settings.local.json'

debe_aceptar='README.md
package.json
.github/workflows/hygiene-gate.yml
docs/environment.md
scripts/hygiene-check.sh
src/template_engine.ts'

echo "== rutas que el gate tiene que rechazar =="
set +e
salida=$(printf '%s\n' "$debe_rechazar" | bash "$check" --stdin 2>&1)
estado=$?
set -e
if [ "$estado" -eq 0 ]; then
  echo "FALLA: el gate salio 0 con 15 rutas prohibidas trackeadas"
  failures=$((failures + 1))
fi
while IFS= read -r ruta; do
  if printf '%s\n' "$salida" | grep -qxF "$ruta"; then
    echo "ok  rechaza  $ruta"
  else
    echo "FALLA: '$ruta' deberia ser rechazado y no aparecio en la salida"
    failures=$((failures + 1))
  fi
done <<<"$debe_rechazar"

echo
echo "== rutas legitimas que el gate NO puede romper =="
set +e
printf '%s\n' "$debe_aceptar" | bash "$check" --stdin >/dev/null 2>&1
estado=$?
set -e
if [ "$estado" -eq 0 ]; then
  printf 'ok  acepta   %s\n' $debe_aceptar
else
  echo "FALLA: el gate rechazo rutas legitimas (salio $estado)"
  printf '  %s\n' $debe_aceptar
  failures=$((failures + 1))
fi

echo
echo "== sobre un repo git real (cubre quotePath y el falso verde) =="
tmp=$(mktemp -d)
sin_git=$(mktemp -d)
capas=$(mktemp -d)
trap 'rm -rf "$tmp" "$sin_git" "$capas"' EXIT

git -C "$tmp" init -q
mkdir -p "$tmp/Ramón"
: >"$tmp/Ramón/.env"
git -C "$tmp" add -f "Ramón/.env"
if (cd "$tmp" && bash "$check" >/dev/null 2>&1); then
  echo "FALLA: una ruta con acento evadio el gate"
  failures=$((failures + 1))
else
  echo "ok  rechaza  Ramón/.env (ruta no-ASCII trackeada)"
fi

# Sin repo git, `git ls-files` falla: el gate tiene que morir ruidoso, no
# imprimir OK y salir 0 (la regresion del `|| true`).
if (cd "$sin_git" && bash "$check" >/dev/null 2>&1); then
  echo "FALLA: el gate salio 0 con git roto (exito falso)"
  failures=$((failures + 1))
else
  echo "ok  falla    cuando git ls-files no puede correr"
fi

echo
echo "== capas de contenido e historial (un repo, cuatro fases) =="
# core.autocrlf=false: el fixture es efimero, el warning CRLF de Windows es ruido.
git_capas() { git -C "$capas" -c user.email=test@test -c user.name=test -c core.autocrlf=false "$@"; }
git_capas init -q

# Fase 1: repo limpio con un commit -> el gate tiene que pasar (guarda contra
# falsos positivos de las capas nuevas sobre contenido legitimo).
printf 'notas legitimas, sin secretos\n' >"$capas/notas.md"
git_capas add notas.md
git_capas commit -qm "base limpia"
if (cd "$capas" && bash "$check" >/dev/null 2>&1); then
  echo "ok  acepta   repo limpio con historial (0 falsos positivos)"
else
  echo "FALLA: el gate rechazo un repo limpio"
  failures=$((failures + 1))
fi

# Fase 2: raya em dentro de un archivo trackeado -> tiene que fallar.
raya=$(printf '\342\200\224')
printf 'texto con raya %s prohibida\n' "$raya" >"$capas/estilo.md"
git_capas add estilo.md
salida=$( (cd "$capas" && bash "$check" 2>&1) ) && estado=0 || estado=$?
if [ "$estado" -ne 0 ] && printf '%s\n' "$salida" | grep -q "Raya em"; then
  echo "ok  rechaza  raya em en contenido trackeado"
else
  echo "FALLA: una raya em en un archivo trackeado paso el gate (salio $estado)"
  failures=$((failures + 1))
fi
# -f: el archivo esta staged pero sin commitear, git rm pide fuerza para eso.
git_capas rm -qf estilo.md

# Fase 3: token con formato conocido dentro de un archivo legitimo -> falla.
token="ghp_$(printf 'a%.0s' $(seq 1 36))"
printf 'API_TOKEN=%s\n' "$token" >"$capas/config.md"
git_capas add config.md
salida=$( (cd "$capas" && bash "$check" 2>&1) ) && estado=0 || estado=$?
if [ "$estado" -ne 0 ] && printf '%s\n' "$salida" | grep -q "formato de credencial dentro"; then
  echo "ok  rechaza  token ghp_ pegado en un archivo trackeado"
else
  echo "FALLA: un token en el contenido paso el gate (salio $estado)"
  failures=$((failures + 1))
fi

# Fase 4: el token se commitea y se borra -> el indice queda limpio pero el
# historial sigue clonable: el gate tiene que seguir fallando.
git_capas commit -qm "mete el token"
git_capas rm -q config.md
git_capas commit -qm "borra el token"
salida=$( (cd "$capas" && bash "$check" 2>&1) ) && estado=0 || estado=$?
if [ "$estado" -ne 0 ] && printf '%s\n' "$salida" | grep -q "HISTORIAL"; then
  echo "ok  rechaza  token commiteado y borrado (sigue en el historial)"
else
  echo "FALLA: un token borrado del indice pero vivo en el historial paso el gate (salio $estado)"
  failures=$((failures + 1))
fi

echo
if [ "$failures" -ne 0 ]; then
  echo "self-test del gate: $failures caso(s) en falla"
  exit 1
fi
echo "self-test del gate: todo en verde"
