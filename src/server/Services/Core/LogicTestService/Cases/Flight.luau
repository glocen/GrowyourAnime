--!strict
-- Flight cases (pure): a won thing's way from where its enemy fell to the player (TR24's fix 8; Rules.Flight). Its beats
-- in order and their lengths, the pop leaving from the fall and landing on the floor a step toward the player, never under
-- the floor, the bounce up and back, the rest still, the pull slow off the floor and fast into the player, following one
-- who walks, and the end on them. Numbers from Config.Effects.Drop.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local EffectsConfig = require(Shared.Config.Effects)
local Flight = require(Shared.Rules.Flight)

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

local function close(a: Vector3, b: Vector3): boolean
	return (a - b).Magnitude < 1e-6
end

return {
	{
		Name = "Flight: TR24's fix 8, a drop pops out of its fall onto the floor, bounces, rests for its name, and is pulled into the player",
		Run = function(t: any)
			local look: Flight.Look = EffectsConfig.Drop
			local pop, bounce, pull = look.Pop, look.Bounce, look.Pull
			local from = Vector3.new(10, 3, 20) -- a fallen Shade's root, 3 studs over a floor at 0
			local floor = 0
			local to = Vector3.new(10, 3, -20) -- the player, 40 studs off: a fight's distance
			local land = Flight.Landing(from, floor, to, look)
			t.Check("its time is its beats'", near(Flight.Length(look), pop.Seconds + bounce.Seconds + look.Rest + pull.Seconds))
			t.Check("it lands a step toward the player, hovering over the floor", close(land, Vector3.new(10, look.Hover, 20 - pop.Out)), tostring(land))
			t.Check("on a player standing on the fall: it lands where it fell", close(Flight.Landing(from, floor, Vector3.new(10, 3, 20), look), Vector3.new(10, look.Hover, 20)))
			t.Check("a player nearer than the step: it lands on them, never past", close(Flight.Landing(from, floor, Vector3.new(10, 3, 19), look), Vector3.new(10, look.Hover, 19)))

			-- the beats, in order
			local function beat(age: number): string
				local _, b = Flight.At(age, from, floor, to, look)
				return b
			end
			local edge = 1e-4
			t.Equal("it starts in the pop", beat(0), "Pop")
			t.Equal("then the bounce", beat(pop.Seconds + edge), "Bounce")
			t.Equal("then the rest", beat(pop.Seconds + bounce.Seconds + edge), "Rest")
			t.Equal("then the pull", beat(pop.Seconds + bounce.Seconds + look.Rest + edge), "Pull")
			t.Equal("then done", beat(Flight.Length(look) + edge), "Done")

			-- the pop: from the fall, up, and down onto the landing, never under the floor
			local start = Flight.At(0, from, floor, to, look)
			t.Check("it leaves from where its Shade fell", close(start, from), tostring(start))
			local highest, lowest = -math.huge, math.huge
			for step = 0, 100 do
				local at = Flight.At(pop.Seconds * step / 100, from, floor, to, look)
				highest = math.max(highest, at.Y)
				lowest = math.min(lowest, at.Y)
			end
			t.Check("it rises Height over the fall at its peak", math.abs(highest - (from.Y + pop.Height)) < 0.01, `{highest}`)
			t.Check("it never goes under its hover in the pop", lowest >= land.Y - 1e-6, `{lowest}`)
			local ending = Flight.At(pop.Seconds - 1e-6, from, floor, to, look)
			t.Check("the pop ends on the landing", (ending - land).Magnitude < 1e-3, tostring(ending))

			-- the bounce: up and back on the landing
			local mid = Flight.At(pop.Seconds + bounce.Seconds / 2, from, floor, to, look)
			t.Check("the bounce rises its Height", near(mid.Y - land.Y, bounce.Height), `{mid.Y - land.Y}`)
			t.Check("and stays over the landing", near(mid.X, land.X) and near(mid.Z, land.Z))

			-- the rest: still on the landing
			local restAt = pop.Seconds + bounce.Seconds
			local a = Flight.At(restAt + look.Rest * 0.1, from, floor, to, look)
			local b = Flight.At(restAt + look.Rest * 0.9, from, floor, to, look)
			t.Check("it rests still on the landing", close(a, land) and close(b, land))

			-- the pull: slow off the floor, fast into the player
			local pullAt = restAt + look.Rest
			local function flat(age: number): number
				local at = Flight.At(age, from, floor, to, look)
				return (Vector3.new(at.X, 0, at.Z) - Vector3.new(land.X, 0, land.Z)).Magnitude
			end
			local gone = (Vector3.new(to.X, 0, to.Z) - Vector3.new(land.X, 0, land.Z)).Magnitude
			local early = flat(pullAt + pull.Seconds * 0.25)
			local late = flat(pullAt + pull.Seconds * 0.75)
			t.Check("a quarter in, it has hardly moved", early < gone * 0.05, `{early} of {gone}`)
			t.Check("three quarters in, it's most of the way", late > gone * 0.4, `{late} of {gone}`)
			local first = flat(pullAt + pull.Seconds * 0.5) - flat(pullAt + pull.Seconds * 0.4)
			local last = flat(pullAt + pull.Seconds * 0.9) - flat(pullAt + pull.Seconds * 0.8)
			t.Check("it speeds up into the player", last > first * 2, `{first} then {last}`)
			local over = Flight.At(pullAt + pull.Seconds / 2, from, floor, to, look)
			t.Check("it lifts in the pull, over the straight line", over.Y > land.Y + (to.Y - land.Y) * 0.125, `{over.Y}`)

			-- the player walks: it follows; at the end it's on them
			local walked = Vector3.new(30, 3, -25)
			local tail = Flight.At(pullAt + pull.Seconds - 1e-6, from, floor, walked, look)
			t.Check("it follows a player who walked, to the end", (tail - walked).Magnitude < 0.01, tostring(tail))
			local done = Flight.At(Flight.Length(look) + 1, from, floor, walked, look)
			t.Check("done, it's on the player", close(done, walked))
			t.Check("the landing doesn't move for a walk: it lands toward where they were at the pop", (Flight.Landing(from, floor, walked, look) - from).Magnitude <= pop.Out + from.Y)
		end,
	},
}
