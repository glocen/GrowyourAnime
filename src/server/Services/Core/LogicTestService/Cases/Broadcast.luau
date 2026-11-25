--!strict
-- Broadcast cases (pure): the Broadcast (TR57; Rules.Broadcast; docs/design.md, "Being seen"). Each event's reach; a
-- bought, failed or typed thing never told; the throttle falling to this server; a bundle every Bundle seconds at most;
-- the plate held behind what covers it; a stale line chat-only; a repeated id shown once; a message at its fullest
-- under 1 kB; the words our own, ids and the display name. Runs in Studio (LogicTests) and with Studio closed
-- (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config.Broadcast)
local VoidkinConfig = require(Shared.Config.Voidkin)
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Broadcast = require(Shared.Rules.Broadcast)
local Collection = require(Shared.Rules.Collection)
local Settings = require(Shared.Rules.Settings)

local T0 = 1_800_000_000
local JOB = "0f6c1c5e-6a7d-4c8e-9c3b-2d7a5e8f1b04" -- a JobId's length

local function fresh(): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	return data
end

local function item(data: Profile.Data, id: string, def: string, rarity: string, reinforce: number?)
	(data.Items :: any)[id] = { Id = id, Def = def, Rarity = rarity, Design = 1, Lines = {}, Sockets = {}, Reinforce = reinforce or 0, Jewels = {} }
end

-- A line as its server sends it.
local function told(kind: string, def: string, rarity: string, level: number, count: number, name: string?): Broadcast.News
	return { Id = `{JOB}:{count}`, Kind = kind, Reach = "All", Def = def, Rarity = rarity, Level = level, User = 1234567890, Name = name or "Mara" }
end

