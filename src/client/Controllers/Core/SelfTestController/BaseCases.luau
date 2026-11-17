--!strict
-- BaseCases (client, Studio only): the base's cases on its plot, a list of their own beside Cases, which joins it as it
-- joins PowerCases (Cases' one table had passed what the type solver checks in one piece). AR16's base as its save has
-- it: the bays awake and asleep, the battery's cells, the Void Mill's wheel, gauge and demand mark (AR19) and the
-- Training machine's crown; its machines' plates apart from the spawn; and the first session's shards opening themselves
-- on the plot (TR24's fix 5); the Festival Door's and the gate's names (TR24's fix 10); a bay's worker at work in its ring,
-- its halo lit in its rarity colour, and the step's chevron over the bay it names (TR24's fix 1).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local BaseLevels = require(Shared.Rules.BaseLevels)
local Breaker = require(Shared.Rules.Breaker)
local ShardConfig = require(Shared.Config.Shards)
local Shards = require(Shared.Definitions.Shards)
local Voidkin = require(Shared.Definitions.Voidkin)
local Power = require(Shared.Rules.Power)
local LightingConfig = require(Shared.Config.Lighting)
local WorldConfig = require(Shared.Config.World)
local Markers = require(Shared.World.Markers)
local BaseManifest: any = require(Shared.Config.Kits.Base.Manifest)
local BasePlan: any = require(Shared.Config.Kits.Base.Plan)
local BaseController = require(script.Parent.Parent.Parent.Main.BaseController)
local LightingController = require(script.Parent.Parent.Parent.Main.LightingController)
local SignsController = require(script.Parent.Parent.Parent.Main.SignsController)
local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local AnimationsConfig = require(Shared.Config.Animations)
local RevealConfig = require(Shared.Config.Reveal)
local Grounds = require(Shared.Definitions.Grounds)
local ProfileController = require(script.Parent.Parent.ProfileController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Layers = require(UI.Layers)
local World = require(UI.World)

-- The base's machine plates by name, beside "Bay1" to "Bay6" (BaseController.Parts).
local PLATES = { Breaker = true, Battery = true, Training = true, Generator = true }

local BaseCases = {}

local SKIP_ALL = 3600 -- seconds of base time a case skips, past any shard's work even at the floor's speed

-- Broken shards waiting to be opened that open themselves (Rules.Breaker.SelfOpening's grades).
local function selfOpeners(): number
	local view = ProfileController.Get()
	local count = 0
	for _, work in (if view then view.Base.Ready else {}) do
		local shard = Shards.ById[work.Def]
		local grade = shard and ShardConfig.Grades[shard.Grade]
		count += if grade and grade.Opens == true then 1 else 0
	end
	return count
end

-- Cases' own helpers and measures, one home each.
export type Given = {
	ANSWER: number,
	waitFor: (t: any, seconds: number, ok: () -> boolean) -> boolean,
}

function BaseCases.Cases(given: Given): { any }
	local ANSWER, waitFor = given.ANSWER, given.waitFor
	return {
		{
			Name = "Base: AR16's base as its save has it: the bays it opened awake and the rest asleep, the battery's cells by its level and lit by its charge, the mill's wheel, gauge and demand mark (AR19), the crown while a Voidkin trains",
			Run = function(t: any)
				local view = ProfileController.Get()
				local plot = Players.LocalPlayer:GetAttribute("Plot")
				local function rackOf(): Instance?
					local found = if type(plot) == "number" then Markers.Find("Battery", { Plot = plot }) else nil
					return if found then found:FindFirstChild("Rack") else nil
				end
				-- Read at home: a case before may leave the avatar at the crossing, where the base streams out.
				if type(plot) == "number" and rackOf() == nil then
					t.Server("Respawn")
					waitFor(t, 8, function(): boolean
						return rackOf() ~= nil
					end)
				end
				local battery = if type(plot) == "number" then Markers.Find("Battery", { Plot = plot }) else nil
				local rack = rackOf()
				if view == nil or type(plot) ~= "number" or rack == nil then
					t.Check("a plot, a save, and the base as its kit", false, if view == nil then "no save yet" elseif type(plot) ~= "number" then "no plot yet" elseif battery == nil then "no battery streamed in" else "a grey base: its battery has no rack")
					return
				end
				-- Every bay the base can open stands on the plot: the opened ones awake, solid as their piece is, the rest asleep
				-- (the content check: nothing stands on a sleeping one, as no worker is sent to a bay the save lacks).
				local open, seen = #view.Base.Bays, 0
				for _, bay in Markers.All("Bay") do
					local index = bay:GetAttribute("Bay")
					if bay:GetAttribute("Plot") ~= plot or type(index) ~= "number" then
						continue
					end
					seen += 1
					-- The far side of the plot may not have streamed in round the avatar: ask for it, and wait for its parts.
					pcall(function()
						Players.LocalPlayer:RequestStreamAroundAsync(Markers.At(bay).Position, 2)
					end)
					local awake = index <= open
					waitFor(t, ANSWER, function(): boolean
						return bay:FindFirstChild("Pad") ~= nil and (awake or bay:FindFirstChild("Sleeping") ~= nil)
					end)
					local pad, sleeping = bay:FindFirstChild("Pad"), bay:FindFirstChild("Sleeping")
					local function shows(part: Instance?, want: boolean): boolean
						return part ~= nil and part:IsA("BasePart") and (part.Transparency == 0) == want
							and part.CanCollide == (want and part:GetAttribute("Solid") == true)
					end
					t.Check(`bay {index}: {if awake then "awake" else "asleep"}`, shows(pad, awake) and ((sleeping == nil and awake) or shows(sleeping, not awake)),
						`pad {if pad and pad:IsA("BasePart") then pad.Transparency else "none"}, asleep {if sleeping and sleeping:IsA("BasePart") then sleeping.Transparency else "none"}`)
				end
				t.Equal("every bay the base can open, on the plot", seen, BaseLevels.Bays(BaseLevels.Top()))
				-- The cells: as many as the level holds, each lit by its share of the charge, its glow from low to full.
				local cells: { BasePart } = {}
				for _, item in (battery :: Instance):GetChildren() do
					local seat = item:GetAttribute("Cell")
					if type(seat) == "number" and item:IsA("BasePart") then
						cells[seat] = item
					end
				end
				t.Equal("a cell on each of the bank's seats", #cells, BaseLevels.Cells(BaseLevels.Top()))
				local empty = LightingConfig.Glow.Empty
				local function wrong(want: { number }): string?
					local now = ProfileController.Get()
					local shown = BaseLevels.Cells((now :: any).Base.Level)
					for seat, cell in cells do
						local lit = want[seat] or 0
						local look = cell:FindFirstChildOfClass("SurfaceAppearance")
						local glow = LightingConfig.Glow.Kit * (empty + (1 - empty) * lit) * LightingController.Look().Glow -- the phase's share (TR23)
						local got = cell:GetAttribute("Lit")
						if (cell.Transparency == 0) ~= (seat <= shown) then
							return `cell {seat}: {if cell.Transparency == 0 then "shown" else "hidden"} at level {(now :: any).Base.Level}`
						elseif type(got) ~= "number" or math.abs(got - lit) > 0.05 then
							return `cell {seat}: lit {tostring(got)}, not {lit}`
						elseif look == nil or math.abs(look.EmissiveStrength - glow) > 0.15 then
							return `cell {seat}: glow {if look then string.format("%.2f", look.EmissiveStrength) else "none"}, not {string.format("%.2f", glow)}`
						end
					end
					return nil
				end
				local count = BaseLevels.Cells(view.Base.Level)
				local capacity = Breaker.Capacity(view.Base)
				local was = view.Base.Charge
				local function full(share: number): { number }
					local want = {}
					for seat = 1, count do
						want[seat] = math.clamp(share * count - (seat - 1), 0, 1)
					end
					return want
				end
				for _, share in { 0, 0.75, 1 } do
					t.Server("BaseBattery", capacity * share)
					t.Check(`at {math.floor(share * 100)}% of its {capacity} kWh, {count} cells lit one after another`, waitFor(t, ANSWER, function(): boolean
						return wrong(full(share)) == nil
					end), wrong(full(share)))
				end
				t.Server("BaseBattery", was)
				-- The Void Mill (AR19), at the stage it stands at: its wheel carries the plant's generation and turns by it,
				-- its gauge's first steps shown as the generation lights them and the rest hidden, and the demand's mark
				-- turned about the axle to the demand's share at its stage's degrees, on one scale (Rules.Power.Gauge).
				local plant = Markers.Find("Generator", { Plot = plot })
				local function standing(): Instance?
					return if plant then BaseController.MillStage(plant) else nil
				end
				local wheel = if standing() then (standing() :: Instance):FindFirstChild("Wheel") else nil
				local mark = if standing() then (standing() :: Instance):FindFirstChild("Demand") else nil
				local mill = WorldConfig.Grey.Generator
				local function gauge(): Power.GaugeRead?
					local now = ProfileController.Get()
					if now == nil then
						return nil
					end
					local rates = Breaker.Rates(now :: any)
					return Power.Gauge(rates.Generation, rates.Demand, mill.Gauge)
				end
				local function stepsWrong(): string?
					local want = gauge()
					local found = standing()
					if want == nil or found == nil then
						return "no save or no mill"
					end
					for step = 1, mill.Gauge.Steps do
						local part = found:FindFirstChild(`Step {step}`)
						if part == nil or not part:IsA("BasePart") then
							return `no step {step}`
						end
						local lit = step <= want.Lit
						if (part.Transparency == 0) ~= lit or (not lit and part.Transparency ~= 1) then
							return `step {step} at {part.Transparency}, {want.Lit} lit`
						end
					end
					return nil
				end
				t.Check("the mill's wheel carries the plant's generation", waitFor(t, ANSWER, function(): boolean
					local now = ProfileController.Get()
					return wheel ~= nil and now ~= nil and wheel:GetAttribute("Generation") == Breaker.Rates(now :: any).Generation
				end), tostring(wheel and wheel:GetAttribute("Generation")))
				t.Check("its gauge's first steps shown as the generation lights them, the rest hidden", waitFor(t, ANSWER, function(): boolean
					return stepsWrong() == nil
				end), stepsWrong())
				t.Check("the demand's mark at the demand's share", waitFor(t, ANSWER, function(): boolean
					local want = gauge()
					local share = if mark then mark:GetAttribute("Share") else nil
					return type(share) == "number" and want ~= nil and math.abs(share - want.Demand) < 1e-6
				end), tostring(mark and mark:GetAttribute("Share")))
				if mark and mark:IsA("BasePart") then
					-- Read once its share has held through two glides: the demand (the Breaker's and the Training machine's
					-- draw) can move meanwhile. In the whole suite, twice on 2026-11-17, the mark was read mid-glide, 0.33 and
					-- 0.37 off a share of 0 that it reaches when the case runs alone.
					local share = mark:GetAttribute("Share")
					local moved = 0
					t.Wait(mill.Gauge.Glide * 2)
					while mark:GetAttribute("Share") ~= share and moved < 5 do
						share = mark:GetAttribute("Share")
						moved += 1
						t.Wait(mill.Gauge.Glide * 2)
					end
					t.Check("its share held through two glides", mark:GetAttribute("Share") == share, `moved {moved} times`)
					local angle = BaseController.TurnedOf(mark)
					local degrees = mark:GetAttribute("Turn")
					t.Check("the mark has its stage's degrees", type(degrees) == "number")
					t.Near("and turned there about the axle, once glided", angle or -1, math.rad(if type(degrees) == "number" then degrees else mill.Gauge.Turn) * (if type(share) == "number" then share else 0), math.rad(1))
				end
				-- How far a turning piece turns in `seconds`, in radians, the way it turns.
				local function turned(part: Instance?, seconds: number): number?
					if part == nil or not part:IsA("BasePart") then
						return nil
					end
					local before = BaseController.TurnedOf(part)
					t.Wait(seconds)
					local after = BaseController.TurnedOf(part)
					if before == nil or after == nil then
						return nil
					end
					return (after - before + math.pi) % (2 * math.pi) - math.pi
				end
				local kw = if wheel then wheel:GetAttribute("Generation") else nil
				if wheel and wheel:IsA("BasePart") and type(kw) == "number" then
					local before = wheel.CFrame
					local spun = turned(wheel, 0.5) or -1
					if kw > 0 then
						local rate = math.min(mill.Wheel.Least + kw * mill.Wheel.PerKw, mill.Wheel.Most)
						t.Near(`it turns heavily at {string.format("%.3f", rate)} turns a second`, spun / (2 * math.pi) / 0.5, rate, rate * 0.25)
						t.Check("about its axle, the line to the gate, so it stays in place", before.Position:FuzzyEq(wheel.CFrame.Position, 1e-3)
							and math.abs(before.LookVector:Dot(wheel.CFrame.LookVector) - 1) < 1e-4)
					else
						t.Check("at no generation, the wheel stands still", before:FuzzyEq(wheel.CFrame, 1e-4))
					end
				end
				-- The mill's stages (AR19): a machine's at the base's ceiling, II at base level 2 and III at 3, each laid
				-- from the swap's table, the other two hidden and their solids open; a stage's pinions driven from its
				-- wheel's angle, about their own axles. The level is the case's own, put back.
				local levelWas = (ProfileController.Get() :: any).Base.Level
				for level = 1, BaseLevels.Top() do
					t.Server("BaseLevel", level)
					local want = BaseLevels.GeneratorStage(level)
					t.Check(`base level {level}: the mill stands at stage {want}`, waitFor(t, ANSWER, function(): boolean
						return plant ~= nil and plant:GetAttribute("Stage") == want
					end), tostring(plant and plant:GetAttribute("Stage")))
					local wrongStage: string? = nil
					for _, group in (if plant then plant:GetChildren() else {}) do
						local at = group:GetAttribute("Stage")
						if type(at) ~= "number" then
							continue
						end
						for _, part in group:GetChildren() do
							if part:IsA("BasePart") and part:GetAttribute("Step") == nil then
								local visible = part:GetAttribute("Unseen") ~= true
								local ok = if at == want
									then (not visible or part.Transparency == 0) and (visible or part.CanCollide)
									else part.Transparency == 1 and not part.CanCollide
								if not ok then
									wrongStage = `stage {at}'s {part.Name} at {part.Transparency}, solid {part.CanCollide}`
								end
							end
						end
					end
					t.Check(`base level {level}: its pieces shown and solid, the others' hidden and open`, wrongStage == nil, wrongStage)
					local shown = standing()
					local turner = if shown then shown:FindFirstChild("Wheel") else nil
					local pinions = 0
					for _, part in (if shown then shown:GetChildren() else {}) do
						local rate = part:GetAttribute("Rate")
						if part:IsA("BasePart") and type(rate) == "number" and rate ~= 1 and turner and turner:IsA("BasePart") then
							pinions += 1
							local before = part.Position
							t.Wait(0.3)
							local a, w = BaseController.TurnedOf(part), BaseController.TurnedOf(turner)
							t.Check(`base level {level}: {part.Name} driven from its wheel at {rate}`, a ~= nil and w ~= nil and math.abs(a - w * rate) < 1e-6, `{a}, {w}`)
							t.Check(`base level {level}: {part.Name} about its own axle`, before:FuzzyEq(part.Position, 1e-3))
						end
					end
					t.Equal(`base level {level}: its pinions`, pinions, want - 1)
				end
				t.Server("BaseLevel", levelWas)
				-- The crown: the server's word on whether a Voidkin trains, and turning only then. Then the client's turning
				-- alone, by its word set here, and the server's put back.
				local trainer = Markers.Find("Training", { Plot = plot })
				local crown = if trainer then trainer:FindFirstChild("Crown") else nil
				t.Check("the crown says whether a Voidkin trains, as the save has it", waitFor(t, ANSWER, function(): boolean
					local on = Players.LocalPlayer:GetAttribute("Training")
					return crown ~= nil and crown:GetAttribute("Training") == (type(on) == "string" and on ~= "")
				end), tostring(crown and crown:GetAttribute("Training")))
				if crown then
					local server = crown:GetAttribute("Training")
					local rate = WorldConfig.Grey.Training.Crown
					for _, on in { true, false } do
						crown:SetAttribute("Training", on)
						local turn = turned(crown, 0.5)
						local want = if on then rate * 2 * math.pi * 0.5 else 0
						t.Check(if on then `while one trains it turns, {rate} turns a second` else "and stands still while none does",
							turn ~= nil and math.abs(turn - want) < (if on then want * 0.25 else 1e-6), if turn then string.format("%.3f of %.3f", turn, want) else "not watched")
					end
					crown:SetAttribute("Training", server)
				end
			end,
		},
		{
			Name = "Base: from the spawn, AR16, no machine's plate covers another's, each kept under the top band",
			Run = function(t: any)
				local old = Players.LocalPlayer.Character
				t.Check("the avatar goes home", t.Server("Respawn") == true and waitFor(t, 8, function(): boolean
					local character = Players.LocalPlayer.Character
					local root = if character and character ~= old then character:FindFirstChild("HumanoidRootPart") else nil
					return root ~= nil
				end))
				t.Wait(1.5) -- the camera settles behind the avatar, and the plates find their machines
				local layer = Layers.Get("World")
				local scale = Layers.Scale()
				local shown: { GuiObject } = {}
				for _, frame in layer:GetChildren() do
					if frame:IsA("GuiObject") and frame.Visible and (PLATES[frame.Name] or string.match(frame.Name, "^Bay%d+$")) then
						table.insert(shown, frame)
					end
				end
				t.Check("at least one machine's plate speaks at the spawn", #shown > 0, tostring(#shown))
				local crossed: { string } = {}
				for i = 1, #shown do
					for j = i + 1, #shown do
						local a, b = shown[i], shown[j]
						local apart = a.AbsolutePosition.X + a.AbsoluteSize.X <= b.AbsolutePosition.X
							or b.AbsolutePosition.X + b.AbsoluteSize.X <= a.AbsolutePosition.X
							or a.AbsolutePosition.Y + a.AbsoluteSize.Y <= b.AbsolutePosition.Y
							or b.AbsolutePosition.Y + b.AbsoluteSize.Y <= a.AbsolutePosition.Y
						if not apart then
							table.insert(crossed, `{a.Name} and {b.Name}`)
						end
					end
				end
				t.Check("none covers another", #crossed == 0, table.concat(crossed, "; "))
				local band = World.Edge()
				local over: { string } = {}
				for _, frame in shown do
					local top = (frame.AbsolutePosition.Y - layer.AbsolutePosition.Y) / scale
					if band and top < band - 0.5 then
						table.insert(over, `{frame.Name} at {math.floor(top)}`)
					end
				end
				t.Check("each under the top band", #over == 0, `{table.concat(over, "; ")} over {tostring(band)}`)
			end,
		},
		{
			Name = "Base: TR24's fix 3, a waiting starter is the break card's crystal, never a lit cube",
			Run = function(t: any)
				local RevealArt = require(Shared.Config.RevealArt)
				local holder = Instance.new("Folder")
				holder.Name = "NL_TestStarter"
				holder.Parent = workspace
				local ok, err = pcall(function()
					local at = t.Root().Position + Vector3.new(0, 40, 0)
					local anchor = BaseController.StarterShard("starter_rook", at, holder)
					t.Check("its anchor unseen, holding its Voidkin", anchor.Transparency == 1 and anchor:GetAttribute("Holds") == "rook", `{anchor.Transparency}, {tostring(anchor:GetAttribute("Holds"))}`)
					t.Check("dressed as soon as the reveal's pieces are in", waitFor(t, 10, function(): boolean
						return anchor:GetAttribute("Dressed") == true
					end))
					local shell, pieces: { MeshPart } = 0, {}
					for _, piece in RevealArt.Shard.Pieces do
						if piece.Order ~= nil then
							shell += 1
						end
					end
					local low, high = math.huge, -math.huge
					for _, child in anchor:GetChildren() do
						if child:IsA("MeshPart") then
							table.insert(pieces, child)
							low = math.min(low, child.Position.Y - child.Size.Y / 2)
							high = math.max(high, child.Position.Y + child.Size.Y / 2)
						end
					end
					t.Check("the reveal's whole shell, no core and no bud", #pieces == shell and anchor:FindFirstChild("Core") == nil and anchor:FindFirstChild("BudFoot") == nil, `{#pieces} of {shell}`)
					t.Check("in the reveal's palette, not neon", #pieces > 0 and pieces[1].Material ~= Enum.Material.Neon and pieces[1].TextureID == RevealArt.Images.reveal_palette.Id)
					local tall = high - low
					t.Check("about the old stand's height, a crystal at hand", tall >= 1.8 and tall <= 3.4, string.format("%.2f studs", tall))
					t.Check("a faint light of its own", anchor:FindFirstChildOfClass("PointLight") ~= nil)
					-- the anchor's turn carries the pieces (they're welded, never left behind)
					local piece = pieces[1]
					local before = if piece then anchor.CFrame:ToObjectSpace(piece.CFrame) else CFrame.new()
					anchor.CFrame = anchor.CFrame * CFrame.Angles(0, 1, 0)
					t.Wait(0.1)
					local after = if piece then anchor.CFrame:ToObjectSpace(piece.CFrame) else CFrame.new()
					t.Check("its pieces turn with it", piece ~= nil and (before.Position - after.Position).Magnitude < 0.01, if piece then string.format("%.3f", (before.Position - after.Position).Magnitude) else "none")
				end)
				holder:Destroy()
				if not ok then
					error(err, 0)
				end
			end,
		},
		{
			Name = "Base: TR24's fix 5, Watt's shard breaks in a starter's time and opens itself once its player is on their plot, never off it",
			Run = function(t: any)
				local shard = "named_watt"
				local grade = ShardConfig.Grades[Shards.ById[shard].Grade]
				t.Check("Watt's shard breaks in a few seconds, a starter's", grade.BreakSeconds <= ShardConfig.Grades.Starter.BreakSeconds, `{grade.BreakSeconds} s`)
				t.Check("it and a starter's open themselves", grade.Opens == true and ShardConfig.Grades.Starter.Opens == true)
				local view = ProfileController.Get()
				local world = workspace:FindFirstChild("World")
				local gateZ = if world then world:GetAttribute("GateZ") else nil
				t.Check("the first shard is chosen", view ~= nil and view.Progress.Starter ~= "")
				t.Check("the world says where its gate stands", type(gateZ) == "number")
				if view == nil or view.Progress.Starter == "" or type(gateZ) ~= "number" then
					return
				end
				BaseController.Dismiss() -- a reveal left up (one that opened itself at the join) holds the next back
				local was = BaseController.SelfOpen(false)
				local ok, err = pcall(function()
					-- off the plot, in the Row: it breaks and waits (turned on there, so nothing left ready opens on the plot)
					local up = Vector3.new(0, 3.6, 0)
					t.Server("TestStandAt", Vector3.new(0, 0, gateZ - 60) + up, Vector3.new(0, 0, gateZ - 70) + up)
					t.Wait(0.5)
					BaseController.SelfOpen(true)
					local held = view.Bag.Shards[shard] or 0
					t.Server("BaseGive", shard, 1)
					t.Check("the server gives one", waitFor(t, ANSWER, function(): boolean
						local now = ProfileController.Get()
						return now ~= nil and (now.Bag.Shards[shard] or 0) == held + 1
					end))
					local before = selfOpeners() -- some may wait already, from earlier runs
					local added = t.Server("Act", "AddShard", { Shard = shard })
					t.Check("it joins the Breaker", type(added) == "table" and added.Ok == true)
					t.Server("BaseSkip", SKIP_ALL)
					t.Check("it breaks", waitFor(t, ANSWER, function(): boolean
						return selfOpeners() == before + 1
					end), `{selfOpeners()} of {before} before`)
					local waiting = selfOpeners()
					t.Wait(1.5)
					t.Check("off the plot it waits for its player", BaseController.Revealed() == nil and selfOpeners() == waiting, `{selfOpeners()} of {waiting}`)
					-- home: it opens itself, with no press
					local old = Players.LocalPlayer.Character
					t.Check("the avatar goes home", t.Server("Respawn") == true and waitFor(t, 8, function(): boolean
						local character = Players.LocalPlayer.Character
						return character ~= nil and character ~= old and character:FindFirstChild("HumanoidRootPart") ~= nil
					end))
					t.Check("on the plot it opens itself, no press", waitFor(t, 3, function(): boolean
						return BaseController.Revealed() ~= nil
					end))
					local shown = BaseController.Revealed()
					-- the oldest that opens itself goes first: Watt's, or a starter's left from an earlier case
					local named: { [string]: boolean } = {}
					for _, row in Shards.List do
						local rowGrade = ShardConfig.Grades[row.Grade]
						if rowGrade and rowGrade.Opens == true and Voidkin.ById[row.Holds] then
							named[Voidkin.ById[row.Holds].Name] = true
						end
					end
					t.Check("its reveal names its Voidkin", shown ~= nil and named[shown.Name] == true, if shown then shown.Name else "nothing")
					t.Check("one fewer waits to be opened", waitFor(t, ANSWER, function(): boolean
						return selfOpeners() == waiting - 1
					end), `{selfOpeners()} of {waiting}`)
				end)
				BaseController.SelfOpen(was)
				BaseController.Dismiss()
				if not ok then
					error(err, 0)
				end
			end,
		},
		{
			Name = "Base: TR24's fix 10, the Festival Door says its name over its arch with its ground under it, and the festival gate says its ground",
			Run = function(t: any)
				local ground = Grounds.ById[WorldConfig.Row.Ground].Name
				local plot = Players.LocalPlayer:GetAttribute("Plot")
				local door = if type(plot) == "number" then Markers.Find("FestivalDoor", { Plot = plot }) else nil
				local gate = Markers.Find("FestivalGate")
				t.Check("the plot's door and the festival gate are in the world", door ~= nil and gate ~= nil)
				local parts: { [string]: Frame } = {}
				t.Check("each wears its sign", waitFor(t, 3, function(): boolean
					parts = SignsController.Parts()
					return parts.Door ~= nil and parts.Gate ~= nil
				end))
				local function says(frame: Frame?, index: number): string
					local panel = frame and frame:FindFirstChild("Panel")
					local label = panel and panel:FindFirstChild(`Line{index}`)
					return if label and label:IsA("TextLabel") then label.Text else ""
				end
				t.Equal("the door: its name", says(parts.Door, 1), WorldConfig.Signs.Door.Name)
				t.Equal("the door: the ground it goes to under it", says(parts.Door, 2), ground)
				t.Equal("the gate: its ground", says(parts.Gate, 1), ground)
				-- over its top: where the plate stands (it moves on render)
				if door and door:IsA("Model") and parts.Door then
					local frame, size = door:GetBoundingBox()
					local want = frame.Position + Vector3.new(0, size.Y / 2 + WorldConfig.Signs.Door.Lift, 0)
					local at = World.Where(parts.Door)
					t.Check("the door's over its arch", at ~= nil and (at - want).Magnitude < 0.1, if at then tostring(at) else "nowhere")
				end
			end,
		},
		{
			Name = "Base: AR15's Festival Door, the ring tunnel: its four rings turn always about the tunnel's axis at their plan's rates, its core lit by whether its ground is open, its way inside the front ring's open opening, its name on the plate",
			Run = function(t: any)
				local plot = Players.LocalPlayer:GetAttribute("Plot")
				local door = if type(plot) == "number" then Markers.Find("FestivalDoor", { Plot = plot }) else nil
				local frame = if door then door:FindFirstChild("Frame") else nil
				if door == nil or frame == nil or not frame:IsA("BasePart") then
					t.Check("the plot's Festival Door, in its kit", false, if door == nil then "no door streamed in" else "a grey door: no Frame")
					return
				end
				local function originOf(part: BasePart): CFrame
					local c = BaseManifest.pieces[part:GetAttribute("Piece") :: string].centre
					return part.CFrame * CFrame.new(-c[1], -c[2], -c[3])
				end
				local origin = originOf(frame)
				-- Full is the frame's own glow, never past the core's most under the bloom applied (Config.Lighting's
				-- CoreBloom): the frame is a kit piece with no state, lit as the day has it (LightingController).
				local frameLook = frame:FindFirstChildOfClass("SurfaceAppearance")
				local most = LightingController.Look().CoreMost
				local look = if frameLook then math.min(frameLook.EmissiveStrength, most) else -1
				local bloom = game:GetService("Lighting"):FindFirstChildOfClass("BloomEffect")
				local under = if bloom then bloom.Threshold * LightingConfig.Glow.CoreBloom else -1
				t.Check("the core: its most under the bloom applied", math.abs(most - under) <= 0.011, `{most}, want {under}`)
				-- The rings: each its plan's spin, turning about its own origin on the tunnel's axis, always.
				local spins: { [string]: number } = {}
				for _, placement in BasePlan.machines.placements do
					if type(placement.spin) == "number" then
						spins[placement.piece] = placement.spin
					end
				end
				local rings: { BasePart } = {}
				for index = 1, 4 do
					local ring = door:FindFirstChild(`Ring {index}`)
					if ring and ring:IsA("BasePart") then
						table.insert(rings, ring)
					end
				end
				t.Equal("four rings behind the front ring", #rings, 4)
				local before: { [BasePart]: { Angle: number?, Origin: CFrame } } = {}
				for _, ring in rings do
					before[ring] = { Angle = BaseController.TurnedOf(ring), Origin = originOf(ring) }
				end
				local from = os.clock()
				task.wait(1)
				local took = os.clock() - from
				for _, ring in rings do
					local kind = ring:GetAttribute("Piece") :: string
					local spin = spins[kind]
					t.Check(`{ring.Name}: its plan's spin`, spin ~= nil and ring:GetAttribute("Moves") == "spins" and ring:GetAttribute("Spin") == spin, `{ring:GetAttribute("Spin")}`)
					t.Check(`{ring.Name}: look only`, not ring.CanCollide, "solid")
					local was, now = before[ring].Angle, BaseController.TurnedOf(ring)
					if spin == nil or was == nil or now == nil then
						t.Check(`{ring.Name}: watched, turning`, false, "not watched")
						continue
					end
					-- The angle runs against the spin (drawn as -angle); one second's turn is under half a turn.
					local turned = (now - was + math.pi) % (2 * math.pi) - math.pi
					local rate = -math.deg(turned) / took
					t.Check(`{ring.Name}: turns at {spin} degrees a second`, math.abs(rate - spin) < math.abs(spin) * 0.1, `{rate}`)
					local axis = originOf(ring)
					t.Check(`{ring.Name}: about its own origin`, axis.Position:FuzzyEq(before[ring].Origin.Position, 1e-3), `{(axis.Position - before[ring].Origin.Position).Magnitude}`)
					t.Check(`{ring.Name}: on the tunnel's axis`, axis.ZVector:Dot(origin.ZVector) > 0.999, `{axis.ZVector:Dot(origin.ZVector)}`)
				end
				-- The core: tinted white, lit full while the ground it goes to is open, low while none is.
				local core = door:FindFirstChild("Core")
				local surface = if core then core:FindFirstChildOfClass("SurfaceAppearance") else nil
				if core == nil or not core:IsA("BasePart") or surface == nil then
					t.Check("the Door's core", false, "none")
				else
					t.Check("the core: tinted white", surface.EmissiveTint == Color3.new(1, 1, 1), surface.EmissiveTint:ToHex())
					t.Check("the core: open, as its ground is laid", core:GetAttribute("Working") == true, `{core:GetAttribute("Working")}`)
					t.Check("the core: full while open", waitFor(t, 1, function(): boolean
						return math.abs(surface.EmissiveStrength - look) < 1e-3
					end), `{surface.EmissiveStrength}, want {look}`)
					core:SetAttribute("Working", false) -- the client's own word, the server's put back below
					t.Check("the core: low while none is", waitFor(t, 1, function(): boolean
						return math.abs(surface.EmissiveStrength - look * LightingConfig.Glow.Empty) < 1e-3
					end), `{surface.EmissiveStrength}, want {look * LightingConfig.Glow.Empty}`)
					core:SetAttribute("Working", true)
				end
				-- The way: in the front ring's opening and through its depth, touching none of the stone.
				local way = door:FindFirstChild("Way")
				local spec = WorldConfig.Grey.Door.Way
				if way == nil or not way:IsA("BasePart") then
					t.Check("the Door's way", false, "none")
				else
					local at = origin:ToObjectSpace(way.CFrame)
					t.Check("the way: in the opening, as Config's", at.Position:FuzzyEq(spec.At, 1e-3) and way.Size:FuzzyEq(spec.Size, 1e-3), `{at.Position} {way.Size}`)
					local corner = Vector2.new(spec.Size.X / 2, spec.Size.Y / 2).Magnitude
					t.Check("the way: inside the stone's collision, within 4.8 of the opening's middle 5.6 up", corner < 4.8 and math.abs(spec.At.Y - 5.6) < 1e-6, `{corner}`)
					t.Check("the way: through the ring's depth, -0.6 to 1.0", spec.At.Z - spec.Size.Z / 2 >= -0.6 - 1e-6 and spec.At.Z + spec.Size.Z / 2 <= 1.0 + 1e-6)
					local only = OverlapParams.new()
					only.FilterType = Enum.RaycastFilterType.Include
					only.FilterDescendantsInstances = { frame }
					local touching = workspace:GetPartsInPart(way, only)
					t.Check("the way: touches none of the stone", #touching == 0 and frame.CanCollide, `{#touching} touching, solid {frame.CanCollide}`)
					-- A player walks through the opening, and bumps the ring round it: a ray from the way in through the
					-- opening's middle meets no stone, one at the ring's side meets it.
					local rays = RaycastParams.new()
					rays.FilterType = Enum.RaycastFilterType.Include
					rays.FilterDescendantsInstances = { frame }
					local back = origin:VectorToWorldSpace(Vector3.new(0, 0, -8))
					local through = workspace:Raycast(origin * Vector3.new(0, 5.6, 4), back, rays)
					local side = workspace:Raycast(origin * Vector3.new(5.7, 5.6, 4), back, rays)
					t.Check("the way: the opening open to walk through", through == nil, if through then `stone at {origin:PointToObjectSpace(through.Position)}` else "open")
					t.Check("the way: the ring round it solid", side ~= nil, if side then "stone" else "open")
				end
				-- The name, on the plate's face toward the way in.
				local host = door:FindFirstChild("Name")
				local gui = if host then host:FindFirstChild("DoorName") else nil
				local words = if gui then gui:FindFirstChild("Words") else nil
				t.Check("the name: on the plate's face", host ~= nil and host:IsA("BasePart") and origin:ToObjectSpace(host.CFrame).Position:FuzzyEq(WorldConfig.Grey.Door.Name.At, 1e-3)
					and gui ~= nil and gui:IsA("SurfaceGui") and gui.Face == Enum.NormalId.Back)
				t.Equal("the name: its words", if words and words:IsA("TextLabel") then words.Text else "", WorldConfig.Signs.Door.Name)
			end,
		},
		{
			Name = "Base: TR24's fix 1, a worker stands at work in its bay's ring playing its rig's Idle, the halo lit in its rarity colour; the bay empty, both gone; the step's chevron over the bay it names",
			Run = function(t: any)
				local view = ProfileController.Get()
				local plot = Players.LocalPlayer:GetAttribute("Plot")
				if view == nil or type(plot) ~= "number" or #view.Base.Bays == 0 then
					t.Check("a plot, a save and an open bay", false)
					return
				end
				-- The chevron: a "Bay" step's marker is the bay it names, on this plot, for each bay the base can open.
				for index = 1, BaseLevels.Bays(BaseLevels.Top()) do
					local found = HudController.StepTargets({ Line = "", Target = "Bay", Bay = index })
					local bay = found[1]
					t.Check(`the step for bay {index}: its chevron over bay {index}`, #found == 1 and bay:GetAttribute("Bay") == index and bay:GetAttribute("Plot") == plot,
						if bay then `bay {tostring(bay:GetAttribute("Bay"))} of plot {tostring(bay:GetAttribute("Plot"))}` else "none")
				end
				-- Bay 1 with a worker: one the save owns, its own worker if it has one, else any that neither leads nor trains.
				local before = view.Base.Bays[1].Worker
				local worker = before
				if worker == "" then
					local busy: { [string]: boolean } = { [view.Roles.Lead] = true, [view.Training.Trainee] = true }
					for _, seat in view.Base.Bays do
						busy[seat.Worker] = true
					end
					local ids: { string } = {}
					for id in view.Voidkin do
						if not busy[id] then
							table.insert(ids, id)
						end
					end
					table.sort(ids)
					worker = ids[1] or ""
				end
				if worker == "" then
					t.Check("a Voidkin free to work bay 1", false, "every Voidkin leads, works or trains")
					return
				end
				local bay = Markers.Find("Bay", { Plot = plot, Bay = 1 })
				if bay == nil then
					t.Check("bay 1 on the plot", false)
					return
				end
				pcall(function()
					Players.LocalPlayer:RequestStreamAroundAsync(Markers.At(bay).Position, 2)
				end)
				local function body(): Model?
					local found = bay:FindFirstChild("Worker")
					return if found and found:IsA("Model") then found else nil
				end
				if before == "" then
					t.Check("bay 1 takes a worker", ProfileController.Act("SetWorker", { Bay = 1, Voidkin = worker }).Ok == true)
				end
				local def = view.Voidkin[worker].Def
				local rig = AnimationsConfig.Rigs[Voidkin.ById[def].Rig or "R6"]
				t.Check("its body stands in the bay, playing its rig's Idle", waitFor(t, ANSWER + 3, function(): boolean
					local made = body()
					return made ~= nil and made:GetAttribute("Playing") == rig.Idle
				end), if body() then `playing {tostring((body() :: Model):GetAttribute("Playing"))}` else "no body")
				local made = body()
				if made then
					t.Equal("the body is the worker's", made:GetAttribute("Voidkin"), worker)
					local at, want = made:GetPivot().Position, Markers.At(bay).Position + Vector3.new(0, WorldConfig.Bay.Hip, 0)
					t.Check("it stands in the ring, Hip studs over the bay's floor", (at - want).Magnitude < 0.05, tostring(at))
					t.Check("facing the bay's front", made:GetPivot().LookVector:Dot(Markers.At(bay).LookVector) > 0.99)
					local root = made:FindFirstChild("HumanoidRootPart")
					t.Check("held where it stands, through nobody's way", root ~= nil and root:IsA("BasePart") and root.Anchored and not root.CanCollide)
				end
				local halo = bay:FindFirstChild("Halo")
				local light = halo and halo:FindFirstChild("Light")
				local colour = RevealConfig.Plate.Words[Voidkin.ById[def].Rarity]
				t.Check("the halo lit in its rarity colour, in Neon", halo ~= nil and halo:IsA("BasePart") and halo.Transparency == 0 and halo.Material == Enum.Material.Neon and halo.Color == colour)
				t.Check("with one light of that colour", light ~= nil and light:IsA("PointLight") and light.Enabled and light.Color == colour)
				-- Bay 1 empty: both go.
				t.Check("the worker steps out", ProfileController.Act("SetWorker", { Bay = 1, Voidkin = "" }).Ok == true)
				t.Check("its body leaves the bay", waitFor(t, ANSWER, function(): boolean
					return body() == nil
				end))
				t.Check("the halo dark, its light out", waitFor(t, ANSWER, function(): boolean
					return halo ~= nil and halo:IsA("BasePart") and halo.Transparency == 1 and light ~= nil and light:IsA("PointLight") and not light.Enabled
				end))
				if before ~= "" then
					t.Check("the worker goes back", ProfileController.Act("SetWorker", { Bay = 1, Voidkin = before }).Ok == true)
				end
			end,
		},
	}
end

return BaseCases
