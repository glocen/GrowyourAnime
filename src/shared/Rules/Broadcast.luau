--!strict
-- Broadcast (shared, pure): what's worth telling of a committed change, to whom, and its words (docs/design.md, "Being
-- seen"; TR57; Config.Broadcast). Only a change that committed and succeeded is read, and never a purchase: ShopBuy
-- isn't one of the labels read, and only a chest's open makes an item's line. Nothing a player typed is carried: a line
-- names a Voidkin by its definition's name, never its nickname. Its only word from outside our definitions is the
-- finder's display name, shown as Roblox gives it (docs/roblox-rules.md, "Text players write"). An every-server message
-- carries ids and numbers, so each client builds the words from its own definitions.
--   Broadcast.Read(label, answer, data)            the news a committed change makes, or nil: one at most, the rarest
--   Broadcast.Climb(kind, floor)                   the Tower's news, "Record" or "Board", at `floor`
--   Broadcast.Record(held, floor, day)             whether a run's `floor` beats this server's best today; keeps it
--   Broadcast.Leads(entries, user, score, floor)   whether a climb posted to the week's board takes its first place
--   Broadcast.Settle(news, share, last, now)       true when it goes to every server; else its Reach falls to "Server"
--   Broadcast.Bundle(lines, job) / Unpack(message) a server's lines in one message, at most Bytes, and back
--   Broadcast.Outbox() / Send(outbox, job, now)    that message at most once every Bundle seconds
--   Broadcast.Size(value)                          a value's length as JSON, counted high
--   Broadcast.Line(news)                           its words as parts, the lit ones in its light, and that rarity
--   Broadcast.Plain(parts) / Rich(parts, hex)      the words plain, or with the lit parts in a colour
--   Broadcast.Fresh(seen, id, now)                 true the first time an id is met (ids kept Stale seconds)
--   Broadcast.Queue() / Hear(queue, news, now, near) / Step(queue, now, covered)   the client's plate
--   Broadcast.Chimes(news, me, others)            whether the plate's fade-in plays its cue (TR57, "The plate's cue")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config.Broadcast)
local VoidkinConfig = require(Shared.Config.Voidkin)
local Profile = require(Shared.Data.Profile)
local Enemies = require(Shared.Definitions.Enemies)
local Grounds = require(Shared.Definitions.Grounds)
local Items = require(Shared.Definitions.Items)
local Rarity = require(Shared.Definitions.Rarity)
local Voidkin = require(Shared.Definitions.Voidkin)

export type News = {
	Id: string, -- the line's own: its server's job and a count, so a line heard twice is shown once
	Kind: string, -- one of Broadcast.Kinds
	Reach: string, -- "All", every server; "Server", this one
	Def: string, -- the item's or the Voidkin's definition, the keeper's ground; "" for the Tower's
	Rarity: string, -- the light its line takes
	Level: number, -- a Reinforce level, the stars, the floor; a keeper's difficulty, 1 Normal and 2 Hard; else 0
	User: number, -- the finder's UserId and display name, set by the finder's server
	Name: string,
}

export type Part = { Text: string, Lit: boolean }
export type Held = { News: News, At: number, Near: boolean }
export type Queue = { Waiting: { Held }, Last: number? }
export type Seen = { [string]: number }
export type Outbox = { Lines: { News }, Sent: number? }

local Broadcast = {}

Broadcast.Kinds = { "Item", "Reinforce", "Stars", "First", "Keeper", "Record", "Board" }
Broadcast.Difficulties = { "Normal", "Hard" }

local VERSION = 1
local NAME_MOST = 80 -- a display name's bytes at most: Roblox's 20 characters, each up to 4 bytes
local DEF_MOST = 40
local JOB_MOST = 64
local NUMBERS = { "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten" }

local function news(kind: string, reach: string, def: string, rarity: string, level: number): News
	return { Id = "", Kind = kind, Reach = reach, Def = def, Rarity = rarity, Level = level, User = 0, Name = "" }
