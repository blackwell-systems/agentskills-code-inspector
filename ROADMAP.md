# Roadmap

## Working

- All 14 check types produce findings with file:line citations and severity tiers
- LSP-first strategy: `mcp__lsp__get_references` used for `dead_symbol` and callee discovery; falls back to Grep with reduced-confidence annotation
- Graceful degradation when lsp-mcp-go is unavailable — built-in `LSP` tool used as fallback; all checks still run
- JSON output (`--json`) with deterministic finding IDs for diff-mode comparison across runs
- `--checks` and `--output` flags
- Mechanical LSP gate — `PreToolUse` hook blocks `Read/Glob/Grep/Bash` until `mcp__lsp__start_lsp` succeeds; scoped to inspector via `agent_type` in hook JSON input

## Planned

### Improved LSP tier detection

Inspector currently requires `mcp__lsp__start_lsp` (lsp-mcp-go) and the gate hook
detects its availability via `PostToolUseFailure`. This makes the agent non-portable for users who
don't have lsp-mcp-go installed.

**Design sketch (revisit when implementing):**

Two tiers exist naturally:
- **Tier 1 (built-in `LSP` tool)** — always available in Claude Code; covers
  `findReferences`, `hover`, `goToDefinition`, `getDocumentSymbols`, `getWorkspaceSymbols`,
  `getSignatureHelp`. Sufficient for most check types.
- **Tier 2 (lsp-mcp-go)** — adds `get_diagnostics`, `call_hierarchy`,
  `get_semantic_tokens`, fuzzy position fallback, multi-language routing.

The hook gate needs to fire on either path — expand `PostToolUse` matcher to
`mcp__lsp__start_lsp|LSP` so the first call to either tool unblocks file reads.

The agent prompt needs a detection step: try `mcp__lsp__start_lsp`; if unavailable,
fall back to built-in `LSP` and note degraded mode in the report summary.

Checks that degrade with Tier 1 only:
- `interface_saturation` — `call_hierarchy` unavailable, falls back to Grep method counting
- `coverage_gap` — `get_diagnostics` unavailable, relies purely on code reading
- All checks still run; affected findings carry `[built-in LSP, reduced confidence]`

**Open questions before implementing:**
- Should degraded mode be transparent in the report or opt-in via a flag?
- Does the `tools:` frontmatter need splitting into required vs optional?
- Can the agent-skills spec's `compatibility` field express optional MCP server dependencies?

