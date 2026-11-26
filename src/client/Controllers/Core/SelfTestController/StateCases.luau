--!strict
-- StateCases (client, Studio only): the element states in play (AR48; docs/design.md, "States in a fight";
-- Config.Combat.States), a list of its own that joins Cases in the runner. The player's lead, made to hit in each element
-- by turns (NL_Debug LeadElement: its own block but for the element), presses its combo at the replay's brawler, and what
-- each state leaves is read off the brawler: a burn's time and its ticks between hits, a chill that slows the brawler's
-- swing and freezes it for its time, with no chill during the lock after, a shock's time, a sap's. The brawler's own Void
-- hits leave the lead no sap (research, 2026-11-23). Each state's look (AR48's rows) is read off the brawler's view while
-- its rows are in: worn while the state holds, a chill's by the third its fill is in, frame by frame, a freeze's break when
-- it ran its time, and the parts a shock's arcs ride on the body.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Actions = require(Shared.Definitions.Actions)
local Enemies = require(Shared.Definitions.Enemies)
local Combat = require(Shared.Config.Combat)
local EffectsConfig = require(Shared.Config.Effects)
local Fight = require(Shared.Rules.Fight)
local FighterController = require(script.Parent.Parent.Parent.Main.FighterController)
local Effects = require(script.Parent.Parent.Parent.Main.FighterController.Effects)

local StateCases = {}

local SLACK = 0.25 -- seconds a time read on this screen may sit off the server's: a hit's trip and a frame
local MISS = 3 -- frames a chill's look may lag its third on this screen: the look's clock and this loop's, a frame apart

-- A state's look is drawn: its rows in and its switch on (Config.Effects.Lasting).
local function shows(name: string?): boolean
	return name ~= nil and EffectsConfig.Lasting[name] == true and (EffectsConfig.Rows :: any)[name] ~= nil
end

-- This player's lead's body, or nil.
local function myLead(): Model?
	local fighters = workspace:FindFirstChild("Fighters")
	for _, model in (if fighters then fighters:GetChildren() else {}) do
		if model:IsA("Model") and model:GetAttribute("Side") == "Lead" and model:GetAttribute("Owner") == Players.LocalPlayer.UserId then
			return model
		end
	end
	return nil
end

-- What one element's turn saw on the brawler and the lead.
type Seen = {
	Hits: number, -- the lead's hits landed on the brawler
	FirstHit: number?, -- server time, as this screen received it
	Burning: number?, -- the brawler's Burning, first seen, and when
	BurningAt: number?,
	Ticked: boolean, -- its health fell with no hit on it just before: a burn's tick
	Rates: { { Rate: number, Want: number } }, -- the brawler's ActionRate at each of its presses, and its chill's rate then
	FreezeLook: string?, -- its first stun's look, how long the stun was set for, and when it ends
	FreezeFor: number?,
	FreezeEnds: number?,
	ChillAfter: number?, -- the first chill's ChillAt after that freeze
	Chilled: boolean,
	Shocked: number?,
	ShockedAt: number?,
	Sapped: number?,
	SappedAt: number?,
	LeadSapped: boolean, -- the lead ever wore a sap
	Looks: { [string]: boolean }, -- every look its view wore
	ChillSteps: { [number]: boolean }, -- the chill's thirds whose look it wore
	ChillMiss: number, -- the most frames in a row its chill's look wasn't its third's
	Broke: boolean, -- a freeze's break played on it after its stun
	ArcsMissing: { string }?, -- the parts a shock's arcs ride that its body lacks, read when the shock first showed
}

