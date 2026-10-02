<!-- ALLOW_PUBLIC: documentación de ingeniería del repo (reglas de build y gates).
     No contiene estrategia de portfolio, panel de evaluación ni rutas privadas. -->

# CLAUDE.md

Instrucciones de este repo. Complementan las convenciones personales del autor: si algo choca,
manda este archivo para este repo.

**Qué es este repo:** el README de perfil de GitHub de `damiansire` (la landing pública) más
los gates de CI que lo custodian. No hay código de aplicación: el producto es el README y los
workflows que lo mantienen honesto.

## Estándar nivel mundial

La barra se hornea build-time, no se audita al final: lo que se escriba acá nace contra estas
reglas. Cada regla dice de dónde sale: de la documentación de un proyecto open source de
referencia (con su enlace) o de un criterio propio del autor. Nada de reglas inventadas sin fuente.

**Alcance de la barra para este repo (honesto):** acá no hay stack de aplicación (no hay Angular,
React, Rust, TypeScript ni Node de aplicación). Lo que aplica es la barra **transversal** de
arquitectura: el piso de Craft (a-j), la legibilidad en frío (k-m) y el techo de Craft, más abajo.
No hay todavía una guía de referencia propia para "Markdown + GitHub Actions", así que la sección
de reglas enforzables deriva de la barra transversal aplicada a este stack, y está marcada como
tal. Si aparece una guía de ese stack, esa sección se reemplaza por ella.

### Piso de Craft (a-j)

Determinista: cada ítem se marca `ok` / `violated` con `file:line`.
Fuente: criterio propio del autor, la regla de la intención clara (el código se explica solo, sin
preguntar ni ejecutarlo). Los proyectos que llevan estos ítems al extremo se citan más abajo.

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

