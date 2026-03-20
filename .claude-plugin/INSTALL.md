# claude-kit Plugin Installation

## Plugin Mode (lightweight)

Plugin mode installs a curated subset: hooks, rules, and commands.
Skills, agents, and practices pipeline require the full repository.

### What's included

| Component | Included | Notes |
|-----------|----------|-------|
| block-destructive hook | yes | PreToolUse, blocks dangerous commands |
| lint-on-save hook | yes | PostToolUse, auto-lint on file write |
| warn-missing-test hook | yes | PostToolUse, strict profile only |
| Common rules | yes | _common.md, memory.md, agents.md |
| Commands | yes | audit, health, review, debug |
| Skills (/forge) | no | Requires full repo |
| Agents (6 subagents) | no | Requires full repo |
| Practices pipeline | no | Requires full repo |
| Stack rules | selectable | Pick stacks during install |

### Installation

```bash
# When Claude Code plugin system is available:
claude plugin install claude-kit

# Until then, use git clone:
git clone https://github.com/luiseiman/claude-kit.git ~/claude-kit
cd ~/claude-kit && ./global/sync.sh
```

## Full Mode (recommended)

Full mode gives access to all features including `/forge` commands.

```bash
git clone https://github.com/luiseiman/claude-kit.git ~/claude-kit
cd ~/claude-kit && ./global/sync.sh
```

Then in any project:
```
/forge bootstrap
```

## Stack Plugins

Individual stacks are also available as standalone plugins:

```bash
# When plugin system supports composition:
claude plugin install claude-kit-stack-python-fastapi
claude plugin install claude-kit-stack-react-vite-ts
```

Each stack plugin includes its `rules/*.md` and `settings.json.partial`.
Multiple stack plugins compose via permission union merge.
