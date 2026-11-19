--!strict
-- Profile (shared, pure): the shape of a player's save, its defaults, and the read copy a client gets.
-- The server owns every write (Services/Core/DataService); a client only reads. The contract around it (who owns what,
-- transactions) is docs/engineering-plan.md; this file is the shape's one home.
-- What a profile holds: ids and numbers. No model, part or display name, nothing a definition already says, nothing a fight
-- derives (health, cooldowns). ProfileStore saves string-keyed tables and dense arrays only, so every table here is one or
-- the other, and an empty slot is "" or an empty table, never a hole. Shared.Data.Saveable checks that.
-- A Voidkin's role isn't stored on it: the slot it fills points at it (Roles.Lead, a bay's Worker), so a role has one home
-- and "one role at a time" is kept by the rules that fill slots (Profile.RoleOf reads it back).
-- No Roblox API: it runs with Studio closed.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OpLedger = require(ReplicatedStorage.Shared.Rules.OpLedger)
local BaseConfig = require(ReplicatedStorage.Shared.Config.Base)
local BaseLevels = require(ReplicatedStorage.Shared.Rules.BaseLevels)

export type OwnedVoidkin = {
	Id: string, -- made by the server when it's uncovered (Profile.NewId), never reused
	Def: string, -- its row in Definitions.Voidkin
	Level: number,
	Xp: number, -- toward the next level
	Stars: number, -- 0 to the ceiling in Config
	Copies: number, -- duplicates waiting to be spent on the next star, by hand (docs/design.md, "Voidkin", "Stars")
	Nickname: string, -- "" for none; stored raw, filtered for each viewer when shown (docs/roblox-rules.md)
	Preset: number, -- the Regalia preset it wears: an index into Presets
	Favourite: boolean,
	Locked: boolean,
	Born: number, -- os.time() when it was uncovered
}

export type ItemLine = { Stat: string, Value: number }

export type OwnedItem = {
	Id: string,
	Def: string, -- its row in Definitions.Items, which names the slot
	Tier: number, -- the level tier
	Rarity: string,
	Design: number, -- its design among its kind's at its rarity (Definitions.ItemDesigns), fixed at its drop: look and name only
	Lines: { ItemLine }, -- the rolled lines
	Sockets: { string }, -- one entry per socket its rarity gives (Config.Chests.Sockets): an emblem key, or "" when empty
	Reinforce: number, -- its Reinforce level, 0 to Config.Reinforce.Cap (TR47, Rules.Reinforce)
	Jewels: { [string]: number }, -- a jewel colour's level in its slot; a colour with none has no key (TR47 part B)
}

-- A Regalia preset (docs/engineering-plan.md, "Class rules"): the twelve shared slots, and one weapon pair for each class.
-- A Voidkin wears its preset's Slots and its own class's pair, nothing else (Rules.Stats, Definitions.Items.Fits).
export type Preset = {
	Slots: { [string]: string }, -- a shared slot's name (Gear.Shared) to an item id; a slot with nothing in it has no key
	Hands: { [string]: { [string]: string } }, -- a class to its pair: "Main Hand" and "Off Hand" to an item id (TR26)
}

export type IndexEntry = {
	First: number, -- os.time() when the first one was found
	Count: number, -- how many were ever found, duplicates included
}

-- A shard in the Breaker. What it gives is fixed by these the moment it enters (docs/engineering-plan.md, "Transactions").
export type ShardWork = {
	Def: string, -- its row in Definitions.Shards, which names its grade and its ground
	Luck: number, -- the luck applied when it entered
	Done: number, -- seconds of work done, at full power
	Volt: number?, -- the voltage put into it, its level in Config.Shards.Voltage.Levels; absent until then (TR18)
}

export type Chamber = {
	Work: ShardWork?, -- the shard breaking in it; absent when the chamber is empty
}

export type Bay = {
	Worker: string, -- the Voidkin's Id, or "" when the bay is empty
	Level: number, -- the bay's own level (TR21): its output rises with it, never past the base's ceiling (Rules.BaseLevels)
}

-- How the generation is split among the machines (Rules.Power; docs/design.md, "Power"). Under Auto, by their demand;
-- else each machine's share of the whole generation, by name (Rules.Power.Machines), the rest charging the battery.
export type Power = {
	Auto: boolean,
	Shares: { [string]: number }, -- 0 to 1 each, never over 1 together; kept while Auto runs
	Open: boolean, -- the Power screen opens once a machine beside the Breaker has drawn power; until then Auto runs unseen
}

export type Base = {
	Level: number, -- the base's level, 1 to Config.Base.Levels.Cap (TR21): its bays, its battery's cap, its machines' ceiling
	Machines: { [string]: number }, -- each single machine's level by name, the Breaker's now (TR21); a bay's is on the bay
	Stamp: number, -- os.time() the base was last advanced to (Rules.Breaker); 0 before the first advance
	Charge: number, -- the battery's charge, kWh (TR18; Migrations step 4 made it from the old electricity)
	Spill: number, -- Credits from overflow not yet whole, carried to the next advance (0 to 1)
	Power: Power,
	Chambers: { Chamber }, -- one per chamber the Breaker has
	Line: { ShardWork }, -- the waiting line, in the order it's fed
	Ready: { ShardWork }, -- broken and waiting to be opened, oldest first
	Bays: { Bay }, -- one per bay opened
	Showcase: string, -- the Voidkin the showcase at the gate stands (TR22), whatever its role; "" for the strongest
}

export type GroundProgress = {
	Opened: number, -- os.time() it opened
	KeeperWins: { [string]: number }, -- its keeper's wins by difficulty, Normal and Hard (TR48); one count before step 12
	Back: number?, -- os.time() this player's keeper is back, set at each win (TR10, Rules.Progress); nil before the first
}

-- A Tower run under way (TR29, Rules.Tower): its ledger, written in the transaction of each floor won and granted once,
-- by the transaction that ends it. A run never resumes: one left in the save by a crash is ended at the next join.
-- A ground's stages on one difficulty (TR43, Rules.Stages): how many are cleared, from the first (a stage needs the one
-- before it, so the clears are always the first ones), and each stage's fastest clear in seconds, 0 before one is timed.
export type StageLine = { Cleared: number, Best: { number } }
export type StageProgress = { Normal: StageLine, Hard: StageLine }

