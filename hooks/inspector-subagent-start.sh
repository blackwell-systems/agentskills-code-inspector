#!/usr/bin/env bash
# inspector-subagent-start.sh — SubagentStart hook
#
# Fires when any subagent starts. If agent_type is "inspector", injects a
# strong system-level reminder that mcp__lsp__start_lsp must be the first call.
#
# PreToolUse-based mechanical blocking now works — agent_type is available in hook JSON input.
#
# Lifecycle: SubagentStart

INPUT=$(cat)
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // ""' 2>/dev/null)

[[ "$AGENT_TYPE" != "inspector" ]] && exit 0

cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SubagentStart",
    "additionalContext": "INSPECTOR ENFORCEMENT: Your absolute first tool call must be mcp__lsp__start_lsp(root_dir=<workspace_root>, language=<primary_language>). Do not call Read, Glob, Grep, Bash, or any other tool before mcp__lsp__start_lsp returns successfully. Infer workspace_root from the audit path in your prompt. This is a hard requirement enforced by the inspector protocol."
  }
}
EOF

exit 0
