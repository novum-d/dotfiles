# Continue Rules

## Context Usage

- Read repo-map before large edits
- Prefer repo-map and search before opening many files
- Inspect surrounding files before refactoring
- Inspect imports before proposing fixes
- Inspect existing architecture before adding abstractions
- Read only the files necessary for the current task
- Avoid scanning unrelated directories
- Prefer minimal diffs

---

## Editing

- Preserve formatting style
- Avoid unrelated changes
- Do not rewrite entire files unnecessarily
- Avoid rewriting working code
- Preserve existing style and architecture
- Prefer incremental targeted edits
- Avoid introducing unnecessary abstractions
- Avoid changing public APIs unless required

---

## Reasoning

- Ask for missing context instead of guessing
- Verify imports before editing
- Verify file existence before referencing
- Do not guess APIs without verification
- Prefer evidence over assumptions
- Identify root cause before proposing fixes
- Explain reasoning before large refactors
- Prefer observable facts over assumptions

---

## Tool Usage

- Prefer filesystem MCP over shell commands
- Prefer structured search over grep
- Prefer repo-map before repeatedly opening files
- Prefer official documentation when using fetch or web tools
- Avoid unnecessary filesystem traversal

---

## Debugging

- Read the full error message first
- Inspect stack traces carefully
- Prefer minimal fixes before architectural changes
- Avoid refactoring during active debugging unless necessary
- Verify behavior after each change

---

## Code Review Mindset

- Check for lifecycle safety
- Check for concurrency issues
- Check for unnecessary allocations
- Check for API compatibility
- Check for regressions before cleanup refactors