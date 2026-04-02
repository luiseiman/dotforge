# Claude Code Internals Analysis — Cross-Repository Research

**Date**: 2026-04-02
**Sources**:
- ComeOnOliver/claude-code-analysis (TypeScript source tree, 1,884 files)
- ThreeFish-AI/analysis_claude_code (Reverse engineering of v1.0.33, obfuscated JS)
- Kuberwastaken/claude-code (Architectural spec + Rust reimplementation)

**Purpose**: Extract verified internals to improve claude-kit's configuration effectiveness.

---

## 1. System Prompt Architecture

### Assembly Pipeline
The system prompt is NOT a single static block. It is assembled dynamically:

1. **Static region** (cacheable via Anthropic prompt caching):
   - Core identity: `"You are Claude Code, Anthropic's official CLI for Claude."`
   - Tool use guidelines, safety policy, output style
   - Custom user instructions (XML-wrapped)
2. **Dynamic region** (per-turn, after `SYSTEM_PROMPT_DYNAMIC_BOUNDARY`):
   - Environment info (platform, OS, shell, git status, model ID)
   - Working directory and memory content
   - Date stamp

**Key system prompt behaviors hardcoded**:
- "Keep responses short, fewer than 4 lines unless user asks for detail"
- "DO NOT ADD ANY COMMENTS unless asked"
- "Use TodoWrite/TodoRead VERY frequently"
- File security warning injected after EVERY Read tool call (costs tokens)

**Implication for claude-kit**: Rules that want verbose output or code comments must use strong override language ("ALWAYS provide detailed explanations", "ALWAYS add docstrings") to counteract hardcoded defaults.

### CLAUDE.md Discovery Order
Later-loaded = higher model attention priority:

1. `/etc/claude-code/CLAUDE.md` — managed/enterprise policy
2. `~/.claude/CLAUDE.md` — user global
3. Project: `CLAUDE.md`, `.claude/CLAUDE.md`, `.claude/rules/*.md` — shared
4. `CLAUDE.local.md` — private project-specific
5. `memory.md` — auto-memory

Discovery walks upward from CWD to filesystem root. Files closer to CWD override distant ones.

**`@include` directive**: `@path`, `@./relative`, `@~/home`, `@/absolute`. Max depth 5. Circular refs prevented. Only works in leaf text nodes (not code blocks).

**`claudeMdExcludes` setting**: Can exclude specific CLAUDE.md files from loading without deleting them.

**`CLAUDE_CODE_DISABLE_CLAUDE_MDS` env var**: Completely disables CLAUDE.md loading (useful for debugging).

---

## 2. Context Window Management — 5-Tier Compaction

The compaction system is far more sophisticated than documented:

| Tier | Trigger | Strategy | Hook Fires? |
|------|---------|----------|-------------|
| API-Native Microcompact | Server-side | `cache_edits`, zero client mutation | No |
| Time-Based Microcompact | 60min idle gap | Replaces tool results with `[Old tool result content cleared]` | No |
| Cached Microcompact | Main thread only | Queues `CacheEditsBlock` without mutation | No |
| Auto Compaction | ~90% context window | Full summarization (9-section template, 20K token budget) | Yes (PreCompact, PostCompact) |
| Context Collapse | ~97% (emergency) | Ultra-short 500-word summary, keeps only summary + last turn | No |

### Auto-Compaction Constants (Verified)
- `AUTOCOMPACT_BUFFER_TOKENS = 13,000`
- `WARNING_THRESHOLD_BUFFER_TOKENS = 20,000`
- `MAX_OUTPUT_TOKENS_FOR_SUMMARY = 20,000`
- `MAX_CONSECUTIVE_AUTOCOMPACT_FAILURES = 3` (circuit breaker — disables for session)
- Thinking disabled during summarization to save tokens
- Keep-alive signals every 30s for WebSocket timeout prevention

### Post-Compaction File Restoration
Two different budgets found across sources:
- ThreeFish: 20 files, 8192 tokens/file, 32768 total
- ComeOnOliver: 5 files, 5K tokens/file, 50K total
- Kuberwastaken: 5 files, 5K tokens/file, 50K total

The 5-file/50K budget appears more current. Skill restoration has separate budget: 25K tokens, ~5 skills, 5K each.

