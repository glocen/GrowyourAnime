--!strict
-- Logic cases (pure): the trip between the base and the Festival (TR45; Rules.Travel; Config.Travel). A ticket survives
-- its trip whole and nothing else does; a failed trip retries as Roblox's own pattern says, capped, and a server full or
-- gone sends the player to any server once; an arrival begins only a stage the player's own save opens. Runs in Studio
-- (LogicTests) and with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local TravelConfig = require(Shared.Config.Travel)
local Stages = require(Shared.Rules.Stages)
local Travel = require(Shared.Rules.Travel)

local NOW = 1_800_000_000
local GROUND = "lanternrow"

local function fresh(): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	return data
end

-- A save that has cleared the ground's first `count` stages on Normal, through the stages' own rules.
local function cleared(count: number): Profile.Data
	local data = fresh()
	for stage = 1, count do
		local run = Stages.Start(data, GROUND, "Normal", stage, NOW) :: Stages.Run
		local row = (Stages.Of(GROUND) :: any)[stage]
		local pack: string? = nil
		for _, stop in row.Stops do
			pack = if stop.Kind == "Pack" then stop.Def else pack
		end
		for _ = 1, row.Quota do
			Stages.Kill(run, pack :: string)
		end
		Stages.Kill(run, (Stages.Last(GROUND, stage) :: any).Def)
		Stages.Clear(data, run, NOW + 60)
	end
	return data
end

