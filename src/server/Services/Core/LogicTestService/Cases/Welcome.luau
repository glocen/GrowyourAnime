--!strict
-- Logic cases (pure): the welcome week and the codes (TR59; Rules.Welcome; Rules.Codes; Config.Welcome). Each day's
-- gift, a missed day waiting, a repeated claim paying once, Lyric owned and not, a code taken twice, ended, wrong, the
-- sixth wrong try in a minute, and no gift of Credits or of anything a code mustn't pay. Runs in Studio (LogicTests)
-- and with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Saveable = require(Shared.Data.Saveable)
local Config = require(Shared.Config.Welcome)
local CodeList = require(game:GetService("ServerScriptService").Server.Config.Codes) -- the server's own list
local ChestRows = require(Shared.Definitions.Chests)
local Shards = require(Shared.Definitions.Shards)
local Welcome = require(Shared.Rules.Welcome)
local Codes = require(Shared.Rules.Codes)
local Collection = require(Shared.Rules.Collection)

local DAY = 20_000 -- a UTC day number (Goals.DayOf)
local NOW = DAY * 86400 + 3600

local function fresh(): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	data.Funnel[Config.ShowsAfter] = true
	return data
end

-- What's in the bag of `gift`'s kind.
local function held(data: Profile.Data, gift: Config.Gift): number
	if gift.Chest then
		return data.Bag.Chests[gift.Chest] or 0
	end
	return data.Bag.Shards[gift.Shard :: string] or 0
end

local CODE: Config.Code = { Id = "test1", Code = "Void Break", Gives = { { Chest = "crate", Count = 1 }, { Shard = "lanternrow_standard", Count = 2 } }, Until = NOW + 86400 }
local OLD: Config.Code = { Id = "test0", Code = "OLDONE", Gives = { { Chest = "pouch", Count = 1 } }, Until = NOW - 1 }

