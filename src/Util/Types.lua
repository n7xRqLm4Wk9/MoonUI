--!strict
--[[
	Moon UI — Types.lua
	Central type definitions shared across the entire framework.
	Keeping every public/internal type in one module guarantees a single
	source of truth and prevents circular `require` chains for types.
]]

export type Dictionary<V> = { [string]: V }
export type Array<V> = { V }
export type Callback = (...any) -> ...any

--------------------------------------------------------------------------------
-- Signal
--------------------------------------------------------------------------------
export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
}

export type Signal<T...> = {
	Connect: (self: Signal<T...>, fn: (T...) -> ()) -> Connection,
	Once: (self: Signal<T...>, fn: (T...) -> ()) -> Connection,
	Wait: (self: Signal<T...>) -> T...,
	Fire: (self: Signal<T...>, T...) -> (),
	DisconnectAll: (self: Signal<T...>) -> (),
	Destroy: (self: Signal<T...>) -> (),
}

--------------------------------------------------------------------------------
-- Maid (lifecycle / cleanup)
--------------------------------------------------------------------------------
export type Task = Instance | RBXScriptConnection | Connection | () -> () | { Destroy: (any) -> () }

export type Maid = {
	Give: (self: Maid, task: Task) -> Task,
	GiveAll: (self: Maid, tasks: { Task }) -> (),
	Clean: (self: Maid) -> (),
	Destroy: (self: Maid) -> (),
	IsCleaning: (self: Maid) -> boolean,
}

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------
export type State<T> = {
	Get: (self: State<T>) -> T,
	Set: (self: State<T>, value: T) -> (),
	Update: (self: State<T>, transform: (T) -> T) -> (),
	Subscribe: (self: State<T>, listener: (new: T, old: T) -> ()) -> Connection,
	Destroy: (self: State<T>) -> (),
}

--------------------------------------------------------------------------------
-- Theme
--------------------------------------------------------------------------------
export type ThemeTokens = {
	-- Surfaces
	Background: Color3,
	Surface: Color3,
	SurfaceVariant: Color3,
	Elevated: Color3,
	-- Brand
	Primary: Color3,
	Accent: Color3,
	-- Text
	Text: Color3,
	SubText: Color3,
	MutedText: Color3,
	-- Lines / strokes
	Border: Color3,
	Divider: Color3,
	-- Status
	Success: Color3,
	Warning: Color3,
	Danger: Color3,
	Info: Color3,
	-- Interaction
	Hover: Color3,
	Pressed: Color3,
	Selected: Color3,
	-- Scalars (numbers, not colors)
	CornerRadius: number,
	Padding: number,
	StrokeThickness: number,
	AnimationSpeed: number, -- multiplier; 1 = default
}

export type Theme = {
	Name: string,
	Appearance: "Dark" | "Light",
	Tokens: ThemeTokens,
}

--------------------------------------------------------------------------------
-- Animation
--------------------------------------------------------------------------------
export type TweenSpec = {
	Time: number?,
	Style: Enum.EasingStyle?,
	Direction: Enum.EasingDirection?,
	Repeat: number?,
	Reverses: boolean?,
	Delay: number?,
}

--------------------------------------------------------------------------------
-- Component option tables (public API surface)
--------------------------------------------------------------------------------
export type WindowOptions = {
	Title: string?,
	SubTitle: string?,
	Icon: string?,
	Size: UDim2?,
	Theme: string?,
	Acrylic: boolean?,
	ToggleKey: Enum.KeyCode?,
	ConfigFolder: string?,
	User: { Name: string?, SubText: string?, Avatar: string? }?,
}

export type TabOptions = {
	Name: string,
	Icon: string?,
}

export type SectionOptions = {
	Name: string,
}

export type ButtonOptions = {
	Name: string,
	Description: string?,
	Icon: string?,
	Callback: (() -> ())?,
}

export type ToggleOptions = {
	Name: string,
	Description: string?,
	Default: boolean?,
	Flag: string?,
	Callback: ((value: boolean) -> ())?,
}

export type SliderOptions = {
	Name: string,
	Description: string?,
	Min: number,
	Max: number,
	Default: number?,
	Increment: number?,
	Suffix: string?,
	Flag: string?,
	Callback: ((value: number) -> ())?,
}

export type TextboxOptions = {
	Name: string,
	Description: string?,
	Default: string?,
	Placeholder: string?,
	ClearOnFocus: boolean?,
	Numeric: boolean?,
	Flag: string?,
	Callback: ((value: string) -> ())?,
}

export type KeybindOptions = {
	Name: string,
	Description: string?,
	Default: (Enum.KeyCode | Enum.UserInputType)?,
	Mode: ("Toggle" | "Hold" | "Always")?,
	Flag: string?,
	Callback: ((active: boolean) -> ())?,
	OnChanged: ((key: Enum.KeyCode | Enum.UserInputType) -> ())?,
}

export type DropdownOptions = {
	Name: string,
	Description: string?,
	Options: { string },
	Default: (string | { string })?,
	Multi: boolean?,
	Searchable: boolean?,
	Flag: string?,
	Callback: ((value: any) -> ())?,
}

export type ColorPickerOptions = {
	Name: string,
	Description: string?,
	Default: Color3?,
	Alpha: boolean?,
	Flag: string?,
	Callback: ((color: Color3, alpha: number) -> ())?,
}

export type LabelOptions = {
	Text: string,
	Icon: string?,
	Color: Color3?,
}

export type ParagraphOptions = {
	Title: string,
	Content: string,
}

export type NotifyOptions = {
	Title: string?,
	Content: string,
	Icon: string?,
	Duration: number?,
	Variant: ("Info" | "Success" | "Warning" | "Danger")?,
	Actions: { { Text: string, Callback: () -> () } }?,
}

export type DialogOptions = {
	Title: string,
	Content: string,
	Icon: string?,
	Buttons: { { Text: string, Variant: ("Primary" | "Secondary" | "Danger")?, Callback: (() -> ())? } }?,
}

return {}
