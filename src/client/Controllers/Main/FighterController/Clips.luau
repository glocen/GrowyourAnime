--!strict
-- Clips (client): an Animation for each clip name. A published clip plays from its id (Config.Animations.Ids). In Studio
-- an unpublished one is registered from its KeyframeSequence, which the server hands every client in
-- ReplicatedStorage.NL_Clips (FightService); under AuthorityMode Automatic that plays at full weight
-- (handbook/art/animation.md). Live, a clip with no id has no Animation, and its fighter simply holds still.

local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Animations = require(ReplicatedStorage.Shared.Config.Animations)
local Actions = require(ReplicatedStorage.Shared.Definitions.Actions)

local FOLDER = "NL_Clips"
local WAIT = 10 -- seconds to wait for the server's copies in a Studio run

local Clips = {}

local cache: { [string]: Animation } = {}

-- The KeyframeSequence a Studio run carries for `clip`, or nil.
function Clips.Sequence(clip: string): KeyframeSequence?
	local folder = ReplicatedStorage:FindFirstChild(FOLDER) or (if RunService:IsStudio() then ReplicatedStorage:WaitForChild(FOLDER, WAIT) else nil)
	local found = if folder then folder:FindFirstChild("NL_" .. clip) else nil
	return if found and found:IsA("KeyframeSequence") then found else nil
end

function Clips.Animation(clip: string): Animation?
	local cached = cache[clip]
	if cached then
		return cached
	end
	local id: string? = nil
	local published = Animations.Ids[clip]
	if published then
		id = `rbxassetid://{published}`
	elseif RunService:IsStudio() then
		local sequence = Clips.Sequence(clip)
		if sequence then
			id = KeyframeSequenceProvider:RegisterKeyframeSequence(sequence)
		end
	end
	if id == nil then
		return nil
	end
	local animation = Instance.new("Animation")
	animation.Name = clip
	animation.AnimationId = id
	cache[clip] = animation
	return animation
end

-- The fades for `clip`, by its role (Definitions.Actions, RoleOf).
function Clips.Fades(clip: string): (number, number)
	local role = Actions.RoleOf(clip)
	local fades = if role then (Animations.Fades :: any)[role] else nil
	if fades then
		local snap = Animations.Snap -- the attack clips' live test (TR69 A)
		return if snap.On and role and snap.Roles[role] then snap.In else fades.In, fades.Out
	end
	return 0.1, 0.1
end

return Clips
