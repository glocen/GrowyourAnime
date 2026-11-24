--!strict
-- Broadcast cases (pure): what a committed change tells and to whom (Rules.Broadcast; launch-design.md, section 6). The
-- ladder read from each label's answer, never a purchase or a failure; the Tower's record and the week's first place;
-- every server or this one; the message checked whole on its way in; the words, never a nickname; the gate's Most a
-- Window; the Broadcast's two switches. Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config.Broadcast)
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Items = require(Shared.Definitions.Items)
local Voidkin = require(Shared.Definitions.Voidkin)
local Broadcast = require(Shared.Rules.Broadcast)
local Collection = require(Shared.Rules.Collection)
local Settings = require(Shared.Rules.Settings)

local function fresh(): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	return data
end

-- An item kept in the bag, as a chest's open leaves it.
local function give(data: Profile.Data, id: string, rarity: string): Profile.OwnedItem
	local def = Items.List[1].Id
	local item: Profile.OwnedItem = {
		Id = id,
		Def = def,
		Tier = 1,
		Rarity = rarity,
		Design = 1,
		Lines = {},
		Sockets = {},
		Reinforce = 0,
		Jewels = {},
	}
	data.Items[id] = item
	return item
end

local function ofRarity(rarity: string): { string }
	local out = {}
	for _, row in Voidkin.List do
		if row.Rarity == rarity then
			table.insert(out, row.Id)
		end
	end
	return out
end

