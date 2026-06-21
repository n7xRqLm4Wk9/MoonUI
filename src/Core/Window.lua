--!strict
--[[ Moon UI — Core/Window.lua
	The window shell: acrylic backdrop, title bar with controls, sidebar
	(profile + search + tab list) and content area with an overlay layer for
	floating popups and dialogs. Handles dragging, minimise, visibility toggle,
	responsive (mobile) layout and live theme switching. ]]

local UserInputService = game:GetService("UserInputService")
local Create = require(script.Parent.Parent.Util.Create)
local Maid = require(script.Parent.Parent.Util.Maid)
local Dragger = require(script.Parent.Parent.Util.Dragger)
local Platform = require(script.Parent.Parent.Util.Platform)
local Theme = require(script.Parent.Parent.Systems.Theme)
local Animation = require(script.Parent.Parent.Systems.Animation)
local Icons = require(script.Parent.Parent.Systems.Icons)
local Config = require(script.Parent.Parent.Systems.Config)
local Notification = require(script.Parent.Parent.Systems.Notification)
local Dialog = require(script.Parent.Parent.Systems.Dialog)
local Signal = require(script.Parent.Parent.Util.Signal)
local Tab = require(script.Parent.Tab)
local Types = require(script.Parent.Parent.Util.Types)

local Window = {}
Window.__index = Window

local function iconButton(name: string, iconName: string): TextButton
	local img = Create("ImageLabel", {
		Name = "Glyph",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(16, 16),
		ScaleType = Enum.ScaleType.Fit,
	}) :: ImageLabel
	Icons.Apply(img, iconName)
	return Create("TextButton", {
		Name = name,
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(28, 28),
		[Create.Children] = {
			Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
			img,
		},
	}) :: TextButton
end

