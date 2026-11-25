--!strict
-- Cues cases (pure): the fight's layered cues (Config.Cues; docs/asset-requests.md, AR13) hold together, the rules play
-- each where it belongs (Rules.Sound), and a led layer lands on its moment at any speed a play picks.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Actions = require(Shared.Definitions.Actions)
local Cues = require(Shared.Config.Cues)
local Combat = require(Shared.Config.Combat)
local Sound = require(Shared.Rules.Sound)

local function within(range: { number }, low: number, high: number): boolean
	return #range == 2 and range[1] >= low and range[2] <= high and range[1] <= range[2]
end

return {
	{
		Name = "Cues: every cue's layers play takes that exist, each an upload with its numbers",
		Run = function(t: any)
			local own: { [string]: boolean } = {}
			for _, mine in Cues.Own do
				for _, name in { mine.Beat, mine.Contact } do
					own[name :: string] = true
				end
			end
			for name, cue in Cues.Cues do
				-- an action's own cue may stand silent until its pick: a ranged cast, the held note (TR42's second round), and
				-- TR64's moments
				t.Check(`{name}: has layers`, #cue.Layers > 0 or own[name] == true or table.find(Cues.Moments, name) ~= nil)
				t.Check(`{name}: plays on a bus`, cue.Bus == "Lead" or cue.Bus == "Shade", cue.Bus)
				t.Check(`{name}: its speed spread about ±8%, never past ±25%`, within(cue.Pitch, 0.8, 1.25))
				t.Check(`{name}: its volume spread inside 0 to 1.5`, within(cue.Volume, 0.01, 1.5))
				t.Check(`{name}: a whole number of voices, at least one`, cue.Voices >= 1 and cue.Voices % 1 == 0)
				t.Check(`{name}: its full volume near, silent far`, cue.Near >= 0 and cue.Range > cue.Near)
				for i, layer in cue.Layers do
					local takes = Cues.Takes[layer.Takes]
					t.Check(`{name} layer {i}: its takes ({layer.Takes}) exist`, takes ~= nil and #takes > 0)
					t.Check(`{name} layer {i}: led by its top, its length, or nothing`, layer.Lead == nil or layer.Lead == "Peak" or layer.Lead == "Length", layer.Lead)
					t.Check(`{name} layer {i}: a volume inside 0 to 2`, layer.Volume >= 0 and layer.Volume <= 2)
				end
			end
			local used: { [string]: boolean } = {}
			for _, cue in Cues.Cues do
				for _, layer in cue.Layers do
					used[layer.Takes] = true
				end
			end
			for _, set in Cues.Arrangements do
				for _, cue in set do
					for _, layer in cue.Layers do
						used[layer.Takes] = true
					end
				end
			end
			-- one of ours is one upload, in one list. A library recording may give slices to several lists (AR39), never
			-- two to one list, and never one of ours'.
			local ids: { [number]: string } = {}
			for layer, takes in Cues.Takes do
				t.Check(`{layer}: a layer plays it`, used[layer] == true)
				local inList: { [number]: boolean } = {}
				for k, take in takes do
					t.Check(`{layer} {k}: an asset id`, take.Id > 0 and take.Id % 1 == 0)
					local library = take.From ~= nil
					local was = ids[take.Id]
					t.Check(`{layer} {k}: its id no other take's, or a library recording's in another list`, not inList[take.Id] and (was == nil or (library and string.sub(was, 1, 3) == "lib")), was)
					inList[take.Id] = true
					ids[take.Id] = if library then `lib {layer} {k}` else `{layer} {k}`
					t.Check(`{layer} {k}: its gain inside its list above 0`, (take.Gain or 1) > 0, tostring(take.Gain))
					t.Check(`{layer} {k}: a length, its top inside it`, take.Seconds > 0 and take.Peak >= 0 and take.Peak <= take.Seconds)
				end
			end
			t.Check("the duck is down, held, then back", Cues.Duck.Db < 0 and Cues.Duck.Db >= -12 and Cues.Duck.Hold > 0 and Cues.Duck.Release >= 0)
			t.Check("the trim takes back the 2025 doubling", math.abs(Cues.Trim - 0.5) < 1e-9)
		end,
	},
	{
		Name = "Sound: a beat, a touch and a critical play the cues AR13 names, and every cue is one they play",
		Run = function(t: any)
			t.Check("a Shade's swing plays its swipe on its clock", Sound.Beat("ShadeSwipe", false, "Shade") == "ShadeSwipe")
			t.Check("a fighter's heavy hit with no cue of its own winds up on its clock", Sound.Beat("AnyHeavy", true, "Lead") == "HeavyWind")
			t.Check("a signature's own cue plays in the wind-up's place", Sound.Beat("RookHaymaker", true, "Lead", "Strike") == "Haymaker")
			t.Check("one led by At plays on that beat alone", Sound.Beat("LyricHeldNote", false, "Lead", "Note") == "HeldNote" and Sound.Beat("LyricHeldNote", false, "Lead", "Crest2") == nil)
			t.Check("a ranged M1 casts on each beat", Sound.Beat("PipCombo", false, "Lead", "Shot2") == "MageShot" and Sound.Beat("LyricCombo", false, "Lead", "Shot1") == "HealerShot")
			t.Check("a light hit has no wind-up", Sound.Beat("RookCombo", false, "Lead") == nil)
			t.Check("a keeper's heavy swing isn't a fighter's wind-up", Sound.Beat("KeeperSignature", true, "Shade") == nil)
			local function same(a: { string }, b: { string }): boolean
				return table.concat(a, ",") == table.concat(b, ",")
			end
			t.Check("a fighter's light hit on a Shade: the hit and the Shade's hurt", same(Sound.Contact(false, "Lead", "Shade"), { "LightHit", "ShadeHurt" }))
			t.Check("a fighter's heavy hit on the dummy: the heavy hit only", same(Sound.Contact(true, "Lead", nil), { "HeavyHit" }))
			t.Check("a Shade's hit on a fighter: none of the six", same(Sound.Contact(false, "Shade", "Lead"), {}))
			t.Check("a Mage's M1 on a Shade: its class's hit and the Shade's hurt", same(Sound.Contact(false, "Lead", "Shade", "PipCombo"), { "MageHit", "ShadeHurt" }))
			t.Check("a signature with only a beat of its own lands the heavy hit", same(Sound.Contact(true, "Lead", "Shade", "RookHaymaker"), { "HeavyHit", "ShadeHurt" }))
			-- every own cue's action and beat exist, and each names a written cue
			local byId: { [string]: any } = {}
			for _, action in Actions.List do
				byId[action.Id] = action
			end
			for id, mine in Cues.Own do
				local action = byId[id]
				t.Check(`{id}: an action, its own cues written`, action ~= nil and (mine.Beat == nil or Cues.Cues[mine.Beat] ~= nil) and (mine.Contact == nil or Cues.Cues[mine.Contact] ~= nil))
				t.Check(`{id}: its At one of its hits' beats`, mine.At == nil or (action ~= nil and action.Hits[mine.At] ~= nil), mine.At)
			end
			t.Check("a fighter's critical shings", Sound.Critical("Lead") == "Critical")
			t.Check("a Shade's critical doesn't", Sound.Critical("Shade") == nil)
			t.Check("the lightest rung has no strength", Sound.Strength(Cues.Strength[1]) == 0 and Sound.Strength(1) == 0)
			t.Check("the heaviest has all of it", Sound.Strength(Cues.Strength[2]) == 1 and Sound.Strength(99) == 1)
			t.Check("halfway is half", math.abs(Sound.Strength((Cues.Strength[1] + Cues.Strength[2]) / 2) - 0.5) < 1e-9)
			-- every cue the rules can name is written, and every one written is named (the burst's is played by name)
			-- the wind-up stays every heavy hit's that has no cue of its own
			local named: { [string]: boolean } = { ShadeBurst = true, [Sound.Beat("AnyHeavy", true, "Lead") :: string] = true }
			for _, moment in Cues.Moments do -- TR64's, played by name at their moment
				named[moment] = true
			end
			for _, action in Actions.List do
				for name, hit in action.Hits do
					for _, side in { "Lead", "Shade" } do
						local beat = Sound.Beat(action.Id, hit.Heavy, side, name)
						if beat then
							named[beat] = true
						end
						for _, struck in { "Lead", "Shade" } do
							for _, cue in Sound.Contact(hit.Heavy, side, struck, action.Id) do
								named[cue] = true
							end
						end
						local shing = Sound.Critical(side)
						if shing then
							named[shing] = true
						end
					end
				end
			end
			for name in named do
				t.Check(`{name}: the rules play it, and it's written`, Cues.Cues[name] ~= nil)
			end
			for name in Cues.Cues do
				t.Check(`{name}: written, and the rules play it`, named[name] == true)
			end
			t.Check("the strength's rungs are the hitstop's", Cues.Strength[1] == Combat.Hitstop.Rungs[1].From and Cues.Strength[2] == Combat.Hitstop.Rungs[#Combat.Hitstop.Rungs].From)
		end,
	},
	{
		Name = "Sound: a led layer lands on its moment at any speed, and a beat's cue fits before its beat",
		Run = function(t: any)
			for name, cue in Cues.Cues do
				local ahead = Sound.Ahead(cue)
				for i, layer in cue.Layers do
					for k, take in Cues.Takes[layer.Takes] or {} do
						for _, speed in { cue.Pitch[1], 1, cue.Pitch[2] } do
							local start = Sound.Start(layer, take, speed)
							local lands = if layer.Lead == "Peak" then start + take.Peak / speed elseif layer.Lead == "Length" then start + take.Seconds / speed else start
							t.Check(`{name} layer {i} take {k} at {speed}: lands at its At`, math.abs(lands - layer.At) < 1e-9, string.format("%.4f", lands))
							t.Check(`{name} layer {i} take {k} at {speed}: starts no sooner than the cue's lead`, -start <= ahead + 1e-9)
						end
					end
				end
			end
			t.Check("the swipe tops on the hit, its rise before it", Cues.Cues.ShadeSwipe.Layers[1].Lead == "Peak" and Cues.Cues.ShadeSwipe.Layers[1].At == 0)
			-- a beat's cue begins inside its press: its whole lead fits between the action's start and the beat
			for _, action in Actions.List do
				for beat, hit in action.Hits do
					for _, side in { "Lead", "Shade" } do
						local name = Sound.Beat(action.Id, hit.Heavy, side, beat)
						local cue = if name then Cues.Cues[name] else nil
						if cue then
							local at = action.Beats[beat]
							t.Check(`{action.Id} {beat} ({side}): {name}'s lead fits before its beat`, at ~= nil and Sound.Ahead(cue) <= at, string.format("%.3f before %s", Sound.Ahead(cue), tostring(at)))
						end
					end
				end
			end
		end,
	},
	{
		Name = "Cues: an arrangement is its pilot with other layers, its players inside their volume (AR39)",
		Run = function(t: any)
			local some = false
			for pilot, set in Cues.Arrangements do
				local of = Cues.Cues[pilot]
				t.Check(`{pilot}: a cue, switched by Use, as it was until Use says otherwise`, of ~= nil and (Cues.Use :: any)[pilot] == "Old", tostring((Cues.Use :: any)[pilot]))
				for variant, cue in set do
					some = true
					local name = `{pilot}@{variant}`
					t.Check(`{name}: its pilot's bus, spreads, voices and reach`, of ~= nil and cue.Bus == of.Bus and cue.Pitch == of.Pitch and cue.Volume == of.Volume and cue.Voices == of.Voices and cue.Near == of.Near and cue.Range == of.Range)
					t.Check(`{name}: not named "Old"`, variant ~= "Old")
					t.Check(`{name}: has layers`, #cue.Layers > 0)
					local loudest = math.max(cue.Volume[1], cue.Volume[2])
					for i, layer in cue.Layers do
						local takes = Cues.Takes[layer.Takes]
						t.Check(`{name} layer {i}: its takes ({layer.Takes}) exist, two or more so none plays twice running`, takes ~= nil and #takes >= 2)
						t.Check(`{name} layer {i}: led by its top, its length, or nothing`, layer.Lead == nil or layer.Lead == "Peak" or layer.Lead == "Length", layer.Lead)
						for k, take in takes or {} do
							local level = Sound.Level(layer, take, loudest, 1)
							t.Check(`{name} layer {i} take {k}: its player's volume above 0, at most 3`, level > 0 and level <= 3, string.format("%.3f", level))
						end
					end
				end
			end
			t.Check("the limiter: at or under full scale, released in a moment", Cues.Limiter.MaxLevel <= 0 and Cues.Limiter.MaxLevel >= -12 and Cues.Limiter.Release > 0 and Cues.Limiter.Release <= 1)
			-- a take's gain is times its layer's volume, and a layer follows the hit's strength only when it says so
			local layer = { Takes = "x", At = 0, Volume = 0.5 } :: any
			local take = { Id = 1, Seconds = 0.1, Peak = 0, Gain = 4 } :: any
			local base = Cues.Volume * Cues.Trim
			t.Check("a take's gain times its layer's volume", math.abs(Sound.Level(layer, take, 0.9, 0.2) - base * 0.5 * 4 * 0.9) < 1e-9)
			t.Check("no gain is 1", math.abs(Sound.Level(layer, { Id = 1, Seconds = 0.1, Peak = 0 } :: any, 1, nil) - base * 0.5) < 1e-9)
			t.Check("a layer by strength: none at the lightest hit", Sound.Level({ Takes = "x", At = 0, Volume = 0.5, Strength = true } :: any, take, 1, 0) == 0)
			t.Check("round 1 is in", some)
			-- the A/B at matched level: an arrangement's own dB while it's on, nothing for a cue as it was or while off
			local on = Cues.Match.On
			for pilot, set in Cues.Match.Db do
				for variant, db in set do
					local named = Cues.Arrangements[pilot] ~= nil and Cues.Arrangements[pilot][variant] ~= nil
					t.Check(`{pilot}@{variant}: its match is an arrangement's, within 30 dB`, named and db == db and math.abs(db) <= 30, tostring(db))
					Cues.Match.On = true
					t.Check(`{pilot}@{variant}: matched, its level times its dB`, math.abs(Sound.Match(pilot, variant) - 10 ^ (db / 20)) < 1e-9)
					Cues.Match.On = false
					t.Check(`{pilot}@{variant}: unmatched, its own level`, Sound.Match(pilot, variant) == 1)
				end
			end
			Cues.Match.On = true
			t.Check("a cue as it was, or an arrangement with no measure, plays at its own level", Sound.Match("LightHit", "Old") == 1 and Sound.Match("LightHit", nil) == 1 and Sound.Match("NoSuchCue", "A1") == 1)
			Cues.Match.On = on
		end,
	},
	{
		Name = "Sound: a library take plays its slice of its file, faded (AR39)",
		Run = function(t: any)
			local frame = 1 / 60
			local function near(a: number?, b: number): boolean
				return a ~= nil and math.abs(a - b) < 1e-9
			end
			-- one of ours: whole, from its start, at full, no fades
			local ours = Sound.Run({ Id = 1, Seconds = 0.25, Peak = 0.1 }, 0, 1, frame)
			t.Check("one of ours: from its file's start, at full, unfaded", ours.Position == 0 and ours.Share == 1 and ours.In == 0 and ours.OutAfter == nil)
			-- a library slice, 1.2 to 1.5 s of its file, in over 50 ms and out over 40
			local slice = { Id = 2, Seconds = 0.3, Peak = 0.06, From = 1.2, To = 1.5, In = 0.05, Out = 0.04 } :: any
			local run = Sound.Run(slice, 0, 1, frame)
			t.Check("a slice starts at its From, silent, and rises over its In", near(run.Position, 1.2) and run.Share == 0 and near(run.In, 0.05))
			t.Check("its fall starts a frame early and ends inside the slice", near(run.OutAfter, 0.3 - 0.04 - frame) and near(run.Out, 0.04) and (run.OutAfter :: number) + run.Out <= 0.3)
			-- late by 20 ms: in from where it would be, the rise part done
			local late = Sound.Run(slice, 0.02, 1, frame)
			t.Check("a late play: in from where it would be by now", near(late.Position, 1.22) and near(late.Share, 0.4) and near(late.In, 0.03) and near(late.OutAfter, 0.3 - 0.04 - 0.02 - frame))
			t.Check("late past its rise: at full", Sound.Run(slice, 0.06, 1, frame).Share == 1 and Sound.Run(slice, 0.06, 1, frame).In == 0)
			-- faster: every time shorter by the speed, the file's place unchanged
			local fast = Sound.Run(slice, 0, 1.25, frame)
			t.Check("at 1.25: its times shorter by the speed", near(fast.Position, 1.2) and near(fast.In, 0.04) and near(fast.Out, 0.032) and near(fast.OutAfter, (0.3 - 0.04) / 1.25 - frame))
			-- a rise a client can't step (under two frames) isn't drawn: the contact isn't swallowed
			local sharp = Sound.Run({ Id = 3, Seconds = 0.15, Peak = 0.004, From = 0.5, To = 0.65, In = 0.003, Out = 0.02 } :: any, 0, 1, frame)
			t.Check("a 3 ms rise isn't stepped: it starts at full", sharp.Share == 1 and sharp.In == 0 and near(sharp.OutAfter, 0.15 - 0.02 - frame))
			-- the registry's own takes: a slice is well formed, and its length is its slice's
			for name, takes in Cues.Takes do
				for k, take in takes :: { any } do
					if take.From ~= nil or take.To ~= nil then
						t.Check(`{name} {k}: a slice with its From before its To, its Seconds their difference`, take.From ~= nil and take.To ~= nil and take.From >= 0 and take.To > take.From and math.abs(take.Seconds - (take.To - take.From)) < 1e-6)
						t.Check(`{name} {k}: falls over at least 10 ms (AR39's gate 6), its top inside it`, (take.Out or 0) >= 0.01 and take.Peak >= 0 and take.Peak <= take.Seconds)
					end
				end
			end
		end,
	},
}
