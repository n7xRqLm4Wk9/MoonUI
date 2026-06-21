--!strict
--[[ Moon UI — Components/ColorPicker.lua
	HSV picker with SV plane + hue strip (+ optional alpha). Popup lives in the
	overlay layer. Encodes Color3 as hex for config. ]]

local UserInputService = game:GetService("UserInputService")
local Create = require(script.Parent.Parent.Util.Create)
local Theme = require(script.Parent.Parent.Systems.Theme)
local Animation = require(script.Parent.Parent.Systems.Animation)
local State = require(script.Parent.Parent.Systems.State)
local Base = require(script.Parent.Base)
local Types = require(script.Parent.Parent.Util.Types)

local ColorPicker = {}
ColorPicker.__index = ColorPicker

export type ColorPicker = {
	Root: Frame,
	State: Types.State<Color3>,
	Set: (self: ColorPicker, color: Color3) -> (),
	Get: (self: ColorPicker) -> Color3,
	Destroy: (self: ColorPicker) -> (),
}

local function toHex(c: Color3): string
	return string.format("#%02X%02X%02X", c.R * 255, c.G * 255, c.B * 255)
end
local function fromHex(hex: string): Color3?
	hex = hex:gsub("#", "")
	if #hex ~= 6 then
		return nil
	end
	local r = tonumber(hex:sub(1, 2), 16)
	local g = tonumber(hex:sub(3, 4), 16)
	local b = tonumber(hex:sub(5, 6), 16)
	if r and g and b then
		return Color3.fromRGB(r, g, b)
	end
	return nil
end

