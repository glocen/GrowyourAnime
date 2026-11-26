--!strict
-- Hands cases (pure): the press, slip then strike (TR69 C; Rules.Hands; Config.Combat.Hands). Call shows in every fight
-- but the Tower's once on, and as TR44's B before; a slip is a Call in the tell that the strike misses; Open runs out;
-- the Finisher's rule and its row; the ring's fill never passes full; Auto's wait; one fight's read-out.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Hands = require(Shared.Rules.Hands)
local Fight = require(Shared.Rules.Fight)
local Combat = require(Shared.Config.Combat)

local H = Combat.Hands

return {
	{
		Name = "Hands (TR69 C): Off by default; on, Call shows in every fight but the Tower's, and off, only in B's keeper try",
		Run = function(t: any)
			t.Equal("Off by default", H.On, false)
			t.Check("on: in a fight", Hands.Calls(true, "A", false, true, false))
			t.Check("on: not out of one", not Hands.Calls(true, "B", true, false, false))
			t.Check("on: never in the Tower", not Hands.Calls(true, "B", false, true, true))
			t.Check("off: B in a keeper's try, as TR44 built it", Hands.Calls(false, "B", true, true, false))
			t.Check("off: never on the Row", not Hands.Calls(false, "B", false, true, false))
			t.Check("off: never under A", not Hands.Calls(false, "A", true, true, false))
		end,
	},
	{
		Name = "Hands (TR69 C): a slip is a Call in the tell that the strike misses; Open runs out; a Finisher needs the signature on an Open foe or a broken Guard",
		Run = function(t: any)
			t.Check("called, missed: a slip", Hands.Slip(false, true))
			t.Check("called, hit: none", not Hands.Slip(true, true))
			t.Check("walked off, never called: none", not Hands.Slip(false, false))
			local at = 100
			local openUntil = at + H.Open.Seconds
			t.Check("Open at its start", Hands.Open(openUntil, at))
			t.Check("and just before its end", Hands.Open(openUntil, openUntil - 0.01))
			t.Check("over at its end", not Hands.Open(openUntil, openUntil))
			t.Check("never Open without a slip", not Hands.Open(nil, at))
			t.Check("the signature on an Open foe", Hands.Finisher(true, true, false))
			t.Check("the signature breaking a Guard", Hands.Finisher(true, false, true))
			t.Check("never an ordinary blow", not Hands.Finisher(false, true, true))
			t.Check("never the signature on a foe that isn't Open", not Hands.Finisher(true, false, false))
		end,
	},
	{
		Name = "Hands (TR69 C): the Finisher's row holds longer than a signature's with the same shake; the ring fills a share and never past full; Auto waits",
		Run = function(t: any)
			local row = Fight.Lever(H.Finisher.Rung, Combat.Hitstop)
			local signature = Fight.Lever(7, Combat.Hitstop)
			t.Equal("its own row", row.From, H.Finisher.Rung)
			t.Check("it holds longer than a signature's", row.Hold > signature.Hold, `{row.Hold} against {signature.Hold}`)
			t.Equal("the one strong shake, as the signature's", row.Trauma, signature.Trauma)
			t.Check("it trembles more", row.Tremble > signature.Tremble)
			t.Check("no damage added: no Coefficient in its config", (H.Finisher :: any).Coefficient == nil)
			local cooldown, at = 10, 50
			t.Equal("half empty, 30% fuller", Hands.Fill(at + 5, at, cooldown, 0.3), at + 2)
			t.Equal("nearly full, full and no further", Hands.Fill(at + 1, at, cooldown, 0.3), at)
			t.Equal("full already, unchanged", Hands.Fill(at - 4, at, cooldown, 0.3), at - 4)
			t.Equal("no cooldown, unchanged", Hands.Fill(at + 5, at, 0, 0.3), at + 5)
			t.Check("Auto waits on a full ring", Hands.Waits(at, at + H.Wait - 0.1, H.Wait))
			t.Check("then fires", not Hands.Waits(at, at + H.Wait, H.Wait))
			t.Check("no wait, no hold", not Hands.Waits(at, at, 0))
		end,
	},
	{
		Name = "Hands (TR69 C): one fight's read-out: its counts, its length, its presses a second, over after Linger",
		Run = function(t: any)
			local tally = Hands.Tally(10)
			t.Equal("a fight of no length has no rate", Hands.Rate(tally), nil)
			Hands.Note(tally, "Calls", 1, 12)
			Hands.Note(tally, "OnPurpose", 1, 13)
			Hands.Note(tally, "Accident", 1, 15)
			Hands.Note(tally, "Taps", 1, 16)
			Hands.Note(tally, "Waited", 0.5, 16)
			Hands.Note(tally, "Taken", 40, 18)
			Hands.Note(tally, "Blow", 0, 20)
			t.Equal("its length, first blow to last", tally.To - tally.From, 10)
			t.Equal("its presses a second", Hands.Rate(tally), 0.2)
			t.Check("its counts", tally.Calls == 1 and tally.OnPurpose == 1 and tally.Accident == 1 and tally.Taps == 1 and tally.Waited == 0.5 and tally.Taken == 40)
			t.Check("still up inside Linger", not Hands.Over(tally, 20 + H.Linger - 0.1, H.Linger))
			t.Check("over after it", Hands.Over(tally, 20 + H.Linger, H.Linger))
			t.Check("an unknown count is refused", not pcall(Hands.Note, tally, "Damage", 1, 21))
			t.Check("and so is its clock", not pcall(Hands.Note, tally, "From", 1, 21))
		end,
	},
}
