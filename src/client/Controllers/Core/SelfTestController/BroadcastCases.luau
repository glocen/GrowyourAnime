--!strict
-- BroadcastCases: the Broadcast's plate and chat line (TR57; BroadcastController; BroadcastService). A line told on the
-- server shows once in the target card's place at the top centre, in our words with the finder's display name, and
-- stays in the chat; an open screen holds the next until it closes. The plate's gap is
-- tuned short for the run and put back. On the smallest phone, the longest item's line keeps clear of the lead's card and
-- the pills, wrapping to two lines there. The plate's cue: someone else's line calls it once on its fade-in; the player's
-- own, a chat-only line, and anyone's while others' finds are off call nothing.

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config.Broadcast)
local HudConfig = require(Shared.Config.Hud)
local Items = require(Shared.Definitions.Items)
local Settings = require(Shared.Rules.Settings)
local ProfileController = require(script.Parent.Parent.ProfileController)
local Cues = require(script.Parent.Parent.Parent.Main.FighterController.Cues)
local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local BroadcastController = require(script.Parent.Parent.Parent.Main.BroadcastController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Layers = require(UI.Layers)
local Theme = require(UI.Theme)
local Screen = require(UI.Kit.Screen)
local SettingsScreen = require(UI.SettingsScreen)
local Helpers = require(script.Parent.Helpers)

local BroadcastCases = {}

local waitFor = Helpers.waitFor
local GAP = 0.5 -- the plate's gap for the run, in place of Config.Broadcast.Plate.Gap

function BroadcastCases.Cases(): { any }
	return {
		{
			Name = "Broadcast (TR57): a told line shows once in the target card's place, in our words, and stays in the chat; an open screen holds the next",
			Run = function(t: any)
				Screen.Close()
				local gap = Config.Plate.Gap
				t.Server("Tune", "Broadcast.Plate.Gap", GAP)
				t.Wait(0.3)
				local _, fighting = HudController.TargetSpot()
				t.Check("no fight's card at the top", not fighting)
				Layers.Force(Theme.Scale.Floor) -- the smallest phone, where the band is narrowest
				Layers.Box(Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height))
				t.Wait(0.2)
				local row = Items.List[1]
				for _, each in Items.List do -- the longest name: the line that wraps on the smallest phone
					if #each.Name > #row.Name then
						row = each
					end
				end
				local told = t.Server("BroadcastTell", "Item", row.Id, "Epic", 0) :: any
				t.Check("told on the server", type(told) == "table" and told.Ok == true, if type(told) == "table" then tostring(told.Error) else "no answer")
				local an = if string.sub(row.Name, -1) == "s" then "" else "an " -- Gloves, Boots: no article (Rules.Broadcast)
				local want = `{Players.LocalPlayer.DisplayName} found {an}Epic {row.Name}`
				t.Check("the plate shows it, in our words with the finder's display name", waitFor(t, GAP + 2, function(): boolean
					return BroadcastController.Shown() == want
				end), tostring(BroadcastController.Shown()))
				local plate = Layers.Get("Hud"):FindFirstChild("NL_Broadcast") :: GuiObject?
				local spot = HudController.TargetSpot()
				t.Check("in the target card's place, at the top centre", plate ~= nil and plate.Position == spot and plate.AnchorPoint == Vector2.new(0.5, 0), if plate then tostring(plate.Position) else "no plate")
				local words = if plate then plate:FindFirstChild("Words", true) :: TextLabel? else nil
				if plate then
					local pill = (HudController.Parts().Electricity :: GuiObject).Parent :: GuiObject
					local lead = HudController.Parts().Lead
					local left, right = plate.AbsolutePosition.X, plate.AbsolutePosition.X + plate.AbsoluteSize.X
					t.Check("clear of the lead's card and the pills", left >= lead.AbsolutePosition.X + lead.AbsoluteSize.X and right <= pill.AbsolutePosition.X,
						`{math.floor(left)} to {math.floor(right)}; the lead's card ends {math.floor(lead.AbsolutePosition.X + lead.AbsoluteSize.X)}, the pill starts {math.floor(pill.AbsolutePosition.X)}`)
				end
				t.Check("its words fit, the rarity lit", words ~= nil and words.TextFits and string.find(words.Text, "<font", 1, true) ~= nil and string.gsub(words.ContentText, "\n", " ") == want, if words then words.ContentText else "no words")
				local chatted, light = BroadcastController.Chatted()
				t.Equal("and it stays in the chat", chatted, want)
				t.Equal("its rarity in the bag's lifted colour, readable on the chat's dark panel", light, HudConfig.Bag.Rarity.Epic:ToHex())
				Layers.Box(nil)
				Layers.Force(nil)
				t.Check("gone after its seconds", waitFor(t, Config.Plate.Seconds + 1, function(): boolean
					return BroadcastController.Shown() == nil
				end))
				-- An open screen: the next line waits, then shows once it closes.
				SettingsScreen.Open({ Act = function(): { [string]: any }
					return { Ok = false }
				end, Say = function() end })
				t.Check("a screen open", waitFor(t, 2, function(): boolean
					return Screen.Current() ~= nil
				end))
				t.Server("BroadcastTell", "Stars", "rook", "Common", 7)
				t.Wait(GAP + 1)
				t.Check("held while the screen is open", BroadcastController.Shown() == nil, tostring(BroadcastController.Shown()))
				Screen.Close()
				t.Check("shown once it closes", waitFor(t, 3, function(): boolean
					local now = BroadcastController.Shown()
					return now ~= nil and string.find(now, "reached seven stars", 1, true) ~= nil
				end), tostring(BroadcastController.Shown()))
				waitFor(t, Config.Plate.Seconds + 1, function(): boolean
					return BroadcastController.Shown() == nil
				end)
				t.Server("Tune", "Broadcast.Plate.Gap", gap)
				Layers.Box(nil)
				Layers.Force(nil)
			end,
		},
		{
			Name = "Broadcast (TR57): the plate's cue, called once on someone else's line as it fades in; never on the player's own, a chat-only line, or with others' finds off",
			Run = function(t: any)
				Screen.Close()
				local gap = Config.Plate.Gap
				t.Server("Tune", "Broadcast.Plate.Gap", GAP)
				local showing = (t.Server("Data") :: any).Settings.ShowFinds ~= false
				local me = Players.LocalPlayer.UserId
				local stamp = string.format("%.3f", os.clock())
				local function line(n: number, user: number, reach: string, name: string): any
					return { Id = `selftest-cue:{stamp}:{n}`, Kind = "Item", Reach = reach, Def = "sword", Rarity = "Legendary", Level = 0, User = user, Name = name }
				end
				local function clear(): boolean
					return waitFor(t, Config.Plate.Seconds + 2, function(): boolean
						return BroadcastController.Shown() == nil
					end)
				end
				local function shows(name: string): boolean
					return waitFor(t, GAP + 2, function(): boolean
						local now = BroadcastController.Shown()
						return now ~= nil and string.sub(now, 1, #name + 1) == `{name} `
					end)
				end
				if not showing then
					t.Server("Act", "Settings", { Name = "ShowFinds", Value = true })
				end
				t.Check("others' finds shown", waitFor(t, 2, function(): boolean
					local view = ProfileController.Get()
					return view ~= nil and Settings.On(view :: any, "ShowFinds")
				end))
				t.Check("no plate up", clear())
				local heard = Cues.Heard("BroadcastPlate")
				BroadcastController.Hear(line(1, 1234567890, "Server", "Mara"))
				t.Check("someone else's line shows", shows("Mara"), tostring(BroadcastController.Shown()))
				t.Equal("and calls the cue once, as it fades in", Cues.Heard("BroadcastPlate") - heard, 1)
				-- While it stands: the player's own line waits, then a stranger's every-server line goes to the chat only.
				BroadcastController.Hear(line(2, me, "Server", Players.LocalPlayer.DisplayName))
				heard = Cues.Heard("BroadcastPlate")
				BroadcastController.Hear(line(3, 1234567891, "All", "Ines"))
				t.Check("a stranger's line behind a waiting one goes to the chat only", waitFor(t, 1, function(): boolean
					return BroadcastController.Chatted() == "Ines found a Legendary Sword"
				end), tostring((BroadcastController.Chatted())))
				t.Equal("and calls nothing", Cues.Heard("BroadcastPlate") - heard, 0)
				t.Check("the plate goes", clear())
				t.Check("the player's own line shows next", shows(Players.LocalPlayer.DisplayName), tostring(BroadcastController.Shown()))
				t.Equal("and calls nothing", Cues.Heard("BroadcastPlate") - heard, 0)
				t.Check("it goes", clear())
				-- Others' finds off: the server sends only the player's own, and the plate stays silent whatever it's handed.
				t.Server("Act", "Settings", { Name = "ShowFinds", Value = false })
				t.Check("others' finds off", waitFor(t, 2, function(): boolean
					local view = ProfileController.Get()
					return view ~= nil and not Settings.On(view :: any, "ShowFinds")
				end))
				t.Wait(GAP + 0.1)
				BroadcastController.Hear(line(4, 1234567890, "Server", "Mara"))
				t.Check("a line handed to the plate shows", shows("Mara"), tostring(BroadcastController.Shown()))
				t.Equal("and calls nothing", Cues.Heard("BroadcastPlate") - heard, 0)
				clear()
				t.Server("Act", "Settings", { Name = "ShowFinds", Value = showing })
				t.Server("Tune", "Broadcast.Plate.Gap", gap)
			end,
		},
	}
end

return BroadcastCases
