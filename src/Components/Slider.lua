--!strict
--[[ Moon UI — Components/Slider.lua : drag + touch + keyboard nudge ]]

local UserInputService = game:GetService("UserInputService")
local Create = require(script.Parent.Parent.Util.Create)
local Theme = require(script.Parent.Parent.Systems.Theme)
local Animation = require(script.Parent.Parent.Systems.Animation)
local State = require(script.Parent.Parent.Systems.State)
local Base = require(script.Parent.Base)
local Types = require(script.Parent.Parent.Util.Types)

local Slider = {}
Slider.__index = Slider

export type Slider = {
	Root: Frame,
	State: Types.State<number>,
	Set: (self: Slider, value: number) -> (),
	Get: (self: Slider) -> number,
	Destroy: (self: Slider) -> (),
}

function Slider.new(options: Types.SliderOptions, context: any): Slider
	local min, max = options.Min, options.Max
	local inc = options.Increment or 1
	local suffix = options.Suffix or ""

	local row = Base.create({
		Name = options.Name,
		Description = options.Description,
		ControlWidth = 160,
	})

	local function snap(v: number): number
		v = math.clamp(v, min, max)
		v = min + math.floor((v - min) / inc + 0.5) * inc
		return math.clamp(v, min, max)
	end

	local state = State.new(snap(options.Default or min))

	local valueLabel = Create("TextLabel", {
		Name = "Value",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 44, 1, 0),
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		LayoutOrder = 2,
	}) :: TextLabel

	local fill = Create("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Theme.Token("Primary"),
		[Create.Children] = { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) },
	}) :: Frame

	local knob = Create("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 3,
		[Create.Children] = { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) },
	}) :: Frame

	local bar = Create("TextButton", {
		Name = "Bar",
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.new(1, -52, 0, 6),
		BackgroundColor3 = Theme.Token("SurfaceVariant"),
		LayoutOrder = 1,
		[Create.Children] = {
			Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
			fill,
			knob,
		},
	}) :: TextButton

	-- align bar vertically centered with the value label
	local controlInner = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		[Create.Children] = {
			Create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
			}),
			bar,
			valueLabel,
		},
	})
	controlInner.Parent = row.Control

	local self = setmetatable({ Root = row.Root, State = state, _row = row, _snap = snap }, Slider)

	local function render(v: number)
		local alpha = (max > min) and (v - min) / (max - min) or 0
		fill.Size = UDim2.fromScale(alpha, 1)
		knob.Position = UDim2.fromScale(alpha, 0.5)
		local display = (inc % 1 == 0) and tostring(math.floor(v)) or string.format("%.2f", v)
		valueLabel.Text = display .. suffix
	end

	row.Maid:Give(state:Subscribe(function(v)
		render(v)
		if options.Callback then
			task.spawn(options.Callback, v)
		end
	end))
	render(state:Get())

	-- Drag handling (mouse + touch).
	local dragging = false
	local function setFromX(x: number)
		local rel = (x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1)
		self:Set(min + math.clamp(rel, 0, 1) * (max - min))
	end

	row.Maid:Give(bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromX(input.Position.X)
		end
	end))
	row.Maid:Give(UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			setFromX(input.Position.X)
		end
	end))
	row.Maid:Give(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))

	row.Maid:Give(Theme.Bind(function()
		valueLabel.TextColor3 = Theme.Token("Text")
		bar.BackgroundColor3 = Theme.Token("SurfaceVariant")
		fill.BackgroundColor3 = Theme.Token("Primary")
	end))

	if options.Flag and context and context.Config then
		context.Config:Register(options.Flag, state)
	end

	return (self :: any) :: Slider
end

function Slider:Set(value)
	self.State:Set(self._snap(value))
end
function Slider:Get()
	return self.State:Get()
end
function Slider:Destroy()
	self.State:Destroy()
	self._row:Destroy()
end

return Slider
