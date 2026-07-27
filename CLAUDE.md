<!-- ALLOW_PUBLIC: documentación de ingeniería del repo (reglas de build y gates).
     No contiene estrategia de portfolio, panel de evaluación ni rutas privadas. -->

# CLAUDE.md

Instrucciones de este repo. Complementan el `CLAUDE.md` global del autor: si algo choca,
manda este archivo para este repo.

**Qué es este repo:** el README de perfil de GitHub de `damiansire` (la landing pública) más
los gates de CI que lo custodian. No hay código de aplicación: el producto es el README y los
workflows que lo mantienen honesto.

## Estándar nivel mundial

La barra se hornea build-time, no se audita al final: lo que se escriba acá nace contra estas
reglas. Fuente única de verdad: el corpus de referencias del autor (`$TOOLS/refs/`). Cada regla
cita la nota de la que sale. Nada de reglas inventadas fuera del corpus.

**Alcance del corpus para este repo (honesto):** el mapeo de stacks no detecta ningún stack
conocido acá (no hay Angular, React, Rust, TypeScript ni Node de aplicación). Lo que aplica es la
barra **transversal** `architecture` del manifest: `architecture/fellow-standard.md` y las notas
`architecture/from-consensus-*`. No existe todavía una nota `from-*` de stack para "Markdown +
GitHub Actions", así que la sección de reglas enforzables deriva de la barra transversal aplicada
a este stack, y está marcada como tal. Si el corpus incorpora ese stack, esa sección se reemplaza
por la nota real.

### Piso de Craft (a-j)

Determinista: cada ítem se marca `ok` / `violated` con `file:line`.
Fuente: `architecture/fellow-standard.md`.

- **a. El nombre revela la intención de dominio, no el mecanismo.** Acá: el nombre de un job,
  step o workflow dice qué garantiza, no cómo lo implementa. Un gate llamado `Hygiene Gate`
  tiene que higienizar todo lo que ese nombre promete.
- **b. Los comentarios explican POR QUÉ, nunca QUÉ.** Acá muerde fuerte: un comentario de config
  que describe contenido que ya no existe es peor que no tener comentario. Si se saca contenido
  del README, se revisa en el mismo commit el comentario que lo justificaba.
- **c. Superficie pública autodocumentada.** La superficie pública de este repo es el README y
  los workflows (que son código copiable): se entiende qué hacen sin abrir el runner.
- **d. Impacto mínimo al cambiar el core.** Un dato (una cifra, un link, un handle) se escribe
  en UN solo lugar. Duplicarlo garantiza drift.
- **e. Features borrables sin cirugía.** Cada workflow es autocontenido: borrarlo no deja
  referencias colgadas en configs ni en el README.
- **f. Flujo de datos inmutable y rastreable.** Los números y claims del README se derivan de una
  fuente verificable o no se afirman. Sin cifras a mano sin nada que las mantenga vivas.
- **g. Consistencia ante excepción.** Si un step falla a mitad, no deja el repo ni el reporte en
  un estado ambiguo: o falla ruidoso o no falla.
- **h. Los boundaries comunican lo que pasa.** El boundary de este repo es el CI: un fallo tiene
  que ser visible sin entrar a la pestaña Actions (badge de estado, o un canal explícito).
- **i. Límites explícitos: timeouts, reintentos acotados.** Todo job declara `timeout-minutes`;
  toda llamada de red del CI (link-check contra hosts de terceros) declara reintentos y
  exclusiones, para que el rojo signifique "link roto" y no "rate limit".
- **j. Fail-closed donde importa.** Los allowlists de permisos (`permissions:` de cada workflow,
  allowlist de herramientas del agente) enumeran lo mínimo y deniegan por defecto. Sin comodines
  que abarquen verbos mutantes.

### Legibilidad en frío (k-m)

Fuente: `architecture/fellow-standard.md` (cluster k-m), evidencia en
`architecture/from-consensus-2026-07-09.md`.

- **k. El README lidera con prueba visible y framing honesto.** El README es la UI de este repo.
  Statement claro de qué-es y para-quién en el primer screenful, y la prueba visible acá es
  **rutear al trabajo**: un perfil que dice "I build in public" y no enlaza ni un repo queda
  sub-descripto, que es justo el modo de falla que este cluster ataca (no inflar es la mitad, la
  otra es no enterrar buen trabajo).
- **l. Donde prometés robustez o performance, la prueba está y es reproducible.** Sensible al
  arquetipo: acá no se pide tabla de benchmarks, se pide que toda afirmación numérica sea
  verificable de un click o esté gateada. Claim sin test es lo que este ítem prohíbe.
- **m. Framing honesto: reconocés el sesgo propio y el límite del claim.** Se etiqueta el
  contexto del claim (idioma del contenido, si un proyecto es privado, de cuándo es una cifra).
  Anunciar trabajo inverificable sin decir que es privado se lee como relleno.

### Techo de Craft

Fuente: `architecture/fellow-standard.md` (sección "Techo de Craft"), evidencia en
`architecture/from-consensus-craft-techo-2026-07-09.md`. Idea rectora del saqueo: los repos de
referencia convierten la calidad en **hecho machine-enforced**, no en convención. El techo no es
"más prolijo", es "imposible de violar sin que algo falle ruidoso".

Traducido a este repo:

- **Nombres y superficie:** el nombre del gate y lo que el gate enforcea son la misma cosa,
  verificable leyendo el step (LLVM: gramática de nombres enforced, un solo contrato de boundary).
- **Encapsulamiento como hecho de CI:** la regla de higiene no vive en el hábito, vive en un
  chequeo default-deny que corre solo (Kubernetes `import-boss`: allowlist chequeada en CI, no
  convención escrita).
