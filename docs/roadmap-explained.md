# Roadmap Explicado — claude-kit

> ⚠️ **Archivo histórico.** Este documento explica las decisiones de diseño de versiones anteriores (v1.x–v2.4.x). Ya no refleja el estado actual del proyecto.
> Para el roadmap activo, ver [ROADMAP.md](../ROADMAP.md).
> Para el historial de cambios, ver [changelog.md](changelog.md).

---

> _Archivo original — explicación detallada y coloquial de cada punto del roadmap durante el desarrollo inicial._
> _Preservado como contexto de decisiones arquitectónicas._

---

## v1.2.3 — Hardening & Quick Wins

### 1. Detección de prompt injection en audit

**El problema:** Hoy el audit revisa que tus rules *existan* y tengan globs, pero no mira *qué dicen adentro*. Si alguien (o vos mismo sin querer) mete en una rule algo como "ignore todas las instrucciones anteriores" o código en base64 escondido, Claude lo va a obedecer ciegamente. Es como tener una alarma en la puerta pero no revisar si alguien ya está adentro.

**El beneficio:** El audit va a escanear el contenido de tus rules y CLAUDE.md buscando patrones peligrosos. Si encuentra algo raro, te avisa y te baja el score. Básicamente es un antivirus para tu configuración de Claude — te protege de que instrucciones maliciosas se cuelen en tus archivos de reglas, ya sea por un copy-paste descuidado, por un PR de alguien más, o por un ataque deliberado.

---

### 2. Hook profiles (minimal / standard / strict)

**El problema:** Hoy el hook `block-destructive` tiene una lista fija de 8 comandos peligrosos que bloquea. Para un proyecto personal chiquito eso puede ser molesto (te bloquea cosas que sabés que son seguras). Para un proyecto de producción crítico, puede ser insuficiente (hay comandos peligrosos que no cubre).

**El beneficio:** Vos elegís cuánto te cuida Claude según el contexto. ¿Estás hackeando un side project un sábado? Ponés `minimal` y solo te frena si intentás borrar todo el disco o force push a main. ¿Estás en el repo de producción que maneja plata? Ponés `strict` y Claude también te frena si intentás hacer `curl | sh` (ejecutar scripts random de internet), `eval` (ejecución dinámica peligrosa), o cambiar permisos a 777. Es como tener un cinturón de seguridad ajustable: apretado cuando importa, cómodo cuando no.

---

### 3. Clasificación de errores en CLAUDE_ERRORS.md

**El problema:** Hoy cuando registrás un error en CLAUDE_ERRORS.md, tenés las columnas Date, Area, Error, Cause, Fix, Rule. Pero no sabés *qué tipo* de error es. Entonces cuando querés ver "¿cuántos bugs de seguridad tuve este mes?" o "¿mis errores son más de lógica o de configuración?", tenés que leer cada entrada y clasificarla mentalmente.

**El beneficio:** Agregando la columna `Type` (syntax, logic, integration, config, security), podés filtrar y detectar patrones rápido. Si ves que el 70% de tus errores son de tipo `integration`, sabés que tu problema es cómo conectás servicios, no la lógica en sí. Si ves varios `security`, es una señal de alarma. También permite que el audit detecte automáticamente cuándo un mismo tipo de error se repite 3+ veces y lo promueva a regla — en vez de seguir tropezando con la misma piedra.

---

### 4. Git worktree en Agent Teams

**El problema:** Cuando Agent Teams trabaja (varios agentes en paralelo tocando código), todos trabajan sobre los mismos archivos del mismo branch. Si el agente A edita `utils.py` y el agente B también, se pisan. Es como dos albañiles trabajando en la misma pared al mismo tiempo sin coordinarse.

**El beneficio:** Con git worktree, cada agente trabaja en su propia copia aislada del repo. El agente A edita su copia, el agente B la suya, y al final se mergean los cambios. Esto hace que Agent Teams sea realmente paralelo y seguro. Hoy es más teórico que práctico porque el riesgo de conflicto lo limita. Con worktree, podés mandar 3 agentes a trabajar en 3 componentes distintos al mismo tiempo sin preocuparte.

---

### 5. TDD warning hook

**El problema:** La regla "funcionalidad nueva necesita test" está escrita en `_common.md`, pero es solo texto. Claude la lee y la mayoría de las veces la respeta, pero a veces se le olvida, especialmente en sesiones largas o después de compactación de contexto. No hay nada que lo frene si crea un archivo nuevo en `src/` sin hacer el test correspondiente.

**El beneficio:** Es un recordatorio automático, no un bloqueo. Cuando Claude crea un archivo nuevo en `src/` y no hay test para ese archivo, el hook le dice "ey, te falta el test". No lo frena (exit 0, no exit 2), pero lo hace consciente. Es como ese compañero de trabajo que te dice "¿le pusiste test a eso?" antes de que hagas el PR. Solo se activa en profile `strict` para no molestar en proyectos donde no aplica.

---

## v1.3.0 — Stack Expansion & Cross-Tool

