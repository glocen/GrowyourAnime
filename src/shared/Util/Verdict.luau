--!strict
-- Verdict (shared, pure): a test run's one word from what it saw (research's item 2, 2026-11-27, from the director's
-- Turing document; SelfTestController). In order:
--   FAILED        any failure seen
--   NOT VERIFIED  the run can't vouch for what was asked: no case ran (a filter that matched nothing), a case asked for
--                 was left out (it belongs to the other place), a case ran and checked nothing, or evidence the run
--                 needs is missing (the server's error list unread, no frames drawn)
--   PASSED        every case asked for ran, checked something, and passed
-- No Roblox API: its cases run with Studio closed.
--   Verdict.Of(run) -> (word, reasons)   reasons: why it isn't PASSED, one line each; empty on a pass

local Verdict = {}

Verdict.Passed = "PASSED"
Verdict.Failed = "FAILED"
Verdict.NotVerified = "NOT VERIFIED"

-- What a run saw. Ran: the cases asked for that ran. Skipped: those asked for but left out (another place's). Empty:
-- those that ran and recorded no check. Missing: each piece of evidence the run needed and didn't get, in words.
export type Run = { Failed: number, Ran: number, Skipped: number, Empty: number, Missing: { string } }

function Verdict.Of(run: Run): (string, { string })
	local reasons: { string } = {}
	if run.Failed > 0 then
		table.insert(reasons, `{run.Failed} check(s) failed`)
		return Verdict.Failed, reasons
	end
	if run.Ran == 0 then
		table.insert(reasons, "no case ran: the filter matched none here")
	end
	if run.Skipped > 0 then
		table.insert(reasons, `{run.Skipped} case(s) asked for belong to the other place and didn't run`)
	end
	if run.Empty > 0 then
		table.insert(reasons, `{run.Empty} case(s) ran and checked nothing`)
	end
	for _, missing in run.Missing do
		table.insert(reasons, missing)
	end
	return if #reasons > 0 then Verdict.NotVerified else Verdict.Passed, reasons
end

return Verdict
