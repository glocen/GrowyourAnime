--!strict
-- RandomPolicyService (server): whether paid random items are restricted for a player, from Roblox's PolicyService
-- (ArePaidRandomItemsRestricted: Australia, Belgium, the Netherlands, the UK and Brazil when read on 2026-11-24;
-- https://create.roblox.com/docs/production/monetization/paid-random-items). Rules.Wallet uses it: there, only earned
-- Credits pay for a random outcome (the director, 2026-11-24: "we will sell credit so make sure it in accord to roblox
-- rule"). Read once a player joins and kept while they stay. Until a read answers, or when it fails, the player counts as
-- restricted (it fails closed), and a failed read is tried again after a while. The answer is also the player's
-- RandomRestricted attribute, so a screen can say why a bought Credit can't pay.
--   RandomPolicyService.Restricted(player) -> boolean   no yield

local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Log = require(ReplicatedStorage.Shared.Util.Log)

local RandomPolicyService = {}

local RETRY = 60 -- seconds before a failed read is tried again
local TRIES = 5 -- reads a player gets before they stay restricted for the session

local known: { [Player]: boolean } = {}
local reading: { [Player]: boolean } = {}

local function read(player: Player)
	if reading[player] then
		return
	end
	reading[player] = true
	task.spawn(function()
		for try = 1, TRIES do
			local ok, info = pcall(PolicyService.GetPolicyInfoForPlayerAsync, PolicyService, player)
			if player.Parent ~= Players then
				break
			end
			if ok and type(info) == "table" and type(info.ArePaidRandomItemsRestricted) == "boolean" then
				known[player] = info.ArePaidRandomItemsRestricted
				player:SetAttribute("RandomRestricted", info.ArePaidRandomItemsRestricted)
				break
			end
			Log.Warn("RandomPolicy", `{player.UserId}: the policy read failed ({try}/{TRIES}), restricted until it answers`)
			task.wait(RETRY)
		end
		reading[player] = nil
	end)
end

function RandomPolicyService.Restricted(player: Player): boolean
	local answer = known[player]
	if answer == nil then
		read(player)
		return true
	end
	return answer
end

function RandomPolicyService.Init()
	Players.PlayerAdded:Connect(function(player: Player)
		player:SetAttribute("RandomRestricted", true)
		read(player)
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		known[player] = nil
		reading[player] = nil
	end)
end

function RandomPolicyService.Start()
	for _, player in Players:GetPlayers() do
		if known[player] == nil then
			player:SetAttribute("RandomRestricted", true)
			read(player)
		end
	end
end

return RandomPolicyService
