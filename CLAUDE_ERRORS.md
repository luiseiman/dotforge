# Known Errors — claude-kit

Error log and lessons learned to avoid repeating mistakes.

| Date | Area | Error | Cause | Fix | Rule |
|------|------|-------|-------|-----|------|
| 2026-03-19 | audit | Checklist counted CLAUDE.md lines instead of verifying sections | Shallow validation | Rewrite checklist to verify section content (Stack, Build, Arch) | Verify content, not existence |
| 2026-03-19 | scoring | No security cap — inflated score when hooks or deny list missing | Permissive formula | Add cap: if item 2 or 4 = 0, max score = 6.0 | Security cap is mandatory |
| 2026-03-19 | stacks | docker-deploy and supabase missing settings.json.partial | Incomplete stacks since v0.1 | Create settings.json.partial with per-stack permissions | Every stack needs rules/ + settings.json.partial |
| 2026-03-19 | agents | agents.md referenced nonexistent tasks/lessons.md | Phantom reference from original template | Change to CLAUDE_ERRORS.md | Never reference files that don't exist in the template |
| 2026-03-19 | agents | `resume` parameter deprecated in Agent tool | Upstream breaking change | Replace with SendMessage({to: agentId}) | Run /forge watch periodically |
| 2026-03-19 | sync | _common.md duplicated with global CLAUDE.md | No deduplication between layers | Separate: global = behavior, _common.md = code rules | Don't repeat rules across layers |
