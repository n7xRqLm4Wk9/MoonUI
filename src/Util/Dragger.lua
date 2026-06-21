--!strict
--[[
	Moon UI — Dragger.lua
	Reusable, input-agnostic drag behaviour (mouse + touch). Clamps the dragged
	frame inside the viewport and emits start/changed/end so windows can persist
	their position. Returns a Maid-cleanable connection bundle.
]]

local UserInputService = game:GetService("UserInputService")
local Signal = require(script.Parent.Signal)
local Maid = require(script.Parent.Maid)
local Types = require(script.Parent.Types)

local Dragger = {}
Dragger.__index = Dragger

export type Dragger = {
	DragEnded: Types.Signal<Vector2>,
	Destroy: (self: any) -> (),
}

function Dragger.attach(handle: GuiObject, target: GuiObject): Dragger
	local maid = Maid.new()
	local self = setmetatable({
		DragEnded = Signal.new(),
		_maid = maid,
	}, Dragger)

	local dragging = false
	local dragStart: Vector2
	local startPos: UDim2

	local function clamp(pos: UDim2): UDim2
		local cam = workspace.CurrentCamera
		if not cam then
			return pos
		end
		local vp = cam.ViewportSize
		local absSize = target.AbsoluteSize
		local x = math.clamp(pos.X.Offset, 0, math.max(0, vp.X - absSize.X))
		local y = math.clamp(pos.Y.Offset, 0, math.max(0, vp.Y - absSize.Y))
		return UDim2.new(pos.X.Scale, x, pos.Y.Scale, y)
	end

	maid:Give(handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
			local conn
			conn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					conn:Disconnect()
					self.DragEnded:Fire(Vector2.new(target.Position.X.Offset, target.Position.Y.Offset))
				end
			end)
		end
	end))

	maid:Give(UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			target.Position = clamp(UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			))
		end
	end))

	return (self :: any) :: Dragger
end

function Dragger:Destroy()
	self.DragEnded:Destroy()
	self._maid:Destroy()
end

return Dragger