### 6. Cuatro stacks nuevos (node-express, java-spring, aws-deploy, go-api)

**El problema:** Hoy claude-kit soporta 8 stacks: python-fastapi, react-vite-ts, swift-swiftui, supabase, docker-deploy, data-analysis, gcp-cloud-run, redis. Si tu proyecto es en Node con Express, Java con Spring Boot, Go, o usa AWS, el bootstrap no detecta tu stack y no te genera rules ni permisos específicos. Te queda una configuración genérica.

**El beneficio:** Con estos 4 stacks nuevos, cubrís la mayoría de backends web del mercado. Si trabajás con Express, el bootstrap te genera rules de Node (no usar `var`, preferir async/await, estructura de middleware). Si trabajás con Spring Boot, te genera rules de Java (inyección de dependencias, patrones de repository). Para AWS, reglas de CloudFormation y permisos de CLI. Para Go, convenciones de error handling y estructura de paquetes. En lugar de una config genérica, tenés una que entiende tu tecnología.

---

### 7. Cross-tool export (`/forge export cursor|codex|windsurf`)

**El problema:** Todo el trabajo que hacés configurando claude-kit (rules, convenciones, permisos) solo funciona en Claude Code. Si mañana probás Cursor, Windsurf, o Codex, tenés que reescribir todo desde cero en el formato de cada herramienta. Tu inversión en configuración está atrapada en un solo tool.

**El beneficio:** Con `/forge export cursor` tomás todas tus rules y CLAUDE.md y generás un `.cursorrules` listo para usar. Lo mismo con Codex y Windsurf. Tu configuración se vuelve portable. Esto es valioso en dos sentidos: (1) si cambiás de herramienta no perdés nada, y (2) si trabajás en un equipo donde otros usan Cursor, podés compartirles una versión traducida de tus mismas reglas. El trabajo de configuración lo hacés una vez, lo usás en todos lados.

---

### 8. Bootstrap profiles (minimal / standard / full)

**El problema:** Hoy `/forge bootstrap` te genera todo: CLAUDE.md, settings.json, hooks, rules, commands, agents, agent-memory, CLAUDE_ERRORS.md. Para un script de 200 líneas que escribís en una tarde, eso es overkill — no necesitás 6 agentes ni memoria de proyecto. Pero para un monorepo enterprise, el setup estándar puede quedarse corto.

**El beneficio:** Elegís la complejidad que necesitás. `minimal` te da solo lo esencial: un CLAUDE.md, settings.json con deny list, y el hook de seguridad. Perfecto para proyectos chicos o scripts. `standard` es lo de hoy. `full` te instala absolutamente todo incluyendo todos los agents, todos los commands, y un CLAUDE_ERRORS.md pre-configurado. El audit entiende tu profile y no te penaliza por no tener agents en un proyecto `minimal`. Es como elegir entre un departamento de un ambiente, uno de tres, o una casa — según lo que necesitás.

---

### 9. Project tier en audit

**El problema:** El audit trata a todos los proyectos igual. Un script de bash de 50 líneas y un monorepo de 100K líneas reciben las mismas 11 preguntas. El script va a sacar 5/10 porque no tiene agents, commands custom, ni memory — pero *no los necesita*. El monorepo puede sacar 8/10 pero debería tener un estándar más alto.

**El beneficio:** El audit detecta automáticamente si tu proyecto es `simple`, `standard`, o `complex` basado en líneas de código, cantidad de stacks, y estructura. Para un proyecto simple, los items recomendados se relajan (no necesitás agents ni memory). Para uno complejo, los recomendados pasan a ser obligatorios (sí necesitás agents si tenés 100K LOC). El score se vuelve significativo: un 9/10 en un proyecto complex realmente significa algo, y un 8/10 en uno simple no te frustra artificialmente.

---

### 10. Stack devcontainer

**El problema:** Claude Code corre directamente en tu máquina con acceso a todo. Los hooks y deny lists ayudan, pero si algo se escapa, Claude tiene acceso al sistema operativo, a tus archivos personales, a tu red. No hay aislamiento real.

**El beneficio:** Con el stack devcontainer, el bootstrap te genera un `.devcontainer/devcontainer.json` que configura un container aislado donde Claude trabaja. Dentro del container, Claude tiene acceso a tu código pero no a tus archivos personales, no a tus credenciales del sistema, no a tu red local. Es como ponerle a Claude su propia oficina separada en vez de dejarlo trabajar en tu escritorio. Especialmente útil si trabajás con código de terceros o proyectos que no confiás al 100%.

---

## v1.4.0 — Distribution & Plugin

### 11. Plugin packaging para marketplace

**El problema:** Hoy para instalar claude-kit tenés que clonar el repo, correr `global/sync.sh`, y mantenerlo actualizado manualmente. Si querés que un compañero lo use, tiene que hacer lo mismo. Es artesanal.

**El beneficio:** Empaquetando claude-kit como plugin oficial, cualquiera puede instalarlo con un comando (`/plugin install claude-kit`). Las actualizaciones llegarían automáticamente. Aparecería en el marketplace donde otros devs lo descubren sin que vos se lo tengas que mostrar. Es la diferencia entre repartir tu app como un .zip por WhatsApp vs publicarla en la App Store.

