--!strict
--[[
	Moon UI — Animation.lua
	Centralised, TweenService-based motion system.

	* Named presets give the whole framework a single, consistent motion language.
	* Respects Theme.AnimationSpeed (global multiplier) so users can speed up /
	  slow down / disable motion at runtime.
	* tween() returns the Tween so callers can wait/cancel; helper verbs
	  (hover/press/open/close) encode intent rather than raw tween specs.
]]

local TweenService = game:GetService("TweenService")
local Theme = require(script.Parent.Theme)
local Types = require(script.Parent.Parent.Util.Types)

local Animation = {}

-- Easing presets. Tuned for a calm, "OS-grade" feel rather than bouncy.
Animation.Presets = {
	Instant = { Time = 0.0, Style = Enum.EasingStyle.Linear },
	Micro = { Time = 0.08, Style = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out },
	Fast = { Time = 0.15, Style = Enum.EasingStyle.Quint, Direction = Enum.EasingDirection.Out },
	Normal = { Time = 0.25, Style = Enum.EasingStyle.Quint, Direction = Enum.EasingDirection.Out },
	Slow = { Time = 0.40, Style = Enum.EasingStyle.Quint, Direction = Enum.EasingDirection.Out },
	Spring = { Time = 0.45, Style = Enum.EasingStyle.Back, Direction = Enum.EasingDirection.Out },
	Smooth = { Time = 0.30, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.InOut },
}

local function resolve(spec: Types.TweenSpec | string): Types.TweenSpec
	if type(spec) == "string" then
		return Animation.Presets[spec] or Animation.Presets.Normal
	end
	return spec
end

function Animation.info(spec: (Types.TweenSpec | string)?): TweenInfo
	local s = resolve(spec or "Normal")
	local mult = Theme.Token("AnimationSpeed") or 1
	local time = (s.Time or 0.25) / math.max(mult, 0.01)
	return TweenInfo.new(
		time,
		s.Style or Enum.EasingStyle.Quint,
		s.Direction or Enum.EasingDirection.Out,
		s.Repeat or 0,
		s.Reverses or false,
		s.Delay or 0
	)
end

function Animation.tween(inst: Instance, props: { [string]: any }, spec: (Types.TweenSpec | string)?): Tween
	local tween = TweenService:Create(inst, Animation.info(spec), props)
	tween:Play()
	return tween
end

-- Common intent helpers ------------------------------------------------------

function Animation.hover(inst: GuiObject, color: Color3)
	return Animation.tween(inst, { BackgroundColor3 = color }, "Fast")
end

function Animation.press(inst: GuiObject)
	-- subtle scale-down via UIScale if present, else a quick color blip
	local scale = inst:FindFirstChildOfClass("UIScale")
	if scale then
		Animation.tween(scale, { Scale = 0.96 }, "Micro")
		task.delay(0.09, function()
			if scale.Parent then
				Animation.tween(scale, { Scale = 1 }, "Fast")
			end
		end)
	end
end

function Animation.open(inst: GuiObject, scaleObj: UIScale?, finalSize: UDim2?)
	inst.Visible = true
	if scaleObj then
		scaleObj.Scale = 0.92
		Animation.tween(scaleObj, { Scale = 1 }, "Spring")
	end
	Animation.tween(inst, { GroupTransparency = 0 }, "Normal")
end

function Animation.close(inst: GuiObject, scaleObj: UIScale?, onDone: (() -> ())?)
	if scaleObj then
		Animation.tween(scaleObj, { Scale = 0.92 }, "Fast")
	end
	local t = Animation.tween(inst, { GroupTransparency = 1 }, "Fast")
	t.Completed:Once(function()
		inst.Visible = false
		if onDone then
			onDone()
		end
	end)
end

return Animation
