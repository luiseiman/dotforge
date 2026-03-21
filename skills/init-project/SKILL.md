---
name: init-project
description: Quick-start Claude Code configuration in 5 seconds. Simplified bootstrap — auto-detects everything, zero questions.
---

# Init Project

Zero-friction Claude Code setup. Detects stack, generates config, done. No questions asked.

Unlike `/forge bootstrap` (which shows a preview and asks for confirmation), `/forge init` just does it.

## Step 1: Check if already initialized

If `.claude/settings.json` exists:
```
Already initialized. Use /forge sync to update or /forge audit to check score.
```
Exit without changes.

## Step 2: Detect stacks

Scan project files silently:

```bash
# Check each stack's detection indicators
# python-fastapi: pyproject.toml, requirements.txt with fastapi
# react-vite-ts: package.json with react + vite
# swift-swiftui: Package.swift, *.xcodeproj
# node-express: package.json with express/fastify (no react)
# go-api: go.mod
# java-spring: pom.xml or build.gradle with spring
# supabase: supabase/ dir or supabase in deps
# docker-deploy: Dockerfile or docker-compose*
# gcp-cloud-run: app.yaml or cloudbuild.yaml
# aws-deploy: cdk.json or template.yaml
# redis: redis in deps
# data-analysis: *.ipynb prominent
# devcontainer: .devcontainer/
```

Use `$CLAUDE_KIT_DIR/stacks/detect.md` as the detection reference.

If no stack detected, default to `standard` profile with `_common.md` rules only.

## Step 3: Generate config

Run `/bootstrap-project` internally with:
- Profile: `standard`
- Stacks: auto-detected
- No confirmation prompt — just generate

## Step 4: Output (one-liner)

Print a single summary line:

```
✓ claude-kit initialized — {stacks detected} — score {X}/10
```

Examples:
```
✓ claude-kit initialized — python-fastapi, docker-deploy — score 9.5/10
✓ claude-kit initialized — react-vite-ts, supabase — score 9.5/10
✓ claude-kit initialized — no stack detected (generic) — score 7.0/10
```

That's it. No walls of text, no previews, no confirmations.

## After init

Suggest next steps only if asked:
- Edit `CLAUDE.md` below `<!-- forge:custom -->` with project-specific context
- Run `/forge audit` for detailed score breakdown
- Run `/forge rule-check` after a few sessions to check rule effectiveness

## Constraints

- NEVER ask the user anything — the whole point is zero friction
- NEVER show file-by-file output — one summary line only
- If bootstrap-project fails, show the error concisely and suggest `/forge bootstrap` for the interactive version
- Do NOT run audit separately — calculate the score from what was generated
