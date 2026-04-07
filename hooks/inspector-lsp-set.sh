#!/usr/bin/env bash
# inspector-lsp-set.sh — PostToolUse hook for the inspector agent
#
# Sets the LSP-ready flag after mcp__lsp__start_lsp completes successfully.
# Pairs with inspector-lsp-gate.sh.

FLAG="/tmp/.inspector-lsp-ready-${CLAUDE_AGENT_ID:-default}"
touch "$FLAG"
exit 0
