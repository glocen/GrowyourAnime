--!strict
-- Figure (client): the Voidkin in the reveal's window, on his Reveal clip (reveal.json, "figure"). Three copies of his body
-- in three ViewportFrames the tile's size, each posed at the same point of the clip every frame:
--   Dark    his silhouette in the room's dark, his edge taking the light from behind him (the rim)
--   Colours his own colours, run down him from the ram's head at the strike (a band growing from the head's row: the
--           art's run measured from a point, read along the height, its soft edge Flood.Soft)
--   Hot     the hot line ahead of the colours, the light run toward white
-- The art draws the run per pixel; the engine has no mask by distance, so this is its nearest: research judges it in
-- motion. A Voidkin without his own body or clip is the grey stand-in on Config.Reveal.Fallback.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Art = require(Shared.Config.RevealArt)
local RevealConfig = require(Shared.Config.Reveal)
local Reveal = require(Shared.Rules.Reveal)
local Clips = require(script.Parent.Parent.Parent.Controllers.Main.FighterController.Clips)

local LOOK = 3.5 -- studs over his soles the camera looks at
local HIP = 3 -- studs from his soles to his root, the Templates' rig
local CENTRE = 185 -- the tile's middle on the screen: his soles on the sill (reveal.json, "figure")

local Figure = {}