export type TowerRun = {
	Id: string, -- Profile.NewId: an end naming another id is a no-op, so a run is granted once
	Started: number, -- os.time() it started
	Floor: number, -- the last floor won; 0 before the first
	Best: number, -- the record when it started: a floor past it pays the first-time bonus
	Seed: number, -- the server's draw at the start: each floor's foe and chest roll come from it (Rules.Tower)
	Credits: number, -- won and not yet granted
	Chests: { [string]: number }, -- won by chest id and not yet granted
	Stones: { [string]: number }?, -- forge stones won by grade and not yet granted (TR47); nil in a run begun before them
}

-- An account's best climb of one week (TR46, Rules.Tower.Score): the week its run started in, the floor, and the score
-- the week's board orders by, the earlier of two equal floors first.
export type TowerWeek = { Week: number, Floor: number, Score: number }

-- The last run's summary, kept until its screen has shown it (Act "TowerSeen" with its id).
export type TowerResults = {
	Id: string,
	Floor: number, -- the highest floor won
	Best: number, -- the record before it
	Record: boolean, -- it passed the record
	Credits: number,
	Chests: { [string]: number },
	Stones: { [string]: number }?, -- by grade (TR47)
}

export type Data = {
	Version: number, -- how many migrations have run on it (Shared.Data.Migrations)
	NextId: number, -- the counter behind every instance id
	Ops: OpLedger.Ledger, -- operations already applied, with their first answers; never sent to a client
	Voidkin: { [string]: OwnedVoidkin }, -- by Id
	Index: { [string]: IndexEntry }, -- by Voidkin definition
	Items: { [string]: OwnedItem }, -- by Id
	Presets: { Preset },
	Bag: {
		Shards: { [string]: number }, -- count by shard definition
		Chests: { [string]: number }, -- count by chest definition, so identical chests stack (TR27, Rules.Chests)
		Stones: { [string]: number }, -- forge stones, count by grade (Config.Reinforce.Grades; TR47)
		Emblems: { [string]: number }, -- War Emblems, count by key, "set:stat" (Rules.Emblems), so identical ones stack
		Jewels: { [string]: number }, -- jewels, count by "Colour:level" (TR47 part B)
	},
	Settings: {
		Salvage: string, -- an opened item of this rarity or under turns into Credits; "" for none (Rules.Chests)
		Music: number, -- the player's levels, 0 to 1 in hundredths (Rules.Settings; AR43's Settings): the music's volume,
		Sound: number, -- every other sound's,
		Effects: number, -- and how much of the fight's particles and camera shake plays
	},
	Currency: {
		Credits: number,
		Research: number, -- Research Points
	},
	-- What was bought from the Void Shop on its latest stock bought from (AR38, Rules.Shop): the stock's number and each
	-- line's count, so a server hop never refills a line; a buy on a later stock starts the counts again.
	Shop: {
		Stock: number,
		Bought: { [string]: number }, -- by line name ("Shard", "Featured")
	},
	Roles: {
		Lead: string, -- the lead's Id, or ""
	},
	-- The first session's steps already logged to Roblox's onboarding funnel, by name (TR32, Rules.Funnel): each once
	-- an account.
	Funnel: { [string]: boolean },
	Base: Base,
	Training: {
		-- Who's on the Training machine while the player is in the game, an owned Voidkin's Id or "" (the server's,
		-- LeadService, Rules.Training.Who); away, it's the lead. The base's clock trains them (Rules.Breaker, TR18).
		Trainee: string,
		Banked: number, -- seconds at full power not yet worth a whole point of experience, kept for the next advance
	},
	Progress: {
		Starter: string, -- the starter shard chosen, or "" before the choice
		Grounds: { [string]: GroundProgress }, -- by ground id, once opened
		Stages: { [string]: StageProgress }, -- by ground id, from its first clear (TR43)
		Kills: number, -- enemies that fell with this player's lead among their hitters (Rules.Drops); the first drops Watt's shard
		Tower: {
			Best: number, -- the highest floor ever won (TR29)
			Run: TowerRun?,
			Results: TowerResults?,
			HealTold: boolean?, -- the heal cap has been told once, the first time it bound (TR46); never again
			Week: TowerWeek?, -- the best climb of the latest week a run was ended in, for the week's board (TR46)
		},
	},
}

