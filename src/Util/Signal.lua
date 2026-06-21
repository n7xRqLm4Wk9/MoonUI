--!strict
--[[
	Moon UI — Signal.lua
	A lightweight, allocation-conscious signal implementation.
	Avoids BindableEvents (which serialize arguments and break references)
	and uses a singly-linked list of connections for O(1) connect/disconnect.
]]

local Types = require(script.Parent.Types)

type ConnectionImpl = {
	Connected: boolean,
	_signal: any,
	_fn: (...any) -> (),
	_next: ConnectionImpl?,
	Disconnect: (self: ConnectionImpl) -> (),
}

local Connection = {}
Connection.__index = Connection

function Connection:Disconnect()
	if not self.Connected then
		return
	end
	self.Connected = false

	local signal = self._signal
	if signal._head == self then
		signal._head = self._next
	else
		local prev = signal._head
		while prev and prev._next ~= self do
			prev = prev._next
		end
		if prev then
			prev._next = self._next
		end
	end
end

local Signal = {}
Signal.__index = Signal

function Signal.new<T...>(): Types.Signal<T...>
	return (setmetatable({ _head = nil }, Signal) :: any) :: Types.Signal<T...>
end

function Signal:Connect(fn)
	local connection: ConnectionImpl = setmetatable({
		Connected = true,
		_signal = self,
		_fn = fn,
		_next = self._head,
	}, Connection) :: any
	self._head = connection
	return (connection :: any) :: Types.Connection
end

function Signal:Once(fn)
	local conn
	conn = self:Connect(function(...)
		conn:Disconnect()
		fn(...)
	end)
	return conn
end

function Signal:Wait()
	local thread = coroutine.running()
	local conn
	conn = self:Connect(function(...)
		conn:Disconnect()
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function Signal:Fire(...)
	-- Iterate a snapshot-safe chain: capture _next before invoking so a
	-- listener disconnecting itself mid-fire does not corrupt traversal.
	local node = self._head
	while node do
		local nextNode = node._next
		if node.Connected then
			task.spawn(node._fn, ...)
		end
		node = nextNode
	end
end

function Signal:DisconnectAll()
	local node = self._head
	while node do
		node.Connected = false
		node = node._next
	end
	self._head = nil
end

function Signal:Destroy()
	self:DisconnectAll()
end

return Signal
