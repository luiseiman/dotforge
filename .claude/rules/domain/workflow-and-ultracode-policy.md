---
globs: "**/CLAUDE.md,**/.forge-manifest.json,**/registry/projects.yml,**/registry/projects.local.yml"
description: "When to default Workflow (tool) and Ultracode (mode) ON per project — tier policy across the 12-project portfolio"
domain: claude-code-engineering
last_verified: 2026-10-06
---

# Workflow & Ultracode Policy

Two orthogonal concepts. Do not conflate.

- **Workflow** = TOOL. Multi-agent orchestration via JS script (`/workflows`, v2.1.154+). Invoked per task when shape calls for fan-out, adversarial verify, or scripted multi-stage work. See `workflow-automation.md`.
- **Ultracode** = MODE. Standing opt-in posture: adversarial verify by default, workflow as first-reach orchestrator, plan-before-code enforced, structured output preferred. Configured **per project** (via tier in registry), not per task.

## 5 decision criteria (canonical — same set used by `/forge ultracode-check`)

| ID | Criterion | Fires when... |
|----|-----------|---------------|
| C1 | **Blast radius** | Task touches ≥3 files OR >200 LOC changed |
| C2 | **Domain risk** | Tier ≥ heavy, OR touches auth/payments/migrations/infra/schema/security |
| C3 | **Ambiguity** | ≥2 valid approaches with real tradeoffs (architecture, library choice, API contract) |
| C4 | **Reversibility** | Change is hard to undo (prod migration, force-push, schema drop, sent comms, live trade) |
| C5 | **Prior failure** | Sonnet attempted and failed, OR `CLAUDE_ERRORS.md` shows repeat in this area |

**Score mapping**: ≥3 fires → ON · 2 fires → CONSIDER · ≤1 → OFF. **Override to ON** if C2+C4 both fire regardless of total (irreversible touch on a risk surface).

## Tier classification (drives the default posture)

- **light**: experimental, no users, no money, no PII. Ultracode OFF; workflow only when explicitly useful.
- **standard**: dev tools, governance repos, prototypes. Ultracode OFF by default; workflow ON for refactors >3 files. Advisory verify only — never gates.
- **heavy**: complex infra, multi-stack, shared by team, or whose failures cascade. Ultracode ON for architecture/security tasks; workflow ON by default for multi-stage work. Soft-gate: High findings warn but do not block.
- **production**: real money, regulated data, live external users, or live downstream clients. Ultracode ON always; workflow ON; plan-mode enforced before edits; hard-gate: blocks merge on any High severity finding.

Default when `ultracode_tier` absent from registry: **standard**.

## Activation: tier (policy) → runtime

Tier is the project POSTURE (declared once in registry). Two independent per-session ACTIVATORS since v2.1.284: `/effort <level>` (reasoning depth) and `/effort ultracode on|off` (workflow-first orchestration). Before v2.1.284 `/effort ultracode` set both at once. Both must align with tier — tier alone does not enforce anything at runtime.

| Tier | Recommended runtime | Workflow trigger |
|------|--------------------|-----------------|
| `production` | `/effort xhigh` + `/effort ultracode on` mandatory at session start | Auto + adversarial verify on every substantive task |
| `heavy` | `/effort high` (default); `/effort xhigh` + ultracode on for architecture/security tasks | Auto for multi-stage; explicit `ultracode` keyword otherwise |
| `standard` | `/effort high` (default since v2.1.94), ultracode off | Only when explicitly requested (`ultracode` keyword or natural language) |
| `light` | `/effort medium` or `high`, ultracode off | Skip workflows |

`session-startup.sh` emits the tier in the startup brief. For tier `heavy` or `production`, treat the brief as a reminder to set effort + ultracode if not already on. `maxEffortLevel` (v2.1.267, user/managed scope) can cap `xhigh` — check `/status` if `/effort xhigh` is refused.

## Security boundary — workflow subagents bypass session permission mode

`production`-tier policy assumes plan-mode enforcement before irreversible edits. **This holds for direct main-thread actions but NOT for workflow-spawned subagents** — they always run in `acceptEdits` mode regardless of session mode. See `workflow-automation.md` § Permission model.

Implication: production-tier projects MUST rely on `permissions.deny` (kernel-enforced + permission-cascade) as the real backstop for irreversible touches. Plan mode alone is not sufficient if any workflow is active. Audit `permissions.deny` to cover: `.env*`, `**/*.key`, `**/*.pem`, `**/credentials*`, plus project-specific paths (`migrations/`, `infrastructure/terraform/`, schema files).

## Portfolio guidance (12 projects, authoritative 2026-06-02)

| Project | Tier | Justification |
|---------|------|---------------|
| TRADINGBOT | production | Real trades; money loss on bug |
| cotiza-api-cloud | production | WebSocket prod clients downstream; SLA users |
| SOMA | production | Oracle ARM VPS infra; Agent OS primary |
| InviSight-iOS | heavy | iOS app, Supabase prod tier, real users |
| jira-nbch | heavy | NBCH banking dashboard, regulatory |
| cds-dashboard | heavy | NBCH banking dashboard, Next.js 15 prod |
| openclaw | heavy | Cross-tool bridge — failures cascade to other projects |
| **dotforge** | **heavy** | **Governance meta — propagates to 12 projects via `/forge sync`; bad sync corrupts downstream. Treat as production for changes touching `template/hooks/`, `stacks/*/settings.json.partial`, or `global/`** |
| SOMA2 | standard | Dev branch, no traffic, no downstream clients |
| vault-bot | standard | Personal utility; git-backed Obsidian vault is recoverable |
| derup | standard | TS Vite ER modeler, single-user dev tool |
| crm | standard | Smaller CRM; promote to heavy if it stores real customer PII |

Promotion direction is **upward only**. A project that goes prod-quiet for a quarter does NOT auto-demote — production status is sticky; revisit only on retirement.

## Anti-patterns

- Treating Ultracode as a per-task flag — it's a project posture; flip via registry tier, not in-prompt
- Enabling Workflow tool everywhere "to be safe" — small tasks pay setup overhead with no fan-out benefit
- Promoting tier to production without also enabling plan-mode + block-destructive hook
- Demoting tier (production → heavy) after a quiet quarter — sticky upward
- Using `/workflows` as substitute for Agent Teams when teammates ≤4 and shape is known upfront — Teams is cheaper and declarative
