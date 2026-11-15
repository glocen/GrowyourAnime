--!strict
-- Author: R6 KeyframeSequences, saved where the Animation Editor finds them (ServerStorage.RBX_ANIMSAVES.R6) and
-- published for the game. Two sources:
--   - clips animated in Blender (tools/blender/r6anim.py), baked to one pose per frame and copied to
--     build/import/Anim_<Name>.txt, which Rojo syncs to ServerStorage.NL_Import. SaveBaked turns one into NL_<Name>.
--   - body-space kits (Animations/<Kit>), the older clips not yet redone in Blender. Save turns their clips into NL_<Name>.
-- Studio, Edit mode, MCP execute_luau:
--   local Author = require(game.ServerStorage.NL_Tools.Animations.Author:Clone())
--   Author.SaveBaked("GrabHold", "GrabHold") -- (re)writes NL_GrabHold from NL_Import.Anim_GrabHold; returns it and a
--     report (length, priority, weights, speed, fades checked against Config.Animations.Fades under the 2nd name)
--   local kit = require(game.ServerStorage.NL_Tools.Animations.Hero:Clone())
--   Author.Save(kit, { "GunBurst" }) -- (re)writes NL_GunBurst
--   local id = Author.Publish("Hero", "GunBurst") -- yields; the id goes into Shared.Config.Animations
--   Author.RestWrists("BladeLight1") -- a clip saved before the weapon wrist gets its wrists at rest; publish it again
-- Kit angles are degrees in body space, converted through the rig's own joint bases (workspace.R6). Positive X raises an
-- arm forward and leans the torso or head forward (their pitch sign is flipped here so all parts read alike). The
-- optional 4th to 6th numbers move the part, in studs.

local AssetService = game:GetService("AssetService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Animations = require(ReplicatedStorage.Shared.Config.Animations)
local ModelRecipe = require(ServerStorage:WaitForChild("NL_Tools"):WaitForChild("ModelRecipe"):Clone()) :: any

export type Pose = { number }
export type Frame = { number | { [string]: Pose } | { string }? }
export type Clip = { Legs: number?, Frames: { Frame } }
export type Kit = { Character: string, Idle: { [string]: Pose }, Clips: { [string]: Clip } }

local PARTS = { "Torso", "Head", "Right Arm", "Left Arm", "Right Leg", "Left Leg" }
local LEGS = { ["Right Leg"] = true, ["Left Leg"] = true }
-- The weapon wrists (Simulation/Equipment): each hand's held part, named for its grip, turns on a joint in its arm, so
-- a clip's grip Pose nests under that arm's Pose.
local GRIPS = { GripR = "Right Arm", GripL = "Left Arm" }
-- Parts a rig carries on a joint of their own, keyed like a grip: their Poses nest under the part they turn on and
-- follow its weight; they get no rest keys. A creature's claws (their Motor6Ds ClawR and ClawL) are written here; each
-- model's own are read from the templates that ship (ModelRecipe.Held: Rook's piston and tape, Pip's hat and lamp,
-- Lyric's stand and speakers, the Lamplighter's pole and the lantern on it, a held part on a held part), so a new
-- model's come with its template.
local HELD: { [string]: string } = {
	GripR = "Right Arm",
	GripL = "Left Arm",
	Creature_ClawsR = "Right Arm",
	Creature_ClawsL = "Left Arm",
}
for part, on in ModelRecipe.Held(ServerStorage:WaitForChild("Templates"):GetChildren()) do
	assert(HELD[part] == nil or HELD[part] == on, `{part}: held on {HELD[part]} here, on {on} in a template`)
	HELD[part] = on
end
local LEANS = { Torso = true, Head = true } -- pitch flips on these: their bases face the other way from an arm's

local Author = {}

-- The place's saved clips, made if missing: a place that never had any would wait forever.
local function saves(): Instance
	local root = ServerStorage:FindFirstChild("RBX_ANIMSAVES")
	if not root then
		root = Instance.new("Folder")
		root.Name = "RBX_ANIMSAVES"
		root.Parent = ServerStorage
	end
	local r6 = (root :: Instance):FindFirstChild("R6")
	if not r6 then
		r6 = Instance.new("Folder")
		r6.Name = "R6"
		r6.Parent = root
	end
	return r6 :: Instance
