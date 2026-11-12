--!strict
-- LeadService (server): the player's lead in the world, the Voidkin in Roles.Lead (Shared.Data.Profile), as a fighter
-- beside the avatar (FightService). It follows the save: a new lead replaces the old one, and a level gained gives it its
-- new stat block, its health kept as a share. Studio adds LeadLevel, to try a fight at a level without playing up to it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Profile = require(Shared.Data.Profile)
local Voidkin = require(Shared.Definitions.Voidkin)
local GrowthConfig = require(Shared.Config.Growth)
local Stats = require(Shared.Rules.Stats)
local Core = script.Parent.Parent.Core
local DataService = require(Core.DataService)
local DebugService = require(Core.DebugService)
local FightService = require(script.Parent.FightService)

local LeadService = {
	Priority = 40, -- after FightService
}

local function same(a: Stats.Block, b: Stats.Block): boolean
	for _, stat in Stats.Names do
		if (a :: any)[stat] ~= (b :: any)[stat] then
			return false
		end
	end
	return a.Level == b.Level
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
	local row = Voidkin.ById[owned.Def]
	local lead = FightService.SpawnLead(player, block, if row then row.Name else owned.Def)
	lead.Model:SetAttribute("Voidkin", id)
end

function LeadService.Start()
	DataService.Ready:Connect(sync)
	DataService.Changed:Connect(sync)
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
		-- Studio only: the lead at `level`, its experience at the level's start.
		DebugService.Register("LeadLevel", function(who: any, level: any): any
			local player = DebugService.ResolvePlayer(who)
			if not player or type(level) ~= "number" or level ~= math.floor(level) or level < 1 or level > GrowthConfig.MaxLevel then
				return { Ok = false, Error = "BadArgs" }
			end
			return DataService.Change(player, "LeadLevel", function(draft: Profile.Data): { [string]: any }
				local owned = draft.Voidkin[draft.Roles.Lead]
				if owned == nil then
					return { Ok = false, Error = "NoLead" }
				end
				owned.Level, owned.Xp = level, 0
				return { Ok = true, Level = level }
			end)
		end)
	end
end

return LeadService
