--!strict
-- Refusals (shared config): every refusal's words in one table (TR71 B, research, 2026-11-26), by the system that
-- refuses, then the code it answers with (each Rules module's own; ProfileController's "NoAnswer"). Read through
-- Rules.Refusal, never here: it fills each {Field} with the number the fix needs ("Need 1,200 more Credits"), grouped,
-- and says a line's Plain words when a number isn't known. A code with no line says Fallback: no raw code ever reaches a
-- player. Each line says the fix, in docs/ui.md's words ("Words players read"): about six words, never "can't", one word
-- for one thing (base, bag, enemy, keeper). TR68's lines are these. Shown grey, with the pressed control's shake
-- (UI.Kit.Button; Rules.Refusal.Shift).

local Condenser = require(script.Parent.Condenser)
local Voidkin = require(script.Parent.Voidkin)

export type Line = string | { Words: string, Plain: string }

-- The full bag's way out, wherever a full bag stops a take (TR53's follow-up, item 6).
local FREE_A_SLOT = "Bag full. Salvage an item to free a slot."
local CREDITS: Line = { Words = "Need {Need} more Credits", Plain = "Not enough Credits" }
local IN_FIGHT = "Not during a fight"
local TRY_AGAIN = "That didn't go through. Try again."
local WAKES = `The Stone Condenser turns on at base level {Condenser.Wakes}`

