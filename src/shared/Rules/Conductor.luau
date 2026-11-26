--!strict
-- Conductor (pure): the order notices show in, through one door (TR71 A; docs/research/cloud-2026-11-24/orchestration.md,
-- 5c; Config.Conductor). The HUD calls Add for every notice and asks Next each frame; this module never draws.
--   Conductor.Item(kind, key, now, extra?)   a notice of `kind` (Config.Conductor.Kinds) about `key` ("Credits", a shard's
--                                            id): extra may set Count, Rarity (a rank, higher first) and Payload
--   Conductor.Add(queue, item)               queued, or merged into a waiting notice or one shown inside Merge seconds
--                                            of the same kind about the same thing (it counts up); returns the notice it
--                                            landed in and whether it merged
--   Conductor.Before(a, b)                   the order: the higher band first, then about the fight, then rarity, then
--                                            arrival
--   Conductor.Next(queue, state, now)        the next to show and how ("Line", or "Chip": an icon chip with no words, a
--                                            band 3 notice not about the fight, in a fight; its line waits for the
--                                            fight's end), or nil; drops what has waited too long first
--   Conductor.Dropped(queue, now)            takes out the band 1 and 2 notices waiting over Drop seconds; returns them
-- A State: InFight; Covered (a reveal, the travel card or a run's card is up: nothing shows); Centre (a band 5 or 6
-- notice is up: the lanes wait); Shown (lane to the notices it shows now); Last (lane to os time it last showed one).

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config.Conductor)

local Conductor = {}

export type Item = {
	Kind: string,
	Key: string,
	Count: number,
	Band: number,
	Lane: string,
	Fight: boolean,
	Merge: boolean,
	Rarity: number,
	At: number, -- when it arrived
	ShownAt: number?, -- when its line showed; nil while it waits
	Chipped: boolean?, -- shown as a chip in a fight, its line still to come
	Payload: any,
}

export type State = {
	InFight: boolean,
	Covered: boolean,
	Centre: boolean,
	Shown: { [string]: number },
	Last: { [string]: number },
}

export type Shown = { Item: Item, As: "Line" | "Chip" }

function Conductor.Item(kind: string, key: string, now: number, extra: { Count: number?, Rarity: number?, Payload: any? }?): Item
	local row = Config.Kinds[kind]
	assert(row ~= nil, `no conductor kind {kind}`)
	return {
		Kind = kind,
		Key = key,
		Count = if extra and extra.Count then extra.Count else 1,
		Band = row.Band,
		Lane = row.Lane,
		Fight = row.Fight,
		Merge = row.Merge,
		Rarity = if extra and extra.Rarity then extra.Rarity else 0,
		At = now,
		Payload = if extra then extra.Payload else nil,
	}
end

function Conductor.Add(queue: { Item }, item: Item): (Item, boolean)
	if item.Merge then
		for _, other in queue do
			local since = if other.ShownAt then item.At - other.ShownAt else 0 -- a waiting notice takes every one that comes
			if other.Kind == item.Kind and other.Key == item.Key and since <= Config.Merge then
				other.Count += item.Count
				other.Payload = if item.Payload ~= nil then item.Payload else other.Payload
				return other, true
			end
		end
	end
	table.insert(queue, item)
	return item, false
end

function Conductor.Before(a: Item, b: Item): boolean
	if a.Band ~= b.Band then
		return a.Band > b.Band
	end
	if a.Fight ~= b.Fight then
		return a.Fight
	end
	if a.Rarity ~= b.Rarity then
		return a.Rarity > b.Rarity
	end
	return a.At < b.At
end

function Conductor.Dropped(queue: { Item }, now: number): { Item }
	local dropped: { Item } = {}
	for index = #queue, 1, -1 do
		local item = queue[index]
		if item.ShownAt == nil and item.Band <= 2 and now - item.At > Config.Drop then
			table.insert(dropped, 1, table.remove(queue, index) :: Item)
		end
	end
	return dropped
end

-- The notices shown long enough ago that nothing more merges into them leave the queue.
local function settle(queue: { Item }, now: number)
	for index = #queue, 1, -1 do
		local shownAt = queue[index].ShownAt
		if shownAt and now - shownAt > Config.Merge then
			table.remove(queue, index)
		end
	end
end

function Conductor.Next(queue: { Item }, state: State, now: number): Shown?
	settle(queue, now)
	Conductor.Dropped(queue, now)
	if state.Covered then
		return nil
	end
	local waiting: { Item } = {}
	for _, item in queue do
		if item.ShownAt == nil then
			table.insert(waiting, item)
		end
	end
	table.sort(waiting, Conductor.Before)
	local caps = Config.Caps[if state.InFight then "Fight" else "Calm"]
	for _, item in waiting do
		local lane = item.Lane
		if state.Centre and lane ~= "Centre" then
			continue -- a payoff holds the centre: the lanes wait for it
		end
		if (state.Shown[lane] or 0) >= (caps[lane] or 1) then
			continue
		end
		if now - (state.Last[lane] or -math.huge) < Config.Gap then
			continue
		end
		if state.InFight and item.Band == 3 and not item.Fight then
			if item.Chipped then
				continue -- its line waits for the fight's end
			end
			item.Chipped = true
			return { Item = item, As = "Chip" }
		end
		item.ShownAt = now
		return { Item = item, As = "Line" }
	end
	return nil
end

return Conductor
