--!strict
-- Rows (client): the one effect player (AR8, "The method"). It plays an effect's rows from Config.Effects.Rows: the kit's
-- parts (ReplicatedStorage.Shared.Assets.FxKit, built by tools/studio/Models/FxKit.luau), cards, emitters and lights,
-- each placed on what it rides and driven by its tracks (Rules.Track), so no effect gets code of its own. The caller owns
-- the clock: Step(frames) takes frames after the effect's marker at the clip's 60 a second, fractions and all, and says
-- whether the effect still lives. The tracks are read every step, so a Tune shows at once; an emitter's properties and the
-- kit's parts are set when it plays, so a Tune there shows on the next.
-- An action's effect (Effects.Play) passes its body, its beats, its target, its hits and its cooldown: a row's From names
-- the beat its keys count from, a Body row rides a point of the body, a Glow row lights one of its parts, put back as it
-- was at the end, a Streak row is thrown at the target, a Sound row plays its cue, and a Relight row relights a part
-- over the cooldown. A streak and a relight, once begun, run their own time (Options.Run), past the effect's end.
-- A look is a SurfaceAppearance template, its texture its own emissive mask, cloned onto the part: a script can't set a
-- look's maps. It can't be preloaded either, so Warm draws every kit mesh and look once, unseen, at load, and the first
-- effect never pops in late (handbook/visuals/vfx-engine-facts.md, "Preloading").

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EffectsConfig = require(ReplicatedStorage.Shared.Config.Effects)
local FxKit = require(ReplicatedStorage.Shared.Config.FxKit)
local Track = require(ReplicatedStorage.Shared.Rules.Track)
local Actions = require(ReplicatedStorage.Shared.Definitions.Actions)
local Sounds = require(script.Parent.Sounds)
local SettingsController = require(script.Parent.Parent.Parent.Core.SettingsController)

local Rows = {}

local FRAME = 1 / 60 -- the clip's frame
local WARM_SECONDS = 2 -- how long Warm keeps the kit drawn, unseen
local WARM_SIZE = 0.02 -- studs: the warm pass's parts, under a pixel at WARM_AHEAD
local WARM_AHEAD = 4 -- studs in front of the camera
local CARRIER = 0.05 -- studs: an invisible part that carries a card, an emitter or a light

export type Player = {
	Name: string,
	Step: (frames: number) -> boolean,
	Destroy: () -> (),
	-- Lets go of the body (it fell, or its action ended early): its glows put back, the rows that ride it gone; the rest
	-- play on in their own time.
	Let: () -> (),
	End: number, -- the frame the last row is done, particles included
	Parts: (row: string) -> { Instance }, -- what a row made, for the self-test
}

export type Options = {
	Body: Model?, -- what Body rows ride and Glow rows light
	Marks: { [string]: number }?, -- the frames of its action's beats from the action's start, for each row's From
	Target: (() -> BasePart?)?, -- where its action's target stands, for a Streak row, and a Beam row's High = "Target"
	Hits: { [string]: Actions.Hit }?, -- its action's hits by beat: a Streak row's on its From beat sets its width
	Cooldown: number?, -- seconds from its action's start until it may start again, for a Relight row
	-- Runs a step each frame with the seconds since it began, until it says false, then `done`: what a streak or a
	-- relight lives on (Effects' own, which a capture's TimeScale holds); none: on Heartbeat
	Run: ((step: (age: number) -> boolean, done: () -> ()) -> ())?,
	Tint: Color3?, -- a Tint row's colour in place of its Color (TR69 A's G1: the Shade's type's)
}

local kit: Folder? = nil
local function kitFolder(): Instance
	if kit == nil then
		kit = (ReplicatedStorage :: any).Shared:WaitForChild("Assets"):WaitForChild("FxKit")
	end
	return kit :: any
end

local folder: Folder? = nil
local function home(): Folder
	if folder == nil or folder.Parent == nil then
		local made = Instance.new("Folder")
		made.Name = "NL_Rows"
		made.Parent = workspace
		folder = made
	end
	return folder :: Folder
end

local function grey(colour: Color3): Color3
	local y = 0.299 * colour.R + 0.587 * colour.G + 0.114 * colour.B
	return Color3.new(y, y, y)
end

-- An image's id: the kit's (Config.FxKit), or one of the effects' own pictures (Config.Effects.Pictures; "" until it's
-- uploaded).
local function imageId(name: string): string
	local image = FxKit.Images[name]
	if image then
		return image.Id
	end
	local picture = EffectsConfig.Pictures[name]
	assert(picture ~= nil, `no image "{name}"`)
	return picture
end

