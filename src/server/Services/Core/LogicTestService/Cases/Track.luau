--!strict
-- Track cases (pure): an effect row's eases and keys (Rules.Track), and every effect's rows whole against the kit
-- (Config.Effects.Rows, Config.FxKit; AR8, "The method"), and the keeper's signature on its beats.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Track = require(Shared.Rules.Track)
local EffectsConfig = require(Shared.Config.Effects)
local SoundsConfig = require(Shared.Config.Sounds)
local EffectRows = require(Shared.Config.EffectRows)
local FxKit = require(Shared.Config.FxKit)
local Actions = require(Shared.Definitions.Actions)
local Combat = require(Shared.Config.Combat)

local KINDS = { Mesh = true, Card = true, Emitter = true, Light = true, Glow = true, Point = true, Beam = true, Streak = true, Sound = true, Relight = true }

local function near(a: number, b: number): boolean
	return math.abs(a - b) <= 1e-9 * math.max(1, math.abs(b))
end

return {
	{
		-- docs/engineering-plan.md, "The rows contract" (Content at scale, item 3): every effect written in Luau goes into a
		-- rows file and back unchanged, so the contract holds all of it, and the files the game reads decode whole.
		Name = "Track: the rows contract: every effect makes a rows file and comes back the same, and the files decode whole",
		Run = function(t: any)
			local function same(a: any, b: any, where: string): (boolean, string?)
				local kind = typeof(a)
				if kind ~= typeof(b) then
					return false, `{where}: {kind} against {typeof(b)}`
				elseif kind == "number" then
					return math.abs(a - b) <= 1e-9 * math.max(1, math.abs(b)), where
				elseif kind == "Vector3" then
					return (a - b).Magnitude <= 1e-6, where
				elseif kind == "Color3" then
					return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B) <= 1e-6, where
				elseif kind == "table" then
					for key, value in a do
						local ok, at = same(value, b[key], `{where}.{tostring(key)}`)
						if not ok then
							return false, at
						end
					end
					for key in b do
						if a[key] == nil then
							return false, `{where}.{tostring(key)}: only after`
						end
					end
					return true, nil
				end
				return a == b, where
			end
			local count = 0
			for name, effect in EffectsConfig.Rows do
				count += 1
				local file = EffectRows.Encode(effect, name)
				t.Check(`{name}: its file names its schema and itself`, file.Schema == EffectRows.Schema and file.Effect == name)
				local back = EffectRows.Decode(file, name)
				local ok, at = same(back.Rows, effect.Rows, name)
				t.Check(`{name}: back from its file the same`, ok, at)
				t.Check(`{name}: its area, grey, action, free and world the same`, back.Area == effect.Area and back.Grey == effect.Grey
					and back.Action == effect.Action and back.Free == effect.Free and back.World == effect.World)
			end
			t.Check("every effect went round", count >= 4, `{count}`)
			for name in EffectRows.Effects do
				t.Check(`{name}: from its file, in Config.Effects.Rows`, EffectsConfig.Rows[name] ~= nil)
			end
			t.Check("Pip's and Lyric's shots are files", EffectRows.Effects.PipShots ~= nil and EffectRows.Effects.LyricShots ~= nil)
			local colour = EffectRows.Effects.PipShots.Rows.Shot1.Color
			t.Check("a colour decodes to a Color3", typeof(colour) == "Color3" and math.abs(colour.R - 225 / 255) < 1e-6)
			-- what a file may not hold
			t.Check("an unknown row field is refused", not pcall(EffectRows.Decode, {
				Schema = EffectRows.Schema, Effect = "X", Area = 1, Rows = { A = { Kind = "Point", Tracks = {}, Colour = 1 } },
			}, "X"))
			t.Check("a file without its schema is refused", not pcall(EffectRows.Decode, { Effect = "X", Area = 1, Rows = {} }, "X"))
			t.Check("a file named for another effect is refused", not pcall(EffectRows.Decode, { Schema = EffectRows.Schema, Effect = "Y", Area = 1, Rows = {} }, "X"))
			t.Check("a Vector3 is three numbers", not pcall(EffectRows.Decode, {
				Schema = EffectRows.Schema, Effect = "X", Area = 1, Rows = { A = { Kind = "Point", Turn = { Vector3 = { 1, 2 } }, Tracks = {} } },
			}, "X"))
			local why = EffectRows.Decode({
				Schema = EffectRows.Schema, Effect = "X", Why = "a note", Area = 1, Rows = { A = { Kind = "Point", Why = "a note" } },
			}, "X")
			t.Check("a Why is a note, dropped; Tracks given when none", why.Rows.A.Why == nil and type(why.Rows.A.Tracks) == "table")
			local world = EffectRows.Decode({ Schema = EffectRows.Schema, Effect = "X", Area = 1, World = true, Rows = {} }, "X")
			t.Check("World is kept, and left out it's none (drawn with its body)", world.World == true and why.World == nil)
		end,
	},
	{
		-- docs/engineering-plan.md, "Content at scale", item 1: an action names its effect, and the rows say whose they are.
		Name = "Track: every action's effect is its own rows, or one of the three older signatures until the finish pass",
		Run = function(t: any)
			local named = 0
			for _, action in Actions.List do
				local name = action.Effect
				if name == nil then
					continue
				end
				named += 1
				local rows = EffectsConfig.Rows[name]
				local older = EffectsConfig.Older[name] == true
				t.Check(`{action.Id}: {name} is rows or an older signature, not both`, (rows ~= nil) ~= older)
				if rows then
					t.Equal(`{action.Id}: its rows say they're its`, rows.Action, action.Id)
				end
			end
			t.Check("the six effects of the old table, named", named >= 6, `{named}`)
			for effectName, effect in EffectsConfig.Rows do
				local action = if effect.Action then Actions.ById[effect.Action] else nil
				if action then
					t.Equal(`{effectName}: its action plays it`, action.Effect, effectName)
				end
			end
			for name in EffectsConfig.Older do
				t.Check(`{name}: an older signature an action still plays`, (function()
					for _, action in Actions.List do
						if action.Effect == name then
							return true
						end
					end
					return false
				end)())
			end
			t.Check("the keeper's signature runs free from its Slam", EffectsConfig.Rows.KeeperSignature.Free == "Slam")
			t.Check("no camera move left in a fight's effect (the director, 2026-11-14)", (EffectsConfig :: any).KeeperSignature == nil)
		end,
	},
	{
		Name = "Track: the eases by Roblox's names",
		Run = function(t: any)
			t.Check("Linear halfway", near(Track.Ease("Linear", 0.5), 0.5))
			t.Check("none is Linear", near(Track.Ease(nil, 0.3), 0.3))
			t.Check("Quad In halfway", near(Track.Ease("Quad In", 0.5), 0.25))
			t.Check("Quart Out halfway", near(Track.Ease("Quart Out", 0.5), 0.9375))
			t.Check("Cubic InOut a quarter in", near(Track.Ease("Cubic InOut", 0.25), 0.0625))
			t.Check("Cubic InOut three quarters in", near(Track.Ease("Cubic InOut", 0.75), 0.9375))
			t.Check("Sine InOut halfway", near(Track.Ease("Sine InOut", 0.5), 0.5))
			t.Check("Sine In a third in", near(Track.Ease("Sine In", 1 / 3), 1 - math.cos(math.pi / 6)))
			t.Check("Back In dips under its start", Track.Ease("Back In", 0.2) < 0)
			for _, style in { "Quad", "Cubic", "Quart", "Quint", "Sine", "Exponential", "Circular", "Back" } do
				for _, way in { "In", "Out", "InOut" } do
					local name = `{style} {way}`
					t.Check(`{name} is known`, Track.Known(name))
					t.Check(`{name} starts at 0`, math.abs(Track.Ease(name, 0)) < 1e-3, tostring(Track.Ease(name, 0)))
					t.Check(`{name} ends at 1`, math.abs(Track.Ease(name, 1) - 1) < 1e-3, tostring(Track.Ease(name, 1)))
				end
			end
			t.Check("clamped below", near(Track.Ease("Quad Out", -1), 0))
			t.Check("clamped above", near(Track.Ease("Quad Out", 2), 1))
			t.Check("a style it doesn't know isn't known", not Track.Known("Bounce Out"))
			t.Check("a way it doesn't know isn't known", not Track.Known("Quad Sideways"))
			t.Check("a name without a way isn't known", not Track.Known("Quad"))
		end,
	},
	{
		Name = "Track: a key list's value at a frame, none before its first key, held past its last",
		Run = function(t: any)
			local keys = { { 2, 10, "Quad In" }, { 6, 30, "Linear" }, { 8, 20 } }
			t.Equal("none before the first key", Track.Value(keys, 1.9), nil)
			t.Equal("none with no track", Track.Value(nil, 3), nil)
			t.Check("on the first key", near(Track.Value(keys, 2), 10))
			t.Check("halfway on Quad In", near(Track.Value(keys, 4), 15))
			t.Check("on the second key", near(Track.Value(keys, 6), 30))
			t.Check("halfway on Linear", near(Track.Value(keys, 7), 25))
			t.Check("held past the last", near(Track.Value(keys, 100), 20))
			local a, b = Track.Span(keys)
			t.Check("its span", a == 2 and b == 8, `{a} {b}`)
			local moved = Track.Value({ { 0, Vector3.new(0, 0, 0) }, { 4, Vector3.new(4, 8, -4) } }, 1) :: Vector3
			t.Check("a Vector3 between keys", (moved - Vector3.new(1, 2, -1)).Magnitude < 1e-9, tostring(moved))
			local colour = Track.Value({ { 0, Color3.new(1, 0, 0) }, { 2, Color3.new(0, 0, 1) } }, 1) :: Color3
			t.Check("a Color3 between keys", near(colour.R, 0.5) and near(colour.G, 0) and near(colour.B, 0.5))
			t.Check("two keys on one frame take the later", near(Track.Value({ { 0, 1 }, { 3, 1 }, { 3, 5 } }, 3), 1)
				and near(Track.Value({ { 0, 1 }, { 3, 1 }, { 3, 5 } }, 3.01), 5))
		end,
	},
	{
		-- A look is rows riding the body, or an outline on it (Config.Effects.Outlines: Ground Wire's shield since AR11's
		-- retake), never both.
		Name = "Track: a hit's looks are worn on a body, rows held to the end of what they show or an outline, and none goes unnamed",
		Run = function(t: any)
			local named: { [string]: boolean } = {}
			-- One look worn on a body for `lasts` seconds at most: its switch, its rows or its outline, held past it.
			local function worn(label: string, name: string, lasts: number)
				named[name] = true
				t.Check(`{label}: played on a body`, EffectsConfig.Lasting[name] ~= nil)
				local rows = (EffectsConfig.Rows :: any)[name] :: EffectsConfig.Rows?
				local outline = (EffectsConfig.Outlines :: any)[name] :: { Color: Color3, Transparency: number }?
				t.Check(`{label}: its rows or its outline, one of them`, (rows ~= nil) ~= (outline ~= nil))
				if outline then
					t.Check(`{label}: an outline in a colour`, typeof(outline.Color) == "Color3")
					t.Check(`{label}: an outline that shows`, type(outline.Transparency) == "number" and outline.Transparency >= 0 and outline.Transparency < 0.9, tostring(outline.Transparency))
				end
				if rows == nil then
					return
				end
				t.Check(`{label}: of no action, so nothing counts from a beat`, rows.Action == nil and rows.Free == nil)
				-- the longest it can show; its rows hold past it, so code ends it
				local last = 0
				for _, row in rows.Rows do
					t.Check(`{label}: every row rides the body`, row.Body ~= nil or row.On ~= nil)
					for _, keys in row.Tracks or {} do
						if type(keys) == "table" and type(keys[1]) == "table" then
							local _, b = Track.Span(keys)
							last = math.max(last, b)
						end
					end
				end
				t.Check(`{label}: held past what it shows`, last / 60 >= lasts, string.format("%.2f s against %.2f", last / 60, lasts))
			end
			-- A shield a cast gives, worn as the ally's ShieldLook (AR58's Support): a look as a hit's is.
			local support = Combat.Support.Shield
			worn(`SupportCast's shield look, {support.Look}`, support.Look, support.Seconds)
			-- The element states' looks (AR48), each for its state's seconds; a chill's for the longest its fill stays in a
			-- third with no hit (its delay, then a share's drain), a freeze's for the whole freeze.
			local states = Combat.States
			worn(`the burn's look, {states.Burn.Look}`, states.Burn.Look, states.Burn.Seconds)
			worn(`the shock's look, {states.Shock.Look}`, states.Shock.Look, states.Shock.Seconds)
			worn(`the sap's look, {states.Sap.Look}`, states.Sap.Look, states.Sap.Seconds)
			worn(`the freeze's look, {states.Freeze.Look}`, states.Freeze.Look, states.Freeze.Seconds)
			local chill = states.Chill
			for step, name in chill.Looks do
				worn(`the chill's look in its share {step}, {name}`, name, chill.Delay + (1 / #chill.Looks) / chill.Drain)
			end
			-- a freeze's break plays once at the foot, on the effects' clock: rows of no action, held to no far frame
			local broke = (EffectsConfig.Rows :: any)[states.Freeze.Break] :: EffectsConfig.Rows?
			t.Check(`the freeze's break, {states.Freeze.Break}: its rows are in`, broke ~= nil)
			t.Check(`the freeze's break: of no action, so nothing counts from a beat`, broke ~= nil and broke.Action == nil and broke.Free == nil)
			t.Check(`the freeze's break: played once, not worn`, EffectsConfig.Lasting[states.Freeze.Break] == nil)
			for _, action in Actions.List do
				for beat, hit in action.Hits do
					local looks = hit.Looks
					if looks == nil then
						continue
					end
					for what, name in looks :: { [string]: string } do
						local label = `{action.Id}.{beat}'s {what} look, {name}`
						t.Check(`{label}: shows what the hit does`, (what == "Stun" and hit.Stun ~= nil) or (what == "Shield" and hit.Shield ~= nil))
						-- the longest it can show: the stun whole, the shield's seconds
						local lasts = if what == "Stun" then hit.Stun :: number else (hit.Shield :: { Seconds: number }).Seconds
						worn(label, name, lasts)
					end
				end
			end
			for name in EffectsConfig.Lasting do
				t.Check(`{name}: played on a body by a hit's look`, named[name] == true)
			end
			for name in EffectsConfig.Outlines do
				t.Check(`{name}: an outline a hit's look wears, with its switch`, named[name] == true and EffectsConfig.Lasting[name] ~= nil)
			end
		end,
	},
	{
		Name = "Track: every effect's rows whole against the kit, and B1's exit on its beats",
		Run = function(t: any)
			for coilName, coil in FxKit.Meshes do
				if coil.Of == nil then
					continue
				end
				local whole = FxKit.Meshes[coil.Of]
				local offset = coil.Centre - whole.Centre
				t.Check(`{coilName} sits at its coil's centre plus its offset`, (offset - (coil.Offset :: Vector3)).Magnitude < 1e-3, tostring(offset))
			end
			for effectName, effect in EffectsConfig.Rows do
				t.Check(`{effectName} is written at an area`, effect.Area > 0)
				local action = if effect.Action then Actions.ById[effect.Action] else nil
				t.Check(`{effectName}: its action is one`, effect.Action == nil or action ~= nil, tostring(effect.Action))
				t.Check(`{effectName}: runs free from a beat of its action`, effect.Free == nil or (action ~= nil and action.Beats[effect.Free] ~= nil), tostring(effect.Free))
				for rowName, row in effect.Rows do
					local label = `{effectName}.{rowName}`
					t.Check(`{label}: a kind the player plays`, KINDS[row.Kind] == true, row.Kind)
					t.Check(`{label}: rides a row of its effect`, row.On == nil or (effect.Rows[row.On] ~= nil and row.On ~= rowName), tostring(row.On))
					t.Check(`{label}: rides one thing`, row.On == nil or row.Body == nil)
					t.Check(`{label}: counts from a beat of its action`, row.From == nil or (action ~= nil and action.Beats[row.From] ~= nil), tostring(row.From))
					t.Check(`{label}: rides a body only in an action's effect, or one played on a body`, row.Body == nil or action ~= nil or EffectsConfig.Lasting[effectName] ~= nil)
					-- a beam's High may be its effect's target as it stands (AR58's link: Effects.Once's target), no row's end
					t.Check(`{label}: only a beam ends at its target`, row.High ~= "Target" or row.Kind == "Beam")
					local reach = row.Tracks.Reach
					if reach then
						for _, key in reach do
							t.Check(`{label}: its Reach a share of the way, 0 to 1`, row.Kind == "Beam" and type(key[2]) == "number" and key[2] >= 0 and key[2] <= 1, tostring(key[2]))
						end
					end
					local refs: { string? } = { row.Low, if row.High ~= "Target" then row.High else nil }
					for _, named in refs do
						local ref = named :: string
						local parts = string.split(ref, ".")
						local other = effect.Rows[parts[1]]
						t.Check(`{label}: hangs on a beam's end, {ref}`, other ~= nil and other.Kind == "Beam" and (parts[2] == "Low" or parts[2] == "High"))
					end
					local like = if row.Like then effect.Rows[row.Like] else nil
					t.Check(`{label}: like a beam of its effect`, row.Like == nil or (like ~= nil and like.Kind == "Beam" and row.Like ~= rowName), tostring(row.Like))
					if row.Kind == "Beam" then
						local picture = if row.Image then FxKit.Images[row.Image] or EffectsConfig.Pictures[row.Image] else nil
						t.Check(`{label}: {row.Image} is a kit image or a picture`, picture ~= nil)
						t.Check(`{label}: its picture uploaded once it's out of grey`, effect.Grey or (picture ~= nil and picture ~= ""))
						t.Check(`{label}: its block-in a kit image, or none`, row.Grey == nil or row.Grey == "" or FxKit.Images[row.Grey] ~= nil, tostring(row.Grey))
						t.Check(`{label}: its ends`, row.Trail ~= nil or row.Low ~= nil or row.Tracks.Foot ~= nil or row.On ~= nil or row.Body ~= nil)
						t.Check(`{label}: a taper is a share of its foot's width`, row.Taper == nil or (row.Taper > 0 and row.Taper <= 1), tostring(row.Taper))
					elseif row.Kind == "Glow" then
						t.Check(`{label}: one part of its body`, action ~= nil and row.Part ~= nil and #row.Part == 1)
					elseif row.Kind == "Streak" then
						t.Check(`{label}: thrown from a point of its body`, action ~= nil and row.Body ~= nil)
						t.Check(`{label}: on a beat that hits`, action ~= nil and row.From ~= nil and action.Hits[row.From :: string] ~= nil, tostring(row.From))
					elseif row.Kind == "Sound" then
						t.Check(`{label}: a cue that's one`, row.Cue ~= nil and (SoundsConfig.Cues :: any)[row.Cue] ~= nil, tostring(row.Cue))
					elseif row.Kind == "Relight" then
						t.Check(`{label}: one part of its body`, action ~= nil and row.Part ~= nil and #row.Part == 1)
						local spec = row.Relight
						t.Check(`{label}: its glow and its curve`, spec ~= nil and spec.Glow >= 0 and spec.Power > 0)
						t.Check(`{label}: over a cooldown`, action ~= nil and action.Cooldown > 0)
					end
					if row.Kind == "Mesh" then
						t.Check(`{label}: has parts`, row.Part ~= nil and #row.Part > 0)
						for _, part in row.Part or {} do
							t.Check(`{label}: {part} is a kit mesh`, FxKit.Meshes[part] ~= nil)
						end
						for _, look in { row.Look, row.Grey } do
							local image = FxKit.Images[look :: string]
							t.Check(`{label}: {look} is a mesh look`, look == nil or (image ~= nil and string.find(image.Use, "^MeshPart") ~= nil))
						end
						for part in row.Bands or {} do
							t.Check(`{label}: its band {part} is one of its parts`, table.find(row.Part or {}, part) ~= nil)
						end
					elseif row.Kind == "Card" or row.Kind == "Emitter" then
						local picture = if row.Image then FxKit.Images[row.Image] or EffectsConfig.Pictures[row.Image] else nil
						t.Check(`{label}: {row.Image} is a kit image or a picture`, picture ~= nil)
						t.Check(`{label}: its picture uploaded once it's out of grey`, effect.Grey or (picture ~= nil and picture ~= ""))
					end
					t.Check(`{label}: a tell is an emitter's bursts`, row.Tell == nil or (row.Kind == "Emitter" and row.Emit ~= nil), tostring(row.Tell))
					local lists: { { any } } = {}
					for _, keys in row.Tracks do
						table.insert(lists, keys)
					end
					for _, tracks in row.Bands or {} do
						for _, keys in tracks do
							table.insert(lists, keys)
						end
					end
					for _, keys in lists do
						for index, key in keys do
							t.Check(`{label}: {key[3]} is an ease`, Track.Known(key[3]))
							t.Check(`{label}: keys in frame order`, index == 1 or key[1] >= keys[index - 1][1])
						end
					end
				end
			end
			local exit = EffectsConfig.LanternBurst.Exit
			t.Check("Lantern Burst's exit names rows, or none", exit == "" or EffectsConfig.Rows[exit] ~= nil, exit)
			local rows = EffectsConfig.Rows.LanternExit.Rows
			local scale = rows.Coil.Tracks.Scale
			t.Check("the coil is a third grown on the hit", near((Track.Value(scale, 0) :: Vector3).Y / (Track.Value(scale, 4) :: Vector3).Y, 0.6))
			for band = 1, 6 do
				local tracks = (rows.Coil.Bands :: any)[`FxCoil2_Burn{band}`]
				local going = 8 + 1.5 * (band - 1)
				t.Check(`band {band} whole until {66 + going}`, near(Track.Value(tracks.Transparency, going), 0))
				t.Check(`band {band} gone by {66 + going + 3}`, near(Track.Value(tracks.Transparency, going + 3), 1))
				-- B1's finish: cut, never faded, so no half-gone flame reads rose over the Shade or a dusk sky
				t.Check(`band {band} whole while it flares, then cut`, near(Track.Value(tracks.Transparency, going + 1.99), 0)
					and near(Track.Value(tracks.Transparency, going + 2.01), 1))
				t.Check(`band {band} flares hot as it goes`, near(Track.Value(tracks.Glow, going + 1.5), 4))
			end
			t.Check("the flare's white on 70", near(Track.Value(rows.Flare.Tracks.Size, 4), 5.5) and near(Track.Value(rows.Flare.Tracks.Size, 7), 0))
			-- B1's finish (AR8, "B1's finish: the bands on fire"): the coil on fire, a burning front where each band meets the next
			t.Check("the coil on fire", rows.Coil.Look == "fx_fire_Flame")
			local fronts = rows.Front
			t.Check("the fronts ride the coil and grow with it", fronts ~= nil and fronts.On == "Coil" and fronts.Tracks.Scale == rows.Coil.Tracks.Scale)
			for n = 1, 5 do
				local name = `FxCoil2_Front{n}`
				local tracks = (fronts.Bands :: any)[name]
				local going = 8 + 1.5 * (n - 1)
				t.Check(`front {n} sits where band {n} meets {n + 1}`, FxKit.Meshes[name].Of == "FxCoil2" and FxKit.Meshes[name].Front == n)
				t.Check(`front {n} unseen until band {n} burns`, near(Track.Value(tracks.Transparency, going), 1))
				t.Check(`front {n} shown as it burns`, near(Track.Value(tracks.Transparency, going + 0.5), 0) and near(Track.Value(tracks.Transparency, going + 2), 0))
				t.Check(`front {n} gone as band {n + 1} takes over`, near(Track.Value(tracks.Transparency, going + 3), 1))
				t.Check(`front {n} brighter than the bands`, Track.Value(tracks.Glow, going + 1) > Track.Value(((rows.Coil.Bands :: any)[`FxCoil2_Burn{n}`]).Glow, 0))
			end
			t.Check("the light at its brightest on the flare", near(Track.Value(rows.Light.Tracks.Brightness, 4), 4))
		end,
	},
	{
		-- AR7, section 7, and Modulo's rows (AR8, "The keeper's signature as rows"): the content check's conditions a and b,
		-- and 4 (the floor clear by about 140), on the clip's frames.
		Name = "Track: the keeper's signature on its beats, as its content check passed it",
		Run = function(t: any)
			local action = Actions.ById.KeeperSignature
			local effect = EffectsConfig.Rows[action.Effect :: string]
			t.Check("its rows are its action's", effect ~= nil and effect.Action == action.Id)
			local rows = effect.Rows
			local mark: { [string]: number } = {}
			for beat, at in action.Beats do
				mark[beat] = math.floor(at * 60 + 0.5)
			end
			t.Equal("Plant on 24", mark.Plant, 24)
			t.Equal("Light on 44", mark.Light, 44)
			t.Equal("Wrench on 106", mark.Wrench, 106)
			t.Equal("Slam on 118", mark.Slam, 118)
			local function at(row: string, track: string, frame: number): any
				local r = rows[row]
				return Track.Value(r.Tracks[track], frame - mark[r.From :: string])
			end
			t.Check("the paper at its top on the Wrench, 106 and 107", near(at("Paper", "Glow", 106), 3) and near(at("Paper", "Glow", 107), 3))
			t.Check("the paper dim after the Slam", at("Paper", "Glow", 119) < 1.2)
			t.Check("and relit as it was by 160", near(at("Paper", "Glow", 160), 1.2))
			t.Check("the hold's light out by 104 (condition a)", near(at("HoldLight", "Brightness", 104), 0))
			t.Check("the shell gone by 104 (condition a)", near(at("Shell", "Transparency", 104), 1))
			t.Check("the streak from 111", at("Streak", "Transparency", 110) == nil and at("Streak", "Transparency", 111) < 1)
			t.Check("and gone before 117 (condition b)", at("Streak", "Transparency", 116) < 1 and near(at("Streak", "Transparency", 117), 1))
			t.Check("the column on the Slam", at("Shaft", "Width", 118) > 0 and near(at("Shaft", "Transparency", 118), 0))
			t.Check("its foot lets go from 124", near(at("Shaft", "Foot", 123), 0) and at("Shaft", "Foot", 124) > 0)
			-- research's verdict on the grey (2026-11-13): it leaps, then climbs gaining speed, widest at the foot
			t.Check("it leaps: its height peaks in its first quarter", at("Shaft", "Top", 118) < at("Shaft", "Top", 123) * 0.5
				and at("Shaft", "Top", 123) - at("Shaft", "Foot", 123) >= at("Shaft", "Top", 130) - at("Shaft", "Foot", 130) - 1e-6)
			local function rise(frame: number): number
				return at("Shaft", "Foot", frame + 1) - at("Shaft", "Foot", frame)
			end
			t.Check("then climbs gaining speed", rise(126) < rise(130) and rise(130) < rise(134) and rise(134) < rise(138))
			t.Check("held until the climb is under way", near(at("Shaft", "Transparency", 132), 0))
			local shaftRow = rows.Shaft
			t.Check("widest at the foot", shaftRow.Taper ~= nil and shaftRow.Taper < 1)
			local clear = 0
			for name, row in rows do
				if row.From == "Slam" then
					local _, last = Track.Span(row.Tracks.Transparency or row.Tracks.Scale or row.Tracks.Brightness or row.Tracks.At)
					clear = math.max(clear, mark.Slam + last)
					if row.Kind == "Mesh" then
						t.Check(`{name} shrinks to nothing`, near(at(name, "Scale", 141), 0))
					end
				end
			end
			t.Check("the floor clear by 141 (condition 4)", clear <= 141, tostring(clear))
			t.Check("the street's light out by 140", near(at("SlamLight", "Brightness", 140), 0))
		end,
	},
	{
		-- AR8, "B5's polish and the square's art" (Config.Effects.Haymaker.Stamp.Art; rook_haymaker_rows.json), its keys
		-- counted from Strike, as its content check passed them
		Name = "Track: Haymaker's stamp in its art, against the kit and on its keys",
		Run = function(t: any)
			local s = EffectsConfig.Haymaker.Stamp
			local art = s.Art
			for _, kind in { art.Frame, art.Plate } do
				t.Check(`{kind.Mesh} is the kit's`, FxKit.Meshes[kind.Mesh] ~= nil and FxKit.Meshes[kind.Mesh].Size == Vector3.one)
				t.Check(`{kind.Look} and {kind.Grey} are the kit's looks`, FxKit.Images[kind.Look] ~= nil and FxKit.Images[kind.Grey] ~= nil
					and string.find(FxKit.Images[kind.Look].Use, "^MeshPart") ~= nil)
			end
			t.Check("the frame in its ember, the plate in its rising ember", art.Frame.Look == "fx_across_Ember" and art.Plate.Look == "fx_rise_Ember")
			t.Check("no rail's face in a post's", art.Rails > 0 and art.Rails < 1)
			t.Check("the plate a pane, thinner than the frame", art.Pane > 0 and art.Pane < art.Depth * art.Rails)
			t.Check("Glow 1 through the hang", near(Track.Value(art.Glow, -s.Rise), 1) and near(Track.Value(art.Glow, -1), 1))
			t.Check("Glow 2 on Strike", near(Track.Value(art.Glow, 0), 2))
			t.Check("1 again two frames after", near(Track.Value(art.Glow, 2), 1) and near(Track.Value(art.Glow, 10), 1))
			t.Check("the plate charges through the hang", near(Track.Value(art.Charge, -s.Rise), 0.85) and near(Track.Value(art.Charge, -6), 0.35))
			t.Check("it flashes on Strike", near(Track.Value(art.Charge, 0), 0.15))
			t.Check("gone 3 frames after, before it lies flat", near(Track.Value(art.Charge, 3), 1) and 3 <= #s.Squash)
			t.Check("the hang tightens on a known ease", Track.Known(s.Tighten))
			t.Check("formed loose: over its side, its top edge held as it tightens", s.Forms > 1 and s.FormBar < s.Bar)
			-- TR7, research's call on the hang (c): kept a margin under the top bar's foot, never touching it
			t.Check("kept under the top bar by a margin", s.Under > 0 and s.Under <= 40, tostring(s.Under))
			t.Check("never capped over the keeper (the content check's block, (d))", s.Uncapped.Keeper == true)
		end,
	},
	{
		Name = "Track: a burst at the Effects level keeps one particle above 0, so a one-particle hero shape never drops first, and a tell's keeps one at 0",
		Run = function(t: any)
			t.Equal("one at a tenth: kept", Track.Burst(1, 0.1), 1)
			t.Equal("one at half: kept", Track.Burst(1, 0.49), 1)
			t.Equal("one at full", Track.Burst(1, 1), 1)
			t.Equal("forty at a quarter: the share", Track.Burst(40, 0.25), 10)
			t.Equal("two at a tenth: one", Track.Burst(2, 0.1), 1)
			t.Equal("at 0: none", Track.Burst(1, 0), 0)
			t.Equal("a count of 0: none", Track.Burst(0, 1), 0)
			t.Equal("full: unchanged", Track.Burst(24, 1), 24)
			-- A tell's row (AR52's ward): one at any level, the share above it as any burst's.
			t.Equal("a tell at 0: one", Track.Burst(4, 0, true), 1)
			t.Equal("a tell at a quarter: the share", Track.Burst(40, 0.25, true), 10)
			t.Equal("a tell of 0: none", Track.Burst(0, 0, true), 0)
		end,
	},
	{
		Name = "Track: a landed hit's spark by its rung, the gold star only on a critical, none from a signature's rung (AR61)",
		Run = function(t: any)
			local sparks = EffectsConfig.HitSparks
			local critical = Combat.Hitstop.Critical
			for _, step in sparks.Rungs do
				t.Check(`{step.Name}'s rows are written`, EffectsConfig.Rows[step.Name] ~= nil, step.Name)
			end
			t.Equal("an ordinary hit", Track.Spark(2, false, sparks, critical), "HitSpark2")
			t.Equal("a combo's last", Track.Spark(3, false, sparks, critical), "HitSpark3")
			t.Equal("a critical", Track.Spark(4, true, sparks, critical), "HitSpark4")
			t.Equal("a killing hit lifted to the critical's rung keeps the rung under it", Track.Spark(4, false, sparks, critical), "HitSpark3")
			t.Equal("a rung between: the highest under it", Track.Spark(6, true, sparks, critical), "HitSpark4")
			t.Equal("a signature's rung: none, the old spark", Track.Spark(sparks.Below, true, sparks, critical), nil)
			t.Equal("under the lowest: none", Track.Spark(1, false, sparks, critical), nil)
			local off = table.clone(sparks)
			off.On = false
			t.Equal("switched off: none", Track.Spark(2, false, off, critical), nil)
		end,
	},
}
