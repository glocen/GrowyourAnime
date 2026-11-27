--!strict
-- WelcomeService (server): the welcome week's claim and the codes (TR59; docs/design.md, "The welcome week and codes";
-- Rules.Welcome; Rules.Codes; Config.Welcome). Each is one transaction through DataService's actions, so a repeated or
-- retried request pays once. The day is the server's UTC day (Goals.DayOf), as for Today's three. A player's wrong code
-- tries are kept here, never saved: five a minute, then a minute's wait.
--   Act "WelcomeClaim" ()          today's gift: { Ok, Day, Gift } or refused Early, Done or Today
--   Act "CodeTake" { Code }        a typed code: { Ok, Code, Gives } or refused Unknown, Used, Ended or Wait
-- Studio only (NL_Debug): "Welcome" reads a player's week, codes and the day; "WelcomeSet" (taken, last, shown) sets
-- the week; "CodeList" (codes) stands a test list in for the server's, nil puts it back and clears the wrong tries.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config.Welcome)
local Profile = require(Shared.Data.Profile)
local Goals = require(Shared.Rules.Goals)
local Welcome = require(Shared.Rules.Welcome)
local Codes = require(Shared.Rules.Codes)
local Core = script.Parent.Parent.Core
local CodeList = require(script.Parent.Parent.Parent.Config.Codes) -- the codes: the server's own, never replicated
local DataService = require(Core.DataService)
local DebugService = require(Core.DebugService)

local WelcomeService = {
	Priority = 30, -- after DataService
}

local gates: { [Player]: Codes.Gate } = {}
local testList: { Config.Code }? = nil -- Studio only: a test list in the server list's place

local function registerDebug()
	DebugService.Register("Welcome", function(who: any): any
		local player = DebugService.ResolvePlayer(who)
		local data = if player then DataService.Get(player) else nil
		if not player or not data then
			return { Ok = false, Error = "NoPlayer" }
		end
		local day = Goals.DayOf(os.time())
		return { Ok = true, Day = day, Shown = Welcome.Shown(data), Row = Welcome.Row(data, day), Welcome = data.Welcome, Codes = data.Codes }
	end)
	DebugService.Register("WelcomeSet", function(who: any, taken: any, last: any, shown: any): any
		local player = DebugService.ResolvePlayer(who)
		if not player or (taken ~= nil and type(taken) ~= "number") or (last ~= nil and type(last) ~= "number") then
			return { Ok = false, Error = "BadArgs" }
		end
		return DataService.Change(player, "WelcomeSet", function(draft: Profile.Data): { [string]: any }
			draft.Welcome = if taken then { Taken = taken, Last = last or 0 } else nil
			if shown ~= nil then
				draft.Funnel[Config.ShowsAfter] = if shown then true else nil
			end
			return { Ok = true }
		end)
	end)
	DebugService.Register("CodeList", function(who: any, list: any): any
		if list ~= nil and type(list) ~= "table" then
			return { Ok = false, Error = "BadArgs" }
		end
		testList = list
		local player = DebugService.ResolvePlayer(who)
		if player == nil then
			return { Ok = true }
		end
		gates[player] = nil
		return DataService.Change(player, "CodeList", function(draft: Profile.Data): { [string]: any }
			draft.Codes = nil -- the test's codes untaken again
			return { Ok = true }
		end)
	end)
end

function WelcomeService.Init()
	if RunService:IsStudio() then
		registerDebug()
	end
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
		return Codes.Redeem(draft, typed, os.time(), testList or CodeList.List, gate :: Codes.Gate)
	end)
end

function WelcomeService.Start()
	Players.PlayerRemoving:Connect(function(player: Player)
		gates[player] = nil
	end)
end

return WelcomeService