function Window.new(parent: Instance, options: Types.WindowOptions)
	local maid = Maid.new()
	if options.Theme then
		Theme.Set(options.Theme)
	end

	local compact = Platform.IsCompact()
	local size = options.Size or Platform.DefaultWindowSize()
	local sidebarWidth = compact and 0 or 200

	--── Title bar controls ────────────────────────────────────────────────────
	local minimizeBtn = iconButton("Minimize", "minus")
	local maximizeBtn = iconButton("Maximize", "maximize")
	local closeBtn = iconButton("Close", "x")
	local controls = Create("Frame", {
		Name = "Controls",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(96, 28),
		[Create.Children] = {
			Create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 4),
			}),
			minimizeBtn,
			maximizeBtn,
			closeBtn,
		},
	}) :: Frame

	local titleIcon = Create("ImageLabel", {
		Name = "TitleIcon",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		Visible = options.Icon ~= nil,
		ScaleType = Enum.ScaleType.Fit,
	}) :: ImageLabel
	if options.Icon then
		Icons.Apply(titleIcon, options.Icon)
	end
	local titleText = Create("TextLabel", {
		Name = "TitleText",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, options.Icon and 36 or 12, 0, 0),
		Size = UDim2.new(1, -140, 1, 0),
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		Text = options.Title or "Moon",
		TextXAlignment = Enum.TextXAlignment.Left,
	}) :: TextLabel

	local titleBar = Create("Frame", {
		Name = "TitleBar",
		BackgroundColor3 = Theme.Token("Surface"),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 36),
		[Create.Children] = {
			titleIcon,
			titleText,
			controls,
			Create("Frame", {
				Name = "Underline",
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = Theme.Token("Divider"),
				BorderSizePixel = 0,
			}),
		},
	}) :: Frame

	--── Sidebar: profile + search + tab list ──────────────────────────────────
	local avatar = Create("ImageLabel", {
		Name = "Avatar",
		BackgroundColor3 = Theme.Token("SurfaceVariant"),
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(34, 34),
		Image = (options.User and options.User.Avatar) or "",
		[Create.Children] = { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) },
	}) :: ImageLabel
	local userName = Create("TextLabel", {
		Name = "Name",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(42, 2),
		Size = UDim2.new(1, -42, 0, 16),
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		Text = (options.User and options.User.Name) or "Moon User",
		TextXAlignment = Enum.TextXAlignment.Left,
	}) :: TextLabel
	local userSub = Create("TextLabel", {
		Name = "SubText",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(42, 18),
		Size = UDim2.new(1, -42, 0, 14),
		Font = Enum.Font.Gotham,
		TextSize = 11,
		Text = (options.User and options.User.SubText) or "",
		TextXAlignment = Enum.TextXAlignment.Left,
	}) :: TextLabel
	local profile = Create("Frame", {
		Name = "Profile",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 34),
		LayoutOrder = 1,
		[Create.Children] = { avatar, userName, userSub },
	}) :: Frame

	local searchInput = Create("TextBox", {
		Name = "SearchInput",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(30, 0),
		Size = UDim2.new(1, -38, 1, 0),
		Font = Enum.Font.Gotham,
		TextSize = 13,
		PlaceholderText = "Search...",
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
	}) :: TextBox
	local searchIcon = Create("ImageLabel", {
		Name = "SearchIcon",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 8, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		ScaleType = Enum.ScaleType.Fit,
	}) :: ImageLabel
	Icons.Apply(searchIcon, "search")
	local search = Create("Frame", {
		Name = "Search",
		BackgroundColor3 = Theme.Token("SurfaceVariant"),
		Size = UDim2.new(1, 0, 0, 32),
		LayoutOrder = 2,
		[Create.Children] = {
			Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
			searchIcon,
			searchInput,
		},
	}) :: Frame

	local tabList = Create("ScrollingFrame", {
		Name = "TabList",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -78),
		Position = UDim2.fromOffset(0, 78),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
		LayoutOrder = 3,
		[Create.Children] = {
			Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
		},
	}) :: ScrollingFrame

	local sidebar = Create("Frame", {
		Name = "Sidebar",
		BackgroundColor3 = Theme.Token("Surface"),
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(0, sidebarWidth, 1, -36),
		Visible = not compact,
		[Create.Children] = {
			Create("UIPadding", {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
				PaddingTop = UDim.new(0, 12),
			}),
			Create("Frame", {
				Name = "Top",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 78),
				[Create.Children] = {
					Create("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }),
					profile,
					search,
				},
			}),
			tabList,
			Create("Frame", {
				Name = "SideDivider",
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.new(0, 1, 1, 0),
				BackgroundColor3 = Theme.Token("Divider"),
				BorderSizePixel = 0,
			}),
		},
	}) :: Frame

	--── Content area ──────────────────────────────────────────────────────────
	local contentTitle = Create("TextLabel", {
		Name = "ContentTitle",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 30),
		Font = Enum.Font.GothamBold,
		TextSize = 24,
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
	}) :: TextLabel

	local pageHost = Create("Frame", {
		Name = "PageHost",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -42),
		LayoutOrder = 2,
	}) :: Frame

	local content = Create("Frame", {
		Name = "Content",
		BackgroundColor3 = Theme.Token("Background"),
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(sidebarWidth, 36),
		Size = UDim2.new(1, -sidebarWidth, 1, -36),
		[Create.Children] = {
			Create("UIPadding", {
				PaddingLeft = UDim.new(0, 20),
				PaddingRight = UDim.new(0, 16),
				PaddingTop = UDim.new(0, 16),
				PaddingBottom = UDim.new(0, 12),
			}),
			Create("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }),
			contentTitle,
			pageHost,
		},
	}) :: Frame

	-- Overlay layer floats above everything for popups/dialogs.
	local overlay = Create("Frame", {
		Name = "Overlay",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 50,
	}) :: Frame

	--── Root window frame ──────────────────────────────────────────────────────
	local scaleObj = Create("UIScale", {}) :: UIScale
	local root = Create("CanvasGroup", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = size,
		BackgroundColor3 = Theme.Token("Background"),
		GroupTransparency = 1,
		[Create.Children] = {
			Create("UICorner", { CornerRadius = UDim.new(0, Theme.Token("CornerRadius") + 2) }),
			Create("UIStroke", { Name = "WindowStroke", Color = Theme.Token("Border"), Thickness = 1 }),
			scaleObj,
			titleBar,
			sidebar,
			content,
			overlay,
		},
	}) :: CanvasGroup

	local gui = Create("ScreenGui", {
		Name = "Moon_" .. (options.Title or "Window"),
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		DisplayOrder = 1000,
		[Create.Children] = { root },
	}) :: ScreenGui
	maid:Give(gui)
	gui.Parent = parent

	-- Acrylic-ish blur behind the window.
	local blur: BlurEffect?
	if options.Acrylic ~= false then
		blur = Create("BlurEffect", { Name = "MoonAcrylic", Size = 0 }) :: BlurEffect
		blur.Parent = game:GetService("Lighting")
		maid:Give(blur)
	end

	--── Self ────────────────────────────────────────────────────────────────────
	local self = setmetatable({
		Gui = gui,
		Root = root,
		OverlayLayer = overlay,
		Config = Config.new(options.ConfigFolder or "MoonConfigs"),
		Closed = Signal.new(),
		_maid = maid,
		_tabs = {} :: { any },
		_active = nil :: any,
		_minimized = false,
		_visible = true,
		_blur = blur,
		_compact = compact,
		_sidebarWidth = sidebarWidth,
		_contentTitle = contentTitle,
		_pageHost = pageHost,
		_tabList = tabList,
		_scale = scaleObj,
	}, Window)
	-- Context shared with every component.
	self._context = { Config = self.Config, OverlayLayer = overlay, Window = self }

	--── Theme binding (live recolor of the whole shell) ─────────────────────────
	maid:Give(Theme.Bind(function()
		root.BackgroundColor3 = Theme.Token("Background")
		;(root.WindowStroke :: UIStroke).Color = Theme.Token("Border")
		titleBar.BackgroundColor3 = Theme.Token("Surface")
		;(titleBar.Underline :: Frame).BackgroundColor3 = Theme.Token("Divider")
		titleText.TextColor3 = Theme.Token("Text")
		titleIcon.ImageColor3 = Theme.Token("Text")
		sidebar.BackgroundColor3 = Theme.Token("Surface")
		;(sidebar.SideDivider :: Frame).BackgroundColor3 = Theme.Token("Divider")
		avatar.BackgroundColor3 = Theme.Token("SurfaceVariant")
		userName.TextColor3 = Theme.Token("Text")
		userSub.TextColor3 = Theme.Token("MutedText")
		search.BackgroundColor3 = Theme.Token("SurfaceVariant")
		searchInput.TextColor3 = Theme.Token("Text")
		searchInput.PlaceholderColor3 = Theme.Token("MutedText")
		searchIcon.ImageColor3 = Theme.Token("MutedText")
		content.BackgroundColor3 = Theme.Token("Background")
		contentTitle.TextColor3 = Theme.Token("Text")
		for _, btn in { minimizeBtn, maximizeBtn, closeBtn } do
			local glyph = btn:FindFirstChild("Glyph") :: ImageLabel
			glyph.ImageColor3 = Theme.Token("SubText")
		end
	end))

	-- Window control hover feedback.
	for _, btn in { minimizeBtn, maximizeBtn, closeBtn } do
		local danger = btn == closeBtn
		maid:Give(btn.MouseEnter:Connect(function()
			Animation.tween(btn, { BackgroundTransparency = 0, BackgroundColor3 = danger and Theme.Token("Danger") or Theme.Token("Hover") }, "Fast")
			if danger then
				Animation.tween(btn.Glyph :: ImageLabel, { ImageColor3 = Color3.new(1, 1, 1) }, "Fast")
			end
		end))
		maid:Give(btn.MouseLeave:Connect(function()
			Animation.tween(btn, { BackgroundTransparency = 1 }, "Fast")
			Animation.tween(btn.Glyph :: ImageLabel, { ImageColor3 = Theme.Token("SubText") }, "Fast")
		end))
	end

	maid:Give(minimizeBtn.Activated:Connect(function()
		self:Minimize()
	end))
	maid:Give(maximizeBtn.Activated:Connect(function()
		self:ToggleMaximize()
	end))
	maid:Give(closeBtn.Activated:Connect(function()
		self:Close()
	end))

	-- Search filters tab elements by title/description.
	maid:Give(searchInput:GetPropertyChangedSignal("Text"):Connect(function()
		self:_applySearch(searchInput.Text)
	end))

	-- Dragging via title bar.
	local dragger = Dragger.attach(titleBar, root)
	maid:Give(dragger)

	-- Visibility toggle key.
	local toggleKey = options.ToggleKey or Enum.KeyCode.RightShift
	maid:Give(UserInputService.InputBegan:Connect(function(input, gp)
		if not gp and input.KeyCode == toggleKey then
			self:ToggleVisibility()
		end
	end))

	-- Responsive relayout on viewport change.
	local cam = workspace.CurrentCamera
	if cam then
		maid:Give(cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			self:_relayout()
		end))
	end

	-- Open animation + acrylic ramp.
	root.Visible = true
	scaleObj.Scale = 0.94
	Animation.tween(root, { GroupTransparency = 0 }, "Normal")
	Animation.tween(scaleObj, { Scale = 1 }, "Spring")
	if blur then
		Animation.tween(blur, { Size = 18 }, "Slow")
	end

	return self
