--!strict
-- AuditionService (server, Studio only): the sound audition panel's server half (docs/test-requests.md, TR42). The finder
-- (tools/studio/Audio/Audition, run in Edit) leaves its candidates under ServerStorage.NL_Audition, which a playtest
-- copies; this hands them to the panel (client, Core/AuditionController) and keeps the picks it reports, each one also
-- printed, so the output holds them after the playtest ends:
--   game.ServerStorage.NL_Debug:Invoke("Audition")   the picks, a line each: cue, id, title, author, kept; and each ten that held none

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local DebugService = require(script.Parent.DebugService)

local FOLDER = "NL_Audition"

local AuditionService = {}

export type Pick = { Cue: string, Id: number, Title: string, Author: string, Kept: boolean }
export type Empty = { Cue: string, Page: number }
type Picks = { Kept: { Pick }, None: { Empty } }

local picks: { [Player]: Picks } = {}

-- One pick as the readout gives it, for Config.Cues and docs/asset-log.md.
local function line(p: Pick): string
	return `{p.Cue}, {p.Id}, {p.Title}, {p.Author}, {if p.Kept then "kept" else "not kept"}`
end

-- The panel's word: what's kept and which tens held none, whole each time, so a repeat never doubles a pick.
local function report(player: Player, kept: any, none: any): number
	if type(kept) ~= "table" or type(none) ~= "table" then
		return 0
	end
	local was = picks[player] or { Kept = {}, None = {} }
	local now: Picks = { Kept = {}, None = {} }
	local known: { [string]: boolean } = {}
	for _, p in was.Kept do
		known[`{p.Cue}#{p.Id}`] = true
	end
	for _, p in kept do
		if type(p) == "table" and type(p.Cue) == "string" and type(p.Id) == "number" then
			local pick: Pick = { Cue = p.Cue, Id = p.Id, Title = tostring(p.Title), Author = tostring(p.Author), Kept = true }
			table.insert(now.Kept, pick)
			if not known[`{p.Cue}#{p.Id}`] then
				print(`[NL] Audition: {line(pick)}`)
			end
		end
	end
	local empty: { [string]: boolean } = {}
	for _, e in was.None do
		empty[`{e.Cue}#{e.Page}`] = true
	end
	for _, e in none do
		if type(e) == "table" and type(e.Cue) == "string" and type(e.Page) == "number" then
			table.insert(now.None, { Cue = e.Cue, Page = e.Page })
			if not empty[`{e.Cue}#{e.Page}`] then
				print(`[NL] Audition: {e.Cue}, page {e.Page}, none`)
			end
		end
	end
	picks[player] = now
	return #now.Kept
end

local function readout(): { string }
	local lines = {}
	for _, p in picks do
		for _, k in p.Kept do
			table.insert(lines, line(k))
		end
		for _, e in p.None do
			table.insert(lines, `{e.Cue}, page {e.Page}, none`)
		end
	end
	return lines
end

function AuditionService.Start()
	if not RunService:IsStudio() then
		return
	end
	local found = ServerStorage:FindFirstChild(FOLDER)
	local candidates = found and found:FindFirstChild("Candidates")
	if candidates and candidates:IsA("StringValue") then
		local copy = Instance.new("StringValue")
		copy.Name = FOLDER
		copy.Value = candidates.Value
		copy.Parent = ReplicatedStorage
	end
	DebugService.Register("AuditionReport", report)
	DebugService.Register("Audition", readout)
end

return AuditionService