-- A fresh copy of a kit mesh in a kit look, unseen and not yet parented: a row's part, or a coded effect's (Haymaker's
-- stamp). With no look it's a flat light in its Color.
function Rows.Mesh(partName: string, lookName: string?): (MeshPart, SurfaceAppearance?)
	local templates = kitFolder()
	local template = (templates :: any).Meshes:FindFirstChild(partName)
	assert(template and FxKit.Meshes[partName], `no kit mesh "{partName}"`)
	local lookTemplate = if lookName then (templates :: any).Looks:FindFirstChild(lookName) else nil
	assert(lookName == nil or lookTemplate, `no kit look "{lookName}"`)
	local part = template:Clone() :: MeshPart
	part.Transparency = 1
	local look: SurfaceAppearance? = nil
	if lookTemplate then
		look = lookTemplate:Clone()
		look.Parent = part
	else
		part.Material = Enum.Material.Neon
	end
	return part, look
end

local function carrier(): Part
	local p = Instance.new("Part")
	p.Name = "NL_RowCarrier"
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Transparency = 1
	p.Size = Vector3.one * CARRIER
	p.Parent = home()
	return p
end

-- A row's first and last frames, over all its tracks, bands and emits.
local function span(row: EffectsConfig.Row): (number, number)
	local first: number, last: number = math.huge, -math.huge
	local function take(keys: { EffectsConfig.Key }?)
		if keys and #keys > 0 then
			local a: number, b: number = Track.Span(keys)
			first, last = math.min(first, a), math.max(last, b)
		end
	end
	for _, keys in row.Tracks do
		take(keys)
	end
	for _, tracks in row.Bands or {} do
		for _, keys in tracks do
			take(keys)
		end
	end
	for _, emit in row.Emit or {} do
		local frame: number = emit[1] :: number
		first, last = math.min(first, frame), math.max(last, frame)
	end
	if first == math.huge then
		return 0, 0
	end
	return first, last
end

-- An emitter property from a row's plain value, by the type the property already has.
local function convert(current: any, value: any, greyed: boolean): any
	local kind = typeof(current)
	if kind == "NumberRange" then
		return if type(value) == "table" then NumberRange.new(value[1], value[2]) else NumberRange.new(value)
	elseif kind == "NumberSequence" then
		if type(value) ~= "table" then
			return NumberSequence.new(value :: number)
		elseif type(value[1]) == "number" then -- a pair: a random value between them
			local mid, half = (value[1] + value[2]) / 2, math.abs(value[2] - value[1]) / 2
			return NumberSequence.new({ NumberSequenceKeypoint.new(0, mid, half), NumberSequenceKeypoint.new(1, mid, half) })
		end
		local points = {}
		for _, point in value do
			table.insert(points, NumberSequenceKeypoint.new(point[1], point[2]))
		end
		return NumberSequence.new(points)
	elseif kind == "ColorSequence" then
		if typeof(value) == "Color3" then
			return ColorSequence.new(if greyed then grey(value) else value)
		end
		local points = {}
		for _, point in value do
			table.insert(points, ColorSequenceKeypoint.new(point[1], if greyed then grey(point[2]) else point[2]))
		end
		return ColorSequence.new(points)
	elseif kind == "EnumItem" then
		return (current :: EnumItem).EnumType:FromName(value)
	elseif kind == "Vector2" and type(value) == "table" then
		return Vector2.new(value[1], value[2])
	end
	return value
end

type Piece = {
	Name: string,
	Row: EffectsConfig.Row,
	First: number,
	Frame: CFrame,
	Scale: Vector3,
	Made: { Instance },
	Meshes: { { Part: MeshPart, Look: SurfaceAppearance?, Name: string } },
	Carrier: Part?,
	Gui: BillboardGui?,
	Label: ImageLabel?,
	Was: boolean,
	Emitter: ParticleEmitter?,
	Emitted: { [number]: boolean },
	Light: PointLight?,
	Offset: number, -- the frame its From beat stands on: its keys count from there
	Placed: boolean, -- what it rides is there this step
	Held: boolean, -- a Hold row's frame, kept from its first shown step
	Rides: Instance?, -- a Body row's point on the body
	History: { { number } }?, -- a Trail row's points by frame: { frame, x, y, z }
	Beam: Beam?,
	Ends: { Attachment }?,
	Blank: boolean, -- a Beam with no picture (none in the block-in): never shown
	Low: Vector3, -- a Beam's ends, for the rows that hang on them
	High: Vector3,
	Glow: SurfaceAppearance?, -- a Glow row's look on the body, and its strength before
	GlowWas: number,
	Touched: boolean,
	Fired: boolean, -- a Streak, Sound or Relight row, once it has gone
	Lit: SurfaceAppearance?, -- a Relight row's look on the body
}

