--!strict
-- WelcomeCases: the welcome week and the codes in play (TR59; UI.TodayList; UI.SettingsScreen; Rules.Welcome;
-- Rules.Codes). The row heads Today's list from the first session's script's end: today's tile lit and taken with one
-- tap, once a day, later ones dim, the card's rim gold while it waits. The codes behind Settings' band press: a code
-- taken once, wrong, and the answer's words. The save's week, codes, goals and chests are put back at the end.

local Shared = game:GetService("ReplicatedStorage").Shared
local HudConfig = require(Shared.Config.Hud)
local UIKit = require(Shared.Config.UIKit)
local WelcomeConfig = require(Shared.Config.Welcome)
local Codes = require(Shared.Rules.Codes)
local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local ProfileController = require(script.Parent.Parent.ProfileController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Button = require(UI.Kit.Button)
local Screen = require(UI.Kit.Screen)
local HomePanel = require(UI.HomePanel)
local TodayList = require(UI.TodayList)
local ReturnCard = require(UI.ReturnCard)
local SettingsScreen = require(UI.SettingsScreen)
local Helpers = require(script.Parent.Helpers)

local WelcomeCases = {}

local waitFor = Helpers.waitFor
local REPLICATE = 3

local function held(t: any, chest: string): number
	return ((t.Server("Data") :: any).Bag.Chests[chest] or 0) :: number
end

local function states(said: any): string
	local out = {}
	for _, tile in said.Week do
		table.insert(out, tile.State)
	end
	return table.concat(out, " ")
end

function WelcomeCases.Cases(): { any }
	return {
		{
			Name = "Welcome week (TR59): the row heads Today's list after the first session's script; today's tile lit and taken with one tap, once; later dim; the rim gold while it waits",
			Run = function(t: any)
				Screen.Close()
				local home = HudConfig.Home
				local was = t.Server("Welcome") :: any
				local goals = t.Server("Goals") :: any
				local crates = held(t, "crate")
				local function restore()
					local w = was.Welcome
					t.Server("WelcomeSet", if w then w.Taken else nil, if w then w.Last else nil, was.Shown)
					t.Server("GoalsSet", goals.Days)
					local gained = held(t, "crate") - crates
					if gained ~= 0 then
						t.Server("ChestGive", "crate", -gained)
					end
					TodayList.Hide(HudController.Home(), true)
				end
				-- today's three open, so only the gift can light the rim
				t.Server("GoalsSet", { { Day = goals.Today, Picks = { "KeepDare", "ThreeShards", "LevelUp" }, Have = { 0, 0, 0 }, Claimed = { false, false, false } } })
				-- before the first session's script ends: no row
				t.Check("the week set unseen", (t.Server("WelcomeSet", nil, nil, false) :: any).Ok == true)
				t.Check("its copy reached the client", waitFor(t, REPLICATE, function(): boolean
					local view = ProfileController.Get() :: any
					return view ~= nil and view.Welcome == nil and view.Funnel[WelcomeConfig.ShowsAfter] ~= true
				end))
				local panel = HudController.Home()
				if not HomePanel.Shown(panel) then
					Button.Press(HudController.Parts().Home :: TextButton)
				end
				t.Wait(home.Open.Grow + 0.2)
				t.Check("the card's rim stays dark", (TodayList.Said(panel) :: any).Waits == false)
				t.Check("the list opens", Button.Press(panel.Cards.Today.Button) and waitFor(t, home.Step.Lit + 0.5, function(): boolean
					return TodayList.Shown(panel)
				end))
				t.Wait(home.Today.Switch + 0.1)
				t.Equal("no row before the script's end", #(TodayList.Said(panel) :: any).Week, 0)
				-- the return card hides under the open list, and comes back as it closes (research's must-fix on TR59)
				local keptCard = (ProfileController.Get() :: any).Base.Card
				t.Server("ReturnCardSet", { Kwh = 3 })
				t.Check("a return card meanwhile, hidden while the list is open", waitFor(t, REPLICATE, function(): boolean
					local card = ReturnCard.Parts().Card
					return ReturnCard.Up() and card ~= nil and not card.Visible
				end))
				TodayList.Hide(panel, true)
				t.Check("and back as the list closes", waitFor(t, 0.5, function(): boolean
					local card = ReturnCard.Parts().Card
					return card ~= nil and card.Visible
				end))
				t.Server("ReturnCardSet", keptCard)
				-- the script over: the row, today's lit
				t.Check("the week set shown", (t.Server("WelcomeSet", nil, nil, true) :: any).Ok == true)
				t.Check("its copy reached the client", waitFor(t, REPLICATE, function(): boolean
					local view = ProfileController.Get() :: any
					return view ~= nil and view.Funnel[WelcomeConfig.ShowsAfter] == true
				end))
				t.Check("the card's rim gold while the gift waits", waitFor(t, 1, function(): boolean
					return (TodayList.Said(panel) :: any).Waits == true
				end))
				t.Check("the list opens", Button.Press(panel.Cards.Today.Button) and waitFor(t, home.Step.Lit + 0.5, function(): boolean
					return TodayList.Shown(panel)
				end))
				t.Wait(home.Today.Switch + 0.1)
				local said = TodayList.Said(panel) :: any
				t.Equal("seven tiles: today's lit, the rest later", states(said), "Today Later Later Later Later Later Later")
				local list = panel.Frame:FindFirstChild("TodayList", true)
				local scroll = if list then list:FindFirstChildWhichIsA("ScrollingFrame", true) else nil
				local fits = scroll ~= nil
				for index = 1, 7 do
					local tile = if scroll then scroll:FindFirstChild(`Week{index}`) else nil
					local day = if tile then tile:FindFirstChild("Day") :: TextLabel? else nil
					fits = fits and day ~= nil and day.TextFits and tile ~= nil and (tile :: Frame).AbsoluteSize.X >= 40
				end
				t.Check("each tile at least 40 points wide, its day's words whole", fits)
				local seventh = if scroll then scroll:FindFirstChild("Week7") else nil
				t.Check("day 7 shows Lyric's face from day 1", seventh ~= nil and seventh:FindFirstChild(WelcomeConfig.Week[7].Shard == "named_lyric" and HudConfig.Home.Today.Week.Picture.Face or "") ~= nil)
				local button = said.Week[1] and said.Week[1].Button
				t.Check("today's tile is a press", button ~= nil)
				t.Check("one tap takes it", button ~= nil and Button.Press(button) and waitFor(t, REPLICATE, function(): boolean
					local view = ProfileController.Get() :: any
					return view ~= nil and view.Welcome ~= nil and view.Welcome.Taken == 1
				end))
				t.Equal("a Forge Crate into the bag", held(t, "crate"), crates + 1)
				t.Check("the row turns: taken, none lit until the next day", waitFor(t, 1, function(): boolean
					return states(TodayList.Said(panel)) == "Taken Later Later Later Later Later Later"
				end), states(TodayList.Said(panel)))
				t.Check("the rim dark again", (TodayList.Said(panel) :: any).Waits == false)
				local first = if scroll then scroll:FindFirstChild("Week1") else nil -- the row laid again in the same scroll
				local shows: { string } = {}
				for _, child in (if first then first:GetChildren() else {}) do
					if child:IsA("GuiObject") and child.Name ~= "Day" then
						table.insert(shows, child.Name)
					end
				end
				t.Check("the taken day shows its check alone, its gift's picture and words gone", first ~= nil and #shows == 1, table.concat(shows, ", "))
				local again = t.Server("Act", "WelcomeClaim", {}) :: any
				t.Check("a second claim the same day pays nothing", again.Ok == false and again.Error == "Today" and held(t, "crate") == crates + 1, tostring(again.Error))
				Helpers.lintClean(t, "Welcome week")
				restore()
			end,
		},
		{
			Name = "Codes (TR59) behind Settings' band press: the field, a code taken once, wrong, used, and the note",
			Run = function(t: any)
				Screen.Close()
				local home = HudConfig.Home
				local crates = held(t, "crate")
				local test = { { Id = "selftest", Code = "Lantern Test", Gives = { { Chest = "crate", Count = 1 } }, Until = 0 } }
				local function restore()
					t.Server("CodeList", nil)
					local gained = held(t, "crate") - crates
					if gained ~= 0 then
						t.Server("ChestGive", "crate", -gained)
					end
					Screen.Close()
				end
				t.Check("a test code stands in", (t.Server("CodeList", test) :: any).Ok == true)
				local panel = HudController.Home()
				if not HomePanel.Shown(panel) then
					Button.Press(HudController.Parts().Home :: TextButton)
				end
				t.Wait(home.Open.Grow + 0.1)
				t.Check("Settings opens", Button.Press(panel.Cards.Settings.Button) and waitFor(t, home.Step.Lit + home.Step.RiseAt + 1, function(): boolean
					return Screen.Current() == SettingsScreen.Name
				end))
				t.Wait(home.Step.Rise + 0.4)
				local parts = SettingsScreen.Parts()
				local press = parts.CodesPress :: TextButton?
				t.Check("the band's Codes press", press ~= nil and press.Visible)
				t.Check("it turns the card to the codes", press ~= nil and Button.Press(press) and waitFor(t, 1, function(): boolean
					return (parts.Codes :: Frame).Visible and not (parts.RowMusic :: Frame).Visible
				end))
				local note = (parts.Codes :: Frame):FindFirstChild("Note") :: TextLabel?
				t.Check("the note, whole", note ~= nil and note.Text == "New codes come with each update. See the game's page." and note.TextFits)
				local card = parts.Card :: Frame
				local field = (parts.Codes :: Frame):FindFirstChild("Field") :: TextBox?
				local S = HudConfig.Settings
				t.Equal("the card shrinks to the codes", card.Size.Y.Offset, S.Codes.Foot - S.Card[2])
				t.Check("the note inside it, no empty middle", note ~= nil and note.AbsolutePosition.Y + note.AbsoluteSize.Y <= card.AbsolutePosition.Y + card.AbsoluteSize.Y
					and card.AbsolutePosition.Y + card.AbsoluteSize.Y - (note.AbsolutePosition.Y + note.AbsoluteSize.Y) < 0.25 * card.AbsoluteSize.Y)
				t.Check("the field in the kit's neutral glass, not violet", field ~= nil and field.BackgroundColor3 == UIKit.Palettes[S.Codes.Field.Palette].Panel[1])
				t.Equal("wrong", SettingsScreen.Take("not a code"), Codes.Words.Unknown)
				t.Equal("taken, in any case and spacing", SettingsScreen.Take("  lantern test"), "Code taken: Forge Crate")
				t.Check("a Forge Crate into the bag", waitFor(t, REPLICATE, function(): boolean
					return held(t, "crate") == crates + 1
				end))
				t.Equal("twice: used", SettingsScreen.Take("LANTERNTEST"), Codes.Words.Used)
				t.Equal("and nothing more", held(t, "crate"), crates + 1)
				Helpers.lintClean(t, "Codes")
				t.Check("the press turns it back", press ~= nil and Button.Press(press) and waitFor(t, 1, function(): boolean
					return not (parts.Codes :: Frame).Visible and (parts.RowMusic :: Frame).Visible
				end))
				t.Equal("the card whole again", (parts.Card :: Frame).Size.Y.Offset, HudConfig.Settings.Card[4] - HudConfig.Settings.Card[2])
				restore()
			end,
		},
	}
end

return WelcomeCases
