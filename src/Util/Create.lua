--!strict
--[[
	Moon UI — Create.lua
	A small, dependency-free declarative instance constructor.

	Usage:
		local frame = Create("Frame", {
			Name = "Root",
			Size = UDim2.fromScale(1, 1),
			[Create.Children] = {
				Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
			},
			[Create.Event "Activated"] = function() ... end,
		})

	The goal is to keep view code flat and readable while still emitting plain
	Roblox Instances (no virtual DOM overhead, no per-frame reconciliation).
]]

export type Props = { [any]: any }

local CHILDREN = newproxy(false)
local EVENT_PREFIX = "MoonEvent::"

local function Create(className: string, props: Props?): Instance
	local inst = Instance.new(className)
	if props then
		local target = inst :: any
		local children = props[CHILDREN]
		for key, value in props do
			if key == CHILDREN then
				continue
			elseif type(key) == "string" and key:sub(1, #EVENT_PREFIX) == EVENT_PREFIX then
				local eventName = key:sub(#EVENT_PREFIX + 1)
				target[eventName]:Connect(value)
			else
				target[key] = value
			end
		end
		if children then
			for _, child in children :: { Instance } do
				child.Parent = inst
			end
		end
	end
	return inst
end

-- Sentinel key for declaring children inline.
;(Create :: any).Children = CHILDREN

-- Helper that returns an event key, e.g. [Create.Event "Activated"] = fn
;(Create :: any).Event = function(eventName: string): string
	return EVENT_PREFIX .. eventName
end

return Create :: typeof(Create) & {
	Children: any,
	Event: (eventName: string) -> string,
}