export type View = Data -- a client's copy: the same shape with Ops emptied

local Profile = {}

-- The defaults a new profile starts from, fresh each call. ProfileStore copies it once when the store opens, and Reconcile
-- fills keys it gains into older saves. Starting numbers come from Config.Base.
function Profile.Template(): Data
	local chambers: { Chamber } = {}
	for i = 1, BaseConfig.Start.Chambers do
		chambers[i] = {}
	end
	local bays: { Bay } = {}
	for i = 1, BaseLevels.Bays(1) do
		bays[i] = { Worker = "", Level = 1 }
	end
	return {
		Version = 0, -- so a new profile runs every migration once and takes the same path as an old one
		NextId = 1,
		Ops = OpLedger.New(),
		Voidkin = {},
		Index = {},
		Items = {},
		Presets = { { Slots = {}, Hands = {} } },
		Bag = { Shards = {}, Chests = {}, Stones = {}, Emblems = {}, Jewels = {} },
		Settings = { Salvage = "", Music = 1, Sound = 1, Effects = 1 },
		Currency = { Credits = 0, Research = 0 },
		Shop = { Stock = 0, Bought = {} },
		Roles = { Lead = "" },
		Funnel = {},
		Base = {
			Level = 1,
			Machines = { Breaker = 1 },
			Showcase = "",
			Stamp = 0,
			Charge = BaseConfig.Start.Charge,
			Spill = 0,
			Power = { Auto = true, Shares = {}, Open = false },
			Chambers = chambers,
			Line = {},
			Ready = {},
			Bays = bays,
		},
		Training = { Trainee = "", Banked = 0 },
		Progress = { Starter = "", Grounds = {}, Stages = {}, Kills = 0, Tower = { Best = 0 } },
	}
end

-- A new instance id ("k1", "k2", ...), and the counter moved on. Ids are per profile: unique inside it, never reused.
function Profile.NewId(data: Data): string
	local id = `k{data.NextId}`
	data.NextId += 1
	return id
end

-- What a Voidkin is doing: "Lead", "Worker" or "Resting", read from the slots that point at it.
function Profile.RoleOf(data: Data, id: string): string
	if id == "" then
		return "Resting"
	end
	if data.Roles.Lead == id then
		return "Lead"
	end
	for _, bay in data.Base.Bays do
		if bay.Worker == id then
			return "Worker"
		end
	end
	return "Resting"
end

-- A copy that shares no table with the original: plain data only, as a save holds.
local function deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, inner in value do
		copy[key] = deepCopy(inner)
	end
	return copy
end
Profile.DeepCopy = deepCopy

-- A client's copy: everything but the ledger, whose answers are the server's business.
function Profile.View(data: Data): View
	local view = deepCopy(data)
	view.Ops = OpLedger.New()
	return view
end

return Profile
