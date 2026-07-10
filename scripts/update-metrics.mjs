import { readFileSync, writeFileSync } from "node:fs";

const USER = "damiansire";
const NPM_PACKAGES = [
  "pascal-parser",
  "pascal-js-compiler",
  "cognitive-substrate-os",
  "youtube-fast-api",
  "pascal-tokenizer",
  "date-wizard-pro",
  "pascal-code-formatter",
  "react-dinamic-tables",
  "json-scan",
  "replace-all-custom",
  "objects-deep-compare",
  "counterweight-stack",
  "json-portable-db",
  "google-sheets-wizard",
  "draw-axis-p5js",
];

async function fetchJson(url, headers = {}) {
  const res = await fetch(url, { headers: { "User-Agent": USER, ...headers } });
  if (!res.ok) return null;
  return res.json();
}

async function publicRepoStats() {
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
  const active = repos.filter((r) => !r.fork && !r.archived);
  const stars = active.reduce((sum, r) => sum + r.stargazers_count, 0);
  return { publicCount: active.length, stars };
}

async function npmDownloads() {
  let total = 0;
  for (const pkg of NPM_PACKAGES) {
    const data = await fetchJson(
      `https://api.npmjs.org/downloads/point/last-month/${pkg}`
    );
    if (data && typeof data.downloads === "number") total += data.downloads;
  }
  return total;
}

const [{ publicCount, stars }, downloads] = await Promise.all([
  publicRepoStats(),
  npmDownloads(),
]);

const block = `<!-- METRICS:START (auto, ver scripts/update-metrics.mjs; corre semanal via GitHub Actions) -->
- 🔓 **${publicCount} public repos** (+ private work in Rust, 3D and games, not counted here) · ⭐ **${stars.toLocaleString("en-US")} stars** across them
- 📦 **${downloads.toLocaleString("en-US")} npm downloads** in the last month across ${NPM_PACKAGES.length} packages
<!-- METRICS:END -->`;

const readmePath = new URL("../README.md", import.meta.url);
const readme = readFileSync(readmePath, "utf8");
const updated = readme.replace(
  /<!-- METRICS:START.*?METRICS:END -->/s,
  block
);

if (updated === readme) {
  console.error("No METRICS:START/METRICS:END markers found in README.md");
  process.exit(1);
}

writeFileSync(readmePath, updated);
console.log(`public repos: ${publicCount}, stars: ${stars}, npm downloads: ${downloads}`);
