# Changelog

All notable changes to this project will be documented in this file.
The format is based on Keep a Changelog, Semantic Versioning.

## [Unreleased]

### Changed
- Consolidated `/inspector` and `/inspect` skills into a single canonical `/inspect` skill
- Promoted the more complete `/inspect` skill (with schema and validator) as the canonical version; removed the simpler `/inspector` SKILL.md
- Added `inspector/assets/schema.json` and `inspector/scripts/validate-report` to the repo — previously lived only in `~/.claude/skills/inspect/` outside version control
- Updated `install.sh` to install to `~/.claude/skills/inspect/` and symlink all three skill files (SKILL.md, assets/schema.json, scripts/validate-report)

### Added
- Initial inspector agent (`inspector.md`) — code quality audit agent for Claude Code
- Check taxonomy covering 14 check types: `dead_symbol`, `layer_violation`, `scope_analysis`, `coverage_gap`, `silent_failure`, `duplicate_semantics`, `cross_field_consistency`, `test_coverage`, `error_wrapping`, `doc_drift`, `interface_saturation`, `panic_not_recovered`, `context_propagation`, `init_side_effects`
- LSP-first tool strategy for all symbol-level checks — `mcp__lsp__*` tools used before Grep fallback; findings annotated with confidence level
- 19 LSP tools wired in agent frontmatter: `start_lsp`, `open_document`, `get_diagnostics`, `get_references`, `get_info_on_location`, `get_document_symbols`, `get_workspace_symbols`, `call_hierarchy`, `go_to_definition`, `go_to_implementation`, `go_to_type_definition`, `get_signature_help`, `get_semantic_tokens`
- LSP enforcement hooks — `inspector-lsp-gate.sh` blocks `Read|Glob|Grep` until `mcp__lsp__start_lsp` has been called; `inspector-lsp-set.sh` sets the ready flag on success; keyed per `CLAUDE_AGENT_ID` for concurrent safety
- Hooks wired in agent frontmatter (`PreToolUse`, `PostToolUse`) — no `settings.json` changes required on install
- `/inspect` skill (`inspector/SKILL.md`) following the agent-skills.io specification
- Progressive disclosure structure — `inspector.md` core (80 lines) loads `references/check-taxonomy.md` eagerly and `references/output-format.md` lazily at report-writing time
- Dual output formats: markdown (default) and JSON (`--json` flag) with deterministic finding IDs (`<check_type>:<file>:<line>`) for diff-mode comparison across runs
- `--checks` flag for targeted audits, `--output` flag for report persistence under `inspections/`
- `install.sh` — idempotent, symlinks agent, hooks, and skill into `~/.claude/agents/`, `~/.claude/agents/hooks/`, and `~/.claude/skills/inspector/`; no `settings.json` mutations
- Graceful degradation via `PostToolUseFailure` on `mcp__lsp__start_lsp` — when lsp-mcp-go is unavailable, `inspector-lsp-fallback.sh` injects context directing the agent to initialize via the built-in `LSP` tool instead; `PostToolUse` matcher expanded to `mcp__lsp__start_lsp|LSP` so the gate clears on either path; all 14 checks still run at Tier 1 with reduced confidence noted on `call_hierarchy` findings
