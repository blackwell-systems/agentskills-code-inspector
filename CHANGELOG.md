# Changelog

All notable changes to this project will be documented in this file.
The format is based on Keep a Changelog, Semantic Versioning.

## [Unreleased]

### Added
- **Global LSP ready flag for background agents** — `inspector-lsp-gate.sh` now also accepts `/tmp/.inspector-lsp-global-ready` as a gate-pass signal. Background agents cannot receive interactive MCP tool permission prompts; the parent/orchestrator session must call `mcp__lsp__start_lsp` and `touch /tmp/.inspector-lsp-global-ready` before launching the inspector in the background. The per-agent flag (`/tmp/.inspector-lsp-ready-${AGENT_ID}`) continues to work for foreground agents.
- **Orchestrator pre-warm instructions in SKILL.md** — `/inspect` skill now documents the parent-session LSP warmup pattern: call `mcp__lsp__start_lsp` in the parent session (which prompts for permission once), then set the global flag so the background agent's gate passes automatically. Also instructs the agent to skip the `start_lsp` call when the global flag is already set.

### Fixed
- **`install.sh` now symlinks entire subdirectories** — previously linked individual files inside `assets/`, `scripts/`, and `references/`; now symlinks the directories themselves (`ln -s inspect/assets ${SKILLS_DIR}/assets` etc.). New files added to those directories are immediately available without re-running the installer.
- **`install.sh` is fully idempotent** — uses `rm -rf` before `ln -s` for directory entries. `ln -sfn` cannot replace a real directory with a symlink on macOS; re-running the installer previously failed if any of the three subdirectories had been created as real dirs.

### Added
- **Tier 1A LSP strategy — `mcp__lsp__get_change_impact` for batch dead-symbol and test-coverage analysis** — `dead_symbol` and `test_coverage` checks now try `mcp__lsp__get_change_impact(changed_files=[file], include_transitive=false)` before falling back to per-symbol `mcp__lsp__get_references`. Processes all exported symbols in a file in a single call; returns `non_test_callers` and `test_callers` per symbol. Eliminates N-call per-symbol loop when Tier 1A is available, improving audit speed on files with many exports.
- **`cross_repo_dead_symbol` check** — new check type activated by `--consumer-repos` flag. Symbols classified as dead locally are verified against consumer repo roots via `mcp__lsp__get_cross_repo_references` before being reported as dead. Symbols found in consumer repos are reclassified as live and annotated `[cross-repo live — N references in consumer repos]`.
- **`--consumer-repos <root,...>` flag** — optional comma-separated list of consumer repo absolute paths. Enables cross-repo dead symbol verification in `dead_symbol` and activates `cross_repo_dead_symbol` check. No effect when absent.
- **LSP tier header in report summary** — the report Summary section now shows which LSP tier was active: `LSP Tier: 1A (get_change_impact)` (Tier 1A batch), `LSP Tier: 1B (get_references)`, `LSP Tier: 2 (built-in LSP)`, or `LSP Tier: 3 (Grep)`.
- **Tier 1A cold-start probe** — inspector performs a probe call to `mcp__lsp__get_change_impact` after LSP warm-up; records availability result before beginning checks. Probe failure is non-fatal; falls back to Tier 1B automatically.
- Added `mcp__lsp__get_change_impact` and `mcp__lsp__get_cross_repo_references` to agent tools frontmatter and SKILL.md allowed-tools.

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
