#!/usr/bin/env bash
# Self-test del chequeo de badges: lo ejercita RECHAZANDO (regla 2 del
# CLAUDE.md del repo). Sin red: BADGE_FETCH apunta a un stub que responde
# segun la URL. Un badge sano tiene que pasar; uno retirado y uno de repo
# inexistente tienen que fallar, cada uno nombrando su URL.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
check="$here/badge-check.sh"
failures=0

fix=$(mktemp -d)
trap 'rm -rf "$fix"' EXIT

cat >"$fix/stub.sh" <<'SH'
#!/usr/bin/env bash
case "$1" in
  *youtube*) echo '{"label":"youtube","message":"retired badge"}' ;;
  *fantasma*) echo '{"label":"stars","message":"repo not found"}' ;;
  *) echo '{"label":"stars","message":"173"}' ;;
esac
SH
chmod +x "$fix/stub.sh"
export BADGE_FETCH="$fix/stub.sh"

correr() { # $1 = linea de badge a escribir en el README fixture
  printf '# Fixture\n\n%s\n![estatico](https://img.shields.io/badge/a-b-red)\n' "$1" >"$fix/README.md"
  salida=$(bash "$check" "$fix/README.md" 2>&1) && estado=0 || estado=$?
}

echo "== badge sano: tiene que pasar =="
correr '![s](https://img.shields.io/github/stars/x/sano?style=flat)'
if [ "$estado" -eq 0 ]; then
  echo "ok  acepta   badge con valor real (y saltea el estatico)"
else
  echo "FALLA: rechazo un badge sano: $salida"
  failures=$((failures + 1))
fi

echo
echo "== badge retirado por Shields: tiene que fallar =="
correr '![y](https://img.shields.io/youtube/channel/subscribers/UCx?style=flat)'
if [ "$estado" -ne 0 ] && printf '%s\n' "$salida" | grep -q "retired badge"; then
  echo "ok  rechaza  badge retirado"
else
  echo "FALLA: un badge retirado paso el chequeo (salio $estado)"
  failures=$((failures + 1))
fi

echo
echo "== badge de repo inexistente: tiene que fallar =="
correr '![f](https://img.shields.io/github/stars/x/fantasma)'
if [ "$estado" -ne 0 ] && printf '%s\n' "$salida" | grep -q "repo not found"; then
  echo "ok  rechaza  badge de repo inexistente"
else
  echo "FALLA: un badge roto paso el chequeo (salio $estado)"
  failures=$((failures + 1))
fi

echo
if [ "$failures" -ne 0 ]; then
  echo "self-test badges: $failures caso(s) en falla"
  exit 1
fi
echo "self-test badges: todo en verde"
