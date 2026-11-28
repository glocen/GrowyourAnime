--!strict
-- Logic cases (pure): TR12, "Health carries" (docs/design.md, "Combat", "Health carries" to "The next lead"; "The base",
-- "The Training machine"): what a Voidkin carries between fights, the fallen lead's way home, the next lead, and the
-- Training machine across time in the game and time away, on the base's clock since it draws power (TR18).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Carry = require(Shared.Rules.Carry)
local Training = require(Shared.Rules.Training)
local Breaker = require(Shared.Rules.Breaker)
local BaseConfig = require(Shared.Config.Base)
local Growth = require(Shared.Rules.Growth)
local Collection = require(Shared.Rules.Collection)
local Hud = require(Shared.Rules.Hud)
local Combat = require(Shared.Config.Combat)
local GrowthConfig = require(Shared.Config.Growth)
local WorldConfig = require(Shared.Config.World)
local StagesConfig = require(Shared.Config.Stages)
local DropsConfig = require(Shared.Config.Drops)

local NOW = 1_800_000_000

local function near(a: number, b: number, tolerance: number?): boolean
	return math.abs(a - b) <= (tolerance or 1e-9)
end

local function owned(level: number, xp: number?): Profile.OwnedVoidkin
	local data = Profile.Template()
	local id = Collection.Uncover(data, "rook", NOW).Id
	local one = data.Voidkin[id]
	one.Level, one.Xp = level, xp or 0
	return one
end

-- Seconds of training from the start of `level` to the start of `level + 1`.
local function levelSeconds(level: number): number
	return (Growth.XpToNext(level) :: number) / Training.Rate()
end

