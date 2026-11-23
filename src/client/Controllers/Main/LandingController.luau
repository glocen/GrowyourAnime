--!strict
-- LandingController (client): AR37's landing, a machine's stage changing in the world (TR51), research's pick A, the
-- Climbing Ring, to Modulo's recipe (Config.Landing; Rules.Landing, frame by frame). When the server counts a machine's
-- "Rose" (BaseService: a rise seen on its owner's plot, scheduled by the plot's flash guard), it plays here: a band of the
-- void's light climbs the machine from the ground on the ease-in, its PointLight running up the frame (the hero; the
-- lever: anticipation, the rise's acceleration); the machine's own shape lights under a Highlight, full as the old
-- stage gives way to the new at the server's swap (the swap is never seen), and cools (the payoff: the new shape); the
-- band pulls in at the top and bursts, a short band thrown out fast then slow and a shaft rising and thinning (the
-- settle). About a second; every landing asked for on one frame starts on the next together, so a base level-up's
-- machines flash as one. Sized from the larger of its two stages' boxes. A Tune of Config.Landing shows on the next frame.
-- No sound yet (AR37, "Waits"). Until the kit holds the landing's look (src/shared/Assets/FxKit.rbxm, rebuilt with
-- fx_rise_Void), the hoop and the shaft are Neon in the throw's colour.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local LandingConfig = require(Shared.Config.Landing)
local Landing = require(Shared.Rules.Landing)
local Tags = require(Shared.World.Tags)

local LandingController = {}

local KINDS = { "Breaker", "Bay", "Battery", "Training", "Generator" } -- every machine with stages (AR19, AR32 to AR35)
local CARRIER = 0.05 -- studs: the light's invisible carrier
local LEAST = 0.001 -- studs: a part's least size

type Playing = {
	Holder: Instance,
	Started: number, -- the render frame it started on (the self-test's: a base level-up's start together)
	Frame: number, -- frames at 60 since its start
	R: number,
	H: number,
	Foot: CFrame, -- the machine's foot at its middle, upright
	Hoop: BasePart,
	HoopLook: SurfaceAppearance?,
	Throw: BasePart,
	Shaft: BasePart,
	ShaftLook: SurfaceAppearance?,
	Carrier: Part,
	Light: PointLight,
	Cover: Highlight,
}

local playing: { Playing } = {}
local seen: { [Instance]: number } = setmetatable({}, { __mode = "k" }) :: any -- each machine's "Rose" when last read
local asked: { Instance } = {} -- landings asked for since the last frame, started together on the next
local frames = 0 -- render frames since Start
local played = 0 -- landings started, for the self-test

local folder: Folder? = nil
local function home(): Folder
	if folder == nil or folder.Parent == nil then
		local made = Instance.new("Folder")
		made.Name = "NL_Landings"
		made.Parent = workspace
		folder = made
	end
	return folder :: Folder
end

