--!strict
--[[ Moon UI — Components/Keybind.lua
	Captures a key, supports Toggle/Hold/Always modes and fires on press.
	Encodes the bound key by EnumItem name for config persistence. ]]

local UserInputService = game:GetService("UserInputService")
local Create = require(script.Parent.Parent.Util.Create)
local Theme = require(script.Parent.Parent.Systems.Theme)
local Animation = require(script.Parent.Parent.Systems.Animation)
local State = require(script.Parent.Parent.Systems.State)
local Base = require(script.Parent.Base)
local Types = require(script.Parent.Parent.Util.Types)

local Keybind = {}
Keybind.__index = Keybind

export type Keybind = {
	Root: Frame,
	State: Types.State<any>,
	Active: boolean,
	SetKey: (self: Keybind, key: Enum.KeyCode | Enum.UserInputType) -> (),
	Destroy: (self: Keybind) -> (),
}

local function keyName(key: any): string
	if typeof(key) == "EnumItem" then
		return key.Name
	end
	return "None"
end

function Keybind.new(options: Types.KeybindOptions, context: any): Keybind
	local mode = options.Mode or "Toggle"
	local row = Base.create({
		Name = options.Name,
		Description = options.Description,
		ControlWidth = 110,
	})

	local state = State.new(options.Default or Enum.KeyCode.Unknown)

	local label = Create("TextButton", {
		Name = "KeyLabel",
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = Theme.Token("SurfaceVariant"),
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		Text = keyName(state:Get()),
		[Create.Children] = {
			Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Create("UIStroke", { Name = "Stroke", Color = Theme.Token("Border"), Thickness = 1 }),
		},
	}) :: TextButton
	local holder = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		[Create.Children] = {
			Create("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
			label,
		},
	})
	holder.Parent = row.Control

	local self = setmetatable({ Root = row.Root, State = state, Active = false, _row = row }, Keybind)
	local stroke = label:FindFirstChild("Stroke") :: UIStroke
	local listening = false

	local function setText()
		label.Text = listening and "..." or keyName(state:Get())
	end

	-- Capture next input as the new bind.
	local function beginCapture()
		listening = true
		setText()
		Animation.tween(stroke, { Color = Theme.Token("Primary") }, "Fast")
	end

	row.Maid:Give(label.Activated:Connect(beginCapture))

	row.Maid:Give(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if listening then
			local k: any
			if input.UserInputType == Enum.UserInputType.Keyboard then
				k = input.KeyCode
			elseif input.UserInputType == Enum.UserInputType.MouseButton2
				or input.UserInputType == Enum.UserInputType.MouseButton3 then
				k = input.UserInputType
			end
			if k then
				if k == Enum.KeyCode.Escape or k == Enum.KeyCode.Backspace then
					k = Enum.KeyCode.Unknown
				end
				listening = false
				state:Set(k)
				Animation.tween(stroke, { Color = Theme.Token("Border") }, "Fast")
				if options.OnChanged then
					task.spawn(options.OnChanged, k)
				end
			end
			return
		end

		if gameProcessed then
			return
		end
		local bound = state:Get()
		local matches = (input.KeyCode == bound and bound ~= Enum.KeyCode.Unknown)
			or (input.UserInputType == bound)
		if matches then
			if mode == "Toggle" then
				self.Active = not self.Active
			elseif mode == "Hold" then
				self.Active = true
			end
			if options.Callback then
				task.spawn(options.Callback, self.Active)
			end
		end
	end))

	if mode == "Hold" then
		row.Maid:Give(UserInputService.InputEnded:Connect(function(input)
			local bound = state:Get()
			if input.KeyCode == bound or input.UserInputType == bound then
				self.Active = false
				if options.Callback then
					task.spawn(options.Callback, false)
				end
			end
		end))
	end

	row.Maid:Give(state:Subscribe(setText))
	setText()

	row.Maid:Give(Theme.Bind(function()
		label.BackgroundColor3 = Theme.Token("SurfaceVariant")
		label.TextColor3 = Theme.Token("Text")
		stroke.Color = Theme.Token("Border")
	end))

	if options.Flag and context and context.Config then
		context.Config:Register(
			options.Flag,
			state,
			function(v)
				return keyName(v)
			end,
			function(name)
				return (Enum.KeyCode :: any)[name] or (Enum.UserInputType :: any)[name] or Enum.KeyCode.Unknown
			end
		)
	end

	return (self :: any) :: Keybind
end

function Keybind:SetKey(key)
	self.State:Set(key)
end
function Keybind:Destroy()
	self.State:Destroy()
	self._row:Destroy()
end

return Keybind
