--!strict
-- Sounds (client): plays a cue (Config.Sounds) as a point in the world: its slice of the library file, levelled to the
-- reference, its pitch spread, through the combat group (handbook/visuals/audio.md, "At runtime"). Every cue is preloaded
-- once and one Sound of each kept loaded, so a play starts on its frame. The numbers are read at each play, so a tune is
-- heard on the next one.
--   Sounds.Play("HaymakerStrike", knuckles)   the Sound it plays, or nil for an unknown cue
--   Sounds.Flat("RevealName", -4, 1, group)  a cue on the screen, not in the world, through `group` (the reveal's)
--   Sounds.Duck(-6)                           the world's groups taken down by that many dB, 0 to put them back

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config.Sounds)
local SoundRule = require(ReplicatedStorage.Shared.Rules.Sound)

local Sounds = {}

local GROUP_NAME = "NL_Combat"
local AFTER = 0.15 -- seconds a sound's point stays past its slice

local DUCK_TIME = 0.15 -- seconds the world's groups take to go down or come back
local BANK_NAME = "NL_SoundBank"

local random = Random.new()
local duck = 1 -- the world's groups' share while something above them plays (Sounds.Duck)
-- One Sound per cue, never played, kept so its file stays loaded: a new Sound waits 0.28 to 0.35 s to load even with its
-- file cached, unless another Sound of that file is alive, and a clone of a loaded one starts within a frame (measured in
-- a Studio playtest, 2026-11-13).
local bank: Folder? = nil

local function named(name: string): SoundGroup
	local found = SoundService:FindFirstChild(name)
	if found and found:IsA("SoundGroup") then
		return found
	end
	local made = Instance.new("SoundGroup")
	made.Name = name
	made.Parent = SoundService
	return made
end

local group: SoundGroup? = nil
local function combat(): SoundGroup
	if group == nil or group.Parent == nil then
		group = named(GROUP_NAME)
	end
	local g = group :: SoundGroup
	g.Volume = Config.Combat * duck
	return g
end

-- A cue's slice of its library file, levelled (Rules.Sound) for the world or the screen: a Sound not yet parented or played.
local function slice(name: string, cue: Config.Cue, db: number, speed: number, screen: boolean?): Sound
	local kept = if bank then bank:FindFirstChild(name) else nil
	local sound = if kept and kept:IsA("Sound") then kept:Clone() else Instance.new("Sound")
	sound.Name = name
	local id = `rbxassetid://{cue.Id}`
	if sound.SoundId ~= id then
		sound.SoundId = id
	end
	sound.PlaybackRegionsEnabled = true
	sound.PlaybackRegion = NumberRange.new(cue.From, cue.To)
	sound.Volume = SoundRule.Volume(cue, db, screen)
	sound.PlaybackSpeed = speed
	return sound
end

function Sounds.Play(name: string, at: Vector3): Sound?
	local cue = (Config.Cues :: { [string]: Config.Cue })[name]
	if cue == nil then
		return nil
	end
	local point = Instance.new("Attachment")
	point.Name = "NL_Sound"
	point.WorldPosition = at
	local low = math.min(cue.Pitch[1], cue.Pitch[2])
	local sound = slice(name, cue, 0, low + random:NextNumber() * (math.max(cue.Pitch[1], cue.Pitch[2]) - low))
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

-- A cue on the screen, not in the world: its slice levelled, `db` against the mix's loudest, at `speed`, through
-- `group`, looped over its slice when `loop`. It cleans itself up once its slice has played (a looped one when stopped).
function Sounds.Flat(name: string, db: number, speed: number, into: SoundGroup, loop: boolean?): Sound?
	local cue = (Config.Cues :: { [string]: Config.Cue })[name]
	if cue == nil then
		return nil
	end
	local sound = slice(name, cue, db, speed, true)
	sound.Looped = loop == true
	if loop then
		sound.LoopRegion = NumberRange.new(cue.From, cue.To)
	end
	sound.SoundGroup = into
	sound.Parent = into
	sound:Play()
	if not loop then
		task.delay((cue.To - cue.From) / math.max(speed, 0.01) + AFTER, function()
			sound:Destroy()
		end)
	end
	return sound
end

-- The group a screen's sounds go through, made once, at its fader.
function Sounds.Group(name: string, volume: number): SoundGroup
	local g = named(name)
	g.Volume = volume
	return g
end

-- The world's groups taken down by `db` (0 puts them back), over a moment: a screen's sounds above them.
function Sounds.Duck(db: number)
	duck = 10 ^ (math.min(db, 0) / 20)
	if group == nil or (group :: SoundGroup).Parent == nil then
		group = named(GROUP_NAME)
	end
	TweenService:Create(group :: SoundGroup, TweenInfo.new(DUCK_TIME), { Volume = Config.Combat * duck }):Play()
end

-- A cue's slice in seconds at speed 1, or nil for an unknown cue.
function Sounds.Length(name: string): number?
	local cue = (Config.Cues :: { [string]: Config.Cue })[name]
	return if cue then cue.To - cue.From else nil
end

-- Every cue fetched once and held in the bank, so each play lands on its frame (handbook/visuals/audio.md: Roblox fetches
-- a sound on its first play; and see the bank, above).
function Sounds.Preload()
	if bank and (bank :: Folder).Parent then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = BANK_NAME
	local probes: { Instance } = {}
	for name, cue in Config.Cues :: { [string]: Config.Cue } do
		local probe = Instance.new("Sound")
		probe.Name = name
		probe.SoundId = `rbxassetid://{cue.Id}`
		probe.Volume = 0
		probe.Parent = folder
		table.insert(probes, probe)
	end
	folder.Parent = SoundService
	bank = folder
	task.spawn(function()
		pcall(ContentProvider.PreloadAsync, ContentProvider, probes)
	end)
end

return Sounds