end

-- A clip that keys an arm keys that arm's wrist too. A loop's grip key shows through a clip that has none, so a clip made while the weapons were welded would swing a weapon bent by whatever loop plays
-- under it. Each driven arm Pose without its grip gets one at rest (the weld's own pose, at the arm's weight), so the
-- weapon sits exactly as the clip was reviewed. Returns how many it added.
local function restWrists(seq: KeyframeSequence): number
	local added = 0
	for _, keyframe in seq:GetKeyframes() do
		for _, pose in keyframe:GetDescendants() do
			for grip, arm in GRIPS do
				if pose:IsA("Pose") and pose.Name == arm and pose.Weight > 0 and not pose:FindFirstChild(grip) then
					local wrist = Instance.new("Pose")
					wrist.Name = grip
					wrist.Weight = pose.Weight
					wrist.EasingStyle = pose.EasingStyle
					wrist.EasingDirection = pose.EasingDirection
					wrist.Parent = pose
					added += 1
				end
			end
		end
	end
	return added
end

local function bases(): { [string]: CFrame }
	local result = {}
	for _, motor in workspace:WaitForChild("R6"):GetDescendants() do
		if motor:IsA("Motor6D") and motor.Part1 then
			result[motor.Part1.Name] = motor.C0.Rotation
		end
	end
	return result
end

local function sequence(kit: Kit, name: string, clip: Clip, basis: { [string]: CFrame }): KeyframeSequence
	local seq = Instance.new("KeyframeSequence")
	seq.Name = "NL_" .. name
	seq.Priority = Enum.AnimationPriority.Action2
	seq.Loop = false
	seq:SetAttribute("Character", kit.Character)
	seq:SetAttribute("Source", "tools/studio/Animations/" .. kit.Character)
	for _, frame in clip.Frames do
		local time, body, markers = frame[1] :: number, frame[2] :: { [string]: Pose }, frame[3] :: { string }?
		local keyframe = Instance.new("Keyframe")
		keyframe.Name = "Pose"
		keyframe.Time = time
		keyframe.Parent = seq
		local root = Instance.new("Pose")
		root.Name = "HumanoidRootPart"
		root.Weight = 0
		root.Parent = keyframe
		local torsoPose = Instance.new("Pose")
		for _, part in PARTS do
			local pose = if part == "Torso" then torsoPose else Instance.new("Pose")
			pose.Name = part
			pose.Parent = if part == "Torso" then root else torsoPose
			local data = body[part] or kit.Idle[part] or { 0, 0, 0 }
			local turn = CFrame.Angles(math.rad(if LEANS[part] then -data[1] else data[1]), math.rad(data[2]), math.rad(data[3]))
			local move = CFrame.new(data[4] or 0, data[5] or 0, data[6] or 0)
			local b = basis[part] or CFrame.identity
			pose.CFrame = b:Inverse() * (move * turn) * b
			pose.Weight = if LEGS[part] then (clip.Legs or 1) else 1
			pose.EasingStyle = Enum.PoseEasingStyle.CubicV2
			pose.EasingDirection = Enum.PoseEasingDirection.InOut
		end
		for _, marker in markers or {} do
			local m = Instance.new("KeyframeMarker")
			m.Name = marker
			m.Parent = keyframe
		end
	end
	restWrists(seq)
	return seq
end

-- Writes the named clips (all when `names` is nil) into RBX_ANIMSAVES.R6, replacing earlier versions.
function Author.Save(kit: Kit, names: { string }?): { string }
	local basis = bases()
	local folder = saves()
	local written = {}
	for name, clip in kit.Clips do
		if names == nil or table.find(names, name) then
			local old = folder:FindFirstChild("NL_" .. name)
			if old then
				old:Destroy()
			end
			sequence(kit, name, clip, basis).Parent = folder
			table.insert(written, name)
		end
	end
	return written
end