### Compression Prompt Template (9 Sections)
1. Primary Request and Intent
2. Key Technical Concepts
3. Files and Code Sections (with full snippets)
4. Errors and Fixes
5. Problem Solving
6. All User Messages (critical for intent tracking)
7. Pending Tasks
8. Current Work
9. Optional Next Step (with verbatim quotes)

Uses `<analysis>` tags for chain-of-thought before `<summary>` output. Custom compression instructions supported via `/compact`.

### Search/Read Deduplication
- `collapse_read_tool_results()`: replaces intermediate reads of same file with placeholders
- `collapse_search_results()`: deduplicates identical grep/glob queries
- These happen before API calls, saving tokens automatically

---

## 3. Tool System — 41 Tools

### Complete Tool Inventory

| Category | Tools |
|----------|-------|
| File Operations | FileRead, FileWrite, FileEdit, MultiEdit, Glob, Grep, LS |
| Execution | Bash, PowerShell, REPL (Python), NotebookEdit, NotebookRead |
| Web | WebFetch (15min cache), WebSearch (US-only) |
| Agent/Task | Agent, TaskCreate/Get/Update/List/Stop/Output, SendMessage |
| Planning | EnterPlanMode, ExitPlanMode, EnterWorktree, ExitWorktree |
| MCP | MCPTool, McpAuth, ListMcpResources, ReadMcpResource |
| Config | Config, Skill, AskUserQuestion, Brief, TodoWrite, Sleep |
| Team | TeamCreate, TeamDelete, RemoteTrigger, ScheduleCron, LSP |
| Search | ToolSearch (deferred tool discovery) |

### Tool Deferral System
- Tools marked `shouldDefer: true` are hidden from initial prompt (saves context)
- Discoverable via `ToolSearch` keyword matching on `searchHint` field
- `alwaysLoad: true` tools bypass deferral
- This is why some tools appear in `<system-reminder>` as "deferred tools"

### Concurrency
- Max 10 concurrent tool executions (`gW5 = 10`)
- Concurrency-safe tools: Read, Glob, Grep, LS, TodoRead, WebFetch, WebSearch
- NOT concurrency-safe: Bash, Write, Edit, MultiEdit

### Bash Sandboxing
- Linux: `bwrap` (bubblewrap)
- macOS: `sandbox-exec`
- Windows: no sandbox
- Output truncated at 30,000 characters
- Default timeout: 120,000ms, max: 600,000ms

### Read-Before-Write Enforcement
Hardcoded in source — NOT just a prompt instruction:
```javascript
if (!context.hasReadFile(input.file_path)) {
  throw new Error("You must use the Read tool to read the file before editing it")
}
```
State tracked in `readFileState: Map<string, { mtime, content }>` with staleness checks. Does NOT survive compaction unless file is in restoration budget.

---

## 4. Permission System — 5-Step Cascade

Evaluation order (confirmed by Rust reimplementation):

1. **Bypass mode check** → immediate Allow
2. **Persistent deny rules** (pattern matching)
3. **Persistent allow rules**
4. **AcceptEdits mode** → Allow (SDK mode)
5. **Plan mode** → Read-only enforcement
6. **Default** → derive from tool's danger level

### Bash Prefix Detection
Uses a **separate LLM call** (fast model, `command_injection` category) to extract prefixes:
- `cat foo.txt` → `cat`
- `git commit -m "foo"` → `git commit`
- `npm run lint` → `none` (no prefix — always prompts unless broadly allowed)
- `git status\`ls\`` → `command_injection_detected`

Allow/deny rules match against these extracted prefixes, not raw commands.

### Settings Cascade (Priority Order)
1. Managed (enterprise, read-only) — highest
2. Local project (`.claude/settings.local.json`)
3. Project shared (`.claude/settings.json`)
4. Global user (`~/.claude/settings.json`) — lowest

### Dangerous Pattern Stripping (Auto Mode)
When entering auto/YOLO mode, allow rules matching these patterns are **silently stripped**:
- Interpreters: `python`, `node`, `deno`, `ruby`, `perl`, `php`, `lua`
- Package runners: `npx`, `bunx`, `npm run`, `yarn run`, `pnpm run`, `bun run`
- Shells: `bash`, `sh`, `zsh`, `fish`, `eval`, `exec`
- Network: `curl`, `wget`, `ssh`
- System: `sudo`, `kubectl`, `aws`, `gcloud`

