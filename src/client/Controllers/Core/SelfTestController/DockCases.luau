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
local HomeTray = require(UI.HomeTray)
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
				local tray = HudController.Home()
				t.Check("a tap opens Home's tray (AR43)", Button.Press(inventory) and waitFor(t, 1, function(): boolean
					return HomeTray.Shown(tray)
				end))
				t.Check("and its cell is open while it is, at L Open", looks(inventory, "Open") and math.abs(lit("Home") - make.L.Open) < 0.02, string.format("L %.2f", lit("Home")))
				t.Check("a second tap closes it", Button.Press(inventory) and not HomeTray.Shown(tray))
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
				t.Check("and its lift doesn't open the tray", Screen.Current() == nil and not HomeTray.Shown(tray), tostring(Screen.Current()))
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
			Name = "HUD: Home's tray (AR43): grows out of the Home cell over the dimmed world; Inventory's four and Equipment's three, Settings tall; a tile steps into its own screen, Back brings the tray back; the unbuilt ones refused",
			Run = function(t: any)
				-- AR43 in B (UI.HomeTray; Config.Hud.Home): the dock's Home cell opens a tray grown from its top, a group a row
				-- and Settings tall at the end; a tile lights, the tray folds back as its screen rises, that screen's Back sinks it
				-- and brings the tray back; a tap on the dimmed world closes it.
				Screen.Close()
				local home = HudConfig.Home
				local parts = HudController.Parts()
				local tray = HudController.Home()
				local cell = parts.Home :: TextButton
				if HomeTray.Shown(tray) then
					HomeTray.Close(tray)
				end
				t.Wait(home.Open.Leave + 0.1)
				t.Check("closed, it's out of sight and so is its dim", not tray.Frame.Visible and not tray.Dim.Visible)
				t.Check("Home's cell opens it", Button.Press(cell) and HomeTray.Shown(tray) and tray.Frame.Visible)
				t.Near("it starts small, from the cell", tray.Scale.Scale, home.Open.From, 0.05)
				local most = 0
				local began = os.clock()
				while os.clock() - began < home.Open.Grow + 0.05 do
					most = math.max(most, tray.Scale.Scale)
					t.Wait(0)
				end
				t.Wait(0.1)
				t.Check("it grows past its size a little and settles", most > 1.005 and most < 1.15 and math.abs(tray.Scale.Scale - 1) < 1e-3, string.format("most %.3f, now %.3f", most, tray.Scale.Scale))
				t.Near("shown whole", tray.Group.GroupTransparency, 0, 1e-3)
				-- The dim: the world and the HUD under it edge to edge, all but the dock's rect (home.json), which stays lit.
				local even = true
				for _, panel in tray.Panels do
					even = even and math.abs(1 - panel.BackgroundTransparency - home.Dim.Amount) < 1e-3
				end
				t.Check("the world and the HUD dimmed under it", even)
				local cover = tray.Dim.Parent :: GuiObject
				local hudGui = (parts.Dock :: GuiObject):FindFirstAncestorOfClass("ScreenGui") :: ScreenGui
				local coverGui = cover:FindFirstAncestorOfClass("ScreenGui") :: ScreenGui
				t.Check("over the HUD's layer", coverGui.DisplayOrder > hudGui.DisplayOrder)
				local area = 0
				for _, panel in tray.Panels do
					area += panel.AbsoluteSize.X * panel.AbsoluteSize.Y
				end
				local wide, tall = cover.AbsoluteSize.X, cover.AbsoluteSize.Y
				local seamTop = ((parts.Dock :: Frame):FindFirstChild("Seam") :: GuiObject).AbsolutePosition.Y
				local hudRoot = (parts.Dock :: GuiObject).Parent :: GuiObject
				local footY = hudRoot.AbsolutePosition.Y + hudRoot.AbsoluteSize.Y
				local middleX = hudRoot.AbsolutePosition.X + hudRoot.AbsoluteSize.X / 2
				local s = Layers.Scale()
				local hole = Rect.new(middleX - home.Dim.Side * s, seamTop, middleX + home.Dim.Side * s, footY)
				local holeArea = hole.Width * hole.Height
				t.Check("edge to edge but for the dock's rect", math.abs(area + holeArea - wide * tall) <= wide + tall, string.format("%.0f + %.0f of %.0f px", area, holeArea, wide * tall))
				local docked = parts.Dock :: GuiObject
				local dx0, dx1 = docked.AbsolutePosition.X, docked.AbsolutePosition.X + docked.AbsoluteSize.X
				t.Check("the dock inside the lit rect", dx0 >= hole.Min.X - 1 and dx1 <= hole.Max.X + 1 and seamTop >= hole.Min.Y - 1, string.format("%.0f..%.0f in %.0f..%.0f", dx0, dx1, hole.Min.X, hole.Max.X))
				t.Check("a tap on it closes the tray: its panels take taps", tray.Dim.Interactable and (tray.Panels[1] :: TextButton):IsA("TextButton"))
				local seam = (parts.Dock :: Frame):FindFirstChild("Seam") :: GuiObject
				local scale = s -- the layer's own: an offset is whole points, so the frame's 536.8 lays as 536
				local foot = tray.Frame.AbsolutePosition.Y + tray.Frame.AbsoluteSize.Y
				local middle = tray.Frame.AbsolutePosition.X + tray.Frame.AbsoluteSize.X / 2
				t.Check("its point on the Home cell's top, at its middle", math.abs(foot - seam.AbsolutePosition.Y) / scale <= 1 and math.abs(middle - (cell.AbsolutePosition.X + cell.AbsoluteSize.X / 2)) / scale <= 1, string.format("%.1f, %.1f off", (foot - seam.AbsolutePosition.Y) / scale, (middle - (cell.AbsolutePosition.X + cell.AbsoluteSize.X / 2)) / scale))
				t.Check("Home's cell open while it is", cell:GetAttribute("Selected") == true)
				t.Check("the next step's chip steps out for it", not (parts.Chip :: GuiObject).Visible)
				-- Every tile at its box, its icon and its word; the built ones at rest, the others refused.
				local body = tray.Group:FindFirstChild("Tray") :: GuiObject
				for _, def in home.Tiles do
					local tile = tray.Tiles[def.Name]
					if tile == nil then
						t.Check(`{def.Name}: a tile`, false)
						continue
					end
					local b = tile.Button
					local x, y = (b.AbsolutePosition.X - body.AbsolutePosition.X) / scale, (b.AbsolutePosition.Y - body.AbsolutePosition.Y) / scale
					local built = (def :: any).Page ~= nil
					t.Check(`{def.Name}: at its box, its icon and its word`, math.abs(x - def.Box[1]) <= 0.5 and math.abs(y - def.Box[2]) <= 0.5 and tile.Icon:GetAttribute("Kit") == def.Icon and tile.Word.Text == def.Name, string.format("%.1f, %.1f", x, y))
					t.Equal(`{def.Name}: {if built then "at rest" else "not built yet: faint"}`, b:GetAttribute("Look"), if built then "Rest" else "Soon")
				end
				t.Check("its two headings", body:FindFirstChild("InventoryHeading") ~= nil and body:FindFirstChild("EquipmentHeading") ~= nil)
				local soon = tray.Tiles.Reinforce.Button
				t.Check("an unbuilt tile refuses, and the tray stays", not Button.Press(soon) and HomeTray.Shown(tray) and Screen.Current() == nil)
				-- A tile: lit, the tray folds back to its cell, its page rises as its own screen.
				local kit = tray.Tiles.Kit.Button
				t.Check("Kit's tile takes the press", Button.Press(kit))
				t.Wait(home.Step.Lit / 2)
				t.Equal("lit while it steps", kit:GetAttribute("Look"), "Pressed")
				local stage: GuiObject? = nil
				t.Check("Kit's page opens", waitFor(t, home.Step.Lit + home.Step.RiseAt + 0.5, function(): boolean
					stage = Screen.Stage(VoidkinScreen.Name)
					return Screen.Current() == VoidkinScreen.Name and stage ~= nil
				end), tostring(Screen.Current()))
				local risen = if stage then (stage :: GuiObject).Position.Y.Offset else 0
				t.Check("rising into place", risen > 0 and risen <= home.Step.RiseFrom, string.format("%.1f under", risen))
				t.Check("the tray folding away as it does", not HomeTray.Shown(tray))
				t.Wait(home.Step.Rise + 0.1)
				t.Check("its own screen: no rail, its name in the band", VoidkinScreen.Find("Rail") == nil and (VoidkinScreen.Find("PageName") :: TextLabel?) ~= nil and (VoidkinScreen.Find("PageName") :: TextLabel).Text == "Kit")
				local page = VoidkinScreen.Find("Page")
				t.Check("the panel shows Kit", page ~= nil and page:GetAttribute("Page") == "Kit")
				t.Check("the tray away, Home's cell still open", not tray.Frame.Visible and cell:GetAttribute("Selected") == true)
				-- Back: it sinks, and the tray comes back.
				Screen.Close("Back")
				t.Check("Back brings the tray back", waitFor(t, home.Step.Sink + home.Step.BackAt + 0.5, function(): boolean
					return HomeTray.Shown(tray)
				end) and Screen.Current() == nil)
				t.Wait(home.Open.Grow + 0.1)
				t.Check("whole again", math.abs(tray.Scale.Scale - 1) < 1e-3 and tray.Group.GroupTransparency < 1e-3)
				-- Closed by the world's tap (its dim's close) and by the cell: it folds into the cell, the chip back.
				HomeTray.Close(tray)
				t.Wait(home.Open.Leave + 0.1)
				t.Check("closed: out of sight, the world undimmed, the cell at rest", not tray.Frame.Visible and not tray.Dim.Visible and cell:GetAttribute("Selected") == false)
				-- Where it stands (research's must-fix, 2026-11-19): over the dock's top, its point on the cell, where that covers
				-- neither the lead card nor the currencies; on the smallest phone, over the dock instead, the same size.
				local function covers(): string
					local body = tray.Group:FindFirstChild("Tray") :: Frame
					local a0, a1 = body.AbsolutePosition, body.AbsolutePosition + body.AbsoluteSize
					local hit = {}
					for _, name in { "Lead", "Credits", "Electricity" } do
						local piece = hudRoot:FindFirstChild(name)
						if piece and piece:IsA("GuiObject") and piece.Visible then
							local b0, b1 = piece.AbsolutePosition, piece.AbsolutePosition + piece.AbsoluteSize
							if a0.X < b1.X and a1.X > b0.X and a0.Y < b1.Y and a1.Y > b0.Y then
								table.insert(hit, name)
							end
						end
					end
					local room = Layers.Get("Cover")
					local r0, r1 = room.AbsolutePosition, room.AbsolutePosition + room.AbsoluteSize
					if a0.X < r0.X - 1 or a0.Y < r0.Y - 1 or a1.X > r1.X + 1 or a1.Y > r1.Y + 1 then
						table.insert(hit, "the room's edge")
					end
					return table.concat(hit, ", ")
				end
				local function opened(): boolean
					Button.Press(cell)
					t.Wait(home.Open.Grow + 0.15)
					return HomeTray.Shown(tray)
				end
				t.Check("this window: over the dock's top, its point on the cell", opened() and not tray.Over and tray.Point.Visible)
				t.Check("covering neither the lead card nor the currencies", covers() == "", covers())
				HomeTray.Close(tray)
				t.Wait(home.Open.Leave + 0.1)
				Layers.Force(Theme.Scale.Floor)
				Layers.Box(Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height))
				t.Wait(0.2)
				t.Check("the smallest phone: over the dock instead, no point", opened() and tray.Over and not tray.Point.Visible)
				t.Check("covering neither the lead card nor the currencies, inside the room", covers() == "", covers())
				t.Near("its own size", body.AbsoluteSize.X / Layers.Scale(), home.Size.X, 1)
				local holeLit = true
				for _, panel in tray.Panels do
					local p0, p1 = panel.AbsolutePosition, panel.AbsolutePosition + panel.AbsoluteSize
					local b0, b1 = body.AbsolutePosition + Vector2.one, body.AbsolutePosition + body.AbsoluteSize - Vector2.one
					holeLit = holeLit and not (p0.X < b1.X and p1.X > b0.X and p0.Y < b1.Y and p1.Y > b0.Y)
				end
				t.Check("the dim round the tray, none over it", holeLit)
				HomeTray.Close(tray)
				t.Wait(home.Open.Leave + 0.1)
				Layers.Box(nil)
				Layers.Force(nil)
				t.Wait(0.2)
			end,
		},
		{
			Name = "Take: AR43, Home's tray held for stills: open, a tile pressed, the step into its screen slowed, then the smallest phone, for research",
			Manual = true,
			Stay = true,
			Run = function(t: any)
				-- AR43's captures: each state is held until the driver moves ReplicatedStorage.NL_TakeStep on ("Open",
				-- "Pressed", "Step", "Phone", "PhonePressed", "End") and captures it. "Step" plays Inventory's step forty
				-- times slower, so a capture lands inside it; its numbers are put back before anything else.
				local step = Instance.new("StringValue")
				step.Name = "NL_TakeStep"
				step.Value = "Ready"
				step.Parent = ReplicatedStorage
				local tray = HudController.Home()
				local cell = HudController.Parts().Home :: TextButton
				local inventory = tray.Tiles.Inventory.Button
				local timings = HudConfig.Home.Step :: { [string]: number }
				local kept: { [string]: number } = {}
				for key, value in timings do
					kept[key] = value
				end
				local function restore()
					for key, value in kept do
						timings[key] = value
					end
				end
				local function opened()
					Screen.Close()
					if not HomeTray.Shown(tray) then
						Button.Press(cell)
					end
					t.Wait(HudConfig.Home.Open.Grow + 0.2)
				end
				local states = {
					Open = opened,
					Pressed = function()
						Button.Touch(inventory, true)
					end,
					Step = function()
						Button.Touch(inventory, false)
						for key in timings do
							if key ~= "RiseFrom" and key ~= "LeaveTo" then
								timings[key] *= 40
							end
						end
						Button.Press(inventory)
						t.Wait(timings.Lit + timings.RiseAt + timings.Rise * 0.4)
					end,
					Phone = function()
						restore()
						Screen.Close()
						t.Wait(HudConfig.Motion.Screen.Exit + 0.1)
						Layers.Force(Theme.Scale.Floor)
						Layers.Box(Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height))
						t.Wait(0.2)
						opened()
					end,
					PhonePressed = function()
						Button.Touch(inventory, true)
					end,
				}
				local shown = step.Value
				local began = os.clock()
				while step.Value ~= "End" and os.clock() - began < 300 do
					if step.Value ~= shown then
						shown = step.Value
						local apply = states[shown]
						if apply then
							apply()
						end
						step:SetAttribute("Shown", shown)
					end
					t.Wait(0.1)
				end
				Button.Touch(inventory, false)
				restore()
				Layers.Box(nil)
				Layers.Force(nil)
				HomeTray.Close(tray)
				Screen.Close()
				step:Destroy()
				t.Check("the driver ended it", shown == "End" or step.Value == "End", shown)
			end,
		},
	}
end

return DockCases
