--!strict
-- Funnel (pure): the first session, measured (TR32; docs/north-star.md, "The first session"). Each beat of that
-- session the build has is a step of Roblox's onboarding funnel, logged once an account from the server act that makes
-- it true (FunnelService). This module names the steps in their order, says which steps a committed act's answer makes
-- true, and marks them on the save, so a repeat, a retried request or a rejoin never logs one again.
--   Funnel.Steps                         the steps in their order: a step's place is its number in Roblox's funnel
--   Funnel.Number[name]                  a step's number
--   Funnel.Of(label, answer): { string } the steps a committed act or server change makes true, in their order
--   Funnel.Mark(data, steps): Answer     marks the steps not yet marked; { Ok, Logged = { { Step, Name } } }, or
--                                        refused with Funnel.Marked when every one already is
-- Arrive (the first join) and Want (the keeper's gate reached) aren't acts: FunnelService marks them itself.

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)

local Funnel = {}

Funnel.Marked = "Marked"

Funnel.Steps = {
	"Arrive", -- the first join
	"Choose", -- a starter picked
	"Reveal", -- its shard broken: the first Voidkin opened
	"Fight", -- the first Shade falls (Lantern Row, the first ground)
	"Find", -- the Named shard found: it drops with the first Shade
	"Work", -- the first worker in a bay
	"Build", -- the first item equipped
	"Want", -- the keeper's gate reached
}

Funnel.Number = {} :: { [string]: number }
for index, name in Funnel.Steps do
	Funnel.Number[name] = index
end

export type Logged = { Step: number, Name: string }

local function filled(answer: { [string]: any }, field: string): boolean
	local value = answer[field]
	return type(value) == "string" and value ~= ""
end

-- What each act's answer must say for its step: a recall (no Voidkin) isn't a worker, taking an item off isn't one
-- equipped.
local READ: { [string]: (answer: { [string]: any }) -> { string } } = {
	ChooseStarter = function()
		return { "Choose" }
	end,
	Open = function()
		return { "Reveal" }
	end,
	Drop = function(answer)
		return if filled(answer, "First") then { "Fight", "Find" } else { "Fight" }
	end,
	SetWorker = function(answer)
		return if filled(answer, "Voidkin") then { "Work" } else {}
	end,
	Equip = function(answer)
		return if filled(answer, "Item") then { "Build" } else {}
	end,
}

function Funnel.Of(label: string, answer: any): { string }
	if type(answer) ~= "table" or answer.Ok ~= true then
		return {}
	end
	local read = READ[label]
	return if read then read(answer) else {}
end

function Funnel.Mark(data: Profile.Data, steps: { string }): { [string]: any }
	local logged: { Logged } = {}
	for _, name in steps do
		local number = Funnel.Number[name]
		if number and data.Funnel[name] ~= true then
			data.Funnel[name] = true
			table.insert(logged, { Step = number, Name = name })
		end
	end
	if #logged == 0 then
		return { Ok = false, Error = Funnel.Marked }
	end
	table.sort(logged, function(a: Logged, b: Logged): boolean
		return a.Step < b.Step
	end)
	return { Ok = true, Logged = logged }
end

return Funnel
