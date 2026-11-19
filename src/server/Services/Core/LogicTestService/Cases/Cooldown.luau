--!strict
-- Cooldown cases (pure): TR10 (the director, 2026-11-14). The elite comes back on the server's one timer, the packs keep
-- theirs; each player's keeper rests from their own win, never from a loss, and the rest is kept in their save across a
-- rejoin or a server hop; a clock behind the one that set a timer never lengthens it.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Saveable = require(Shared.Data.Saveable)
local WorldConfig = require(Shared.Config.World)
local Grounds = require(Shared.Definitions.Grounds)
local Progress = require(Shared.Rules.Progress)
local Cooldown = require(Shared.Rules.Cooldown)

local NOW = 1_800_000_000

local function fresh(): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	return data
end

return {
	{
		Name = "Cooldown: TR10, the elite is back on the server's own timer, 2 minutes; the packs keep theirs",
		Run = function(t: any)
			t.Equal("the elite's wait: research's seed", Cooldown.Wait("Elite"), 120)
			t.Equal("the keeper's: research's seed", Cooldown.Wait("Keeper"), 300)
			t.Equal("a pack's is still Respawn", Cooldown.Wait("Pack"), WorldConfig.Row.Respawn)
			t.Check("a pack is back sooner than the elite", Cooldown.Wait("Pack") < Cooldown.Wait("Elite"))
			t.Equal("no timer: it's up", Cooldown.Left(nil, NOW, "Elite"), 0)
			t.Equal("50 s from its end", Cooldown.Left(NOW + 50, NOW, "Elite"), 50)
			t.Equal("past its end: up", Cooldown.Left(NOW - 1, NOW, "Elite"), 0)
			t.Equal("a clock behind the one that set it never lengthens it", Cooldown.Left(NOW + 10_000, NOW, "Elite"), 120)
			t.Equal("not a number: up", Cooldown.Left(0 / 0, NOW, "Elite"), 0)
			-- Tuned live: the next fall reads the new wait.
			local back = WorldConfig.Row.Back
			local was = back.Elite
			back.Elite = 30
			t.Equal("tuned live", Cooldown.Wait("Elite"), 30)
			back.Elite = was
		end,
	},
	{
		Name = "Cooldown: TR10, each player's keeper rests 5 minutes from their own win; a loss rests nothing",
		Run = function(t: any)
			local first, second = Grounds.List[1], Grounds.List[2]
			local data = fresh()
			t.Equal("a new player's keeper is up", Progress.Resting(data, first.Id, NOW), 0)
			-- A lost try writes nothing to the save, so it rests nothing: the same fresh save is up.
			local won = Progress.KeeperWon(data, first.Id, NOW)
			t.Equal("the win says when it's back", won.Back, NOW + 300)
			t.Equal("resting from the win", Progress.Resting(data, first.Id, NOW), 300)
			t.Equal("two minutes on", Progress.Resting(data, first.Id, NOW + 120), 180)
			t.Equal("back after five", Progress.Resting(data, first.Id, NOW + 300), 0)
			t.Equal("and stays back", Progress.Resting(data, first.Id, NOW + 301), 0)
			t.Equal("another player's keeper is their own: up", Progress.Resting(fresh(), first.Id, NOW + 10), 0)
			t.Equal("the ground the win opened rests nothing", Progress.Resting(data, second.Id, NOW), 0)
			t.Check("a clock behind never makes it longer", Progress.Resting(data, first.Id, NOW - 1000) <= 300)
			Progress.KeeperWon(data, first.Id, NOW + 400)
			t.Equal("the next win rests it again, from that win", Progress.Resting(data, first.Id, NOW + 400), 300)
			t.Equal("its record keeps both wins", data.Progress.Grounds[first.Id].KeeperWins.Normal, 2)
			t.Equal("an unknown ground rests nothing", Progress.Resting(data, "nowhere", NOW), 0)
		end,
	},
	{
		Name = "Cooldown: TR10, a rejoin or a server hop keeps the keeper's rest",
		Run = function(t: any)
			local first = Grounds.List[1]
			local data = fresh()
			Progress.KeeperWon(data, first.Id, NOW)
			t.Equal("its save stays saveable", #Saveable.Problems(data), 0)
			-- The save as another server loads it: a copy, its migrations run again (none left), a moment later.
			local loaded = Profile.View(data) :: Profile.Data
			Migrations.Run(loaded)
			t.Equal("the rest is in the copy", loaded.Progress.Grounds[first.Id].Back, NOW + 300)
			t.Equal("100 s later on the new server: 200 s left", Progress.Resting(loaded, first.Id, NOW + 100), 200)
			t.Equal("the client reads the same from its copy", Progress.Resting(Profile.View(data), first.Id, NOW + 100), 200)
			t.Equal("a hop past its end: up", Progress.Resting(loaded, first.Id, NOW + 300), 0)
		end,
	},
}