---

### 12. Stacks como plugins independientes

**El problema:** Si alguien solo quiere las rules de Python/FastAPI, tiene que instalar todo claude-kit (9 skills, 6 agents, 8 stacks, el sistema de auditoría completo). Es todo o nada.

**El beneficio:** Cada stack se vuelve un plugin independiente que podés instalar por separado. ¿Solo trabajás con React? Instalás `claude-kit-stack-react-vite-ts` y listo — te llegan las rules de React, los permisos de npm/vite, y el hook de lint de TypeScript. Sin la auditoría, sin los agents, sin el sistema de prácticas. Adopción granular: la gente puede empezar con un stack y después, si le gusta, instalar el kit completo.

---

## v1.5.0 — Intelligence & Analytics

### 13. `/forge insights` — análisis de sesiones

**El problema:** Después de semanas usando Claude Code no tenés idea de cómo lo estás usando. ¿Qué herramientas usa más? ¿Qué archivos toca más? ¿Dónde pierde más tiempo? ¿Qué errores se repiten? No hay forma de aprender de tus sesiones pasadas.

**El beneficio:** `/forge insights` analiza tu historial de sesiones y te dice cosas como: "El 40% de tus sesiones tocan `auth.py` — considerá refactorearlo", o "Tus errores más comunes son de integración con la API de pagos", o "Claude usa Grep 3x más que Read — tus archivos podrían estar mejor organizados". Esos insights alimentan automáticamente el pipeline de prácticas: si detecta un patrón repetido, crea una práctica en inbox para que la evalúes. Es como tener un coach que mira cómo trabajás y te sugiere mejoras.

---

### 14. Session report en Stop hook

**El problema:** Cuando terminás una sesión con Claude, desaparece. No queda registro de qué se hizo, qué archivos se tocaron, qué tests se corrieron, qué errores aparecieron. Si alguien te pregunta "¿qué hiciste hoy con Claude?", tenés que recordar de memoria.

**El beneficio:** Al terminar cada sesión, se genera automáticamente un `SESSION_REPORT.md` con un resumen: archivos tocados, commits hechos, tests corridos (y si pasaron), errores encontrados. Es un log de actividad que te sirve para documentar tu trabajo, para reportar a un equipo, o simplemente para retomar al día siguiente desde donde quedaste. Todo en markdown, nada fancy — un archivo de texto que podés leer, versionar, o ignorar.

---

### 15. Scoring trends y alertas

**El problema:** El registry ya guarda el historial de scores de cada proyecto, pero nadie lo mira. Tenés datos de que tu proyecto pasó de 8.5 a 7.0 a 6.5 en tres audits, pero no hay nada que te avise que estás empeorando.

**El beneficio:** Tres cosas concretas. Primero, si tu score baja más de 1.5 puntos entre dos audits, te salta una alerta: "ojo, tu proyecto se está degradando". Segundo, `/forge status` te muestra un sparkline en ASCII (una mini-gráfica en la terminal) de cómo evolucionó el score de cada proyecto. Tercero, si tu score está abajo de 7.0 y hay una versión nueva de claude-kit disponible, te recomienda correr `/forge sync` porque probablemente las mejoras nuevas te suban el score. Es pasar de "datos que se acumulan" a "datos que te hablan".

---

## Backlog (sin versión asignada)

### MCP server templates
Plantillas pre-armadas para conectar Claude con GitHub, Slack, bases de datos, etc. via MCP. Hoy si querés conectar un MCP lo tenés que configurar a mano. Con templates sería: "quiero GitHub" → configuración lista.

### Team mode
Configuración en capas: base (company) → team → individual. Cada nivel hereda del anterior y puede sobreescribir. Útil si claude-kit lo usan 10 personas y querés consistencia sin quitar flexibilidad individual.

### CI integration
Un GitHub Action que corre `/forge audit` automáticamente en cada PR y comenta el score. Así nadie mergea un PR que degrade la configuración de Claude. Quality gate automático.

### Stack auto-update
Si cambiás tus dependencias (agregás React a un proyecto Python), claude-kit detecta el cambio y te sugiere agregar el stack correspondiente. Hoy solo detecta stacks en bootstrap, después se olvida.

### Model routing rules
Reglas para cuándo usar cada modelo. El test-runner ya usa Sonnet (más rápido y barato para correr tests). Generalizar eso: researcher con Haiku para búsquedas rápidas, implementer con Opus para código complejo, etc.

---

## Descartados (y por qué)

| Idea | Razón |
|------|-------|
| npm/npx distribution | Requiere app code, rompe la filosofía md+shell |
| Web UI / dashboard | Fuera de scope, somos terminal-native |
| Model routing automático | Over-engineering para una config factory |
| 500+ skills at scale | Calidad > cantidad. 9 skills focalizados es suficiente |
| Real-time analytics | Requiere proceso daemon, contradice "no app code" |
