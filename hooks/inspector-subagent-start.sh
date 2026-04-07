#!/usr/bin/env bash
# inspector-subagent-start.sh — SubagentStart hook
#
# Fires when any subagent starts. If the agent is "inspector", creates a gate
# file keyed on CLAUDE_AGENT_ID, which is also available inside the running
# child's PreToolUse hooks — the only identifier consistent across both contexts.
#
# Lifecycle: SubagentStart
# Pair: inspector-lsp-gate.sh (PreToolUse), inspector-lsp-set.sh (PostToolUse)

INPUT=$(cat)
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // ""' 2>/dev/null)
AGENT_DESC="${CLAUDE_AGENT_DESCRIPTION:-}"

# Identify inspector by agent_type field or description
if [[ "$AGENT_TYPE" != "inspector" && "$AGENT_DESC" != *"inspector"* ]]; then
  exit 0
fi

# CLAUDE_AGENT_ID in SubagentStart context is the child agent's ID —
# the same value the child sees in its own hook executions.
AGENT_ID="${CLAUDE_AGENT_ID:-}"
[[ -z "$AGENT_ID" ]] && exit 0

touch "/tmp/.inspector-gate-${AGENT_ID}"
exit 0
