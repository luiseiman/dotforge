# Distribution Material — dotforge v2.9.0

## Discord Posts

### Post 1: #agent-skills (Day 1)

**Title idea:** Configuration governance — not another skill collection

```
I built dotforge — a configuration governance system for Claude Code.

It's not a skills collection or a CLAUDE.md generator. It's the layer that manages your .claude/ directory across projects: bootstrap, audit (0-10 score), sync, and a practices pipeline that propagates discoveries.

I use it across 12 projects. One went from 4.4 to 9.1 after applying the audit recommendations. Security-critical items (missing settings.json or block-destructive hook) cap your score at 6.0 — no matter how many optional items you have.

What makes it different:
• Cross-project registry with audit history and trending
• Practices pipeline: inbox → evaluating → active → deprecated
• Template sync that preserves your customizations (forge:section markers)
• 15 auto-detected tech stacks layered additively
• Zero dependencies — markdown + shell scripts only

Works alongside claude-skills, gstack, or any other tools you already use. dotforge manages the config around them.

curl -fsSL https://raw.githubusercontent.com/luiseiman/dotforge/main/install.sh | bash

GitHub: https://github.com/luiseiman/dotforge
```

---

### Post 2: #claude-code (Day 3)

**Title idea:** How I manage .claude/ across 12 projects with zero deps

```
Managing .claude/ manually across multiple projects gets messy fast. Different deny lists, missing hooks, inconsistent rules. I built dotforge to solve this.

The core loop:
  bootstrap → audit → sync → capture → propagate

/forge init auto-detects your stack (15 supported) and generates the full .claude/ setup. /forge audit scores it 0-10 with a 12-item checklist. /forge sync updates without destroying your customizations. /forge capture records discoveries that propagate to other projects.

Real numbers from my registry:
• 12 projects managed
• Average score: 9.8/10
• Lowest improved from 4.4 → 9.1
• 28 practices in the pipeline (8 active, 9 deprecated)

Also exports to other editors:
/forge export cursor → .cursorrules
/forge export codex → AGENTS.md
/forge export windsurf → .windsurfrules

https://github.com/luiseiman/dotforge
```

---

### Post 3: #built-with-claude (Day 6)

```
dotforge — configuration governance for Claude Code

Built entirely with Claude Code (the project itself scores 10.0/10 on its own audit system).

Demo: /forge audit scores your .claude/ config on a 12-item checklist. Missing settings.json or block-destructive hook? Capped at 6.0.

Demo: /forge status shows all managed projects with scores, trends, and alerts.

15 auto-detected stacks • 7 specialized agents • practices pipeline • zero dependencies

https://github.com/luiseiman/dotforge
```

---

## Awesome-List PRs

### PR 1: awesome-claude-code (hesreallyhim, 36.6K stars)

**Category:** Configuration Management (or Tools & Utilities)

**Entry to add:**
```markdown
- [dotforge](https://github.com/luiseiman/dotforge) - Configuration governance for Claude Code. Bootstrap, audit (0-10 score), sync, and evolve .claude/ across projects with 15 auto-detected stacks, practices pipeline, and cross-project registry. Zero dependencies.
```

**PR title:** Add dotforge — configuration governance system

**PR body:**
```
## What is dotforge?

Configuration governance for Claude Code — bootstrap, audit, sync, and evolve `.claude/` configuration across projects.

### Why it belongs here

- **Not a skill collection** — it's the management layer for your entire `.claude/` directory
- **Unique features**: audit scoring (0-10) with security cap, cross-project registry, practices pipeline (inbox → active → deprecated), template sync with customization preservation
- **Complementary**: works alongside skills collections, gstack, and other tools listed here
- **Zero dependencies**: markdown + shell scripts only
- **Active**: 12 projects managed, v2.9.0 released, MIT licensed

### Quick install
```bash
curl -fsSL https://raw.githubusercontent.com/luiseiman/dotforge/main/install.sh | bash
```
```

---

### PR 2: awesome-agent-skills (VoltAgent, 14.2K stars)

**Entry to add:**
```markdown
- [dotforge](https://github.com/luiseiman/dotforge) - Configuration governance: bootstrap, audit, sync .claude/ across projects. 15 stacks, 7 agents, practices pipeline, audit scoring. Zero deps.
```

**PR title:** Add dotforge — .claude/ configuration governance

---

## Day 10+: Organic Discord Engagement

Topics to watch for and reply with value:

- "How do you manage .claude/ across projects?" → mention /forge sync + registry
- "My CLAUDE.md is getting too long" → mention modularizing into .claude/rules/ with globs
- "How do I score my config?" → mention /forge audit with 12-item checklist
- "What hooks should I use?" → mention block-destructive (mandatory) + lint-on-save
- "How do I export to Cursor?" → mention /forge export cursor
- "Auto mode stripped my permissions" → mention using specific tool commands (pytest, vitest) not interpreters

Rule: provide genuine value first, mention dotforge only if directly relevant. No spam.
