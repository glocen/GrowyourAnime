--!strict
-- Helpers (client, Studio only): the case lists' shared waits and reads, one home each, for Cases and the lists that join
-- the run apart from it (Cases is at the type checker's limit, so a list that needs these can't be given them by Cases).
--   Helpers.ANSWER                          seconds a request through a screen may take to come back in the save's copy
--   Helpers.SKIP_ALL                        seconds of base time a case skips, past any shard's work at the floor's speed
--   Helpers.waitFor(t, seconds, ok)         true as soon as `ok` holds, polled every 0.1 s, or its last word at the end
--   Helpers.lintClean(t, where)             the UI lint's checks on whatever shows now, once no toast is mid-ride
--   Helpers.readyCount(def)                 shards of `def` broken and waiting to be opened
--   Helpers.openReadyDown(t, def, keep)     opens them, the oldest first, down to `keep`
--   Helpers.breakerPart(name)               a piece of the open Breaker screen, by name at any depth under its body
--   Helpers.batteryCells(t, mark, kwh, cap, where)  the battery mark's cells lit as the charge says (UI.BatteryMark)
--   Helpers.SQUARE                          the elite in the square (one elite a stage, TR43): its group's Name ("Elite 2"),
--                                           its marker's Stage, and the pack before it (Before, "Pack 2")
--   Helpers.TRIP_ASKED                      seconds a step on a door or a pad, or a pick, may take to ask for a trip
--   Helpers.lastTrip(t, role)               the newest trip TravelService's stub recorded, if it goes to place `role`

