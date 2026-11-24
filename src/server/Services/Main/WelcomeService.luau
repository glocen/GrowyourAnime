--!strict
-- WelcomeService (server): what's given, never sold (Rules.Welcome; docs/research/cloud-2026-11-24/launch-design.md,
-- section 8, on the director's "ok" of 2026-11-24). The welcome week's gift comes on a player's first moment of each day
-- played: at join, at the starter's choice on the first day, and at the UTC day's turn while they stay. Each gift is one
-- change, and the rule refuses a second on one day, so a repeat gives nothing. Its answer goes to the client by the "Gift"
-- remote, for its toast. A code comes through the action "RedeemCode" { Code }, typed in Home's settings once that
-- card is built (the PC; AR49).

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config.Welcome)
local Profile = require(Shared.Data.Profile)
local Net = require(Shared.Net)
local Goals = require(Shared.Rules.Goals)
local Welcome = require(Shared.Rules.Welcome)

local DataService = require(script.Parent.Parent.Core.DataService)

local WelcomeService = {
	Priority = 20, -- after DataService
}

local DAY_CHECK = 60 -- seconds between looks for the day's turn
local looked: { [Player]: number } = {} -- the UTC day each player was last given to, or found nothing due

local function give(player: Player)
	local today = Goals.DayOf(os.time())
	looked[player] = today
	local answer = DataService.Change(player, "WelcomeGift", function(draft: Profile.Data): { [string]: any }
		return Welcome.Gift(draft, today)
	end)
	if answer.Ok == true then
		Net.Server.Fire("Gift", player, answer)
	end
end

function WelcomeService.Init()
	DataService.Action("RedeemCode", function(draft: Profile.Data, args: any): { [string]: any }
		return Welcome.Redeem(draft, if type(args) == "table" then args.Code else nil, os.time(), Config.Codes)
	end)
end

function WelcomeService.Start()
	DataService.Ready:Connect(function(player: Player)
		give(player)
	end)
	DataService.Changed:Connect(function(player: Player, _data: any, answer: any, label: string?)
		if label == "ChooseStarter" and type(answer) == "table" and answer.Ok == true then
			give(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		looked[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(DAY_CHECK)
			local today = Goals.DayOf(os.time())
			for player, day in looked do
				if day ~= today and player.Parent == Players then
					give(player)
				end
			end
		end
	end)
end

return WelcomeService
