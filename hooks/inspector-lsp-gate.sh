#!/usr/bin/env bash
# inspector-lsp-gate.sh — PreToolUse hook
#
# Blocks Read, Glob, Grep, and Bash in inspector sessions until LSP is initialized.
# Reads agent_type and agent_id from JSON stdin (available when hook fires inside a subagent).
#
# Lifecycle: PreToolUse (fires before Read|Glob|Grep|Bash)
# Pair: inspector-lsp-set.sh (PostToolUse), inspector-lsp-fallback.sh (PostToolUseFailure)

INPUT=$(cat)
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // ""' 2>/dev/null)
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // ""' 2>/dev/null)

[[ "$AGENT_TYPE" != "inspector" ]] && exit 0
[[ -z "$AGENT_ID" ]] && exit 0

READY="/tmp/.inspector-lsp-ready-${AGENT_ID}"
[[ -f "$READY" ]] && exit 0

# Also accept a global ready flag set by the parent session (e.g. when orchestrator
# pre-warms LSP before launching the inspector agent in background mode).
GLOBAL_READY="/tmp/.inspector-lsp-global-ready"
[[ -f "$GLOBAL_READY" ]] && exit 0

echo "BLOCKED: Call mcp__lsp__start_lsp(root_dir=<workspace_root>) before reading any files." >&2
exit 2
