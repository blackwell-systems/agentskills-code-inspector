#!/usr/bin/env bash
# inspector-lsp-set.sh — PostToolUse hook
#
# Sets the LSP-ready flag after mcp__lsp__start_lsp or built-in LSP succeeds.
# Only acts in inspector sessions (gate file must exist for this CLAUDE_AGENT_ID).
#
# Lifecycle: PostToolUse (fires after mcp__lsp__start_lsp|LSP succeeds)
# Pair: inspector-lsp-gate.sh (PreToolUse gate)

AGENT_ID="${CLAUDE_AGENT_ID:-}"
[[ -z "$AGENT_ID" ]] && exit 0

GATE="/tmp/.inspector-gate-${AGENT_ID}"
[[ ! -f "$GATE" ]] && exit 0

touch "/tmp/.inspector-lsp-ready-${AGENT_ID}"
exit 0
