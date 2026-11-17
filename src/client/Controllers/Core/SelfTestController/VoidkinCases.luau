--!strict
-- VoidkinCases (client, Studio only): the Voidkin screen's case (TR17, the director's full-screen layout), a list of its
-- own beside Cases, which joins it as it joins Takes. On the screen as it stands at home (Stay): opened from the dock,
-- full screen over a cover that hides the world and the HUD, Back, its marks and the currencies in Roblox's band, its
-- name and rarity on one line over the stage, the figure whole under it at its measured share, no gear slot and Combat
-- Power alone at its feet (the director, 2026-11-17), the rail's seven taps whole where they
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
local Sheet = require(Shared.Rules.Sheet)
local Growth = require(Shared.Rules.Growth)
local Hud = require(Shared.Rules.Hud)
local Voidkin = require(Shared.Definitions.Voidkin)
local Gear = require(Shared.Definitions.Gear)
local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local ProfileController = require(script.Parent.Parent.ProfileController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Layers = require(UI.Layers)
local Read = require(UI.Read)
local Screen = require(UI.Kit.Screen)
local Button = require(UI.Kit.Button)
local Toast = require(UI.Kit.Toast)
local Bar = require(UI.Kit.Bar)
local VoidkinScreen = require(UI.VoidkinScreen)
local Figure = require(UI.VoidkinScreen.Figure)
local Seam = require(UI.VoidkinScreen.Seam)
local UIKit = require(Shared.Config.UIKit)

local VoidkinCases = {}

local DEFS = { "rook", "pip", "lyric" } -- the three with their own bodies and Reveals
local SETTLE = 0.15 -- seconds for a page shown to be built again

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

-- The figure's stage as drawn: its light's colours, its fill, its halo, its disc, and whether a warm glow stands in it.
-- The same on every page (TR24, the director's run, fix 4).
local function stageLook(): string
	local shown = VoidkinScreen.Find("Figure")
	local stage = if shown and shown:IsA("ViewportFrame") then shown.Parent else nil
	if shown == nil or not (stage and stage:IsA("Frame")) then
		return "no stage"
	end
	local light, halo, disc = stage:FindFirstChild("Light"), stage:FindFirstChild("Halo"), shown:FindFirstChild("Floor", true)
	local keys = {}
	if light and light:IsA("UIGradient") then
		for _, key in light.Color.Keypoints do
			table.insert(keys, key.Value:ToHex())
		end
	end
	return string.format("light %s, fill %.2f, halo %s, disc %s, warm %s", table.concat(keys, "-"), stage.BackgroundTransparency,
		if halo and halo:IsA("Frame") and halo.Visible then halo.BackgroundColor3:ToHex() else "none",
		if disc and disc:IsA("BasePart") then string.format("%s %.2f %.2f", disc.Color:ToHex(), disc.Transparency, disc.Size.Z) else "none",
		tostring(stage:FindFirstChild("Warm") ~= nil))
end

-- A colour of the lacquer's family, the Items page's before TR24's fix 4: a warm brown or a brass, never a rarity's light
-- (Legendary's gold and its lights are bright).
local function lacquered(colour: Color3): boolean
	local h, s, v = colour:ToHSV()
	return h >= 15 / 360 and h <= 50 / 360 and s >= 0.15 and v <= 0.8
end

-- The graphite the screen wore before the seam (TR28): the theme's colours and the Graphite palette's, by their hex.
local GRAPHITE: { [string]: boolean } = {}
local function grey(colour: any)
	if typeof(colour) == "Color3" then
		GRAPHITE[(colour :: Color3):ToHex()] = true
	end
end
for _, colour in Theme.Colour :: { [string]: any } do
	grey(colour)
end
for _, value in UIKit.Palettes.Graphite :: { [string]: any } do
	for _, colour in (if type(value) == "table" then value else { value }) :: { any } do
		grey(colour)
	end
end
GRAPHITE[Theme.Colour.Heal:ToHex()] = nil -- a gain's green stays the game's

-- The first graphite colour drawn under each root: a fill, a tint, a word, an edge, a gradient's key.
local function graphiteIn(roots: { Instance? }): string
	for _, root in roots do
		for _, piece in (if root then root:GetDescendants() else {}) :: { Instance } do
			local found: Color3? = nil
			if piece:IsA("GuiObject") and piece.Visible and piece.BackgroundTransparency < 1 and GRAPHITE[piece.BackgroundColor3:ToHex()] then
				found = piece.BackgroundColor3
			elseif piece:IsA("ImageLabel") and piece.Visible and piece.ImageTransparency < 1 and GRAPHITE[piece.ImageColor3:ToHex()] then
				found = piece.ImageColor3
			elseif piece:IsA("TextLabel") and piece.Visible and piece.Text ~= "" and piece.TextTransparency < 1 and GRAPHITE[piece.TextColor3:ToHex()] then
				found = piece.TextColor3
			elseif piece:IsA("UIStroke") and piece.Enabled and piece.Transparency < 1 and GRAPHITE[piece.Color:ToHex()] then
				found = piece.Color
			end
			if found then
				return `{piece:GetFullName():match("[^.]+%.[^.]+$") or piece.Name} {found:ToHex()}`
			end
		end
	end
	return ""
end

-- The screen's own pieces: its frame, its cover and its band's Back (the wallet's pills beside it stay the HUD's).
local function screenRoots(): { Instance? }
	return { Screen.Frame("Voidkin"), Screen.Cover("Voidkin"), VoidkinScreen.Find("Back") }
end

-- The first colour of the lacquer's family drawn under `root`: a fill, a tint, a word, an edge, a gradient's key.
local function lacquerIn(root: Instance): string
	for _, piece in root:GetDescendants() do
		local found: Color3? = nil
		if piece:IsA("GuiObject") and piece.Visible and piece.BackgroundTransparency < 1 and lacquered(piece.BackgroundColor3) then
			found = piece.BackgroundColor3
		elseif piece:IsA("ImageLabel") and piece.ImageTransparency < 1 and lacquered(piece.ImageColor3) then
			found = piece.ImageColor3
		elseif piece:IsA("TextLabel") and piece.Text ~= "" and lacquered(piece.TextColor3) then
			found = piece.TextColor3
		elseif piece:IsA("UIStroke") and piece.Enabled and lacquered(piece.Color) then
			found = piece.Color
		elseif piece:IsA("UIGradient") then
			for _, key in piece.Color.Keypoints do
				found = if lacquered(key.Value) then key.Value else found
			end
		end
		if found then
			return `{piece.Name} {found:ToHex()}`
		end
	end
	return ""
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

	-- No gear slot anywhere on the Overview (the director, 2026-11-17: "overview ui shouldn't show any gears slot"), and
	-- Combat Power alone at its feet, under the figure's middle.
	local function feet(t: any, where: string)
		local frame = Screen.Frame("Voidkin")
		local slot = ""
		for _, item in (if frame then frame:GetDescendants() else {}) :: { Instance } do
			if slot == "" and item:IsA("GuiObject") and (item:GetAttribute("Slot") ~= nil or item.Name == "LeftSlots" or item.Name == "RightSlots") then
				slot = item.Name
			end
		end
		t.Check(`{where}: no gear slot on the screen`, frame ~= nil and slot == "", slot)
		local figure = VoidkinScreen.Figure()
		local row = VoidkinScreen.Find("Feet")
		local plate = VoidkinScreen.Find("Power")
		if figure and row and plate and plate:IsA("GuiObject") then
			local middle = figure.Stage.AbsolutePosition.X + figure.Stage.AbsoluteSize.X / 2
			local centre = plate.AbsolutePosition.X + plate.AbsoluteSize.X / 2
			t.Check(`{where}: Combat Power under the figure's middle, to a pixel's rounding`, math.abs(centre - middle) <= 2, string.format("%.1f against %.1f", centre, middle))
			t.Check(`{where}: alone at its feet`, #row:GetChildren() == 1, `{#row:GetChildren()}`)
			t.Row(`{where}: Combat Power's plate, authored px wide`, nil, nil, VoidkinScreen.Measure().Power, "")
		else
			t.Check(`{where}: Combat Power at its feet`, false)
		end
	end

	-- Its name over the stage: one line inside it, its rarity after it, whole, in the rarity's colour.
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
		local figure = VoidkinScreen.Figure()
		local stage = if figure then figure.Stage else nil
		local from = if stage then stage.AbsolutePosition.X else math.huge
		local to = if stage then stage.AbsolutePosition.X + stage.AbsoluteSize.X else -math.huge
		t.Check(`{where}: on one line inside the stage`, name.AbsolutePosition.X >= from - 1 and name.AbsolutePosition.X + name.AbsoluteSize.X <= to + 1, string.format("%.0f to %.0f in %.0f to %.0f", name.AbsolutePosition.X, name.AbsolutePosition.X + name.AbsoluteSize.X, from, to))
		t.Check(`{where}: the name first, its rarity after it, whole in the line`, title.AbsolutePosition.X + title.AbsoluteSize.X <= rarity.AbsolutePosition.X + 1 and rarity.TextFits and rarity.AbsolutePosition.X + rarity.AbsoluteSize.X <= name.AbsolutePosition.X + name.AbsoluteSize.X + 1, string.format("%.0f, %.0f, %.0f", title.AbsoluteSize.X, rarity.AbsoluteSize.X, name.AbsoluteSize.X))
		t.Row(`{where}: the name's line, authored px wide (its name {if title.TextFits then "whole" else "cut"})`, nil, nil, name.AbsoluteSize.X / Layers.Scale(), "")
	end

	-- The band clear (research's must-fix on TR28, 2026-11-17: no top-bar overlap on any page or phone): the wallet right
	-- of everything else in it, and each of its chips' words whole.
	local function bandClear(t: any, where: string)
		local wallet = VoidkinScreen.Find("Wallet")
		local band = if wallet then wallet.Parent else nil
		local reach, last = -math.huge, "nothing"
		for _, item in (if band then band:GetDescendants() else {}) :: { Instance } do
			if item:IsA("GuiObject") and item.Visible and item.Parent == band and item ~= wallet and item.AbsoluteSize.X > 0 then
				local right = item.AbsolutePosition.X + item.AbsoluteSize.X
				if right > reach then
					reach, last = right, item.Name
				end
			end
		end
		local from, cut = math.huge, ""
		for _, chip in (if wallet then wallet:GetChildren() else {}) :: { Instance } do
			if chip:IsA("GuiObject") and chip.Visible then
				from = math.min(from, chip.AbsolutePosition.X)
				local value = chip:FindFirstChild("Value")
				if value and value:IsA("TextLabel") and not value.TextFits then
					cut = chip.Name
				end
			end
		end
		t.Check(`{where}: the band clear, the wallet right of {last}`, wallet ~= nil and from >= reach - 0.5, string.format("%.0f against %.0f (%s)", from, reach, tostring(wallet and wallet:GetAttribute("Form"))))
		t.Check(`{where}: the wallet's words whole`, wallet ~= nil and cut == "", cut)
	end

	-- The lead's page: "Leading" with its mark alone across the line, in the rail's chosen tab's light; no Station, since
	-- the page's own state rules it out (research's ruling on the director's remark, 2026-11-17).
	local function leadsWork(t: any, where: string)
		local leads = button("Lead")
		local row = leads and leads.Parent
		t.Check(`{where}: no Station on the lead's page`, button("Work") == nil)
		if leads and row and row:IsA("GuiObject") then
			local label = leads:FindFirstChild("Label") :: TextLabel?
			local mark = label and label:FindFirstChild("Mark") :: ImageLabel?
			t.Check(`{where}: Leading across the line`, math.abs(leads.AbsoluteSize.X - row.AbsoluteSize.X) <= 1, `{leads.AbsoluteSize.X} of {row.AbsoluteSize.X}`)
			t.Check(`{where}: its word whole, its mark beside it`, label ~= nil and label.Text == "Leading" and label.TextFits and mark ~= nil and mark.Visible)
			t.Check(`{where}: in the chosen tab's light, not a dim glass`, leads:GetAttribute("Kind") == "Plate", tostring(leads:GetAttribute("Kind")))
		else
			t.Check(`{where}: the lead's Leading`, false)
		end
	end

	local case = {
		Name = "Voidkin screen (TR17): full screen, Back, its marks and the currencies in Roblox's band, its name over one Voidkin, the rail's built pages (AR29's B: the seam), the bag, its power, its actions over the panel, switched by the strip and a flick",
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
			-- AR29's B: Back with no plate, its chevron and BACK over its line; the marks in one channel, three equal cells.
			local back = button("Back")
			local plateFill = back and back:FindFirstChild("Fill", true)
			local chevron = back and back:FindFirstChild("Icon", true)
			local backWord = back and back:FindFirstChild("Word", true)
			t.Check("Back bare: no plate, its chevron, BACK and its line", plateFill ~= nil and plateFill:IsA("ImageLabel") and not plateFill.Visible and chevron ~= nil and chevron:GetAttribute("Kit") == "Back" and backWord ~= nil and backWord:IsA("TextLabel") and backWord.Text == "BACK" and back ~= nil and back:FindFirstChild("Line", true) ~= nil)
			local channel = VoidkinScreen.Find("Channel")
			local firstMark, lastMark = button("Favourite"), button("Rename")
			if channel and channel:IsA("GuiObject") and firstMark and lastMark then
				local left, right = channel.AbsolutePosition.X, channel.AbsolutePosition.X + channel.AbsoluteSize.X
				t.Check("favourite, lock and rename in one channel, from the first's left to the last's right", math.abs(left - firstMark.AbsolutePosition.X) <= 1 and math.abs(right - lastMark.AbsolutePosition.X - lastMark.AbsoluteSize.X) <= 1, `{left}..{right}`)
				local lock = button("Lock")
				t.Check("three equal cells", lock ~= nil and math.abs(firstMark.AbsoluteSize.X - lock.AbsoluteSize.X) < 0.5 and math.abs(lock.AbsoluteSize.X - lastMark.AbsoluteSize.X) < 0.5)
				t.Check("split by two hairlines", channel:FindFirstChild("Split1") ~= nil and channel:FindFirstChild("Split2") ~= nil)
			else
				t.Check("favourite, lock and rename in one channel", false)
			end
			-- Every hairline of B's draws: a UDim's offset is whole, so a line of 0.85 would be cut to nothing (Seam.Whole).
			local thin: { string } = {}
			for _, root in { back, channel } :: { Instance? } do
				for _, piece in if root then root:GetDescendants() else {} do
					if piece:IsA("Frame") and ((piece.Name == "Line" and piece.Parent ~= nil and piece.Parent:GetAttribute("Seam") == true) or string.match(piece.Name, "^Split%d$") ~= nil) and math.min(piece.AbsoluteSize.X, piece.AbsoluteSize.Y) < 1 then
						table.insert(thin, `{piece:GetFullName()} {piece.AbsoluteSize}`)
					end
				end
			end
			t.Check("Back's line and the channel's hairlines a pixel or more across", #thin == 0, thin[1])
			local opened = VoidkinScreen.Find("Page")
			t.Check("it opens on the Items page", opened ~= nil and opened:GetAttribute("Page") == "Bag", tostring(opened and opened:GetAttribute("Page")))
			-- The Items page is AR18's A (TR28), checked in its own case (BagCases): what follows is Overview's composition.
			VoidkinScreen.Show("Overview")
			t.Wait(SETTLE)
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
			feet(t, "this window")
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
			for _, name in { "Rail", "Name", "Panel", "Strip", "Lead" } do -- the lead's page: no Station
				t.Check(`{name} in view`, inView(name))
			end
			t.Check("the bag's kinds the bag's five, weapons and armor one Gear", table.concat(VoidkinScreen.Kinds, ", ") == "All, Gear, Jewelry, Chests, Materials", table.concat(VoidkinScreen.Kinds, ", "))
			-- Its name over the stage: one line inside it, its rarity after it in the rarity's colour.
			nameLine(t, "this window", owned)
			-- The rail (AR29's B): every built page's tap whole, one under another, each a touch or more, and no scroll; a page
			-- not built yet isn't on it (the director's pick of B: hidden until it opens).
			local strung = VoidkinScreen.Find("Rail")
			if strung and strung:IsA("ScrollingFrame") then
				local top, foot = strung.AbsolutePosition.Y, strung.AbsolutePosition.Y + strung.AbsoluteSize.Y
				local fits, taps, last, hidden = true, true, top, true
				for _, name in VoidkinScreen.Pages do
					local each = railButton(name)
					if VoidkinScreen.Soon[name] then
						hidden = hidden and each == nil
						continue
					end
					fits = fits and each ~= nil and each.AbsolutePosition.Y >= last - 1 and each.AbsolutePosition.Y + each.AbsoluteSize.Y <= foot + 1
					taps = taps and each ~= nil and each.AbsoluteSize.Y >= Theme.Size.Touch - 0.5
					last = if each then each.AbsolutePosition.Y + each.AbsoluteSize.Y else last
				end
				t.Check("the rail holds every built page's tap whole, one under another", fits and strung:GetAttribute("Whole") == true)
				t.Check("the pages not built yet aren't on it", hidden)
				t.Check("with no scroll", not strung.ScrollingEnabled)
				t.Check(`each a touch or more tall, {Theme.Size.Touch} rendered px`, taps)
			else
				t.Check("the rail", false)
			end
			local leads, panel = button("Lead"), VoidkinScreen.Find("Panel")
			if leads and panel and panel:IsA("GuiObject") then
				local top, left, right = panel.AbsolutePosition.Y, panel.AbsolutePosition.X, panel.AbsolutePosition.X + panel.AbsoluteSize.X
				t.Check("Leading out of the panel, on the line over it", leads.AbsolutePosition.Y + leads.AbsoluteSize.Y <= top + 1)
				t.Check("in the panel's column", leads.AbsolutePosition.X >= left - 1 and leads.AbsolutePosition.X + leads.AbsoluteSize.X <= right + 1)
			else
				t.Check("Leading out of the panel, on the line over it", false)
			end
			local wallet = VoidkinScreen.Find("Wallet")
			local credits = wallet and wallet:FindFirstChild("Credits")
			local value = credits and credits:FindFirstChild("Value")
			t.Check("the band's Credits, the save's", value ~= nil and value:IsA("TextLabel") and value.Text == Read.Number(view.Currency.Credits), if value and value:IsA("TextLabel") then value.Text else "none")
			-- The lead: its Lead lit and reading Leading, alone on its line.
			t.Check("the lead's own reads Leading", labelOf(leads) == "Leading", labelOf(leads))
			t.Check("lit, not greyed", leads ~= nil and Button.State(leads) == "Selected", if leads then Button.State(leads) else "none")
			leadsWork(t, "this window")
			-- Each page from its rail button, on the save's numbers; one not built yet says so and keeps the page.
			local chrome = HudConfig.Voidkin.Chrome
			t.Check("the rail holds every page", table.concat(VoidkinScreen.Pages, ", ") == "Overview, Bag, Kit, Stars, Forge, Jewels, War Emblems", table.concat(VoidkinScreen.Pages, ", "))
			local overviewLook = "" -- the Overview's stage, for the Items page's to match
			for _, name in VoidkinScreen.Pages do
				if VoidkinScreen.Soon[name] then
					local before = VoidkinScreen.Find("Page")
					local was = before and before:GetAttribute("Page")
					VoidkinScreen.Show(name)
					t.Wait(SETTLE)
					local after = VoidkinScreen.Find("Page")
					t.Check(`{name}, not built: asked for, it says so`, table.find(Toast.Shown(), `{name}: soon`) ~= nil, table.concat(Toast.Shown(), "; "))
					t.Check(`and the page stays, never an empty one`, after ~= nil and after:GetAttribute("Page") == was, tostring(after and after:GetAttribute("Page")))
					continue
				end
				t.Check(`the rail's {name} takes a tap`, VoidkinScreen.Tap(railButton(name)))
				t.Wait(SETTLE)
				local chosen = railButton(name)
				t.Check(`{name} chosen`, chosen ~= nil and chosen:GetAttribute("Chosen") == true)
				-- Its tab of glass: the cut plates, edged in the seam's light, washed toward the line, and the line bright and
				-- wide where they meet.
				local fill = chosen and chosen:FindFirstChild("Fill")
				local edge = chosen and chosen:FindFirstChild("Edge")
				local wash = chosen and chosen:FindFirstChild("Wash")
				local tab = chrome.Rail.Tab
				t.Check("its tab of glass, cut, edged in the seam's light", fill ~= nil and fill:IsA("ImageLabel") and fill.Image == chrome.Images.TabFill.Id and fill.ScaleType == Enum.ScaleType.Slice and edge ~= nil and edge:IsA("ImageLabel") and edge.ImageColor3 == Seam.Light and math.abs(edge.ImageTransparency - (1 - tab.Edge)) < 1e-3)
				t.Check("washed in the light toward the line, and the line wide where they meet", wash ~= nil and wash:FindFirstChildOfClass("UIGradient") ~= nil and chosen ~= nil and chosen:FindFirstChild("Meet") ~= nil)
				local icon = chosen and chosen:FindFirstChild("Icon")
				local chosenWord = chosen and chosen:FindFirstChild("Label")
				t.Check("its icon over its word, in the seam's text", icon ~= nil and icon:IsA("ImageLabel") and icon.ImageColor3 == Seam.Colour.Text and chosenWord ~= nil and chosenWord:IsA("TextLabel") and chosenWord.TextColor3 == Seam.Colour.Text and chosenWord.AbsolutePosition.Y >= icon.AbsolutePosition.Y + icon.AbsoluteSize.Y * 0.8)
				if chosenWord and chosenWord:IsA("TextLabel") and fill and fill:IsA("GuiObject") then
					local inkLeft = chosenWord.AbsolutePosition.X + (chosenWord.AbsoluteSize.X - chosenWord.TextBounds.X) / 2
					local inkRight = inkLeft + chosenWord.TextBounds.X
					local inkFoot = chosenWord.AbsolutePosition.Y + (chosenWord.AbsoluteSize.Y + chosenWord.TextBounds.Y) / 2
					t.Check("its word inside the glass", inkLeft >= fill.AbsolutePosition.X - 0.5 and inkRight <= fill.AbsolutePosition.X + fill.AbsoluteSize.X + 0.5 and inkFoot <= fill.AbsolutePosition.Y + fill.AbsoluteSize.Y + 1, string.format("%.1f..%.1f in %.1f..%.1f", inkLeft, inkRight, fill.AbsolutePosition.X, fill.AbsolutePosition.X + fill.AbsoluteSize.X))
				end
				local alone, idle, quiet = true, true, true
				for _, other in VoidkinScreen.Pages do
					local rest = railButton(other)
					if other ~= name and rest then
						local restIcon = rest:FindFirstChild("Icon")
						alone = alone and rest:GetAttribute("Chosen") == false
						idle = idle and restIcon ~= nil and restIcon:IsA("ImageLabel") and restIcon.ImageColor3 == chrome.Rail.Idle and rest:FindFirstChild("Tick") ~= nil
						quiet = quiet and rest:FindFirstChild("Label") == nil and rest:FindFirstChild("Fill") == nil
					end
				end
				t.Check("the only one chosen; the rest idle, each its icon in the idle tint and a tick on the line", alone and idle)
				t.Check("only its word shows", quiet)
				local line = VoidkinScreen.Find("Rail")
				local seam = line and line:FindFirstChild("Line")
				if seam and chosen then
					local middle = chosen.Position.Y.Offset + chosen.Size.Y.Offset / 2
					t.Check("the line brightest at it", math.abs((seam:GetAttribute("Peak") :: number) - middle) < 0.5, string.format("%.1f against %.1f", seam:GetAttribute("Peak") :: number, middle))
				else
					t.Check("the line brightest at it", false)
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
							local item = scroll:FindFirstChild(Sheet.Said[stat] or stat, true) -- a line is named as it reads (Defense)
							local right = item and item:FindFirstChild("Right", true) -- in its Total, beside its Main
							t.Check(`Overview: its {stat}, resolved`, right ~= nil and (right :: TextLabel).Text == Hud.Digits((block :: any)[stat]), if right then (right :: TextLabel).Text else "none")
						end
						t.Check("Overview: its Speed", scroll:FindFirstChild("Speed", true) ~= nil)
						overviewLook = stageLook()
						t.Check("Overview: the stage lit, its halo, no warm glow", string.find(overviewLook, "halo none", 1, true) == nil and string.find(overviewLook, "warm false", 1, true) ~= nil, overviewLook)
						-- TR28: the screen in the seam's skin, its cover the seam's backing, and nothing of the graphite left.
						local behind = Screen.Cover("Voidkin")
						local shaft = VoidkinScreen.Find("Shaft")
						t.Check("Overview: the seam's backing behind, its shaft behind the figure", behind ~= nil and behind:IsA("Frame") and behind.BackgroundColor3 == Seam.Colour.Backing and shaft ~= nil)
						local grey = graphiteIn(screenRoots())
						t.Check("Overview: nothing of the graphite left", grey == "", grey)
					elseif name == "Bag" then
						t.Check("Bag: its doll, its strip and the card's room", VoidkinScreen.Find("Case") ~= nil and VoidkinScreen.Find("Doll") ~= nil and VoidkinScreen.Find("Kinds") ~= nil and VoidkinScreen.Find("CardRoom") ~= nil)
						-- TR24, the director's run, fix 4: one palette across the tabs. The stage as the Overview's, the page bare on
						-- the screen's backing, every cell's well an Overview slot's, and nothing of the lacquer's warm browns.
						local look = stageLook()
						t.Equal("Bag: the stage as the Overview's", look, overviewLook)
						local case = VoidkinScreen.Find("Case")
						local strip = VoidkinScreen.Find("Strip")
						local items = if strip then strip.Parent else nil
						-- TR28: the room in the seam's panel, its top a lit edge, and every well the seam's, a Legendary's too.
						local roomRamp = if case then case:FindFirstChildOfClass("UIGradient") else nil
						t.Check("Bag: the room in the seam's panel, its top lit", case ~= nil and case:IsA("Frame") and math.abs(case.BackgroundTransparency - (1 - Seam.Alpha)) < 1e-3
							and roomRamp ~= nil and roomRamp.Color.Keypoints[1].Value == Seam.Panel[1] and case:FindFirstChild("Top") ~= nil)
						local wells, odd = 0, ""
						for _, piece in (if items then items:GetDescendants() else {}) :: { Instance } do
							if piece:IsA("ImageLabel") and piece.Name == "Well" then
								wells += 1
								local ramp = piece:FindFirstChildOfClass("UIGradient")
								local keys = if ramp then ramp.Color.Keypoints else {}
								local right = piece.ImageColor3 == Color3.new(1, 1, 1) and piece.ImageTransparency == 0 and #keys == 2 and keys[1].Value == Seam.Well[1] and keys[2].Value == Seam.Well[2]
								odd = if right or odd ~= "" then odd else `{(piece.Parent :: Instance).Name} {piece.ImageColor3:ToHex()} {piece.ImageTransparency}`
							end
						end
						t.Check("Bag: every cell's and slot's well the seam's", wells >= 14 and odd == "", `{wells} wells; {odd}`)
						local grey = graphiteIn(screenRoots())
						t.Check("Bag: nothing of the graphite left", grey == "", grey)
						local warm = if items then lacquerIn(items) else "no page"
						t.Check("Bag: nothing in the lacquer's browns", warm == "", warm)
						-- The rail words only the chosen page (and Soon's): chosen, the bag's page reads Items (the director, 2026-11-15).
						local pages = VoidkinScreen.Find("Rail")
						local bagPage = pages and pages:FindFirstChild("Bag", true)
						local word = bagPage and bagPage:FindFirstChild("Label")
						t.Check("Bag: its page reads Items on the rail", word ~= nil and word:IsA("TextLabel") and word.Text == "Items", if word and word:IsA("TextLabel") then word.Text else "no word")
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
						-- Its copies toward the next star (Rules.Hud.Copies): never a count past its total read as N of M.
						local said = ""
						for _, child in scroll:GetChildren() do
							local under = if string.find(child.Name, " stars$") then child:FindFirstChild("Under") else nil
							said = if under and under:IsA("TextLabel") then under.Text else said
						end
						local n, m = string.match(said, "^([%d,]+) of ([%d,]+) copies")
						local past = n ~= nil and m ~= nil and (tonumber((string.gsub(n, ",", ""))) or 0) > (tonumber((string.gsub(m, ",", ""))) or 0)
						t.Check("Stars: its copies toward the next star, never N of M past M", said ~= "" and not past, said)
					end
				end
				for _, kept in (if name == "Bag" then {} else { "Lead" }) :: { string } do -- C's Items page has none; the lead's, no Station
					t.Check(`{name}: {kept} still in view`, inView(kept))
				end
			end
			-- Combat Power's tap: where it comes from.
			t.Check("a tap on Combat Power is taken", VoidkinScreen.Tap(VoidkinScreen.Find("Power")))
			local shown = VoidkinScreen.Find("Page")
			t.Check("and shows Overview, where its stats are", shown ~= nil and shown:GetAttribute("Page") == "Overview" and shown:FindFirstChild("Health", true) ~= nil)
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
					t.Check(`{mark.Name}: its icon {if want then "solid, in the light, with its line under" else "an outline, in the seam's text"}`, waitFor(t, 1, function(): boolean
						local found = button(mark.Name)
						local icon = found and found:FindFirstChild("Icon", true)
						local lit = found and found:FindFirstChild("Lit", true)
						return icon ~= nil and icon:IsA("ImageLabel") and icon:GetAttribute("Kit") == (if want then `{mark.Name}On` else mark.Name) and icon.ImageColor3 == (if want then Seam.Light else Seam.Colour.Text) and (lit ~= nil) == want
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
			-- One stationed and recalled (or, every bay busy, recalled and stationed again), each saying its bay under its name;
			-- on another Voidkin's page Lead and Station stand side by side, the line over the panel.
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
			local function says(want: string): (boolean, string)
				local work = button("Work")
				local reason = work and work:FindFirstChild("Reason") :: TextLabel?
				local said = if reason and reason.Visible then reason.Text else "none"
				return said == want and reason ~= nil and reason.TextFits, said
			end
			local function pair(where: string)
				local leads, works = button("Lead"), button("Work")
				t.Check(`{where}: Lead first, Station or Recall beside it`, leads ~= nil and works ~= nil and leads.AbsolutePosition.X + leads.AbsoluteSize.X <= works.AbsolutePosition.X
					and math.abs(leads.AbsolutePosition.Y - works.AbsolutePosition.Y) <= 1)
			end
			if free and empty then
				VoidkinScreen.Choose(free)
				pair("an idle one")
				t.Check(`Station says its bay under its name, Bay {empty}`, says(`Bay {empty}`))
				t.Check("Station", Button.Press(button("Work") :: TextButton) and role(free, `Bay {empty}`))
				t.Check("and its button recalls it", shows("Recall"), labelOf(button("Work")))
				t.Check(`Recall says its bay, Bay {empty}`, says(`Bay {empty}`))
				t.Check("Recall", Button.Press(button("Work") :: TextButton) and role(free, ""))
			elseif worker then
				VoidkinScreen.Choose(worker)
				pair("a stationed one")
				t.Check("every bay busy: a stationed one reads Recall", labelOf(button("Work")) == "Recall", labelOf(button("Work")))
				t.Check(`and says its bay, Bay {working}`, says(`Bay {working}`))
				t.Check("Recall", Button.Press(button("Work") :: TextButton) and role(worker, ""))
				t.Check("and its button stations it", shows("Station"), labelOf(button("Work")))
				t.Check("Station, to the bay it left", Button.Press(button("Work") :: TextButton) and role(worker, `Bay {working}`))
			else
				t.Check("a Voidkin to station or to recall", false)
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
			for _, name in VoidkinScreen.Pages do
				if not VoidkinScreen.Soon[name] then
					VoidkinScreen.Show(name)
					t.Wait(SETTLE)
					bandClear(t, `this window, {name}`)
				end
			end
			Layers.Force(Theme.Scale.Floor)
			Layers.Box(Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height))
			t.Wait(0.1)
			for _, name in VoidkinScreen.Pages do
				if not VoidkinScreen.Soon[name] then
					VoidkinScreen.Show(name) -- built again at the phone's size
					t.Wait(SETTLE)
					lintClean(t, `the smallest phone, {name}`)
					bandClear(t, `the smallest phone, {name}`)
				end
			end
			whole(t, "the smallest phone")
			feet(t, "the smallest phone")
			nameLine(t, "the smallest phone", (ProfileController.Get() :: Profile.View).Voidkin[lead])
			leadsWork(t, "the smallest phone")
			for _, name in { "Back", "Favourite", "Lock", "Rename", "Wallet" } do
				t.Check(`the smallest phone: {name} in the band, whole`, inView(name))
			end
			local purse = VoidkinScreen.Find("Wallet")
			t.Row(`the smallest phone: the band, authored px wide (the wallet's form {tostring(purse and purse:GetAttribute("Form"))})`, nil, nil, Layers.Band().X, "")
			-- The built pages stand whole on the rail, a touch or more each, with no scroll (AR29's B; research's call on seven
			-- rows: every page in sight).
			local holder = VoidkinScreen.Find("Rail")
			if holder and holder:IsA("ScrollingFrame") then
				local top, foot = holder.AbsolutePosition.Y, holder.AbsolutePosition.Y + holder.AbsoluteSize.Y
				local fits, taps = true, true
				for _, name in VoidkinScreen.Pages do
					local each = railButton(name)
					if not VoidkinScreen.Soon[name] then
						fits = fits and each ~= nil and each.AbsolutePosition.Y >= top - 1 and each.AbsolutePosition.Y + each.AbsoluteSize.Y <= foot + 1
						taps = taps and each ~= nil and each.AbsoluteSize.Y >= Theme.Size.Touch - 0.5
					end
				end
				t.Check("the smallest phone: every built page whole on the rail, a touch or more each", fits and taps)
				t.Check("the smallest phone: with no scroll", not holder.ScrollingEnabled and holder:GetAttribute("Whole") == true)
				t.Row(`the smallest phone: the rail's pitch, authored px, in a window of {math.floor(holder.AbsoluteWindowSize.Y / Layers.Scale())}`, nil, nil, holder:GetAttribute("Pitch") :: number, "")
			else
				t.Check("the smallest phone: the rail", false)
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

	-- Overview's stat sheet (docs/ui.md, 5, "Overview's stat sheet"; TR17, "Overview shows every stat"): every stat in its
	-- three groups, each line the rule's words, a plain list where nothing opens [the director, 2026-11-15, night: "Plain
	-- list, no taps"], its experience bar lit as far as its share, and whole on the smallest phone with the list scrolled to
	-- its foot.
	local sheet = {
		Name = "Voidkin screen: Overview's stat sheet, the Basic Attributes then the Battle Attributes' blocks as a plain list where nothing opens, each rating's chance under it, its experience bar lit to its share, whole on the smallest phone at the list's foot",
		Run = function(t: any)
			local view = ProfileController.Get()
			t.Check("the save's copy is here", view ~= nil)
			if view == nil then
				return
			end
			local owned = view.Voidkin[view.Roles.Lead]
			t.Check("a lead to read", owned ~= nil)
			if owned == nil then
				return
			end
			-- A bar sized by its parent lights as far as its share (it stayed a pixel: research's still, 7.8%).
			local room = Instance.new("Frame")
			room.Name = "NL_SheetBar"
			room.BackgroundTransparency = 1
			room.Size = UDim2.fromOffset(300, 40)
			room.Parent = Layers.Get("Menus")
			local probe = Bar.new({ Name = "Probe", Size = UDim2.new(1, 0, 0, Theme.Size.Bar), Parent = room, Colour = HudConfig.Card.Xp })
			Bar.Set(probe, 0.078)
			t.Wait(0.1)
			local function lit(bar: Instance): number?
				local skin = bar:FindFirstChild("NL_Skin")
				local light = skin and skin:FindFirstChild("Light", true)
				if light == nil or not light:IsA("GuiObject") or not bar:IsA("GuiObject") or bar.AbsoluteSize.X <= 0 then
					return nil
				end
				return if light.Visible then light.AbsoluteSize.X / bar.AbsoluteSize.X else 0
			end
			local share = lit(probe)
			t.Check("a bar as wide as its parent, at 7.8%, lights about 7.8% of its length", share ~= nil and math.abs(share - 0.078) <= 0.03, if share then string.format("%.3f", share) else "no light")
			room:Destroy()
			Screen.Close()
			local hud = HudController.Parts()
			t.Check("the dock's Voidkin opens it", Button.Press(hud.Voidkin :: TextButton) and waitFor(t, 1, function(): boolean
				return Screen.Current() == VoidkinScreen.Name
			end))
			t.Wait(HudConfig.Motion.Screen.Enter + 0.1)
			VoidkinScreen.Show("Overview")
			t.Wait(SETTLE)
			local scroll = VoidkinScreen.Find("Page")
			t.Check("on Overview", scroll ~= nil and scroll:GetAttribute("Page") == "Overview")
			if scroll == nil or not scroll:IsA("ScrollingFrame") then
				Screen.Close()
				return
			end
			local block = Stats.Resolve(owned, Stats.PresetOf(view :: any, owned), view :: any)
			local wrong: { string } = {}
			local order = 0
			-- A cell's place on the page: its row's, the right one half a step on.
			local function placeOf(item: GuiObject): number
				local pair = item.Parent
				return if pair and pair:IsA("GuiObject") and pair.Parent == scroll then pair.LayoutOrder + item.Position.X.Scale else -1
			end
			local function said(item: Instance?, part: string): string?
				local label = item and item:FindFirstChild(part, true)
				return if label and label:IsA("TextLabel") then label.Text else nil
			end
			-- The Main tag starts within a gap of its total's last character and ends inside its own cell, so it never reads
			-- as the next cell's (TR24, the director's run).
			local function mainBeside(item: GuiObject): boolean
				local value, tag = item:FindFirstChild("Right", true), item:FindFirstChild("Main", true)
				if value == nil or tag == nil or not value:IsA("TextLabel") or not tag:IsA("TextLabel") then
					return false
				end
				local ends = value.AbsolutePosition.X + value.TextBounds.X
				local gap = tag.AbsolutePosition.X - ends
				return gap >= 0 and gap <= 16 and tag.AbsolutePosition.X + tag.AbsoluteSize.X <= item.AbsolutePosition.X + item.AbsoluteSize.X + 1
			end
			for _, group in Sheet.Rows(block) do
				for _, frame in { if group.Heading then `Heading{group.Heading}` else nil, if group.Name ~= "" then `Group{group.Name}` else nil } do
					local head = scroll:FindFirstChild(frame)
					if head == nil or not head:IsA("GuiObject") or head.LayoutOrder <= order then
						table.insert(wrong, `{frame} out of its place`)
					else
						order = head.LayoutOrder
					end
				end
				if group.Caption and said(scroll:FindFirstChild(`Heading{group.Heading}`), "Caption") ~= group.Caption then
					table.insert(wrong, `{group.Heading}'s caption`)
				end
				for _, want in group.Rows do
					local item = scroll:FindFirstChild(want.Name, true)
					if item == nil or not item:IsA("GuiObject") or placeOf(item) <= order then
						table.insert(wrong, `{want.Name} out of its block`)
					elseif said(item, "Right") ~= want.Value or item:FindFirstChild("Effect", true) ~= nil or item:FindFirstChild("Under") ~= nil then
						table.insert(wrong, `{want.Name}: {said(item, "Right")}, wanted {want.Value} and nothing under it`)
					elseif (item:FindFirstChild("Main", true) ~= nil) ~= (want.Main == true) then
						table.insert(wrong, `{want.Name}: its Main tag`)
					elseif want.Main and not mainBeside(item) then
						table.insert(wrong, `{want.Name}: its Main tag away from its total`)
					else
						order = placeOf(item)
					end
				end
			end
			t.Check("the five, then Core, Offense and Defense, Sustain, two a row in order, each under its heading and caption with its one total (a rating's its percent alone), the Main tagged beside its own total", #wrong == 0, wrong[1])
			-- Nothing opens: no cell is a button, none holds anything under its total, and no caption says to tap.
			local opens: { string } = {}
			for _, group in Sheet.Groups do
				for _, stat in group.Stats do
					local item = scroll:FindFirstChild(Sheet.Said[stat] or stat, true)
					for _, inside in if item then item:GetDescendants() else {} do
						if inside:IsA("GuiButton") or inside.Name == "Sources" then
							table.insert(opens, `{stat}: {inside.Name}`)
						end
					end
				end
				local head = scroll:FindFirstChild(`Group{group.Name}`)
				if head and head:FindFirstChild("Hint") then
					table.insert(opens, `{group.Name}'s hint`)
				end
			end
			t.Check("nothing opens: no tap on a stat, nothing under it, no hint to tap", #opens == 0, opens[1])
			local need = Growth.XpToNext(owned.Level)
			if need and owned.Xp > 0 then
				local level = scroll:FindFirstChild(`Level {owned.Level}`)
				local xp = level and level:FindFirstChild("Xp")
				local got = if xp then lit(xp) else nil
				local want = math.clamp(owned.Xp / need, 0, 1)
				t.Check("its experience bar lights as far as its share", got ~= nil and math.abs(got - want) <= 0.03, if got then string.format("%.3f for %.3f", got, want) else "no light")
			end
			-- The smallest phone, the list at its foot.
			Layers.Force(Theme.Scale.Floor)
			Layers.Box(Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height))
			t.Wait(0.1)
			VoidkinScreen.Show("Overview")
			t.Wait(SETTLE)
			local small = VoidkinScreen.Find("Page")
			if small and small:IsA("ScrollingFrame") then
				small.CanvasPosition = Vector2.new(0, math.max(0, small.AbsoluteCanvasSize.Y - small.AbsoluteWindowSize.Y))
				t.Wait(0.1)
				local final = Sheet.Groups[#Sheet.Groups].Stats
				local last = small:FindFirstChild(final[#final], true)
				t.Check("the smallest phone: the list scrolls to its last line", last ~= nil and last:IsA("GuiObject") and last.AbsolutePosition.Y + last.AbsoluteSize.Y <= small.AbsolutePosition.Y + small.AbsoluteWindowSize.Y + 1)
				lintClean(t, "the smallest phone, Overview at its foot")
				-- Every name and total whole on its line at the smallest phone.
				local cut: { string } = {}
				for _, group in Sheet.Groups do
					for _, stat in group.Stats do
						local item = small:FindFirstChild(Sheet.Said[stat] or stat, true)
						for _, part in { "Left", "Right" } do
							local label = item and item:FindFirstChild(part, true)
							if label == nil or not label:IsA("TextLabel") or not label.TextFits then
								table.insert(cut, `{stat} {part}`)
							end
						end
					end
				end
				t.Check("the smallest phone: every name, total and chance fits its line", #cut == 0, cut[1])
			else
				t.Check("the smallest phone: Overview", false)
			end
			Layers.Box(nil)
			Layers.Force(nil)
			t.Wait(0.1)
			Screen.Close()
			t.Wait(HudConfig.Motion.Screen.Exit + 0.1)
		end,
	}

	-- AR29's B in the build, for research's read (docs/asset-requests.md, AR29): the screen held, each state as
	-- ReplicatedStorage.NL_TakeStep says, "<room> <page> <marks>": the room "Large" (this window) or "Phone" (the
	-- smallest phone), a built page's name, and "on" or "off" for favourite and lock together. "End" closes it, the marks
	-- as they were. Each state is set on the server as a press would, so the screen shows the save's own answer.
	local held = {
		Name = "Take: AR29's B, the rail and the bar in every state, held as the driver writes, for research",
		Manual = true,
		Stay = true,
		Run = function(t: any)
			local ids = VoidkinCases.Own(t, waitFor, ANSWER)
			if #ids == 0 then
				return
			end
			local step = Instance.new("StringValue")
			step.Name = "NL_TakeStep"
			step.Value = "Large Overview off"
			step.Parent = ReplicatedStorage
			Screen.Close()
			Button.Press(HudController.Parts().Voidkin :: TextButton)
			t.Check("the Voidkin screen opens", waitFor(t, 1, function(): boolean
				return Screen.Current() == VoidkinScreen.Name
			end))
			local lead = VoidkinScreen.Chosen() :: string
			local fields: { [string]: string } = { Favourite = "Favourite", Lock = "Locked" }
			local function marked(name: string): boolean
				local now = ProfileController.Get()
				return now ~= nil and (now.Voidkin[lead] :: any)[fields[name]] == true
			end
			local was: { [string]: boolean } = { Favourite = marked("Favourite"), Lock = marked("Lock") }
			local function mark(name: string, want: boolean)
				if marked(name) ~= want then
					Button.Press(button(name) :: TextButton)
					waitFor(t, ANSWER, function(): boolean
						return marked(name) == want
					end)
				end
			end
			local function apply(said: string)
				local room, rest = string.match(said, "^(%a+) (.+)$")
				local page, marks = string.match(rest or "", "^(.-) (%a+)$")
				if room == nil or page == nil then
					return
				end
				Layers.Force(if room == "Phone" then Theme.Scale.Floor else nil)
				Layers.Box(if room == "Phone" then Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height) else nil)
				t.Wait(SETTLE)
				VoidkinScreen.Tap(railButton(page))
				for name in fields do
					mark(name, marks == "on")
				end
				t.Wait(SETTLE)
				step:SetAttribute("Shown", said)
			end
			apply(step.Value)
			local shown = step.Value
			waitFor(t, 600, function(): boolean
				if step.Value ~= shown then
					shown = step.Value
					if shown ~= "End" then
						apply(shown)
					end
				end
				return step.Value == "End"
			end)
			for name, before in was do
				mark(name, before)
			end
			Layers.Box(nil)
			Layers.Force(nil)
			Screen.Close()
			step:Destroy()
		end,
	}

	return { case, sheet, held }
end

return VoidkinCases
