--!strict
-- LightingController (client): the world's look (TR8; the director, 2026-11-12: "we should add a night cycle for this
-- festival area as well"; 2026-11-16: "we need a day time", TR23). North of the festival gate, from Config.Lighting.From
-- studs short of it, and over the base too while Config.Lighting.Everywhere, the ground's look holds: its day, its dusk
-- and its night on the server's one clock (Rules.Night; the epoch is the workspace attribute NightFrom), each eased
-- into the next through a minute's crossing. Everywhere else the place keeps its own Lighting, as this client found it at its
-- start. Walking in or out turns one look into the other over Enter seconds; a jump (a door, a fade, a respawn) lands
-- in its look at once. Where the player stands is the camera's focus: the avatar, or the lead while spectating. The
-- camera itself is never touched.
-- * A sky can't fade into another (handbook/visuals/lighting-and-mood.md, "Skies"): each blend swaps its sky at its
--   middle, under a peak of haze (Config.Lighting.Veil; south of the Row, Clear.Veil's Haze alone), and all the ground's
--   skies are loaded before they're needed. A phase with no faces wears Roblox's built-in sky (a new Sky's own), with its
--   Bodies (the day's sun disc). A crossing's light warms from its first second, Config.Lighting.Warm of the way there
--   by the swap (TR24's fix 9).
-- * No mist over the base and the map round it (the director, 2026-11-16, 16:50), and bright hours there (AR20's C):
--   south of the Row's From line the phase's Atmosphere wears Config.Lighting.Clear's, its light, fill and exposure
--   Clear.Phases', and the kit's glow Clear.Glow times its own, eased over Enter seconds on the walk up the side street.
-- * The sun stands where the kit's frames have it (Config.Lighting.Toward) at a day clock, solved once for this engine's
--   sun (Lighting:GetSunDirection()), so the painted moon and the shadows agree.
-- * The kit's pieces (tagged Kit.Tag by WorldService) glow by Config.Lighting.Glow, the houses less, the floors by the
--   phase, all by the phase's Glow share (by day a share, full from dusk); the street's lights shine by
--   Config.Lighting.Pools and Lamp, by the phase's Lights share; the paper's boxes stand in Config.Lighting.Paper's
--   band with its rate and tint (Kit.PaperBand). Each piece streamed in takes its value at once.
-- * The player's lead carries the plan's tenth light at its head (Config.Lighting.Lead), turned up with the ground's look
--   and the phase's Lights share, and off out of it.
-- Every number is read from Config each frame, so a Tune shows at once (a new Toward is solved again).
--   LightingController.Look()   what's applied: the look, how far into the ground (Area) and into the Row (Row, 0 out in
--                               the clear), the turn (From, To, Turn: 0 at From to 1 at To, Phase; Warm, how far its
--                               light has come), the shares (Glow, Lights) and the haze's peak (Veil), for tests
--   LightingController.Sun()    the solved sun: { Clock, Latitude, Off } (Off: degrees from Toward), for tests
--   LightingController.LeadLight()  the lead's light, or nil with no lead, for tests

local CollectionService = game:GetService("CollectionService")
local ContentProvider = game:GetService("ContentProvider")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Shared
local LightingConfig = require(Shared.Config.Lighting)
local Night = require(Shared.Rules.Night)
local Kit = require(Shared.World.Kit)
local Plan: Kit.Plan = require(Shared.Config.Kits.LanternRow.Plan) :: any -- the kit Lantern Row wears (WorldService's DRESS)
local Parts = require(Shared.Util.Parts)

local LightingController = {}

local WORLD = "World"
local JUMP = 40 -- studs the focus moves in one frame that make a jump, not a walk: the look lands at once
local LIGHTING_KEYS = { "Ambient", "OutdoorAmbient", "Brightness", "ColorShift_Top", "EnvironmentDiffuseScale", "ExposureCompensation", "ClockTime", "GeographicLatitude" }
local ATMOSPHERE_KEYS = { "Density", "Offset", "Haze", "Glare", "Color", "Decay" }
local BLOOM_KEYS = { "Intensity", "Size", "Threshold" }

local base: any = nil -- the place's own look, captured at the start
local atmosphere: Atmosphere
local bloom: BloomEffect
local skies: { [string]: Sky? } = {} -- "Base" (the place's, if it has one), and one per phase of the cycle
local shownSky = "Base"
local sun = { Clock = 14, Latitude = 0, Off = 180 }
local solvedFor: Vector3? = nil
local area = 0 -- 0 out of the ground, 1 in it, eased by the walk
local row = 0 -- 0 south of the Row's line (the base, the Strip, the crossing: no mist), 1 in the Row, eased by the walk
local lastFocus: Vector3? = nil
local applied: any = nil -- the last look applied, for tests and to set only what changed
local current = { Area = 0, Row = 0, From = "Day", To = "Day", Turn = 0, Warm = 0, Phase = "Day", Glow = 1, Steady = 1, Lights = 1, Veil = 0 }
local SHARE_STEP = 0.02 -- the glow's and the lights' shares move in steps: a crossing re-dresses the pieces ~30 times, not each frame
local glowShare, lightShare = 1, 1
local steadyShare = 1 -- the phase's share of the glow alone, without Clear's lift: a steady piece's (Config.Lighting.Steady)
local coreMost = math.huge -- a core's most glow, under the bloom applied (Config.Lighting's CoreBloom), in the shares' steps
local floors: { [BasePart]: true } = {}
local stamp = "" -- the glow and light numbers last given to the pieces
local leadLight: PointLight? = nil

local function ease(x: number): number
	local t = math.clamp(x, 0, 1)
	return t * t * (3 - 2 * t)
end

local function capture(instance: Instance, keys: { string }): { [string]: any }
	local out = {}
	for _, key in keys do
		out[key] = (instance :: any)[key]
	end
	return out
end

-- The place's own Atmosphere and Bloom, or new ones that change nothing until the ground's look needs them.
local function own(class: string, idle: { [string]: any }): (Instance, { [string]: any })
	local found = Lighting:FindFirstChildOfClass(class :: any)
	if found then
		return found, capture(found, if class == "Atmosphere" then ATMOSPHERE_KEYS else BLOOM_KEYS)
	end
	local made = Instance.new(class :: any)
	for key, value in idle do
		(made :: any)[key] = value
	end
	made.Parent = Lighting
	return made, idle
end

-- Finds the clock and the latitude that stand this engine's sun nearest `toward`, coarse to fine; puts Lighting back.
local function solve(toward: Vector3)
	local before = { ClockTime = Lighting.ClockTime, GeographicLatitude = Lighting.GeographicLatitude }
	local want = toward.Unit
	local best = { Clock = 12, Latitude = 0, Dot = -2 }
	local function try(clock: number, latitude: number)
		Lighting.ClockTime = clock
		Lighting.GeographicLatitude = latitude
		local dot = Lighting:GetSunDirection():Dot(want)
		if dot > best.Dot then
			best = { Clock = clock, Latitude = latitude, Dot = dot }
		end
	end
	-- A day clock only (the handbook's pseudo-night): from 6 to 18.
	for clock = 6, 18, 0.5 do
		for latitude = -90, 90, 5 do
			try(clock, latitude)
		end
	end
	for _, step in { { 0.05, 0.5 }, { 0.005, 0.05 } } do
		local clock0, latitude0 = best.Clock, best.Latitude
		for i = -10, 10 do
			for j = -10, 10 do
				try(math.clamp(clock0 + i * step[1], 6, 18), math.clamp(latitude0 + j * step[2], -90, 90))
			end
		end
	end
	Lighting.ClockTime = before.ClockTime
	Lighting.GeographicLatitude = before.GeographicLatitude
	sun = { Clock = best.Clock, Latitude = best.Latitude, Off = math.deg(math.acos(math.clamp(best.Dot, -1, 1))) }
	solvedFor = toward
end

local function setSkyFaces(sky: Sky, phase: any)
	for face, id in phase.Sky or {} do -- none: the built-in faces a new Sky has
		local key = `Skybox{face}`
		if (sky :: any)[key] ~= id then
			(sky :: any)[key] = id
		end
	end
	for _, bodies in { LightingConfig.SkyBodies :: any, phase.Bodies or {} } do
		for key, value in bodies do
			if (sky :: any)[key] ~= value then
				(sky :: any)[key] = value
			end
		end
	end
end

local function groundSky(name: string, phase: any): Sky
	local sky = Instance.new("Sky")
	sky.Name = if string.sub(name, 1, 5) == "Clear" then `Base{string.sub(name, 6)}` else `LanternRow{name}`
	setSkyFaces(sky, phase)
	return sky
end

-- Every sky by its name: each phase's (the Row's), and each phase's own south of the Row (Night.SkyOf: Clear<name>).
local function skyLooks(): { [string]: any }
	local out: { [string]: any } = {}
	for name, look in LightingConfig.Phases :: any do
		out[name] = look
	end
	for name, look in LightingConfig.Clear.Phases :: any do
		if look.Sky then
			out[`Clear{name}`] = look
		end
	end
	return out
end

local function showSky(name: string)
	for key, look in skyLooks() do
		local sky = skies[key]
		if sky then
			setSkyFaces(sky, look)
		end
	end
	if name == shownSky then
		return
	end
	for key, sky in skies do
		if sky and key ~= name then
			sky.Parent = nil
		end
	end
	local sky = skies[name]
	if sky then
		sky.Parent = Lighting
	end
	shownSky = name
end

-- The ground's z line: the festival gate's, on the world's folder (its markers stream out; the folder doesn't).
local function gateZ(): number?
	local world = workspace:FindFirstChild(WORLD)
	local z = if world then world:GetAttribute("GateZ") else nil
	return if type(z) == "number" then z else nil
end

-- A piece's glow, a light's brightness and range, from Config.
local function glowOf(piece: string, floor: number): number
	if Kit.Floors[piece] then
		return floor
	end
	return if LightingConfig.Houses[piece] then LightingConfig.Glow.Houses else LightingConfig.Glow.Kit
end

local function floorNow(): number
	local dusk = LightingConfig.Phases.Dusk.Floor
	return if applied then applied.Floor or dusk else dusk
end

-- A piece whose glow follows its state, set by the server, watched once: a Breaker's chamber by "Working" (AR15), a
-- battery cell by "Lit", 0 to 1, low while dark and full while lit (AR15, section 4).
local watched: { [Instance]: true } = setmetatable({}, { __mode = "k" }) :: any

local function dressOne(item: Instance, floor: number)
	local piece = item:GetAttribute("Piece")
	if type(piece) == "string" then
		local look = item:FindFirstChildOfClass("SurfaceAppearance")
		local working, lit = item:GetAttribute("Working"), item:GetAttribute("Lit")
		if (working ~= nil or lit ~= nil) and not watched[item] then
			watched[item] = true
			local function again()
				dressOne(item, floorNow())
			end
			item:GetAttributeChangedSignal("Working"):Connect(again)
			item:GetAttributeChangedSignal("Lit"):Connect(again)
		end
		if look then
			local empty = LightingConfig.Glow.Empty
			local share = if working == false then empty elseif type(lit) == "number" then empty + (1 - empty) * math.clamp(lit, 0, 1) else 1
			local steady = LightingConfig.Steady[piece]
			local full = if steady then steady * steadyShare else glowOf(piece, floor) * glowShare
			local want = (if LightingConfig.Cores[piece] then math.min(full, coreMost) else full) * share
			if look.EmissiveStrength ~= want then
				look.EmissiveStrength = want
			end
		end
		if Kit.Floors[piece] and item:IsA("BasePart") then
			floors[item] = true
		end
		return
	end
	-- A box of the paper's air: the band, its rate and its tint, set here only, so a Tune shows at once.
	local index = item:GetAttribute("Paper")
	if type(index) == "number" then
		local paper = Plan.paper
		local box = if paper then paper.boxes[index] else nil
		local floorY, z = item:GetAttribute("FloorY"), gateZ()
		local emitter = item:FindFirstChildOfClass("ParticleEmitter")
		if paper and box and type(floorY) == "number" and z and emitter and item:IsA("BasePart") then
			local band = LightingConfig.Paper
			local _, tall, share = Kit.PaperBand(box, band)
			item.Size = Vector3.new(box.size[1], tall, box.size[3])
			item.CFrame = Kit.Paper(box, z, floorY, band)
			emitter.Rate = paper.emitter.Rate * share
			emitter.Color = ColorSequence.new(band.Colour)
		end
		return
	end
	local kind = item:GetAttribute("Light")
	local numbers = if kind == "Pool" then LightingConfig.Pools elseif kind == "Lamp" then LightingConfig.Lamp else nil
	local light = item:FindFirstChildWhichIsA("Light")
	if numbers and light then
		light.Brightness = numbers.Brightness * lightShare;
		(light :: any).Range = numbers.Range
	end
end

local function dressAll(floor: number)
	local glow, pools, lamp, paper = LightingConfig.Glow, LightingConfig.Pools, LightingConfig.Lamp, LightingConfig.Paper
	local now = `{glow.Kit},{glow.Houses},{glow.Empty},{coreMost},{pools.Brightness},{pools.Range},{lamp.Brightness},{lamp.Range},{paper.Floor},{paper.Top},{paper.Colour},{glowShare},{lightShare},{steadyShare}`
	if now ~= stamp then
		stamp = now
		for _, item in CollectionService:GetTagged(Kit.Tag) do
			dressOne(item, floor)
		end
		return
	end
	-- Only the floors follow the turn frame by frame (the shares by their steps, above).
	for part in floors do
		if part.Parent == nil then
			floors[part] = nil
			continue
		end
		local look = part:FindFirstChildOfClass("SurfaceAppearance")
		local want = floor * glowShare
		if look and look.EmissiveStrength ~= want then
			look.EmissiveStrength = want
		end
	end
end

-- The player's own lead, standing in the world's fighters (as SpectateController finds it).
local function myLead(): Model?
	local folder = workspace:FindFirstChild("Fighters")
	for _, model in (if folder then folder:GetChildren() else {}) do
		if model:IsA("Model") and model:GetAttribute("Side") == "Lead" and model:GetAttribute("Owner") == Players.LocalPlayer.UserId then
			return model
		end
	end
	return nil
end

-- The lead's light, `share` of its brightness: at its head, or its root.
local function lightLead(share: number)
	local lead = myLead()
	local at = if lead then (lead:FindFirstChild("Head") or Parts.Root(lead)) else nil
	if at == nil or not at:IsA("BasePart") then
		if leadLight then
			leadLight:Destroy()
			leadLight = nil
		end
		return
	end
	local light = leadLight
	if light == nil or light.Parent ~= at then
		if light then
			light:Destroy()
		end
		local made = Instance.new("PointLight")
		made.Name = "GA_LeadLight"
		made.Shadows = false
		made.Parent = at
		light = made
		leadLight = made
	end
	local numbers = LightingConfig.Lead
	local on = light :: PointLight
	on.Enabled = share > 0
	on.Color = numbers.Colour
	on.Range = numbers.Range
	on.Brightness = numbers.Brightness * share
end

local function setKeys(instance: Instance, values: { [string]: any }, last: { [string]: any }?)
	for key, value in values do
		if last == nil or last[key] ~= value then
			(instance :: any)[key] = value
		end
	end
end

local function step(dt: number)
	if solvedFor ~= LightingConfig.Toward then
		solve(LightingConfig.Toward)
	end
	-- Where the player stands, and how far into the ground.
	local camera = workspace.CurrentCamera
	local focus = if camera then camera.Focus.Position else nil
	local z = gateZ()
	local inRow = focus ~= nil and z ~= nil and Night.Inside(focus.Z, z, LightingConfig.From)
	local target = if LightingConfig.Everywhere or inRow then 1 else 0
	local jumped = focus == nil or lastFocus == nil or (focus - (lastFocus :: Vector3)).Magnitude > JUMP
	lastFocus = focus
	local function toward(now: number, want: number): number
		if jumped or LightingConfig.Enter <= 0 then
			return want
		end
		return if want > now then math.min(want, now + dt / LightingConfig.Enter) else math.max(want, now - dt / LightingConfig.Enter)
	end
	area = toward(area, target)
	row = toward(row, if inRow then 1 else 0)
	local a = ease(area)
	local mist = ease(row)
	-- The turn, on the server's clock.
	local from = workspace:GetAttribute(Night.Attribute)
	local seconds = workspace:GetServerTimeNow() - (if type(from) == "number" then from else 0)
	local fromName, toName, turn, phase, into = Night.Turn(seconds, LightingConfig.Cycle :: any)
	local phases = LightingConfig.Phases :: any
	local at = { Clock = sun.Clock, Latitude = sun.Latitude }
	-- The light, the haze and the glow warm from the crossing's first second (TR24's fix 9); the sky still swaps at its
	-- middle, under the veil's peak.
	local warm = if fromName == toName then 0 else Night.Warm(into, LightingConfig.Warm)
	-- South of the Row, no mist (the director's 16:50) and bright hours (AR20's C): Clear's over each phase's own, as far
	-- as the walk has come out of the Row.
	local clear = LightingConfig.Clear
	local out = 1 - mist
	local function phaseOf(name: string): any
		local over = (clear.Phases :: any)[name]
		return if over then Night.Clear(phases[name], over, out) else phases[name]
	end
	local ground = Night.Mix(Night.Ground(phaseOf(fromName), fromName, at), Night.Ground(phaseOf(toName), toName, at), warm)
	local shownPhase = if turn < 0.5 then fromName else toName
	ground.Sky = Night.SkyOf(shownPhase, clear.Phases :: any, out)
	ground.Atmosphere = Night.Clear(ground.Atmosphere, clear.Atmosphere :: any, out)
	local look = Night.Mix(base, ground, a)
	glowShare = math.floor(ground.Glow * (1 + (clear.Glow - 1) * out) / SHARE_STEP + 0.5) * SHARE_STEP
	steadyShare = math.floor(ground.Glow / SHARE_STEP + 0.5) * SHARE_STEP
	lightShare = math.floor(ground.Lights * (1 + (clear.Lights - 1) * out) / SHARE_STEP + 0.5) * SHARE_STEP
	coreMost = math.floor(look.Bloom.Threshold * LightingConfig.Glow.CoreBloom / SHARE_STEP + 0.5) * SHARE_STEP
	-- The haze's peak where a sky is swapped: the turn's, inside, and the walk's own, into the ground and up or down the
	-- side street when the base's sky differs from the Row's. In the Row its haze and density; south of it Haze alone,
	-- which veils the sky and leaves the yard clear.
	local width = LightingConfig.Veil.Width
	local walkVeil = if Night.SkyOf(shownPhase, clear.Phases :: any, 1) ~= shownPhase then Night.Veil(mist, width) else 0
	local veil = math.max(Night.Veil(turn, width) * a, Night.Veil(a, width), walkVeil)
	look.Atmosphere.Density += (clear.Veil.Density + (LightingConfig.Veil.Density - clear.Veil.Density) * mist) * veil
	look.Atmosphere.Haze += (clear.Veil.Haze + (LightingConfig.Veil.Haze - clear.Veil.Haze) * mist) * veil
	-- Applied, only what changed.
	setKeys(Lighting, look.Lighting, applied and applied.Lighting)
	setKeys(atmosphere, look.Atmosphere, applied and applied.Atmosphere)
	setKeys(bloom, look.Bloom, applied and applied.Bloom)
	showSky(look.Sky)
	dressAll(ground.Floor)
	lightLead(a * lightShare)
	applied = look
	current = { Area = area, Row = row, From = fromName, To = toName, Turn = turn, Warm = warm, Phase = phase, Glow = glowShare, Steady = steadyShare, Lights = lightShare, CoreMost = coreMost, Veil = veil }
end

function LightingController.Start()
	base = {
		Lighting = capture(Lighting, LIGHTING_KEYS),
		Sky = "Base",
	}
	local dusk = LightingConfig.Phases.Dusk
	local a, atmosphereBase = own("Atmosphere", {
		Density = 0,
		Offset = 0,
		Haze = 0,
		Glare = 0,
		Color = dusk.Atmosphere.Color,
		Decay = dusk.Atmosphere.Decay,
	})
	local b, bloomBase = own("BloomEffect", { Intensity = 0, Size = dusk.Bloom.Size, Threshold = dusk.Bloom.Threshold })
	atmosphere, bloom = a :: Atmosphere, b :: BloomEffect
	base.Atmosphere, base.Bloom = atmosphereBase, bloomBase
	skies.Base = Lighting:FindFirstChildOfClass("Sky")
	local load: { Instance } = {}
	for name, phase in skyLooks() do
		local sky = groundSky(name, phase)
		skies[name] = sky
		table.insert(load, sky)
	end
	task.spawn(function()
		ContentProvider:PreloadAsync(load)
	end)
	CollectionService:GetInstanceAddedSignal(Kit.Tag):Connect(function(item: Instance)
		dressOne(item, floorNow())
	end)
	RunService:BindToRenderStep("GA_Lighting", Enum.RenderPriority.Camera.Value + 1, step)
end

function LightingController.Look(): any
	local out = table.clone(current) :: any
	out.Look = applied
	return out
end

-- The lead's light as it shines now, or nil with no lead standing, for tests.
function LightingController.LeadLight(): PointLight?
	return leadLight
end

function LightingController.Sun(): { Clock: number, Latitude: number, Off: number }
	return table.clone(sun)
end

return LightingController
