--!strict
-- DockCases (client, Studio only): the dock's cases, a list of their own beside Cases, which joins it as it joins
-- HudCases (Cases' one table had passed what the type solver checks in one piece). The dock of three icons in AR30's make
-- (UI.Dock; Config.Hud.Make.Dock): each cell's glass, light, foot, icon and touch, its light by its state, its call.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local HudConfig = require(Shared.Config.Hud)
local UIKit = require(Shared.Config.UIKit)
local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Button = require(UI.Kit.Button)
local Dock = require(UI.Dock)
local Screen = require(UI.Kit.Screen)
local Theme = require(UI.Theme)

local DockCases = {}

export type Given = {
	waitFor: (t: any, seconds: number, ok: () -> boolean) -> boolean,
}

function DockCases.Cases(given: Given): { any }
	local waitFor = given.waitFor
	return {
		{
			Name = "HUD: the dock of three icons in the seam's make (AR30): each cell's glass, light, foot, icon and touch at the make's numbers, its light by its press, its screen and its call; a long press shows its word, the Map's is dim",
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
			local hues = { Base = HudConfig.Make.Light.Power, Inventory = seam.Light, Map = HudConfig.Make.Light.Map }
				local kits = { Base = "DockSeamBase", Inventory = "PageItems", Map = "DockSeamMap" }
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
				local inventory = parts.Voidkin :: TextButton
				local function looks(button: TextButton, want: string): boolean
					return waitFor(t, 0.5, function(): boolean
						return button:GetAttribute("Look") == want
					end)
				end
				t.Check("Inventory's cell at rest", looks(inventory, "Rest"), tostring(inventory:GetAttribute("Look")))
				local mark = piece("InventoryMark")
				local restY = mark.AbsolutePosition.Y
				Button.Touch(inventory, true)
				t.Check("held, its light rises to a press's", looks(inventory, "Pressed") and math.abs(lit("Inventory") - make.L.Pressed) < 0.02, string.format("L %.2f", lit("Inventory")))
				t.Near("and nothing sinks", (mark.AbsolutePosition.Y - restY) / scale, 0, 0.3)
				Button.Touch(inventory, false)
				t.Check("let go, it's back at rest", looks(inventory, "Rest"), tostring(inventory:GetAttribute("Look")))
				t.Check("a tap opens the Voidkin screen", Button.Press(inventory) and waitFor(t, 1, function(): boolean
					return Screen.Current() == "Voidkin"
				end))
				t.Check("and its cell is open while it is, at L Open", looks(inventory, "Open") and math.abs(lit("Inventory") - make.L.Open) < 0.02, string.format("L %.2f", lit("Inventory")))
				Screen.Close()
				t.Check("and at rest once it closes", looks(inventory, "Rest"), tostring(inventory:GetAttribute("Look")))
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
				Dock.Pip(own, "Inventory", true)
				Dock.Paint(own)
				local call, glow, ring = its("InventoryCall"), its("InventoryPipGlow"), its("InventoryPip")
				local ownScale = own.Frame.AbsoluteSize.X / make.Box.X
				local px = (ring.AbsolutePosition.X - ownFrame.AbsolutePosition.X) / ownScale
				local py = (ring.AbsolutePosition.Y - ownFrame.AbsolutePosition.Y) / ownScale
				local pw = ring.AbsoluteSize.X / ownScale
				local cell = make.Cells[2]
				t.Check("calling, its light at L Calling and its whole edge lit in its colour", math.abs(ownL("Inventory") - make.L.Calling) < 0.02 and call.Visible and call.ImageColor3 == seam.Light, string.format("L %.2f", ownL("Inventory")))
				t.Check("and the pip on its far corner, its glow in its colour over an ink ring", glow.Visible and ring.Visible and ring.ImageColor3 == seam.Ink and its("InventoryPipHue").Visible and its("InventoryPipLight").Visible and near(px + pw / 2, cell.Pip.X) and near(py + pw / 2, cell.Pip.Y) and near(pw, make.Pip.Rings[1]), string.format("%.1f, %.1f, %.1f across", px + pw / 2, py + pw / 2, pw))
				Dock.Pip(own, "Inventory", false)
				t.Check("its call gone, back at L Rest", not call.Visible and not ring.Visible and math.abs(ownL("Inventory") - make.L.Rest) < 0.02)
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
				local word = dock:FindFirstChild("InventoryWord", true) :: TextLabel
				Dock.Hold(inventory, true)
				t.Check("a long press shows its word", waitFor(t, HudConfig.Dock.LongPress + 0.3, function(): boolean
					return word.Visible
				end) and word.Text == "Inventory", word.Text)
				Button.Press(inventory)
				Dock.Hold(inventory, false)
				t.Wait(0.4)
				t.Check("and its lift doesn't open the screen", Screen.Current() == nil, tostring(Screen.Current()))
				t.Check("the word goes a moment after", waitFor(t, 1, function(): boolean
					return not word.Visible
				end))
				local map = parts.Map :: TextButton
				t.Check("the Map's cell is dim: no light, its foot dim, its icon in Faint", looks(map, "Dim") and lit("Map") < 0.02 and math.abs(piece("MapFoot").ImageTransparency - make.DimFoot) < 1e-3 and piece("MapMark").ImageColor3 == seam.Faint, tostring(map:GetAttribute("Look")))
				t.Check("and a tap opens nothing", not Button.Press(map) and Screen.Current() == nil)
				Screen.Close()
			end,
		},
	}
end

return DockCases
