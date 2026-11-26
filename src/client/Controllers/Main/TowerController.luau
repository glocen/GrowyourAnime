--!strict
-- TowerController (client): the Tower's screen side (TR29; docs/design.md, "The Tower"): the run's results open once from
-- the save (UI.TowerScreen). The floor reads once, by the room's slab, never a line on the HUD over it (research's
-- must-fix on AR56): the room itself, its beat and the gates' records are TowerRoomController's (AR56). During a run, a
-- Leave under the pills asks first, "Leave the Tower?" (TR67, UI.TowerScreen.Ask), and a walk out of the room, set back
-- by the server, asks the same (Net "TowerEdge").
--   TowerController.Ask()     the question, as the Leave's press opens it (tests)
--   TowerController.Parts()   the Leave's button (tests)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local TowerConfig = require(Shared.Config.Tower)
local Profile = require(Shared.Data.Profile)
local Net = require(Shared.Net)

local UI = script.Parent.Parent.Parent.UI
local Screen = require(UI.Kit.Screen)
local Button = require(UI.Kit.Button)
local Layers = require(UI.Layers)
local Theme = require(UI.Theme)
local TowerScreen = require(UI.TowerScreen)
local ProfileController = require(script.Parent.Parent.Core.ProfileController)
local HudController = require(script.Parent.HudController)
local Cues = require(script.Parent.FighterController.Cues)

local TowerController = {}

local LEAVE_WIDE = 96 -- the Leave's button under the pills, in the HUD layer's authored pixels

local leaveButton: TextButton? = nil

-- The floors the run under way has won: the save's run, else the floor being fought less one.
local function won(): number
	local view = ProfileController.Get()
	local run = if view then view.Progress.Tower.Run else nil
	if run then
		return run.Floor
	end
	local floor = Players.LocalPlayer:GetAttribute("Tower")
	return if type(floor) == "number" then math.max(0, floor - 1) else 0
end

-- "Leave the Tower?" during a run, unless it's open already or another screen is: Leave ends the run (Net
-- "TowerLeave"), Stay closes it.
function TowerController.Ask(): boolean
	if Players.LocalPlayer:GetAttribute("Tower") == nil or Screen.Current() ~= nil then
		return false
	end
	TowerScreen.Ask(won(), function(): boolean
		local ok, answer = pcall(Net.Client.Invoke, "TowerLeave")
		return ok and type(answer) == "table" and answer.Ok == true
	end)
	return true
end

function TowerController.Parts(): { [string]: GuiObject }
	return { Leave = leaveButton :: any }
end

-- The Leave under the pills, shown only during a run.
local function makeLeave()
	local made = Button.new({
		Name = "TowerLeave",
		Text = "Leave",
		Size = UDim2.fromOffset(LEAVE_WIDE, Theme.Size.Tap),
		Position = HudController.UnderPills(),
		AnchorPoint = Vector2.new(1, 0),
		Parent = Layers.Get("Hud"),
		Quiet = true,
		OnPress = TowerController.Ask,
	})
	made.Visible = Players.LocalPlayer:GetAttribute("Tower") ~= nil
	HudController.Beneath(made) -- the plates in its column keep under it
	leaveButton = made
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
	if held.Record then
		Cues.Moment("Record") -- a new record (TR64), as its card opens
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

function TowerController.Start()
	-- The heal cap, told once per account the first time it binds (TR46; research's words, the share from Config).
	Net.Client.On("TowerHealCap", function(share: any)
		local percent = math.floor((if type(share) == "number" then share else TowerConfig.HealCap) * 100 + 0.5)
		HudController.Note(`Healing capped for this floor: {percent}% of your lead's health.`)
	end)
	makeLeave()
	Net.Client.On("TowerEdge", function()
		TowerController.Ask()
	end)
	Players.LocalPlayer:GetAttributeChangedSignal("Tower"):Connect(function()
		local running = Players.LocalPlayer:GetAttribute("Tower") ~= nil
		if leaveButton then
			leaveButton.Visible = running
		end
		if not running and Screen.Current() == TowerScreen.AskName then
			Screen.Close() -- the run ended another way while the question stood
		end
		results(ProfileController.Get())
	end)
	ProfileController.Changed:Connect(function(view: Profile.View)
		results(view)
	end)
	results(ProfileController.Get())
end

return TowerController