**Implication**: `Bash(python *)` in allow list gets removed when auto mode activates. Use specific script paths instead.

### MCP Tool Default
MCP tools default to `passthrough` behavior (always ask) — a distinct fourth permission type beyond allow/ask/deny.

---

## 5. Hook System — 25 Events

### Full Event List (Source-Verified)

**Currently documented in claude-kit (13)**:
SessionStart, PreToolUse, PostToolUse, UserPromptSubmit, Stop, SubagentStop, PreCompact, PostCompact, PermissionRequest, SubagentStart, CwdChanged, StopFailure, SessionEnd

**Newly discovered (12)**:
- `Setup` — initialization phase
- `PostToolUseFailure` — fires when a tool execution fails
- `FileChanged` — external file modification detected
- `InstructionsLoaded` — CLAUDE.md/rules loaded
- `TaskCreated` — agent task spawned
- `TaskCompleted` — agent task finished
- `PermissionDenied` — permission was denied (audit trail)
- `Elicitation` / `ElicitationResult` — interactive prompts
- `TeammateIdle` — multi-agent coordinator event
- `ConfigChange` — settings modified
- `Notification` — system notification
- `StatusLine` — status bar updates
- `FileSuggestion` — file recommendation

### Async Hooks
Hooks can declare `async: true` or `asyncRewake` in config, or stream `{"async":true}` as first JSON line. Background hooks survive new user prompts but killed on hard cancel (Escape).

### Timeouts
- Tool hooks: 10 minutes (`TOOL_HOOK_EXECUTION_TIMEOUT_MS`)
- SessionEnd hooks: 1.5 seconds default (`SESSION_END_HOOK_TIMEOUT_MS_DEFAULT`)
- Override via `hook.timeout` or `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS`

### Plugin Environment Variables
- `${CLAUDE_PLUGIN_ROOT}` — plugin directory
- `${CLAUDE_PLUGIN_DATA}` — plugin data directory
- `${user_config.X}` — user config values
- `CLAUDE_PLUGIN_OPTION_*` — plugin options as env vars

---

## 6. Agent/Subagent Mechanics

### Subagent Architecture
- Each subagent gets independent context window (isolated from main thread)
- Tool access: full tool set including Bash, Edit, Write, etc.
- Fork subagents share parent prompt cache (Anthropic caching API)
- `shouldAvoidPermissionPrompts: true` for background agents (auto-deny, no UI)

### Task Types
- `local_agent` — sub-agent via AgentTool
- `remote_agent` — remote execution
- `in_process_teammate` — shared memory teammate (Coordinator mode)
- `dream` — auto-dream background memory consolidation

### Agent Memory
- `agentMemory.ts` + `agentMemorySnapshot.ts` for persistence
- Dynamic loading from `~/.claude/agents/` via `loadAgentsDir.ts`
- Built-in agents defined in `builtInAgents.ts`

### Slash Command Priority
`bundledSkills > builtinPluginSkills > skillDirCommands > workflowCommands > pluginCommands > pluginSkills > COMMANDS()`

Skills installed via claude-kit can shadow built-in commands if names collide — be intentional about naming.

---

## 7. Frontmatter Fields (Complete)

Beyond `globs:` and `paths:`, rules support:

| Field | Values | Effect |
|-------|--------|--------|
| `model` | `haiku`, `sonnet`, `opus`, `inherit` | Pin model tier for rule/skill |
| `effort` | `low`, `medium`, `high`, `max`, integer | Thinking level / reasoning depth |
| `context` | `inline`, `fork` | Execute inline or fork to subagent |
| `agent` | agent type string | Sub-agent type when `context: fork` |
| `shell` | `bash`, `powershell` | Shell for hook execution |
| `hooks` | event + matcher config | Register hook events |
| `skills` | comma-separated names | Preload skills |
| `user-invocable` | boolean | Show as slash command |
| `allowed-tools` | tool name filter | Restrict available tools |

---

## 8. Session Management

