--!strict
-- HudCases (client, Studio only): the HUD's and the kit's newer cases, a list of their own beside Cases, which joins it
-- as it joins VoidkinCases (Cases' one table had passed what the type solver checks in one piece). The dock's Base tile
-- as the way home (TR19), everything that presses answering the pointer (TR20), and a plate kept clear of the lead's corner.

local ContentProvider = game:GetService("ContentProvider")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Combat = require(Shared.Config.Combat)
local HomeConfig = require(Shared.Config.Home)
local HudConfig = require(Shared.Config.Hud)
local BaseViewConfig = require(Shared.Config.BaseView)
local WorldConfig = require(Shared.Config.World)
local UIKit = require(Shared.Config.UIKit)
local Markers = require(Shared.World.Markers)
local Parts = require(Shared.Util.Parts)
local EffectsConfig = require(Shared.Config.Effects)
local Flight = require(Shared.Rules.Flight)
local Progress = require(Shared.Rules.Progress)
local Grounds = require(Shared.Definitions.Grounds)
local Effects = require(script.Parent.Parent.Parent.Main.FighterController.Effects)
local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local BaseController = require(script.Parent.Parent.Parent.Main.BaseController)
local DownController = require(script.Parent.Parent.Parent.Main.DownController)
local ProfileController = require(script.Parent.Parent.ProfileController)
local Helpers = require(script.Parent.Helpers)
local UI = script.Parent.Parent.Parent.Parent.UI
local Slate = require(UI.Kit.Slate)
local Readout = require(UI.Readout)
local BreakerScreen = require(UI.BreakerScreen)
local VoidkinScreen = require(UI.VoidkinScreen)
local Button = require(UI.Kit.Button)
local BaseView = require(UI.BaseView)
local Hover = require(UI.Kit.Hover)
local Screen = require(UI.Kit.Screen)
local Toast = require(UI.Kit.Toast)
local Layers = require(UI.Layers)
local Theme = require(UI.Theme)
local World = require(UI.World)
local Guide = require(UI.Guide)

local HudCases = {}

-- Cases' own helpers and measures, one home each.
export type Given = {
	REPLICATE: number,
	LEAD_SETTLE: number,
	ANSWER: number,
	ARRIVE_TIMEOUT: number,
	PLATE_TICK: number,
	SET_DOWN: number,
	R6_ROOT_HEIGHT: number,
	waitFor: (t: any, seconds: number, ok: () -> boolean) -> boolean,
	streamed: (t: any, name: string, where: { [string]: any }?) -> Instance?,
	lintClean: (t: any, where: string) -> (),
	myLead: () -> Model?,
}

-- The battery's mark in the Power pill (research, TR41 (e); docs/ui.md, the top right): before the battery's reading,
-- its gap to the words, its middle on their line, clear of the generation's words, its cells as the charge says.
function HudCases.PillBattery(t: any, parts: { [string]: any }, kwh: number, capacity: number)
	local mark = parts.PowerBattery :: ImageLabel
	local stored = parts.PowerStored :: TextLabel
	local value = parts.Electricity :: TextLabel
	Helpers.batteryCells(t, mark, kwh, capacity, "the Power pill")
	local look = HudConfig.Power.PillMark
	local scale = mark.AbsoluteSize.X / look.Side
	local words = stored.AbsolutePosition.X + stored.AbsoluteSize.X - stored.TextBounds.X
	local gap = words - (mark.AbsolutePosition.X + mark.AbsoluteSize.X)
	t.Near("the pill's battery mark stands its gap before the reading, in points", gap / scale, look.Gap, 0.75)
	local middle = mark.AbsolutePosition.Y + mark.AbsoluteSize.Y / 2
	local line = stored.AbsolutePosition.Y + stored.AbsoluteSize.Y / 2
	t.Check("its middle on the reading's line", math.abs(middle - line) <= 1, string.format("%.1f against %.1f", middle, line))
	local past = value.AbsolutePosition.X + value.TextBounds.X
	t.Check("clear of the generation's words", mark.AbsolutePosition.X >= past + scale, string.format("its left %.1f, the words end %.1f", mark.AbsolutePosition.X, past))
	t.Check("not the pill's own mark: that stays the bolt", (mark.Parent :: Instance):FindFirstChild("Mark") ~= mark)
end

-- The lead card's level on a badge on the portrait's frame (TR24, the director's run, fix 6), for the lead card's case in
-- Cases: over the frame's foot and inside its width, the old tab gone; take A's colours (AR12, research's pick of
-- 2026-11-17): the Voidkin's Block under the chevrons and the number in ink, the plate's edge its lavender, the words its
-- pale; the number on the block; its foot above the eye under the card. `scale` is the card's points to pixels.
function HudCases.LevelBadge(t: any, parts: { [string]: any }, scale: number)
	-- AR62, B in F2's finish: a gold badge astride the portrait's foot, across the card's left edge, its number white on
	-- it in the gold's stroke; the name white.
	local lead = parts.Lead :: Frame
	local badge = lead:FindFirstChild("LevelBadge") :: Frame?
	local portrait = parts.LeadPortrait :: GuiObject
	if not t.Check("its level on a badge", badge ~= nil and badge:IsA("Frame") and lead:FindFirstChild("LevelPlate") == nil, "no LevelBadge") or not badge then
		return
	end
	local top, foot = badge.AbsolutePosition.Y, badge.AbsolutePosition.Y + badge.AbsoluteSize.Y
	local left, right = badge.AbsolutePosition.X, badge.AbsolutePosition.X + badge.AbsoluteSize.X
	local face = portrait.AbsolutePosition.Y + portrait.AbsoluteSize.Y
	local edge = lead.AbsolutePosition.X
	t.Check("the badge astride the portrait's foot, across the card's left edge", top < face and foot > face and left < edge
		and right > edge and left <= portrait.AbsolutePosition.X + 1,
		string.format("%.0f to %.0f over %.0f; %.0f to %.0f across %.0f, the portrait from %.0f", top, foot, face, left, right, edge,
			portrait.AbsolutePosition.X))
	local slate = HudConfig.Slate
	local top0 = HudCases.BadgeTop(parts)
	local number = parts.LeadLevel :: TextLabel
	t.Check("F2's colours: the badge gold, its number white, the name white",
		top0 == slate.Sides.Gold.Fill[1] and number.TextColor3 == slate.Ink and (parts.LeadName :: TextLabel).TextColor3 == slate.Ink,
		`{top0:ToHex()}, {number.TextColor3:ToHex()}, {(parts.LeadName :: TextLabel).TextColor3:ToHex()}`)
	local middle = number.AbsolutePosition + number.AbsoluteSize / 2
	t.Check("the number on the badge", middle.X > left and middle.X < right and middle.Y > top and middle.Y < foot,
		string.format("the number at %.0f, %.0f; the badge %.0f..%.0f, %.0f..%.0f", middle.X, middle.Y, left, right, top, foot))
	local _ = scale
end

-- The foe card's rims (AR62, B in F2's finish): an elite's gold band in its ring stack and a second rim outside the
-- plate, or the coral band that says theirs and no second.
function HudCases.Rims(t: any, parts: { [string]: any }, elite: boolean)
	local card = parts.Target :: Frame
	local glass = card:FindFirstChild("Glass")
	local dark = if glass then glass:FindFirstChild("Dark") else nil
	local band = if dark then dark:FindFirstChild("Band") else nil
	local paint = if band then band:FindFirstChild("Paint") :: UIGradient? else nil
	local slate = HudConfig.Slate
	local family = if elite then slate.Sides.Elite else slate.Sides.Theirs
	local lit = if paint then paint.Color.Keypoints[1].Value else nil
	t.Check(if elite then "its band the gold" else "with the coral band that says theirs", lit ~= nil and lit == family.Band[1]
		and card:GetAttribute("Side") == (if elite then "Elite" else "Theirs"), if lit then lit:ToHex() else "no band")
	local outer = parts.TargetElite :: Frame
	local line = outer:FindFirstChild("Line") :: UIStroke?
	if elite then
		t.Check("and the second rim outside the plate", outer.Visible and line ~= nil and line.Color == slate.Sides.Elite.Band[2]
			and outer.AbsoluteSize.X > card.AbsoluteSize.X)
	else
		t.Check("and no second rim", not outer.Visible)
	end
end

-- The top of the level badge's fill now: the level-up's pop lifts it toward white (UI.LeadCard.Glow).
function HudCases.BadgeTop(parts: { [string]: any }): Color3
	local badge = (parts.Lead :: Frame):FindFirstChild("LevelBadge")
	local fill = if badge then Slate.FillOf(badge) else nil
	local body = if fill then fill:FindFirstChild("Paint") :: UIGradient? else nil
	return if body then body.Color.Keypoints[1].Value else Color3.new()
end

function HudCases.Cases(given: Given): { any }
	local REPLICATE, LEAD_SETTLE, SET_DOWN, R6_ROOT_HEIGHT = given.REPLICATE, given.LEAD_SETTLE, given.SET_DOWN, given.R6_ROOT_HEIGHT
	local waitFor, streamed, lintClean, myLead = given.waitFor, given.streamed, given.lintClean, given.myLead
	local ANSWER, ARRIVE_TIMEOUT, PLATE_TICK = given.ANSWER, given.ARRIVE_TIMEOUT, given.PLATE_TICK

	-- TR10's down marker stood where the world has none (DownController.Try): `kind` for `def`, 272 seconds left, `away`
	-- studs ahead of the camera, flat, its plate on the ray through the HUD's middle a third down, so it stands in the
	-- view's open middle, or a take's phone box's (the World layer covers the screen; the HUD's root is the box).
	local function standDown(t: any, kind: string, def: string, away: number)
		local camera = workspace.CurrentCamera
		local hud = Layers.Get("Hud")
		local middle = hud.AbsolutePosition + hud.AbsoluteSize * Vector2.new(0.5, 0.3)
		local ray = camera:ScreenPointToRay(middle.X, middle.Y)
		local flat = Vector3.new(ray.Direction.X, 0, ray.Direction.Z).Magnitude
		local point = ray.Origin + ray.Direction * (away / math.max(flat, 0.1))
		local up = (HudConfig.Down.Up :: any)[kind] or 10
		local lead = myLead()
		local level = if lead and type(lead:GetAttribute("Level")) == "number" then lead:GetAttribute("Level") :: number else 10
		DownController.Try(kind, { Kind = kind, Def = def, Level = level, Ground = WorldConfig.Row.Ground }, 272, point - Vector3.new(0, up, 0))
	end

	return {
		{
			-- The top right is ours (research, 21:44): Roblox's player list, whose height grows with the server, is hidden
			-- so it never stands over the pills.
			Name = "HUD: Roblox's player list hidden, so it never stands over the pills",
			Run = function(t: any)
				t.Check("the player list is off", Helpers.waitFor(t, 6, function(): boolean
					return not game:GetService("StarterGui"):GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)
				end))
			end,
		},
		{
			-- AR62's piece 1, B (research's yes to Modulo's tier 2, 2026-11-26, 23:46): a fight shows no pills, no dock and no
			-- next step; a reward banked in one shows its own pill alone for its count-up and Config.Hud.FightHides.Hold, then
			-- it goes again; out of the fight, all back. The lead's damage taken on its card over the bar's draining end, hits
			-- while it shows adding up, never over the body. The hits dealt on one body stack: the latest whole, the two before
			-- smaller and fainter, an older one gone (Rules.Hud.Stack).
			Name = "HUD: AR62, a fight hides the pills, the dock and the step; a reward peeks its pill alone; damage taken on the lead's card; hits dealt stack",
			Run = function(t: any)
				local parts = HudController.Parts()
				local credits, power = (parts.Credits :: GuiObject).Parent :: GuiObject, (parts.Electricity :: GuiObject).Parent :: GuiObject
				local dock = parts.Dock :: GuiObject
				t.Wait(0.3)
				HudController.FightFor(20)
				-- A reward an earlier case banked may still be peeking: it runs out, then the fight holds them out.
				local peekLongest = HudConfig.FightHides.Flight + HudConfig.Motion.Count.Seconds + HudConfig.FightHides.Hold
				t.Check("in a fight, both pills and the dock step out", waitFor(t, peekLongest + 1, function(): boolean
					return not credits.Visible and not power.Visible and not dock.Visible and not parts.Chip.Visible
				end), `credits {credits.Visible}, power {power.Visible}, dock {dock.Visible}`)
				t.Check("credits banked mid-fight", t.Server("DataCredits", 5).Ok == true)
				t.Check("its pill peeks, alone", waitFor(t, 2, function(): boolean
					return credits.Visible and not power.Visible
				end), `credits {credits.Visible}, power {power.Visible}`)
				local hides = HudConfig.FightHides
				t.Check("and goes again after its count-up and its hold", waitFor(t, HudConfig.Motion.Count.Seconds + hides.Hold + 1, function(): boolean
					return not credits.Visible
				end))
				t.Server("DataCredits", -5)
				HudController.FightFor(0)
				t.Check("out of the fight, the pills and the dock back", waitFor(t, 1, function(): boolean
					return credits.Visible and power.Visible and dock.Visible
				end), `credits {credits.Visible}, power {power.Visible}, dock {dock.Visible}`)
				-- The damage taken, on the card.
				t.Check("the lead's damage taken goes to its card, not over the body", Effects.Taken == HudController.LeadTaken)
				local card = parts.Lead :: Frame
				local taken = card:FindFirstChild("Taken") :: TextLabel?
				if not t.Check("the card holds its taken number", taken ~= nil and card.Visible) or taken == nil then
					return
				end
				HudController.HoldTaken(0.3)
				HudController.LeadTaken(15)
				HudController.LeadTaken(10)
				t.Wait(0.1)
				local slate: any = HudConfig.Slate
				local stroke = taken:FindFirstChild("Stroke") :: UIStroke?
				t.Equal("hits while it shows add up", taken.Text, "−25")
				local lit = taken:FindFirstChild("Paint") :: UIGradient?
				local stops = if lit then lit.Color.Keypoints else {}
				t.Check("lit pale to coral in its dark stroke", taken.Visible and #stops == #slate.Taken.Fill and stops[1].Value == slate.Taken.Fill[1]
					and stops[#stops].Value == slate.Taken.Fill[#slate.Taken.Fill] and stroke ~= nil and stroke.Color == slate.Taken.Stroke)
				local mark = (parts.Lead :: Frame):FindFirstChild("ClassMark") :: GuiObject?
				local middle = taken.AbsolutePosition.Y + taken.AbsoluteSize.Y / 2
				local k = card.AbsoluteSize.X / card.Size.X.Offset
				local edge = card.AbsolutePosition.Y + slate.Taken.Cross / slate.Page * k
				local lo, hi = card.AbsolutePosition.X, card.AbsolutePosition.X + card.AbsoluteSize.X
				t.Check("inside the card, clear of the name's marks", taken.AbsolutePosition.X >= lo and taken.AbsolutePosition.X + taken.AbsoluteSize.X <= hi + 1
					and mark ~= nil and taken.AbsolutePosition.X >= mark.AbsolutePosition.X + mark.AbsoluteSize.X - 1,
					string.format("%.0f..%.0f in %.0f..%.0f", taken.AbsolutePosition.X, taken.AbsolutePosition.X + taken.AbsoluteSize.X, lo, hi))
				t.Check("crossing the card's top edge, risen no more than Rise", middle <= edge + 2 * k and middle >= edge - (slate.Taken.Rise / slate.Page + 2) * k,
					string.format("its middle %.0f, the card's top %.0f", middle, edge))
				HudController.HoldTaken(nil)
				t.Check("gone after its life", waitFor(t, slate.Taken.Life + 0.5, function(): boolean
					return not taken.Visible
				end))
				-- The stack: four presses on one body, a twentieth apart.
				local body = Instance.new("Model")
				body.Name = "NL_StackTest"
				local root = Instance.new("Part")
				root.Name = "HumanoidRootPart"
				root.Anchored, root.CanCollide, root.Transparency = true, false, 1
				local camera = workspace.CurrentCamera
				root.CFrame = camera.CFrame * CFrame.new(0, 0, -16)
				root.Parent = body
				body.Parent = workspace
				local ok, problem = pcall(function()
					for i = 1, 4 do
						Effects.Number(root, `Stack@{i}`, 10 * i, { Style = "Dealt" }, Combat.Numbers)
						t.Wait(0.05)
					end
					t.Wait(0.25)
					local onBody: any = Effects.Counting[root] or {}
					local newest, before, oldest, gone = onBody["Stack@4"], onBody["Stack@3"], onBody["Stack@2"], onBody["Stack@1"]
					t.Check("the latest whole", newest ~= nil and newest.Rank == 0 and math.abs(newest.Scale.Scale - 1) < 0.02, if newest then string.format("%.2f", newest.Scale.Scale) else "none")
					local stack = HudConfig.Numbers.Stack
					t.Check("the one before smaller and fainter", before ~= nil and before.Rank == 1 and math.abs(before.Scale.Scale - stack.Scale[2]) < 0.02 and before.Fade >= stack.Fade[2] - 0.02,
						if before then string.format("%.2f, faded %.2f", before.Scale.Scale, before.Fade) else "none")
					t.Check("two before, smaller and fainter again", oldest ~= nil and oldest.Rank == 2 and oldest.Scale.Scale < (if before then before.Scale.Scale else 0) and oldest.Fade > (if before then before.Fade else 1),
						if oldest then string.format("%.2f, faded %.2f", oldest.Scale.Scale, oldest.Fade) else "none")
					t.Check("an older one gone", gone == nil)
				end)
				body:Destroy()
				if not ok then
					error(problem, 0)
				end
			end,
		},
		{
			-- TR10's pictures (Modulo's, research's pass 2026-11-17 and 2026-11-19, 21:03): a down elite's and a resting keeper's
			-- marker wear their row's Marker on the tile, filling it over its colour, untinted; a row without one keeps its
			-- letter. Stood by DownController.Try, so it runs where the world has no square or gate.
			Name = "HUD: TR10, the down marker's tile wears its row's picture, a row without one its letter",
			Run = function(t: any)
				t.Wait(LEAD_SETTLE)
				local function check(kind: string, def: string, picture: string?)
					standDown(t, kind, def, 20)
					local plate: Frame? = nil
					t.Check(`{def}: its marker stands`, waitFor(t, 2, function(): boolean
						plate = DownController.Plate(kind)
						return plate ~= nil and plate:GetAttribute("Left") == 272 and plate:GetAttribute("Picture") == (picture or "")
					end))
					local icon = if plate then plate:FindFirstChild("Icon", true) else nil
					local image = if icon then icon:FindFirstChild("Picture") :: ImageLabel? else nil
					local letter = if icon then icon:FindFirstChild("Initial") :: TextLabel? else nil
					if icon == nil or image == nil or letter == nil then
						t.Check(`{def}: the tile, its picture and its letter`, false)
						return
					end
					if picture then
						t.Check(`{def}: {picture} on the tile, the letter hidden`, image.Visible and image.Image == UIKit.Images[picture].Id and not letter.Visible, image.Image)
						t.Check(`{def}: untinted, over the tile's colour`, image.ImageColor3 == Color3.new(1, 1, 1) and image.BackgroundTransparency == 1)
						t.Check(`{def}: it fills the tile`, (image.AbsoluteSize - (icon :: GuiObject).AbsoluteSize).Magnitude < 1, `{image.AbsoluteSize} in {(icon :: GuiObject).AbsoluteSize}`)
						t.Check(`{def}: clipped to the tile's corner`, image:FindFirstChildOfClass("UICorner") ~= nil)
					else
						t.Check(`{def}: no picture, its letter`, not image.Visible and letter.Visible and letter.Text ~= "", letter.Text)
					end
				end
				local ok, problem = pcall(function()
					check("Elite", "brawler_elite", "MarkerElite")
					check("Keeper", "lamplighter", "MarkerLamplighter")
					check("Elite", "brawler", nil)
				end)
				DownController.Try("Elite", nil)
				DownController.Try("Keeper", nil)
				t.Check("it ran", ok, tostring(problem))
				t.Check("cleared: the markers go", waitFor(t, 2, function(): boolean
					local elite, keeper = DownController.Plate("Elite"), DownController.Plate("Keeper")
					return (elite == nil or elite:GetAttribute("Left") == 0) and (keeper == nil or keeper:GetAttribute("Left") == 0)
				end))
			end,
		},
		{
			-- TR10's must-fixes (research's verdict, 2026-11-23, 16:41). The badge takes its size from the world: today's within
			-- Full studs of the camera, Full / distance past them, never under Least's floor, its time readable on the smallest
			-- phone at every size. Far, it draws only its tile and its time, the card's panel hidden. Near, the card unfolds
			-- under the tile, which stays where it stood.
			Name = "HUD: TR10, the down badge takes its size from the world; far, only its tile and its time",
			Run = function(t: any)
				t.Wait(LEAD_SETTLE)
				local config = HudConfig.Down
				local was = config.Near
				local least = math.min(1, config.Least / (config.Icon * Theme.Scale.Floor))
				local camera = workspace.CurrentCamera
				local function stand(away: number): Frame?
					standDown(t, "Elite", "brawler_elite", away)
					local plate: Frame? = nil
					waitFor(t, 2, function(): boolean
						plate = DownController.Plate("Elite")
						return plate ~= nil and plate:GetAttribute("Left") == 272 and World.Where(plate) ~= nil
					end)
					t.Wait(config.Unfold + 0.3)
					return plate
				end
				local ok, problem = pcall(function()
					for _, away in { 12, 60, 100, 200 } do
						local plate = stand(away)
						local where = if plate then World.Where(plate) else nil
						if plate == nil or where == nil then
							t.Check(`{away} studs ahead: it stands`, false)
							continue
						end
						local distance = (where - camera.CFrame.Position).Magnitude
						local size = plate:GetAttribute("Size") :: number
						t.Near(`{away} studs ahead, {math.floor(distance)} from the camera: its size`, size, math.clamp(config.Full / distance, least, 1), 0.02)
						local time = plate:FindFirstChild("Time") :: TextLabel
						local icon = plate:FindFirstChild("Icon") :: Frame
						t.Check(`{away}: its time reads on the smallest phone`, time.TextSize * size * Theme.Scale.Floor >= Theme.Text.Minimum - 0.5,
							string.format("%d at %.2f", time.TextSize, size))
						t.Check(`{away}: its tile never under {config.Least} px there`, icon.Size.X.Offset * size * Theme.Scale.Floor >= config.Least - 0.5)
						if away >= 100 then
							local back = plate:FindFirstChild("Back") :: CanvasGroup
							t.Check(`{away}: far, only its tile and its time`, plate:GetAttribute("Unfold") == 0 and not back.Visible and plate.Size.X.Offset < config.Width / 2,
								`{plate.Size.X.Offset} wide, its back {if back.Visible then "shown" else "hidden"}`)
						end
					end
					lintClean(t, "the down badge, far")
					-- Near, the card unfolds and the tile stays put.
					local plate = stand(30)
					if plate == nil then
						t.Check("30 studs ahead: it stands", false)
						return
					end
					local icon = plate:FindFirstChild("Icon") :: Frame
					config.Near = 0
					t.Check("folded", waitFor(t, config.Unfold + 0.5, function(): boolean
						return plate:GetAttribute("Unfold") == 0
					end))
					t.Wait(0.1)
					local folded = icon.AbsolutePosition
					config.Near = 1e6
					t.Check("near: its card unfolds whole", waitFor(t, config.Unfold + 0.5, function(): boolean
						return plate:GetAttribute("Card") == true
					end))
					t.Wait(0.1)
					t.Near("the tile stays where it stood (pixels)", (icon.AbsolutePosition - folded).Magnitude, 0, 1.5)
					t.Check("its panel shows under it", (plate:FindFirstChild("Back") :: CanvasGroup).Visible and plate.Size.X.Offset >= config.Width - 0.5)
					lintClean(t, "the down badge, near")
				end)
				config.Near = was
				DownController.Try("Elite", nil)
				t.Check("it ran", ok, tostring(problem))
			end,
		},
		{
			Name = "Take: TR10's badge, walked to from 120 studs at the smallest phone, the elite's then the keeper's, for research",
			Manual = true,
			Stay = true,
			Run = function(t: any)
				-- Each marker is stood until the driver moves ReplicatedStorage.NL_TakeStep on ("Elite", "Keeper", "End"): its
				-- floor 120 studs ahead of the avatar along the camera's look, written on the step as its Floor attribute, so
				-- the driver walks the avatar to 24 studs from it and captures the walk (research's second look: the badge
				-- growing, the card arriving at Near). On the smallest phone's frame inside Studio's window, as AR44's take:
				-- the HUD boxed to the window's left 16:9 at the scale the smallest phone's would be at that height, so a
				-- capture of that 16:9 is the phone's picture, larger.
				local step = Instance.new("StringValue")
				step.Name = "NL_TakeStep"
				step.Value = "Ready"
				step.Parent = ReplicatedStorage
				local function await(name: string): boolean
					return waitFor(t, 600, function(): boolean
						return step.Value == name or step.Value == "End"
					end) and step.Value == name
				end
				local function stand(kind: string, def: string)
					local root = Parts.Root(Players.LocalPlayer.Character)
					local look = workspace.CurrentCamera.CFrame.LookVector
					if root == nil then
						return
					end
					local floor = root.Position - Vector3.new(0, R6_ROOT_HEIGHT, 0) + Vector3.new(look.X, 0, look.Z).Unit * 120
					local lead = myLead()
					local level = if lead and type(lead:GetAttribute("Level")) == "number" then lead:GetAttribute("Level") :: number else 10
					DownController.Try(kind, { Kind = kind, Def = def, Level = level, Ground = WorldConfig.Row.Ground }, 272, floor)
					step:SetAttribute("Floor", floor)
				end
				t.Wait(LEAD_SETTLE)
				-- The world as a player stands in it: the World layer hides under any open screen (a spawn at the base's door
				-- opens the Stage picker, TR45)
				if Screen.Current() ~= nil then
					Screen.Close()
					t.Wait(0.5)
				end
				-- The phone centred on the window, so the world stands under its HUD as on the phone: the camera draws the
				-- world across the whole window. Its left, rendered, goes on the step for the capture.
				local view = workspace.CurrentCamera.ViewportSize
				local wide = math.floor(view.Y * Theme.Smallest.X / Theme.Smallest.Y)
				local left = math.floor((view.X - wide) / 2)
				Layers.Force(Theme.Scale.Floor * view.Y / Theme.Smallest.Y)
				Layers.Box(Vector2.new(wide, view.Y - GuiService.TopbarInset.Height), Vector2.new(left, 0))
				step:SetAttribute("Left", left)
				step:SetAttribute("Wide", wide)
				local ok, problem = pcall(function()
					if await("Elite") then
						stand("Elite", "brawler_elite")
						t.Wait(0.5)
						t.Check("the elite's stands", DownController.Plate("Elite") ~= nil)
					end
					if await("Keeper") then
						DownController.Try("Elite", nil)
						stand("Keeper", "lamplighter")
						t.Wait(0.5)
						t.Check("the keeper's stands", DownController.Plate("Keeper") ~= nil)
					end
					await("End")
				end)
				DownController.Try("Elite", nil)
				DownController.Try("Keeper", nil)
				Layers.Box(nil)
				Layers.Force(nil)
				step:Destroy()
				t.Check("it ran", ok, tostring(problem))
			end,
		},
		{
			Name = "Take: AR45's skull in its four colours on the foe card at the smallest phone, each held for a still, for research (TR49)",
			Manual = true,
			Stay = true,
			Run = function(t: any)
				-- Each tier is held until the driver moves ReplicatedStorage.NL_TakeStep on ("White", "Yellow", "Red", "Grey",
				-- "End") and captures it: an elite at the lead's level with the cuts moved round its cost, then a Shade a level
				-- under over them. The cuts are put back at the end.
				local step = Instance.new("StringValue")
				step.Name = "NL_TakeStep"
				step.Value = "Ready"
				step.Parent = ReplicatedStorage
				local function await(name: string): boolean
					return waitFor(t, 300, function(): boolean
						return step.Value == name or step.Value == "End"
					end) and step.Value == name
				end
				local parts = HudController.Parts()
				local lead = myLead()
				local level = if lead then lead:GetAttribute("Level") else nil
				if lead == nil or type(level) ~= "number" then
					t.Check("the lead is in the world", false)
					step:Destroy()
					return
				end
				local wasCuts = table.clone(HudConfig.Skulls.Cuts)
				-- Its foes stand through the take: a hundred times their health, a hundredth of their attack, put back after
				-- (the card's health reads staged; the skull and the level's colour are what's judged).
				local Enemies = require(Shared.Config.Enemies) :: any
				local rows = { "Ordinary", "Elite" }
				local was: { [string]: { Health: number, Attack: number } } = {}
				for _, row in rows do
					was[row] = { Health = Enemies[row].Health, Attack = Enemies[row].Attack }
					t.Server("Tune", `Enemies.{row}.Health`, Enemies[row].Health * 100)
					t.Server("Tune", `Enemies.{row}.Attack`, Enemies[row].Attack / 100)
				end
				Layers.Force(Theme.Scale.Floor)
				Layers.Box(Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height))
				local AHEAD, MEET = 12, 20 -- studs ahead a Shade spawns, seconds it may take to be met (as Cases' own)
				local function meet(def: string, at: number): boolean
					t.Server("FightSpawn") -- clears the last
					local camera, root = workspace.CurrentCamera, t.Root()
					local ahead = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
					if camera and ahead.Magnitude > 1e-3 then -- the view looks where it spawns (ViewController's report)
						camera.CFrame = CFrame.lookAt(root.Position - ahead.Unit * 10 + Vector3.new(0, 4, 0), root.Position + ahead.Unit * AHEAD)
						t.Wait(0.5)
					end
					local spawned = t.Server("FightSpawn", def, at, AHEAD)
					return type(spawned) == "table" and spawned.Ok == true and waitFor(t, MEET, function(): boolean
						return lead:GetAttribute("Target") == spawned.Id and parts.Target.Visible
					end)
				end
				local ok, problem = pcall(function()
					t.Check("an elite at the lead's level", meet("brawler_elite", level))
					local tiers: { { Name: string, Cuts: { number } } } = {
						{ Name = "White", Cuts = { 1e6, 2e6, 3e6 } },
						{ Name = "Yellow", Cuts = { 1e-6, 2e-6, 1e6 } },
						{ Name = "Red", Cuts = { 1e-6, 2e-6, 3e-6 } },
					}
					for _, tier in tiers do
						if await(tier.Name) then -- the step lays its state, then the driver captures it
							t.Server("Tune", "Hud.Skulls.Cuts", tier.Cuts)
						end
					end
					if await("Grey") then
						t.Server("Tune", "Hud.Skulls.Cuts", { 1e6, 2e6, 3e6 })
						if level > 1 then
							t.Check("a Shade a level under", meet("brawler", level - 1))
						end
					end
					await("End")
				end)
				t.Server("Tune", "Hud.Skulls.Cuts", wasCuts)
				t.Server("FightSpawn")
				for _, row in rows do
					t.Server("Tune", `Enemies.{row}.Health`, was[row].Health)
					t.Server("Tune", `Enemies.{row}.Attack`, was[row].Attack)
				end
				Layers.Box(nil)
				Layers.Force(nil)
				step:Destroy()
				if not ok then
					error(problem, 0)
				end
			end,
		},
		{
			Name = "Take: AR45's foe card digits on the light at full, half and near-empty health at the smallest phone, each held for a still, for research",
			Manual = true,
			Stay = true,
			Run = function(t: any)
				-- Each fill is held until the driver moves ReplicatedStorage.NL_TakeStep on ("Full", "Half", "Low", "End") and
				-- captures it over the Breaker's light: an elite at the lead's level, its health set by FoeHealth (research's
				-- must-fix 2, 23:31: the digits straight on the light, no band). Its foes stand through the take: a hundred
				-- times their health, a hundredth of their attack, put back after.
				local step = Instance.new("StringValue")
				step.Name = "NL_TakeStep"
				step.Value = "Ready"
				step.Parent = ReplicatedStorage
				local function await(name: string): boolean
					return waitFor(t, 300, function(): boolean
						return step.Value == name or step.Value == "End"
					end) and step.Value == name
				end
				local parts = HudController.Parts()
				local lead = myLead()
				local level = if lead then lead:GetAttribute("Level") else nil
				if lead == nil or type(level) ~= "number" then
					t.Check("the lead is in the world", false)
					step:Destroy()
					return
				end
				local Enemies = require(Shared.Config.Enemies) :: any
				local was = { Health = Enemies.Elite.Health, Attack = Enemies.Elite.Attack }
				t.Server("Tune", "Enemies.Elite.Health", was.Health * 100)
				t.Server("Tune", "Enemies.Elite.Attack", was.Attack / 100)
				Layers.Force(Theme.Scale.Floor)
				Layers.Box(Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height))
				local ok, problem = pcall(function()
					t.Server("FightSpawn")
					local spawned = t.Server("FightSpawn", "brawler_elite", level, 12)
					local id = if type(spawned) == "table" then spawned.Id else nil
					t.Check("an elite met", id ~= nil and waitFor(t, 20, function(): boolean
						return lead:GetAttribute("Target") == id and parts.Target.Visible
					end))
					local digits = parts.Target:FindFirstChild("Value", true) :: TextLabel?
					local stroke = if digits then digits:FindFirstChildOfClass("UIStroke") else nil
					t.Check("no band behind the digits", parts.Target:FindFirstChild("Band", true) == nil)
					t.Check("the digits' outline: solid, 2 points, authored", stroke ~= nil and stroke.Transparency == 0 and math.abs(stroke.Thickness - 2) < 1e-3, if stroke then `{stroke.Thickness} points, grown by the layer's UIScale` else "none")
					for _, fill in { { Name = "Full", Share = 1 }, { Name = "Half", Share = 0.5 }, { Name = "Low", Share = 0.06 } } do
						if await(fill.Name) then -- the step lays its fill, then the driver captures it
							t.Server("FoeHealth", id, fill.Share)
						end
					end
					await("End")
				end)
				t.Server("FightSpawn")
				t.Server("Tune", "Enemies.Elite.Health", was.Health)
				t.Server("Tune", "Enemies.Elite.Attack", was.Attack)
				Layers.Box(nil)
				Layers.Force(nil)
				step:Destroy()
				if not ok then
					error(problem, 0)
				end
			end,
		},
		{
			-- TR19 (docs/test-requests.md, "Home in one tap: the dock's Base tile"): at home the tile is quiet and a tap does
			-- nothing; out on Lantern Row a tap charges, the tile filling from its foot and the avatar's outline lifting, then the
			-- player stands at their plot's spawn facing its Breaker with their lead beside them; the cooldown's veil is on the
			-- tile away from home; a fight, a hit in the charge and a keeper's try each refuse in plain words and shake the tile;
			-- a lead fallen alone out in a ground gives the tile its pip.
			Name = "HUD: TR19, the dock's Base tile takes the player home after its charge, refuses in plain words, is quiet at home, and wears the pip after a lone fall",
			Place = "Main", -- TR45: away is the Strip; in the Festival's place the tile is the trip home (its own case)
			Stay = true, -- it moves the avatar itself; the next case's reset takes it back to the pad
			Run = function(t: any)
				t.Wait(LEAD_SETTLE)
				Screen.Close()
				local player = Players.LocalPlayer
				local parts = HudController.Parts()
				local base = parts.Base :: TextButton
				local plot = player:GetAttribute("Plot")
				local where = if type(plot) == "number" then { Plot = plot } else nil
				local spawn = if where then streamed(t, "Spawn", where) else nil
				local breaker = if where then streamed(t, "Breaker", where) else nil
				local world = workspace:FindFirstChild("World")
				local strip = if world then world:FindFirstChild("Strip") else nil
				t.Check("the plot's spawn and Breaker, and the Strip", spawn ~= nil and breaker ~= nil and strip ~= nil and strip:IsA("BasePart"))
				if not (spawn and breaker and strip and strip:IsA("BasePart")) then
					return
				end
				local function flat(a: Vector3, b: Vector3): number
					return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
				end
				local function shakes(): number
					return tonumber(base:GetAttribute("Shakes")) or 0
				end
				local function state(): any
					return t.Server("HomeState")
				end
				local function said(words: string): boolean
					return table.find(Toast.Shown(), words) ~= nil
				end
				local function restore()
					t.Server("HomeReady")
					t.Server("LeadHeal")
					t.Root().CFrame = CFrame.new(Markers.At(spawn).Position + Vector3.new(0, R6_ROOT_HEIGHT, 0))
					t.Wait(0.5)
				end
				t.Server("HomeReady")
				t.Server("LeadCalm") -- out of any fight a case before left it in: a lead with a target is "In a fight"
				-- Away: the Strip's crossing, off every plot, nothing to fight (TR45: the street is the Festival's place).
				local square = strip.Position + Vector3.new(0, strip.Size.Y / 2 + R6_ROOT_HEIGHT, 0)
				local home = Markers.At(spawn).Position
				-- At home: quiet, and a tap opens the base's command view (TR21's blockout; its build retires the quiet look).
				t.Root().CFrame = CFrame.new(home + Vector3.new(0, R6_ROOT_HEIGHT, 0))
				t.Wait(0.5)
				t.Check("at home the tile is quiet", waitFor(t, 1, function(): boolean
					return base:GetAttribute("Look") == "Quiet"
				end), tostring(base:GetAttribute("Look")))
				t.Equal("and the server says here", state().Refusal, "Here")
				-- Research's verdict on TR20, fix 2: the word says why a tap does nothing, and the tap stays silent.
				local word = (parts.Dock :: Frame):FindFirstChild("BaseWord", true) :: TextLabel
				Hover.Pretend("Mouse")
				Hover.Force(base, true)
				t.Check("its word says you're home", waitFor(t, HudConfig.Motion.Hover.Word + 0.4, function(): boolean
					return word.Visible
				end) and word.Text == "Back at your base", word.Text)
				Hover.Force(base, nil)
				Hover.Pretend(nil)
				local still, shownBefore = shakes(), Toast.Shown()
				Button.Press(base)
				t.Wait(0.4)
				local new = {}
				for _, message in Toast.Shown() do
					if not table.find(shownBefore, message) then
						table.insert(new, message)
					end
				end
				t.Check("a tap opens the base's command view (TR21): no charge, no shake, nothing said", BaseView.IsOpen() and player:GetAttribute("HomeCharge") == nil and shakes() == still and #new == 0, table.concat(new, "; "))
				BaseView.Close()
				t.Wait(BaseViewConfig.Lift.Seconds + 0.2)
				-- Out on the Strip, nothing in the way: a tap charges, then home.
				t.Root().CFrame = CFrame.new(square)
				t.Wait(LEAD_SETTLE)
				t.Check("away from the plot the tile is at rest", waitFor(t, 1, function(): boolean
					return base:GetAttribute("Look") == "Rest" and base:GetAttribute("Mood") == nil
				end), tostring(base:GetAttribute("Look")))
				t.Equal("and the server would take them home", state().Refusal, "")
				local fov = workspace.CurrentCamera.FieldOfView
				-- Unloaded, an image drew nothing for a moment: the black frame research saw in TR19's take (a pressed twin
				-- then; a call's edge and pip in AR30's make, shown only when something's new).
				local unloaded = {}
				for _, image in (parts.Dock :: Frame):GetDescendants() do
					if image:IsA("ImageLabel") and image.Image ~= "" and ContentProvider:GetAssetFetchStatus(image.Image) ~= Enum.AssetFetchStatus.Success then
						table.insert(unloaded, image.Name)
					end
				end
				t.Check("every image the dock lays is loaded before it first shows", #unloaded == 0, table.concat(unloaded, ", "))
				-- Research's verdict on TR19: the press goes straight into the charge, ink from the tap to the jump and the fill
				-- rising white over it, never a flash back to rest.
				local looks: { string } = {}
				local lookTimes: { string } = {}
				local filledAt: number? = nil
				local pressed = os.clock()
				local function sample()
					local shown = tostring(base:GetAttribute("Look"))
					if looks[#looks] ~= shown then
						table.insert(looks, shown)
						table.insert(lookTimes, string.format("%s %.2f%s", shown, os.clock() - pressed, if player:GetAttribute("Engaged") then " engaged" else ""))
					end
					local fill = base:GetAttribute("Fill")
					if filledAt == nil and type(fill) == "number" and fill > 0 then
						filledAt = os.clock()
					end
				end
				local watch = RunService.RenderStepped:Connect(sample)
				pressed = os.clock()
				t.Check("a tap begins the charge", Button.Press(base) and waitFor(t, REPLICATE, function(): boolean
					return player:GetAttribute("HomeCharge") ~= nil
				end))
				t.Check("the tile fills from its foot", waitFor(t, HomeConfig.Charge, function(): boolean
					local fill = base:GetAttribute("Fill")
					return type(fill) == "number" and fill > 0 and fill < 1
				end), tostring(base:GetAttribute("Fill")))
				local character = player.Character
				local glow = if character then character:FindFirstChild("NL_HomeCharge") else nil
				local first = if filledAt then filledAt - pressed else math.huge
				t.Check("the fill rises from the tap's own frame", first <= 0.05, string.format("%.3f s", first))
				waitFor(t, HomeConfig.Charge, function(): boolean -- past the bright band, so the body shows under it
					return (tonumber(base:GetAttribute("Fill")) or 0) > HudConfig.Dock.Charge.Edge + 0.05
				end)
				local gui = base:FindFirstAncestorOfClass("ScreenGui")
				local fillLayer = if gui then gui:FindFirstChild("BaseFill", true) else nil
				local ramp = if fillLayer then fillLayer:FindFirstChildOfClass("UIGradient") else nil
				local alphas: { NumberSequenceKeypoint } = if ramp then ramp.Transparency.Keypoints else {}
				local edgeLit = false
				for _, key in alphas do
					edgeLit = edgeLit or key.Value == 0
				end
				local body = alphas[#alphas]
				t.Check("its rising edge at full over a softer body", edgeLit and body ~= nil and math.abs(body.Value - (1 - HudConfig.Dock.Charge.Alpha)) < 1e-3, `{#alphas} keys`)
				t.Check("and the avatar's outline lifts in void light", glow ~= nil and glow:IsA("Highlight") and glow.Enabled and glow.OutlineColor == HomeConfig.Outline)
				t.Check("then it lands", waitFor(t, HomeConfig.Charge + REPLICATE + 0.5, function(): boolean
					local landed = player:GetAttribute("HomeLanded")
					return type(landed) == "number" and landed >= pressed
				end))
				waitFor(t, HomeConfig.Hold + 0.2, function(): boolean
					return base:GetAttribute("Look") == "Quiet"
				end)
				sample() -- the dock may paint after the watch in the frame the wait ends
				watch:Disconnect()
				local inked = table.find(looks, "Charge")
				t.Check("ink from the tap to home, then quiet: no flash of rest or dim between", inked ~= nil and looks[inked + 1] == "Quiet" and #looks == inked + 1, table.concat(lookTimes, " then "))
				local took = (tonumber(player:GetAttribute("HomeLanded")) or pressed) - pressed
				t.Check("after the whole charge", took >= HomeConfig.Charge - 0.05, string.format("%.2f s", took))
				t.Wait(0.3) -- physics settles the set-down
				local root = t.Root()
				t.Near("at the plot's spawn (studs off)", flat(root.Position, home), 0, SET_DOWN)
				local toward = Markers.At(breaker).Position - root.Position
				local look = root.CFrame.LookVector
				local facing = Vector3.new(look.X, 0, look.Z).Unit:Dot(Vector3.new(toward.X, 0, toward.Z).Unit)
				t.Check("facing its Breaker", facing > math.cos(math.rad(10)), string.format("%.0f degrees off", math.deg(math.acos(math.clamp(facing, -1, 1)))))
				local mine = myLead()
				local beside = if mine then flat(mine:GetPivot().Position, root.Position) else math.huge
				t.Check("the lead beside them", beside < 5, string.format("%.1f studs", beside))
				local lit = glow ~= nil and glow:IsA("Highlight") and glow.Enabled
				t.Check("the charge's fill and outline are gone", base:GetAttribute("Fill") == nil and not lit)
				t.Check("the field of view settles back", waitFor(t, HomeConfig.Settle + 0.3, function(): boolean
					return math.abs(workspace.CurrentCamera.FieldOfView - fov) < 0.05
				end), string.format("%.2f", workspace.CurrentCamera.FieldOfView))
				-- The cooldown: quiet at home, its veil on the tile out in the ground, and a tap says how long.
				t.Check("home again, the tile is quiet", waitFor(t, 1, function(): boolean
					return base:GetAttribute("Look") == "Quiet"
				end))
				t.Root().CFrame = CFrame.new(square)
				t.Wait(0.5)
				local veil = base:GetAttribute("Veil")
				t.Check("away, the cooldown's veil covers what's left", type(veil) == "number" and veil > 0 and veil < 1, tostring(veil))
				t.Check("still tappable, to say why", Button.State(base) ~= "Disabled", Button.State(base))
				local before = shakes()
				Button.Press(base)
				t.Check("a tap says how long, and the tile shakes", waitFor(t, REPLICATE, function(): boolean
					for _, shown in Toast.Shown() do
						if string.match(shown, "^Ready in %d+ s$") then
							return shakes() > before
						end
					end
					return false
				end), table.concat(Toast.Shown(), " | "))
				t.Equal("the server agrees", state().Refusal, "Cooldown")
				-- In a fight: dim, and a tap says so.
				t.Server("HomeReady")
				t.Server("HomeHit")
				t.Check("a hit just now dims the tile", waitFor(t, REPLICATE, function(): boolean
					return base:GetAttribute("Look") == "Dim"
				end), tostring(base:GetAttribute("Look")))
				before = shakes()
				Button.Press(base)
				t.Check("a tap says it's in a fight, and shakes", waitFor(t, REPLICATE, function(): boolean
					return said("Not during a fight") and shakes() > before
				end))
				-- A hit in the charge cancels it, and nothing is spent.
				t.Server("HomeReady")
				t.Wait(REPLICATE)
				before = shakes()
				local from = t.Root().Position
				t.Check("a fresh charge", Button.Press(base) and waitFor(t, REPLICATE, function(): boolean
					return player:GetAttribute("HomeCharge") ~= nil
				end))
				t.Server("HomeHit")
				t.Check("a hit in it cancels it, said and shaken", waitFor(t, HomeConfig.Charge + REPLICATE, function(): boolean
					return player:GetAttribute("HomeCharge") == nil and shakes() > before
				end))
				t.Check("the player wasn't moved", flat(t.Root().Position, from) < SET_DOWN)
				t.Check("and no cooldown was spent", player:GetAttribute("HomeReady") == nil)
				t.Server("HomeReady")
				-- A lead fallen alone away from home: the pip on the tile, gone at its return.
				t.Root().CFrame = CFrame.new(square)
				t.Wait(LEAD_SETTLE)
				t.Check("no pip while the lead stands", base:GetAttribute("New") ~= true)
				local alone = t.Server("VoidkinFallen")
				t.Check("none other ready", type(alone) == "table" and alone.Ok == true)
				t.Check("the lead falls", t.Server("FightHealth", 0).Ok == true)
				t.Check("then the tile wears its pip", waitFor(t, Combat.Lead.Leave + REPLICATE + 1, function(): boolean
					return base:GetAttribute("New") == true
				end))
				t.Check("and never the next lead's button", not parts.Next.Visible)
				lintClean(t, "a lead fallen alone, the Base tile's pip")
				t.Server("LeadHeal")
				t.Check("at the lead's return the pip is gone", waitFor(t, 2, function(): boolean
					return base:GetAttribute("New") ~= true
				end))
				restore()
			end,
		},
		{
			-- TR20 (docs/test-requests.md, "Everything that presses answers the pointer: hover"): a dock tile, a Breaker's
			-- chamber and a Voidkin card answer the mouse within a frame, lift and brighten in their own place, and go back;
			-- a dock tile's word shows after a moment, a refused one's reason; a pad's selection answers the same with a rim;
			-- a touch answers nothing.
			Name = "UI: TR20, a dock tile, a Breaker's chamber and a Voidkin card answer the pointer within a frame and move nothing round them; a pad's selection too; a touch nothing",
			Run = function(t: any)
				local motion = HudConfig.Motion.Hover
				local settle = math.max(motion.In, motion.Out) + 0.1
				Screen.Close()
				t.Wait(HudConfig.Motion.Screen.Exit + 0.1)
				local parts = HudController.Parts()
				local dock = parts.Dock :: Frame
				local make = HudConfig.Make.Dock
				local scale = dock.AbsoluteSize.X / make.Box.X
				local inventory = parts.Home :: TextButton
				local tile = dock:FindFirstChild("HomeGlass", true) :: ImageLabel
				local cellLight = dock:FindFirstChild("HomeLight", true) :: ImageLabel
				local edge = dock:FindFirstChild("HomeRim", true) :: ImageLabel
				local word = dock:FindFirstChild("HomeWord", true) :: TextLabel
				local others = { dock:FindFirstChild("BaseGlass", true) :: ImageLabel, dock:FindFirstChild("MapGlass", true) :: ImageLabel }
				local function at(piece: GuiObject): Vector2
					return piece.AbsolutePosition
				end
				local restTile = at(tile)
				local restOthers = { at(others[1]), at(others[2]) }
				local restButton = at(inventory)
				local function still(): boolean
					return (at(others[1]) - restOthers[1]).Magnitude < 0.5 and (at(others[2]) - restOthers[2]).Magnitude < 0.5 and (at(inventory) - restButton).Magnitude < 0.5
				end
				Hover.Pretend("Mouse")
				-- The dock: within a frame, then whole: lifted, its light raised Halo of the way to a press's, nothing else moved.
				Hover.Force(inventory, true)
				RunService.RenderStepped:Wait()
				RunService.RenderStepped:Wait()
				t.Check("a dock tile answers within a frame of the pointer's entry", Hover.Share(inventory) > 0, string.format("%.2f", Hover.Share(inventory)))
				t.Wait(settle)
				t.Near("whole once it's eased in", Hover.Share(inventory), 1, 1e-3)
				t.Near("it lifts its points", (restTile.Y - at(tile).Y) / scale, motion.Lift, 0.3)
				local raised = make.L.Rest + (make.L.Pressed - make.L.Rest) * motion.Halo
				t.Check("its light raised toward a press's", math.abs(cellLight.ImageTransparency - (1 - raised / make.Top)) < 0.02, string.format("%.2f", cellLight.ImageTransparency))
				t.Check("nothing round it moves, nor its tap", still())
				t.Check("its word shows after a moment", waitFor(t, motion.Word + 0.3, function(): boolean
					return word.Visible
				end) and word.Text == "Home", word.Text)
				-- Fix 1 (research's verdict on TR20): the word on a plate of its own, centred on its tile, over everything
				-- round it in its layer, the chip among them.
				local plate = word.Parent :: Frame
				local middle = tile.AbsolutePosition.X + tile.AbsoluteSize.X / 2 -- the tile the eye sees, not its tap (rounded wider)
				t.Check("its word stands on a plate of its own, centred on its tile", plate:IsA("Frame") and plate.Visible and plate:FindFirstChild("Fill", true) ~= nil and math.abs(plate.AbsolutePosition.X + plate.AbsoluteSize.X / 2 - middle) < 1, string.format("%.1f off", plate.AbsolutePosition.X + plate.AbsoluteSize.X / 2 - middle))
				t.Check("the plate holds its words whole", word.TextFits and plate.AbsoluteSize.X >= word.TextBounds.X, string.format("%d for %d", plate.AbsoluteSize.X, word.TextBounds.X))
				local over = {}
				for _, other in (dock.Parent :: Instance):GetChildren() do
					if other ~= dock and other:IsA("GuiObject") and other.ZIndex >= dock.ZIndex then
						table.insert(over, `{other.Name} {other.ZIndex}`)
					end
				end
				t.Check("the dock, its word with it, draws over every other piece in its layer, the chip among them", #over == 0 and (parts.Chip :: GuiObject).Parent == dock.Parent, table.concat(over, ", "))
				Hover.Force(inventory, false)
				t.Wait(settle)
				t.Near("off it, it eases out", Hover.Share(inventory), 0, 1e-3)
				t.Check("back in its place, its word gone", (at(tile) - restTile).Magnitude < 0.5 and not word.Visible)
				-- The Map tile's word is Play (TR45; a refused tile's reason is TR19's "Back at your base", in its own case).
				local map = parts.Map :: TextButton
				local mapWord = dock:FindFirstChild("MapWord", true) :: TextLabel
				Hover.Force(map, true)
				t.Check("the Map tile's word is Play", waitFor(t, motion.Word + 0.3, function(): boolean
					return mapWord.Visible
				end) and mapWord.Text == "Play", mapWord.Text)
				Hover.Force(map, nil)
				-- A touch answers nothing.
				Hover.Pretend("Touch")
				Hover.Force(inventory, true)
				t.Wait(settle)
				t.Equal("on touch nothing answers", Hover.Share(inventory), 0)
				Hover.Force(inventory, nil)
				-- A pad's selection answers the same, with the tile's rim.
				Hover.Pretend("Pad")
				GuiService.SelectedObject = inventory
				t.Wait(settle)
				t.Near("a pad's selection lifts it too", Hover.Share(inventory), 1, 1e-3)
				t.Check("and wears its rim", edge.Visible and edge.ImageTransparency < 0.05, string.format("%.2f", edge.ImageTransparency))
				GuiService.SelectedObject = nil
				t.Wait(settle)
				t.Check("deselected, the rim goes", not edge.Visible)
				Hover.Pretend("Mouse")
				-- A Breaker's chamber: its words lift inside it, its place and its neighbour's stay. A chamber takes a tap only
				-- while a shard breaks in it, so one goes in if the first stands empty (and is left breaking, as the Breaker's
				-- own cases leave theirs).
				local function firstWorks(): boolean
					local now = ProfileController.Get()
					local first = if now then now.Base.Chambers[1] else nil
					return first ~= nil and first.Work ~= nil
				end
				if not firstWorks() then
					local shard = "lanternrow_standard"
					local before = ProfileController.Get()
					local held = if before then before.Bag.Shards[shard] or 0 else 0
					t.Server("BaseGive", shard, 1)
					t.Check("a shard for the first chamber", waitFor(t, 2, function(): boolean
						local now = ProfileController.Get()
						return now ~= nil and (now.Bag.Shards[shard] or 0) == held + 1
					end) and ProfileController.Act("AddShard", { Shard = shard }).Ok == true and waitFor(t, 2, firstWorks))
				end
				Screen.Close()
				t.Wait(HudConfig.Motion.Screen.Exit + 0.1)
				BaseController.OpenBreaker()
				t.Check("the Breaker's screen opens", waitFor(t, 1, function(): boolean
					return Screen.Current() == BreakerScreen.Name
				end))
				t.Wait(HudConfig.Motion.Screen.Enter + 0.1)
				-- The pointer on the first chamber and off, measured; nil when the panel was rebuilt meanwhile (a chamber's work
				-- changing, as the whole suite's clock can bring), so the chamber measured is still the one shown.
				local function hovered(): { [string]: any }?
					local screen = Screen.Frame(BreakerScreen.Name)
					local chamber = if screen then screen:FindFirstChild("Chamber1", true) :: Frame? else nil
					local neighbour = if screen then screen:FindFirstChild("Chamber2", true) :: Frame? else nil
					local tap = if chamber then chamber:FindFirstChild("Tap") :: TextButton? else nil
					local piece = if chamber then chamber:FindFirstChildWhichIsA("TextLabel") else nil
					if not (chamber and neighbour and tap and piece) then
						return { Found = false }
					end
					local restWords, restCell, restNext = at(piece), at(chamber), at(neighbour)
					Hover.Force(tap, true)
					t.Wait(settle)
					local lift = (restWords.Y - at(piece).Y) / scale
					local stays = (at(chamber) - restCell).Magnitude < 0.5 and (at(neighbour) - restNext).Magnitude < 0.5
					Hover.Force(tap, false)
					t.Wait(settle)
					local back = (at(piece) - restWords).Magnitude < 0.5
					Hover.Force(tap, nil)
					if piece.Parent == nil or chamber.Parent == nil or neighbour.Parent == nil then
						return nil
					end
					return { Found = true, Lift = lift, Stays = stays, Back = back }
				end
				local measured = hovered()
				if measured == nil then
					measured = hovered()
				end
				t.Check("its first two chambers, a tap and words", measured ~= nil and measured.Found)
				if measured and measured.Found then
					t.Near("a chamber's words lift inside it (points)", measured.Lift, motion.Lift, 0.3)
					t.Check("its own place and its neighbour's stay", measured.Stays)
					t.Check("off it, its words are back", measured.Back)
				end
				-- A ready chip's gold edge goes toward its full light under the pointer: toward the panel's accent it dulled,
				-- and the hovered chip read weaker than its neighbour (TR20's retake). One is made if none is ready.
				local function readyChip(): (GuiObject?, ImageLabel?)
					local frame = Screen.Frame(BreakerScreen.Name)
					local ready = if frame then frame:FindFirstChild("Ready1", true) else nil
					local skin = if ready then ready:FindFirstChild("NL_Skin") else nil
					return if ready then ready:FindFirstChild("Tap") :: GuiObject? else nil, if skin then skin:FindFirstChild("Edge", true) :: ImageLabel? else nil
				end
				local readyTap, readyEdge = readyChip()
				if readyTap == nil then
					t.Server("BaseSkip", 120)
					waitFor(t, 3, function(): boolean
						readyTap, readyEdge = readyChip()
						return readyTap ~= nil
					end)
				end
				t.Check("a ready chip to hover", readyTap ~= nil and readyEdge ~= nil)
				if readyTap and readyEdge then
					local function light(c: Color3): number
						return c.R + c.G + c.B
					end
					local restEdge = readyEdge.ImageColor3
					Hover.Force(readyTap, true)
					t.Wait(settle)
					t.Check("its gold edge goes lighter under the pointer, never duller", light(readyEdge.ImageColor3) > light(restEdge) + 0.1, `{restEdge:ToHex()} to {readyEdge.ImageColor3:ToHex()}`)
					-- Its breath holds at its High while hovered, since the whitening is lost under its gold (TR20's verdict), and
					-- breathes on once the pointer leaves.
					local readyFrame = readyTap.Parent
					local glowFill = if readyFrame then readyFrame:FindFirstChild("Glow", true) else nil
					local high = 1 - HudConfig.Breaker.Glow.High
					local held = glowFill ~= nil and glowFill:IsA("ImageLabel") and math.abs(glowFill.ImageTransparency - high) < 0.01
					t.Wait(0.2)
					held = held and glowFill ~= nil and glowFill:IsA("ImageLabel") and math.abs(glowFill.ImageTransparency - high) < 0.01
					t.Check("its glow holds at its High under the pointer", held, if glowFill and glowFill:IsA("ImageLabel") then string.format("%.3f for %.3f", glowFill.ImageTransparency, high) else "no glow")
					Hover.Force(readyTap, nil)
					if glowFill and glowFill:IsA("ImageLabel") then
						t.Wait(HudConfig.Motion.Hover.Out + 0.05)
						local left = glowFill.ImageTransparency
						t.Wait(0.25)
						t.Check("and breathes on once the pointer leaves", math.abs(glowFill.ImageTransparency - left) > 0.005, string.format("%.3f then %.3f", left, glowFill.ImageTransparency))
					end
				end
				Screen.Close()
				t.Wait(HudConfig.Motion.Screen.Exit + 0.1)
				-- A Voidkin card on the strip: it scales in its own place and its rim lifts.
				local view = ProfileController.Get()
				t.Check("the save's copy is here", view ~= nil)
				if view == nil then
					Hover.Pretend(nil)
					return
				end
				VoidkinScreen.Last("Bag") -- the card opens the page last shown (AR49)
				t.Check("the Voidkin screen opens", Button.Press(parts.Voidkin :: TextButton) and waitFor(t, 1, function(): boolean
					return Screen.Current() == "Voidkin"
				end))
				t.Wait(HudConfig.Motion.Screen.Enter + 0.1)
				-- It opens on the Items page (TR28); the Voidkin's cards stand on Overview's strip.
				VoidkinScreen.Show("Overview")
				t.Wait(0.1)
				local other: TextButton? = nil
				for id in view.Voidkin do
					local cell = VoidkinScreen.Find(id)
					if id ~= VoidkinScreen.Chosen() and cell and cell:IsA("TextButton") then
						other = cell
						break
					end
				end
				t.Check("a card besides the chosen one", other ~= nil)
				if other then
					local card = other :: TextButton
					local grow = card:FindFirstChild("Face") and (card:FindFirstChild("Face") :: Instance):FindFirstChild("Hover") :: UIScale?
					local rim = card:FindFirstChild("HoverRim") :: UIStroke?
					local restCard = at(card)
					Hover.Force(card, true)
					t.Wait(settle)
					t.Check("a card scales to its seed", grow ~= nil and math.abs(grow.Scale - motion.Card) < 1e-3 and math.abs(Button.Squeeze(card) - motion.Card) < 1e-3, if grow then string.format("%.3f", grow.Scale) else "no scale")
					t.Check("its rarity's rim lifts, at full light (research's verdict on TR20, fix 3)", rim ~= nil and rim.Transparency < 0.05 and math.abs(rim.Thickness - motion.Rim) < 1e-3 and math.min(rim.Color.R, rim.Color.G, rim.Color.B) >= motion.RimLight - 0.01, if rim then rim.Color:ToHex() else "no rim")
					t.Check("in its own place", (at(card) - restCard).Magnitude < 0.5)
					-- It grows into its gap, never over a neighbour: the grown face and the rim round it clear every other card.
					local face = card:FindFirstChild("Face") :: GuiObject
					local reach = (if rim then rim.Thickness else 0) * card.AbsoluteSize.X / HudConfig.Voidkin.Strip
					local lo = Vector2.new(math.min(face.AbsolutePosition.X, card.AbsolutePosition.X - reach), math.min(face.AbsolutePosition.Y, card.AbsolutePosition.Y - reach))
					local hi = Vector2.new(math.max(face.AbsolutePosition.X + face.AbsoluteSize.X, card.AbsolutePosition.X + card.AbsoluteSize.X + reach), math.max(face.AbsolutePosition.Y + face.AbsoluteSize.Y, card.AbsolutePosition.Y + card.AbsoluteSize.Y + reach))
					local crossed, cards = {}, 0
					for _, near in (card.Parent :: Instance):GetChildren() do
						if near ~= card and near:IsA("TextButton") and near.Visible then
							cards += 1
							local nearFace = (near:FindFirstChild("Face") or near) :: GuiObject
							local a, b = nearFace.AbsolutePosition, nearFace.AbsolutePosition + nearFace.AbsoluteSize
							if lo.X < b.X - 0.5 and a.X < hi.X - 0.5 and lo.Y < b.Y - 0.5 and a.Y < hi.Y - 0.5 then
								table.insert(crossed, near.Name)
							end
						end
					end
					t.Check("it grows into its gap, never over a neighbour's face", cards > 0 and #crossed == 0, `{cards} beside it, over {table.concat(crossed, ", ")}; {math.floor(hi.X - lo.X + 0.5)} wide`)
					Hover.Force(card, nil)
					t.Wait(settle)
					t.Check("off it, back to its size", grow ~= nil and math.abs(grow.Scale - 1) < 1e-3 and math.abs(Button.Squeeze(card) - 1) < 1e-3)
				end
				Screen.Close()
				Hover.Pretend(nil)
			end,
		},
		{
			Name = "HUD: a machine's plate under the lead's card starts right of the readout and the eye, in this window and on the smallest phone",
			Place = "Main", -- TR45: its world stands in that place only
			Run = function(t: any)
				-- Research's pass on AR12 at phone size (2026-11-15): at home, Spectate's eye stood over "Bay 1 · no one works
				-- here". The camera is turned so the Breaker's point stands over the eye, halfway up the band; its plate must show
				-- under the band, clear of the readout and the eye, and right beside them, at both sizes (World.Band's corner).
				-- The plate's own point, over the gantry's lamp: aimed at the prompt's, 5.5 studs under it, the point stood over
				-- the screen's top from AR16's nearer spawn, and the plate rightly hid.
				local world = Layers.Get("World")
				local hud = HudController.Parts()
				local plate: Frame? = nil
				waitFor(t, ANSWER, function(): boolean
					plate = BaseController.Parts().BreakerPlate :: Frame?
					return plate ~= nil and plate:FindFirstChild("Panel") ~= nil
				end)
				t.Check("the Breaker's plate", plate ~= nil)
				if plate == nil then
					return
				end
				local shard = "named_watt"
				local gave = t.Server("BaseGive", shard, 1)
				t.Check("a shard in the bag: the plate has news", type(gave) == "table" and gave.Ok == true)
				local old = Players.LocalPlayer.Character
				t.Check("the avatar goes home", t.Server("Respawn") == true and waitFor(t, ARRIVE_TIMEOUT, function(): boolean
					local character = Players.LocalPlayer.Character
					local humanoid = if character and character ~= old then Parts.Humanoid(character) else nil
					return humanoid ~= nil and humanoid.FloorMaterial ~= Enum.Material.Air
				end))
				t.Wait(PLATE_TICK * 2)
				-- A plate speaks only near its machine (research's must-fix on AR16, 2026-11-17). The camera keeps the spawn's
				-- place, and the avatar steps beside the Breaker, aside from the camera's line, out of the plate's way.
				local camera = workspace.CurrentCamera
				local says = BaseController.Says()
				-- Near the plate's point is its lift over the prompt (AR65), lower than the machine's top, and toward the Mill
				-- the avatar stood under the plate, which hid over it. 9 studs out, 150 degrees round from the camera's line,
				-- it stands left of the plate once the camera turns, the prompt in reach (10; projected 2026-11-26, 60 px clear).
				local breakerSpot = says.Breaker
				local near = false
				if camera and breakerSpot then
					camera.CameraType = Enum.CameraType.Scriptable
					local flat = camera.CFrame.Position - breakerSpot.Ground
					local aside = CFrame.Angles(0, math.rad(-150), 0) * Vector3.new(flat.X, 0, flat.Z).Unit
					t.Server("TestStandAt", breakerSpot.Ground + aside * 9 + Vector3.new(0, 3, 0), breakerSpot.Ground)
					near = waitFor(t, 1, function(): boolean
						return BaseController.Says().Breaker.Near
					end)
				end
				t.Check("the avatar beside the Breaker: its plate speaks", near)
				t.Wait(PLATE_TICK)
				local point = World.Where(plate)
				t.Check("its point", point ~= nil and camera ~= nil)
				if point and camera then
					camera.CameraType = Enum.CameraType.Scriptable
					local from = camera.CFrame.Position
					local eye, piece = hud.Spectate :: GuiObject, hud.Signature :: GuiObject
					local high = GuiService.TopbarInset.Height
					for _, at in { { Name = "this window", Scale = nil :: number?, Box = nil :: Vector2? }, { Name = "the smallest phone", Scale = Theme.Scale.Floor, Box = Theme.Smallest - Vector2.new(0, high) } } do
						Layers.Force(at.Scale)
						Layers.Box(at.Box)
						t.Wait(0.1) -- laid out again, the band and the corner with it
						local band = world:GetAttribute("Band")
						local scale = Layers.Scale()
						if type(band) ~= "number" then
							t.Check(`{at.Name}: the band`, false)
							continue
						end
						local foot = world.AbsolutePosition.Y + band * scale
						local below = eye.AbsolutePosition.Y + eye.AbsoluteSize.Y > foot
						t.Row(`{at.Name}: the eye's foot past the band's`, nil, nil, eye.AbsolutePosition.Y + eye.AbsoluteSize.Y - foot, "px")
						local inset = GuiService:GetGuiInset()
						local x = eye.AbsolutePosition.X + eye.AbsoluteSize.X / 2 + inset.X
						local y = world.AbsolutePosition.Y + band * scale * 0.5 + inset.Y
						camera.CFrame = CFrame.lookAt(from, point)
						local aside = camera.CFrame:VectorToObjectSpace(camera:ViewportPointToRay(x, y).Direction)
						camera.CFrame *= CFrame.fromRotationBetweenVectors(aside, Vector3.new(0, 0, -1))
						for _ = 1, 3 do
							RunService.RenderStepped:Wait()
						end
						local seen = camera:WorldToViewportPoint(point)
						t.Check(`{at.Name}: the Breaker's point is over the eye`, math.abs(seen.X - x) < eye.AbsoluteSize.X / 2, string.format("%.1f against %.1f", seen.X, x))
						t.Check(`{at.Name}: its plate shows`, plate.Visible and plate.Parent ~= nil)
						local p0, p1 = plate.AbsolutePosition, plate.AbsolutePosition + plate.AbsoluteSize
						local function clear(frame: GuiObject): (boolean, string)
							local a0, a1 = frame.AbsolutePosition, frame.AbsolutePosition + frame.AbsoluteSize
							local ok = p0.X >= a1.X - 0.5 or p1.X <= a0.X + 0.5 or p0.Y >= a1.Y - 0.5 or p1.Y <= a0.Y + 0.5
							return ok, string.format("the plate %.0f,%.0f to %.0f,%.0f; it %.0f,%.0f to %.0f,%.0f", p0.X, p0.Y, p1.X, p1.Y, a0.X, a0.Y, a1.X, a1.Y)
						end
						t.Check(`{at.Name}: clear of the eye`, clear(eye))
						t.Check(`{at.Name}: clear of the readout`, clear(piece))
						local under = (p0.Y - world.AbsolutePosition.Y) / scale - band
						t.Check(`{at.Name}: whole under the band`, under >= -1, string.format("its top %.1f px under the band", under))
						local gap = (p0.X - (eye.AbsolutePosition.X + eye.AbsoluteSize.X)) / scale
						if below then
							t.Check(`{at.Name}: right beside the eye, not lost aside`, gap >= -0.5 and gap <= HudConfig.Numbers.Band + 2, string.format("%.1f px right of it", gap))
						else
							t.Check(`{at.Name}: the eye in the band, the plate under it at its point, not pushed aside`, gap <= HudConfig.Numbers.Band + 2, string.format("%.1f px right of it", gap))
						end
					end
					Layers.Box(nil)
					Layers.Force(nil)
					t.Wait(0.1)
					-- Roblox's own prompt, its point aimed at the Electricity pill: its card stands under the band, clear of the
					-- pill (research's fix on AR16, 2026-11-17: "Void Breaker · Open" stood over it on every visit).
					local prompt = BaseController.Parts().BreakerPrompt :: ProximityPrompt?
					local pill = hud.Electricity
					local spot = if prompt and prompt.Parent and prompt.Parent:IsA("BasePart") then prompt.Parent.Position else nil
					t.Check("the Breaker's prompt shows", prompt ~= nil and spot ~= nil and waitFor(t, 1, function(): boolean
						local gui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
						local holder = if gui then gui:FindFirstChild("ProximityPrompts") else nil
						for _, item in if holder then holder:GetChildren() else {} do
							if item:IsA("BillboardGui") and item.Adornee == (prompt :: ProximityPrompt).Parent then
								return true
							end
						end
						return false
					end))
					if prompt and spot and pill then
						local inset = GuiService:GetGuiInset()
						local aim = pill.AbsolutePosition + pill.AbsoluteSize / 2 + inset
						camera.CFrame = CFrame.lookAt(from, spot)
						local aside = camera.CFrame:VectorToObjectSpace(camera:ViewportPointToRay(aim.X, aim.Y).Direction)
						camera.CFrame *= CFrame.fromRotationBetweenVectors(aside, Vector3.new(0, 0, -1))
						for _ = 1, 3 do
							RunService.RenderStepped:Wait()
						end
						local seen = camera:WorldToViewportPoint(spot)
						t.Check("its point stands on the pill", math.abs(seen.Y - aim.Y) < pill.AbsoluteSize.Y and math.abs(seen.X - aim.X) < pill.AbsoluteSize.X / 2, string.format("%.0f,%.0f against %.0f,%.0f", seen.X, seen.Y, aim.X, aim.Y))
						local c0, c1 = World.PromptBox(prompt)
						local foot = World.BandFoot()
						t.Check("its card stands under the band", c0 ~= nil and foot ~= nil and c0.Y >= foot - 1, string.format("its top %.1f, the band's foot %.1f", if c0 then c0.Y else -1, foot or -1))
						local p0, p1 = pill.AbsolutePosition + inset, pill.AbsolutePosition + pill.AbsoluteSize + inset
						t.Check("clear of the pill", c0 ~= nil and c1 ~= nil and (c0.Y >= p1.Y - 0.5 or c1.Y <= p0.Y + 0.5 or c0.X >= p1.X - 0.5 or c1.X <= p0.X + 0.5))
					end
					camera.CameraType = Enum.CameraType.Custom
					t.Wait(0.1)
				end
				if type(gave) == "table" and gave.Ok == true then
					t.Server("BaseGive", shard, -1)
				end
			end,
		},
		{
			-- TR21's blockout (docs/ui.md, 7; UI/BaseView): the camera lifts over the player's whole base, each machine and
			-- bay wears a chip saying its name, its level and what it does, the base's level stands at the top, the HUD and
			-- the machines' own plates step back, and Close gives the camera back behind the lead.
			Name = "Base view: TR21's blockout, the camera lifts over the whole base, a chip on every machine and bay, and Close gives it back",
			Place = "Main", -- TR45: its world stands in that place only
			Run = function(t: any)
				Screen.Close()
				local camera = workspace.CurrentCamera
				local was = camera.CFrame
				local seconds = BaseViewConfig.Lift.Seconds
				HudController.OpenView()
				t.Check("it opens", BaseView.IsOpen())
				t.Wait(seconds + 0.3)
				local ok, err = pcall(function()
					t.Equal("the camera is the view's", camera.CameraType, Enum.CameraType.Scriptable)
					-- Over the machines' floor, not over where the camera was: the self-test's pad stands far above the plot.
					local floor = -math.huge
					for _, spot in BaseController.Says() do
						floor = math.max(floor, spot.Ground.Y)
					end
					t.Check("lifted over the base", camera.CFrame.Position.Y > floor + 20, `{math.floor(camera.CFrame.Position.Y)} against the floor at {math.floor(floor)}`)
					local chips = BaseView.Parts().Chips
					local room = Layers.Get("World").AbsoluteSize
					local names = 0
					for name in BaseController.Says() do
						names += 1
						local chip = chips[name]
						local title = chip and chip:FindFirstChild("Title", true)
						local doing = chip and chip:FindFirstChild("Doing", true)
						local at = if chip then chip.AbsolutePosition - Layers.Get("World").AbsolutePosition else Vector2.zero
						local inside = chip ~= nil and at.X >= 0 and at.Y >= 0 and at.X + chip.AbsoluteSize.X <= room.X and at.Y + chip.AbsoluteSize.Y <= room.Y
						t.Check(`{name}: its chip in view`, chip ~= nil and chip.Visible and inside, if chip then `{math.floor(at.X)}, {math.floor(at.Y)}` else "none")
						t.Check(`{name}: it says what it is and what it does`, title ~= nil and title:IsA("TextLabel") and title.Text ~= "" and doing ~= nil and doing:IsA("TextLabel") and doing.Text ~= "", if title and title:IsA("TextLabel") then title.Text else "")
					end
					t.Check("the base's machines and bays, every one", names >= 5, tostring(names))
					-- No chip covers another, however close their machines stand: one rises over the other.
					local crossed: { string } = {}
					for one, a in chips do
						for other, b in chips do
							if one < other and a.Visible and b.Visible then
								local p, q = a.AbsolutePosition, b.AbsolutePosition
								local across = p.X < q.X + b.AbsoluteSize.X and q.X < p.X + a.AbsoluteSize.X
								local up = p.Y < q.Y + b.AbsoluteSize.Y and q.Y < p.Y + a.AbsoluteSize.Y
								if across and up then
									table.insert(crossed, `{one} over {other}`)
								end
							end
						end
					end
					t.Check("no chip covers another", #crossed == 0, table.concat(crossed, ", "))
					local level = BaseView.Parts().Level
					local under: { string } = {}
					if level then
						local foot = level.AbsolutePosition.Y + level.AbsoluteSize.Y
						for name, chip in chips do
							if chip.Visible and chip.AbsolutePosition.Y < foot then
								table.insert(under, `{name} {math.floor(foot - chip.AbsolutePosition.Y)} px`)
							end
						end
					end
					t.Check("nor the base's level at the top", #under == 0, table.concat(under, ", "))
					local top = level and level:FindFirstChild("Title", true)
					t.Check("the base's level at the top", top ~= nil and top:IsA("TextLabel") and string.find(top.Text, "^Base · Level %d") ~= nil, if top and top:IsA("TextLabel") then top.Text else "")
					t.Check("the HUD steps back", not Layers.Get("Hud").Visible)
					local plate = BaseController.Parts().BreakerPlate
					t.Check("and the machines' own plates", plate == nil or not (plate :: GuiObject).Visible)
					lintClean(t, "the base's command view")
				end)
				BaseView.Close()
				t.Wait(seconds + 0.3)
				t.Equal("Close gives the camera back", camera.CameraType, Enum.CameraType.Custom)
				t.Check("behind the lead, where it was", (camera.CFrame.Position - was.Position).Magnitude < 2, `{math.floor((camera.CFrame.Position - was.Position).Magnitude)} studs off`)
				t.Check("the HUD is back", Layers.Get("Hud").Visible)
				if not ok then
					error(err, 0)
				end
			end,
		},
		{
			-- TR24's fix 8 (Config.Effects.Drop; Rules.Flight): a shard won drops in the world with its name and flies to
			-- the avatar, and the toast's moment, `landed`, comes as it lands on them.
			Name = "HUD: TR24's fix 8, a shard won drops in the world with its name over it and flies into the avatar, landing as its toast",
			Run = function(t: any)
				local root = Parts.Root(Players.LocalPlayer.Character)
				t.Check("the avatar stands", root ~= nil)
				if root == nil then
					return
				end
				local look = EffectsConfig.Drop
				local avatar = root :: BasePart
				local from = avatar.Position + avatar.CFrame.LookVector * 20 -- a Shade fallen 20 studs ahead, at root height
				local name = "Test shard"
				local landedAt: number? = nil
				local began = os.clock()
				local before = Effects.Drops()
				Effects.Drop(from, function(): Vector3?
					return if avatar.Parent then avatar.Position else nil
				end, name, function()
					landedAt = os.clock()
				end)
				local shard: BasePart? = nil
				local plate: Frame? = nil
				for part, frame in Effects.Drops() do
					if before[part] == nil then
						shard, plate = part, frame
					end
				end
				t.Check("a shard is in the world", shard ~= nil)
				if shard == nil or plate == nil then
					return
				end
				t.Check("it's the hero size", math.abs(shard.Size.Y - look.Size) < 1e-3, `{shard.Size.Y}`)
				local named = plate :: Frame
				local label = named:FindFirstChild("Name")
				t.Equal("its plate says its name", if label and label:IsA("TextLabel") then label.Text else "", name)
				-- in the rest: on the floor, a step toward the avatar, its plate over it
				local restAt = look.Pop.Seconds + look.Bounce.Seconds + look.Rest / 2
				t.Wait(restAt)
				local floor = from.Y - 3
				t.Check("resting, it sits on the floor", math.abs(shard.Position.Y - (floor + look.Hover)) < 0.3, `{shard.Position.Y - floor} over the floor`)
				local flatGap = (Vector3.new(shard.Position.X, 0, shard.Position.Z) - Vector3.new(from.X, 0, from.Z)).Magnitude
				t.Check("a step toward the avatar from its fall", math.abs(flatGap - look.Pop.Out) < 0.3, `{flatGap} studs`)
				local over = World.Where(named)
				t.Check("its name stands over it", over ~= nil and over.Y > shard.Position.Y + look.Size / 2, if over then tostring(over) else "hidden")
				t.Check("nothing landed yet", landedAt == nil)
				-- the end: it's on the avatar and gone, and the toast's moment came then
				t.Check("it lands", waitFor(t, Flight.Length(look) + 1, function(): boolean
					return landedAt ~= nil
				end))
				local took = if landedAt then landedAt - began else 0
				t.Check("it lands as its flight ends", math.abs(took - Flight.Length(look)) < 0.25, `{took} s`)
				t.Check("the shard is gone from the world", shard.Parent == nil and Effects.Drops()[shard] == nil)
			end,
		},
		{
			Name = "HUD: the world's marker only in the tutorial (TR65): before a keeper is beaten, its chevron or edge arrow on the next step; after, with shards ready, neither, and the line still says them",
			Place = "Main", -- the plot's Breaker
			Run = function(t: any)
				local was = t.Server("KeeperWinsSet")
				t.Check("the save's keeper wins read", type(was) == "table" and was.Ok == true and type(was.Wins) == "table")
				if type(was) ~= "table" or was.Ok ~= true then
					return
				end
				local none, back = {}, {}
				for ground, wins in was.Wins do
					none[ground] = { Normal = 0, Hard = 0 }
					back[ground] = wins
				end
				if back[Grounds.First] == nil then
					back[Grounds.First] = false -- a record only this case made goes again
				end
				local function beaten(): boolean
					local view = ProfileController.Get()
					return view ~= nil and Progress.Beaten(view.Progress.Grounds)
				end
				local function readyLine(): string
					local view = ProfileController.Get()
					local count = if view then #view.Base.Ready else 0
					return if count == 1 then "Ready to open at the Breaker" else `{count} ready to open at the Breaker`
				end
				local shard = "lanternrow_standard"
				local before = Helpers.readyCount(shard)
				local failed: any = nil
				local ok = xpcall(function()
					-- A shard ready at the Breaker, and the avatar home, before it.
					local gave = t.Server("BaseGive", shard, 1)
					local added = type(gave) == "table" and gave.Ok == true and ProfileController.Act("AddShard", { Shard = shard }).Ok == true
					t.Server("BaseSkip", Helpers.SKIP_ALL)
					t.Check("a shard ready at the Breaker", added and waitFor(t, ANSWER, function(): boolean
						return Helpers.readyCount(shard) > before
					end))
					local plot = Players.LocalPlayer:GetAttribute("Plot")
					local mill = if type(plot) == "number" then Markers.Find("Generator", { Plot = plot }) else nil
					local breaker = BaseController.Says().Breaker
					if breaker and mill then
						local flat = Markers.At(mill).Position - breaker.Ground
						local toward = Vector3.new(flat.X, 0, flat.Z).Unit
						t.Server("TestStandAt", breaker.Ground + toward * (HudConfig.Guide.Near + 8) + Vector3.new(0, 3, 0), breaker.Ground) -- past where the marker steps back
					end
					t.Wait(0.5)
					-- No keeper beaten: the tutorial, so the marker stands on the Breaker.
					t.Server("KeeperWinsSet", none)
					local shows = waitFor(t, ANSWER, function(): boolean
						local read = Guide.Read()
						return not beaten() and read.Count > 0 and (read.Shown > 0 or read.Edge)
					end)
					local read = Guide.Read()
					local step = HudController.Step()
					t.Check("before a keeper is beaten, the next step's marker shows", shows and step ~= nil and step.Target == "Breaker",
						`{read.Count} targets, {read.Shown} chevrons, edge {read.Edge}, step {if step then step.Target else "none"}`)
					-- A keeper beaten: past the tutorial, no marker, and the line stays.
					t.Server("KeeperWinsSet", { [Grounds.First] = { Normal = 1, Hard = 0 } })
					local gone = waitFor(t, ANSWER, function(): boolean
						read = Guide.Read()
						return beaten() and read.Count == 0 and read.Shown == 0 and not read.Edge
					end)
					t.Check("after it, no chevron and no edge arrow", gone, `{read.Count} targets, {read.Shown} chevrons, edge {read.Edge}`)
					local chip = HudController.Parts().ChipText :: TextLabel?
					t.Check("and the line still says the shards ready", chip ~= nil and chip.Text == readyLine(), if chip then chip.Text else "no line")
				end, function(problem: any): any
					failed = problem
					return problem
				end)
				t.Server("KeeperWinsSet", back)
				Helpers.openReadyDown(t, shard, before)
				if not ok then
					error(failed, 0)
				end
			end,
		},
	{
		-- AR62's piece 1 (B in F2's finish): the signature's press alone, through the states it must show.
		Name = "HUD: AR62, the press draws its states: its art in one slot, its cooldown one layer over it (the veil, the count, the ring lit by the share), gold when ready, the flash",
		Run = function(t: any)
			local config = HudConfig.Readout
			local slate: any = HudConfig.Slate
			local cool = slate.Press.Cooldown
			local holder = Instance.new("Frame")
			holder.Name = "SelfTestReadout"
			holder.BackgroundTransparency = 1
			holder.Size = UDim2.fromOffset(80, 80)
			holder.Position = UDim2.fromOffset(-500, -500) -- off the screen
			holder.Parent = Layers.Get("Hud")
			local piece = Readout.new(holder)
			local drawn = next(config.Icons)
			local function state(share: number, flash: number?, seen: number?, action: string?, left: number?): Readout.State
				return { Share = share, Full = share >= 1, Left = left, Flash = flash or 0, Swell = 0, Seen = seen or 1, Action = action or drawn or "", Class = "Warrior" }
			end
			t.Near("the press is the tap's size", piece.Frame.Size.X.Offset, slate.Press.Size / slate.Page, 1) -- whole points
			-- The director's next direction drops in (2026-11-27, by 01:00): the cooldown one layer over the disc and its art.
			t.Check("its cooldown one layer over the disc and its art: the veil, the ring and the count in it", piece.Cooldown.ZIndex > piece.Art.ZIndex
				and piece.Veil:IsDescendantOf(piece.Cooldown) and piece.Count:IsDescendantOf(piece.Cooldown) and piece.Halves[1]:IsDescendantOf(piece.Cooldown)
				and not piece.Disc:IsDescendantOf(piece.Cooldown) and not piece.Art:IsDescendantOf(piece.Cooldown))
			for _, share in { 0, 0.25, 0.5, 0.75, 0.99 } do
				Readout.Step(piece, state(share))
				t.Near(`at {share}: it says how full`, piece.Frame:GetAttribute("Share") :: number, share, 1e-6)
				-- The ring clockwise from the top: the right half to 0.5, the left after (UI.Readout's halves).
				t.Near(`at {share}: the right half lit to its share`, piece.Halves[1].Rotation, math.min(share, 0.5) * 360, 1e-6)
				t.Near(`at {share}: the left half after it`, piece.Halves[2].Rotation, math.max(share, 0.5) * 360, 1e-3)
				t.Check(`at {share}: charging, the veil over the disc and its art`, math.abs(piece.Glass.BackgroundTransparency - cool.Veil) < 0.01
					and piece.Gold.BackgroundTransparency < 0.01 and piece.Art.ImageTransparency < 0.01,
					string.format("veil %.2f, gold %.2f, art %.2f", piece.Glass.BackgroundTransparency, piece.Gold.BackgroundTransparency, piece.Art.ImageTransparency))
			end
			Readout.Step(piece, state(0.6, 0, 1, nil, 3.2))
			t.Check("cooling, the seconds left on it, whole", piece.Count.Visible and piece.Count.Text == "4", `{piece.Count.Visible} {piece.Count.Text}`)
			Readout.Step(piece, state(1))
			t.Check("ready: the gold disc and its art whole, no veil, the ring whole, no count", piece.Gold.BackgroundTransparency < 0.01 and piece.Art.ImageTransparency < 0.01
				and piece.Glass.BackgroundTransparency > 0.99 and piece.Halves[1].Rotation == 180 and piece.Halves[2].Rotation == 360 and not piece.Count.Visible)
			t.Check("and its lit curve from below", piece.Curve.Transparency < 0.99, string.format("%.2f", piece.Curve.Transparency))
			if drawn then
				local mark = config.Icons[drawn]
				local want = if UIKit.Images[mark] then mark else "ClassWarriorGlyph"
				t.Check("its art today's mark for its signature", piece.Art:GetAttribute("Kit") == want, tostring(piece.Art:GetAttribute("Kit")))
			end
			Readout.Step(piece, state(0, 1))
			t.Check("as it fires it swells", piece.Scale.Scale > 1.1, string.format("%.2f", piece.Scale.Scale))
			t.Check("and the veil isn't in yet", piece.Glass.BackgroundTransparency > 0.99)
			Readout.Step(piece, state(0.05, 0.5))
			t.Near("half through the flash, the veil is half in", piece.Glass.BackgroundTransparency, 1 - 0.5 * (1 - cool.Veil), 0.01)
			Readout.Step(piece, state(0.5, 0, 0))
			local hidden = piece.Art.ImageTransparency > 0.99 and piece.Gold.BackgroundTransparency > 0.99 and piece.Glass.BackgroundTransparency > 0.99
				and piece.Track.Transparency > 0.99 and piece.TrackInk.Transparency > 0.99 and piece.Curve.Transparency > 0.99
			for _, line in piece.Lit do
				hidden = hidden and line.Transparency > 0.99
			end
			t.Check("faded out, every layer is", hidden)
			Readout.Step(piece, state(0.5, 0, 1, "SelfTestNoIcon"))
			t.Check("a signature with no art yet shows its class's glyph in white", piece.Art:GetAttribute("Kit") == "ClassWarriorGlyph" and piece.Art.ImageColor3 == slate.Ink, tostring(piece.Art:GetAttribute("Kit")))
			-- A signature's own art (its image, or its name as lettering) takes the slot from the token alone.
			local images = slate.Press.Art.Images
			images.SelfTestArt = "rbxassetid://1"
			local ok, failed = pcall(function()
				Readout.Step(piece, state(1, 0, 1, "SelfTestArt"))
				t.Check("its own art, from its token, takes the slot", piece.Art.Image == "rbxassetid://1" and piece.Art:GetAttribute("Kit") == nil
					and piece.Frame:GetAttribute("Art") == "rbxassetid://1" and piece.Art.ImageRectSize == Vector2.zero, piece.Art.Image)
			end)
			images.SelfTestArt = nil
			if not ok then
				error(failed, 0)
			end
			holder:Destroy()
		end,
	},
	{
		-- AR62 piece 1, research's F2 must-fixes: the slate's page at the target's size past the layers' cap (2), every word
		-- on the plates in the display face at its em, in its stroke (1), Modulo's painted marks (3).
		Name = "HUD: AR62, piece 1 at F2's size: the page grows past the cap, the plates' words in the display face at their em, the painted marks",
		Run = function(t: any)
			t.Wait(1)
			local slate: any = HudConfig.Slate
			local parts = HudController.Parts()
			local root = Slate.Root()
			local grow = root:FindFirstChild("Grow") :: UIScale?
			local card = parts.Lead
			t.Check("the cards, the press and Auto stand in the slate's page", card.Parent == root and parts.Target.Parent == root
				and parts.Signature.Parent == root and parts.SignatureAuto.Parent == root and parts.Spectate.Parent == root,
				if card.Parent then card.Parent:GetFullName() else "none")
			t.Near("its grow: the page's fit over the layers'", if grow then grow.Scale else 0, Slate.Grow(), 1e-3)
			local k = card.AbsoluteSize.X / math.max(card.Size.X.Offset, 1)
			t.Near("a card's point draws at the page's fit, the target's size by height", k, Layers.Fit(slate.Cap), 0.02)
			-- The words: their em the target's (a TextSize is the line, the em its share), or more where the floor lifts it.
			local em = slate.Text.Em
			for name, page in { LeadName = slate.Lead.Name, LeadLevel = slate.Badge.Text, TargetName = slate.Foe.Name, TargetLevel = slate.Foe.Level } :: { [string]: number } do
				local label = parts[name] :: TextLabel
				local stroke = label:FindFirstChild("Stroke") :: UIStroke?
				t.Check(`{name}: the display face in its stroke`, label.FontFace.Family == slate.Face and stroke ~= nil and stroke.Enabled
					and stroke.Thickness >= 1, `{label.FontFace.Family}, {if stroke then stroke.Thickness else "no stroke"}`)
				t.Check(`{name}: its em the target's, or the floor's`, label.TextSize * em >= Slate.Pt(page) - 1,
					string.format("%.1f, want %.1f", label.TextSize * em, Slate.Pt(page)))
				-- the floor counts the page's grow: a word whose em already draws 14 px keeps its size
				if Slate.Pt(page) * Layers.Scale() * Slate.Grow() >= Theme.Text.Minimum + 1 then
					t.Near(`{name}: no lift where its em draws 14 px already`, label.TextSize, Slate.Pt(page) / em, 1)
				end
			end
			local said = parts.SignatureAuto:FindFirstChild("Word", true) :: TextLabel?
			t.Check("Auto's word too", said ~= nil and said.FontFace.Family == slate.Face and said:FindFirstChild("Stroke") ~= nil,
				if said then said.FontFace.Family else "none")
			-- The marks: Modulo's painting where one is made, its drawing `across` and its pad round it.
			local function painted(image: Instance?, kit: string): (boolean, string)
				local im = UIKit.Images[slate.Icons[kit] or ""]
				local ok = image ~= nil and image:IsA("ImageLabel") and image:GetAttribute("Kit") == kit and image:GetAttribute("Painted") == true
					and im ~= nil and image.Image == im.Id
				return ok, if image then `{tostring(image:GetAttribute("Kit"))}, painted {tostring(image:GetAttribute("Painted"))}` else "none"
			end
			t.Check("the foe's skull, painted", painted(parts.TargetSkull, "Skull"))
			local eye = parts.Spectate:FindFirstChild("On", true) :: ImageLabel?
			t.Check("the eye, painted", painted(eye, "Eye"))
			local im = UIKit.Images[slate.Icons.Eye]
			if eye and im then
				t.Near("its drawing Icon points across", eye.Size.X.Offset * (im.Points.X - 2 * im.Pad) / im.Points.X, Slate.Pt(slate.Eye.Icon), 0.5)
			end
			local on = Players.LocalPlayer:GetAttribute("SignatureAuto") ~= false
			t.Check("Auto's turn, painted for its state", painted(parts.SignatureAuto:FindFirstChild("Turn", true), if on then "AutoOn" else "AutoOff"))
			local gem = parts.LeadGem
			local kind = tostring(gem:GetAttribute("Kit"))
			if slate.Icons[kind] then
				t.Check("the lead's gem, painted", painted(gem, kind))
			else
				t.Row(`the lead's gem: {kind} has no painting yet`, nil, nil, 0, "")
			end
			local class = card:FindFirstChild("Class", true) :: ImageLabel?
			local named = if class then tostring(class:GetAttribute("Kit")) else ""
			if slate.Icons[named] then
				t.Check("the lead's class mark, painted, in its own colours", class ~= nil and class.ImageColor3 == Color3.new(1, 1, 1) and painted(class, named))
			else
				t.Check(`the lead's class mark {named}, the kit's in the quiet ink`, class ~= nil and class.ImageColor3 == slate.Ink2)
			end
			local probe = Instance.new("ImageLabel")
			Slate.Mark(probe, "GemRed", 10)
			local gemIm = UIKit.Images[slate.Icons.GemRed]
			t.Check("a red gem marked: the painted one, about its middle, its pad round its 10 points", painted(probe, "GemRed") and probe.AnchorPoint == Vector2.new(0.5, 0.5)
				and math.abs(probe.Size.X.Offset - 10 * gemIm.Points.X / (gemIm.Points.X - 2 * gemIm.Pad)) < 1, tostring(probe.Size))
			Slate.Mark(probe, "GemBlue")
			t.Check("an unpainted one: the kit's", probe:GetAttribute("Painted") == false and probe:GetAttribute("Kit") == "GemBlue"
				and (UIKit.Images.GemBlue == nil or probe.Image == UIKit.Images.GemBlue.Id), tostring(probe:GetAttribute("Kit")))
			probe:Destroy()
			-- On a phone's scale the page doesn't grow: a forced scale is the screen's.
			local ok, failed = pcall(function()
				Layers.Force(Theme.Scale.Floor)
				t.Wait(0.2)
				t.Near("forced to the floor, the page doesn't grow", if grow then grow.Scale else 0, 1, 1e-3)
				-- The smallest phone's words (research, 2ef0afec: the level, the name and the health under 14 px): each em 14 px
				for _, name in { "LeadName", "LeadLevel", "LeadHealthText", "TargetName", "TargetLevel" } do
					local label = parts[name] :: TextLabel
					local drawn = label.TextSize * em * Theme.Scale.Floor
					t.Check(`{name}: its em 14 px at the floor's scale`, drawn >= Theme.Text.Minimum - 0.05, string.format("%.1f px", drawn))
				end
			end)
			Layers.Force(nil)
			t.Wait(0.3)
			if not ok then
				error(failed, 0)
			end
		end,
	},
	{
		-- Research, after the director's 02:04 word: the finish is Modulo's painted 9-slices, so a plate's surface is a slot
		-- they drop into (Config.Hud.Slate.Surfaces), the ring stack where none is named.
		Name = "HUD: AR62, a plate's painted surface: a 9-slice named for its kind and side takes the ring stack's place, sliced at its density",
		Run = function(t: any)
			local slate: any = HudConfig.Slate
			local images: any = UIKit.Images
			local surfaces = slate.Surfaces
			local holder = Instance.new("Frame")
			holder.Name = "SelfTestSurface"
			holder.BackgroundTransparency = 1
			holder.Size = UDim2.fromOffset(300, 200)
			holder.Parent = Layers.Get("Hud")
			local ok, failed = pcall(function()
				local plate = Slate.Plate(holder, "Card", Vector2.new(160, 45), "Mine")
				local glass, lift = plate:FindFirstChild("Glass") :: Frame, plate:FindFirstChild("Lift") :: Frame
				t.Check("none named: the ring stack and its lift", glass.Visible and lift.Visible and (plate:FindFirstChild("Surface") == nil
					or not (plate:FindFirstChild("Surface") :: GuiObject).Visible))
				images.SelfTestSurface = { Id = "rbxassetid://1", Pixels = Vector2.new(256, 128), Points = Vector2.new(100, 50), Pad = 0 }
				slate.Surfaces = { ["Card.Mine"] = { Image = "SelfTestSurface", Slice = Rect.new(40, 40, 216, 88), Density = 2, Out = 1.28 } }
				Slate.Side(plate, "Theirs")
				Slate.Side(plate, "Mine") -- painted again with the surface named
				local surface = plate:FindFirstChild("Surface") :: ImageLabel?
				t.Check("named for Card.Mine: its 9-slice shows, the stack and the lift hidden", surface ~= nil and surface.Visible and surface.Image == "rbxassetid://1"
					and surface.ScaleType == Enum.ScaleType.Slice and surface.SliceCenter == Rect.new(40, 40, 216, 88) and not glass.Visible and not lift.Visible)
				if surface then
					t.Near("sliced at its density: two pixels a page point", surface.SliceScale, 1 / (2 * slate.Page), 1e-4)
					t.Check("reaching Out past the plate each side", surface.Size == UDim2.new(1, 2, 1, 2), tostring(surface.Size))
					Slate.Clear(plate, 0.4)
					t.Near("and fading with it", surface.ImageTransparency, 0.4, 1e-3)
				end
				Slate.Side(plate, "Theirs")
				t.Check("another side, none named: the stack again", glass.Visible and lift.Visible and surface ~= nil and not surface.Visible)
				slate.Surfaces = { Card = { Image = "SelfTestSurface", Slice = Rect.new(40, 40, 216, 88), Density = 2 } }
				Slate.Side(plate, "Mine")
				t.Check("a kind's surface, for every side", surface ~= nil and surface.Visible and not glass.Visible)
			end)
			slate.Surfaces = surfaces
			images.SelfTestSurface = nil
			holder:Destroy()
			if not ok then
				error(failed, 0)
			end
		end,
	},
	}
end

return HudCases
