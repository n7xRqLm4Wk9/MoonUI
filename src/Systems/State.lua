--!strict
--[[
	Moon UI — State.lua
	Observable value container. The backbone of dynamic updates and state
	binding: components subscribe to a State and re-render only what changed,
	avoiding full-interface rebuilds. Equality-checked sets prevent redundant
	notifications (and therefore redundant tweens / redraws).
]]

local Signal = require(script.Parent.Parent.Util.Signal)
local Types = require(script.Parent.Parent.Util.Types)

local State = {}
State.__index = State

function State.new<T>(initial: T): Types.State<T>
	return (setmetatable({
		_value = initial,
		_changed = Signal.new(),
	}, State) :: any) :: Types.State<T>
end

function State:Get()
	return self._value
end

function State:Set(value)
	if self._value == value then
		return
	end
	local old = self._value
	self._value = value
	self._changed:Fire(value, old)
end

function State:Update(transform)
	self:Set(transform(self._value))
end

function State:Subscribe(listener)
	-- Fire once immediately so subscribers sync to current value on bind.
	task.spawn(listener, self._value, self._value)
	return self._changed:Connect(listener)
end

function State:Destroy()
	self._changed:Destroy()
end

return State