-- The fields a baked clip may carry (r6anim.py's export, and the extras each clip script adds) and their JSON types.
-- SaveBaked fails on any other, so a renamed or misspelled field is never dropped silently.
local FIELDS: { [string]: string } = {
	Name = "string", Character = "string", Source = "string", Legs = "number", Fps = "number", Frames = "table",
	Markers = "table", Loop = "boolean", Priority = "string", FadeIn = "number", FadeOut = "number", Weights = "table",
	Speed = "number", StudsPerLoop = "number", Heading = "number", TurnRate = "number", DegreesPerLoop = "number", SyncTo = "string",
	Release = "table", Telegraph = "number",
}

-- What's wrong with a baked clip, if anything: unknown or mistyped fields, a Name that isn't the file's, an unknown
-- Priority, weights outside 0..1 or on unknown parts, frames out of order or missing a part, markers off the clip.
local function problems(clip: any, name: string): { string }
	local found = {}
	local function fail(text: string)
		table.insert(found, text)
	end
	if type(clip) ~= "table" then
		return { "not a JSON object" }
	end
	for key, value in clip do
		local kind = FIELDS[key]
		if not kind then
			fail(`unknown field {key}`)
		elseif type(value) ~= kind then
			fail(`{key} is a {type(value)}, not a {kind}`)
		end
	end
	if clip.Name ~= name then
		fail(`its Name is {tostring(clip.Name)}, not {name}`)
	end
	if type(clip.Priority) == "string" and not pcall(function()
		return (Enum.AnimationPriority :: any)[clip.Priority]
	end) then
		fail(`no priority {clip.Priority}`)
	end
	local function unit(value: any): boolean
		return type(value) == "number" and value >= 0 and value <= 1
	end
	if clip.Legs ~= nil and not unit(clip.Legs) then
		fail(`Legs {clip.Legs} isn't 0..1`)
	end
	for _, fade in { "FadeIn", "FadeOut" } do
		if type(clip[fade]) == "number" and clip[fade] < 0 then
			fail(`{fade} is negative`)
		end
	end
	if type(clip.Fps) == "number" and clip.Fps <= 0 then
		fail("Fps isn't positive")
	end
	local known: { [string]: boolean } = {}
	for _, part in PARTS do
		known[part] = true
	end
	for held in HELD do
		known[held] = true
	end
	if type(clip.Weights) == "table" then
		for part, weight in clip.Weights do
			if not known[part] or not unit(weight) then
				fail(`Weights.{part} = {tostring(weight)}`)
			end
		end
	end
	local function transform(value: any): boolean
		if type(value) ~= "table" or #value ~= 12 then
			return false
		end
		for _, n in value do
			if type(n) ~= "number" or n ~= n then
				return false
			end
		end
		return true
	end
	local last = -math.huge
	local frames = if type(clip.Frames) == "table" then clip.Frames else {}
	if #frames == 0 then
		fail("no frames")
	end
	for i, frame in frames do
		if type(frame) ~= "table" or type(frame.T) ~= "number" or type(frame.Poses) ~= "table" then
			fail(`frame {i} isn't \{ T, Poses }`)
			continue
		end
		if frame.T <= last then
			fail(`frame {i} at {frame.T} s isn't after the one before`)
		end
		last = frame.T
		for _, part in PARTS do
			if not transform(frame.Poses[part]) then
				fail(`frame {i} has no 12-number {part}`)
			end
		end
		for part, value in frame.Poses do
			if not known[part] then
				fail(`frame {i} poses an unknown part {part}`)
			elseif HELD[part] and not transform(value) then
				fail(`frame {i} has a malformed {part}`)
			end
		end
	end
	if #frames > 0 and type(frames[1]) == "table" and frames[1].T ~= 0 then
		fail(`the first frame is at {tostring(frames[1].T)} s, not 0`)
	end
	for i, marker in if type(clip.Markers) == "table" then clip.Markers else {} do
		if type(marker) ~= "table" or type(marker.Name) ~= "string" or type(marker.T) ~= "number" or marker.T < 0 or marker.T > last then
			fail(`marker {i} isn't a \{ T, Name } within the clip`)
		end
	end
	return found
end

-- A baked clip in one line: its length, keyframes, priority, legs, weights, speed and fades, the fades checked against
-- the game's (Shared.Config.Animations.Fades) under its name there, `as`.
local function describe(clip: any, seq: KeyframeSequence, as: string?): string
	local frames = clip.Frames
	local parts = {}
	if clip.Weights then
		for _, part in PARTS do
			local weight = clip.Weights[part]
			if weight ~= nil and weight ~= 1 then
				table.insert(parts, `{part} {weight}`)
			end
		end
	end
	local motion = {}
	for _, field in { "Speed", "StudsPerLoop", "Heading", "TurnRate", "DegreesPerLoop" } do
		if clip[field] ~= nil then
			table.insert(motion, `{field} {clip[field]}`)
		end
	end
	local fades = if clip.FadeIn or clip.FadeOut then `fades in {clip.FadeIn or "?"}, out {clip.FadeOut or "?"}` else "no fades"
	if as then
		local game = (Animations.Fades :: any)[as]
		if not game then
			fades ..= ` (Config has none for {as}: AnimationSim's own apply)`
		elseif game.In ~= clip.FadeIn or game.Out ~= clip.FadeOut then
			fades ..= ` (MISMATCH: Config.Fades.{as} is in {game.In}, out {game.Out})`
		else
			fades ..= ` (as Config.Fades.{as})`
		end
	end
	return string.format("%s: %.3f s, %d keyframes at %s fps, %s, %s; legs %s%s%s; %s; %d markers",
		seq.Name, frames[#frames].T, #frames, tostring(clip.Fps), seq.Priority.Name, if seq.Loop then "looped" else "once",
		tostring(clip.Legs or 1), if #parts > 0 then "; weights " .. table.concat(parts, ", ") .. ", the rest 1" else "",
		if #motion > 0 then "; " .. table.concat(motion, ", ") else "", fades, #(clip.Markers or {}))
end

-- A clip baked in Blender (tools/blender/r6anim.py), from NL_Import.Anim_<name>: JSON with the clip's Character, its
-- Legs weight, Frames ({ T, Poses = { [part] = the Motor6D Transform's 12 CFrame components } }, one per frame, so
-- they're joined linearly), Markers ({ T, Name }), and Loop and Priority when it sets them (else a one-shot at
-- Action2). Weights ({ [part] = weight }) override a part's weight (else the legs take Legs and the rest 1). A frame's
-- GripR and GripL turn the weapons on their wrists (GRIPS), and a rig's held parts turn under their arms the same way
-- (HELD: the Creature's claws, Rook's piston and tape); a driven arm without its grip holds it at rest
-- (restWrists). A limb at weight 0 is left out, so the loops under the clip pose it (leaving it out and a Pose
-- at weight 0 blend alike, and Pose.Weight is deprecated); the Torso stays, at weight 0, as the container a keyed arm,
-- head or leg needs. Fails on a malformed clip (problems). Writes NL_<name> into RBX_ANIMSAVES.R6, replacing an earlier
-- one, and returns it with a one-line report, its fades checked against Config's under the game's name for it, `as`.
function Author.SaveBaked(name: string, as: string?): (KeyframeSequence, string)
	local source = ServerStorage:WaitForChild("NL_Import"):FindFirstChild("Anim_" .. name)
	assert(source and source:IsA("StringValue"), `NL_Import.Anim_{name} is missing: copy the baked JSON to build/import`)
	local clip = HttpService:JSONDecode(source.Value)
	local wrong = problems(clip, name)
	assert(#wrong == 0, `Anim_{name}: {table.concat(wrong, "; ")}`)
	local seq = Instance.new("KeyframeSequence")
	seq.Name = "NL_" .. name
	seq.Priority = if clip.Priority then (Enum.AnimationPriority :: any)[clip.Priority] else Enum.AnimationPriority.Action2
	seq.Loop = clip.Loop == true
	seq:SetAttribute("Character", clip.Character)
	seq:SetAttribute("Source", clip.Source)
	local keyframes: { Keyframe } = {}
	for _, frame in clip.Frames do
		local keyframe = Instance.new("Keyframe")
		keyframe.Name = "Pose"
		keyframe.Time = frame.T
		keyframe.Parent = seq
		table.insert(keyframes, keyframe)
		local root = Instance.new("Pose")
		root.Name = "HumanoidRootPart"
		root.Weight = 0
		root.Parent = keyframe
		local torsoPose = Instance.new("Pose")
		local poses: { [string]: Pose } = {}
		local function weight(part: string): number
			local given = clip.Weights and clip.Weights[part]
			if type(given) == "number" then
				return given
			end
			-- a wrist the clip doesn't weigh follows its arm, so a clip that leaves an arm to the loops leaves its weapon
			-- too (at weight 1 the blade swings' and the burst lowering's gun wrist took the gun from the burst: B1c)
			local arm = HELD[part]
			if arm then
				-- the Torso at weight 0 is only the container a keyed part needs (a layer that leaves the body to the clips
				-- under it: Kirra's tail layers over the open set, AR10), so a part held on it keeps its own 1
				if arm == "Torso" and weight("Torso") <= 0 then
					return 1
				end
				return weight(arm)
			end
			return if LEGS[part] then (clip.Legs or 1) else 1
		end
		for _, part in PARTS do
			if part ~= "Torso" and weight(part) <= 0 then
				continue -- left to the loops under the clip
			end
			local pose = if part == "Torso" then torsoPose else Instance.new("Pose")
			pose.Name = part
			pose.Parent = if part == "Torso" then root else torsoPose
			pose.CFrame = CFrame.new(table.unpack(frame.Poses[part]))
			pose.Weight = weight(part)
			pose.EasingStyle = Enum.PoseEasingStyle.Linear
			poses[part] = pose
		end
		-- Held parts, each under its kept arm (or kept held part: the Lamplighter's lantern on its pole), parents first; a
		-- wrist weighted 0 there stays at 0, or restWrists would hold it at the arm's weight.
		local pending: { string } = {}
		for grip in HELD do
			if frame.Poses[grip] then
				table.insert(pending, grip)
			end
		end
		local placed = true
		while placed and #pending > 0 do
			placed = false
			for index = #pending, 1, -1 do
				local grip = pending[index]
				local arm = HELD[grip]
				if poses[arm] then
					local pose = Instance.new("Pose")
					pose.Name = grip
					pose.Parent = poses[arm]
					pose.CFrame = CFrame.new(table.unpack(frame.Poses[grip]))
					pose.Weight = weight(grip)
					pose.EasingStyle = Enum.PoseEasingStyle.Linear
					poses[grip] = pose
					table.remove(pending, index)
					placed = true
				end
			end
		end
	end
	for _, marker in clip.Markers or {} do
		local nearest = keyframes[1]
		for _, keyframe in keyframes do
			if math.abs(keyframe.Time - marker.T) < math.abs(nearest.Time - marker.T) then
				nearest = keyframe
			end
		end
		local m = Instance.new("KeyframeMarker")
		m.Name = marker.Name
		m.Parent = nearest
	end
	restWrists(seq)
	local folder = saves()
	local old = folder:FindFirstChild(seq.Name)
	if old then
		old:Destroy()
	end
	seq.Parent = folder
	local report = describe(clip, seq, as)
	print(report)
	return seq, report
end

-- Gives a clip saved before the weapon wrist its wrists at rest (restWrists), in place; returns how many grip Poses it
-- added (0: it keys them already). Publish it again for the game to see it.
function Author.RestWrists(name: string): number
	local seq = saves():FindFirstChild("NL_" .. name)
	assert(seq and seq:IsA("KeyframeSequence"), `NL_{name} isn't saved`)
	return restWrists(seq)
end

-- Publishes a saved clip as an Animation asset owned by the place's creator (the group, in the group's places); returns
-- its id. Yields.
function Author.Publish(character: string, name: string): number
	local seq = saves():FindFirstChild("NL_" .. name)
	assert(seq and seq:IsA("KeyframeSequence"), `NL_{name} isn't saved; run Author.Save or Author.SaveBaked first`)
	local source = seq:GetAttribute("Source") or `tools/studio/Animations/{character}`
	local result, id = AssetService:CreateAssetAsync(seq:Clone(), Enum.AssetType.Animation, {
		Name = `NL_{character}_{name}`,
		Description = `{character}'s {name} ({source}).`,
		CreatorId = game.CreatorId,
		CreatorType = if game.CreatorType == Enum.CreatorType.Group
			then Enum.AssetCreatorType.Group
			else Enum.AssetCreatorType.User,
	})
	assert(result == Enum.CreateAssetResult.Success, `{name}: {result}`)
	return id
end

return Author
