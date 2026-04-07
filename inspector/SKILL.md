---
name: inspector
description: >
  Use /inspect to run a structured code quality audit on one or more areas of the
  codebase. Inspector applies a fixed check taxonomy (dead_symbol, layer_violation,
  scope_analysis, coverage_gap, silent_failure, duplicate_semantics, test_coverage,
  error_wrapping, doc_drift, interface_saturation, panic_not_recovered,
  context_propagation, init_side_effects, cross_field_consistency) and returns a
  severity-tiered findings report. Use it before major refactors, after large merges,
  or when you want a systematic quality sweep of an unfamiliar area.
---

# Inspector: Code Quality Audit

Invoke the `inspector` agent with the areas to audit and optional flags.

## Usage

```
/inspect <area> [<area2> ...] [--checks <type1>,<type2>] [--output <path>] [--json]
```

**`area`** — path, package, or description. Examples:
- `internal/session/`
- `cmd/lsp-mcp-go/server.go`
- `the authentication middleware`

**`--checks`** — run only specific check types:
```
/inspect src/api/ --checks dead_symbol,error_wrapping
```

**`--output`** — write report to file (must be under `inspections/` or end with `-inspection.md`):
```
/inspect internal/ --output inspections/internal-audit.md
```

**`--json`** — emit structured JSON instead of markdown.

## What inspector checks

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

## LSP requirement

Inspector uses LSP for all symbol-level checks. The hook enforces this — `mcp__lsp__start_lsp` is called automatically before any file reads. For Go codebases, gopls must be installed. For TypeScript, tsserver. For Python, pyright or pylsp.

## Examples

```
/inspect internal/session/
/inspect cmd/server.go internal/tools/ --checks dead_symbol,silent_failure
/inspect . --output inspections/full-audit.md
```
