--!strict
-- BaseCases (client, Studio only): the base's cases on its plot, a list of their own beside Cases, which joins it as it
-- joins PowerCases (Cases' one table had passed what the type solver checks in one piece). AR16's base as its save has
-- it: the bays awake and asleep, the Void Mill's wheel, gauge and demand mark (AR19) and the
-- Training machine's crown; its machines' plates apart from the spawn; and the first session's shards opening themselves
-- on the plot (TR24's fix 5); the Festival Door's and the gate's names (TR24's fix 10); a bay's worker at work in its ring,
-- its halo lit in its rarity colour, and the step's chevron over the bay it names (TR24's fix 1).

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local BaseConfig = require(Shared.Config.Base)
local PlaceRole = require(Shared.Util.PlaceRole)
local BaseLevels = require(Shared.Rules.BaseLevels)
local Breaker = require(Shared.Rules.Breaker)
local ShardConfig = require(Shared.Config.Shards)
local Shards = require(Shared.Definitions.Shards)
local Voidkin = require(Shared.Definitions.Voidkin)
local Power = require(Shared.Rules.Power)
local LightingConfig = require(Shared.Config.Lighting)
local WorldConfig = require(Shared.Config.World)
local Markers = require(Shared.World.Markers)
local Kit = require(Shared.World.Kit)
local Profile = require(Shared.Data.Profile)
local Collection = require(Shared.Rules.Collection)
local Stats = require(Shared.Rules.Stats)
local Sheet = require(Shared.Rules.Sheet)
local Hud = require(Shared.Rules.Hud)
local Condenser = require(Shared.Rules.Condenser)
local CondenserConfig = require(Shared.Config.Condenser)
local HudConfig = require(Shared.Config.Hud)
local UIKit = require(Shared.Config.UIKit)
local ReinforceRules = require(Shared.Rules.Reinforce)
local ReinforceConfig = require(Shared.Config.Reinforce)
local PowerConfig = require(Shared.Config.Base).Power
local Forge = require(Shared.Rules.Forge)
local BaseManifest: any = require(Shared.Config.Kits.Base.Manifest)
local BasePlan: any = require(Shared.Config.Kits.Base.Plan)
local BaseController = require(script.Parent.Parent.Parent.Main.BaseController)
local LandingController = require(script.Parent.Parent.Parent.Main.LandingController)
local LandingConfig = require(Shared.Config.Landing)
local LightingController = require(script.Parent.Parent.Parent.Main.LightingController)
local SignsController = require(script.Parent.Parent.Parent.Main.SignsController)
local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local ShopController = require(script.Parent.Parent.Parent.Main.ShopController)
local AnimationsConfig = require(Shared.Config.Animations)
local RevealConfig = require(Shared.Config.Reveal)
local Grounds = require(Shared.Definitions.Grounds)
local ProfileController = require(script.Parent.Parent.ProfileController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Layers = require(UI.Layers)
local Theme = require(UI.Theme)
local Screen = require(UI.Kit.Screen)
local EquipmentScreen = require(UI.EquipmentScreen)
local ReturnCard = require(UI.ReturnCard)
local Read = require(UI.Read)
local Button = require(UI.Kit.Button)
local World = require(UI.World)
local Helpers = require(script.Parent.Helpers)

-- The base's machine plates by name, beside "Bay1" to "Bay6" (BaseController.Parts).
local PLATES = { Breaker = true, Training = true, Generator = true }

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
	local baysBefore: { string }? = nil -- the runner's own case, below: the bays as its first half found them
	return {
		{
			Name = "Base: AR65's cut pass: nothing the world cuts stands, no Lab's place, no battery (folded into the Mill) and no Forge, and the plot glows at the base's: its floors dark, its pieces at Base",
			Place = "Main", -- TR45: its world stands in that place only
			Run = function(t: any)
				local world = workspace:FindFirstChild("World")
				local standing: { string } = {}
				for _, item in (if world then world:GetDescendants() else {}) do
					local piece = item:GetAttribute("Piece")
					if type(piece) == "string" and WorldConfig.Cut[piece] then
						table.insert(standing, piece)
					elseif WorldConfig.Cut[item.Name] and item:FindFirstChildWhichIsA("Light") then
						table.insert(standing, item.Name)
					end
				end
				t.Check("nothing cut stands where the client sees", world ~= nil and #standing == 0, table.concat(standing, ", "))
				local report = t.Server("WorldReport")
				local cutLaid: { string } = {}
				for _, problem in (if type(report) == "table" then report else {}) do
					if string.find(tostring(problem), "cut", 1, true) then
						table.insert(cutLaid, tostring(problem))
					end
				end
				t.Check("nor on the server: the world report names nothing cut laid", type(report) == "table" and #cutLaid == 0, table.concat(cutLaid, "; "))
				local plot = Players.LocalPlayer:GetAttribute("Plot")
				local plots = if world then world:FindFirstChild("Plots") else nil
				local lot = if plots and type(plot) == "number" then plots:FindFirstChild(`Plot {plot}`) else nil
				local base = if lot then lot:FindFirstChild("Base") else nil
				local dressing = if base then base:FindFirstChild("Dressing") else nil
				if dressing == nil then
					t.Check("a plot dressed", false, "no base streamed in")
					return
				end
				t.Check("no Lab's sleeping place", (base :: Instance):FindFirstChild("Sleeping") == nil)
				t.Check("no battery, nor its plate: folded into the Mill", Markers.Find("Battery", { Plot = plot }) == nil and BaseController.Parts().BatteryPlate == nil)
				t.Check("no Forge, nor its prompt", not WorldConfig.Cut.Forge or (Markers.Find("Forge", { Plot = plot }) == nil and BaseController.Parts().ForgePrompt == nil))
				local floorLook, wallLook = nil, nil
				for _, item in dressing:GetChildren() do
					local piece = item:GetAttribute("Piece")
					if type(piece) == "string" and Kit.Floors[piece] and floorLook == nil then
						floorLook = item:FindFirstChildOfClass("SurfaceAppearance")
					elseif piece == "Wall" and wallLook == nil then
						wallLook = item:FindFirstChildOfClass("SurfaceAppearance")
					end
				end
				local share = LightingController.Look().Glow -- the phase's share (TR23)
				t.Near("its floor at the base's floor glow", if floorLook then floorLook.EmissiveStrength else -1, LightingConfig.Glow.BaseFloor * share, 1e-3)
				t.Near("its wall at the base's glow", if wallLook then wallLook.EmissiveStrength else -1, LightingConfig.Glow.Base * share, 1e-3)
			end,
		},
		{
			Name = "Base: AR16's base as its save has it: the bays it opened awake and the rest asleep, the mill's wheel, gauge and demand mark (AR19), the crown while a Voidkin trains",
			Place = "Main", -- TR45: its world stands in that place only
			Run = function(t: any)
				local view = ProfileController.Get()
				local plot = Players.LocalPlayer:GetAttribute("Plot")
				-- The battery is folded into the Mill (AR65): the Mill's stage says the base stands as its kit.
				local function millOf(): Instance?
					local found = if type(plot) == "number" then Markers.Find("Generator", { Plot = plot }) else nil
					return if found then BaseController.StageOf(found) else nil -- its stage's (TR51)
				end
				-- Read at home: a case before may leave the avatar at the crossing, where the base streams out.
				if type(plot) == "number" and millOf() == nil then
					t.Server("Respawn")
					waitFor(t, 8, function(): boolean
						return millOf() ~= nil
					end)
				end
				if view == nil or type(plot) ~= "number" or millOf() == nil then
					t.Check("a plot, a save, and the base as its kit", false, if view == nil then "no save yet" elseif type(plot) ~= "number" then "no plot yet" else "no Mill streamed in, or a grey one")
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
					-- Its pad: its stage's (TR51), or the grey one's.
					local function padOf(): Instance?
						return (BaseController.StageOf(bay) or bay):FindFirstChild("Pad")
					end
					waitFor(t, ANSWER, function(): boolean
						return padOf() ~= nil and (awake or bay:FindFirstChild("Sleeping") ~= nil)
					end)
					local pad, sleeping = padOf(), bay:FindFirstChild("Sleeping")
					local function shows(part: Instance?, want: boolean): boolean
						return part ~= nil and part:IsA("BasePart") and (part.Transparency == 0) == want
							and part.CanCollide == (want and part:GetAttribute("Solid") == true)
					end
					t.Check(`bay {index}: {if awake then "awake" else "asleep"}`, shows(pad, awake) and ((sleeping == nil and awake) or shows(sleeping, not awake)),
						`pad {if pad and pad:IsA("BasePart") then pad.Transparency else "none"}, asleep {if sleeping and sleeping:IsA("BasePart") then sleeping.Transparency else "none"}`)
				end
				t.Equal("every bay on the plot, the two no level at launch opens among them (D5)", seen, BaseLevels.Plot())
				-- The Void Mill (AR19), at the stage it stands at: its wheel carries the plant's generation and turns by it,
				-- its gauge's first steps shown as the generation lights them and the rest hidden, and the demand's mark
				-- turned about the axle to the demand's share at its stage's degrees, on one scale (Rules.Power.Gauge).
				local plant = Markers.Find("Generator", { Plot = plot })
				local function standing(): Instance?
					return if plant then BaseController.StageOf(plant) else nil
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
						return plant ~= nil and plant:GetAttribute("Stage") == want and plant:GetAttribute("Swapping") ~= true -- a rise's swap waits under its landing (AR37)
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
				local crown = if trainer then (BaseController.StageOf(trainer) or trainer):FindFirstChild("Crown") else nil -- its stage's (TR51)
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
			Name = "Base: each machine at its stage (TR51; AR32 to AR35): the Breaker and a bay at their own level, the Training machine at the base's, one stage standing and the others hidden, the Breaker's lids where it hasn't a chamber yet and its lamp on its stage's crystal, the turners by their work, a rise that lands and a fall or a respawn that doesn't",
			Place = "Main", -- TR45: its world stands in that place only
			Run = function(t: any)
				local view = ProfileController.Get()
				local plot = Players.LocalPlayer:GetAttribute("Plot")
				local function find(kind: string, bay: number?): Instance?
					if type(plot) ~= "number" then
						return nil
					end
					return Markers.Find(kind, if bay then { Plot = plot, Bay = bay } else { Plot = plot })
				end
				local function staged(): boolean
					local breaker = find("Breaker")
					return breaker ~= nil and breaker:FindFirstChild("Stage 1") ~= nil
				end
				-- Read at home: a case before may leave the avatar at the crossing, where the base streams out.
				if type(plot) == "number" and not staged() then
					t.Server("Respawn")
					waitFor(t, 8, staged)
				end
				if view == nil or type(plot) ~= "number" or not staged() then
					t.Check("a plot, a save, and the Breaker in its stages", false, if view == nil then "no save yet" elseif type(plot) ~= "number" then "no plot yet" else "no stages: a grey base, or the kit lacks them")
					return
				end
				-- `holder` at stage `want`: that stage's pieces standing, the others hidden with their solids open, and
				-- none while it's asleep.
				local function wrong(holder: Instance?, want: number, awake: boolean?): string?
					if holder == nil then
						return "not streamed in"
					elseif holder:GetAttribute("Stage") ~= want then
						return `at stage {tostring(holder:GetAttribute("Stage"))}, not {want}`
					elseif holder:GetAttribute("Swapping") == true then
						return "its swap waits under its landing" -- AR37: the old stage stands until the swap
					end
					for _, group in holder:GetChildren() do
						local at = group:GetAttribute("Stage")
						if not group:IsA("Model") or type(at) ~= "number" then
							continue
						end
						local on = awake ~= false and at == want
						for _, part in group:GetChildren() do
							if part:IsA("BasePart") and ((part.Transparency == 0) ~= on or (not on and part.CanCollide)) then
								return `stage {at}: {part.Name} {if part.Transparency == 0 then "shown" else "hidden"}`
							end
						end
					end
					return nil
				end
				local function stands(label: string, holder: Instance?, want: number, awake: boolean?)
					t.Check(label, waitFor(t, ANSWER, function(): boolean
						return wrong(holder, want, awake) == nil
					end), wrong(holder, want, awake))
				end
				local function rises(holder: Instance?): number
					local count = if holder then holder:GetAttribute("Rose") else nil
					return if type(count) == "number" then count else 0
				end
				local breaker = find("Breaker")
				local base = (view :: any).Base
				local breakerWas = base.Machines.Breaker or 1
				local bayWas = base.Bays[1].Level
				local levelWas = base.Level
				-- The Breaker by its own level, at each stage's edges (Config.Base.Machines.Stages: 1, 6, 15), its chambers
				-- as many as the save holds, a lid on each place its stage has and the save hasn't, its lamp on the crystal.
				local had = #base.Chambers
				for _, level in { 1, 5, 6, 14, 15 } do
					t.Server("MachineLevel", "Breaker", level)
					local want = BaseLevels.Stage(level)
					stands(`the Breaker at level {level}: stage {want}`, breaker, want)
					local chambers: string? = nil
					for index = 1, 4 do
						local chamber, lid = (breaker :: Instance):FindFirstChild(`Chamber {index}`), (breaker :: Instance):FindFirstChild(`Lid {index}`)
						local from = if chamber then chamber:GetAttribute("From") else nil
						local there = chamber ~= nil and (type(from) ~= "number" or from <= want)
						local shown = chamber ~= nil and chamber:IsA("BasePart") and chamber.Transparency == 0
						local covered = lid ~= nil and lid:IsA("BasePart") and lid.Transparency == 0
						if shown ~= (there and index <= had) or (lid ~= nil and covered ~= (there and index > had)) then
							chambers = `chamber {index}: {if shown then "shown" else "hidden"}, its lid {if covered then "shown" elseif lid then "hidden" else "none"}`
							break
						end
					end
					t.Check(`the Breaker at level {level}: its {had} chambers, a lid where it has none yet`, chambers == nil, chambers)
					local group = (breaker :: Instance):FindFirstChild(`Stage {want}`)
					local dressing = ((breaker :: Instance).Parent :: Instance):FindFirstChild("Dressing")
					local lamp = if dressing then dressing:FindFirstChild("BreakerLamp") else nil
					local lampAt = if group then group:GetAttribute("Lamp") else nil
					if lamp and lamp:IsA("BasePart") and typeof(lampAt) == "CFrame" then
						t.Check(`the Breaker at level {level}: its lamp on stage {want}'s crystal`, lamp.CFrame.Position:FuzzyEq(lampAt.Position, 0.05), `{lamp.Position} vs {lampAt.Position}`)
					end
				end
				-- A rise lands, once (AR37); a fall doesn't, nor a respawn on the same plot, nor the same stage again.
				local before = rises(breaker)
				t.Server("MachineLevel", "Breaker", 5)
				t.Server("MachineLevel", "Breaker", 6)
				t.Check("Breaker 5 to 6: the rise lands once", waitFor(t, ANSWER, function(): boolean
					return rises(breaker) == before + 1
				end), `{rises(breaker) - before} landings`)
				-- Raised again and lowered while the swap waits: no landing of their own, the newest stage at the swap.
				t.Server("MachineLevel", "Breaker", 7)
				t.Server("MachineLevel", "Breaker", 5)
				stands("Breaker 6 to 7 and 7 to 5 while its swap waits: stage I at the swap", breaker, 1)
				t.Equal("Breaker 6 to 7 (the same stage) and 7 to 5 (a fall): no landing", rises(breaker) - before, 1)
				t.Check("the old stage stood until the swap: the landing's stage it rose from", (breaker :: Instance):GetAttribute("RoseFrom") == 1, tostring((breaker :: Instance):GetAttribute("RoseFrom")))
				t.Server("MachineLevel", "Breaker", 6)
				waitFor(t, ANSWER, function(): boolean
					return rises(breaker) == before + 2
				end)
				local old = Players.LocalPlayer.Character
				t.Server("Respawn")
				waitFor(t, 8, function(): boolean
					return Players.LocalPlayer.Character ~= old
				end)
				t.Wait(0.5)
				t.Equal("a respawn on stage II: no landing", rises(breaker) - before, 2)
				t.Server("MachineLevel", "Breaker", breakerWas)
				-- Its hinges turn while a chamber breaks and stand while none does (the server's word).
				local breaking = false
				for _, held in base.Chambers do
					breaking = breaking or held.Work ~= nil
				end
				local hinges = 0
				for _, part in (breaker :: Instance):GetDescendants() do
					if part:GetAttribute("Spinning") ~= nil then
						hinges += 1
						t.Check(`{part.Parent and part.Parent.Name} {part.Name}: turning only while a chamber breaks`, part:GetAttribute("Spinning") == breaking, tostring(part:GetAttribute("Spinning")))
						break
					end
				end
				t.Check("the Breaker's jaws turn on their hinges", hinges > 0)
				-- A bay by its own level, its rings turning only while a worker works there; a bay asleep shows no stage.
				local bay = find("Bay", 1)
				for _, level in { 1, 5, 6, 14, 15 } do
					t.Server("MachineLevel", "Bay", level, 1)
					stands(`bay 1 at level {level}: stage {BaseLevels.Stage(level)}`, bay, BaseLevels.Stage(level))
				end
				t.Server("MachineLevel", "Bay", bayWas, 1)
				local worked = base.Bays[1].Worker ~= ""
				for _, part in (if bay then bay:GetDescendants() else {}) do
					if part:GetAttribute("Spinning") ~= nil then
						t.Check(`bay 1's {part.Name}: turning only while a worker works there`, waitFor(t, ANSWER, function(): boolean
							return part:GetAttribute("Spinning") == worked
						end), tostring(part:GetAttribute("Spinning")))
					end
				end
				local asleep = #base.Bays + 1
				if asleep <= BaseLevels.Plot() then
					stands(`bay {asleep}, asleep: no stage of it stands`, find("Bay", asleep), 1, false)
				end
				-- The Training machine by the base's level, as the mill (AR19). The battery is folded into the Mill (AR65).
				local trainer = find("Training")
				for level = 1, BaseLevels.Top() do
					t.Server("BaseLevel", level)
					local want = BaseLevels.GeneratorStage(level)
					stands(`base level {level}: the Training machine at stage {want}`, trainer, want)
				end
				t.Server("BaseLevel", levelWas)
			end,
		},
		{
			Name = "Base: a stage lands (TR51, AR37): a rise on its owner's plot plays the climbing ring round the machine, its cover the machine's own shape, occluded, full as the old stage gives way to the new, everything gone by its last frame; a base level-up's machines start on one frame, and a plot's next landing waits the flash guard's gap",
			Place = "Main", -- TR45: its world stands in that place only
			Run = function(t: any)
				local view = ProfileController.Get()
				local plot = Players.LocalPlayer:GetAttribute("Plot")
				local function find(kind: string): Instance?
					return if type(plot) == "number" then Markers.Find(kind, { Plot = plot }) else nil
				end
				local function staged(): boolean
					local breaker = find("Breaker")
					return breaker ~= nil and breaker:FindFirstChild("Stage 1") ~= nil
				end
				if type(plot) == "number" and not staged() then
					t.Server("Respawn")
					waitFor(t, 8, staged)
				end
				local breaker = find("Breaker")
				if view == nil or breaker == nil or not staged() then
					t.Check("a plot, a save, and the Breaker in its stages", false, if view == nil then "no save yet" else "no stages: a grey base, or the kit lacks them")
					return
				end
				local base = (view :: any).Base
				local breakerWas, levelWas = base.Machines.Breaker or 1, base.Level
				local function settled(holders: { Instance? }): boolean
					for _, holder in holders do
						if holder == nil or holder:GetAttribute("Swapping") == true then
							return false
						end
					end
					return #LandingController.Playing() == 0
				end
				local function shows(holder: Instance, stage: number): boolean
					local group = holder:FindFirstChild(`Stage {stage}`)
					local body = if group then group:FindFirstChildWhichIsA("BasePart") else nil
					return body ~= nil and (body :: BasePart).Transparency == 0
				end
				local function landingOf(holder: Instance): any
					for _, each in LandingController.Playing() do
						if each.Holder == holder then
							return each
						end
					end
					return nil
				end
				-- The Breaker from 5 to 6, stage I to II, each render frame read: the old stage standing before the swap and
				-- the new after, the swap under the full cover.
				t.Server("MachineLevel", "Breaker", 5)
				t.Check("the Breaker settles at stage I", waitFor(t, ANSWER, function(): boolean
					return settled({ breaker }) and breaker:GetAttribute("Stage") == 1 and shows(breaker, 1)
				end))
				t.Wait(LandingConfig.Gap)
				local played = LandingController.Played()
				local rows: { { Frame: number, Fill: number, Old: boolean, New: boolean } } = {}
				local reading = RunService.RenderStepped:Connect(function()
					local each = landingOf(breaker)
					if each then
						table.insert(rows, { Frame = each.Frame, Fill = 1 - each.Cover.FillTransparency, Old = shows(breaker, 1), New = shows(breaker, 2) })
					end
				end)
				t.Server("MachineLevel", "Breaker", 6)
				local each: any = nil
				t.Check("a landing plays on the Breaker", waitFor(t, ANSWER, function(): boolean
					each = landingOf(breaker)
					return each ~= nil
				end), `{LandingController.Played() - played} started`)
				if each then
					t.Check("its cover is the Breaker's own shape, never seen through a wall", each.Cover.Adornee == breaker and each.Cover.DepthMode == Enum.HighlightDepthMode.Occluded)
					t.Check("sized round the machine", each.R > 1 and each.H > 1, `r {each.R}, h {each.H}`)
				end
				waitFor(t, 3, function(): boolean
					return landingOf(breaker) == nil
				end)
				reading:Disconnect()
				local swapAt: number? = nil
				local fillAt, oldLate, newEarly = 0, false, false
				for _, row in rows do
					if row.New and swapAt == nil then
						swapAt, fillAt = row.Frame, row.Fill
					end
					oldLate = oldLate or (row.Frame >= LandingConfig.Swap + 5 and row.Old)
					newEarly = newEarly or (row.Frame < LandingConfig.Swap - 5 and row.New)
				end
				t.Check(`{#rows} frames read: the old stage stands until the swap, the new from it`, #rows > 20 and not oldLate and not newEarly and swapAt ~= nil,
					`swap at frame {tostring(swapAt)}`)
				t.Check("the swap under the full cover, never seen", swapAt ~= nil and fillAt >= 0.8, string.format("fill %.2f at frame %s", fillAt, tostring(swapAt)))
				local left = workspace:FindFirstChild("NL_Landings")
				t.Check("everything gone by its last frame, its cover with it", left == nil or #left:GetChildren() == 0, if left then `{#left:GetChildren()} left` else "")
				-- A respawn on the plot plays none.
				played = LandingController.Played()
				local old = Players.LocalPlayer.Character
				t.Server("Respawn")
				waitFor(t, 8, function(): boolean
					return Players.LocalPlayer.Character ~= old
				end)
				t.Wait(1)
				t.Equal("a respawn: no landing", LandingController.Played() - played, 0)
				-- A base level-up, 1 to 2: the mill and the Training machine start on one frame (the battery is folded into the
				-- Mill, AR65); the Breaker raised just after waits the gap for its own swap (the flash guard: at most 3 flashes
				-- in any second).
				local plant, trainer = find("Generator"), find("Training")
				t.Server("MachineLevel", "Breaker", 5)
				t.Server("BaseLevel", 1)
				waitFor(t, ANSWER, function(): boolean
					return settled({ breaker, plant, trainer })
				end)
				t.Wait(LandingConfig.Gap)
				local started: { [Instance]: number } = {}
				local clocks: { [Instance]: number } = {}
				local noting = RunService.RenderStepped:Connect(function()
					for _, playing in LandingController.Playing() do
						if started[playing.Holder] == nil then
							started[playing.Holder], clocks[playing.Holder] = playing.Started, os.clock()
						end
					end
				end)
				t.Server("BaseLevel", 2)
				t.Server("MachineLevel", "Breaker", 6)
				waitFor(t, ANSWER, function(): boolean
					return started[breaker] ~= nil and settled({ breaker, plant, trainer })
				end)
				noting:Disconnect()
				local together = plant ~= nil and trainer ~= nil and started[plant :: Instance] ~= nil
					and started[plant :: Instance] == started[trainer :: Instance]
				t.Check("the base level-up's two machines start on one frame", together,
					`{tostring(plant and started[plant])}, {tostring(trainer and started[trainer])}`)
				local apart = if plant and clocks[plant] and clocks[breaker] then clocks[breaker] - clocks[plant] else nil
				t.Check(`the Breaker's landing waits the gap, {LandingConfig.Gap} s`, apart ~= nil and apart >= LandingConfig.Gap - 1 / 30,
					if apart then string.format("%.3f s after", apart) else "not seen")
				t.Server("MachineLevel", "Breaker", breakerWas)
				t.Server("BaseLevel", levelWas)
			end,
		},
		{
			Name = "Base: from the spawn, AR16, no machine's plate speaks (each only near its machine); at the Breaker its plate speaks, covering none, under the top band",
			Place = "Main", -- TR45: its world stands in that place only
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
				local function shown(): { GuiObject }
					local list: { GuiObject } = {}
					for _, frame in layer:GetChildren() do
						if frame:IsA("GuiObject") and frame.Visible and (PLATES[frame.Name] or string.match(frame.Name, "^Bay%d+$")) then
							table.insert(list, frame)
						end
					end
					return list
				end
				-- Research's must-fix of 2026-11-17 (12:19): a plate speaks only near its machine, and the spawn stands about
				-- 30 studs from the nearest at 128 (AR16, delivery 3).
				local names: { string } = {}
				for _, frame in shown() do
					table.insert(names, frame.Name)
				end
				t.Check("none speaks at the spawn", #names == 0, table.concat(names, ", "))
				-- At the Breaker: the avatar 7 studs short of its prompt's spot, facing it, the camera behind.
				local prompt = BaseController.Parts().BreakerPrompt
				local anchor = if prompt then prompt.Parent else nil
				local root = t.Root()
				t.Check("the Breaker's prompt to stand by", anchor ~= nil and anchor:IsA("BasePart") and root ~= nil)
				if anchor == nil or not anchor:IsA("BasePart") or root == nil then
					return
				end
				local away = Vector3.new(root.Position.X - anchor.Position.X, 0, root.Position.Z - anchor.Position.Z)
				local dir = if away.Magnitude > 1e-3 then away.Unit else Vector3.new(0, 0, 1)
				local target = Vector3.new(anchor.Position.X, root.Position.Y, anchor.Position.Z)
				t.Server("TestStandAt", target + dir * 7, target)
				local list: { GuiObject } = {}
				t.Check("the Breaker's plate speaks there", waitFor(t, 3, function(): boolean
					list = shown()
					for _, frame in list do
						if frame.Name == "Breaker" then
							return true
						end
					end
					return false
				end), tostring(#list))
				t.Wait(0.5) -- the camera settles behind the avatar
				list = shown()
				local crossed: { string } = {}
				for i = 1, #list do
					for j = i + 1, #list do
						local a, b = list[i], list[j]
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
				for _, frame in list do
					local top = (frame.AbsolutePosition.Y - layer.AbsolutePosition.Y) / scale
					if band and top < band - 0.5 then
						table.insert(over, `{frame.Name} at {math.floor(top)}`)
					end
				end
				t.Check("each under the top band", #over == 0, `{table.concat(over, "; ")} over {tostring(band)}`)
				t.Server("Respawn")
				t.Wait(1)
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
			Place = "Main", -- TR45: its world stands in that place only
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
					-- off the plot, on the Strip's crossing: it breaks and waits (turned on there, so nothing left ready opens
					-- on the plot; TR45: the street is the Festival's place)
					local up = Vector3.new(0, 3.6, 0)
					t.Server("TestStandAt", up, Vector3.new(10, 0, 0) + up)
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
			Name = "Base: TR24's fix 10, the Festival Door says its name with its ground under it, and the festival gate says its ground, each sign beside its landmark and never over it, the Door's away while its own plate reads",
			Run = function(t: any)
				local ground = Grounds.ById[WorldConfig.Row.Ground].Name
				local plot = Players.LocalPlayer:GetAttribute("Plot")
				local door = if type(plot) == "number" then Markers.Find("FestivalDoor", { Plot = plot }) else nil
				local gate = Markers.Find("FestivalGate")
				-- Each place has its own (TR45): the plot's door in the base's, the festival gate in the Festival's.
				local festival = PlaceRole.Is("Festival")
				t.Check("this place's landmark is in the world", if festival then gate ~= nil else door ~= nil)
				local parts: { [string]: Frame } = {}
				t.Check("it wears its sign", waitFor(t, 3, function(): boolean
					parts = SignsController.Parts()
					return if festival then parts.Gate ~= nil else parts.Door ~= nil
				end))
				local function says(frame: Frame?, index: number): string
					local panel = frame and frame:FindFirstChild("Panel")
					local label = panel and panel:FindFirstChild(`Line{index}`)
					return if label and label:IsA("TextLabel") then label.Text else ""
				end
				if festival then
					t.Equal("the gate: its ground", says(parts.Gate, 1), ground)
				else
					t.Equal("the door: its name", says(parts.Door, 1), WorldConfig.Signs.Door.Name)
					t.Equal("the door: the ground it goes to under it", says(parts.Door, 2), ground)
				end
				-- Beside each landmark, never over it, and the Door's away while its own plate reads (research's must-fix on
				-- AR15, 2026-11-17). Seen as the game's camera sees a stand: 12 studs behind the avatar and 4.7 up, looking at
				-- its head, the avatar facing the landmark (measured in AR15). It moves on render.
				local camera = workspace.CurrentCamera
				local function look(marker: Instance, stand: Vector3)
					local middle = if marker:IsA("Model") then marker:GetBoundingBox().Position else (marker :: BasePart).Position
					local flat = Vector3.new(stand.X - middle.X, 0, stand.Z - middle.Z).Unit
					camera.CameraType = Enum.CameraType.Scriptable
					camera.CFrame = CFrame.lookAt(stand + flat * 12.07 + Vector3.new(0, 4.74, 0), stand + Vector3.new(0, 1.5, 0))
					for _ = 1, 3 do
						RunService.RenderStepped:Wait()
					end
				end
				local function covered(frame: Frame, marker: Instance): number?
					local low, high = SignsController.Box(marker)
					if not frame.Visible or low == nil or high == nil then
						return nil
					end
					local screen = frame:FindFirstAncestorOfClass("ScreenGui")
					local inset = if screen and not screen.IgnoreGuiInset then GuiService:GetGuiInset() else Vector2.zero
					local a, b = frame.AbsolutePosition + inset, frame.AbsolutePosition + frame.AbsoluteSize + inset
					local wide = math.max(0, math.min(b.X, high.X) - math.max(a.X, low.X))
					local tall = math.max(0, math.min(b.Y, high.Y) - math.max(a.Y, low.Y))
					return wide * tall / (frame.AbsoluteSize.X * frame.AbsoluteSize.Y)
				end
				local frameOf = if door then door:FindFirstChild("Frame") else nil
				local doorSign: Frame? = parts.Door
				if door and frameOf and frameOf:IsA("BasePart") and doorSign then
					local c = BaseManifest.pieces[frameOf:GetAttribute("Piece") :: string].centre
					local origin = frameOf.CFrame * CFrame.new(-c[1], -c[2], -c[3])
					look(door, origin * Vector3.new(0, 3.5, 18))
					t.Check("the door: its sign away while its own plate reads, at the way in", SignsController.Aside(door) and not doorSign.Visible, `{SignsController.Aside(door)}, shown {doorSign.Visible}`)
					local stands: { { Name: string, At: Vector3 } } = {
						{ Name = "40 out", At = Vector3.new(0, 3.5, 40) },
						{ Name = "18 behind", At = Vector3.new(0, 3.5, -18) },
						{ Name = "18 aside", At = Vector3.new(18, 3.5, 4) },
					}
					for _, stand in stands do
						look(door, origin * stand.At)
						local over = covered(doorSign, door)
						t.Check(`the door, {stand.Name}: its sign shown beside it, none of it over the door`, not SignsController.Aside(door) and over == 0, `aside {SignsController.Aside(door)}, over {over}`)
					end
				elseif not festival then
					t.Check("the door's kit, to stand before it", false, "no Frame")
				end
				local gateSign: Frame? = parts.Gate
				if gate and gateSign then
					local box, extent = if gate:IsA("Model") then gate:GetBoundingBox() else (gate :: BasePart).CFrame, if gate:IsA("Model") then gate:GetExtentsSize() else (gate :: BasePart).Size
					local middle = box.Position
					local toward = if door and door:IsA("Model") then door:GetBoundingBox().Position else middle + Vector3.new(0, 0, 1)
					local flat = Vector3.new(toward.X - middle.X, 0, toward.Z - middle.Z).Unit
					look(gate, middle + flat * 40 + Vector3.new(0, 3 - extent.Y / 2, 0)) -- the avatar's root on the gate's floor
					t.Check("the gate, 40 out: its sign shown", gateSign.Visible)
					local over = covered(gateSign, gate)
					t.Check("the gate, 40 out: none of its sign over the gate", over == 0, `over {over}`)
				end
				camera.CameraType = Enum.CameraType.Custom
			end,
		},
		{
			Name = "Base: AR15's Festival Door, the ring tunnel: its four rings turn always about the tunnel's axis at their plan's rates, its core lit by whether its ground is open, its way inside the front ring's open opening, its name on the plate",
			Place = "Main", -- TR45: its world stands in that place only
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
			Place = "Main", -- TR45: its world stands in that place only
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
		{
			Name = "Base: AR50's levels: each base level's pieces stand at it beside the lower levels', after its generator's swap; the rings turn in place on the plan's axle, opposite ways; bays 3 and 4 wear their wake only while awake",
			Place = "Main", -- TR45: its world stands in that place only
			Run = function(t: any)
				local view = ProfileController.Get()
				local plot = Players.LocalPlayer:GetAttribute("Plot")
				local plant = if type(plot) == "number" then Markers.Find("Generator", { Plot = plot }) else nil
				local base = if plant then plant.Parent else nil
				if base then
					pcall(function()
						Players.LocalPlayer:RequestStreamAroundAsync((base :: Model):GetPivot().Position, 2)
					end)
				end
				local levels = if base then base:FindFirstChild("Levels") else nil
				if view == nil or plant == nil or levels == nil then
					t.Check("a plot, its levels and a save", false, if levels == nil then "no Levels on the plot" else nil)
					return
				end
				local held, generator, frame = levels :: Instance, plant :: Instance, (base :: Model):GetPivot()
				local rows = BasePlan.machines.baseLevels.levels
				-- the pieces the world lays: none of the cut's (Config.World.Cut, AR65)
				local function kept(list: { any }): number
					local n = 0
					for _, row in list do
						n += if WorldConfig.Cut[row.piece] then 0 else 1
					end
					return n
				end
				local pieces = kept(rows["2"].pieces) + kept(rows["3"].pieces)
				-- Every piece shown as `level` has it: a level's own and every lower level's, solid only the fins.
				local function standsAt(level: number): (boolean, string)
					local wrong, count = {}, 0
					for _, part in held:GetChildren() do
						local from = part:GetAttribute("BaseLevel")
						if part:IsA("BasePart") and type(from) == "number" then
							count += 1
							local want = level >= from
							if (part.Transparency == 0) ~= want or part.CanCollide ~= (want and part:GetAttribute("Solid") == true) then
								table.insert(wrong, `{part.Name} {part.Transparency}`)
							end
						end
					end
					return count == pieces and #wrong == 0, `{count} of {pieces}; {table.concat(wrong, ", ")}`
				end
				local function newHidden(level: number): boolean
					for _, part in held:GetChildren() do
						if part:IsA("BasePart") and part:GetAttribute("BaseLevel") == level and part.Transparency == 0 then
							return false
						end
					end
					return true
				end
				local levelWas = view.Base.Level
				local said = ""
				t.Server("BaseLevel", 1)
				t.Check("base level 1: none of the later levels' pieces", waitFor(t, ANSWER + 2, function(): boolean
					local ok, words = standsAt(1)
					said = words
					return ok
				end), said)
				for level = 2, BaseLevels.Top() do
					t.Server("BaseLevel", level)
					local swapping = waitFor(t, 1, function(): boolean
						return generator:GetAttribute("Swapping") == true
					end)
					t.Check(`base level {level}: its pieces wait for the generator's swap, under the landing's cover`, swapping and newHidden(level), tostring(swapping))
					t.Check(`then its pieces stand beside the lower levels'`, waitFor(t, ANSWER + 2, function(): boolean
						local ok, words = standsAt(level)
						said = words
						return ok
					end), said)
				end
				-- The rings at level 3: on the plan's axle in the plot's frame, turning in place at their rates, opposite ways.
				for _, row in ({ rows["2"].pieces[4], rows["3"].pieces[4] } :: { any }) do
					local ring: BasePart? = nil
					for _, part in held:GetChildren() do
						if part:IsA("BasePart") and part:GetAttribute("Piece") == row.piece then
							ring = part
						end
					end
					if WorldConfig.Cut[row.piece :: string] then
						t.Check(`{row.piece}: none, while it's cut`, ring == nil)
						continue
					end
					if ring == nil then
						t.Check(`{row.piece}: on the plot`, false)
						continue
					end
					local up = frame:VectorToObjectSpace(ring.CFrame.UpVector)
					local axle = Vector3.new(row.axle[1], row.axle[2], row.axle[3])
					t.Check(`{row.piece}: on the plan's axle`, (up - axle).Magnitude < 1e-3, string.format("%.4f %.4f %.4f", up.X, up.Y, up.Z))
					local before, began = ring.CFrame, os.clock()
					t.Wait(1)
					local after = ring.CFrame
					local _, yaw, _ = before:ToObjectSpace(after):ToEulerAnglesYXZ()
					local rate = math.deg(yaw) / (os.clock() - began)
					local want = row.rate * 360 * row.sign
					t.Check(`{row.piece}: turns {want} degrees a second about its axle, in place`, math.abs(rate - want) < 0.5 and (after.Position - before.Position).Magnitude < 1e-3 and after.UpVector:Dot(before.UpVector) > 0.99999,
						string.format("%.2f", rate))
				end
				t.Server("BaseLevel", levelWas)
				t.Check("the level put back: so are its pieces", waitFor(t, ANSWER + 2, function(): boolean
					return (standsAt(levelWas))
				end))
				-- The wakes: bays 3 and 4 each their own, at its bay's place and turn, shown only while the bay is awake.
				local open = #(ProfileController.Get() or view).Base.Bays
				local wakes = BasePlan.machines.baseLevels.bayWake.pieces
				for _, bay in Markers.All("Bay") do
					local index = bay:GetAttribute("Bay")
					if bay:GetAttribute("Plot") ~= plot or type(index) ~= "number" then
						continue
					end
					local wake = bay:FindFirstChild("Wake")
					local want = wakes[tostring(index)]
					if want ~= nil and WorldConfig.Cut[want] then
						t.Check(`bay {index}: no wake, while it's cut`, wake == nil)
						continue
					elseif want == nil then
						t.Check(`bay {index}: no wake`, wake == nil)
						continue
					end
					if wake == nil or not wake:IsA("BasePart") then
						t.Check(`bay {index}: its wake, {want}`, false)
						continue
					end
					local awake = index <= open
					t.Check(`bay {index}: its wake {if awake then "shown, awake" else "hidden, asleep"}`, wake:GetAttribute("Piece") == want and (wake.Transparency == 0) == awake, tostring(wake.Transparency))
					local turned = (bay :: Model):GetPivot().LookVector:Dot(wake.CFrame.LookVector)
					t.Check(`bay {index}: its wake turned with its bay`, turned > 0.9999, string.format("%.4f", turned))
				end
			end,
		},
		{
			Name = "Base: TR22's gate and plinth (TR51): the plate says its owner's name over the base's level on both faces, and follows the level; the plinth stands the showcase Voidkin, the strongest until one's picked, at its middle, playing its Idle, turning, its CR over it; a pick stands the one picked, and \"\" gives it back",
			Place = "Main", -- TR45: its world stands in that place only
			Run = function(t: any)
				local view = ProfileController.Get()
				local plot = Players.LocalPlayer:GetAttribute("Plot")
				local breaker = if type(plot) == "number" then Markers.Find("Breaker", { Plot = plot }) else nil
				local dressing = if breaker and breaker.Parent then breaker.Parent:FindFirstChild("Dressing") else nil
				if view == nil or dressing == nil then
					t.Check("a plot, its dressing and a save", false)
					return
				end
				local dressed = dressing :: Instance
				-- The plate, on both faces.
				local function plateSays(level: number): (boolean, string)
					local plate = dressed:FindFirstChild("LevelMark")
					local said = {}
					for _, face in { "Front", "Back" } do
						local gui = if plate then plate:FindFirstChild(face) else nil
						local owner = if gui then gui:FindFirstChild("Owner") else nil
						local mark = if gui then gui:FindFirstChild("Level") else nil
						if not (owner and owner:IsA("TextLabel") and mark and mark:IsA("TextLabel")) then
							return false, `{face}: no plate`
						end
						table.insert(said, `{owner.Text} / {mark.Text}`)
						if owner.Text ~= Players.LocalPlayer.DisplayName or mark.Text ~= `Level {level}` then
							return false, table.concat(said, "; ")
						end
					end
					return true, table.concat(said, "; ")
				end
				local levelWas = view.Base.Level
				local said = ""
				t.Check("the plate: the owner's name over the base's level, on both faces", waitFor(t, ANSWER + 3, function(): boolean
					local ok, words = plateSays(levelWas)
					said = words
					return ok
				end), said)
				local other = if levelWas < BaseLevels.Top() then levelWas + 1 else levelWas - 1
				if other >= 1 and other ~= levelWas then
					t.Server("BaseLevel", other)
					t.Check(`the base at level {other}: the plate follows`, waitFor(t, ANSWER, function(): boolean
						local ok, words = plateSays(other)
						said = words
						return ok
					end), said)
					t.Server("BaseLevel", levelWas)
					t.Check("the level put back: so does the plate", waitFor(t, ANSWER, function(): boolean
						return (plateSays(levelWas))
					end))
				end
				-- The plinth's Voidkin.
				local function figure(): Model?
					local found = dressed:FindFirstChild("Showcased")
					return if found and found:IsA("Model") and found.PrimaryPart then found else nil
				end
				local function stands(id: string): boolean
					local made = figure()
					return made ~= nil and made:GetAttribute("Voidkin") == id
				end
				local shown = Collection.Showcase(ProfileController.Get() :: any)
				if shown == nil then
					t.Check("a Voidkin to show", false)
					return
				end
				local owned = shown :: Profile.OwnedVoidkin
				local rig = AnimationsConfig.Rigs[Voidkin.ById[owned.Def].Rig or "R6"]
				t.Check("the plinth stands the showcase Voidkin (Collection.Showcase), playing its rig's Idle", waitFor(t, ANSWER + 3, function(): boolean
					local made = figure()
					return stands(owned.Id) and made ~= nil and made:GetAttribute("Playing") == rig.Idle
				end), if figure() then `{tostring((figure() :: Model):GetAttribute("Voidkin"))}, playing {tostring((figure() :: Model):GetAttribute("Playing"))}` else "none")
				local made = figure()
				local plinth: Instance? = nil
				for _, part in dressed:GetChildren() do
					if part:GetAttribute("Piece") == "Showcase" then
						plinth = part
					end
				end
				local stand = if plinth then plinth:GetAttribute("Stand") else nil
				if made and typeof(stand) == "CFrame" then
					local look = WorldConfig.Showcase
					local at = made:GetPivot().Position
					local want = (stand * CFrame.new(0, look.Hip, 0)).Position
					t.Check("at the plinth's middle, Up over its foot and Hip over that", (at - want).Magnitude < 0.05, tostring(at - want))
					local root = made.PrimaryPart :: BasePart
					t.Check("held where it stands, through nobody's way", root.Anchored and not root.CanCollide)
					-- Turning: its facing about the up axis, over half a second, at Turn turns a second.
					local was, from = made:GetPivot().LookVector, os.clock()
					task.wait(0.5)
					local now, took = made:GetPivot().LookVector, os.clock() - from
					local turned = math.acos(math.clamp(was:Dot(now), -1, 1))
					local expect = look.Turn * 2 * math.pi * took
					t.Check(`turning: {string.format("%.3f", turned)} rad in {string.format("%.2f", took)} s, about {string.format("%.3f", expect)}`, turned > expect * 0.6 and turned < expect * 1.4)
					t.Check("upright as it turns", math.abs(now.Y) < 1e-3)
					-- Its CR, over it.
					local board = root:FindFirstChild("Power")
					local words = if board then board:FindFirstChild("Words") else nil
					local data = ProfileController.Get() :: any
					local power = Stats.Power((Stats.Resolve(owned, Stats.PresetOf(data, owned), data)))
					t.Check("its CR over it, read from the Strip", board ~= nil and board:IsA("BillboardGui") and board.Adornee == root and board.MaxDistance == look.Far
						and math.abs(board.StudsOffsetWorldSpace.Y - look.Above) < 1e-4) -- a Vector3 holds float32
					t.Equal("the CR as the sheet writes it", if words and words:IsA("TextLabel") then words.Text else "none", `{Sheet.Said.Power} {Hud.Digits(power)}`)
				else
					t.Check("the plinth and its Voidkin", false, if made then "no stand" else "no figure")
				end
				-- A pick stands the one picked; "" gives it back to the strongest.
				local pickedWas = view.Base.Showcase
				local pick: string? = nil
				for id in (ProfileController.Get() :: any).Voidkin do
					if id ~= owned.Id and (pick == nil or id < pick) then
						pick = id
					end
				end
				if pick then
					t.Check("picked: accepted", ProfileController.Act("SetShowcase", { Voidkin = pick }).Ok == true)
					t.Check("the plinth stands the one picked", waitFor(t, ANSWER + 3, function(): boolean
						return stands(pick :: string)
					end), tostring(figure() and (figure() :: Model):GetAttribute("Voidkin")))
					t.Check("picked back", ProfileController.Act("SetShowcase", { Voidkin = pickedWas }).Ok == true)
					t.Check("and the showcase stands again", waitFor(t, ANSWER + 3, function(): boolean
						return stands(owned.Id)
					end), tostring(figure() and (figure() :: Model):GetAttribute("Voidkin")))
				else
					t.Check("one Voidkin only: no pick to try", true)
				end
			end,
		},
		{
			Name = "Base: TR37, the Forge and the Stone Condenser in their sleeping places: the Condenser sleeps on its stone below its base level and wakes at it, its comb lit by its tray, full, part-full and empty, its core turning while it works; a tap collects the tray; the convert's card beside its cradle (AR51) asleep, ready, short and running, its prompt on the cradle runs a convert; no Forge while AR65 cuts it, else its prompt opens Reinforce and a try strikes its ram",
			Place = "Main", -- TR45: its world stands in that place only
			Run = function(t: any)
				local view = ProfileController.Get()
				local plot = Players.LocalPlayer:GetAttribute("Plot")
				local condenser = if type(plot) == "number" then Markers.Find("Condenser", { Plot = plot }) else nil
				local forge = if type(plot) == "number" then Markers.Find("Forge", { Plot = plot }) else nil
				-- The Forge is out of the yard while it's cut (AR65): its prompt and ram are checked only once it's back.
				local forgeCut = WorldConfig.Cut.Forge == true
				if view == nil or condenser == nil or (forge == nil and not forgeCut) then
					t.Check("a plot, its Forge, its Condenser and a save", false, `{condenser ~= nil}, {forge ~= nil}`)
					return
				end
				local machine = condenser :: Instance
				local levelWas = view.Base.Level
				local low, mid = CondenserConfig.Makes, CondenserConfig.Converts.Low.To
				local function shownOf(name: string): boolean
					local part = machine:FindFirstChild(name)
					return part ~= nil and part:IsA("BasePart") and part.Transparency < 1
				end
				-- The jewels its tray holds, as its plate says them after the stones (TR56); "" for none.
				local function jewelWords(data: any): string
					local n = Condenser.JewelsHeld(data.Base)
					return if n == 0 then "" else ` · {n} {if n == 1 then "jewel" else "jewels"}`
				end
				local function litCups(): number
					local lit = 0
					for _, part in machine:GetChildren() do
						if part:IsA("BasePart") and type(part:GetAttribute("Cup")) == "number" and part.Transparency < 1 then
							lit += 1
						end
					end
					return lit
				end
				local cups = machine:GetAttribute("Cups")
				t.Check("its comb's cups, one stone each", type(cups) == "number" and cups > 0, tostring(cups))
				local comb = if type(cups) == "number" then cups else 0
				local function plateLine(): string
					local plate = BaseController.Parts().CondenserPlate
					local panel = if plate then plate:FindFirstChild("Panel") else nil
					local line = if panel then panel:FindFirstChild("Line2") else nil
					return if line and line:IsA("TextLabel") then line.Text else ""
				end
				-- Asleep below its level: its stone, nothing of its Comb, the plate says when it wakes, nothing to tap.
				t.Server("BaseLevel", CondenserConfig.Wakes - 1)
				t.Check("asleep: its sleeping stone, not its Comb", waitFor(t, ANSWER + 2, function(): boolean
					return shownOf("Asleep") and not shownOf("Frame") and not shownOf("Core") and litCups() == 0
				end), `stone {shownOf("Asleep")}, comb {shownOf("Frame")}, {litCups()} cups`)
				t.Check("its plate says when it wakes", waitFor(t, ANSWER, function(): boolean
					return plateLine() == `Turns on at base level {CondenserConfig.Wakes}`
				end), plateLine())
				t.Check("nothing to collect", BaseController.Parts().CondenserPrompt == nil)
				-- The convert's card (AR51's B): asleep, its cost line alone, 44 high, nothing to start.
				local look = HudConfig.Convert
				local function card(): Frame?
					local found = BaseController.Parts().ConvertCard
					return if found and found:IsA("Frame") then found else nil
				end
				local function cardPart(name: string): GuiObject?
					local found = card()
					local panel = if found then found:FindFirstChild("Panel") else nil
					local part = if panel then panel:FindFirstChild(name) else nil
					return if part and part:IsA("GuiObject") then part else nil
				end
				local function word(): string
					local label = cardPart("Word")
					return if label and label:IsA("TextLabel") then label.Text else ""
				end
				local function cardState(): string
					local found = card()
					return if found then tostring(found:GetAttribute("State")) else "no card"
				end
				t.Check("asleep: the card's cost line alone, 44 high", waitFor(t, ANSWER, function(): boolean
					local found, bar, said = card(), cardPart("Bar"), cardPart("Word")
					return found ~= nil and cardState() == "Asleep" and found.Size.Y.Offset == look.Asleep and bar ~= nil and not bar.Visible
						and said ~= nil and not said.Visible
				end), cardState())
				local stones = { cardPart("From"), cardPart("To") }
				t.Check("its cost in the stones' own pictures, the take and the give", (stones[1] :: ImageLabel?) ~= nil and (stones[2] :: ImageLabel?) ~= nil
					and (stones[1] :: ImageLabel).Image == UIKit.Images[`Stone{CondenserConfig.Converts.Low.From}`].Id and (stones[2] :: ImageLabel).Image == UIKit.Images[`Stone{CondenserConfig.Converts.Low.To}`].Id
					and (cardPart("Take") :: TextLabel?) ~= nil and (cardPart("Take") :: TextLabel).Text == tostring(CondenserConfig.Converts.Low.Take)
					and (cardPart("Give") :: TextLabel?) ~= nil and (cardPart("Give") :: TextLabel).Text == tostring(CondenserConfig.Converts.Low.Give))
				local asleepPrompt = BaseController.Parts().ConvertPrompt :: ProximityPrompt?
				t.Check("nothing to start", asleepPrompt ~= nil and not asleepPrompt.Enabled)
				local switch = BaseController.Parts().ConvertSwitch :: ProximityPrompt?
				t.Check("TR56: its Switch off while the Condenser runs one convert (Mid into High from its level 10)", switch ~= nil and not switch.Enabled)
				-- Awake: its Comb, the stone gone. An empty tray first, so the fills below are its own.
				t.Server("BaseLevel", math.max(levelWas, CondenserConfig.Wakes))
				t.Check("awake at its level: its Comb, the stone gone", waitFor(t, ANSWER + 2, function(): boolean
					return shownOf("Frame") and shownOf("Core") and not shownOf("Asleep")
				end), `stone {shownOf("Asleep")}, comb {shownOf("Frame")}`)
				ProfileController.Act("CollectTray")
				t.Check("empty: the comb dark", waitFor(t, ANSWER, function(): boolean
					return litCups() == 0 and machine:GetAttribute("Held") == 0
				end), `{litCups()} lit, {tostring(machine:GetAttribute("Held"))} held`)
				local level = Condenser.Level((ProfileController.Get() :: any).Base)
				local cap = Condenser.Cap(level)
				local rate = Condenser.Rate(level)
				local floor = PowerConfig.MinSpeed -- the skips below hold at any power the plot has, the floor's included
				local bagWas = table.clone((ProfileController.Get() :: any).Bag.Stones)
				-- Part-full: 4 hours' work at the floor's speed (1 stone a level-1 hour at full, 4 at the floor's quarter)
				-- is at least a stone and, at full power, a third of the tray.
				t.Server("BaseBattery", 1e9)
				t.Server("BaseSkip", 1.05 * 3600 / (rate * floor))
				local function trayHeld(): number
					local held = machine:GetAttribute("Held")
					return if type(held) == "number" then held else -1
				end
				-- The attribute's value lands with its packet, the copy's handler a moment later: the plate and the case read
				-- the copy, so each wait holds until the two agree.
				local function copyHeld(): number
					local copy = ProfileController.Get() :: any
					return if copy then Condenser.Held(copy.Base) else -1
				end
				t.Check("part-full: some stones in the tray", waitFor(t, ANSWER + 2, function(): boolean
					return trayHeld() > 0 and trayHeld() < cap and copyHeld() == trayHeld()
				end), `{trayHeld()} held, the copy {copyHeld()}`)
				local held = trayHeld()
				local data = ProfileController.Get() :: any
				t.Equal("its comb lit by the tray's fill", litCups(), Condenser.Lit(data.Base, comb))
				t.Check("part of the comb, not all", litCups() > 0 and litCups() < comb, `{litCups()} of {comb}`)
				t.Equal("its plate reads the tray, and the jewels its work made (TR56)", plateLine(), `Tray {held} of {cap} {low}{jewelWords(data)}`)
				local core = machine:FindFirstChild("Core") :: BasePart?
				t.Check("its core turning while it works", core ~= nil and core:GetAttribute("Spinning") == true)
				if core then
					local was = BaseController.TurnedOf(core) or 0
					task.wait(0.5)
					t.Check("and turned", (BaseController.TurnedOf(core) or 0) ~= was)
				end
				t.Check("a tap to collect", waitFor(t, ANSWER, function(): boolean
					local prompt = BaseController.Parts().CondenserPrompt
					return prompt ~= nil and prompt:IsA("ProximityPrompt") and (prompt :: ProximityPrompt).ActionText == "Collect"
				end))
				-- Full: its whole comb lit, its core still, the plate says so.
				t.Server("BaseSkip", (cap + 1) * 3600 / (rate * floor))
				t.Check("full: the whole comb lit", waitFor(t, ANSWER + 2, function(): boolean
					return trayHeld() == cap and litCups() == comb and copyHeld() == cap
				end), `{trayHeld()} held, the copy {copyHeld()}, {litCups()} of {comb} lit`)
				t.Check("its core still on a full tray", core ~= nil and core:GetAttribute("Spinning") == false)
				t.Equal("its plate says full", plateLine(), `Tray full · {cap} {low}{jewelWords(ProfileController.Get() :: any)}`)
				-- The tap: the whole tray into the bag, once.
				local lowWas = (ProfileController.Get() :: any).Bag.Stones[low] or 0
				local answer = BaseController.CollectTray()
				t.Check("collected: the whole tray", answer.Ok == true and answer.Count == cap, tostring(answer.Error))
				t.Check("into the bag, and the comb dark", waitFor(t, ANSWER, function(): boolean
					local bag = (ProfileController.Get() :: any).Bag.Stones[low] or 0
					return bag == lowWas + cap and litCups() == 0
				end))
				t.Check("nothing left to tap", waitFor(t, ANSWER, function(): boolean
					return BaseController.Parts().CondenserPrompt == nil
				end))
				-- The card: ready, short and running; its prompt on the cradle begins a convert, which says its time, refuses a
				-- second, and lands its Mid in the tray.
				local c = CondenserConfig.Converts.Low
				local cradle = WorldConfig.Condenser.Cradle
				local at = (Markers.At(machine) * CFrame.new(cradle[1], cradle[3], -cradle[2])).Position
				local onCradle = BaseController.Parts().ConvertPrompt :: ProximityPrompt?
				local holder = if onCradle then onCradle.Parent else nil
				t.Check("the convert's prompt on the cradle", holder ~= nil and holder:IsA("BasePart") and (holder.Position - at).Magnitude < 0.01,
					if holder and holder:IsA("BasePart") then tostring(holder.Position) else "no prompt")
				local function fill(): number
					local bar = cardPart("Bar")
					local lit = if bar then bar:FindFirstChild("Fill") :: Frame? else nil
					if not (bar and lit) then
						return -1
					end
					return if lit.Visible then lit.Size.X.Offset / (bar.Size.X.Offset - 2 * look.Bar.Inset) else 0
				end
				local function have(): number
					return (ProfileController.Get() :: any).Bag.Stones[c.From] or 0
				end
				if have() < c.Take then
					t.Server("StonesGive", c.From, c.Take - have())
				end
				t.Check("ready: its bar full, its word, its prompt", waitFor(t, ANSWER, function(): boolean
					local found = card()
					return found ~= nil and cardState() == "Ready" and word() == "Ready" and math.abs(fill() - 1) < 1e-6
						and found.Size.Y.Offset == look.Size.Y and onCradle ~= nil and onCradle.Enabled
				end), `{cardState()}, {word()}, {fill()}`)
				-- TR56: from the Condenser's level 10, with Mid in the bag, its Switch on, and a press turns the card to Mid into
				-- High; back at its level, off again, the card on Low into Mid.
				do
					local was = ProfileController.Get() :: any
					local condenserWas, midWas = was.Base.Machines.Condenser or 1, was.Bag.Stones.Mid or 0
					local high = CondenserConfig.Converts.Mid
					t.Server("MachineLevel", "Condenser", high.FromLevel)
					t.Server("StonesGive", "Mid", math.max(0, high.Take - midWas))
					local switchPrompt = BaseController.Parts().ConvertSwitch :: ProximityPrompt?
					local panel = BaseController.Parts().ConvertCard :: Instance?
					t.Check("TR56: at the Condenser's level 10, Mid in the bag: its Switch on, the card still on Low", waitFor(t, ANSWER, function(): boolean
						return switchPrompt ~= nil and switchPrompt.Enabled and panel ~= nil and panel:GetAttribute("From") == "Low"
					end), if panel then tostring(panel:GetAttribute("From")) else "no card")
					t.Equal("a switch: Mid into High", BaseController.SwitchConvert(), "Mid")
					t.Check("the card's cost line on Mid", waitFor(t, ANSWER, function(): boolean
						return panel ~= nil and panel:GetAttribute("From") == "Mid"
					end), if panel then tostring(panel:GetAttribute("From")) else "no card")
					t.Server("MachineLevel", "Condenser", condenserWas)
					t.Server("StonesGive", "Mid", midWas - ((ProfileController.Get() :: any).Bag.Stones.Mid or 0))
					t.Check("back under level 10: its Switch off, the card on Low", waitFor(t, ANSWER, function(): boolean
						return switchPrompt ~= nil and not switchPrompt.Enabled and panel ~= nil and panel:GetAttribute("From") == "Low"
					end), if panel then tostring(panel:GetAttribute("From")) else "no card")
				end
				-- In reach, beside its prompt (UI.World.Beside): Roblox's card draws under every layer, so the card stands right
				-- of it, or at the screen's right edge.
				local stand = (Markers.At(machine) * CFrame.new(1.0, 3, -8.6)).Position
				t.Server("TestStandAt", stand, Vector3.new(at.X, stand.Y, at.Z))
				local function promptShown(): boolean
					local gui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
					local cards = if gui then gui:FindFirstChild("ProximityPrompts") else nil
					for _, item in if cards then cards:GetChildren() else {} do
						if item:IsA("BillboardGui") and item.Adornee ~= nil and item.Adornee == holder and item.AbsoluteSize.X > 0 then
							return true
						end
					end
					return false
				end
				local said = ""
				local promptRight: number? = nil -- where its card ended, for the card once the prompt has gone
				t.Check("in reach: the card clear of its prompt's card", waitFor(t, ANSWER + 2, function(): boolean
					local found = card()
					local low: Vector2?, high: Vector2? = nil, nil
					if onCradle then
						low, high = World.PromptBox(onCradle)
					end
					if not (found and found.Visible and low and high and promptShown()) then
						said = `card {found ~= nil and found.Visible}, prompt {promptShown()}`
						return false
					end
					local gap = HudConfig.Plates.Gap * Layers.Scale()
					local left, right = found.AbsolutePosition.X, found.AbsolutePosition.X + found.AbsoluteSize.X
					local room = (found.Parent :: GuiObject).AbsoluteSize.X
					local edge = (high :: Vector2).X
					promptRight = edge
					said = string.format("its left %.1f, the prompt's right %.1f", left, edge)
					return left >= edge + gap - 1 or right >= room - gap - 1
				end), said)
				-- Under every HUD piece in its column by the kit's gap (research's must-fix 3 on AR51: its top met the shop's
				-- restock line flush): a stand-in piece under the band's, its foot 4 pixels into the card's top.
				local shown = card()
				local before = if shown then shown.AbsolutePosition.Y else 0
				local hud = Layers.Get("Hud")
				local piece = Instance.new("Frame")
				piece.Name = "NL_SelfTestColumnPiece"
				piece.BackgroundTransparency = 1
				if shown then
					local scale = Layers.Scale()
					local from = shown.AbsolutePosition - hud.AbsolutePosition
					piece.Position = UDim2.fromOffset(from.X / scale, (from.Y + 4) / scale - 20)
					piece.Size = UDim2.fromOffset(shown.AbsoluteSize.X / scale, 20)
				end
				piece.Parent = hud
				HudController.Beneath(piece)
				local under = ""
				t.Check("under a HUD piece in its column by the kit's gap", shown ~= nil and waitFor(t, 2, function(): boolean
					local found = card()
					if found == nil then
						return false
					end
					local foot = piece.AbsolutePosition.Y + piece.AbsoluteSize.Y
					under = string.format("its top %.1f, the piece's foot %.1f", found.AbsolutePosition.Y, foot)
					return found.AbsolutePosition.Y >= foot + HudConfig.Plates.Gap * Layers.Scale() - 1
				end), under)
				piece:Destroy()
				t.Check("back up once it's gone", waitFor(t, 2, function(): boolean
					local found = card()
					return found ~= nil and math.abs(found.AbsolutePosition.Y - before) < 1
				end))
				-- Short: the bag one stone short of a hand's worth, the bar at what it holds, nothing to start.
				local short = c.Take - 1
				t.Server("StonesGive", c.From, short - have())
				t.Check(`short: "{short} of {c.Take} {c.From}", its bar at {short} of {c.Take}`, waitFor(t, ANSWER, function(): boolean
					return cardState() == "Short" and word() == `{short} of {c.Take} {c.From}` and math.abs(fill() - short / c.Take) < 0.03
						and onCradle ~= nil and not onCradle.Enabled
				end), `{cardState()}, {word()}, {fill()}`)
				t.Server("StonesGive", c.From, c.Take - have())
				t.Check("it can start", waitFor(t, ANSWER, function(): boolean
					return onCradle ~= nil and onCradle.Enabled and cardState() == "Ready"
				end), cardState())
				local begun = BaseController.Convert()
				t.Check("a convert begins", begun.Ok == true, tostring(begun.Error))
				t.Check("running: its card counts its time down, its bar at the share done", waitFor(t, ANSWER, function(): boolean
					local share = fill()
					return cardState() == "Running" and string.find(word(), " left$") ~= nil and share >= 0 and share < 1 and onCradle ~= nil and not onCradle.Enabled
				end), `{cardState()}, {word()}, {fill()}`)
				-- Still clear of where the prompt's card stood: its whole size held once it has gone (a prompt shown for a
				-- moment as the convert began held its opening width, 72, and the card slid over the Voidkin, AR51's take).
				local found = card()
				local stayed = found ~= nil and promptRight ~= nil and (found.AbsolutePosition.X >= (promptRight :: number) + HudConfig.Plates.Gap * Layers.Scale() - 1
					or found.AbsolutePosition.X + found.AbsoluteSize.X >= (found.Parent :: GuiObject).AbsoluteSize.X - HudConfig.Plates.Gap * Layers.Scale() - 1)
				t.Check("running: the card still beside where its prompt stood", stayed,
					if found and promptRight then string.format("its left %.1f, the prompt's right %.1f", found.AbsolutePosition.X, promptRight :: number) else "no card")
				t.Equal("one at a time", ProfileController.Act("Convert").Error, "Busy")
				t.Server("BaseSkip", CondenserConfig.Converts.Low.Seconds / floor + 5)
				t.Check("its Mid lands in the tray", waitFor(t, ANSWER + 2, function(): boolean
					local tray = (ProfileController.Get() :: any).Base.Condenser.Tray
					return (tray[mid] or 0) >= CondenserConfig.Converts.Low.Give
				end))
				t.Check("its plate says so", waitFor(t, ANSWER, function(): boolean
					return string.find(plateLine(), `{CondenserConfig.Converts.Low.Give} {mid}`, 1, true) ~= nil
				end), plateLine())
				ProfileController.Act("CollectTray")
				for _, grade in { low, mid } do -- the bag as it was
					local change = (bagWas[grade] or 0) - ((ProfileController.Get() :: any).Bag.Stones[grade] or 0)
					if change ~= 0 then
						t.Server("StonesGive", grade, change)
					end
				end
				-- The Forge: its prompt opens Reinforce; a try strikes its ram on every client.
				if forgeCut then
					t.Check("no Forge in the yard, nor its prompt: Reinforce lives in Equipment (AR65)", forge == nil and BaseController.Parts().ForgePrompt == nil)
				else
					local forgePrompt = BaseController.Parts().ForgePrompt
					t.Check("the Forge's prompt", forgePrompt ~= nil and forgePrompt:IsA("ProximityPrompt") and (forgePrompt :: ProximityPrompt).ActionText == "Reinforce")
					BaseController.PressForge()
					t.Check("it opens Equipment on Reinforce", waitFor(t, ANSWER, function(): boolean
						return Screen.Current() == EquipmentScreen.Name and EquipmentScreen.State().Page == "Reinforce"
					end), `{tostring(Screen.Current())}, {EquipmentScreen.State().Page}`)
					if Screen.Current() == EquipmentScreen.Name then
						Screen.Close()
					end
					local ram = (forge :: Instance):FindFirstChild("Ram") :: BasePart?
					local item: string? = nil
					for id, owned in (ProfileController.Get() :: any).Items do
						if owned.Reinforce < ReinforceConfig.Cap and (item == nil or id < item) then
							item = id
						end
					end
					if ram and item then
						local owned = (ProfileController.Get() :: any).Items[item]
						local cost = ReinforceRules.Cost(owned, owned.Reinforce + 1)
						local was = owned.Reinforce
						t.Server("StonesGive", cost.Grade, cost.Stones) -- what the try spends, given first: the bag and purse end as they were
						t.Server("DataCredits", cost.Credits)
						local strikes = ram:GetAttribute("Strikes")
						-- Watched from the try on, every frame, so the hitstop's few frames are never missed.
						local lowest, moved = 0, false
						local watching = true
						task.spawn(function()
							while watching do
								local rise, striking = BaseController.StrikeOf(ram)
								moved = moved or striking
								lowest = math.min(lowest, rise or 0)
								task.wait()
							end
						end)
						local tried = ProfileController.Act("Reinforce", { Item = item })
						t.Check("a Reinforce try made", tried.Ok == true, tostring(tried.Error))
						t.Check("its ram counted one strike", waitFor(t, ANSWER, function(): boolean
							return ram:GetAttribute("Strikes") == (if type(strikes) == "number" then strikes else 0) + 1
						end))
						task.wait(Forge.Length(WorldConfig.Forge) + 0.3)
						watching = false
						local plan = BasePlan.machines.forge.ram
						t.Check("the ram struck the plate", moved and math.abs(lowest - (plan.contact - plan.rest)) < 0.05, `lowest {lowest}`)
						t.Check("and settled at rest", (BaseController.StrikeOf(ram)) == 0)
						t.Server("ReinforceSet", item, was)
					else
						t.Check("an item and the ram to strike", false, `ram {ram ~= nil}, item {tostring(item)}`)
					end
				end
				t.Server("BaseLevel", levelWas)
			end,
		},
		{
			Name = "Take: AR51, the convert's card from the prompt's reach in the smallest phone's proportions, each state as the driver writes, then the Power screen at the smallest phone with the Condenser's share, for research",
			Manual = true,
			Stay = true,
			Run = function(t: any)
				-- AR51's captures (docs/asset-requests.md, AR51). The driver writes ReplicatedStorage.NL_TakeStep: Asleep, Ready,
				-- Short or Running, the card in that state from Modulo's stand (across 1.0, along 8.6 in the Condenser's frame),
				-- the game's camera there held. The smallest phone whole in the viewport's middle: every layer at its floor in a
				-- box its size there, and the camera's field widened so that box sees the phone's own field, so the world, the
				-- plates and Roblox's prompt card (drawn in its own points, never scaled by the layers) all stand as they do on
				-- it. Then Power and Auto, the Power screen in the cases' smallest-phone box, the Condenser converting so its
				-- light is its own; End puts back the level, the split, the bag and the camera, the convert run out and its Mid
				-- collected. "Shown" says what is up.
				local view = ProfileController.Get()
				local plot = Players.LocalPlayer:GetAttribute("Plot")
				local machine = if type(plot) == "number" then Markers.Find("Condenser", { Plot = plot }) else nil
				t.Check("a save and the Condenser", view ~= nil and machine ~= nil)
				if view == nil or machine == nil then
					return
				end
				local c = CondenserConfig.Converts.Low
				local levelWas = view.Base.Level
				local power = { Open = view.Base.Power.Open, Auto = view.Base.Power.Auto, Shares = table.clone(view.Base.Power.Shares) }
				local bagWas = table.clone(view.Bag.Stones)
				local step = Instance.new("StringValue")
				step.Name = "NL_TakeStep"
				step.Value = "Ready"
				step.Parent = ReplicatedStorage
				local function have(): number
					return (ProfileController.Get() :: any).Bag.Stones[c.From] or 0
				end
				local function hold(count: number)
					if have() ~= count then
						t.Server("StonesGive", c.From, count - have())
					end
				end
				local function stateOf(): string
					local card = BaseController.Parts().ConvertCard
					return if card then tostring(card:GetAttribute("State")) else "none"
				end
				-- The stand, and the game's camera there: 12.07 behind and 4.74 up, at the head (AR15's measure).
				local home = Markers.At(machine)
				local stand = (home * CFrame.new(1.0, 3, -8.6)).Position
				local middle = home.Position + Vector3.new(0, 3, 0)
				t.Server("TestStandAt", stand, Vector3.new(middle.X, stand.Y, middle.Z))
				local camera = workspace.CurrentCamera
				local cameraWas, fieldWas = camera.CameraType, camera.FieldOfView
				local flat = Vector3.new(stand.X - middle.X, 0, stand.Z - middle.Z).Unit
				local top = GuiService.TopbarInset.Height
				local function phoneWorld()
					local view, phone = camera.ViewportSize, Theme.Smallest
					camera.CameraType = Enum.CameraType.Scriptable
					camera.FieldOfView = 2 * math.deg(math.atan(math.tan(math.rad(fieldWas / 2)) * view.Y / phone.Y))
					camera.CFrame = CFrame.lookAt(stand + flat * 12.07 + Vector3.new(0, 4.74, 0), stand + Vector3.new(0, 1.5, 0))
					Layers.Force(Theme.Scale.Floor)
					Layers.Box(phone - Vector2.new(0, top), (view - phone) / 2)
					step:SetAttribute("Frame", `{math.round((view.X - phone.X) / 2)},{math.round((view.Y - phone.Y) / 2)}`)
				end
				local converting = false
				local shown = ""
				waitFor(t, 900, function(): boolean
					if step.Value ~= shown then
						shown = step.Value
						if shown == "Asleep" or shown == "Ready" or shown == "Short" or shown == "Running" then
							if Screen.Current() then
								Screen.Close()
							end
							t.Server("BaseLevel", if shown == "Asleep" then CondenserConfig.Wakes - 1 else math.max(levelWas, CondenserConfig.Wakes))
							hold(if shown == "Short" then c.Take - 1 else math.max(have(), c.Take))
							if shown == "Running" and not converting then
								converting = BaseController.Convert().Ok == true
							end
							phoneWorld()
							waitFor(t, ANSWER + 2, function(): boolean
								return stateOf() == shown
							end)
							t.Wait(0.5)
							step:SetAttribute("Shown", stateOf())
						elseif shown == "Power" or shown == "Auto" then
							t.Server("BaseLevel", math.max(levelWas, CondenserConfig.Wakes))
							if not converting then
								hold(math.max(have(), c.Take))
								converting = BaseController.Convert().Ok == true
							end
							t.Server("PowerOpen", true)
							local asked = if shown == "Auto" then { Auto = true } else { Auto = false, Shares = { Breaker = 0.4, Training = 0.2, Condenser = 0.25 } }
							local answer = ProfileController.Act("SetPower", asked)
							if Screen.Current() then
								Screen.Close()
							end
							camera.FieldOfView = fieldWas
							Layers.Force(Theme.Scale.Floor)
							Layers.Box(Theme.Smallest - Vector2.new(0, top))
							t.Wait(0.3)
							BaseController.OpenPower()
							t.Wait(1)
							step:SetAttribute("Shown", `{shown} {answer.Ok == true} {tostring(Screen.Current())}`)
						end
					end
					return step.Value == "End"
				end)
				if Screen.Current() then
					Screen.Close()
				end
				Layers.Box(nil)
				Layers.Force(nil)
				camera.CameraType, camera.FieldOfView = cameraWas, fieldWas
				local back = ProfileController.Act("SetPower", if power.Auto then { Auto = true } else { Auto = false, Shares = power.Shares })
				t.Check("the split put back", back.Ok == true, tostring(back.Error))
				if not power.Open then
					t.Server("PowerOpen", false)
				end
				if converting then
					-- The convert run out at the floor's speed, its Mid collected, and the bag put back below: the skip's time,
					-- the battery's charge with it, is the take's one lasting change (the test store's save).
					t.Server("BaseSkip", c.Seconds / PowerConfig.MinSpeed + 5)
					waitFor(t, ANSWER + 2, function(): boolean
						return Condenser.ConvertLeft((ProfileController.Get() :: any).Base) == nil
					end)
					ProfileController.Act("CollectTray")
				end
				for grade, count in bagWas do
					local change = count - ((ProfileController.Get() :: any).Bag.Stones[grade] or 0)
					if change ~= 0 then
						t.Server("StonesGive", grade, change)
					end
				end
				for grade, count in (ProfileController.Get() :: any).Bag.Stones do
					if bagWas[grade] == nil and count > 0 then
						t.Server("StonesGive", grade, -count)
					end
				end
				t.Server("BaseLevel", levelWas)
				step:Destroy()
			end,
		},
		{
			Name = "Base: the return card (TR53, AR55): the save's card in its lines, in research's words and order, at the HUD's right under the Electricity pill, the next step waiting while it's up, on the smallest phone too; Reveal with a shard, else Collect, which lets it go",
			Place = "Main", -- the card is the base's
			Run = function(t: any)
				local view = ProfileController.Get()
				t.Check("a save", view ~= nil)
				if view == nil then
					return
				end
				local lead = view.Roles.Lead
				local owned = view.Voidkin[lead]
				local kept = view.Base.Card -- put back at the end
				local R = HudConfig.Return
				local function press(): (TextButton?, string)
					local button = ReturnCard.Parts().Press
					local label = if button then button:FindFirstChild("Label") :: TextLabel? else nil
					return button, if label then label.Text else ""
				end
				local function fits(where: string)
					local card = ReturnCard.Parts().Card
					local root = Layers.Get("Hud")
					local pill = HudController.Parts().Electricity
					local pillFoot = if pill and pill.Parent and pill.Parent:IsA("GuiObject") then pill.Parent.AbsolutePosition.Y + pill.Parent.AbsoluteSize.Y else math.huge
					if card == nil then
						t.Check(`{where}: the card stands`, false)
						return
					end
					local top, foot = card.AbsolutePosition.Y, card.AbsolutePosition.Y + card.AbsoluteSize.Y
					local right = card.AbsolutePosition.X + card.AbsoluteSize.X
					local edge = root.AbsolutePosition.X + root.AbsoluteSize.X
					local bottom = root.AbsolutePosition.Y + root.AbsoluteSize.Y
					local scale = Layers.Scale()
					t.Check(`{where}: under the Electricity pill`, top >= pillFoot - 0.5, `top {math.floor(top)}, the pill's foot {math.floor(pillFoot)}`)
					t.Check(`{where}: {R.Right} in from the HUD's right and {R.Foot} over its foot`, math.abs(edge - right - R.Right * scale) < 1 and math.abs(bottom - foot - R.Foot * scale) < 1, `{math.floor((edge - right) / scale + 0.5)}, {math.floor((bottom - foot) / scale + 0.5)}`)
					t.Check(`{where}: the next step waits while it's up`, HudController.Parts().Chip.Visible == false)
					local countdown = ShopController.Chip()
					t.Check(`{where}: the Void Shop's countdown waits while it's up`, countdown == nil or countdown.Visible == false)
				end
				-- Four workers who gained levels (research, 2026-11-25): three lines, the most first, then the fourth folded,
				-- so the tallest card a full base gives is the one laid on the smallest phone.
				local others: { string } = {}
				for id in view.Voidkin do
					if id ~= lead then
						table.insert(others, id)
					end
				end
				table.sort(others)
				local gains = { 5, 3, 3, 1 } -- as many as the room and one more, so the last folds
				assert(#gains == BaseConfig.Return.Workers + 1, "the case's gains: the room and one more")
				local worked: { [string]: number } = {}
				for index = 1, math.min(#others, #gains) do
					worked[others[index]] = gains[index]
				end
				local ok, err = pcall(function()
					local set = t.Server("ReturnCardSet", {
						Kwh = 12.4,
						Stones = { Low = 6, Mid = 1 },
						Trained = if owned then { [lead] = 2 } else {},
						Worked = worked,
						Shards = { "lanternrow_standard" },
					})
					-- each worker a line up to the room, and the fourth the fold's one line: one line a worker here
					local count = (if owned then 5 else 4) + math.min(#others, #gains)
					t.Check("the server sets a card of every line", type(set) == "table" and set.Ok == true and set.Lines == count, if type(set) == "table" then `{set.Lines} lines` else "no answer")
					local want = {
						{ Kind = "Battery", Gain = `+{Read.Kwh(12.4)} kWh`, Word = "stored" },
						{ Kind = "Stones", Gain = "+6", Word = "Low stones" },
						{ Kind = "Stones", Gain = "+1", Word = "Mid stone" },
					}
					if owned then
						table.insert(want, { Kind = "Training", Gain = "+2 levels", Word = Collection.Name(owned) })
					end
					for index = 1, math.min(#others, #gains) do
						local worker = view.Voidkin[others[index]]
						local level = `+{gains[index]} {if gains[index] == 1 then "level" else "levels"}`
						if index <= BaseConfig.Return.Workers then
							table.insert(want, { Kind = "Worker", Gain = level, Word = Collection.Name(worker) })
						else
							table.insert(want, { Kind = "Workers", Gain = level, Word = "1 more worker" })
						end
					end
					table.insert(want, { Kind = "Shards", Gain = "1 shard", Word = "ready" })
					local function shown(): string
						local out = {}
						for _, line in ReturnCard.Parts().Lines do
							table.insert(out, `{line.Kind} {line.Gain} / {line.Word}`)
						end
						return table.concat(out, "; ")
					end
					local function matches(): boolean
						local lines = ReturnCard.Parts().Lines
						if #lines ~= #want then
							return false
						end
						for index, line in want do
							local got = lines[index]
							if got.Kind ~= line.Kind or got.Gain ~= line.Gain or got.Word ~= line.Word then
								return false
							end
						end
						return true
					end
					t.Check("it rises, and its counts land on the save's card, in order", Helpers.waitFor(t, ANSWER + R.Seconds + #want * R.After + HudConfig.Motion.Count.Latest, matches), shown())
					local card = ReturnCard.Parts().Card
					local head = if card then card:FindFirstChild("Head", true) :: TextLabel? else nil
					t.Check("its head says where the player was", head ~= nil and head.Text == "While you were away")
					local _, word = press()
					t.Check("with a shard among them its press reveals", word == "Reveal", word)
					fits("this window")
					Helpers.lintClean(t, "this window, the return card up")
					Layers.Force(Theme.Scale.Floor)
					Layers.Box(Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height))
					t.Wait(0.2)
					fits("the smallest phone")
					Helpers.lintClean(t, "the smallest phone, the return card up")
					-- Short of room, the workers fold sooner (Rules.Return.Lines): every other line as it was, their
					-- levels all kept in fewer lines, the shard's line still last.
					local kept2, levels = {}, 0
					for _, line in ReturnCard.Parts().Lines do
						if line.Kind == "Worker" or line.Kind == "Workers" then
							levels += tonumber(line.Gain:match("%d+")) or 0
						else
							table.insert(kept2, `{line.Kind} {line.Gain} / {line.Word}`)
						end
					end
					local rest, total = {}, 0
					for _, line in want do
						if line.Kind ~= "Worker" and line.Kind ~= "Workers" then
							table.insert(rest, `{line.Kind} {line.Gain} / {line.Word}`)
						end
					end
					for index = 1, math.min(#others, #gains) do
						total += gains[index]
					end
					t.Check("the smallest phone: every other line as it stood, the shard's last", table.concat(kept2, "; ") == table.concat(rest, "; "), shown())
					t.Check("the smallest phone: the workers' levels all kept", levels == total, `{levels} of {total}: {shown()}`)
					-- All folded, the line names its most-grown worker, or counts them where the name doesn't fit (research, 2026-11-26)
					local folded = math.min(#others, #gains)
					local most = view.Voidkin[others[1]]
					local foldWord = ""
					for _, line in ReturnCard.Parts().Lines do
						foldWord = if line.Kind == "Workers" then line.Word else foldWord
					end
					t.Check("the smallest phone: the fold names its most-grown worker, or counts them", folded < 2 or foldWord == `{folded} workers`
						or (most ~= nil and foldWord == `{Collection.Name(most)} and {folded - 1} more`), foldWord)
					Layers.Box(nil)
					Layers.Force(nil)
					t.Check("back on this window, the whole card again", Helpers.waitFor(t, 1, matches), shown())
					-- Without a shard: Collect, and the press lets it go, on the server's word.
					t.Server("ReturnCardSet", { Kwh = 3 })
					t.Check("a card without a shard collects", Helpers.waitFor(t, ANSWER, function(): boolean
						local _, now = press()
						return now == "Collect" and #ReturnCard.Parts().Lines == 1
					end), select(2, press()))
					local button = press()
					t.Check("Collect lets it go, on the server's word", button ~= nil and Button.Press(button) and Helpers.waitFor(t, ANSWER, function(): boolean
						local now = ProfileController.Get()
						return not ReturnCard.Up() and now ~= nil and now.Base.Card == nil
					end))
				end)
				Layers.Box(nil)
				Layers.Force(nil)
				t.Server("ReturnCardSet", kept)
				if not ok then
					error(err, 0)
				end
			end,
		},
		-- The runner puts back the bays a case changed (SelfTestController, keepBays), in two cases that run in turn: the
		-- first swaps a worker in as the lead and back, which takes it out of its bay (Collection.SetLead), and leaves
		-- the bay so; the second finds the bay as it was.
		{
			Name = "Self-test: the bays a case changes are put back after it, 1: a worker made the lead and back leaves its bay",
			Place = "Main",
			Run = function(t: any)
				local workers = t.Server("Bays")
				local found: { string } = if type(workers) == "table" then table.clone(workers) else {}
				baysBefore = found
				local view = ProfileController.Get()
				local was = if view then view.Roles.Lead else ""
				local bay: number? = nil
				for index, worker in found do
					if worker ~= "" then
						bay = index
						break
					end
				end
				-- A save with every bay empty gets a free Voidkin into bay 1 first, so there's a worker to swap, and the
				-- runner empties it again.
				local worker = if bay then found[bay] else nil
				if bay == nil and #found > 0 then
					for id in (if view then view.Voidkin else {}) :: { [string]: any } do
						if id ~= was and not table.find(found, id) then
							local put = t.Server("Act", "SetWorker", { Bay = 1, Voidkin = id })
							if type(put) == "table" and put.Ok == true then
								bay, worker = 1, id
								break
							end
						end
					end
				end
				if not t.Check("a bay with a worker to swap", bay ~= nil and worker ~= nil, table.concat(found, ", ")) or bay == nil then
					return
				end
				local made = t.Server("Act", "SetLead", { Voidkin = worker })
				local now = t.Server("Bays")
				t.Check(`made the lead, it leaves bay {bay}`, type(made) == "table" and made.Ok == true and type(now) == "table" and now[bay] == "",
					if type(made) == "table" then tostring(made.Error) else tostring(made))
				local back = t.Server("Act", "SetLead", { Voidkin = was })
				local after = t.Server("Bays")
				t.Check("the old lead back, the bay still empty", type(back) == "table" and back.Ok == true and type(after) == "table" and after[bay] == "")
			end,
		},
		{
			Name = "Self-test: the bays a case changes are put back after it, 2: the bay worked again",
			Place = "Main",
			Run = function(t: any)
				local now = t.Server("Bays")
				local said = if type(now) == "table" then table.concat(now, ", ") else "no bays"
				t.Check("each bay as the case before found it", baysBefore ~= nil and type(now) == "table" and table.concat(baysBefore, ",") == table.concat(now, ","),
					`{said}, against {if baysBefore then table.concat(baysBefore, ", ") else "nothing read"}`)
				baysBefore = nil
			end,
		},
	}
end

return BaseCases
