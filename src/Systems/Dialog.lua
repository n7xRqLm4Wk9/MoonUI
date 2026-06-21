--!strict
--[[ Moon UI — Systems/Dialog.lua
	Modal dialog with dimmed backdrop, scale-in animation, icon, title, content
	and configurable buttons. Returns a handle so callers can close early. ]]

local Create = require(script.Parent.Parent.Util.Create)
local Maid = require(script.Parent.Parent.Util.Maid)
local Theme = require(script.Parent.Parent.Systems.Theme)
local Animation = require(script.Parent.Parent.Systems.Animation)
local Icons = require(script.Parent.Parent.Systems.Icons)
local Platform = require(script.Parent.Parent.Util.Platform)
local Types = require(script.Parent.Parent.Util.Types)

local Dialog = {}

local VARIANT = {
	Primary = "Primary",
	Secondary = "Surface",
	Danger = "Danger",
}

function Dialog.open(overlay: Instance, options: Types.DialogOptions)
	local maid = Maid.new()

	local scale = Create("UIScale", { Scale = 0.9 }) :: UIScale

	local titleRow = Create("Frame", {
		Name = "TitleRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24),
		LayoutOrder = 1,
		[Create.Children] = {
			Create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 8),
			}),
		},
	}) :: Frame
	if options.Icon then
		local ic = Create("ImageLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(20, 20),
			ImageColor3 = Theme.Token("Primary"),
			ScaleType = Enum.ScaleType.Fit,
		}) :: ImageLabel
		Icons.Apply(ic, options.Icon)
		ic.Parent = titleRow
	end
	local title = Create("TextLabel", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromScale(0, 1),
		Font = Enum.Font.GothamBold,
		TextSize = 17,
		TextColor3 = Theme.Token("Text"),
		Text = options.Title,
		TextXAlignment = Enum.TextXAlignment.Left,
	}) :: TextLabel
	title.Parent = titleRow

	local content = Create("TextLabel", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextColor3 = Theme.Token("SubText"),
		Text = options.Content,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 2,
	}) :: TextLabel

	local buttonRow = Create("Frame", {
		Name = "Buttons",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 36),
		LayoutOrder = 3,
		[Create.Children] = {
			Create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 8),
			}),
		},
	}) :: Frame

	local panel = Create("Frame", {
		Name = "Dialog",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(Platform.IsCompact() and 300 or 380, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Token("Surface"),
		[Create.Children] = {
			Create("UICorner", { CornerRadius = UDim.new(0, 12) }),
			Create("UIStroke", { Color = Theme.Token("Border"), Thickness = 1 }),
			Create("UIPadding", {
				PaddingLeft = UDim.new(0, 18),
				PaddingRight = UDim.new(0, 18),
				PaddingTop = UDim.new(0, 16),
				PaddingBottom = UDim.new(0, 16),
			}),
			Create("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }),
			scale,
			titleRow,
			content,
			buttonRow,
		},
	}) :: Frame

	local backdrop = Create("TextButton", {
		Name = "DialogBackdrop",
		Text = "",
		AutoButtonColor = false,
		Modal = true,
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 100,
		[Create.Children] = { panel },
	}) :: TextButton
	maid:Give(backdrop)
	backdrop.Parent = overlay

	local function close()
		Animation.tween(backdrop, { BackgroundTransparency = 1 }, "Fast")
		Animation.close(panel :: any, scale, function()
			maid:Destroy()
		end)
	end

	-- buttons
	local buttons = options.Buttons or { { Text = "OK", Variant = "Primary" } }
	for i, def in buttons do
		local isPrimary = (def.Variant or "Secondary") ~= "Secondary"
		local token = VARIANT[def.Variant or "Secondary"] or "Surface"
		local btn = Create("TextButton", {
			Name = def.Text,
			AutoButtonColor = false,
			LayoutOrder = i,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 32),
			BackgroundColor3 = isPrimary and Theme.Token(token) or Theme.Token("SurfaceVariant"),
			Font = Enum.Font.GothamMedium,
			TextSize = 14,
			TextColor3 = isPrimary and Color3.new(1, 1, 1) or Theme.Token("Text"),
			Text = def.Text,
			[Create.Children] = {
				Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
				Create("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }),
			},
		}) :: TextButton
		btn.Activated:Connect(function()
			if def.Callback then
				task.spawn(def.Callback)
			end
			close()
		end)
		btn.Parent = buttonRow
	end

	-- open animation
	panel.Visible = true
	Animation.tween(backdrop, { BackgroundTransparency = 0.45 }, "Normal")
	Animation.tween(scale, { Scale = 1 }, "Spring")

	return { Close = close }
end

return Dialog
