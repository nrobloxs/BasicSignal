# BasicSignal

A lightweight signal/event implementation for Roblox, in the style of GoodSignal.

## Installation

Add to your `wally.toml`:

```toml
[dependencies]
BasicSignal = "nrobloxs/basicsignal@0.1.0"
```

Then run:

```
wally install
```

## Usage

```luau
local BasicSignal = require(path.to.BasicSignal)

local signal = BasicSignal.new()

local connection = signal:Connect(function(message)
	print("Received:", message)
end)

signal:Fire("Hello!")

connection:Disconnect()
```

## API

### `BasicSignal.new()`

Creates a new signal instance.

### `Signal:Connect(fn: (...) -> ()): Connection`

Subscribes `fn` to the signal. Returns a `Connection` object.

### `Signal:Fire(...)`

Calls every connected listener with the given arguments. Each listener runs in its own thread, so one erroring or yielding listener won't block the others.

### `Signal:Wait(): ...`

Yields the calling thread until the signal next fires, then returns the fired arguments.

### `Signal:DisconnectAll()`

Disconnects every currently connected listener.

### `Signal:Destroy()`

Alias for `DisconnectAll()`.

### `Connection:Disconnect()`

Unsubscribes this specific listener. Safe to call multiple times.

### `Connection.Connected: boolean`

Whether this connection is still active.

## License

MIT