function ColorPicker.new(options: Types.ColorPickerOptions, context: any): ColorPicker
	local row = Base.create({
		Name = options.Name,
		Description = options.Description,
		ControlWidth = 60,
	})

	local state = State.new(options.Default or Color3.fromRGB(96, 132, 255))

	local swatch = Create("TextButton", {
		Name = "Swatch",
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromOffset(44, 26),
		BackgroundColor3 = state:Get(),
		[Create.Children] = {
			Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Create("UIStroke", { Color = Theme.Token("Border"), Thickness = 1 }),
		},
	}) :: TextButton
	local holder = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		[Create.Children] = {
			Create("UIListLayout", {
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
			}),
			swatch,
		},
	})
	holder.Parent = row.Control

	local self = setmetatable({ Root = row.Root, State = state, _row = row }, ColorPicker)

	local h, s, v = state:Get():ToHSV()
	local popup: Frame
	local open = false
	local svCursor: Frame, hueCursor: Frame, svPlane: ImageLabel, svColor: Frame

	local function currentColor(): Color3
		return Color3.fromHSV(h, s, v)
	end
	local function pushColor()
		state:Set(currentColor())
	end

	local function buildPopup()
		svColor = Create("Frame", {
			Name = "Hue",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromHSV(h, 1, 1),
			[Create.Children] = { Create("UICorner", { CornerRadius = UDim.new(0, 6) }) },
		}) :: Frame
		svCursor = Create("Frame", {
			Name = "Cursor",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(10, 10),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 4,
			[Create.Children] = {
				Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1 }),
			},
		}) :: Frame
		svPlane = Create("ImageButton", {
			Name = "SV",
			Size = UDim2.new(1, -28, 0, 120),
			BackgroundColor3 = Color3.fromHSV(h, 1, 1),
			AutoButtonColor = false,
			Text = "",
			[Create.Children] = {
				Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
				-- white gradient (saturation) then black gradient (value)
				Create("UIGradient", {
					Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)),
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0),
						NumberSequenceKeypoint.new(1, 1),
					}),
				}),
				Create("Frame", {
					Name = "Value",
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = Color3.new(0, 0, 0),
					[Create.Children] = {
						Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
						Create("UIGradient", {
							Rotation = 90,
							Transparency = NumberSequence.new({
								NumberSequenceKeypoint.new(0, 1),
								NumberSequenceKeypoint.new(1, 0),
							}),
						}),
					},
				}),
				svCursor,
			},
		}) :: any

		hueCursor = Create("Frame", {
			Name = "HueCursor",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, h),
			Size = UDim2.new(1, 4, 0, 4),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 4,
			[Create.Children] = { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) },
		}) :: Frame
		local hueStrip = Create("ImageButton", {
			Name = "HueStrip",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.new(0, 20, 0, 120),
			Text = "",
			AutoButtonColor = false,
			[Create.Children] = {
				Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Create("UIGradient", {
					Rotation = 90,
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0.00, Color3.fromHSV(0, 1, 1)),
						ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
						ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
						ColorSequenceKeypoint.new(0.50, Color3.fromHSV(0.50, 1, 1)),
						ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
						ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
						ColorSequenceKeypoint.new(1.00, Color3.fromHSV(1, 1, 1)),
					}),
				}),
				hueCursor,
			},
		}) :: any

		local hexBox = Create("TextBox", {
			Name = "Hex",
			Position = UDim2.fromOffset(0, 128),
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundColor3 = Theme.Token("SurfaceVariant"),
			Font = Enum.Font.Code,
			TextSize = 13,
			TextColor3 = Theme.Token("Text"),
			Text = toHex(currentColor()),
			[Create.Children] = {
				Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Create("UIPadding", { PaddingLeft = UDim.new(0, 8) }),
			},
		}) :: TextBox

		popup = Create("Frame", {
			Name = "ColorPopup",
			BackgroundColor3 = Theme.Token("Elevated"),
			Size = UDim2.fromOffset(200, 170),
			Visible = false,
			ZIndex = 50,
			[Create.Children] = {
				Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
				Create("UIStroke", { Color = Theme.Token("Border"), Thickness = 1 }),
				Create("UIPadding", {
					PaddingLeft = UDim.new(0, 10),
					PaddingRight = UDim.new(0, 10),
					PaddingTop = UDim.new(0, 10),
					PaddingBottom = UDim.new(0, 10),
				}),
				svPlane,
				hueStrip,
				hexBox,
			},
		}) :: Frame
		popup.Parent = context.OverlayLayer

		local function updateSVCursor()
			svCursor.Position = UDim2.fromScale(s, 1 - v)
			svPlane.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			hueCursor.Position = UDim2.fromScale(0.5, h)
			hexBox.Text = toHex(currentColor())
		end
		self._updateCursor = updateSVCursor
		updateSVCursor()

		-- SV drag
		local svDragging = false
		local function setSV(pos: Vector2)
			local rx = math.clamp((pos.X - svPlane.AbsolutePosition.X) / svPlane.AbsoluteSize.X, 0, 1)
			local ry = math.clamp((pos.Y - svPlane.AbsolutePosition.Y) / svPlane.AbsoluteSize.Y, 0, 1)
			s, v = rx, 1 - ry
			updateSVCursor()
			pushColor()
		end
		svPlane.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				svDragging = true
				setSV(i.Position)
			end
		end)
		-- hue drag
		local hueDragging = false
		local function setHue(pos: Vector2)
			h = math.clamp((pos.Y - hueStrip.AbsolutePosition.Y) / hueStrip.AbsoluteSize.Y, 0, 1)
			updateSVCursor()
			pushColor()
		end
		hueStrip.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				hueDragging = true
				setHue(i.Position)
			end
		end)
		row.Maid:Give(UserInputService.InputChanged:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
				if svDragging then setSV(i.Position) end
				if hueDragging then setHue(i.Position) end
			end
		end))
		row.Maid:Give(UserInputService.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				svDragging, hueDragging = false, false
			end
		end))
		hexBox.FocusLost:Connect(function()
			local c = fromHex(hexBox.Text)
			if c then
				h, s, v = c:ToHSV()
				updateSVCursor()
				pushColor()
			else
				hexBox.Text = toHex(currentColor())
			end
		end)
	end

	local function position()
		local absPos = swatch.AbsolutePosition
		local absSize = swatch.AbsoluteSize
		local layerPos = context.OverlayLayer.AbsolutePosition
		popup.Position = UDim2.fromOffset(
			absPos.X - layerPos.X + absSize.X - popup.AbsoluteSize.X,
			absPos.Y - layerPos.Y + absSize.Y + 4
		)
	end

	row.Maid:Give(swatch.Activated:Connect(function()
		if not popup then
			buildPopup()
		end
		open = not open
		popup.Visible = open
		if open then
			position()
		end
	end))

	row.Maid:Give(state:Subscribe(function(c)
		swatch.BackgroundColor3 = c
		if not (UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)) then
			h, s, v = c:ToHSV()
			if self._updateCursor then
				self._updateCursor()
			end
		end
		if options.Callback then
			task.spawn(options.Callback, c, 1)
		end
	end))

	row.Maid:Give(Theme.Bind(function()
		swatch:FindFirstChildOfClass("UIStroke").Color = Theme.Token("Border")
	end))

	row.Maid:Give(function()
		if popup then
			popup:Destroy()
		end
	end)

	if options.Flag and context and context.Config then
		context.Config:Register(
			options.Flag,
			state,
			function(c)
				return toHex(c)
			end,
			function(hex)
				return fromHex(hex) or Color3.new(1, 1, 1)
			end
		)
	end

	return (self :: any) :: ColorPicker
end

function ColorPicker:Set(color)
	self.State:Set(color)
end
function ColorPicker:Get()
	return self.State:Get()
end
function ColorPicker:Destroy()
	self.State:Destroy()
	self._row:Destroy()
end

return ColorPicker
