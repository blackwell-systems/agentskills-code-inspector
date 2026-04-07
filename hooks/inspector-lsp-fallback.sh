#!/usr/bin/env bash
# inspector-lsp-fallback.sh — PostToolUseFailure hook
#
# Fires when mcp__lsp__start_lsp fails. Injects context directing the agent
# to initialize via the built-in LSP tool instead. Only acts in inspector sessions.
#
# Lifecycle: PostToolUseFailure (fires when mcp__lsp__start_lsp fails)
# Pair: inspector-lsp-gate.sh (PreToolUse gate), inspector-lsp-set.sh (PostToolUse on LSP)

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null)

[[ -z "$SESSION_ID" ]] && exit 0

GATE="/tmp/.inspector-gate-${SESSION_ID}"
[[ ! -f "$GATE" ]] && exit 0

cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUseFailure",
    "additionalContext": "mcp__lsp__start_lsp failed — lsp-mcp-go is not available. Use the built-in LSP tool to initialize instead: call LSP(operation=\"hover\", filePath=\"<any file in the workspace>\", line=1, character=1). This unblocks the gate. All 14 check types will still run at Tier 1 (built-in LSP). Note reduced confidence on call_hierarchy findings in the report summary: [lsp-mcp-go unavailable — built-in LSP, Tier 1 mode]"
  }
}
EOF

exit 0
