--!strict
--[[ Moon UI — Core/Section.lua
	A titled group of elements inside a Tab. Owns the element factory methods —
	this is the surface developers spend most time with. Every Create* method
	instantiates a component, parents its Root into the section list, registers
	it for cleanup, and returns the component handle for runtime control. ]]

local Create = require(script.Parent.Parent.Util.Create)
local Maid = require(script.Parent.Parent.Util.Maid)
local Theme = require(script.Parent.Parent.Systems.Theme)
local Types = require(script.Parent.Parent.Util.Types)

local Button = require(script.Parent.Parent.Components.Button)
local Toggle = require(script.Parent.Parent.Components.Toggle)
local Slider = require(script.Parent.Parent.Components.Slider)
local Textbox = require(script.Parent.Parent.Components.Textbox)
local Keybind = require(script.Parent.Parent.Components.Keybind)
local Dropdown = require(script.Parent.Parent.Components.Dropdown)
local ColorPicker = require(script.Parent.Parent.Components.ColorPicker)
local Display = require(script.Parent.Parent.Components.Display)

local Section = {}
Section.__index = Section

function Section.new(parent: Instance, name: string, context: any)
	local maid = Maid.new()

	local header = Create("TextLabel", {
		Name = "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		Text = name:upper(),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 0,
		Visible = name ~= "",
	}) :: TextLabel

	local list = Create("Frame", {
		Name = "Elements",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		[Create.Children] = {
			Create("UIListLayout", {
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	}) :: Frame

	local root = Create("Frame", {
		Name = "Section_" .. name,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		[Create.Children] = {
			Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
			header,
			list,
		},
	}) :: Frame
	maid:Give(root)
	root.Parent = parent

	maid:Give(Theme.Bind(function()
		header.TextColor3 = Theme.Token("MutedText")
	end))

	local self = setmetatable({
		Root = root,
		_list = list,
		_maid = maid,
		_context = context,
		_order = 0,
		_elements = {} :: { any },
	}, Section)
	return self
end

-- Generic registration: parents a component's Root and tracks it.
function Section:_add(component: any): any
	self._order += 1
	component.Root.LayoutOrder = self._order
	component.Root.Parent = self._list
	self._maid:Give(component)
	table.insert(self._elements, component)
	return component
end

-- Inputs ---------------------------------------------------------------------
function Section:CreateButton(o: Types.ButtonOptions)
	return self:_add(Button.new(o, self._context))
end
function Section:CreateToggle(o: Types.ToggleOptions)
	return self:_add(Toggle.new(o, self._context))
end
function Section:CreateSlider(o: Types.SliderOptions)
	return self:_add(Slider.new(o, self._context))
end
function Section:CreateTextbox(o: Types.TextboxOptions)
	return self:_add(Textbox.new(o, self._context))
end
function Section:CreateKeybind(o: Types.KeybindOptions)
	return self:_add(Keybind.new(o, self._context))
end
function Section:CreateDropdown(o: Types.DropdownOptions)
	return self:_add(Dropdown.new(o, self._context))
end
function Section:CreateColorPicker(o: Types.ColorPickerOptions)
	return self:_add(ColorPicker.new(o, self._context))
end

-- Display ---------------------------------------------------------------------
function Section:CreateLabel(o: Types.LabelOptions)
	return self:_add(Display.Label(o))
end
function Section:CreateParagraph(o: Types.ParagraphOptions)
	return self:_add(Display.Paragraph(o))
end
function Section:CreateDivider(label: string?)
	return self:_add(Display.Divider(label))
end
function Section:CreateBadge(text: string, variant: string?)
	return self:_add(Display.Badge(text, variant))
end
function Section:CreateProgress(initial: number?)
	return self:_add(Display.Progress(initial))
end

function Section:Destroy()
	self._maid:Destroy()
end

return Section
