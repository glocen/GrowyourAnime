--!strict
-- SettingsCases: Settings in B (AR43, "The cut in B, for Faber"; UI.SettingsScreen; Rules.Settings). From Home's tall
-- tile: one card of Music, Sound and Effects; a slider let go saves its level once and the game takes it at once (the
-- music's group, the cues' buses); Off at nought. The levels are put back at the end.

local SoundService = game:GetService("SoundService")

local Shared = game:GetService("ReplicatedStorage").Shared
local HudConfig = require(Shared.Config.Hud)
local Settings = require(Shared.Rules.Settings)
local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local SettingsController = require(script.Parent.Parent.SettingsController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Button = require(UI.Kit.Button)
local Screen = require(UI.Kit.Screen)
local HomePanel = require(UI.HomePanel)
local SettingsScreen = require(UI.SettingsScreen)
local Helpers = require(script.Parent.Helpers)

local SettingsCases = {}

local waitFor = Helpers.waitFor

local function said(row: Instance?): string
	local label = if row then row:FindFirstChild("Said") else nil
	return if label and label:IsA("TextLabel") then label.Text else ""
end

function SettingsCases.Cases(): { any }
	return {
		{
			Name = "Settings (AR43, B) from Home's Settings card (AR49): Music, Sound and Effects on one card; a slider let go saves once and is heard at once; Off at nought",
			Run = function(t: any)
				Screen.Close()
				local before = (t.Server("Data") :: any).Settings
				local home = HudConfig.Home
				local panel = HudController.Home()
				if not HomePanel.Shown(panel) then
					Button.Press(HudController.Parts().Home :: TextButton)
				end
				t.Wait(home.Open.Grow + 0.1)
				t.Check("Settings' card opens its screen", Button.Press(panel.Cards.Settings.Button) and waitFor(t, home.Step.Lit + home.Step.RiseAt + 1, function(): boolean
					return Screen.Current() == SettingsScreen.Name
				end), tostring(Screen.Current()))
				t.Wait(home.Step.Rise + 0.4)
				local parts = SettingsScreen.Parts()
				for _, name in Settings.Levels do
					local row = parts[`Row{name}`]
					t.Equal(`{name}: its row, at the save's level`, said(row), Settings.Said(before[name]))
				end
				Helpers.lintClean(t, "Settings")
				-- Music to 40%: the row says so, the save keeps it, the music's group follows.
				t.Check("Music dragged to 40% and let go", SettingsScreen.Set("Music", 0.4))
				t.Equal("its row says 40%", said(parts.RowMusic), "40%")
				t.Equal("the game takes it at once", SettingsController.Level("Music"), 0.4)
				t.Check("saved", waitFor(t, 2, function(): boolean
					return (t.Server("Data") :: any).Settings.Music == 0.4
				end))
				local music = SoundService:FindFirstChild("GA_Music")
				t.Check("the music's group at 40%", music ~= nil and music:IsA("SoundGroup") and math.abs(music.Volume - 0.4) < 1e-3, if music and music:IsA("SoundGroup") then tostring(music.Volume) else "no group")
				-- Sound to nought: Off, and every bus's head silent.
				t.Check("Sound dragged to nought", SettingsScreen.Set("Sound", 0))
				t.Equal("it reads Off", said(parts.RowSound), "Off")
				local heads, quiet = 0, true
				for _, each in SoundService:GetChildren() do
					if each:IsA("AudioFader") and string.sub(each.Name, -5) == "Level" then
						heads += 1
						quiet = quiet and each.Volume == 0
					end
				end
				t.Check("the cues' buses silent at their heads", heads > 0 and quiet, `{heads} heads`)
				t.Check("Effects to half", SettingsScreen.Set("Effects", 0.5) and SettingsController.Level("Effects") == 0.5)
				t.Check("both saved", waitFor(t, 2, function(): boolean
					local now = (t.Server("Data") :: any).Settings
					return now.Sound == 0 and now.Effects == 0.5
				end))
				-- Back as they were.
				for _, name in Settings.Levels do
					t.Server("Act", "Settings", { Name = name, Value = before[name] })
				end
				Screen.Close("Back")
				t.Check("Back sinks it, and the panel comes back", waitFor(t, home.Step.Sink + home.Step.BackAt + 0.5, function(): boolean
					return HomePanel.Shown(panel)
				end))
				HomePanel.Close(panel)
				t.Check("the levels put back, and heard", waitFor(t, 2, function(): boolean
					local ok = true
					for _, name in Settings.Levels do
						ok = ok and SettingsController.Level(name) == before[name]
					end
					return ok
				end))
			end,
		},
	}
end

return SettingsCases
