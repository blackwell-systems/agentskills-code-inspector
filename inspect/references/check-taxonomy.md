# Check Taxonomy

Each check type has a defined tool strategy. Use it rather than improvising.

---

### `dead_symbol`
A symbol is defined but never referenced at runtime.

**Tool strategy:**
1. Locate the symbol definition with Grep to get exact file:line:character
2. **Tier 1A (preferred) — call `mcp__lsp__get_change_impact(changed_files=[file], include_transitive=false)`.** Returns `affected_symbols` with per-symbol `non_test_callers` and `test_callers` counts for all exported symbols in the file at once.
   - `non_test_callers == 0 AND test_callers == 0` → dead
   - `non_test_callers == 0 AND test_callers > 0` → test-only (warning, not dead)
   - Annotate: `[LSP Tier 1A — get_change_impact: N non-test callers, M test callers]`
   - If `mcp__lsp__get_change_impact` is unavailable or errors: proceed to Tier 1B.
3. **Tier 1B (fallback) — call `mcp__lsp__get_references` with the exact file_path, line, and character from step 1.** A dead_symbol finding is invalid without this call (either Tier 1A or Tier 1B must succeed).
4. **If `mcp__lsp__get_references` also errors or is unavailable:** fall back to Grep across the full repo — mark finding as `[LSP unavailable — Grep fallback, reduced confidence]`
5. Zero references outside the definition site = dead. Report the LSP result verbatim: `[LSP findReferences: N references]`

**Optional cross-repo extension (`cross_repo_dead_symbol`):** If `consumer_roots` are provided (via `--consumer-repos` flag), after a symbol is classified dead or test-only by Tier 1A/1B, call `mcp__lsp__get_cross_repo_references(symbol_file, line, column, consumer_roots)`. If any references are found in consumer repos, reclassify as live and annotate: `[cross-repo live — N references in consumer repos]`.

**Severity:** warning if the symbol has a comment suggesting future use; error otherwise.

---

### `layer_violation`
A package or module imports something it should not, crossing a boundary in the layer map established in Step 0.

**Tool strategy:**
1. Read the file's import block
2. Check each import against the layer map from Step 0
3. Trace the dependency direction — A imports B is only a violation if B is downstream of A or if A and B are declared peers that should not depend on each other

**Severity:** error if the import creates a cycle or crosses a hard boundary; warning for soft boundary violations.

---

### `scope_analysis`
A function, class, or module is doing too many things. Natural split points exist.

**Tool strategy:**
1. Read the full function/module
2. List each distinct responsibility (I/O, validation, transformation, coordination, etc.)
3. Identify natural split points — places where a sub-function has a clear single purpose
4. Note nesting depth as a signal (3+ levels often indicates bundled concerns)
5. Compare to peer functions sampled in Step 0 — outliers are more meaningful than absolute thresholds

**Severity:** warning if 3–4 responsibilities; error if 5+ or if a single responsibility spans more than ~100 lines and could be independently tested.

---

### `coverage_gap`
A code path, input scenario, or error condition is not handled and will fail silently or produce incorrect behavior.

**Tool strategy:**
1. Read the validation or control flow logic
2. Enumerate the handled cases explicitly
3. Identify what is NOT handled — edge cases, error returns, missing branches
4. Confirm the gap is reachable (not dead code)

**Severity:** error if the unhandled case is reachable from normal inputs; warning if it requires unusual preconditions.

---

### `silent_failure`
An error is caught, logged, or ignored rather than returned or propagated, allowing execution to continue in a bad state.

**Tool strategy:**
1. Read the function's error handling paths
2. Flag any error that is assigned to `_`, logged without return, or used only in a condition that does not abort the function
3. Check if downstream code depends on state that may be invalid due to the suppressed error

**Severity:** error if downstream state is affected; warning if the suppressed error is truly recoverable.

---

### `duplicate_semantics`
Two or more symbols (error codes, types, functions, constants) represent nearly the same concept, creating ambiguity for callers.

**Tool strategy:**
1. Read the definitions of the candidate symbols
2. Compare their descriptions, names, and emission/call contexts
3. Check if callers distinguish between them or treat them interchangeably

**Severity:** warning if the distinction is documented and intentional; error if callers cannot meaningfully distinguish them.

---

### `cross_field_consistency`
Two or more fields in a struct, schema, or configuration must be consistent with each other, but no validation enforces this.

**Tool strategy:**
1. Read the type or schema definition
2. Identify fields that reference each other (by name, by value range, by meaning)
3. Search the validation layer for checks that enforce the relationship
4. If no check exists, confirm by tracing what happens when the fields are inconsistent
5. Use LSP `hover` on related symbols to verify types and constraints

**Severity:** error if inconsistency causes silent data corruption or a runtime panic; warning if it produces a recoverable error.

---

### `test_coverage`
An exported symbol (function, method, type) has no corresponding test.

**Tool strategy:**
1. Enumerate exported symbols in the area with Grep (`^func [A-Z]`, `^type [A-Z]`, etc.)
2. **Tier 1A (preferred) — call `mcp__lsp__get_change_impact(changed_files=[file], include_transitive=false)` per file.** Use the `test_callers` field for each symbol — this includes enclosing test function names, more precise than Grep. Symbols with `test_callers == 0` lack test coverage. Annotate: `[LSP Tier 1A — get_change_impact: M test callers]`. If unavailable, proceed to Tier 1B.
3. **Tier 1B (fallback) — call `mcp__lsp__get_references` on the symbol definition position** to confirm whether test files are callers. Grep misses aliased calls; LSP gives ground truth.
4. **Grep fallback:** if both Tier 1A and Tier 1B are unavailable, search test files (`*_test.go`, `*.test.ts`, `test_*.py`, etc.) for the symbol name with Grep. Mark as `[LSP unavailable — Grep fallback, reduced confidence]`.
5. Flag symbols with zero test references. Report `[LSP findReferences: N references, M in test files]`

