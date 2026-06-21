--!strict
--[[ Moon UI — Components/Dropdown.lua
	Single + multi select, optional search. Renders its popup into the window
	overlay layer so it floats above all rows and never clips inside scrolls. ]]

local Create = require(script.Parent.Parent.Util.Create)
local Theme = require(script.Parent.Parent.Systems.Theme)
local Animation = require(script.Parent.Parent.Systems.Animation)
local State = require(script.Parent.Parent.Systems.State)
local Icons = require(script.Parent.Parent.Systems.Icons)
local Base = require(script.Parent.Base)
local Types = require(script.Parent.Parent.Util.Types)

local Dropdown = {}
Dropdown.__index = Dropdown

export type Dropdown = {
	Root: Frame,
	State: Types.State<any>,
	Set: (self: Dropdown, value: any) -> (),
	Get: (self: Dropdown) -> any,
	SetOptions: (self: Dropdown, options: { string }) -> (),
	Destroy: (self: Dropdown) -> (),
}

function Dropdown.new(options: Types.DropdownOptions, context: any): Dropdown
	local multi = options.Multi or false
	local row = Base.create({
		Name = options.Name,
		Description = options.Description,
		ControlWidth = 160,
	})

	local items = table.clone(options.Options)
	local default = options.Default or (multi and {} or items[1])
	local state = State.new(default)

	local valueText = Create("TextLabel", {
		Name = "Value",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -28, 1, 0),
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromOffset(10, 0),
	}) :: TextLabel

	local arrow = Create("ImageLabel", {
		Name = "Arrow",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		ScaleType = Enum.ScaleType.Fit,
	}) :: ImageLabel
	Icons.Apply(arrow, "chevron-down")

	local button = Create("TextButton", {
		Name = "Display",
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = Theme.Token("SurfaceVariant"),
		[Create.Children] = {
			Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Create("UIStroke", { Name = "Stroke", Color = Theme.Token("Border"), Thickness = 1 }),
			valueText,
			arrow,
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
			button,
		},
	})
	holder.Parent = row.Control

	local self = setmetatable({ Root = row.Root, State = state, _row = row, _items = items }, Dropdown)
	local stroke = button:FindFirstChild("Stroke") :: UIStroke

	local function isSelected(opt: string): boolean
		local v = state:Get()
		if multi then
			for _, s in v :: { string } do
				if s == opt then
					return true
				end
			end
			return false
		end
		return v == opt
	end

	local function summary(): string
		local v = state:Get()
		if multi then
			local list = v :: { string }
			if #list == 0 then
				return "None"
			elseif #list <= 2 then
				return table.concat(list, ", ")
			end
			return #list .. " selected"
		end
		return tostring(v)
	end

	-- ── Popup (lives in overlay layer) ──────────────────────────────────────
	local popup: Frame
	local listFrame: ScrollingFrame
	local open = false
	local rowButtons: { [string]: TextButton } = {}

	local function buildPopup()
		local searchBox: TextBox?
		local children: { Instance } = {}
		if options.Searchable then
			searchBox = Create("TextBox", {
				Name = "Search",
				Size = UDim2.new(1, -8, 0, 28),
				Position = UDim2.fromOffset(4, 4),
				BackgroundColor3 = Theme.Token("Surface"),
				PlaceholderText = "Search...",
				Font = Enum.Font.Gotham,
				TextSize = 13,
				TextColor3 = Theme.Token("Text"),
				PlaceholderColor3 = Theme.Token("MutedText"),
				TextXAlignment = Enum.TextXAlignment.Left,
				[Create.Children] = {
					Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
					Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
				},
			}) :: TextBox
		end

		listFrame = Create("ScrollingFrame", {
			Name = "List",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(4, searchBox and 36 or 4),
			Size = UDim2.new(1, -8, 1, searchBox and -40 or -8),
			ScrollBarThickness = 3,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarImageColor3 = Theme.Token("Border"),
			[Create.Children] = {
				Create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
			},
		}) :: ScrollingFrame

		popup = Create("Frame", {
			Name = "DropdownPopup",
			BackgroundColor3 = Theme.Token("Elevated"),
			Size = UDim2.fromOffset(10, 10),
			Visible = false,
			ZIndex = 50,
			[Create.Children] = {
				Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
				Create("UIStroke", { Color = Theme.Token("Border"), Thickness = 1 }),
				listFrame,
			},
		}) :: Frame
		if searchBox then
			searchBox.Parent = popup
		end
		popup.Parent = context.OverlayLayer

		local function renderItems(filter: string?)
			for _, c in listFrame:GetChildren() do
				if c:IsA("TextButton") then
					c:Destroy()
				end
			end
			table.clear(rowButtons)
			for i, opt in self._items do
				if filter and filter ~= "" and not opt:lower():find(filter:lower(), 1, true) then
					continue
				end
				local check = Create("ImageLabel", {
					Name = "Check",
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -8, 0.5, 0),
					Size = UDim2.fromOffset(15, 15),
					ImageTransparency = isSelected(opt) and 0 or 1,
					ImageColor3 = Theme.Token("Primary"),
				}) :: ImageLabel
				Icons.Apply(check, "check")
				local optBtn = Create("TextButton", {
					Name = opt,
					LayoutOrder = i,
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundColor3 = isSelected(opt) and Theme.Token("Selected") or Theme.Token("SurfaceVariant"),
					BackgroundTransparency = isSelected(opt) and 0 or 1,
					Text = opt,
					Font = Enum.Font.Gotham,
					TextSize = 13,
					TextColor3 = Theme.Token("Text"),
					TextXAlignment = Enum.TextXAlignment.Left,
					AutoButtonColor = false,
					[Create.Children] = {
						Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
						Create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 28) }),
						check,
					},
				}) :: TextButton
				optBtn.Activated:Connect(function()
					self:_choose(opt)
				end)
				rowButtons[opt] = optBtn
				optBtn.Parent = listFrame
			end
		end

		if searchBox then
			searchBox:GetPropertyChangedSignal("Text"):Connect(function()
				renderItems(searchBox.Text)
			end)
		end
		self._renderItems = renderItems
		renderItems()
	end

	function self:_refreshPopupSelection()
		for opt, btn in rowButtons do
			local sel = isSelected(opt)
			btn.BackgroundTransparency = sel and 0 or 1
			local check = btn:FindFirstChild("Check") :: ImageLabel
			if check then
				check.ImageTransparency = sel and 0 or 1
			end
		end
	end

	function self:_choose(opt: string)
		if multi then
			local list = table.clone(state:Get() :: { string })
			local found = table.find(list, opt)
			if found then
				table.remove(list, found)
			else
				table.insert(list, opt)
			end
			state:Set(list)
			self:_refreshPopupSelection()
		else
			state:Set(opt)
			self:_close()
		end
	end

	function self:_position()
		local absPos = button.AbsolutePosition
		local absSize = button.AbsoluteSize
		local layerPos = context.OverlayLayer.AbsolutePosition
		local height = math.min(#self._items * 32 + (options.Searchable and 40 or 8), 220)
		popup.Position = UDim2.fromOffset(
			absPos.X - layerPos.X,
			absPos.Y - layerPos.Y + absSize.Y + 4
		)
		popup.Size = UDim2.fromOffset(absSize.X, height)
	end

	function self:_open()
		if open then
			return
		end
		open = true
		if not popup then
			buildPopup()
		end
		self:_position()
		popup.Visible = true
		Animation.tween(arrow, { Rotation = 180 }, "Fast")
		Animation.tween(stroke, { Color = Theme.Token("Primary") }, "Fast")
	end

	function self:_close()
		if not open then
			return
		end
		open = false
		if popup then
			popup.Visible = false
		end
		Animation.tween(arrow, { Rotation = 0 }, "Fast")
		Animation.tween(stroke, { Color = Theme.Token("Border") }, "Fast")
	end

	row.Maid:Give(button.Activated:Connect(function()
		if open then
			self:_close()
		else
			self:_open()
		end
	end))

	-- Close on outside click.
	row.Maid:Give(context.OverlayLayer.InputBegan:Connect(function(input)
		if open and input.UserInputType == Enum.UserInputType.MouseButton1 then
			local m = input.Position
			local p, s = popup.AbsolutePosition, popup.AbsoluteSize
			local b, bs = button.AbsolutePosition, button.AbsoluteSize
			local inPopup = m.X >= p.X and m.X <= p.X + s.X and m.Y >= p.Y and m.Y <= p.Y + s.Y
			local inBtn = m.X >= b.X and m.X <= b.X + bs.X and m.Y >= b.Y and m.Y <= b.Y + bs.Y
			if not inPopup and not inBtn then
				self:_close()
			end
		end
	end))

	row.Maid:Give(state:Subscribe(function(v)
		valueText.Text = summary()
		if options.Callback then
			task.spawn(options.Callback, v)
		end
	end))
	valueText.Text = summary()

	row.Maid:Give(Theme.Bind(function()
		button.BackgroundColor3 = Theme.Token("SurfaceVariant")
		valueText.TextColor3 = Theme.Token("Text")
		arrow.ImageColor3 = Theme.Token("SubText")
		stroke.Color = Theme.Token("Border")
	end))

	row.Maid:Give(function()
		if popup then
			popup:Destroy()
		end
	end)

	if options.Flag and context and context.Config then
		context.Config:Register(options.Flag, state)
	end

	return (self :: any) :: Dropdown
end

function Dropdown:Set(value)
	self.State:Set(value)
end
function Dropdown:Get()
	return self.State:Get()
end
function Dropdown:SetOptions(opts)
	self._items = table.clone(opts)
	if self._renderItems then
		self._renderItems()
	end
end
function Dropdown:Destroy()
	self.State:Destroy()
	self._row:Destroy()
end

return Dropdown
