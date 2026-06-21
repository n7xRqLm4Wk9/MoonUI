--!strict
--[[ Moon UI — Components/Textbox.lua ]]

local Create = require(script.Parent.Parent.Util.Create)
local Theme = require(script.Parent.Parent.Systems.Theme)
local Animation = require(script.Parent.Parent.Systems.Animation)
local State = require(script.Parent.Parent.Systems.State)
local Base = require(script.Parent.Base)
local Types = require(script.Parent.Parent.Util.Types)

local Textbox = {}
Textbox.__index = Textbox

export type Textbox = {
	Root: Frame,
	State: Types.State<string>,
	Set: (self: Textbox, value: string) -> (),
	Get: (self: Textbox) -> string,
	Destroy: (self: Textbox) -> (),
}

function Textbox.new(options: Types.TextboxOptions, context: any): Textbox
	local row = Base.create({
		Name = options.Name,
		Description = options.Description,
		ControlWidth = 150,
	})

	local state = State.new(options.Default or "")

	local input = Create("TextBox", {
		Name = "Input",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Token("SurfaceVariant"),
		Font = Enum.Font.Gotham,
		TextSize = 13,
		PlaceholderText = options.Placeholder or "",
		Text = state:Get(),
		ClearTextOnFocus = options.ClearOnFocus or false,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClipsDescendants = true,
		[Create.Children] = {
			Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Create("UIPadding", {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			}),
			Create("UIStroke", {
				Name = "Stroke",
				Color = Theme.Token("Border"),
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
		},
	}) :: TextBox
	local container = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 32),
		[Create.Children] = { input },
	})
	container.Parent = row.Control

	local self = setmetatable({ Root = row.Root, State = state, _row = row, _input = input }, Textbox)
	local stroke = input:FindFirstChild("Stroke") :: UIStroke

	row.Maid:Give(input.Focused:Connect(function()
		Animation.tween(stroke, { Color = Theme.Token("Primary") }, "Fast")
	end))
	row.Maid:Give(input.FocusLost:Connect(function()
		Animation.tween(stroke, { Color = Theme.Token("Border") }, "Fast")
		local text = input.Text
		if options.Numeric and tonumber(text) == nil and text ~= "" then
			input.Text = state:Get() -- reject non-numeric
			return
		end
		state:Set(text)
	end))

	row.Maid:Give(state:Subscribe(function(v)
		if input.Text ~= v then
			input.Text = v
		end
		if options.Callback then
			task.spawn(options.Callback, v)
		end
	end))

	row.Maid:Give(Theme.Bind(function()
		input.BackgroundColor3 = Theme.Token("SurfaceVariant")
		input.TextColor3 = Theme.Token("Text")
		input.PlaceholderColor3 = Theme.Token("MutedText")
		stroke.Color = Theme.Token("Border")
	end))

	if options.Flag and context and context.Config then
		context.Config:Register(options.Flag, state)
	end

	return (self :: any) :: Textbox
end

function Textbox:Set(value)
	self.State:Set(tostring(value))
end
function Textbox:Get()
	return self.State:Get()
end
function Textbox:Destroy()
	self.State:Destroy()
	self._row:Destroy()
end

return Textbox
