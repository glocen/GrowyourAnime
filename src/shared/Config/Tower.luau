--!strict
-- The Tower (shared Config; docs/design.md, "The Tower"; docs/balance.md, "The Tower"; TR29): one Voidkin climbs behind
-- its base, one foe a floor, its health carried. The foe's numbers are research's seeds (tools/balance/seeds.json,
-- "tower", on the director's yes of 2026-11-16), modelled by tools/balance/tower.py; once here, this is their home.
-- The rewards are the builder's seeds (tier 2, for research's fit, TR29). Rules.Tower reads them when it runs.

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
	-- Its Voidkin: one with a body of its own (a Model), picked from the run's seed by floor, no new models.
	HealCap = 0.15, -- healing in one floor tops out at this share of the lead's most health (seeds "healCap")
	Rise = 2.5, -- seconds from a floor won to the next foe: the rise to its platform (seeds "risePerFloorSec")
	Leap = 0.5, -- the share of Rise at which the lead and the avatar are set down on the new platform
	-- A fast floor (design: "a floor far below the lead's power falls in one hit and the rise quickens"): a foe this many
	-- levels under the lead falls to the first hit that lands, and the next rise takes Rise seconds instead. Builder's.
	Fast = { Gap = 10, Rise = 0.8 },
	-- A floor's Credits: a kill's at the foe's level (Config.Drops.CreditsPerKillPerG x G) times Share, and times Record
	-- again on a floor past the run's record before it (the first-time bonus).
	Credits = { Share = 2, Record = 2 },
	-- A chest a floor won: Base + PerFloor x the floor, at most Most. It's the chest of the ground the foe's level
	-- stands in, at Tier (an elite's), so deep floors give the rarities their grounds' elites do.
	Chest = { Base = 0, PerFloor = 0.01, Most = 0.5, Tier = 2 },
	-- The world, in studs (builder's, tuned by playing). The ring lies on its lot's crossing end, where the sleeping
	-- Tower stood; stepping within Ring of its middle starts a run. Floor f's platform stands f x Height over it.
	Ring = 5,
	Platform = { Radius = 14, Height = 12, Thick = 1 },
	-- The avatar off its platform by Side past its edge, or Below under its top, has left: the run ends there.
	Out = { Side = 3, Below = 8 },
	Stand = 0.55, -- the avatar is set down this share of the radius behind the middle, the foe as far in front
	Rest = 4, -- seconds after a run ends before the ring starts another, and only once the avatar has stepped out of it
}
