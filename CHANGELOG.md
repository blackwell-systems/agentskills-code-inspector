# Changelog

All notable changes to this project will be documented in this file.
The format is based on Keep a Changelog, Semantic Versioning.

## [Unreleased]

### Fixed
- **LSP cold-start sequence in `/inspect` launch instructions** — `start_lsp` alone does not guarantee a usable workspace when gopls is already bound to a prior session's root. The Step 0 sequence now requires three ordered steps before any LSP query: (1) `restart_lsp_server` to clear prior workspace binding, (2) `start_lsp(root_dir=...)` to point at the correct repo, (3) `open_document` on one representative file per audited package (gopls does not index a package until a file in it is opened). A mandatory warm-up check — calling `get_references` on a known-active symbol and verifying it returns ≥ 1 result before proceeding — is also required, matching the pattern established in `/lsp-dead-code`. Without these steps, `get_references` returns "no package metadata" for all internal packages and dead-symbol checks silently fall back to Grep with reduced confidence.

### Changed
- Rewrote all hooks (`inspector-lsp-gate.sh`, `inspector-lsp-set.sh`, `inspector-lsp-fallback.sh`) to read `agent_type` and `agent_id` from JSON stdin instead of `$CLAUDE_AGENT_ID` env var — the env var is empty when hooks fire from global `settings.json` context; JSON input fields are always populated inside subagent calls
- Mechanical LSP gate is now active: `PreToolUse` hook blocks `Read/Glob/Grep/Bash` until `mcp__lsp__start_lsp` succeeds; no longer advisory-only
- Removed gate sentinel file (`/tmp/.inspector-gate-*`) — `agent_type == "inspector"` from JSON input now serves as the identity check directly
- Fixed `PostToolUse` matcher to include built-in LSP: `"mcp__lsp__start_lsp"` → `"mcp__lsp__start_lsp|LSP"` — graceful degradation path was broken (gate blocked forever on fallback)
- Fixed `validate-report` injection vector: `${INPUT}` was interpolated into Python triple-quoted string; now passed via stdin
- Fixed `rmdir --ignore-fail-on-non-empty` in uninstall — GNU-only flag; plain `rmdir` already refuses non-empty directories
- Fixed SKILL.md tool name references: `mcp__lsp-mcp__*` → `mcp__lsp__*` to match actual MCP server namespace
- Removed `mcp__lsp__restart_lsp_server` from agent tools frontmatter — was listed but explicitly prohibited in body text
- Added `inspect/references/` symlinks to `install.sh` — reference files (check-taxonomy.md, output-format.md) were not installed, causing agent to fail loading taxonomy
- Aligned version strings across agent (v0.8.0), schema (`$id`), and output-format example
- Fixed README install path: `~/.claude/skills/inspector/` → `~/.claude/skills/inspect/`
- Fixed stale `inspector/SKILL.md` path references in README and CHANGELOG
- Added prerequisites section to README (lsp-mcp-go dependency)

### Changed
- Consolidated `/inspector` and `/inspect` skills into a single canonical `/inspect` skill
- Promoted the more complete `/inspect` skill (with schema and validator) as the canonical version; removed the simpler `/inspector` SKILL.md
- Added `inspect/assets/schema.json` and `inspect/scripts/validate-report` to the repo — previously lived only in `~/.claude/skills/inspect/` outside version control
- Updated `install.sh` to install to `~/.claude/skills/inspect/` and symlink all three skill files (SKILL.md, assets/schema.json, scripts/validate-report)
- Renamed `inspector/` skill directory to `inspect/` to match the `name: inspect` field required by the agent-skills.io specification
- Promoted `argument-hint` and `user-invocable` to top-level frontmatter fields so Claude Code renders hint text on `/inspect`

### Added
- Initial inspector agent (`inspector.md`) — code quality audit agent for Claude Code
- Check taxonomy covering 14 check types: `dead_symbol`, `layer_violation`, `scope_analysis`, `coverage_gap`, `silent_failure`, `duplicate_semantics`, `cross_field_consistency`, `test_coverage`, `error_wrapping`, `doc_drift`, `interface_saturation`, `panic_not_recovered`, `context_propagation`, `init_side_effects`
- LSP-first tool strategy for all symbol-level checks — `mcp__lsp__*` tools used before Grep fallback; findings annotated with confidence level
- 19 LSP tools wired in agent frontmatter: `start_lsp`, `open_document`, `get_diagnostics`, `get_references`, `get_info_on_location`, `get_document_symbols`, `get_workspace_symbols`, `call_hierarchy`, `go_to_definition`, `go_to_implementation`, `go_to_type_definition`, `get_signature_help`, `get_semantic_tokens`
- LSP enforcement hooks — `inspector-lsp-gate.sh` blocks `Read|Glob|Grep` until `mcp__lsp__start_lsp` has been called; `inspector-lsp-set.sh` sets the ready flag on success; keyed per `agent_id` from hook JSON input for concurrent safety
- Hooks wired in agent frontmatter (`PreToolUse`, `PostToolUse`) — no `settings.json` changes required on install
- `/inspect` skill (`inspect/SKILL.md`) following the agent-skills.io specification
- Progressive disclosure structure — `inspector.md` core loads `references/check-taxonomy.md` eagerly and `references/output-format.md` lazily at report-writing time
- Dual output formats: markdown (default) and JSON (`--json` flag) with deterministic finding IDs (`<check_type>:<file>:<line>`) for diff-mode comparison across runs
- `--checks` flag for targeted audits, `--output` flag for report persistence under `inspections/`
- `install.sh` — idempotent, symlinks agent, hooks, and skill into `~/.claude/agents/`, `~/.claude/agents/hooks/`, and `~/.claude/skills/inspect/`; no `settings.json` mutations
- Graceful degradation via `PostToolUseFailure` on `mcp__lsp__start_lsp` — when lsp-mcp-go is unavailable, `inspector-lsp-fallback.sh` injects context directing the agent to initialize via the built-in `LSP` tool instead; `PostToolUse` matcher expanded to `mcp__lsp__start_lsp|LSP` so the gate clears on either path; all 14 checks still run at Tier 1 with reduced confidence noted on `call_hierarchy` findings
