--!strict
-- The Tower (shared Config; docs/design.md, "The Tower"; docs/balance.md, "The Tower"; TR29): one Voidkin climbs behind
-- its base, one foe a floor, its health carried. The foe's numbers are research's seeds (tools/balance/seeds.json,
-- "tower", on the director's yes of 2026-11-16), modelled by tools/balance/tower.py; once here, this is their home.
-- The rewards are research's fit (TR29, "Research's fit and feel line", 2026-11-16, 20:34; tools/balance/tower.py reads
-- them from here): only hard floors pay, half Lantern Row's Credits an hour at levels 10 to 15, about 15 chests an hour
-- of runs at level 10. Rules.Tower reads them when it runs.

return {
	-- Floor f's foe stands at level 1 + (f - 1) x LevelPerFloor, rounded, never past Growth's last level.
	LevelPerFloor = 0.5,
	-- The foe stands on its own figure (Stats.Resolve, no Regalia) lifted to the seeds' 0.45 build ("enemyFrac"): each
	-- stat over the own figure, read from the model at level 30 (attributes.fighter_attr(30, 0.45) over (30, 0), a Common
	-- Warrior; 15 reads lower, 60 the same). A new enemyFrac means a new reading. Stats not named stay as they are.
	Lift = {
		Health = 2.36, Attack = 1.76, Defence = 2.1, Hit = 1.84, Dodge = 4.02, Critical = 2.14, CriticalResist = 1.47,
		Block = 2.97, Penetration = 1.74, ElementalResist = 1.62, CriticalDamage = 1.11,
	} :: { [string]: number },
	Health = 0.55, -- and then this share of its health (seeds "enemyHpShare")
	-- Its Voidkin: one with a body and moves of its own (a Model and a Kit: Rules.Tower.Pool), picked from the run's seed by floor, no new models.
	-- The opening: the first floors' foes, in this order in every run, so the climb starts the same for everyone and each
	-- teaches one fighter (the director's design review of 2026-11-18, on the director's go of that day). An id not in
	-- the pool falls back to the seed's pick. Past it, the seed picks as before.
	Opening = { "rook", "pip", "kirra", "lyric", "watt" } :: { string },
	-- Past the opening, the foes come from the week (TR46): the same on every server all week, so the week's board is one
	-- race. In seconds: Start, a week's first moment (1970-01-05 00:00 UTC, a Monday), and Length.
	Week = { Start = 345600, Length = 604800 },
	-- The week's board (TR46; builder's): each account's best climb of the week in an OrderedDataStore of its own, read as
	-- one page of the best Page, kept Fresh seconds on a server (GetSortedAsync's budget: 5 + 2 a player a minute). The
	-- card shows the first Shown and the player's own row; a player under a full page reads "#Page+".
	Board = { Page = 100, Shown = 10, Fresh = 60 },
	HealCap = 0.15, -- healing in one floor tops out at this share of the lead's most health (seeds "healCap")
	Rise = 2.5, -- seconds from a floor won to the next foe: the rise to its platform (seeds "risePerFloorSec")
	Leap = 0.5, -- the share of Rise at which the lead and the avatar are set down on the new platform
	-- A fast floor (design: "a floor far below the lead's power falls in one hit and the rise quickens"): a foe this many
	-- levels under the lead falls to the first hit that lands, and the next rise takes Rise seconds instead. Builder's.
	Fast = { Gap = 10, Rise = 0.8 },
	-- Only a hard floor pays: a fast floor gives no Credits and no chest, the free ride to where it gets hard.
	-- A hard floor's Credits: a kill's at the foe's level (Config.Drops.CreditsPerKillPerG x G) times Share, and times
	-- Record again on a floor past the run's record before it (the first-time bonus).
	Credits = { Share = 0.34, Record = 2 },
	-- A chest a hard floor won: Base + PerFloor x the floor, at most Most. It's the Tower's own (Config.Chests.Tower, its
	-- own rarity row), of the ground the foe's level stands in, which an item's worth is read from.
	-- First: the floor whose chest is sure the first time the account wins it (the same review: the roll there was 0.9%).
	Chest = { Base = 0, PerFloor = 0.0018, Most = 0.5, First = 5 },
	-- Forge stones a hard floor won gives, of the grade of the ground its foe's level stands in (TR47; Rules.Drops.StoneGrade).
	-- The builder's seed of 2026-11-19, for research's loot refit.
	Stones = 1,
	-- The world, in studs (builder's, tuned by playing). The ring lies on its lot's crossing end, where the sleeping
	-- Tower stood; stepping within Ring of its middle starts a run. Floor f's platform stands f x Height over it.
	Ring = 5,
	-- 48 across and 18 between floors (AR41, "The director: the Tower is too small", research's seeds of 2026-11-19 after
	-- the director's "the tower is way to small"): the avatar and the foe stand 26 apart, three discs 54 tall. Thick in
	-- proportion to the 28 across it was, until AR41's model. It reaches past its lot's 32 deep, in the air, by
	-- Rules.Tower.Reach: clear of its yard and its neighbour, and the base's ground runs on under its far side.
	Platform = { Radius = 24, Height = 18, Thick = 1.7 },
	-- The avatar off its platform by Side past its edge, or Below under its top, has left: the run ends there.
	Out = { Side = 3, Below = 8 },
	Stand = 0.55, -- the avatar is set down this share of the radius behind the middle, the foe as far in front
	Rest = 4, -- seconds after a run ends before the ring starts another, and only once the avatar has stepped out of it
}
