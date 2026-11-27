--!strict
-- Verdict cases (pure): a test run's word (Util.Verdict; research's item 2, 2026-11-27). A real match passes; a typo, a
-- case of the other place's, a case that checks nothing, a failure and missing evidence each give their own outcome.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Verdict = require(game:GetService("ReplicatedStorage").Shared.Util.Verdict)

local function run(over: { [string]: any }): Verdict.Run
	local r: Verdict.Run = { Failed = 0, Ran = 3, Skipped = 0, Empty = 0, Missing = {} }
	for key, value in over do
		(r :: any)[key] = value
	end
	return r
end

return {
	{
		Name = "Verdict: PASSED only when every case asked for ran and passed; each other outcome its own",
		Run = function(t: any)
			local word, reasons = Verdict.Of(run({}))
			t.Check("a real match, every case run and passed: PASSED", word == Verdict.Passed and #reasons == 0, word)
			word, reasons = Verdict.Of(run({ Ran = 0 }))
			t.Check("a typo, no case ran: NOT VERIFIED", word == Verdict.NotVerified and string.find(reasons[1], "no case ran", 1, true) ~= nil, word)
			word, reasons = Verdict.Of(run({ Ran = 0, Skipped = 2 }))
			t.Check("the other place's cases, none run here: NOT VERIFIED, both said", word == Verdict.NotVerified and #reasons == 2, `{word}: {table.concat(reasons, "; ")}`)
			word = Verdict.Of(run({ Skipped = 1 }))
			t.Equal("some ran, one asked for left out: NOT VERIFIED", word, Verdict.NotVerified)
			word = Verdict.Of(run({ Empty = 1 }))
			t.Equal("a case that checked nothing: NOT VERIFIED", word, Verdict.NotVerified)
			word, reasons = Verdict.Of(run({ Missing = { "the server's error list couldn't be read" } }))
			t.Check("missing evidence: NOT VERIFIED, with its words", word == Verdict.NotVerified and reasons[1] == "the server's error list couldn't be read", word)
			word = Verdict.Of(run({ Failed = 1 }))
			t.Equal("a failing case: FAILED", word, Verdict.Failed)
			word = Verdict.Of(run({ Failed = 2, Ran = 0, Skipped = 1, Missing = { "no frames drawn" } }))
			t.Equal("a failure seen comes first, whatever else is missing", word, Verdict.Failed)
		end,
	},
}
