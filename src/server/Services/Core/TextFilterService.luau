--!strict
-- TextFilterService (server): what a player wrote, through Roblox's text filter, as the one who sees it may see it
-- (docs/roblox-rules.md, "Nicknames"; https://create.roblox.com/docs/ui/text-filtering, reread 2026-11-14: filtered after
-- it's submitted, never as it's typed, and stored text filtered when it's shown). Stored raw, each text is filtered for
-- each viewer, cached for as long as the viewer stays. A filter that errors shows nothing of the writer's, and is tried
-- again after a while.
--   TextFilterService.ForUser(author, raw, viewer) -> string?   yields: the text as `viewer` may see it, nil if it failed
--   TextFilterService.Cached(author, raw, viewer) -> string?    no yield: the cached text; nil until it's filtered, which
--                                                               it starts, firing Filtered once it's in
--   TextFilterService.Filtered: Signal (author, viewer)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Shared = ReplicatedStorage.Shared
local Log = require(Shared.Util.Log)
local Signal = require(Shared.Util.Signal)

local TextFilterService = {}
TextFilterService.Filtered = Signal.new()

local RETRY = 30 -- seconds before a failed filter is tried again

local cache: { [Player]: { [string]: string } } = {} -- by viewer, then by writer and text
local failed: { [string]: number } = {} -- by viewer, writer and text: when it last failed
local pending: { [string]: boolean } = {}

local function keyOf(author: Player, raw: string): string
	return `{author.UserId}:{raw}`
end

function TextFilterService.ForUser(author: Player, raw: string, viewer: Player): string?
	if raw == "" then
		return ""
	end
	local key = keyOf(author, raw)
	local seen = cache[viewer]
	if seen and seen[key] then
		return seen[key]
	end
	local ok, result = pcall(function(): string
		local filtered = TextService:FilterStringAsync(raw, author.UserId, Enum.TextFilterContext.PublicChat)
		return filtered:GetNonChatStringForUserAsync(viewer.UserId)
	end)
	if not ok then
		failed[`{viewer.UserId}:{key}`] = os.clock()
		Log.Warn("TextFilterService", `the filter failed for {author.Name}'s text: {result}`)
		return nil
	end
	if viewer.Parent then -- still in the server
		local mine = cache[viewer] or {}
		mine[key] = result
		cache[viewer] = mine
	end
	return result
end

function TextFilterService.Cached(author: Player, raw: string, viewer: Player): string?
	if raw == "" then
		return ""
	end
	local key = keyOf(author, raw)
	local seen = cache[viewer]
	if seen and seen[key] then
		return seen[key]
	end
	local job = `{viewer.UserId}:{key}`
	local last = failed[job]
	if pending[job] or (last and os.clock() - last < RETRY) then
		return nil
	end
	pending[job] = true
	task.spawn(function()
		local result = TextFilterService.ForUser(author, raw, viewer)
		pending[job] = nil
		if result ~= nil and viewer.Parent then
			TextFilterService.Filtered:Fire(author, viewer)
		end
	end)
	return nil
end

function TextFilterService.Init()
	Players.PlayerRemoving:Connect(function(player: Player)
		cache[player] = nil
	end)
end

return TextFilterService
