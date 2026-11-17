--!strict
-- Sound cases (client, during a playtest): AR13's six cues on the audio graph (FighterController/Cues; Config.Cues):
-- every take loaded, each cue heard through its bus, a beat's cue silent until its lead, the voice cap, the Shades'
-- duck, and a press's wind-up and touch heard in a replay; and AR39's engine: a library take's slice and fades, a start
-- on the mixer's clock, the counted miss, the A/B. Apart from Cases, which is at the type checker's limit.

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
		{
			Name = "Sound: AR39's engine: a slice of a file with its fades, a start on the mixer's clock, no play missed, and a pilot's arrangement switched in",
			Run = function(t: any)
				local camera = workspace.CurrentCamera
				local config = CuesConfig :: any
				local source = CuesConfig.Takes.ShadeSwipe[1]
				-- a slice of one of our own takes, as a library take is given: 0.08 to 0.28 s of its file
				local slice = { Id = source.Id, Seconds = 0.2, Peak = 0.05, From = 0.08, To = 0.28, In = 0.05, Out = 0.06 }
				local cue = { Layers = { { Takes = "NL_TestSlice", At = 0, Volume = 1 } }, Bus = "Shade", Pitch = { 1, 1 }, Volume = { 1, 1 }, Voices = 1, Near = 30, Range = 160 }
				local missedBefore = Cues.Missed()
				config.Takes.NL_TestSlice = { slice }
				config.Cues.NL_TestSlice = cue
				Cues.Try("NL_TestSlice", cue :: any)
				local voice = Cues.Voice("NL_TestSlice", 1, 1)
				local analyzer, done = listen("Shade")
				if voice == nil or analyzer == nil then
					t.Check("the test's cue is built on the Shades' bus", false)
				else
					t.Check("its voice loads", waitFor(t, 8, function(): boolean
						return voice.IsReady
					end))
					t.Check("its player is held to its slice of the file", math.abs(voice.PlaybackRegion.Min - slice.From) < 1e-3 and math.abs(voice.PlaybackRegion.Max - slice.To) < 1e-3, tostring(voice.PlaybackRegion))
					local full = CuesConfig.Volume * CuesConfig.Trim
					-- played now: from its From, rising from silence to full, falling to silence by its end, never past its To
					hush(analyzer)
					local began = os.clock()
					Cues.Play("NL_TestSlice", camera.CFrame.Position)
					local first, top, furthest, heard = voice.Volume, 0, 0, 0
					local startedAt = voice.TimePosition
					while os.clock() - began < slice.Seconds + 0.3 do
						RunService.Heartbeat:Wait()
						top = math.max(top, voice.Volume)
						furthest = math.max(furthest, voice.TimePosition)
						heard = math.max(heard, analyzer.PeakLevel)
					end
					t.Check("it starts at its From, silent", math.abs(startedAt - slice.From) < 0.02 and first < full * 0.5, `at {startedAt}, volume {first}`)
					t.Check("it rises to its full volume and is heard", math.abs(top - full) < 1e-3 and heard > QUIET, `top {top} of {full}, peak {heard}`)
					t.Check("it falls to silence by its end, never past its To", voice.Volume < full * 0.05 and furthest <= slice.To + 0.03, `volume {voice.Volume}, furthest {furthest}`)
					-- a start ahead: scheduled on the mixer's clock, silent and still until then
					hush(analyzer)
					local into = 0.5
					began = os.clock()
					Cues.Play("NL_TestSlice", camera.CFrame.Position, { In = into })
					local moved: number? = nil
					while os.clock() - began < into + 0.4 do
						RunService.Heartbeat:Wait()
						if moved == nil and voice.TimePosition > slice.From + 1e-3 then
							moved = os.clock() - began
						end
					end
					t.Check("a start 0.5 s ahead begins then, on the mixer's clock", moved ~= nil and math.abs(moved - into) < 0.12, tostring(moved))
					-- a start ahead taken back by a play now (one voice): it plays now, and never again at the old time
					hush(analyzer)
					began = os.clock()
					Cues.Play("NL_TestSlice", camera.CFrame.Position, { In = 0.6 })
					Cues.Play("NL_TestSlice", camera.CFrame.Position)
					local now = loudest(analyzer, began, 0, slice.Seconds + 0.1)
					local again = loudest(analyzer, began, 0.5, 0.95)
					t.Check("a start 0.6 s ahead replaced by a play now: heard now, never then", now > QUIET and again <= QUIET, string.format("now %.4f, then %.4f", now, again))
					-- a start the mixer already holds can't be taken back: its voice waits it out, the play that finds none is
					-- counted, and the voice plays again after
					hush(analyzer)
					local counted = Cues.Missed()
					began = os.clock()
					Cues.Play("NL_TestSlice", camera.CFrame.Position, { In = CuesConfig.Lookahead * 0.6 })
					Cues.Play("NL_TestSlice", camera.CFrame.Position)
					local neither = loudest(analyzer, began, 0, 0.3)
					t.Check("a start inside the lookahead replaced: its voice held, the play counted as missed, nothing heard twice", Cues.Missed() == counted + 1 and neither <= QUIET, `missed {Cues.Missed() - counted}, peak {neither}`)
					missedBefore += 1
					began = os.clock()
					Cues.Play("NL_TestSlice", camera.CFrame.Position)
					t.Check("and its voice plays again once that start has passed", loudest(analyzer, began, 0, slice.Seconds + 0.1) > QUIET)
					-- the A/B: the pilot's cue as one of its arrangements, then as it was, by the tune
					local use = t.Server("Tune", "Cues.Use.LightHit")
					local arranged = config.Arrangements.LightHit
					config.Arrangements.LightHit = { Test = cue }
					Cues.Try("LightHit@Test", cue :: any)
					local variant = Cues.Voice("LightHit@Test", 1, 1)
					t.Check("the arrangement's voice loads", variant ~= nil and waitFor(t, 8, function(): boolean
						return (variant :: AudioPlayer).IsReady
					end))
					t.Server("Tune", "Cues.Use.LightHit", "Test")
					t.Check("the tune reaches the client", waitFor(t, 3, function(): boolean
						return config.Use.LightHit == "Test"
					end), tostring(config.Use.LightHit))
					if variant then
						variant:Stop()
						Cues.Play("LightHit", camera.CFrame.Position)
						t.Wait(0.1)
						t.Check("LightHit plays its arrangement while Use names it", variant.TimePosition > slice.From + 1e-3 or variant.IsPlaying, tostring(variant.TimePosition))
						t.Wait(0.5)
						t.Server("Tune", "Cues.Use.LightHit", "Old")
						waitFor(t, 3, function(): boolean
							return config.Use.LightHit == "Old"
						end)
						variant:Stop()
						variant.TimePosition = slice.From
						Cues.Play("LightHit", camera.CFrame.Position)
						local old = Cues.Playing("LightHit")
						t.Wait(0.1)
						t.Check("and the cue as it was once Use says Old", config.Use.LightHit == "Old" and old > 0 and not variant.IsPlaying and math.abs(variant.TimePosition - slice.From) < 1e-3, `use {config.Use.LightHit}, playing {old}, at {variant.TimePosition}`)
					end
					t.Server("Tune", "Cues.Use.LightHit", if type(use) == "string" then use else "Old")
					config.Arrangements.LightHit = arranged
					Cues.Try("LightHit@Test", nil)
				end
				t.Equal("no play missed its take", Cues.Missed(), missedBefore)
				done()
				Cues.Try("NL_TestSlice", nil)
				config.Cues.NL_TestSlice = nil
				config.Takes.NL_TestSlice = nil
			end,
		},
		{
			Name = "Sound: AR39's arrangements: each bus ends in its limiter, which holds, and every arrangement is heard through its pilot's bus at its matched level",
			Run = function(t: any)
				local camera = workspace.CurrentCamera
				local config = CuesConfig :: any
				-- ten studs ahead: an emitter on the listener itself reads 8.5 dB down (measured 2026-11-17)
				local ahead = camera.CFrame:PointToWorldSpace(Vector3.new(0, 0, -10))
				local out = game:GetService("SoundService"):FindFirstChild("NL_CuesOut")
				local buses: { [string]: boolean } = {}
				for _, cue in CuesConfig.Cues do
					buses[cue.Bus] = true
				end
				local function wired(from: Instance?, to: Instance?): boolean
					for _, w in (if to then to:GetChildren() else {}) do
						if w:IsA("Wire") and w.SourceInstance == from and w.TargetInstance == to then
							return true
						end
					end
					return false
				end
				for bus in buses do
					local limiter, fader = Cues.Limiter(bus), Cues.Fader(bus)
					local is = limiter ~= nil and limiter:IsA("AudioLimiter")
					t.Check(`the {bus} bus: fader, limiter, out, and never past the limiter`, is and wired(fader, limiter) and wired(limiter, out) and not wired(fader, out))
					if limiter and limiter:IsA("AudioLimiter") then
						t.Check(`the {bus} bus's limiter takes Config.Cues.Limiter's values`, math.abs(limiter.MaxLevel - CuesConfig.Limiter.MaxLevel) < 1e-3 and math.abs(limiter.Release - CuesConfig.Limiter.Release) < 1e-3 and not limiter.Bypass, `{limiter.MaxLevel} {limiter.Release}`)
					end
				end
				-- it holds: a take at its file's own level against a limit 12 dB under full scale (quiet on purpose)
				local limiter = Cues.Limiter("Shade")
				local before, doneBefore = listen("Shade")
				if limiter and limiter:IsA("AudioLimiter") and before then
					local after = Instance.new("AudioAnalyzer")
					local w = Instance.new("Wire")
					w.SourceInstance = limiter
					w.TargetInstance = after
					w.Parent = after
					after.Parent = limiter
					local cue = { Layers = { { Takes = "ShadeSwipe", At = 0, Volume = 1 / (CuesConfig.Volume * CuesConfig.Trim) } }, Bus = "Shade", Pitch = { 1, 1 }, Volume = { 1, 1 }, Voices = 1, Near = 30, Range = 160 }
					config.Cues.NL_TestHot = cue
					Cues.Try("NL_TestHot", cue :: any)
					local voice = Cues.Voice("NL_TestHot", 1, 1)
					waitFor(t, 8, function(): boolean
						return voice ~= nil and voice.IsReady
					end)
					local limit = 10 ^ (-12 / 20)
					limiter.MaxLevel = -12
					hush(before)
					local began = os.clock()
					Cues.Play("NL_TestHot", ahead)
					local into: number = 0
					local held: number = 0
					while os.clock() - began < 0.6 do
						RunService.Heartbeat:Wait()
						into = math.max(into, before.PeakLevel)
						held = math.max(held, after.PeakLevel)
					end
					limiter.MaxLevel = CuesConfig.Limiter.MaxLevel
					t.Check("a take over the limit goes in over it and comes out at it", into > limit * 1.5 and held > QUIET and held <= limit * 1.03, string.format("in %.3f, out %.3f, the limit %.3f", into, held, limit))
					after:Destroy()
					Cues.Try("NL_TestHot", nil)
					config.Cues.NL_TestHot = nil
				else
					t.Check("the Shades' bus has its limiter", false)
				end
				doneBefore()
				-- every arrangement, switched in as the A/B does it
				local missedBefore = Cues.Missed()
				for name, set in CuesConfig.Arrangements do
					local use = t.Server("Tune", `Cues.Use.{name}`)
					local variants: { string } = {}
					for variant: string in set :: { [string]: CuesConfig.Cue } do
						table.insert(variants, variant)
					end
					table.sort(variants)
					for _, variant in variants do
						local cue = set[variant]
						local analyzer, done = listen(cue.Bus)
						t.Server("Tune", `Cues.Use.{name}`, variant)
						local switched = waitFor(t, 3, function(): boolean
							return config.Use[name] == variant
						end)
						if analyzer and switched then
							hush(analyzer)
							local lead = SoundRule.Ahead(cue)
							local began = os.clock()
							local played = Cues.Play(name, ahead, { In = lead, Strength = 1 })
							local sounding = Cues.Playing(name)
							-- its first layer's player, against that take's level times the A/B's match, capped as a player is
							local takes = (CuesConfig.Takes :: { [string]: { CuesConfig.Take } })[cue.Layers[1].Takes]
							local match = SoundRule.Match(name, variant)
							local heard: number = 0
							local most: number = 0
							while os.clock() - began < lead + 0.5 do
								RunService.Heartbeat:Wait()
								heard = math.max(heard, analyzer.PeakLevel)
								for k, take in takes do
									for nth = 1, math.max(cue.Voices, 1) do
										local voice = Cues.Voice(`{name}@{variant}`, 1, k, nth)
										if voice and voice.IsPlaying then
											most = math.max(most, voice.Volume / math.min(SoundRule.Level(cue.Layers[1], take, 1, 1) * match, 3))
										end
									end
								end
							end
							t.Check(`{name} as {variant}: heard through the {cue.Bus} bus`, played and sounding > 0 and heard > QUIET, string.format("peak %.4f, %d sounding", heard, sounding))
							t.Check(`{name} as {variant}: its player at its level times its match (x{string.format("%.2f", match)})`, most <= 1.001 and most >= math.min(cue.Volume[1], cue.Volume[2]) - 0.02, string.format("%.3f of it", most))
						else
							t.Check(`{name} as {variant}: switched in`, false, tostring(config.Use[name]))
						end
						done()
					end
					t.Server("Tune", `Cues.Use.{name}`, if type(use) == "string" then use else "Old")
					t.Check(`{name} is back on what it played`, waitFor(t, 3, function(): boolean
						return config.Use[name] == (if type(use) == "string" then use else "Old")
					end), tostring(config.Use[name]))
				end
				t.Equal("no play missed its take", Cues.Missed(), missedBefore)
			end,
		},
	}
end

return SoundCases
