--!strict
-- Rows (client): the one effect player (AR8, "The method"). It plays an effect's rows from Config.Effects.Rows: the kit's
-- parts (ReplicatedStorage.Shared.Assets.FxKit, built by tools/studio/Models/FxKit.luau), cards, emitters and lights,
-- each placed on what it rides and driven by its tracks (Rules.Track), so no effect gets code of its own. The caller owns
-- the clock: Step(frames) takes frames after the effect's marker at the clip's 60 a second, fractions and all, and says
-- whether the effect still lives. The tracks are read every step, so a Tune shows at once; an emitter's properties and the
-- kit's parts are set when it plays, so a Tune there shows on the next.
-- A look is a SurfaceAppearance template, its texture its own emissive mask, cloned onto the part: a script can't set a
-- look's maps. It can't be preloaded either, so Warm draws every kit mesh and look once, unseen, at load, and the first
-- effect never pops in late (handbook/visuals/vfx-engine-facts.md, "Preloading").

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EffectsConfig = require(ReplicatedStorage.Shared.Config.Effects)
local FxKit = require(ReplicatedStorage.Shared.Config.FxKit)
local Track = require(ReplicatedStorage.Shared.Rules.Track)

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
	End: number, -- the frame the last row is done, particles included
	Parts: (row: string) -> { Instance }, -- what a row made, for the self-test
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
}

-- The rows in an order where each comes after the row it rides.
local function ordered(rows: { [string]: EffectsConfig.Row }): { string }
	local order, placed = {}, {}
	local function place(name: string, depth: number)
		if placed[name] then
			return
		end
		assert(depth < 16, `rows ride in a loop at "{name}"`)
		local on = rows[name].On
		if on then
			assert(rows[on], `row "{name}" rides "{on}", which isn't a row`)
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

local function make(name: string, row: EffectsConfig.Row, greyed: boolean): Piece
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
	}
	if row.Kind == "Mesh" then
		local templates = kitFolder()
		local lookName = if greyed then row.Grey or row.Look else row.Look
		local lookTemplate = if lookName then (templates :: any).Looks:FindFirstChild(lookName) else nil
		assert(lookName == nil or lookTemplate, `no kit look "{lookName}"`)
		for _, partName in row.Part or {} do
			local template = (templates :: any).Meshes:FindFirstChild(partName)
			assert(template and FxKit.Meshes[partName], `no kit mesh "{partName}"`)
			local part = template:Clone() :: MeshPart
			part.Transparency = 1
			local look: SurfaceAppearance? = nil
			if lookTemplate then
				look = lookTemplate:Clone()
				look.Parent = part
			else -- no look: a flat light in its Color
				part.Material = Enum.Material.Neon
			end
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
			label.Image = FxKit.Images[row.Image :: string].Id
			label.ImageTransparency = 1 -- shown by its image, never by Enabled (AR8 A: a picture shown is drawn a step late)
			label.Parent = gui
			gui.Parent = holder
			piece.Gui, piece.Label = gui, label
		elseif row.Kind == "Emitter" then
			local emitter = Instance.new("ParticleEmitter")
			emitter.Name = "NL_RowEmitter"
			emitter.Rate = 0
			emitter.Texture = FxKit.Images[row.Image :: string].Id
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
		else
			error(`row "{name}": no kind "{row.Kind}"`)
		end
	end
	return piece
end

-- The frames an emitter's particles live past its last key.
local function tail(row: EffectsConfig.Row): number
	local life = row.Emitter and row.Emitter.Lifetime
	if life == nil then
		return 0
	end
	return (if type(life) == "table" then math.max(life[1], life[2]) else life) / FRAME
end

-- Plays the rows named `name` from `anchor` (the effect's foot; its look vector the way it faces), at `scale` times the
-- size they're written at (the hit's area over the rows' Area).
function Rows.Play(name: string, anchor: CFrame, scale: number): Player
	local effect = (EffectsConfig.Rows :: any)[name] :: EffectsConfig.Rows
	assert(effect, `no rows "{name}"`)
	local greyed = effect.Grey
	local order = ordered(effect.Rows)
	local pieces: { [string]: Piece } = {}
	local finish = 0
	for _, rowName in order do
		local row = effect.Rows[rowName]
		pieces[rowName] = make(rowName, row, greyed)
		local _, last = span(row)
		finish = math.max(finish, last + tail(row))
	end
	local done = false

	local player: Player
	local function destroy()
		if done then
			return
		end
		done = true
		for _, piece in pieces do
			for _, made in piece.Made do
				made:Destroy()
			end
		end
	end

	local function step(t: number): boolean
		if done then
			return false
		end
		local rows = ((EffectsConfig.Rows :: any)[name] :: EffectsConfig.Rows).Rows -- a Tune shows at once
		for _, rowName in order do
			local piece = pieces[rowName]
			local row = rows[rowName] or piece.Row
			local tracks = row.Tracks
			local parentFrame, parentScale = anchor, Vector3.one * scale
			if row.On then
				local parent = pieces[row.On]
				parentFrame, parentScale = parent.Frame, parent.Scale
			end
			local at = Track.Value(tracks.At, t) or Vector3.zero
			local spin = Track.Value(tracks.Spin, t) or 0
			local tilt = Track.Value(tracks.Tilt, t) or Vector3.zero
			piece.Frame = parentFrame
				* CFrame.new(at * parentScale)
				* CFrame.Angles(0, math.rad(spin), 0)
				* CFrame.Angles(math.rad(tilt.X), math.rad(tilt.Y), math.rad(tilt.Z))
			local shown = t >= piece.First
			if row.Kind == "Mesh" then
				local own = Track.Value(tracks.Scale, t) or Vector3.one
				piece.Scale = own * scale
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
					local colour = (band and Track.Value(band.Color, t)) or tint
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
			else
				piece.Scale = parentScale
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
					emitter.Rate = if shown then Track.Value(tracks.Rate, t) or 0 else 0
					for index, emit in row.Emit or {} do
						if not piece.Emitted[index] and t >= emit[1] then
							piece.Emitted[index] = true
							emitter:Emit(emit[2])
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
		if t > finish then
			destroy()
			return false
		end
		return true
	end

	player = {
		Name = name,
		Step = step,
		Destroy = destroy,
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
local warmed = false
local warming: Folder? = nil
function Rows.Warm()
	if warmed then
		return
	end
	warmed = true
	local ids = {}
	for _, image in FxKit.Images do
		table.insert(ids, image.Id)
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
		local parts: { MeshPart } = {}
		for index = 1, math.max(#meshes, #looks) do
			local part = meshes[(index - 1) % #meshes + 1]:Clone() :: MeshPart
			part.Size = Vector3.one * WARM_SIZE
			part.Transparency = 0.95
			local look = looks[(index - 1) % #looks + 1]:Clone()
			look.Parent = part
			part.Parent = holder
			table.insert(parts, part)
		end
		local began = os.clock()
		while os.clock() - began < WARM_SECONDS and holder.Parent do
			local view = (workspace.CurrentCamera :: Camera).CFrame
			for index, part in parts do
				part.CFrame = view * CFrame.new((index - #parts / 2) * WARM_SIZE * 1.5, 0, -WARM_AHEAD)
			end
			RunService.RenderStepped:Wait()
		end
		holder:Destroy()
		warming = nil
	end)
end

-- For the self-test: whether the warm pass ran and is over.
function Rows.Warmed(): boolean
	return warmed and warming == nil
end

return Rows
