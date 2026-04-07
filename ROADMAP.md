# Roadmap

## Planned

### Graceful degradation for LSP tooling

Inspector currently requires `mcp__lsp__start_lsp` (lsp-mcp-go) and the gate hook
blocks execution until it is called. This makes the agent non-portable for users who
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

---

### Mechanical LSP gate (requires platform support)

Inspector currently uses a `SubagentStart` hook to inject a strong context reminder
to call `mcp__lsp__start_lsp` first. A mechanical block (hook that returns exit 2)
would be more reliable but is not currently achievable because:

- `CLAUDE_AGENT_ID` and `CLAUDE_AGENT_DESCRIPTION` are empty in `PreToolUse` hook
  context when hooks are wired globally via `settings.json`
- `session_id` in `SubagentStart` is the parent's session ID; the child uses a
  different session_id in its own `PreToolUse` calls — the two contexts cannot be
  linked with currently available identifiers
- Agent frontmatter hooks (`hooks:` in `inspector.md`) would solve this if supported,
  but are not active as of Claude Code v2.1.84

**Platform feature request:** expose `agent_type` or `agent_name` in `PreToolUse`
hook payload so hooks can be scoped to the agent currently executing them.

The gate hook code (`inspector-lsp-gate.sh`) is retained and wired in frontmatter —
it will activate automatically when Claude Code adds PreToolUse support for
agent-scoped hooks.
