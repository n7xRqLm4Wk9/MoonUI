--!strict
--[[ Moon UI — Components/Toggle.lua : iOS-style animated switch ]]

local Create = require(script.Parent.Parent.Util.Create)
local Theme = require(script.Parent.Parent.Systems.Theme)
local Animation = require(script.Parent.Parent.Systems.Animation)
local State = require(script.Parent.Parent.Systems.State)
local Base = require(script.Parent.Base)
local Types = require(script.Parent.Parent.Util.Types)

local Toggle = {}
Toggle.__index = Toggle

export type Toggle = {
	Root: Frame,
	State: Types.State<boolean>,
	Set: (self: Toggle, value: boolean) -> (),
	Get: (self: Toggle) -> boolean,
	Toggle: (self: Toggle) -> (),
	OnChanged: (self: Toggle, fn: (boolean) -> ()) -> any,
	Destroy: (self: Toggle) -> (),
}

local TRACK_W, TRACK_H, KNOB = 40, 22, 16

function Toggle.new(options: Types.ToggleOptions, context: any): Toggle
	local row = Base.create({
		Name = options.Name,
		Description = options.Description,
		ControlWidth = TRACK_W,
	})

	local state = State.new(options.Default or false)

	local knob = Create("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(KNOB, KNOB),
		BackgroundColor3 = Color3.new(1, 1, 1),
		[Create.Children] = { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) },
	}) :: Frame

	local track = Create("TextButton", {
		Name = "Track",
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromOffset(TRACK_W, TRACK_H),
		BackgroundColor3 = Theme.Token("SurfaceVariant"),
		[Create.Children] = {
			Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
			knob,
		},
	}) :: TextButton
	track.Parent = row.Control

	local self = setmetatable({ Root = row.Root, State = state, _row = row }, Toggle)

	local function render(on: boolean, animate: boolean)
		local spec = animate and "Normal" or "Instant"
		Animation.tween(track, {
			BackgroundColor3 = on and Theme.Token("Primary") or Theme.Token("SurfaceVariant"),
		}, spec)
		Animation.tween(knob, {
			Position = on and UDim2.new(1, -(KNOB + 3), 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
		}, spec)
	end

	row.Maid:Give(state:Subscribe(function(v)
		render(v, true)
		if options.Callback then
			task.spawn(options.Callback, v)
		end
	end))
	-- ensure initial visual without animation
	render(state:Get(), false)

	row.Maid:Give(track.Activated:Connect(function()
		self:Toggle()
	end))

	row.Maid:Give(Theme.Bind(function()
		render(state:Get(), false)
	end))

	-- Config flag wiring (boolean encodes directly to JSON).
	if options.Flag and context and context.Config then
		context.Config:Register(options.Flag, state)
	end

	return (self :: any) :: Toggle
end

function Toggle:Set(value)
	self.State:Set(value and true or false)
end
function Toggle:Get()
	return self.State:Get()
end
function Toggle:Toggle()
	self.State:Set(not self.State:Get())
end
function Toggle:OnChanged(fn)
	return self.State:Subscribe(function(v)
		fn(v)
	end)
end
function Toggle:Destroy()
	self.State:Destroy()
	self._row:Destroy()
end

return Toggle
