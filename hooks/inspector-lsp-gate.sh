#!/usr/bin/env bash
# inspector-lsp-gate.sh — PreToolUse hook for the inspector agent
#
# Blocks Read, Glob, and Grep until mcp__lsp__start_lsp has been called.
# Keyed on CLAUDE_AGENT_ID so concurrent inspector runs don't share state.
#
# Lifecycle: PreToolUse (fires before Read|Glob|Grep)
# Pair: inspector-lsp-set.sh (PostToolUse on mcp__lsp__start_lsp)

FLAG="/tmp/.inspector-lsp-ready-${CLAUDE_AGENT_ID:-default}"

if [ ! -f "$FLAG" ]; then
  echo "BLOCKED: Call mcp__lsp__start_lsp(root_dir=<workspace>, language=<lang>) before reading any files." >&2
  exit 2
fi

exit 0
