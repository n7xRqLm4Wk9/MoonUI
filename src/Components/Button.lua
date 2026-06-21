--!strict
--[[ Moon UI — Components/Button.lua ]]

local Create = require(script.Parent.Parent.Util.Create)
local Theme = require(script.Parent.Parent.Systems.Theme)
local Animation = require(script.Parent.Parent.Systems.Animation)
local Icons = require(script.Parent.Parent.Systems.Icons)
local Base = require(script.Parent.Base)
local Types = require(script.Parent.Parent.Util.Types)

local Button = {}
Button.__index = Button

export type Button = {
	Root: Frame,
	SetText: (self: Button, text: string) -> (),
	SetCallback: (self: Button, fn: () -> ()) -> (),
	Fire: (self: Button) -> (),
	Destroy: (self: Button) -> (),
}

function Button.new(options: Types.ButtonOptions, _context: any): Button
	local row = Base.create({
		Name = options.Name,
		Description = options.Description,
		Icon = options.Icon,
		Interactive = true,
		ControlWidth = 28,
	})

	local callback = options.Callback

	local chevron = Create("ImageLabel", {
		Name = "Chevron",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(16, 16),
		ScaleType = Enum.ScaleType.Fit,
	}) :: ImageLabel
	Icons.Apply(chevron, "chevron-right")
	chevron.Parent = row.Control

	-- Whole row acts as the button (better touch target than a small button).
	local hit = Create("TextButton", {
		Name = "Hit",
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 5,
	}) :: TextButton
	hit.Parent = row.Root

	local self = setmetatable({ Root = row.Root, _row = row, _cb = callback }, Button)

	row.Maid:Give(Theme.Bind(function()
		chevron.ImageColor3 = Theme.Token("MutedText")
	end))

	row.Maid:Give(hit.MouseButton1Down:Connect(function()
		Animation.tween(row.Root, { BackgroundColor3 = Theme.Token("Pressed") }, "Micro")
	end))
	row.Maid:Give(hit.Activated:Connect(function()
		Animation.tween(row.Root, { BackgroundColor3 = Theme.Token("Hover") }, "Fast")
		self:Fire()
	end))

	return (self :: any) :: Button
end

function Button:SetText(text)
	self._row:SetTitle(text)
end
function Button:SetCallback(fn)
	self._cb = fn
end
function Button:Fire()
	if self._cb then
		task.spawn(self._cb)
	end
end
function Button:Destroy()
	self._row:Destroy()
end

return Button