Fuente: criterio propio del autor, con evidencia en la documentación pública de proyectos de
referencia: [SQLite, Distinctive Features](https://sqlite.org/different.html) (el alcance se
declara por negación), [ripgrep](https://github.com/BurntSushi/ripgrep) y la
[nota de su autor sobre el diseño y los benchmarks](https://burntsushi.net/ripgrep/) (pruebas
reproducibles y framing honesto), y la guía de GitHub sobre
[READMEs](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes).

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

Fuente: criterio propio del autor, con evidencia en la documentación pública de
[LLVM](https://llvm.org/docs/CodingStandards.html),
[Kubernetes](https://github.com/kubernetes/kubernetes/blob/master/staging/publishing/import-restrictions.yaml)
y [SQLite](https://sqlite.org/testing.html). Idea rectora de esa lectura: los repos de referencia
convierten la calidad en **hecho machine-enforced**, no en convención. El techo no es "más
prolijo", es "imposible de violar sin que algo falle ruidoso".

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

Derivadas de la barra transversal aplicada a este stack, no de una guía propia del stack (ver
"Alcance de la barra" arriba). Cada una es chequeable.

1. **Un gate que no gatea no es un gate, es un comentario.** Nada de `|| true` neutralizando el
   `set -e` de un chequeo que se vende como bloqueante, ni de pasos que reportan OK cuando el
   comando de abajo falló. `set -euo pipefail`, y separar "el comando falló" de "no hubo matches".
   (fuente: [promptfoo-action](https://github.com/promptfoo/promptfoo-action) distingue el modo
   suave, que solo postea un comentario en el PR y no falla el check, del modo duro con umbral
   que sale con error. Lo que se vende como gate de calidad tiene que ser el segundo).
2. **El gate se ejercita en su dirección de falla.** Todo chequeo nuevo viene con un caso fixture
   que DEBE hacerlo salir 1. (fuente: la
   [estrategia de testing de SQLite](https://sqlite.org/testing.html): un VFS de crash que simula
   escrituras incompletas y un VFS de journal-test. El recovery se ejercita, no se asume).
3. **Default-deny en permisos.** `permissions:` explícito y mínimo en cada workflow; los
   allowlists de herramientas enumeran comandos concretos, nunca comodines que cubran verbos
   mutantes de una API. (fuente: ítem j del piso de Craft y el fail-closed de sistemas de authz
   independientes: la
   [autorización de Kubernetes](https://kubernetes.io/docs/reference/access-authn-authz/authorization/),
   la [keyword `default` de OPA/Rego](https://www.openpolicyagent.org/docs/policy-reference/keywords/default)
   y el [RBAC de Envoy](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/rbac/v3/rbac.proto)).
4. **Presupuesto de tiempo y reintentos acotados en todo job.** `timeout-minutes` en cada job y
   reintentos con tope en toda llamada de red del CI. (fuente: ítem i del piso de Craft y
   [exponential backoff and jitter](https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/)
   de AWS: cap exponencial finito, jitter obligatorio, stop por presupuesto de tiempo).
5. **Acciones de terceros pinneadas a una referencia durable.** Un `@vN` móvil que además recibe
   `GITHUB_TOKEN` es superficie de supply-chain sin control de versión. (criterio propio del
   autor: los workflows de este repo pinnean cada acción a un SHA y dejan el tag en un comentario).
6. **Todo gate declarado corre en local antes de pushear.** `pnpm install` y `pnpm lint` corren
   el mismo chequeo que CI sin esperar al runner. Un gate que solo existe en el runner convierte
   cada typo en un ciclo de 90 segundos.
7. **Un dato, un lugar.** Ninguna cifra ni handle se escribe dos veces en el README. (fuente:
   ítem d del piso de Craft: lógica duplicada que puede divergir).
8. **Convenciones del autor (no salen de ninguna fuente externa, son preferencias propias):** sin
   raya larga (em dash) en ningún texto; conventional commits en español; nada de `git push` ni
   releases sin pedido explícito.

### Documentación

El README de este repo ES el producto, así que estas cláusulas son gate, no cosmética.

- **El README nombra al proyecto igual que el manifest.** El nombre y la descripción declarados
  (`package.json`, description y topics del repo en GitHub) dicen lo mismo que el README. Hay
  chequeo ejecutable de coherencia doc-manifest y tiene que quedar verde. (fuente: ítem k de la
  legibilidad en frío: el nombre y la descripción dicen lo que el contenido es de verdad).
- **No se linkea a archivos ni secciones que no existen.** Ni links rotos (lo cubre `Link Check`)
  ni referencias a contenido borrado. Vale también para los comentarios de config: si un
  comentario justifica una excepción por contenido que ya no está, se borra o se actualiza en el
  mismo commit. (fuente: ítem b del piso de Craft: el comentario explica POR QUÉ y ese porqué
  tiene que ser cierto).
- **No es un molde reciclado.** Nada de secciones de plantilla que no describan este repo, ni
  texto genérico de perfil. Cada línea del README tiene que ser falsable. (fuente: la guía de
  GitHub sobre [READMEs](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes),
  el README como entry-point con un statement honesto del problema, y la
  [nota del autor de ripgrep](https://burntsushi.net/ripgrep/), donde el framing honesto genera
  confianza: reconoce el sesgo propio y reporta hasta el benchmark que pierde).
- **Todo `.md` nuevo entra al glob de `pnpm lint` y al workflow.** Si un archivo no está en el
  glob, el gate no lo cubre y la regla vuelve a ser convención.

### Cómo se corre la barra en local

```bash
pnpm install       # una vez
pnpm lint          # markdownlint-cli2 con .markdownlint-cli2.yaml, el mismo chequeo que CI
pnpm hygiene       # gate de higiene: nombres, contenido e historial
pnpm hygiene:test  # self-test del gate de higiene (direccion de falla)
pnpm doc           # coherencia doc-manifest (handle, description, scripts prometidos)
pnpm doc:test      # self-test del chequeo doc-manifest
```

El link-check corre con `lychee` en CI. Si se quiere en local, hace falta el binario de `lychee`
instalado: no se agrega como dependencia npm para no fingir que está pinneado.
