--!strict
--[[
	███╗   ███╗ ██████╗  ██████╗ ███╗   ██╗
	████╗ ████║██╔═══██╗██╔═══██╗████╗  ██║
	██╔████╔██║██║   ██║██║   ██║██╔██╗ ██║
	██║╚██╔╝██║██║   ██║██║   ██║██║╚██╗██║
	██║ ╚═╝ ██║╚██████╔╝╚██████╔╝██║ ╚████║
	╚═╝     ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝

	Moon — a modern, high-performance Roblox UI framework.
	MIT licensed. See README.md for full documentation.

	Entry point. Returns a ready-to-use Library instance:

		local Moon = require(path.to.Moon)
		local Window = Moon:CreateWindow({ Title = "Moon UI", Icon = "moon" })
		local Tab    = Window:CreateTab({ Name = "Combat", Icon = "swords" })
		Tab:CreateToggle({ Name = "Kill Aura", Default = false, Callback = print })
]]

local Library = require(script.src.Core.Library)

return Library.new()
