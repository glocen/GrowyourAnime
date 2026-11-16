--!strict
-- Night cases (pure): the world's day, dusk and night on one server clock (TR8; the director, 2026-11-12 and 2026-11-16,
-- TR23; Rules.Night, Config.Lighting). A turn holds each look and crosses into the next, day the most of it; the crossing
-- eases; the sky's swap hides under the haze's peak; a look mixes key by key; the ground's look holds from just before
-- its gate, a door's landing inside it.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Night = require(Shared.Rules.Night)
local LightingConfig = require(Shared.Config.Lighting)
local WorldConfig = require(Shared.Config.World)

local CYCLE: Night.Cycle = { Order = { "Day", "Dusk", "Night" }, Hold = { Day = 1080, Dusk = 300, Night = 240 }, Cross = 60 }
local NOW = 1_800_000_000

local function near(a: number, b: number): boolean
	return math.abs(a - b) <= 1e-6 * math.max(1, math.abs(b))
end

-- The turn at `seconds`: (from, to, w, phase).
local function at(seconds: number): (string, string, number, string)
	local from, to, w, phase = Night.Turn(seconds, CYCLE)
	return from, to, w, phase
end

-- How far into night the turn stands, 0 to 1, on the way from dusk and back to day.
local function w(seconds: number): number
	local _, _, weight = at(seconds)
	return weight
end