-- The row a ref names: "Shaft.High" is the Shaft's. "Target" is no row's: the options' target (AR58's link).
local TARGET = "Target"
local function refRow(ref: string): string?
	if ref == TARGET then
		return nil
	end
	return (string.split(ref, ".")[1])
end

-- The rows in an order where each comes after the row it rides.
local function ordered(rows: { [string]: EffectsConfig.Row }): { string }
	local order, placed = {}, {}
	local function place(name: string, depth: number)
		if placed[name] then
			return
		end
		assert(depth < 16, `rows ride in a loop at "{name}"`)
		local row = rows[name]
		local hangs: { string? } = { row.On, row.Like, if row.Low then refRow(row.Low) else nil, if row.High then refRow(row.High) else nil }
		for _, other in hangs do
			local on = other :: string
			assert(rows[on], `row "{name}" hangs on "{on}", which isn't a row`)
			place(on, depth + 1)
		end
		placed[name] = true
		table.insert(order, name)
	end
	local names = {}
	for name in rows do
		table.insert(names, name)
	end
	table.sort(names)
	for _, name in names do
		place(name, 0)
	end
	return order
end

-- The point a Body row rides: the body's attachment by that name, or else its part.
local function pointOf(body: Model?, name: string): Instance?
	if body == nil then
		return nil
	end
	local part: Instance? = nil
	for _, d in body:GetDescendants() do
		if d.Name == name then
			if d:IsA("Attachment") then
				return d
			elseif d:IsA("BasePart") and part == nil then
				part = d
			end
		end
	end
	return part
end

local function make(name: string, row: EffectsConfig.Row, greyed: boolean, options: Options): Piece
	local offset = 0
	if row.From then
		local marks = options.Marks
		offset = assert(marks and marks[row.From], `row "{name}": no beat "{row.From}" to count from`)
	end
	local piece: Piece = {
		Name = name,
		Row = row,
		First = (span(row)),
		Frame = CFrame.identity,
		Scale = Vector3.one,
		Made = {},
		Meshes = {},
		Was = false,
		Emitted = {},
		Offset = offset,
		Placed = false,
		Held = false,
		Blank = false,
		Low = Vector3.zero,
		High = Vector3.zero,
		GlowWas = 0,
		Touched = false,
		Fired = false,
	}
	if row.Body then
		piece.Rides = pointOf(options.Body, row.Body)
	end
	if row.Trail then
		piece.History = {}
	end
	if row.Kind == "Glow" then -- the body's own look: nothing made
		local body = options.Body
		local part = if body and row.Part then body:FindFirstChild(row.Part[1], true) else nil
		local look = if part then part:FindFirstChildOfClass("SurfaceAppearance") else nil
		if look then
			piece.Glow, piece.GlowWas = look, look.EmissiveStrength
		end
		return piece
	elseif row.Kind == "Point" or row.Kind == "Streak" or row.Kind == "Sound" then -- a place; what fires there is made then
		return piece
	elseif row.Kind == "Relight" then
		local body = options.Body
		local part = if body and row.Part then body:FindFirstChild(row.Part[1], true) else nil
		piece.Lit = if part then part:FindFirstChildOfClass("SurfaceAppearance") else nil
		return piece
	end
	if row.Kind == "Mesh" then
		local lookName = if greyed then row.Grey or row.Look else row.Look
		for _, partName in row.Part or {} do
			local part, look = Rows.Mesh(partName, lookName)
			part.Parent = home()
			table.insert(piece.Meshes, { Part = part, Look = look, Name = partName })
			table.insert(piece.Made, part)
		end
	else
		local holder = carrier()
		piece.Carrier = holder
		table.insert(piece.Made, holder)
		if row.Kind == "Card" then
			local gui = Instance.new("BillboardGui")
			gui.Name = "NL_RowCard"
			gui.Adornee = holder
			gui.LightInfluence = 0
			gui.AlwaysOnTop = false
			local label = Instance.new("ImageLabel")
			label.BackgroundTransparency = 1
			label.BorderSizePixel = 0
			label.Size = UDim2.fromScale(1, 1)
			label.ScaleType = Enum.ScaleType.Stretch
			label.Image = imageId(row.Image :: string)
			label.ImageTransparency = 1 -- shown by its image, never by Enabled (AR8 A: a picture shown is drawn a step late)
			label.Parent = gui
			gui.Parent = holder
			piece.Gui, piece.Label = gui, label
		elseif row.Kind == "Emitter" then
			local emitter = Instance.new("ParticleEmitter")
			emitter.Name = "NL_RowEmitter"
			emitter.Rate = 0
			emitter.Texture = imageId(row.Image :: string)
			for property, value in row.Emitter or {} do
				local target = emitter :: any
				target[property] = convert(target[property], value, greyed)
			end
			emitter.Parent = holder
			piece.Emitter = emitter
		elseif row.Kind == "Light" then
			local light = Instance.new("PointLight")
			light.Name = "NL_RowLight"
			light.Brightness = 0
			light.Shadows = false
			light.Parent = holder
			piece.Light = light
		elseif row.Kind == "Beam" then
			holder.CFrame = CFrame.identity -- its ends are set in the world
			local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
			a0.Name, a1.Name = "Low", "High"
			a0.Parent, a1.Parent = holder, holder
			local beam = Instance.new("Beam")
			beam.Name = "NL_RowBeam"
			beam.Attachment0, beam.Attachment1 = a0, a1
			beam.Enabled = false
			beam.Segments = 10
			for property, value in row.Beam or {} do
				local target = beam :: any
				target[property] = convert(target[property], value, greyed)
			end
			local id = if greyed and row.Grey ~= nil then (if row.Grey == "" then "" else imageId(row.Grey)) else imageId(row.Image :: string)
			beam.Texture = id
			piece.Blank = id == ""
			local colour = row.Color or Color3.new(1, 1, 1)
			beam.Color = ColorSequence.new(if greyed then grey(colour) else colour)
			beam.Parent = holder
			piece.Beam, piece.Ends = beam, { a0, a1 }
		else
			error(`row "{name}": no kind "{row.Kind}"`)
		end
	end
	return piece
