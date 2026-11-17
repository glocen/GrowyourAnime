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
			for name, cue in Cues.Cues do
				t.Check(`{name}: has layers`, #cue.Layers > 0)
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
			local ids: { [number]: string } = {}
			for layer, takes in Cues.Takes do
				t.Check(`{layer}: a layer plays it`, used[layer] == true)
				for k, take in takes do
					t.Check(`{layer} {k}: an asset id`, take.Id > 0 and take.Id % 1 == 0)
					t.Check(`{layer} {k}: its id no other take's`, ids[take.Id] == nil, ids[take.Id])
					ids[take.Id] = `{layer} {k}`
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
			t.Check("a fighter's heavy hit winds up on its clock", Sound.Beat("RookHaymaker", true, "Lead") == "HeavyWind")
			t.Check("a light hit has no wind-up", Sound.Beat("RookCombo", false, "Lead") == nil)
			t.Check("a keeper's heavy swing isn't a fighter's wind-up", Sound.Beat("KeeperSignature", true, "Shade") == nil)
			local function same(a: { string }, b: { string }): boolean
				return table.concat(a, ",") == table.concat(b, ",")
			end
			t.Check("a fighter's light hit on a Shade: the hit and the Shade's hurt", same(Sound.Contact(false, "Lead", "Shade"), { "LightHit", "ShadeHurt" }))
			t.Check("a fighter's heavy hit on the dummy: the heavy hit only", same(Sound.Contact(true, "Lead", nil), { "HeavyHit" }))
			t.Check("a Shade's hit on a fighter: none of the six", same(Sound.Contact(false, "Shade", "Lead"), {}))
			t.Check("a fighter's critical shings", Sound.Critical("Lead") == "Critical")
			t.Check("a Shade's critical doesn't", Sound.Critical("Shade") == nil)
			t.Check("the lightest rung has no strength", Sound.Strength(Cues.Strength[1]) == 0 and Sound.Strength(1) == 0)
			t.Check("the heaviest has all of it", Sound.Strength(Cues.Strength[2]) == 1 and Sound.Strength(99) == 1)
			t.Check("halfway is half", math.abs(Sound.Strength((Cues.Strength[1] + Cues.Strength[2]) / 2) - 0.5) < 1e-9)
			-- every cue the rules can name is written, and every one written is named (the burst's is played by name)
			local named: { [string]: boolean } = { ShadeBurst = true }
			for _, action in Actions.List do
				for _, hit in action.Hits do
					for _, side in { "Lead", "Shade" } do
						local beat = Sound.Beat(action.Id, hit.Heavy, side)
						if beat then
							named[beat] = true
						end
						for _, struck in { "Lead", "Shade" } do
							for _, cue in Sound.Contact(hit.Heavy, side, struck) do
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
			t.Check("the swipe's tell starts 0.2 s before the hit", math.abs(Sound.Start(Cues.Cues.ShadeSwipe.Layers[1], Cues.Takes.ShadeTell[1], 1) + 0.2) < 1e-9)
			-- a beat's cue begins inside its press: its whole lead fits between the action's start and the beat
			for _, action in Actions.List do
				for beat, hit in action.Hits do
					for _, side in { "Lead", "Shade" } do
						local name = Sound.Beat(action.Id, hit.Heavy, side)
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
}
