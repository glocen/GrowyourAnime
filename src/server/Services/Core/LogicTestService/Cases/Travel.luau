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
local GameConfig = require(Shared.Config.Game)

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
		Name = "Travel: an arrival begins the ticket's difficulty at the player's own checkpoint if their save opens it (TR50); otherwise Stage 1 for a fresh player, the menu for anyone else",
		Run = function(t: any)
			local two = cleared(1)
			local go = Travel.Arrival(Travel.Stage(GROUND, "Normal", 2, nil, NOW), two, GROUND, NOW)
			t.Check("Stage 1 cleared: the run begins at its checkpoint, 2", go.Begin and go.Difficulty == "Normal" and go.Stage == 2 and go.Refused == nil)
			local skip = Travel.Arrival(Travel.Stage(GROUND, "Normal", 4, nil, NOW), two, GROUND, NOW)
			t.Check("a ticket for Stage 4: the save's checkpoint still, 2, never past it", skip.Begin and skip.Stage == 2 and skip.Refused == nil)
			local hard = Travel.Arrival(Travel.Stage(GROUND, "Hard", 1, nil, NOW), two, GROUND, NOW)
			t.Check("Hard before the keeper fell on Normal: refused", not hard.Begin and hard.Refused == Stages.Keeper)
			local new = fresh()
			local forged = Travel.Arrival(Travel.Stage(GROUND, "Normal", 4, nil, NOW), new, GROUND, NOW)
			t.Check("a fresh player's forged Stage 4: Stage 1 on Normal, its checkpoint", forged.Begin and forged.Difficulty == "Normal" and forged.Stage == 1)
			local none = Travel.Arrival(nil, new, GROUND, NOW)
			t.Check("a fresh player with no ticket: Stage 1 on Normal", none.Begin and none.Stage == 1 and none.Refused == nil)
			local back = Travel.Arrival(nil, two, GROUND, NOW)
			t.Check("anyone else with no ticket: the menu", not back.Begin and back.Refused == nil)
			local elsewhere = Travel.Arrival(Travel.Stage("nowhere", "Normal", 1, nil, NOW), two, GROUND, NOW)
			t.Check("a ticket for another ground: refused as unknown, the menu", not elsewhere.Begin and elsewhere.Refused == Stages.Unknown)
			local homeTicket = Travel.Arrival(Travel.Home(NOW), two, GROUND, NOW)
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
	-- The engine-free part of the Festival suite's travel cases, "Places (TR45)" (TravelCases): the base's pick, the far
	-- side's trust in a joining player's ticket, and the round trip.
	{
		Name = "Travel (TR45): the base's pick carries the save's checkpoint, Hard refused before the keeper with what it waits for; the far side reads a ticket only from this universe's places, and the round trip begins the run where the base sent it",
		Run = function(t: any)
			local new = fresh()
			local first = Stages.Way(new, GROUND, "Normal")
			t.Check("a fresh save: Normal at its first stretch", first.Ok == true and first.Stage == 1)
			local hard = Stages.Way(new, GROUND, "Hard")
			t.Check("Hard shut, waiting for the keeper", hard.Ok == false and hard.Error == Stages.Locked and hard.Needs == Stages.Keeper)
			t.Equal("no such ground", Stages.Way(new, "nowhere", "Normal").Error, Stages.Unknown)
			t.Equal("no such difficulty", Stages.Way(new, GROUND, "Nightmare").Error, Stages.Unknown)
			local data = cleared(2)
			local way = Stages.Way(data, GROUND, "Normal")
			t.Check("two stretches cleared: the pick goes to 3", way.Ok == true and way.Stage == 3)
			local ticket = Travel.Stage(GROUND, "Normal", way.Stage, "job-a", NOW)
			local main, festival = GameConfig.Places.Main, GameConfig.Places.Festival
			t.Check("the two places differ", type(main) == "number" and type(festival) == "number" and main ~= festival)
			local came = Travel.Joined({ SourcePlaceId = main, TeleportData = ticket }, GameConfig.Places)
			t.Check("from the base: the ticket whole", came ~= nil and came.Go == "Stage" and came.Stage == 3 and came.From == "job-a" and came.Sent == NOW)
			local arrival = Travel.Arrival(came, data, GROUND, NOW)
			t.Check("the round trip: the run begins where the base sent it", arrival.Begin and arrival.Difficulty == "Normal" and arrival.Stage == 3 and arrival.Refused == nil)
			t.Check("from the Festival's own place (a hop): read", Travel.Joined({ SourcePlaceId = festival, TeleportData = Travel.Home(NOW) }, GameConfig.Places) ~= nil)
			t.Equal("from another experience's place: none", Travel.Joined({ SourcePlaceId = 1234567, TeleportData = ticket }, GameConfig.Places), nil)
			t.Equal("no source place (a plain join): none", Travel.Joined({ TeleportData = ticket }, GameConfig.Places), nil)
			t.Equal("a source place as text: none", Travel.Joined({ SourcePlaceId = tostring(main), TeleportData = ticket }, GameConfig.Places), nil)
			t.Equal("no join data: none", Travel.Joined(nil, GameConfig.Places), nil)
			t.Equal("from the base, broken: none", Travel.Joined({ SourcePlaceId = main, TeleportData = { V = 1, Go = "Stage" } }, GameConfig.Places), nil)
			local menu = Travel.Arrival(Travel.Joined({ SourcePlaceId = 1234567, TeleportData = ticket }, GameConfig.Places), data, GROUND, NOW)
			t.Check("a foreign ticket on a played save: the Arc panel, nothing begun", not menu.Begin and menu.Refused == nil)
		end,
	},
	{
		Name = "Travel (TR74): a ticket for the Keeper alone keeps its ask through Read, and an arrival begins it only where Rules.Stages.Alone allows",
		Run = function(t: any)
			local ticket = Travel.Read(Travel.Stage(GROUND, "Normal", 4, nil, NOW, true)) :: Travel.Ticket
			t.Check("read back: still the Keeper alone", ticket ~= nil and ticket.Alone == true)
			t.Check("a plain ticket asks nothing of it", (Travel.Read(Travel.Stage(GROUND, "Normal", 1, nil, NOW)) :: Travel.Ticket).Alone == nil)
			t.Check("a forged Alone that isn't true is dropped", (Travel.Read({ V = Travel.Version, Go = "Stage", Ground = GROUND, Difficulty = "Normal", Stage = 1, Alone = "yes", Sent = NOW }) :: Travel.Ticket).Alone == nil)
			local data = Profile.Template()
			Migrations.Run(data)
			local shut = Travel.Arrival(ticket, data, GROUND, NOW)
			t.Check("a save whose keeper hasn't fallen: refused, so no run", shut.Begin == false or shut.Alone == nil, shut.Refused)
			local count = #(Stages.Of(GROUND) :: { any })
			data.Progress.Stages[GROUND] = { Normal = { Cleared = count, Best = table.create(count, 60) }, Hard = { Cleared = 0, Best = table.create(count, 0) } }
			local open = Travel.Arrival(ticket, data, GROUND, NOW)
			t.Check("its keeper fallen and not resting: the keeper's stretch, alone", open.Begin == true and open.Stage == count and open.Alone == true and open.Difficulty == "Normal", open.Stage)
		end,
	},
}
