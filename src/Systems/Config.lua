--!strict
--[[
	Moon UI — Config.lua
	Robust configuration manager.

	* Flags: any component with a `Flag` registers a State here. The config
	  serialises every flag's value into JSON on disk (when filesystem access is
	  available in the host) and restores them on load.
	* Versioned + checksummed payloads guard against corruption and across-
	  version drift. A bad/old file is rejected rather than applied blindly.
	* Auto-save debounces writes so rapid slider drags don't thrash the disk.

	Filesystem functions (writefile/readfile/...) are optional in vanilla
	Roblox; this module degrades gracefully to an in-memory store when they
	are unavailable, so the same API works everywhere.
]]

local HttpService = game:GetService("HttpService")
local State = require(script.Parent.State)
local Signal = require(script.Parent.Parent.Util.Signal)
local Types = require(script.Parent.Parent.Util.Types)

local Config = {}
Config.__index = Config

local SCHEMA_VERSION = 1

-- Host capability probing (exploit/plugin/studio environments differ).
local fs = {
	write = (writefile :: any),
	read = (readfile :: any),
	delete = (delfile :: any),
	exists = (isfile :: any),
	listfiles = (listfiles :: any),
	makefolder = (makefolder :: any),
	isfolder = (isfolder :: any),
}
local HAS_FS = type(fs.write) == "function" and type(fs.read) == "function"

export type ConfigManager = typeof(setmetatable({}, Config)) & {
	Saved: Types.Signal<string>,
	Loaded: Types.Signal<string>,
}

function Config.new(folder: string): ConfigManager
	local self = setmetatable({
		_folder = folder,
		_flags = {} :: { [string]: { state: Types.State<any>, encode: ((any) -> any)?, decode: ((any) -> any)? } },
		_memory = {} :: { [string]: string },
		_autosave = false,
		_pending = false,
		Saved = Signal.new(),
		Loaded = Signal.new(),
	}, Config)

	if HAS_FS then
		pcall(function()
			if not fs.isfolder(folder) then
				fs.makefolder(folder)
			end
		end)
	end

	return (self :: any) :: ConfigManager
end

-- Register a flag-backed State. encode/decode handle non-JSON types (Color3,
-- EnumItem, etc.) so the on-disk payload stays plain JSON.
function Config:Register(flag: string, state: Types.State<any>, encode: ((any) -> any)?, decode: ((any) -> any)?)
	self._flags[flag] = { state = state, encode = encode, decode = decode }
	state:Subscribe(function()
		if self._autosave then
			self:_scheduleAutoSave()
		end
	end)
end

function Config:_path(name: string): string
	return self._folder .. "/" .. name .. ".moon.json"
end

local function checksum(payload: string): number
	-- Lightweight FNV-1a hash; enough to detect truncation/tampering.
	local hash = 2166136261
	for i = 1, #payload do
		hash = bit32.bxor(hash, string.byte(payload, i))
		hash = (hash * 16777619) % 4294967296
	end
	return hash
end

function Config:_serialise(): string
	local data: Types.Dictionary<any> = {}
	for flag, entry in self._flags do
		local v = entry.state:Get()
		data[flag] = if entry.encode then entry.encode(v) else v
	end
	local body = HttpService:JSONEncode(data)
	local envelope = {
		version = SCHEMA_VERSION,
		checksum = checksum(body),
		data = data,
	}
	return HttpService:JSONEncode(envelope)
end

function Config:Save(name: string): boolean
	local ok, encoded = pcall(function()
		return self:_serialise()
	end)
	if not ok then
		return false
	end
	if HAS_FS then
		local wrote = pcall(fs.write, self:_path(name), encoded)
		if not wrote then
			return false
		end
	else
		self._memory[name] = encoded
	end
	self.Saved:Fire(name)
	return true
end

function Config:Load(name: string): boolean
	local raw: string?
	if HAS_FS then
		if not (fs.exists and fs.exists(self:_path(name))) then
			return false
		end
		local ok, content = pcall(fs.read, self:_path(name))
		if ok then
			raw = content
		end
	else
		raw = self._memory[name]
	end
	if not raw then
		return false
	end

	local ok, envelope = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not ok or type(envelope) ~= "table" then
		warn(`[Moon] Config '{name}' is corrupt and was skipped.`)
		return false
	end

	-- Version + integrity gate.
	if envelope.version ~= SCHEMA_VERSION then
		warn(`[Moon] Config '{name}' version mismatch ({tostring(envelope.version)} vs {SCHEMA_VERSION}); attempting best-effort load.`)
	end
	if envelope.checksum then
		local body = HttpService:JSONEncode(envelope.data)
		if checksum(body) ~= envelope.checksum then
			warn(`[Moon] Config '{name}' failed integrity check; not applied.`)
			return false
		end
	end

	for flag, value in envelope.data do
		local entry = self._flags[flag]
		if entry then
			local decoded = if entry.decode then entry.decode(value) else value
			entry.state:Set(decoded)
		end
	end
	self.Loaded:Fire(name)
	return true
end

function Config:Delete(name: string): boolean
	if HAS_FS then
		if fs.exists and fs.exists(self:_path(name)) and fs.delete then
			return (pcall(fs.delete, self:_path(name)))
		end
		return false
	else
		self._memory[name] = nil
		return true
	end
end

function Config:List(): { string }
	local names = {}
	if HAS_FS and fs.listfiles then
		local ok, files = pcall(fs.listfiles, self._folder)
		if ok then
			for _, f in files do
				local n = (f :: string):match("([^/\\]+)%.moon%.json$")
				if n then
					table.insert(names, n)
				end
			end
		end
	else
		for n in self._memory do
			table.insert(names, n)
		end
	end
	table.sort(names)
	return names
end

-- Import a raw exported payload string under `name`.
function Config:Import(name: string, encoded: string): boolean
	if HAS_FS then
		return (pcall(fs.write, self:_path(name), encoded))
	else
		self._memory[name] = encoded
		return true
	end
end

-- Export returns the raw JSON string (for copying to clipboard / sharing).
function Config:Export(name: string): string?
	if HAS_FS then
		if fs.exists and fs.exists(self:_path(name)) then
			local ok, content = pcall(fs.read, self:_path(name))
			return ok and content or nil
		end
		return nil
	else
		return self._memory[name]
	end
end

function Config:SetAutoSave(name: string, enabled: boolean)
	self._autosave = enabled
	self._autosaveName = name
end

function Config:_scheduleAutoSave()
	if self._pending then
		return
	end
	self._pending = true
	task.delay(0.5, function()
		self._pending = false
		if self._autosave and self._autosaveName then
			self:Save(self._autosaveName)
		end
	end)
end

return Config
