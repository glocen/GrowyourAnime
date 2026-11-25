--!strict
-- Logic cases (pure): the boards on the Strip (TR58; Rules.Boards; Config.Boards). A post only raises, the throttle, the
-- top ten and the own-rank line from a made-up page, a store keyed by id and never a name, each account's number, and the
-- stores' budget at a full server. Runs in Studio (LogicTests) and with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Config = require(Shared.Config.Boards)
local Boards = require(Shared.Rules.Boards)
local Collection = require(Shared.Rules.Collection)
local Stats = require(Shared.Rules.Stats)
local Voidkin = require(Shared.Definitions.Voidkin)

local NOW = 1_800_000_000
local FULL = 8 -- players a server holds (Max Players)

local function fresh(): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	return data
end

-- A made-up page: `n` entries, ids 1001 up, scores falling by 10 from 10,000, best first.
local function page(n: number): { Boards.Entry }
	local out: { Boards.Entry } = {}
	for i = 1, n do
		table.insert(out, { Id = 1000 + i, Score = 10_000 - 10 * i })
	end
	return out
end

return {
	{
		Name = "Boards: a post only raises; the store's write cancels when what's stored is as high",
		Run = function(t: any)
			t.Equal("nothing stored: written", Boards.Raise(nil, 5), 5)
			t.Equal("lower stored: raised", Boards.Raise(3, 5), 5)
			t.Equal("as high stored: no write", Boards.Raise(5, 5), nil)
			t.Equal("higher stored: no write", Boards.Raise(7, 5), nil)
			t.Equal("a stored value that isn't a number: written over", Boards.Raise("x", 5), 5)
		end,
	},
	{
		Name = "Boards: the throttle, one post a player a board each Post seconds and as they leave, never a number that fell",
		Run = function(t: any)
			local post = Config.Post
			t.Check("nothing yet: nothing to post", not Boards.Due(nil, 0, 0, false))
			t.Check("a first number: posted at once", Boards.Due(nil, 10, 0, false))
			local last: Boards.Post = { Value = 10, At = 0 }
			t.Check("the same number: not again", not Boards.Due(last, 10, post * 4, false))
			t.Check("higher inside Post seconds: waits", not Boards.Due(last, 12, post - 1, false))
			t.Check("higher at Post seconds: posted", Boards.Due(last, 12, post, false))
			t.Check("higher as they leave: posted at once", Boards.Due(last, 12, 1, true))
			t.Check("a number that fell: never, leaving or not", not Boards.Due(last, 8, post * 4, false) and not Boards.Due(last, 8, post * 4, true))
		end,
	},
	{
		Name = "Boards: the top ten and the own-rank line from a made-up page; ties by id; a newer own number in its place",
		Run = function(t: any)
			local shown, full = Config.Shown, Config.Page
			-- inside the ten: their row among the rows, no line under
			local rows, own = Boards.Rank(page(30), 1004, 9960, shown, full)
			t.Check("ten rows, best first", #rows == shown and rows[1].Id == 1001 and rows[1].Rank == 1 and rows[shown].Rank == shown)
			t.Check("their own at 4th", own ~= nil and own.Rank == 4 and rows[4].Id == 1004)
			-- outside the ten: rows without them, their rank under
			rows, own = Boards.Rank(page(30), 1014, 9860, shown, full)
			local among = false
			for _, row in rows do
				among = among or row.Id == 1014
			end
			t.Check("14th: not among the ten, their rank under", not among and own ~= nil and own.Rank == 14 and own.Score == 9860)
			-- a newer number than the page holds: their save's, in its place
			rows, own = Boards.Rank(page(30), 1020, 9995, shown, full)
			t.Check("raised past the first: first, the old row gone", own ~= nil and own.Rank == 1 and rows[1].Id == 1020 and #rows == shown and rows[2].Id == 1001)
			-- under a full page: no rank, their number kept
			rows, own = Boards.Rank(page(full), 9999, 5, shown, full)
			t.Check("under a full page: a rank of none, their number", own ~= nil and own.Rank == nil and own.Score == 5 and #rows == shown)
			-- ties go by id
			rows = Boards.Rank({ { Id = 30, Score = 50 }, { Id = 20, Score = 50 }, { Id = 40, Score = 60 } }, 1, nil, shown, full)
			t.Check("equal numbers by id", rows[1].Id == 40 and rows[2].Id == 20 and rows[3].Id == 30)
			-- no number: no own row
			rows, own = Boards.Rank(page(3), 77, 0, shown, full)
			t.Check("no number of their own: no own row, the page as it is", own == nil and #rows == 3)
			rows = Boards.Rank({}, 77, nil, shown, full)
			t.Equal("an empty board: no rows", #rows, 0)
		end,
	},
	{
		Name = "Boards: a store is keyed by UserId alone, never a name; a page's other keys and values are dropped",
		Run = function(t: any)
			t.Equal("the key is the UserId", Boards.Key(123456), "123456")
			local entries = Boards.Entries({
				{ key = "123456", value = 50 },
				{ key = "Alice", value = 90 },
				{ key = "12.5", value = 40 },
				{ key = "-3", value = 30 },
				{ key = "777", value = "x" },
				{ key = "888", value = 20 },
			})
			t.Check("only whole UserIds with numbers", #entries == 2 and entries[1].Id == 123456 and entries[1].Score == 50 and entries[2].Id == 888, `{#entries} kept`)
			for _, entry in entries do
				t.Check("an entry holds an id and a number, nothing else", type(entry.Id) == "number" and type(entry.Score) == "number" and (entry :: any).Name == nil)
			end
		end,
	},
	{
		Name = "Boards: each account's number, its lead's Combat Power as it shows and every star its Voidkin hold",
		Run = function(t: any)
			local data = fresh()
			data.Roles.Lead = ""
			t.Equal("no lead: 0", Boards.Value(data, "Lead"), 0)
			local first = Collection.Uncover(data, Voidkin.List[1].Id, NOW)
			local second = Collection.Uncover(data, Voidkin.List[2].Id, NOW + 5)
			data.Roles.Lead = first.Id :: string
			local owned = data.Voidkin[first.Id :: string]
			local power = Stats.Power((Stats.Resolve(owned, Stats.PresetOf(data, owned), data)))
			t.Check("the lead's Combat Power as it shows", power > 0 and Boards.Value(data, "Lead") == power, `{Boards.Value(data, "Lead")} against {power}`)
			local stars = 0
			for _, each in data.Voidkin do
				stars += each.Stars
			end
			data.Voidkin[second.Id :: string].Stars += 3
			t.Equal("every star the collection holds", Boards.Value(data, "Stars"), stars + 3)
			t.Equal("a board it doesn't keep: 0", Boards.Value(data, "Week"), 0)
		end,
	},
	{
		Name = "Boards: the stores' budget at a full server, reads and posts a minute against Roblox's limits (SOURCED, creator-docs)",
		Run = function(t: any)
			local stored = 0
			for _ in Config.Stores do
				stored += 1
			end
			local reads = (stored + 1) * 60 / Config.Read -- the Tower's week is read as often
			local posts = stored * FULL * 60 / Config.Post
			t.Check("reads a minute inside GetSortedAsync's 5 + 2 a player", reads <= 5 + 2 * FULL, `{reads} a minute`)
			t.Check("posts a minute inside a third of the writes' 30 + 5 a player, the saves keep the rest", posts <= (30 + 5 * FULL) / 3, `{posts} a minute`)
			t.Check("every board in the order but the Tower's week and the news is a store", Config.Stores.Lead ~= nil and Config.Stores.Stars ~= nil and Config.Stores.Week == nil and Config.Stores.News == nil)
		end,
	},
}
