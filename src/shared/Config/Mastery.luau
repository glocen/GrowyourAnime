--!strict
-- Mastery (shared): the numbers of a Voidkin's Mastery, ranks 1 to 5, earned by leading it (docs/design.md, "Voidkin",
-- "Growing a Voidkin"; TR76, the director's yes of 2026-11-28, 11:32). Rules.Mastery reads them when it runs.
-- PLACEHOLDERS, the builder's of 2026-11-28, until research sets the seeds with the simulation (tools/balance/seeds.json):
-- every number below is one, sized only so the design's two marks hold by hand.

return {
	-- Mastery experience a fall gives the lead that took it, by the fallen's kind (Config.Enemies' kinds; Rules.Drops), and
	-- by what a win is (Warden: a Tower Warden's floor; Bout: a Colosseum bout won). Flat counts, never on G: a rank is
	-- hours of leading one Voidkin, at any ground. PLACEHOLDER.
	Gain = { Ordinary = 1, Elite = 3, Keeper = 10, Warden = 10, Bout = 5 } :: { [string]: number },
	-- The experience each rank takes in all, from none: rank 1 at 300 (a first session's, about 30 min at 601 kills an
	-- hour, Config.Growth), rank 5 at 7,600 (about 10 h of leading it: 601 kills and about 17 keepers an hour, so about
	-- 770 an hour). PLACEHOLDER.
	Ranks = { 300, 1200, 2800, 5000, 7600 },
	-- The points each rank adds to its class's Main in all (not each), at G = 1, so on G(level) as every source is
	-- (docs/balance.md, "The one rule"). Rank 5's 18 is about 11% of a Common's own points (157 for a Warrior), which is
	-- about 4% of a level-60 build where the own base is 35% ("Where power comes from"). PLACEHOLDER.
	Points = { 3, 6, 10, 14, 18 },
}
