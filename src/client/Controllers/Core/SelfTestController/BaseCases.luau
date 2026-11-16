--!strict
-- BaseCases (client, Studio only): the base's cases on its plot, a list of their own beside Cases, which joins it as it
-- joins PowerCases (Cases' one table had passed what the type solver checks in one piece). AR16's base as its save has
-- it: the bays awake and asleep, the battery's cells, the Void Mill's wheel, gauge and demand mark (AR19) and the
-- Training machine's crown; its machines' plates apart from the spawn; and the first session's shards opening themselves
-- on the plot (TR24's fix 5).

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
local BaseController = require(script.Parent.Parent.Parent.Main.BaseController)
local LightingController = require(script.Parent.Parent.Parent.Main.LightingController)
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
			Name = "Base: AR16's base as its save has it: the bays it opened awake and the rest asleep, the battery's cells by its level and lit by its charge, the mill's wheel, gauge and demand mark (AR19), the crown while a Voidkin trains, the Door's way in the festival's print",
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
				-- The Void Mill (AR19): its wheel carries the plant's generation and turns by it, its gauge's first steps
				-- shown as the generation lights them and the rest hidden, and the demand's mark turned about the axle to
				-- the demand's share, on one scale (Rules.Power.Gauge).
				local plant = Markers.Find("Generator", { Plot = plot })
				local wheel = if plant then plant:FindFirstChild("Wheel") else nil
				local mark = if plant then plant:FindFirstChild("Demand") else nil
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
					local found = plant
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
					t.Wait(mill.Gauge.Glide * 2)
					local share = mark:GetAttribute("Share")
					local angle = BaseController.TurnedOf(mark)
					t.Near("and turned there about the axle, once glided", angle or -1, math.rad(mill.Gauge.Turn) * (if type(share) == "number" then share else 0), math.rad(1))
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
				-- The Festival Door's way wears the festival seen through it, a print on the kit's atlas, tinted white so it keeps
				-- its colours (AR15, section 6).
				local door = Markers.Find("FestivalDoor", { Plot = plot })
				local way = if door then door:FindFirstChild("Light") else nil
				local tint = string.lower(string.sub(WorldConfig.Grey.Door.Light, 2))
				t.Check("the Door's way wears the festival's print, in Config's tint", way ~= nil and way:IsA("BasePart") and way:FindFirstChildOfClass("SurfaceAppearance") ~= nil
					and string.lower(way.Color:ToHex()) == tint and way.Transparency == WorldConfig.Grey.Door.LightFade,
					if way and way:IsA("BasePart") then `{way.Color:ToHex()} at {way.Transparency}` else "no way")
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
				local was = BaseController.SelfOpen(true)
				local ok, err = pcall(function()
					-- off the plot, in the Row: it breaks and waits
					local up = Vector3.new(0, 3.6, 0)
					t.Server("TestStandAt", Vector3.new(0, 0, gateZ - 60) + up, Vector3.new(0, 0, gateZ - 70) + up)
					t.Wait(0.5)
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
	}
end

return BaseCases
