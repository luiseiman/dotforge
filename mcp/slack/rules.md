---
globs: "**/*"
---

# Slack MCP Rules

## Read operations (call freely)
- `list_channels`, `get_channel_history`, `get_thread_replies`: message inspection
- `search_messages`: find relevant discussions
- `get_users`, `get_user_profile`: team directory lookup

## Sending messages — always show draft first
Before calling `post_message` or `reply_to_thread`:
1. Show the full message text as a draft
2. Confirm the target channel or thread
3. Wait for explicit approval — sent messages are visible to others and cannot be unsent easily

## Format and tone
- Never add emojis unless the user includes them in the draft
- Never use @here or @channel in automated messages without explicit instruction
- Keep automated/bot messages clearly distinguishable from human messages

## Privacy
- Do not log or store message content from `get_channel_history` beyond the current task
- Do not share content from private channels in responses unless directly relevant to the task
- User profiles may contain personal info — use only for context, never expose unnecessarily

## Hard stops
- `delete_message`: only on bot-authored messages. Never delete messages from other users.
- `kick_user_from_channel`: always denied — administrative actions belong in the Slack UI.
