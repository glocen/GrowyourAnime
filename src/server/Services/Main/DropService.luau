--!strict
-- DropService (server): an enemy's fall pays each player whose lead hit it, in one step on their own save (Rules.Drops;
-- docs/design.md, "The world, in grey": the drop in full to every hitter). The roll is the server's, one per player. An
-- enemy spawned without a ground (the replay's dummy, a Studio spawn) drops nothing. A fall happens once per fighter
-- (FightService), so each drop is written once. Studio adds Drops: the asking player's kill count, purse and bag.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Profile = require(Shared.Data.Profile)
local DropsConfig = require(Shared.Config.Drops)
local Shards = require(Shared.Definitions.Shards)
local Drops = require(Shared.Rules.Drops)
local Log = require(Shared.Util.Log)
local Core = script.Parent.Parent.Core
local DataService = require(Core.DataService)
local DebugService = require(Core.DebugService)
local FightService = require(script.Parent.FightService)

local DropService = {
	Priority = 50, -- after the fight and the services that spawn enemies
}

local rng = Random.new()

local function give(player: Player, f: FightService.Fighter)
	local roll, chestRoll = rng:NextNumber(), rng:NextNumber()
	local loot: Drops.Loot = {
		Stone = rng:NextNumber(),
		Emblem = rng:NextNumber(),
		Rarity = rng:NextNumber(),
		Set = rng:NextNumber(),
		Stat = rng:NextNumber(),
	}
	local answer = DataService.Change(player, "Drop", function(draft: Profile.Data): { [string]: any }
		return Drops.Give(draft, f.Kind, f.Block.Level, f.Ground, roll, chestRoll, loot)
	end)
	if answer.Ok ~= true and answer.Error ~= DataService.NoProfile then
		Log.Warn("DropService", `{f.Def} at level {f.Block.Level} in {tostring(f.Ground)} paid {player.Name} nothing: {tostring(answer.Error)}`)
	end
end

-- Studio: what the drops have written so far for `who`.
local function state(who: any): any
	local player = DebugService.ResolvePlayer(who)
	local data = if player then DataService.Get(player) else nil
	if data == nil then
		return { Ok = false, Error = DataService.NoProfile }
	end
	local lead = data.Voidkin[data.Roles.Lead]
	local standard = ""
	for _, row in Shards.List do
		standard = if row.Grade == "Standard" and row.Ground == "lanternrow" then row.Id else standard
	end
	return {
		Ok = true,
		Kills = data.Progress.Kills,
		Credits = data.Currency.Credits,
		Named = data.Bag.Shards[DropsConfig.First] or 0,
		Standard = data.Bag.Shards[standard] or 0,
		Level = if lead then lead.Level else 0,
		Xp = if lead then lead.Xp else 0,
	}
end

function DropService.Start()
	FightService.Fell:Connect(function(f: FightService.Fighter, hitters: { Player })
		if f.Side ~= "Shade" or f.Ground == nil then
			return
		end
		for _, player in hitters do
			give(player, f)
		end
	end)
	if RunService:IsStudio() then
		DebugService.Register("Drops", state)
	end
end

return DropService
