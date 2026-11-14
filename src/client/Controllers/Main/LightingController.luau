--!strict
-- LightingController (client): Lantern Row's look (TR8; the director, 2026-11-12: "we should add a night cycle for this
-- festival area as well"). North of the festival gate, from Config.Lighting.From studs short of it, the ground's look
-- holds: its dusk and its night on the server's one clock (Rules.Night; the epoch is the workspace attribute NightFrom),
-- eased through a minute's crossing. Everywhere else the place keeps its own Lighting, as this client found it at its
-- start. Walking in or out turns one look into the other over Enter seconds; a jump (a door, a fade, a respawn) lands
-- in its look at once. Where the player stands is the camera's focus: the avatar, or the lead while spectating. The
-- camera itself is never touched.
-- * A sky can't fade into another (handbook/visuals/lighting-and-mood.md, "Skies"): each blend swaps its sky at its
--   middle, under a peak of haze (Config.Lighting.Veil), and both of the ground's skies are loaded before they're needed.
-- * The sun stands where the kit's frames have it (Config.Lighting.Toward) at a day clock, solved once for this engine's
--   sun (Lighting:GetSunDirection()), so the painted moon and the shadows agree.
-- * The kit's pieces (tagged Kit.Tag by WorldService) glow by Config.Lighting.Glow, the houses less, the floors by the
--   phase; the street's lights shine by Config.Lighting.Pools and Lamp. Each piece streamed in takes its value at once.
-- * The player's lead carries the plan's tenth light at its head (Config.Lighting.Lead), turned up with the ground's look
--   and off out of it.
-- Every number is read from Config each frame, so a Tune shows at once (a new Toward is solved again).
--   LightingController.Look()   what's applied: the look, how far into the ground (Area), the turn (Night, Phase) and the
--                               haze's peak (Veil), for tests
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
local Parts = require(Shared.Util.Parts)

local LightingController = {}

local WORLD = "World"
local JUMP = 40 -- studs the focus moves in one frame that make a jump, not a walk: the look lands at once
local LIGHTING_KEYS = { "Ambient", "OutdoorAmbient", "Brightness", "ColorShift_Top", "EnvironmentDiffuseScale", "ClockTime", "GeographicLatitude" }
local ATMOSPHERE_KEYS = { "Density", "Offset", "Haze", "Glare", "Color", "Decay" }
local BLOOM_KEYS = { "Intensity", "Size", "Threshold" }

