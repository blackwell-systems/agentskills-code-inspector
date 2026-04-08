# Output Format

## Default (markdown)

```
## Summary
- Audited: [list of areas]
- Layer map: [the boundary map committed in Step 0]
- Highest severity: [error / warning / none]
- Signal: [one sentence overall assessment]

## [Area Name]
[For each finding:]
**[check_type]** · [severity] · [confidence: high | reduced]
`file:line` · [LSP findReferences: N | LSP hover: confirmed | LSP unavailable — Grep fallback]
What: [what was found]
Fix: [concrete recommendation]

## All Findings
| Severity | Confidence | Check Type | Finding | Location |
|----------|------------|------------|---------|----------|
...
[sorted error → warning, then high confidence → reduced confidence]

## Not Checked — Out of Scope
[Things excluded by design: areas not requested, check types skipped via --checks, etc.]

## Not Checked — Tooling Constraints
[Things that could not be checked due to tooling: LSP unavailable, cross-repo
inaccessible, file not readable, etc. Each entry should state what was attempted
and why it failed.]
```

## JSON (`--json` flag)

```json
{
  "inspector_version": "0.8.0",
  "timestamp": "<ISO8601>",
  "repo_root": "<absolute path>",
  "areas": ["<area1>", "<area2>"],
  "layer_map": "<committed layer map from Step 0>",
  "architectural_context": "<one sentence: what orientation found>",
  "checks_applied": ["<check_type>"],
  "findings": [
    {
      "id": "<check_type>:<repo-relative-file>:<line>",
      "check_type": "<check type>",
      "severity": "error | warning",
      "confidence": "high | reduced",
      "file": "<repo-relative path>",
      "line": 42,
      "symbol": "<symbol name if applicable>",
      "description": "<what was found>",
      "tool": "LSP findReferences: N | LSP hover: confirmed | LSP unavailable — Grep fallback",
      "recommendation": "<what to do>"
    }
  ],
  "summary": {
    "total": 0,
    "by_severity": { "error": 0, "warning": 0 },
    "by_confidence": { "high": 0, "reduced": 0 },
    "by_check_type": { "<check_type>": 0 },
    "not_checked": {
      "out_of_scope": ["<item>"],
      "tooling_constraints": ["<item>"]
    }
  }
}
```

**Finding ID format:** `<check_type>:<repo-relative-file>:<line>` — e.g. `dead_symbol:pkg/result/codes.go:138`. Deterministic and stable across runs, enabling diff-mode comparison between reports.

**Confidence field:** `"high"` when LSP produced the result; `"reduced"` when Grep fallback was used.

## Persistence (`--output <path>`)

Write the report using the Write tool. Path must be under `inspections/` or end with `-inspection.md` / `-inspection.json`. Format determined by `--json` flag.

The "Not Checked" sections are required in all modes — a clean result is only meaningful if the scope is explicit.
