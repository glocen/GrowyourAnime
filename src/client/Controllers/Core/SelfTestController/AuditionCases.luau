--!strict
-- AuditionCases (client, Studio only): the sound audition panel (docs/test-requests.md, TR42; Core/AuditionController), a
-- list of its own that joins the run apart from Cases (Cases is at the type checker's limit). TR42's cases: the panel isn't
-- built outside Studio; a candidate that fails to load is marked and skipped; changing the live sound never drops or
-- doubles a voice; "Old" brings today's cue back exactly. And the fair listen: every candidate of a cue at one loudness,
-- under the ceiling, with no spread. The candidates here are known library slices, so the cases don't need the finder's.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config.Audition)
local CuesConfig = require(Shared.Config.Cues)
local SoundRule = require(Shared.Rules.Sound)
local Cues = require(script.Parent.Parent.Parent.Main.FighterController.Cues)
local Audition = require(script.Parent.Parent.AuditionController)
local Helpers = require(script.Parent.Helpers)

local AuditionCases = {}

local PILOT = "LightHit"
local USE = CuesConfig.Use :: { [string]: string }

-- Two known library sounds as candidates: Haymaker's strike's slice (0.7 s, long enough to be heard across a switch) and
-- a hand slap from AR39's lists. Loud is set so each plays at volume 1 with no reference.
local LONG: Audition.Candidate = { Number = 1, Id = 9116673915, Title = "Test: Haymaker's strike", Author = "ProSoundEffects", From = 2.35, To = 3.05, Seconds = 0.7, Peak = 0.01, Out = 0.02, Loud = -30 }
local SHORT: Audition.Candidate = { Number = 2, Id = 9114773313, Title = "Test: a hand slap", Author = "ProSoundEffects", From = 0, To = 0.076, Seconds = 0.076, Peak = 0.005, Out = 0, Loud = -30 }
local BAD: Audition.Candidate = { Number = 3, Id = 1, Title = "Test: no sound at all", Author = "nobody", From = 0, To = 0.2, Seconds = 0.2, Peak = 0.01, Out = 0, Loud = -30 }

local function keyOf(c: Audition.Candidate): string
	return `{PILOT}@A{c.Id}`
end

-- Whether any voice of a key's layer 1 take 1 is playing.
local function sounding(key: string, voices: number): boolean
	for nth = 1, voices do
		local player = Cues.Voice(key, 1, 1, nth)
		if player and player.IsPlaying then
			return true
		end
	end
	return false
end

local function here(): Vector3
	local camera = workspace.CurrentCamera
	return camera.CFrame.Position + camera.CFrame.LookVector * Config.Preview
end

