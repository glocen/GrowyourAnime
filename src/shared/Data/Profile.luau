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
	Lines: { ItemLine }, -- the rolled lines
	Sockets: { string }, -- one entry per socket its rarity gives: an emblem id, or "" when empty
	Jewel: string, -- a jewel id, or ""
}

export type Preset = {
	Slots: { [string]: string }, -- slot name to item id; a slot with nothing in it has no key
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
}

export type Chamber = {
	Work: ShardWork?, -- the shard breaking in it; absent when the chamber is empty
}

export type Bay = {
	Worker: string, -- the Voidkin's Id, or "" when the bay is empty
}

export type Base = {
	Stamp: number, -- os.time() the base was last advanced to (Rules.Breaker); 0 before the first advance
	Battery: number, -- electricity stored
	Spill: number, -- Credits from overflow not yet whole, carried to the next advance (0 to 1)
	Chambers: { Chamber }, -- one per chamber the Breaker has
	Line: { ShardWork }, -- the waiting line, in the order it's fed
	Ready: { ShardWork }, -- broken and waiting to be opened, oldest first
	Bays: { Bay }, -- one per bay opened
}

export type GroundProgress = {
	Opened: number, -- os.time() it opened
	KeeperWins: number,
}

export type Data = {
	Version: number, -- how many migrations have run on it (Shared.Data.Migrations)
	NextId: number, -- the counter behind every instance id
	Ops: OpLedger.Ledger, -- operations already applied, with their first answers; never sent to a client
	Voidkin: { [string]: OwnedVoidkin }, -- by Id
	Index: { [string]: IndexEntry }, -- by Voidkin definition
	Items: { [string]: OwnedItem }, -- by Id
	Presets: { Preset },
	SlotRanks: { [string]: number }, -- forge rank by slot name; a slot never forged has no key
	Bag: {
		Shards: { [string]: number }, -- count by shard definition
	},
	Currency: {
		Credits: number,
		Research: number, -- Research Points
	},
	Roles: {
		Lead: string, -- the lead's Id, or ""
	},
	Base: Base,
	Progress: {
		Starter: string, -- the starter shard chosen, or "" before the choice
		Grounds: { [string]: GroundProgress }, -- by ground id, once opened
		Kills: number, -- enemies that fell with this player's lead among their hitters (Rules.Drops); the first drops Watt's shard
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
	for i = 1, BaseConfig.Start.Bays do
		bays[i] = { Worker = "" }
	end
	return {
		Version = 0, -- so a new profile runs every migration once and takes the same path as an old one
		NextId = 1,
		Ops = OpLedger.New(),
		Voidkin = {},
		Index = {},
		Items = {},
		Presets = { { Slots = {} } },
		SlotRanks = {},
		Bag = { Shards = {} },
		Currency = { Credits = 0, Research = 0 },
		Roles = { Lead = "" },
		Base = {
			Stamp = 0,
			Battery = BaseConfig.Start.Battery,
			Spill = 0,
			Chambers = chambers,
			Line = {},
			Ready = {},
			Bays = bays,
		},
		Progress = { Starter = "", Grounds = {}, Kills = 0 },
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
