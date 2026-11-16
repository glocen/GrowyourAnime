--!strict
-- The Items page's case (TR28, AR18's C, "the case"): the case right of the rail, the belt, the six kinds, the grid on
-- Rules.Bag's own list, the up arrow, the worn tick and another class's dim, a card sliding over the Voidkin's half, Equip
-- and Take off through the server, a chest's card and Open, the sort and the salvage; then the smallest phone, where the
-- belt shows one group and every target holds a touch. The items and chests it gives are its own, taken back at its end
-- (Studio's ItemGive, ItemTake and ChestGive), so the save is left as it was.

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local HudConfig = require(Shared.Config.Hud)
local Profile = require(Shared.Data.Profile)
local Items = require(Shared.Definitions.Items)
local Voidkin = require(Shared.Definitions.Voidkin)
local Rules = require(Shared.Rules.Bag)
local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local ProfileController = require(script.Parent.Parent.ProfileController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Layers = require(UI.Layers)
local Screen = require(UI.Kit.Screen)
local Button = require(UI.Kit.Button)
local Toast = require(UI.Kit.Toast)
local VoidkinScreen = require(UI.VoidkinScreen)
local VoidkinCases = require(script.Parent.VoidkinCases)

local BagCases = {}

export type Given = {
	ANSWER: number,
	waitFor: (t: any, seconds: number, ok: () -> boolean) -> boolean,
	lintClean: (t: any, where: string) -> (),
}

local CHEST = "lanternrow_1"

local function view(): Profile.View
	return ProfileController.Get() :: Profile.View
end

local function find(name: string): GuiObject?
	local found = VoidkinScreen.Find(name)
	return if found and found:IsA("GuiObject") then found else nil
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
			Name = "Items page (TR28): C's case, the belt, the six kinds, the grid on Rules.Bag's list, the card over the Voidkin's half, Equip and Take off, a chest opened, the sort and the salvage, then the smallest phone",
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
				local weapon = give(weaponFor(class, true), "Epic", { { Stat = "Attack", Value = 999 }, { Stat = "Might", Value = 20 } })
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
				for _, name in { "Rail", "Case", "Belt", "Strip", "Page", "Over", "Totals", "CardRoom", "BagCount" } do
					t.Check(`{name} in view`, inView(find(name)))
				end
				local count, page = find("BagCount"), find("Page")
				t.Check("the count says the bag's held, pinned outside the grid's scroll (TR28's call 3)", count ~= nil and page ~= nil and count:GetAttribute("Held") == Rules.Held(view() :: any) and not count:IsDescendantOf(page))
				-- The belt: all fourteen where they stand at a touch, each slot a touch.
				local function beltChecks(where: string)
					local whole = Bag.State().Whole
					local belt = find("Belt")
					local shown = 0
					local small = ""
					for _, slots in Rules.Groups do
						for _, slot in slots do
							local piece = if belt then belt:FindFirstChild(slot) else nil
							if piece and piece:IsA("GuiObject") then
								shown += 1
								if not (touches(piece) and inView(piece)) then
									small = slot
								end
							end
						end
					end
					if whole then
						t.Check(`{where}: all fourteen slots on the belt`, shown == 14, `{shown}`)
					else
						local group = Bag.State().Group or 0
						local chips = 0
						for index = 1, 3 do
							chips += if belt and belt:FindFirstChild(`Group{index}`) then 1 else 0
						end
						t.Check(`{where}: one group on the belt, a chip for each of the others`, group > 0 and shown == #Rules.Groups[group] and chips == 2, `group {group}, {shown} slots, {chips} chips`)
					end
					t.Check(`{where}: every slot shown a touch or more, {Theme.Size.Touch} rendered px, whole`, small == "", small)
					local kinds = find("Kinds")
					local cut = ""
					for _, kind in Rules.Kinds do
						local chip = if kinds then kinds:FindFirstChild(kind) else nil
						if not (chip and chip:IsA("GuiObject") and chip.AbsoluteSize.Y >= Theme.Size.Touch - 0.5) then
							cut = kind
						end
					end
					t.Check(`{where}: the six kinds, each a touch tall`, cut == "", cut)
					local chosen = if kinds then kinds:FindFirstChild(Bag.State().Kind) else nil
					t.Check(`{where}: the chosen kind's chip in view`, chosen ~= nil and chosen:IsA("GuiObject") and kinds ~= nil and chosen.AbsolutePosition.X >= kinds.AbsolutePosition.X - 1 and chosen.AbsolutePosition.X + chosen.AbsoluteSize.X <= kinds.AbsolutePosition.X + kinds.AbsoluteSize.X + 1)
				end
				beltChecks("this window")
				-- The grid is Rules.Bag's list, in its order, each cell saying what the list says.
				local function gridChecks(where: string, kind: string, sort: string)
					local list = Rules.List(view() :: any, view().Voidkin[lead], kind, sort)
					local grid = find("Page")
					local cells = grid and grid:FindFirstChild("Cells")
					local right, wrong = 0, ""
					for index, entry in list do
						local cell = cells and cells:FindFirstChild(entry.Id)
						local ok = cell ~= nil and cell:IsA("GuiObject") and cell.LayoutOrder == index and cell:GetAttribute("Up") == entry.Up and cell:GetAttribute("Worn") == (entry.Worn or "") and cell:GetAttribute("Fits") == entry.Fits and cell:GetAttribute("Count") == entry.Count and (cell:FindFirstChild("Up") ~= nil) == entry.Up and (cell:FindFirstChild("WornMark") ~= nil) == (entry.Worn ~= nil)
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
				-- A tap: its card slides over the Voidkin's half, and the slot it would fill is ringed on the belt.
				t.Check("a tap on the weapon chooses it", VoidkinScreen.Tap(find(weapon :: string)) and Bag.State().Chosen == weapon)
				t.Wait(HudConfig.Bag.Slide + 0.1)
				local card = find("Card")
				local room = find("CardRoom")
				t.Check("its card over the Voidkin's half, slid in", card ~= nil and card:GetAttribute("For") == weapon and room ~= nil and math.abs(card.AbsolutePosition.X - room.AbsolutePosition.X) <= 1 and inView(card))
				local info = Rules.Card(view() :: any, view().Voidkin[lead], weapon :: string)
				local power = find("Power")
				local said = if card then card:FindFirstChild("Power", true) else nil
				t.Check("its Combat Power change is the comparison's", info ~= nil and said ~= nil and said:GetAttribute("Power") == info.Power and info.Power > 0, if info then `{info.Power}` else "none")
				local target = find("Main Hand")
				local ring = target and target:FindFirstChild("Target")
				t.Check("the Main Hand ringed on the belt", ring ~= nil and ring:IsA("UIStroke") and ring.Enabled)
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
				-- The worn slot on the belt opens it; Take off takes it off.
				t.Check("a tap on the belt's Main Hand opens what it wears", VoidkinScreen.Tap(find("Main Hand")) and Bag.State().Chosen == weapon)
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
				t.Check("the close shuts the card", VoidkinScreen.Tap(find("Close")) and Bag.State().Chosen == nil)
				-- The kinds: each shows its own list.
				for _, kind in { "Weapons", "Jewellery", "Chests" } do
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
				-- The smallest phone: one group on the belt, five across, every target a touch.
				Layers.Force(Theme.Scale.Floor)
				Layers.Box(Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height))
				VoidkinScreen.Show("Bag")
				t.Wait(0.2)
				beltChecks("the smallest phone")
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
				t.Row("the smallest phone: the Voidkin's half, authored px wide", nil, nil, if half then half.AbsoluteSize.X / Layers.Scale() else 0, "")
				t.Check("the smallest phone: a card opens whole", VoidkinScreen.Tap(find(weapon :: string)) and waitFor(t, 1, function(): boolean
					local shown = find("Card")
					return shown ~= nil and inView(shown) and touches(find("Equip")) and touches(find("Close"))
				end))
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
	}
end

return BagCases
