--!strict
-- Music (pure): which of Config.Music's places is playing for where the player is, and which of its tracks comes next.
-- The client's MusicController plays what this says. No Roblox API: its cases run with Studio closed.
--   Music.Place({ Try, Tower, Row, Plot }) -> the place's name, the first that holds: a keeper's try, a Tower run,
--                                            Lantern Row (north of the Festival Gate), the player's own plot, the Strip
--   Music.Id(pasted) -> number?           a pasted id as a number: 123, "123" and "rbxassetid://123" all read 123
--   Music.Next(ids, last, roll) -> index? the next track: any of the others than `last`, by `roll(n)` (1 to n)
--   Music.Holds(ids, id) -> index?        where a list holds a playing track, so a change of place that shares it plays on

local Music = {}

export type Where = { Try: boolean, Tower: boolean, Row: boolean, Plot: boolean }

function Music.Place(where: Where): string
	if where.Try then
		return "Keeper"
	elseif where.Tower then
		return "Tower"
	elseif where.Row then
		return "LanternRow"
	elseif where.Plot then
		return "Base"
	end
	return "Strip"
end

function Music.Id(pasted: any): number?
	local id = if type(pasted) == "number" then pasted elseif type(pasted) == "string" then tonumber(string.match(pasted, "(%d+)%s*$") or "") else nil
	return if id and id > 0 and id == math.floor(id) then id else nil
end

-- The index of the track to play after `last` (0 before the first): one of the list's playable ones other than `last`,
-- so no track plays twice running while there's another; the only one again when it's alone; nil for none.
function Music.Next(ids: { any }, last: number, roll: (count: number) -> number): number?
	local others: { number } = {}
	local playable = 0
	for index, pasted in ids do
		if Music.Id(pasted) then
			playable += 1
			if index ~= last then
				table.insert(others, index)
			end
		end
	end
	if playable == 0 then
		return nil
	elseif #others == 0 then
		return last
	end
	return others[math.clamp(roll(#others), 1, #others)]
end

-- The index at which a list holds the track `id` (any way it was pasted), or nil: a change of place whose list holds
-- the track already playing keeps it, so a walk between two places that share their music never starts it over.
function Music.Holds(ids: { any }, id: number?): number?
	if id == nil then
		return nil
	end
	for index, pasted in ids do
		if Music.Id(pasted) == id then
			return index
		end
	end
	return nil
end

return Music
