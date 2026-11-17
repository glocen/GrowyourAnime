--!strict
-- Sound cases (client, during a playtest): AR13's six cues on the audio graph (FighterController/Cues; Config.Cues):
-- every take loaded, each cue heard through its bus, a beat's cue silent until its lead, the voice cap, the Shades'
-- duck, and a press's wind-up and touch heard in a replay. Apart from Cases, which is at the type checker's limit.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Actions = require(Shared.Definitions.Actions)
local CuesConfig = require(Shared.Config.Cues)
local SoundRule = require(Shared.Rules.Sound)
local Cues = require(script.Parent.Parent.Parent.Main.FighterController.Cues)

local SoundCases = {}

local QUIET = 1e-4 -- an analyzer's peak at or under this is silence
local REPLAY_PAUSE = 5 -- seconds past the action before a second press, longer than the case waits, as Cases'

local function waitFor(t: any, seconds: number, ok: () -> boolean): boolean
	local began = os.clock()
	while os.clock() - began < seconds do
		if ok() then
			return true
		end
		t.Wait(0.1)
	end
	return ok()
end

-- An analyzer on a bus's fader, and how to take it off.
local function listen(bus: string): (AudioAnalyzer?, () -> ())
	local fader = Cues.Fader(bus)
	if fader == nil then
		return nil, function() end
	end
	local analyzer = Instance.new("AudioAnalyzer")
	analyzer.Name = "NL_SelfTestEar"
	local w = Instance.new("Wire")
	w.SourceInstance = fader
	w.TargetInstance = analyzer
	w.Parent = analyzer
	analyzer.Parent = fader
	return analyzer, function()
		analyzer:Destroy()
	end
end

-- The loudest peak `analyzer` reads between `from` and `to` seconds after `began`.
local function loudest(analyzer: AudioAnalyzer, began: number, from: number, to: number): number
	local peak = 0
	while os.clock() - began < to do
		RunService.Heartbeat:Wait()
		if os.clock() - began >= from then
			peak = math.max(peak, analyzer.PeakLevel)
		end
	end
	return peak
end

-- Waits for a bus to go quiet, so the next cue is heard alone.
local function hush(analyzer: AudioAnalyzer)
	local began, still = os.clock(), os.clock()
	while os.clock() - began < 3 do
		RunService.Heartbeat:Wait()
		if analyzer.PeakLevel > QUIET then
			still = os.clock()
		elseif os.clock() - still > 0.25 then
			return
		end
	end
end

local function myLead(): Model?
	local fighters = workspace:FindFirstChild("Fighters")
	for _, model in (if fighters then fighters:GetChildren() else {}) do
		if model:IsA("Model") and model:GetAttribute("Side") == "Lead" and model:GetAttribute("Owner") == Players.LocalPlayer.UserId then
			return model
		end
	end
	return nil
end

