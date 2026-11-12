--!strict
-- Fight cases (pure): the action rows hold together, the seeds are the game's, and the fight's decisions (beats, the
-- choice of action, targets, the leash, giving up, reach, damage, healing) do what docs/design.md, "Combat", says.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Actions = require(Shared.Definitions.Actions)
local Enemies = require(Shared.Definitions.Enemies)
local Voidkin = require(Shared.Definitions.Voidkin)
local Fight = require(Shared.Rules.Fight)
local Stats = require(Shared.Rules.Stats)
local Hit = require(Shared.Rules.Hit)
local Growth = require(Shared.Rules.Growth)
local Combat = require(Shared.Config.Combat)
local EnemiesConfig = require(Shared.Config.Enemies)
local Animations = require(Shared.Config.Animations)

local function near(a: number, b: number, tolerance: number?): boolean
	return math.abs(a - b) <= (tolerance or 1e-9) * math.max(1, math.abs(b))
end

local function candidate(id: string, distance: number, reach: number, aggrieved: boolean?): Fight.Candidate
	return { Id = id, Distance = distance, Reach = reach, Aggrieved = aggrieved }
end

return {
	{
		Name = "Fight: every action row holds together",
		Run = function(t: any)
			local seen = {}
			for _, action in Actions.List do
				t.Check(`{action.Id} once`, not seen[action.Id])
				seen[action.Id] = true
				t.Check(`{action.Id} cancels inside its length`, action.CancelFrom > 0 and action.CancelFrom <= action.Length)
				t.Check(`{action.Id} has a cooldown of 0 or more`, action.Cooldown >= 0)
				t.Check(`{action.Id} starts inside its reach`, action.Range > 0)
				local beats = 0
				for name, at in action.Beats do
					beats += 1
					t.Check(`{action.Id}.{name} inside the action`, at >= 0 and at <= action.Length)
				end
				t.Check(`{action.Id} has beats`, beats > 0)
				local heavy = false
				for beat, hit in action.Hits do
					t.Check(`{action.Id} hits on its beat {beat}`, action.Beats[beat] ~= nil)
					t.Check(`{action.Id}.{beat} hits harder than nothing`, hit.Coefficient > 0)
					t.Check(`{action.Id}.{beat} reaches past where it starts`, hit.Reach >= action.Range)
					t.Check(`{action.Id}.{beat} pushes 0 or more`, hit.Push >= 0)
					heavy = heavy or hit.Heavy
				end
				t.Equal(`{action.Id} is heavy exactly when a hit is`, action.Heavy, heavy)
				t.Check(`{action.Id} names its levers`, #action.Levers > 0)
				if action.Clip then
					t.Check(`{action.Id}'s clip has a role for its fades`, Animations.Roles[action.Clip] ~= nil)
				end
			end
			for def, ids in Actions.Kits do
				t.Check(`kit {def} is a Voidkin`, Voidkin.ById[def] ~= nil)
				for _, id in ids do
					t.Check(`kit {def}: {id} exists`, Actions.ById[id] ~= nil)
				end
			end
			t.Equal("an unbuilt Voidkin fights with the stand-in's kit", Actions.KitOf("watt")[1].Id, Actions.KitOf(Actions.StandIn)[1].Id)
			for _, row in Enemies.List do
				t.Check(`{row.Id}'s numbers exist`, (EnemiesConfig :: any)[row.Kind] ~= nil)
				t.Check(`{row.Id}'s action exists`, row.Action == nil or Actions.ById[row.Action] ~= nil)
			end
		end,
	},
	{
		Name = "Fight: the actions are the seeds' (tools/balance/seeds.json, attack)",
		Run = function(t: any)
			-- seeds: comboCoefs [0.9, 0.9, 1.4], comboSeconds 1.8, signatureCoef 4.0, signatureEvery 10.
			local combo, haymaker = Actions.ById.RookCombo, Actions.ById.RookHaymaker
			t.Check("the combo's three", near(combo.Hits.Hit1.Coefficient, 0.9) and near(combo.Hits.Hit2.Coefficient, 0.9) and near(combo.Hits.Hit3.Coefficient, 1.4))
			t.Equal("the combo's cycle", combo.CancelFrom, 1.8)
			t.Equal("the signature's coefficient", haymaker.Hits.Strike.Coefficient, 4.0)
			t.Equal("the signature's cooldown", haymaker.Cooldown, 10)
			t.Check("Haymaker is heavy", haymaker.Heavy and haymaker.Hits.Strike.Heavy)
			local lead = (0.9 + 0.9 + 1.4) / combo.CancelFrom + haymaker.Hits.Strike.Coefficient / haymaker.Cooldown
			t.Check("the enemies' coefficient a second is the lead's", near(Actions.EnemyPerSecond, lead))
			for _, id in { "ShadeSwipe", "KeeperSwing" } do
				local action = Actions.ById[id]
				t.Check(`{id} hits the same a second`, near(action.Hits.Strike.Coefficient / action.CancelFrom, lead))
			end
			-- The chain's rhythm (handbook/feel/combat.md): every hit to the next, the last into the next combo's first, near 0.6 s.
			local beats = combo.Beats
			for _, gap in { beats.Hit2 - beats.Hit1, beats.Hit3 - beats.Hit2, combo.CancelFrom + beats.Hit1 - beats.Hit3 } do
				t.Check(`a gap of {string.format("%.3f", gap)} s`, gap >= 0.5 and gap <= 0.7)
				t.Check("a flinch ends inside it", Combat.Flinch.Seconds < gap)
			end
		end,
	},
	{
		Name = "Fight: an enemy's block is its numbers times G",
		Run = function(t: any)
			for _, level in { 1, 5, 9 } do
				local g = Growth.G(level)
				local shade = Stats.Enemy("brawler", level, "Technique")
				t.Check(`level {level} health`, near(shade.Health, EnemiesConfig.Ordinary.Health * g))
				t.Check(`level {level} attack`, near(shade.Attack, EnemiesConfig.Ordinary.Attack * g))
				t.Check(`level {level} defence`, near(shade.Defence, EnemiesConfig.Ordinary.Defence * g))
				t.Equal(`level {level} type from the spawn`, shade.Type, "Technique")
				local keeper = Stats.Enemy("lamplighter", level)
				t.Check(`level {level} keeper's dodge`, near(keeper.Dodge, EnemiesConfig.Keeper.Dodge * g))
				t.Equal(`level {level} keeper's own type`, keeper.Type, "Intelligence")
			end
			t.Equal("an unknown enemy is empty", Stats.Enemy("nobody", 3).Health, 0)
			t.Equal("past the top level it's the top level", Stats.Enemy("brawler", 999).Level, Stats.Enemy("brawler", 60).Level)
		end,
	},
	{
		Name = "Fight: the seeds' time to kill, against a bare Common Warrior",
		Run = function(t: any)
			-- The expected damage a second, both ways, through the game's own hit, against the targets in Config.Enemies.
			local function perSecond(attacker: Stats.Block, defender: Stats.Block, coefficientPerSecond: number): number
				local odds = Hit.Resolve(attacker, defender, 1, { Dodge = 0.999999, Critical = 0.999999, Block = 0.999999 })
				local mean = 0
				for _, critical in { true, false } do
					for _, blocked in { true, false } do
						local hit = Hit.Resolve(attacker, defender, 1, { Dodge = 0.999999, Critical = if critical then 0 else 0.999999, Block = if blocked then 0 else 0.999999 })
						local p = (if critical then odds.ChanceCritical else 1 - odds.ChanceCritical) * (if blocked then odds.ChanceBlock else 1 - odds.ChanceBlock)
						mean += p * hit.Total
					end
				end
				return mean * (1 - odds.ChanceDodge) * coefficientPerSecond
			end
			local targets = { -- seeds enemy: ttk and the health share a kill costs
				{ "brawler", 5, 0.12 },
				{ "brawler_elite", 18, 0.35 },
				{ "lamplighter", 45, 0.7 },
			}
			for _, level in { 1, 5, 9 } do
				local lead = Stats.Resolve({ Id = "k", Def = "rook", Level = level, Xp = 0, Stars = 0, Copies = 0, Nickname = "", Preset = "", Favourite = false, Locked = false, Born = 0 } :: any)
				for _, target in targets do
					local enemy = Stats.Enemy(target[1] :: string, level)
					local ttk = enemy.Health / perSecond(lead, enemy, Actions.EnemyPerSecond)
					local share = perSecond(enemy, lead, Actions.EnemyPerSecond) * ttk / lead.Health
					t.Check(`level {level} {target[1]}: {string.format("%.2f", ttk)} s`, near(ttk, target[2] :: number, 0.01))
					t.Check(`level {level} {target[1]}: {string.format("%.3f", share)} of the lead`, near(share, target[3] :: number, 0.01))
				end
			end
		end,
	},
	{
		Name = "Fight: beats come once each, in order",
		Run = function(t: any)
			local combo = Actions.ById.RookCombo
			t.Equal("none before the first", #Fight.BeatsBetween(combo, -1, 0.19), 0)
			local first = Fight.BeatsBetween(combo, -1, 0.2)
			t.Check("the first on its time", #first == 1 and first[1] == "Hit1")
			local all = Fight.BeatsBetween(combo, -1, combo.Length)
			t.Check("all three, in order", #all == 3 and all[1] == "Hit1" and all[2] == "Hit2" and all[3] == "Hit3")
			-- Frame by frame at 60 fps, every beat comes exactly once.
			local count, from = 0, -1
			for frame = 0, 130 do
				local to = frame / 60
				count += #Fight.BeatsBetween(combo, from, to)
				from = to
			end
			t.Equal("frame by frame, once each", count, 3)
			local swipe = Actions.ById.ShadeSwipe
			t.Check("a beat at 0 comes from below 0", Fight.BeatsBetween(swipe, -1, 0)[1] == "Wind")
			t.Equal("and not from 0", #Fight.BeatsBetween(swipe, 0, 0.1), 0)
		end,
	},
	{
		Name = "Fight: the signature goes when it's ready, the combo otherwise",
		Run = function(t: any)
			local kit = Actions.KitOf("rook")
			t.Equal("fresh, the signature", (Fight.Choose(kit, {}, 0) :: any).Id, "RookHaymaker")
			local ready = { RookHaymaker = 10 }
			t.Equal("on cooldown, the combo", (Fight.Choose(kit, ready, 9.99) :: any).Id, "RookCombo")
			t.Equal("ready again on the second", (Fight.Choose(kit, ready, 10) :: any).Id, "RookHaymaker")
			t.Check("nothing when all wait", Fight.Choose({ Actions.ById.RookHaymaker }, ready, 5) == nil)
		end,
	},
	{
		Name = "Fight: the lead fights near the avatar and comes back",
		Run = function(t: any)
			local leash = Combat.Lead.Leash
			local list = {
				candidate("far", 2, leash + 1), -- near the lead, past the leash from the avatar
				candidate("b", 9, 10),
				candidate("a", 5, 12),
			}
			t.Equal("the nearest to the lead inside the leash", Fight.LeadTarget(list, nil, leash), "a")
			t.Equal("it keeps its target while that stays in", Fight.LeadTarget(list, "b", leash), "b")
			t.Equal("past the leash it drops it", Fight.LeadTarget(list, "far", leash), "a")
			t.Check("nothing in: it comes back", Fight.LeadTarget({ candidate("x", 1, leash + 0.01) }, nil, leash) == nil)
			t.Equal("on the leash counts", Fight.LeadTarget({ candidate("x", 1, leash) }, nil, leash), "x")
			t.Equal("a tie goes the same way every time", Fight.LeadTarget({ candidate("q", 3, 1), candidate("p", 3, 1) }, nil, leash), "p")
			local lead = Combat.Lead
			t.Equal("with a target, it fights", Fight.LeadMode(10, true, lead), "Fight")
			t.Equal("without, it follows", Fight.LeadMode(10, false, lead), "Follow")
			t.Equal("far gone, it reappears", Fight.LeadMode(lead.TeleportFrom + 1, true, lead), "Teleport")
			t.Equal("near, it walks", Fight.FollowSpeed(lead.CatchUpFrom - 1, lead), lead.WalkSpeed)
			t.Equal("far, it catches up", Fight.FollowSpeed(lead.CatchUpFrom, lead), lead.CatchUpSpeed)
		end,
	},
	{
		Name = "Fight: a Shade notices, answers who hit its pack, and gives up",
		Run = function(t: any)
			local notice = Combat.Shade.Notice
			t.Check("nobody near: it stays", Fight.ShadeTarget({ candidate("l", notice + 1, 0) }, nil, notice) == nil)
			t.Equal("a lead inside notice", Fight.ShadeTarget({ candidate("l", notice, 0) }, nil, notice), "l")
			local list = { candidate("near", 3, 0), candidate("hitter", 35, 0, true) }
			t.Equal("who hit its pack comes first, wherever", Fight.ShadeTarget(list, nil, notice), "hitter")
			t.Equal("it keeps its target", Fight.ShadeTarget(list, "near", notice), "near")
			t.Check("a target gone is dropped", Fight.ShadeTarget({ candidate("other", 50, 0) }, "gone", notice) == nil)
			t.Check("inside its ground it fights on", not Fight.GivesUp(Combat.Shade.GiveUp, Combat.Shade.GiveUp))
			t.Check("past it, it gives up", Fight.GivesUp(Combat.Shade.GiveUp + 0.1, Combat.Shade.GiveUp))
		end,
	},
	{
		Name = "Fight: a hit reaches ahead, not behind",
		Run = function(t: any)
			local arc = Combat.Arc
			t.Check("dead ahead, in reach", Fight.Reaches(5, 1, 6, arc))
			t.Check("past its reach, no", not Fight.Reaches(6.01, 1, 6, arc))
			t.Check("behind, no", not Fight.Reaches(3, -1, 6, arc))
			t.Check("at the arc's edge, yes", Fight.Reaches(3, math.cos(math.rad(arc)), 6, arc))
			t.Check("just past it, no", not Fight.Reaches(3, math.cos(math.rad(arc + 1)), 6, arc))
			t.Check("touching, any side", Fight.Reaches(0.2, -1, 6, arc))
			t.Check("NaN never reaches", not Fight.Reaches(0 / 0, 1, 6, arc))
		end,
	},
	{
		Name = "Fight: a pack spreads around its target, never stacked",
		Run = function(t: any)
			local spacing = Combat.Slots.Spacing
			local function apart(a: number, b: number): number
				return math.abs(Fight.Wrap(a - b))
			end
			local function closest(list: { number }): number
				local least = math.huge
				for i = 1, #list do
					for j = i + 1, #list do
						least = math.min(least, apart(list[i], list[j]))
					end
				end
				return least
			end
			t.Check("nobody, nothing", #Fight.Spread({}, spacing) == 0)
			t.Check("alone, it stays", near(Fight.Spread({ 37 }, spacing)[1], 37))
			local apartAlready = Fight.Spread({ 0, 100 }, spacing)
			t.Check("apart already, they stay", near(apartAlready[1], 0) and near(apartAlready[2], 100))
			local stacked = Fight.Spread({ 10, 10, 10 }, spacing)
			t.Check("three on one spot: spaced", closest(stacked) >= spacing - 1e-6, `closest {closest(stacked)}`)
			t.Check("around the same middle", near(stacked[2], 10) and near(stacked[1], 10 - spacing) and near(stacked[3], 10 + spacing))
			local across = Fight.Spread({ 175, -175 }, spacing)
			t.Check("across the back, spaced", near(apart(across[1], across[2]), spacing), `{across[1]}, {across[2]}`)
			t.Check("in the same order around", Fight.Wrap(across[2] - across[1]) > 0)
			local crowd = Fight.Spread({ 0, 0, 0, 0, 0, 0, 0, 0 }, spacing)
			t.Check("too many: the circle shared evenly", near(closest(crowd), 360 / 8), `closest {closest(crowd)}`)
			for _, a in Fight.Spread({ 170, 179, -179, -170, 0 }, spacing) do
				t.Check(`{a} is a bearing`, a >= -180 and a < 180)
			end
			t.Check("wrapped", near(Fight.Wrap(190), -170) and near(Fight.Wrap(-190), 170) and near(Fight.Wrap(540), -180))
		end,
	},
	{
		Name = "Fight: damage, healing and a new maximum",
		Run = function(t: any)
			local left, fell = Fight.Damage(100, 30)
			t.Check("it takes the damage", left == 70 and not fell)
			left, fell = Fight.Damage(100, 250)
			t.Check("never below 0, and it falls", left == 0 and fell)
			for _, bad in { 0, -5, 0 / 0, math.huge } do
				t.Equal(`{bad} does nothing`, (Fight.Damage(100, bad)), 100)
			end
			local heal = Combat.Lead.Heal
			t.Equal("in a fight, no healing", Fight.Heal(50, 100, heal.After - 0.01, 1, heal), 50)
			t.Check("out of it, a share a second", near(Fight.Heal(50, 100, heal.After, 1, heal), 50 + 100 * heal.PerSecond))
			t.Equal("never past the maximum", Fight.Heal(99, 100, 60, 60, heal), 100)
			t.Equal("down, no healing", Fight.Heal(0, 100, 60, 1, heal), 0)
			t.Check("a new maximum keeps the share", near(Fight.Rescale(40, 80, 200), 100))
			t.Equal("from nothing, full", Fight.Rescale(0, 0, 200), 200)
		end,
	},
	{
		Name = "Fight: a pack stands round its spawn, its Shades a spacing apart",
		Run = function(t: any)
			local one = Fight.PackRing(1, 7)
			t.Check("one Shade stands on the spawn", #one == 1 and one[1][1] == 0 and one[1][2] == 0)
			t.Equal("nothing below one", #Fight.PackRing(0, 7), 1)
			for _, count in { 2, 3, 4, 6 } do
				local ring = Fight.PackRing(count, 7)
				t.Equal(`{count} Shades, {count} places`, #ring, count)
				local sumX, sumZ = 0, 0
				for k, here in ring do
					local nextOne = ring[k % count + 1]
					local gap = math.sqrt((here[1] - nextOne[1]) ^ 2 + (here[2] - nextOne[2]) ^ 2)
					t.Check(`{count}: place {k} is the spacing from the next`, near(gap, 7, 1e-6), `got {gap}`)
					sumX += here[1]
					sumZ += here[2]
				end
				t.Check(`{count}: centred on the spawn`, math.abs(sumX) < 1e-6 and math.abs(sumZ) < 1e-6)
				t.Check(`{count}: the first straight ahead`, math.abs(ring[1][1]) < 1e-9 and ring[1][2] < 0)
			end
		end,
	},
}
