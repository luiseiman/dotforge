---
globs: "**/*"
---

# Slack MCP Rules

## Read operations — call freely
- `list_channels`: workspace channel index
- `get_channel_history`: recent messages in a channel
- `get_thread_replies`: thread inspection
- `search_messages`: find relevant discussions
- `get_users`, `get_user_profile`: team directory lookup

## Sending messages — show draft first

Before calling `post_message` or `reply_to_thread`:
1. Show the full message text as a draft
2. Confirm the target channel or thread (name + ID)
3. Wait for explicit approval — sent messages are immediately visible to others

Before `add_reaction`: state the emoji and target message. Reactions are visible and
accumulate — don't add reactions automatically without user intent.

## Format and tone
- Never add emojis unless the user includes them in the draft
- Never use `@here`, `@channel`, or `@everyone` in automated messages without explicit instruction
- Bot messages must be distinguishable from human messages — never impersonate a user
- Markdown formatting (bold, code blocks) is acceptable; decorative formatting is not

## Editing messages

`update_message` is denied by default. If re-enabled:
- Only edit bot-authored messages — never edit messages posted by a human user
- Show the before/after diff before calling
- Require explicit user approval

## Privacy

- Do not log or store message content from `get_channel_history` beyond the current task
- Private channels (`is_private: true`): only read if the user explicitly navigated to them —
  do not proactively scan private channels during workspace exploration
- User profiles may contain personal info (phone, email, timezone) — use only for
  task context, never surface unnecessarily
- Never forward channel content to external services during an MCP session

## Hard stops

- `delete_message`: denied by default. If re-enabled, only on bot-authored messages,
  require explicit confirmation, and never delete in bulk.
- `update_message`: denied by default (editing messages from others is irreversible from
  the recipient's perspective).
- `kick_user_from_channel`: always denied — administrative actions belong in the Slack UI
  or via the Slack admin API with proper audit trail.
- `archive_channel`: always denied — permanently removes a channel from active use.
  Requires workspace admin review.
- `set_channel_purpose` / `set_channel_topic`: always denied — channel metadata changes
  affect all members and should be intentional, not side effects of an automated session.

## Channel scope

When asked to "check Slack" or "look at Slack", default to the channels the user
explicitly names. Do not iterate over all channels or read channel history broadly.
Ask: "Which channel(s) should I check?"
