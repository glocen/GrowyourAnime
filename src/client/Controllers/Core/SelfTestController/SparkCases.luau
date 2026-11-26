--!strict
-- SparkCases: a landed hit's star in play (AR61; Config.Effects.HitSparks; Rules.Track.Spark; Effects.HitSpark). In the
-- replay, the player's lead's hits on its dummy: each rung's star on the side struck, its Front the way the blow
-- travels, its rows drawn; the gold star only on a critical, a killing hit's lift keeping the rung under it; a
-- signature's rung keeping the old spark; none on a raised shield (AR52: the glance or the break is its own look). Apart
-- from Cases, whose size the type check can't take more of.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Combat = require(Shared.Config.Combat)
local EffectsConfig = require(Shared.Config.Effects)
local FightRule = require(Shared.Rules.Fight)
local Actions = require(Shared.Definitions.Actions)
local Main = script.Parent.Parent.Parent.Main
local FighterController = require(Main.FighterController)
local Effects = require(Main.FighterController.Effects)
local Helpers = require(script.Parent.Helpers)

local SparkCases = {}

local function myLead(): Model?
	local fighters = workspace:FindFirstChild("Fighters")
	for _, model in (if fighters then fighters:GetChildren() else {}) do
		if model:IsA("Model") and model:GetAttribute("Side") == "Lead" and model:GetAttribute("Owner") == Players.LocalPlayer.UserId then
			return model
		end
	end
	return nil
end

type Want = { Rung: number, Critical: boolean, Name: string }

function SparkCases.Cases(): { any }
	return {
		{
			Name = "Hit sparks (AR61): each rung's star on the side struck along the blow, the gold only on a critical, a signature's rung the old spark, none on a raised shield",
			Run = function(t: any)
				local lead = myLead()
				local view: any = if lead then FighterController.Views[lead] else nil
				t.Check("the lead is in the world, with a view", view ~= nil)
				if lead == nil or view == nil then
					return
				end
				local found: Actions.Action? = nil
				for _, each in Actions.KitOf(lead:GetAttribute("Def") :: string) do
					if each.Cooldown == 0 then
						found = each
					end
				end
				if found == nil then
					t.Check("the lead has an action with no cooldown", false)
					return
				end
				local action = found :: Actions.Action
				local ok, result = pcall(function()
					return t.Server("Replay", action.Id, action.Length + 5)
				end)
				t.Check("the replay starts", ok and type(result) == "table" and result.Ok == true, tostring(if ok then result and result.Error else result))
				local struck: any = nil
				Helpers.waitFor(t, 3, function(): boolean
					for model, each in FighterController.Views do
						if model:GetAttribute("Kind") == "Dummy" then
							struck = each
						end
					end
					return struck ~= nil
				end)
				t.Check("the replay's dummy is on screen", struck ~= nil)
				if struck then
					t.Wait(action.Length + 0.3) -- the replay's own hits over
					local blow = struck.Root.Position - view.Root.Position
					local way = Vector3.new(blow.X, 0, blow.Z).Unit
					local wants: { Want } = {
						{ Rung = 2, Critical = false, Name = "HitSpark2" },
						{ Rung = 3, Critical = false, Name = "HitSpark3" },
						{ Rung = 4, Critical = true, Name = "HitSpark4" },
						{ Rung = 4, Critical = false, Name = "HitSpark3" }, -- a killing hit's lift
					}
					for index, want in wants do
						t.Wait(Combat.Hitstop.Kill + 0.05)
						local before: any = Effects.LastSpark()
						FighterController.Show(view, struck, want.Rung, false, false, `SparkTest@{index}`, nil, want.Critical)
						local spark: any = Effects.LastSpark()
						local fresh = spark ~= nil and spark ~= before
						local said = `rung {want.Rung}{if want.Critical then ", a critical" else ""}`
						t.Equal(`{said}: its star`, if fresh then spark.Name else "none", want.Name)
						if fresh then
							local anchor: CFrame = spark.Anchor
							local stood = anchor.Position
							local toward = Vector3.new(stood.X - struck.Root.Position.X, 0, stood.Z - struck.Root.Position.Z)
							local along = anchor.LookVector:Dot(way)
							t.Check(`{said}: its front along the blow`, along > 0.99, string.format("%.3f", along))
							t.Check(`{said}: on the side struck`, toward.Magnitude > 0.1 and toward.Unit:Dot(-way) > 0.9, string.format("%.2f studs", toward.Magnitude))
							t.Check(`{said}: its rows drawn`, #spark.Rows.Parts("StarLine") > 0)
						end
					end
					t.Wait(Combat.Hitstop.Kill + 0.05)
					local last: any = Effects.LastSpark()
					FighterController.Show(view, struck, EffectsConfig.HitSparks.Below, true, false, "SparkTest@9", nil, true)
					t.Check("a signature's rung: no star, the old spark", Effects.LastSpark() == last)
					t.Wait(FightRule.Hold(EffectsConfig.HitSparks.Below, false, Combat.Hitstop) + 0.1)
					-- AR52: its shield raised (here only: the server never raises a dummy's), a critical's blow on it
					struck.Model:SetAttribute("GuardUntil", workspace:GetServerTimeNow() + 5)
					FighterController.Show(view, struck, 4, false, false, "SparkTest@10", nil, true)
					t.Check("a raised shield: no star, the glance or the break its own look", Effects.LastSpark() == last)
					struck.Model:SetAttribute("GuardUntil", nil)
					t.Wait(Combat.Hitstop.Kill + 0.05)
				end
				t.Server("Replay")
				t.Wait(0.3)
			end,
		},
	}
end

return SparkCases
