--!strict
-- Transaction (shared, pure): one change to a profile, all or nothing (docs/engineering-plan.md, "Transactions").
-- The change runs on a copy. Only when it answers Ok does the copy replace the profile, with its operation id written into
-- the ledger in the same step, so a repeated request gets the first answer and changes nothing, even after a crash.
-- A refusal or an error inside the change leaves the profile exactly as it was.
-- The change itself must not yield, and one that does is refused (see Run), so two changes can never interleave.
-- Code that keeps a reference to a table inside a profile loses it at the next commit: read from the profile each time.
-- No Roblox API: it runs with Studio closed.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OpLedger = require(ReplicatedStorage.Shared.Rules.OpLedger)
local Profile = require(ReplicatedStorage.Shared.Data.Profile)

-- What a change answers. Plain data only, because a client's answer is saved in the ledger: Ok, and on a refusal the
-- reason as a short code ("NoShard", "Busy"); anything else the change wants the caller to know rides beside them.
export type Answer = { [string]: any }

export type Change = (draft: Profile.Data) -> Answer

local Transaction = {}

-- Refusal codes this module gives itself. A change's own codes are its rules' business.
Transaction.Failed = "Failed" -- the change errored: a bug, logged by the caller, and nothing applied
Transaction.BadOp = "BadOp" -- the operation id isn't well formed

local function commit(data: Profile.Data, draft: Profile.Data)
	local target = data :: any
	for key in target do
		if (draft :: any)[key] == nil then
			target[key] = nil
		end
	end
	for key, value in draft :: any do
		target[key] = value
	end
end

-- Runs `change` on a copy of `data` and commits it if it answers Ok.
-- `opId` is the client's operation id, or nil for a change the server makes on its own (a drop, a keeper's fall), whose
-- callers make sure it runs once. Returns the answer, whether `data` changed, and the error text when the change errored.
function Transaction.Run(data: Profile.Data, opId: string?, change: Change, keep: number): (Answer, boolean, string?)
	if opId ~= nil then
		if not OpLedger.ValidId(opId) then
			return { Ok = false, Error = Transaction.BadOp }, false, nil
		end
		local seen, first = OpLedger.Seen(data.Ops, opId)
		if seen then
			return first, false, nil
		end
	end
	local draft = Profile.DeepCopy(data)
	-- Run in its own thread to catch a yield: a change that waited would let another change commit meanwhile, and
	-- committing this one after it would silently undo the other. So a change that yields is refused, its draft dropped.
	local thread = coroutine.create(change)
	local ran, result = coroutine.resume(thread, draft)
	if not ran then
		return { Ok = false, Error = Transaction.Failed }, false, tostring(result)
	end
	if coroutine.status(thread) ~= "dead" then
		return { Ok = false, Error = Transaction.Failed }, false, "the change yielded; a change must finish without waiting"
	end
	local answer: Answer = if type(result) == "table" then result else { Ok = false, Error = Transaction.Failed }
	if answer.Ok ~= true then
		return answer, false, if type(result) == "table" then nil else "the change returned no answer table"
	end
	if opId ~= nil then
		-- a copy, so an answer that points into the profile (a new Voidkin's record) isn't saved twice under one table
		OpLedger.Record(draft.Ops, opId, Profile.DeepCopy(answer), keep)
	end
	commit(data, draft)
	return answer, true, nil
end

return Transaction