end

--── Public API ─────────────────────────────────────────────────────────────
function Window:CreateTab(options: Types.TabOptions)
	local tab = Tab.new(self, options, self._context)
	table.insert(self._tabs, tab)
	tab._order = #self._tabs
	tab.Button.LayoutOrder = #self._tabs
	tab.Button.Parent = self._tabList
	tab.Page.Parent = self._pageHost
	self._maid:Give(tab)
	if not self._active then
		self:SelectTab(tab)
	end
	return tab
end

function Window:SelectTab(tab: any)
	if self._active == tab then
		return
	end
	if self._active then
		self._active:SetSelected(false, false)
	end
	self._active = tab
	tab:SetSelected(true, true)
	self._contentTitle.Text = tab.Name
end

function Window:_applySearch(query: string)
	query = query:lower()
	local empty = query == ""
	for _, tab in self._tabs do
		for _, section in tab._sections do
			local anyVisible = false
			for _, element in section._elements do
				local root = element.Root
				local match = empty
				if not match then
					local titleLabel = root:FindFirstChild("Title", true)
					if titleLabel and titleLabel:IsA("TextLabel") then
						match = titleLabel.Text:lower():find(query, 1, true) ~= nil
					end
				end
				root.Visible = match
				anyVisible = anyVisible or match
			end
			section.Root.Visible = anyVisible or empty
		end
	end
