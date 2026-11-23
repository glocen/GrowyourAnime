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
local Effects = require(script.Parent.Parent.Parent.Main.FighterController.Effects)
local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local BaseController = require(script.Parent.Parent.Parent.Main.BaseController)
local DownController = require(script.Parent.Parent.Parent.Main.DownController)
local ProfileController = require(script.Parent.Parent.ProfileController)
local Helpers = require(script.Parent.Helpers)
local UI = script.Parent.Parent.Parent.Parent.UI
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
	local lead = parts.Lead :: Frame
	local badge = lead:FindFirstChild("LevelBadge") :: ImageLabel?
	if not t.Check("its level on a badge", badge ~= nil and lead:FindFirstChild("LevelPlate") == nil, "no LevelBadge") or not badge then
		return
	end
	local frame, at, pad = UIKit.LeadCard.Frame, lead.AbsolutePosition, UIKit.Images.CardLevelBadge.Pad * scale
	local top, left = badge.AbsolutePosition.Y + pad, badge.AbsolutePosition.X + pad -- the block, inside its shadow's pad
	local foot, right = badge.AbsolutePosition.Y + badge.AbsoluteSize.Y - pad, badge.AbsolutePosition.X + badge.AbsoluteSize.X - pad
	local frameFoot, frameRight = at.Y + (frame[2] + frame[4]) * scale, at.X + (frame[1] + frame[3]) * scale
	t.Check("the badge over the frame's foot, inside its width", top < frameFoot and foot > frameFoot and left >= at.X - 1 and right <= frameRight + 1,
		string.format("%.0f to %.0f over %.0f; %.0f to %.0f, the frame to %.0f", top, foot, frameFoot, left, right, frameRight))
	local voidkin, ink = UIKit.Systems.Voidkin, HudConfig.Card.LeadLevel
	local body = badge:FindFirstChildOfClass("UIGradient")
	local chevrons = lead:FindFirstChild("LevelChevrons") :: ImageLabel?
	local number = parts.LeadLevel :: TextLabel
	local rim = lead:FindFirstChild("PlateRim") :: ImageLabel
	t.Check("take A's colours: the badge the Voidkin's Block, the chevrons and number in ink, the edge lavender, the name pale",
		body ~= nil and body.Color.Keypoints[1].Value == voidkin.Block[1] and chevrons ~= nil and chevrons.ImageColor3 == ink and number.TextColor3 == ink
			and rim.ImageColor3 == voidkin.Colour and (parts.LeadName :: TextLabel).TextColor3 == voidkin.Pale,
		`{if body then body.Color.Keypoints[1].Value:ToHex() else "no body"}, {number.TextColor3:ToHex()}, {rim.ImageColor3:ToHex()}`)
	t.Check("its height never stretched: a slanted slice stretched smaller than its pixels draws upright", badge.ScaleType == Enum.ScaleType.Slice and badge.SliceCenter.Height == 0,
		`{badge.ScaleType.Name}, its middle {badge.SliceCenter.Height} tall`)
	local middle = number.AbsolutePosition + number.AbsoluteSize / 2
	local eye = (parts.Spectate :: GuiObject).AbsolutePosition.Y
	t.Check("the number on the badge, the badge above the eye", middle.X > left and middle.X < right and middle.Y > top and middle.Y < foot and foot <= eye + 1,
		string.format("the number at %.0f, %.0f; the badge's foot %.0f, the eye %.0f", middle.X, middle.Y, foot, eye))
end

-- The top of the level badge's tint now: the level-up's pop lifts it toward white (UI.LeadCard.Glow).
function HudCases.BadgeTop(parts: { [string]: any }): Color3
	local badge = (parts.Lead :: Frame):FindFirstChild("LevelBadge")
	local body = if badge then badge:FindFirstChildOfClass("UIGradient") else nil
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
			Name = "Take: TR10's down marker with its pictures at the smallest phone, each held for a still, for research",
			Manual = true,
			Stay = true,
			Run = function(t: any)
				-- Each state is held until the driver moves ReplicatedStorage.NL_TakeStep on ("Near", "Far", "Keeper", "End"):
				-- the elite's plate in the picked layout 24 studs ahead, then 120, then the keeper's. On the smallest phone's
				-- frame inside Studio's window, as AR44's take: the HUD boxed to the window's left 16:9 at the scale the
				-- smallest phone's would be at that height, so a capture of that 16:9 is the phone's picture, larger.
				local step = Instance.new("StringValue")
				step.Name = "NL_TakeStep"
				step.Value = "Ready"
				step.Parent = ReplicatedStorage
				local function await(name: string): boolean
					return waitFor(t, 300, function(): boolean
						return step.Value == name or step.Value == "End"
					end) and step.Value == name
				end
				t.Wait(LEAD_SETTLE)
				-- The world as a player stands in it: the World layer hides under any open screen (a spawn at the base's door
				-- opens the Stage picker, TR45)
				if Screen.Current() ~= nil then
					Screen.Close()
					t.Wait(0.5)
				end
				local tall = workspace.CurrentCamera.ViewportSize.Y
				Layers.Force(Theme.Scale.Floor * tall / Theme.Smallest.Y)
				Layers.Box(Vector2.new(tall * Theme.Smallest.X / Theme.Smallest.Y, tall) - Vector2.new(0, GuiService.TopbarInset.Height))
				local ok, problem = pcall(function()
					if await("Near") then
						standDown(t, "Elite", "brawler_elite", 24)
						t.Wait(0.5)
						t.Check("near: the elite's stands", DownController.Plate("Elite") ~= nil)
					end
					if await("Far") then
						standDown(t, "Elite", "brawler_elite", 120)
						t.Wait(0.5)
					end
					if await("Keeper") then
						DownController.Try("Elite", nil)
						standDown(t, "Keeper", "lamplighter", 24)
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
				end) and word.Text == "You're home", word.Text)
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
					return said("In a fight") and shakes() > before
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
				-- The Map tile's word is Play (TR45; a refused tile's reason is TR19's "You're home", in its own case).
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
				local breakerSpot, batterySpot = says.Breaker, says.Battery
				local near = false
				if camera and breakerSpot and batterySpot then
					camera.CameraType = Enum.CameraType.Scriptable
					local flat = batterySpot.Ground - breakerSpot.Ground
					local back = Vector3.new(flat.X, 0, flat.Z).Unit
					local side = Vector3.new(-back.Z, 0, back.X)
					t.Server("TestStandAt", breakerSpot.Ground + side * 9 + Vector3.new(0, 3, 0), breakerSpot.Ground)
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
						t.Check(`{at.Name}: the eye reaches below the band`, eye.AbsolutePosition.Y + eye.AbsoluteSize.Y > foot, string.format("its foot %.1f, the band's %.1f", eye.AbsolutePosition.Y + eye.AbsoluteSize.Y, foot))
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
						t.Check(`{at.Name}: right beside the eye, not lost aside`, gap >= -0.5 and gap <= HudConfig.Numbers.Band + 2, string.format("%.1f px right of it", gap))
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
	}
end

return HudCases
