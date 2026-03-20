# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in claude-kit, please report it responsibly:

1. **Do NOT open a public issue**
2. Email: Open a private security advisory on [GitHub](https://github.com/luiseiman/claude-kit/security/advisories/new)
3. Include: description, reproduction steps, and impact assessment

You should receive a response within 48 hours.

## Scope

claude-kit generates configuration files for Claude Code. Security concerns include:

- **Hook scripts** (`template/hooks/`, `stacks/*/hooks/`) — shell scripts that execute during Claude Code sessions
- **Deny lists** (`settings.json`) — files that should be blocked from reading
- **Rules** — markdown files loaded into Claude's context (potential prompt injection vector)

## Known Security Controls

- `block-destructive.sh` — blocks dangerous bash commands (configurable profiles: minimal/standard/strict)
- Deny list template covers: `.env`, `*.key`, `*.pem`, `*credentials*`, `*secret*`
- Audit item 12: prompt injection scan on rules and CLAUDE.md
- `tests/test-config.sh` validates deny list completeness

## Supported Versions

| Version | Supported |
|---------|-----------|
| 2.0.x   | Yes       |
| < 2.0   | No        |
