# Claude Code Feature Flags — Reference completa

**Fecha**: 2026-04-03
**Fuentes**: Reverse engineering (3 repos) + source leak analysis (March 31, 2026) + docs oficiales

---

## Feature Flags Usables HOY

### Env vars que funcionan para usuarios externos

| Variable | Efecto | Verificado |
|----------|--------|------------|
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` | Habilita Agent Teams (Lead + hasta 4 teammates paralelos con worktree isolation). Requiere Opus. | Sí — única feature-flag major accesible |
| `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=80` | Override del threshold de auto-compactación (default ≈93.5% for 200K). Poner en 80 para trigger más temprano, dando más room a post-compact hooks | Sí |
| `CLAUDE_CODE_DISABLE_AUTOCOMPACT=1` | Desactiva compactación automática completamente | Sí |
| `CLAUDE_CODE_DISABLE_CLAUDE_MDS` | Desactiva ALL CLAUDE.md loading (debug) | Sí |
| `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS=5000` | Override SessionEnd hook timeout (default: 1500ms). Crítico para session-report.sh | Sí |
| `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1` | Desactiva experimental beta API headers. Usar con Bedrock/Vertex AI para evitar errores de compatibilidad | Sí |
| `CLAUDE_CODE_ENABLE_TELEMETRY=1` | Habilita OpenTelemetry trace/metric/log export | Sí |
| `CLAUDE_ENV_FILE` | Path a env file que se carga en evento `CwdChanged` | Sí |
| `ANTHROPIC_BASE_URL` | Override API base URL (proxy, gateway, compatible endpoints) | Sí |

### settings.json keys usables

| Key | Tipo | Efecto |
|-----|------|--------|
| `autoMemoryEnabled` | boolean | Habilita auto-memory (MEMORY.md). Default true |
| `claudeMdExcludes` | string[] | Glob patterns de CLAUDE.md files a excluir del loading. Toggle sin borrar |
| `env` | object | Key/value env vars seteadas para cada sesión. Evita wrapper scripts |
| `skipDangerousModePermissionPrompt` | boolean | Suprime el warning de `bypassPermissions`. Auto-set en primera aceptación |

### Additional settings.json keys

| Key | Type | Default | Impact |
|-----|------|---------|--------|
| `cleanupPeriodDays` | number | 30 | Transcript retention days. Set to 0 for no persistence (sensitive projects) |
| `effortLevel` | low/medium/high | (default) | Global thinking depth override |
| `worktree.symlinkDirectories` | string[] | — | Directories to symlink in Agent Team worktrees |
| `worktree.sparsePaths` | string[] | — | Sparse-checkout paths for large monorepos |
| `autoMode.allow/soft_deny` | string[] | — | Custom auto-mode classifier rules |
| `respectGitignore` | boolean | true | Set false to include gitignored files in search |

---

## Feature Flags Inaccesibles (Internal/Unshipped)

### Flags mayores (compilación/server-side)

| Flag | Qué controla | Por qué inaccesible |
|------|-------------|---------------------|
| **KAIROS** | Daemon 24/7 persistente. Systemd service, cron, acciones autónomas, GitHub webhooks, logs append-only. 150+ refs en source | Gated a `false` en external build |
| **COORDINATOR_MODE** | Orquestación multi-agente con workers paralelos y mailbox system. Prompt: "Do not rubber-stamp weak work" | Gated a `false` en external build |
| **ULTRAPLAN** | Planning remoto en cloud container con Opus por 30 min + browser UI | Gated a `false` en external build |
| **VOICE_MODE** | STT/TTS completo, streaming speech-to-text con keyword detection | Gated a `false` en external build |
| **VIM_MODE** | Layer de Vim keybindings: normal/insert/visual/command modes, motions, registers | Gated a `false` en external build |
| **UNDERCOVER** | Strip Anthropic attribution en repos externos (solo empleados) | `USER_TYPE === 'ant'` only |
| **ANTI_DISTILLATION_CC** | Inyecta fake tools en system prompt para prevenir distillation por competidores | GrowthBook server-side only |

### Flags parcialmente shipped

| Flag | Estado | Detalle |
|------|--------|---------|
| **autoDream** | Automático | Se ejecuta cuando `autoMemoryEnabled: true` + 24h gap + 5 sesiones + PID lock. 4 fases: orient → gather → consolidate → prune. No hay toggle directo |
| **BUDDY** | Shipped April 1, 2026 | Tamagotchi: 18 especies, 5 rarezas, gacha determinístico. Fue April Fools pero puede ser permanente |
| **BRIDGE_MODE** | Parcial | WebSocket CLI↔claude.ai. Requiere OAuth + GrowthBook gating |
| **SPECULATION** | Client listo, server OFF | `CLAUDE_CODE_ENABLE_PROMPT_SUGGESTION=1` existe pero el server flag `tengu_speculation` está OFF para externos. Tab=accept, Enter=accept+run |

---

## GrowthBook Remote Feature Gates (tengu_ prefix)

El sistema de feature flags remoto usa keys con patrón `tengu_<adjective>_<noun>`:

| Key | Qué gatean |
|-----|-----------|
| `tengu_amber_flint` | Agent Teams / Swarm capabilities |
| `tengu_anti_distill_fake_tool_injection` | Fake tool injection (anti-distillation) |
| `tengu_frond_boric` | Analytics sink killswitch |
| `tengu_attribution_header` | Attribution header killswitch |
| `tengu_speculation` | Speculative execution / prompt suggestions |
| ~25+ flags adicionales | Nombres codificados: `slate_heron`, `copper_bridge`, `coral_fern`, `timber_lark`, `surreal_dali`, `birch_trellis`, `bramble_lintel`, etc. |

**Refresh**: 6 horas para externos, 20 minutos para Anthropic internos.
`hasGrowthBookEnvOverride` permite override local pero solo para testing interno.

---

## Slash Commands Feature-Gated

| Comando | Qué hace | Gate |
|---------|----------|------|
| `/thinkback` | Replay del thinking del modelo en turnos anteriores | Unshipped (internal) |
| `/teleport` | Resume cross-machine de sesión | Unshipped (internal) |
| `/rewind` | Undo a un SessionCheckpoint nombrado | Unshipped (internal) |
| `/ctx_viz` | Visualización del context window (token budget, tier breakdown) | Unshipped (internal) |
| `/security-review` | Audit de seguridad interno | `USER_TYPE === 'ant'` only |
| `/compact` | Compactación manual con instrucciones custom | **Shipped, público** |
| `/stickers` | Sistema de stickers | Unshipped (internal) |
| `/passes` | Sistema de referrals | Unshipped (internal) |
| `/advisor` | AI advisor integration | Unshipped (internal) |
| `/good-claude` | Positive reinforcement con memory/knowledge dirs | Unshipped (internal) |

---

## Acciones para claude-kit

### Incorporar inmediatamente

1. **`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`** — documentar en `template/rules/agents.md` como alternativa a la orquestación manual. Agregar a `docs/best-practices.md`

2. **`CLAUDE_AUTOCOMPACT_PCT_OVERRIDE`** — usar en proyectos con hooks pesados de PostCompact. Set a 75-80 para dar más room al post-compact.sh. Documentar en `context-window-optimization.md`

3. **`CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS=5000`** — agregar al template como env var default para evitar que session-report.sh se mate a los 1.5s

4. **`claudeMdExcludes`** — documentar como mecanismo de toggle para stacks. Agregar a `/forge status` y `/forge audit`

5. **`env` key en settings.json** — usar para setear env vars de proyecto sin wrapper scripts. Agregar al template con CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS como ejemplo

6. **`/compact` con instrucciones custom** — documentar que acepta texto libre post-comando para guiar la compactación. Agregar ejemplos por stack

### Monitorear para futuro

7. **`tengu_speculation`** — cuando se active para externos, claude-kit debería documentar el patrón Tab/Enter y cómo las prompt suggestions interactúan con hooks

8. **COORDINATOR_MODE** — cuando ship, reemplaza nuestra orquestación manual de Agent Teams. Preparar stack `coordinator` con rules optimizadas

9. **KAIROS** — si ship, redefine session management. Nuestros hooks Stop/SessionEnd se vuelven menos relevantes; los hooks de cron toman protagonismo

10. **autoDream** — investigar si el output de `post-compact.sh` en formato específico puede alimentar el dream para consolidación más inteligente