- **Session ID**: `randomUUID()` at init, regenerated on `/clear`
- **Lineage**: `parentSessionId` tracks session chain
- **Persistence**: Messages saved BEFORE API call (crash-safe, enables `--resume`)
- **Storage**: `~/.claude/sessions/<sessionId>/` with JSONL transcripts
- **Session memory**: `memory.jsonl` per session, semantic similarity retrieval
- **Checkpoints**: `SessionCheckpoint` with message index + label for rewind
- **autoDream**: Background memory consolidation (3-gate: 24h time, 5-session, PID lock)
- **Teleportation**: Cross-machine session resume via `teleportedSessionInfo`

---

## 9. Undocumented Features & Special Modes

| Feature | Description |
|---------|-------------|
| KAIROS | Always-on persistent assistant with cron scheduling |
| Coordinator Mode | Multi-agent orchestration with parallel workers |
| Voice Mode | STT/TTS input/output |
| ULTRAPLAN | Remote 30-min planning sessions on cloud Opus |
| autoDream | Background 4-phase memory consolidation |
| Bridge Mode | WebSocket connection to claude.ai |
| Vim Mode | Terminal vim keybinding integration |
| BUDDY | Tamagotchi companion (18 species, 5 rarity tiers) |
| `/thinkback` | Replay model thinking |
| `/teleport` | Git navigation / cross-machine resume |
| `/rewind` | Undo to checkpoint |
| `/ctx_viz` | Context window visualization |

---

## 10. Debunked Claims

| Claim | Reality |
|-------|---------|
| "25-turn loop limit" | No hardcoded turn limit — loop runs until task complete |
| "AI-driven permission evaluation" | Static rule-based pattern matching (not ML) |
| "Intelligent tool selection algorithm" | Tool selection is entirely by the LLM, no routing layer |

---

## 11. Actionable Improvements for claude-kit

### High Priority

1. **Update hook-architecture.md with 12 new events** — `PostToolUseFailure`, `FileChanged`, `TaskCreated`, `TaskCompleted`, `PermissionDenied`, and others enable richer hook workflows
2. **Document async hooks** — `async: true` pattern enables long-running hooks that don't block. Critical for hookify stack
3. **Add frontmatter fields `model`, `effort`, `context`, `agent`** to rule-effectiveness.md — rules and skills can pin model tier and thinking level directly
4. **SessionEnd hook 1.5s timeout warning** — session-report.sh must be fast or use `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS` override
5. **Document auto-mode permission stripping** — interpreters/network tools silently removed from allow list in auto mode

### Medium Priority

6. **Add `@include` directive to template system** — max depth 5, could simplify multi-stack CLAUDE.md assembly
7. **Document 5-tier compaction** — current docs treat compaction as single mechanism
8. **Add `claudeMdExcludes` setting** to stack disable pattern — disable stacks without deleting
9. **Warn about Bash prefix extraction** — `npm run lint` → `none` means it always prompts; document prefix patterns
10. **Post-compact file restoration budget** — 5 files, 50K tokens total, 5K per file; last-compact.md must stay under 5K tokens
11. **Document search/read deduplication** — avoid redundant reads; system deduplicates but wastes turn time

### Lower Priority

12. **Slash command naming conflicts** — skills can shadow built-ins; document collision risk
13. **`CLAUDE_CODE_DISABLE_CLAUDE_MDS` env var** — useful for debugging
14. **System prompt conflicts** — "no comments", "4-line limit", "use TodoWrite frequently" are hardcoded; override patterns needed
15. **Read-after-compact gap** — `hasReadFile` state doesn't survive compaction; long sessions may need re-reads

---

## Appendix: Token Budget Reference

| Component | Limit |
|-----------|-------|
| Auto-compact buffer | 13,000 tokens |
| Warning threshold buffer | 20,000 tokens |
| Compaction summary max output | 20,000 tokens |
| Post-compact file restoration | 5 files, 50K total, 5K each |
| Post-compact skill restoration | 25K total, ~5 skills, 5K each |
| Bash output truncation | 30,000 characters |
| Read default lines | 2,000 |
| Read line truncation | 2,000 characters/line |
| Concurrent tool executions | 10 max |
| WebFetch cache TTL | 15 minutes |
| SessionEnd hook timeout | 1.5 seconds |
| Tool hook timeout | 10 minutes |
| `@include` max depth | 5 levels |
| Context collapse threshold | ~97% |
| Auto-compact threshold | ~90% |
| Compaction circuit breaker | 3 consecutive failures |
