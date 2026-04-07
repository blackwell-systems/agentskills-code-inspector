#!/usr/bin/env bash
# inspector-lsp-fallback.sh — PostToolUseFailure hook
#
# Fires when mcp__lsp__start_lsp fails. Instructs the inspector to try
# mcp__lsp__restart_lsp_server before giving up on LSP entirely.
#
# Background: the MCP server connection propagates to subagents, but the
# server may be running against a different workspace root from a prior session.
# restart_lsp_server forces it onto the correct root without needing a new
# connection. The built-in LSP tool is NOT available in subagents.
#
# Lifecycle: PostToolUseFailure (fires when mcp__lsp__start_lsp fails)
# Pair: inspector-lsp-gate.sh (PreToolUse gate), inspector-lsp-set.sh (PostToolUse on LSP)

AGENT_ID="${CLAUDE_AGENT_ID:-}"
[[ -z "$AGENT_ID" ]] && exit 0

GATE="/tmp/.inspector-gate-${AGENT_ID}"
[[ ! -f "$GATE" ]] && exit 0

cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUseFailure",
    "additionalContext": "mcp__lsp__start_lsp failed — the LSP server may already be running with a different workspace root. Do NOT fall back to Grep yet. Execute the recovery sequence: (1) Call mcp__lsp__restart_lsp_server(root_dir=<workspace>) to force the server onto the correct workspace. (2) If that succeeds, verify with mcp__lsp__get_document_symbols on any source file. (3) Only if both fail: proceed with Grep fallback and note [LSP unavailable — Grep fallback, reduced confidence] in the report. The built-in LSP tool is not available — do not attempt to call it."
  }
}
EOF

exit 0
