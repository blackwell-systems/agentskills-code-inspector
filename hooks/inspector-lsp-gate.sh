#!/usr/bin/env bash
# inspector-lsp-gate.sh — PreToolUse hook
#
# Blocks Read, Glob, Grep, and Bash in inspector sessions until LSP has been initialized.
# Identity is established by inspector-subagent-start.sh via a session-scoped gate
# file. Uses session_id (present in all hook payloads) as the linking key.
#
# Lifecycle: PreToolUse (fires before Read|Glob|Grep)
# Pair: inspector-subagent-start.sh (SubagentStart), inspector-lsp-set.sh (PostToolUse)

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null)

[[ -z "$SESSION_ID" ]] && exit 0

GATE="/tmp/.inspector-gate-${SESSION_ID}"
READY="/tmp/.inspector-lsp-ready-${SESSION_ID}"

# Not an inspector session — pass through
[[ ! -f "$GATE" ]] && exit 0

# LSP already initialized — pass through
[[ -f "$READY" ]] && exit 0

echo "BLOCKED: Call mcp__lsp__start_lsp(root_dir=<workspace>, language=<lang>) before reading any files." >&2
exit 2
