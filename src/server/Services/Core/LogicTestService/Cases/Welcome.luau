--!strict
-- Welcome cases (pure): the welcome week and the codes (Rules.Welcome; launch-design.md, section 8). One gift a day
-- played, in order, never two a day and never lost to a missed one; the seventh chosen, never rolled; a code once per
-- account, matched without case or spaces, inside its time, and never anything but chests with no gear. Runs in Studio
-- (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config.Welcome)
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local ChestRows = require(Shared.Definitions.Chests)
local Shards = require(Shared.Definitions.Shards)
local Voidkin = require(Shared.Definitions.Voidkin)
local Collection = require(Shared.Rules.Collection)
local Welcome = require(Shared.Rules.Welcome)

local function fresh(): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	data.Progress.Starter = "starter_rook" -- past the first choice, where the week begins
	return data
end

local function made(): { string }
	local out = {}
	for _, row in Voidkin.List do
		if Voidkin.Made(row) then
			table.insert(out, row.Id)
		end
	end
	return out
end

local CODES: { Config.Code } = {
	{ Id = "launch", Code = "Lantern Light", Chests = { forge_crate = 1, jewel_pouch = 2 }, From = 0, Until = 0 },
	{ Id = "later", Code = "SOON", Chests = { forge_crate = 1 }, From = 5000, Until = 0 },
	{ Id = "over", Code = "GONE", Chests = { forge_crate = 1 }, From = 0, Until = 2000 },
	{ Id = "gear", Code = "GEAR", Chests = { [ChestRows.List[1].Id] = 1 }, From = 0, Until = 0 },
}

