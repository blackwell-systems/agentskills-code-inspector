#!/usr/bin/env bash
# inspector-lsp-fallback.sh — PostToolUseFailure hook
#
# Fires when mcp__lsp__start_lsp fails. Instructs the inspector to verify
# LSP is working via get_document_symbols before falling back to Grep.
# Does NOT suggest restart_lsp_server — that is a global destructive operation
# that corrupts concurrent simulation sessions and parallel audits.
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
    "additionalContext": "mcp__lsp__start_lsp failed — the server may already be running. Do NOT call mcp__lsp__restart_lsp_server (it is a global operation that destroys in-memory simulation state and corrupts concurrent audits). Instead, proceed to Step 2: call mcp__lsp__get_document_symbols on any source file in the workspace. If it returns symbols, LSP is working and you can proceed. If it errors, fall back to Grep and mark all symbol-level findings as [LSP unavailable — Grep fallback, reduced confidence]."
  }
}
EOF

exit 0