return {
	{
		Name = "Training: TR12, a Voidkin carries its health home, heals there, and a fallen one waits until it's whole",
		Run = function(t: any)
			local home = Combat.Lead.Home
			t.Check("the fallen heal is about 90 s", home.Fallen >= 60 and home.Fallen <= 120, `{home.Fallen}`)
			t.Check("and slower than one that only got hurt", home.Fallen > home.Full)
			t.Equal("no entry: whole", Carry.Share(nil, NOW, home), 1)
			local hurt: Carry.Entry = { Share = 0.4, At = NOW, Fallen = false }
			t.Equal("taken in hurt, it keeps its share", Carry.Share(hurt, NOW, home), 0.4)
			t.Check("and heals at home's rate", near(Carry.Share(hurt, NOW + home.Full / 2, home), 0.9))
			t.Equal("never past whole", Carry.Share(hurt, NOW + 1e6, home), 1)
			t.Check("whole at its time", near(Carry.WholeAt(hurt, home), NOW + 0.6 * home.Full))
			local fell: Carry.Entry = { Share = 0, At = NOW, Fallen = true }
			t.Check("a fallen one heals at the fallen rate", near(Carry.Share(fell, NOW + home.Fallen / 2, home), 0.5))
			t.Check("whole about 90 s on", near(Carry.WholeAt(fell, home), NOW + home.Fallen))
			t.Equal("a clock gone back changes nothing", Carry.Share(fell, NOW - 50, home), 0)
			t.Equal("a bad share is nothing", Carry.Mend(0 / 0, 0, 90), 0)
			t.Equal("no time to full: whole", Carry.Mend(0.2, 1, 0), 1)
		end,
	},
	{
		Name = "Training: TR12, a fall, the trip home and following again",
		Run = function(t: any)
			local leave = Combat.Lead.Leave
			t.Check("the fall is seen before it leaves", leave >= 0.8 and leave <= 3, `{leave}`)
			t.Equal("down while its fall plays", Carry.Fallen("Down", leave - 0.01, false, leave, false), "Down")
			t.Equal("then home, as light", Carry.Fallen("Down", leave, false, leave, false), "Home")
			t.Equal("home even when its player's on the plot: it lands there first", Carry.Fallen("Down", leave, true, leave, true), "Home")
			t.Equal("it waits at home, whole, while its player is away", Carry.Fallen("Home", 1e6, false, leave, true), "Home")
			t.Equal("it heals before it follows, the player home or not", Carry.Fallen("Home", 0, true, leave, false), "Home")
			t.Equal("it follows once whole and its player's on the plot", Carry.Fallen("Home", 0, true, leave, true), "Idle")
			t.Equal("a standing lead is its own", Carry.Fallen("Idle", 99, true, leave, false), "Idle")
			t.Equal("the card: down as it falls", Hud.LeadStatus("Down", NOW + 1, NOW, false), "Down")
			t.Equal("the card: healing, with its time", Hud.LeadStatus("Home", NOW + 72.2, NOW, false), "Healing 1:13")
			t.Equal("the card: training once healed", Hud.LeadStatus("Home", NOW, NOW, true), "Training")
			t.Equal("the card: at home when the machine has another", Hud.LeadStatus("Home", NOW - 1, NOW, false), "At base")
			t.Equal("the card: nothing while it stands", Hud.LeadStatus("Idle", 0, NOW, false), nil)
			t.Equal("a clock: seconds", Hud.Clock(9), "0:09")
			t.Equal("a clock: rounded up", Hud.Clock(64.1), "1:05")
			t.Equal("a clock: never below nothing", Hud.Clock(-3), "0:00")
		end,
	},
	{
		Name = "Training: TR12, the next lead goes out at once, anywhere out of combat, never a fallen one still healing",
		Run = function(t: any)
			local home = Combat.Lead.Home
			t.Equal("out of combat, a whole one goes", Carry.Refusal(false, nil, NOW, home), nil)
			t.Equal("never in a fight", Carry.Refusal(true, nil, NOW, home), Carry.InCombat)
			local fell: Carry.Entry = { Share = 0, At = NOW, Fallen = true }
			t.Equal("a fallen one still healing stays home", Carry.Refusal(false, fell, NOW + 10, home), Carry.Healing)
			t.Equal("and goes once it's whole", Carry.Refusal(false, fell, NOW + home.Fallen, home), nil)
			local hurt: Carry.Entry = { Share = 0.3, At = NOW, Fallen = false }
			t.Equal("one that's hurt but never fell may go as it is", Carry.Refusal(false, hurt, NOW, home), nil)
			t.Equal("the screen says it's in a fight", Hud.LeadReason("", nil, NOW, true), "In a fight")
			t.Equal("the screen says it's healing, with its time", Hud.LeadReason("", NOW + 30, NOW, false), "Healing 0:30")
			t.Equal("healed: free", Hud.LeadReason("", NOW - 1, NOW, false), nil)
			t.Equal("the lead is still the lead", Hud.LeadReason("Lead", NOW + 30, NOW, true), "Leading")
		end,
	},
	{
		Name = "Training: TR12, the machine trains at a fixed third of Lantern Row's pace, level by level, and keeps what's left",
		Run = function(t: any)
			local share = GrowthConfig.Training.Share
			t.Check("about a third", share >= 0.25 and share <= 0.4, `{share}`)
			-- Lantern Row's fighting, a second, as its stages are played (TR43): in each stage of packs and an elite, its
			-- quota of Shades, one of its packs' levels each in turn, then its elite, each kill as Drops pays it (the
			-- director, 2026-11-14: "Fixed rate, no cap").
			local kills, xp = 0, 0
			for _, stage in StagesConfig.Grounds[WorldConfig.Row.Ground] do
				local last = stage.Stops[#stage.Stops]
				local levels: { number } = {}
				for _, stop in stage.Stops do
					if stop.Kind == "Pack" then
						table.insert(levels, stop.Level)
					end
				end
				if last.Kind == "Elite" and #levels > 0 then
					for kill = 1, stage.Quota do
						kills += 1
						xp += GrowthConfig.XpPerKillPerG * Growth.G(levels[(kill - 1) % #levels + 1]) * DropsConfig.Share.Ordinary
					end
					kills += 1
					xp += GrowthConfig.XpPerKillPerG * Growth.G(last.Level) * DropsConfig.Share.Elite
				end
			end
			local fight = GrowthConfig.KillsPerHour / 3600 * xp / kills
			t.Check("a third of what fighting earns in Lantern Row", near(Training.Rate(), share * fight), string.format("%.4f a second, fighting %.4f", Training.Rate(), fight))
			t.Check("about 37 a minute on the stages' seeds at the measured 386 kills an hour (TR72's session)", Training.Rate() * 60 > 32 and Training.Rate() * 60 < 42, string.format("%.1f", Training.Rate() * 60))
			local one = owned(5)
			local gained, left = Training.Gain(one, levelSeconds(5) / 2)
			t.Check("half a level's time: half its experience", gained == 0 and math.abs(one.Xp - (Growth.XpToNext(5) :: number) / 2) <= 1, `{one.Xp}`)
			t.Check("what isn't a whole point is kept", left >= 0 and left * Training.Rate() < 1, `{left}`)
			one = owned(5)
			gained = Training.Gain(one, levelSeconds(5) + levelSeconds(6) + 1)
			t.Check("two levels, each at its own rate", gained == 2 and one.Level == 7, `{gained}, level {one.Level}`)
			t.Check("no cap: each level's rising cost slows it", levelSeconds(15) > levelSeconds(5) and levelSeconds(30) > levelSeconds(15))
			one = owned(GrowthConfig.MaxLevel)
			gained, left = Training.Gain(one, 1e6)
			t.Check("nothing past the last level", gained == 0 and one.Level == GrowthConfig.MaxLevel and one.Xp == 0 and left == 0)
			one = owned(3, 7)
			gained = Training.Gain(one, 0 / 0)
			t.Check("a bad time does nothing", gained == 0 and one.Level == 3 and one.Xp == 7)
		end,
	},
	{
		Name = "Training: TR12, who trains: the lead away, a fallen one healed at home, nobody with the player home",
		Run = function(t: any)
			local healed = { { Id = "k2", Fell = NOW }, { Id = "k3", Fell = NOW + 5 } }
			t.Equal("nobody while the player's on the plot", Training.Who(true, "k1", true, healed), nil)
			t.Equal("the lead, fallen and healed, waiting at home", Training.Who(false, "k1", true, healed), "k1")
			t.Equal("else the last to fall among those healed", Training.Who(false, "k1", false, healed), "k3")
			t.Equal("nobody healed, nobody trains", Training.Who(false, "k1", false, {}), nil)
		end,
	},
	{
		Name = "Training: TR12 and TR18, the machine across a leave on the base's clock: full while the battery lasts, then the floor, with no cap",
		Run = function(t: any)
			local data = Profile.Template()
			local lead = Collection.Uncover(data, "rook", NOW).Id
			data.Roles.Lead = lead
			data.Base.Charge = Breaker.Capacity(data.Base) -- no workers: the battery runs it, then the floor
			local first = Breaker.Advance(data, NOW, true)
			t.Check("the first advance only sets the stamp", first.Trained == nil and data.Base.Stamp == NOW)
			-- A night away: the lead trains from the stamp to the join.
			local night = NOW + 8 * 3600
			local summary = Breaker.Advance(data, night, true)
			local level = data.Voidkin[lead].Level
			t.Check("a night away trains the lead", summary.Trained == lead and summary.Levels > 0 and level > 1, `level {level}`)
			local expect = owned(1)
			local full = math.min(8, Breaker.Capacity(data.Base) / BaseConfig.Training.Kw)
			Training.Gain(expect, full * 3600 + (8 - full) * 3600 * BaseConfig.Power.MinSpeed)
			t.Check("at full power while the battery lasts, then at the floor", expect.Level == level and math.abs(expect.Xp - data.Voidkin[lead].Xp) <= 1, `{expect.Level}/{expect.Xp} against {level}/{data.Voidkin[lead].Xp}`)
			t.Check("the battery spent", data.Base.Charge == 0)
			local copy = Profile.Template()
			local same = Collection.Uncover(copy, "rook", NOW).Id
			copy.Roles.Lead = same
			copy.Base.Charge = Breaker.Capacity(copy.Base)
			Breaker.Advance(copy, NOW, true)
			for hour = 1, 8 do
				Breaker.Advance(copy, NOW + hour * 3600, true)
			end
			t.Check("the same night in steps gives the same", copy.Voidkin[same].Level == level and math.abs(copy.Voidkin[same].Xp - data.Voidkin[lead].Xp) <= 8, `{copy.Voidkin[same].Level}/{copy.Voidkin[same].Xp} and {level}/{data.Voidkin[lead].Xp}`)
			-- A long leave: no cap but the last level, at the floor's pace.
			Breaker.Advance(data, night + 40 * 365 * 24 * 3600, true) -- forty years at the floor: past the cap at 125 (TR14)
			t.Check("a long leave: no cap but the last level", data.Voidkin[lead].Level == GrowthConfig.MaxLevel, `{data.Voidkin[lead].Level}`)
			-- Online with nobody on it, nobody trains.
			data.Training.Trainee = ""
			local later = Breaker.Advance(data, night + 41 * 365 * 24 * 3600)
			t.Check("nobody on it: nothing given", later.Trained == nil and later.Levels == 0)
		end,
	},
	{
		Name = "Training: TR24's fix 5, until a keeper is beaten a fallen one's wait is short enough to walk home, and the game's after",
		Run = function(t: any)
			local times = Combat.Lead.Home
			t.Check("the first session's wait is the shorter", times.FirstFallen < times.Fallen and times.FirstFallen > 0, `{times.FirstFallen} of {times.Fallen}`)
			t.Check("a walk home's length: half a minute or less", times.FirstFallen <= 30, tostring(times.FirstFallen))
			local none = Carry.HomeFor(times, nil)
			t.Equal("a new account: the short wait", none.Fallen, times.FirstFallen)
			t.Equal("its home heal untouched", none.Full, times.Full)
			local opened = { lanternrow = { KeeperWins = { Normal = 0, Hard = 0 } } }
			t.Equal("a ground opened, its keeper standing: still short", Carry.HomeFor(times, opened).Fallen, times.FirstFallen)
			local won = { lanternrow = { KeeperWins = { Normal = 0, Hard = 0 } }, second = { KeeperWins = { Normal = 0, Hard = 1 } } }
			t.Equal("a keeper beaten in any ground: the game's wait", Carry.HomeFor(times, won).Fallen, times.Fallen)
			t.Equal("and its home heal", Carry.HomeFor(times, won).Full, times.Full)
			local bad = Carry.HomeFor({ Full = 30, Fallen = 90, FirstFallen = 0 / 0 }, nil)
			t.Equal("no number: the game's wait", bad.Fallen, 90)
			-- the wait carries through the rules that read it
			local entry: Carry.Entry = { Share = 0, At = NOW, Fallen = true }
			local short = Carry.HomeFor(times, nil)
			t.Check("whole after the short wait", near(Carry.WholeAt(entry, short), NOW + times.FirstFallen))
			t.Check("sent out once whole", Carry.Refusal(false, entry, NOW + times.FirstFallen, short) == nil)
			t.Equal("still healing just before", Carry.Refusal(false, entry, NOW + times.FirstFallen - 1, short), Carry.Healing)
		end,
	},
}