end

-- What a streak or a relight lives on: the effect's own runner, or Heartbeat.
local function runOn(options: Options, step: (age: number) -> boolean, done: () -> ())
	local given = options.Run
	if given then
		given(step, done)
		return
	end
	local age = 0
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(dt: number)
		age += dt
		local ok, alive = pcall(step, age)
		if not ok or not alive then
			connection:Disconnect()
			done()
		end
	end)
end

-- A Streak row's streak, from `from` to the target as it stands now (Config.Effects.Shot), over its Life.
local function throwStreak(row: EffectsConfig.Row, from: Vector3, scale: number, greyed: boolean, options: Options)
	local aim = if options.Target then options.Target() else nil
	if aim == nil then
		return
	end
	local to = aim.Position
	local length = (to - from).Magnitude
	if length < 0.1 then
		return
	end
	local hit = if options.Hits and row.From then options.Hits[row.From] else nil
	local heavy = hit ~= nil and hit.Heavy
	local bar = Instance.new("Part")
	bar.Name = "NL_RowStreak"
	bar.Anchored, bar.CanCollide, bar.CanQuery, bar.CanTouch, bar.CastShadow = true, false, false, false, false
	bar.Material = Enum.Material.Neon
	local colour = row.Color or Color3.new(1, 1, 1)
	bar.Color = if greyed then grey(colour) else colour
	bar.Size = Vector3.one * CARRIER
	bar.Transparency = 1
	bar.Parent = home()
	local placed = CFrame.lookAt((from + to) / 2, to)
	runOn(options, function(age: number): boolean
		local shot = EffectsConfig.Shot
		local u = age / math.max(FRAME, shot.Life)
		if u >= 1 then
			return false
		end
		local width = (if heavy then shot.Heavy else shot.Width) * scale * (1 - u)
		bar.Size = Vector3.new(width, width, length)
		bar.CFrame = placed
		bar.Transparency = u
		return true
	end, function()
		bar:Destroy()
	end)
end

-- A Relight row's look: dark now, back to its Glow over the rest of the action's cooldown from `frames` after its start.
local relit: { [SurfaceAppearance]: number } = {}
local function relight(row: EffectsConfig.Row, look: SurfaceAppearance?, frames: number, options: Options)
	local spec = row.Relight
	if look == nil or spec == nil then
		return
	end
	local token = (relit[look] or 0) + 1
	relit[look] = token
	local seconds = (options.Cooldown or 0) - frames * FRAME
	if seconds <= 0 then
		look.EmissiveStrength = spec.Glow
		return
	end
	look.EmissiveStrength = 0
	runOn(options, function(age: number): boolean
		if relit[look] ~= token or look.Parent == nil then
			return false
		end
		local u = math.clamp(age / seconds, 0, 1)
		look.EmissiveStrength = spec.Glow * u ^ spec.Power
		return u < 1
	end, function() end)
end

