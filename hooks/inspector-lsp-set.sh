#!/usr/bin/env bash
# inspector-lsp-set.sh — PostToolUse hook
#
# Sets the LSP-ready flag after mcp__lsp__start_lsp or built-in LSP succeeds.
# Only acts in inspector sessions.
#
# Lifecycle: PostToolUse (fires after mcp__lsp__start_lsp|LSP succeeds)
# Pair: inspector-lsp-gate.sh (PreToolUse gate)

INPUT=$(cat)
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // ""' 2>/dev/null)
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // ""' 2>/dev/null)

[[ "$AGENT_TYPE" != "inspector" ]] && exit 0
[[ -z "$AGENT_ID" ]] && exit 0

touch "/tmp/.inspector-lsp-ready-${AGENT_ID}"
exit 0
