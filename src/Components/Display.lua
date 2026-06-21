--!strict
--[[ Moon UI — Components/Display.lua
	Non-interactive display widgets bundled together since each is tiny:
	Label, Paragraph, Divider, Badge, Progress. Each exposes a Root + Destroy
	and lightweight setters, all live-themed. ]]

local Create = require(script.Parent.Parent.Util.Create)
local Maid = require(script.Parent.Parent.Util.Maid)
local Theme = require(script.Parent.Parent.Systems.Theme)
local Animation = require(script.Parent.Parent.Systems.Animation)
local Icons = require(script.Parent.Parent.Systems.Icons)
local Types = require(script.Parent.Parent.Util.Types)

local Display = {}

--── Label ──────────────────────────────────────────────────────────────────
function Display.Label(options: Types.LabelOptions)
	local maid = Maid.new()
	local icon = Create("ImageLabel", {
		Name = "Icon",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(16, 16),
		Visible = options.Icon ~= nil,
		ScaleType = Enum.ScaleType.Fit,
		LayoutOrder = 1,
	}) :: ImageLabel
	if options.Icon then
		Icons.Apply(icon, options.Icon)
	end
	local text = Create("TextLabel", {
		Name = "Text",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		Text = options.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 2,
	}) :: TextLabel
	local root = Create("Frame", {
		Name = "Label",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		[Create.Children] = {
			Create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			icon,
			text,
		},
	}) :: Frame
	maid:Give(root)
	maid:Give(Theme.Bind(function()
		text.TextColor3 = options.Color or Theme.Token("SubText")
		icon.ImageColor3 = options.Color or Theme.Token("SubText")
	end))
	return {
		Root = root,
		SetText = function(_, t: string)
			text.Text = t
		end,
		Destroy = function()
			maid:Destroy()
		end,
	}
end

--── Paragraph ──────────────────────────────────────────────────────────────
function Display.Paragraph(options: Types.ParagraphOptions)
	local maid = Maid.new()
	local title = Create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		Text = options.Title,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
	}) :: TextLabel
	local body = Create("TextLabel", {
		Name = "Body",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		Text = options.Content,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 2,
	}) :: TextLabel
	local root = Create("Frame", {
		Name = "Paragraph",
		BackgroundColor3 = Theme.Token("SurfaceVariant"),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		[Create.Children] = {
			Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Create("UIPadding", {
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
			}),
			Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
			title,
			body,
		},
	}) :: Frame
	maid:Give(root)
	maid:Give(Theme.Bind(function()
		root.BackgroundColor3 = Theme.Token("SurfaceVariant")
		title.TextColor3 = Theme.Token("Text")
		body.TextColor3 = Theme.Token("SubText")
	end))
	return {
		Root = root,
		SetContent = function(_, t: string)
			body.Text = t
		end,
		Destroy = function()
			maid:Destroy()
		end,
	}
end

--── Divider ────────────────────────────────────────────────────────────────
function Display.Divider(label: string?)
	local maid = Maid.new()
	local line = Create("Frame", {
		Name = "Line",
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
	}) :: Frame
	local text: TextLabel? = nil
	local children: { Instance } = { line }
	if label then
		text = Create("TextLabel", {
			Name = "Caption",
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromScale(0, 1),
			Font = Enum.Font.GothamMedium,
			TextSize = 11,
			Text = label:upper(),
		}) :: TextLabel
	end
	local root = Create("Frame", {
		Name = "Divider",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, label and 16 or 9),
		[Create.Children] = label and {
			Create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 8),
			}),
			text,
		} or { line },
	}) :: Frame
	if label and text then
		line.Size = UDim2.new(1, -text.AbsoluteSize.X - 8, 0, 1)
		line.Parent = root
	end
	maid:Give(root)
	maid:Give(Theme.Bind(function()
		line.BackgroundColor3 = Theme.Token("Divider")
		if text then
			text.TextColor3 = Theme.Token("MutedText")
		end
	end))
	return {
		Root = root,
		Destroy = function()
			maid:Destroy()
		end,
	}
end

--── Badge ──────────────────────────────────────────────────────────────────
function Display.Badge(text: string, variant: string?)
	local maid = Maid.new()
	local label = Create("TextLabel", {
		Name = "Badge",
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 20),
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		Text = text,
		[Create.Children] = {
			Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
			Create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
		},
	}) :: TextLabel
	maid:Give(label)
	maid:Give(Theme.Bind(function()
		local color = Theme.Token(variant or "Primary") or Theme.Token("Primary")
		label.BackgroundColor3 = color
		label.TextColor3 = Theme.Get().Appearance == "Dark" and Color3.new(1, 1, 1) or Color3.new(1, 1, 1)
	end))
	return {
		Root = label,
		SetText = function(_, t: string)
			label.Text = t
		end,
		Destroy = function()
			maid:Destroy()
		end,
	}
end

--── Progress ───────────────────────────────────────────────────────────────
function Display.Progress(initial: number?)
	local maid = Maid.new()
	local fill = Create("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(math.clamp(initial or 0, 0, 1), 1),
		BorderSizePixel = 0,
		[Create.Children] = { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) },
	}) :: Frame
	local track = Create("Frame", {
		Name = "Progress",
		Size = UDim2.new(1, 0, 0, 8),
		BorderSizePixel = 0,
		[Create.Children] = {
			Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
			fill,
		},
	}) :: Frame
	maid:Give(track)
	maid:Give(Theme.Bind(function()
		track.BackgroundColor3 = Theme.Token("SurfaceVariant")
		fill.BackgroundColor3 = Theme.Token("Primary")
	end))
	return {
		Root = track,
		Set = function(_, alpha: number)
			Animation.tween(fill, { Size = UDim2.fromScale(math.clamp(alpha, 0, 1), 1) }, "Normal")
		end,
		Destroy = function()
			maid:Destroy()
		end,
	}
end

return Display
