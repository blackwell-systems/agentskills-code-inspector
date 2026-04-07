#!/usr/bin/env bash
# inspector-lsp-set.sh — PostToolUse hook
#
# Sets the LSP-ready flag after mcp__lsp__start_lsp or the built-in LSP tool
# succeeds. Only acts in inspector sessions (gate file must exist).
#
# Lifecycle: PostToolUse (fires after mcp__lsp__start_lsp|LSP succeeds)
# Pair: inspector-lsp-gate.sh (PreToolUse gate)

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null)

[[ -z "$SESSION_ID" ]] && exit 0

GATE="/tmp/.inspector-gate-${SESSION_ID}"
[[ ! -f "$GATE" ]] && exit 0

touch "/tmp/.inspector-lsp-ready-${SESSION_ID}"
exit 0