type Copy = { View: ViewportFrame, Track: AnimationTrack?, Body: Model }
export type Figure = {
	Holder: Frame, -- the tile, placed on the stage
	Dark: Copy,
	Colours: Copy,
	Hot: Copy,
	ColoursGroup: CanvasGroup,
	ColoursFade: UIGradient,
	HotGroup: CanvasGroup,
	HotFade: UIGradient,
	Clip: string, -- the Reveal clip he plays (his own, or the stand-in's)
	Strike: number, -- his strike marker's time in his clip
	Length: number, -- his clip's length
}

local function strip(body: Model)
	for _, item in body:GetDescendants() do
		if item:IsA("SurfaceAppearance") or item:IsA("Decal") or item:IsA("Texture") then
			item:Destroy()
		elseif item:IsA("MeshPart") then
			item.TextureID = ""
		end
		if item:IsA("BasePart") then
			item.Color = Color3.new(1, 1, 1)
			item.Material = Enum.Material.SmoothPlastic
		end
	end
end

-- One copy of the body in its own ViewportFrame, on the clip, still at its start.
local function copy(source: Model, clip: string, parent: Instance, name: string, plain: boolean): Copy
	local view = Instance.new("ViewportFrame")
	view.Name = name
	view.BackgroundTransparency = 1
	view.Size = UDim2.fromScale(1, 1)
	local world = Instance.new("WorldModel")
	world.Parent = view
	local body = source:Clone()
	local root = body:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		body.PrimaryPart = root
		root.Anchored = true
		body:PivotTo(body:GetPivot() * root.CFrame:Inverse() * CFrame.new(0, HIP, 0)) -- his root at the hip's height, facing -Z
	end
	if plain then
		strip(body)
	end
	body.Parent = world
	local camera = Instance.new("Camera")
	local figure = Art.Figure
	local target = Vector3.new(0, LOOK, 0)
	camera.FieldOfView = figure.Fov
	camera.CFrame = CFrame.lookAt(target + figure.Direction.Unit * figure.Distance, target)
	camera.Parent = view
	view.CurrentCamera = camera
	local track: AnimationTrack? = nil
	local animator = body:FindFirstChildWhichIsA("Animator", true)
	local animation = Clips.Animation(clip)
	if animator and animation then
		track = (animator :: Animator):LoadAnimation(animation)
		local loaded = track :: AnimationTrack
		loaded.Looped = false
		loaded.Priority = Enum.AnimationPriority.Action4
		loaded:Play(0, 1, 0)
	end
	view.Parent = parent
	return { View = view, Track = track, Body = body }
end

local function group(name: string, parent: Instance): (CanvasGroup, UIGradient)
	local canvas = Instance.new("CanvasGroup")
	canvas.Name = name
	canvas.BackgroundTransparency = 1
	canvas.Size = UDim2.fromScale(1, 1)
	local fade = Instance.new("UIGradient")
	fade.Rotation = 90 -- top to bottom of the tile
	fade.Parent = canvas
	canvas.Parent = parent
	return canvas, fade
end

-- His body and his clip: his own if both are made, else the stand-in on the fallback clip.
local function pick(model: string?): (Model, string)
	local figures = ReplicatedStorage:WaitForChild("NL_Reveal"):WaitForChild("Figures")
	local own = if model then figures:FindFirstChild(model) else nil
	local clip = if model then `{model}Reveal` else ""
	if own and own:IsA("Model") and RevealConfig.Strikes[clip] and Clips.Animation(clip) then
		return own, clip
	end
	return figures:WaitForChild("StandIn") :: Model, RevealConfig.Fallback
end

function Figure.new(model: string?, parent: Instance, z: number): Figure
	local tile = Art.Figure.Tile
	local holder = Instance.new("Frame")
	holder.Name = "Figure"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromOffset(tile.X, tile.Y)
	holder.ZIndex = z
	local body, clip = pick(model)
	local dark = copy(body, clip, holder, "Dark", true)
	dark.View.Ambient = Art.Figure.Dark
	local camera = dark.View.CurrentCamera :: Camera
	dark.View.LightDirection = camera.CFrame:VectorToWorldSpace(RevealConfig.Rim.Direction.Unit)
	local coloursGroup, coloursFade = group("Colours", holder)
	local colours = copy(body, clip, coloursGroup, "View", false)
	local lit = RevealConfig.Lit
	colours.View.Ambient, colours.View.LightColor = lit.Ambient, lit.Light
	colours.View.LightDirection = camera.CFrame:VectorToWorldSpace(lit.Direction.Unit)
	local hotGroup, hotFade = group("Hot", holder)
	local hot = copy(body, clip, hotGroup, "View", true)
	hot.View.LightColor = Color3.new(0, 0, 0)
	holder.Parent = parent
	local track = colours.Track
	return {
		Holder = holder,
		Dark = dark,
		Colours = colours,
		Hot = hot,
		ColoursGroup = coloursGroup,
		ColoursFade = coloursFade,
		HotGroup = hotGroup,
		HotFade = hotFade,
		Clip = clip,
		Strike = RevealConfig.Strikes[clip].Time,
		Length = if track and track.Length > 0 then track.Length else 1.6,
	}
end

-- A transparency over the tile's height, by distance from the head's row (Reveal.Profile). The art measures from the
-- head itself; this reads it along the height, the way his colours run down him.
local function profile(row: number, height: number, f: (d: number) -> number, ds: { number }): NumberSequence
	local keys: { NumberSequenceKeypoint } = {}
	for _, key in Reveal.Profile(row, height, f, ds) do
		table.insert(keys, NumberSequenceKeypoint.new(key[1], key[2]))
	end
	return NumberSequence.new(keys)
end

-- The figure as Reveal.At lays it at one frame, his window standing at frame.Cx.
function Figure.Lay(figure: Figure, frame: Reveal.Frame)
	local at = frame.Figure
	figure.Holder.Visible = at ~= nil
	if at == nil then
		return
	end
	local art = Art.Figure
	figure.Holder.Position = UDim2.fromOffset(frame.Cx - art.Tile.X / 2, CENTRE - art.Tile.Y / 2)
	local time = math.clamp(Reveal.Figure(frame.Clip, figure.Strike), 0, figure.Length - 1e-3)
	for _, c in { figure.Dark, figure.Colours, figure.Hot } do
		if c.Track then
			c.Track.TimePosition = time
		end
	end
	local cover = 1 - math.clamp(at.Cover, 0, 1)
	figure.Dark.View.ImageTransparency = cover
	figure.Dark.View.LightColor = Color3.new(0, 0, 0):Lerp(frame.Colour, math.clamp(at.Rim, 0, 1))
	local soft, row, height = art.Flood.Soft, art.Flood.Origin.Y, art.Tile.Y
	local edge = at.Edge
	figure.ColoursGroup.Visible = edge ~= nil
	figure.HotGroup.Visible = edge ~= nil and at.Line > 0
	if edge then
		figure.ColoursGroup.GroupTransparency = cover
		figure.ColoursFade.Transparency = profile(row, height, function(d: number): number
			return 1 - math.clamp((edge - d) / soft, 0, 1)
		end, { 0, edge - soft, edge })
		local line = edge - 22.5 -- the hot line runs this far behind the colours' edge, 25 points either side
		figure.Hot.View.Ambient = frame.Hot
		figure.HotGroup.GroupTransparency = 1 - math.clamp(at.Line, 0, 1) * (1 - cover)
		figure.HotFade.Transparency = profile(row, height, function(d: number): number
			return 1 - math.exp(-((d - line) / 25) ^ 2)
		end, { 0, line - 37.5, line - 25, line - 12.5, line, line + 12.5, line + 25, line + 37.5 })
	end
end

return Figure
