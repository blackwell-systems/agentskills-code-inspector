#!/usr/bin/env bash
# inspector-lsp-gate.sh — PreToolUse hook
#
# Blocks Read, Glob, Grep, and Bash in inspector sessions until LSP is initialized.
#
# NOTE: This hook is wired in inspector.md frontmatter for when Claude Code
# supports agent-scoped PreToolUse hooks. It cannot work reliably from
# global settings.json because CLAUDE_AGENT_ID is empty in that context.
# See ROADMAP.md for the platform feature request.
#
# Lifecycle: PreToolUse (fires before Read|Glob|Grep|Bash)
# Pair: inspector-subagent-start.sh (SubagentStart), inspector-lsp-set.sh (PostToolUse)

AGENT_ID="${CLAUDE_AGENT_ID:-}"
[[ -z "$AGENT_ID" ]] && exit 0

GATE="/tmp/.inspector-gate-${AGENT_ID}"
READY="/tmp/.inspector-lsp-ready-${AGENT_ID}"

[[ ! -f "$GATE" ]] && exit 0
[[ -f "$READY" ]] && exit 0

echo "BLOCKED: Call mcp__lsp__start_lsp(root_dir=<workspace>, language=<lang>) before reading any files." >&2
exit 2
