--!strict
-- Sounds (client): plays a cue (Config.Sounds) as a point in the world: its slice of the library file, levelled to the
-- reference, its pitch spread, through the combat group (handbook/visuals/audio.md, "At runtime"). Every cue is preloaded
-- once, so the first press isn't late. The numbers are read at each play, so a tune is heard on the next one.
--   Sounds.Play("HaymakerStrike", knuckles)   the Sound it plays, or nil for an unknown cue

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage.Shared.Config.Sounds)

local Sounds = {}

local GROUP_NAME = "NL_Combat"
local AFTER = 0.15 -- seconds a sound's point stays past its slice

local random = Random.new()

local group: SoundGroup? = nil
local function combat(): SoundGroup
	if group == nil or group.Parent == nil then
		local made = SoundService:FindFirstChild(GROUP_NAME) :: SoundGroup? or Instance.new("SoundGroup")
		made.Name = GROUP_NAME
		made.Parent = SoundService
		group = made
	end
	local g = group :: SoundGroup
	g.Volume = Config.Combat
	return g
end

function Sounds.Play(name: string, at: Vector3): Sound?
	local cue = (Config.Cues :: { [string]: Config.Cue })[name]
	if cue == nil then
		return nil
	end
	local point = Instance.new("Attachment")
	point.Name = "NL_Sound"
	point.WorldPosition = at
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = `rbxassetid://{cue.Id}`
	sound.PlaybackRegionsEnabled = true
	sound.PlaybackRegion = NumberRange.new(cue.From, cue.To)
	local gain = math.clamp(10 ^ ((Config.Reference - cue.Level) / 20), Config.Gain[1], Config.Gain[2])
	sound.Volume = cue.Volume * gain
	local low = math.min(cue.Pitch[1], cue.Pitch[2])
	sound.PlaybackSpeed = low + random:NextNumber() * (math.max(cue.Pitch[1], cue.Pitch[2]) - low)
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = cue.Near
	sound.RollOffMaxDistance = cue.Range
	sound.SoundGroup = combat()
	sound.Parent = point
	point.Parent = workspace.Terrain
	sound:Play()
	task.delay((cue.To - cue.From) / math.max(low, 0.01) + AFTER, function()
		point:Destroy()
	end)
	return sound
end

-- Every cue fetched once, so its first play lands on its frame (handbook/visuals/audio.md: Roblox fetches a sound on its
-- first play).
function Sounds.Preload()
	local probes: { Instance } = {}
	for name, cue in Config.Cues :: { [string]: Config.Cue } do
		local probe = Instance.new("Sound")
		probe.Name = name
		probe.SoundId = `rbxassetid://{cue.Id}`
		table.insert(probes, probe)
	end
	task.spawn(function()
		pcall(ContentProvider.PreloadAsync, ContentProvider, probes)
		for _, probe in probes do
			probe:Destroy()
		end
	end)
end

return Sounds
