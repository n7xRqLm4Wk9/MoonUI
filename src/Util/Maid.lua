--!strict
--[[
	Moon UI — Maid.lua
	Deterministic lifecycle manager. Every component owns a Maid and registers
	all of its instances, connections, signals and sub-objects with it.
	Destroying the component cleans everything in reverse insertion order,
	which is the single most important guard against memory leaks in a
	long-lived UI framework.
]]

local Types = require(script.Parent.Types)

local Maid = {}
Maid.__index = Maid

function Maid.new(): Types.Maid
	return (setmetatable({
		_tasks = {},
		_cleaning = false,
	}, Maid) :: any) :: Types.Maid
end

local function cleanupTask(t: any)
	local tt = typeof(t)
	if tt == "function" then
		t()
	elseif tt == "RBXScriptConnection" then
		t:Disconnect()
	elseif tt == "Instance" then
		t:Destroy()
	elseif tt == "table" then
		if typeof(t.Disconnect) == "function" then
			t:Disconnect()
		elseif typeof(t.Destroy) == "function" then
			t:Destroy()
		end
	end
end

function Maid:Give(task)
	if self._cleaning then
		-- Adding during teardown: clean immediately, never store.
		cleanupTask(task)
		return task
	end
	table.insert(self._tasks, task)
	return task
end

function Maid:GiveAll(tasks)
	for _, t in tasks do
		self:Give(t)
	end
end

function Maid:IsCleaning()
	return self._cleaning
end

function Maid:Clean()
	if self._cleaning then
		return
	end
	self._cleaning = true
	local tasks = self._tasks
	self._tasks = {}
	-- Reverse order so children are destroyed before parents.
	for i = #tasks, 1, -1 do
		cleanupTask(tasks[i])
	end
	self._cleaning = false
end

function Maid:Destroy()
	self:Clean()
end

return Maid
