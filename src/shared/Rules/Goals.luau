--!strict
-- Goals (pure): today's three, their bank and their claims, the account's Next, and a stretch's dare (docs/design.md,
-- "Goals"; docs/test-requests.md, TR54). The rows and their words are Definitions.Goals; the numbers Config.Goals.
-- GoalService keeps the state in the save and feeds it the game's events. No Roblox API: its cases run with Studio closed.
--   Goals.DayOf(seconds) -> number                      the UTC day a moment falls in (0 is 1970-01-01), whatever the server
--   Goals.Pick(seed, day, salt, count) -> number        a fixed draw from 1 to count: the same player, day and list give it
--   Goals.Draw(rows, lists, seed, day, open) -> { string }  a day's three, one from each of `lists` in order, from the
--                                                       rows whose Opens the account has
--   Goals.Roll(state, today, bank, draw) -> boolean     the days brought up to today: older than the bank dropped, each
--                                                       missing day inside it drawn (so nine at most), a new account's
--                                                       from today; true when changed
--   Goals.Credit(state, byId, event, amount) -> { Spot } every open goal on that event moved on; the spots it finished
--   Goals.Note(data, event, amount?)                    the save's goals moved on by one of the game's events, where it
--                                                       happens (a rule's own step, so every path counts it); nil-safe
--   Goals.Claim(state, byId, day, slot) -> (boolean, string?)  a finished goal taken once; else false and why
--   Goals.Take(data, args, reward) -> Answer            the "GoalClaim" action { Day, Slot }: the goal claimed and its
--                                                       shard paid, in one step (behind the op ledger, Transaction.Run)
--   Goals.PayDare(data, grade, count)                   a kept dare's stones into the bag, and today's "keep a dare"
--   Goals.Waits(state, byId) -> number                  the goals finished and not yet claimed, every day's
--   Goals.Led(state, today, id) -> boolean              a lead counted for the day: true when it hadn't led yet today
--   Goals.Next(steps, facts) -> number                  the first step not done; a step with no Fact is the last line
--   Goals.Dare(dares, fallback, stage, ready) -> Dare    a stretch's dare: its own once its piece is in, else the fallback
--   Goals.DareStep(dare, state, event, value?) -> boolean  an event on a running dare; true when its look changed
--   Goals.DareKept(dare, state) -> boolean               kept, judged as its stretch clears
--   Goals.DareLook(dare, state) -> "Holds" | "Broken"    its mark while the stretch runs

local Shared = game:GetService("ReplicatedStorage").Shared
local Defs = require(Shared.Definitions.Goals)

local Goals = {}

export type Row = {
	Id: string,
	List: string, -- "Fight", "Base" or "Roster"
	Text: string,
	Event: string, -- what moves it on (GoalService's events)
	Need: number, -- how much of the event finishes it
	Opens: string?, -- an account fact it needs before it's drawn (Goals.Draw's `open`); nil: always
}
export type Day = { Day: number, Picks: { string }, Have: { number }, Claimed: { boolean } }
export type State = { Days: { Day }, Led: { Day: number, Ids: { string } } }
export type Spot = { Day: number, Slot: number }
export type Step = { Text: string, Opens: string?, Fact: string?, AtLeast: number? }
export type Dare = {
	Id: string,
	Text: string,
	-- "Above": its lead's health share at the clear over Share (its mark follows it); "Do": its Event at least once;
	-- "Avoid": never its Event
	Kind: string,
	Event: string,
	Share: number?,
	Needs: string?, -- the piece it needs in the game (Config.Goals.Ready); nil: always
}
export type DareState = { Broken: boolean, Done: boolean }

local DAY = 86400
local FNV_OFFSET = 2166136261

function Goals.DayOf(seconds: number): number
	return math.floor(seconds / DAY)
end

-- FNV-1a over the key's bytes, its multiply split so no step passes a double's exact integers (16777619 = 2^24 + 403).
function Goals.Pick(seed: number, day: number, salt: string, count: number): number
	local key = `{math.floor(seed)}:{math.floor(day)}:{salt}`
	local h = FNV_OFFSET
	for i = 1, #key do
		h = bit32.bxor(h, string.byte(key, i))
		h = (h * 403 + bit32.lshift(h, 24)) % 4294967296
	end
	return h % math.max(1, count) + 1
end

function Goals.Draw(rows: { Row }, lists: { string }, seed: number, day: number, open: { [string]: boolean }): { string }
	local picks = {}
	for _, list in lists do
		local pool = {}
		for _, row in rows do
			if row.List == list and (row.Opens == nil or open[row.Opens] == true) then
				table.insert(pool, row.Id)
			end
		end
		if #pool > 0 then
			table.insert(picks, pool[Goals.Pick(seed, day, list, #pool)])
		end
	end
	return picks
end

function Goals.Roll(state: State, today: number, bank: number, draw: (day: number) -> { string }): boolean
	local changed = false
	local first = today - (bank - 1)
	-- the oldest first; a day past the bank leaves, claimed or not
	local kept = {}
	for _, d in state.Days do
		if d.Day >= first then
			table.insert(kept, d)
		else
			changed = true
		end
	end
	-- a new account starts today; one that has played banks the days it missed
	local newest = if #kept > 0 then kept[#kept].Day elseif #state.Days == 0 then today - 1 else first - 1
	for day = math.max(newest + 1, first), today do
		local picks = draw(day)
		local have, claimed = {}, {}
		for i = 1, #picks do
			have[i] = 0
			claimed[i] = false
		end
		table.insert(kept, { Day = day, Picks = picks, Have = have, Claimed = claimed })
		changed = true
	end
	state.Days = kept
	return changed
end

function Goals.Credit(state: State, byId: { [string]: Row }, event: string, amount: number): { Spot }
	local finished = {}
	for _, d in state.Days do
		for slot, id in d.Picks do
			local row = byId[id]
			if row and row.Event == event and not d.Claimed[slot] and d.Have[slot] < row.Need then
				d.Have[slot] = math.min(row.Need, d.Have[slot] + amount)
				if d.Have[slot] >= row.Need then
					table.insert(finished, { Day = d.Day, Slot = slot })
				end
			end
		end
	end
	return finished
end

function Goals.Note(data: any, event: string, amount: number?)
	local state = if type(data) == "table" then data.Goals else nil
	if type(state) == "table" and type(state.Days) == "table" and (amount == nil or amount > 0) then
		Goals.Credit(state, Defs.ById, event, amount or 1)
	end
end

function Goals.Claim(state: State, byId: { [string]: Row }, day: number, slot: number): (boolean, string?)
	for _, d in state.Days do
		if d.Day == day then
			local row = byId[d.Picks[slot] or ""]
			if row == nil then
				return false, "NoGoal"
			elseif d.Claimed[slot] then
				return false, "Claimed"
			elseif d.Have[slot] < row.Need then
				return false, "NotDone"
			end
			d.Claimed[slot] = true
			return true, nil
		end
	end
	return false, "NoDay"
end

function Goals.Take(data: any, args: any, reward: { Shard: string, Count: number }): { [string]: any }
	local day = if type(args) == "table" then args.Day else nil
	local slot = if type(args) == "table" then args.Slot else nil
	if type(day) ~= "number" or type(slot) ~= "number" then
		return { Ok = false, Error = "NoGoal" }
	end
	local ok, why = Goals.Claim(data.Goals, Defs.ById, day, slot)
	if not ok then
		return { Ok = false, Error = why }
	end
	local shards = data.Bag.Shards
	shards[reward.Shard] = (shards[reward.Shard] or 0) + reward.Count
	return { Ok = true, Day = day, Slot = slot, Shard = reward.Shard, Count = reward.Count }
end

function Goals.PayDare(data: any, grade: string, count: number)
	local stones = data.Bag.Stones
	stones[grade] = (stones[grade] or 0) + count
	Goals.Note(data, "DareKept")
end

function Goals.Waits(state: State, byId: { [string]: Row }): number
	local n = 0
	for _, d in state.Days do
		for slot, id in d.Picks do
			local row = byId[id]
			if row and not d.Claimed[slot] and d.Have[slot] >= row.Need then
				n += 1
			end
		end
	end
	return n
end

function Goals.Led(state: State, today: number, id: string): boolean
	if state.Led.Day ~= today then
		state.Led = { Day = today, Ids = {} }
	end
	if table.find(state.Led.Ids, id) then
		return false
	end
	table.insert(state.Led.Ids, id)
	return true
end

function Goals.Next(steps: { Step }, facts: { [string]: any }): number
	for i, step in steps do
		if step.Fact == nil then
			return i -- the last line: nothing left to do
		end
		local have = facts[step.Fact]
		local done = if step.AtLeast then type(have) == "number" and have >= step.AtLeast else have == true
		if not done then
			return i
		end
	end
	return #steps + 1
end

function Goals.Dare(dares: { Dare }, fallback: Dare, stage: number, ready: { [string]: boolean }): Dare
	local dare = dares[stage]
	if dare and (dare.Needs == nil or ready[dare.Needs] == true) then
		return dare
	end
	return fallback
end

function Goals.DareStep(dare: Dare, state: DareState, event: string, value: number?): boolean
	if event ~= dare.Event then
		return false
	end
	local was = Goals.DareLook(dare, state)
	if dare.Kind == "Above" then
		state.Broken = (value or 0) <= (dare.Share or 0)
	elseif dare.Kind == "Do" then
		state.Done = true
	elseif dare.Kind == "Avoid" then
		state.Broken = true
	end
	return Goals.DareLook(dare, state) ~= was
end

function Goals.DareKept(dare: Dare, state: DareState): boolean
	if dare.Kind == "Do" then
		return state.Done
	end
	return not state.Broken
end

function Goals.DareLook(_dare: Dare, state: DareState): string
	return if state.Broken then "Broken" else "Holds"
end

return Goals
