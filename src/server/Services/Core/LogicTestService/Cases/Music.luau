--!strict
-- Logic cases (pure): the music's places and its shuffle (Rules.Music; Config.Music). Runs in Studio (LogicTests) and with
-- Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Music = require(Shared.Rules.Music)
local MusicConfig = require(Shared.Config.Music)

local function where(try: boolean, tower: boolean, row: boolean, plot: boolean): Music.Where
	return { Try = try, Tower = tower, Row = row, Plot = plot }
end

return {
	{
		Name = "Music: the place playing is the first that holds, a keeper's try, a Tower run, Lantern Row, the plot, the Strip",
		Run = function(t: any)
			t.Equal("nowhere else: the Strip", Music.Place(where(false, false, false, false)), "Strip")
			t.Equal("on the plot", Music.Place(where(false, false, false, true)), "Base")
			t.Equal("north of the gate", Music.Place(where(false, false, true, false)), "LanternRow")
			t.Equal("a Tower run over its plot", Music.Place(where(false, true, false, true)), "Tower")
			t.Equal("a keeper's try over the street", Music.Place(where(true, false, true, false)), "Keeper")
			for _, place in { "Strip", "Base", "LanternRow", "Keeper", "Tower" } do
				local list = MusicConfig.Lists[place]
				t.Check(`{place} has its list in Config.Music`, list ~= nil and type(list.Ids) == "table" and type(list.Volume) == "number")
				for index, pasted in if list then list.Ids else {} do
					t.Check(`{place}'s track {index} reads as an id`, Music.Id(pasted) ~= nil, tostring(pasted))
				end
			end
		end,
	},
	{
		Name = "Music: a pasted id reads as its number however it's pasted, and the shuffle never plays one twice running",
		Run = function(t: any)
			t.Equal("a number", Music.Id(1234567890), 1234567890)
			t.Equal("its digits in quotes", Music.Id("1234567890"), 1234567890)
			t.Equal("the asset address whole", Music.Id("rbxassetid://1234567890"), 1234567890)
			t.Check("nothing, zero, a fraction or words: none", Music.Id(nil) == nil and Music.Id(0) == nil and Music.Id(1.5) == nil and Music.Id("song") == nil)
			t.Equal("an empty list plays nothing", Music.Next({}, 0, function(_n: number): number
				return 1
			end), nil)
			t.Equal("one track plays again", Music.Next({ 111 }, 1, function(_n: number): number
				return 1
			end), 1)
			local ids = { 111, 222, 333, 444 }
			local seed = 7 -- a small generator of its own, so the case runs with Studio closed
			local last, repeats, seen = 0, 0, {}
			for _ = 1, 400 do
				local index = Music.Next(ids, last, function(n: number): number
					seed = (seed * 1103515245 + 12345) % 2147483648
					return 1 + (seed // 65536) % n
				end) :: number
				repeats += if index == last then 1 else 0
				seen[index] = true
				last = index
			end
			t.Equal("400 picks: never the same twice running", repeats, 0)
			t.Check("every track plays", seen[1] and seen[2] and seen[3] and seen[4])
			t.Equal("a bad entry is passed over", Music.Next({ "oops", 222 }, 2, function(_n: number): number
				return 1
			end), 2)
		end,
	},
	{
		Name = "Music: the director's folders (2026-11-24), M at the base and on the Strip, C in the game modes only; a change of place that shares the playing track plays on",
		Run = function(t: any)
			local function same(a: { any }, b: { any }): boolean
				if #a ~= #b then
					return false
				end
				for index, pasted in a do
					if Music.Id(pasted) ~= Music.Id(b[index]) then
						return false
					end
				end
				return true
			end
			local lists = MusicConfig.Lists
			t.Check("the base and the Strip play the same list (M)", #lists.Base.Ids > 0 and same(lists.Base.Ids, lists.Strip.Ids))
			t.Check("the Festival's runs, a keeper's try and the Tower play the same list (C)", #lists.LanternRow.Ids > 0 and same(lists.LanternRow.Ids, lists.Keeper.Ids) and same(lists.LanternRow.Ids, lists.Tower.Ids))
			local shared = false
			for _, pasted in lists.Base.Ids do
				shared = shared or Music.Holds(lists.LanternRow.Ids, Music.Id(pasted)) ~= nil
			end
			t.Check("no M track in C's places", not shared)
			t.Equal("a list holds a track however it was pasted", Music.Holds({ 111, "rbxassetid://222" }, 222), 2)
			t.Equal("not one it lacks", Music.Holds({ 111, 222 }, 333), nil)
			t.Equal("nor nothing", Music.Holds({ 111 }, nil), nil)
		end,
	},
}
