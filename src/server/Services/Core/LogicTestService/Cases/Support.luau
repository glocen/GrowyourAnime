--!strict
-- Logic cases (pure): AR58's Support Shade (docs/asset-requests.md, AR58). Its cast mends the most hurt of its pack in
-- reach, else shields the nearest engaged one, else waits (Rules.Support.Pick); between casts it keeps past its pack's
-- middle, away from the lead (Support.Back); it spawns in a row at its pack's back (Rules.Fight.PackSpots); it's a
-- fragile Ordinary Shade on the Shade's rig in its own mask, its cast the handoff's clip on its beats; it stands behind
-- stage 3's second pack and its fall counts to that stretch. Runs in Studio (LogicTests) and with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Combat = require(Shared.Config.Combat)
local World = require(Shared.Config.World)
local Animations = require(Shared.Config.Animations)
local Actions = require(Shared.Definitions.Actions)
local Enemies = require(Shared.Definitions.Enemies)
local Fight = require(Shared.Rules.Fight)
local Stats = require(Shared.Rules.Stats)
local Stages = require(Shared.Rules.Stages)
local Support = require(Shared.Rules.Support)

local EPS = 1e-6

local function near(a: number, b: number, eps: number?): boolean
	return math.abs(a - b) < (eps or EPS)
end

local function ally(id: string, share: number, distance: number, shielded: boolean?, engaged: boolean?): Support.Ally
	return { Id = id, Share = share, Distance = distance, Shielded = shielded == true, Engaged = engaged ~= false }
end

