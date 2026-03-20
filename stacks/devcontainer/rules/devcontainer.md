---
globs: ".devcontainer/**,devcontainer.json"
---

# Devcontainer Rules

## Configuration
- `devcontainer.json` in `.devcontainer/` directory
- Pin image versions: `mcr.microsoft.com/devcontainers/base:1-bookworm` not `:latest`
- Use features for tool installation instead of Dockerfile RUN commands
- `postCreateCommand` for project setup (install deps, build, etc.)

## Claude Code in Containers
- Ensure `bash`, `git`, `jq`, `curl` are available (required by hooks)
- Mount `.claude/` directory if persisting config across rebuilds
- Set `CLAUDE_KIT_DIR` env var if using /forge commands
- File watchers: increase `fs.inotify.max_user_watches` if needed

## Security
- Never run container as root in production — use `remoteUser`
- Forward only necessary ports
- Use container secrets for sensitive env vars, not `containerEnv`
- `.devcontainer/` should be committed (shared config), but `.env` should not

## Features
```json
{
  "features": {
    "ghcr.io/devcontainers/features/node:1": {},
    "ghcr.io/devcontainers/features/python:1": {},
    "ghcr.io/devcontainers/features/docker-in-docker:2": {}
  }
}
```

## Common Mistakes
- Missing `forwardPorts` — services unreachable from host
- `postCreateCommand` fails silently — always chain with `&&` and check exit codes
- Rebuilding container loses uncommitted work — commit or use volumes
- Conflicting extensions between `.vscode/extensions.json` and `customizations.vscode.extensions`
