--!strict
-- DockCases (client, Studio only): the dock's cases, a list of their own beside Cases, which joins it as it joins
-- HudCases (Cases' one table had passed what the type solver checks in one piece). The dock of three icons in AR30's make
-- (UI.Dock; Config.Hud.Make.Dock): each cell's glass, light, foot, icon and touch, its light by its state, its call.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local HudConfig = require(Shared.Config.Hud)
local UIKit = require(Shared.Config.UIKit)
local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Button = require(UI.Kit.Button)
local Dock = require(UI.Dock)
local HomePanel = require(UI.HomePanel)
local Fade = require(UI.Kit.Fade)
local Screen = require(UI.Kit.Screen)
local StageScreen = require(UI.StageScreen)
local Layers = require(UI.Layers)
local Theme = require(UI.Theme)
local VoidkinScreen = require(UI.VoidkinScreen)

local DockCases = {}

export type Given = {
	waitFor: (t: any, seconds: number, ok: () -> boolean) -> boolean,
}

function DockCases.Cases(given: Given): { any }
	local waitFor = given.waitFor
	return {
		{
			Name = "HUD: the dock of three icons in the seam's make (AR30): each cell's glass, light, foot, icon and touch at the make's numbers, its light by its press, its screen and its call; a long press shows its word; the Map's, its word Play, opens the Festival's menu",
			Run = function(t: any)
				-- AR30, "The dock" (UI.Dock; Config.Hud.Make.Dock): one dark channel at the foot's middle, each cell its glass lit
				-- from its foot in its room's colour, its icon in Text; held, its light rises and nothing sinks; open while its
				-- screen is; calling, brighter with its edge lit and the pip on its corner; a long press shows its word and
				-- doesn't press.
				Screen.Close()
				local make = HudConfig.Make.Dock
				local seam = UIKit.Palettes.Seam
				local parts = HudController.Parts()
				local dock = parts.Dock :: Frame
				local layer = dock.Parent :: GuiObject
				local middle = dock.AbsolutePosition.X + dock.AbsoluteSize.X / 2 - (layer.AbsolutePosition.X + layer.AbsoluteSize.X / 2)
				t.Check("the dock shows at the foot's middle", dock.Visible and math.abs(middle) <= 1, string.format("%.1f off the middle", middle))
				local scale = dock.AbsoluteSize.X / make.Box.X
				local frame = dock:FindFirstChild("Seam") :: Frame
				local function rel(piece: GuiObject, from: GuiObject): (number, number, number, number)
					return (piece.AbsolutePosition.X - from.AbsolutePosition.X) / scale, (piece.AbsolutePosition.Y - from.AbsolutePosition.Y) / scale, piece.AbsoluteSize.X / scale, piece.AbsoluteSize.Y / scale
				end
				local function near(a: number, b: number): boolean
					return math.abs(a - b) <= 1
				end
				local fx, fy, fw, fh = rel(frame, dock)
				t.Check("its frame the make's, centred where today's dock stood, its foot on today's tiles' foot", near(fw, make.Frame.X) and near(fh, make.Frame.Y) and near(fx + fw / 2, make.Box.X / 2) and near(fy + fh, make.At.Y + make.Frame.Y), string.format("%.1f x %.1f at %.1f, %.1f", fw, fh, fx, fy))
				-- The bag's cell rises over the old tiles' top: the next step's chip stands a gap clear over the dock's frame.
			local chip = parts.Chip :: GuiObject
			local clear = (frame.AbsolutePosition.Y - (chip.AbsolutePosition.Y + chip.AbsoluteSize.Y)) / scale
			t.Check("the next step's chip stands a gap clear over its frame", clear >= Theme.Size.Gap - 0.5, string.format("%.1f clear", clear))
			local hues = { Base = HudConfig.Make.Light.Power, Home = seam.Light, Map = HudConfig.Make.Light.Map }
				local kits = { Base = "DockSeamBase", Home = "DockSeamHome", Map = "DockSeamMap" }
				local function piece(name: string): ImageLabel
					return frame:FindFirstChild(name) :: ImageLabel
				end
				local function lit(name: string): number -- a cell's L, read off its light
					return make.Top * (1 - piece(`{name}Light`).ImageTransparency)
				end
				for _, cell in make.Cells do
					local name = cell.Name
					local glass, light, foot, mark = piece(`{name}Glass`), piece(`{name}Light`), piece(`{name}Foot`), piece(`{name}Mark`)
					local button = frame:FindFirstChild(name) :: TextButton?
					if glass and light and foot and mark and button then
						local gx, gy, gw, gh = rel(glass, frame)
						local size = (make.Glass :: { [string]: Vector2 })[cell.Kind]
						t.Check(`{name}: its glass at its place and size`, near(gx, cell.Glass.X) and near(gy, cell.Glass.Y) and near(gw, size.X) and near(gh, size.Y), string.format("%.1f, %.1f, %.1f x %.1f", gx, gy, gw, gh))
						t.Check(`{name}: its light and foot in its room's colour`, light.ImageColor3 == hues[name] and foot.ImageColor3 == hues[name])
						local mx, my, mw = rel(mark, frame)
						t.Check(`{name}: its icon on its middle, its size`, mark:GetAttribute("Kit") == kits[name] and near(mx + mw / 2, cell.Icon.X) and near(my + mw / 2, cell.Icon.Y) and near(mw, cell.Side), string.format("%.1f, %.1f, %.1f across", mx + mw / 2, my + mw / 2, mw))
						local shown = tostring(button:GetAttribute("Look"))
						local wantL = (make.L :: { [string]: number })[shown] or -1
						local ink = if shown == "Dim" then seam.Faint elseif shown == "Quiet" then seam.Soft else seam.Text
						t.Check(`{name}: {shown}, its light at L {wantL} and its icon in its ink`, math.abs(lit(name) - wantL) < 0.02 and mark.ImageColor3 == ink, string.format("L %.2f", lit(name)))
						local tx, ty, tw, th = rel(button, frame)
						t.Check(`{name}: its touch its column`, near(tx, cell.Tap[1]) and near(ty, cell.Tap[2]) and near(tw, cell.Tap[3]) and near(th, cell.Tap[4]), string.format("%.1f, %.1f, %.1f x %.1f", tx, ty, tw, th))
					else
						t.Check(`{name}: its glass, light, foot, icon and touch`, false)
					end
				end
				local inventory = parts.Home :: TextButton
				local function looks(button: TextButton, want: string): boolean
					return waitFor(t, 0.5, function(): boolean
						return button:GetAttribute("Look") == want
					end)
				end
				t.Check("Home's cell at rest", looks(inventory, "Rest"), tostring(inventory:GetAttribute("Look")))
				local mark = piece("HomeMark")
				local restY = mark.AbsolutePosition.Y
				Button.Touch(inventory, true)
				t.Check("held, its light rises to a press's", looks(inventory, "Pressed") and math.abs(lit("Home") - make.L.Pressed) < 0.02, string.format("L %.2f", lit("Home")))
				t.Near("and nothing sinks", (mark.AbsolutePosition.Y - restY) / scale, 0, 0.3)
				Button.Touch(inventory, false)
				t.Check("let go, it's back at rest", looks(inventory, "Rest"), tostring(inventory:GetAttribute("Look")))
				local panel = HudController.Home()
				t.Check("a tap opens Home's panel (AR49)", Button.Press(inventory) and waitFor(t, 1, function(): boolean
					return HomePanel.Shown(panel)
				end))
				t.Check("and its cell is open while it is, at L Open", looks(inventory, "Open") and math.abs(lit("Home") - make.L.Open) < 0.02, string.format("L %.2f", lit("Home")))
				t.Check("a second tap closes it", Button.Press(inventory) and not HomePanel.Shown(panel))
				t.Check("and its cell is at rest once it closes", looks(inventory, "Rest"), tostring(inventory:GetAttribute("Look")))
				t.Wait(HudConfig.Motion.Screen.Exit + 0.1)
				-- A dock of the test's own for what this save's state may not show: a call, a charge, a quiet cell.
				local gui = Instance.new("ScreenGui")
				gui.Name = "NL_TestDock"
				gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
				local own = Dock.new(gui, {})
				local ownFrame = own.Frame:FindFirstChild("Seam") :: Frame
				local function its(name: string): ImageLabel
					return ownFrame:FindFirstChild(name) :: ImageLabel
				end
				local function ownL(name: string): number
					return make.Top * (1 - its(`{name}Light`).ImageTransparency)
				end
				Dock.Pip(own, "Home", true)
				Dock.Paint(own)
				local call, glow, ring = its("HomeCall"), its("HomePipGlow"), its("HomePip")
				local ownScale = own.Frame.AbsoluteSize.X / make.Box.X
				local px = (ring.AbsolutePosition.X - ownFrame.AbsolutePosition.X) / ownScale
				local py = (ring.AbsolutePosition.Y - ownFrame.AbsolutePosition.Y) / ownScale
				local pw = ring.AbsoluteSize.X / ownScale
				local cell = make.Cells[2]
				t.Check("calling, its light at L Calling and its whole edge lit in its colour", math.abs(ownL("Home") - make.L.Calling) < 0.02 and call.Visible and call.ImageColor3 == seam.Light, string.format("L %.2f", ownL("Home")))
				t.Check("and the pip on its far corner, its glow in its colour over an ink ring", glow.Visible and ring.Visible and ring.ImageColor3 == seam.Ink and its("HomePipHue").Visible and its("HomePipLight").Visible and near(px + pw / 2, cell.Pip.X) and near(py + pw / 2, cell.Pip.Y) and near(pw, make.Pip.Rings[1]), string.format("%.1f, %.1f, %.1f across", px + pw / 2, py + pw / 2, pw))
				Dock.Pip(own, "Home", false)
				t.Check("its call gone, back at L Rest", not call.Visible and not ring.Visible and math.abs(ownL("Home") - make.L.Rest) < 0.02)
				Dock.Charges(own, "Base", true)
				Dock.Fill(own, "Base", 0.5)
				Dock.Paint(own)
				local ownBase = own.Tiles.Base.Button
				local inked = its("BaseGlass")
				t.Check("a charge: its glass in ink, no light, the fill over it", ownBase:GetAttribute("Look") == "Charge" and inked.ImageColor3 == HudConfig.Dock.Charge.Ink and inked:FindFirstChildOfClass("UIGradient") == nil and ownL("Base") < 0.02 and its("BaseFill").Visible)
				Dock.Fill(own, "Base", nil)
				Dock.Mood(own, "Base", "Quiet")
				Dock.Paint(own)
				t.Check("quiet: at L Quiet, its icon in Soft, its glass back in the Panel gradient", ownBase:GetAttribute("Look") == "Quiet" and math.abs(ownL("Base") - make.L.Quiet) < 0.02 and its("BaseMark").ImageColor3 == seam.Soft and inked:FindFirstChildOfClass("UIGradient") ~= nil)
				gui:Destroy()
				local word = dock:FindFirstChild("HomeWord", true) :: TextLabel
				Dock.Hold(inventory, true)
				t.Check("a long press shows its word", waitFor(t, HudConfig.Dock.LongPress + 0.3, function(): boolean
					return word.Visible
				end) and word.Text == "Home", word.Text)
				Button.Press(inventory)
				Dock.Hold(inventory, false)
				t.Wait(0.4)
				t.Check("and its lift doesn't open the panel", Screen.Current() == nil and not HomePanel.Shown(panel), tostring(Screen.Current()))
				t.Check("the word goes a moment after", waitFor(t, 1, function(): boolean
					return not word.Visible
				end))
				-- The Map's cell, its word Play (TR45): at rest like the others, and a tap opens the Festival's menu.
				local map = parts.Map :: TextButton
				t.Check("the Map's cell at rest", looks(map, "Rest"), tostring(map:GetAttribute("Look")))
				t.Equal("its word is Play", (dock:FindFirstChild("MapWord", true) :: TextLabel).Text, "Play")
				t.Check("a tap opens the Festival's menu", Button.Press(map) and waitFor(t, 1, function(): boolean
					return Screen.Current() == StageScreen.Name
				end), tostring(Screen.Current()))
				Screen.Close()
			end,
		},
		{
			Name = "HUD: Home's panel (AR49): grows over the dimmed world, the cards landing in turn; clear of the lead's card, its pointer on the Home cell; the lead live under its frame, a press never over it; a card steps into its screen on the page last shown, Back brings the panel back; the smallest phone",
			Run = function(t: any)
				-- AR49 in C (UI.HomePanel; Config.Hud.Home): three cards on dark glass, each its own art in its frame; Voidkin the
				-- lead live (Figure.Bust), its head rising out of the frame; a card lights, the panel makes way as its screen
				-- rises, that screen's Back brings the panel back; a tap on the dimmed world closes it.
				Screen.Close()
				local home = HudConfig.Home
				local parts = HudController.Parts()
				local panel = HudController.Home()
				local cell = parts.Home :: TextButton
				if HomePanel.Shown(panel) then
					HomePanel.Close(panel)
				end
				t.Wait(home.Open.Leave + 0.1)
				t.Check("closed, it's out of sight and so is its dim", not panel.Frame.Visible and not panel.Dim.Visible)
				t.Check("Home's cell opens it", Button.Press(cell) and HomePanel.Shown(panel) and panel.Frame.Visible)
				t.Near("it starts a little small", panel.Scale.Scale, home.Open.From, 0.05)
				local most = 0
				local began = os.clock()
				while os.clock() - began < home.Open.Grow + 0.05 do
					most = math.max(most, panel.Scale.Scale)
					t.Wait(0)
				end
				local landed = (#home.Open.Order - 1) * home.Open.Stagger + home.Open.Land
				t.Wait(math.max(landed - home.Open.Grow, 0) + 0.1)
				t.Check("it grows past its size a little and settles", most > 1.002 and most < 1.15 and math.abs(panel.Scale.Scale - 1) < 1e-3, string.format("most %.3f, now %.3f", most, panel.Scale.Scale))
				t.Near("shown whole", panel.Shown, 1, 1e-3)
				local settled = true
				for _, name in home.Open.Order do
					local card = panel.Cards[name]
					settled = settled and card ~= nil and card.Holder.Position.Y.Offset == 0 and Fade.Of(card.Holder) > 0.999
				end
				t.Check("each card landed, risen into place and whole", settled)
				-- The dim: the world and the HUD under it edge to edge, all but the dock's rect, which stays lit.
				local even = true
				for _, each in panel.Panels do
					even = even and math.abs(1 - each.BackgroundTransparency - home.Dim.Amount) < 1e-3
				end
				t.Check("the world and the HUD dimmed under it", even)
				local cover = panel.Dim.Parent :: GuiObject
				local hudGui = (parts.Dock :: GuiObject):FindFirstAncestorOfClass("ScreenGui") :: ScreenGui
				local coverGui = cover:FindFirstAncestorOfClass("ScreenGui") :: ScreenGui
				t.Check("over the HUD's layer", coverGui.DisplayOrder > hudGui.DisplayOrder)
				local area = 0
				for _, each in panel.Panels do
					area += each.AbsoluteSize.X * each.AbsoluteSize.Y
				end
				local wide, tall = cover.AbsoluteSize.X, cover.AbsoluteSize.Y
				local seamTop = ((parts.Dock :: Frame):FindFirstChild("Seam") :: GuiObject).AbsolutePosition.Y
				local hudRoot = (parts.Dock :: GuiObject).Parent :: GuiObject
				local footY = hudRoot.AbsolutePosition.Y + hudRoot.AbsoluteSize.Y
				local middleX = hudRoot.AbsolutePosition.X + hudRoot.AbsoluteSize.X / 2
				local s = Layers.Scale()
				local hole = Rect.new(middleX - home.Dim.Side * s, seamTop, middleX + home.Dim.Side * s, footY)
				t.Check("edge to edge but for the dock's rect", math.abs(area + hole.Width * hole.Height - wide * tall) <= wide + tall, string.format("%.0f + %.0f of %.0f px", area, hole.Width * hole.Height, wide * tall))
				t.Check("a tap on it closes the panel: its panels take taps", panel.Dim.Interactable and (panel.Panels[1] :: TextButton):IsA("TextButton"))
				t.Check("Home's cell open while it is", cell:GetAttribute("Selected") == true)
				t.Check("the next step's chip steps out for it", not (parts.Chip :: GuiObject).Visible)
				-- Where it stands: its foot Above over the dock's top, its pointer's middle on the Home cell's, its left clear of
				-- the lead's card, inside the room.
				local function standing(): string
					local f0, f1 = panel.Frame.AbsolutePosition, panel.Frame.AbsolutePosition + panel.Frame.AbsoluteSize
					local scale = Layers.Scale()
					local wrong = {}
					local top = ((parts.Dock :: Frame):FindFirstChild("Seam") :: GuiObject).AbsolutePosition.Y
					if math.abs((top - f1.Y) / scale - home.Above) > 1 then
						table.insert(wrong, string.format("foot %.1f over the dock", (top - f1.Y) / scale))
					end
					local pointer = panel.Pointer
					local pointerMiddle = pointer.AbsolutePosition.X + pointer.AbsoluteSize.X / 2
					local cellMiddle = cell.AbsolutePosition.X + cell.AbsoluteSize.X / 2
					if math.abs(pointerMiddle - cellMiddle) / scale > 1 then
						table.insert(wrong, string.format("pointer %.1f off the cell", (pointerMiddle - cellMiddle) / scale))
					end
					local lead = parts.Lead :: GuiObject
					if lead.Visible and f0.X < lead.AbsolutePosition.X + lead.AbsoluteSize.X + (home.Gap - 1) * scale and f1.Y > lead.AbsolutePosition.Y then
						table.insert(wrong, "over the lead's card")
					end
					local room = Layers.Get("Hud") -- the phone's safe area: the cover runs under a notch, and past a test's box
					local r0, r1 = room.AbsolutePosition, room.AbsolutePosition + room.AbsoluteSize
					if f0.X < r0.X - 1 or f0.Y < r0.Y - 1 or f1.X > r1.X - (home.Edge - 1) * scale or f1.Y > r1.Y + 1 then
						table.insert(wrong, "past the room's edge")
					end
					return table.concat(wrong, ", ")
				end
				t.Check("this window: over the dock, its pointer on the cell, clear of the lead's card, in the room", standing() == "", standing())
				-- A corner piece the glass would cut mid-word fades under it (Modulo's build note).
				t.Wait(0.3)
				local through = HudController.SeeThrough()
				local f0, f1 = panel.Frame.AbsolutePosition, panel.Frame.AbsolutePosition + panel.Frame.AbsoluteSize
				local cut = {}
				for _, name in { "Credits", "Electricity" } do
					local root = hudRoot:FindFirstChild(name)
					if root and root:IsA("GuiObject") and root.Visible then
						local a0, a1 = root.AbsolutePosition, root.AbsolutePosition + root.AbsoluteSize
						if a0.X < f1.X and a1.X > f0.X and a0.Y < f1.Y and a1.Y > f0.Y and (through[name] or 1) > 0.05 then
							table.insert(cut, string.format("%s %.2f", name, through[name] or 1))
						end
					end
				end
				t.Check("no corner piece shows under the glass", #cut == 0, table.concat(cut, ", "))
				-- Each card: its art, its word whole, at rest.
				for _, def in home.Cards do
					local card = panel.Cards[def.Name]
					if card == nil then
						t.Check(`{def.Name}: a card`, false)
						continue
					end
					local laid = 0
					for _, image in card.Holder:GetChildren() do
						laid += if image:IsA("ImageLabel") and image:GetAttribute("Kit") ~= nil then 1 else 0
					end
					local label = card.Holder:FindFirstChild("Word") :: TextLabel?
					local whole = label ~= nil and label.Text == def.Name and label.TextFits
					t.Check(`{def.Name}: its art laid, its word whole, at rest`, laid >= #def.Images + 1 and whole and card.Button:GetAttribute("Look") == "Rest", `{laid} images, {if label then label.Text else "no word"}`)
				end
				local level = panel.Cards.Equipment.Holder:FindFirstChild("Level") :: TextLabel?
				t.Check("Equipment's +7 whole", level ~= nil and level.Text == "+7" and level.TextFits)
				t.Check("Settings' cog", panel.Cards.Settings.Holder:FindFirstChild("Mark") ~= nil)
				-- The lead live (research's condition 2) and its press under it (condition 1).
				local voidkin = panel.Cards.Voidkin
				local live = voidkin.Holder:FindFirstChild("Live") :: ViewportFrame?
				t.Check("the lead live in its card", live ~= nil and panel.LeadDef ~= nil and live:FindFirstChildOfClass("WorldModel") ~= nil and live.CurrentCamera ~= nil, tostring(panel.LeadDef))
				local frameImage = voidkin.Holder:FindFirstChild("HomeVoidkinFrame") :: ImageLabel?
				t.Check("its frame over it, its press under it", live ~= nil and frameImage ~= nil and voidkin.Press.ZIndex < live.ZIndex and live.ZIndex < frameImage.ZIndex, if live and frameImage then `press {voidkin.Press.ZIndex}, live {live.ZIndex}, frame {frameImage.ZIndex}` else "missing")
				Button.Touch(voidkin.Button, true)
				t.Check("held, it lights: its press shows", waitFor(t, 0.5, function(): boolean
					return voidkin.Press.Visible and voidkin.Button:GetAttribute("Look") == "Pressed"
				end))
				Button.Touch(voidkin.Button, false)
				t.Check("let go, it's back at rest", waitFor(t, 0.5, function(): boolean
					return not voidkin.Press.Visible and voidkin.Button:GetAttribute("Look") == "Rest"
				end))
				-- A card: lit, the panel makes way, its screen rises on the page last shown.
				t.Equal("the page last shown, Kit", VoidkinScreen.Last("Kit"), "Kit")
				t.Check("Voidkin's card takes the press", Button.Press(voidkin.Button))
				t.Wait(home.Step.Lit / 2)
				t.Equal("lit while it steps", voidkin.Button:GetAttribute("Look"), "Pressed")
				local stage: GuiObject? = nil
				t.Check("the Voidkin screen opens", waitFor(t, home.Step.Lit + home.Step.RiseAt + 0.5, function(): boolean
					stage = Screen.Stage(VoidkinScreen.Name)
					return Screen.Current() == VoidkinScreen.Name and stage ~= nil
				end), tostring(Screen.Current()))
				local risen = if stage then (stage :: GuiObject).Position.Y.Offset else 0
				t.Check("rising into place", risen > 0 and risen <= home.Step.RiseFrom, string.format("%.1f under", risen))
				t.Check("the panel making way as it does", not HomePanel.Shown(panel))
				t.Wait(home.Step.Rise + 0.1)
				local page = VoidkinScreen.Find("Page")
				t.Check("on Kit, the page last shown", page ~= nil and page:GetAttribute("Page") == "Kit")
				t.Check("the panel away, Home's cell still open", not panel.Frame.Visible and cell:GetAttribute("Selected") == true)
				Screen.Close("Back")
				t.Check("Back brings the panel back", waitFor(t, home.Step.Sink + home.Step.BackAt + 0.5, function(): boolean
					return HomePanel.Shown(panel)
				end) and Screen.Current() == nil)
				t.Wait(landed + 0.1)
				t.Check("whole again", math.abs(panel.Scale.Scale - 1) < 1e-3 and panel.Shown > 0.999)
				t.Equal("and Kit kept as the page last shown", VoidkinScreen.Last(), "Kit")
				VoidkinScreen.Last("Bag")
				HomePanel.Close(panel)
				t.Wait(home.Open.Leave + home.Dim.Seconds + 0.1)
				t.Check("closed: out of sight, the world undimmed, the cell at rest", not panel.Frame.Visible and not panel.Dim.Visible and cell:GetAttribute("Selected") == false)
				-- The smallest phone: the same size, clear of the lead's card and inside the room.
				Layers.Force(Theme.Scale.Floor)
				Layers.Box(Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height))
				t.Wait(0.2)
				Button.Press(cell)
				t.Wait(landed + 0.15)
				t.Check("the smallest phone: over the dock, its pointer on the cell, clear of the lead's card, in the room", HomePanel.Shown(panel) and standing() == "", standing())
				t.Near("its own size", panel.Frame.AbsoluteSize.X / Layers.Scale(), home.Size.X, 1)
				local words = true
				for _, card in panel.Cards do
					for _, label in card.Holder:GetChildren() do
						if label:IsA("TextLabel") then
							words = words and label.TextFits
						end
					end
				end
				t.Check("every word whole", words)
				HomePanel.Close(panel)
				t.Wait(home.Open.Leave + 0.1)
				Layers.Box(nil)
				Layers.Force(nil)
				t.Wait(0.2)
			end,
		},
		{
			Name = "Take: AR49, Home's panel held for stills: open, each card pressed, two other leads, then the smallest phone, for research",
			Manual = true,
			Stay = true,
			Run = function(t: any)
				-- AR49's captures: each state is held until the driver moves ReplicatedStorage.NL_TakeStep on ("Open",
				-- "Voidkin", "Equipment", "Settings", "Lead:<def>" for any Voidkin, "Phone", "PhoneVoidkin", "End") and
				-- captures it. A card named is held pressed, the others let go; a lead named is shown live, the save's put back
				-- at the end.
				local step = Instance.new("StringValue")
				step.Name = "NL_TakeStep"
				step.Value = "Ready"
				step.Parent = ReplicatedStorage
				local panel = HudController.Home()
				local cell = HudController.Parts().Home :: TextButton
				local own = panel.LeadDef
				local function letGo()
					for _, card in panel.Cards do
						Button.Touch(card.Button, false)
					end
				end
				local function opened()
					Screen.Close()
					letGo()
					if not HomePanel.Shown(panel) then
						Button.Press(cell)
					end
					t.Wait(HudConfig.Home.Open.Grow + 0.3)
				end
				local function held(name: string)
					letGo()
					Button.Touch(panel.Cards[name].Button, true)
				end
				local states: { [string]: () -> () } = {
					Open = opened,
					Voidkin = function()
						held("Voidkin")
					end,
					Equipment = function()
						held("Equipment")
					end,
					Settings = function()
						held("Settings")
					end,
					Phone = function()
						letGo()
						HomePanel.Close(panel)
						t.Wait(HudConfig.Home.Open.Leave + 0.1)
						Layers.Force(Theme.Scale.Floor)
						Layers.Box(Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height))
						t.Wait(0.2)
						opened()
					end,
					PhoneVoidkin = function()
						held("Voidkin")
					end,
				}
				local shown = step.Value
				local began = os.clock()
				while step.Value ~= "End" and os.clock() - began < 300 do
					if step.Value ~= shown then
						shown = step.Value
						local def = string.match(shown, "^Lead:(.+)$")
						if def then
							letGo()
							HomePanel.Lead(panel, def)
						else
							local apply = states[shown]
							if apply then
								apply()
							end
						end
						step:SetAttribute("Shown", shown)
					end
					t.Wait(0.1)
				end
				letGo()
				HomePanel.Lead(panel, own)
				Layers.Box(nil)
				Layers.Force(nil)
				HomePanel.Close(panel)
				Screen.Close()
				step:Destroy()
				t.Check("the driver ended it", shown == "End" or step.Value == "End", shown)
			end,
		},
	}
end

return DockCases
