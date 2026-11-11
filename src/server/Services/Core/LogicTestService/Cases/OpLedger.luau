--!strict
-- OpLedger cases (pure): a repeated operation gets its first answer, the ledger stays bounded, and it stays saveable.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local OpLedger = require(game:GetService("ReplicatedStorage").Shared.Rules.OpLedger)

local GUID = "0f8fad5b-d9cb-469f-a165-70867728950e"

return {
	{
		Name = "OpLedger: a new id is unseen",
		Run = function(t: any)
			local ledger = OpLedger.New()
			local seen, answer = OpLedger.Seen(ledger, GUID)
			t.Equal("seen", seen, false)
			t.Equal("answer", answer, nil)
		end,
	},
	{
		Name = "OpLedger: a repeat gets the first answer",
		Run = function(t: any)
			local ledger = OpLedger.New()
			OpLedger.Record(ledger, GUID, "fighter-7", 8)
			OpLedger.Record(ledger, GUID, "fighter-8", 8) -- the retry tries to record a second outcome
			local seen, answer = OpLedger.Seen(ledger, GUID)
			t.Equal("seen", seen, true)
			t.Equal("the first answer stands", answer, "fighter-7")
			t.Equal("held once", #ledger.Order, 1)
		end,
	},
	{
		Name = "OpLedger: the oldest drop past the cap",
		Run = function(t: any)
			local ledger = OpLedger.New()
			for i = 1, 5 do
				OpLedger.Record(ledger, `op-{i}`, i, 3)
			end
			t.Equal("held", #ledger.Order, 3)
			t.Equal("oldest left is op-3", ledger.Order[1], "op-3")
			t.Equal("op-1 forgotten", (OpLedger.Seen(ledger, "op-1")), false)
			t.Equal("op-2 forgotten", (OpLedger.Seen(ledger, "op-2")), false)
			t.Equal("op-5 kept", select(2, OpLedger.Seen(ledger, "op-5")), 5)
		end,
	},
	{
		Name = "OpLedger: stays saveable",
		Run = function(t: any)
			-- A save keeps a list only without gaps and a map only by string keys; Order and Answers must agree.
			local ledger = OpLedger.New()
			for i = 1, 20 do
				OpLedger.Record(ledger, `op-{i % 7}`, true, 4)
			end
			local listed = 0
			for index in ledger.Order do
				listed += 1
				t.Check(`index {index} in order`, index == listed)
			end
			local answered = 0
			for id in ledger.Answers do
				answered += 1
				t.Check(`{id} is in Order`, table.find(ledger.Order, id) ~= nil)
			end
			t.Equal("one answer per id", answered, listed)
		end,
	},
	{
		Name = "OpLedger: a client's id is checked",
		Run = function(t: any)
			t.Check("a GUID", OpLedger.ValidId(GUID))
			t.Check("short letters", OpLedger.ValidId("a1"))
			t.Check("not nil", not OpLedger.ValidId(nil))
			t.Check("not a number", not OpLedger.ValidId(12))
			t.Check("not empty", not OpLedger.ValidId(""))
			t.Check("not 41 characters", not OpLedger.ValidId(string.rep("a", 41)))
			t.Check("no spaces", not OpLedger.ValidId("a b"))
			t.Check("no dots or slashes", not OpLedger.ValidId("../x"))
		end,
	},
	{
		Name = "OpLedger: a nil answer is refused",
		Run = function(t: any)
			local ledger = OpLedger.New()
			local ok = pcall(OpLedger.Record, ledger, GUID, nil, 4)
			t.Check("Record errors", not ok)
			t.Equal("nothing held", #ledger.Order, 0)
		end,
	},
}
