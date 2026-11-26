--!strict
-- GoalService (server): today's three and their claims, and each stretch's dare (docs/test-requests.md, TR54; Rules.Goals,
-- Definitions.Goals, Config.Goals; the save's contract in docs/engineering-plan.md, "Goals").
-- - The days roll on join, before the base's away time lands, and at each UTC midnight. Each draw is fixed by the
--   player's id and the day. The game's events are noted in their own rules (Rules.Goals.Note), so every path counts.
-- - One action, "GoalClaim" { Day, Slot }: a finished goal's shard paid once, behind the op ledger.
-- - A stretch's dare: StageService opens it as each stretch begins (Stretch), judges it as the stretch clears (Judge, then
--   its stone paid inside the clear's own step), and closes it with the run (Stop). FightService's signals move it on.
--   The client reads it from two attributes: StageDare "<stage> <id>" and StageDareLook (Rules.Goals.DareLook while it
--   runs: "Holds", "Broken", "Waits" or "Kept"; at the clear "Kept" or "Broken").

local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Goals = require(Shared.Rules.Goals)
local GoalFacts = require(Shared.Rules.GoalFacts)
local Defs = require(Shared.Definitions.Goals)
local Config = require(Shared.Config.Goals)
local Stages = require(Shared.Rules.Stages)

local DataService = require(script.Parent.Parent.Core.DataService)
local DebugService = require(script.Parent.Parent.Core.DebugService)
local FightService = require(script.Parent.FightService)

local GoalService = {
	Priority = 15, -- after DataService; its Ready is heard before the base's (BaseService, in its Start), so a rejoin's
	-- away time is counted to today's goals
}

local WATCH = 0.2 -- seconds between reads of a lead's health, for a dare that follows it
local DAY_CHECK = 5 -- seconds between looks at the clock for UTC midnight

export type Judged = { Stage: number, Kept: boolean, Grade: string, Count: number }

type Live = {
	Ground: string,
	Difficulty: string,
	Stage: number,
	Dare: Goals.Dare,
	State: Goals.DareState,
	Open: boolean, -- false once judged
	Kept: { number }, -- the run's stretches whose dare was kept, for its card
	Stones: number,
	Grade: string,
}

local live: { [Player]: Live } = {}
local rolled: { [Player]: number } = {} -- the UTC day each player's goals were last brought up to

-- The days brought up to today, in a draft: a day past the bank leaves, each day missing inside it is drawn.
local function rollIn(draft: Profile.Data, player: Player, today: number): boolean
	local open = GoalFacts.Of(draft)
	return Goals.Roll(draft.Goals, today, Config.Bank, function(day: number): { string }
		return Goals.Draw(Defs.Rows, Defs.Lists, player.UserId, day, open)
	end)
end

local function roll(player: Player)
	local today = Goals.DayOf(os.time())
	DataService.Change(player, "GoalsRoll", function(draft: Profile.Data): { [string]: any }
		if rollIn(draft, player, today) then
			return { Ok = true, Day = today }
		end
		return { Ok = false, Error = "Same" } -- nothing to write, nothing pushed
	end)
	rolled[player] = today
end

-- A run's lead counted for the day: "lead a run with someone new" (StageService.Begin, TowerService.Begin).
function GoalService.Led(player: Player)
	local data = DataService.Get(player)
	local lead = if data then data.Roles.Lead else ""
	if lead == "" then
		return
	end
	local today = Goals.DayOf(os.time())
	DataService.Change(player, "GoalsLed", function(draft: Profile.Data): { [string]: any }
		if not Goals.Led(draft.Goals, today, lead) then
			return { Ok = false, Error = "Led" }
		end
		Goals.Note(draft, "NewLead")
		return { Ok = true }
	end)
end

local function shareOf(player: Player): number?
	local lead = FightService.LeadOf(player)
	if lead == nil or lead.Block.Health <= 0 then
		return nil
	end
	return lead.Health / lead.Block.Health
end

local function show(player: Player, l: Live, look: string)
	player:SetAttribute("StageDareLook", look)
	player:SetAttribute("StageDare", `{l.Stage} {l.Dare.Id}`)
end

-- An event on `player`'s running dare.
local function step(player: Player, event: string, value: number?)
	local l = live[player]
	if l == nil or not l.Open then
		return
	end
	if Goals.DareStep(l.Dare, l.State, event, value) then
		player:SetAttribute("StageDareLook", Goals.DareLook(l.Dare, l.State))
	end
end

-- A stretch begins: its dare opens, its own once its piece is in (Config.Goals.Ready), else the fallback.
function GoalService.Stretch(player: Player, rule: Stages.Run)
	local was = live[player]
	local l: Live = if was and was.Ground == rule.Ground and was.Difficulty == rule.Difficulty
		then was
		else {
			Ground = rule.Ground,
			Difficulty = rule.Difficulty,
			Stage = rule.Stage,
			Dare = Defs.Fallback,
			State = { Broken = false, Done = false },
			Open = false,
			Kept = {},
			Stones = 0,
			Grade = Config.Dare.Grade[rule.Ground] or "Low",
		}
	l.Stage = rule.Stage
	l.Dare = Goals.Dare(Defs.Dares, Defs.Fallback, rule.Stage, Config.Ready)
	l.State = { Broken = false, Done = false }
	l.Open = true
	live[player] = l
	if l.Dare.Kind == "Above" then
		Goals.DareStep(l.Dare, l.State, l.Dare.Event, shareOf(player) or 1)
	end
	show(player, l, Goals.DareLook(l.Dare, l.State))
end

-- The stretch clears: its dare judged once, its mark flaring or dark. The stone is paid by `Pay` inside the clear's own
-- step, so a clear that isn't saved pays nothing.
function GoalService.Judge(player: Player, rule: Stages.Run): Judged?
	local l = live[player]
	if l == nil or not l.Open or l.Stage ~= rule.Stage then
		return nil
	end
	if l.Dare.Kind == "Above" then
		Goals.DareStep(l.Dare, l.State, l.Dare.Event, shareOf(player) or 0)
	end
	l.Open = false
	local kept = Goals.DareKept(l.Dare, l.State)
	player:SetAttribute("StageDareLook", if kept then "Kept" else "Broken")
	return { Stage = rule.Stage, Kept = kept, Grade = l.Grade, Count = Config.Dare.Count }
end

-- Inside the clear's step: a kept dare's stone into the draft's bag.
function GoalService.Pay(draft: Profile.Data, judged: Judged?)
	if judged and judged.Kept then
		Goals.PayDare(draft, judged.Grade, judged.Count)
	end
end

-- After the clear is saved: the kept stretch joins the run's card.
function GoalService.Paid(player: Player, judged: Judged?)
	local l = live[player]
	if l and judged and judged.Kept then
		table.insert(l.Kept, judged.Stage)
		l.Stones += judged.Count
	end
end

-- The run's dares for its card: the stretches kept in it and the stones they paid, or nil when none was kept.
function GoalService.Card(player: Player): { [string]: any }?
	local l = live[player]
	if l == nil or #l.Kept == 0 then
		return nil
	end
	return { Kept = table.clone(l.Kept), Grade = l.Grade, Count = l.Stones }
end

-- The run is over: its dare closes and leaves the run's line.
function GoalService.Stop(player: Player)
	live[player] = nil
	player:SetAttribute("StageDare", nil)
	player:SetAttribute("StageDareLook", nil)
end

-- Studio only: the goals read, set for a test, or an event noted as the game would.
--   ("Goals", who)                    the save's days and the live dare
--   ("GoalsSet", who, days)           the save's days replaced (each { Day, Picks, Have, Claimed })
--   ("GoalNote", who, event, amount)  an event counted to every open goal, as Rules.Goals.Note does
--   ("DareStep", who, event, value)   an event on the running dare, as FightService's signals send it; its look after
local function registerDebug()
	DebugService.Register("DareStep", function(who: any, event: any, value: any): any
		local player = DebugService.ResolvePlayer(who)
		if not player or type(event) ~= "string" or (value ~= nil and type(value) ~= "number") then
			return { Ok = false, Error = "BadArgs" }
		end
		step(player, event, value)
		return { Ok = true, Look = player:GetAttribute("StageDareLook") }
	end)
	DebugService.Register("Goals", function(who: any): any
		local player = DebugService.ResolvePlayer(who)
		local data = if player then DataService.Get(player) else nil
		if not player or not data then
			return { Ok = false, Error = "NoPlayer" }
		end
		local l = live[player]
		return { Ok = true, Today = Goals.DayOf(os.time()), Days = data.Goals.Days, Led = data.Goals.Led, Dare = if l then { Stage = l.Stage, Id = l.Dare.Id, Open = l.Open, Kept = l.Kept, Stones = l.Stones } else nil }
	end)
	DebugService.Register("GoalsSet", function(who: any, days: any): any
		local player = DebugService.ResolvePlayer(who)
		if not player or type(days) ~= "table" then
			return { Ok = false, Error = "BadArgs" }
		end
		return DataService.Change(player, "GoalsSet", function(draft: Profile.Data): { [string]: any }
			draft.Goals.Days = days
			return { Ok = true }
		end)
	end)
	DebugService.Register("GoalNote", function(who: any, event: any, amount: any): any
		local player = DebugService.ResolvePlayer(who)
		if not player or type(event) ~= "string" or (amount ~= nil and type(amount) ~= "number") then
			return { Ok = false, Error = "BadArgs" }
		end
		return DataService.Change(player, "GoalNote", function(draft: Profile.Data): { [string]: any }
			Goals.Note(draft, event, amount)
			return { Ok = true }
		end)
	end)
end

function GoalService.Init()
	DataService.Ready:Connect(function(player: Player)
		roll(player)
	end)
	if RunService:IsStudio() then
		registerDebug()
	end
	DataService.Action("GoalClaim", function(draft: Profile.Data, args: any, player: Player): { [string]: any }
		rollIn(draft, player, Goals.DayOf(os.time())) -- a day that has left the bank can't be claimed
		return Goals.Take(draft, args, Config.Reward)
	end)
end

function GoalService.Start()
	FightService.Broke:Connect(function(f: FightService.Fighter, _target: FightService.Fighter, signature: boolean)
		if signature and f.Side == "Lead" and f.Owner then
			step(f.Owner, "SignatureBreak")
		end
	end)
	FightService.Unmarked:Connect(function(_f: FightService.Fighter, mark: FightService.Mark, struck: { FightService.Fighter }?)
		if mark.Kind ~= nil and mark.Kind ~= "Second" then
			return -- the keeper's pools and sweep (TR69 D) are neither a slam nor a Dasher's line; its second slam is a slam
		end
		for _, lead in struck or {} do
			if lead.Side == "Lead" and lead.Owner then
				step(lead.Owner, if mark.Length ~= nil then "LineHit" else "SlamHit")
			end
		end
	end)
	FightService.Fell:Connect(function(f: FightService.Fighter)
		if f.Side == "Lead" and f.Owner then
			step(f.Owner, "LeadFell")
		end
	end)
	game:GetService("Players").PlayerRemoving:Connect(function(player: Player)
		live[player] = nil
		rolled[player] = nil
	end)
	task.spawn(function()
		local since = 0
		while true do
			local dt = task.wait(WATCH)
			for player, l in live do
				if l.Open and l.Dare.Kind == "Above" then
					local share = shareOf(player)
					if share then
						step(player, l.Dare.Event, share)
					end
				end
			end
			since += dt
			if since >= DAY_CHECK then
				since = 0
				local today = Goals.DayOf(os.time())
				for player, day in rolled do
					if day ~= today and player.Parent then
						roll(player)
					end
				end
			end
		end
	end)
end

return GoalService
