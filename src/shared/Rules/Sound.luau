--!strict
-- Sound (pure): a cue's levelling (Config.Sounds). Each cue's slice is brought to the reference, then mixed by `db`. A
-- cue in the world is levelled within the bounds, so no quiet file comes up 6 dB with its noise. A cue on the screen is
-- mixed well under the reference (Config.Reveal.Sounds), so there the bound is on the file's whole amplification: a
-- quiet file played quieter still brings no noise up. The client's FighterController/Sounds plays what this says.
-- And the fight's layered cues (Config.Cues; AR13): which one a hit's beat or its touch plays, and when each layer starts.
-- FighterController/Cues plays them.

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config.Sounds)
local Cues = require(Shared.Config.Cues)

local Sound = {}

-- The gain that brings a cue's slice to the reference, unbounded.
function Sound.Gain(cue: Config.Cue): number
	return 10 ^ ((Config.Reference - cue.Level) / 20)
end

-- Whether a cue only ever plays on the screen: no distance at which it fades.
function Sound.Screen(cue: Config.Cue): boolean
	return cue.Near == 0 and cue.Range == 0
end

-- A Sound's Volume for a cue played `db` under the mix's loudest, in the world or, when `screen`, on the screen.
function Sound.Volume(cue: Config.Cue, db: number, screen: boolean?): number
	local gain = Sound.Gain(cue)
	if screen then
		return math.min(cue.Volume * math.max(gain, Config.Gain[1]) * 10 ^ (db / 20), Config.Gain[2])
	end
	return cue.Volume * math.clamp(gain, Config.Gain[1], Config.Gain[2]) * 10 ^ (db / 20)
end

-- The cue a hit's beat plays on its attacker's clock, landed or not: a Shade's swing, or anyone else's heavy hit's wind-up.
function Sound.Beat(action: string, heavy: boolean, side: string?): string?
	if action == "ShadeSwipe" then
		return "ShadeSwipe"
	end
	return if heavy and side ~= "Shade" then "HeavyWind" else nil
end

-- The cues a hit plays as it lands, on the struck body: the attacker's light or heavy hit unless it's a Shade's, and a
-- Shade's hurt when a Shade is struck. A Shade's hit on a fighter plays none of the six (the lead's own hurt waits).
function Sound.Contact(heavy: boolean, side: string?, struck: string?): { string }
	local cues = {}
	if side ~= "Shade" then
		table.insert(cues, if heavy then "HeavyHit" else "LightHit")
	end
	if struck == "Shade" then
		table.insert(cues, "ShadeHurt")
	end
	return cues
end

-- The shing a critical adds on the server's word, to the fighters' hits only.
function Sound.Critical(side: string?): string?
	return if side ~= "Shade" then "Critical" else nil
end

-- A hit's strength for a layer that follows it (Config.Cues.Strength): 0 at the lightest rung, 1 at the heaviest.
function Sound.Strength(rung: number): number
	local low, high = Cues.Strength[1], Cues.Strength[2]
	return math.clamp((rung - low) / math.max(high - low, 1e-6), 0, 1)
end

-- When a layer starts, in seconds from its cue's moment, playing `take` at `speed`: a layer led by its top or its length
-- starts that much earlier, so its top or its end lands on the moment.
function Sound.Start(layer: Cues.Layer, take: Cues.Take, speed: number): number
	local lead = if layer.Lead == "Peak" then take.Peak elseif layer.Lead == "Length" then take.Seconds else 0
	return layer.At - lead / math.max(speed, 1e-6)
end

-- How long before its moment a cue's earliest layer can start, at its slowest pick: a beat's cue begins when its
-- attacker's clock is that far from the beat.
function Sound.Ahead(cue: Cues.Cue): number
	local slowest = math.min(cue.Pitch[1], cue.Pitch[2])
	local ahead = 0
	for _, layer in cue.Layers do
		for _, take in Cues.Takes[layer.Takes] or {} do
			ahead = math.max(ahead, -Sound.Start(layer, take, slowest))
		end
	end
	return ahead
end

return Sound
