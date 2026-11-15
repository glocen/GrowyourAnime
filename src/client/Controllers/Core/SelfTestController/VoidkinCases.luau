--!strict
-- VoidkinCases (client, Studio only): the Voidkin screen's case (TR17, the director's full-screen layout), a list of its
-- own beside Cases, which joins it as it joins Takes. On the screen as it stands at home (Stay): opened from the dock,
-- full screen over a cover that hides the world and the HUD, Back, its marks and the currencies in Roblox's band, its
-- name and rarity on one line over the stage, the figure whole under it at its measured share, the twelve shared slots
-- in two columns of six and its class's two hands either side of Combat Power, the rail's seven taps whole where they
-- fit, each page from its rail button (the chosen one larger and lit), on the save's numbers, Lead and Send to work over
-- the panel (the lead's lit, its work off with why under its name), favourite and lock set and cleared, a switch by the
-- strip and by a flick, a switch to a body still being fetched (the one shown stays with its panel), a tap's flourish,
-- a turn, one sent to work and brought home, a rename, the UI lint in this window and on the smallest phone, and Back.
-- VoidkinCases.Own gives the account Rook, Pip and Lyric when it lacks them, for this and the takes.

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local HudConfig = require(Shared.Config.Hud)
local VoidkinConfig = require(Shared.Config.Voidkin)
local Profile = require(Shared.Data.Profile)
local Stats = require(Shared.Rules.Stats)
local Hud = require(Shared.Rules.Hud)
local Voidkin = require(Shared.Definitions.Voidkin)
local Gear = require(Shared.Definitions.Gear)
local Shards = require(Shared.Definitions.Shards)
local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local ProfileController = require(script.Parent.Parent.ProfileController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Layers = require(UI.Layers)
local Read = require(UI.Read)
local Screen = require(UI.Kit.Screen)
local Button = require(UI.Kit.Button)
local Toast = require(UI.Kit.Toast)
local VoidkinScreen = require(UI.VoidkinScreen)
local Figure = require(UI.VoidkinScreen.Figure)

local VoidkinCases = {}

local DEFS = { "rook", "pip", "lyric" } -- the three with their own bodies and Reveals

export type Given = {
	ANSWER: number,
	REPLICATE: number,
	waitFor: (t: any, seconds: number, ok: () -> boolean) -> boolean,
	lintClean: (t: any, where: string) -> (),
}

type WaitFor = (t: any, seconds: number, ok: () -> boolean) -> boolean

-- The account's Voidkin, lead first, given Rook, Pip and Lyric when it lacks one.
function VoidkinCases.Own(t: any, waitFor: WaitFor, answer: number): { string }
	for _, def in DEFS do
		local view = ProfileController.Get()
		local has = false
		for _, owned in (if view then view.Voidkin else {}) :: { [string]: Profile.OwnedVoidkin } do
			has = has or owned.Def == def
		end
		if not has then
			local given = t.Server("VoidkinGive", def)
			local id = if type(given) == "table" and given.Ok == true then given.Id else nil
			if type(id) == "string" then
				waitFor(t, answer, function(): boolean
					local now = ProfileController.Get()
					return now ~= nil and now.Voidkin[id] ~= nil
				end)
			end
		end
	end
	local ids = {}
	local view = ProfileController.Get()
	for _, owned in (if view then Read.Roster(view) else {}) :: { Profile.OwnedVoidkin } do
		table.insert(ids, owned.Id)
	end
	return ids
end

-- The figure's crown and soles as shares of its stage's height, from the stage camera's own framing.
local function framed(figure: Figure.Figure): (number, number)
	local camera = figure.View.CurrentCamera :: Camera
	local at, size = figure.Body:GetBoundingBox()
	local half = math.tan(math.rad(camera.FieldOfView) / 2)
	local function share(y: number): number
		local rel = camera.CFrame:PointToObjectSpace(Vector3.new(at.Position.X, y, at.Position.Z))
		return 0.5 - (rel.Y / -rel.Z) / (2 * half)
	end
	return share(at.Position.Y + size.Y / 2), share(at.Position.Y - size.Y / 2)
end

-- A piece of the open screen that shows, whole, inside the screen's frame, or inside the band when it stands there.
local function inView(name: string): boolean
	local frame: GuiObject? = Screen.Frame(VoidkinScreen.Name)
	local piece = VoidkinScreen.Find(name)
	if frame == nil or piece == nil or not piece:IsA("GuiObject") then
		return false
	end
	local band = Layers.Get("Band")
	if piece:IsDescendantOf(band) then
		frame = band
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

local function labelOf(button: Instance?): string
	local label = button and button:FindFirstChild("Label", true)
	return if label and label:IsA("TextLabel") then label.Text else ""
end

local function button(name: string): TextButton?
	local found = VoidkinScreen.Find(name)
	return if found and found:IsA("TextButton") then found else nil
end

-- A rail button by its page's name.
local function railButton(name: string): TextButton?
	local rail = VoidkinScreen.Find("Rail")
	local found = rail and rail:FindFirstChild(name)
	return if found and found:IsA("TextButton") then found else nil
end

-- A column's slots, top to bottom.
local function slotsOf(column: Instance?): { Frame }
	local slots: { Frame } = {}
	for _, child in (if column then column:GetChildren() else {}) :: { Instance } do
		if child:IsA("Frame") and child:GetAttribute("Slot") ~= nil then
			table.insert(slots, child)
		end
	end
	table.sort(slots, function(a: Frame, b: Frame): boolean
		return a.AbsolutePosition.Y < b.AbsolutePosition.Y
	end)
	return slots
end

function VoidkinCases.Cases(given: Given): { any }
	local ANSWER = given.ANSWER
	local waitFor, lintClean = given.waitFor, given.lintClean

	-- The figure whole between the stage's top and Combat Power's plate, and its share of the screen's height noted.
	local function whole(t: any, where: string)
		local figure = VoidkinScreen.Figure()
		local plate = VoidkinScreen.Find("Power")
		t.Check(`{where}: a figure on the stage`, figure ~= nil)
		if figure == nil or plate == nil or not plate:IsA("GuiObject") then
			return
		end
		local crown, soles = framed(figure)
		local stage = figure.Stage
		local solesAt = stage.AbsolutePosition.Y + soles * stage.AbsoluteSize.Y
		t.Check(`{where}: its crown under the stage's top`, crown >= 0, string.format("%.3f", crown))
		local name = VoidkinScreen.Find("Name")
		if name and name:IsA("GuiObject") then
			local crownAt, foot = stage.AbsolutePosition.Y + crown * stage.AbsoluteSize.Y, name.AbsolutePosition.Y + name.AbsoluteSize.Y
			t.Check(`{where}: its crown under its name's line`, crownAt >= foot - 1, string.format("%.0f against %.0f", crownAt, foot))
		else
			t.Check(`{where}: its name's line over the stage`, false)
		end
		t.Check(`{where}: its soles over Combat Power`, solesAt <= plate.AbsolutePosition.Y + 1, string.format("%.0f against %.0f", solesAt, plate.AbsolutePosition.Y))
		local room = Layers.Get("Menus").AbsoluteSize.Y
		t.Row(`{where}: the figure's share of the screen's height`, nil, nil, (soles - crown) * stage.AbsoluteSize.Y / room, "")
		local framedFor = VoidkinScreen.Measure()
		t.Row(`{where}: framed for, on a stage {math.floor(framedFor.Stage)} authored px tall, its {figure.Studs} studs`, nil, nil, framedFor.Height, "")
	end

	-- The gear round the figure: two columns of six, the twelve shared in their order, and its class's hands at its feet.
	local function gear(t: any, where: string, class: string)
		local figure = VoidkinScreen.Figure()
		local scale = Layers.Scale()
		local side = VoidkinScreen.Measure().Slot
		local middle = if figure then figure.Stage.AbsolutePosition.X + figure.Stage.AbsoluteSize.X / 2 else 0
		for index, name in { "LeftSlots", "RightSlots" } do
			local column = VoidkinScreen.Find(name)
			local slots = slotsOf(column)
			t.Check(`{where}: {name} holds six slots`, #slots == 6, `{#slots}`)
			local named, square, beside = true, true, true
			for at, slot in slots do
				named = named and slot.Name == Gear.Shared[(index - 1) * 6 + at]
				square = square and math.abs(slot.AbsoluteSize.X - side * scale) <= 1 and math.abs(slot.AbsoluteSize.Y - side * scale) <= 1
				local centre = slot.AbsolutePosition.X + slot.AbsoluteSize.X / 2
				beside = beside and (if index == 1 then centre < middle else centre > middle)
			end
			t.Check(`{where}: {name} in the shared order, top to bottom`, named)
			local apart, spaced = HudConfig.Voidkin.Slots.Gap, true
			for at = 2, #slots do
				local between = slots[at].AbsolutePosition.Y - (slots[at - 1].AbsolutePosition.Y + slots[at - 1].AbsoluteSize.Y)
				spaced = spaced and math.abs(between - apart * scale) <= 1
			end
			t.Check(`{where}: {name}'s slots {apart} authored px apart`, spaced)
			t.Check(`{where}: {name}'s slots square, {side} authored px`, square)
			t.Check(`{where}: {name} {if index == 1 then "left" else "right"} of the figure`, beside)
			local stage = if figure then figure.Stage else nil
			local last = slots[#slots]
			t.Check(`{where}: {name} inside the stage`, stage ~= nil and last ~= nil and slots[1].AbsolutePosition.Y >= stage.AbsolutePosition.Y - 1 and last.AbsolutePosition.Y + last.AbsoluteSize.Y <= stage.AbsolutePosition.Y + stage.AbsoluteSize.Y + 1)
		end
		t.Row(`{where}: a slot's side, rendered px (the reference's about 46, the mock's 40)`, nil, nil, side * scale, "")
		local feet = VoidkinScreen.Find("Feet")
		local main, off = feet and feet:FindFirstChild("Main Hand"), feet and feet:FindFirstChild("Off Hand")
		local plate = VoidkinScreen.Find("Power")
		if main and off and plate and main:IsA("GuiObject") and off:IsA("GuiObject") and plate:IsA("GuiObject") then
			t.Check(`{where}: Main Hand takes its class's weapon`, main:GetAttribute("Kind") == Gear.Kind("Main Hand", class), tostring(main:GetAttribute("Kind")))
			t.Check(`{where}: Off Hand takes its class's`, off:GetAttribute("Kind") == Gear.Kind("Off Hand", class), tostring(off:GetAttribute("Kind")))
			t.Check(`{where}: Main Hand left of Combat Power, clear of it`, main.AbsolutePosition.X + main.AbsoluteSize.X <= plate.AbsolutePosition.X + 1)
			t.Check(`{where}: Off Hand right of it, clear of it`, off.AbsolutePosition.X >= plate.AbsolutePosition.X + plate.AbsoluteSize.X - 1)
			local foot = plate.AbsolutePosition.Y + plate.AbsoluteSize.Y
			t.Check(`{where}: the three on one foot line`, math.abs(main.AbsolutePosition.Y + main.AbsoluteSize.Y - foot) <= 1 and math.abs(off.AbsolutePosition.Y + off.AbsoluteSize.Y - foot) <= 1)
			t.Row(`{where}: a hand's side, rendered px (the mock's 46)`, nil, nil, main.AbsoluteSize.X, "")
			t.Row(`{where}: Combat Power's plate, authored px wide`, nil, nil, VoidkinScreen.Measure().Power, "")
		else
			t.Check(`{where}: its two hands and Combat Power at its feet`, false)
		end
	end

	-- Its name over the stage: one line between the two slot columns, its rarity after it, whole, in the rarity's colour.
	local function nameLine(t: any, where: string, owned: Profile.OwnedVoidkin?)
		local name = VoidkinScreen.Find("Name")
		local title, rarity = name and name:FindFirstChild("Title"), name and name:FindFirstChild("Rarity")
		local row = if owned then Voidkin.ById[owned.Def] else nil
		if not (owned and row and name and name:IsA("GuiObject") and title and title:IsA("TextLabel") and rarity and rarity:IsA("TextLabel")) then
			t.Check(`{where}: its name and its rarity over the stage`, false)
			return
		end
		t.Check(`{where}: its name`, title.Text == Read.VoidkinName(owned), title.Text)
		t.Check(`{where}: its rarity, in the rarity's colour`, rarity.Text == row.Rarity and rarity.TextColor3 == HudConfig.Card.Trim[row.Rarity], rarity.Text)
		local left, right = VoidkinScreen.Find("LeftSlots"), VoidkinScreen.Find("RightSlots")
		local from = if left and left:IsA("GuiObject") then left.AbsolutePosition.X + left.AbsoluteSize.X else math.huge
		local to = if right and right:IsA("GuiObject") then right.AbsolutePosition.X else -math.huge
		t.Check(`{where}: on one line between the slot columns`, name.AbsolutePosition.X >= from - 1 and name.AbsolutePosition.X + name.AbsoluteSize.X <= to + 1, string.format("%.0f to %.0f in %.0f to %.0f", name.AbsolutePosition.X, name.AbsolutePosition.X + name.AbsoluteSize.X, from, to))
		t.Check(`{where}: the name first, its rarity after it, whole in the line`, title.AbsolutePosition.X + title.AbsoluteSize.X <= rarity.AbsolutePosition.X + 1 and rarity.TextFits and rarity.AbsolutePosition.X + rarity.AbsoluteSize.X <= name.AbsolutePosition.X + name.AbsoluteSize.X + 1, string.format("%.0f, %.0f, %.0f", title.AbsoluteSize.X, rarity.AbsoluteSize.X, name.AbsoluteSize.X))
		t.Row(`{where}: the name's line, authored px wide (its name {if title.TextFits then "whole" else "cut"})`, nil, nil, name.AbsoluteSize.X / Layers.Scale(), "")
	end

	-- The lead's Send to work: off, its own name kept and why under it, both whole on its face.
	local function leadsWork(t: any, where: string)
		local work = button("Work")
		local label, reason = work and work:FindFirstChild("Label", true), work and work:FindFirstChild("Reason", true)
		if work and label and label:IsA("TextLabel") and reason and reason:IsA("TextLabel") then
			t.Check(`{where}: the lead's Send to work is off`, Button.State(work) == "Disabled", Button.State(work))
			t.Check(`{where}: it keeps its name`, label.Text == "Send to work" and label.TextFits, label.Text)
			t.Check(`{where}: and says why under it`, reason.Visible and reason.Text == "Not while leading" and reason.TextFits and reason.AbsolutePosition.Y >= label.AbsolutePosition.Y and reason.AbsolutePosition.Y + reason.AbsoluteSize.Y <= work.AbsolutePosition.Y + work.AbsoluteSize.Y + 1, reason.Text)
		else
			t.Check(`{where}: the lead's Send to work, its name and why`, false)
		end
	end

	local case = {
		Name = "Voidkin screen (TR17): full screen, Back, its marks and the currencies in Roblox's band, its name over one Voidkin between its gear slots, the rail's seven pages, the bag, its power, its actions over the panel, switched by the strip and a flick",
		Stay = true,
		Run = function(t: any)
			local ids = VoidkinCases.Own(t, waitFor, ANSWER)
			t.Check("three Voidkin to switch between", #ids >= 3, `{#ids}`)
			if #ids < 3 then
				return
			end
			Screen.Close()
			local hud = HudController.Parts()
			t.Check("the dock's Voidkin opens it", Button.Press(hud.Voidkin :: TextButton) and waitFor(t, 1, function(): boolean
				return Screen.Current() == VoidkinScreen.Name
			end))
			t.Wait(HudConfig.Motion.Screen.Enter + 0.1)
			-- Full screen: its frame is the whole room, over a cover that hides the world and the HUD edge to edge.
			local frame = Screen.Frame(VoidkinScreen.Name)
			local room = Layers.Get("Menus")
			t.Check("its frame fills the screens' room", frame ~= nil and (frame.AbsoluteSize - room.AbsoluteSize).Magnitude <= 2, if frame then `{frame.AbsoluteSize} in {room.AbsoluteSize}` else "none")
			local cover = Screen.Cover(VoidkinScreen.Name)
			local window = (workspace.CurrentCamera :: Camera).ViewportSize
			t.Check("a cover behind it, opaque", cover ~= nil and cover.BackgroundTransparency <= 0.01, if cover then string.format("%.2f", cover.BackgroundTransparency) else "none")
			t.Check("over the whole window", cover ~= nil and cover.AbsoluteSize.X >= window.X - 1 and cover.AbsoluteSize.Y >= window.Y - 1 and cover.AbsolutePosition.X <= 1 and cover.AbsolutePosition.Y <= 1, if cover then `{cover.AbsoluteSize} of {window}` else "none")
			t.Check("and it takes the taps of what it hides", cover ~= nil and cover.Active)
			-- Roblox's band: Back first, the marks beside it, the currencies at its right, none over another.
			local band = Layers.Get("Band")
			local inset = GuiService.TopbarInset
			t.Check("the band is the top bar's free room", math.abs(band.AbsoluteSize.X - inset.Width) <= 2 and math.abs(band.AbsoluteSize.Y - inset.Height) <= 2 and band.AbsoluteSize.Y > 0, `{band.AbsoluteSize} of {inset.Width}, {inset.Height}`)
			local across: { GuiObject } = {}
			for _, name in { "Back", "Favourite", "Lock", "Rename", "Wallet" } do
				local piece = VoidkinScreen.Find(name)
				t.Check(`{name} in the band, whole`, piece ~= nil and piece:IsDescendantOf(band) and inView(name))
				if piece and piece:IsA("GuiObject") then
					table.insert(across, piece)
				end
			end
			local order, touch = #across == 5, true
			for at = 2, #across do
				order = order and across[at - 1].AbsolutePosition.X + across[at - 1].AbsoluteSize.X <= across[at].AbsolutePosition.X + 1
			end
			for at = 1, math.min(#across, 4) do
				touch = touch and across[at].AbsoluteSize.X >= Theme.Size.Touch - 0.5 and across[at].AbsoluteSize.Y >= Theme.Size.Touch - 0.5
			end
			t.Check("Back, favourite, lock, rename, then the currencies, left to right, none over another", order)
			t.Check(`Back and each mark a touch or more, {Theme.Size.Touch} rendered px`, touch)
			local view = ProfileController.Get() :: Profile.View
			local lead = view.Roles.Lead
			t.Check("on the lead", VoidkinScreen.Chosen() == lead, tostring(VoidkinScreen.Chosen()))
			local owned = view.Voidkin[lead]
			local figure = VoidkinScreen.Figure()
			local row = if owned then Voidkin.ById[owned.Def] else nil
			local body = if row and row.Model then row.Model else "StandIn"
			t.Check("its own body on the stage", figure ~= nil and figure.Body.Name == body, if figure then figure.Body.Name else "no figure")
			t.Check("on its Idle", figure ~= nil and figure.Idle ~= nil and (figure.Idle :: AnimationTrack).IsPlaying)
			whole(t, "this window")
			gear(t, "this window", if row then row.Class else "")
			if owned then
				local block = Stats.Resolve(owned, Stats.PresetOf(view :: any, owned), view :: any)
				local number = VoidkinScreen.Find("Number")
				local said = if number and number:IsA("TextLabel") then number.Text else "none"
				t.Check("Combat Power at its feet, from its stats", said == Hud.Digits(Stats.Power(block)), said)
				-- Its digits in cobalt (AR12; Config.Hud.Voidkin.Finish): the ramp's stops, the stroke, the drop saying the
				-- same a stroke lower, the glow behind, the caption's colour.
				local finish = HudConfig.Voidkin.Finish
				local plate = VoidkinScreen.Find("Power")
				local drop = if number then (number.Parent :: Instance):FindFirstChild("Drop") :: TextLabel? else nil
				local metal = if number then number:FindFirstChildOfClass("UIGradient") else nil
				local keys = if metal then metal.Color.Keypoints else {}
				local ramp = #keys == #finish.Stops
				for index, key in keys do
					local want = finish.Colours[index]
					ramp = ramp and want ~= nil and math.abs(key.Time - finish.Stops[index]) < 1e-3 and (Vector3.new(key.Value.R, key.Value.G, key.Value.B) - Vector3.new(want.R, want.G, want.B)).Magnitude < 1e-2
				end
				t.Check("its digits wear the cobalt ramp", ramp, `{#keys} stops`)
				local stroke = if number then number:FindFirstChildOfClass("UIStroke") else nil
				t.Check("stroked in ink", stroke ~= nil and stroke.Color == finish.Stroke and math.abs(stroke.Thickness - finish.Line) < 1e-3)
				local lower = if drop and number then (drop.AbsolutePosition.Y - (number :: GuiObject).AbsolutePosition.Y) / Layers.Scale() else 0
				t.Check("its drop says the same, a stroke lower", drop ~= nil and number ~= nil and drop.Text == said and drop.TextColor3 == finish.Stroke and math.abs(lower - finish.Drop) < 0.05, string.format("%.2f points lower", lower))
				local glow = if plate then plate:FindFirstChild("Glow", true) :: ImageLabel? else nil
				t.Check("a soft glow behind them", glow ~= nil and glow.ImageColor3 == finish.Glow and math.abs(glow.ImageTransparency - (1 - finish.GlowAlpha)) < 1e-3)
				local caption = if plate then plate:FindFirstChild("Caption") :: TextLabel? else nil
				t.Check("its caption in its colour", caption ~= nil and caption.TextColor3 == finish.Caption and caption.Text == "COMBAT POWER")
			end
			for _, name in { "Rail", "Name", "Panel", "Strip", "Lead", "Work" } do
				t.Check(`{name} in view`, inView(name))
			end
			local opened = VoidkinScreen.Find("Page")
			t.Check("it opens on the bag", opened ~= nil and opened:GetAttribute("Page") == "Bag", tostring(opened and opened:GetAttribute("Page")))
			local pages = VoidkinScreen.Find("Rail")
			local bagPage = pages and pages:FindFirstChild("Bag", true)
			local word = bagPage and bagPage:FindFirstChild("Label")
			t.Check("whose page reads Items on the rail, its gear tab Gear", word ~= nil and word:IsA("TextLabel") and word.Text == "Items" and table.find(VoidkinScreen.Kinds, "Gear") ~= nil and table.find(VoidkinScreen.Kinds, "Items") == nil, if word and word:IsA("TextLabel") then word.Text else "no word")
			-- Its name over the stage: one line between the slot columns, its rarity after it in the rarity's colour.
			nameLine(t, "this window", owned)
			-- The rail: all seven taps whole, each a touch or more, and no scroll.
			local strung = VoidkinScreen.Find("Rail")
			if strung and strung:IsA("ScrollingFrame") then
				local top, foot = strung.AbsolutePosition.Y, strung.AbsolutePosition.Y + strung.AbsoluteSize.Y
				local fits, taps, last = true, true, top
				for _, name in VoidkinScreen.Pages do
					local each = railButton(name)
					fits = fits and each ~= nil and each.AbsolutePosition.Y >= last - 1 and each.AbsolutePosition.Y + each.AbsoluteSize.Y <= foot + 1
					taps = taps and each ~= nil and each.AbsoluteSize.Y >= Theme.Size.Touch - 0.5
					last = if each then each.AbsolutePosition.Y + each.AbsoluteSize.Y else last
				end
				t.Check("the rail holds all seven taps whole, one under another", fits and strung:GetAttribute("Whole") == true)
				t.Check("with no scroll", not strung.ScrollingEnabled)
				t.Check(`each a touch or more tall, {Theme.Size.Touch} rendered px`, taps)
			else
				t.Check("the rail", false)
			end
			local leads, works, panel = button("Lead"), button("Work"), VoidkinScreen.Find("Panel")
			if leads and works and panel and panel:IsA("GuiObject") then
				local top, left, right = panel.AbsolutePosition.Y, panel.AbsolutePosition.X, panel.AbsolutePosition.X + panel.AbsoluteSize.X
				t.Check("Lead and Send to work out of the panel, on the line over it", leads.AbsolutePosition.Y + leads.AbsoluteSize.Y <= top + 1 and works.AbsolutePosition.Y + works.AbsoluteSize.Y <= top + 1)
				t.Check("Lead first, Send to work beside it, in the panel's column", leads.AbsolutePosition.X >= left - 1 and leads.AbsolutePosition.X + leads.AbsoluteSize.X <= works.AbsolutePosition.X and works.AbsolutePosition.X + works.AbsoluteSize.X <= right + 1)
			else
				t.Check("Lead and Send to work out of the panel, on the line over it", false)
			end
			local wallet = VoidkinScreen.Find("Wallet")
			local credits = wallet and wallet:FindFirstChild("Credits")
			local value = credits and credits:FindFirstChild("Value")
			t.Check("the band's Credits, the save's", value ~= nil and value:IsA("TextLabel") and value.Text == Read.Number(view.Currency.Credits), if value and value:IsA("TextLabel") then value.Text else "none")
			-- The lead: its Lead lit and reading Leading, its Send to work off, its name kept and why under it.
			t.Check("the lead's own reads Leading", labelOf(leads) == "Leading", labelOf(leads))
			t.Check("lit, not greyed", leads ~= nil and Button.State(leads) == "Selected", if leads then Button.State(leads) else "none")
			leadsWork(t, "this window")
			-- A tap on a column: the way to the gear page, which isn't built.
			t.Check("a tap on the left column is taken", VoidkinScreen.Tap(VoidkinScreen.Find("LeftSlots")) and table.find(Toast.Shown(), "Gear isn't built yet") ~= nil, table.concat(Toast.Shown(), "; "))
			-- Each page from its rail button, on the save's numbers; one not built yet says so and keeps the page.
			local rail = HudConfig.Voidkin.Rail
			t.Check("the rail holds every page", table.concat(VoidkinScreen.Pages, ", ") == "Overview, Bag, Kit, Stars, Forge, Jewels, War Emblems", table.concat(VoidkinScreen.Pages, ", "))
			for _, name in VoidkinScreen.Pages do
				if VoidkinScreen.Soon[name] then
					local before = VoidkinScreen.Find("Page")
					local was = before and before:GetAttribute("Page")
					local greyed = railButton(name)
					t.Check(`{name}, not built: greyed, and reads Soon`, greyed ~= nil and greyed:GetAttribute("Soon") == true and labelOf(greyed) == "Soon", labelOf(greyed))
					t.Check(`a tap on it says so`, VoidkinScreen.Tap(greyed) and table.find(Toast.Shown(), `{name}: soon`) ~= nil, table.concat(Toast.Shown(), "; "))
					local after, still = VoidkinScreen.Find("Page"), railButton(name)
					t.Check(`and the page stays, never an empty one`, after ~= nil and after:GetAttribute("Page") == was and still ~= nil and still:GetAttribute("Chosen") == false, tostring(after and after:GetAttribute("Page")))
					continue
				end
				t.Check(`the rail's {name} takes a tap`, VoidkinScreen.Tap(railButton(name)))
				t.Wait(rail.Run + 0.15)
				local chosen = railButton(name)
				local dot = chosen and chosen:FindFirstChild("Dot")
				local ring = dot and dot:FindFirstChild("Ring")
				t.Check(`{name} chosen`, chosen ~= nil and chosen:GetAttribute("Chosen") == true)
				t.Check(`its ring lit`, ring ~= nil and ring:IsA("UIStroke") and ring.Color == Theme.Colour.Primary)
				local larger, alone, words = true, true, true
				for _, other in VoidkinScreen.Pages do
					local rest = railButton(other)
					local restDot = rest and rest:FindFirstChild("Dot")
					if other ~= name and rest and restDot and restDot:IsA("GuiObject") and dot and dot:IsA("GuiObject") then
						larger = larger and dot.AbsoluteSize.X > restDot.AbsoluteSize.X + 4
						alone = alone and rest:GetAttribute("Chosen") == false
					end
					words = words and labelOf(rest) == (if other == name then VoidkinScreen.Said[name] or name elseif VoidkinScreen.Soon[other] then "Soon" else "")
				end
				t.Check(`larger than the six at rest, and the only one chosen`, larger and alone)
				t.Check(`only its word shows, and Soon under those not built`, words)
				local lit = VoidkinScreen.Find("Lit")
				if lit and lit:IsA("GuiObject") and dot and dot:IsA("GuiObject") then
					local reach = lit.AbsolutePosition.Y + lit.AbsoluteSize.Y
					local centre = dot.AbsolutePosition.Y + dot.AbsoluteSize.Y / 2
					t.Check(`the line lit down to it`, math.abs(reach - centre) <= 2, string.format("%.0f against %.0f", reach, centre))
				else
					t.Check(`the line lit down to it`, false)
				end
				local scroll = VoidkinScreen.Find("Page")
				t.Check(`the panel shows {name}`, scroll ~= nil and scroll:GetAttribute("Page") == name)
				local lines = 0
				for _, child in (if scroll then scroll:GetChildren() else {}) :: { Instance } do
					lines += if child:IsA("GuiObject") then 1 else 0
				end
				t.Check(`{name} shows its lines`, lines > 0, `{lines}`)
				if scroll and owned then
					if name == "Overview" then
						local now = scroll:FindFirstChild("Now")
						local under = now and now:FindFirstChild("Under")
						t.Check("Overview: the lead's Now reads Leading", under ~= nil and (under :: TextLabel).Text == "Leading", if under then (under :: TextLabel).Text else "none")
						local worn = scroll:FindFirstChild(`Gear · preset {owned.Preset}`)
						local pair = worn and worn:FindFirstChild("Under")
						local class = if row then row.Class else ""
						t.Check("Overview: its preset and its class's pair", pair ~= nil and pair:IsA("TextLabel") and string.find(pair.Text, Gear.Kind("Main Hand", class), 1, true) ~= nil and string.find(pair.Text, Gear.Kind("Off Hand", class), 1, true) ~= nil, if pair and pair:IsA("TextLabel") then pair.Text else "none")
						-- Its whole stat sheet is here: there's no Stats page.
						local block = Stats.Resolve(owned, Stats.PresetOf(view :: any, owned), view :: any)
						for _, stat in { "Health", "Attack", "Defence" } do
							local item = scroll:FindFirstChild(stat)
							local right = item and item:FindFirstChild("Right")
							t.Check(`Overview: its {stat}, resolved`, right ~= nil and (right :: TextLabel).Text == Hud.Digits((block :: any)[stat]), if right then (right :: TextLabel).Text else "none")
						end
						t.Check("Overview: its Speed", scroll:FindFirstChild("Speed") ~= nil)
					elseif name == "Bag" then
						local kinds = VoidkinScreen.Find("Kinds")
						local tabs = true
						local cut = ""
						for _, kind in VoidkinScreen.Kinds do
							local tab = kinds and kinds:FindFirstChild(kind)
							local want = if VoidkinScreen.Held[kind] then "" else "Soon"
							tabs = tabs and tab ~= nil and tab:IsA("TextButton") and tab:GetAttribute("Disabled") == want
							if kinds and kinds:IsA("GuiObject") and tab and tab:IsA("GuiObject") then
								local left = tab.AbsolutePosition.X - kinds.AbsolutePosition.X
								if left < -0.5 or left + tab.AbsoluteSize.X > kinds.AbsoluteSize.X + 0.5 then
									cut = kind
								end
							end
						end
						t.Check("Bag: a tab for each kind, those not held yet greyed with Soon", tabs)
						t.Check("Bag: every tab whole in its row, none cut", kinds ~= nil and not kinds:IsA("ScrollingFrame") and cut == "", cut)
						local shards = kinds and kinds:FindFirstChild("Shards")
						t.Check("Bag: on Shards", shards ~= nil and shards:IsA("TextButton") and Button.State(shards) == "Selected")
						local bag = (ProfileController.Get() :: Profile.View).Bag.Shards
						local held, total = 0, 0
						for _, count in bag do
							held += if count > 0 then 1 else 0
							total += count
						end
						t.Check("Bag: its count of shards, the save's", scroll:FindFirstChild(if total == 1 then "1 shard" else `{Hud.Digits(total)} shards`) ~= nil, `{total}`)
						local cells = scroll:FindFirstChild("Cells")
						local shown, right, first = 0, true, nil :: TextButton?
						for _, cell in (if cells then cells:GetChildren() else {}) :: { Instance } do
							if cell:IsA("TextButton") then
								shown += 1
								right = right and cell:GetAttribute("Count") == bag[cell.Name]
								first = first or cell
							end
						end
						t.Check("Bag: a cell for each shard held, with its count", shown == held and right, `{shown} of {held}`)
						if first then
							-- AR12: its grade's picture, the size's own (Rules.Hud.ShardPicture).
							local picture = first:FindFirstChild("Picture", true)
							local grade = if Shards.ById[first.Name] then Shards.ById[first.Name].Grade else "Standard"
							local art = HudConfig.ShardArt
							local want = Hud.ShardPicture(grade, Theme.Size.Tap * art.Cell, art.Large)
							t.Check("Bag: a cell wears its grade's picture", picture ~= nil and picture:GetAttribute("Kit") == want, if picture then tostring(picture:GetAttribute("Kit")) else "none")
							local said = `{Read.ShardName(first.Name)} ×{Hud.Digits(bag[first.Name])}`
							t.Check("Bag: a tap on a cell names it", VoidkinScreen.Tap(first) and table.find(Toast.Shown(), said) ~= nil, table.concat(Toast.Shown(), "; "))
						end
					elseif name == "Kit" then
						local signature = false
						for _, child in scroll:GetChildren() do
							signature = signature or string.find(child.Name, "^Signature · ") ~= nil
						end
						t.Check("Kit: its signature by name", signature)
					elseif name == "Stars" then
						local pips = scroll:FindFirstChild("Pips")
						local count = 0
						for _, child in (if pips then pips:GetChildren() else {}) :: { Instance } do
							count += if child:IsA("Frame") then 1 else 0
						end
						t.Check(`Stars: {VoidkinConfig.MaxStars} pips`, count == VoidkinConfig.MaxStars, `{count}`)
					end
				end
				for _, kept in { "Lead", "Work" } do
					t.Check(`{name}: {kept} still in view`, inView(kept))
				end
			end
			-- Combat Power's tap: where it comes from.
			t.Check("a tap on Combat Power is taken", VoidkinScreen.Tap(VoidkinScreen.Find("Power")))
			local shown = VoidkinScreen.Find("Page")
			t.Check("and shows Overview, where its stats are", shown ~= nil and shown:GetAttribute("Page") == "Overview" and shown:FindFirstChild("Health") ~= nil)
			-- Favourite and lock, set and cleared on the server.
			for _, mark in { { Name = "Favourite", Field = "Favourite" }, { Name = "Lock", Field = "Locked" } } do
				local before = ((ProfileController.Get() :: Profile.View).Voidkin[lead] :: any)[mark.Field] == true
				for _, want in { not before, before } do
					Button.Press(button(mark.Name) :: TextButton)
					t.Check(`{mark.Name}: {if want then "set" else "cleared"} in the save`, waitFor(t, ANSWER, function(): boolean
						local now = ProfileController.Get()
						return now ~= nil and (now.Voidkin[lead] :: any)[mark.Field] == want
					end))
					t.Check(`{mark.Name}: its button shows it`, waitFor(t, 1, function(): boolean
						local found = button(mark.Name)
						return found ~= nil and (Button.State(found) == "Selected") == want
					end))
				end
			end
			-- Never an empty stage: a switch to a body still being fetched keeps the one shown, with its panel, and both
			-- change once it's in memory.
			for _, def in DEFS do
				waitFor(t, 5, function(): boolean
					return Figure.Ready(def)
				end)
				t.Check(`{def}'s body in memory behind the screen, within 5 s of the open`, Figure.Ready(def))
			end
			do
				local id = ids[3]
				local def = (ProfileController.Get() :: Profile.View).Voidkin[id].Def
				local leadDef = (ProfileController.Get() :: Profile.View).Voidkin[lead].Def
				local title = VoidkinScreen.Find("Title")
				local was = if title and title:IsA("TextLabel") then title.Text else ""
				Figure.Hold(def)
				VoidkinScreen.Choose(id)
				t.Wait(0.2)
				local held, kept = VoidkinScreen.Figure(), VoidkinScreen.Find("Title")
				t.Check("a body being fetched: the one shown stays on the stage", VoidkinScreen.Chosen() == lead and held ~= nil and held.Def == leadDef and held.Body.Parent ~= nil, tostring(VoidkinScreen.Chosen()))
				t.Check("with its own name, and the next one awaited", VoidkinScreen.Awaited() == id and kept ~= nil and kept:IsA("TextLabel") and kept.Text == was, tostring(VoidkinScreen.Awaited()))
				local asked = button(id)
				t.Check("the tap answered: the awaited one's cell lit on the strip", asked ~= nil and Button.State(asked) == "Selected", if asked then Button.State(asked) else "none")
				Figure.Release(def)
				local next, named = VoidkinScreen.Figure(), VoidkinScreen.Find("Title")
				t.Check("fetched: the figure and its name change in the one beat", VoidkinScreen.Chosen() == id and VoidkinScreen.Awaited() == nil and next ~= nil and next.Def == def and named ~= nil and named:IsA("TextLabel") and named.Text == Read.VoidkinName((ProfileController.Get() :: Profile.View).Voidkin[id]), tostring(VoidkinScreen.Chosen()))
				VoidkinScreen.Choose(lead)
				t.Wait(HudConfig.Voidkin.Figure.Back + 0.1)
			end
			-- The strip: the second, then the third.
			for index = 2, 3 do
				local id = ids[index]
				local cell = button(id)
				t.Check(`the strip's cell {index} pressed`, cell ~= nil and Button.Press(cell))
				local def = (ProfileController.Get() :: Profile.View).Voidkin[id].Def
				t.Check(`and Voidkin {index} on the stage`, waitFor(t, 1, function(): boolean
					local now = VoidkinScreen.Figure()
					return VoidkinScreen.Chosen() == id and now ~= nil and now.Def == def
				end), tostring(VoidkinScreen.Chosen()))
				local chosen = button(id)
				t.Check(`its cell marked`, chosen ~= nil and Button.State(chosen) == "Selected")
				local class = (Voidkin.ById[def] :: Voidkin.Row).Class
				local main = VoidkinScreen.Find("Main Hand")
				t.Check(`its Main Hand takes a {Gear.Kind("Main Hand", class)}`, main ~= nil and main:GetAttribute("Kind") == Gear.Kind("Main Hand", class), tostring(main and main:GetAttribute("Kind")))
			end
			-- A flick: the left brings the next (round to the first), the right the one before.
			local swipe = HudConfig.Voidkin.Swipe
			for _, step in { { Delta = -(swipe.Distance + 30), Want = ids[3 % #ids + 1] }, { Delta = swipe.Distance + 30, Want = ids[3] } } do
				local now = VoidkinScreen.Figure()
				local kind = if now then Figure.Gesture(now, Vector2.new(step.Delta, 6), swipe.Time / 2) else "none"
				t.Check(`a flick of {step.Delta} px is a swipe`, kind == "Swipe", kind)
				t.Check(`and goes to {step.Want}`, waitFor(t, 1, function(): boolean
					return VoidkinScreen.Chosen() == step.Want
				end), tostring(VoidkinScreen.Chosen()))
			end
			-- A tap plays the end of its Reveal; a drag turns it.
			t.Wait(HudConfig.Voidkin.Figure.Back + 0.1)
			local now = VoidkinScreen.Figure()
			t.Check("a tap is a tap", now ~= nil and Figure.Gesture(now, Vector2.new(2, 1), swipe.TapTime / 2) == "Tap")
			t.Check("and plays its flourish", now ~= nil and now.Reveal ~= nil and (now.Reveal :: AnimationTrack).IsPlaying)
			local slow = if now then Figure.Gesture(now, Vector2.new(swipe.Distance + 30, 0), swipe.Time * 3) else "none"
			t.Check("a slow drag across only turns it", slow == "Turn" and VoidkinScreen.Chosen() == ids[3], slow)
			if now then
				local from = now.Yaw
				Figure.Turn(now, 40)
				local _, yaw = now.Body:GetPivot():ToEulerAnglesYXZ()
				t.Check("turned 40°", math.abs(((from + 40) % 360) - now.Yaw) < 1e-6 and math.abs(math.deg(yaw) - ((from + 40 + 180) % 360 - 180)) < 0.5, string.format("%.1f°", math.deg(yaw)))
			end
			-- One sent to work and brought home (or, every bay busy, home and back).
			local current = ProfileController.Get() :: Profile.View
			local free: string?, worker: string?, working = nil, nil, 0
			for _, id in ids do
				local at = Read.Role(current, id)
				free = free or (if at == "" then id else nil)
				local bay = tonumber(string.match(at, "^Bay (%d+)$"))
				if bay and worker == nil then
					worker, working = id, bay
				end
			end
			local _, empty = Hud.WorkReason("", current.Base.Bays)
			local function role(id: string, want: string): boolean
				return waitFor(t, ANSWER, function(): boolean
					local after = ProfileController.Get()
					return after ~= nil and Read.Role(after, id) == want
				end)
			end
			local function shows(want: string): boolean
				return waitFor(t, 1, function(): boolean
					return labelOf(button("Work")) == want
				end)
			end
			if free and empty then
				VoidkinScreen.Choose(free)
				t.Check("Send to work", Button.Press(button("Work") :: TextButton) and role(free, `Bay {empty}`))
				t.Check("and its button brings it home", shows("Bring home"), labelOf(button("Work")))
				t.Check("Bring home", Button.Press(button("Work") :: TextButton) and role(free, ""))
			elseif worker then
				VoidkinScreen.Choose(worker)
				t.Check("every bay busy: a worker reads Bring home", labelOf(button("Work")) == "Bring home", labelOf(button("Work")))
				t.Check("Bring home", Button.Press(button("Work") :: TextButton) and role(worker, ""))
				t.Check("and its button sends it", shows("Send to work"), labelOf(button("Work")))
				t.Check("Send to work, to the bay it left", Button.Press(button("Work") :: TextButton) and role(worker, `Bay {working}`))
			else
				t.Check("a Voidkin to send or to bring home", false)
			end
			-- A rename: the line a box, Save and Cancel in the band; tidied, through the filter; then taken off.
			VoidkinScreen.Choose(lead)
			local own = (Voidkin.ById[(ProfileController.Get() :: Profile.View).Voidkin[lead].Def] :: Voidkin.Row).Name
			for _, try in { { Typed = "  Test   Name ", Want = "Test Name" }, { Typed = "", Want = "" } } do
				t.Check(`Rename opens its box (to {if try.Want == "" then "take it off" else try.Want})`, Button.Press(button("Rename") :: TextButton) and waitFor(t, 1, function(): boolean
					return VoidkinScreen.Find("NameBox") ~= nil
				end))
				local box = VoidkinScreen.Find("NameBox")
				t.Check("Save and Cancel in the band, in the marks' place", inView("Save") and inView("Cancel") and VoidkinScreen.Find("Rename") == nil)
				if box and box:IsA("TextBox") then
					box:ReleaseFocus()
					box.Text = try.Typed
					t.Check("Save", Button.Press(button("Save") :: TextButton))
					t.Check(`the save's nickname "{try.Want}"`, waitFor(t, ANSWER, function(): boolean
						local after = ProfileController.Get()
						return after ~= nil and after.Voidkin[lead].Nickname == try.Want
					end), tostring(((ProfileController.Get() :: Profile.View).Voidkin[lead]).Nickname))
					t.Check("the box closed", waitFor(t, 1, function(): boolean
						return VoidkinScreen.Find("NameBox") == nil
					end))
					local named = VoidkinScreen.Find("Name")
					local title = named and named:FindFirstChild("Title")
					local read = if title and title:IsA("TextLabel") then title.Text else "none"
					t.Check(`the name reads {if try.Want == "" then own else try.Want}`, read == (if try.Want == "" then own else try.Want), read)
					t.Check("the marks back in the band", inView("Rename") and VoidkinScreen.Find("Save") == nil)
				end
			end
			-- The UI lint, in this window and on the smallest phone, on every page.
			t.Wait(0.3)
			lintClean(t, "this window")
			Layers.Force(Theme.Scale.Floor)
			Layers.Box(Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height))
			t.Wait(0.1)
			local leadRow = Voidkin.ById[(ProfileController.Get() :: Profile.View).Voidkin[lead].Def]
			for _, name in VoidkinScreen.Pages do
				if not VoidkinScreen.Soon[name] then
					VoidkinScreen.Show(name) -- built again at the phone's size
					t.Wait(rail.Run + 0.15)
					lintClean(t, `the smallest phone, {name}`)
				end
			end
			whole(t, "the smallest phone")
			gear(t, "the smallest phone", if leadRow then leadRow.Class else "")
			nameLine(t, "the smallest phone", (ProfileController.Get() :: Profile.View).Voidkin[lead])
			leadsWork(t, "the smallest phone")
			for _, name in { "Back", "Favourite", "Lock", "Rename", "Wallet" } do
				t.Check(`the smallest phone: {name} in the band, whole`, inView(name))
			end
			local purse = VoidkinScreen.Find("Wallet")
			t.Row(`the smallest phone: the band, authored px wide (the battery {if purse and purse:GetAttribute("Short") then "without" else "with"} its capacity)`, nil, nil, Layers.Band().X, "")
			-- Seven taps are taller than the rail: the built pages stand whole in it before any scroll, the rest a scroll down.
			local holder = VoidkinScreen.Find("Rail")
			if holder and holder:IsA("ScrollingFrame") then
				holder.CanvasPosition = Vector2.zero
				t.Wait(0.05)
				local top, foot = holder.AbsolutePosition.Y, holder.AbsolutePosition.Y + holder.AbsoluteSize.Y
				local fits = true
				for _, name in VoidkinScreen.Pages do
					local each = railButton(name)
					if not VoidkinScreen.Soon[name] then
						fits = fits and each ~= nil and each.AbsolutePosition.Y >= top - 1 and each.AbsolutePosition.Y + each.AbsoluteSize.Y <= foot + 1
					end
				end
				t.Check("the smallest phone: every built page's button whole in the rail before any scroll", fits)
				local last = railButton(VoidkinScreen.Pages[#VoidkinScreen.Pages])
				t.Check("the smallest phone: the rail scrolls down to its last button", last ~= nil and holder.AbsoluteCanvasSize.Y > holder.AbsoluteWindowSize.Y and last.AbsolutePosition.Y + last.AbsoluteSize.Y - top <= holder.AbsoluteCanvasSize.Y + 1)
				t.Row(`the smallest phone: the rail's seven taps, authored px, in a window of {math.floor(holder.AbsoluteWindowSize.Y / Layers.Scale())}`, nil, nil, holder.AbsoluteCanvasSize.Y / Layers.Scale(), "")
			else
				t.Check("the smallest phone: the rail scrolls", false)
			end
			Layers.Box(nil)
			Layers.Force(nil)
			t.Wait(0.1)
			-- Back: closed at once, the HUD's taps its own again, the cover gone with the screen.
			local exit = button("Back")
			t.Check("Back closes it", exit ~= nil and Button.Press(exit) and Screen.Current() == nil)
			local leaving = Screen.Cover(VoidkinScreen.Name)
			t.Check("the cover lets taps through at once", leaving == nil or not leaving.Active)
			t.Wait(HudConfig.Motion.Screen.Exit + 0.15)
			t.Check("and is gone with the screen, its band too", Screen.Cover(VoidkinScreen.Name) == nil and Screen.Stage(VoidkinScreen.Name) == nil and Screen.Band(VoidkinScreen.Name) == nil)
		end,
	}

	return { case }
end

return VoidkinCases