return {
	{
		Name = "Broadcast: each event's reach, an open's rarest only; nothing bought, failed or below its ladder",
		Run = function(t: any)
			local data = fresh()
			item(data, "a", "sword", "Legendary")
			item(data, "b", "helmet", "Epic")
			item(data, "c", "ring", "Rare")
			local open = Broadcast.Read("OpenChests", { Ok = true, Items = { "c", "b", "a" } }, data)
			t.Check("an open with a Legendary: every server, its rarest", open ~= nil and open.Kind == "Item" and open.Reach == "All" and open.Def == "sword" and open.Rarity == "Legendary")
			local epic = Broadcast.Read("OpenChests", { Ok = true, Items = { "c", "b" } }, data)
			t.Check("an Epic: this server", epic ~= nil and epic.Reach == "Server" and epic.Rarity == "Epic")
			t.Check("a Rare: nobody", Broadcast.Read("OpenChests", { Ok = true, Items = { "c" } }, data) == nil)
			t.Check("an item the bag didn't keep (salvaged): nobody", Broadcast.Read("OpenChests", { Ok = true, Items = { "gone" } }, data) == nil)
			-- Reinforce: 20 every server, 15 this one, a failure nobody
			item(data, "r", "sword", "Epic", 20)
			local twenty = Broadcast.Read("Reinforce", { Ok = true, Item = "r", Success = true, Level = 20 }, data)
			t.Check("Reinforce to +20: every server", twenty ~= nil and twenty.Reach == "All" and twenty.Level == 20)
			local fifteen = Broadcast.Read("Reinforce", { Ok = true, Item = "r", Success = true, Level = 15 }, data)
			t.Check("to +15: this server", fifteen ~= nil and fifteen.Reach == "Server")
			t.Check("to +14: nobody", Broadcast.Read("Reinforce", { Ok = true, Item = "r", Success = true, Level = 14 }, data) == nil)
			t.Check("a failed try at +20: nobody", Broadcast.Read("Reinforce", { Ok = true, Item = "r", Success = false, Level = 19 }, data) == nil)
			-- Stars: seven every server, six nobody
			local rook = Collection.Uncover(data, "rook", T0).Id
			local seven = Broadcast.Read("SpendCopies", { Ok = true, Id = rook, Stars = VoidkinConfig.MaxStars }, data)
			t.Check("seven stars: every server", seven ~= nil and seven.Kind == "Stars" and seven.Reach == "All" and seven.Def == "rook")
			t.Check("six: nobody", Broadcast.Read("SpendCopies", { Ok = true, Id = rook, Stars = VoidkinConfig.MaxStars - 1 }, data) == nil)
			-- Firsts from Rare up, this server; a Common nobody; a second Rare nobody
			local found = Collection.Uncover(data, "lyric", T0)
			local firstRare = Broadcast.Read("Open", found, data)
			t.Check("the account's first Rare: this server", firstRare ~= nil and firstRare.Kind == "First" and firstRare.Reach == "Server" and firstRare.Def == "lyric")
			t.Check("a Common: nobody", Broadcast.Read("Open", Collection.Uncover(data, "kirra", T0), data) == nil)
			t.Check("a second Rare: nobody", Broadcast.Read("Open", Collection.Uncover(data, "mirage", T0), data) == nil)
			t.Check("a copy of the first Rare: nobody", Broadcast.Read("Open", Collection.Uncover(data, "lyric", T0), data) == nil)
			-- A keeper's first fall on Hard, this server; on Normal, or a second, nobody
			local hard = Broadcast.Read("KeeperWon", { Ok = true, Ground = "lanternrow", Difficulty = "Hard", Wins = 1 }, data)
			t.Check("the Lamplighter's first fall on Hard: this server", hard ~= nil and hard.Kind == "Keeper" and hard.Reach == "Server" and hard.Level == 2)
			t.Check("on Normal: nobody", Broadcast.Read("KeeperWon", { Ok = true, Ground = "lanternrow", Difficulty = "Normal", Wins = 1 }, data) == nil)
			t.Check("a second on Hard: nobody", Broadcast.Read("KeeperWon", { Ok = true, Ground = "lanternrow", Difficulty = "Hard", Wins = 2 }, data) == nil)
			-- Nothing bought or failed: a ShopBuy, a refusal, an unknown label
			item(data, "s", "sword", "Legendary")
			t.Check("a Legendary bought from the Shop: nobody", Broadcast.Read("ShopBuy", { Ok = true, Items = { "s" }, Item = "s" }, data) == nil)
			t.Check("a refused open: nobody", Broadcast.Read("OpenChests", { Ok = false, Items = { "a" } }, data) == nil)
			t.Check("an answer that isn't a table: nobody", Broadcast.Read("OpenChests", "a", data) == nil)
		end,
	},
	{
		Name = "Broadcast: the Tower's best today from floor 10, a new day starting over; the week's first place taken, not held",
		Run = function(t: any)
			local held = { Day = 0, Floor = 0 }
			t.Check("floor 9: under Least", Broadcast.Record(held, Config.Record.Least - 1, 100) == false)
			t.Check("floor 12: today's best", Broadcast.Record(held, 12, 100) == true)
			t.Check("floor 12 again: not past it", Broadcast.Record(held, 12, 100) == false)
			t.Check("floor 11 the next day: the day's best", Broadcast.Record(held, 11, 101) == true)
			local record = Broadcast.Climb("Record", 11)
			t.Check("told to this server, in its light", record.Reach == "Server" and record.Rarity == Config.Light.Record and record.Level == 11)
			local page = { { Id = 7, Score = 500 }, { Id = 8, Score = 300 } }
			t.Check("past every other account: first place", Broadcast.Leads(page, 8, 600, 12) == true)
			t.Check("not past the first: no", Broadcast.Leads(page, 8, 450, 12) == false)
			t.Check("the first raising its own: not news", Broadcast.Leads(page, 7, 900, 14) == false)
			t.Check("under floor 10: no", Broadcast.Leads(page, 8, 600, Config.Board.Least - 1) == false)
			t.Check("first place to every server", Broadcast.Climb("Board", 12).Reach == "All")
		end,
	},
	{
		Name = "Broadcast: one every-server line a player each 10 minutes, the next falling to this server; off sharing, this server only",
		Run = function(t: any)
			local one = told("Item", "sword", "Legendary", 0, 1)
			t.Check("the first goes to every server", Broadcast.Settle(one, true, nil, T0) == true and one.Reach == "All")
			local two = told("Item", "sword", "Legendary", 0, 2)
			t.Check("one inside 10 minutes falls to this server", Broadcast.Settle(two, true, T0, T0 + Config.Every - 1) == false and two.Reach == "Server")
			local three = told("Item", "sword", "Legendary", 0, 3)
			t.Check("10 minutes on, every server again", Broadcast.Settle(three, true, T0, T0 + Config.Every) == true)
			local four = told("Item", "sword", "Legendary", 0, 4)
			t.Check("sharing off: this server only, never dropped", Broadcast.Settle(four, false, nil, T0) == false and four.Reach == "Server")
			local here: Broadcast.News = told("Item", "helmet", "Epic", 0, 5)
			here.Reach = "Server"
			t.Check("a this-server line stays this server's", Broadcast.Settle(here, true, nil, T0) == false and here.Reach == "Server")
			local data = fresh()
			t.Check("both switches start on", Settings.On(data, "ShareFinds") and Settings.On(data, "ShowFinds"))
			t.Check("a switch set off", Settings.Set(data, { Name = "ShowFinds", Value = false }).Ok == true and not Settings.On(data, "ShowFinds"))
			t.Equal("a switch set to a number", Settings.Set(data, { Name = "ShareFinds", Value = 0 }).Error, Settings.Bad)
			t.Check("an old save without them reads on", Settings.On({ Settings = {} } :: any, "ShareFinds"))
		end,
	},
	{
		Name = "Broadcast: a message every 5 s at most, under 1 kB at its fullest, ids and numbers only, read back whole",
		Run = function(t: any)
			local box = Broadcast.Outbox()
			t.Check("nothing waiting: no message", Broadcast.Send(box, JOB, T0) == nil)
			table.insert(box.Lines, told("Item", "sword", "Legendary", 0, 1))
			local first = Broadcast.Send(box, JOB, T0)
			t.Check("a line waiting: a message", first ~= nil and #box.Lines == 0)
			table.insert(box.Lines, told("Reinforce", "sword", "Epic", 20, 2))
			t.Check("inside 5 s of the last: none", Broadcast.Send(box, JOB, T0 + Config.Bundle - 0.1) == nil and #box.Lines == 1)
			t.Check("5 s on: the next", Broadcast.Send(box, JOB, T0 + Config.Bundle) ~= nil)
			-- At its fullest: the longest name Roblox allows, every character 4 bytes, many lines waiting
			local widest = string.rep("\u{1F600}", 20)
			local many: { Broadcast.News } = {}
			for count = 1, 12 do
				table.insert(many, told("Reinforce", "throwing_blades", "Legendary", 100000, 2 ^ 52 + count, widest))
			end
			local full = Broadcast.Bundle(many, JOB)
			local size = if full then Broadcast.Size(full) else 0
			t.Check("at its fullest, under Bytes", full ~= nil and size <= Config.Bytes and size < 1024, `{size} bytes, {if full then #full.L else 0} lines`)
			t.Check("the rest wait for the next", #many > 0 and #many < 12, `{#many} waiting`)
			-- What's carried: ids and numbers, the display name the only text not ours
			local line = told("First", "lyric", "Rare", 0, 7)
			local message = Broadcast.Bundle({ line }, JOB) :: any
			local carried = message.L[1]
			t.Check("a line carries a kind, ids, numbers and the name", #carried == 7 and type(carried[1]) == "number" and carried[2] == "lyric" and carried[6] == "Mara")
			local back, job = Broadcast.Unpack(message)
			t.Check("read back whole, its id kept", job == JOB and #back == 1 and back[1].Id == `{JOB}:7` and back[1].Def == "lyric" and back[1].Reach == "All")
			-- The size counts high: against a JSON a real encoder would write, for plain text
			t.Equal("a small table's size", Broadcast.Size({ A = 1, B = { "x", 22 } }), #'{"A":1,"B":["x",22]}')
		end,
	},
	{
		Name = "Broadcast: a message that's off is left out: an unknown kind, a definition we don't have, words in place of ids",
		Run = function(t: any)
			local good = Broadcast.Bundle({ told("Stars", "rook", "Common", 7, 1) }, JOB) :: any
			local function with(change: (line: { any }) -> ()): number
				local copy = table.clone(good)
				copy.L = { table.clone(good.L[1]) }
				change(copy.L[1])
				return #(Broadcast.Unpack(copy))
			end
			t.Equal("the good line", with(function() end), 1)
			t.Equal("an unknown kind", with(function(line) line[1] = 99 end), 0)
			t.Equal("a Voidkin we don't have", with(function(line) line[2] = "nobody" end), 0)
			t.Equal("words in place of an id", with(function(line) line[2] = "<b>free gear at</b>" end), 0)
			t.Equal("a rarity we don't have", with(function(line) line[3] = "Godly" end), 0)
			t.Equal("a name past 80 bytes", with(function(line) line[6] = string.rep("x", 81) end), 0)
			t.Equal("no name", with(function(line) line[6] = "" end), 0)
			t.Equal("a level that isn't whole", with(function(line) line[4] = 7.5 end), 0)
			t.Equal("another version", #(Broadcast.Unpack({ V = 2, J = JOB, L = good.L })), 0)
			t.Equal("not a table", #(Broadcast.Unpack("hello")), 0)
		end,
	},
	{
		Name = "Broadcast: the words, ours and the display name, the rarity and the item or the Voidkin lit; never a nickname; escaped as rich text",
		Run = function(t: any)
			local function said(news: Broadcast.News): string
				local parts = Broadcast.Line(news)
				return Broadcast.Plain(parts)
			end
			t.Equal("an item", said(told("Item", "sword", "Legendary", 0, 1)), "Mara found a Legendary Sword")
			t.Equal("an Epic: an", said(told("Item", "helmet", "Epic", 0, 1)), "Mara found an Epic Helmet")
			t.Equal("a pair: no article", said(told("Item", "gloves", "Legendary", 0, 1)), "Mara found Legendary Gloves")
			t.Equal("Reinforce", said(told("Reinforce", "sword", "Epic", 20, 1)), "Mara's Sword reached +20")
			t.Equal("stars", said(told("Stars", "rook", "Common", 7, 1)), "Mara's Rook reached seven stars")
			t.Equal("a first", said(told("First", "lyric", "Rare", 0, 1)), "Mara found Lyric in a shard")
			t.Equal("a keeper", said(told("Keeper", "lanternrow", "Epic", 2, 1)), "Mara beat the Lamplighter on Hard")
			t.Equal("the Tower's week", said(told("Board", "", "Legendary", 14, 1)), "Mara leads the Tower this week, floor 14")
			t.Equal("this server's best", said(told("Record", "", "Rare", 12, 1)), "Mara reached floor 12, this server's best today")
			local parts = Broadcast.Line(told("Item", "sword", "Legendary", 0, 1))
			t.Check("the rarity and the item lit, the rest not", #parts == 2 and parts[2].Lit and parts[2].Text == "Legendary Sword" and not parts[1].Lit)
			-- A nickname is never read: the line names the Voidkin's own name
			local data = fresh()
			local found = Collection.Uncover(data, "lyric", T0)
			data.Voidkin[found.Id].Nickname = "free robux here"
			local first = Broadcast.Read("Open", found, data) :: Broadcast.News
			first.Name = "Mara"
			t.Equal("a nicknamed Voidkin, by its own name", said(first), "Mara found Lyric in a shard")
			-- Every word but the name is ours: the line less the name is the same for any name
			local plain = said(told("Item", "sword", "Legendary", 0, 1, "Zed"))
			t.Equal("only the name changes", (string.gsub(plain, "^Zed", "")), (string.gsub(said(told("Item", "sword", "Legendary", 0, 1)), "^Mara", "")))
			local rich = Broadcast.Rich(Broadcast.Line(told("Item", "sword", "Legendary", 0, 1, "<b>Mara</b>")), "FFC94A")
			t.Equal("rich text: the name escaped, the lit part coloured", rich, `&lt;b&gt;Mara&lt;/b&gt; found a <font color="#FFC94A">Legendary Sword</font>`)
		end,
	},
	{
		Name = "Broadcast: the plate one at a time, one each 20 s, held while covered, near lines first, a stale line chat-only, an id shown once",
		Run = function(t: any)
			local queue = Broadcast.Queue()
			local a = told("Item", "helmet", "Epic", 0, 1)
			t.Equal("a near line waits", Broadcast.Hear(queue, a, T0, true), "Wait")
			local shown, stale = Broadcast.Step(queue, T0, true)
			t.Check("covered (a card, a ring, a reveal, a screen): held", shown == nil and #stale == 0 and #queue.Waiting == 1)
			shown = Broadcast.Step(queue, T0 + 1, false)
			t.Check("uncovered: shown", shown == a and #queue.Waiting == 0)
			local far = told("Item", "sword", "Legendary", 0, 2)
			t.Equal("a stranger's every-server line inside 20 s: the chat only", Broadcast.Hear(queue, far, T0 + 5, false), "Chat")
			local near = told("Item", "helmet", "Epic", 0, 3)
			t.Equal("a near one inside 20 s waits", Broadcast.Hear(queue, near, T0 + 5, true), "Wait")
			t.Check("not before 20 s from the last", (Broadcast.Step(queue, T0 + 20, false)) == nil)
			t.Check("at 20 s, the next", (Broadcast.Step(queue, T0 + 21, false)) == near)
			-- Near first: a stranger's line waiting, then a friend's, the friend's shows first
			local q2 = Broadcast.Queue()
			local stranger = told("Item", "sword", "Legendary", 0, 4)
			local friend = told("Item", "ring", "Legendary", 0, 5)
			Broadcast.Hear(q2, stranger, T0, false)
			Broadcast.Hear(q2, friend, T0 + 1, true)
			t.Check("near lines first", (Broadcast.Step(q2, T0 + 2, false)) == friend)
			-- Stale: a line still waiting after 60 s goes to the chat only
			local q3 = Broadcast.Queue()
			local old = told("Item", "helmet", "Epic", 0, 6)
			Broadcast.Hear(q3, old, T0, true)
			local none, gone = Broadcast.Step(q3, T0 + Config.Plate.Stale + 1, true)
			t.Check("stale: the chat only, never the plate", none == nil and #gone == 1 and gone[1] == old and #q3.Waiting == 0)
			-- An id heard twice is shown once
			local seen: Broadcast.Seen = {}
			t.Check("an id the first time", Broadcast.Fresh(seen, `{JOB}:9`, T0) == true)
			t.Check("the same id again: not shown", Broadcast.Fresh(seen, `{JOB}:9`, T0 + 1) == false)
			t.Check("forgotten after Stale", Broadcast.Fresh(seen, `{JOB}:9`, T0 + Config.Plate.Stale + 2) == true)
		end,
	},
}