return {
	{
		Name = "Night: TR23, a turn is 18 minutes of day, a minute's crossing, 5 of dusk, a minute, 4 of night and a minute's dawn, on the server's clock",
		Run = function(t: any)
			t.Equal("the builder's seed: 30 minutes", Night.Length(LightingConfig.Cycle :: any), 1800)
			t.Equal("the seed in Config", Night.Length(CYCLE), Night.Length(LightingConfig.Cycle :: any))
			t.Check("day the most of the turn, about 60%", (LightingConfig.Cycle.Hold.Day :: number) / Night.Length(LightingConfig.Cycle :: any) >= 0.55)
			t.Equal("the phases in order", table.concat(Night.Phases(CYCLE), " "), "Day ToDusk Dusk ToNight Night ToDay")
			local from, to, weight, phase = at(0)
			t.Check("it starts in the day", from == "Day" and to == "Day" and weight == 0 and phase == "Day", `{from} {to} {weight} {phase}`)
			from, to, weight, phase = at(1079.9)
			t.Check("day to its last moment", from == "Day" and phase == "Day")
			from, to, weight, phase = at(1110)
			t.Check("half way to dusk", from == "Day" and to == "Dusk" and near(weight, 0.5) and phase == "ToDusk", `{from} {to} {weight} {phase}`)
			from, to, weight, phase = at(1140)
			t.Check("dusk", from == "Dusk" and to == "Dusk" and weight == 0 and phase == "Dusk", `{from} {to} {weight} {phase}`)
			from, to, weight, phase = at(1470)
			t.Check("half way to night", from == "Dusk" and to == "Night" and near(weight, 0.5) and phase == "ToNight", `{from} {to} {weight} {phase}`)
			from, to, weight, phase = at(1500)
			t.Equal("night", phase, "Night")
			from, to, weight, phase = at(1770)
			t.Check("half way through the dawn", from == "Night" and to == "Day" and near(weight, 0.5) and phase == "ToDay", `{from} {to} {weight} {phase}`)
			from, to, weight, phase = at(1800)
			t.Equal("round to day again", phase, "Day")
			from, to, weight, phase = at(-30)
			t.Check("before the epoch, the turn runs on", from == "Night" and to == "Day" and near(weight, 0.5), `{from} {to} {weight} {phase}`)
			from, to, weight, phase = at(0 / 0)
			t.Check("no clock: day", weight == 0 and phase == "Day")
			t.Equal("day's 18 minutes left at its start", Night.Left(0, CYCLE), 1080)
			t.Equal("40 s of the crossing to dusk left", Night.Left(1100, CYCLE), 40)
			t.Equal("night's 4 minutes", Night.Left(1500, CYCLE), 240)
			-- A look held for no time is passed over: the turn crosses straight on.
			local short: Night.Cycle = { Order = { "Day", "Dusk", "Night" }, Hold = { Day = 100, Night = 100 }, Cross = 10 }
			t.Equal("no dusk held: the crossing to it, then on to night", select(4, Night.Turn(115, short)), "ToNight")
		end,
	},
	{
		Name = "Night: TR23, a jump to a phase puts the server's clock at its start, for the takes",
		Run = function(t: any)
			for _, phase in Night.Phases(CYCLE) do
				local epoch = Night.From(phase, NOW, CYCLE)
				local _, _, _, got = at(NOW - epoch)
				t.Equal(`{phase}: there`, got, phase)
				local _, _, _, before = at(NOW - epoch - 0.01)
				t.Check(`{phase}: at its start`, before ~= phase)
			end
			t.Equal("night's 4 minutes ahead", Night.Left(NOW - Night.From("Night", NOW, CYCLE), CYCLE), 240)
			t.Check("no such phase", not pcall(Night.From, "Noon", NOW, CYCLE))
			for _, name in LightingConfig.Cycle.Order do
				t.Check(`{name}: a look in Config`, (LightingConfig.Phases :: any)[name] ~= nil)
			end
			for name in LightingConfig.Phases :: any do
				t.Check(`{name}: in the turn`, table.find(LightingConfig.Cycle.Order, name) ~= nil)
			end
		end,
	},
	{
		Name = "Night: TR8, each crossing eases from one look to the next, and the sky's swap hides under the haze's peak",
		Run = function(t: any)
			for name, start in ({ ToDusk = 1080, ToNight = 1440, ToDay = 1740 } :: { [string]: number }) do
				local last, rising = -1, true
				for s = start, start + 59, 1 do
					local weight = w(s)
					rising = rising and weight >= last
					last = weight
				end
				t.Check(`{name}: never back`, rising)
				t.Check(`{name}: eased, slow at its ends`, w(start + 3) < 0.05 and w(start + 57) > 0.95)
			end
			local width = LightingConfig.Veil.Width
			t.Equal("the peak at the middle", Night.Veil(0.5, width), 1)
			t.Equal("nothing at its edge", Night.Veil(0.5 + width / 2, width), 0)
			t.Equal("nothing while a look holds", Night.Veil(0, width), 0)
			t.Equal("nothing at the crossing's end", Night.Veil(1, width), 0)
			t.Check("half way up, between", Night.Veil(0.5 - width / 4, width) > 0 and Night.Veil(0.5 - width / 4, width) < 1)
			t.Equal("no width, no veil", Night.Veil(0.5, 0), 0)
		end,
	},
	{
		Name = "Night: TR8, a look mixes key by key: numbers, colours and vectors blend, and the sky is one or the other",
		Run = function(t: any)
			local a = { N = 0, C = Color3.new(0, 0, 0), V = Vector3.zero, Sky = "Dusk", In = { D = 0.2 } }
			local b = { N = 10, C = Color3.new(1, 1, 1), V = Vector3.one, Sky = "Night", In = { D = 0.4 } }
			local mid = Night.Mix(a, b, 0.25)
			t.Check("a number", near(mid.N, 2.5))
			t.Check("a colour", near(mid.C.R, 0.25))
			t.Check("a vector", near(mid.V.X, 0.25))
			t.Check("inside a table", near(mid.In.D, 0.25))
			t.Equal("the sky below the middle", mid.Sky, "Dusk")
			t.Equal("and from it", Night.Mix(a, b, 0.5).Sky, "Night")
			t.Equal("none from one side: the other's", Night.Mix({ X = 1 }, {}, 0.7).X, 1)
			-- A phase as Lighting holds it.
			local dusk = LightingConfig.Phases.Dusk
			local look = Night.Ground(dusk, "Dusk", { Clock = 13.5, Latitude = 20 })
			t.Check("one flat fill, both ambients", look.Lighting.Ambient == dusk.Ambient and look.Lighting.OutdoorAmbient == dusk.Ambient)
			t.Equal("the sun's colour on the faces turned to it", look.Lighting.ColorShift_Top, dusk.Sun)
			t.Equal("the sun where the frames have it", look.Lighting.ClockTime, 13.5)
			t.Equal("the sky by name", look.Sky, "Dusk")
			t.Equal("the floors' glow", look.Floor, dusk.Floor)
			t.Equal("dusk's glow whole", look.Glow, 1)
			t.Equal("dusk's lights whole", look.Lights, 1)
			local day = (LightingConfig.Phases :: any).Day
			local bright = Night.Ground(day, "Day", { Clock = 13.5, Latitude = 20 })
			t.Check("by day the glow and the lights at a share", bright.Glow == day.Glow and bright.Lights == day.Lights
				and day.Glow < 1 and day.Lights < 1, `{bright.Glow} {bright.Lights}`)
			look.Atmosphere.Density = 99
			t.Check("a look is its own copy", dusk.Atmosphere.Density ~= 99)
		end,
	},
	{
		Name = "Night: TR8, TR23, the ground's phases are whole, and its look holds from just before the gate, a door's landing inside it",
		Run = function(t: any)
			local phases = LightingConfig.Phases :: any
			for name, phase in phases do
				for _, key in { "Sun", "Brightness", "Ambient", "Diffuse", "Atmosphere", "Bloom", "Floor" } do
					t.Check(`{name} {key}: given, of dusk's kind`, phase[key] ~= nil and typeof(phase[key]) == typeof(phases.Dusk[key]))
				end
				for _, key in { "Glow", "Lights" } do
					t.Check(`{name} {key}: a share, if given`, phase[key] == nil or (phase[key] >= 0 and phase[key] <= 1))
				end
				if phase.Sky == nil then
					continue -- Roblox's built-in sky (the day's, until our own is drawn)
				end
				local count = 0
				for face, id in phase.Sky do
					count += 1
					t.Check(`{name} {face}: a published face`, string.match(id, "^rbxassetid://%d+$") ~= nil, id)
				end
				t.Equal(`{name}: six faces`, count, 6)
			end
			t.Check("day, dusk and night wear our own skies", phases.Day.Sky ~= nil and phases.Dusk.Sky ~= nil and phases.Night.Sky ~= nil)
			t.Check("the day brighter than dusk, dusk than night", phases.Day.Brightness > phases.Dusk.Brightness and phases.Dusk.Brightness > phases.Night.Brightness)
			t.Check("night's floors glow more, its pools doing more of the work", phases.Night.Floor > phases.Dusk.Floor)
			t.Check("the sun's toward, a unit vector up", near(LightingConfig.Toward.Magnitude, 1) or math.abs(LightingConfig.Toward.Magnitude - 1) < 0.01)
			t.Check("and above the horizon: a day clock", LightingConfig.Toward.Y > 0)
			local gateZ, from = -272, LightingConfig.From
			t.Check("north of the gate: inside", Night.Inside(gateZ - 100, gateZ, from))
			t.Check("a door's landing: inside", Night.Inside(gateZ + WorldConfig.Grey.Door.Landing, gateZ, from))
			t.Check("the side street's far end: outside", not Night.Inside(gateZ + from + 1, gateZ, from))
		end,
	},
	{
		Name = "Night: the director's 16:50, no mist south of the Row in any phase, and TR24's fix 9, a crossing's light warming from its first second with the sky still swapped at its middle",
		Run = function(t: any)
			local clear = LightingConfig.Clear
			t.Check("the clear air holds no mist: no density, no haze", clear.Atmosphere.Density == 0 and clear.Atmosphere.Haze == 0)
			t.Check("its veil hides the sky alone: no more density than the Row's, and haze", clear.Veil.Density <= LightingConfig.Veil.Density and clear.Veil.Haze > 0)
			for name, phase in LightingConfig.Phases :: any do
				local out = Night.Clear(phase.Atmosphere, clear.Atmosphere :: any, 1)
				t.Check(`{name}: clear south of the Row`, out.Density == 0 and out.Haze == 0 and out.Glare == 0, `{out.Density} {out.Haze} {out.Glare}`)
				t.Check(`{name}: its colours kept, for the veil's tint`, out.Color == phase.Atmosphere.Color and out.Decay == phase.Atmosphere.Decay)
				local kept = Night.Clear(phase.Atmosphere, clear.Atmosphere :: any, 0)
				t.Check(`{name}: the Row keeps its haze`, kept.Density == phase.Atmosphere.Density and kept.Haze == phase.Atmosphere.Haze)
				local half = Night.Clear(phase.Atmosphere, clear.Atmosphere :: any, 0.5)
				t.Check(`{name}: half way up the side street, half of it`, near(half.Density, phase.Atmosphere.Density / 2))
			end
			t.Equal("a key the clear air doesn't hold stays out", Night.Clear({ Density = 0.3 }, { Density = 0, Haze = 0 }, 1).Haze, nil)
			-- the warm light
			local warm = LightingConfig.Warm
			t.Check("the seed: past half by the middle, under all of it", warm > 0.5 and warm < 1, tostring(warm))
			t.Equal("nothing before the crossing", Night.Warm(0, warm), 0)
			t.Check("the first second of a minute's crossing already moves it", Night.Warm(1 / 60, warm) >= 0.02, string.format("%.4f", Night.Warm(1 / 60, warm)))
			local _, _, second = at(1080 + 1)
			t.Check("where the eased turn has barely moved", Night.Warm(1 / 60, warm) > 10 * second, string.format("%.5f", second))
			t.Check("Warm of the way by the middle", near(Night.Warm(0.5, warm), warm), string.format("%.4f", Night.Warm(0.5, warm)))
			t.Check("all of it at the end", near(Night.Warm(1, warm), 1))
			local last, rising = -1, true
			for step = 0, 20 do
				local v = Night.Warm(step / 20, warm)
				rising = rising and v >= last
				last = v
			end
			t.Check("never back", rising)
			t.Check("a straight line at a half", near(Night.Warm(0.3, 0.5), 0.3))
			t.Check("no number: nothing", Night.Warm(0 / 0, warm) == 0)
			local _, _, w, _, x = Night.Turn(1110, CYCLE)
			t.Check("the turn gives its crossing's own share: half way to dusk", near(x, 0.5) and near(w, 0.5), `{x} {w}`)
			local _, _, _, _, held = Night.Turn(500, CYCLE)
			t.Equal("none while a look holds", held, 0)
			local _, _, eased, _, early = Night.Turn(1080 + 6, CYCLE)
			t.Check("6 s in: the share a tenth, the ease under it", near(early, 0.1) and eased < early, `{early} {eased}`)
		end,
	},
	{
		Name = "Night: AR20's C, bright hours south of the Row: a lighter fill, light and exposure over each phase's own, the glow lifted, the Row keeping its own",
		Run = function(t: any)
			local clear = LightingConfig.Clear
			local phases = LightingConfig.Phases :: any
			local function lum(c: Color3): number
				return 0.2126 * c.R + 0.7152 * c.G + 0.0722 * c.B
			end
			local sun = { Clock = 14, Latitude = 0 }
			for _, name in { "Day", "Dusk", "Night" } do
				local over = (clear.Phases :: any)[name]
				local phase = phases[name]
				t.Check(`{name}: C's fill`, over ~= nil and typeof(over.Ambient) == "Color3")
				if over == nil then
					continue
				end
				t.Check(`{name}: its fill lighter than the Row's`, lum(over.Ambient) > lum(phase.Ambient), string.format("%.3f over %.3f", lum(over.Ambient), lum(phase.Ambient)))
				t.Check(`{name}: its exposure lifted`, over.Exposure > (phase.Exposure or 0), tostring(over.Exposure))
				for key, value in over do
					t.Check(`{name} {key}: a key the phase holds, of its kind`, phase[key] ~= nil and typeof(phase[key]) == typeof(value))
				end
				local bright = Night.Ground(Night.Clear(phase, over, 1), name, sun)
				t.Check(`{name}: out of the Row, C's fill`, bright.Lighting.Ambient == over.Ambient and bright.Lighting.OutdoorAmbient == over.Ambient)
				t.Equal(`{name}: and its exposure`, bright.Lighting.ExposureCompensation, over.Exposure)
				t.Equal(`{name}: its sky its own`, bright.Sky, name)
				t.Check(`{name}: its haze its own until the clear air`, bright.Atmosphere.Density == phase.Atmosphere.Density)
				local row = Night.Ground(Night.Clear(phase, over, 0), name, sun)
				t.Check(`{name}: in the Row, its own`, row.Lighting.Ambient == phase.Ambient and row.Lighting.Brightness == phase.Brightness)
				t.Equal(`{name}: and its own exposure`, row.Lighting.ExposureCompensation, phase.Exposure or 0)
			end
			t.Check("dusk brighter than night, still", clear.Phases.Dusk.Brightness > clear.Phases.Night.Brightness)
			t.Check("night still night: its fill under dusk's", lum(clear.Phases.Night.Ambient) < lum(clear.Phases.Dusk.Ambient))
			t.Check("the glow lifted, not doubled", clear.Glow > 1 and clear.Glow < 2, tostring(clear.Glow))
		end,
	},
}
