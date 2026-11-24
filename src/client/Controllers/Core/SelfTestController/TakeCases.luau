--!strict
-- TakeCases: stills held for research, run by name only (Manual). Apart from Cases, which is at the type checker's limit.
-- AR62's before set (docs/asset-requests.md, AR62, "The plan", step 1): every screen in its main state at the smallest
-- phone, as ReplicatedStorage.NL_TakeStep says. The box is centred on the window (Layers.Box's `at`), so the world stands
-- under the HUD as on the phone, and the step's "Frame" attribute says where the box's top left sits, in the window's
-- pixels. The camera's field of view widens so the world fills the phone's screen as it would there (BaseCases' take).
-- Steps: "Hud" (the HUD and the dock, nothing open), "Menu" (Home's panel), "Voidkin", "Equipment", "Settings",
-- "Today" (each Menu card's screen), "Breaker", "Shop" (the Void Shop), "Arc" (the dock's Play to the Arc panel), "Toast",
-- "Fall" (a run on Normal, its lead's fall, the card), "Win" (the keeper's clear, the card: the Festival's place only),
-- "End". The reveal is driven by its own bridge (NL_RevealTest) while the box holds. The record on Lantern Row and
-- Studio's camera are put back at the end.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local BaseController = require(script.Parent.Parent.Parent.Main.BaseController)
local ShopController = require(script.Parent.Parent.Parent.Main.ShopController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Screen = require(UI.Kit.Screen)
local Button = require(UI.Kit.Button)
local Toast = require(UI.Kit.Toast)
local HomePanel = require(UI.HomePanel)
local StageScreen = require(UI.StageScreen)
local VoidkinScreen = require(UI.VoidkinScreen)
local Layers = require(UI.Layers)
local Theme = require(UI.Theme)
local Helpers = require(script.Parent.Helpers)

local TakeCases = {}

local waitFor = Helpers.waitFor
local CARDS = { Voidkin = true, Equipment = true, Settings = true, Today = true }

local function closeAll()
	Screen.Close()
	local panel = HudController.Home()
	if HomePanel.Shown(panel) then
		HomePanel.Close(panel)
	end
end

function TakeCases.Cases(): { any }
	return {
		{
			Name = "Take: AR62, every screen in its main state at the smallest phone, as the driver writes (NL_TakeStep), for research's before set",
			Manual = true,
			Stay = true,
			Run = function(t: any)
				local player = Players.LocalPlayer
				local camera = workspace.CurrentCamera
				local fieldWas = camera.FieldOfView
				local record = t.Server("Stage")
				local normal = if type(record) == "table" and type(record.Normal) == "table" then record.Normal else nil
				local cleared = if normal and type(normal.Cleared) == "number" then normal.Cleared else nil
				local checkpoint = if type(record) == "table" and type(record.Checkpoint) == "table" then record.Checkpoint.Normal else nil
				local step = Instance.new("StringValue")
				step.Name = "NL_TakeStep"
				step.Value = "Hud"
				step.Parent = ReplicatedStorage
				local function box()
					local view, phone = camera.ViewportSize, Theme.Smallest
					camera.FieldOfView = 2 * math.deg(math.atan(math.tan(math.rad(fieldWas / 2)) * view.Y / phone.Y))
					Layers.Force(Theme.Scale.Floor)
					Layers.Box(phone - Vector2.new(0, GuiService.TopbarInset.Height), (view - phone) / 2)
					step:SetAttribute("Frame", `{math.round((view.X - phone.X) / 2)},{math.round((view.Y - phone.Y) / 2)}`)
				end
				local function say(words: string)
					step:SetAttribute("Said", words)
				end
				box()
				closeAll()
				t.Wait(0.3)
				local shown = ""
				waitFor(t, 1800, function(): boolean
					local value = step.Value
					if value == shown then
						return false
					end
					shown = value
					box()
					if value == "Hud" then
						closeAll()
						say("hud")
					elseif value == "Menu" then
						closeAll()
						t.Wait(0.2)
						local opened = Button.Press(HudController.Parts().Home :: TextButton)
						say(if opened then "menu" else "menu: Home didn't press")
					elseif CARDS[value] then
						closeAll()
						t.Wait(0.2)
						local panel = HudController.Home()
						Button.Press(HudController.Parts().Home :: TextButton)
						t.Wait(0.5)
						local card = panel.Cards[value]
						local pressed = card ~= nil and Button.Press(card.Button)
						if pressed and value == "Voidkin" then -- its main state: the Overview page, whichever was last open
							t.Wait(0.4)
							VoidkinScreen.Show("Overview")
						end
						say(if pressed then value else `{value}: its card didn't press`)
					elseif value == "Breaker" then
						closeAll()
						BaseController.OpenBreaker()
						say("breaker")
					elseif value == "Shop" then
						closeAll()
						say(if ShopController.Open() then "shop" else "shop: didn't open here")
					elseif value == "Arc" then
						closeAll()
						t.Wait(0.2)
						local up = Helpers.openArc(t, HudController.Parts().Map :: TextButton, 2, function(): boolean
							return Screen.Current() == StageScreen.Name and StageScreen.Parts().Arc ~= nil
						end)
						say(if up then "arc" else `arc: {tostring(Screen.Current())}`)
					elseif value == "Toast" then
						closeAll()
						Toast.Show("Collected 120 Void Stones")
						say("toast")
					elseif value == "Fall" then
						closeAll()
						Helpers.endRun(t)
						t.Server("LeadHeal")
						t.Server("StageBegin", "Normal")
						local began = waitFor(t, 3, function(): boolean
							return type(player:GetAttribute("StageRun")) == "string"
						end)
						t.Wait(1)
						t.Server("FightHealth", 0)
						local card = began and waitFor(t, 12, function(): boolean
							return Screen.Current() == StageScreen.Name
						end)
						say(if card then "fall" else `fall: {tostring(player:GetAttribute("StageRun"))}`)
					elseif value == "Win" then
						closeAll()
						Helpers.endRun(t)
						t.Server("LeadHeal")
						t.Server("StageLine", "Normal", 3, 4)
						t.Server("StageBegin", "Normal")
						t.Wait(1)
						t.Server("KeeperTry")
						local keeper = waitFor(t, 15, function(): boolean
							local state = t.Server("Keeper")
							return type(state) == "table" and state.Keeper ~= nil
						end)
						t.Wait(1.5)
						t.Server("KeeperEnd", "Win")
						local card = keeper and waitFor(t, 25, function(): boolean
							return Screen.Current() == StageScreen.Name
						end)
						say(if card then "win" else `win: keeper {tostring(keeper)}, {tostring(Screen.Current())}`)
					end
					return value == "End"
				end)
				closeAll()
				Helpers.endRun(t)
				Screen.Close()
				Layers.Box(nil)
				Layers.Force(nil)
				camera.FieldOfView = fieldWas
				if cleared ~= nil then
					t.Server("StageLine", "Normal", cleared, checkpoint)
				end
				t.Server("LeadHeal")
				step:Destroy()
			end,
		},
	}
end

return TakeCases
