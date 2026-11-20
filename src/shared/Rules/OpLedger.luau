--!strict
-- OpLedger (shared, pure): the operation ids a profile has already applied, each with its first answer, so a request the
-- client sends again under its id (ProfileController.Act's retry, a resend after lag) gets that answer again and changes
-- nothing (the directive, section 9). A second press is a new request with its own id: the UI kit's Button refuses it
-- while the first is pending, and the rule itself refuses what the save can no longer pay for.
-- The ledger lives inside the saved profile and is written in the same change as what the operation did, so a repeat after
-- a crash or a server hop is caught too. No Roblox API: it runs with Studio closed (tools/checks/logic_offline.luau).

export type Ledger = {
	Order: { string }, -- the ids held, oldest first: a list with no gaps, as a save needs
	Answers: { [string]: any }, -- by id, the first answer: plain data only, because it's saved
}

local MAX_ID_LENGTH = 40 -- a GUID is 36 characters with its dashes

local OpLedger = {}

function OpLedger.New(): Ledger
	return { Order = {}, Answers = {} }
end

-- A well-formed op id: letters, digits and dashes, 1 to MAX_ID_LENGTH long. A client sends it, so it's checked first.
function OpLedger.ValidId(id: any): boolean
	return type(id) == "string" and #id >= 1 and #id <= MAX_ID_LENGTH and string.find(id, "^[%w%-]+$") ~= nil
end

-- (true, the first answer) when the ledger holds `id`, else (false, nil).
function OpLedger.Seen(ledger: Ledger, id: string): (boolean, any)
	local answer = ledger.Answers[id]
	if answer == nil then
		return false, nil
	end
	return true, answer
end

-- Holds `id` with `answer`, dropping the oldest ids past `keep`. An id already held keeps its first answer.
function OpLedger.Record(ledger: Ledger, id: string, answer: any, keep: number)
	assert(answer ~= nil, "an answer can't be nil: the id would read as never seen")
	assert(keep >= 1, "the ledger must keep at least one id")
	if ledger.Answers[id] ~= nil then
		return
	end
	table.insert(ledger.Order, id)
	ledger.Answers[id] = answer
	while #ledger.Order > keep do
		local oldest = table.remove(ledger.Order, 1) :: string
		ledger.Answers[oldest] = nil
	end
end

return OpLedger