return {
	{
		Name = "Broadcast: an open tells its rarest kept item, a Legendary every server, an Epic this one; nothing else, nothing bought or failed",
		Run = function(t: any)
			local data = fresh()
			give(data, "a", "Common")
			give(data, "b", "Epic")
			local legend = give(data, "c", "Legendary")
			local said = Broadcast.Read("OpenChests", { Ok = true, Items = { "a", "b", "c" } }, data)
			t.Check("one line, the Legendary", said ~= nil and said.Kind == "Item" and said.Rarity == "Legendary" and said.Reach == "All")
			t.Check("its item's design", said ~= nil and said.Def == legend.Def and said.Design == 1)
			local epic = Broadcast.Read("OpenChests", { Ok = true, Items = { "a", "b" } }, data)
			t.Check("an Epic, this server", epic ~= nil and epic.Reach == "Server" and epic.Rarity == "Epic")
			t.Equal("a Common alone tells nothing", Broadcast.Read("OpenChests", { Ok = true, Items = { "a" } }, data), nil)
			t.Equal("an id the bag doesn't hold (salvaged) tells nothing", Broadcast.Read("OpenChests", { Ok = true, Items = { "zz" } }, data), nil)
			t.Equal("a refusal tells nothing", Broadcast.Read("OpenChests", { Ok = false, Items = { "c" } }, data), nil)
			t.Equal("a purchase is never read", Broadcast.Read("ShopBuy", { Ok = true, Items = { "c" }, Item = "c" }, data), nil)
			t.Equal("nor a gift by hand", Broadcast.Read("ItemGive", { Ok = true, Items = { "c" } }, data), nil)
			t.Equal("an answer that isn't a table", Broadcast.Read("OpenChests", "c", data), nil)
		end,
	},
	{
		Name = "Broadcast: a Reinforce success at +15 tells this server and at +20 every server; a failure never",
		Run = function(t: any)
			local data = fresh()
			give(data, "x", "Rare")
			local function tried(level: number, success: boolean): Broadcast.News?
				return Broadcast.Read("Reinforce", { Ok = true, Item = "x", Success = success, Level = level }, data)
			end
			t.Equal("+14 tells nothing", tried(Config.Reinforce.Server - 1, true), nil)
			local server = tried(Config.Reinforce.Server, true)
			t.Check("+15, this server", server ~= nil and server.Reach == "Server" and server.Level == Config.Reinforce.Server)
			local all = tried(Config.Reinforce.All, true)
			t.Check("+20, every server, in the item's light", all ~= nil and all.Reach == "All" and all.Rarity == "Rare")
			t.Equal("a failure at +20 tells nothing", tried(Config.Reinforce.All, false), nil)
			t.Equal("an item that's gone", Broadcast.Read("Reinforce", { Ok = true, Item = "gone", Success = true, Level = 25 }, data), nil)
		end,
	},
	{
		Name = "Broadcast: seven stars tell every server by the Voidkin's own name; an account's first Rare tells this server, its second nothing",
		Run = function(t: any)
			local data = fresh()
			local rares = ofRarity("Rare")
			local commons = ofRarity("Common")
			t.Check("the roster has two Rares and a Common to test with", #rares >= 2 and #commons >= 1)
			local common = Collection.Uncover(data, commons[1], 0)
			t.Equal("a new Common tells nothing", Broadcast.Read("Open", common, data), nil)
			local one = Collection.Uncover(data, rares[1], 0)
			local said = Broadcast.Read("Open", one, data)
			t.Check("the first Rare, this server", said ~= nil and said.Kind == "First" and said.Reach == "Server" and said.Def == rares[1])
			local copy = Collection.Uncover(data, rares[1], 0)
			t.Equal("a copy of it tells nothing", Broadcast.Read("Open", copy, data), nil)
			local two = Collection.Uncover(data, rares[2], 0)
			t.Equal("the second Rare tells nothing", Broadcast.Read("Open", two, data), nil)

			local owned = data.Voidkin[one.Id]
			owned.Nickname = "Sparkle"
			owned.Stars = 7
			local stars = Broadcast.Read("SpendCopies", { Ok = true, Id = one.Id, Stars = 7, Copies = 0, Credits = 0 }, data)
			t.Check("seven stars, every server", stars ~= nil and stars.Kind == "Stars" and stars.Reach == "All" and stars.Level == 7)
			if stars then
				stars.Name = "Mika"
				local words = Broadcast.Line(stars)
				t.Check("the line names its own name, never the nickname", words:find(Voidkin.ById[rares[1]].Name, 1, true) ~= nil and words:find("Sparkle", 1, true) == nil, words)
			end
			t.Equal("six stars tell nothing", Broadcast.Read("SpendCopies", { Ok = true, Id = one.Id, Stars = 6 }, data), nil)
		end,
	},
	{
		Name = "Broadcast: a keeper's first win on Hard tells this server; its second, or a first on Normal, nothing",
		Run = function(t: any)
			local data = fresh()
			local said = Broadcast.Read("KeeperWon", { Ok = true, Ground = "lanternrow", Difficulty = "Hard", Wins = 1 }, data)
			t.Check("the first on Hard", said ~= nil and said.Kind == "Keeper" and said.Reach == "Server" and said.Level == 2)
			if said then
				said.Name = "Mika"
				local words = Broadcast.Line(said)
				t.Check("it names the keeper and the difficulty", words:find("the Lamplighter", 1, true) ~= nil and words:find("Hard", 1, true) ~= nil, words)
			end
			t.Equal("the second on Hard", Broadcast.Read("KeeperWon", { Ok = true, Ground = "lanternrow", Difficulty = "Hard", Wins = 2 }, data), nil)
			t.Equal("the first on Normal", Broadcast.Read("KeeperWon", { Ok = true, Ground = "lanternrow", Difficulty = "Normal", Wins = 1 }, data), nil)
			t.Equal("a ground that isn't one", Broadcast.Read("KeeperWon", { Ok = true, Ground = "nowhere", Difficulty = "Hard", Wins = 1 }, data), nil)
		end,
	},
	{
		Name = "Broadcast: the Tower's server record from its least floor up, and the week's first place taken, not held",
		Run = function(t: any)
			local least = Config.Record.Least
			t.Check("under the least floor, no record", not Broadcast.Record(0, least - 1))
			t.Check("the least floor on a new server", Broadcast.Record(0, least))
			t.Check("level with the record, none", not Broadcast.Record(least + 2, least + 2))
			t.Check("past it", Broadcast.Record(least + 2, least + 3))
			local record = Broadcast.Climb("Record", least + 3)
			t.Check("a record's news", record.Kind == "Record" and record.Reach == Config.Record.Reach and record.Level == least + 3)

			local floor = Config.Board.Least
			t.Check("an empty board, at the least floor", Broadcast.Leads({}, 1, 50, floor))
			t.Check("under the least floor, never", not Broadcast.Leads({}, 1, 50, floor - 1))
			local board = { { Id = 2, Score = 80 }, { Id = 1, Score = 60 } }
			t.Check("under the leader, no", not Broadcast.Leads(board, 1, 70, floor))
			t.Check("past the leader, yes", Broadcast.Leads(board, 1, 90, floor))
			t.Check("a tie isn't first", not Broadcast.Leads(board, 1, 80, floor))
			t.Check("the leader climbing on, told once only", not Broadcast.Leads(board, 2, 95, floor))
			local lead = Broadcast.Climb("Board", floor)
			t.Check("the week's first place, every server", lead.Reach == Config.Board.Reach and lead.Rarity == Config.Light.Board)
		end,
	},
	{
		Name = "Broadcast: every server only when shared and not told in the last Every seconds; else this server",
		Run = function(t: any)
			local data = fresh()
			give(data, "c", "Legendary")
			local function legend(): Broadcast.News
				return Broadcast.Read("OpenChests", { Ok = true, Items = { "c" } }, data) :: Broadcast.News
			end
			local first = legend()
			t.Check("the first, every server", Broadcast.Settle(first, true, nil, 1000) and first.Reach == "All")
			local soon = legend()
			t.Check("another inside Every, this server", not Broadcast.Settle(soon, true, 1000, 1000 + Config.Every - 1) and soon.Reach == "Server")
			local later = legend()
			t.Check("one at Every, every server", Broadcast.Settle(later, true, 1000, 1000 + Config.Every) and later.Reach == "All")
			local kept = legend()
			t.Check("not shared, this server", not Broadcast.Settle(kept, false, nil, 1000) and kept.Reach == "Server")
			local here = Broadcast.Climb("Record", 30)
			t.Check("a this-server line stays here", not Broadcast.Settle(here, true, nil, 1000) and here.Reach == "Server")
		end,
	},
	{
		Name = "Broadcast: the message carries ids and numbers, comes back whole, and anything off is refused",
		Run = function(t: any)
			local data = fresh()
			give(data, "c", "Legendary")
			local said = Broadcast.Read("OpenChests", { Ok = true, Items = { "c" } }, data) :: Broadcast.News
			said.User, said.Name = 42, "Mika"
			local message = Broadcast.Pack(said, "job-1")
			local size = 0
			for key, value in message do
				size += #tostring(key) + #tostring(value) + 6
			end
			t.Check("well under 1 kB", size < 200, tostring(size))
			local back, job = Broadcast.Unpack(message)
			t.Check("it comes back whole", back ~= nil and back.Kind == said.Kind and back.Def == said.Def and back.Design == said.Design and back.User == 42 and back.Name == "Mika" and back.Reach == "All")
			t.Equal("and its job", job, "job-1")
			t.Check("the same words both sides", back ~= nil and Broadcast.Line(back) == Broadcast.Line(said))
			local function off(key: string, value: any): boolean
				local copy = table.clone(message)
				copy[key] = value
				return Broadcast.Unpack(copy) == nil
			end
			t.Check("another version", off("V", 2))
			t.Check("an unknown kind", off("K", "Chat"))
			t.Check("an unknown item", off("D", "no_such_item"))
			t.Check("an unknown rarity", off("R", "Shiny"))
			t.Check("a design its kind doesn't have", off("G", 999))
			t.Check("a level that isn't whole", off("L", 1.5))
			t.Check("no user", off("U", 0))
			t.Check("an empty name", off("N", ""))
			t.Check("a name past its length", off("N", string.rep("a", 129)))
			t.Check("words where a number goes", off("L", "20"))
			t.Equal("not a table", Broadcast.Unpack("Mika found everything"), nil)
			local tower = Broadcast.Climb("Board", 40)
			tower.User, tower.Name = 7, "Ren"
			local told = Broadcast.Unpack(Broadcast.Pack(tower, ""))
			t.Check("the Tower's comes back too", told ~= nil and told.Kind == "Board" and told.Level == 40)
			local pinned = Broadcast.Pack(tower, "")
			pinned.D = "lanternrow"
			t.Equal("the Tower's with a definition", Broadcast.Unpack(pinned), nil)
		end,
	},
	{
		Name = "Broadcast: the words for each kind, and a name made safe for rich text",
		Run = function(t: any)
			local data = fresh()
			local item = give(data, "c", "Legendary")
			local design = Items.Design(item)
			local said = Broadcast.Read("OpenChests", { Ok = true, Items = { "c" } }, data) :: Broadcast.News
			said.Name = "Mika"
			local words, light = Broadcast.Line(said)
			t.Check("an item by its design's name, in its light", design ~= nil and words == `Mika found {design.Name}` and light == "Legendary", words)
			local up = Broadcast.Read("Reinforce", { Ok = true, Item = "c", Success = true, Level = 21 }, data) :: Broadcast.News
			up.Name = "Mika"
			t.Check("a Reinforce names its level", (Broadcast.Line(up)):find("+21", 1, true) ~= nil)
			for _, kind in { "Record", "Board" } do
				local climb = Broadcast.Climb(kind :: any, 33)
				climb.Name = "Ren"
				t.Check(`{kind} names the floor`, (Broadcast.Line(climb)):find("floor 33", 1, true) ~= nil)
			end
			t.Equal("rich text's marks escaped", Broadcast.Escape([[<b>"A" & 'B'</b>]]), "&lt;b&gt;&quot;A&quot; &amp; &apos;B&apos;&lt;/b&gt;")
		end,
	},
	{
		Name = "Broadcast: the gate shows Most a Window, holds the rest in order, and drops the oldest waiting past its room",
		Run = function(t: any)
			local gate = Broadcast.Gate()
			for floor = 1, Config.Waiting do
				Broadcast.Wait(gate, Broadcast.Climb("Record", floor))
			end
			local now = Broadcast.Release(gate, 100)
			t.Equal("Most at once", #now, math.min(Config.Most, Config.Waiting))
			t.Equal("oldest first", now[1].Level, 1)
			Broadcast.Wait(gate, Broadcast.Climb("Record", 99))
			t.Equal("none more inside the Window", #Broadcast.Release(gate, 100 + Config.Window - 1), 0)
			local after = Broadcast.Release(gate, 100 + Config.Window)
			t.Check("the waiting one once the Window has passed", #after == 1 and after[1].Level == 99)
			local full = Broadcast.Gate()
			for floor = 1, Config.Waiting + 3 do
				Broadcast.Wait(full, Broadcast.Climb("Record", floor))
			end
			t.Check("held to its room, the oldest dropped", #full.Waiting == Config.Waiting and full.Waiting[1].Level == 4)
			local list = { 1, 2, 3 }
			Broadcast.Push(list, 4, 3)
			t.Check("a list held to its most", #list == 3 and list[1] == 2 and list[3] == 4)
		end,
	},
	{
		Name = "Settings: the Broadcast's two switches start on, take true or false, refuse anything else, and leave the levels alone",
		Run = function(t: any)
			local data = fresh()
			for _, name in Settings.Switches do
				t.Check(`{name} starts on`, Settings.On(data, name))
			end
			local set = Settings.Set(data, { Name = "ShareFinds", Value = false })
			t.Check("ShareFinds off", set.Ok == true and set.Value == false and not Settings.On(data, "ShareFinds"))
			t.Equal("a number for a switch", Settings.Set(data, { Name = "ShowFinds", Value = 0 }).Error, Settings.Bad)
			t.Equal("a word for a switch", Settings.Set(data, { Name = "ShowFinds", Value = "off" }).Error, Settings.Bad)
			t.Check("ShowFinds still on", Settings.On(data, "ShowFinds"))
			t.Equal("true for a level", Settings.Set(data, { Name = "Music", Value = true }).Error, Settings.Bad)
			t.Check("the levels untouched", data.Settings.Music == 1 and data.Settings.Sound == 1 and data.Settings.Effects == 1)
			local old = fresh()
			;(old.Settings :: any).ShareFinds = nil
			t.Check("a save from before them reads on", Settings.On(old, "ShareFinds"))
		end,
	},
}
