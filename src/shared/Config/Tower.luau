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
	-- Refit to the build players have (TR48, research's MODEL of 2026-11-19, 16:53): each lift's excess over 1 scaled by
	-- 0.3, so an expected lead climbs 10 floors at level 10, 23 at 16 and 31 at 20.
	Lift = {
		Health = 1.41, Attack = 1.23, Defence = 1.33, Hit = 1.25, Dodge = 1.91, Critical = 1.34, CriticalResist = 1.14,
		Block = 1.59, Penetration = 1.22, ElementalResist = 1.19, CriticalDamage = 1.03,
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
	Rise = 2.5, -- seconds from a floor won to the next foe (seeds "risePerFloorSec"): the room's beat, its steps and its number (AR56)
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
	-- TR48's refit: about 15 to 17.5 chests an hour for an expected lead.
	Chest = { Base = 0.02, PerFloor = 0.0004, Most = 0.5, First = 5 },
	-- A hard floor won drops a Shade's forge stones on this difficulty (Rules.Drops.Stones), of the grade of the ground its
	-- foe's level stands in (TR48: "a Shade's of its band").
	Stones = "Normal",
	-- The world, in studs (builder's, tuned by playing). The room (AR56, the Crown): each run is fought in its owner's own
	-- copy of one great round room, made as the run starts and removed at its end (TowerService), a move within the place.
	-- Its shape is the kit's plan (Config.Kits.TowerRoom.Plan: the floor, where the two stand, the step ring past it, the
	-- beat); here, where the copies stand: copy n at Origin, in rows of Across, Spacing apart, far past the map and each
	-- other by more than the streaming radius (1024), so the map streams out of a room's view and no other room in.
	Room = { Origin = Vector3.new(0, 400, -6000), Spacing = 2400, Across = 6 },
	-- The room's drifting clouds (the plan's drift): each passes along +X and comes round within Wrap studs of the room's
	-- middle, fading over Fade studs at each end, so it's never seen to jump.
	Drift = { Wrap = 320, Fade = 80 },
	-- The avatar past the room's step ring by Side, or Below under its floor, has left: the run ends there.
	Out = { Side = 3, Below = 8 },
	-- The gate on the lot, where the ring was (AR56; Rules.Tower.InGate): stepping through its door of light starts a
	-- run. Its box round the door, in studs of the lot's frame: Half across, Deep either side of the door, Up over the
	-- lot's ground. Out of a run, the avatar is set down Back studs in front of the gate, toward its base, facing it.
	Gate = { Half = 3.4, Deep = 1.5, Up = 9 },
	Back = 16,
	Rest = 4, -- seconds after a run ends before the gate starts another, and only once the avatar has stepped out of it
}
