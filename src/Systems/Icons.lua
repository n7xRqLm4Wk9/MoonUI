--!strict
--[[
	Moon UI — Icons.lua
	Icon resolution + caching layer on top of a pluggable Lucide pack.

	Accepts three forms of icon reference and normalises them:
		"moon"                 -> lucide named icon (spritesheet lookup)
		"rbxassetid://123"     -> raw asset id
		123 (number)           -> raw asset id

	Resolved results are memoised. Apply() configures an ImageLabel/ImageButton
	(image, rect offset, rect size) and can be called again to hot-swap icons.
]]

local IconData = require(script.Parent.IconData)

local Icons = {}

local pack: IconData.Pack = IconData
local cache: { [string]: { Image: string, Offset: Vector2, Size: Vector2 } } = {}

export type Resolved = { Image: string, Offset: Vector2, Size: Vector2 }

local EMPTY: Resolved = { Image = "", Offset = Vector2.zero, Size = Vector2.zero }

-- Allow a project to swap in the full Lucide pack at runtime.
function Icons.SetPack(newPack: IconData.Pack)
	pack = newPack
	table.clear(cache)
end

function Icons.Has(name: string): boolean
	return pack.Map[name] ~= nil
end

function Icons.Resolve(ref: (string | number)?): Resolved
	if ref == nil or ref == "" then
		return EMPTY
	end

	if type(ref) == "number" then
		return { Image = "rbxassetid://" .. ref, Offset = Vector2.zero, Size = Vector2.zero }
	end

	local key = ref :: string
	local cached = cache[key]
	if cached then
		return cached
	end

	local resolved: Resolved
	if key:match("^rbxassetid://") or key:match("^rbxasset://") or key:match("^http") then
		resolved = { Image = key, Offset = Vector2.zero, Size = Vector2.zero }
	else
		local entry = pack.Map[key]
		if entry then
			resolved = {
				Image = pack.Sheets[entry.Sheet] or "",
				Offset = entry.Offset,
				Size = entry.Size,
			}
		else
			resolved = EMPTY
		end
	end

	cache[key] = resolved
	return resolved
end

-- Apply an icon to an existing Image instance. Returns true if a real icon
-- was applied (lets callers hide the holder when an icon is absent).
function Icons.Apply(image: ImageLabel | ImageButton, ref: (string | number)?): boolean
	local r = Icons.Resolve(ref)
	image.Image = r.Image
	if r.Size.Magnitude > 0 then
		image.ImageRectOffset = r.Offset
		image.ImageRectSize = r.Size
	else
		image.ImageRectOffset = Vector2.zero
		image.ImageRectSize = Vector2.zero
	end
	return r.Image ~= ""
end

return Icons
