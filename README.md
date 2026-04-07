[![Blackwell Systems™](https://raw.githubusercontent.com/blackwell-systems/blackwell-docs-theme/main/badge-trademark.svg)](https://github.com/blackwell-systems)
[![Agent Skills](assets/badge-agentskills.svg)](https://agentskills.io)

# inspector

Structured code quality audits for AI coding agents. Inspector applies a fixed check taxonomy against one or more areas of a codebase and returns a severity-tiered findings report with LSP-backed confidence annotations.

## Features

- **14 check types** — dead symbols, layer violations, scope analysis, coverage gaps, silent failures, duplicate semantics, test coverage, error wrapping, doc drift, interface saturation, unrecovered panics, context propagation, init side effects, cross-field consistency
- **LSP-first** — symbol-level checks use `mcp__lsp__*` tools before falling back to Grep; every finding is annotated with its source tool and confidence level
- **LSP gate hook** — enforced via agent frontmatter hooks; `mcp__lsp__start_lsp` must be called before any file reads
- **Dual output** — markdown (default) or JSON (`--json`) with deterministic finding IDs for diff-mode comparison across runs
- **Targeted audits** — `--checks dead_symbol,error_wrapping` to run specific check types only
- **Report persistence** — `--output inspections/audit.md` to write findings to file

## Install

```bash
git clone https://github.com/blackwell-systems/agentskills-code-inspector
cd agentskills-code-inspector
./install.sh
```

Installs:
- `~/.claude/agents/inspector.md` — Claude Code agent definition
- `~/.claude/agents/hooks/inspector-lsp-{gate,set}.sh` — LSP enforcement hooks
- `~/.claude/skills/inspector/SKILL.md` — `/inspect` skill

No `settings.json` changes required. Hooks are wired in agent frontmatter.

## Usage

```
/inspect <area> [<area2> ...] [--checks <types>] [--output <path>] [--json]
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

Inspector is published as an [Agent Skill](https://agentskills.io) — a portable, tool-agnostic package for adding capabilities to AI coding agents. The `inspector/SKILL.md` follows the agent-skills.io open standard.
