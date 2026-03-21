---
name: init-project
description: Quick-start Claude Code configuration. Auto-detects stack, asks 3 questions to understand the project, generates complete config.
---

# Init Project

Fast Claude Code setup: auto-detect stack + 3 quick questions = complete, personalized config.

Unlike `/forge bootstrap` (full interactive preview), `/forge init` is streamlined: detect, ask, generate, done.

## Step 1: Check if already initialized

If `.claude/settings.json` exists:
```
Already initialized. Use /forge sync to update or /forge audit to check score.
```
Exit without changes.

## Step 2: Detect stacks

Scan project files silently using `$CLAUDE_KIT_DIR/stacks/detect.md` as reference:

```
python-fastapi: pyproject.toml, requirements.txt with fastapi
react-vite-ts:  package.json with react + vite
swift-swiftui:  Package.swift, *.xcodeproj
node-express:   package.json with express/fastify (no react)
go-api:         go.mod
java-spring:    pom.xml or build.gradle with spring
supabase:       supabase/ dir or supabase in deps
docker-deploy:  Dockerfile or docker-compose*
gcp-cloud-run:  app.yaml or cloudbuild.yaml
aws-deploy:     cdk.json or template.yaml
redis:          redis in deps
data-analysis:  *.ipynb prominent
devcontainer:   .devcontainer/
```

Also scan existing files for additional context:
- README.md → project description
- existing test files → testing patterns
- CI config (.github/workflows, Makefile) → build/test commands

## Step 3: Ask 3 questions

Present all 3 questions together (not one at a time):

```
═══ FORGE INIT ═══
Stack detected: {stacks or "none — generic config"}

3 quick questions to generate a complete config:

1. ¿Qué hace y qué NO hace?
   → One sentence: the problem it solves, and explicit v0.1 limits.
   Example: "API REST for real-time quotes. No auth, no frontend, no historical data yet."

2. ¿Con qué?
   → Stack, language, DB, external services, where it runs.
   Example: "Python 3.12, FastAPI, Supabase, deployed on GCP Cloud Run."

3. ¿Cómo trabajo?
   → Solo or team, spec-first or prototype-first, testing level from day one.
   Example: "Solo, prototype-first, tests only for critical paths."
```

Wait for user responses. If the user answers in a single message covering all 3, parse accordingly.

If the user says "skip" or gives empty answers, proceed with auto-detected info only.

## Step 4: Generate config

Run `/bootstrap-project` internally with:
- Profile: `standard`
- Stacks: auto-detected
- No confirmation prompt

Then **enrich the generated CLAUDE.md** with the user's answers:

### CLAUDE.md enrichment

Insert the user's answers into the `<!-- forge:custom -->` section of CLAUDE.md:

```markdown
<!-- forge:custom -->

## What this project does
{answer to question 1 — what it does AND what it doesn't do}

## Stack & infrastructure
{answer to question 2 — expanded with detected stacks}

## Working style
{answer to question 3 — solo/team, approach, testing expectations}
```

If the user provided build/test commands in their answers, also update the `## Build & Test` section above the forge:custom marker.

### Deny list enrichment

If the user mentioned specific services, external APIs, or sensitive areas in question 2, add relevant deny patterns to settings.json. Examples:
- Mentioned Supabase → ensure `Read(**/.env)` covers SUPABASE_* vars
- Mentioned external API → add API key env var patterns
- Mentioned "no auth yet" → no auth-related deny needed

## Step 5: Output

Show a concise summary:

```
═══ FORGE INIT — DONE ═══
Project:  {name}
Stacks:   {detected stacks}
Config:   claude-kit v2.3.0 standard

Generated:
  CLAUDE.md          → project context (personalized)
  .claude/settings.json → permissions + hooks
  .claude/rules/     → {N} rules
  .claude/hooks/     → {N} hooks
  .claude/commands/  → {N} commands
  .claude/agent-memory/ → persistent memory
  CLAUDE_ERRORS.md   → error log
  .forge-manifest.json → version tracking

Score: {X}/10 (run /forge audit for details)
```

## Constraints

- Ask exactly 3 questions, together, not sequentially
- If user skips questions, proceed with auto-detected info — never block on missing answers
- Keep the output concise — no walls of text
- The user's answers go in `<!-- forge:custom -->` section (protected from future syncs)
- If bootstrap-project fails, show error and suggest `/forge bootstrap` for full interactive version