-- The frames an emitter's particles live past its last key.
local function tail(row: EffectsConfig.Row): number
	local life = row.Emitter and row.Emitter.Lifetime
	if life == nil then
		return 0
	end
	return (if type(life) == "table" then math.max(life[1], life[2]) else life) / FRAME
end

-- A Trail row's point at frame `t`, between the steps it was seen at; its oldest if it wasn't seen that far back.
local function pointBefore(history: { { number } }, t: number): Vector3?
	local count = #history
	if count == 0 then
		return nil
	end
	for index = count, 1, -1 do
		local a = history[index]
		if a[1] <= t then
			local b = history[index + 1]
			if b == nil or b[1] <= a[1] then
				return Vector3.new(a[2], a[3], a[4])
			end
			local u = (t - a[1]) / (b[1] - a[1])
			return Vector3.new(a[2], a[3], a[4]):Lerp(Vector3.new(b[2], b[3], b[4]), u)
		end
	end
	local first = history[1]
	return Vector3.new(first[2], first[3], first[4])
end

-- A row as it plays: a Tint row given a tint takes it for its Color, and an Emitter row for its Emitter.Color, one flat
-- ColorSequence (AR69 round 2: the fall's ring, a light multiplier on fx_halo_Flame, takes Hard's Burst).
local function tinted(row: EffectsConfig.Row, given: Options): EffectsConfig.Row
	if row.Tint and given.Tint then
		local copy = table.clone(row)
		copy.Color = given.Tint
		if row.Kind == "Emitter" then
			local emitter = table.clone(row.Emitter or {})
			emitter.Color = given.Tint -- convert makes it ColorSequence.new(tint), greyed on a grey block-in
			copy.Emitter = emitter
		end
		return copy
	end
	return row
end

