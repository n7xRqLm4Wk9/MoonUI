--!strict
--[[
	Moon UI — Components/Base.lua
	Factory for the canonical "setting row": optional leading icon, a title,
	an optional description, and a right-aligned control slot. Every input
	component composes this so spacing, hover, theming and accessibility are
	implemented exactly once.

	Returns a table the concrete component extends:
		row.Root        Frame                (the clickable row)
		row.Control     Frame                (right-aligned slot for the widget)
		row.Maid        Maid
		row:SetTitle(text)
		row:SetDescription(text)
		row:SetIcon(name)
		row:SetVisible(bool)
		row:Destroy()
]]

local Create = require(script.Parent.Parent.Util.Create)
local Maid = require(script.Parent.Parent.Util.Maid)
local Platform = require(script.Parent.Parent.Util.Platform)
local Theme = require(script.Parent.Parent.Systems.Theme)
local Animation = require(script.Parent.Parent.Systems.Animation)
local Icons = require(script.Parent.Parent.Systems.Icons)

local Base = {}

export type Row = {
	Root: Frame,
	Control: Frame,
	TitleLabel: TextLabel,
	DescLabel: TextLabel,
	Maid: any,
	SetTitle: (self: Row, text: string) -> (),
	SetDescription: (self: Row, text: string?) -> (),
	SetIcon: (self: Row, name: string?) -> (),
	SetVisible: (self: Row, visible: boolean) -> (),
	SetEnabled: (self: Row, enabled: boolean) -> (),
	Destroy: (self: Row) -> (),
}

export type RowConfig = {
	Name: string,
	Description: string?,
	Icon: string?,
	Interactive: boolean?, -- whether the whole row reacts to hover/click
	ControlWidth: number?,
}

function Base.create(config: RowConfig): Row
	local maid = Maid.new()
	local pad = Theme.Token("Padding")

	local iconHolder = Create("ImageLabel", {
		Name = "Icon",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(18, 18),
		Visible = config.Icon ~= nil,
		ScaleType = Enum.ScaleType.Fit,
		LayoutOrder = 1,
	}) :: ImageLabel

	local titleLabel = Create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = config.Name,
	}) :: TextLabel

	local descLabel = Create("TextLabel", {
		Name = "Description",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = config.Description or "",
		Visible = config.Description ~= nil,
		AutomaticSize = Enum.AutomaticSize.Y,
	}) :: TextLabel

	local textColumn = Create("Frame", {
		Name = "Text",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = 2,
		[Create.Children] = {
			Create("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 2),
			}),
			titleLabel,
			descLabel,
		},
	})

	local leftGroup = Create("Frame", {
		Name = "Left",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, -(config.ControlWidth or 120) - pad, 0, 0),
		[Create.Children] = {
			Create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 10),
			}),
			iconHolder,
			textColumn,
		},
	})

	local control = Create("Frame", {
		Name = "Control",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, config.ControlWidth or 120, 1, 0),
		[Create.Children] = {
			Create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	}) :: Frame

	local minH = math.max(48, Platform.TouchTarget() + 14)
	local root = Create("Frame", {
		Name = config.Name,
		BackgroundColor3 = Theme.Token("SurfaceVariant"),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, minH),
		AutomaticSize = Enum.AutomaticSize.Y,
		[Create.Children] = {
			Create("UICorner", { CornerRadius = UDim.new(0, Theme.Token("CornerRadius") - 2) }),
			Create("UIPadding", {
				PaddingLeft = UDim.new(0, pad),
				PaddingRight = UDim.new(0, pad),
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 8),
			}),
			Create("Frame", {
				Name = "Inner",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				[Create.Children] = { leftGroup, control },
			}),
		},
	}) :: Frame

	maid:Give(root)

	-- Theme binding (live, no rebuild).
	maid:Give(Theme.Bind(function()
		titleLabel.TextColor3 = Theme.Token("Text")
		descLabel.TextColor3 = Theme.Token("SubText")
		iconHolder.ImageColor3 = Theme.Token("SubText")
		root.BackgroundColor3 = Theme.Token("Hover")
	end))

	if config.Icon then
		Icons.Apply(iconHolder, config.Icon)
	end

	local self: Row = {
		Root = root,
		Control = control,
		TitleLabel = titleLabel,
		DescLabel = descLabel,
		Maid = maid,
	} :: any

	function self.SetTitle(_, text)
		titleLabel.Text = text
	end
	function self.SetDescription(_, text)
		descLabel.Text = text or ""
		descLabel.Visible = text ~= nil and text ~= ""
	end
	function self.SetIcon(_, name)
		iconHolder.Visible = name ~= nil and Icons.Apply(iconHolder, name)
	end
	function self.SetVisible(_, visible)
		root.Visible = visible
	end
	function self.SetEnabled(_, enabled)
		root.Active = enabled
		local t = enabled and 0 or 0.5
		titleLabel.TextTransparency = t
		descLabel.TextTransparency = t
	end
	function self.Destroy(_)
		maid:Destroy()
	end

	-- Optional row-level hover feedback (used by Button / clickable rows).
	if config.Interactive then
		maid:Give(root.MouseEnter:Connect(function()
			Animation.tween(root, { BackgroundTransparency = 0 }, "Fast")
		end))
		maid:Give(root.MouseLeave:Connect(function()
			Animation.tween(root, { BackgroundTransparency = 1 }, "Fast")
		end))
	end

	return self
end

return Base