local Shared = game:GetService("ReplicatedStorage").Shared
local HudConfig = require(Shared.Config.Hud)
local WorldConfig = require(Shared.Config.World)
local StagesConfig = require(Shared.Config.Stages)
local Hud = require(Shared.Rules.Hud)
local ProfileController = require(script.Parent.Parent.ProfileController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Toast = require(UI.Kit.Toast)
local Screen = require(UI.Kit.Screen)
local BreakerScreen = require(UI.BreakerScreen)
local StageScreen = require(UI.StageScreen)
local UiLint = require(script.Parent.UiLint)

local Helpers = {}

Helpers.TRIP_ASKED = 3

function Helpers.lastTrip(t: any, role: string): { [string]: any }?
	local record = t.Server("TravelSent")
	local sent = if type(record) == "table" and type(record.Sent) == "table" then record.Sent else {}
	local last = sent[#sent]
	return if type(last) == "table" and last.Role == role then last else nil
end

Helpers.ANSWER = 3
Helpers.SKIP_ALL = 3600
Helpers.SQUARE = (function(): { Name: string, Stage: number, Before: string }
	local packs = 0
	for _, stop in WorldConfig.Row.Stops do
		packs += if stop.Kind == "Pack" then 1 else 0
		if stop.Kind == "Elite" and stop.Square then
			return { Name = `Elite {stop.Stage}`, Stage = stop.Stage, Before = `Pack {packs}` }
		end
	end
	return { Name = "Elite", Stage = 0, Before = "Pack 1" }
end)()

function Helpers.waitFor(t: any, seconds: number, ok: () -> boolean): boolean
	local began = os.clock()
	while os.clock() - began < seconds do
		if ok() then
			return true
		end
		t.Wait(0.1)
	end
	return ok()
end

-- Ends a run a case left going, by the game's own way out: its lead's fall (StageBegin would begin another). Its card
-- comes Results.After later and is closed; the lead is healed. The record's stretches are the case's to put back after.
function Helpers.endRun(t: any)
	local player = game:GetService("Players").LocalPlayer
	if type(player:GetAttribute("StageRun")) ~= "string" then
		return
	end
	t.Server("FightHealth", 0)
	Helpers.waitFor(t, 2, function(): boolean
		return player:GetAttribute("StageRun") == nil
	end)
	Helpers.waitFor(t, StagesConfig.Results.After + 1, function(): boolean
		return Screen.Current() == StageScreen.Name
	end)
	Screen.Close()
	t.Server("LeadHeal")
end

-- A toast rides in from off the screen and leaves that way (Kit.Toast), so the lint reads once none is mid-ride: a gain's
-- toast caught on its way in failed "on screen" under load (2026-11-15).
function Helpers.lintClean(t: any, where: string)
	Helpers.waitFor(t, 1, function(): boolean
		return not Toast.Riding()
	end)
	-- One frame, so the deferred signals have run, as they always have before a frame draws: NameGuardController keeps a
	-- name from translation on one (D8), and a case can lint in the frame that built its rows.
	task.wait()
	local report = UiLint.Run()
	t.Check(`{where}: every label fits its box`, #report.Fit == 0, UiLint.Detail(report.Fit, report.Checked))
	t.Check(`{where}: every label reads at {Theme.Text.Minimum} px or more`, #report.Size == 0, UiLint.Detail(report.Size, report.Checked))
	t.Check(`{where}: every label is on screen`, #report.Screen == 0, UiLint.Detail(report.Screen, report.Checked))
	t.Check(`{where}: no label shows Roblox's default`, #report.Placeholder == 0, UiLint.Detail(report.Placeholder, report.Checked))
	t.Check(`{where}: no Voidkin's name goes to translation`, #report.Names == 0, UiLint.Detail(report.Names, report.Checked))
	t.Check(`{where}: every tap is {Theme.Size.Touch} px or more`, #report.Touch == 0, UiLint.Detail(report.Touch, report.Checked))
	t.Check(`{where}: every piece sits in the safe area`, #report.Safe == 0, UiLint.Detail(report.Safe, report.Checked))
	t.Check(`{where}: no two pieces of the HUD overlap`, #report.Overlap == 0, UiLint.Detail(report.Overlap, report.Checked))
	t.Check(`{where}: nothing sits under the thumbs' controls`, #report.Thumbs == 0, UiLint.Detail(report.Thumbs, report.Checked))
	t.Check(`{where}: no list draws Roblox's own thumb`, #report.Bars == 0, UiLint.Detail(report.Bars, report.Checked))
end

function Helpers.readyCount(def: string): number
	local view = ProfileController.Get()
	local count = 0
	for _, work in (if view then view.Base.Ready else {}) do
		count += if work.Def == def then 1 else 0
	end
	return count
end

-- A case leaves the Breaker as it found it.
function Helpers.openReadyDown(t: any, def: string, keep: number)
	while Helpers.readyCount(def) > keep do
		local current = ProfileController.Get()
		local at = 0
		for index, work in (if current then current.Base.Ready else {}) do
			if at == 0 and work.Def == def then
				at = index
			end
		end
		local count = Helpers.readyCount(def)
		if ProfileController.Act("Open", { Index = at }).Ok ~= true then
			break
		end
		Helpers.waitFor(t, Helpers.ANSWER, function(): boolean
			return Helpers.readyCount(def) < count
		end)
	end
end

function Helpers.breakerPart(name: string): Instance?
	local frame = Screen.Frame(BreakerScreen.Name)
	local body = frame and frame:FindFirstChild("Body")
	return body and body:FindFirstChild(name, true)
end

-- The battery's mark (UI.BatteryMark; TR41 (e), research's must-fix): as many cells lit as Rules.Hud.BatteryCells says
-- for this charge, each drawn from its own image as a lit cell or the slot's dark, so it never disagrees with the reading.
function Helpers.batteryCells(t: any, mark: Instance?, kwh: number, capacity: number, where: string)
	local want = Hud.BatteryCells(kwh, capacity)
	local cells = HudConfig.Power.Cells
	local drawn = 0
	if mark and mark:IsA("ImageLabel") then
		for index = 1, 3 do
			local cell = mark:FindFirstChild(`Cell{index}`)
			local lit = index <= want
			if cell and cell:IsA("ImageLabel") and cell.Image == mark.Image and cell:GetAttribute("Lit") == lit and cell.ImageRectOffset == (if lit then cells.Lit else cells.Dark.From) then
				drawn += 1
			end
		end
	end
	local said = if mark then tostring(mark:GetAttribute("Cells")) else "no mark"
	t.Check(`{where}: the mark's cells follow the charge, {want} of 3 lit at {string.format("%.2f", kwh)} of {capacity} kWh`, mark ~= nil and mark:GetAttribute("Cells") == want and drawn == 3, `{said} lit, {drawn} of 3 drawn so`)
end

return Helpers