- **Integridad de estado, invariante ejercitado:** un gate se prueba en su **dirección de falla**.
  SQLite no asume que su recovery anda: lo ejercita con un VFS que simula crashes. Acá el
  equivalente barato es un self-test del gate (un fixture que DEBE hacerlo fallar); si el
  self-test pasa a verde, el gate está roto.
- **Observabilidad:** contexto capturado en el ORIGEN, no reconstruido después. El rojo del cron
  semanal tiene que llegar a alguien, no morir en un mail ignorado.
- **Resiliencia:** presupuesto de tiempo explícito y finito (`timeout-minutes`), reintentos con
  tope y jitter para las llamadas de red.
- **Fail-closed:** la rama sin match de toda decisión de permisos DENIEGA (Kubernetes RBAC
  `DecisionNoOpinion`, Rego `default allow := false`, Envoy `action: ALLOW` como safe-list).

### Reglas enforzables del stack (Markdown + GitHub Actions)

Derivadas de la barra transversal aplicada a este stack, no de una nota `from-*` propia (ver
"Alcance del corpus" arriba). Cada una es chequeable.

1. **Un gate que no gatea no es un gate, es un comentario.** Nada de `|| true` neutralizando el
   `set -e` de un chequeo que se vende como bloqueante, ni de pasos que reportan OK cuando el
   comando de abajo falló. `set -euo pipefail`, y separar "el comando falló" de "no hubo matches".
   (fuente: `architecture/from-consensus-eval-infra-2026-07-17.md`, divergencia D3 soft vs hard
   gate: "un eval que se vende como gate de calidad y corre soft-por-default (`|| true`) NO es un
   gate, es un comentario").
2. **El gate se ejercita en su dirección de falla.** Todo chequeo nuevo viene con un caso fixture
   que DEBE hacerlo salir 1. (fuente: `architecture/fellow-standard.md`, techo de los ítems f-g:
   SQLite VFS de crash y journal-test, se ejercita, no se asume).
3. **Default-deny en permisos.** `permissions:` explícito y mínimo en cada workflow; los
   allowlists de herramientas enumeran comandos concretos, nunca comodines que cubran verbos
   mutantes de una API. (fuente: `architecture/fellow-standard.md` ítem j +
   `architecture/from-consensus-resiliencia-2026-07-09.md`, fail-closed confirmado 3-0 en cuatro
   sistemas de authz independientes).
4. **Presupuesto de tiempo y reintentos acotados en todo job.** `timeout-minutes` en cada job y
   reintentos con tope en toda llamada de red del CI. (fuente: `architecture/fellow-standard.md`
   ítem i + `architecture/from-consensus-resiliencia-2026-07-09.md`: cap exponencial finito,
   jitter obligatorio, stop por presupuesto de tiempo).
5. **Acciones de terceros pinneadas a una referencia durable.** Un `@vN` móvil que además recibe
   `GITHUB_TOKEN` es superficie de supply-chain sin control de versión. (fuente:
   `architecture/from-consensus-resiliencia-2026-07-09.md`, caveat de durabilidad: "para un lint
   durable, pinnear a un tag de release").
6. **Todo gate declarado corre en local antes de pushear.** `pnpm install` y `pnpm lint` corren
   el mismo chequeo que CI sin esperar al runner. Un gate que solo existe en el runner convierte
   cada typo en un ciclo de 90 segundos.
7. **Un dato, un lugar.** Ninguna cifra ni handle se escribe dos veces en el README. (fuente:
   `architecture/fellow-standard.md` ítem d: lógica duplicada que puede divergir).
8. **Convenciones del autor (no salen del corpus, salen del `CLAUDE.md` global):** sin raya larga
   (em dash) en ningún texto; conventional commits en español; nada de `git push` ni releases sin
   pedido explícito.

### Documentación

El README de este repo ES el producto, así que estas cláusulas son gate, no cosmética.

- **El README nombra al proyecto igual que el manifest.** El nombre y la descripción declarados
  (`package.json`, description y topics del repo en GitHub) dicen lo mismo que el README. Hay
  chequeo ejecutable de coherencia doc-manifest y tiene que quedar verde. (fuente:
  `architecture/fellow-standard.md` ítem k, "nombre y descripción = el contenido real").
- **No se linkea a archivos ni secciones que no existen.** Ni links rotos (lo cubre `Link Check`)
  ni referencias a contenido borrado. Vale también para los comentarios de config: si un
  comentario justifica una excepción por contenido que ya no está, se borra o se actualiza en el
  mismo commit. (fuente: `architecture/fellow-standard.md` ítem b, el comentario explica POR QUÉ
  y ese porqué tiene que ser cierto).
- **No es un molde reciclado.** Nada de secciones de plantilla que no describan este repo, ni
  texto genérico de perfil. Cada línea del README tiene que ser falsable. (fuente:
  `architecture/from-consensus-2026-07-09.md`: README como entry-point con statement honesto del
  problema, y framing honesto como generador de confianza).
- **Todo `.md` nuevo entra al glob de `pnpm lint` y al workflow.** Si un archivo no está en el
  glob, el gate no lo cubre y la regla vuelve a ser convención.

### Cómo se corre la barra en local

```bash
pnpm install       # una vez
pnpm lint          # markdownlint-cli2 con .markdownlint-cli2.yaml, el mismo chequeo que CI
```

El link-check corre con `lychee` en CI. Si se quiere en local, hace falta el binario de `lychee`
instalado: no se agrega como dependencia npm para no fingir que está pinneado.