function AuditionCases.Cases(): { any }
	local waitFor = Helpers.waitFor
	return {
		{
			Name = "Audition: TR42, the panel isn't built outside Studio, and is in Studio once the finder's candidates are here",
			Run = function(t: any)
				local gui = Players.LocalPlayer:WaitForChild("PlayerGui")
				local before = #gui:GetChildren()
				local studio = Audition.Studio
				Audition.Studio = function(): boolean
					return false
				end
				local made = Audition.Mount()
				Audition.Studio = studio
				t.Check("outside Studio it mounts nothing", made == nil and #gui:GetChildren() == before)
				local has = ReplicatedStorage:FindFirstChild("NL_Audition") ~= nil
				t.Check("in Studio, the panel stands exactly when the finder's candidates are here", (gui:FindFirstChild("NL_Audition") ~= nil) == has, `candidates {has}`)
			end,
		},
		{
			Name = "Audition: TR42, a candidate that fails to load is marked and skipped, and the live sound stays",
			Run = function(t: any)
				local was, missed = USE[PILOT], Cues.Missed()
				local began = os.clock()
				local ok = Audition.Choose(PILOT, BAD, true)
				t.Check("it isn't made live", not ok and USE[PILOT] == was and Audition.Live(PILOT) ~= `A{BAD.Id}`, `use {USE[PILOT]}`)
				t.Check("it's marked as not loaded", Audition.Failed(PILOT, BAD.Id))
				local again = os.clock()
				t.Check("and skipped: a second tap does nothing, at once", not Audition.Choose(PILOT, BAD, true) and os.clock() - again < 0.05)
				t.Check("its voices are taken away", Cues.Voice(keyOf(BAD), 1, 1) == nil)
				t.Equal("no play missed", Cues.Missed(), missed)
				t.Check("within its load time", os.clock() - began < 6, string.format("%.1f s", os.clock() - began))
			end,
		},
		{
			Name = "Audition: TR42, changing the live sound never drops or doubles a voice, a candidate plays with no spread, and Old brings today's cue back exactly",
			Run = function(t: any)
				local was, missed = USE[PILOT], Cues.Missed()
				local voices = CuesConfig.Cues[PILOT].Voices
				local oldCue = CuesConfig.Cues[PILOT]
				local oldTakes = oldCue.Layers[1].Takes
				t.Check("the short one loads and goes live", Audition.Choose(PILOT, SHORT, true) and USE[PILOT] == `A{SHORT.Id}`)
				t.Check("the long one loads and goes live", Audition.Choose(PILOT, LONG, true) and USE[PILOT] == `A{LONG.Id}`)
				local set = CuesConfig.Arrangements[PILOT]
				local cue: CuesConfig.Cue? = if set then set[`A{LONG.Id}`] else nil
				t.Check("a candidate is one layer, its pilot's bus and voices, with no pitch or volume spread", cue ~= nil and #cue.Layers == 1
					and cue.Pitch[1] == 1 and cue.Pitch[2] == 1 and cue.Volume[1] == 1 and cue.Volume[2] == 1 and cue.Bus == oldCue.Bus and cue.Voices == voices)
				-- a hit on the long one, then the switch while it sounds
				Cues.Play(PILOT, here())
				t.Check("the hit plays the live one", waitFor(t, 0.5, function(): boolean
					return sounding(keyOf(LONG), voices)
				end) and Cues.Playing(keyOf(LONG)) == 1 and Cues.Playing(keyOf(SHORT)) == 0)
				t.Check("the switch to an already loaded one is at once", Audition.Choose(PILOT, SHORT, true) and USE[PILOT] == `A{SHORT.Id}`)
				t.Check("the sound playing before it isn't dropped", sounding(keyOf(LONG), voices) and Cues.Playing(keyOf(LONG)) == 1)
				Cues.Play(PILOT, here())
				t.Check("a hit after it plays the new one only, never both", Cues.Playing(keyOf(SHORT)) == 1 and Cues.Playing(keyOf(LONG)) == 1,
					`new {Cues.Playing(keyOf(SHORT))}, old {Cues.Playing(keyOf(LONG))}`)
				-- while a sound not yet made loads, hits keep the live one
				Audition.Forget(PILOT, LONG)
				Audition.Choose(PILOT, SHORT, true)
				local playing = Cues.Playing(keyOf(SHORT))
				task.spawn(Audition.Choose, PILOT, LONG, true)
				if USE[PILOT] == `A{SHORT.Id}` then
					Cues.Play(PILOT, here())
					t.Check("while the next one loads, a hit plays the live one", Cues.Playing(keyOf(SHORT)) == playing + 1 and Cues.Playing(keyOf(LONG)) == 0)
				end
				t.Check("then the next one goes live", waitFor(t, 6, function(): boolean
					return USE[PILOT] == `A{LONG.Id}`
				end))
				-- Old: today's cue, exactly
				t.Check("Old goes live", Audition.Choose(PILOT, "Old", true) and USE[PILOT] == "Old" and Audition.Live(PILOT) == "Old")
				t.Wait(0.8)
				local before = Cues.Playing(PILOT)
				Cues.Play(PILOT, here())
				local heard = false
				for k = 1, #CuesConfig.Takes[oldTakes] do
					for nth = 1, voices do
						local player = Cues.Voice(PILOT, 1, k, nth)
						heard = heard or (player ~= nil and player.IsPlaying)
					end
				end
				t.Check("a hit plays today's cue's own voices", heard and Cues.Playing(PILOT) == before + 1 and Cues.Playing(keyOf(LONG)) == 0 and Cues.Playing(keyOf(SHORT)) == 0)
				t.Check("today's cue is untouched", CuesConfig.Cues[PILOT] == oldCue and oldCue.Layers[1].Takes == oldTakes and Cues.Ahead(PILOT) == SoundRule.Ahead(oldCue))
				t.Equal("no play missed", Cues.Missed(), missed)
				Audition.Forget(PILOT, LONG)
				Audition.Forget(PILOT, SHORT)
				USE[PILOT] = was
			end,
		},
		{
			Name = "Audition: TR42, Others off silences the fight's other cues, and on again puts them back exactly",
			Run = function(t: any)
				local pilots: { [string]: boolean } = {}
				for _, spec in Config.Cues do
					pilots[spec.Name] = true
				end
				local names: { string } = {}
				for name in CuesConfig.Cues do
					if not pilots[name] then
						table.insert(names, name)
					end
				end
				table.sort(names)
				t.Check("the fight has other cues", #names > 0, `{#names}`)
				local was: { [string]: any } = {}
				for _, name in names do
					was[name] = { Use = USE[name], Set = CuesConfig.Arrangements[name] }
				end
				local pilotUse = USE[PILOT]
				local name = names[1]
				local cue = CuesConfig.Cues[name]
				local function base(): boolean
					for k = 1, #(CuesConfig.Takes[cue.Layers[1].Takes] or {}) do
						for nth = 1, math.max(cue.Voices, 1) do
							local player = Cues.Voice(name, 1, k, nth)
							if player and player.IsPlaying then
								return true
							end
						end
					end
					return false
				end
				t.Wait(1.5) -- its voices from any play before have ended
				Audition.Others(false)
				t.Check("off: every other cue on its silent arrangement, the pilots as they were", not Audition.OthersOn() and USE[PILOT] == pilotUse and (function(): boolean
					for _, n in names do
						if USE[n] ~= "Mute" then
							return false
						end
					end
					return true
				end)())
				local missed = Cues.Missed()
				Cues.Play(name, here())
				local heard = false
				local began = os.clock()
				while os.clock() - began < 0.4 do
					heard = heard or base()
					task.wait()
				end
				t.Check(`off: {name} is silent`, not heard, "one of its own voices played")
				t.Equal("off: no play missed", Cues.Missed(), missed)
				Audition.Others(true)
				local same = true
				for _, n in names do
					same = same and USE[n] == was[n].Use and CuesConfig.Arrangements[n] == was[n].Set and Cues.Voice(`{n}@Mute`, 1, 1) == nil
				end
				t.Check("on again: every switch and arrangement as before, the silent ones gone", Audition.OthersOn() and same and USE[PILOT] == pilotUse)
				Cues.Play(name, here())
				t.Check(`on again: {name} plays its own voices`, waitFor(t, 0.5, base))
			end,
		},
		{
			Name = "Audition: TR42, the fair listen: every candidate of a cue at one loudness, its top under the ceiling, its first event no longer than its cue allows",
			Run = function(t: any)
				local value = ReplicatedStorage:FindFirstChild("NL_Audition")
				t.Check("the finder's candidates are here", value ~= nil)
				if value == nil then
					return
				end
				local data = game:GetService("HttpService"):JSONDecode((value :: StringValue).Value)
				for _, spec in Config.Cues do
					local list = data.Cues[spec.Name] or {}
					local target = data.Reference + ((Config.Levels :: any)[spec.Name] or 0)
					local off, hot, long, quiet = 0, -math.huge, 0, 0
					for _, c in list do
						local volume = Audition.VolumeOf(spec.Name, c)
						off = math.max(off, math.abs(c.Loud + 20 * math.log10(volume) - target))
						hot = math.max(hot, c.Top + 20 * math.log10(volume))
						long = math.max(long, c.Seconds)
						if CuesConfig.Volume * CuesConfig.Trim * volume > 10 then -- an AudioPlayer's Volume stops at 10
							quiet += 1
						end
					end
					t.Check(`{spec.Name}: candidates found`, #list > 0, `{#list}`)
					t.Check(`{spec.Name}: one loudness`, off < 1e-6, string.format("%.3f dB off", off))
					t.Check(`{spec.Name}: every top under {Config.Ceiling} dBTP`, hot <= Config.Ceiling + 1e-6, string.format("%.1f dBTP", hot))
					t.Check(`{spec.Name}: none longer than {spec.Max} s`, long <= spec.Max + 1e-6, string.format("%.2f s", long))
					t.Check(`{spec.Name}: none past a player's volume`, quiet == 0, `{quiet}`)
				end
			end,
		},
	}
end

return AuditionCases