return {
	{
		Name = "Travel: a ticket comes back whole from its trip, and a forged or broken one comes back as none",
		Run = function(t: any)
			local out = Travel.Stage(GROUND, "Hard", 3, "job-1", NOW + 0.25)
			local back = Travel.Read(out) :: Travel.Ticket
			t.Check("read back", back ~= nil)
			if back then
				t.Check("every field", back.Go == "Stage" and back.Ground == GROUND and back.Difficulty == "Hard" and back.Stage == 3 and back.From == "job-1" and back.Sent == NOW + 0.25)
			end
			local home = Travel.Read(Travel.Home(NOW)) :: Travel.Ticket
			t.Check("home: nothing but its send", home ~= nil and home.Go == "Home" and home.Ground == nil and home.Stage == nil)
			t.Equal("nothing", Travel.Read(nil), nil)
			t.Equal("not a table", Travel.Read("Stage 1"), nil)
			local function with(field: string, value: any): any
				local copy = table.clone(out :: any)
				copy[field] = value
				return Travel.Read(copy)
			end
			t.Equal("an old version", with("V", Travel.Version + 1), nil)
			t.Equal("no send", with("Sent", nil), nil)
			t.Equal("a send that isn't a number (nan)", with("Sent", 0 / 0), nil)
			t.Equal("an unknown way", with("Go", "Shop"), nil)
			t.Equal("stage 0", with("Stage", 0), nil)
			t.Equal("stage 2.5", with("Stage", 2.5), nil)
			t.Equal("stage 1000", with("Stage", 1000), nil)
			t.Equal("a stage as text", with("Stage", "2"), nil)
			t.Equal("no ground", with("Ground", nil), nil)
			t.Equal("a ground of 65 letters", with("Ground", string.rep("a", 65)), nil)
			local junk = with("From", { "not", "a", "job" }) :: Travel.Ticket
			t.Check("a From that isn't text is dropped, the rest kept", junk ~= nil and junk.From == nil and junk.Stage == 3)
			local extra = table.clone(out :: any)
			extra.Credits = 1_000_000
			local kept = Travel.Read(extra) :: any
			t.Check("a field it doesn't know never comes through", kept ~= nil and kept.Credits == nil)
		end,
	},
	{
		Name = "Travel: a failed trip retries as Roblox's pattern says, capped, and a full or gone server sends the player to any",
		Run = function(t: any)
			local flood = Travel.Next("Flooded", 1, false) :: Travel.Step
			t.Check("a flood waits long", flood ~= nil and flood.Wait == TravelConfig.Flooded and not flood.Open)
			local fail = Travel.Next("Failure", 1, false) :: Travel.Step
			t.Check("a plain failure, briefly", fail ~= nil and fail.Wait == TravelConfig.Failure and not fail.Open)
			t.Check("a flood waits longer than a failure", TravelConfig.Flooded > TravelConfig.Failure)
			t.Equal("past the most, it gives up", Travel.Next("Failure", TravelConfig.Most + 1, false), nil)
			t.Check("on the most, still once more", Travel.Next("Failure", TravelConfig.Most, false) ~= nil)
			for _, final in { "Unauthorized", "IsTeleporting", "GameNotFound", "Unknown" } do
				t.Equal(`{final}: final`, Travel.Next(final, 1, true), nil)
			end
			local full = Travel.Next("GameFull", 1, true) :: Travel.Step
			t.Check("asked for one server, full: any server, at once", full ~= nil and full.Open and full.Wait == 0)
			local gone = Travel.Next("GameEnded", 1, true) :: Travel.Step
			t.Check("asked for one server, gone: any server", gone ~= nil and gone.Open)
			t.Equal("full with no server asked for: final", Travel.Next("GameFull", 1, false), nil)
			t.Check("the watchdog outlasts the retries' own waits", TravelConfig.Watchdog > TravelConfig.Flooded + TravelConfig.Calls * TravelConfig.Gap)
		end,
	},
	{
		Name = "Travel: an arrival begins the ticket's stage only if the player's own save opens it; otherwise Stage 1 for a fresh player, the menu for anyone else",
		Run = function(t: any)
			local two = cleared(1)
			local go = Travel.Arrival(Travel.Stage(GROUND, "Normal", 2, nil, NOW), two, GROUND)
			t.Check("Stage 2, open after Stage 1: it begins", go.Begin and go.Difficulty == "Normal" and go.Stage == 2 and go.Refused == nil)
			local skip = Travel.Arrival(Travel.Stage(GROUND, "Normal", 4, nil, NOW), two, GROUND)
			t.Check("Stage 4, not open: refused, the menu", not skip.Begin and skip.Refused == Stages.Before)
			local hard = Travel.Arrival(Travel.Stage(GROUND, "Hard", 1, nil, NOW), two, GROUND)
			t.Check("Hard before the keeper fell on Normal: refused", not hard.Begin and hard.Refused == Stages.Keeper)
			local new = fresh()
			local forged = Travel.Arrival(Travel.Stage(GROUND, "Normal", 4, nil, NOW), new, GROUND)
			t.Check("a fresh player's forged Stage 4: Stage 1 on Normal instead", forged.Begin and forged.Difficulty == "Normal" and forged.Stage == 1 and forged.Refused == Stages.Before)
			local none = Travel.Arrival(nil, new, GROUND)
			t.Check("a fresh player with no ticket: Stage 1 on Normal", none.Begin and none.Stage == 1 and none.Refused == nil)
			local back = Travel.Arrival(nil, two, GROUND)
			t.Check("anyone else with no ticket: the menu", not back.Begin and back.Refused == nil)
			local elsewhere = Travel.Arrival(Travel.Stage("nowhere", "Normal", 1, nil, NOW), two, GROUND)
			t.Check("a ticket for another ground: refused as unknown, the menu", not elsewhere.Begin and elsewhere.Refused == Stages.Unknown)
			local homeTicket = Travel.Arrival(Travel.Home(NOW), two, GROUND)
			t.Check("a home ticket here: the menu", not homeTicket.Begin)
		end,
	},
	{
		Name = "Travel: the trip's length is read from the ticket, and a clock past belief gives none",
		Run = function(t: any)
			local ticket = Travel.Stage(GROUND, "Normal", 1, nil, NOW)
			t.Equal("6.5 s", Travel.Took(ticket, NOW + 6.5), 6.5)
			t.Equal("arrived before it left", Travel.Took(ticket, NOW - 3), nil)
			t.Equal("ten minutes", Travel.Took(ticket, NOW + 600), nil)
		end,
	},
}
