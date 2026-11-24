--!strict
-- Broadcast (shared, pure): what's worth telling of a committed change, to whom, and its line (docs/research/
-- cloud-2026-11-24/launch-design.md, section 6, on the director's "ok" of 2026-11-24; Config.Broadcast). Only a
-- committed change that succeeded is read, and never a purchase: ShopBuy isn't one of the labels read. Nothing a player
-- typed is carried: a line names a Voidkin by its own name, never its nickname, and its only word from a player is the
-- finder's display name, which Roblox moderates. Every-server messages carry ids and numbers, so each client builds the
-- words from its own definitions.
--   Broadcast.Read(label, answer, data)            the news a committed change makes, or nil: one at most, the rarest
--   Broadcast.Climb(kind, floor)                   the Tower's news, "Record" or "Board", at `floor`
--   Broadcast.Record(best, floor)                  whether a run that ended at `floor` beats this server's `best`
--   Broadcast.Leads(entries, user, score, floor)   whether a climb posted to the week's board takes its first place
--   Broadcast.Settle(news, share, last, now)       every server, or this one only: true when it goes to every server
--   Broadcast.Pack(news, job) / Unpack(message)    the every-server message, and back: (news, job) or nil
--   Broadcast.Line(news)                           its words, plain, and the rarity whose light they take
--   Broadcast.Escape(text)                         the words made safe for rich text
--   Broadcast.Gate() / Wait(gate, news) / Release(gate, now)   at most Most lines shown a Window
--   Broadcast.Push(list, item, most)               a list held to `most`, its oldest dropped first

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
	Kind: string, -- one of Broadcast.Kinds
	Reach: string, -- "All", every server; "Server", this one
	Def: string, -- the item's or the Voidkin's definition, the keeper's ground; "" for the Tower's
	Rarity: string, -- the light its line takes
	Design: number, -- an item's design (Profile.OwnedItem.Design); 0 for the rest
	Level: number, -- a Reinforce level, the stars, the floor; a keeper's difficulty, 1 Normal and 2 Hard; else 0
	User: number, -- the finder's UserId, and their display name: set by the server
	Name: string,
}

export type Gate = { Shown: { number }, Waiting: { News } }

local Broadcast = {}

Broadcast.Kinds = { "Item", "Reinforce", "Stars", "First", "Keeper", "Record", "Board" }
Broadcast.Difficulties = { "Normal", "Hard" }

local VERSION = 1
local NAME_MOST = 32 -- a display name's characters at most (Roblox's are 20)
local DEF_MOST = 64
local JOB_MOST = 64

local function news(kind: string, reach: string, def: string, rarity: string, design: number, level: number): News
	return { Kind = kind, Reach = reach, Def = def, Rarity = rarity, Design = design, Level = level, User = 0, Name = "" }
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
	return news("Item", Config.Item[best.Rarity], best.Def, best.Rarity, best.Design, 0)
end

local function reinforced(answer: any, data: Profile.Data): News?
	local level = answer.Level
	local item = if type(answer.Item) == "string" then data.Items[answer.Item] else nil
	if answer.Success ~= true or type(level) ~= "number" or item == nil then
		return nil
	end
	local reach = if level >= Config.Reinforce.All then "All" elseif level >= Config.Reinforce.Server then "Server" else nil
	return if reach then news("Reinforce", reach, item.Def, item.Rarity, item.Design, level) else nil
end

local function starred(answer: any, data: Profile.Data): News?
	local owned = if type(answer.Id) == "string" then data.Voidkin[answer.Id] else nil
	local row = if owned then Voidkin.ById[owned.Def] else nil
	if owned == nil or row == nil or answer.Stars ~= VoidkinConfig.MaxStars then
		return nil
	end
	return news("Stars", Config.Stars, row.Id, row.Rarity, 0, answer.Stars)
end

-- A new Voidkin that's the account's first of its rarity: the save, after the change, holds that one alone.
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
	return if count == 1 then news("First", reach, row.Id, row.Rarity, 0, 0) else nil
end

local function keeper(answer: any): News?
	local reach = if type(answer.Difficulty) == "string" then Config.Keeper[answer.Difficulty] else nil
	local ground = if type(answer.Ground) == "string" then Grounds.ById[answer.Ground] else nil
	if reach == nil or ground == nil or ground.Keeper == nil or answer.Wins ~= 1 then
		return nil
	end
	local level = table.find(Broadcast.Difficulties, answer.Difficulty) or 0
	return news("Keeper", reach, ground.Id, Config.Light.Keeper, 0, level)
end

