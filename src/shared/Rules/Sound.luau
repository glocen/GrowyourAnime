--!strict
-- Sound (pure): a cue's levelling (Config.Sounds). Each cue's slice is brought to the reference, then mixed by `db`. A
-- cue in the world is levelled within the bounds, so no quiet file comes up 6 dB with its noise. A cue on the screen is
-- mixed well under the reference (Config.Reveal.Sounds), so there the bound is on the file's whole amplification: a
-- quiet file played quieter still brings no noise up. The client's FighterController/Sounds plays what this says.

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config.Sounds)

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

return Sound
