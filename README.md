[![Blackwell Systems™](https://raw.githubusercontent.com/blackwell-systems/blackwell-docs-theme/main/badge-trademark.svg)](https://github.com/blackwell-systems)
[![Agent Skills](assets/badge-agentskills.svg)](https://agentskills.io)

# /inspect

Structured code quality audits for AI coding agents. Inspector applies a fixed check taxonomy against one or more areas of a codebase and returns a severity-tiered findings report with LSP-backed confidence annotations.

## Features

- **14 check types** — dead symbols, layer violations, scope analysis, coverage gaps, silent failures, duplicate semantics, test coverage, error wrapping, doc drift, interface saturation, unrecovered panics, context propagation, init side effects, cross-field consistency
- **LSP-first with Tier 1A batch analysis** — `dead_symbol` and `test_coverage` use `mcp__lsp__get_change_impact` for whole-file batch symbol analysis before falling back to per-symbol `mcp__lsp__get_references` (Tier 1B), built-in LSP (Tier 2), or Grep (Tier 3); every finding is annotated with its source tool, confidence level, and active LSP tier
- **LSP gate hook** — enforced via agent frontmatter hooks; `mcp__lsp__start_lsp` must be called before any file reads
- **Dual output** — markdown (default) or JSON (`--json`) with deterministic finding IDs for diff-mode comparison across runs
- **Targeted audits** — `--checks dead_symbol,error_wrapping` to run specific check types only
- **Cross-repo dead symbol verification** — `--consumer-repos /path/to/consumer1,/path/to/consumer2` checks symbols against external consumer repos before classifying them as dead; activates the `cross_repo_dead_symbol` check
- **Report persistence** — `--output inspections/audit.md` to write findings to file

## Install

```bash
git clone https://github.com/blackwell-systems/agentskills-code-inspector
cd agentskills-code-inspector
./install.sh
```

**Prerequisites:** An agent runtime that supports subagent delegation and tool use (e.g. Claude Code). The [agent-lsp](https://github.com/blackwell-systems/agent-lsp) MCP server is recommended for full LSP capabilities (`call_hierarchy`, `get_diagnostics`, `get_change_impact`, multi-language routing). If unavailable, inspector automatically falls back to the runtime's built-in LSP tool — most checks work fine, a few degrade (`interface_saturation` without call hierarchy). If both LSP tiers fail, Grep is used with reduced-confidence annotations. All 14 checks run in all modes.

Installs (Claude Code paths):
- `~/.claude/agents/inspector.md` — agent definition
- `~/.claude/agents/hooks/inspector-lsp-{gate,set}.sh` — LSP enforcement hooks
- `~/.claude/skills/inspect/SKILL.md` — `/inspect` skill

No `settings.json` changes required. Hooks are wired in agent frontmatter.

## Usage

```
/inspect <area> [<area2> ...] [--checks <types>] [--output <path>] [--json] [--consumer-repos <root,...>]
```

```
/inspect internal/session/
/inspect cmd/server.go internal/tools/ --checks dead_symbol,silent_failure
/inspect . --output inspections/full-audit.md
```

## Check Types

| Check | What it finds |
|-------|--------------|
| `dead_symbol` | Exported symbols with no callers |
| `layer_violation` | Import direction violations |
| `scope_analysis` | Functions doing too many things |
| `coverage_gap` | Unhandled code paths |
| `silent_failure` | Suppressed errors |
| `duplicate_semantics` | Near-duplicate types or error codes |
| `test_coverage` | Exported symbols with no tests |
| `error_wrapping` | Bare `return err` losing context |
| `doc_drift` | Docs that no longer match the code |
| `interface_saturation` | Interfaces with too many methods |
| `panic_not_recovered` | Unrecovered panics in goroutines |
| `context_propagation` | Fresh root contexts discarding cancellation |
| `init_side_effects` | Module initializers with I/O or global mutation |
| `cross_field_consistency` | Struct fields with unenforced invariants |

## Agent Skills

Inspector is published as an [Agent Skill](https://agentskills.io) — a portable, tool-agnostic package for adding capabilities to AI coding agents. The `inspect/SKILL.md` follows the agent-skills.io open standard.
