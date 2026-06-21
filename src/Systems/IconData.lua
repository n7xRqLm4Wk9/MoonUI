--!strict
--[[
	Moon UI — IconData.lua
	Lucide icon data pack.

	Lucide ships ~1500 icons. In Roblox they are delivered as a spritesheet:
	one (or a few) uploaded image assets plus per-icon rect offset/size.
	This module returns that data in a uniform shape so Icons.lua stays
	agnostic to how the pack was produced.

	`Sheets` maps a sheet id -> rbxassetid image.
	`Map`    maps lucide-name -> { Sheet, Offset (Vector2), Size (Vector2) }.

	The framework ships a curated starter set wired to the public Lucide
	spritesheet upload pattern. To embed the FULL Lucide set, run the generator
	in /tools/generate_lucide.lua (see README) and replace `Map`/`Sheets` below —
	the rest of the framework needs no changes because the shape is stable.
]]

export type IconEntry = {
	Sheet: string,
	Offset: Vector2,
	Size: Vector2,
}

export type Pack = {
	Sheets: { [string]: string },
	Map: { [string]: IconEntry },
}

-- A 16x16 grid spritesheet (each cell 256px) is the layout produced by the
-- bundled generator. Offsets below follow that convention.
local CELL = 256

local function cell(sheet: string, col: number, row: number): IconEntry
	return {
		Sheet = sheet,
		Offset = Vector2.new(col * CELL, row * CELL),
		Size = Vector2.new(CELL, CELL),
	}
end

-- Replace this asset id with your uploaded Lucide spritesheet ("page 1").
local SHEET_1 = "rbxassetid://0"

local pack: Pack = {
	Sheets = {
		["1"] = SHEET_1,
	},
	Map = {
		-- Navigation / window
		["moon"] = cell("1", 0, 0),
		["home"] = cell("1", 1, 0),
		["settings"] = cell("1", 2, 0),
		["search"] = cell("1", 3, 0),
		["menu"] = cell("1", 4, 0),
		["x"] = cell("1", 5, 0),
		["minus"] = cell("1", 6, 0),
		["maximize"] = cell("1", 7, 0),
		["chevron-down"] = cell("1", 8, 0),
		["chevron-right"] = cell("1", 9, 0),
		["chevron-up"] = cell("1", 10, 0),
		["chevron-left"] = cell("1", 11, 0),
		-- Status
		["check"] = cell("1", 0, 1),
		["info"] = cell("1", 1, 1),
		["alert-triangle"] = cell("1", 2, 1),
		["alert-circle"] = cell("1", 3, 1),
		["bell"] = cell("1", 4, 1),
		-- Common
		["user"] = cell("1", 0, 2),
		["swords"] = cell("1", 1, 2),
		["layout"] = cell("1", 2, 2),
		["image"] = cell("1", 3, 2),
		["palette"] = cell("1", 4, 2),
		["message-square"] = cell("1", 5, 2),
		["sliders"] = cell("1", 6, 2),
		["trash"] = cell("1", 7, 2),
		["save"] = cell("1", 8, 2),
		["folder"] = cell("1", 9, 2),
		["eye"] = cell("1", 10, 2),
		["eye-off"] = cell("1", 11, 2),
		["copy"] = cell("1", 12, 2),
	},
}

return pack
