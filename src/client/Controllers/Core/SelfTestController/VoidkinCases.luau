--!strict
-- VoidkinCases (client, Studio only): the Voidkin screen's case (TR17, the director's full-screen layout), a list of its
-- own beside Cases, which joins it as it joins Takes. On the screen as it stands at home (Stay): opened from the dock,
-- full screen over a cover that hides the world and the HUD, Back, its marks and the currencies in Roblox's band, its
-- name and rarity on one line over the stage, the figure whole under it at its measured share, no gear slot and Combat
-- Power alone at its feet (the director, 2026-11-17), each built page with its name in the band and lit on the rail of
-- pages (AR49, the Equipment screen's rail), on the save's numbers, Lead and Send to work over
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
local Power = require(Shared.Rules.Power)
local Voidkin = require(Shared.Definitions.Voidkin)
local Gear = require(Shared.Definitions.Gear)
local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local ProfileController = require(script.Parent.Parent.ProfileController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Layers = require(UI.Layers)
local Text = require(UI.Kit.Text)
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
	local words = if button then button:GetAttribute("Words") else nil -- a Glass kit face's words (Glass.Dress)
	if type(words) == "string" then
		return words
	end
	local label = button and button:FindFirstChild("Label", true)
	return if label and label:IsA("TextLabel") then label.Text else ""
end

local function button(name: string): TextButton?
	local found = VoidkinScreen.Find(name)
	return if found and found:IsA("TextButton") then found else nil
end

-- The stage's stone shows the same under every rarity's light (TR50, research's must-fix 1): the floor's colour, lit as
-- the stage lights a plastic floor (its Ambient + LightColor x Lit, as measured), is the stone's Shows. 3 levels is the
-- room for a part's 8-bit colour.
local function stoneShows(t: any, figure: any, who: string)
	local floor = if figure then figure.Floor :: BasePart? else nil
	local view = if floor then floor:FindFirstAncestorOfClass("ViewportFrame") else nil
	if floor == nil or view == nil then
		t.Check(`{who}: the stone shows the sheet's under its rarity's light`, false, "no floor")
		return
	end
	local look = HudConfig.Voidkin.Stage.Floor
	local function lit(colour: number, ambient: number, light: number): number
		return colour * (ambient + light * look.Lit)
	end
	local a, l, c = view.Ambient, view.LightColor, floor.Color
	local shows = Color3.new(lit(c.R, a.R, l.R), lit(c.G, a.G, l.G), lit(c.B, a.B, l.B))
	local off = math.max(math.abs(shows.R - look.Shows.R), math.abs(shows.G - look.Shows.G), math.abs(shows.B - look.Shows.B))
	local row = Voidkin.ById[figure.Def]
	t.Check(`{who}: the stone shows the sheet's under its rarity's light`, off < 3 / 255,
		`{if row then row.Rarity else "?"}: wears {c:ToHex()}, shows {shows:ToHex()} for {look.Shows:ToHex()}`)
end

-- The page rail (AR49, research's call of 2026-11-20, 00:12): the Equipment screen's, its four pages down the room's left,
-- each word whole and in the room, the page shown lit, its column clear of the stage, every button a finger's size.
local function railWhole(t: any, where: string, shown: string)
	local holder = VoidkinScreen.Find("Rail")
	t.Check(`{where}: the rail of pages`, holder ~= nil)
	if holder == nil then
		return
	end
	local stage = VoidkinScreen.Find("Stage")
	local stageLeft = if stage and stage:IsA("GuiObject") then stage.AbsolutePosition.X else math.huge
	local least = math.huge
	local wrong = {}
	for _, name in HudConfig.Voidkin.Rail.Pages do
		local button = holder:FindFirstChild(`Rail{name}`) :: GuiObject?
		local face = holder:FindFirstChild(`{name}Face`) :: Frame?
		local word = holder:FindFirstChild(`{name}Word`) :: TextLabel?
		if button == nil or face == nil or word == nil then
			table.insert(wrong, `{name} missing`)
			continue
		end
		least = math.min(least, button.AbsoluteSize.X, button.AbsoluteSize.Y)
		if not word.TextFits or word.Text ~= (VoidkinScreen.Said[name] or name) then
			table.insert(wrong, `{name}'s word cut`)
		end
		if not inView(`{name}Word`) then
			table.insert(wrong, `{name}'s word out of the room`)
		end
		local right = word.AbsolutePosition.X + word.AbsoluteSize.X / 2 + word.TextBounds.X / 2
		if right > stageLeft + 1 then
			table.insert(wrong, `{name}'s word over the stage`)
		end
		if (face:GetAttribute("Chosen") == true) ~= (name == shown) then
			table.insert(wrong, `{name} lit wrong`)
		end
	end
	t.Check(`{where}: its four pages whole, {shown} lit, clear of the stage`, #wrong == 0, table.concat(wrong, ", "))
	t.Check(`{where}: each page a finger's size`, least >= Theme.Size.Touch - 0.5, string.format("%.1f px", least))
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

	-- The lead's page: "Leading" with its mark alone across the line, in the seam's light; no Station, since
	-- the page's own state rules it out (research's ruling on the director's remark, 2026-11-17).
	local function leadsWork(t: any, where: string)
		local leads = button("Lead")
		local row = leads and leads.Parent
		t.Check(`{where}: no Station on the lead's page`, button("Work") == nil)
		if leads and row and row:IsA("GuiObject") then
			-- AR43's take 2: the Glass kit's lit face, the diamond and the word centred together.
			local label = leads:FindFirstChild("Words", true) :: TextLabel?
			local mark = leads:FindFirstChild("Mark", true) :: GuiObject?
			t.Check(`{where}: Leading across the line`, math.abs(leads.AbsoluteSize.X - row.AbsoluteSize.X) <= 1, `{leads.AbsoluteSize.X} of {row.AbsoluteSize.X}`)
			t.Check(`{where}: its word whole, its mark beside it`, label ~= nil and label.Text == "Leading" and label.TextFits and mark ~= nil and mark.Visible
				and mark.AbsolutePosition.X + mark.AbsoluteSize.X <= label.AbsolutePosition.X + (label.AbsoluteSize.X - label.TextBounds.X) / 2 + 1)
			t.Check(`{where}: lit, not a dim glass`, leads:GetAttribute("Dress") == "Lit", tostring(leads:GetAttribute("Dress")))
		else
			t.Check(`{where}: the lead's Leading`, false)
		end
	end

	local case = {
		Name = "Voidkin screen (TR17): full screen, Back, its marks and the currencies in Roblox's band, its name over one Voidkin, each built page on its own (AR43), the bag, its power, its actions over the panel, switched by the strip and a flick",
		Stay = true,
		Run = function(t: any)
			local ids = VoidkinCases.Own(t, waitFor, ANSWER)
			t.Check("three Voidkin to switch between", #ids >= 3, `{#ids}`)
			if #ids < 3 then
				return
			end
			Screen.Close()
			local hud = HudController.Parts()
			VoidkinScreen.Last("Bag") -- the card opens the page last shown (AR49)
			t.Check("Home's Inventory tile opens it", Button.Press(hud.Voidkin :: TextButton) and waitFor(t, 1, function(): boolean
				return Screen.Current() == VoidkinScreen.Name
			end))
			t.Wait(HudConfig.Motion.Screen.Enter + 0.1)
			-- Its own screen (AR43): its name in the band after the channel, its tile's.
			local banded = VoidkinScreen.Find("PageName")
			t.Check("its name in the band, its tile's: Inventory", banded ~= nil and banded:IsA("TextLabel") and banded.Text == "Inventory", if banded and banded:IsA("TextLabel") then banded.Text else "none")
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
			-- The stage's stone under it, its element only a ring of light round the edge (TR50's sweep, Modulo's B).
			local floor = if figure then figure.Floor else nil
			local rim = if floor and floor.Parent then floor.Parent:FindFirstChild("FloorRim") :: BasePart? else nil
			local element = if row and row.Element ~= "" then UIKit.Elements[row.Element] else nil
			local stone = HudConfig.Voidkin.Stage.Floor
			t.Check("it stands on the stage's stone, plastic", floor ~= nil and floor.Material == Enum.Material.SmoothPlastic, if floor then floor.Material.Name else "no floor")
			stoneShows(t, figure, "the lead")
			-- The ring shows its element: its colour through the viewport's Neon, as measured, is the element's. A part keeps
			-- its colour in 8 bits, and the curve's slope turns one step into up to about 4 levels shown: 6 is the room.
			local function throughNeon(value: number): number
				local light = if value <= 0.04045 then value / 12.92 else ((value + 0.055) / 1.055) ^ 2.4
				local out = math.min(1, stone.Neon.Gain * light ^ stone.Neon.Power)
				return if out <= 0.0031308 then out * 12.92 else 1.055 * out ^ (1 / 2.4) - 0.055
			end
			local ringShows = if rim then Color3.new(throughNeon(rim.Color.R), throughNeon(rim.Color.G), throughNeon(rim.Color.B)) else nil
			t.Check("its element a ring of light round the stone's edge, Rim of the floor across, showing the element's colour", if element == nil
				then rim == nil
				else rim ~= nil and floor ~= nil and ringShows ~= nil and math.max(math.abs(ringShows.R - element.R), math.abs(ringShows.G - element.G), math.abs(ringShows.B - element.B)) < 6 / 255
					and rim.Material == Enum.Material.Neon and rim.Transparency == 0
					and math.abs(rim.Size.Y * (1 - 2 * stone.Rim) - floor.Size.Y) < 1e-3 and rim.Position.Y < floor.Position.Y,
				if rim and ringShows then `wears {rim.Color:ToHex()}, shows {ringShows:ToHex()} for {if element then element:ToHex() else "none"}, {rim.Size.Y} across` else "no ring")
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
				t.Check("its caption in its colour", caption ~= nil and caption.TextColor3 == finish.Caption and caption.Text == string.upper(Sheet.Said.Power), if caption then caption.Text else nil)
			end
			for _, name in { "PageName", "Name", "Panel", "Strip", "Lead" } do -- the lead's page: no Station
				t.Check(`{name} in view`, inView(name))
			end
			t.Check("the bag's kinds the bag's five, weapons and armor one Gear", table.concat(VoidkinScreen.Kinds, ", ") == "All, Gear, Jewelry, Chests, Materials", table.concat(VoidkinScreen.Kinds, ", "))
			-- Its name over the stage: one line inside it, its rarity after it in the rarity's colour.
			nameLine(t, "this window", owned)
			-- The rail of pages (AR49), and the page shown named in the band.
			railWhole(t, "this window", "Overview")
			local pageName = VoidkinScreen.Find("PageName")
			t.Check("Overview shown: its name in the band", pageName ~= nil and pageName:IsA("TextLabel") and pageName.Text == "Overview", if pageName and pageName:IsA("TextLabel") then pageName.Text else "none")
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
			-- Each page on the save's numbers, its name in the band; one not built yet says so and keeps the page.
			t.Check("every page", table.concat(VoidkinScreen.Pages, ", ") == "Overview, Bag, Kit, Stars, Forge, Jewels, War Emblems", table.concat(VoidkinScreen.Pages, ", "))
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
				VoidkinScreen.Show(name)
				t.Wait(SETTLE)
				railWhole(t, name, name)
				local title = VoidkinScreen.Find("PageName")
				local want = VoidkinScreen.Said[name] or name
				t.Check(`{name}: its name in the band`, title ~= nil and title:IsA("TextLabel") and title.Text == want, if title and title:IsA("TextLabel") then title.Text else "none")
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
						-- TR28: the room in the seam's panel, its top a lit edge, and every well the seam's, a Legendary's too; since
						-- AR43's take 2 the kit's panel, as the Overview's, in the screen's Panel with its edge lit from above.
						local fill = if case then case:FindFirstChild("Fill", true) :: ImageLabel? else nil
						local fillRamp = if fill then fill:FindFirstChildOfClass("UIGradient") else nil
						local edge = if case then case:FindFirstChild("Edge", true) :: ImageLabel? else nil
						local split = VoidkinScreen.Find("BagDivider")
						t.Check("Bag: the room in the seam's panel, its top lit", case ~= nil and case:IsA("Frame") and fill ~= nil and fillRamp ~= nil
							and fillRamp.Color.Keypoints[1].Value == Seam.Kit.Panel[1] and edge ~= nil and edge:FindFirstChildOfClass("UIGradient") ~= nil
							and edge.ImageColor3 == Seam.Kit.Facet)
						t.Check("Bag: the doll's side and the bag's split by the Facet's hairline", split ~= nil and split:IsA("Frame") and split.Visible
							and split.BackgroundColor3 == Seam.Kit.Facet and split.AbsoluteSize.X <= 2)
						local wells, odd = 0, ""
						for _, piece in (if items then items:GetDescendants() else {}) :: { Instance } do
							if piece:IsA("ImageLabel") and piece.Name == "Well" and piece:GetAttribute("Kit") ~= "DotsWell" then -- a button's dots' well is the kit's
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
						-- AR43's take 2: each won star lit in its trim with the Glint's hairline, each to win in the Well with the
						-- Facet's, every one seen.
						local itsRow = Voidkin.ById[owned.Def]
						local trim = HudConfig.Card.Trim[if itsRow then itsRow.Rarity else "Common"]
						local wrong = {}
						for index = 1, VoidkinConfig.MaxStars do
							local pip = if pips then pips:FindFirstChild(`Star{index}`) else nil
							local ramp = pip and pip:FindFirstChildOfClass("UIGradient")
							local hair = pip and pip:FindFirstChild("Hairline") :: UIStroke?
							local won = index <= owned.Stars
							local foot = if ramp then ramp.Color.Keypoints[#ramp.Color.Keypoints].Value else nil
							local well = UIKit.Palettes.SeamDeep.Well
							local top = if ramp then ramp.Color.Keypoints[1].Value else nil
							local ok = pip ~= nil and (pip :: GuiObject).Visible and hair ~= nil and hair.Transparency < 1
								and hair.Color == (if won then UIKit.Palettes.SeamDeep.Glint else UIKit.Palettes.SeamDeep.Facet)
								and (if won then foot == trim else top == well)
							if not ok then
								table.insert(wrong, `Star{index}`)
							end
						end
						t.Check("Stars: each won star lit in its trim, each to win in the well, every one seen", #wrong == 0, table.concat(wrong, ", "))
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
				stoneShows(t, VoidkinScreen.Figure(), `Voidkin {index}`)
			end
			-- Under a rarity's own light: the first not Common, when the save has one (Epic's turned the stone lavender).
			do
				local mine = (ProfileController.Get() :: Profile.View).Voidkin
				local other: string? = nil
				for _, id in ids do
					local each = Voidkin.ById[mine[id].Def]
					if each and each.Rarity ~= "Common" then
						other = id
						break
					end
				end
				t.Check("the save holds a Voidkin not Common, to light the stone by", other ~= nil)
				if other then
					local def = mine[other].Def
					VoidkinScreen.Choose(other)
					t.Check("a Voidkin not Common on the stage", waitFor(t, 3, function(): boolean
						local now = VoidkinScreen.Figure()
						return VoidkinScreen.Chosen() == other and now ~= nil and now.Def == def
					end), tostring(VoidkinScreen.Chosen()))
					stoneShows(t, VoidkinScreen.Figure(), "a Voidkin not Common")
					VoidkinScreen.Choose(ids[3])
					t.Check("and the third again", waitFor(t, 3, function(): boolean
						local now = VoidkinScreen.Figure()
						return VoidkinScreen.Chosen() == ids[3] and now ~= nil and now.Def == mine[ids[3]].Def
					end), tostring(VoidkinScreen.Chosen()))
				end
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
			-- what a press costs, as the line under it says it (docs/ui.md, item 5): "Bay 3 · +12 kW", "Leaves Bay 2 · −18 kW"
			local function costs(words: string, id: string, bay: number, sign: number): string
				local view = ProfileController.Get() :: Profile.View
				return `{words} · {Hud.KwChange(sign * Power.BayKw(view :: any, bay, view.Voidkin[id] :: any))}`
			end
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
			local function says(want: string, called: string?): (boolean, string)
				local work = button(called or "Work")
				local reason = work and work:FindFirstChild("Why", true) :: TextLabel? -- the line under its name (Glass.Dress)
				local said = if reason and reason.Visible then reason.ContentText else "none"
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
				t.Check(`Station says its bay under its name and what it would make there, Bay {empty}`, says(costs(`Bay {empty}`, free, empty, 1)))
				t.Check("Station", Button.Press(button("Work") :: TextButton) and role(free, `Bay {empty}`))
				t.Check("and its button recalls it", shows("Recall"), labelOf(button("Work")))
				t.Check(`Recall says its bay and what it stops making, Bay {empty}`, says(costs(`Bay {empty}`, free, empty, -1)))
				local itsLead = button("Lead")
				t.Check(`stationed, its Lead still pressable, saying "Leaves Bay {empty}" and its cost`, itsLead ~= nil and Button.State(itsLead) ~= "Disabled" and (says(costs(`Leaves Bay {empty}`, free, empty, -1), "Lead")),
					if itsLead then Button.State(itsLead) else "none")
				t.Check("Recall", Button.Press(button("Work") :: TextButton) and role(free, ""))
			elseif worker then
				VoidkinScreen.Choose(worker)
				pair("a stationed one")
				t.Check("every bay busy: a stationed one reads Recall", labelOf(button("Work")) == "Recall", labelOf(button("Work")))
				t.Check(`and says its bay and what it stops making, Bay {working}`, says(costs(`Bay {working}`, worker, working, -1)))
				local itsLead = button("Lead")
				t.Check(`its Lead still pressable, saying "Leaves Bay {working}" and its cost`, itsLead ~= nil and Button.State(itsLead) ~= "Disabled" and (says(costs(`Leaves Bay {working}`, worker, working, -1), "Lead")),
					if itsLead then Button.State(itsLead) else "none")
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
					railWhole(t, `the smallest phone, {name}`, name)
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
			t.Check("the smallest phone: its name in the band, whole", inView("PageName"))
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
			VoidkinScreen.Last("Bag") -- the card opens the page last shown (AR49)
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
					-- Under its total, only its row's own quiet line: HP Regen's "every 8 s" (4.6), nothing on the others.
					elseif said(item, "Right") ~= want.Value or item:FindFirstChild("Effect", true) ~= nil or said(item, "Under") ~= want.Under then
						table.insert(wrong, `{want.Name}: {said(item, "Right")} over {said(item, "Under") or "nothing"}, wanted {want.Value} over {want.Under or "nothing"}`)
					elseif (item:FindFirstChild("Main", true) ~= nil) ~= (want.Main == true) then
						table.insert(wrong, `{want.Name}: its Main tag`)
					elseif want.Main and not mainBeside(item) then
						table.insert(wrong, `{want.Name}: its Main tag away from its total`)
					else
						order = placeOf(item)
					end
				end
			end
			t.Check("the five, then Core, Offense and Defense, Sustain, two a row in order, each under its heading and caption with its one total (a rating's its percent alone, HP Regen's how often under it), the Main tagged beside its own total", #wrong == 0, wrong[1])
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
				-- AR43's take 2: the five Basic Attributes three a row, then two, all showing with nothing scrolled, and
				-- no name or number cut or drawn under the size its role draws at this scale (research's condition, 21:28).
				small.CanvasPosition = Vector2.zero
				t.Wait(0.1)
				local basic = Sheet.Basic(block)
				local foot = small.AbsolutePosition.Y + small.AbsoluteWindowSize.Y + 1
				local hidden, whole, rows = {} :: { string }, {} :: { string }, {} :: { [number]: number }
				for _, want in basic do
					local item = small:FindFirstChild(want.Name, true)
					if item == nil or not item:IsA("GuiObject") then
						table.insert(hidden, `{want.Name} missing`)
						continue
					end
					if item.AbsolutePosition.Y + item.AbsoluteSize.Y > foot then
						table.insert(hidden, `{want.Name} under the fold`)
					end
					local many = (item.Parent :: Instance):GetAttribute("Across")
					local key = if type(many) == "number" then many else 0
					rows[key] = (rows[key] or 0) + 1
					for _, part in { "Left", "Right", "Main" } do
						local label = item:FindFirstChild(part, true)
						if label and label:IsA("TextLabel") then
							local least = Text.Legible(if part == "Right" then Theme.Text.Body else Theme.Text.Caption, Layers.Scale())
							if not label.TextFits or label.TextSize < least or label.AbsolutePosition.X + label.TextBounds.X > item.AbsolutePosition.X + item.AbsoluteSize.X + 1 then
								table.insert(whole, `{want.Name} {part}: {label.Text} at {label.TextSize}`)
							end
						elseif part ~= "Main" then
							table.insert(whole, `{want.Name} {part} missing`)
						end
					end
				end
				-- Where each line stands, in points from the list's top, to read a miss by.
				local scale, stood = Layers.Scale(), {} :: { GuiObject }
				for _, child in small:GetChildren() do
					if child:IsA("GuiObject") and child.Visible then
						table.insert(stood, child)
					end
				end
				table.sort(stood, function(a: GuiObject, b: GuiObject): boolean
					return a.AbsolutePosition.Y < b.AbsolutePosition.Y
				end)
				local lines = {}
				for index = 1, math.min(#stood, 6) do
					local child = stood[index]
					table.insert(lines, `{child.Name} {math.round((child.AbsolutePosition.Y - small.AbsolutePosition.Y) / scale)}+{math.round(child.AbsoluteSize.Y / scale)}`)
				end
				local stand = `{table.concat(lines, ", ")}; the foot at {math.round(small.AbsoluteWindowSize.Y / scale)}`
				t.Check("the smallest phone: all five Basic Attributes show with nothing scrolled", #basic == 5 and #hidden == 0, if #hidden > 0 then `{hidden[1]}: {stand}` else stand)
				t.Check("the smallest phone: three a row where every word fits a third whole, else two", (rows[3] or 0) + (rows[2] or 0) == #basic, `{rows[3] or 0} three a row, {rows[2] or 0} two`)
				t.Check("the smallest phone: no attribute's name or number cut or shrunk", #whole == 0, whole[1])
				-- Its experience on one line, its bar under the words, the line ending at the bar's foot (AR43's take 2).
				local levelLine = small:FindFirstChild(`Level {owned.Level}`) :: GuiObject?
				local words = if levelLine then levelLine:FindFirstChild("Under") :: TextLabel? else nil
				local xpBar = if levelLine then levelLine:FindFirstChild("Xp") :: GuiObject? else nil
				if levelLine and words and xpBar then
					local oneLine = words.TextBounds.Y <= words.TextSize * 1.5
					local under = xpBar.AbsolutePosition.Y >= words.AbsolutePosition.Y + words.TextBounds.Y - 1
					local ends = math.abs(levelLine.AbsolutePosition.Y + levelLine.AbsoluteSize.Y - (xpBar.AbsolutePosition.Y + xpBar.AbsoluteSize.Y)) <= 1
					t.Check("the smallest phone: its experience on one line, its bar under the words, the line ending at the bar", oneLine and under and ends and words.TextFits,
						`{words.Text}: {words.TextBounds.Y} tall at {words.TextSize}, under {under}, ends {ends}`)
				elseif Growth.XpToNext(owned.Level) then
					t.Check("the smallest phone: its experience line and bar", false)
				end
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
		Name = "Take: AR29's B, the pages and the bar in every state, held as the driver writes, for research",
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
			VoidkinScreen.Last("Bag") -- the card opens the page last shown (AR49)
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
				VoidkinScreen.Show(page)
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
