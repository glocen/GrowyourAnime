--!strict
-- The Items page's case (TR28, AR18's A, "the ledger"): the lacquer right of the rail, the doll's fourteen slots, the six
-- kinds with All first, the grid on Rules.Bag's own list with each item's design picture, the up arrow, the worn tick and
-- another class's dim, a card sliding over the doll titled with the design's name, the slot it would fill ringed in its
-- column, Equip and Take off through the server, a chest's card and Open, the sort and the salvage; then the smallest
-- phone, five across, all fourteen slots still a touch. The items and chests it gives are its own, taken back at its end
-- (Studio's ItemGive, ItemTake and ChestGive), so the save is left as it was.

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local HudConfig = require(Shared.Config.Hud)
local UIKit = require(Shared.Config.UIKit)
local Profile = require(Shared.Data.Profile)
local Items = require(Shared.Definitions.Items)
local Voidkin = require(Shared.Definitions.Voidkin)
local Rules = require(Shared.Rules.Bag)
local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local ProfileController = require(script.Parent.Parent.ProfileController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Text = require(UI.Kit.Text)
local Layers = require(UI.Layers)
local Screen = require(UI.Kit.Screen)
local Button = require(UI.Kit.Button)
local Toast = require(UI.Kit.Toast)
local VoidkinScreen = require(UI.VoidkinScreen)
local Seam = require(UI.VoidkinScreen.Seam)
local VoidkinCases = require(script.Parent.VoidkinCases)

local BagCases = {}

export type Given = {
	ANSWER: number,
	waitFor: (t: any, seconds: number, ok: () -> boolean) -> boolean,
	lintClean: (t: any, where: string) -> (),
}

local CHEST = "lanternrow_1"
local KIT = UIKit.Palettes.Seam

local function view(): Profile.View
	return ProfileController.Get() :: Profile.View
end

local function find(name: string): GuiObject?
	local found = VoidkinScreen.Find(name)
	return if found and found:IsA("GuiObject") then found else nil
end

-- The seam's chosen ring as drawn (UI.VoidkinScreen.Seam.Ring): shown, a moat of the seam's Channel inside a ring of its
-- Light, and its glow outward.
local function ringed(ring: Instance?): boolean
	if not (ring and ring:IsA("GuiObject") and ring.Visible) then
		return false
	end
	local function stroke(name: string): UIStroke?
		local band = ring:FindFirstChild(name)
		return if band then band:FindFirstChildOfClass("UIStroke") else nil
	end
	local moat, light, glow = stroke("Moat"), stroke("Light"), stroke("Glow1")
	return moat ~= nil and light ~= nil and glow ~= nil and moat.Color == Seam.Colour.Channel and light.Color == Seam.Light and light.Transparency == 0 and glow.Transparency > 0
end

-- A chip in AR30's make (UI.Kit.Button's Chip): chosen, the glass at L Chosen, its word in Text; otherwise no plate of
-- its own, its word in Soft.
local function chipChosen(chip: Instance?): boolean
	local word = if chip then chip:FindFirstChild("Label") else nil
	return chip ~= nil and chip:GetAttribute("Kind") == "Glass" and chip:GetAttribute("L") == HudConfig.Make.L.Chosen and word ~= nil and word:IsA("TextLabel") and word.TextColor3 == KIT.Text
end

local function chipIdle(chip: Instance?): boolean
	local word = if chip then chip:FindFirstChild("Label") else nil
	return chip ~= nil and chip:GetAttribute("Kind") == "Chip" and word ~= nil and word:IsA("TextLabel") and word.TextColor3 == KIT.Soft
end

local function inView(piece: GuiObject?): boolean
	local frame = Screen.Frame(VoidkinScreen.Name)
	if frame == nil or piece == nil then
		return false
	end
	local up: Instance? = piece
	while up and up ~= frame do
		if up:IsA("GuiObject") and not up.Visible then
			return false
		end
		up = up.Parent
	end
	local a, b = frame.AbsolutePosition, frame.AbsolutePosition + frame.AbsoluteSize
	local c, d = piece.AbsolutePosition, piece.AbsolutePosition + piece.AbsoluteSize
	return c.X >= a.X - 1 and c.Y >= a.Y - 1 and d.X <= b.X + 1 and d.Y <= b.Y + 1
end

local function touches(piece: GuiObject?): boolean
	return piece ~= nil and piece.AbsoluteSize.X >= Theme.Size.Touch - 0.5 and piece.AbsoluteSize.Y >= Theme.Size.Touch - 0.5
end

local function weaponFor(class: string, same: boolean): string?
	for _, row in Items.List do
		if row.Class and row.Slot == "Main Hand" and (row.Class == class) == same then
			return row.Id
		end
	end
	return nil
end

function BagCases.Cases(given: Given): { any }
	local ANSWER, waitFor, lintClean = given.ANSWER, given.waitFor, given.lintClean
	local Bag = VoidkinScreen.Bag
	return {
		{
			Name = "Items page (TR28): A's ledger, the doll's fourteen, the five kinds, the grid on Rules.Bag's list with its designs, the card over the doll, Equip and Take off, a chest opened, the sort and the salvage, then the smallest phone",
			Stay = true,
			Run = function(t: any)
				local ids = VoidkinCases.Own(t, waitFor, ANSWER)
				local lead = view().Roles.Lead
				local owned = view().Voidkin[lead]
				local row = if owned then Voidkin.ById[owned.Def] else nil
				t.Check("a lead to dress", owned ~= nil and row ~= nil and #ids > 0)
				if owned == nil or row == nil then
					return
				end
				local class = row.Class
				-- Its own things: a strong weapon for the lead's class, another class's, a helmet, a ring, three chests.
				local mine: { string } = {}
				local function give(def: string?, rarity: string, lines: { { Stat: string, Value: number } }): string?
					if def == nil then
						return nil
					end
					local answer = t.Server("ItemGive", def, rarity, lines)
					local id = if type(answer) == "table" and answer.Ok == true then answer.Id else nil
					if type(id) == "string" then
						table.insert(mine, id)
						waitFor(t, ANSWER, function(): boolean
							return view().Items[id] ~= nil
						end)
					end
					return id
				end
				local weapon = give(weaponFor(class, true), "Epic", { { Stat = "Attack", Value = 999 }, { Stat = "Strength", Value = 20 } })
				local other = give(weaponFor(class, false), "Legendary", { { Stat = "Attack", Value = 999 } })
				give("helmet", "Rare", { { Stat = "Health", Value = 400 } })
				give("ring", "Uncommon", { { Stat = "Critical", Value = 30 } })
				local heldBefore = view().Bag.Chests[CHEST] or 0
				t.Server("ChestGive", CHEST, 3)
				waitFor(t, ANSWER, function(): boolean
					return (view().Bag.Chests[CHEST] or 0) == heldBefore + 3
				end)
				t.Check("its own items and chests given", weapon ~= nil and other ~= nil and #mine == 4 and (view().Bag.Chests[CHEST] or 0) == heldBefore + 3, `{#mine} items`)
				local itemsBefore: { [string]: boolean } = {}
				for id in view().Items do
					itemsBefore[id] = true
				end
				Screen.Close()
				local hud = HudController.Parts()
				t.Check("the dock's Voidkin opens it, on the Items page", Button.Press(hud.Voidkin :: TextButton) and waitFor(t, 1, function(): boolean
					local page = find("Page")
					return Screen.Current() == VoidkinScreen.Name and page ~= nil and page:GetAttribute("Page") == "Bag"
				end))
				t.Wait(HudConfig.Motion.Screen.Enter + 0.1)
				local state = Bag.State()
				t.Check("on All, by rarity, nothing chosen", state.Kind == "All" and state.Sort == "Rarity" and state.Chosen == nil, `{state.Kind}, {state.Sort}`)
				-- All is the strip's first tab and holds everything, the gear and the chests among it (the director, by 21:32).
				local kindsStrip = find("Kinds")
				local firstChip = if kindsStrip then kindsStrip:FindFirstChild(Rules.Kinds[1]) else nil
				local everything = Rules.List(view() :: any, owned, "All", "Rarity")
				local gearIn, chestIn = false, false
				for _, entry in everything do
					gearIn = gearIn or entry.Kind == "Item"
					chestIn = chestIn or entry.Kind == "Chest"
				end
				t.Check("All the strip's first tab, lit, holding the gear and the chests", Rules.Kinds[1] == "All" and firstChip ~= nil and firstChip:GetAttribute("Chosen") == true and gearIn and chestIn)
				-- AR30's make: the chosen chip the glass, its word in Text; the others no plate, in Soft.
				t.Check("the chosen chip the glass, its word in Text, the others no plate and Soft", chipChosen(firstChip) and chipIdle(if kindsStrip then kindsStrip:FindFirstChild(Rules.Kinds[2]) else nil))
				for _, name in { "Rail", "Case", "Doll", "Strip", "Page", "Over", "CardRoom", "BagCount" } do
					t.Check(`{name} in view`, inView(find(name)))
				end
				local count, page = find("BagCount"), find("Page")
				t.Check("the count says the bag's held, pinned outside the grid's scroll (TR28's call 3)", count ~= nil and page ~= nil and count:GetAttribute("Held") == Rules.Held(view() :: any) and not count:IsDescendantOf(page))
				-- The doll: all fourteen slots, always, each a touch and whole in view, whatever the room.
				local function dollChecks(where: string)
					-- The kinds strip: its right edge veiled exactly when it hides a chip (no sliver read as a stray mark).
					local strip = find("Kinds")
					local veiled = find("VeilRight")
					if strip and strip:IsA("ScrollingFrame") and veiled and veiled:IsA("GuiObject") then
						local hides = strip.CanvasPosition.X + strip.AbsoluteWindowSize.X < strip.AbsoluteCanvasSize.X - 1
						t.Check(`{where}: the kinds strip's edge veiled where it hides a chip`, veiled.Visible == hides, `hides {hides}, veiled {veiled.Visible}`)
					else
						t.Check(`{where}: the kinds strip's edge veiled where it hides a chip`, false, "no strip or veil")
					end
					local doll = find("Doll")
					local shown = 0
					local small = ""
					for _, slots in Rules.Groups do
						for _, slot in slots do
							local piece = if doll then doll:FindFirstChild(slot) else nil
							if piece and piece:IsA("GuiObject") then
								shown += 1
								if not (touches(piece) and inView(piece)) then
									small = slot
								end
							end
						end
					end
					t.Check(`{where}: all fourteen slots on the doll`, shown == 14, `{shown}`)
					-- A's sides (the director, 2026-11-16): the doll at the room's left, the grid right of it; the card's room at the
					-- room's right edge, so Equip stands under the right thumb.
					local grid, room, case = find("Strip"), find("CardRoom"), find("Case")
					t.Check(`{where}: the doll left of the grid, the card's room at the right edge`, doll ~= nil and grid ~= nil and room ~= nil and case ~= nil
						and doll.AbsolutePosition.X + doll.AbsoluteSize.X <= grid.AbsolutePosition.X
						and math.abs(room.AbsolutePosition.X + room.AbsoluteSize.X - (case.AbsolutePosition.X + case.AbsoluteSize.X)) <= 2)
					-- AR22: an empty slot shows its piece's mark from the kit, a worn one none.
					local unmarked = ""
					for _, piece in (if doll then doll:GetChildren() else {}) :: { Instance } do
						local mark = piece:FindFirstChild("Empty", true)
						local empty = piece:GetAttribute("Item") == ""
						local right = if empty then mark ~= nil and mark:IsA("ImageLabel") and mark.Image ~= "" else mark == nil
						unmarked = if right or unmarked ~= "" then unmarked else piece.Name
					end
					t.Check(`{where}: each empty slot its mark (AR22), a worn one none`, unmarked == "", unmarked)
					t.Check(`{where}: every slot shown a touch or more, {Theme.Size.Touch} rendered px, whole`, small == "", small)
					local kinds = find("Kinds")
					local cut = ""
					for _, kind in Rules.Kinds do
						local chip = if kinds then kinds:FindFirstChild(kind) else nil
						if not (chip and chip:IsA("GuiObject") and chip.AbsoluteSize.Y >= Theme.Size.Touch - 0.5) then
							cut = kind
						end
					end
					t.Check(`{where}: the five kinds, each a touch tall`, cut == "", cut)
					local chosen = if kinds then kinds:FindFirstChild(Bag.State().Kind) else nil
					t.Check(`{where}: the chosen kind's chip in view`, chosen ~= nil and chosen:IsA("GuiObject") and kinds ~= nil and chosen.AbsolutePosition.X >= kinds.AbsolutePosition.X - 1 and chosen.AbsolutePosition.X + chosen.AbsoluteSize.X <= kinds.AbsolutePosition.X + kinds.AbsoluteSize.X + 1, if chosen and chosen:IsA("GuiObject") and kinds then `chip {math.floor(chosen.AbsolutePosition.X)}+{math.floor(chosen.AbsoluteSize.X)}, strip {math.floor(kinds.AbsolutePosition.X)}+{math.floor(kinds.AbsoluteSize.X)}, canvas {math.floor((kinds :: ScrollingFrame).CanvasPosition.X)}` else "none")
				end
				dollChecks("this window")
				-- The grid is Rules.Bag's list, in its order, each cell saying what the list says.
				local function gridChecks(where: string, kind: string, sort: string)
					local list = Rules.List(view() :: any, view().Voidkin[lead], kind, sort)
					local grid = find("Page")
					local cells = grid and grid:FindFirstChild("Cells")
					local right, wrong = 0, ""
					for index, entry in list do
						local cell = cells and cells:FindFirstChild(entry.Id)
						local ok = cell ~= nil and cell:IsA("GuiObject") and cell.LayoutOrder == index and cell:GetAttribute("Up") == entry.Up and cell:GetAttribute("Worn") == (entry.Worn or "") and cell:GetAttribute("Fits") == entry.Fits and cell:GetAttribute("Count") == entry.Count and (cell:FindFirstChild("Up") ~= nil) == entry.Up and (cell:FindFirstChild("WornMark") ~= nil) == (entry.Worn ~= nil) and cell:GetAttribute("Image") == (entry.Image or "") and (entry.Image == nil or cell:FindFirstChild("Picture", true) ~= nil)
						right += if ok then 1 else 0
						wrong = if ok or wrong ~= "" then wrong else entry.Id
					end
					local shown = 0
					for _, child in (if cells then cells:GetChildren() else {}) :: { Instance } do
						shown += if child:IsA("TextButton") then 1 else 0
					end
					t.Check(`{where}: {kind} by {sort}, a cell for each of the list's {#list}, in order, each as the list says`, right == #list and shown == #list, `{right} of {#list}, {shown} shown; {wrong}`)
					local first = if cells then cells:FindFirstChildWhichIsA("TextButton") else nil
					t.Check(`{where}: a cell is a touch or more`, first == nil or touches(first))
				end
				gridChecks("this window", "All", "Rarity")
				local list = Rules.List(view() :: any, owned, "All", "Rarity")
				local strong, dim = nil :: Rules.Entry?, nil :: Rules.Entry?
				for _, entry in list do
					strong = if entry.Id == weapon then entry else strong
					dim = if entry.Id == other then entry else dim
				end
				t.Check("the strong weapon wears the up arrow", strong ~= nil and strong.Up and find(weapon :: string) ~= nil and (find(weapon :: string) :: GuiObject):FindFirstChild("Up") ~= nil)
				t.Check("another class's weapon is dimmed with its class's mark", dim ~= nil and not dim.Fits and find(other :: string) ~= nil and (find(other :: string) :: GuiObject):FindFirstChild("Class", true) ~= nil)
				-- A tap: its card slides over the doll, titled with its design's name, and the slot it would fill is ringed in its column.
				t.Check("a tap on the weapon chooses it", VoidkinScreen.Tap(find(weapon :: string)) and Bag.State().Chosen == weapon)
				t.Wait(HudConfig.Bag.Slide + 0.1)
				local card = find("Card")
				local room = find("CardRoom")
				t.Check("its card over the doll, slid in", card ~= nil and card:GetAttribute("For") == weapon and room ~= nil and math.abs(card.AbsolutePosition.X + card.AbsoluteSize.X - (room.AbsolutePosition.X + room.AbsoluteSize.X)) <= 1 and inView(card))
				-- TR28's seam: its sliding edge lit, its shadow on the grid; the chosen cell ringed in light over its neighbours.
				t.Check("the card's sliding edge lit, its shadow on the grid", card ~= nil and card:FindFirstChild("SlideEdge") ~= nil and card:FindFirstChild("Shade") ~= nil)
				local cell = find(weapon :: string)
				local shownRings = 0
				for _, each in (if cell and cell.Parent then cell.Parent:GetDescendants() else {}) :: { Instance } do
					shownRings += if each.Name == "Chosen" and each:IsA("GuiObject") and each.Visible then 1 else 0
				end
				t.Check("the chosen cell ringed in the seam's light, a dark moat inside, drawn over its neighbours, and only it", cell ~= nil and ringed(cell:FindFirstChild("Chosen")) and (cell :: GuiObject).ZIndex == 2 and shownRings == 1, `{shownRings} rings`)
				local info = Rules.Card(view() :: any, view().Voidkin[lead], weapon :: string)
				local power = find("Power")
				local said = if card then card:FindFirstChild("Power", true) else nil
				t.Check("its Combat Power change is the comparison's", info ~= nil and said ~= nil and said:GetAttribute("Power") == info.Power and info.Power > 0, if info then `{info.Power}` else "none")
				-- Only what it changes: a line for each changed Basic Attribute and each Battle one, none at nought.
				local changed, shownLines, nought = 0, 0, 0
				if info then
					for _, each in info.Basic do
						changed += if each.Change ~= 0 then 1 else 0
					end
					changed += #info.Battle
				end
				local lines = if card then card:FindFirstChild("Lines") else nil
				for _, each in (if lines then lines:GetChildren() else {}) :: { Instance } do
					local delta = each:FindFirstChild("Change")
					if delta then
						shownLines += 1
						nought += if delta:GetAttribute("Change") == 0 then 1 else 0
					end
				end
				t.Check("its card lists only what it changes", info ~= nil and shownLines == changed and nought == 0, `{shownLines} of {changed}, {nought} at nought`)
				local title = find("ItemName")
				t.Check("the card titled with its design's name", info ~= nil and title ~= nil and title:IsA("TextLabel") and title.Text == info.Name and info.Image ~= nil, if title and title:IsA("TextLabel") then title.Text else "none")
				local doll = find("Doll")
				local target = if doll then doll:FindFirstChild("Main Hand") else nil
				local ring = target and target:FindFirstChild("Target", true)
				local rings = 0
				for _, each in (if doll then doll:GetDescendants() else {}) :: { Instance } do
					rings += if each.Name == "Target" and each:IsA("GuiObject") and each.Visible then 1 else 0
				end
				t.Check("the Main Hand ringed on the doll in the seam's light, and only it", ringed(ring) and rings == 1, `{rings} rings`)
				local press = find("Equip")
				t.Check("Equip the glass while it can be pressed, lit at the main action's L (AR30)", press ~= nil and press:GetAttribute("Kind") == "Glass" and press:GetAttribute("L") == HudConfig.Make.L.Main)
				t.Check("the figure's Combat Power still under the card", power ~= nil)
				-- Equip: the server wears it, the card goes, the cell says it's worn.
				local equip = find("Equip")
				t.Check("Equip pressed", equip ~= nil and equip:IsA("TextButton") and Button.Press(equip))
				t.Check("the save wears it in the Main Hand", waitFor(t, ANSWER, function(): boolean
					return Rules.Worn(view() :: any, view().Voidkin[lead])["Main Hand"] == weapon
				end))
				t.Check("the card closes", waitFor(t, 1, function(): boolean
					return Bag.State().Chosen == nil
				end))
				t.Check("the cell shows the tick", waitFor(t, 1, function(): boolean
					local cell = find(weapon :: string)
					return cell ~= nil and cell:GetAttribute("Worn") == "Main Hand" and cell:FindFirstChild("WornMark") ~= nil
				end))
				-- The worn slot on the doll opens it; Take off takes it off.
				local worn = find("Doll")
				local hand = if worn then worn:FindFirstChild("Main Hand") else nil
				t.Check("the doll's Main Hand holds it", hand ~= nil and hand:GetAttribute("Item") == weapon)
				t.Check("a tap on the doll's Main Hand opens what it wears", VoidkinScreen.Tap(hand :: GuiObject?) and Bag.State().Chosen == weapon)
				t.Wait(HudConfig.Bag.Slide + 0.1)
				local off = find("TakeOff")
				t.Check("Take off pressed", off ~= nil and off:IsA("TextButton") and Button.Press(off))
				t.Check("the save wears nothing there", waitFor(t, ANSWER, function(): boolean
					return Rules.Worn(view() :: any, view().Voidkin[lead])["Main Hand"] == nil
				end))
				-- Another class's weapon: its lines, whose it is, and Equip off with the reason.
				t.Check("a tap on the other class's weapon", VoidkinScreen.Tap(find(other :: string)))
				t.Wait(HudConfig.Bag.Slide + 0.1)
				local blocked = find("Equip")
				local whose = find("Whose")
				local otherRow = Items.ById[(view().Items[other :: string] :: Profile.OwnedItem).Def]
				local why = `{otherRow.Class} only`
				t.Check("it says whose", whose ~= nil and whose:IsA("TextLabel") and whose.Text == why, if whose and whose:IsA("TextLabel") then whose.Text else "none")
				t.Check("Equip off, saying why", blocked ~= nil and blocked:IsA("TextButton") and Button.State(blocked) == "Disabled" and blocked:GetAttribute("Disabled") == why)
				t.Check("Equip off in the seam's own button, no light", blocked ~= nil and blocked:GetAttribute("Palette") == Seam.Palette and blocked:FindFirstChild("Glow", true) == nil)
				t.Check("the close shuts the card", VoidkinScreen.Tap(find("Close")) and Bag.State().Chosen == nil)
				-- The kinds: each shows its own list.
				for _, kind in { "Gear", "Jewelry", "Chests" } do
					t.Check(`the {kind} chip`, VoidkinScreen.Tap(find(kind)) and Bag.State().Kind == kind)
					t.Wait(0.1)
					gridChecks("this window", kind, Bag.State().Sort)
				end
				-- A chest: its card, its odds, and Open.
				t.Check("the chest's card", VoidkinScreen.Tap(find(CHEST)) and Bag.State().Chosen == CHEST)
				t.Wait(HudConfig.Bag.Slide + 0.1)
				local chest = Rules.Chest(view() :: any, CHEST)
				local odds = find("Odds")
				local rows = 0
				for _, child in (if odds then odds:GetChildren() else {}) :: { Instance } do
					rows += if chest and child:IsA("Frame") and table.find(HudConfig.Bag.Salvage, child.Name) ~= nil or (child.Name == "Legendary") then 1 else 0
				end
				t.Check("its odds, a line for each rarity it gives", chest ~= nil and odds ~= nil and rows >= #chest.Odds - 1, `{rows}`)
				local open = find("OpenOne")
				local held = view().Bag.Chests[CHEST] or 0
				t.Check("Open pressed", open ~= nil and open:IsA("TextButton") and Button.Press(open))
				t.Check("one chest opened", waitFor(t, ANSWER, function(): boolean
					return (view().Bag.Chests[CHEST] or 0) == held - 1
				end))
				t.Check("and it says so", waitFor(t, 1, function(): boolean
					for _, line in Toast.Shown() do
						if string.find(line, "^Opened 1: ") then
							return true
						end
					end
					return false
				end), table.concat(Toast.Shown(), "; "))
				-- The salvage: one step, then round to off.
				local salvage = find("Salvage")
				t.Check("the salvage's control in Chests", salvage ~= nil)
				local steps = HudConfig.Bag.Salvage
				local from = table.find(steps, view().Settings.Salvage) or 1
				for step = 1, #steps do
					local want = steps[(from - 1 + step) % #steps + 1]
					t.Check(`salvage to "{want}"`, VoidkinScreen.Tap(find("Salvage")) and waitFor(t, ANSWER, function(): boolean
						return view().Settings.Salvage == want and find("Salvage") ~= nil
					end), view().Settings.Salvage)
					t.Wait(0.1)
				end
				t.Check("and back where it was", view().Settings.Salvage == steps[from])
				-- The sort, round its three.
				t.Check("back to All", VoidkinScreen.Tap(find("All")) and Bag.State().Kind == "All")
				for _ = 1, #Rules.Sorts do
					local was = Bag.State().Sort
					t.Check(`the sort from {was}`, VoidkinScreen.Tap(find("Sort")) and Bag.State().Sort ~= was)
					t.Wait(0.1)
					gridChecks("this window", "All", Bag.State().Sort)
				end
				t.Check("round to Rarity", Bag.State().Sort == "Rarity")
				lintClean(t, "this window, Items")
				-- The smallest phone: all fourteen still, five across, every target a touch.
				Layers.Force(Theme.Scale.Floor)
				Layers.Box(Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height))
				VoidkinScreen.Show("Bag")
				t.Wait(0.2)
				dollChecks("the smallest phone")
				gridChecks("the smallest phone", "All", "Rarity")
				local grid = find("Page")
				local cells = grid and grid:FindFirstChild("Cells")
				local columns: { [number]: boolean } = {}
				local across = 0
				for _, child in (if cells then cells:GetChildren() else {}) :: { Instance } do
					if child:IsA("GuiObject") then
						local x = math.floor(child.AbsolutePosition.X + 0.5)
						if not columns[x] then
							columns[x] = true
							across += 1
						end
					end
				end
				t.Check("the smallest phone: five cells across or more", across >= math.min(5, #list), `{across}`)
				local half = find("CardRoom")
				t.Row("the smallest phone: the doll, authored px wide", nil, nil, if half then half.AbsoluteSize.X / Layers.Scale() else 0, "")
				t.Check("the smallest phone: a card opens whole", VoidkinScreen.Tap(find(weapon :: string)) and waitFor(t, 1, function(): boolean
					local shown = find("Card")
					return shown ~= nil and inView(shown) and touches(find("Equip")) and touches(find("Close"))
				end))
				-- TR36: the weapon's Strength adds Battle lines, so its card's lines scroll here, and every change still ends
				-- inside the list's window, clear of the bar (the bar's own width once clipped its last figure).
				local shownCard = find("Card")
				local cardLines = if shownCard then shownCard:FindFirstChild("Lines") else nil
				local counted, clipped = 0, 0
				if cardLines and cardLines:IsA("ScrollingFrame") then
					local right = cardLines.AbsolutePosition.X + cardLines.AbsoluteWindowSize.X
					for _, each in cardLines:GetChildren() do
						local delta = each:FindFirstChild("Change")
						if delta and delta:IsA("TextLabel") then
							counted += 1
							local ends = delta.AbsolutePosition.X + delta.AbsoluteSize.X
							clipped += if ends > right + 0.5 or delta.TextBounds.X > delta.AbsoluteSize.X + 0.5 then 1 else 0
						end
					end
				end
				local scrolls = cardLines ~= nil and cardLines:IsA("ScrollingFrame") and cardLines.AbsoluteCanvasSize.Y > cardLines.AbsoluteWindowSize.Y + 0.5
				t.Check("the smallest phone: the card's lines scroll, and every change ends inside them, clear of the bar (TR36)", scrolls and counted > 0 and clipped == 0, `scrolls {scrolls}, {clipped} of {counted} past the window`)
				lintClean(t, "the smallest phone, Items with a card")
				Layers.Box(nil)
				Layers.Force(nil)
				Screen.Close()
				-- Its own things taken back: the items it gave, what the chest gave, the chests left.
				local gone = 0
				for id in view().Items do
					if not itemsBefore[id] then
						table.insert(mine, id)
					end
				end
				for _, id in mine do
					local answer = t.Server("ItemTake", id)
					gone += if type(answer) == "table" and answer.Ok == true then 1 else 0
				end
				t.Server("ChestGive", CHEST, heldBefore - (view().Bag.Chests[CHEST] or 0))
				t.Check("its own things taken back", waitFor(t, ANSWER, function(): boolean
					for _, id in mine do
						if view().Items[id] then
							return false
						end
					end
					return (view().Bag.Chests[CHEST] or 0) == heldBefore
				end), `{gone} of {#mine} items`)
			end,
		},
		{
			Name = "Take: TR28, the Items page in A, stills held step by step: an empty kind, a full bag, a long name, another class's weapon, the chests and the smallest phone, for research's verdict",
			Manual = true,
			Stay = true,
			Run = function(t: any)
				-- Each state is held until the driver moves ReplicatedStorage.NL_TakeStep on ("Empty", "Full", "Long",
				-- "Other", "Chests", "PhoneDoll", "Phone", "End") and captures it. No night still: no day/night checks (the director,
				-- 2026-11-15). Its items and chests are its own, taken back at its end.
				local step = Instance.new("StringValue")
				step.Name = "NL_TakeStep"
				step.Value = "Ready"
				step.Parent = ReplicatedStorage
				local function await(name: string): boolean
					return waitFor(t, 180, function(): boolean
						return step.Value == name or step.Value == "End"
					end) and step.Value == name
				end
				local ids = VoidkinCases.Own(t, waitFor, ANSWER)
				local lead = view().Roles.Lead
				local owned = view().Voidkin[lead]
				local row = if owned then Voidkin.ById[owned.Def] else nil
				t.Check("a lead to dress", owned ~= nil and row ~= nil and #ids > 0)
				if owned == nil or row == nil then
					step:Destroy()
					return
				end
				-- An empty kind first, before it gives anything.
				Screen.Close()
				t.Check("the Items page opens", Button.Press(HudController.Parts().Voidkin :: TextButton) and waitFor(t, 1, function(): boolean
					local page = find("Page")
					return page ~= nil and page:GetAttribute("Page") == "Bag"
				end))
				if await("Empty") then
					local empty: string? = nil
					for _, kind in Rules.Kinds do
						if empty == nil and #Rules.List(view() :: any, view().Voidkin[lead], kind, "Rarity") == 0 then
							empty = kind
						end
					end
					t.Row("an empty kind", nil, nil, 0, empty or "none")
					VoidkinScreen.Tap(find(empty or "Gear"))
					t.Wait(0.3)
				end
				-- A full bag: one of every kind, the rarities in turn, and a chest of each tier, given once the empty kind is
				-- captured (the step held until "Full").
				local full = await("Full")
				local rarities = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }
				local mine: { string } = {}
				for index, item in Items.List do
					local answer = t.Server("ItemGive", item.Id, rarities[(index - 1) % #rarities + 1], { { Stat = if item.Class then "Attack" else "Health", Value = 40 + index * 7 } })
					if type(answer) == "table" and answer.Ok == true and type(answer.Id) == "string" then
						table.insert(mine, answer.Id)
					end
				end
				local chests: { [string]: number } = {}
				for tier = 1, 4 do
					local id = `lanternrow_{tier}`
					chests[id] = view().Bag.Chests[id] or 0
					t.Server("ChestGive", id, 2)
				end
				waitFor(t, ANSWER, function(): boolean
					for _, id in mine do
						if view().Items[id] == nil then
							return false
						end
					end
					return (view().Bag.Chests.lanternrow_4 or 0) == chests.lanternrow_4 + 2
				end)
				t.Check("its own things given", #mine == #Items.List, `{#mine} of {#Items.List}`)
				if full then
					VoidkinScreen.Tap(find("All"))
					t.Wait(0.3)
				end
				-- The longest design name among its own, chosen.
				local long, longest = nil :: string?, 0
				for _, id in mine do
					local item = view().Items[id]
					local design = if item then Items.Design(item) else nil
					if design and #design.Name > longest then
						long, longest = id, #design.Name
					end
				end
				if await("Long") then
					Bag.Choose(long)
					t.Wait(HudConfig.Bag.Slide + 0.2)
				end
				if await("Other") then
					local other: string? = nil
					for _, id in mine do
						local item = view().Items[id]
						local def = if item then Items.ById[item.Def] else nil
						if def and def.Class and def.Class ~= row.Class and other == nil then
							other = id
						end
					end
					Bag.Choose(other)
					t.Wait(HudConfig.Bag.Slide + 0.2)
				end
				if await("Chests") then
					Bag.Choose(nil)
					VoidkinScreen.Tap(find("Chests"))
					t.Wait(0.2)
					Bag.Choose("lanternrow_4")
					t.Wait(HudConfig.Bag.Slide + 0.2)
				end
				local function phone()
					Bag.Choose(nil)
					VoidkinScreen.Tap(find("All"))
					Layers.Force(Theme.Scale.Floor)
					Layers.Box(Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height))
					VoidkinScreen.Show("Bag")
					t.Wait(0.2)
				end
				if await("PhoneDoll") then
					phone() -- the doll's fourteen at the smallest phone's pitch, no card
				end
				if await("Phone") then
					phone()
					Bag.Choose(long)
					t.Wait(HudConfig.Bag.Slide + 0.2)
				end
				await("End")
				Layers.Box(nil)
				Layers.Force(nil)
				Bag.Choose(nil)
				Screen.Close()
				step:Destroy()
				for _, id in mine do
					t.Server("ItemTake", id)
				end
				for id, was in chests do
					t.Server("ChestGive", id, was - (view().Bag.Chests[id] or 0))
				end
				t.Check("its own things taken back", waitFor(t, ANSWER, function(): boolean
					for _, id in mine do
						if view().Items[id] then
							return false
						end
					end
					for id, was in chests do
						if (view().Bag.Chests[id] or 0) ~= was then
							return false
						end
					end
					return true
				end))
			end,
		},
		{
			Name = "Items page: the kinds' row and Sort in the seam's make (AR30): one channel, each chip its word's width, the chosen one the glass inset, the splits only between two unchosen, a press's word and short line; Sort's name, value and chevron at the make's places, its line on a press and while it's on; the salvage's steps the same",
			Run = function(t: any)
				local MAKE = HudConfig.Make
				local K, Q = MAKE.Chip, MAKE.Pick
				local U = MAKE.Underline
				local faint = KIT.Faint :: Color3
				Screen.Close()
				Bag.Reset()
				local hud = HudController.Parts()
				t.Check("the dock's bag opens the Items page", Button.Press(hud.Voidkin :: TextButton) and waitFor(t, 1, function(): boolean
					local page = find("Page")
					return page ~= nil and page:GetAttribute("Page") == "Bag"
				end))
				t.Wait(HudConfig.Motion.Screen.Enter + 0.1)
				local function layer(button: Instance?, name: string): ImageLabel?
					local found = if button then button:FindFirstChild(name, true) else nil
					return if found and found:IsA("ImageLabel") then found else nil
				end
				local function near(a: number, b: number, within: number?): boolean
					return math.abs(a - b) <= (within or 0.51)
				end
				local scale = Layers.Scale()
				-- The row: one channel under the chips, its edge over them and their veils.
				local row, rowEdge, kinds = find("Row"), find("RowEdge"), find("Kinds")
				local fill, edge = layer(row, "Fill"), layer(rowEdge, "Edge")
				local veil = find("VeilRight")
				t.Check("one channel: its fill in Channel at the channel's T, its edge in Edge over the chips and the veils", fill ~= nil and fill.ImageColor3 == KIT.Channel and near(fill.ImageTransparency, MAKE.Channel.Rest, 1e-3)
					and edge ~= nil and edge.ImageColor3 == KIT.Edge and rowEdge ~= nil and kinds ~= nil and veil ~= nil and rowEdge.ZIndex > kinds.ZIndex and rowEdge.ZIndex > veil.ZIndex and veil.ZIndex > kinds.ZIndex)
				t.Check("the row's height a touch, the make's 52", kinds ~= nil and near(kinds.AbsoluteSize.Y / scale, Theme.Size.Tap, 0.6))
				-- Each chip: its word's width or the least, abutting the one before.
				local chips: { GuiObject } = {}
				for _, name in Rules.Kinds do
					local one = if kinds then kinds:FindFirstChild(name) else nil
					if one and one:IsA("GuiObject") then
						table.insert(chips, one)
					end
				end
				local wrongWide, gapped = "", ""
				for index, one in chips do
					local word = one:FindFirstChild("Label") :: TextLabel?
					local want = if word then math.max(K.Least, math.ceil(Text.Wide(word, one.Name)) + K.Pad) else -1
					wrongWide = if wrongWide == "" and one.Size.X.Offset ~= want then `{one.Name} {one.Size.X.Offset}, not {want}` else wrongWide
					local before = chips[index - 1]
					if before and not near(one.AbsolutePosition.X, before.AbsolutePosition.X + before.AbsoluteSize.X, 1) then
						gapped = one.Name
					end
				end
				t.Check("five chips, each max(52, its word + 30) wide", #chips == #Rules.Kinds and wrongWide == "", wrongWide)
				t.Check("abutting in one channel, no gaps", gapped == "", gapped)
				-- The chosen one (All): the glass inset all round, its word in Text one over the middle.
				local all = chips[1]
				local allSkin = all and all:FindFirstChild("Skin", true)
				local allWord = all and all:FindFirstChild("Label") :: TextLabel?
				t.Check("All chosen: the glass at L Chosen, its word in Text", chipChosen(all))
				t.Check(`the glass inset {K.Inset} all round`, allSkin ~= nil and allSkin:IsA("GuiObject") and all ~= nil and near(allSkin.AbsoluteSize.X, all.AbsoluteSize.X - 2 * K.Inset * scale, 0.6) and near(allSkin.AbsoluteSize.Y, all.AbsoluteSize.Y - 2 * K.Inset * scale, 0.6),
					if allSkin and allSkin:IsA("GuiObject") and all then `{allSkin.AbsoluteSize} in {all.AbsoluteSize}` else "none")
				t.Check("its word one over the middle", allWord ~= nil and allWord.Position.Y.Offset == -math.round(MAKE.Word.OnOver))
				local idle = ""
				for index = 2, #chips do
					local word = chips[index]:FindFirstChild("Label") :: TextLabel?
					local plate = layer(chips[index], "Fill")
					idle = if idle == "" and not (chipIdle(chips[index]) and plate ~= nil and not plate.Visible and word ~= nil and word.Position.Y.Offset == -math.round(MAKE.Word.Over)) then chips[index].Name else idle
				end
				t.Check("the others no plate of their own, their words in Soft one over the middle", idle == "", idle)
				-- The splits: a hairline in Edge between two unchosen chips only.
				local splits = ""
				for index, one in chips do
					local split = one:FindFirstChild("Split")
					local want = index > 1 and one:GetAttribute("Chosen") ~= true and chips[index - 1]:GetAttribute("Chosen") ~= true
					local right = if want then split ~= nil and split:IsA("Frame") and split.BackgroundColor3 == KIT.Edge and near(split.BackgroundTransparency, 1 - K.Split, 1e-3) and split.Size.Y.Offset == K.SplitTall else split == nil
					splits = if splits == "" and not right then one.Name else splits
				end
				t.Check("a split in Edge, 26 tall, only between two unchosen chips", splits == "", splits)
				-- A press on an unchosen chip: its word in Text over a short line, no sink, no wash.
				local gear = chips[2]
				if gear and gear:IsA("TextButton") then
					local word = gear:FindFirstChild("Label") :: TextLabel
					local under, glow, wash = layer(gear, "Under"), layer(gear, "UnderGlow"), layer(gear, "Wash")
					local restY = word.Position.Y.Offset
					Button.Touch(gear, true)
					local span = math.round(2 * K.Under * gear.Size.X.Offset * U.Span)
					t.Check("pressed: its word in Text over its line, half 0.32 of its width", word.TextColor3 == KIT.Text and under ~= nil and under.Visible and under.Size.X.Offset == span and glow ~= nil and glow.Visible,
						if under then `{under.Visible} {under.Size.X.Offset}, want {span}` else "none")
					t.Check("the line at T 0.2, its glow at 0.6", under ~= nil and glow ~= nil and near(under.ImageTransparency, K.Line, 1e-3) and near(glow.ImageTransparency, K.Glow, 1e-3))
					t.Check("no sink, no wash", word.Position.Y.Offset == restY and wash ~= nil and not wash.Visible)
					Button.Touch(gear, false)
					t.Check("let go: back to Soft, no line", word.TextColor3 == KIT.Soft and under ~= nil and not under.Visible)
				else
					t.Check("Gear's chip", false, "none")
				end
				-- Sort: the channel, its words + 44 wide; "Sort:" from 15 in, the value Gap after it, the chevron 15 in from the right.
				local function pickChecks(name: string, words: string, value: string, on: boolean)
					local pick = find(name)
					local named = pick and pick:FindFirstChild("PickName", true) :: TextLabel?
					local word = pick and pick:FindFirstChild("Label") :: TextLabel?
					local chevron = layer(pick, "Chevron")
					if not (pick and pick:IsA("TextButton") and named and word and chevron) then
						t.Check(`{name}: its name, value and chevron`, false, "missing")
						return
					end
					local nameWide, valueWide = Text.Wide(named, words), Text.Wide(word, value)
					local wide = math.ceil(nameWide + Q.Gap + valueWide) + Q.Pad
					t.Check(`{name}: "{words}" then "{value}", {wide} wide (its words + {Q.Pad})`, named.Text == words and word.Text == value and pick.Size.X.Offset == wide, `{named.Text} {word.Text} {pick.Size.X.Offset}`)
					local left = pick.AbsolutePosition.X
					local mid = pick.AbsolutePosition.Y + pick.AbsoluteSize.Y / 2
					local inkLeft = word.AbsolutePosition.X + (word.AbsoluteSize.X - word.TextBounds.X) / 2
					t.Check(`{name}: its name from {Q.In} in, its value {Q.Gap} after it`, near(named.AbsolutePosition.X, left + Q.In * scale, 1) and near(inkLeft, left + (Q.In + nameWide + Q.Gap) * scale, 1.5),
						`{(named.AbsolutePosition.X - left) / scale}, {(inkLeft - left) / scale}`)
					t.Check(`{name}: the chevron {Q.In} in from the right, {Q.Drop} under the middle`, near(chevron.AbsolutePosition.X + chevron.AbsoluteSize.X / 2, left + pick.AbsoluteSize.X - Q.In * scale, 1) and near(chevron.AbsolutePosition.Y + chevron.AbsoluteSize.Y / 2, mid + Q.Drop * scale, 1))
					local under, glow, wash = layer(pick, "Under"), layer(pick, "UnderGlow"), layer(pick, "Wash")
					local colour = if on then KIT.Light :: Color3 else KIT.Text
					t.Check(`{name}: its name in Soft, its value and chevron in {if on then "the light" else "Text"}`, named.TextColor3 == KIT.Soft and word.TextColor3 == colour and chevron.ImageColor3 == colour)
					local span = math.round(2 * Q.Under * pick.Size.X.Offset * U.Span)
					if on then
						t.Check(`{name} on: its line half 0.3 of its width, at T 0.2, its glow 0.52`, under ~= nil and glow ~= nil and under.Visible and under.Size.X.Offset == span and near(under.ImageTransparency, Q.Line[1], 1e-3) and near(glow.ImageTransparency, Q.Glow[1], 1e-3))
					else
						t.Check(`{name} at its first step: no line`, under ~= nil and not under.Visible)
					end
					local restY = word.Position.Y.Offset
					Button.Touch(pick, true)
					t.Check(`{name} pressed: its line at T 0, its glow 0.4, no sink, no wash`, under ~= nil and glow ~= nil and under.Visible and under.Size.X.Offset == span and near(under.ImageTransparency, Q.Line[2], 1e-3) and near(glow.ImageTransparency, Q.Glow[2], 1e-3)
						and word.Position.Y.Offset == restY and wash ~= nil and not wash.Visible)
					Button.Touch(pick, false)
					t.Check(`{name}: the channel, its fill at T {MAKE.Channel.Rest}`, pick:GetAttribute("Kind") == "Channel" and layer(pick, "Fill") ~= nil and near((layer(pick, "Fill") :: ImageLabel).ImageTransparency, MAKE.Channel.Rest, 1e-3))
					local row_ = find("Kinds") -- the row as rebuilt by the last tap
					local rowRight = if row_ then row_.AbsolutePosition.X + row_.AbsoluteSize.X else 0
					t.Check(`{name}: right of the row by a gap`, near(left - rowRight, Theme.Size.Gap * scale, 1), `{(left - rowRight) / scale}`)
					-- Unavailable: everything in Faint, then put back.
					Button.Set(pick, { Disabled = "test" })
					t.Check(`{name} unavailable: its name, value and chevron in Faint, no line`, named.TextColor3 == faint and word.TextColor3 == faint and chevron.ImageColor3 == faint and under ~= nil and not under.Visible and word.Text == value)
					Button.Set(pick, { Disabled = false })
				end
				pickChecks("Sort", "Sort:", Bag.State().Sort, false)
				t.Check("a tap: the next sort, on", VoidkinScreen.Tap(find("Sort")) and Bag.State().Sort == Rules.Sorts[2])
				t.Wait(0.1)
				pickChecks("Sort", "Sort:", Rules.Sorts[2], true)
				for _ = 3, #Rules.Sorts + 1 do
					VoidkinScreen.Tap(find("Sort"))
					t.Wait(0.1)
				end
				t.Check("round to the first", Bag.State().Sort == Rules.Sorts[1])
				-- Chests: the salvage's steps in the same make, on while it turns anything into Credits.
				t.Check("Chests", VoidkinScreen.Tap(find("Chests")) and Bag.State().Kind == "Chests")
				t.Wait(0.1)
				local below = view().Settings.Salvage
				pickChecks("Salvage", "Salvage:", if below == "" then "Off" else below, below ~= "")
				local chests = find("Chests")
				t.Check("Chests chosen: the glass, its neighbours unsplit", chipChosen(chests) and chests ~= nil and chests:FindFirstChild("Split") == nil and (find("Materials") :: Instance):FindFirstChild("Split") == nil)
				-- A row that scrolls shows that it scrolls (research's must-fix): its fade reaches past a chip's half pad, so
				-- a whole chip at the edge fades too; and a row scrolled to show the chosen chip ends on its neighbour, cut.
				t.Check("the row's fade reaches past a chip's half pad", HudConfig.Bag.Veil >= K.Pad / 2 + 8, `{HudConfig.Bag.Veil}`)
				local rowNow, materials = find("Kinds"), find("Materials")
				if rowNow and rowNow:IsA("ScrollingFrame") and rowNow.CanvasPosition.X > 1 and materials and materials:IsA("GuiObject") and chests and chests:IsA("GuiObject") then
					local rowEnd = rowNow.AbsolutePosition.X + rowNow.AbsoluteWindowSize.X
					local shown = rowEnd - materials.AbsolutePosition.X
					t.Check("scrolled to Chests: it stands whole, and Peek of Materials beside it, cut by the edge", chests.AbsolutePosition.X >= rowNow.AbsolutePosition.X - 0.5 and near(shown, materials.AbsoluteSize.X * HudConfig.Bag.Peek, 1.5) and find("VeilRight") ~= nil and (find("VeilRight") :: GuiObject).Visible, `shown {shown} of {materials.AbsoluteSize.X}`)
				end
				VoidkinScreen.Tap(find("All"))
				Bag.Reset()
				Screen.Close()
			end,
		},
	}
end

return BagCases
