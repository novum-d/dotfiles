# BLE Guidelines

## Android BLE

- Verify Android version-specific permissions before changing code
- Check targetSdk before changing manifest permissions
- Verify scan throttling and background restrictions
- Prefer explicit reconnect strategy over implicit retries
- Use explicit timeouts for connect, discover services, read, write, and notify setup
- Verify MTU negotiation and payload sizing
- Treat GATT lifecycle cleanup as part of the implementation
- Do not assume callback ordering is reliable
- Check manufacturer-specific behavior before generalizing a fix

## Investigation

1. Identify device, Android version, and targetSdk
2. Confirm permission state and Bluetooth adapter state
3. Inspect scan, connect, service discovery, MTU, and notification logs
4. Identify the failing lifecycle stage
5. Prefer the smallest fix that preserves existing architecture