-- Plays the rows named `name` from `anchor` (the effect's foot; its look vector the way it faces), at `scale` times the
-- size they're written at (the hit's area over the rows' Area). `options`: the body and beats of an action's effect.
function Rows.Play(name: string, anchor: CFrame, scale: number, options: Options?): Player
	local effect = (EffectsConfig.Rows :: any)[name] :: EffectsConfig.Rows
	assert(effect, `no rows "{name}"`)
	local given: Options = options or {}
	local greyed = effect.Grey
	local order = ordered(effect.Rows)
	local pieces: { [string]: Piece } = {}
	local finish = 0
	for _, rowName in order do
		local row = tinted(effect.Rows[rowName], given)
		local piece = make(rowName, row, greyed, given)
		pieces[rowName] = piece
		local _, last = span(row)
		finish = math.max(finish, piece.Offset + last + tail(row))
	end
	local done = false
	local let = false

	local function putBack()
		for _, piece in pieces do
			local look = piece.Glow
			if look and piece.Touched and look.Parent then
				look.EmissiveStrength = piece.GlowWas
			end
			piece.Glow = nil
		end
	end

	local player: Player
	local function destroy()
		if done then
			return
		end
		done = true
		putBack()
		for _, piece in pieces do
			for _, made in piece.Made do
				made:Destroy()
			end
		end
	end

	-- A beam's end another row names ("Shaft.High"), as it stands this step.
	local function refPoint(ref: string): Vector3
		local parts = string.split(ref, ".")
		local piece = pieces[parts[1]]
		return if parts[2] == "Low" then piece.Low else piece.High
	end

	local function step(frames: number): boolean
		if done then
			return false
		end
		local rows = ((EffectsConfig.Rows :: any)[name] :: EffectsConfig.Rows).Rows -- a Tune shows at once
		for _, rowName in order do
			local piece = pieces[rowName]
			local row = if rows[rowName] then tinted(rows[rowName], given) else piece.Row
			local tracks = row.Tracks
			local t = frames - piece.Offset -- its own frames, from its From beat
			local shown = t >= piece.First
			if not (row.Hold and piece.Held) then
				local parentFrame, parentScale, placed = anchor, Vector3.one * scale, true
				if row.On then
					local parent = pieces[row.On]
					parentFrame, parentScale, placed = parent.Frame, parent.Scale, parent.Placed
				elseif row.Body then
					local point = piece.Rides
					if let or point == nil or point.Parent == nil then
						placed = false
					elseif point:IsA("Attachment") then
						parentFrame = point.WorldCFrame
					else
						parentFrame = (point :: BasePart).CFrame
					end
				end
				local at = Track.Value(tracks.At, t) or Vector3.zero
				local spin = Track.Value(tracks.Spin, t) or 0
				local tilt = Track.Value(tracks.Tilt, t) or Vector3.zero
				local frame = parentFrame
					* CFrame.new(at * parentScale)
					* CFrame.Angles(0, math.rad(spin), 0)
					* CFrame.Angles(math.rad(tilt.X), math.rad(tilt.Y), math.rad(tilt.Z))
				local turn = row.Turn
				if turn then -- about up, then its own X, then its own Z
					frame *= CFrame.Angles(0, math.rad(turn.Y), 0) * CFrame.Angles(math.rad(turn.X), 0, 0) * CFrame.Angles(0, 0, math.rad(turn.Z))
				end
				if row.Ground then -- set down to the effect's foot, upright, facing as the effect does; its At.Y still lifts it off the floor
					frame = CFrame.new(frame.X, anchor.Y + (at * parentScale).Y, frame.Z) * anchor.Rotation
				end
				piece.Frame, piece.Scale, piece.Placed = frame, parentScale, placed
				if row.Hold and shown and placed then
					piece.Held = true
				end
				local history = piece.History
				if history and placed then
					local p = frame.Position
					table.insert(history, { t, p.X, p.Y, p.Z })
					if #history > 120 then
						table.remove(history, 1)
					end
				end
			end
			shown = shown and piece.Placed
			if row.Kind == "Mesh" then
				local own = Track.Value(tracks.Scale, t)
				piece.Scale = (if type(own) == "number" then Vector3.one * own elseif own then own :: Vector3 else Vector3.one) * scale
				local fade = Track.Value(tracks.Transparency, t)
				local glow = Track.Value(tracks.Glow, t)
				local tint = Track.Value(tracks.Color, t)
				for _, mesh in piece.Meshes do
					local unit = FxKit.Meshes[mesh.Name]
					local band = row.Bands and row.Bands[mesh.Name]
					local part = mesh.Part
					if not shown then
						part.Transparency = 1
						continue
					end
					part.Size = unit.Size * piece.Scale
					part.CFrame = piece.Frame * CFrame.new(unit.Centre * piece.Scale)
					part.Transparency = (band and Track.Value(band.Transparency, t)) or fade or 0
					local colour = (band and Track.Value(band.Color, t)) or tint or row.Color
					local look = mesh.Look
					if look then
						look.EmissiveStrength = (band and Track.Value(band.Glow, t)) or glow or 1
						if colour then
							look.Color = if greyed then grey(colour) else colour
						end
					elseif colour then
						part.Color = if greyed then grey(colour) else colour
					end
				end
			elseif row.Kind == "Glow" then
				local look = piece.Glow
				local glow = Track.Value(tracks.Glow, t)
				if look and look.Parent and glow and not let then
					look.EmissiveStrength = glow
					piece.Touched = true
				end
			elseif row.Kind == "Beam" then
				local beam = piece.Beam :: Beam
				local ends = piece.Ends :: { Attachment }
				local likeName = row.Like
				local like = if likeName then rows[likeName] or pieces[likeName].Row else nil
				local likeT = if likeName then frames - pieces[likeName].Offset else t
				local own = Track.Value(tracks.Width, t)
				local width = own or (like and Track.Value(like.Tracks.Width, likeT)) or 0
				if own == nil and like and row.Low == `{likeName}.High` then
					width *= like.Taper or 1 -- footed on its Like's top: the width there
				end
				local fade = Track.Value(tracks.Transparency, t) or (like and Track.Value(like.Tracks.Transparency, likeT)) or 0
				local up = piece.Frame.UpVector
				local studs = piece.Scale.Y
				local low: Vector3?, high: Vector3? = nil, nil
				local trail = row.Trail
				if trail then -- from the point's trailing edge back to where it was Lag frames before
					local now = piece.Frame.Position
					local back = pointBefore(piece.History :: { { number } }, t - (Track.Value(tracks.Lag, t) or 0))
					local along = if back then now - back else Vector3.zero
					if back and along.Magnitude > 1e-3 then
						low = now - along.Unit * trail.Back * studs
						high = back - along.Unit * trail.Beyond * studs
					end
				else
					local foot = if row.Low then refPoint(row.Low) else piece.Frame.Position + up * (Track.Value(tracks.Foot, t) or 0) * studs
					local spike = Track.Value(tracks.Spike, t)
					low = foot
					if row.High == TARGET then -- at the target as it stands this frame; none (or gone): no beam
						local find = given.Target
						local target = if find then find() else nil
						high = if target and target.Parent then target.Position else nil
					else
						high = if row.High then refPoint(row.High)
							elseif spike then foot + up * spike * studs
							else piece.Frame.Position + up * (Track.Value(tracks.Top, t) or 0) * studs
					end
					local reach = Track.Value(tracks.Reach, t) -- the share of the way from Low to High it's drawn out to
					if reach and high then
						high = foot + (high - foot) * reach
					end
				end
				local on = shown and not piece.Blank and width > 0 and fade < 1 and low ~= nil and high ~= nil
				if low and high then
					piece.Low, piece.High = low, high
					-- Both ends turned as the row its Low names is (its guide), else as its own place: a CurveSize bends along
					-- that frame's X, not the world's (AR69 round 2, Scintilla's tongues). The holder stands at identity.
					local guideName = if row.Low then refRow(row.Low) else nil
					local turn = (if guideName and pieces[guideName] then pieces[guideName].Frame else piece.Frame).Rotation
					ends[1].WorldCFrame, ends[2].WorldCFrame = CFrame.new(low) * turn, CFrame.new(high) * turn
					local v = math.clamp(fade, 0, 1)
					local length = (high - low).Magnitude
					local footFade = row.FootFade
					if footFade and footFade > 0 and length > 1e-3 then
						local f = math.clamp(footFade * studs / length, 0.001, 0.998)
						beam.Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 1),
							NumberSequenceKeypoint.new(f, v),
							NumberSequenceKeypoint.new(1, v),
						})
					else
						beam.Transparency = NumberSequence.new(v)
					end
				end
				beam.Width0, beam.Width1 = width * studs, width * (row.Taper or 1) * studs
				beam.Enabled = on
			elseif row.Kind == "Point" then
				continue
			elseif row.Kind == "Streak" or row.Kind == "Sound" or row.Kind == "Relight" then
				if shown and not piece.Fired then
					piece.Fired = true
					if row.Kind == "Streak" then
						throwStreak(row, piece.Frame.Position, scale, greyed, given)
					elseif row.Kind == "Sound" then
						Sounds.Play(row.Cue :: string, piece.Frame.Position)
					elseif not let then
						relight(row, piece.Lit, frames, given)
					end
				end
				continue
			else
				local holder = piece.Carrier :: Part
				holder.CFrame = piece.Frame
				if row.Kind == "Card" then
					local label = piece.Label :: ImageLabel
					local size = (Track.Value(tracks.Size, t) or 0) * scale
					local on = shown and size > 0
					if on then
						local gui = piece.Gui :: BillboardGui
						gui.Size = UDim2.fromScale(size, size)
						gui.Brightness = Track.Value(tracks.Brightness, t) or 1
						local colour = Track.Value(tracks.Color, t) or row.Color or Color3.new(1, 1, 1)
						label.ImageColor3 = if greyed then grey(colour) else colour
						label.ImageTransparency = Track.Value(tracks.Transparency, t) or 0
					elseif not piece.Was then
						label.ImageTransparency = 1 -- cleared a step after its last frame, as it's drawn a step late
					end
					piece.Was = on
				elseif row.Kind == "Emitter" then
					local emitter = piece.Emitter :: ParticleEmitter
					local radius = Track.Value(tracks.Radius, t)
					if radius then
						holder.Size = Vector3.new(2 * radius * piece.Scale.X, CARRIER, 2 * radius * piece.Scale.Z)
					end
					-- At the player's Effects level (AR43's Settings): its rate in that share, each burst's count by Track.Burst.
					local share = SettingsController.Level("Effects")
					emitter.Rate = if shown then (Track.Value(tracks.Rate, t) or 0) * share else 0
					for index, emit in row.Emit or {} do
						if not piece.Emitted[index] and t >= emit[1] then
							piece.Emitted[index] = true
							local count = Track.Burst(emit[2], share, row.Tell)
							if count > 0 then
								emitter:Emit(count)
							end
						end
					end
				elseif row.Kind == "Light" then
					local light = piece.Light :: PointLight
					light.Range = (row.Range or 8) * scale
					local colour = Track.Value(tracks.Color, t) or row.Color or Color3.new(1, 1, 1)
					light.Color = if greyed then grey(colour) else colour
					light.Brightness = if shown then Track.Value(tracks.Brightness, t) or 1 else 0
				end
			end
		end
		if frames > finish then
			destroy()
			return false
		end
		return true
	end

	player = {
		Name = name,
		Step = step,
		Destroy = destroy,
		Let = function()
			let = true
			putBack()
		end,
		End = finish,
		Parts = function(rowName: string): { Instance }
			local piece = pieces[rowName]
			return if piece then table.clone(piece.Made) else {}
		end,
	}
	return player