end

local function rank(rarity: string): number
	return Rarity.Rank[rarity] or 0
end

-- The rarest kept item of an open that's worth telling.
local function opened(answer: any, data: Profile.Data): News?
	if type(answer.Items) ~= "table" then
		return nil
	end
	local best: Profile.OwnedItem? = nil
	for _, id in answer.Items do
		local item = if type(id) == "string" then data.Items[id] else nil
		if item and Config.Item[item.Rarity] and (best == nil or rank(item.Rarity) > rank(best.Rarity)) then
			best = item
		end
	end
	if best == nil then
		return nil
	end
	return news("Item", Config.Item[best.Rarity], best.Def, best.Rarity, 0)
end

local function reinforced(answer: any, data: Profile.Data): News?
	local level = answer.Level
	local item = if type(answer.Item) == "string" then data.Items[answer.Item] else nil
	if answer.Success ~= true or type(level) ~= "number" or item == nil then
		return nil
	end
	local reach = if level >= Config.Reinforce.All then "All" elseif level >= Config.Reinforce.Server then "Server" else nil
	return if reach then news("Reinforce", reach, item.Def, item.Rarity, level) else nil
end

local function starred(answer: any, data: Profile.Data): News?
	local owned = if type(answer.Id) == "string" then data.Voidkin[answer.Id] else nil
	local row = if owned then Voidkin.ById[owned.Def] else nil
	if owned == nil or row == nil or answer.Stars ~= VoidkinConfig.MaxStars then
		return nil
	end
	return news("Stars", Config.Stars, row.Id, row.Rarity, answer.Stars)
end

-- A new Voidkin from a shard that's the account's first of its rarity: the save, after the change, holds that one
-- alone (a Voidkin never leaves a collection).
local function first(answer: any, data: Profile.Data): News?
	local row = if answer.Outcome == "New" and type(answer.Def) == "string" then Voidkin.ById[answer.Def] else nil
	local reach = if row then Config.First[row.Rarity] else nil
	if row == nil or reach == nil then
		return nil
	end
	local count = 0
	for _, owned in data.Voidkin do
		local other = Voidkin.ById[owned.Def]
		if other and other.Rarity == row.Rarity then
			count += 1
		end
	end
	return if count == 1 then news("First", reach, row.Id, row.Rarity, 0) else nil
end

local function keeper(answer: any): News?
	local reach = if type(answer.Difficulty) == "string" then Config.Keeper[answer.Difficulty] else nil
	local ground = if type(answer.Ground) == "string" then Grounds.ById[answer.Ground] else nil
	if reach == nil or ground == nil or ground.Keeper == nil or answer.Wins ~= 1 then
		return nil
	end
	local level = table.find(Broadcast.Difficulties, answer.Difficulty) or 0
	return news("Keeper", reach, ground.Id, Config.Light.Keeper, level)
end

local READERS: { [string]: (any, Profile.Data) -> News? } = {
	OpenChests = opened,
	Reinforce = reinforced,
	SpendCopies = starred,
	Open = first, -- a shard opened at the base (Rules.Base.Open)
	KeeperWon = keeper,
}

-- The news a committed change labelled `label` makes, from its answer and the save after it; nil for none.
function Broadcast.Read(label: string, answer: any, data: Profile.Data): News?
	local reader = READERS[label]
	if reader == nil or type(answer) ~= "table" or answer.Ok ~= true then
		return nil
	end
	return reader(answer, data)
end

function Broadcast.Climb(kind: "Record" | "Board", floor: number): News
	local reach = if kind == "Record" then Config.Record.Reach else Config.Board.Reach
	return news(kind, reach, "", Config.Light[kind], floor)
end