return {
	{
		Name = "Welcome: one gift a day played, in the week's order, none twice a day, none lost to a missed day, none past the seventh",
		Run = function(t: any)
			local early = Profile.Template()
			Migrations.Run(early)
			t.Equal("before the starter's chosen, nothing", Welcome.Gift(early, 100).Error, Welcome.Early)
			t.Equal("and the week not begun", early.Gifts.Week, 0)
			local data = fresh()
			local first = Welcome.Gift(data, 100)
			t.Check("day 1, a Forge Crate", first.Ok == true and first.Gift == 1 and first.Chest == "forge_crate" and data.Bag.Chests.forge_crate == 1)
			t.Equal("the same day again", Welcome.Gift(data, 100).Error, Welcome.Today)
			t.Equal("and it gave nothing", data.Bag.Chests.forge_crate, 1)
			local second = Welcome.Gift(data, 105) -- four days missed
			t.Check("the next day played, the second, an Emblem Case", second.Ok == true and second.Gift == 2 and second.Chest == Welcome.Case(data))
			local row = ChestRows.ById[second.Chest]
			t.Check("the elite's case of the furthest ground", row ~= nil and row.Kind == "Emblem" and row.Id == (ChestRows.CaseOf("lanternrow", "Elite") :: any).Id)
			local third = Welcome.Gift(data, 106)
			t.Check("the third, a Jewel Pouch", third.Ok == true and third.Chest == "jewel_pouch" and data.Bag.Chests.jewel_pouch == 1)
			for day = 107, 109 do
				t.Check(`gift on day {day}`, Welcome.Gift(data, day).Ok == true)
			end
			local seventh = Welcome.Gift(data, 110)
			local shard: string = seventh.Shard
			t.Check("the seventh, a Named shard", seventh.Ok == true and seventh.Gift == #Config.Week and shard ~= "" and data.Bag.Shards[shard] == 1)
			t.Equal("an eighth", Welcome.Gift(data, 111).Error, Welcome.Done)
			t.Equal("the week's count kept", data.Gifts.Week, #Config.Week)
			t.Equal("a new account's first, on any day", Welcome.Gift(fresh(), 0).Ok, true)
		end,
	},
	{
		Name = "Welcome: the seventh is a Named shard of a launch Voidkin the account doesn't own, the first in the roster, never rolled; all five owned gives a Forge Crate",
		Run = function(t: any)
			local five = made()
			t.Equal("launch has five made Voidkin", #five, 5)
			for _, id in five do
				local found = false
				for _, shard in Shards.List do
					found = found or (shard.Grade == "Named" and shard.Holds == id)
				end
				t.Check(`{id} has a Named shard`, found)
			end
			local data = fresh()
			local shard = Shards.ById[Welcome.Named(data)]
			t.Check("none owned, the roster's first", shard ~= nil and shard.Holds == five[1])
			Collection.Uncover(data, five[1], 0)
			Collection.Uncover(data, five[3], 0)
			local next = Shards.ById[Welcome.Named(data)]
			t.Check("the first not owned", next ~= nil and next.Holds == five[2])
			t.Equal("the same save, the same pick", Welcome.Named(data), Welcome.Named(data))
			for _, id in five do
				Collection.Uncover(data, id, 0)
			end
			t.Equal("all five owned, none", Welcome.Named(data), "")
			data.Gifts.Week = #Config.Week - 1
			data.Gifts.Day = 1
			local seventh = Welcome.Gift(data, 2)
			t.Check("so the seventh is the fallback", seventh.Ok == true and seventh.Shard == "" and seventh.Chest == Config.Fallback)
		end,
	},
	{
		Name = "Welcome: a code once per account, matched without case or spaces, inside its time, giving chests with no gear only",
		Run = function(t: any)
			local data = fresh()
			local typed = Welcome.Redeem(data, "  lantern light ", 3000, CODES)
			t.Check("typed loosely, accepted", typed.Ok == true and typed.Code == "launch")
			t.Check("its chests given", data.Bag.Chests.forge_crate == 1 and data.Bag.Chests.jewel_pouch == 2)
			t.Equal("a second time", Welcome.Redeem(data, "LANTERNLIGHT", 3001, CODES).Error, Welcome.Used)
			t.Check("and nothing more given", data.Bag.Chests.forge_crate == 1 and data.Bag.Chests.jewel_pouch == 2)
			t.Equal("a word that isn't one", Welcome.Redeem(data, "FREE", 3000, CODES).Error, Welcome.Unknown)
			t.Equal("an empty one", Welcome.Redeem(data, "   ", 3000, CODES).Error, Welcome.Unknown)
			t.Equal("past its length", Welcome.Redeem(data, string.rep("A", Config.CodeMost + 1), 3000, CODES).Error, Welcome.Unknown)
			t.Equal("not a word", Welcome.Redeem(data, 42, 3000, CODES).Error, Welcome.Unknown)
			t.Equal("before it opens, as if none", Welcome.Redeem(data, "soon", 3000, CODES).Error, Welcome.Unknown)
			t.Check("once open", Welcome.Redeem(data, "soon", 5000, CODES).Ok == true)
			t.Equal("past its end", Welcome.Redeem(data, "gone", 3000, CODES).Error, Welcome.Ended)
			local before = data.Bag.Chests[ChestRows.List[1].Id] or 0
			t.Equal("a code that would give gear", Welcome.Redeem(data, "gear", 3000, CODES).Error, Welcome.Unknown)
			t.Equal("gives none", data.Bag.Chests[ChestRows.List[1].Id] or 0, before)
			t.Check("and isn't kept as used", data.Gifts.Codes.gear == nil)
			for _, code in Config.Codes do
				for id, count in code.Chests do
					local row = ChestRows.ById[id]
					t.Check(`the game's code {code.Id} gives {id}, no gear`, row ~= nil and row.Kind ~= "Gear" and count >= 1)
				end
			end
		end,
	},
	{
		Name = "Welcome: a gift's and a code's words",
		Run = function(t: any)
			t.Equal("a chest", Welcome.Said({ Gift = 1, Of = 7, Chest = "forge_crate", Shard = "" }), "Welcome gift 1 of 7: a Forge Crate")
			t.Equal("an Emblem Case", Welcome.Said({ Gift = 2, Of = 7, Chest = (ChestRows.CaseOf("lanternrow", "Elite") :: any).Id, Shard = "" }), "Welcome gift 2 of 7: an Emblem Case")
			t.Equal("a shard", Welcome.Said({ Gift = 7, Of = 7, Chest = "", Shard = "named_rook" }), "Welcome gift 7 of 7: a Named shard of Rook")
			t.Equal("a code", Welcome.Said({ Code = "launch", Chests = { forge_crate = 1, jewel_pouch = 2 } }), "Code accepted: a Forge Crate, 2 Jewel Pouches")
		end,
	},
}