end

-- Every kit image the rows use, and every kit mesh and look drawn once, unseen, so the first effect draws whole (AR8, "On
-- a phone"). The parts sit under a pixel in front of the camera, nearly clear, for WARM_SECONDS. Once per session.
-- Each kit image is drawn as a particle and as a beam too: fetched alone, a picture's first particle in a session drew
-- nothing, the session's first mend losing its flash and needles while the second had both (Scintilla's join test,
-- AR58, 2026-11-25). One nearly clear particle of each, re-emitted every WARM_EMIT seconds through the warm.
local WARM_EMIT = 0.25
local warmed = false
local warming: Folder? = nil
local warmedImages = 0 -- the kit images drawn as particles in the warm, for the self-test
function Rows.Warm()
	if warmed then
		return
	end
	warmed = true
	-- The kit's images and the effects' own pictures (Config.Effects.Pictures, once uploaded): a textured Beam draws as
	-- a solid band until its texture has loaded.
	local ids = {}
	for _, image in FxKit.Images do
		table.insert(ids, image.Id)
	end
	for _, picture in EffectsConfig.Pictures do
		if picture ~= "" then
			table.insert(ids, picture)
		end
	end
	task.spawn(function()
		local missed: { string } = {}
		pcall(function()
			ContentProvider:PreloadAsync(ids, function(id: string, status: Enum.AssetFetchStatus)
				if status ~= Enum.AssetFetchStatus.Success then
					table.insert(missed, id)
				end
			end)
		end)
		if #missed > 0 then -- a fetch can fail once and come on the next try (seen in a playtest, 2026-11-13)
			pcall(function()
				ContentProvider:PreloadAsync(missed)
			end)
		end
	end)
	task.spawn(function()
		local templates = kitFolder()
		local meshes = (templates :: any).Meshes:GetChildren()
		local looks = (templates :: any).Looks:GetChildren()
		table.sort(meshes, function(a: Instance, b: Instance)
			return a.Name < b.Name
		end)
		table.sort(looks, function(a: Instance, b: Instance)
			return a.Name < b.Name
		end)
		local camera = workspace.CurrentCamera
		local holder = Instance.new("Folder")
		holder.Name = "NL_RowsWarm"
		holder.Parent = camera
		warming = holder
		local parts: { BasePart } = {}
		for index = 1, math.max(#meshes, #looks) do
			local part = meshes[(index - 1) % #meshes + 1]:Clone() :: MeshPart
			part.Size = Vector3.one * WARM_SIZE
			part.Transparency = 0.95
			local look = looks[(index - 1) % #looks + 1]:Clone()
			look.Parent = part
			part.Parent = holder
			table.insert(parts, part)
		end
		local emitters: { ParticleEmitter } = {}
		for _, id in ids do
			local part = Instance.new("Part")
			part.Name = "NL_WarmImage"
			part.Anchored = true
			part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = false, false, false, false
			part.Transparency = 1
			part.Size = Vector3.one * WARM_SIZE
			local low, high = Instance.new("Attachment"), Instance.new("Attachment")
			high.Position = Vector3.new(WARM_SIZE, 0, 0)
			low.Parent, high.Parent = part, part
			local emitter = Instance.new("ParticleEmitter")
			emitter.Texture = id
			emitter.Rate = 0
			emitter.Lifetime = NumberRange.new(WARM_EMIT)
			emitter.Speed = NumberRange.new(0)
			emitter.Size = NumberSequence.new(WARM_SIZE)
			emitter.Transparency = NumberSequence.new(0.98)
			emitter.LightEmission = 0
			emitter.LockedToPart = true
			emitter.Parent = low
			local beam = Instance.new("Beam")
			beam.Texture = id
			beam.Attachment0, beam.Attachment1 = low, high
			beam.Width0, beam.Width1 = WARM_SIZE, WARM_SIZE
			beam.Transparency = NumberSequence.new(0.98)
			beam.Parent = part
			part.Parent = holder
			table.insert(parts, part)
			table.insert(emitters, emitter)
		end
		local began = os.clock()
		local emitted = -math.huge
		while os.clock() - began < WARM_SECONDS and holder.Parent do
			local view = (workspace.CurrentCamera :: Camera).CFrame
			for index, part in parts do
				part.CFrame = view * CFrame.new((index - #parts / 2) * WARM_SIZE * 1.5, 0, -WARM_AHEAD)
			end
			if os.clock() - emitted >= WARM_EMIT then
				emitted = os.clock()
				for _, emitter in emitters do
					emitter:Emit(1)
				end
				warmedImages = #emitters
			end
			RunService.RenderStepped:Wait()
		end
		holder:Destroy()
		warming = nil
	end)
end

-- For the self-test: whether the warm pass ran and is over, and how many kit images it drew as particles.
function Rows.Warmed(): (boolean, number)
	return warmed and warming == nil, warmedImages
end

return Rows