end

function Window:Minimize()
	self._minimized = not self._minimized
	if self._minimized then
		Animation.close(self.Root :: any, self._scale)
		if self._blur then
			Animation.tween(self._blur, { Size = 0 }, "Fast")
		end
	else
		self.Root.Visible = true
		Animation.open(self.Root :: any, self._scale)
		if self._blur then
			Animation.tween(self._blur, { Size = 18 }, "Normal")
		end
	end
end

function Window:ToggleVisibility()
	self._visible = not self._visible
	if self._visible then
		self.Root.Visible = true
		Animation.open(self.Root :: any, self._scale)
		if self._blur then
			Animation.tween(self._blur, { Size = 18 }, "Normal")
		end
	else
		Animation.close(self.Root :: any, self._scale)
		if self._blur then
			Animation.tween(self._blur, { Size = 0 }, "Fast")
		end
	end
end

function Window:ToggleMaximize()
	if self._maximized then
		self.Root.Size = self._restoreSize or Platform.DefaultWindowSize()
		self.Root.Position = self._restorePos or UDim2.fromScale(0.5, 0.5)
		self._maximized = false
	else
		self._restoreSize = self.Root.Size
		self._restorePos = self.Root.Position
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		Animation.tween(self.Root, {
			Size = UDim2.fromOffset(vp.X - 40, vp.Y - 40),
			Position = UDim2.fromScale(0.5, 0.5),
		}, "Normal")
		self._maximized = true
	end
end

function Window:_relayout()
	local compact = Platform.IsCompact()
	if compact == self._compact then
		return
	end
	self._compact = compact
	local sidebar = self.Root.Sidebar :: Frame
	local content = self.Root.Content :: Frame
	if compact then
		sidebar.Visible = false
		content.Position = UDim2.fromOffset(0, 36)
		content.Size = UDim2.new(1, 0, 1, -36)
		self.Root.Size = Platform.DefaultWindowSize()
	else
		sidebar.Visible = true
		content.Position = UDim2.fromOffset(self._sidebarWidth, 36)
		content.Size = UDim2.new(1, -self._sidebarWidth, 1, -36)
	end
end

-- Notifications + dialogs are routed through the window so they share its GUI
-- parent and theme.
function Window:Notify(options: Types.NotifyOptions)
	return Notification.push(self.Gui.Parent, options)
end

function Window:Dialog(options: Types.DialogOptions)
	return Dialog.open(self.OverlayLayer, options)
end

-- Config convenience wrappers.
function Window:SaveConfig(name: string)
	return self.Config:Save(name)
end
function Window:LoadConfig(name: string)
	return self.Config:Load(name)
end
function Window:SetTheme(name: string)
	Theme.Set(name)
end

function Window:Close()
	Animation.close(self.Root :: any, self._scale, function()
		self.Closed:Fire()
		self._maid:Destroy()
	end)
	if self._blur then
		Animation.tween(self._blur, { Size = 0 }, "Fast")
	end
end

function Window:Destroy()
	self._maid:Destroy()
end

return Window
