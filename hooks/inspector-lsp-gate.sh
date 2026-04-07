#!/usr/bin/env bash
# inspector-lsp-gate.sh — PreToolUse hook
#
# Blocks Read, Glob, Grep, and Bash in inspector sessions until LSP is initialized.
# Gate file is keyed on CLAUDE_AGENT_ID, set by inspector-subagent-start.sh.
#
# Lifecycle: PreToolUse (fires before Read|Glob|Grep|Bash)
# Pair: inspector-subagent-start.sh (SubagentStart), inspector-lsp-set.sh (PostToolUse)

AGENT_ID="${CLAUDE_AGENT_ID:-}"
[[ -z "$AGENT_ID" ]] && exit 0

GATE="/tmp/.inspector-gate-${AGENT_ID}"
READY="/tmp/.inspector-lsp-ready-${AGENT_ID}"

# Not an inspector session — pass through
[[ ! -f "$GATE" ]] && exit 0

# LSP already initialized — pass through
[[ -f "$READY" ]] && exit 0

echo "BLOCKED: Call mcp__lsp__start_lsp(root_dir=<workspace>, language=<lang>) before reading any files." >&2
exit 2
