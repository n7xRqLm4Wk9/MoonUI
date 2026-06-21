--!strict
--[[ Moon UI — Systems/Notification.lua
	Toast stack (top-right), auto-dismiss, slide+fade animation, variant colors,
	optional action buttons, icons. Owns its own ScreenGui so notifications
	survive window minimise/close. ]]

local Players = game:GetService("Players")
local Create = require(script.Parent.Parent.Util.Create)
local Maid = require(script.Parent.Parent.Util.Maid)
local Theme = require(script.Parent.Parent.Systems.Theme)
local Animation = require(script.Parent.Parent.Systems.Animation)
local Icons = require(script.Parent.Parent.Systems.Icons)
local Platform = require(script.Parent.Parent.Util.Platform)
local Types = require(script.Parent.Parent.Util.Types)

local Notification = {}

local gui: ScreenGui?
local stack: Frame?

local VARIANT_ICON = {
	Info = "info",
	Success = "check",
	Warning = "alert-triangle",
	Danger = "alert-circle",
}
local VARIANT_TOKEN = {
	Info = "Info",
	Success = "Success",
	Warning = "Warning",
	Danger = "Danger",
}

local function ensureLayer(parent: Instance)
	if gui and gui.Parent then
		return
	end
	stack = Create("Frame", {
		Name = "Stack",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 16),
		Size = UDim2.new(0, Platform.IsCompact() and 280 or 320, 1, -32),
		BackgroundTransparency = 1,
		[Create.Children] = {
			Create("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				VerticalAlignment = Enum.VerticalAlignment.Top,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
			}),
		},
	}) :: Frame
	gui = Create("ScreenGui", {
		Name = "MoonNotifications",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 10000,
		IgnoreGuiInset = true,
		[Create.Children] = { stack },
	}) :: ScreenGui
	gui.Parent = parent
end

local nextOrder = 0

function Notification.push(parent: Instance, options: Types.NotifyOptions)
	ensureLayer(parent)
	assert(stack, "notification stack")
	local variant = options.Variant or "Info"
	local accent = Theme.Token(VARIANT_TOKEN[variant])
	local maid = Maid.new()
	nextOrder += 1

	local icon = Create("ImageLabel", {
		Name = "Icon",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(18, 18),
		Position = UDim2.fromOffset(12, 12),
		ImageColor3 = accent,
		ScaleType = Enum.ScaleType.Fit,
	}) :: ImageLabel
	Icons.Apply(icon, options.Icon or VARIANT_ICON[variant])

	local title = Create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(40, 10),
		Size = UDim2.new(1, -52, 0, 18),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Theme.Token("Text"),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = options.Title or variant,
		Visible = options.Title ~= nil or true,
	}) :: TextLabel

	local content = Create("TextLabel", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(40, 30),
		Size = UDim2.new(1, -52, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = Theme.Token("SubText"),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Text = options.Content,
	}) :: TextLabel

	local progress = Create("Frame", {
		Name = "Progress",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
	}) :: Frame

	local card = Create("CanvasGroup", {
		Name = "Toast",
		LayoutOrder = nextOrder,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Token("Elevated"),
		GroupTransparency = 1,
		Position = UDim2.fromOffset(40, 0),
		[Create.Children] = {
			Create("UICorner", { CornerRadius = UDim.new(0, 10) }),
			Create("UIStroke", { Color = Theme.Token("Border"), Thickness = 1 }),
			Create("UIPadding", { PaddingBottom = UDim.new(0, 12) }),
			icon,
			title,
			content,
			progress,
		},
	}) :: CanvasGroup
	maid:Give(card)
	card.Parent = stack

	-- slide-in + fade
	Animation.tween(card, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) }, "Normal")

	local duration = options.Duration or 4
	local dismissed = false
	local function dismiss()
		if dismissed then
			return
		end
		dismissed = true
		local t = Animation.tween(card, { GroupTransparency = 1, Position = UDim2.fromOffset(40, 0) }, "Fast")
		t.Completed:Once(function()
			maid:Destroy()
		end)
	end

	-- countdown bar
	Animation.tween(progress, { Size = UDim2.new(0, 0, 0, 2) }, { Time = duration, Style = Enum.EasingStyle.Linear })
	local timer = task.delay(duration, dismiss)
	maid:Give(function()
		task.cancel(timer)
	end)

	-- click to dismiss
	local hit = Create("TextButton", {
		Name = "Hit",
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
	}) :: TextButton
	hit.Parent = card
	maid:Give(hit.Activated:Connect(dismiss))

	return { Dismiss = dismiss }
end

return Notification
