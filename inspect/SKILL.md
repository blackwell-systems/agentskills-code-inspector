---
name: inspect
description: Launch a code quality inspector agent to audit defined areas of a codebase. Language-agnostic. Applies a fixed check taxonomy — dead symbols, layer violations, scope overload, coverage gaps, silent failures, duplicate semantics, cross-field consistency, missing tests on exported symbols, unwrapped errors, doc drift, interface saturation, unrecovered panics, context propagation breaks, and init side effects — using LSP-first tool strategies. Returns a severity-tiered findings report with per-finding confidence levels. Supports --json for structured output, --output for persistence, and --checks to target specific check types. Use when auditing files, packages, or cross-cutting concerns for any of these patterns.
compatibility: Designed for Claude Code. Requires an agent runtime that supports subagent delegation.
allowed-tools: Agent(subagent_type=inspector)
argument-hint: "<path-or-description> [<path-or-description> ...] [--json] [--output <path>] [--checks <type1>,<type2>]"
user-invocable: true
metadata:
  schema: assets/schema.json
  validator: scripts/validate-report
---

# /inspect — Code Quality Inspection

Launch an inspector agent to audit one or more areas of the codebase.

## Usage

```
/inspect <area> [<area> ...] [--json] [--output <path>] [--checks <type1>,<type2>]
```

Areas can be:
- A file path: `/inspect pkg/result/codes.go`
- A package: `/inspect pkg/engine`
- A description: `/inspect "error handling across the validation layer"`
- Multiple areas: `/inspect pkg/result/codes.go pkg/protocol/validation.go`

**Flags:**
- `--json` — emit structured JSON instead of markdown (machine-readable, enables downstream tooling)
- `--output <path>` — persist report to disk; path must be under `inspections/` or end in
  `-inspection.md` / `-inspection.json`. Example: `--output docs/inspections/2026-04-04.md`
- `--checks <type1>,<type2>` — apply only the listed check types, skipping others. Example:
  `--checks dead_symbol,layer_violation`

## What it checks

The inspector applies these checks where relevant — you do not need to specify them:

| Check | What it finds |
|-------|--------------|
| `dead_symbol` | Defined but never referenced (uses `mcp__lsp__get_references` → high confidence; Grep fallback → low confidence) |
| `layer_violation` | Import crosses an architectural boundary |
| `scope_analysis` | Function or module doing too many things |
| `coverage_gap` | Unhandled input, error, or code path |
| `silent_failure` | Error suppressed rather than returned |
| `duplicate_semantics` | Two symbols that mean the same thing |
| `cross_field_consistency` | Related fields with no consistency enforcement |
| `test_coverage` | Exported symbol with no test references |
| `error_wrapping` | Error returned without context (opaque call stack) |
| `doc_drift` | Function documentation no longer matches its signature |
| `interface_saturation` | Interface with too many methods; callers use a narrow subset |
| `panic_not_recovered` | Unhandled crash in a goroutine, thread, or async context |
| `context_propagation` | Function receives a context/token but creates a fresh root for callees |
| `init_side_effects` | Module initializer performs I/O, network calls, or global mutation |

## Execution

Launch the inspector agent with the user's areas as input. Pass the current working
directory as the repo root. **Always set `run_in_background: true`** so the audit runs
asynchronously and the user can continue working while it runs.

```
Launch inspector agent with:
- Areas to inspect: [user's areas]
- Repo root: [resolve the actual repo root from the area path — e.g. if area is /Users/x/code/my-repo/pkg/foo, repo root is /Users/x/code/my-repo]
- Flags: pass through --json, --output, --checks as provided
- run_in_background: true
- Instructions: apply the check taxonomy, report findings with severity and file:line citations
- First instruction to agent: run the Step 0 cold-start sequence below (restart_lsp_server → start_lsp → open_document per package → warm-up check) before any other operation
```

**Critical: LSP tool usage.** Include this instruction verbatim in the inspector agent's
launch prompt — the agent definition alone is not sufficient:

> **LSP enforcement:** You have two LSP tool surfaces. Use them in this priority order:
>
> **Step 0 — cold-start sequence (required, do this first, in order):**
>
> 1. **Restart the server** to clear any prior workspace binding from earlier in the session:
>    `mcp__lsp__restart_lsp_server()`
>
> 2. **Re-initialize** pointing at the correct repo root:
>    `mcp__lsp__start_lsp(root_dir="<repo_root>")`
>
> 3. **Open one file per package** you plan to audit. gopls does not index a package
>    until at least one file in it is opened. Without this, `get_references` returns
>    "no package metadata" for all symbols in that package:
>    ```
>    mcp__lsp__open_document(file_path="<repo_root>/internal/lsp/client.go", language_id="go")
>    mcp__lsp__open_document(file_path="<repo_root>/internal/tools/workspace.go", language_id="go")
>    # … one representative file per package being audited
>    ```
>
> 4. **Warm-up check (mandatory before trusting zero-reference results):**
>    Pick one symbol you know is actively used (e.g. a widely-called function in the
>    first package). Call `get_references` on it. If it returns `[]`, the workspace
>    is not yet indexed — wait 3–5 seconds and retry. Do not proceed to dead-symbol
>    checks until a known-active symbol returns ≥ 1 reference.
>
> **1. `mcp__lsp__get_references` (preferred for `dead_symbol`):**
> Call this for all reference lookups. Returns 1-based locations.
> Example: `mcp__lsp__get_references(file_path="/abs/path/file.go", language_id="go", line=22, column=6)`
> Zero results = dead symbol (high confidence). If the call errors, fall back to option 2.
>
> **2. `LSP` built-in tool (fallback or for hover/other operations):**
> Use for hover, go-to-definition, and as fallback when `mcp__lsp-mcp` is unavailable.
> `LSP(operation="hover", filePath="/abs/path/file.ts", line=14, character=10)`
>
> Do NOT shell out to gopls/rust-analyzer/tsserver via Bash.
> If both LSP surfaces fail, fall back to Grep and annotate as reduced confidence.

The agent works autonomously. When it completes you will be notified — surface the report
directly to the user at that point.

## JSON output and validation

When `--json` is passed, the agent emits a structured report conforming to
[assets/schema.json](assets/schema.json). To validate a report:

```bash
scripts/validate-report report.json
# or: cat report.json | scripts/validate-report
```

Exit 0 = valid, 1 = schema errors, 2 = usage error.
