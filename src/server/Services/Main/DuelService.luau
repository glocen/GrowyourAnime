--!strict
-- DuelService (server, Studio only): TR73's duel harness. One Voidkin against another on the real FightService (real
-- AI, real kits), measured per fight, so ranged against melee is read from fights, not from paper.
--   NL_Debug:Invoke("Duel", who, { Lead = "pip", Rival = "rook", LeadLevel = 30, RivalLevel = 30, Runs = 10, Seed = 1,
--                                  Limit = 90, Off = "Skip" })   starts a batch in the background
--   NL_Debug:Invoke("Duel", who, { spec, spec, ... })            a list, run one after another (the whole matrix)
--   NL_Debug:Invoke("DuelRead", who, brief)                      { Running, Done, Of, Results, Error }; each result one
--                                                                fight; brief leaves the results out
--   NL_Debug:Invoke("DuelStop", who)                             stops after the fight running, and puts everything back
-- The player's lead becomes `Lead` at LeadLevel (granted if the save has none: the Test store only), and a Tower rival
-- (FightService.SpawnRival) is `Rival` at RivalLevel. Both fight on their Voidkin's bare block at that level: no stars,
-- nothing worn, no Tower lift. They start Start studs apart (Pip's combo starts within 14.5) on a flat pad far from any
-- map, the avatar Behind studs behind its lead, still. A rival never skips and never flinches (FightService: trySkip is
-- the lead's, Combat.Flinch.Kinds has no Rival), so each direction runs the rules its sides own: each result says which.
-- `Health` (TR73's narrowing, research 2026-11-27) multiplies both sides' health, the kits and damage as they are: a
-- longer fight, to see what lasts past the burst. Each result carries it.
-- `Poise` (TR73) sets the lead's poise for the batch (Config.Combat.Poise.Lead, seconds; put back after). Each result
-- carries the one it ran.
-- `Off` turns one rule off for the batch, on the shared Config.Combat, and back after: "Skip" (Skip.On), "Flinch" (the
-- lead's flinch, Flinch.Kinds.Lead), "Push" (every hit's push: Weight.Lead and Weight.Rival at 0).
-- Each run seeds the hits' rolls (FightService.Seed: Seed + its index). The AI's own choices aren't seeded.
-- The player's camera look is fixed from the lead to the rival for every fight (FightService.FixView), so a lead never
-- waits on where Studio's camera points (View.Wait: 3 s, which made the off batches' first swings 4 to 5 s late, TR73).
-- The avatar goes back where it stood before the pad is taken away, so neither it nor its lead falls into the void.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Parts = require(Shared.Util.Parts)
local Actions = require(Shared.Definitions.Actions)
local Voidkin = require(Shared.Definitions.Voidkin)
local Combat = require(Shared.Config.Combat)
local Stats = require(Shared.Rules.Stats)
local Profile = require(Shared.Data.Profile)
local Collection = require(Shared.Rules.Collection)
local Core = script.Parent.Parent.Core
local DataService = require(Core.DataService)
local DebugService = require(Core.DebugService)
local FightService = require(script.Parent.FightService)

local PAD_NAME = "NL_DuelPad"
local CENTER = Vector3.new(800, 2500, 0) -- far above any map, apart from the replay's pad and the self-test's
local SIZE = Vector3.new(220, 4, 220)
local STAND = 3 -- an R6 root over the floor
local START = 14 -- studs apart at the bell: Pip's combo starts within 14.5
local BEHIND = 8 -- the avatar behind its lead
local SETTLE = 0.6 -- seconds the lead stands on its spot before the rival comes
local LEAD_WAIT = 12 -- seconds the save's new lead has to stand up as a fighter
local RANGED: { [string]: boolean } = { Mage = true, Healer = true }
local NEAR, FAR = 6, 13 -- the ranges' bands: under NEAR, NEAR to FAR, over FAR

local DuelService = {}

type Side = {
	Def: string,
	Role: string, -- "Ranged" or "Melee"
	FirstSwing: number?, -- seconds from the bell to its first action started (a skip not counted)
	FirstHit: number?, -- to its first hit landed (not dodged)
	Hits: number,
	Damage: number,
	Uptime: number, -- share of the fight's whole seconds in which it landed damage
	Flinches: number,
	Flinched: number, -- seconds in Flinch
	Stuns: number,
	Pushes: number, -- pushes taken
	Pushed: number, -- studs thrown
	Skips: number,
	Dodged: number, -- hits at it it dodged
	Ended: number, -- health share at the end
}
type Result = {
	LeadDef: string,
	RivalDef: string,
	LeadLevel: number,
	RivalLevel: number,
	Run: number,
	Seed: number,
	Off: string,
	Health: number,
	Poise: number,
	Winner: string, -- "Lead", "Rival" or "Time"
	WinnerDef: string,
	Seconds: number,
	Ranges: { Near: number, Mid: number, Far: number }, -- seconds in each band
	Rules: { Skip: string, Flinch: string }, -- which side's rule ran
	Lead: Side,
	Rival: Side,
}
type Batch = { Running: boolean, Stop: boolean, Done: number, Of: number, Results: { Result }, Error: string? }

local batches: { [Player]: Batch } = {}

local function pad(): BasePart
	local found = workspace:FindFirstChild(PAD_NAME)
	if found and found:IsA("BasePart") then
		return found
	end
	local floor = Instance.new("Part")
	floor.Name = PAD_NAME
	floor.Anchored = true
	floor.Size = SIZE
	floor.Position = CENTER
	floor.Color = Color3.fromRGB(88, 90, 96)
	floor.Material = Enum.Material.SmoothPlastic
	floor.Parent = workspace
	return floor
end

-- A Voidkin's own block at `level`: no stars, nothing worn.
local function bare(def: string, level: number, health: number?): Stats.Block
	local block = Stats.Resolve({
		Id = "",
		Def = def,
		Level = level,
		Xp = 0,
		Stars = 0,
		Copies = 0,
		Nickname = "",
		Preset = 0,
		Favourite = false,
		Locked = false,
		Born = 0,
	}, nil, nil)
	block.Health *= health or 1
	return block
end

local function roleOf(def: string): string
	local row = Voidkin.ById[def]
	return if row and RANGED[row.Class] then "Ranged" else "Melee"
end

local function newSide(def: string): Side
	return {
		Def = def,
		Role = roleOf(def),
		Hits = 0,
		Damage = 0,
		Uptime = 0,
		Flinches = 0,
		Flinched = 0,
		Stuns = 0,
		Pushes = 0,
		Pushed = 0,
		Skips = 0,
		Dodged = 0,
		Ended = 0,
	}
end

type Saved = { Lead: string, Levels: { [string]: { Level: number, Xp: number } } }

-- The save's lead set to `def` at `level`, granted if none is owned; what it was, to put back.
local function setLead(player: Player, def: string, level: number, saved: Saved?): (boolean, Saved?)
	local was: Saved? = nil
	local answer = DataService.Change(player, "DuelLead", function(draft: Profile.Data): { [string]: any }
		local function find(): string?
			for id, owned in draft.Voidkin do
				if owned.Def == def then
					return id
				end
			end
			return nil
		end
		local id = find()
		if id == nil then
			local made = Collection.Uncover(draft, def, workspace:GetServerTimeNow())
			if made.Ok == false then
				return made
			end
			id = find()
		end
		if id == nil then
			return { Ok = false, Error = "NotOwned" }
		end
		local key = id :: string
		local owned = draft.Voidkin[key]
		local keep: Saved = saved or { Lead = draft.Roles.Lead, Levels = {} }
		if keep.Levels[key] == nil then
			keep.Levels[key] = { Level = owned.Level, Xp = owned.Xp }
		end
		was = keep
		draft.Roles.Lead = key
		owned.Level, owned.Xp = level, 0
		return { Ok = true }
	end)
	return answer.Ok == true, was
end

local function putBack(player: Player, saved: Saved)
	DataService.Change(player, "DuelBack", function(draft: Profile.Data): { [string]: any }
		for id, keep in saved.Levels do
			local owned = draft.Voidkin[id]
			if owned then
				owned.Level, owned.Xp = keep.Level, keep.Xp
			end
		end
		if draft.Voidkin[saved.Lead] then
			draft.Roles.Lead = saved.Lead
		end
		return { Ok = true }
	end)
end

local function leadAs(player: Player, def: string, level: number): FightService.Fighter?
	local from = os.clock()
	while os.clock() - from < LEAD_WAIT do
		local lead = FightService.LeadOf(player)
		if lead and lead.Def == def and lead.Block.Level == level then
			return lead
		end
		task.wait(0.2)
	end
	return nil
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

-- One fight, measured.
local function fight(player: Player, spec: any, index: number): Result
	local seed = (spec.Seed :: number) + index
	FightService.Seed(seed)
	DebugService.Run("LeadHeal", player)
	local lead = leadAs(player, spec.Lead, spec.LeadLevel)
	assert(lead, "the lead didn't stand up as " .. spec.Lead)
	lead.Reblock = function(block: Stats.Block): Stats.Block
		return bare(block.Def, block.Level, spec.Health)
	end
	FightService.SetBlock(lead, lead.Block)
	FightService.SetHealthShare(lead, 1)
	-- The stage: the lead on its spot facing the rival's, the avatar behind it.
	local floor = pad()
	local y = floor.Position.Y + floor.Size.Y / 2 + STAND
	local leadAt = CFrame.lookAt(Vector3.new(CENTER.X, y, CENTER.Z + START / 2), Vector3.new(CENTER.X, y, CENTER.Z - START / 2))
	local rivalAt = CFrame.lookAt(Vector3.new(CENTER.X, y, CENTER.Z - START / 2), Vector3.new(CENTER.X, y, CENTER.Z + START / 2))
	local avatar = Parts.Root(player.Character)
	if avatar then
		avatar.AssemblyLinearVelocity = Vector3.zero
		avatar.CFrame = leadAt * CFrame.new(0, 0, BEHIND)
	end
	lead.Root.AssemblyLinearVelocity = Vector3.zero
	lead.Root.CFrame = leadAt
	lead.Humanoid:MoveTo(leadAt.Position)
	FightService.FixView(player, rivalAt.Position - leadAt.Position) -- the player watching their fight, the rival in view
	task.wait(SETTLE)
	local rival = FightService.SpawnRival(player, bare(spec.Rival, spec.RivalLevel, spec.Health), rivalAt, "Duel")
	local sides: { [FightService.Fighter]: Side } = { [lead] = newSide(spec.Lead), [rival] = newSide(spec.Rival) }
	local bins: { [FightService.Fighter]: { [number]: boolean } } = { [lead] = {}, [rival] = {} }
	local ranges = { Near = 0, Mid = 0, Far = 0 }
	local bell = os.clock()
	local over: FightService.Fighter? = nil
	local connections: { any } = {}
	table.insert(connections, FightService.Landed:Connect(function(a: FightService.Fighter, t: FightService.Fighter, landed: any)
		local by, at = sides[a], sides[t]
		if by == nil or at == nil then
			return
		end
		local now = os.clock() - bell
		if landed.Dodged then
			at.Dodged += 1
			return
		end
		by.Hits += 1
		by.Damage += landed.Total
		by.FirstHit = by.FirstHit or now
		bins[a][math.floor(now)] = true
		if landed.Flinch then
			at.Flinches += 1
		end
		if landed.Stun > 0 then
			at.Stuns += 1
		end
		if landed.Push > 0 then
			at.Pushes += 1
			at.Pushed += landed.Push
		end
	end))
	table.insert(connections, FightService.Fell:Connect(function(f: FightService.Fighter)
		if sides[f] and over == nil then
			over = f
		end
	end))
	for f, side in sides do
		local skip = Actions.SkipOf(f.Def)
		table.insert(connections, f.Model:GetAttributeChangedSignal("Action"):Connect(function()
			local id = f.Model:GetAttribute("Action")
			if type(id) ~= "string" or id == "" then
				return
			end
			if skip and id == skip.Id then
				side.Skips += 1
			elseif side.FirstSwing == nil then
				side.FirstSwing = os.clock() - bell
			end
		end))
	end
	local limit = spec.Limit :: number
	local last = os.clock()
	while over == nil and os.clock() - bell < limit and rival.Model.Parent ~= nil do
		task.wait()
		local now = os.clock()
		local dt = now - last
		last = now
		local gap = flat(lead.Root.Position - rival.Root.Position).Magnitude
		if gap < NEAR then
			ranges.Near += dt
		elseif gap <= FAR then
			ranges.Mid += dt
		else
			ranges.Far += dt
		end
		for f, side in sides do
			if f.Model:GetAttribute("State") == "Flinch" then
				side.Flinched += dt
			end
		end
	end
	local seconds = os.clock() - bell
	for _, c in connections do
		c:Disconnect()
	end
	local whole = math.max(1, math.ceil(seconds))
	for f, side in sides do
		local count = 0
		for _ in bins[f] do
			count += 1
		end
		side.Uptime = count / whole
		side.Ended = if f.Block.Health > 0 then math.max(f.Health, 0) / f.Block.Health else 0
	end
	local fallen = over :: FightService.Fighter?
	local winner = if fallen == lead then "Rival" elseif fallen == rival then "Lead" else "Time"
	local result: Result = {
		LeadDef = spec.Lead,
		RivalDef = spec.Rival,
		LeadLevel = spec.LeadLevel,
		RivalLevel = spec.RivalLevel,
		Run = index,
		Seed = seed,
		Off = spec.Off or "",
		Health = spec.Health or 1,
		Poise = (Combat.Poise :: any).Lead,
		Winner = winner,
		WinnerDef = if winner == "Lead" then spec.Lead elseif winner == "Rival" then spec.Rival else "",
		Seconds = seconds,
		Ranges = ranges,
		Rules = { Skip = if Actions.SkipOf(spec.Lead) then "Lead" else "none", Flinch = if (Combat.Flinch.Kinds :: any).Lead then "Lead" else "none" },
		Lead = sides[lead],
		Rival = sides[rival],
	}
	if rival.Model.Parent ~= nil then -- a fallen one goes by itself
		FightService.Remove(rival)
	end
	task.wait(0.3)
	return result
end

local OFF: { [string]: { { any } } } = {
	-- { table, key, value while off }
	Skip = { { Combat.Skip, "On", false } },
	Flinch = { { Combat.Flinch.Kinds, "Lead", false } },
	Push = { { Combat.Weight, "Lead", 0 }, { Combat.Weight, "Rival", 0 } },
}

local function runOne(player: Player, spec: any, batch: Batch)
	local saved: Saved? = nil
	local undo: { { any } } = {}
	local ok, err = pcall(function()
		for _, row in OFF[spec.Off or ""] or {} do
			table.insert(undo, { row[1], row[2], row[1][row[2]] })
			row[1][row[2]] = row[3]
		end
		if spec.Poise ~= nil then
			local poise: any = Combat.Poise
			table.insert(undo, { poise, "Lead", poise.Lead })
			poise.Lead = spec.Poise
		end
		local set, was = setLead(player, spec.Lead, spec.LeadLevel, nil)
		saved = was
		assert(set, "the lead couldn't be set")
		FightService.SetSolo(player, true)
		for index = 1, spec.Runs do
			if batch.Stop then
				break
			end
			table.insert(batch.Results, fight(player, spec, index))
			batch.Done += 1
		end
	end)
	if not ok then
		batch.Error = `{spec.Lead} against {spec.Rival}: {tostring(err)}`
	end
	for i = #undo, 1, -1 do
		local row = undo[i]
		row[1][row[2]] = row[3]
	end
	FightService.SetSolo(player, false)
	FightService.FixView(player, nil)
	local lead = FightService.LeadOf(player)
	if lead then
		lead.Reblock = nil
	end
	if saved then
		putBack(player, saved)
	end
	DebugService.Run("LeadHeal", player)
end

local function run(player: Player, specs: { any }, batch: Batch)
	local start = Parts.Root(player.Character)
	local stood = if start then start.CFrame else nil
	for _, spec in specs do
		if batch.Stop or batch.Error then
			break
		end
		runOne(player, spec, batch)
	end
	-- Off the pad before it goes: a lead left on it fell past FallenPartsDestroyHeight and fought on without a body.
	local avatar = Parts.Root(player.Character)
	if avatar and stood then
		avatar.AssemblyLinearVelocity = Vector3.zero
		avatar.CFrame = stood
		task.wait(0.5) -- its lead follows it (FightService's Teleport mode)
	end
	local found = workspace:FindFirstChild(PAD_NAME)
	if found then
		found:Destroy()
	end
	batch.Running = false
end

local function duel(who: any, spec: any): any
	local player = DebugService.ResolvePlayer(who)
	if player == nil or type(spec) ~= "table" then
		return { Ok = false, Error = "BadArgs" }
	end
	if batches[player] and batches[player].Running then
		return { Ok = false, Error = "Running" }
	end
	local list = if spec[1] ~= nil then spec else { spec }
	local specs = {}
	local total = 0
	for _, one in list do
		local given = {
			Lead = one.Lead,
			Rival = one.Rival,
			LeadLevel = one.LeadLevel or 30,
			RivalLevel = one.RivalLevel or 30,
			Runs = one.Runs or 10,
			Seed = one.Seed or 1,
			Limit = one.Limit or 90,
			Off = one.Off,
			Health = one.Health,
			Poise = one.Poise,
		}
		if type(given.Lead) ~= "string" or Voidkin.ById[given.Lead] == nil or type(given.Rival) ~= "string" or Voidkin.ById[given.Rival] == nil then
			return { Ok = false, Error = "BadArgs" }
		end
		if given.Off ~= nil and OFF[given.Off] == nil then
			return { Ok = false, Error = "BadOff" }
		end
		if given.Health ~= nil and not (type(given.Health) == "number" and given.Health > 0) then
			return { Ok = false, Error = "BadHealth" }
		end
		if given.Poise ~= nil and not (type(given.Poise) == "number" and given.Poise >= 0) then
			return { Ok = false, Error = "BadPoise" }
		end
		total += given.Runs
		table.insert(specs, given)
	end
	local batch: Batch = { Running = true, Stop = false, Done = 0, Of = total, Results = {} }
	batches[player] = batch
	task.spawn(run, player, specs, batch)
	return { Ok = true, Of = total }
end

local function duelRead(who: any, brief: any): any
	local player = DebugService.ResolvePlayer(who)
	local batch = if player then batches[player] else nil
	if batch == nil then
		return { Ok = false, Error = "None" }
	end
	return { Ok = true, Running = batch.Running, Done = batch.Done, Of = batch.Of, Results = if brief == true then nil else batch.Results, Error = batch.Error }
end

local function duelStop(who: any): any
	local player = DebugService.ResolvePlayer(who)
	local batch = if player then batches[player] else nil
	if batch then
		batch.Stop = true
	end
	return { Ok = true }
end

function DuelService.Start()
	if not RunService:IsStudio() then
		return
	end
	DebugService.Register("Duel", duel)
	DebugService.Register("DuelRead", duelRead)
	DebugService.Register("DuelStop", duelStop)
	Players.PlayerRemoving:Connect(function(player: Player)
		local batch = batches[player]
		if batch then
			batch.Stop = true
		end
		batches[player] = nil
	end)
end

return DuelService