local base: any = nil -- the place's own look, captured at the start
local atmosphere: Atmosphere
local bloom: BloomEffect
local skies: { [string]: Sky? } = {} -- "Base" (the place's, if it has one), "Dusk", "Night"
local shownSky = "Base"
local sun = { Clock = 14, Latitude = 0, Off = 180 }
local solvedFor: Vector3? = nil
local area = 0 -- 0 out of the ground, 1 in it, eased by the walk
local lastFocus: Vector3? = nil
local applied: any = nil -- the last look applied, for tests and to set only what changed
local current = { Area = 0, Night = 0, Phase = "Dusk", Veil = 0 }
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
	for face, id in phase.Sky do
		local key = `Skybox{face}`
		if (sky :: any)[key] ~= id then
			(sky :: any)[key] = id
		end
	end
	for key, value in LightingConfig.SkyBodies :: any do
		if (sky :: any)[key] ~= value then
			(sky :: any)[key] = value
		end
	end
end

local function groundSky(name: string): Sky
	local sky = Instance.new("Sky")
	sky.Name = `LanternRow{name}`
	setSkyFaces(sky, (LightingConfig.Phases :: any)[name])
	return sky
end

local function showSky(name: string)
	for _, phase in { "Dusk", "Night" } do
		setSkyFaces(skies[phase] :: Sky, (LightingConfig.Phases :: any)[phase])
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

local function dressOne(item: Instance, floor: number)
	local piece = item:GetAttribute("Piece")
	if type(piece) == "string" then
		local look = item:FindFirstChildOfClass("SurfaceAppearance")
		if look then
			local want = glowOf(piece, floor)
			if look.EmissiveStrength ~= want then
				look.EmissiveStrength = want
			end
		end
		if Kit.Floors[piece] and item:IsA("BasePart") then
			floors[item] = true
		end
		return
	end
	local kind = item:GetAttribute("Light")
	local numbers = if kind == "Pool" then LightingConfig.Pools elseif kind == "Lamp" then LightingConfig.Lamp else nil
	local light = item:FindFirstChildWhichIsA("Light")
	if numbers and light then
		light.Brightness = numbers.Brightness;
		(light :: any).Range = numbers.Range
	end
end

local function dressAll(floor: number)
	local glow, pools, lamp = LightingConfig.Glow, LightingConfig.Pools, LightingConfig.Lamp
	local now = `{glow.Kit},{glow.Houses},{pools.Brightness},{pools.Range},{lamp.Brightness},{lamp.Range}`
	if now ~= stamp then
		stamp = now
		for _, item in CollectionService:GetTagged(Kit.Tag) do
			dressOne(item, floor)
		end
		return
	end
	-- Only the floors follow the turn.
	for part in floors do
		if part.Parent == nil then
			floors[part] = nil
			continue
		end
		local look = part:FindFirstChildOfClass("SurfaceAppearance")
		if look and look.EmissiveStrength ~= floor then
			look.EmissiveStrength = floor
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
	local inside = focus ~= nil and z ~= nil and Night.Inside(focus.Z, z, LightingConfig.From)
	local target = if inside then 1 else 0
	local jumped = focus == nil or lastFocus == nil or (focus - (lastFocus :: Vector3)).Magnitude > JUMP
	lastFocus = focus
	if jumped or LightingConfig.Enter <= 0 then
		area = target
	else
		area = if target > area then math.min(target, area + dt / LightingConfig.Enter) else math.max(target, area - dt / LightingConfig.Enter)
	end
	local a = ease(area)
	-- The turn, on the server's clock.
	local from = workspace:GetAttribute(Night.Attribute)
	local seconds = workspace:GetServerTimeNow() - (if type(from) == "number" then from else 0)
	local night, phase = Night.At(seconds, LightingConfig.Cycle)
	local phases = LightingConfig.Phases :: any
	local at = { Clock = sun.Clock, Latitude = sun.Latitude }
	local ground = Night.Mix(Night.Ground(phases.Dusk, "Dusk", at), Night.Ground(phases.Night, "Night", at), night)
	local look = Night.Mix(base, ground, a)
	-- The haze's peak where a sky is swapped: the turn's, inside, and the walk's own.
	local width = LightingConfig.Veil.Width
	local veil = math.max(Night.Veil(night, width) * a, Night.Veil(a, width))
	look.Atmosphere.Density += LightingConfig.Veil.Density * veil
	look.Atmosphere.Haze += LightingConfig.Veil.Haze * veil
	-- Applied, only what changed.
	setKeys(Lighting, look.Lighting, applied and applied.Lighting)
	setKeys(atmosphere, look.Atmosphere, applied and applied.Atmosphere)
	setKeys(bloom, look.Bloom, applied and applied.Bloom)
	showSky(look.Sky)
	dressAll(ground.Floor)
	lightLead(a)
	applied = look
	current = { Area = area, Night = night, Phase = phase, Veil = veil }
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
	skies.Dusk, skies.Night = groundSky("Dusk"), groundSky("Night")
	task.spawn(function()
		ContentProvider:PreloadAsync({ skies.Dusk :: Sky, skies.Night :: Sky })
	end)
	CollectionService:GetInstanceAddedSignal(Kit.Tag):Connect(function(item: Instance)
		dressOne(item, if applied then applied.Floor or LightingConfig.Phases.Dusk.Floor else LightingConfig.Phases.Dusk.Floor)
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
