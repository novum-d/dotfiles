# Review Checklist

## General

- Verify error handling
- Verify null safety
- Check unnecessary complexity
- Check naming consistency

## Kotlin / Android

- Verify coroutine cancellation safety
- Verify lifecycle awareness
- Check recomposition cost
- Verify background thread usage
- Verify memory leak risks

## BLE

- Verify Android 12+ permissions
- Verify scan throttling handling
- Verify reconnect handling
- Verify timeout handling

## Rust

- Verify ownership correctness
- Check unnecessary allocations
- Check blocking inside async runtime
- Verify Send/Sync assumptions

## Nix

- Verify attribute paths
- Verify indentation
- Verify reproducibility