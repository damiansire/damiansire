#!/usr/bin/env bash
# Self-test del gate de higiene: lo ejercita RECHAZANDO, que es la direccion en
# la que un gate falla en silencio. Cubre las tres regresiones concretas que la
# auditoria encontro: exito falso si git falla, evasion por ruta no-ASCII, y
# variantes de .env que pasaban limpio.
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
service-credentials.json'

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
  echo "FALLA: el gate salio 0 con 14 rutas prohibidas trackeadas"
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
trap 'rm -rf "$tmp" "$sin_git"' EXIT

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
if [ "$failures" -ne 0 ]; then
  echo "self-test del gate: $failures caso(s) en falla"
  exit 1
fi
echo "self-test del gate: todo en verde"
