local Connection = {}
Connection.__index = Connection

export type Connection = typeof(setmetatable(
	{} :: {
		_connected: boolean,
		_fn: any,
		_signal: Signal,
	},
	Connection
))

function Connection.new(Signal, fn)
	return setmetatable({
		_connected = true,
		_fn = fn,
		_signal = Signal,
	}, Connection)
end

function Connection.Disconnect(self: Connection)
	self._connected = false
	local connections = self._signal._Connections

	for i, connection in ipairs(connections) do
		if connection == self then
			table.remove(connections, i)
			break
		end
	end
end

local Signal = {}
Signal.__index = Signal

export type Signal = typeof(setmetatable(
	{} :: {
		_Connections: {},
	},
	Signal
))

function Signal.new()
	local self = setmetatable({
		_Connections = {},
	}, Signal)
	return self
end

function Signal.Fire(self: Signal, ...)
	local _ConnectionsCopy = table.clone(self._Connections)
	for _, connection: Connection in ipairs(_ConnectionsCopy) do
		if connection._connected then
			task.spawn(connection._fn, ...)
		end
	end
end

function Signal.Connect(self: Signal, fn)
	local connection = Connection.new(self, fn)
	table.insert(self._Connections, connection)
	return connection
end

function Signal.Wait(self: Signal)
	local thread = coroutine.running()
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		task.spawn(thread, ...)
	end)

	return coroutine.yield()
end

function Signal.DisconnectAll(self: Signal)
	if self._Connections then
		for _, connection: Connection in ipairs(self._Connections) do
			connection._connected = false
		end
		table.clear(self._Connections)
	end
end

function Signal.Destroy(self: Signal)
	self:DisconnectAll()
end
return Signal
