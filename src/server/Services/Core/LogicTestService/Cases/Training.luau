--!strict
-- Logic cases (pure): TR12, "Health carries" (docs/design.md, "Combat", "Health carries" to "The next lead"; "The base",
-- "The Training machine"): what a Voidkin carries between fights, the fallen lead's way home, the next lead, and the
-- Training machine across time in the game and time away.

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Carry = require(Shared.Rules.Carry)
local Training = require(Shared.Rules.Training)
local Growth = require(Shared.Rules.Growth)
local Collection = require(Shared.Rules.Collection)
local Hud = require(Shared.Rules.Hud)
local Combat = require(Shared.Config.Combat)
local GrowthConfig = require(Shared.Config.Growth)

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
	return (Growth.XpToNext(level) :: number) / Training.Rate(level)
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
			t.Equal("the card: healing at home, with its time", Hud.LeadStatus("Home", NOW + 72.2, NOW, false), "Healing at home 1:13")
			t.Equal("the card: training once healed", Hud.LeadStatus("Home", NOW, NOW, true), "Training")
			t.Equal("the card: at home when the machine has another", Hud.LeadStatus("Home", NOW - 1, NOW, false), "At home")
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
		Name = "Training: TR12, the machine trains at a third of a fight's pace, level by level, and keeps what's left",
		Run = function(t: any)
			local share = GrowthConfig.Training.Share
			t.Check("about a third", share >= 0.25 and share <= 0.4, `{share}`)
			for _, level in { 1, 5, 15, 40 } do
				local fight = GrowthConfig.KillsPerHour / 3600 * Growth.XpPerKill(level)
				t.Check(`a third of a fight's experience at {level}`, near(Training.Rate(level), share * fight))
			end
			local one = owned(5)
			local gained, left = Training.Gain(one, levelSeconds(5) / 2)
			t.Check("half a level's time: half its experience", gained == 0 and math.abs(one.Xp - (Growth.XpToNext(5) :: number) / 2) <= 1, `{one.Xp}`)
			t.Check("what isn't a whole point is kept", left >= 0 and left * Training.Rate(5) < 1, `{left}`)
			one = owned(5)
			gained = Training.Gain(one, levelSeconds(5) + levelSeconds(6) + 1)
			t.Check("two levels, each at its own rate", gained == 2 and one.Level == 7, `{gained}, level {one.Level}`)
			t.Check("the second is slower than the first: no cap, each level's cost slows it", levelSeconds(15) > levelSeconds(5))
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
		Name = "Training: TR12, the machine across a leave, a long one included, with no cap",
		Run = function(t: any)
			local data = Profile.Template()
			local lead = Collection.Uncover(data, "rook", NOW).Id
			data.Roles.Lead = lead
			local who, gained = Training.Advance(data, NOW, lead)
			t.Check("the first call only sets the stamp", who == nil and gained == 0 and data.Training.Stamp == NOW)
			-- A night away: the lead trains from the stamp to the join.
			local night = NOW + 8 * 3600
			who, gained = Training.Advance(data, night, lead)
			local level = data.Voidkin[lead].Level
			t.Check("a night away trains the lead", who == lead and gained > 0 and level > 1, `level {level}`)
			t.Check("the stamp keeps only what wasn't a whole point", data.Training.Stamp <= night and night - data.Training.Stamp < 1 / Training.Rate(level) + 1e-6)
			local copy = Profile.Template()
			local same = Collection.Uncover(copy, "rook", NOW).Id
			copy.Voidkin[same].Level = 1
			local inSteps = 0
			copy.Training.Stamp = NOW
			for hour = 1, 8 do
				local _, g = Training.Advance(copy, NOW + hour * 3600, same)
				inSteps += g
			end
			t.Check("the same night in steps gives the same", copy.Voidkin[same].Level == level and math.abs(copy.Voidkin[same].Xp - data.Voidkin[lead].Xp) <= 8, `{copy.Voidkin[same].Level}/{copy.Voidkin[same].Xp} and {level}/{data.Voidkin[lead].Xp}`)
			-- A long leave: no cap but the last level.
			who, gained = Training.Advance(data, night + 400 * 24 * 3600, lead)
			t.Check("a long leave: no cap but the last level", data.Voidkin[lead].Level == GrowthConfig.MaxLevel, `{data.Voidkin[lead].Level}`)
			-- Nobody training, and a worker, move the stamp and give nothing.
			local later = night + 401 * 24 * 3600
			who, gained = Training.Advance(data, later, nil)
			t.Check("nobody: the stamp moves, nothing given", who == nil and gained == 0 and data.Training.Stamp == later)
			local worker = Collection.Uncover(data, "watt", NOW).Id
			data.Base.Bays[1].Worker = worker
			who = Training.Advance(data, later + 3600, worker)
			t.Check("a worker never trains", who == nil and data.Voidkin[worker].Level == 1 and data.Training.Stamp == later + 3600)
			who = Training.Advance(data, later, lead)
			t.Check("a clock gone back only sets the stamp", who == nil and data.Training.Stamp == later)
		end,
	},
}