-- A kit column (Config.FxKit's FxColumn) in the landing's look, or Neon in `colour` while the kit hasn't the look.
local function column(name: string, look: string?, colour: Color3): (BasePart, SurfaceAppearance?)
	local kit = (Shared :: any):FindFirstChild("Assets")
	kit = if kit then kit:FindFirstChild("FxKit") else nil
	local template = if kit then kit.Meshes:FindFirstChild("FxColumn") else nil
	local part: BasePart = if template then template:Clone() else Instance.new("Part") -- no kit: a box of light, the same numbers
	part.Name = name
	part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = true, false, false, false, false
	part.Transparency = 1
	local surface: SurfaceAppearance? = nil
	local lookTemplate = if look and kit then kit.Looks:FindFirstChild(look) else nil
	if lookTemplate then
		surface = lookTemplate:Clone()
		;(surface :: SurfaceAppearance).Parent = part
	else
		part.Material = Enum.Material.Neon
		part.Color = colour
	end
	part.Parent = home()
	return part, surface
end

-- A stage's box ({ width, depth, height }) and its foot's middle, upright, or nil while it isn't streamed in.
local function boxOf(holder: Instance, stage: any): ({ number }?, CFrame?)
	local group = if type(stage) == "number" then holder:FindFirstChild(`Stage {stage}`) else nil
	if group == nil or not group:IsA("Model") or group:FindFirstChildWhichIsA("BasePart") == nil then
		return nil, nil
	end
	local at, size = group:GetBoundingBox()
	local foot = at.Position - at.UpVector * size.Y / 2
	local _, turn, _ = at:ToEulerAnglesYXZ()
	return { size.X, size.Z, size.Y }, CFrame.new(foot) * CFrame.Angles(0, turn, 0)
end

local function start(holder: Instance)
	if holder.Parent == nil then
		return
	end
	for _, each in playing do
		if each.Holder == holder then
			return -- one landing a machine at a time: the server swaps to its newest under that cover
		end
	end
	local was, wasFoot = boxOf(holder, holder:GetAttribute("RoseFrom"))
	local grown, grownFoot = boxOf(holder, holder:GetAttribute("Stage"))
	local boxes = {}
	if was then
		table.insert(boxes, was)
	end
	if grown then
		table.insert(boxes, grown)
	end
	-- Round the larger stage: the new one's foot, unless the old stood taller.
	local foot = if was and grown and was[3] > grown[3] then wasFoot else grownFoot or wasFoot
	if #boxes == 0 or foot == nil then
		return -- streamed out: nothing to see
	end
	local config: Landing.Config = LandingConfig :: any
	local r, h = Landing.Size(boxes, config)
	local hoop, hoopLook = column("Hoop", LandingConfig.Look, LandingConfig.Throw.Colour)
	local throw = column("Throw", nil, LandingConfig.Throw.Colour)
	local shaft, shaftLook = column("Shaft", LandingConfig.Look, LandingConfig.Throw.Colour)
	local carrier = Instance.new("Part")
	carrier.Name = "LandingLight"
	carrier.Anchored, carrier.CanCollide, carrier.CanQuery, carrier.CanTouch, carrier.CastShadow = true, false, false, false, false
	carrier.Transparency = 1
	carrier.Size = Vector3.one * CARRIER
	carrier.Parent = home()
	local light = Instance.new("PointLight")
	light.Shadows = false
	light.Brightness = 0
	light.Parent = carrier
	local cover = Instance.new("Highlight")
	cover.Name = "LandingCover"
	cover.DepthMode = Enum.HighlightDepthMode.Occluded -- never through a wall
	cover.FillTransparency, cover.OutlineTransparency = 1, 1
	cover.Adornee = holder -- the machine's own shape: the old stage's, the new one's from the swap
	cover.Parent = home()
	played += 1
	table.insert(playing, {
		Holder = holder,
		Started = frames,
		Frame = 0,
		R = r,
		H = h,
		Foot = foot,
		Hoop = hoop,
		HoopLook = hoopLook,
		Throw = throw,
		Shaft = shaft,
		ShaftLook = shaftLook,
		Carrier = carrier,
		Light = light,
		Cover = cover,
	})
end

local function finish(each: Playing)
	each.Hoop:Destroy()
	each.Throw:Destroy()
	each.Shaft:Destroy()
	each.Carrier:Destroy()
	each.Cover:Destroy() -- a disabled one still holds a slot
end

-- One landing drawn at its frame: every part placed and lit as Rules.Landing.At says.
local function draw(each: Playing)
	local config: Landing.Config = LandingConfig :: any
	local frame = Landing.At(each.Frame, each.R, each.H, config)
	local foot = each.Foot
	local hoop = frame.Hoop
	if hoop and hoop.Top - hoop.Foot > LEAST then
		each.Hoop.Size = Vector3.new(math.max(hoop.Across, LEAST), hoop.Top - hoop.Foot, math.max(hoop.Across, LEAST))
		each.Hoop.CFrame = foot * CFrame.new(0, (hoop.Top + hoop.Foot) / 2, 0) * CFrame.Angles(math.pi, 0, 0) -- turned over: the core at its top
		each.Hoop.Transparency = 0
		if each.HoopLook then
			(each.HoopLook :: SurfaceAppearance).EmissiveStrength = hoop.Glow
		end
	else
		each.Hoop.Transparency = 1
	end
	local throw = frame.Throw
	if throw then
		each.Throw.Size = Vector3.new(throw.Across, throw.Tall, throw.Across)
		each.Throw.CFrame = foot * CFrame.new(0, throw.Up, 0)
		each.Throw.Transparency = throw.Transparency
	else
		each.Throw.Transparency = 1
	end
	local shaft = frame.Shaft
	if shaft then
		each.Shaft.Size = Vector3.new(math.max(shaft.Across, LEAST), shaft.Tall, math.max(shaft.Across, LEAST))
		each.Shaft.CFrame = foot * CFrame.new(0, shaft.Foot + shaft.Tall / 2, 0)
		each.Shaft.Transparency = shaft.Transparency
		if each.ShaftLook then
			(each.ShaftLook :: SurfaceAppearance).EmissiveStrength = shaft.Glow
		end
	else
		each.Shaft.Transparency = 1
	end
	local light = LandingConfig.Light
	each.Carrier.CFrame = foot * CFrame.new(0, frame.Light.Up, 0)
	each.Light.Color = light.Colour
	each.Light.Range = math.min(60, light.Range * each.R)
	each.Light.Brightness = light.Brightness * frame.Light.Share
	local cover = LandingConfig.Cover
	each.Cover.FillColor, each.Cover.OutlineColor = cover.Fill, cover.Outline
	each.Cover.FillTransparency = 1 - frame.Fill
	each.Cover.OutlineTransparency = 1 - frame.Line
end

local function step(dt: number)
	frames += 1
	if #asked > 0 then
		local now = asked
		asked = {}
		for _, holder in now do
			start(holder)
		end
	end
	for index = #playing, 1, -1 do
		local each = playing[index]
		if each.Holder.Parent == nil or each.Frame >= LandingConfig.Frames then
			finish(each)
			table.remove(playing, index)
		else
			draw(each)
			each.Frame += dt * 60
		end
	end
end

local function watch(holder: Instance)
	if seen[holder] ~= nil then
		return
	end
	local count = holder:GetAttribute("Rose")
	seen[holder] = if type(count) == "number" then count else 0 -- what it had when it streamed in: never played
	holder:GetAttributeChangedSignal("Rose"):Connect(function()
		local now = holder:GetAttribute("Rose")
		if type(now) == "number" and now > (seen[holder] or now) and not table.find(asked, holder) then
			table.insert(asked, holder)
		end
		seen[holder] = if type(now) == "number" then now else 0
	end)
end

-- The landings playing now, for the self-test: each one's machine, frame, size and parts.
function LandingController.Playing(): { { Holder: Instance, Started: number, Frame: number, R: number, H: number, Cover: Highlight, Hoop: BasePart, Light: PointLight } }
	local list = {}
	for _, each in playing do
		table.insert(list, { Holder = each.Holder, Started = each.Started, Frame = each.Frame, R = each.R, H = each.H, Cover = each.Cover, Hoop = each.Hoop, Light = each.Light })
	end
	return list
end

-- How many landings have started since the client began, for the self-test.
function LandingController.Played(): number
	return played
end

function LandingController.Start()
	for _, kind in KINDS do
		local tag = Tags[kind].Tag
		for _, holder in CollectionService:GetTagged(tag) do
			watch(holder)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(watch)
	end
	RunService.RenderStepped:Connect(step)
end

return LandingController