local READERS: { [string]: (any, Profile.Data) -> News? } = {
	OpenChests = opened,
	Reinforce = reinforced,
	SpendCopies = starred,
	Open = first,
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
	return news(kind, reach, "", Config.Light[kind], 0, floor)
end

function Broadcast.Record(best: number, floor: number): boolean
	return floor >= Config.Record.Least and floor > best
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
-- none in the last Every seconds (`last`, their last one's time, nil for none); else to this server only.
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

function Broadcast.Pack(item: News, job: string): { [string]: any }
	return { V = VERSION, K = item.Kind, D = item.Def, R = item.Rarity, G = item.Design, L = item.Level, U = item.User, N = item.Name, J = job }
end

local function whole(value: any, least: number, most: number): boolean
	return type(value) == "number" and value == math.floor(value) and value >= least and value <= most
end

local function text(value: any, least: number, most: number): boolean
	return type(value) == "string" and #value >= least and #value <= most
end

-- Whether `def` names what a line of `kind` reads, so every line it makes has its words.
local function known(kind: string, def: string, rarity: string, design: number): boolean
	if kind == "Item" or kind == "Reinforce" then
		return Items.ById[def] ~= nil and (design == 0 or Items.Design({ Def = def, Rarity = rarity, Design = design }) ~= nil)
	elseif kind == "Stars" or kind == "First" then
		return Voidkin.ById[def] ~= nil
	elseif kind == "Keeper" then
		local ground = Grounds.ById[def]
		return ground ~= nil and ground.Keeper ~= nil and Enemies.ById[ground.Keeper] ~= nil
	end
	return def == ""
end

-- A message another server published, checked whole: (news, the job it came from), or nil when anything is off.
function Broadcast.Unpack(message: any): (News?, string?)
	if type(message) ~= "table" or message.V ~= VERSION then
		return nil, nil
	end
	local kind, def, rarity = message.K, message.D, message.R
	if type(kind) ~= "string" or table.find(Broadcast.Kinds, kind) == nil or not text(def, 0, DEF_MOST) then
		return nil, nil
	end
	if type(rarity) ~= "string" or Rarity.Rank[rarity] == nil or not whole(message.G, 0, 999) or not whole(message.L, 0, 100000) then
		return nil, nil
	end
	if not whole(message.U, 1, 2 ^ 53) or not text(message.N, 1, NAME_MOST) or not text(message.J, 0, JOB_MOST) then
		return nil, nil
	end
	if not known(kind, def, rarity, message.G) then
		return nil, nil
	end
	local item = news(kind, "All", def, rarity, message.G, message.L)
	item.User, item.Name = message.U, message.N
	return item, message.J
end

local function itemName(item: News): string
	local design = Items.Design({ Def = item.Def, Rarity = item.Rarity, Design = item.Design })
	if design then
		return design.Name
	end
	local row = Items.ById[item.Def]
	return if row then `{item.Rarity} {row.Name}` else item.Def
end

local function voidkinName(item: News): string
	local row = Voidkin.ById[item.Def]
	return if row then row.Name else item.Def
end

-- The line's words, plain (research writes the final words; these stand in), and the rarity whose light it takes.
function Broadcast.Line(item: News): (string, string)
	local who = item.Name
	local kind = item.Kind
	local words
	if kind == "Item" then
		words = `{who} found {itemName(item)}`
	elseif kind == "Reinforce" then
		words = `{who} reinforced {itemName(item)} to +{item.Level}`
	elseif kind == "Stars" then
		words = `{who} raised {voidkinName(item)} to {item.Level} stars`
	elseif kind == "First" then
		words = `{who} found their first {item.Rarity} Voidkin: {voidkinName(item)}`
	elseif kind == "Keeper" then
		local ground = Grounds.ById[item.Def]
		local foe = if ground and ground.Keeper then Enemies.ById[ground.Keeper] else nil
		local difficulty = Broadcast.Difficulties[item.Level] or "Normal"
		words = `{who} brought down {if foe then foe.Name else "a keeper"} on {difficulty} for the first time`
	elseif kind == "Record" then
		words = `{who} climbed the Tower to floor {item.Level}, this server's best`
	else
		words = `{who} leads this week's Tower at floor {item.Level}`
	end
	return words, item.Rarity
end

function Broadcast.Escape(words: string): string
	return (words:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub("\"", "&quot;"):gsub("'", "&apos;"))
end

function Broadcast.Push(list: { any }, item: any, most: number)
	table.insert(list, item)
	while #list > most do
		table.remove(list, 1)
	end
end

function Broadcast.Gate(): Gate
	return { Shown = {}, Waiting = {} }
end

function Broadcast.Wait(gate: Gate, item: News)
	Broadcast.Push(gate.Waiting, item, Config.Waiting)
end

-- The lines that may show at `now` (seconds, any clock that only rises), oldest first: while fewer than Most showed in
-- the last Window seconds.
function Broadcast.Release(gate: Gate, now: number): { News }
	local kept = {}
	for _, at in gate.Shown do
		if now - at < Config.Window then
			table.insert(kept, at)
		end
	end
	gate.Shown = kept
	local out = {}
	while #gate.Waiting > 0 and #gate.Shown < Config.Most do
		table.insert(out, table.remove(gate.Waiting, 1) :: News)
		table.insert(gate.Shown, now)
	end
	return out
end

return Broadcast
