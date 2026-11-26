--!strict
-- Exist (pure): how many of a Voidkin exist (docs/design.md, "Voidkin", "How many exist"; the outside review's item 4,
-- research, 2026-11-25). Each Voidkin the server uncovers for an account gets its own number, never reused, in the order
-- its kind was first held by any account; a duplicate becomes a copy and gets none. The count is how many accounts hold
-- its kind: Voidkin really granted, never numbers reserved and left unused, so it may run behind and never ahead. No
-- Roblox API: tested with Studio closed.
--   Missing  the owned Voidkin still waiting for a number, in the order they were uncovered
--   Fresh    a save numbered in another era cleared for this one (Config.Exist.Epoch)
--   Grant    a number written on one owned Voidkin, once: the server's change after it holds the number
--   Reserve  the store's transform: a block of numbers taken and the grants made added, in one write
--   Take     the next number from a server's block
--   Words    "No. 1,284 · 3,912 exist", as the Overview's header says it

local Shared = script.Parent.Parent
local Profile = require(Shared.Data.Profile)
local Hud = require(Shared.Rules.Hud)

local Exist = {}

-- A kind's record in the store: the next number nobody holds yet, and how many were granted.
export type Stored = { Next: number, Held: number }
-- A server's block of numbers for one kind: From to To, both included; empty once From passes To.
export type Block = { From: number, To: number }

Exist.Taken = "Taken" -- it has a number already
Exist.Gone = "Gone" -- no such Voidkin
Exist.Era = "Era" -- the save belongs to another era: numbered again first

-- The owned Voidkin with no number, as { Id, Def }, in the order they were uncovered (then by id, so two reads agree).
function Exist.Missing(data: Profile.Data): { { Id: string, Def: string } }
	local out: { { Id: string, Def: string, Born: number } } = {}
	for id, owned in data.Voidkin do
		if owned.No == nil then
			table.insert(out, { Id = id, Def = owned.Def, Born = owned.Born or 0 })
		end
	end
	table.sort(out, function(a: { Id: string, Def: string, Born: number }, b: { Id: string, Def: string, Born: number }): boolean
		if a.Born ~= b.Born then
			return a.Born < b.Born
		end
		return a.Id < b.Id
	end)
	local missing: { { Id: string, Def: string } } = {}
	for _, each in out do
		table.insert(missing, { Id = each.Id, Def = each.Def })
	end
	return missing
end

-- A save numbered in another era loses its numbers and joins `epoch`; true when it changed.
function Exist.Fresh(data: Profile.Data, epoch: string): boolean
	if data.ExistEpoch == epoch then
		return false
	end
	data.ExistEpoch = epoch
	for _, owned in data.Voidkin do
		owned.No = nil
	end
	return true
end

-- Number `no` written on Voidkin `id`, once, in era `epoch`: { Ok } or a refusal (Taken, Gone, Era), so a number the
-- save can't take stays unused and is never counted.
function Exist.Grant(data: Profile.Data, id: string, no: number, epoch: string): { [string]: any }
	if data.ExistEpoch ~= epoch then
		return { Ok = false, Error = Exist.Era }
	end
	local owned = data.Voidkin[id]
	if owned == nil then
		return { Ok = false, Error = Exist.Gone }
	end
	if owned.No ~= nil then
		return { Ok = false, Error = Exist.Taken }
	end
	owned.No = no
	return { Ok = true, Id = id, No = no }
end

-- The store's transform for one kind: `take` numbers reserved and `add` grants counted, in one write. Returns the new
-- record and the block it reserved (nil when `take` is 0). A record that isn't one starts at number 1 and none held.
function Exist.Reserve(old: any, take: number, add: number): (Stored, Block?)
	local next = if type(old) == "table" and type(old.Next) == "number" then math.max(1, math.floor(old.Next)) else 1
	local held = if type(old) == "table" and type(old.Held) == "number" then math.max(0, math.floor(old.Held)) else 0
	local block: Block? = if take > 0 then { From = next, To = next + take - 1 } else nil
	return { Next = next + math.max(0, take), Held = held + math.max(0, add) }, block
end

-- The next number from `block`, or nil when it's spent.
function Exist.Take(block: Block?): number?
	if block == nil or block.From > block.To then
		return nil
	end
	local no = block.From
	block.From += 1
	return no
end

-- "No. 1,284 · 3,912 exist" ("1 exists" alone); "No. 1,284" before the count is read; "" with no number yet.
function Exist.Words(no: number?, count: number?): string
	if no == nil then
		return ""
	end
	local said = `No. {Hud.Digits(no)}`
	if count ~= nil and count > 0 then
		said ..= ` · {Hud.Digits(count)} {if count == 1 then "exists" else "exist"}`
	end
	return said
end

return Exist
