# Coding Guidelines

## General

- Prefer explicit naming over abbreviations
- Prefer immutable state
- Prefer small focused functions
- Avoid unnecessary abstractions
- Prefer composition over inheritance

## Kotlin

- Prefer Flow over LiveData
- Prefer suspend functions over callbacks
- Avoid GlobalScope
- Use structured concurrency

## Android

- Keep business logic outside Activity/Fragment
- Verify lifecycle safety
- Prefer unidirectional data flow

## Rust

- Prefer borrowing over cloning
- Avoid unnecessary Arc<Mutex<T>>
- Prefer Result over panic

## Nix

- Prefer source files over embedded text
- Keep modules small and composable