-- One element's turn: the lead hits in `element`, pressing `combo` every `every` seconds at the replay's brawler, for
-- `seconds`; the replay stopped after.
local function turn(t: any, lead: Model, element: string, combo: Actions.Action, every: number, seconds: number): Seen?
	local set = t.Server("LeadElement", element)
	t.Check(`{element}: the lead hits in {element}`, type(set) == "table" and set.Ok == true and set.Element == element, if type(set) == "table" then tostring(set.Error) else tostring(set))
	local seen: Seen = { Hits = 0, Ticked = false, Rates = {}, Chilled = false, LeadSapped = false, Looks = {}, ChillSteps = {}, ChillMiss = 0, Broke = false }
	local chillLooks = Combat.States.Chill.Looks
	local missed = 0
	local brokeWas: any = false -- the view's Broke when its stun began; false until then
	local brawler: Model? = nil
	local lastHit = -math.huge -- os.clock() of the last hit on the brawler
	local onHit = Net.Client.On("Hit", function(hit: any)
		if type(hit) == "table" and hit.A == lead and typeof(hit.T) == "Instance" and (hit.T :: Instance):GetAttribute("Def") == "brawler" then
			brawler = hit.T :: Model
			lastHit = os.clock()
			if not hit.Dodged then
				seen.Hits += 1
				seen.FirstHit = seen.FirstHit or workspace:GetServerTimeNow()
			end
		end
	end)
	local started = t.Server("Replay", combo.Id, every, "brawler")
	local ok = type(started) == "table" and started.Ok == true
	t.Check(`{element}: the replay presses {combo.Id} at a brawler`, ok, if type(started) == "table" then tostring(started.Error) else tostring(started))
	local watched: { RBXScriptConnection } = {}
	local hooked: Model? = nil
	local health: number? = nil
	local stunSeen = false
	local began = os.clock()
	while ok and os.clock() - began < seconds do
		RunService.Heartbeat:Wait()
		local now = workspace:GetServerTimeNow()
		if lead:GetAttribute("Sapped") ~= nil then
			seen.LeadSapped = true
		end
		local body = brawler
		if body == nil then
			continue
		end
		if hooked ~= body then
			hooked = body
			table.insert(watched, body:GetAttributeChangedSignal("ActionAt"):Connect(function()
				local at = body:GetAttribute("ActionAt")
				if body:GetAttribute("Action") ~= "" and type(at) == "number" then
					local rate = body:GetAttribute("ActionRate")
					local fill, chillAt = body:GetAttribute("Chill"), body:GetAttribute("ChillAt")
					local now = if type(fill) == "number" and type(chillAt) == "number" then Fight.ChillNow(Combat.States.Chill, { Fill = fill, At = chillAt }, at) else 0
					table.insert(seen.Rates, { Rate = if type(rate) == "number" then rate else 1, Want = Fight.ChillRate(Combat.States.Chill, now) })
				end
			end))
		end
		local burning = body:GetAttribute("Burning")
		if seen.Burning == nil and type(burning) == "number" then
			seen.Burning, seen.BurningAt = burning, now
		end
		local h = body:GetAttribute("Health")
		if type(h) == "number" then
			if health and h < health - 1e-6 and os.clock() - lastHit > 0.12 then
				seen.Ticked = true
			end
			health = h
		end
		local state, look, untilTime = body:GetAttribute("State"), body:GetAttribute("StunLook"), body:GetAttribute("StateUntil")
		local view = FighterController.Views[body]
		if state == "Stun" and not stunSeen and type(untilTime) == "number" then
			stunSeen = true
			seen.FreezeLook, seen.FreezeFor, seen.FreezeEnds = if type(look) == "string" then look else nil, untilTime - now, untilTime
			brokeWas = if view then view.Broke else nil
		end
		if view then
			for name in view.Looks do
				seen.Looks[name] = true
			end
			if brokeWas ~= false and view.Broke ~= nil and view.Broke ~= brokeWas then
				seen.Broke = true
			end
			-- the chill's look against the third its fill is in, by the same rule
			local fillNow, fillAt = body:GetAttribute("Chill"), body:GetAttribute("ChillAt")
			local step = if state ~= "Down" and type(fillNow) == "number" and type(fillAt) == "number"
				then Fight.ChillStep(Fight.ChillNow(Combat.States.Chill, { Fill = fillNow, At = fillAt }, now), #chillLooks)
				else 0
			local right = true
			for i, name in chillLooks do
				local on = view.Looks[name] ~= nil
				if on then
					seen.ChillSteps[i] = true
				end
				if shows(name) and on ~= (i == step) then
					right = false
				end
			end
			missed = if right then 0 else missed + 1
			seen.ChillMiss = math.max(seen.ChillMiss, missed)
		end
		local chill, chillAt = body:GetAttribute("Chill"), body:GetAttribute("ChillAt")
		if type(chill) == "number" and chill > 0 then
			seen.Chilled = true
			if seen.FreezeEnds and seen.ChillAfter == nil and type(chillAt) == "number" and chillAt >= (seen.FreezeEnds :: number) then
				seen.ChillAfter = chillAt
			end
		end
		local shocked = body:GetAttribute("Shocked")
		if seen.Shocked == nil and type(shocked) == "number" then
			seen.Shocked, seen.ShockedAt = shocked, now
			-- the parts its arcs ride, as Rows finds them: a part or an attachment of that name
			local shockLook = Combat.States.Shock.Look
			local rows = if shockLook then (EffectsConfig.Rows :: any)[shockLook] :: EffectsConfig.Rows? else nil
			local missing = {}
			for _, row in (if rows then rows.Rows else {}) :: { [string]: EffectsConfig.Row } do
				local part = if row.Body then body:FindFirstChild(row.Body, true) else nil
				if row.Body and not (part and (part:IsA("BasePart") or part:IsA("Attachment"))) and not table.find(missing, row.Body) then
					table.insert(missing, row.Body)
				end
			end
			seen.ArcsMissing = missing
		end
		local sapped = body:GetAttribute("Sapped")
		if seen.Sapped == nil and type(sapped) == "number" then
			seen.Sapped, seen.SappedAt = sapped, now
		end
	end
	onHit:Disconnect()
	for _, c in watched do
		c:Disconnect()
	end
	t.Server("Replay")
	t.Wait(0.5)
	t.Check(`{element}: the lead's hits land on the brawler`, seen.Hits > 0, `{seen.Hits}`)
	return if ok then seen else nil
end

function StateCases.Cases(): { any }
	return {
		{
			Name = "Fight: the element states (AR48): a burn, a chill and its freeze, a shock and a sap, as each element's hit leaves them",
			Run = function(t: any)
				local lead = myLead()
				t.Check("a lead to hit with", lead ~= nil)
				if lead == nil then
					return
				end
				local def = lead:GetAttribute("Def")
				local combo: Actions.Action? = nil
				for _, action in Actions.KitOf(if type(def) == "string" then def else "") do
					if action.Cooldown == 0 and next(action.Hits) ~= nil then
						combo = action
						break
					end
				end
				t.Check("its combo", combo ~= nil, tostring(def))
				if combo == nil then
					return
				end
				local states = Combat.States
				local every = combo.Length + 0.4
				local brawlerKind = Enemies.ById.brawler and Enemies.ById.brawler.Kind or "Ordinary"

				-- Fire: a burn, its time from the hit, and its ticks between hits.
				local fire = turn(t, lead, "Fire", combo, every, every + states.Burn.Seconds * 0.6)
				if fire then
					t.Check("Fire: the brawler burns", fire.Burning ~= nil)
					t.Check("for the burn's time from the hit", fire.Burning ~= nil and fire.FirstHit ~= nil and math.abs((fire.Burning :: number) - (fire.BurningAt :: number) - states.Burn.Seconds) < SLACK,
						if fire.Burning and fire.BurningAt then `{(fire.Burning :: number) - (fire.BurningAt :: number)} s` else "none")
					t.Check("its health falls between hits: the burn's ticks", fire.Ticked)
					if shows(states.Burn.Look) then
						t.Check(`it wears the burn's look, {states.Burn.Look}`, fire.Looks[states.Burn.Look] == true)
					end
				end

				-- Frost: a chill that slows the brawler's swing, then a freeze for its time, and no chill in the lock after.
				local frozenFor = states.Freeze.Seconds * math.clamp(Combat.Stun.Share[brawlerKind] or 1, 0, 1)
				local frost = turn(t, lead, "Frost", combo, every, every * 2 + frozenFor + Combat.Stun.Lock + 1.5)
				if frost then
					t.Check("Frost: the brawler chills", frost.Chilled)
					local slowed, kept, said = false, true, {}
					for _, press in frost.Rates do
						slowed = slowed or press.Rate < 1 - 1e-3
						kept = kept and math.abs(press.Rate - press.Want) < 1e-3
						table.insert(said, string.format("%.3f for %.3f", press.Rate, press.Want))
					end
					t.Check("each of its swings runs at its chill's rate as it began", #frost.Rates > 0 and kept, table.concat(said, ", "))
					t.Check("one begun chilled runs slower", slowed, table.concat(said, ", "))
					t.Check("a full chill freezes it: a stun in the ice's look", frost.FreezeLook == states.Freeze.Look, tostring(frost.FreezeLook))
					t.Check(`for the freeze's time ({frozenFor} s)`, frost.FreezeFor ~= nil and math.abs((frost.FreezeFor :: number) - frozenFor) < SLACK, tostring(frost.FreezeFor))
					t.Check("no chill builds during the lock after it", frost.FreezeEnds ~= nil and (frost.ChillAfter == nil or (frost.ChillAfter :: number) >= (frost.FreezeEnds :: number) + Combat.Stun.Lock - 1e-3),
						if frost.ChillAfter and frost.FreezeEnds then `{(frost.ChillAfter :: number) - (frost.FreezeEnds :: number)} s after` else "none after")
					t.Check("and it chills again once the lock is over", frost.ChillAfter ~= nil)
					local chillLooks = states.Chill.Looks
					if shows(chillLooks[1]) and shows(chillLooks[2]) then
						t.Check("it wears the chill's first third's look, then its second's", frost.ChillSteps[1] == true and frost.ChillSteps[2] == true,
							`{frost.ChillSteps[1]}, {frost.ChillSteps[2]}`)
					end
					t.Check(`each frame, the chill's look is its third's (at most {MISS} frames behind)`, frost.ChillMiss <= MISS, `{frost.ChillMiss} frames`)
					if shows(states.Freeze.Look) then
						t.Check(`the freeze wears the ice, {states.Freeze.Look}`, frost.Looks[states.Freeze.Look] == true)
					end
					if (EffectsConfig.Rows :: any)[states.Freeze.Break] ~= nil then
						t.Check(`the freeze that ran its time breaks, {states.Freeze.Break}`, frost.Broke)
						-- its ending hit (research's AR48 must-fix, 21:40): a hit inside the freeze's last Window plays the break,
						-- once, in place of its spark; one mid-freeze keeps its spark, as does a body not frozen
						local w, at = states.Freeze.Window, workspace:GetServerTimeNow()
						local ending: any = { Model = lead, StunLook = states.Freeze.Look, StunEnds = at + w / 2 }
						t.Check("a hit in a freeze's last window plays the break in place of its spark", FighterController.Breaks(ending)
							and ending.Broke ~= nil and ending.BrokeFor == ending.StunEnds)
						local first = ending.Broke
						t.Check("a second hit just after shows no spark and no second break", FighterController.Breaks(ending) and ending.Broke == first)
						local mid: any = { Model = lead, StunLook = states.Freeze.Look, StunEnds = at + states.Freeze.Seconds / 2 }
						t.Check("a hit mid-freeze keeps its spark", not FighterController.Breaks(mid) and mid.Broke == nil)
						t.Check("a hit on a body not frozen keeps its spark", not FighterController.Breaks({ Model = lead } :: any))
					end
				end

				-- Storm: a shock for its time.
				local storm = turn(t, lead, "Storm", combo, every, combo.Length + 0.5)
				if storm then
					t.Check("Storm: the brawler is shocked", storm.Shocked ~= nil)
					t.Check("for the shock's time from the hit", storm.Shocked ~= nil and math.abs((storm.Shocked :: number) - (storm.ShockedAt :: number) - states.Shock.Seconds) < SLACK,
						if storm.Shocked then `{(storm.Shocked :: number) - (storm.ShockedAt :: number)} s` else "none")
					local shockLook = states.Shock.Look
					if shockLook and shows(shockLook) then
						t.Check(`it wears the shock's look, {shockLook}`, storm.Looks[shockLook] == true)
						t.Check("its body has every part the arcs ride", storm.ArcsMissing ~= nil and #(storm.ArcsMissing :: { string }) == 0,
							if storm.ArcsMissing then table.concat(storm.ArcsMissing :: { string }, ", ") else "not read")
					end
				end

				-- Void: a sap on the brawler; the brawler's own Void leaves the lead none.
				local void = turn(t, lead, "Void", combo, every, every + 1)
				if void then
					t.Check("Void: the brawler is sapped", void.Sapped ~= nil)
					t.Check("for the sap's time from the hit", void.Sapped ~= nil and math.abs((void.Sapped :: number) - (void.SappedAt :: number) - states.Sap.Seconds) < SLACK,
						if void.Sapped then `{(void.Sapped :: number) - (void.SappedAt :: number)} s` else "none")
					if shows(states.Sap.Look) then
						t.Check(`it wears the sap's look, {states.Sap.Look}`, void.Looks[states.Sap.Look] == true)
					end
				end
				local sappedLead = (fire and fire.LeadSapped) or (frost and frost.LeadSapped) or (storm and storm.LeadSapped) or (void and void.LeadSapped)
				t.Check("a Shade's Void saps nothing: the lead never wore a sap", not sappedLead)
				t.Server("LeadElement", nil)
			end,
		},
		{
			-- AR48's install (research, 21:53): Burn, Freeze's break in a hit's spark's place, and Sap, in play from the
			-- player's camera, each held still at its moment for a capture: the effects' clock and every emitter stopped,
			-- NL_TakeStep's value naming what's held until the driver sets it to "Next". The break is held 3 of its frames
			-- after a hit lands in a freeze's last Window, so the still shows the break where the hit's spark would be.
			Name = "Take: AR48's states in play, a burn, a freeze's break in a hit's spark's place and a sap, each held for a still, for research",
			Manual = true,
			Stay = true,
			Run = function(t: any)
				local lead = myLead()
				local def = if lead then lead:GetAttribute("Def") else nil
				local combo: Actions.Action? = nil
				for _, action in Actions.KitOf(if type(def) == "string" then def else "") do
					if action.Cooldown == 0 and next(action.Hits) ~= nil then
						combo = action
					end
				end
				t.Check("a lead and its combo", lead ~= nil and combo ~= nil)
				if lead == nil or combo == nil then
					return
				end
				local step = Instance.new("StringValue")
				step.Name = "NL_TakeStep"
				step.Value = "Ready"
				step.Parent = ReplicatedStorage
				local function hold(name: string)
					local stopped: { [ParticleEmitter]: number } = {}
					Effects.TimeScale = 0
					for _, emitter in workspace:WaitForChild("Fighters"):GetDescendants() do
						if emitter:IsA("ParticleEmitter") then
							stopped[emitter] = emitter.TimeScale
							emitter.TimeScale = 0
						end
					end
					step.Value = name
					local began = os.clock()
					while step.Value ~= "Next" and os.clock() - began < 300 do
						RunService.Heartbeat:Wait()
					end
					Effects.TimeScale = 1
					for emitter, was in stopped do
						emitter.TimeScale = was
					end
				end
				-- One element at `foe` till `moment` says so (held by `name`), or 30 s: whether it was held.
				local freeze = Combat.States.Freeze
				local function play(element: string, foe: string, name: string, moment: (body: Model, now: number, inWindow: boolean) -> boolean): boolean
					t.Server("LeadElement", element)
					local body: Model? = nil
					local inWindow = false
					local onHit = Net.Client.On("Hit", function(hit: any)
						if type(hit) == "table" and hit.A == lead and not hit.Dodged and typeof(hit.T) == "Instance" and (hit.T :: Instance):GetAttribute("Def") == foe then
							local target = hit.T :: Model
							local ends = target:GetAttribute("StateUntil")
							body = target
							inWindow = inWindow or (target:GetAttribute("StunLook") == freeze.Look and type(ends) == "number" and workspace:GetServerTimeNow() >= ends - freeze.Window)
						end
					end)
					t.Server("Replay", (combo :: Actions.Action).Id, 1.2, foe)
					local began, held = os.clock(), false
					while os.clock() - began < 30 do
						RunService.Heartbeat:Wait()
						if body and moment(body :: Model, workspace:GetServerTimeNow(), inWindow) then
							held = true
							break
						end
					end
					onHit:Disconnect()
					if held and name == "Break" then
						Effects.TimeScale = 0.05 -- its third frame: 3/60 s of its clock at a twentieth
						task.wait(3 / 60 / 0.05)
					end
					if held then
						hold(name)
					end
					t.Server("Replay")
					t.Check(`{name}: held at its moment`, held)
					return held
				end
				local ok, problem = pcall(function()
					local burnFrom: number? = nil
					play("Fire", "brawler", "Burn", function(body: Model, now: number): boolean
						local burning = body:GetAttribute("Burning")
						burnFrom = if type(burning) == "number" and burning > now then burnFrom or now else nil
						return burnFrom ~= nil and now - burnFrom >= 0.8
					end)
					play("Frost", "brawler", "Break", function(_body: Model, _now: number, inWindow: boolean): boolean
						return inWindow
					end)
					local sapFrom: number? = nil
					play("Void", "lamplighter", "Sap", function(body: Model, now: number): boolean
						local sapped = body:GetAttribute("Sapped")
						sapFrom = if type(sapped) == "number" and sapped > now then sapFrom or now else nil
						return sapFrom ~= nil and now - sapFrom >= 1
					end)
				end)
				Effects.TimeScale = 1
				t.Server("Replay")
				t.Server("LeadElement")
				step:Destroy()
				t.Check("it ran", ok, tostring(problem))
			end,
		},
	}
end

return StateCases
