--!strict
-- The Play panel's cases (the director, 2026-11-24; UI.ModeScreen, ModeController, Rules.Modes): the dock's Play opens
-- it and closes it; a card a mode, inside the panel, each with its name, its line, where the player stands and its
-- press; the Festival's press begins the run Rules.Modes names, through the begin it's handed; "Choose Arc" opens the
-- Arc panel; the Tower's press leaves the world's marker on the player's own ring, at home, and says why it can't
-- anywhere else. No case here asks the server for a run.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local HudConfig = require(Shared.Config.Hud)
local WorldConfig = require(Shared.Config.World)
local Markers = require(Shared.World.Markers)
local Modes = require(Shared.Rules.Modes)
local Profile = require(Shared.Data.Profile)
local ProfileController = require(script.Parent.Parent.ProfileController)
local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local ModeController = require(script.Parent.Parent.Parent.Main.ModeController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Screen = require(UI.Kit.Screen)
local Button = require(UI.Kit.Button)
local Guide = require(UI.Guide)
local ModeScreen = require(UI.ModeScreen)
local StageScreen = require(UI.StageScreen)
local Theme = require(UI.Theme)

local ModeCases = {}

local function view(): Profile.View
	return ProfileController.Get() :: Profile.View
end

local function waitFor(t: any, seconds: number, ok: () -> boolean): boolean
	local began = os.clock()
	while os.clock() - began < seconds do
		if ok() then
			return true
		end
		t.Wait(0.1)
	end
	return ok()
end

local function part(name: string): GuiObject?
	local found = ModeScreen.Parts()[name]
	return if found and found:IsA("GuiObject") and found.Parent ~= nil then found else nil
end

function ModeCases.Cases(): { any }
	return {
		{
			Name = "Play panel: the dock's Play opens it, a card a mode inside the panel, and a second tap closes it",
			Run = function(t: any)
				if not HudConfig.Modes.On then
					t.Check("the panel is switched off (Config.Hud.Modes.On): Play opens the Arc panel", true)
					return
				end
				Screen.Close()
				t.Wait(0.3)
				local map = HudController.Parts().Map :: TextButton
				t.Check("a tap on Play opens the Play panel", Button.Press(map) and waitFor(t, 1, function(): boolean
					return Screen.Current() == ModeScreen.Name
				end), tostring(Screen.Current()))
				local cards = ModeController.Cards() :: { Modes.Card }
				t.Equal("two modes", #cards, 2)
				local body = part("Body") :: Frame
				local panel = body.Parent :: Frame
				local pad = Theme.Size.Pad
				local wide = panel.Size.X.Offset - pad * 4
				local room = panel.Size.Y.Offset - Screen.Head - pad
				local right = 0
				for _, card in cards do
					local holder = part(card.Id)
					t.Check(`{card.Id}: its card stands`, holder ~= nil)
					if holder == nil then
						continue
					end
					local x, w, h = holder.Position.X.Offset, holder.Size.X.Offset, holder.Size.Y.Offset
					t.Check(`{card.Id}: inside the panel`, x >= right - 0.5 and x + w <= wide + 0.5 and h <= room + 0.5, `{x} + {w} of {wide}, {h} of {room}`)
					right = x + w
					for _, name in { "Title", "Line", "Says" } do
						local label = part(card.Id .. name) :: TextLabel?
						t.Check(`{card.Id}: its {name} reads`, label ~= nil and label.Text == (card :: any)[name], if label then label.Text else "none")
					end
					local press = part(`{card.Id}Press`) :: TextButton?
					t.Check(`{card.Id}: a press a touch high, on the card`, press ~= nil and press.Size.Y.Offset >= Theme.Size.Tap and press.Position.Y.Offset + press.Size.Y.Offset <= h + 0.5)
					t.Check(`{card.Id}: a second press only where the mode has one`, (part(`{card.Id}Second`) ~= nil) == (card.Second ~= nil))
					if press and card.Off then
						t.Check(`{card.Id}: shut, its press takes no tap ("{card.Off}")`, Button.Press(press) == false and Screen.Current() == ModeScreen.Name)
					end
				end
				t.Check("a second tap on Play closes it", Button.Press(map) and Screen.Current() ~= ModeScreen.Name, tostring(Screen.Current()))
			end,
		},
		{
			Name = "Play panel: the Festival's press begins the run the rules name, Choose Arc opens the Arc panel, the Tower's press asks for its ring",
			Run = function(t: any)
				Screen.Close()
				t.Wait(0.3)
				local cards = Modes.Cards(view(), WorldConfig.Row.Ground, true)
				cards[2].Off = nil -- the Tower's press as at home with no climb under way, whatever this place and save are
				local began: { string } = {}
				local arcs, rings = 0, 0
				ModeScreen.Open(cards, {
					Begin = function(ground: string, difficulty: string): boolean
						table.insert(began, `{ground} {difficulty}`)
						return true
					end,
					Arc = function()
						arcs += 1
					end,
					Ring = function(): boolean
						rings += 1
						return true
					end,
				})
				local which = Modes.Frontier(view(), WorldConfig.Row.Ground)
				local festival = part("FestivalPress") :: TextButton
				if cards[1].Off == nil then
					Button.Press(festival)
					t.Check("the Festival's press: one run, the rules' ground and difficulty", #began == 1 and began[1] == `{WorldConfig.Row.Ground} {which}`, table.concat(began, ", "))
				end
				Button.Press(part("TowerPress") :: TextButton)
				t.Check("the Tower's press asks for the ring, once, and begins no run", rings == 1 and #began <= 1)
				Button.Press(part("FestivalSecond") :: TextButton)
				t.Equal("Choose Arc asks for the Arc panel, once", arcs, 1)
				Screen.Close()
				t.Wait(0.3)
				-- The real panel's Choose Arc: the Arc panel stands in its place.
				if HudConfig.Modes.On then
					ModeController.Open()
					local second = part("FestivalSecond") :: TextButton?
					t.Check("the real panel's Choose Arc opens the Arc panel", second ~= nil and Button.Press(second) ~= false and waitFor(t, 1, function(): boolean
						return Screen.Current() == StageScreen.Name
					end), tostring(Screen.Current()))
					Screen.Close()
					t.Wait(0.3)
				end
			end,
		},
		{
			Name = "Play panel: Go to the Tower closes the panel and leaves the world's marker on the player's own ring",
			Place = "Main", -- the Tower stands in that place only
			Run = function(t: any)
				if not HudConfig.Modes.On then
					return
				end
				Screen.Close()
				t.Wait(0.3)
				local cards = ModeController.Cards() :: { Modes.Card }
				if cards[2].Off ~= nil then
					t.Check(`the Tower's card is shut here ("{cards[2].Off}"): nothing to point at`, true)
					return
				end
				local plot = Players.LocalPlayer:GetAttribute("Plot")
				local ring = if type(plot) == "number" then Markers.Find("TowerRing", { Plot = plot }) else nil
				t.Check("the player's own ring stands", ring ~= nil)
				ModeController.Open()
				local press = part("TowerPress") :: TextButton?
				t.Check("its press takes the tap and the panel closes", press ~= nil and Button.Press(press) ~= false and waitFor(t, 1, function(): boolean
					return Screen.Current() == nil
				end), tostring(Screen.Current()))
				local read = Guide.Read()
				t.Check("the marker is on an errand, at one target", read.Errand and read.Count == 1, `errand {read.Errand}, {read.Count} targets`)
				Guide.Errand(nil)
				t.Check("the errand over, the marker is the next step's again", not Guide.Read().Errand)
			end,
		},
	}
end

return ModeCases