local Refusals = {
	Fallback = TRY_AGAIN,
	Lines = {
		-- Rules.Base, Rules.Collection (BaseController): the bays, the Breaker, voltage, power, the Condenser.
		Base = {
			Chosen = "Your first shard is already chosen",
			NoShard = "None in the bag. Lantern Row drops them.",
			Empty = "Empty",
			Leading = "Pick another lead first",
			Working = "Take it out of its bay first",
			Named = "One known Voidkin inside. No voltage needed.",
			Infused = "This shard has its voltage already",
			Short = { Words = "Need {Need} more kWh in the battery", Plain = "Not enough charge in the battery" },
			Brief = "Under a minute left. No voltage needed.", -- the Breaker face's own words (BreakerScreen REASONS)
			Closed = "Open the Power screen first",
			Over = "Over 100%. Lower one share.",
			Moved = "That shard changed. Try again.",
			Stale = "Already done",
			Cap = "That's the top level for now",
			Ceiling = "Upgrade the base first",
			Asleep = WAKES,
			Busy = "Wait for the Condenser to finish",
			Stones = { Words = "Need {Need} more {Grade} stones", Plain = "Not enough stones" },
			Low = `Upgrade the Condenser to level {Condenser.Converts.Mid.FromLevel} first`,
			NoAnswer = TRY_AGAIN,
		},
		-- Rules.BaseLevels (BaseView): the base's own upgrade.
		Levels = {
			Short = CREDITS,
			Stale = "Already bought",
			Cap = "That's the top level for now",
			Ceiling = "Upgrade the base first",
			Asleep = WAKES,
			NoAnswer = TRY_AGAIN,
		},
		-- Rules.Shop, ShopService's Closed (ShopScreen, ShopController).
		Shop = {
			Gone = "New stock came in. Pick again.",
			Limit = "None left for you this stock",
			Poor = CREDITS,
			Short = { Words = "Need {Need} more kWh in the battery", Plain = "Not enough charge in the battery" }, -- the Power Deal (TR76)
			BagFull = FREE_A_SLOT,
			Unknown = "That isn't on the shelf now",
			Closed = "The Shop is closed for a moment",
			NoAnswer = TRY_AGAIN,
		},
		-- Rules.Exchange (the Shop's Exchange tab, TR76).
		Exchange = {
			Gone = "A new week came in. Pick again.",
			Limit = "None left for you this week",
			Short = { Words = "Need {Need} more {Tokens}", Plain = "Not enough to trade" },
			MaxStars = "Already at its last star",
			Unknown = "That isn't on the Exchange",
			NoAnswer = TRY_AGAIN,
		},
		-- Rules.Carry, Rules.Collection, VoidkinService (the Voidkin screen): the lead, stars, nicknames, bays.
		Voidkin = {
			InCombat = IN_FIGHT,
			Healing = { Words = "Still healing at base. Ready in {Time}.", Plain = "Still healing at base" },
			Leading = "Pick another lead first",
			Working = "Working in a bay. Take it out first.",
			NotEnough = { Words = "Need {Need} more copies", Plain = "Not enough copies" },
			MaxStars = "All seven stars already",
			-- Rules.Signature (TR76): a signature's next level
			NoManuals = { Words = "Need {Need} more Skill Manuals", Plain = "Not enough Skill Manuals" },
			NoCredits = CREDITS,
			MaxLevel = "Signature at its top level",
			Filtered = "Try another name",
			BadName = "Try another name",
			TooLong = `At most {Voidkin.Nickname.Max} characters`,
			FilterFailed = "Try the name again in a minute",
			NoAnswer = TRY_AGAIN,
		},
		-- Rules.Chests (the bag): opening chests.
		Chests = {
			NotEnough = "You don't have that many",
			BagFull = FREE_A_SLOT,
			NoAnswer = TRY_AGAIN,
		},
		-- Rules.Chests' salvage (the bag).
		Salvage = {
			NotOwned = "It isn't in the bag",
			Worn = "Take it off first",
			NoAnswer = TRY_AGAIN,
		},
		-- Rules.Regalia (the bag): wearing an item.
		Equip = {
			NotOwned = "It isn't in the bag",
			WrongSlot = "Wrong slot",
			WrongClass = "That weapon is for another class",
			WornElsewhere = { Words = "Preset {Preset} wears it too. Take it off there first.", Plain = "Another preset wears it too" },
			InCombat = IN_FIGHT,
			NoAnswer = TRY_AGAIN,
		},
		-- Rules.Reinforce, Rules.Emblems (the equipment screen).
		Gear = {
			InCombat = IN_FIGHT,
			Capped = "Already at max",
			Poor = CREDITS,
			NoStones = { Words = "Need {Need} more {Grade} stones", Plain = "Not enough stones" },
			NoneLeft = "None of that emblem left",
			Empty = "That socket is empty",
			NotEnough = "Combining takes 3 of one stat and rarity",
			Top = "Already Legendary",
			NoAnswer = TRY_AGAIN,
		},
		-- TowerService.Begin (the mode screen's Go).
		Tower = {
			NoRing = "The Tower isn't in reach here",
			Nowhere = "The Tower isn't in reach here",
			InRun = "You're in the Tower already",
			InCombat = IN_FIGHT,
			NoLead = { Words = "Still healing at base. Ready in {Time}.", Plain = "Wait for your lead to heal" }, -- Time: TowerService's
			NoRoom = "The Tower is full. Try again soon.",
		},
		-- Rules.Stages, StageService (the stage screen): what a shut stretch or difficulty waits for.
		Stages = {
			Before = "Clear Stretch {Stage} first",
			Keeper = "Beat the {Keeper} on Normal",
			Fallen = "Beat the {Keeper} here first", -- the Keeper alone, before its first fall on that difficulty (TR74)
			Resting = "The {Keeper} rests for {Minutes} min", -- the Keeper alone, in the keeper's rest after a win
			Ground = "Not open yet",
			Locked = "Not open yet",
			NoLead = "Wait for your lead to heal",
			InTry = "Not during a challenge",
			NoAnswer = TRY_AGAIN,
		},
		-- Rules.Codes (the settings screen's codes).
		Codes = {
			Unknown = "That isn't a code",
			Ended = "That code has ended",
			Used = "Already used on this account",
			Wait = "Try again in a minute",
		},
		-- Rules.Return (the return card's take): anything but its own "nothing to take".
		Return = {
			NoAnswer = TRY_AGAIN,
		},
		-- TravelService (a trip between places): a teleport that failed.
		Travel = {
			Failed = "The trip didn't go through. Try again.",
		},
		-- Rules.Settings (the settings screen): a level or a switch the server didn't keep.
		Settings = {
			Unsaved = "Not saved. Try again.",
			NoAnswer = "Not saved. Try again.",
		},
		-- Rules.Home (the dock's Home): the trip back to the base.
		Home = {
			Boss = "Not during a keeper fight", -- the keeper's street, never the Arc: players read a ground as an Arc
			Event = "Not during an event",
			Fight = IN_FIGHT,
			Cooldown = { Words = "Ready in {Seconds} s", Plain = "Ready soon" },
			Here = "Back at your base", -- the tile's word on a hover, never a refusal: a tap at the base opens its view (TR20, fix 2)
		},
	} :: { [string]: { [string]: Line } },
}

return Refusals
