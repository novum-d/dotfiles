# Debugging Guidelines

## General

- Explain reasoning before large refactors
- Identify the root cause before proposing fixes
- Do not guess when logs or stack traces are available
- Prefer evidence over assumptions
- Prefer minimal targeted fixes over rewrites
- Reproduce the issue before changing architecture
- Inspect surrounding code before editing

## Investigation Process

1. Read the full error message
2. Inspect stack trace carefully
3. Identify failing layer/module
4. Verify assumptions with actual code
5. Propose the smallest viable fix
6. Explain why the issue occurred

## Code Changes

- Avoid unrelated refactors during debugging
- Preserve existing behavior unless necessary
- Prefer observable/debuggable solutions
- Add logging only when useful for diagnosis

## Android

- Verify lifecycle state
- Verify coroutine cancellation
- Verify threading assumptions
- Check Android version-specific behavior
- Verify permission state before debugging logic

## Rust

- Inspect ownership boundaries
- Verify async runtime usage
- Check blocking calls inside async contexts
- Verify Send/Sync assumptions

## Nix

- Read the full evaluation trace
- Verify attribute paths carefully
- Check indentation and quoting
- Prefer incremental fixes
