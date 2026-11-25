--!strict
-- WelcomeService (server): the welcome week's claim and the codes (TR59; docs/design.md, "The welcome week and codes";
-- Rules.Welcome; Rules.Codes; Config.Welcome). Each is one transaction through DataService's actions, so a repeated or
-- retried request pays once. The day is the server's UTC day (Goals.DayOf), as for Today's three. A player's wrong code
-- tries are kept here, never saved: five a minute, then a minute's wait.
--   Act "WelcomeClaim" ()          today's gift: { Ok, Day, Gift } or refused Early, Done or Today
--   Act "CodeTake" { Code }        a typed code: { Ok, Code, Gives } or refused Unknown, Used, Ended or Wait

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config.Welcome)
local Profile = require(Shared.Data.Profile)
local Goals = require(Shared.Rules.Goals)
local Welcome = require(Shared.Rules.Welcome)
local Codes = require(Shared.Rules.Codes)
local Core = script.Parent.Parent.Core
local DataService = require(Core.DataService)

local WelcomeService = {
	Priority = 30, -- after DataService
}

local gates: { [Player]: Codes.Gate } = {}

function WelcomeService.Init()
	DataService.Action("WelcomeClaim", function(draft: Profile.Data): { [string]: any }
		return Welcome.Claim(draft, Goals.DayOf(os.time()))
	end)
	DataService.Action("CodeTake", function(draft: Profile.Data, args: any, player: Player): { [string]: any }
		local gate = gates[player]
		if gate == nil then
			gate = Codes.Gate()
			gates[player] = gate
		end
		local typed = if type(args) == "table" then args.Code else nil
		return Codes.Redeem(draft, typed, os.time(), Config.Codes.List, gate :: Codes.Gate)
	end)
end

function WelcomeService.Start()
	Players.PlayerRemoving:Connect(function(player: Player)
		gates[player] = nil
	end)
end

return WelcomeService
