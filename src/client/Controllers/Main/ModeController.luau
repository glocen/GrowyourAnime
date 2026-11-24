--!strict
-- ModeController (client): the dock's Play (the director, 2026-11-24: "i asked for the play button to open a panel of
-- gamemode"; docs/research/cloud-2026-11-24/play-mode-panel.md). Play opens the Play panel (UI.ModeScreen), a card a
-- mode as Rules.Modes says for this player's save: the Festival's press begins the run the player would go to next,
-- through the Arc panel's own begin (StageController), and "Choose Arc" opens the Arc panel; the Tower's press closes
-- the panel and points the world's marker at the player's own ring (UI.Guide's errand), where a climb begins as it
-- always has. Pressed again while the panel or the Arc panel is open, Play closes it. The panel is built again when the save changes under it.
-- Config.Hud.Modes.On = false gives Play the Arc panel directly, as before.
--   ModeController.Open()                  what the dock's Play does
--   ModeController.Cards() -> { Card }?    the cards as they'd show now, for tests; nil before the save arrives

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local HudConfig = require(Shared.Config.Hud)
local WorldConfig = require(Shared.Config.World)
local Markers = require(Shared.World.Markers)
local Modes = require(Shared.Rules.Modes)
local Profile = require(Shared.Data.Profile)
local PlaceRole = require(Shared.Util.PlaceRole)

local UI = script.Parent.Parent.Parent.UI
local Guide = require(UI.Guide)
local Screen = require(UI.Kit.Screen)
local Toast = require(UI.Kit.Toast)
local ModeScreen = require(UI.ModeScreen)
local StageScreen = require(UI.StageScreen)
local ProfileController = require(script.Parent.Parent.Core.ProfileController)
local HudController = require(script.Parent.HudController)
local StageController = require(script.Parent.StageController)

local ModeController = {}

local player = Players.LocalPlayer
local LOOK = HudConfig.Modes

local function cards(view: Profile.View): { Modes.Card }
	return Modes.Cards(view, WorldConfig.Row.Ground, PlaceRole.Is("Main"))
end

local on: ModeScreen.On = {
	Begin = StageController.Begin,
	Arc = function()
		StageController.Pick()
	end,
	Ring = function(): boolean
		local plot = player:GetAttribute("Plot")
		local ring = if type(plot) == "number" then Markers.Find("TowerRing", { Plot = plot }) else nil
		if ring == nil then
			Toast.Show("The Tower isn't in reach here")
			return false
		end
		Screen.Close()
		Guide.Errand({ ring }, LOOK.Errand)
		return true
	end,
}

function ModeController.Cards(): { Modes.Card }?
	local view = ProfileController.Get()
	return if view then cards(view) else nil
end

function ModeController.Open()
	local view = ProfileController.Get()
	if view == nil then
		return
	end
	-- Play's own screens close on its second tap, as every dock tile's do: the panel, and the Arc panel its Choose Arc opens
	if Screen.Current() == ModeScreen.Name or Screen.Current() == StageScreen.Name then
		Screen.Close()
		return
	end
	ModeScreen.Open(cards(view), on)
end

function ModeController.Start()
	HudController.OpenPlay = if LOOK.On then ModeController.Open else StageController.Pick
	ProfileController.Changed:Connect(function(view: Profile.View)
		if Screen.Current() == ModeScreen.Name then
			ModeScreen.Open(cards(view), on)
		end
	end)
end

return ModeController