return {
	{
		Name = "Welcome: each day's gift in order, one a UTC day played; a missed day waits; a repeat the same day pays once; the week ends at seven",
		Run = function(t: any)
			local data = fresh()
			local before = Profile.DeepCopy(data)
			t.Equal("seven gifts", #Config.Week, 7)
			local early = fresh()
			early.Funnel[Config.ShowsAfter] = nil
			t.Equal("before the first session's script ends: refused, nothing shown lit", Welcome.Claim(early, DAY).Error, Welcome.Early)
			t.Check("and its row has none lit", table.find(Welcome.Row(early, DAY), "Today") == nil)
			local day = DAY
			for index, gift in Config.Week do
				local row = Welcome.Row(data, day)
				t.Check(`day {index}: lit today, the ones before taken`, row[index] == "Today" and (index == 1 or row[index - 1] == "Taken") and (index == 7 or row[index + 1] == "Later"))
				local had = held(data, gift)
				local answer = Welcome.Claim(data, day)
				t.Check(`day {index}: its gift into the bag`, answer.Ok == true and answer.Day == index and held(data, gift) == had + gift.Count, `{tostring(answer.Error)}`)
				local again = Welcome.Claim(data, day)
				t.Check(`day {index}: a second claim the same day pays nothing`, again.Ok == false and again.Error == (if index == 7 then Welcome.Done else Welcome.Today) and held(data, gift) == had + gift.Count)
				day += if index == 3 then 5 else 1 -- a missed stretch after day 3: the next only waits
			end
			t.Equal("the week ends at seven", Welcome.Claim(data, day + 1).Error, Welcome.Done)
			t.Check("every tile taken", table.concat(Welcome.Row(data, day + 1), ",") == "Taken,Taken,Taken,Taken,Taken,Taken,Taken")
			t.Equal("the save stays saveable", #Saveable.Problems(data), 0)
			t.Check("and the gifts are the design's", Config.Week[1].Chest == ChestRows.CrateId and Config.Week[4].Chest == ChestRows.PouchId
				and Config.Week[3].Shard == "lanternrow_standard" and Config.Week[3].Count == 2 and Config.Week[7].Shard == "named_lyric")
			t.Check("days 2 and 6 roll as Lantern Row's elite chest", Config.Week[2].Chest == "lanternrow_2_case" and ChestRows.ById.lanternrow_2_case ~= nil and Config.Week[6].Chest == Config.Week[2].Chest)
			t.Check("a fresh save untouched by the checks", before.Welcome == nil)
		end,
	},
	{
		Name = "Welcome: day 7 is Lyric's Named shard for everyone, a new Voidkin when Lyric isn't owned and a copy when it is",
		Run = function(t: any)
			local row = Shards.ById.named_lyric
			t.Check("Lyric's Named shard holds Lyric", row ~= nil and row.Grade == "Named" and row.Holds == "lyric")
			local without = fresh()
			t.Equal("not owned: a new Voidkin", Collection.Uncover(without, "lyric", NOW).Outcome, "New")
			local with = fresh()
			Collection.Uncover(with, "lyric", NOW)
			t.Equal("owned: a copy toward its next star", Collection.Uncover(with, "lyric", NOW + 1).Outcome, "Copy")
			t.Equal("its words", Welcome.Said(Config.Week[7]), "Lyric's Named shard")
			t.Equal("two shards' words", Welcome.Said(Config.Week[3]), "2 Standard shards")
		end,
	},
	{
		Name = "Codes: matched in any case and spacing, taken once an account, never after its end, wrong ones refused",
		Run = function(t: any)
			local data = fresh()
			local gate = Codes.Gate()
			local list = { CODE, OLD }
			local answer = Codes.Redeem(data, "  void break ", NOW, list, gate)
			t.Check("any case, any spaces: taken", answer.Ok == true and answer.Code == "test1" and data.Bag.Chests.crate == 1 and data.Bag.Shards.lanternrow_standard == 2)
			t.Equal("its words", Codes.Said(answer), "Code taken: Forge Crate, 2 Standard shards")
			local twice = Codes.Redeem(data, "VOIDBREAK", NOW + 5, list, gate)
			t.Check("twice: refused, nothing more", twice.Error == Codes.Used and data.Bag.Chests.crate == 1)
			t.Equal("its words", Codes.Said(twice), "Already used on this account")
			local other = fresh()
			t.Equal("ended", Codes.Redeem(other, "oldone", NOW, list, Codes.Gate()).Error, Codes.Ended)
			t.Equal("ended's words", Codes.Said({ Ok = false, Error = Codes.Ended }), "That code has ended")
			t.Check("so nothing given", other.Bag.Chests.pouch == nil and other.Codes == nil)
			t.Equal("a code past its end, the same second", Codes.Redeem(fresh(), "voidbreak", CODE.Until, list, Codes.Gate()).Error, Codes.Ended)
			local wrong = Codes.Redeem(fresh(), "nope", NOW, list, Codes.Gate())
			t.Check("wrong: refused", wrong.Error == Codes.Unknown and Codes.Said(wrong) == "That isn't a code")
			t.Equal("too long: no match", Codes.Plain(string.rep("A", Config.Codes.Most + 1)), "")
			t.Equal("not a string: no match", Codes.Plain(42), "")
			t.Equal("the save stays saveable", #Saveable.Problems(data), 0)
		end,
	},
	{
		Name = "Codes: five wrong tries a minute, the sixth refused for a minute, a right one too; then tries again",
		Run = function(t: any)
			local data = fresh()
			local gate = Codes.Gate()
			local list = { CODE }
			for i = 1, Config.Codes.Tries do
				t.Equal(`wrong try {i}: refused as wrong`, Codes.Redeem(data, `guess{i}`, NOW + i, list, gate).Error, Codes.Unknown)
			end
			local sixth = Codes.Redeem(data, "VOIDBREAK", NOW + Config.Codes.Tries + 1, list, gate)
			t.Check("the sixth inside the minute: wait, even a right code", sixth.Error == Codes.Wait and data.Codes == nil)
			t.Equal("its words", Codes.Said(sixth), "Try again in a minute")
			local later = Codes.Redeem(data, "VOIDBREAK", NOW + Config.Codes.Tries + Config.Codes.Wait + 1, list, gate)
			t.Check("after the wait: taken", later.Ok == true)
			-- spread out, wrong tries never add up to a wait
			local slow = Codes.Gate()
			local waited = false
			for i = 1, 12 do
				waited = waited or Codes.Redeem(fresh(), "nope", NOW + i * (Config.Codes.Wait / 4 + 1), list, slow).Error == Codes.Wait
			end
			t.Check("four a minute, never a wait", not waited)
		end,
	},
	{
		Name = "Codes and the week: never Credits, only a crate, a case, a pouch or Standard shards",
		Run = function(t: any)
			local pays = Config.Codes.Pays
			for index, gift in Config.Week do
				t.Check(`day {index}: a chest or a shard, never Credits`, (gift.Chest ~= nil) ~= (gift.Shard ~= nil) and gift.Count >= 1 and (gift :: any).Credits == nil)
			end
			for _, id in pays.Chests do
				local row = ChestRows.ById[id]
				t.Check(`{id}: a chest that holds no gear`, row ~= nil and (row.Tier == ChestRows.Pouch or row.Tier == ChestRows.Crate or string.sub(id, -5) == "_case"))
			end
			t.Check("shards: Standard only", #pays.Shards == 1 and Shards.ById[pays.Shards[1]].Grade == "Standard")
			for _, code in CodeList.List do
				t.Check(`{code.Id}: pays only what a code may`, Codes.Allowed(code))
				t.Check(`{code.Id}: ends`, code.Until > 0)
			end
			t.Check("a code paying a gear chest is refused", not Codes.Allowed({ Id = "x", Code = "X", Gives = { { Chest = "lanternrow_1", Count = 1 } }, Until = 1 }))
			t.Check("a code paying a Named shard is refused", not Codes.Allowed({ Id = "x", Code = "X", Gives = { { Shard = "named_lyric", Count = 1 } }, Until = 1 }))
			t.Check("a code paying nothing is refused", not Codes.Allowed({ Id = "x", Code = "X", Gives = {}, Until = 1 }))
		end,
	},
}
