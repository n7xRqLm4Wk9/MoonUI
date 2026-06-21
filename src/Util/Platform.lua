--!strict
--[[
	Moon UI — Platform.lua
	Single source of truth for input/device detection and adaptive sizing.
	Other modules read from here rather than each calling UserInputService,
	which keeps behaviour consistent and makes it trivial to override for tests.
]]

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Signal = require(script.Parent.Signal)
local Types = require(script.Parent.Types)

local Platform = {}

Platform.Changed = Signal.new() :: Types.Signal<string>

local function detect(): string
	if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
		return "Touch"
	elseif GuiService:IsTenFootInterface() or (UserInputService.GamepadEnabled and not UserInputService.MouseEnabled) then
		return "Gamepad"
	else
		return "Desktop"
	end
end

Platform.Current = detect()

-- A device is "compact" when the smaller viewport axis is phone-sized.
function Platform.IsCompact(): boolean
	local cam = workspace.CurrentCamera
	if not cam then
		return false
	end
	local vp = cam.ViewportSize
	return math.min(vp.X, vp.Y) <= 600
end

function Platform.IsTouch(): boolean
	return Platform.Current == "Touch" or UserInputService.TouchEnabled
end

function Platform.IsGamepad(): boolean
	return Platform.Current == "Gamepad"
end

-- Recommended minimum hit target (px). Touch needs larger comfortable targets.
function Platform.TouchTarget(): number
	return Platform.IsTouch() and 44 or 32
end

-- Recommended default window size for the current device.
function Platform.DefaultWindowSize(): UDim2
	if Platform.IsCompact() then
		return UDim2.fromOffset(380, 460)
	end
	return UDim2.fromOffset(640, 480)
end

local lastInput = ""
UserInputService.LastInputTypeChanged:Connect(function(inputType)
	local mapped
	if inputType == Enum.UserInputType.Touch then
		mapped = "Touch"
	elseif inputType.Name:find("Gamepad") then
		mapped = "Gamepad"
	elseif inputType == Enum.UserInputType.Keyboard or inputType.Name:find("Mouse") then
		mapped = "Desktop"
	end
	if mapped and mapped ~= lastInput then
		lastInput = mapped
		Platform.Current = mapped
		Platform.Changed:Fire(mapped)
	end
end)

return Platform
