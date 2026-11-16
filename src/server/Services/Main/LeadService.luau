--!strict
-- LeadService (server): the player's lead in the world, the Voidkin in Roles.Lead (Shared.Data.Profile), as a fighter
-- beside the avatar (FightService). It follows the save: a new lead replaces the old one, and a level gained gives it its
-- new stat block, its health kept as a share. Studio adds LeadLevel, to try a fight at a level without playing up to it,
-- and VoidkinGive, to try a Voidkin no shard of the built grounds holds yet (Lyric's is the second ground's).
-- Health carries (TR12; docs/design.md, "Combat", "Health carries" to "The next lead"): a Voidkin taken in keeps what it
-- had and heals at home (Rules.Carry), in memory for the session; the lead never changes in a fight, and a fallen one goes
-- out again only once it's whole (VoidkinService asks LeadService.Refusal). The client reads the player's folder Healing
-- (an attribute a fallen one, by its Id, the server time it's whole: an attribute's string holds 50 characters, too few
-- for several) and the player's attributes InCombat and Training (who's on the machine, or "").
-- The Training machine (Rules.Training): one Voidkin trains while the player is in the game (Training.Who). It draws power
-- (TR18), so the base's clock (Rules.Breaker) trains it: here, whenever who trains changes, the base is advanced to now
-- with the one that was on it, then the save's Training.Trainee names the next, and every Config.Growth.Training.Every
-- seconds the base is advanced so its levels show. At a join BaseService's away advance trains the lead for the time away,
-- before this service's own Ready, so nothing here advances the base until then. Studio adds TrainingSkip, as if `seconds`
-- passed away, the lead on it, and LeadHeal: every Voidkin whole at once, a fallen lead back up
-- beside the avatar (the way home takes a walk to the plot, which a case on the test pad can't make), and VoidkinFallen:
-- every Voidkin but the lead fallen just now, so a lead falls alone (TR16).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Profile = require(Shared.Data.Profile)
local Voidkin = require(Shared.Definitions.Voidkin)
local GrowthConfig = require(Shared.Config.Growth)
local Carry = require(Shared.Rules.Carry)
local Training = require(Shared.Rules.Training)
local Breaker = require(Shared.Rules.Breaker)
local Markers = require(Shared.World.Markers)
local Stats = require(Shared.Rules.Stats)
local Parts = require(Shared.Util.Parts)
local Collection = require(Shared.Rules.Collection)
local Core = script.Parent.Parent.Core
local DataService = require(Core.DataService)
local DebugService = require(Core.DebugService)
local FightService = require(script.Parent.FightService)

local LeadService = {
	Priority = 40, -- after FightService
}

local HEALING = "Healing" -- the player's folder of fallen Voidkin healing at home (HudController reads it)

local function same(a: Stats.Block, b: Stats.Block): boolean
	for _, stat in Stats.Names do
		if (a :: any)[stat] ~= (b :: any)[stat] then
			return false
		end
	end
	return a.Level == b.Level
end

local function now(): number
	return workspace:GetServerTimeNow()
end

-- What each player's Voidkin carry while they aren't out, by Id (Rules.Carry).
local carried: { [Player]: { [string]: Carry.Entry } } = {}
local training: { [Player]: string } = {} -- who's on the machine now, "" for nobody
local settled: { [Player]: number } = {} -- when the machine was last credited

local function carriedOf(player: Player): { [string]: Carry.Entry }
	local mine = carried[player]
	if mine == nil then
		mine = {}
		carried[player] = mine
	end
	return mine
end

-- The lead being taken in keeps what it carries; a fallen one heals at the fallen rate from here.
local function takeIn(player: Player, f: FightService.Fighter)
	local id = f.Model:GetAttribute("Voidkin")
	if type(id) ~= "string" then
		return
	end
	local most = f.Block.Health
	carriedOf(player)[id] = {
		Share = if most > 0 then math.clamp(f.Health / most, 0, 1) else 1,
		At = now(),
		Fallen = f.State == "Down" or f.State == "Home",
	}
end

local function playerHome(player: Player): boolean
	local plot = player:GetAttribute("Plot")
	local root = Parts.Root(player.Character)
	return Markers.OnPlot(if type(plot) == "number" then plot else nil, if root then root.Position else nil)
end

-- Who's on the Training machine now while the player is in the game (Training.Who).
local function trainee(player: Player): string?
	local data = DataService.Get(player)
	if data == nil then
		return nil
	end
	local lead = FightService.LeadOf(player)
	local waiting = lead ~= nil and lead.State == "Home" and lead.Health >= lead.Block.Health
	local healed: { Training.Healed } = {}
	for id, entry in carriedOf(player) do
		if entry.Fallen and data.Voidkin[id] and Carry.Share(entry, now(), FightService.HomeOf(player)) >= 1 then
			table.insert(healed, { Id = id, Fell = entry.At })
		end
	end
	return Training.Who(playerHome(player), data.Roles.Lead, waiting, healed)
end

-- The base's clock run to now, the one on the machine trained up to now, then `who` on it from here ("" for nobody).
local function settle(player: Player, who: string, label: string)
	settled[player] = now()
	DataService.Change(player, label, function(draft: Profile.Data): { [string]: any }
		local summary = Breaker.Advance(draft, now())
		draft.Training.Trainee = who
		return { Ok = true, Id = summary.Trained or "", Levels = summary.Levels }
	end)
end

local function setAttribute(holder: Instance, name: string, value: any)
	if holder:GetAttribute(name) ~= value then
		holder:SetAttribute(name, value)
	end
end

-- What the client shows (the lead's card, the Voidkin screen, the machine's plate), and the machine's credit.
local function tick(player: Player)
	if DataService.Get(player) == nil or player.Parent ~= Players then
		return
	end
	local healing: { [string]: number } = {}
	local any = false
	-- The lead itself, fallen: down, then healing at home until StateUntil.
	local lead = FightService.LeadOf(player)
	local leadId = if lead then lead.Model:GetAttribute("Voidkin") else nil
	if lead and type(leadId) == "string" and (lead.State == "Down" or lead.State == "Home") then
		local whole = if lead.State == "Home" then lead.StateUntil else lead.StateUntil + FightService.HomeOf(player).Fallen
		if whole > now() then
			healing[leadId], any = whole, true
		end
	end
	for id, entry in carriedOf(player) do
		local whole = Carry.WholeAt(entry, FightService.HomeOf(player))
		if entry.Fallen and whole > now() then
			healing[id], any = whole, true
		end
	end
	local folder = player:FindFirstChild(HEALING)
	if folder == nil and any then
		folder = Instance.new("Folder")
		folder.Name = HEALING
		folder.Parent = player
	end
	if folder then
		for id in folder:GetAttributes() do
			if healing[id] == nil then
				folder:SetAttribute(id, nil)
			end
		end
		for id, whole in healing do
			setAttribute(folder, id, whole)
		end
	end
	setAttribute(player, "InCombat", FightService.InCombat(player))
	local who = trainee(player) or ""
	local was = training[player]
	if was ~= nil and (who ~= was or now() - (settled[player] or 0) >= GrowthConfig.Training.Every) then
		settle(player, who, "Training") -- nil until this service's Ready: the time away is BaseService's, with the lead
		training[player] = who
	end
	setAttribute(player, "Training", who)
end

-- Why `player` can't send out `id` as their lead now, or nil (Rules.Carry.Refusal). The one already out is no change.
function LeadService.Refusal(player: Player, id: any): string?
	if type(id) ~= "string" then
		return nil -- Collection's own answer
	end
	local current = FightService.LeadOf(player)
	if current and current.Model:GetAttribute("Voidkin") == id then
		return nil
	end
	-- In a fight, and frozen through a keeper's try or a Tower run (D10).
	return Carry.Refusal(FightService.InCombat(player) or FightService.Frozen(player), carriedOf(player)[id], now(), FightService.HomeOf(player))
end

local function sync(player: Player)
	local data = DataService.Get(player)
	if data == nil or player.Parent ~= Players then
		return
	end
	local current = FightService.LeadOf(player)
	local id = data.Roles.Lead
	local owned = if id ~= "" then data.Voidkin[id] else nil
	if owned == nil then
		if current then
			takeIn(player, current)
			FightService.Remove(current)
		end
		return
	end
	local block = Stats.Resolve(owned, Stats.PresetOf(data, owned), data)
	if current and current.Model:GetAttribute("Voidkin") == id then
		if not same(current.Block, block) then
			FightService.SetBlock(current, block)
		end
		return
	end
	if player.Character == nil then
		return -- CharacterAdded brings it
	end
	if current then
		takeIn(player, current)
	end
	local mine = carriedOf(player)
	local share = Carry.Share(mine[id], now(), FightService.HomeOf(player))
	mine[id] = nil
	local row = Voidkin.ById[owned.Def]
	local lead = FightService.SpawnLead(player, block, if row then row.Name else owned.Def, share)
	lead.Model:SetAttribute("Voidkin", id)
	tick(player)
end

function LeadService.Start()
	DataService.Ready:Connect(function(player: Player)
		-- BaseService's away advance has trained the lead for the time away (its Ready runs first, Priority 20): from
		-- here the machine is empty until Training.Who names someone, and the lead comes out at its level.
		DataService.Change(player, "TrainingReturn", function(draft: Profile.Data): { [string]: any }
			draft.Training.Trainee = ""
			return { Ok = true }
		end)
		training[player], settled[player] = "", now()
		sync(player)
	end)
	DataService.Changed:Connect(sync)
	Players.PlayerRemoving:Connect(function(player: Player)
		carried[player], training[player], settled[player] = nil, nil, nil
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in Players:GetPlayers() do
				task.spawn(tick, player)
			end
		end
	end)
	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function()
			task.defer(sync, player)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
		task.defer(sync, player)
	end
	if RunService:IsStudio() then
		-- Studio only: the lead at `level`, its experience at the level's start, or at `xp` (a test putting a save back).
		DebugService.Register("LeadLevel", function(who: any, level: any, xp: any): any
			local player = DebugService.ResolvePlayer(who)
			if not player or type(level) ~= "number" or level ~= math.floor(level) or level < 1 or level > GrowthConfig.MaxLevel then
				return { Ok = false, Error = "BadArgs" }
			end
			if xp ~= nil and (type(xp) ~= "number" or xp < 0) then
				return { Ok = false, Error = "BadArgs" }
			end
			return DataService.Change(player, "LeadLevel", function(draft: Profile.Data): { [string]: any }
				local owned = draft.Voidkin[draft.Roles.Lead]
				if owned == nil then
					return { Ok = false, Error = "NoLead" }
				end
				owned.Level, owned.Xp = level, if xp == nil then 0 else xp
				return { Ok = true, Level = level }
			end)
		end)
		-- Studio only: every Voidkin of the player whole at once, and a fallen lead up beside the avatar.
		DebugService.Register("LeadHeal", function(who: any): any
			local player = DebugService.ResolvePlayer(who)
			if not player then
				return { Ok = false, Error = "BadArgs" }
			end
			carried[player] = {}
			local lead = FightService.LeadOf(player)
			if lead then
				FightService.Recall(lead)
			end
			tick(player)
			return { Ok = true, State = if lead then lead.State else "" }
		end)
		-- Studio only: the lead out of any fight at once (FightService.Calm), for a case that starts after one.
		DebugService.Register("LeadCalm", function(who: any): any
			local player = DebugService.ResolvePlayer(who)
			if not player then
				return { Ok = false, Error = "BadArgs" }
			end
			FightService.Calm(player)
			return { Ok = true }
		end)
		-- Studio only: every Voidkin of the player but the lead fallen just now, healing at home, so none is ready to lead
		-- (TR16: a lead alone after its fall, on an account that owns several). LeadHeal makes them whole again.
		DebugService.Register("VoidkinFallen", function(who: any): any
			local player = DebugService.ResolvePlayer(who)
			local data = if player then DataService.Get(player) else nil
			if not player or data == nil then
				return { Ok = false, Error = "BadArgs" }
			end
			local mine = carriedOf(player)
			local count = 0
			for id in data.Voidkin do
				if id ~= data.Roles.Lead then
					mine[id] = { Share = 0, At = now(), Fallen = true }
					count += 1
				end
			end
			tick(player)
			return { Ok = true, Count = count }
		end)
		-- Studio only: the Training machine as if `seconds` passed away, the lead on it (Rules.Training).
		DebugService.Register("TrainingSkip", function(who: any, seconds: any): any
			local player = DebugService.ResolvePlayer(who)
			if not player or type(seconds) ~= "number" or not (seconds > 0) or seconds == math.huge then
				return { Ok = false, Error = "BadArgs" }
			end
			return DataService.Change(player, "TrainingSkip", function(draft: Profile.Data): { [string]: any }
				if draft.Base.Stamp == 0 then
					return { Ok = false, Error = "NoStamp" }
				end
				draft.Base.Stamp -= seconds
				local summary = Breaker.Advance(draft, now(), true) -- away: the lead on the machine, the plant as it runs
				return { Ok = true, Id = summary.Trained or "", Levels = summary.Levels }
			end)
		end)
		-- Studio only: `def` uncovered as a shard's would be (Collection.Uncover): new, or a copy of the one owned.
		DebugService.Register("VoidkinGive", function(who: any, def: any): any
			local player = DebugService.ResolvePlayer(who)
			if not player or type(def) ~= "string" then
				return { Ok = false, Error = "BadArgs" }
			end
			return DataService.Change(player, "VoidkinGive", function(draft: Profile.Data): { [string]: any }
				return Collection.Uncover(draft, def, workspace:GetServerTimeNow())
			end)
		end)
	end
end

return LeadService
