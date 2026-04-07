#!/usr/bin/env bash
# inspector-subagent-start.sh — SubagentStart hook
#
# Fires when any subagent starts. If agent_type is "inspector", creates a
# session-scoped gate file that the PreToolUse hook uses to identify inspector
# sessions. Uses session_id (present in all hook payloads) as the linking key.
#
# Lifecycle: SubagentStart
# Pair: inspector-lsp-gate.sh (PreToolUse gate), inspector-lsp-set.sh (PostToolUse)

INPUT=$(cat)
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // ""' 2>/dev/null)
SESSION_ID=$(echo "$INPUT"  | jq -r '.session_id // ""'  2>/dev/null)

[[ "$AGENT_TYPE" != "inspector" ]] && exit 0
[[ -z "$SESSION_ID" ]] && exit 0

touch "/tmp/.inspector-gate-${SESSION_ID}"
exit 0
