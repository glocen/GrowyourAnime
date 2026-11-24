--!strict
-- TowerController (client): the Tower's screen side (TR29; docs/design.md, "The Tower"). The own player's floor reads at
-- the top of the screen while their "Tower" attribute holds (TowerService), and the run's results open once from the
-- save (UI.TowerScreen). The room itself, its beat and the gates' records: TowerRoomController (AR56).
--   TowerController.Label() -> TextLabel?                                  the floor's line, for tests

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local TowerConfig = require(Shared.Config.Tower)
local Profile = require(Shared.Data.Profile)
local Net = require(Shared.Net)

local UI = script.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Layers = require(UI.Layers)
local Text = require(UI.Kit.Text)
local Screen = require(UI.Kit.Screen)
local TowerScreen = require(UI.TowerScreen)
local ProfileController = require(script.Parent.Parent.Core.ProfileController)
local HudController = require(script.Parent.HudController)

local TowerController = {}

local label: TextLabel? = nil

local function showLabel()
	local floor = Players.LocalPlayer:GetAttribute("Tower")
	if type(floor) ~= "number" then
		if label then
			label.Visible = false
		end
		return
	end
	if label == nil or label.Parent == nil then
		local made = Text.new({
			Name = "TowerFloor",
			Size = Theme.Text.Big,
			Font = Theme.Font.Number,
			Align = Enum.TextXAlignment.Center,
			Box = UDim2.fromOffset(240, 34),
			Position = UDim2.new(0.5, 0, 0, HudController.FoeFoot() + Theme.Size.Gap), -- under the foe's card, never over its health
			AnchorPoint = Vector2.new(0.5, 0),
			Parent = Layers.Get("Hud"),
		})
		made.TextStrokeTransparency = 0.4
		label = made
	end
	local view = ProfileController.Get()
	local best = if view then view.Progress.Tower.Best else 0
	local l = label :: TextLabel
	l.Text = if best > 0 then `Floor {floor}   ·   best {best}` else `Floor {floor}`
	l.Visible = true
end

-- The results the save holds, opened once they're the client's to see: out of a run, never twice. Results on screen the
-- save no longer holds close: a run started over them dropped them (Rules.Tower.Start), and its own open at its end.
local function results(view: Profile.View?)
	local held = if view then view.Progress.Tower.Results else nil
	local open = Screen.Current() == TowerScreen.Name
	if open and (held == nil or TowerScreen.Shown() ~= held.Id) then
		Screen.Close()
		open = false
	end
	if held == nil or Players.LocalPlayer:GetAttribute("Tower") ~= nil or TowerScreen.Told(held.Id) or open then
		return
	end
	TowerScreen.Open(held, {
		Act = ProfileController.Act,
		Retry = function(): { [string]: any }
			return Net.Client.Invoke("TowerRetry")
		end,
		Home = function(): { [string]: any }
			return Net.Client.Invoke("TowerHome")
		end,
		Board = function(): { [string]: any }
			return Net.Client.Invoke("TowerBoard")
		end,
	})
end

function TowerController.Label(): TextLabel?
	return label
end

function TowerController.Start()
	-- The heal cap, told once per account the first time it binds (TR46; research's words, the share from Config).
	Net.Client.On("TowerHealCap", function(share: any)
		local percent = math.floor((if type(share) == "number" then share else TowerConfig.HealCap) * 100 + 0.5)
		HudController.Note(`Healing capped for this floor: {percent}% of your lead's health.`)
	end)
	Players.LocalPlayer:GetAttributeChangedSignal("Tower"):Connect(function()
		showLabel()
		results(ProfileController.Get())
	end)
	ProfileController.Changed:Connect(function(view: Profile.View)
		results(view)
		showLabel()
	end)
	results(ProfileController.Get())
end

return TowerController