-- Whether a run that ended at `floor` on `day` is this server's best today, from Least up; `held` keeps the day's best.
function Broadcast.Record(held: { Day: number, Floor: number }, floor: number, day: number): boolean
	if held.Day ~= day then
		held.Day, held.Floor = day, 0
	end
	local beaten = floor >= Config.Record.Least and floor > held.Floor
	held.Floor = math.max(held.Floor, floor)
	return beaten
end

-- Whether user `user`'s climb at `score` (Rules.Tower.Score), `floor` floors, takes the first place of `entries`, the
-- page read before it was posted: past every other account's, and the account didn't hold it already.
function Broadcast.Leads(entries: { { Id: number, Score: number } }, user: number, score: number, floor: number): boolean
	if floor < Config.Board.Least then
		return false
	end
	local others, own = -math.huge, -math.huge
	for _, entry in entries do
		if entry.Id == user then
			own = math.max(own, entry.Score)
		else
			others = math.max(others, entry.Score)
		end
	end
	return score > others and own <= others
end

-- Every server, or this one: an every-server line goes to every server only if the player shares their finds and told
-- none in the last Every seconds (`last`, their last one's time, nil for none); else it's told to this server, never
-- dropped.
function Broadcast.Settle(item: News, share: boolean, last: number?, now: number): boolean
	if item.Reach ~= "All" then
		return false
	end
	if not share or (last ~= nil and now - last < Config.Every) then
		item.Reach = "Server"
		return false
	end
	return true
end

-- A string's length as JSON, counted high: a byte past ASCII as 3, since an escape writes a character of up to 4 bytes
-- as up to 12.
local function stringSize(text: string): number
	local size = 2
	for index = 1, #text do
		local byte = string.byte(text, index)
		if byte == 34 or byte == 92 then
			size += 2
		elseif byte < 32 then
			size += 6
		elseif byte >= 128 then
			size += 3
		else
			size += 1
		end
	end
	return size
end

function Broadcast.Size(value: any): number
	local kind = type(value)
	if kind == "string" then
		return stringSize(value)
	elseif kind == "number" then
		return if value == math.floor(value) and math.abs(value) < 2 ^ 53 then #string.format("%d", value) else 24
	elseif kind == "boolean" then
		return if value then 4 else 5
	elseif kind == "table" then
		local size, count = 2, 0
		if #value > 0 then
			for _, item in ipairs(value) do
				size += Broadcast.Size(item)
				count += 1
			end
		else
			for key, item in value do
				size += Broadcast.Size(tostring(key)) + 1 + Broadcast.Size(item)
				count += 1
			end
		end
		return size + math.max(0, count - 1)
	end
	return 4 -- null
end

local function packed(item: News, count: number): { any }
	return { table.find(Broadcast.Kinds, item.Kind) or 0, item.Def, item.Rarity, item.Level, item.User, item.Name, count }
end

-- A server's every-server lines waiting (oldest first), as one message from job `job`: as many as fit in Bytes, taken
-- off `lines`; nil when none waits. A line too big alone is dropped, so one never holds the rest.
local function bundle(lines: { News }, job: string): { [string]: any }?
	local message = { V = VERSION, J = job, L = {} :: { any } }
	while #lines > 0 do
		local item = lines[1]
		local count = tonumber(string.match(item.Id, ":(%d+)$")) or 0
		table.insert(message.L, packed(item, count))
		if Broadcast.Size(message) > Config.Bytes then
			table.remove(message.L)
			if #message.L == 0 then
				table.remove(lines, 1)
				continue
			end
			break
		end
		table.remove(lines, 1)
	end
	return if #message.L > 0 then message else nil
end

Broadcast.Bundle = bundle

function Broadcast.Outbox(): Outbox
	return { Lines = {}, Sent = nil }
end

-- The message to publish at `now`, or nil: at most one every Bundle seconds, its lines the oldest waiting that fit.
function Broadcast.Send(outbox: Outbox, job: string, now: number): { [string]: any }?
	if #outbox.Lines == 0 or (outbox.Sent ~= nil and now - outbox.Sent < Config.Bundle) then
		return nil
	end
	local message = bundle(outbox.Lines, job)
	if message then
		outbox.Sent = now
	end
	return message
end

local function whole(value: any, least: number, most: number): boolean
	return type(value) == "number" and value == math.floor(value) and value >= least and value <= most
end

local function text(value: any, least: number, most: number): boolean
	return type(value) == "string" and #value >= least and #value <= most
end

-- Whether `def` names what a line of `kind` reads, so every line it makes has its words.
local function known(kind: string, def: string): boolean
	if kind == "Item" or kind == "Reinforce" then
		return Items.ById[def] ~= nil
	elseif kind == "Stars" or kind == "First" then
		return Voidkin.ById[def] ~= nil
	elseif kind == "Keeper" then
		local ground = Grounds.ById[def]
		return ground ~= nil and ground.Keeper ~= nil and Enemies.ById[ground.Keeper] ~= nil
	end
	return def == ""
end

local function unpackLine(line: any, job: string): News?
	if type(line) ~= "table" then
		return nil
	end
	local kind = Broadcast.Kinds[if whole(line[1], 1, #Broadcast.Kinds) then line[1] else 0]
	local def, rarity, level, user, name, count = line[2], line[3], line[4], line[5], line[6], line[7]
	if kind == nil or not text(def, 0, DEF_MOST) or not known(kind, def) then
		return nil
	end
	if type(rarity) ~= "string" or Rarity.Rank[rarity] == nil or not whole(level, 0, 100000) then
		return nil
	end
	if not whole(user, 1, 2 ^ 53) or not text(name, 1, NAME_MOST) or not whole(count, 0, 2 ^ 53) then
		return nil
	end
	local item = news(kind, "All", def, rarity, level)
	item.Id, item.User, item.Name = `{job}:{count}`, user, name
	return item
end

-- A message another server published, each line checked whole: (its lines, the job it came from). A message that's off
-- gives none; a line that's off is left out.
function Broadcast.Unpack(message: any): ({ News }, string?)
	if type(message) ~= "table" or message.V ~= VERSION or not text(message.J, 0, JOB_MOST) or type(message.L) ~= "table" then
		return {}, nil
	end
	local out = {}
	for _, line in ipairs(message.L) do
		local item = unpackLine(line, message.J)
		if item then
			table.insert(out, item)
		end
	end
	return out, message.J
end

local function article(rarity: string, name: string): string
	if string.sub(name, -1) == "s" then
		return "" -- Gloves, Boots: no article
	end
	return if string.find(rarity, "^[AEIOU]") then "an " else "a "
end

local function itemName(item: News): string
	local row = Items.ById[item.Def]
	return if row then row.Name else item.Def
end

local function voidkinName(item: News): string
	local row = Voidkin.ById[item.Def]
	return if row then row.Name else item.Def
end

local function part(textOf: string, lit: boolean?): Part
	return { Text = textOf, Lit = lit == true }
end

-- The line's words (docs/design.md, "Being seen", "The words"), the rarity and the item, or the Voidkin's name, lit; and
-- the rarity whose light it takes.
function Broadcast.Line(item: News): ({ Part }, string)
	local who = item.Name
	local kind = item.Kind
	local parts: { Part }
	if kind == "Item" then
		local name = itemName(item)
		parts = { part(`{who} found {article(item.Rarity, name)}`), part(`{item.Rarity} {name}`, true) }
	elseif kind == "Reinforce" then
		parts = { part(`{who}'s `), part(itemName(item), true), part(` reached +{item.Level}`) }
	elseif kind == "Stars" then
		parts = { part(`{who}'s `), part(voidkinName(item), true), part(` reached {NUMBERS[item.Level] or tostring(item.Level)} stars`) }
	elseif kind == "First" then
		parts = { part(`{who} found `), part(voidkinName(item), true), part(" in a shard") }
	elseif kind == "Keeper" then
		local ground = Grounds.ById[item.Def]
		local foe = if ground and ground.Keeper then Enemies.ById[ground.Keeper] else nil
		local difficulty = Broadcast.Difficulties[item.Level] or "Normal"
		parts = { part(`{who} beat {if foe then foe.Name else "a keeper"} on {difficulty}`) }
	elseif kind == "Record" then
		parts = { part(`{who} reached Tower floor {item.Level}`) } -- it shows only when it's the server's best today (TR67)
	else
		parts = { part(`{who} took first place in the Tower this week: floor {item.Level}`) }
	end
	return parts, item.Rarity
end

function Broadcast.Plain(parts: { Part }): string
	local out = {}
	for _, each in parts do
		table.insert(out, each.Text)
	end
	return table.concat(out)
end

local function escape(words: string): string
	return (words:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub("\"", "&quot;"):gsub("'", "&apos;"))
end

-- The words as rich text, every part escaped (a display name may hold "<"), the lit ones in `hex` ("RRGGBB").
function Broadcast.Rich(parts: { Part }, hex: string): string
	local out = {}
	for _, each in parts do
		local safe = escape(each.Text)
		table.insert(out, if each.Lit then `<font color="#{hex}">{safe}</font>` else safe)
	end
	return table.concat(out)
end

-- True the first time `id` is met; ids are kept Stale seconds, and older ones forgotten.
function Broadcast.Fresh(seen: Seen, id: string, now: number): boolean
	for key, at in seen do
		if now - at > Config.Plate.Stale then
			seen[key] = nil
		end
	end
	if seen[id] ~= nil then
		return false
	end
	seen[id] = now
	return true
end

function Broadcast.Queue(): Queue
	return { Waiting = {}, Last = nil }
end

-- A line arrives at `now`; `near`, this server's or a friend's. It waits for the plate ("Wait"), or, an every-server line
-- from a stranger past the cap (a plate shown inside Gap, or a line already waiting), goes to the chat only ("Chat").
function Broadcast.Hear(queue: Queue, item: News, now: number, near: boolean): string
	local capped = #queue.Waiting > 0 or (queue.Last ~= nil and now - queue.Last < Config.Plate.Gap)
	if not near and capped then
		return "Chat"
	end
	table.insert(queue.Waiting, { News = item, At = now, Near = near })
	return "Wait"
end

-- At `now`: the line the plate shows now, or nil; and the lines that waited past Stale, for the chat only. Nothing shows
-- while `covered` (a fight's card, a keeper's ring, a reveal or a screen), inside Gap of the last, and the near lines
-- go first, each kind oldest first.
function Broadcast.Step(queue: Queue, now: number, covered: boolean): (News?, { News })
	local stale = {}
	for index = #queue.Waiting, 1, -1 do
		local held = queue.Waiting[index]
		if now - held.At > Config.Plate.Stale then
			table.insert(stale, 1, held.News)
			table.remove(queue.Waiting, index)
		end
	end
	if covered or #queue.Waiting == 0 or (queue.Last ~= nil and now - queue.Last < Config.Plate.Gap) then
		return nil, stale
	end
	local pick = 1
	for index, held in queue.Waiting do
		if held.Near then
			pick = index
			break
		end
	end
	local held = table.remove(queue.Waiting, pick) :: Held
	queue.Last = now
	return held.News, stale
end

-- The plate's cue (TR57, "The plate's cue"; Config.Cues' BroadcastPlate): someone else's find, as it fades in, while the
-- player shows others' finds (`others`). A line of the player's own (`me`) stays silent: their find already sounded, its
-- drop and its reveal. A chat-only line never reaches the plate, so never asks.
function Broadcast.Chimes(item: News, me: number, others: boolean): boolean
	return others and item.User ~= me
end

return Broadcast
