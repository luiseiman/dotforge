---
globs: workflows/*.js, docs/v4/*.md, .claude/rules/domain/workflow-automation.md
description: When dotforge should use workflows vs skills, based on PoC cost-quality measurements
domain: dotforge-meta
last_verified: 2026-10-07
---

# Workflow Economics

dotforge uses bash skills for mechanical lifecycle work and workflows ONLY as on-demand escalation. This rule documents the cost-quality data from the v4 PoC (2026-06-03) and the decision matrix derived from it.

## The decision matrix

Apply this matrix BEFORE proposing any workflow refactor of a skill:

| Question | Skill (stay) | Workflow (consider) |
|----------|--------------|---------------------|
| Is the hot path LLM-driven? | No (bash/git/grep/file checks) | Yes (research, synthesis, evaluation) |
| Would adversarial verify catch real bugs? | No (deterministic output) | Yes (LLM hallucination risk) |
| Wall-clock currently > 2 min AND parallelizable? | No | Yes |
| Is it run > 5x per week? | Yes — token cost compounds | No — one-off is fine |
| Does main thread need to retain context? | Yes | No — context isolation helps |

**If 3+ questions point to "Skill" → DO NOT REFACTOR.** Workflow is too expensive vs bash for recurring mechanical work.

## Measured cost (v4 PoC, 4 smoke tests on `workflows/watch.js`)

| Configuration | Cost per run | vs baseline `/forge watch` skill |
|---------------|-------------|----------------------------------|
| Default Opus session model | ~$5-25 | 5-25x baseline |
| Model routing (Haiku parse + Sonnet verify) | ~$4-5 | 4-5x baseline |
| Hybrid (main thread fetches + workflow processes) | ~$4-5 | 4-5x baseline |
| Bash skill baseline (`/forge watch` v3.13) | ~$0.75-1.00 | baseline |

**Per-agent overhead in workflows is ~80K tokens regardless of model.** Model routing helps but does not reach cost parity. Verify-without-WebSearch saves cost but causes quality regression (smoke #4 missed BREAKING finding that smoke #3 verified).

## Token economy principles (mandatory for any dotforge-owned workflow)

1. **Bash-first triage at workflow start** — filter work mechanically before spawning agents
2. **Default skepticism = single-pass verify** (`args.skepticism: 'normal'`)
3. **Custom `agentType` only when role matters** — default workflow agent is lighter
4. **Schema validation = 0 token cost** — always use `opts.schema` for structured output
5. **Minimal prompts per `agent()` call** — only the context needed for that decision
6. **Declare `budget.total` per workflow** — default 100_000 output tokens; document overrides
7. **Resume cache via `resumeFromRunId`** — same script + same args = 100% cache hit
8. **Phase boundaries are free** — use `phase()` liberally for visibility
9. **One workflow = one concern** — compose via `workflow()` 1-level when needed
10. **Log per-phase token spend** — end with `log(`Spent: ${budget.spent()} of ${budget.total}`)`

## Per-stage model routing

For workflows that do mix mechanical + judgment work:

| Stage type | Model | Why |
|-----------|-------|-----|
| Mechanical extraction from curated content | `haiku` | Same accuracy as Sonnet, 1/10th the cost |
| File reading + topic enumeration | `haiku` | No judgment needed |
| Adversarial verify (judgment) | `sonnet` | Needs reasoning quality |
| Final synthesis / report composition | `sonnet` | Needs coherent narrative |
| Architecture decisions / security audit | `opus` | Worth the cost |

ALWAYS specify `model:` in `agent()` opts when a stage doesn't need the session-default model. Inheriting Opus 4.7 for mechanical parse calls was the single largest cost driver in PoC smoke #3 (~$5-25 vs $0.50 if routed correctly).

## When workflows DO make economic sense for dotforge

- **One-off codebase-wide research** — `/deep-research` bundled workflow
- **Production-tier projects where false-positive cost > workflow cost** — pay ~$5 cheap insurance vs hours of cleanup
- **Adversarial verify on individually high-stakes findings** — invoke manually per finding, not as bulk replacement

## When workflows DO NOT make sense for dotforge

- **`/forge sync-all`** — pure mechanical (git classify), 0 hot-path LLM calls. Workflow = token bomb.
- **`/forge audit`** — file/grep checks. Mechanical.
- **`/forge watch`** — measured 4-5x baseline; bash skill produces good-enough output with manual review. For deltas >30 releases the skill uses the **bash-first + 2 sonnet subagents by version range** pattern (curl raw CHANGELOG → slice → split → grep coverage → spot-check), ~500K subagent tokens for 62 versions — still a plain skill, not a workflow
- **`/forge update`** — judgment-heavy but recurring; cost compounds
- **`/forge sync`, `/forge bootstrap`, `/forge init`** — file ops, no LLM judgment in hot path

## The reference implementation

`workflows/watch.js` is preserved in the repo as a REFERENCE implementation, not as the default `/forge watch`. It demonstrates:
- Hybrid pattern (main thread fetches, workflow processes)
- Schema-validated parsing with `SOURCE_RESULT_SCHEMA`
- Smart Phase 2 (read only relevant domain files based on detected categories)
- Per-stage model routing (Haiku parse + coverage, Sonnet verify + synth)
- Defensive `args` parsing (string OR object)

Read it when designing a new workflow. Do not invoke as `/forge watch` substitute — the bash skill remains the production tool.

## Lessons from PoC iteration

1. **My first cost estimate was wrong by 8-10x.** Per-agent overhead is ~80K tokens regardless of model. Budget conservatively until measured.
2. **KNOWN_TOPICS static glossary saves tokens but degrades accuracy.** False-positive matches creep in. Better to spend $0.05 on an agent reading actual domain files than to maintain a stale heuristic.
3. **Adversarial verify quality depends on cross-source check.** Internal-reasoning-only verify saves cost but cannot catch BREAKING findings whose claim requires fetching to confirm. Smoke #4 missed the 10K char cap that smoke #3 verified.
4. **Workflow value is real, just expensive per finding.** Smoke #3 found 4 real gaps that bash `/forge watch` missed. The question is not "do workflows add value" but "is each finding worth $X to verify".
5. **`opts.model` is mandatory in production workflows.** Without it, every agent runs at session model rate. For dotforge sessions on Opus 4.7, that's $75/M output — workflow becomes economically unviable.

## References

- `docs/v4/SPEC.md` — full PoC findings and v4 scope decision
- `workflows/watch.js` — reference implementation with model routing
- `domain/workflow-automation.md` — upstream `/workflows` API documentation
- `domain/workflow-and-ultracode-policy.md` — tier-based posture (when to invoke workflows manually)
