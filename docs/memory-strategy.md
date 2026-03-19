# Memory Strategy

How claude-kit manages memory across projects. Five layers, each with a distinct purpose.

## The 5 Layers

```
Layer          What              Where                     Injection    Maintained by
─────────────────────────────────────────────────────────────────────────────────────
1. CLAUDE.md   Prescriptive      <project>/CLAUDE.md       Auto-always  Human
               (what to do)      ~/.claude/CLAUDE.md

2. Rules       Contextual        .claude/rules/*.md        Auto-by-glob Human via sync
               (when to do it)

3. Errors      Known issues      CLAUDE_ERRORS.md          Auto-always  Claude + Human
               (what NOT to do)  (via memory.md rule)

4. Auto-memory Discoveries       ~/.claude/projects/       Auto-always  Claude Code
               (what was found)  */memory/

5. Agent mem   Per-role learning  .claude/agent-memory/     Auto-on-use  Each agent
               (what each role   <agent-name>/
               learned)
```

## How They Interact

```
                    PRESCRIPTIVE                    DESCRIPTIVE
                    (human-curated)                 (auto-accumulated)
                    ────────────────                ──────────────────
Always loaded:      CLAUDE.md ←──────────────────→ Auto-memory
                    Rules (by glob)                 Agent memory (on invoke)
                    Errors (by memory.md rule)

                    ↕ promote (3+ occurrences)      ↕ discovered patterns

                    _common.md / stack rules ←────── CLAUDE_ERRORS.md
```

- **CLAUDE.md** and **auto-memory** both describe the project, but CLAUDE.md is what SHOULD happen (conventions, architecture) while auto-memory is what WAS discovered (build quirks, debugging insights). They diverge — that's expected.
- **CLAUDE_ERRORS.md** feeds **rules**: when an error repeats 3+ times, the derived rule should be promoted to `_common.md` or a stack-specific rule. This is manual — the memory.md rule reminds Claude to do it.
- **Agent memory** is independent per agent. The code-reviewer accumulates code quality patterns. The architect accumulates design decisions. They don't cross-pollinate — each agent's memory is its own.

## Design Decisions

### Why not centralize errors?
Each project has its own CLAUDE_ERRORS.md. Cross-project patterns get captured via `/forge capture` into the practices pipeline, not via a central error file. This keeps errors contextual to their project.

### Why no memory for researcher and test-runner?
These agents are **transactional**: they explore/test and return a summary. Their value is in the report, not in accumulated knowledge. Adding memory would make them slower (reading past context) without benefit.

### Why autoMemoryEnabled in template?
Claude Code's auto-memory captures insights that no other layer does: build command quirks, environment issues, debugging paths. It's the cheapest form of cross-session learning. Enabled by default in the template; can be disabled per-project in settings.local.json.

### Why a separate memory.md rule?
CLAUDE_ERRORS.md needs to be read before modifying code, but injecting the entire file as a rule would waste context on every tool use. Instead, the memory.md rule is a lightweight reminder that tells Claude to READ the file when relevant — not a dump of its contents.

## Template Files

| File | Purpose |
|------|---------|
| `template/settings.json.tmpl` | `autoMemoryEnabled: true` |
| `template/rules/memory.md` | Memory policy (error reading, agent memory, auto-memory) |
| `template/CLAUDE_ERRORS.md` | Empty template with table structure |
| `agents/*.md` | `memory: project` on 4 agents, commented on 2 |