**Severity:** error for public API surface (exported and called externally); warning for internal helpers that are exported but only used within the package.

---

### `error_wrapping`
An error is returned without adding context, making the call stack opaque at the call site.

**Tool strategy:**
1. Read error return paths in the function
2. Flag bare `return err` where `err` came from a call into another package
3. Check the wrapping convention established in Step 0 (e.g., `fmt.Errorf`, `%w`, `errors.Wrap`) — apply consistently with what the codebase already does
4. Do not flag: errors already containing context, sentinel errors intended to be passed through, or errors at the top of the call stack (main, handler boundary)

**Severity:** warning — missing context degrades debuggability but does not cause incorrect behavior.

---

### `doc_drift`
A function's documentation no longer matches its signature or behavior.

**Tool strategy:**
1. Read the function signature and its doc comment
2. **REQUIRED — call `mcp__lsp__get_info_on_location` with the exact file_path, line, and character of the function name.** Gives the canonical signature the compiler sees, independent of what the source text says. A doc_drift finding is invalid without this call.
3. If `mcp__lsp__get_info_on_location` is unavailable: fall back to direct Read — mark finding as `[LSP unavailable — Read fallback, reduced confidence]`
4. Compare hover output against the doc comment: parameter names, types, return values, described behavior. Flag mismatches.

**Severity:** warning — doc drift misleads callers but does not cause runtime failures. Error only if the drift describes incorrect error conditions (caller may suppress errors they shouldn't).

---

### `interface_saturation`
An interface or abstract type has too many methods, preventing callers from using it narrowly.

**Tool strategy:**
1. Read the interface definition and count methods
2. **REQUIRED — call `mcp__lsp__get_references` on the type name position to identify all implementors and callers.** Interface saturation findings are invalid without this call.
3. For each caller, check how many methods it actually uses
4. Check if a coherent subset of the methods forms an independently useful contract

**Language patterns:** Go interfaces, Java/C# abstract classes, Python protocols, TypeScript interfaces, Rust traits.

**Severity:** warning if 6+ methods and callers demonstrably use a narrow subset; error if the interface is the only way to reach a core behavior and splitting it would eliminate a forced dependency on unrelated methods.

---

### `panic_not_recovered`
An unhandled crash occurs in a concurrent or long-running context without a recovery mechanism.

**Tool strategy:**
1. Grep for crash-inducing calls:
   - Go: `panic(`
   - Python: `raise` inside threads/async without try/except
   - JavaScript/TypeScript: `throw` inside async functions or Promise callbacks without `.catch`
   - Rust: `unwrap()`, `expect()` on `Option`/`Result` in async contexts
2. For each site, check if the enclosing concurrent context has a recovery mechanism
3. Flag sites in goroutines, threads, async tasks, or long-running server loops
4. Do not flag: crashes in main entry points or test helpers

**Severity:** error in goroutines/threads/async contexts; warning in synchronous long-running functions where a caller-level handler may exist.

---

### `context_propagation`
A function receives a cancellation token but creates a fresh root context for callees, breaking cancellation propagation.

**Tool strategy:**
1. Grep for functions accepting a cancellation parameter:
   - Go: `ctx context.Context`
   - C#: `CancellationToken`
   - JavaScript/TypeScript: `AbortSignal`, `signal`
2. Within each, grep for fresh root context construction passed to callees:
   - Go: `context.Background()`, `context.TODO()`
   - C#: `new CancellationToken()`
   - JS: `new AbortController()`
3. Flag cases where fresh root replaces the received token
4. Do not flag: derived contexts created from the received one (e.g., `context.WithTimeout(ctx, ...)`)

**Severity:** warning in general; error on request-handling paths where cancellation is critical for resource cleanup.

---

### `init_side_effects`
A module initializer performs observable side effects — I/O, global mutation, network calls.

**Tool strategy:**
1. Grep for module-level initializers:
   - Go: `func init()`
   - Python: module-level statements outside `if __name__ == "__main__"`
   - JavaScript/TypeScript: module-level code with side effects
   - Java/Kotlin: `static {}` blocks
2. Read the body of each initializer
3. Flag: file I/O, network calls, global variable mutation conditioned on external state, process-exit calls
4. Do not flag: registering constants, building lookup tables from compile-time data, pure deterministic assignments

**Severity:** warning — couples test setup to module import order; error if the side effect can fail at import time with no recovery path.

---

### `cross_repo_dead_symbol`
A symbol appears dead within its own repo but may be consumed by external repos that are not indexed by the local LSP server. Only applicable when `--consumer-repos` is provided.

**Tool strategy:**
1. Identify symbols classified as dead or test-only by `dead_symbol` check
2. **REQUIRED — call `mcp__lsp__get_cross_repo_references(symbol_file, line, column, consumer_roots)` for each candidate.** `consumer_roots` comes from the `--consumer-repos` flag (comma-separated list of absolute repo root paths).
3. If any references are returned from consumer repos: reclassify as live. Annotate: `[cross-repo live — N references in consumer repos]`. Remove from dead_symbol report.
4. If zero cross-repo references: confirm dead across all known consumers. Annotate: `[cross-repo verified dead — checked N consumer repos]`.
5. If `mcp__lsp__get_cross_repo_references` is unavailable or errors: skip cross-repo check. Note in "Not Checked — Tooling Constraints" section.

**Severity:** inherited from the underlying dead_symbol finding. Cross-repo verification upgrades confidence, not severity.

**Note:** This check only runs when `--consumer-repos` is provided. It does not appear in reports when the flag is absent.
