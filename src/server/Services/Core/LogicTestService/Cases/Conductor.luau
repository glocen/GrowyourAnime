--!strict
-- Conductor cases (pure): the order notices show in, through one door (TR71 A; Rules.Conductor, Config.Conductor;
-- docs/research/cloud-2026-11-24/orchestration.md, 5c). Same frame, merge, fight gating, defer and drop.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Conductor = require(Shared.Rules.Conductor)
local Config = require(Shared.Config.Conductor)

local function calm(): Conductor.State
	return { InFight = false, Covered = false, Centre = false, Shown = {}, Last = {} }
end

local function fighting(): Conductor.State
	local state = calm()
	state.InFight = true
	return state
end

-- Shows what the conductor gives one at a time, each lane's notice taken down at once, its time Gap apart.
local function drain(queue: { Conductor.Item }, state: Conductor.State, from: number): { string }
	local order: { string } = {}
	local now = from
	for _ = 1, 40 do
		local shown = Conductor.Next(queue, state, now)
		if shown then
			table.insert(order, `{shown.Item.Kind}:{shown.Item.Key}{if shown.As == "Chip" then "(chip)" else ""}`)
			state.Last[shown.Item.Lane] = now
		end
		now += Config.Gap
	end
	return order
end

return {
	{
		Name = "Conductor (TR71 A): same frame, the higher band first, then about the fight, then rarity, then arrival; each lane its Gap apart",
		Run = function(t: any)
			local queue: { Conductor.Item } = {}
			Conductor.Add(queue, Conductor.Item("Credits", "Credits", 0, { Count = 40 }))
			Conductor.Add(queue, Conductor.Item("GoalDone", "goal-1", 0))
			Conductor.Add(queue, Conductor.Item("Drop", "sword", 0, { Rarity = 3 }))
			Conductor.Add(queue, Conductor.Item("Drop", "ring", 0, { Rarity = 4 }))
			Conductor.Add(queue, Conductor.Item("KeeperFall", "lamplighter", 0))
			local sorted = table.clone(queue)
			table.sort(sorted, Conductor.Before)
			local kinds: { string } = {}
			for _, item in sorted do
				table.insert(kinds, `{item.Kind}:{item.Key}`)
			end
			t.Equal("the band, then the fight, then rarity", table.concat(kinds, ","), "KeeperFall:lamplighter,Drop:ring,Drop:sword,GoalDone:goal-1,Credits:Credits")
			local a, b = Conductor.Item("Drop", "a", 1), Conductor.Item("Drop", "b", 2)
			t.Check("and then arrival", Conductor.Before(a, b) and not Conductor.Before(b, a))
			local order = drain(queue, calm(), 0)
			t.Equal("all shown, the centre first and each in its lane", table.concat(order, ","), "KeeperFall:lamplighter,Drop:ring,Drop:sword,GoalDone:goal-1,Credits:Credits")
			-- each lane waits its Gap
			local lane: { Conductor.Item } = {}
			Conductor.Add(lane, Conductor.Item("GoalDone", "g1", 0))
			Conductor.Add(lane, Conductor.Item("GoalDone", "g2", 0))
			local state = calm()
			local first = Conductor.Next(lane, state, 0)
			state.Last.Rewards = 0
			t.Check("the first shows", first ~= nil and first.Item.Key == "g1")
			t.Check("the second waits its Gap", Conductor.Next(lane, state, Config.Gap / 2) == nil)
			local second = Conductor.Next(lane, state, Config.Gap)
			t.Check("then shows", second ~= nil and second.Item.Key == "g2")
		end,
	},
	{
		Name = "Conductor (TR71 A): the same kind about the same thing inside Merge seconds counts up in one line; another thing, or later, is its own",
		Run = function(t: any)
			local queue: { Conductor.Item } = {}
			local one = Conductor.Add(queue, Conductor.Item("Credits", "Credits", 0, { Count = 40 }))
			local into, merged = Conductor.Add(queue, Conductor.Item("Credits", "Credits", 0.4, { Count = 25 }))
			t.Check("merged while it waits", merged and into == one and one.Count == 65 and #queue == 1, `{one.Count}`)
			local state = calm()
			local shown = Conductor.Next(queue, state, 0.5)
			t.Check("shown once, with the sum", shown ~= nil and shown.Item.Count == 65)
			local _, again = Conductor.Add(queue, Conductor.Item("Credits", "Credits", 0.5 + Config.Merge - 0.1, { Count = 10 }))
			t.Check("merged into the line it shows, inside Merge", again and one.Count == 75)
			local _, late = Conductor.Add(queue, Conductor.Item("Credits", "Credits", 0.5 + Config.Merge + 0.1, { Count = 10 }))
			t.Check("past Merge: its own line", not late)
			local _, other = Conductor.Add(queue, Conductor.Item("Shard", "watt", 0.6))
			local _, otherKey = Conductor.Add(queue, Conductor.Item("Shard", "ember", 0.6))
			t.Check("another thing of a merging kind: its own", not other and not otherKey)
			local _, never = Conductor.Add(queue, Conductor.Item("GoalDone", "g", 0.6))
			local _, neverTwice = Conductor.Add(queue, Conductor.Item("GoalDone", "g", 0.7))
			t.Check("a kind that doesn't merge never does", not never and not neverTwice)
		end,
	},
	{
		Name = "Conductor (TR71 A): in a fight, one per lane; a band 3 notice not about the fight shows as a chip and its line waits for the fight's end; a fight's own shows its line",
		Run = function(t: any)
			local queue: { Conductor.Item } = {}
			Conductor.Add(queue, Conductor.Item("GoalDone", "goal-1", 0))
			Conductor.Add(queue, Conductor.Item("Drop", "sword", 0, { Rarity = 3 }))
			local state = fighting()
			local first = Conductor.Next(queue, state, 0)
			t.Check("the fight's own first, as its line", first ~= nil and first.Item.Kind == "Drop" and first.As == "Line")
			state.Last.Rewards, state.Shown.Rewards = 0, 1
			t.Check("one per lane in a fight", Conductor.Next(queue, state, 1) == nil)
			state.Shown.Rewards = 0
			local chip = Conductor.Next(queue, state, 1)
			t.Check("the goal: a chip, no line", chip ~= nil and chip.Item.Kind == "GoalDone" and chip.As == "Chip" and chip.Item.ShownAt == nil)
			state.Last.Rewards = 1
			t.Check("and no second chip while the fight lasts", Conductor.Next(queue, state, 2) == nil)
			state.InFight = false
			local line = Conductor.Next(queue, state, 30)
			t.Check("the fight over: its line plays", line ~= nil and line.Item.Kind == "GoalDone" and line.As == "Line")
			-- out of a fight, two at once in the rewards lane
			local calmQueue: { Conductor.Item } = {}
			Conductor.Add(calmQueue, Conductor.Item("GoalDone", "a", 0))
			Conductor.Add(calmQueue, Conductor.Item("GoalDone", "b", 0))
			local quiet = calm()
			quiet.Shown.Rewards = 1
			t.Check("out of a fight, a second beside the first", Conductor.Next(calmQueue, quiet, 1) ~= nil)
			quiet.Shown.Rewards = 2
			t.Check("and no third", Conductor.Next(calmQueue, quiet, 2) == nil)
		end,
	},
	{
		Name = "Conductor (TR71 A): defer: nothing shows over a reveal or a card; a payoff holds the centre and the lanes wait; band 1 and 2 waiting past Drop are dropped, band 3 never",
		Run = function(t: any)
			local queue: { Conductor.Item } = {}
			Conductor.Add(queue, Conductor.Item("Credits", "Credits", 0, { Count = 40 }))
			Conductor.Add(queue, Conductor.Item("Shard", "watt", 0))
			Conductor.Add(queue, Conductor.Item("GoalDone", "goal-1", 0))
			local state = calm()
			state.Covered = true
			t.Check("covered: nothing", Conductor.Next(queue, state, 1) == nil and #queue == 3)
			state.Covered = false
			state.Centre = true
			Conductor.Add(queue, Conductor.Item("Record", "tower", 1))
			local centre = Conductor.Next(queue, state, 1)
			t.Check("a payoff up: only the centre", centre ~= nil and centre.Item.Kind == "Record")
			state.Last.Centre = 1
			t.Check("the lanes wait for it", Conductor.Next(queue, state, 2) == nil)
			local dropped = Conductor.Dropped(queue, Config.Drop + 0.5)
			local names: { string } = {}
			for _, item in dropped do
				table.insert(names, item.Kind)
			end
			t.Equal("past Drop: the Credits and the shard dropped", table.concat(names, ","), "Credits,Shard")
			local left = 0
			for _, item in queue do
				if item.Kind == "GoalDone" then
					left += 1
				end
			end
			t.Check("the goal kept", left == 1)
			state.Centre = false
			local after = Conductor.Next(queue, state, Config.Drop + 60)
			t.Check("the centre gone: the goal shows, however late", after ~= nil and after.Item.Kind == "GoalDone")
		end,
	},
	{
		Name = "Conductor (TR71 A): every kind has a band 0 to 6, a lane of three, and only bands 4 and up in the centre",
		Run = function(t: any)
			local bad: { string } = {}
			for kind, row in Config.Kinds do
				local lane = row.Lane == "Lead" or row.Lane == "Rewards" or row.Lane == "Centre"
				if row.Band < 0 or row.Band > 6 or not lane or (row.Lane == "Centre") ~= (row.Band >= 4) then
					table.insert(bad, kind)
				end
			end
			t.Equal("none off the ladder", table.concat(bad, ","), "")
			for _, caps in Config.Caps do
				t.Check("every lane has a cap", caps.Lead ~= nil and caps.Rewards ~= nil and caps.Centre ~= nil)
			end
		end,
	},
}
