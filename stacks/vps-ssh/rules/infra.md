---
globs: "**/deploy*.sh,**/Makefile,**/.github/workflows/*.yml,**/scripts/*.sh"
description: "SSH/VPS deployment conventions — remote host access, key management, deploy flow"
domain: infra
last_verified: 2026-04-20
---

# VPS / SSH

## Canonical host doc

The project's authoritative connection info lives in `.claude/rules/domain/infra.md`.
Fields every infra.md MUST cover:

- **Host alias** (as in `~/.ssh/config`), real HostName, User, IdentityFile
- **App directory** on the remote (absolute path)
- **Deploy command** (local → remote) and **rollback**
- **Service name** (systemd unit, docker compose service, pm2 name)
- **Logs command** (`journalctl -u X -f`, `docker logs -f`, `tail -f /var/log/...`)
- **Health check** URL or command

## Never do

- Hardcode IPs or users in project scripts when an `~/.ssh/config` alias exists — use the alias
- Commit private keys (deny rules block Read on `id_*`, `*.key`, `*_ed25519`, `*_rsa`)
- Run `ssh root@...` when a non-root sudo user exists
- Chain destructive commands over ssh without a dry-run flag first

## Deploy flow (standard)

1. Build locally, run tests
2. `rsync -avz --delete ./dist/ user@host:/app/dist/` OR `git pull` on remote
3. Remote: restart service (`sudo systemctl restart X` or `docker compose up -d`)
4. Health-check endpoint
5. Tail logs for first 30s
6. If fail → documented rollback

## Key management

- One key per purpose (per-project or per-VPS). Never reuse personal keys for CI
- Keys in `~/.ssh/`, 0600 perms, referenced via `IdentityFile` in `~/.ssh/config`
- Rotate yearly; document rotation date in `domain/infra.md`

## Troubleshooting

- `ssh -v <host>` for verbose connection trace
- `ssh <host> 'command'` for one-shot remote command (avoid opening full shell)
- `ssh -o ServerAliveInterval=60` for flaky networks
