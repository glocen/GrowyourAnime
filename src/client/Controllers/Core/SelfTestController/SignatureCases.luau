--!strict
-- SignatureCases (client, Studio only): TR52's block, the signature on a tap, a list of its own beside Cases, which joins
-- it as it joins ViewCases (Cases' one table had passed what the type solver checks in one piece). The readout is the
-- button and the Auto toggle stands after the eye (HudController); the server arms and fires (FightService.Tap), on
-- Rules.Fight.Tap, whose own cases are the logic cases'.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Actions = require(Shared.Definitions.Actions)
local HudConfig = require(Shared.Config.Hud)
local FightRule = require(Shared.Rules.Fight)
local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Button = require(UI.Kit.Button)

local SignatureCases = {}

-- Cases' own helpers and measures, one home each.
export type Given = {
	LEAD_SETTLE: number,
	SHADE_AHEAD: number,
	SHADE_TOUGHER: number,
	SHADE_TIMEOUT: number,
	waitFor: (t: any, seconds: number, ok: () -> boolean) -> boolean,
	myLead: () -> Model?,
}

function SignatureCases.Cases(given: Given): { any }
	local LEAD_SETTLE, SHADE_AHEAD, SHADE_TOUGHER, SHADE_TIMEOUT = given.LEAD_SETTLE, given.SHADE_AHEAD, given.SHADE_TOUGHER, given.SHADE_TIMEOUT
	local waitFor, myLead = given.waitFor, given.myLead
	return {
		{
			Name = "HUD: TR52, the signature on a tap: Auto off holds a full ring, and it pulses once; a tap answers on its frame and fires it once; a ring not full does nothing",
			Run = function(t: any)
				-- TR52's block (docs/test-requests.md): the readout is the button, the Auto toggle after the eye. The server arms
				-- and fires (Rules.Fight.Tap, FightService.Tap); this watches the lead's Ready and Action from here.
				-- Whole, standing and out of any fight, whatever the case before left (the HUD's run: a fall sends it home).
				t.Server("LeadHeal")
				t.Server("LeadCalm")
				t.Server("FightSpawn")
				t.Wait(LEAD_SETTLE)
				local lead = myLead()
				local def = if lead then lead:GetAttribute("Def") else nil
				local kit = Actions.KitOf(if type(def) == "string" then def else "")
				local signature = FightRule.Signature(kit)
				local parts = HudController.Parts()
				local ring, auto = parts.Signature, parts.SignatureAuto :: TextButton
				if lead == nil or signature == nil then
					t.Check("a lead without a signature has no readout", lead ~= nil and not ring.Visible)
					return
				end
				local action = signature :: Actions.Action
				local me = Players.LocalPlayer
				local function target(): boolean
					local id = lead:GetAttribute("Target")
					return type(id) == "string" and id ~= ""
				end
				local ok, err = pcall(function()
					Net.Client.Invoke("Signature", "Auto", true)
					local level = lead:GetAttribute("Level")
					local spawned = t.Server("FightSpawn", "brawler", (if type(level) == "number" then level else 1) + SHADE_TOUGHER, SHADE_AHEAD, true) -- it comes for the lead, wherever the camera looks
					t.Check("a Shade to fight spawns", type(spawned) == "table" and spawned.Ok == true)
					t.Check("the lead takes it on", waitFor(t, SHADE_TIMEOUT, target), `state {tostring(lead:GetAttribute("State"))}, away {tostring(lead:GetAttribute("Away"))}`)
					t.Check("in a fight, Auto shows after the eye, on", waitFor(t, 1, function(): boolean
						return auto.Visible and ring.Visible
					end) and me:GetAttribute("SignatureAuto") ~= false)
					-- Auto off, on its toggle; then a fresh ring (the lead stood up full) waits for the tap.
					Button.Press(auto)
					t.Check("its toggle turns Auto off", waitFor(t, 2, function(): boolean
						return me:GetAttribute("SignatureAuto") == false
					end))
					local pulses, last, fires = 0, 0, 0
					local acted: { string } = {}
					local pulseWatch = RunService.RenderStepped:Connect(function()
						local p = (ring:GetAttribute("Pulse") :: number?) or 0
						if p > 0 and last <= 0 then
							pulses += 1
						end
						last = p
					end)
					local readyWatch = lead:GetAttributeChangedSignal("Ready"):Connect(function()
						fires += 1
					end)
					local actionWatch = lead:GetAttributeChangedSignal("Action"):Connect(function()
						table.insert(acted, tostring(lead:GetAttribute("Action")))
					end)
					-- Wait it out to full if it fired before Auto went off.
					local full = waitFor(t, action.Cooldown + 2, function(): boolean
						return ring:GetAttribute("Share") == 1
					end)
					t.Check("the ring fills", full)
					fires, pulses = 0, 0
					local heldFrom = os.clock()
					t.Wait(HudConfig.Readout.Ready + HudConfig.Readout.Pulse.Hold + HudConfig.Readout.Pulse.Length + 1.2)
					t.Check("Auto off: a full ring waits for the tap", fires == 0 and target(), `{fires} fires in {string.format("%.1f", os.clock() - heldFrom)} s`)
					t.Check("and pulses once, so it's never missed", pulses == 1, `{pulses} pulses`)
					-- The tap: three on one frame, as a thumb's bounce might.
					fires = 0
					table.clear(acted)
					-- Watched over the frames, not read once: this thread and the HUD's step share each frame's RenderStepped.
					local scale = ring:FindFirstChildOfClass("UIScale")
					local frames, dipped, least = 0, nil :: number?, 1
					local squeezeWatch = RunService.RenderStepped:Connect(function()
						frames += 1
						local now = if scale then scale.Scale else 1
						least = math.min(least, now)
						if dipped == nil and now < 1 - HudConfig.Readout.Press / 4 then
							dipped = frames
						end
					end)
					local tappedAt = os.clock()
					HudController.TapSignature()
					HudController.TapSignature()
					HudController.TapSignature()
					t.Wait(HudConfig.Readout.PressTime)
					squeezeWatch:Disconnect()
					t.Check("the tap answers on its frame: the ring squeezes in", dipped ~= nil and dipped <= 2 and least < 1 - HudConfig.Readout.Press / 2, string.format("in on frame %s, to %.3f", tostring(dipped), least))
					local started = waitFor(t, 2, function(): boolean
						return table.find(acted, action.Id) ~= nil
					end)
					local took = os.clock() - tappedAt
					t.Check("the signature starts its clip at once", started and took < 0.3, string.format("%s in %.0f ms", tostring(started), took * 1000))
					t.Wait(1)
					local starts = 0
					for _, id in acted do
						if id == action.Id then
							starts += 1
						end
					end
					t.Check("three taps on one frame fire it once", fires == 1 and starts == 1, `{fires} fires, {starts} starts`)
					t.Check("fired, the ring empties", ((ring:GetAttribute("Share") :: number?) or 1) < 0.5 and ring:GetAttribute("Armed") == false)
					-- A ring not full: a tap does nothing and changes nothing.
					local before = lead:GetAttribute("Ready")
					local answer = Net.Client.Invoke("Signature", "Tap")
					t.Check("a tap with the ring not full does nothing", type(answer) == "table" and answer.Ok == false and answer.Error == "NotReady", if type(answer) == "table" then tostring(answer.Error) else "no answer")
					t.Wait(0.3)
					t.Check("and changes nothing", lead:GetAttribute("Ready") == before and lead:GetAttribute("Armed") == nil)
					pulseWatch:Disconnect()
					readyWatch:Disconnect()
					actionWatch:Disconnect()
					-- Auto back on, on its toggle: a full ring goes by itself again.
					Button.Press(auto)
					t.Check("its toggle turns Auto back on", waitFor(t, 2, function(): boolean
						return me:GetAttribute("SignatureAuto") ~= false
					end))
				end)
				Net.Client.Invoke("Signature", "Auto", true)
				t.Server("FightSpawn")
				if not ok then
					error(err, 0)
				end
			end,
		},
	}
end

return SignatureCases