return {
	{
		Name = "Support: its cast mends the most hurt of its pack in reach, else shields the nearest engaged one, else waits",
		Run = function(t: any)
			local reach, below = 18, 0.7
			local id, does = Support.Pick({ ally("a", 0.9, 4), ally("b", 0.4, 10), ally("c", 0.6, 3) }, reach, below)
			t.Check("the most hurt under the line is mended", id == "b" and does == "Heal", `{id} {does}`)
			id, does = Support.Pick({ ally("a", 0.5, 9), ally("b", 0.5, 4) }, reach, below)
			t.Check("of two as hurt, the nearer", id == "b" and does == "Heal", `{id} {does}`)
			id, does = Support.Pick({ ally("a", 0.7, 6) }, reach, below)
			t.Check("at the line itself, mended", id == "a" and does == "Heal", `{id} {does}`)
			id, does = Support.Pick({ ally("a", 0.2, 25), ally("b", 0.9, 5) }, reach, below)
			t.Check("one out of reach isn't mended: the one in reach is shielded", id == "b" and does == "Shield", `{id} {does}`)
			id, does = Support.Pick({ ally("a", 0, 2), ally("b", 1, 5) }, reach, below)
			t.Check("a down one is passed over", id == "b" and does == "Shield", `{id} {does}`)
			id, does = Support.Pick({ ally("a", 1, 3, true), ally("b", 0.95, 7), ally("c", 1, 5) }, reach, below)
			t.Check("none hurt: the nearest unshielded one is shielded", id == "c" and does == "Shield", `{id} {does}`)
			id, does = Support.Pick({ ally("a", 1, 3, false, false), ally("b", 1, 6, false, true) }, reach, below)
			t.Check("only one engaged with a lead is shielded", id == "b" and does == "Shield", `{id} {does}`)
			id, does = Support.Pick({ ally("a", 1, 3, true), ally("b", 0.9, 4, false, false) }, reach, below)
			t.Check("nobody to take it: no cast", id == nil and does == nil, `{id} {does}`)
			id = Support.Pick({}, reach, below)
			t.Check("alone: no cast", id == nil)
		end,
	},
	{
		Name = "Support: between casts it keeps Back studs past its pack's middle, away from the lead",
		Run = function(t: any)
			local x, z = Support.Back(0, 0, 0, -10, 8)
			t.Check("the lead ahead: straight behind", near(x, 0) and near(z, 8), `{x}, {z}`)
			x, z = Support.Back(3, 4, 0, 0, 5)
			t.Check("on the line from the lead through the middle", near(x, 6) and near(z, 8), `{x}, {z}`)
			x, z = Support.Back(2, 2, 2, 2, 5)
			t.Check("the lead on the middle: back along +z", near(x, 2) and near(z, 7), `{x}, {z}`)
			t.Check("its seeds: back past its slack", Combat.Support.Back > Combat.Support.Slack and Combat.Support.Slack > 0)
		end,
	},
	{
		Name = "Support: a pack's rear stands in a row at its back, past its ring; the ring as before",
		Run = function(t: any)
			local spread, behind = 7, 5
			local plain = Fight.PackSpots("brawler", 3, "dasher", 1, nil, nil, spread, behind)
			local defs, ring = Fight.PackDefs("brawler", 3, "dasher", 1), Fight.PackRing(3, spread)
			t.Equal("no rear: the ring alone", #plain, 3)
			local same = true
			for index, spot in plain do
				same = same and spot.Def == defs[index] and near(spot.X, ring[index][1]) and near(spot.Z, ring[index][2])
			end
			t.Check("each its place in the ring, as PackDefs and PackRing say", same)
			local deepest = -math.huge
			for _, offset in ring do
				deepest = math.max(deepest, offset[2])
			end
			local one = Fight.PackSpots("brawler", 3, "dasher", 1, "support", 1, spread, behind)
			t.Equal("one rear: four", #one, 4)
			local last = one[4]
			t.Check("the rear one last, behind the ring's deepest, in the middle", last.Def == "support" and near(last.X, 0) and near(last.Z, deepest + behind), `{last.Def} {last.X} {last.Z}`)
			local two = Fight.PackSpots("brawler", 3, nil, nil, "support", 2, spread, behind)
			t.Check("two rear: a row across the back, spread apart", #two == 5 and near(two[5].X - two[4].X, spread) and near(two[4].X + two[5].X, 0) and near(two[4].Z, two[5].Z))
			t.Equal("a rear count of none: no rear", #Fight.PackSpots("brawler", 3, nil, nil, "support", 0, spread, behind), 3)
			t.Check("its depth is the world's", World.Row.Behind > 0)
			-- the street's own: no rear Shade stands nearer another than the ring's spacing (the Packs case's gap)
			for _, stop in World.Row.Stops do
				if stop.Kind == "Pack" and stop.Rear then
					local w = stop.With
					local all = Fight.PackSpots(stop.Def, stop.Count or 1, if w then w.Def else nil, if w then w.Count else nil, stop.Rear.Def, stop.Rear.Count, World.Row.Spread, World.Row.Behind)
					local gap = math.huge
					for i = 1, #all do
						for j = i + 1, #all do
							gap = math.min(gap, math.sqrt((all[i].X - all[j].X) ^ 2 + (all[i].Z - all[j].Z) ^ 2))
						end
					end
					t.Check(`stage {stop.Stage}'s pack with a rear: its Shades no nearer than Row.Spread`, gap >= World.Row.Spread - 0.01, string.format("%.2f", gap))
				end
			end
		end,
	},
	{
		Name = "Support: a fragile Ordinary Shade in its own mask, Orange, slighter; its cast the handoff's clip on its beats",
		Run = function(t: any)
			local row = Enemies.ById.support
			t.Check("a row", row ~= nil)
			if row == nil then
				return
			end
			t.Equal("Ordinary", row.Kind, "Ordinary")
			t.Equal("the Shade's rig", row.Rig, "Shade")
			t.Equal("its own mask", row.Mask, "Support")
			t.Equal("Orange", row.Type, "Orange")
			t.Check("slighter than its kin", row.Scale ~= nil and row.Scale < 1)
			t.Equal("its swing a Brawler's", row.Action, Enemies.ById.brawler.Action)
			local weak, whole = Stats.Enemy("support", 7), Stats.Enemy("brawler", 7)
			t.Check("fragile: less health than a Brawler of its level, by its row's share", row.Health ~= nil and row.Health < 1 and near(weak.Health, whole.Health * (row.Health :: number), 1e-3), `{weak.Health} vs {whole.Health}`)
			t.Check("its attack a Brawler's", near(weak.Attack, whole.Attack), `{weak.Attack} vs {whole.Attack}`)
			local cast = Actions.ById[row.Signature or ""]
			t.Check("its signature is its cast", cast ~= nil and cast.Id == "SupportCast")
			if cast == nil then
				return
			end
			t.Equal("the handoff's clip", cast.Clip, "ShadeCast")
			t.Check("the clip is uploaded", type(Animations.Ids.ShadeCast) == "number")
			t.Check("its fades in Config", (Animations.Fades :: any)[Animations.Roles.ShadeCast or ""] ~= nil)
			t.Check("its length the clip's (1.7 s, 103 frames)", near(cast.Length, 1.7))
			t.Check("its sleeves up at Cast, the clip's marker (0.4 s)", near(cast.Beats.Cast, 0.4))
			t.Check("down from Lower, the clip's marker (1.4 s)", near(cast.Beats.Lower, 1.4))
			t.Check("it casts on a beat it has", cast.Support ~= nil and cast.Beats[cast.Support :: string] ~= nil)
			t.Check("it never hits", next(cast.Hits) == nil)
			t.Check("a cooldown, so it isn't cast back to back", cast.Cooldown > cast.Length)
			t.Check("alone, its cast held, its swing is chosen", Fight.Choose({ cast, Actions.ById.ShadeSwipe }, {}, 0, cast.Id) == Actions.ById.ShadeSwipe)
			local seeds = Combat.Support
			t.Check("its seeds: a heal's share and a shield's", seeds.Below > 0 and seeds.Below < 1 and seeds.Heal > 0 and seeds.Heal <= 1 and seeds.Shield.Share > 0 and seeds.Shield.Share < 1 and seeds.Shield.Seconds > 0)
		end,
	},
	{
		Name = "Support: it stands behind stage 3's second pack, and its fall counts to that stretch's quota only",
		Run = function(t: any)
			local rears: { [number]: string } = {}
			for _, stop in World.Row.Stops do
				if stop.Kind == "Pack" and stop.Rear then
					rears[stop.Stage] = stop.Rear.Def
					t.Check(`stage {stop.Stage}: its rear is an enemy, one or more`, Enemies.ById[stop.Rear.Def] ~= nil and stop.Rear.Count >= 1)
				end
			end
			t.Equal("stage 3 has the Support at a pack's back", rears[3], "support")
			t.Check("no other stage has one", rears[1] == nil and rears[2] == nil)
			local run = { Ground = World.Row.Ground, Difficulty = "Normal", Stage = 3, Kills = 0, Last = false, Done = false } :: any
			Stages.Kill(run, "support")
			t.Equal("a Support's fall counts in stage 3", run.Kills, 1)
			run = { Ground = World.Row.Ground, Difficulty = "Normal", Stage = 2, Kills = 0, Last = false, Done = false } :: any
			Stages.Kill(run, "support")
			t.Equal("not in stage 2", run.Kills, 0)
		end,
	},
}
