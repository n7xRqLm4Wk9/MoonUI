--!strict
--[[ Moon UI — Core/Tab.lua
	A navigable page. Owns a scrolling content area that stacks Sections, plus
	a sidebar button. The Window controls show/hide; the Tab proxies element
	creation to a default section so simple usage (Tab:CreateToggle) works
	without explicitly creating a Section first. ]]

local Create = require(script.Parent.Parent.Util.Create)
local Maid = require(script.Parent.Parent.Util.Maid)
local Theme = require(script.Parent.Parent.Systems.Theme)
local Animation = require(script.Parent.Parent.Systems.Animation)
local Icons = require(script.Parent.Parent.Systems.Icons)
local Section = require(script.Parent.Section)
local Types = require(script.Parent.Parent.Util.Types)

local Tab = {}
Tab.__index = Tab

function Tab.new(window: any, options: Types.TabOptions, context: any)
	local maid = Maid.new()

	-- Sidebar button -----------------------------------------------------------
	local icon = Create("ImageLabel", {
		Name = "Icon",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		Visible = options.Icon ~= nil,
		ScaleType = Enum.ScaleType.Fit,
	}) :: ImageLabel
	if options.Icon then
		Icons.Apply(icon, options.Icon)
	end

	local selector = Create("Frame", {
		Name = "Selector",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(3, 0),
		BackgroundColor3 = Theme.Token("Primary"),
		BorderSizePixel = 0,
		[Create.Children] = { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) },
	}) :: Frame

	local label = Create("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, options.Icon and 36 or 14, 0, 0),
		Size = UDim2.new(1, -(options.Icon and 44 or 22), 1, 0),
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		Text = options.Name,
		TextXAlignment = Enum.TextXAlignment.Left,
	}) :: TextLabel

	local button = Create("TextButton", {
		Name = "Tab_" .. options.Name,
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Theme.Token("Hover"),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 36),
		[Create.Children] = {
			Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
			selector,
			icon,
			label,
		},
	}) :: TextButton
	maid:Give(button)

	-- Content page --------------------------------------------------------------
	local page = Create("ScrollingFrame", {
		Name = "Page_" .. options.Name,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.Token("Border"),
		Visible = false,
		[Create.Children] = {
			Create("UIPadding", {
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 10),
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 16),
			}),
			Create("UIListLayout", { Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder }),
		},
	}) :: ScrollingFrame
	maid:Give(page)

	local self = setmetatable({
		Name = options.Name,
		Button = button,
		Page = page,
		_window = window,
		_context = context,
		_maid = maid,
		_sections = {} :: { any },
		_default = nil :: any,
		_selected = false,
		_order = 0,
	}, Tab)

	maid:Give(Theme.Bind(function()
		selector.BackgroundColor3 = Theme.Token("Primary")
		page.ScrollBarImageColor3 = Theme.Token("Border")
		self:_paint()
	end))

	maid:Give(button.MouseEnter:Connect(function()
		if not self._selected then
			Animation.tween(button, { BackgroundTransparency = 0 }, "Fast")
		end
	end))
	maid:Give(button.MouseLeave:Connect(function()
		if not self._selected then
			Animation.tween(button, { BackgroundTransparency = 1 }, "Fast")
		end
	end))
	maid:Give(button.Activated:Connect(function()
		window:SelectTab(self)
	end))

	return self
end

function Tab:_paint()
	if self._selected then
		self.Button.BackgroundColor3 = Theme.Token("Selected")
		self.Button.BackgroundTransparency = 0
		;(self.Button.Label :: TextLabel).TextColor3 = Theme.Token("Text")
		;(self.Button.Icon :: ImageLabel).ImageColor3 = Theme.Token("Primary")
	else
		self.Button.BackgroundColor3 = Theme.Token("Hover")
		;(self.Button.Label :: TextLabel).TextColor3 = Theme.Token("SubText")
		;(self.Button.Icon :: ImageLabel).ImageColor3 = Theme.Token("SubText")
	end
end

function Tab:SetSelected(selected: boolean, animate: boolean)
	self._selected = selected
	local selector = self.Button.Selector :: Frame
	if selected then
		self.Page.Visible = true
		self:_paint()
		Animation.tween(self.Button, { BackgroundTransparency = 0 }, "Fast")
		Animation.tween(selector, { Size = UDim2.fromOffset(3, 18) }, "Normal")
		if animate then
			self.Page.Position = UDim2.fromOffset(0, 8)
			self.Page.Position = UDim2.fromOffset(0, 0)
		end
	else
		self.Page.Visible = false
		self:_paint()
		Animation.tween(self.Button, { BackgroundTransparency = 1 }, "Fast")
		Animation.tween(selector, { Size = UDim2.fromOffset(3, 0) }, "Fast")
	end
end

function Tab:CreateSection(options: Types.SectionOptions | string)
	local name = if type(options) == "string" then options else options.Name
	local section = Section.new(self.Page, name, self._context)
	self._order += 1
	section.Root.LayoutOrder = self._order
	table.insert(self._sections, section)
	self._maid:Give(section)
	return section
end

-- Default-section proxy so Tab:CreateX works without a manual Section.
function Tab:_defaultSection()
	if not self._default then
		self._default = self:CreateSection("")
	end
	return self._default
end

for _, method in {
	"CreateButton", "CreateToggle", "CreateSlider", "CreateTextbox",
	"CreateKeybind", "CreateDropdown", "CreateColorPicker",
	"CreateLabel", "CreateParagraph", "CreateDivider", "CreateBadge", "CreateProgress",
} do
	Tab[method] = function(self, ...)
		return self:_defaultSection()[method](self:_defaultSection(), ...)
	end
end

function Tab:Destroy()
	self._maid:Destroy()
end

return Tab