function SoundCases.Cases(): { any }
	return {
		{
			Name = "Sound: AR13's six cues, every take loaded, each heard through its bus",
			Run = function(t: any)
				local ready, all = 0, 0
				local loaded = waitFor(t, 10, function(): boolean
					ready, all = Cues.Ready()
					return all > 0 and ready == all
				end)
				t.Check("every take's voices loaded", loaded, `{ready} of {all}`)
				local camera = workspace.CurrentCamera
				for name, cue in CuesConfig.Cues do
					local analyzer, done = listen(cue.Bus)
					if analyzer == nil then
						t.Check(`{name}: its bus ({cue.Bus}) is built`, false)
						continue
					end
					hush(analyzer)
					local ahead = SoundRule.Ahead(cue)
					local began = os.clock()
					local played = Cues.Play(name, camera.CFrame.Position, { In = ahead, Strength = 1 })
					local heard = loudest(analyzer, began, 0, ahead + 0.5)
					t.Check(`{name}: heard through the {cue.Bus} bus`, played and heard > QUIET, string.format("peak %.4f", heard))
					done()
				end
			end,
		},
		{
			Name = "Sound: a beat's cue is silent until its lead, the voice cap holds, and the Shades duck",
			Run = function(t: any)
				local camera = workspace.CurrentCamera
				local swipe = CuesConfig.Cues.ShadeSwipe
				local analyzer, done = listen(swipe.Bus)
				if analyzer then
					hush(analyzer)
					local into = 0.6
					local began = os.clock()
					Cues.Play("ShadeSwipe", camera.CFrame.Position, { In = into })
					-- its earliest layer starts no sooner than its lead before the moment
					local early = loudest(analyzer, began, 0, into - SoundRule.Ahead(swipe) - 0.05)
					local late = loudest(analyzer, began, into - SoundRule.Ahead(swipe) + 0.05, into + 0.35)
					t.Check("the swipe is silent until its lead", early <= QUIET, string.format("peak %.4f", early))
					t.Check("and heard from it to the hit", late > QUIET, string.format("peak %.4f", late))
					done()
				else
					t.Check("the Shades' bus is built", false)
				end
				local burst = CuesConfig.Cues.ShadeBurst
				for _ = 1, burst.Voices + 2 do
					Cues.Play("ShadeBurst", camera.CFrame.Position)
				end
				t.Check(`a burst past its cap: {burst.Voices} at once`, Cues.Playing("ShadeBurst") == burst.Voices, tostring(Cues.Playing("ShadeBurst")))
				local shades, lead = Cues.Fader("Shade"), Cues.Fader("Lead")
				local duck = CuesConfig.Duck
				Cues.Duck()
				local down = if shades then shades.Volume else -1
				t.Check("the lead's hit ducks the Shades' bus", math.abs(down - 10 ^ (duck.Db / 20)) < 0.01, string.format("%.3f", down))
				t.Check("and not the lead's own", lead ~= nil and math.abs(lead.Volume - 1) < 1e-6)
				t.Wait(duck.Hold + duck.Release + 0.2)
				local back = if shades then shades.Volume else -1
				t.Check("and it comes back", math.abs(back - 1) < 0.01, string.format("%.3f", back))
			end,
		},
		{
			Name = "Sound: a heavy press winds up before its touch; a light one only touches",
			Run = function(t: any)
				local lead = myLead()
				local def = if lead then lead:GetAttribute("Def") else nil
				local kit = if type(def) == "string" then Actions.Kits[def] else nil
				t.Check("the player's lead and its kit", kit ~= nil, tostring(def))
				if kit == nil then
					return
				end
				local heavy: Actions.Action?, light: Actions.Action? = nil, nil
				for _, id in kit do
					local action = Actions.ById[id]
					local any = false
					for _, hit in (if action then action.Hits else {}) do
						any = any or hit.Heavy
					end
					if action and any and heavy == nil then
						heavy = action
					elseif action and not any and light == nil and next(action.Hits) ~= nil then
						light = action
					end
				end
				for _, pair in { { heavy, true }, { light, false } } do
					local action = pair[1] :: Actions.Action?
					if action == nil then
						t.Check(`the kit has a {if pair[2] then "heavy" else "light"} press`, false)
						continue
					end
					local started = t.Server("Replay", action.Id, action.Length + REPLAY_PAUSE)
					t.Check(`the replay presses {action.Id}`, type(started) == "table" and started.Ok == true)
					local wound: number?, struck: number?, tapped: number? = nil, nil, nil
					local began = os.clock()
					while os.clock() - began < action.Length + 1 do
						RunService.Heartbeat:Wait()
						local now = os.clock()
						wound = wound or (if Cues.Playing("HeavyWind") > 0 then now else nil)
						struck = struck or (if Cues.Playing("HeavyHit") > 0 then now else nil)
						tapped = tapped or (if Cues.Playing("LightHit") > 0 then now else nil)
					end
					t.Server("Replay")
					if pair[2] then
						t.Check(`{action.Id}: its wind-up heard`, wound ~= nil)
						t.Check(`{action.Id}: its heavy touch heard`, struck ~= nil)
						t.Check(`{action.Id}: the wind-up before the touch`, wound ~= nil and struck ~= nil and wound < struck, string.format("%.3f s before", (struck or 0) - (wound or 0)))
					else
						t.Check(`{action.Id}: its light touch heard`, tapped ~= nil)
						t.Check(`{action.Id}: no wind-up`, wound == nil)
					end
					t.Wait(1)
				end
			end,
		},
	}
end

return SoundCases
