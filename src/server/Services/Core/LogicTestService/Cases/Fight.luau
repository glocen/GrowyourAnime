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
local ShadeBurstArt = require(Shared.Config.ShadeBurstArt)
local EffectsConfig = require(Shared.Config.Effects)

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
				-- an entrance (AR7's Challenge) hurts no one and is never chosen by its reach
				t.Check(`{action.Id} starts inside its reach`, action.Range > 0 or next(action.Hits) == nil)
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
				if row.Rig == "Box" then
					t.Check(`{row.Id}'s box has a size`, row.Size ~= nil and #(row.Size :: { number }) == 3)
				elseif row.Rig == "Shade" then
					-- AR2's rig carries the four masks by role (tools/studio/Models/Shade.luau)
					local masks = { Brawler = true, Guard = true, Dasher = true, Support = true }
					t.Check(`{row.Id} wears one of the rig's masks`, row.Mask ~= nil and masks[row.Mask :: string] == true)
				else
					-- a rig of its own (AR7: the keeper's template), with its clips by role
					t.Check(`{row.Id}'s rig has its clips`, Animations.Rigs[row.Rig] ~= nil)
				end
				t.Check(`{row.Id}'s scale is a size`, row.Scale == nil or (row.Scale :: number) > 0)
				if row.Enter then
					-- the entrance it holds as it's spawned: an action that hurts no one
					local enter = Actions.ById[row.Enter :: string]
					t.Check(`{row.Id}'s entrance exists`, enter ~= nil)
					t.Check(`{row.Id}'s entrance hurts no one`, enter ~= nil and next(enter.Hits) == nil)
				end
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
			-- AR8, "B5": the stamp lands on the target and it stays under it (tier 2, research, 2026-11-13)
			t.Equal("Haymaker pins: its strike pushes nothing", haymaker.Hits.Strike.Push, 0)
			local lead = (0.9 + 0.9 + 1.4) / combo.CancelFrom + haymaker.Hits.Strike.Coefficient / haymaker.Cooldown
			t.Check("the enemies' coefficient a second is the lead's", near(Actions.EnemyPerSecond, lead))
			for _, id in { "ShadeSwipe", "KeeperSwing" } do
				local action = Actions.ById[id]
				local total = 0
				for _, hit in action.Hits do
					total += hit.Coefficient
				end
				t.Check(`{id} hits the same a second`, near(total / action.CancelFrom, lead))
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
			local swing = Actions.ById.KeeperSwing
			t.Check("a beat at 0 comes from below 0", Fight.BeatsBetween(swing, -1, 0)[1] == "Wind")
			t.Equal("and not from 0", #Fight.BeatsBetween(swing, 0, 0.1), 0)
		end,
	},
	{
		Name = "Fight: a hit ahead of its beat moves the clock to the beat, never back",
		Run = function(t: any)
			local combo = Actions.ById.RookCombo
			t.Equal("behind: to the beat", Fight.CatchTo(combo, "Hit2", 0.7), combo.Beats.Hit2)
			t.Equal("far behind: to the beat, not past it", Fight.CatchTo(combo, "Hit3", 0), combo.Beats.Hit3)
			t.Check("on the beat: stays", Fight.CatchTo(combo, "Hit2", combo.Beats.Hit2) == nil)
			t.Check("past it: stays", Fight.CatchTo(combo, "Hit1", 0.9) == nil)
			t.Check("not one of its beats: stays", Fight.CatchTo(combo, "Release", 0.1) == nil)
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
		-- TR7's balance batch: a push carried a Shade through Lantern Row's east wall, and it walked into the wall for good.
		Name = "Fight: a Shade walking home that comes no nearer for a while is stuck",
		Run = function(t: any)
			local stuck = Combat.Shade.ResetStuck
			local closest, since, isStuck = Fight.ResetStuck(math.huge, 0, 30, 1, stuck.Gain, stuck.Seconds)
			t.Check("its first step home counts as nearer", closest == 30 and since == 1 and not isStuck)
			closest, since, isStuck = Fight.ResetStuck(closest, since, 25, 2, stuck.Gain, stuck.Seconds)
			t.Check("nearer: on its way", closest == 25 and since == 2 and not isStuck)
			closest, since, isStuck = Fight.ResetStuck(closest, since, 25 - stuck.Gain / 2, 2 + stuck.Seconds - 0.1, stuck.Gain, stuck.Seconds)
			t.Check("a hair nearer isn't progress, and not stuck yet", closest == 25 and since == 2 and not isStuck)
			closest, since, isStuck = Fight.ResetStuck(closest, since, 25, 2 + stuck.Seconds + 0.1, stuck.Gain, stuck.Seconds)
			t.Check("no nearer for Seconds: stuck", isStuck)
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
		Name = "Fight: a crowd adds to a Shade's health from its third lead",
		Run = function(t: any)
			local c = Combat.Crowd
			t.Equal("one lead: its own", Fight.CrowdHealth(100, 1, c), 100)
			t.Equal("a duo: still its own", Fight.CrowdHealth(100, c.From - 1, c), 100)
			t.Equal("the third adds its share", Fight.CrowdHealth(100, c.From, c), 100 * (1 + c.Share))
			t.Equal("each further one its share again", Fight.CrowdHealth(100, c.From + 1, c), 100 * (1 + 2 * c.Share))
			t.Equal("none: its own", Fight.CrowdHealth(100, 0, c), 100)
		end,
	},
	{
		Name = "Fight: a lead fights beyond its target, and walks round to get there",
		Run = function(t: any)
			local frame = Combat.Lead.Frame
			local step = Combat.Slots.Step
			-- The avatar at bearing 180 round the target (to its west): beyond is 0 (east), turned toward the lead's side.
			t.Check("from the north side, beyond and north", near(Fight.Beyond(180, 90, frame), frame), `{Fight.Beyond(180, 90, frame)}`)
			t.Check("from the south side, beyond and south", near(Fight.Beyond(180, -90, frame), -frame), `{Fight.Beyond(180, -90, frame)}`)
			t.Check("straight between the avatar and its target, still beyond", math.abs(Fight.Wrap(Fight.Beyond(180, 180, frame))) <= frame + 1e-6)
			t.Check("the avatar across the back of the circle", near(Fight.Beyond(-170, 0, frame), 10 - frame), `{Fight.Beyond(-170, 0, frame)}`)
			t.Check("a step at a time", near(Fight.Toward(180, 0, step), Fight.Wrap(180 + step)) or near(Fight.Toward(180, 0, step), Fight.Wrap(180 - step)))
			t.Check("the short way round", near(Fight.Toward(170, -170, step), -170), `{Fight.Toward(170, -170, step)}`)
			t.Check("there already, it stays", near(Fight.Toward(30, 30, step), 30))
			t.Check("never past its place", near(Fight.Toward(0, step / 2, step), step / 2))
		end,
	},
	{
		Name = "Fight: beside a wide target seen off to one side, a lead takes the side away from the player's line of sight",
		Run = function(t: any)
			local beside = Combat.Lead.Beside.Keeper
			local straight = Combat.Lead.Straight
			-- The avatar at bearing 180 round the target (to its west): beyond is 0 (east), and its sides are north and south.
			t.Check("seen off to the north, it stands north", near(Fight.Aside(180, 20, -90, beside, straight), beside), `{Fight.Aside(180, 20, -90, beside, straight)}`)
			t.Check("seen off to the south, it stands south", near(Fight.Aside(180, -20, 90, beside, straight), -beside), `{Fight.Aside(180, -20, 90, beside, straight)}`)
			t.Check("whichever side it stands on now", near(Fight.Aside(180, 20, 90, beside, straight), beside))
			t.Check("seen straight ahead, it keeps its nearer side", near(Fight.Aside(180, straight / 2, -90, beside, straight), -beside))
			t.Check("the keeper's turn puts it past straight", Combat.Keeper.Turn > straight)
		end,
	},
	{
		-- research's call on AR7's fix 4, option A (2026-11-13)
		Name = "Fight: beside a keeper, a lead takes the side toward the player's line of sight, so its walk-in never crosses it",
		Run = function(t: any)
			local beside = Combat.Lead.Beside.Keeper
			local straight = Combat.Lead.Straight
			t.Check("keepers are fought from the near side", (Combat.Lead.Near :: { [string]: boolean }).Keeper == true)
			t.Check("elites keep the far side", (Combat.Lead.Near :: { [string]: boolean }).Elite ~= true)
			t.Check("seen off to the north, it stands south", near(Fight.Aside(180, 20, -90, beside, straight, true), -beside), `{Fight.Aside(180, 20, -90, beside, straight, true)}`)
			t.Check("seen off to the south, it stands north", near(Fight.Aside(180, -20, 90, beside, straight, true), beside), `{Fight.Aside(180, -20, 90, beside, straight, true)}`)
			t.Check("whichever side it stands on now", near(Fight.Aside(180, 20, 90, beside, straight, true), -beside))
			t.Check("seen straight ahead, it still keeps its nearer side", near(Fight.Aside(180, straight / 2, -90, beside, straight, true), -beside))
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
			-- Health carries (TR12): its Regen a second, the same in a fight as out of one; nothing waits for a quiet moment.
			local regen = 20
			t.Equal("its Regen a second", Fight.Regen(50, 1000, regen, 1), 70)
			t.Check("frame by frame as by the second", near(Fight.Regen(50, 1000, regen, 1 / 60), 50 + regen / 60))
			t.Equal("never past the maximum", Fight.Regen(990, 1000, regen, 60), 1000)
			t.Equal("down, no healing", Fight.Regen(0, 1000, regen, 1), 0)
			for _, bad in { 0, -5, 0 / 0, math.huge } do
				t.Equal(`a rate of {bad} does nothing`, Fight.Regen(50, 1000, bad, 1), 50)
				t.Equal(`a time of {bad} does nothing`, Fight.Regen(50, 1000, regen, bad), 50)
			end
			t.Check("a new maximum keeps the share", near(Fight.Rescale(40, 80, 200), 100))
			t.Equal("from nothing, full", Fight.Rescale(0, 0, 200), 200)
		end,
	},
	{
		-- TR12, "Health carries" (docs/design.md, "Combat"): away from its plot a lead heals its Regen alone, so a pack's
		-- damage stays; on its plot, from nothing to full in about Home.Full seconds.
		Name = "Fight: TR12, a lead heals its Regen alone away from home, and to full in about 30 s on its plot",
		Run = function(t: any)
			local full = Combat.Lead.Home.Full
			t.Check("home's heal is about 30 s", full >= 20 and full <= 40, `{full}`)
			local regen, most = 20, 1000
			t.Equal("away from home: its Regen alone", Fight.RegenRate(regen, most, false, full), regen)
			t.Check("at home: nothing to full in Home.Full seconds besides", near(Fight.RegenRate(regen, most, true, full), regen + most / full))
			t.Equal("a bad Regen adds nothing", Fight.RegenRate(-5, most, false, full), 0)
			local function heal(home: boolean, seconds: number): number
				local health, frame = 1, 1 / 60
				for _ = 1, math.floor(seconds / frame + 0.5) do
					health = Fight.Regen(health, most, Fight.RegenRate(regen, most, home, full), frame)
				end
				return health
			end
			t.Check("at home: full by Home.Full", heal(true, full) == most, string.format("%.1f", heal(true, full)))
			t.Check("and not long before it", heal(true, full * 0.6) < most, string.format("%.1f", heal(true, full * 0.6)))
			local away = heal(false, full)
			t.Check("away, the same time heals only its Regen's worth", near(away, 1 + regen * full, 1e-6), string.format("%.1f", away))
		end,
	},
	{
		-- AR4: Pip's Lantern Burst lets its flame out over an area round its target.
		Name = "Fight: an area hit takes every enemy within its studs of the target, and a hit without one takes none",
		Run = function(t: any)
			local area = Actions.ById.PipLanternBurst.Hits.Burst.Area :: number
			t.Check("Lantern Burst has an area", type(area) == "number" and area > 0)
			t.Check("on the target", Fight.Within(0, area))
			t.Check("at its edge", Fight.Within(area, area))
			t.Check("not past it", not Fight.Within(area + 0.01, area))
			t.Check("no area, nobody else", not Fight.Within(0, 0))
			for _, action in Actions.List do
				for beat, hit in action.Hits do
					t.Check(`{action.Id}.{beat}: an area is positive when there is one`, hit.Area == nil or hit.Area > 0)
				end
			end
			-- Pip fights from his signature's spacing, so the clip's 12-stud throw lands a stud and a half short of the target.
			for _, id in Actions.Kits.pip do
				t.Check(`{id} is fought from the throw's spacing`, near(Actions.ById[id].Range - Combat.Approach, 13.5))
			end
		end,
	},
	{
		-- AR4, section 9: Lyric's Held Note touches every Shade in its cone on each crest, and heals her and her allies.
		Name = "Fight: the Held Note's five crests split its total, its cone reaches 14 studs, and a heal mends a share",
		Run = function(t: any)
			local note = Actions.ById.LyricHeldNote
			local crests = { "Note", "Crest2", "Crest3", "Crest4", "Release" }
			local total, healed, count = 0, 0, 0
			for _ in note.Hits do
				count += 1
			end
			t.Equal("five touches, one a crest", count, #crests)
			for i, beat in crests do
				local hit = note.Hits[beat]
				t.Check(`{beat} is a touch`, hit ~= nil)
				if hit == nil then
					continue
				end
				total += hit.Coefficient
				healed += hit.Heal or 0
				t.Check(`{beat}: each a fifth, the same`, near(hit.Coefficient, note.Hits.Note.Coefficient) and near(hit.Heal or 0, note.Hits.Note.Heal or 0))
				t.Check(`{beat}: the cone is 14 studs from her, 24 degrees a side from 3.9 behind her`, hit.Reach == 14 and hit.Cone == 24 and hit.Apex == 3.9)
				t.Check(`{beat}: her hold keeps its count`, hit.Steady == true)
				if i > 1 then
					t.Check(`{beat}: a half-beat after the last`, near(note.Beats[beat] - note.Beats[crests[i - 1]], 0.25))
				end
			end
			t.Check("the total is the seed's (2.5)", near(total, 2.5))
			-- Research's seed (AR4, section 9): 0.01 a touch, so a solo Lyric heals 0.5% a second, under a keeper's 1.2 to 2%.
			t.Check("the heal's total is a twentieth of her health", near(healed, 0.05))
			-- The cone, along and across the line to her target, its degrees from its point 3.9 behind her.
			local hit = note.Hits.Note
			local function inside(along: number, across: number): boolean
				return Fight.InCone(along, across, hit.Reach, hit.Cone :: number, hit.Apex :: number)
			end
			local edge = (11 + 3.9) * math.tan(math.rad(24))
			t.Check("at its end", inside(14, 0))
			t.Check("not past it", not inside(14.01, 0))
			t.Check("at its edge by the target, either side", inside(11, edge - 0.01) and inside(11, -(edge - 0.01)))
			t.Check("not outside it", not inside(11, edge + 0.01))
			t.Check("not past its end at the edge", not inside(12, 7.3))
			t.Check("never behind her", not inside(-1, 0) and not inside(-4, 0))
			t.Check("from her own spot it still reaches forward", inside(0.5, 0.1))
			-- The avatar in the game's framing (Combat.Lead.Frame): her target 11 out, she beyond it turned Frame from the
			-- avatar's line; the avatar `d` from the target stands past 14 from her once d passes 3.9 (fix 1, section 9).
			local frame = math.rad(Combat.Lead.Frame)
			for _, d in { 4, 5.2, 8 } do
				local away = math.sqrt(d * d + 121 + 2 * 11 * d * math.cos(frame))
				t.Check(`the avatar {d} from her target stands past the cone ({away})`, away > hit.Reach)
			end
			for _, id in Actions.Kits.lyric do
				t.Check(`{id} is fought where the cone's middle meets her target (11)`, near(Actions.ById[id].Range - Combat.Approach, 11))
			end
			t.Check("a heal mends a share of the most", near(Fight.Mend(50, 100, 0.04), 54))
			t.Equal("never past the most", Fight.Mend(99, 100, 0.04), 100)
			t.Equal("down stays down", Fight.Mend(0, 100, 0.04), 0)
			t.Equal("a bad share does nothing", Fight.Mend(50, 100, 0 / 0), 50)
			t.Equal("nor a negative one", Fight.Mend(50, 100, -0.1), 50)
		end,
	},
	{
		Name = "Fight: a Shade's burst plays the art sheet: the charge, the flare on the marker, the flame let go, the paper only rising",
		Run = function(t: any)
			-- docs/asset-requests.md, AR2, section 11, and its content check: the charge 18 to 26, the flare on the Burst frame
			-- (27), where the body hides; the flame 28 to 41; the paper 28 to 49, each scrap only rising, shrinking and ending.
			local art = ShadeBurstArt
			t.Equal("the Burst frame is the clip's marker's", art.Burst, 27)
			local span: { [string]: { number } } = {}
			local outside = 0
			for frame = art.First, art.Last do
				for _, picture in art.Frames[frame] or {} do
					local seen = span[picture.Kind] or { frame, frame }
					seen[1], seen[2] = math.min(seen[1], frame), math.max(seen[2], frame)
					span[picture.Kind] = seen
					local far = picture.Offset + picture.Rect
					if picture.Offset.X < 0 or picture.Offset.Y < 0 or far.X > art.Size.X or far.Y > art.Size.Y then
						outside += 1
					end
				end
			end
			local function between(kind: string, first: number, last: number)
				local seen = span[kind]
				t.Check(`the {kind} from {first} to {last}`, seen ~= nil and seen[1] == first and seen[2] == last, if seen then `{seen[1]} to {seen[2]}` else "none")
			end
			between("charge", 18, 26)
			between("flare", art.Burst, art.Burst)
			between("flame", 28, 41)
			between("scrap", 28, 49)
			t.Equal("every picture's rectangle inside the picture", outside, 0)
			local flare = (art.Frames[art.Burst] :: { ShadeBurstArt.Picture })[1]
			t.Check("the flare the coat's size, its top 0.9 over the collar", flare.Size == Vector2.new(3.8, 5.4) and near(flare.At.Z + flare.Size.Y / 2, 0.9, 1e-6))
			-- one scrap, one id: it only rises and shrinks, and once gone it never comes back
			local last: { [number]: ShadeBurstArt.Picture } = {}
			local ended: { [number]: boolean } = {}
			local falls, grows, returns, scraps = 0, 0, 0, 0
			for frame = art.First, art.Last do
				local now: { [number]: ShadeBurstArt.Picture } = {}
				for _, picture in art.Frames[frame] or {} do
					if picture.Kind == "scrap" then
						now[picture.Id] = picture
					end
				end
				for id, picture in now do
					local before = last[id]
					if ended[id] then
						returns += 1
					elseif before then
						falls += if picture.At.Z < before.At.Z - 1e-9 then 1 else 0
						grows += if picture.Size.X > before.Size.X + 1e-9 then 1 else 0
					else
						scraps += 1
					end
				end
				for id in last do
					if now[id] == nil then
						ended[id] = true
					end
				end
				last = now
			end
			t.Equal("ten scraps", scraps, 10)
			t.Equal("no scrap ever falls", falls, 0)
			t.Equal("no scrap ever grows", grows, 0)
			t.Equal("none comes back once gone", returns, 0)
			-- AR2, section 13: a clip that never reaches its marker bursts anyway, after the longest hold pauses it and with
			-- the replication's delay to spare before the server takes the body away
			local wait = EffectsConfig.ShadeBurst.Wait
			local forced = art.Burst / 60 + wait
			t.Check("the burst waits out the longest hold", wait > Fight.LongestHold(Combat.Hitstop), `{wait} s against {Fight.LongestHold(Combat.Hitstop)}`)
			t.Check("and bursts a held clip a fifth of a second or more before the body goes", forced <= Combat.Shade.FadeSeconds - 0.2, string.format("%.2f s of %.2f", forced, Combat.Shade.FadeSeconds))
		end,
	},
	{
		-- AR7, sections 4 and 5: the keeper falls into the Shade's burst on its own clip's Burst, its lantern gutters, goes
		-- out and goes to paper at Gone, and the server keeps the body until then; it walks at its own pace.
		Name = "Fight: the keeper's fall keeps its order and its body to Gone, and it walks its walk",
		Run = function(t: any)
			local row = Enemies.ById.lamplighter
			local fall = (EffectsConfig.Falls :: any)[row.Rig]
			t.Check("the keeper's rig has its fall", fall ~= nil)
			if fall == nil then
				return
			end
			t.Check("Burst, Gutter, Out, Gone, in order", fall.Burst < fall.Gutter and fall.Gutter < fall.Out and fall.Out < fall.Gone)
			t.Equal("its fall is its rig's Down", Animations.Roles[Animations.Rigs[row.Rig].Down], "Burst")
			local hold = Fight.LongestHold(Combat.Hitstop)
			local keeper = Combat.Keeper
			local gone = fall.Gone / 60 + hold
			t.Check("Gone, after the longest hold, a fifth of a second or more before the body goes", gone <= keeper.FadeSeconds - 0.2, string.format("%.2f s of %.2f", gone, keeper.FadeSeconds))
			local forced = fall.Burst / 60 + EffectsConfig.ShadeBurst.Wait
			t.Check("a held clip's burst, forced, as early", forced <= keeper.FadeSeconds - 0.2, string.format("%.2f s of %.2f", forced, keeper.FadeSeconds))
			t.Check("and the body goes before the try's fade", keeper.FadeSeconds < keeper.WinPause)
			-- research's verdict on the install, fix 3: out reads, the paper dark and unlit a third of a second before Gone,
			-- going down from Gutter, eased in, to a deep blue-grey at about a third of its value
			t.Check("Out to Gone about a third of a second", (fall.Gone - fall.Out) / 60 >= 0.3 and (fall.Gone - fall.Out) / 60 <= 0.45, string.format("%.2f s", (fall.Gone - fall.Out) / 60))
			local _, saturation, value = fall.Dark:ToHSV()
			t.Check("its paper down to a deep blue-grey", value >= 0.2 and value <= 0.45 and saturation > 0.05 and saturation < 0.45 and fall.Dark.B > fall.Dark.R, string.format("value %.2f, saturation %.2f", value, saturation))
			t.Check("eased in", fall.Ease > 1)
			-- the scraps finish before the try's fade begins
			local last = fall.Gone / 60 + hold + (ShadeBurstArt.Last - ShadeBurstArt.Burst) / 60
			t.Check("its scraps' last before the try's fade", last <= keeper.WinPause, string.format("%.2f s of %.2f", last, keeper.WinPause))
			-- the paper is the burst's scraps, by id: the lantern's first, then the pole's
			local scraps: { [number]: boolean } = {}
			for _, pictures in ShadeBurstArt.Frames do
				for _, picture in pictures do
					if picture.Kind == "scrap" then
						scraps[picture.Id] = true
					end
				end
			end
			local wanted = fall.Scraps.Lantern + fall.Scraps.Pole
			local all = fall.Scraps.Lantern >= 1 and fall.Scraps.Pole >= 1
			for id = 1, wanted do
				all = all and scraps[id] == true
			end
			t.Check("its scraps are the burst's own", all, `{wanted} wanted`)
			t.Check("its lantern dims to a floor above nothing", fall.Flicker.Low > 0 and fall.Flicker.Low < 1 and fall.Glow > 0)
			-- research's tier 2 (AR7, section 4): its own speed near 5, the clip near rate 1, never past 1.4
			local rate = keeper.WalkSpeed / Animations.Strides[Animations.Rigs[row.Rig].Walk]
			t.Check("its walk plays near rate 1, never past 1.4", rate >= 0.9 and rate <= 1.42, string.format("rate %.2f", rate))
		end,
	},
	{
		-- AR1, section 8: a server-moved body reaches a client's screen late, so the client draws the push itself.
		Name = "Fight: the drawn push reaches the hit's push by the end of the server's, and hands it back",
		Run = function(t: any)
			-- the combo's ram, the game's longest push since Haymaker pins (AR8, "B5")
			local push = Combat.Push
			for _, kind in { "Dummy", "Elite" } do
				local studs = Actions.ById.RookCombo.Hits.Hit3.Push * (Combat.Weight :: { [string]: number })[kind]
				t.Equal(`{kind}: nothing drawn through the hold`, Fight.KnockAhead(studs, -0.05, 0, push), 0)
				t.Check(`{kind}: half the server's push, half the studs`, near(Fight.KnockAhead(studs, push.Seconds / 2, 0, push) :: number, studs / 2))
				t.Check(`{kind}: by its end, all of Push × weight`, near(Fight.KnockAhead(studs, push.Seconds, 0, push) :: number, studs))
				t.Check(`{kind}: only what the replica hasn't brought`, near(Fight.KnockAhead(studs, push.Seconds, studs * 0.3, push) :: number, studs * 0.7))
				t.Equal(`{kind}: never drawn back past the replica`, Fight.KnockAhead(studs, push.Seconds / 2, studs, push), 0)
				t.Equal(`{kind}: handed back once the replica has it all`, Fight.KnockAhead(studs, push.Seconds, studs, push), nil)
				local midway = push.Seconds + push.Wait + push.HandBack / 2
				t.Check(`{kind}: what never came is let go over HandBack`, near(Fight.KnockAhead(studs, midway, 0, push) :: number, studs / 2))
				t.Equal(`{kind}: and then over`, Fight.KnockAhead(studs, push.Seconds + push.Wait + push.HandBack + 0.01, 0, push), nil)
			end
			t.Equal("no push, nothing drawn", Fight.KnockAhead(0, push.Seconds, 0, push), nil)
			t.Check("an instant push is all there at once", near(Fight.KnockAhead(4, 0, 0, { Seconds = 0, Wait = 0.4, HandBack = 0.1 }) :: number, 4))
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
	{
		Name = "Fight: a hit's levers grow with its rung (AR8 A)",
		Run = function(t: any)
			-- docs/research/vfx-reference.md, rules 1 and 2: the hold, the flash, the tremble and the camera's trauma by the
			-- hit's rung on the ladder; a critical raised, a killing hit holding at least its own.
			local hitstop = Combat.Hitstop
			local rows = hitstop.Rungs
			t.Check("rows", #rows >= 3)
			for k = 2, #rows do
				local a, b = rows[k - 1], rows[k]
				t.Check(`row {k} sits higher on the ladder`, b.From > a.From)
				t.Check(`row {k} holds no shorter`, b.Hold >= a.Hold)
				t.Check(`row {k} flashes no shorter`, b.Flash >= a.Flash)
				t.Check(`row {k} glows no less`, b.Glow >= a.Glow)
				t.Check(`row {k} trembles no less`, b.Tremble >= a.Tremble)
				t.Check(`row {k} jolts no less`, b.Trauma >= a.Trauma)
			end
			for _, row in rows do
				t.Check(`rung {row.From}: a hold of 0.03 to 0.2 s`, row.Hold >= 0.03 and row.Hold <= 0.2, `{row.Hold}`)
				t.Check(`rung {row.From}: a glow inside 0 to 1`, row.Glow > 0 and row.Glow <= 1)
				t.Check(`rung {row.From}: trauma inside 0 to 1`, row.Trauma >= 0 and row.Trauma <= 1)
				-- nothing below 7 takes the top value for more than a picture or two (rule 1)
				if row.From < 7 then
					t.Check(`rung {row.From}: below the top value`, row.Glow < 0.8, `{row.Glow}`)
					t.Equal(`rung {row.From}: no tremble`, row.Tremble, 0)
				else
					t.Check(`rung {row.From}: it trembles`, row.Tremble > 0)
				end
			end
			-- the ladder's own rungs (rule 1)
			t.Equal("an ordinary hit is 2", Fight.Rung(nil, false, hitstop), 2)
			t.Equal("a critical ordinary hit is the critical's", Fight.Rung(nil, true, hitstop), hitstop.Critical)
			t.Equal("a critical signature keeps its own", Fight.Rung(7, true, hitstop), 7)
			t.Equal("rung 5 takes rung 4's row", Fight.Lever(5, hitstop).From, 4)
			t.Equal("below the ladder takes the lowest row", Fight.Lever(1, hitstop).From, rows[1].From)
			t.Equal("past the top takes the top", Fight.Lever(10, hitstop).From, rows[#rows].From)
			-- the study's starting numbers (rule 2)
			local ordinary, critical, signature = Fight.Hold(2, false, hitstop), Fight.Hold(4, false, hitstop), Fight.Hold(7, false, hitstop)
			t.Check("an ordinary hit holds 0.04 to 0.05 s", ordinary >= 0.04 and ordinary <= 0.05, `{ordinary}`)
			t.Check("a critical holds about 0.07 s", near(critical, 0.07, 0.15), `{critical}`)
			t.Check("a signature holds 0.12 to 0.14 s", signature >= 0.12 and signature <= 0.14, `{signature}`)
			t.Equal("a killing ordinary hit holds the kill's", Fight.Hold(2, true, hitstop), hitstop.Kill)
			t.Equal("a killing signature keeps its longer own", Fight.Hold(7, true, hitstop), math.max(signature, hitstop.Kill))
			t.Check("the longest hold is the longest", Fight.LongestHold(hitstop) >= signature and Fight.LongestHold(hitstop) >= hitstop.Kill)
			-- every hit's rung is on the ladder, a signature's at 7 or more
			for _, action in Actions.List do
				for beat, hit in action.Hits do
					local rung = hit.Rung or 2
					t.Check(`{action.Id}.{beat}: rung 2 to 9`, rung >= 2 and rung <= 9, `{rung}`)
				end
			end
			t.Check("Haymaker is a signature's", (Actions.ById.RookHaymaker.Hits.Strike.Rung or 2) >= 7)
			t.Check("Lantern Burst is a signature's", (Actions.ById.PipLanternBurst.Hits.Burst.Rung or 2) >= 7)
			t.Equal("the combo's ram is its last", Actions.ById.RookCombo.Hits.Hit3.Rung, 3)
			t.Equal("the Shade's swing is 3", Actions.ById.ShadeSwipe.Hits.Hit.Rung, 3)
			-- the flash: its top at once, eased out, gone at its end
			t.Equal("the flash starts at its glow", Fight.Flash(0, 0.06, 0.5), 0.5)
			t.Check("eased: under half by halfway", Fight.Flash(0.03, 0.06, 0.5) < 0.25)
			t.Equal("gone at its end", Fight.Flash(0.06, 0.06, 0.5), 0)
			t.Equal("nothing before it", Fight.Flash(-0.01, 0.06, 0.5), 0)
			-- the tremble shrinks across the hold to nothing
			t.Equal("the tremble at its full at the hold's start", Fight.Tremble(0, 0.13, 0.2), 0.2)
			t.Check("half by half the hold", near(Fight.Tremble(0.065, 0.13, 0.2), 0.1, 1e-6))
			t.Equal("none once the hold is over", Fight.Tremble(0.13, 0.13, 0.2), 0)
			-- trauma: added and capped, falling over Decay, the shake its square
			t.Equal("trauma adds", Fight.Trauma(0.3, 0.5), 0.8)
			t.Equal("capped at 1", Fight.Trauma(0.8, 0.8), 1)
			t.Equal("never taken by a jolt", Fight.Trauma(0.5, -1), 0.5)
			t.Check("falls by dt over decay", near(Fight.TraumaAfter(1, 0.1, 0.4), 0.75, 1e-9))
			t.Equal("never below nothing", Fight.TraumaAfter(0.1, 1, 0.4), 0)
			t.Equal("the shake is its square", Fight.ShakeOf(0.5), 0.25)
			local shake = Combat.Shake
			t.Check("a decay of 0.3 to 0.4 s (rule 2)", shake.Decay >= 0.3 and shake.Decay <= 0.4, `{shake.Decay}`)
			t.Check("a signature's jolt shakes over twice a critical's", Fight.ShakeOf(Fight.Lever(7, hitstop).Trauma) > 2 * Fight.ShakeOf(Fight.Lever(4, hitstop).Trauma))
		end,
	},
	{
		-- docs/design.md, "Combat", the skip back (TR7, part 2): its seeds, its rows, when it's taken, where it goes.
		Name = "Fight: a ranged lead skips back when an enemy closes, never into a swing already coming, to its place first (TR7)",
		Run = function(t: any)
			local skip = Combat.Skip
			t.Check("on", skip.On == true)
			t.Check("Close past a Shade's swing (4 studs)", skip.Close > 4 and skip.Close <= 8, `{skip.Close}`)
			t.Check("Every a few seconds", skip.Every >= 2 and skip.Every <= 8, `{skip.Every}`)
			t.Check("Step divides the half turn", skip.Step > 0 and (180 / skip.Step) % 1 == 0, `{skip.Step}`)
			-- every Mage and Healer with a kit has a skip, nobody else; a skip is never in a kit, never hits, lands on Land
			for _, row in Voidkin.List do
				local ranged = row.Class == "Mage" or row.Class == "Healer"
				local action = Actions.SkipOf(row.Id)
				if Actions.Kits[row.Id] then
					t.Check(`{row.Id}: a skip if and only if ranged`, (action ~= nil) == ranged, `{row.Class}`)
				end
				if action then
					local land = action.Beats.Land
					local hits = 0
					for _ in action.Hits do
						hits += 1
					end
					t.Check(`{action.Id}: no hit, no cooldown, no range`, hits == 0 and action.Cooldown == 0 and action.Range == 0)
					t.Check(`{action.Id}: lands about 0.35 s in, cut from there`, land ~= nil and math.abs(land - 0.35) < 0.05 and action.CancelFrom == land and land < action.Length, `{land}`)
					t.Equal(`{action.Id}: its clip's role`, Animations.Roles[action.Clip :: string], "Skip")
					for _, id in Actions.Kits[row.Id] or {} do
						t.Check(`{action.Id}: not in the kit`, id ~= action.Id, id)
					end
				end
			end
			t.Check("Skip has its fades", Animations.Fades.Skip ~= nil)
			-- when
			t.Equal("an enemy inside Close, its last skip long ago: skips", Fight.ShouldSkip(skip.Close - 0.5, math.huge, false, skip), true)
			t.Equal("an enemy at Close: no", Fight.ShouldSkip(skip.Close, math.huge, false, skip), false)
			t.Equal("its last skip under Every ago: no", Fight.ShouldSkip(1, skip.Every - 0.01, false, skip), false)
			t.Equal("at Every: yes", Fight.ShouldSkip(1, skip.Every, false, skip), true)
			t.Equal("a swing at it winding up: no", Fight.ShouldSkip(1, math.huge, true, skip), false)
			-- where: its place first, its own side first at each step, out to straight across, each once
			local tries = Fight.SkipBearings(30, 30, 50)
			t.Equal("its place first", tries[1], 30)
			t.Equal("then its own side", tries[2], 60)
			t.Equal("then the other", tries[3], 0)
			t.Equal("straight across last", tries[#tries], -150)
			t.Equal("every step once", #tries, 12)
			local other = Fight.SkipBearings(30, 30, 10)
			t.Equal("standing on the other side, that side first", other[2], 0)
			local seen: { [number]: boolean } = {}
			local once = true
			for _, bearing in Fight.SkipBearings(-170, 30, 0) do
				local key = math.floor(bearing + 0.5)
				once = once and not seen[key] and bearing > -180 - 1e-9 and bearing <= 180
				seen[key] = true
			end
			t.Check("wrapped, none twice", once)
			-- the way: never nearer an enemy than Body; from point blank, only straight away
			local body = skip.Body
			t.Equal("away from it: clear", Fight.SkipKeepsClear(Vector3.new(0, 0, 0), Vector3.new(-10, 0, 0), Vector3.new(2, 0, 0), body), true)
			t.Equal("past it: not", Fight.SkipKeepsClear(Vector3.new(0, 0, 0), Vector3.new(10, 0, 0), Vector3.new(5, 0, 0.5), body), false)
			t.Equal("beside the way, Body off: clear", Fight.SkipKeepsClear(Vector3.new(0, 0, 0), Vector3.new(10, 0, 0), Vector3.new(5, 0, body + 0.1), body), true)
			t.Equal("from point blank, straight away: clear", Fight.SkipKeepsClear(Vector3.new(0, 0, 0), Vector3.new(-10, 0, 0), Vector3.new(0.5, 0, 0), body), true)
			t.Equal("from point blank, across it: not", Fight.SkipKeepsClear(Vector3.new(0, 0, 0), Vector3.new(0, 0, 10), Vector3.new(0.5, 0, 0.5), body), false)
			t.Equal("height doesn't count", Fight.SkipKeepsClear(Vector3.new(0, 3, 0), Vector3.new(-10, 3, 0), Vector3.new(2, 0, 0), body), true)
		end,
	},
}
