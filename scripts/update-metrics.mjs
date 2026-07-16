import { readFileSync, writeFileSync } from "node:fs";

// Nota (2026-07-16): se sacaron del README las cifras agregadas de vanidad
// (suma de stars, suma de npm downloads). Un tercero no puede verificarlas
// con un click: hay que recalcularlas a mano. Queda solo el conteo de repos
// publicos, verificable en un click en el tab "Repositories" del perfil, y
// CI (link-check.yml) lo verifica en cada push/PR que toque el README con
// --check, asi un numero manual que difiera de la API real de GitHub rompe CI.

const USER = "damiansire";
const CHECK_ONLY = process.argv.includes("--check");

async function fetchJson(url, headers = {}) {
  const res = await fetch(url, { headers: { "User-Agent": USER, ...headers } });
  if (!res.ok) return null;
  return res.json();
}

async function publicRepoCount() {
  let page = 1;
  let repos = [];
  while (true) {
    const batch = await fetchJson(
      `https://api.github.com/users/${USER}/repos?type=public&per_page=100&page=${page}`
    );
    if (!batch || batch.length === 0) break;
    repos = repos.concat(batch);
    if (batch.length < 100) break;
    page++;
  }
  return repos.filter((r) => !r.fork && !r.archived).length;
}

const publicCount = await publicRepoCount();

const readmePath = new URL("../README.md", import.meta.url);
const readme = readFileSync(readmePath, "utf8");
const match = readme.match(/<!-- METRICS:START.*?METRICS:END -->/s);

if (!match) {
  console.error("No METRICS:START/METRICS:END markers found in README.md");
  process.exit(1);
}

// Reusa el salto de linea del propio README (LF o CRLF) para que el bloque
// generado coincida byte a byte con el archivo, sin depender de que git
// autocrlf este configurado igual en cada maquina.
const NL = readme.includes("\r\n") ? "\r\n" : "\n";
const block = [
  "<!-- METRICS:START (auto, ver scripts/update-metrics.mjs; CI verifica con --check que coincida con la API de GitHub) -->",
  `- 🔓 **${publicCount} public repos**, ver [github.com/${USER}?tab=repositories](https://github.com/${USER}?tab=repositories) (+ private work in Rust, 3D and games, not counted here)`,
  "<!-- METRICS:END -->",
].join(NL);

if (CHECK_ONLY) {
  if (match[0] !== block) {
    console.error("Las metricas del README no coinciden con la API de GitHub ahora mismo.");
    console.error("Esperado:\n" + block + "\n");
    console.error("Encontrado:\n" + match[0] + "\n");
    console.error("Corre `node scripts/update-metrics.mjs` (sin --check) y commiteá el resultado.");
    process.exit(1);
  }
  console.log(`OK: public repos en README (${publicCount}) coincide con la API de GitHub.`);
  process.exit(0);
}

const updated = readme.replace(/<!-- METRICS:START.*?METRICS:END -->/s, block);
writeFileSync(readmePath, updated);
console.log(`public repos: ${publicCount}`);
