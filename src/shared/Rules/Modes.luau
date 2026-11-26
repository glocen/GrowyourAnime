--!strict
-- The Play panel's rules (shared, pure; the director, 2026-11-24: "i asked for the play button to open a panel of
-- gamemode"; docs/research/cloud-2026-11-24/play-mode-panel.md): which modes the dock's Play shows, a card each, and
-- what each card's press does for this player. A mode that isn't built has no card. The Festival's card goes where the
-- player would go next (Modes.Frontier), so a return player fights in two taps; the Arc panel stays one press further
-- for anyone who wants to choose. The Tower's card takes the player to their own gate at home (a teleport, TR65), and says where it's
-- climbed from anywhere else: the run still begins by stepping in, so the server's rules are untouched.
--   Modes.Frontier(data, ground) -> (difficulty, stretch)   where Continue takes this player
--   Modes.Cards(data, ground, home) -> { Card }             the cards, in the panel's order

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Grounds = require(Shared.Definitions.Grounds)
local Stages = require(Shared.Rules.Stages)

local Modes = {}

-- What a card's main press does: begins a run (Ground, Difficulty), takes the player to their own Tower gate, or
-- nothing while Off says why.
Modes.Begin = "Begin"
Modes.Ring = "Ring"

export type Card = {
	Id: string, -- "Festival" or "Tower"
	Title: string,
	Line: string, -- what the mode is, one line
	Says: string, -- where this player stands in it
	Press: string, -- the main press's word
	Does: string, -- Modes.Begin or Modes.Ring
	Off: string?, -- why the main press can't be pressed, in the player's words
	Second: string?, -- a quiet second press's word (the Festival's "Choose Arc")
	Ground: string?, -- for Modes.Begin
	Difficulty: string?,
	Stage: number?, -- the stretch the run begins at
	Count: number?, -- of how many
}

-- The difficulty a Continue takes on `ground`, and the stretch it begins at. A run under way comes first (a checkpoint
-- past the first stretch, the harder one if both stand); else the first open difficulty not yet cleared whole; else the
-- hardest open one. A seed, tuned by playing: the save doesn't yet say which the player fought last.
function Modes.Frontier(data: Profile.Data, ground: string): (string, number)
	local count = #((Stages.Of(ground) or {}) :: { any })
	local open: { string } = {}
	for _, which in Stages.Difficulties do
		if Stages.Needs(data, ground, which, 1) == nil then
			table.insert(open, which)
		end
	end
	for index = #open, 1, -1 do
		local at = Stages.Checkpoint(data, ground, open[index])
		if at > 1 then
			return open[index], at
		end
	end
	for _, which in open do
		if Stages.Line(data, ground, which).Cleared < count then
			return which, Stages.Checkpoint(data, ground, which)
		end
	end
	local which = open[#open] or Stages.Difficulties[1]
	return which, Stages.Checkpoint(data, ground, which)
end

local function festival(data: Profile.Data, ground: string): Card
	local row = Grounds.ById[ground]
	local named = if row then row.Name else "The Arcs"
	local count = #((Stages.Of(ground) or {}) :: { any })
	local which, at = Modes.Frontier(data, ground)
	local way = Stages.Way(data, ground, which)
	return {
		Id = "Festival",
		Title = "Festival of Battles",
		Line = "Fight through the Arcs beside your lead",
		Says = if count > 0 then `{named} · {which} · Stretch {at} of {count}` else named,
		Press = if at > 1 then "Continue" else "Fight",
		Does = Modes.Begin,
		Off = if way.Ok == true then nil else "Not open yet",
		Second = "Choose Arc",
		Ground = ground,
		Difficulty = which,
		Stage = at,
		Count = count,
	}
end

local function tower(data: Profile.Data, home: boolean): Card
	local record = data.Progress.Tower
	local best = if type(record.Best) == "number" then record.Best else 0
	local run = record.Run
	return {
		Id = "Tower",
		Title = "The Tower",
		Line = "One climb, floor by floor, until your lead falls",
		Says = if best > 0 then `Your record: floor {best}` else "No climb yet",
		Press = "Go to the Tower",
		Does = Modes.Ring,
		Off = if run ~= nil then "Climbing now" elseif not home then "Climb it from your base" else nil,
	}
end

-- The cards, in the panel's order: the Festival first, then the Tower. `home`: whether the player stands in the place
-- their base is in, where the Tower's ring is.
function Modes.Cards(data: Profile.Data, ground: string, home: boolean): { Card }
	return { festival(data, ground), tower(data, home) }
end

return Modes
