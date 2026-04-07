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
  echo '{"decision":"block","reason":"BLOCKED: You must call mcp__lsp__start_lsp(root_dir=<workspace>, language=<lang>) before reading any files. This is the mandatory first action for the inspector agent."}'
  exit 0
fi

exit 0
