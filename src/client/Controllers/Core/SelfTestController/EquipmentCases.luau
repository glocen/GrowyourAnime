--!strict
-- EquipmentCases: Equipment's three screens in B (AR43, "The cut in B, for Faber"; TR47's part A; UI.EquipmentScreen).
-- Reinforce from Home's Equipment card: the lead's worn gear, its odds before the press, a try's beat and the level it leaves, the
-- press off when the stones are short. War Emblems: put in and taken out through the bag. Jewels: its five slots, marked
-- as coming. Forge heat on Reinforce (TR55). Four cases, so a frame-bound beat (Reinforce's, on RenderStepped) never takes the others down with it.
-- Everything given is taken back at the end of each.

local Shared = game:GetService("ReplicatedStorage").Shared
local HudConfig = require(Shared.Config.Hud)
local Rules = require(Shared.Rules.Reinforce)
local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local ProfileController = require(script.Parent.Parent.ProfileController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Button = require(UI.Kit.Button)
local Screen = require(UI.Kit.Screen)
local HomePanel = require(UI.HomePanel)
local EquipmentScreen = require(UI.EquipmentScreen)
local Helpers = require(script.Parent.Helpers)

local EquipmentCases = {}

local waitFor = Helpers.waitFor
local MOTION = HudConfig.Equipment.Motion

local function view(t: any): any
	return t.Server("Data")
end

local function find(root: Instance?, name: string): Instance?
	return if root then root:FindFirstChild(name, true) else nil
end

-- A label's words; the newest one of that name when lines cross (the outgoing frame leaves after the incoming is laid).
local function said(root: Instance?, name: string): string
	local found = ""
	if root then
		for _, each in root:GetDescendants() do
			if each.Name == name and each:IsA("TextLabel") then
				found = each.Text
			end
		end
	end
	return found
end

local function dressOf(button: Instance?): string?
	return if button then button:GetAttribute("Dress") :: string? else nil
end

-- A Rare helmet on the lead's own preset, and what the case changes, kept to put back.
type Given = { Id: string, Preset: number, Worn: string?, Before: any }

local function give(t: any, stones: number, emblems: number): Given?
	Screen.Close()
	local before = view(t)
	local lead = before.Voidkin[before.Roles.Lead]
	local preset = if lead then lead.Preset else 1
	local made = t.Server("ItemGive", "helmet", "Rare", { { Stat = "Health", Value = 300 } })
	t.Check("a helmet given", made and made.Ok == true)
	if not (made and made.Ok) then
		return nil
	end
	t.Server("Act", "Equip", { Preset = preset, Slot = "Helmet", Item = made.Id })
	t.Server("DataCredits", 100000)
	if stones ~= 0 then
		t.Server("StonesGive", "Low", stones)
	end
	if emblems ~= 0 then
		t.Server("EmblemGive", "warhorn:Hit", emblems)
	end
	t.Wait(0.3)
	return { Id = made.Id, Preset = preset, Worn = before.Presets[preset].Slots.Helmet, Before = before }
end

local function putBack(t: any, g: Given, emblems: number)
	if Screen.Current() == EquipmentScreen.Name then
		Screen.Close()
	end
	t.Server("Act", "Equip", { Preset = g.Preset, Slot = "Helmet", Item = g.Worn or "" })
	if emblems ~= 0 then
		t.Server("EmblemGive", "warhorn:Hit", -emblems)
	end
	t.Server("ItemTake", g.Id)
	local now = view(t)
	t.Server("DataCredits", g.Before.Currency.Credits - now.Currency.Credits)
	t.Server("StonesGive", "Low", (g.Before.Bag.Stones.Low or 0) - (now.Bag.Stones.Low or 0))
	local restored = view(t)
	t.Check("put back: Credits, stones, emblems, the helmet worn", restored.Currency.Credits == g.Before.Currency.Credits and (restored.Bag.Stones.Low or 0) == (g.Before.Bag.Stones.Low or 0) and (restored.Bag.Emblems["warhorn:Hit"] or 0) == (g.Before.Bag.Emblems["warhorn:Hit"] or 0) and restored.Presets[g.Preset].Slots.Helmet == g.Worn and restored.Items[g.Id] == nil)
end

-- Straight to a page, as Home's card does once it has stepped (HudController's equipmentScreen).
local function open(t: any, page: string, id: string): boolean
	local profile = ProfileController.Get()
	if profile == nil then
		return false
	end
	EquipmentScreen.Open(page, profile, { Act = ProfileController.Act, Say = function(_: string) end })
	t.Wait(MOTION.WorkStart + MOTION.WorkTime + 0.1)
	return Screen.Current() == EquipmentScreen.Name and EquipmentScreen.Choose(id)
end

function EquipmentCases.Cases(): { any }
	return {
		{
			Name = "Equipment: Reinforce (AR43, B) from Home's Equipment card (AR49), on the page last shown: the lead's worn gear, its odds before the press, a try's rise and its level, the press off when short",
			Run = function(t: any)
				local g = give(t, 3, 0)
				if g == nil then
					return
				end
				local id = g.Id
				-- From its card: its own screen on the page last shown, the worn gear listed, the helmet among them.
				local panel = HudController.Home()
				local home = HudConfig.Home
				if not HomePanel.Shown(panel) then
					Button.Press(HudController.Parts().Home :: TextButton)
				end
				t.Wait(home.Open.Grow + 0.1)
				local last = EquipmentScreen.Last()
				t.Check("Equipment's card opens Equipment", Button.Press(panel.Cards.Equipment.Button) and waitFor(t, home.Step.Lit + home.Step.RiseAt + 1, function(): boolean
					return Screen.Current() == EquipmentScreen.Name
				end), tostring(Screen.Current()))
				t.Wait(home.Step.Rise + 0.1)
				t.Equal("on the page last shown", EquipmentScreen.State().Page, last)
				t.Check("the rail's Reinforce", EquipmentScreen.Switch("Reinforce") and EquipmentScreen.State().Page == "Reinforce")
				t.Wait(MOTION.Enter + 0.1)
				local list = EquipmentScreen.Parts().List :: ScrollingFrame?
				local rows, held = 0, false
				local layer = if list then list:FindFirstChild("Rows") else nil
				for _, child in if layer then layer:GetChildren() else {} do
					rows += if child:IsA("TextButton") then 1 else 0
					held = held or child:GetAttribute("Item") == id
				end
				t.Check("the lead's worn gear, a row each, the helmet's among them", rows >= 1 and held, `{rows} rows`)
				t.Check("the helmet's row chosen", EquipmentScreen.Choose(id) and EquipmentScreen.State().Item == id)
				t.Wait(MOTION.Enter + 0.1)
				Helpers.lintClean(t, "Reinforce")
				local work = EquipmentScreen.Parts().Work :: CanvasGroup?
				t.Equal("ready", if work then work:GetAttribute("State") else nil, "Ready")
				local odds = math.floor(Rules.Chance(1) * 100 + 0.5)
				t.Equal("its odds before the press, adding to 100", said(work, "Success") .. " / " .. said(work, "Fail"), `Success {odds}% / Fail {100 - odds}%`)
				t.Equal("now +0, after +1", said(work, "NowLevel") .. " " .. said(work, "AfterLevel"), "+0 +1")
				local press = EquipmentScreen.Parts().ReinforcePress :: TextButton?
				t.Equal("the press lit", dressOf(press), "Lit")
				-- The try: the stones fly, the ring breathes, the rise; the beat holds the screen until it settles.
				local credits = view(t).Currency.Credits
				local cost = Rules.Cost({ Tier = view(t).Items[id].Tier }, 1)
				t.Check("the press takes", press ~= nil and Button.Press(press :: TextButton))
				t.Wait(0.1)
				t.Check("busy while it answers: no page change", EquipmentScreen.State().Busy and not EquipmentScreen.Switch("Jewels"))
				local M = HudConfig.Equipment.Reinforce.Motion
				t.Check("the beat ends", waitFor(t, M.Least + M.Settle + 1.5, function(): boolean
					return not EquipmentScreen.State().Busy
				end))
				local after = view(t)
				t.Equal("risen to +1 in the save", after.Items[id].Reinforce, 1)
				t.Equal("one try's Credits", credits - after.Currency.Credits, cost.Credits)
				work = EquipmentScreen.Parts().Work :: CanvasGroup?
				t.Equal("its state: Rose", if work then work:GetAttribute("State") else nil, "Rose")
				t.Equal("the level by the ring", said(work, "NowLevel"), "+1")
				t.Equal("said in the good", said(work, "Said1"), "Reinforced to +1")
				-- Short: the stones taken away, the press stands off; the rise's line stays over the state's until the next press.
				t.Server("StonesGive", "Low", -(after.Bag.Stones.Low or 0))
				t.Wait(0.3)
				work = EquipmentScreen.Parts().Work :: CanvasGroup?
				press = EquipmentScreen.Parts().ReinforcePress :: TextButton?
				t.Check("no stones: the press off, it refuses", press ~= nil and dressOf(press) == "Off" and not Button.Press(press :: TextButton), tostring(dressOf(press)))
				local upcoming = Rules.Cost({ Tier = after.Items[id].Tier }, 2)
				t.Equal("said short", said(work, "Said2"), `You have 0 {upcoming.Grade} stones: {upcoming.Stones} short`)
				Screen.Close("Back")
				t.Check("Back sinks it, and the panel comes back", waitFor(t, home.Step.Sink + home.Step.BackAt + 0.5, function(): boolean
					return HomePanel.Shown(panel)
				end) and Screen.Current() == nil)
				HomePanel.Close(panel)
				putBack(t, g, 0)
			end,
		},
		{
			Name = "Equipment: forge heat on Reinforce (TR55): no bar while a try is sure; its fill is the item's heat; full, the odds read 100% and the try rises, then it's empty",
			Run = function(t: any)
				local g = give(t, 6, 0)
				if g == nil then
					return
				end
				local id = g.Id
				t.Check("the Reinforce page, the helmet chosen", open(t, "Reinforce", id))
				local function work(): CanvasGroup?
					return EquipmentScreen.Parts().Work :: CanvasGroup?
				end
				local function share(): number?
					local track, fill = find(work(), "HeatTrack") :: GuiObject?, find(work(), "HeatFill") :: GuiObject?
					if track == nil or fill == nil or track.AbsoluteSize.X <= 0 then
						return nil
					end
					return fill.AbsoluteSize.X / track.AbsoluteSize.X
				end
				t.Check("at +0, a sure try: no heat shown", find(work(), "HeatTrack") == nil)
				t.Check("+5 with 60 heat", (t.Server("ItemForge", id, 5, 60) or {}).Ok == true)
				t.Wait(0.5)
				t.Equal("the odds for +6", said(work(), "Success") .. " / " .. said(work(), "Fail"), "Success 80% / Fail 20%")
				local part = share()
				t.Check("its bar 60% full", part ~= nil and math.abs(part - 0.6) < 0.03, tostring(part))
				t.Check("not yet sure", said(work(), "HeatFull") == "")
				t.Check("full", (t.Server("ItemForge", id, 5, 100) or {}).Ok == true)
				t.Wait(0.5)
				t.Equal("full: the odds read sure", said(work(), "Success") .. " / " .. said(work(), "Fail"), "Success 100% / Fail 0%")
				t.Equal("and say so", said(work(), "HeatFull"), HudConfig.Equipment.Reinforce.Heat.Full)
				part = share()
				t.Check("its bar whole", part ~= nil and math.abs(part - 1) < 0.03, tostring(part))
				local press = EquipmentScreen.Parts().ReinforcePress :: TextButton?
				t.Check("the press takes", press ~= nil and Button.Press(press :: TextButton))
				local M = HudConfig.Equipment.Reinforce.Motion
				t.Check("the beat ends", waitFor(t, M.Least + M.Settle + 1.5, function(): boolean
					return not EquipmentScreen.State().Busy
				end))
				local after = view(t).Items[id]
				t.Check("a sure try rose to +6, its heat gone", after.Reinforce == 6 and after.Heat == nil, `+{after.Reinforce}, {after.Heat}`)
				t.Wait(0.3)
				t.Check("the bar empty", find(work(), "HeatTrack") ~= nil and find(work(), "HeatFill") == nil)
				putBack(t, g, 0)
			end,
		},
		{
			Name = "Equipment: War Emblems (AR43, B): an emblem from the bag into the lit socket, then taken out back to the bag",
			Run = function(t: any)
				local g = give(t, 0, 2)
				if g == nil then
					return
				end
				local id = g.Id
				t.Check("its page opens on the helmet", open(t, "War Emblems", id))
				t.Equal("on War Emblems", EquipmentScreen.State().Page, "War Emblems")
				t.Wait(MOTION.Enter + 0.1)
				Helpers.lintClean(t, "War Emblems")
				local bag = EquipmentScreen.Parts().EmblemsBag :: ScrollingFrame?
				local cell: TextButton? = nil
				for _, each in if bag then bag:GetDescendants() else {} do
					if each:IsA("TextButton") and each:GetAttribute("Emblem") == "warhorn:Hit" then
						cell = each
					end
				end
				t.Check("the bag's emblem in its row", cell ~= nil)
				t.Equal("nothing chosen: off", dressOf(EquipmentScreen.Parts().EmblemsPress), "Off")
				t.Check("the emblem chosen", cell ~= nil and Button.Press(cell :: TextButton))
				t.Wait(0.2)
				local put = EquipmentScreen.Parts().EmblemsPress :: TextButton?
				t.Equal("Put in, lit", if put then `{dressOf(put)} {put:GetAttribute("Words")}` else nil, "Lit Put in")
				t.Check("Put in takes", put ~= nil and Button.Press(put :: TextButton))
				t.Check("in the socket", waitFor(t, 2, function(): boolean
					return view(t).Items[id].Sockets[1] == "warhorn:Hit"
				end))
				t.Wait(0.3)
				local work = EquipmentScreen.Parts().Work :: CanvasGroup?
				local socket = find(work, "Socket1")
				t.Check("the socket shows it", socket ~= nil and socket:GetAttribute("Emblem") == "warhorn:Hit", if socket then tostring(socket:GetAttribute("Emblem")) else "no socket")
				local out = EquipmentScreen.Parts().EmblemsPress :: TextButton?
				t.Equal("the socket alone: Take out", if out then `{dressOf(out)} {out:GetAttribute("Words")}` else nil, "Lit Take out")
				t.Check("Take out takes", out ~= nil and Button.Press(out :: TextButton))
				t.Check("back in the bag", waitFor(t, 2, function(): boolean
					local now = view(t)
					return (now.Items[id].Sockets[1] or "") == "" and now.Bag.Emblems["warhorn:Hit"] == (g.Before.Bag.Emblems["warhorn:Hit"] or 0) + 2
				end))
				putBack(t, g, 2)
			end,
		},
		{
			Name = "Equipment: Jewels (AR43, B; TR47's part A): five slots in the colours' order, marked as coming, its presses off",
			Run = function(t: any)
				local g = give(t, 0, 0)
				if g == nil then
					return
				end
				t.Check("its page opens on the helmet", open(t, "Jewels", g.Id))
				t.Wait(MOTION.Enter + 0.1)
				Helpers.lintClean(t, "Jewels")
				local work = EquipmentScreen.Parts().Work :: CanvasGroup?
				local slots = 0
				for _, colour in HudConfig.Equipment.Jewels.Order do
					slots += if find(work, `Socket{colour}`) then 1 else 0
				end
				t.Equal("five slots", slots, 5)
				t.Equal("marked as coming", if work then work:GetAttribute("State") else nil, "Coming")
				t.Equal("said so", said(work, "Said1"), "Jewels are coming")
				local jewel = EquipmentScreen.Parts().JewelsPutIn :: TextButton?
				t.Check("its press off, refusing", jewel ~= nil and dressOf(jewel) == "Off" and not Button.Press(jewel :: TextButton))
				putBack(t, g, 0)
			end,
		},
	}
end

return EquipmentCases
