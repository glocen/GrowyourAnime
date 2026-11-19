--!strict
-- FunnelCases: the first session measured, in a playtest (TR32; FunnelService, Rules.Funnel). The rule's own cases run
-- with Studio closed (LogicTestService/Cases/Funnel.luau); these prove the wire: a committed act's label reaches the
-- funnel, its step is marked on the save and logged once, and a repeat, a second act or a refusal logs nothing. The
-- account's own marks are put back at the end.

local HttpService = game:GetService("HttpService")
local Helpers = require(script.Parent.Helpers)

local FunnelCases = {}

local LOG = 2 -- seconds for a committed act's step to be marked and logged (deferred after the act)
local SETTLE = 0.5 -- seconds a repeat is given to log something it shouldn't
local LOOK = 3 -- seconds for the gate's look (every second) to see the avatar

local function said(t: any): string
	local read = t.Server("Funnel")
	return if read and read.Ok then table.concat(read.Logged, ", ") else "?"
end

local function marked(t: any, name: string): boolean
	local read = t.Server("Funnel")
	return read ~= nil and read.Ok == true and table.find(read.Marks, name) ~= nil
end

-- An item the account wears, or one given for the case and taken back after it.
local function worn(t: any): (string?, string?, string?)
	local view = t.Server("Data")
	local preset = if view and view.Presets then view.Presets[1] else nil
	for slot, id in (if preset then preset.Slots else {}) :: { [string]: string } do
		return slot, id, nil
	end
	local given = t.Server("ItemGive", "helmet", "Common", {})
	return "Helmet", if given and given.Ok then given.Id else nil, if given and given.Ok then given.Id else nil
end

function FunnelCases.Cases(): { any }
	local waitFor = Helpers.waitFor
	return {
		{
			Name = "Funnel: TR32, a step through the act's own path: an item equipped logs Build once; its repeat, a second equip and a refused pick log nothing",
			Run = function(t: any)
				local before = t.Server("Funnel")
				t.Check("the funnel's marks read", before ~= nil and before.Ok == true)
				if not (before and before.Ok) then
					return
				end
				t.Check("the marks cleared for the case", t.Server("FunnelSet", {}).Ok == true and not marked(t, "Build"))
				local slot, item, given = worn(t)
				t.Check("an item to equip", item ~= nil)
				if item then
					local op = HttpService:GenerateGUID(false)
					local args = { Preset = 1, Slot = slot, Item = item }
					t.Check("the equip is answered", t.Server("Act", "Equip", args, op).Ok == true)
					waitFor(t, LOG, function(): boolean
						return marked(t, "Build")
					end)
					t.Check("Build marked on the save", marked(t, "Build"))
					t.Equal("logged once, as step 7", said(t), "7 Build")
					t.Server("Act", "Equip", args, op)
					t.Server("Act", "Equip", args)
					t.Check("a refused pick (the starter's chosen) is refused", t.Server("Act", "ChooseStarter", { Shard = "starter_rook" }).Ok ~= true)
					task.wait(SETTLE)
					t.Equal("its repeat, a second equip and a refused pick: nothing more", said(t), "7 Build")
					t.Equal("the marks: Build alone", table.concat(t.Server("Funnel").Marks, ", "), "Build")
				end
				if given then
					t.Server("Act", "Equip", { Preset = 1, Slot = "Helmet", Item = "" })
					t.Server("ItemTake", given)
				end
				t.Server("FunnelSet", before.Marks)
				t.Equal("the account's own marks put back", table.concat(t.Server("Funnel").Marks, ", "), table.concat(before.Marks, ", "))
			end,
		},
		{
			Name = "Funnel: TR32, the keeper's gate reached logs Want once, at the Challenge's reach",
			Place = "Festival", -- the keeper's gate stands in that place only (TR45)
			Run = function(t: any)
				local before = t.Server("Funnel")
				t.Check("the funnel's marks read", before ~= nil and before.Ok == true)
				local gate = t.Server("TestStream", "KeeperGate")
				t.Check("the keeper's gate found", typeof(gate) == "Vector3")
				if not (before and before.Ok and typeof(gate) == "Vector3") then
					return
				end
				t.Server("FunnelSet", {})
				t.Server("TestStandAt", gate + Vector3.new(0, 3, 14), gate)
				task.wait(LOOK)
				t.Check("outside the reach: no Want", not marked(t, "Want"))
				t.Server("TestStandAt", gate + Vector3.new(0, 3, 6), gate)
				waitFor(t, LOOK, function(): boolean
					return marked(t, "Want")
				end)
				t.Equal("within the reach: Want logged once, as step 8", said(t), "8 Want")
				task.wait(LOOK)
				t.Equal("standing on: nothing more", said(t), "8 Want")
				t.Server("FunnelSet", before.Marks)
			end,
		},
	}
end

return FunnelCases
