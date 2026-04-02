# TOOLS.md

## Development Machines

- **Mac (local)**: macOS, primary dev machine. Vault: `/Users/luiseiman/vault/`
- **VPS (Oracle ARM64)**: Ubuntu, Docker host, production services. Vault: `/home/ubuntu/vault/`

## Cloud Services

- **GCP**: Cloud Run (Cotiza-Api-Cloud, APIs). Project billing active.
- **Vercel**: Frontend deployments (React/Vite apps).
- **Supabase**: Database + auth for InviSight and other projects.

## Source Control

- **GitHub**: github.com/luiseiman — all repos. Use `gh` CLI for PRs/issues.
- **Branches**: feature/, fix/, refactor/, chore/ prefixes.
- **Never force push main** without explicit confirmation.

## Observability

- **Obsidian vault**: second brain, auto-sync git every 30 min. Decisions in `decisions/`, postmortems in vault root.
- **Claude Code metrics**: `~/.claude/metrics/` — session reports from stop hooks.

## Trading Infrastructure

- **Cotiza-Api-Cloud**: WebSocket API on Cloud Run — real-time market data (BYMA, crypto).
- **SOMA**: Agent OS — Python 3.12, FastAPI, Redis Streams, Docker on VPS.
- **InviSight**: iOS trading app — Swift/SwiftUI, Supabase backend.

## Credentials Policy

- Never hardcode secrets. Use environment variables.
- `.env` files are gitignored. Never commit, never read aloud.
- API keys referenced by name only (e.g., "use ANTHROPIC_API_KEY"), never by value.

## MCP Servers

- **Supabase**: database operations, migrations, edge functions.
- **Gmail**: read/draft emails.
- **Google Calendar**: events, scheduling.
- **Telegram**: channel messaging via bot.
- **Postman**: API collection management.
