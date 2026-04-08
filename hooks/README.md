# Hooks

These scripts are installed to `~/.claude/agents/hooks/` by `install.sh` and wired in `inspector.md` frontmatter. They enforce LSP initialization before any file reads.

| Script | Event | Purpose |
|--------|-------|---------|
| `inspector-subagent-start.sh` | `SubagentStart` | Injects a context reminder to call `mcp__lsp__start_lsp` before reading files |
| `inspector-lsp-gate.sh` | `PreToolUse` | Blocks `Read/Glob/Grep/Bash` until LSP is initialized; scoped to inspector via `agent_type` in hook JSON input |
| `inspector-lsp-set.sh` | `PostToolUse` | Sets the LSP-ready flag when `mcp__lsp__start_lsp` or the built-in `LSP` tool succeeds |
| `inspector-lsp-fallback.sh` | `PostToolUseFailure` | Fires when `mcp__lsp__start_lsp` fails (lsp-mcp-go not installed); injects context to use the built-in `LSP` tool instead |

All hooks are scoped to the inspector agent and no-op for other agents.
