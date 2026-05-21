# Android Rules

## Environment

- Target SDK: 35
- Kotlin: 2.x

---

## Architecture

- Prefer MVVM or clean architecture
- Separate UI/domain/data layers
- Avoid business logic inside Activity or Fragment
- Prefer unidirectional data flow
- Prefer explicit state ownership

---

## Kotlin

- Prefer immutable state
- Prefer Flow over LiveData
- Prefer suspend functions over callbacks
- Prefer explicit naming
- Prefer structured concurrency
- Avoid GlobalScope

---

## Compose

- Avoid unnecessary recomposition
- Prefer state hoisting
- Use remember only for UI state
- Avoid passing unstable objects
- Keep composables small and focused

---

## BLE

- Verify Android 12+ bluetooth permissions
- Consider scan throttling
- Consider background restrictions
- Consider foreground service requirements
- Verify manufacturer-specific behavior
- Verify reconnect behavior
- Verify MTU negotiation assumptions
- Verify GATT lifecycle cleanup
- Use explicit timeouts for operations that can hang
- Verify callback threading assumptions
- Verify connection state transitions carefully

---

## Android Version Notes

### Android 12+

- BLUETOOTH_SCAN permission required for scanning
- BLUETOOTH_CONNECT permission required for connecting and GATT access
- Verify neverForLocation only when scan results are not used for location

### Android 14+

- Foreground service restrictions tightened
- Verify background BLE behavior before implementation

### Android 15+

- Verify behavior changes before implementation
- Prefer current official documentation over remembered API behavior

---

## Performance

- Avoid blocking Main thread
- Use Dispatchers.IO for I/O
- Verify cold Flow collection costs
- Avoid unnecessary allocations during BLE communication

---

## Build / Gradle

- Inspect Gradle modules before editing
- Verify minSdk and targetSdk compatibility
- Verify AGP and Kotlin compatibility

---

## Do Not

- Do not use deprecated Android APIs unless required by compatibility constraints
- Do not assume BLE callbacks arrive in a reliable order
- Do not change manifest permissions without checking targetSdk behavior
- Do not rewrite working architecture unnecessarily
- Do not introduce unrelated refactors during debugging
