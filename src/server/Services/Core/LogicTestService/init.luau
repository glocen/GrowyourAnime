--!strict
-- LogicTestService (server, Studio only): checks of the game's rule math with no playtest input needed: culls, rewards, rule
-- definitions, the world contract. It complements the movement/combat self-test (SelfTestController). Cases live in
-- the Cases child module; expected values come from the definitions wherever they can.
-- Run during a playtest, Server context:  game.ServerStorage.NL_Debug:Invoke("LogicTests")
-- Its first line's word is Util.Verdict's, as the self-test's: a case that checked nothing, or no case at all, is NOT
-- VERIFIED, never PASSED (Codex's audit, research, 2026-11-27).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Preset = require(ReplicatedStorage.Shared.Util.Preset)
local Verdict = require(ReplicatedStorage.Shared.Util.Verdict)
local DebugService = require(script.Parent.DebugService)
local Cases = require(script.Cases)

export type Tester = {
	Check: (name: string, ok: boolean, detail: string?) -> (),
	Equal: (name: string, got: any, want: any) -> (),
}

local BASELINE = "Baseline" -- the preset the cases are written against

local LogicTestService = {}

function LogicTestService.Run(): string
	local lines: { string } = {}
	local passed, failed, empty = 0, 0, 0
	-- the cases are written against the game's own numbers, whichever preset is being played
	local preset = Preset.Current()
	Preset.Pick(BASELINE)
	task.wait(0.1)
	for _, case in Cases do
		local checks = 0
		local function record(ok: boolean, name: string, detail: string?)
			checks += 1
			if ok then
				passed += 1
			else
				failed += 1
			end
			table.insert(lines, `{if ok then "PASS" else "FAIL"}  {case.Name} · {name}{if detail then ` ({detail})` else ""}`)
		end
		local tester: Tester = {
			Check = function(name, ok, detail)
				record(ok, name, detail)
			end,
			Equal = function(name, got, want)
				record(got == want, name, `got {tostring(got)}, want {tostring(want)}`)
			end,
		}
		local ok, err = pcall(case.Run, tester)
		if not ok then
			record(false, "errored", tostring(err))
		elseif checks == 0 then
			empty += 1
			table.insert(lines, `EMPTY {case.Name} · it ran and checked nothing`)
		end
	end
	Preset.Pick(preset)
	local verdict, reasons = Verdict.Of({ Failed = failed, Ran = #Cases, Skipped = 0, Empty = empty, Missing = {} })
	table.insert(lines, 1, `LOGIC TESTS {verdict}: {passed} passed, {failed} failed, {#Cases} case(s)`)
	if verdict ~= Verdict.Failed then
		for index, reason in reasons do
			table.insert(lines, 1 + index, `WHY   {reason}`)
		end
	end
	return table.concat(lines, "\n")
end

function LogicTestService.Init()
	if RunService:IsStudio() then
		DebugService.Register("LogicTests", LogicTestService.Run)
	end
end

return LogicTestService
