---
name: forge-context-status
description: Report on current context window usage, cache health, and compaction recommendation. Read-only — does not compact.
---

Read the current session transcript file (path is in the runtime — check `$CLAUDE_TRANSCRIPT_PATH` env var, or fall back to `.claude/session/last-startup.md` for the working tree state). Estimate context usage with this approach:

1. **Token estimation** (proxy): use `wc -c` on the transcript file (if accessible), divide bytes by 5 for rough token count. This is approximate — actual context = transcript content + system prompt + memory injections.

2. **Context limit by model**:
   - Sonnet 4.6 / Opus 4.7: 1M tokens → 80% threshold = 800K
   - Haiku 4.5: 200K tokens → 80% threshold = 160K
   Detect model from `~/.claude/settings.json` `model` field if available, default to 1M.

3. **Cache health proxy**: read `/tmp/claude-tool-latency-<hash>` (the project hash file written by `tool-latency.sh`). Latency p50 << 100ms on Read/Edit suggests hot cache. p50 > 500ms suggests cache miss / cold reads.

4. **Recent edits volume**: count modifications in `.claude/session/` and `.git/index.lock` recency.

Output a tight report:

```
═══ CONTEXT STATUS ═══
Model:               Sonnet 4.6 (1M context)
Estimated usage:     ~XX% (≈Y tokens)
Cache health proxy:  hot | warm | cold (based on tool latency p50)
Files modified:      N this session
Last compact:        <timestamp from .claude/session/last-compact.md, or "none">
Behaviors disabled:  <list from session state>

── RECOMMENDATION ──
< 70%:  Continue working
70-80%: Monitor; consider /forge compact-task at next task break
> 80%:  /forge compact-task NOW (evidence-based threshold)
> 90%:  /forge compact-task URGENT or risk auto-compact mid-task
```

Be honest about the estimation — token count is a proxy, not exact. If estimate seems off, mention it.
