--!strict
-- Night cases (pure): Lantern Row's dusk and night on one server clock (TR8; the director, 2026-11-12; Rules.Night,
-- Config.Lighting). A turn is research's seed, 20 minutes; the crossing eases; the sky's swap hides under the haze's peak;
-- a look mixes key by key; the ground's look holds from just before its gate, a door's landing inside it.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Night = require(Shared.Rules.Night)
local LightingConfig = require(Shared.Config.Lighting)
local WorldConfig = require(Shared.Config.World)

local CYCLE = { Dusk = 780, Night = 300, Cross = 60 }
local NOW = 1_800_000_000

local function near(a: number, b: number): boolean
	return math.abs(a - b) <= 1e-6 * math.max(1, math.abs(b))
end

local function at(seconds: number): (number, string)
	return Night.At(seconds, CYCLE)
end

return {
	{
		Name = "Night: TR8, a turn is 13 minutes of dusk, a minute's crossing, 5 of night and a minute back, on the server's clock",
		Run = function(t: any)
			t.Equal("research's seed: 20 minutes", Night.Length(LightingConfig.Cycle), 1200)
			t.Equal("the seed in Config", Night.Length(CYCLE), Night.Length(LightingConfig.Cycle))
			local w, phase = at(0)
			t.Check("it starts at dusk", w == 0 and phase == "Dusk")
			w, phase = at(779.9)
			t.Check("dusk to its last moment", w == 0 and phase == "Dusk")
			w, phase = at(810)
			t.Check("half way to night", near(w, 0.5) and phase == "ToNight", `{w} {phase}`)
			w, phase = at(840)
			t.Check("night", w == 1 and phase == "Night")
			w, phase = at(1170)
			t.Check("half way back", near(w, 0.5) and phase == "ToDusk", `{w} {phase}`)
			w, phase = at(1200)
			t.Check("round to dusk again", w == 0 and phase == "Dusk")
			w, phase = at(-30)
			t.Check("before the epoch, the turn runs on", near(w, 0.5) and phase == "ToDusk", `{w} {phase}`)
			w, phase = at(0 / 0)
			t.Check("no clock: dusk", w == 0 and phase == "Dusk")
			t.Equal("dusk's 13 minutes left at its start", Night.Left(0, CYCLE), 780)
			t.Equal("40 s of the crossing left", Night.Left(800, CYCLE), 40)
		end,
	},
	{
		Name = "Night: TR8, a jump to a phase puts the server's clock at its start, for the takes",
		Run = function(t: any)
			for _, phase in { "Dusk", "ToNight", "Night", "ToDusk" } do
				local epoch = Night.From(phase, NOW, CYCLE)
				local _, got = at(NOW - epoch)
				t.Equal(`{phase}: there`, got, phase)
				local _, before = at(NOW - epoch - 0.01)
				t.Check(`{phase}: at its start`, before ~= phase)
			end
			t.Equal("night's 5 minutes ahead", Night.Left(NOW - Night.From("Night", NOW, CYCLE), CYCLE), 300)
			t.Check("no such phase", not pcall(Night.From, "Noon", NOW, CYCLE))
		end,
	},
	{
		Name = "Night: TR8, the crossing eases from dusk to night, and the sky's swap hides under the haze's peak",
		Run = function(t: any)
			local last, rising = -1, true
			for s = 780, 840, 2 do
				local w = at(s)
				rising = rising and w >= last
				last = w
			end
			t.Check("never back on the way to night", rising)
			t.Check("eased: slow at its ends", at(783) < 0.05 and at(837) > 0.95)
			local width = LightingConfig.Veil.Width
			t.Equal("the peak at the middle", Night.Veil(0.5, width), 1)
			t.Equal("nothing at its edge", Night.Veil(0.5 + width / 2, width), 0)
			t.Equal("nothing at dusk", Night.Veil(0, width), 0)
			t.Equal("nothing at night", Night.Veil(1, width), 0)
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
			look.Atmosphere.Density = 99
			t.Check("a look is its own copy", dusk.Atmosphere.Density ~= 99)
		end,
	},
	{
		Name = "Night: TR8, Lantern Row's two phases are whole, and its look holds from just before the gate, a door's landing inside it",
		Run = function(t: any)
			local phases = LightingConfig.Phases :: any
			for key, value in phases.Dusk do
				t.Check(`{key}: in both phases, of one kind`, phases.Night[key] ~= nil and typeof(phases.Night[key]) == typeof(value))
			end
			for name, phase in phases do
				local count = 0
				for face, id in phase.Sky do
					count += 1
					t.Check(`{name} {face}: a published face`, string.match(id, "^rbxassetid://%d+$") ~= nil, id)
				end
				t.Equal(`{name}: six faces`, count, 6)
			end
			t.Check("night's floors glow more, its pools doing more of the work", phases.Night.Floor > phases.Dusk.Floor)
			t.Check("the sun's toward, a unit vector up", near(LightingConfig.Toward.Magnitude, 1) or math.abs(LightingConfig.Toward.Magnitude - 1) < 0.01)
			t.Check("and above the horizon: a day clock", LightingConfig.Toward.Y > 0)
			local gateZ, from = -272, LightingConfig.From
			t.Check("north of the gate: inside", Night.Inside(gateZ - 100, gateZ, from))
			t.Check("a door's landing: inside", Night.Inside(gateZ + WorldConfig.Grey.Door.Landing, gateZ, from))
			t.Check("the side street's far end: outside", not Night.Inside(gateZ + from + 1, gateZ, from))
		end,
	},
}
