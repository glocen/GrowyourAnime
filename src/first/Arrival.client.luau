--!strict
-- Arrival (ReplicatedFirst): a player who came by a trip between the base and the Festival of Battles keeps the trip's
-- card up from the first frame, before the place has drawn anything (TR45; docs/research/game-mode-places.md, "the
-- arrival GUI comes from ReplicatedFirst"). It takes Roblox's copy of the card, puts it in PlayerGui as TravelArrival,
-- and drops Roblox's own loading screen. TravelController lifts it when the server says the stage stands. LAST is only
-- the last resort if the game never boots: TravelController's Config.Travel.Hold comes first.

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TeleportService = game:GetService("TeleportService")

local LAST = 60

local gui = TeleportService:GetArrivingTeleportGui()
if gui then
	gui.Name = "TravelArrival"
	gui.ResetOnSpawn = false
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	ReplicatedFirst:RemoveDefaultLoadingScreen()
	task.delay(LAST, function()
		if gui.Parent then
			gui:Destroy()
		end
	end)
end
