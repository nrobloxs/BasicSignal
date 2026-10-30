--!strict

local FreeRunnerThread: thread? = nil

type Handler = (...any) -> ()

local function NOOP() end

local function AquireRunnerThread_andCallEventHandler(fn: Handler, ...: any)
	local AquiredFreeRunnerThread = FreeRunnerThread
	FreeRunnerThread = nil
	fn(...)
	FreeRunnerThread = AquiredFreeRunnerThread
end

local function RunEventHandler_InFreeThread(...: any)
	AquireRunnerThread_andCallEventHandler(...)
	while true do
		AquireRunnerThread_andCallEventHandler(coroutine.yield())
	end
end

local Connection = {}
Connection.__index = Connection

export type Connection = typeof(setmetatable(
	{} :: {
		_connected: boolean,
		_fn: Handler,
		_signal: Signal,
	},
	Connection
))

local Signal = {}
Signal.__index = Signal

export type Signal = typeof(setmetatable(
	{} :: {
		_Connections: { Connection }, -- immutable snapshot: replace, never mutate in place
		_destroyed: boolean,
	},
	Signal
))

local EMPTY: { Connection } = table.freeze({}) :: { Connection }

function Connection.new(signal: Signal, fn: Handler): Connection
	return setmetatable({
		_connected = true,
		_fn = fn,
		_signal = signal,
	}, Connection)
end

function Connection.Disconnect(self: Connection)
	if not self._connected then
		return
	end
	self._connected = false
	self._fn = NOOP

	local signal = self._signal
	local list = signal._Connections
	local index = table.find(list, self)
	if index then
		local new = table.clone(list)
		table.remove(new, index)
		signal._Connections = new
	end
end

function Signal.new(): Signal
	return setmetatable({
		_Connections = EMPTY,
		_destroyed = false,
	}, Signal)
end

function Signal.Fire(self: Signal, ...)
	local list = self._Connections
	for i = 1, #list do
		local connection = list[i]
		if connection._connected then
			local runner = FreeRunnerThread
			if not runner then
				runner = coroutine.create(RunEventHandler_InFreeThread)
				FreeRunnerThread = runner
			end
			task.spawn(runner :: thread, connection._fn, ...)
		end
	end
end

function Signal.Connect(self: Signal, fn: Handler): Connection
	assert(not self._destroyed, "Cannot connect to a destroyed Signal")
	local connection = Connection.new(self, fn)
	local list = self._Connections
	local new = table.clone(list)
	new[#list + 1] = connection
	self._Connections = new
	return connection
end

function Signal.Once(self: Signal, fn: Handler): Connection
	local connection: Connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		fn(...)
	end)
	return connection
end

function Signal.Wait(self: Signal)
	local thread = coroutine.running()
	self:Once(function(...)
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function Signal.DisconnectAll(self: Signal)
	local list = self._Connections
	self._Connections = EMPTY
	for _, connection in list do
		connection._connected = false
		connection._fn = NOOP
	end
end

function Signal.Destroy(self: Signal)
	self._destroyed = true
	self:DisconnectAll()
end

return Signal
