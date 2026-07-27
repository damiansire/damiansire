#!/usr/bin/env bash
# Self-test del gate de higiene: lo ejercita RECHAZANDO, que es la direccion en
# la que un gate falla en silencio. Cubre las tres regresiones concretas que la
# auditoria encontro: exito falso si git falla, evasion por ruta no-ASCII, y
# variantes de .env que pasaban limpio.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
check="$here/hygiene-check.sh"
failures=0

expect_rejected() {
  if printf '%s\n' "$1" | bash "$check" --stdin >/dev/null 2>&1; then
    echo "FALLA: '$1' deberia ser rechazado y paso"
    failures=$((failures + 1))
  else
    echo "ok  rechaza  $1"
  fi
}

expect_accepted() {
  if printf '%s\n' "$1" | bash "$check" --stdin >/dev/null 2>&1; then
    echo "ok  acepta   $1"
  else
    echo "FALLA: '$1' es legitimo y fue rechazado"
    failures=$((failures + 1))
  fi
}

echo "== rutas que el gate tiene que rechazar =="
expect_rejected ".env"
expect_rejected ".env.local"
expect_rejected ".env.production"
expect_rejected "config/.env"
expect_rejected "claude-scratch-notas.md"
expect_rejected "notas/claude-scratch-2026/dump.txt"
expect_rejected "claude-orch-run/driver.mjs"
expect_rejected "temp_salida.txt"
expect_rejected "rewrite2.py"
expect_rejected ".npmrc"
expect_rejected "id_rsa"
expect_rejected "keys/id_ed25519.pub"
expect_rejected "certs/server.pem"
expect_rejected "service-credentials.json"

echo
echo "== rutas legitimas que el gate NO puede romper =="
expect_accepted "README.md"
expect_accepted "package.json"
expect_accepted ".github/workflows/hygiene-gate.yml"
expect_accepted "docs/environment.md"
expect_accepted "scripts/hygiene-check.sh"
expect_accepted "src/template_engine.ts"

echo
echo "== sobre un repo git real (cubre quotePath y el falso verde) =="
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

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
sin_git=$(mktemp -d)
trap 'rm -rf "$tmp" "$sin_git"' EXIT
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
