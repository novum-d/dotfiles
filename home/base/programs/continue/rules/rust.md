# Rust Rules

## Environment

- Rust edition: 2024

---

## Ownership

- Prefer borrowing over cloning
- Avoid unnecessary `Arc<Mutex<T>>`
- Prefer `Rc<RefCell<T>>` only for single-threaded cases
- Prefer clear ownership boundaries
- Minimize shared mutable state

---

## Error Handling

- Prefer `Result` over `panic!`
- Use `anyhow` for applications
- Use `thiserror` for libraries
- Propagate errors with context
- Avoid `unwrap()` and `expect()` outside tests or prototypes

---

## Async

- Prefer Tokio ecosystem
- Avoid blocking the async runtime
- Use `spawn` carefully with ownership and lifetimes
- Prefer structured concurrency
- Verify `Send` and `Sync` assumptions explicitly
- Avoid unnecessary async abstraction layers

---

## Design

- Prefer traits over inheritance
- Prefer explicit types at API boundaries
- Keep modules small and cohesive
- Prefer composition over overly generic abstractions
- Prefer readability over clever type-level tricks
- Keep public APIs stable and predictable

---

## Performance

- Avoid unnecessary allocations
- Prefer iterators over temporary `Vec`
- Prefer slices over owned collections when possible
- Avoid cloning large structures unnecessarily
- Measure performance before micro-optimizing

---

## Debugging

- Inspect ownership boundaries before changing lifetimes
- Verify async runtime assumptions
- Check blocking operations inside async contexts
- Prefer minimal targeted fixes over rewrites
- Verify compiler diagnostics carefully before changing architecture

---

## Editing

- Preserve module organization
- Prefer minimal diffs
- Avoid unrelated refactors
- Preserve formatting and idiomatic style
- Verify imports and feature flags before editing

---

## Best Practices

- Prefer explicitness over magic
- Prefer safe abstractions
- Prefer compile-time guarantees when practical
- Keep unsafe code isolated and documented
- Document invariants around concurrency and ownership

---

## Do Not

- Do not introduce unnecessary `unsafe`
- Do not hide ownership complexity behind excessive abstraction
- Do not block inside async code
- Do not introduce global mutable state unnecessarily
- Do not rewrite working code without identifying root cause