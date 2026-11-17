--!strict
-- Effects (client): the fight's stand-ins in grey, timing and size only (TR2; the looks come with the art sheets).
--   Spark     a landed hit: a burst of light where it lands, larger on a heavy hit. Light only: no wound, nothing left.
--   Haymaker  AR1's art sheet: the charge square and the punctuation, one bar picture for both, or grey parts until
--             it's uploaded (Config.Effects.Haymaker; docs/asset-requests.md, AR1, section 5). The ram's heat on its
--             glow mask, and the strike's sound (Config.Sounds). And B5's stamp, a grey block until its art (AR8,
--             "B5"): the square hung over the target through the hold, slammed onto it on Strike, squashed flat where
--             it lands. Never over the top bar's foot; the top band goes see-through while your own lead's hangs behind it.
--   LanternBurst  Pip's signature, AR4's art sheet: the heat in the cage on his glow mask, the throw with its trail, the
--             flame let out over the target, and the lantern relit over the cooldown as its readout
--             (Config.Effects.LanternBurst; docs/asset-requests.md, AR4, section 8). The flame let out is its exit's rows
--             (AR8, B1; Config.Effects.Rows, played by Rows), or the burst's picture when Exit is "".
--   Play      every other action's effect: its rows (Action.Effect; Config.Effects.Rows) on its beats, played by Rows:
--             the keeper's signature (AR8), Pip's and Lyric's shots. Older: the three above, by the name an Effect gives,
--             until they move to rows at the finish pass.
--   HeldNote  Lyric's signature, AR4's art sheet (Config.Effects.HeldNote; AR4, section 10): the flash in her rings, a
--             crest thrown across the cone on every half-beat (a ribbon over a veil that falls away), and the hit's
--             cells on each Shade it reaches. HealRing: the heal's ring rising round each body it mends.
--   BoxPose   a Shade box's stand-in motion on its action's beats: it leans back, then lunges.
--   ShadeBurst  a Shade falls: AR2's art sheet, the sky lantern. A flame swells in its collar, flares the coat's size on
--             its clip's marker as the body goes, and climbs away with its paper (docs/design.md, "Combat": no gore).
--   Number    a damage number over the target: one counting number for a flurry, one press's hits on one body.
--   Jolt      the camera's trauma, on the player's own lead's hit by its rung, or a hard hit taken.
-- Effects driven by an action take its clock on screen, which hitstop pauses; the rest run on Effects.TimeScale, which a
-- capture sets to 0 to hold a frame (.claude/skills/ga-studio-test, "Captures").

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local Actions = require(ReplicatedStorage.Shared.Definitions.Actions)
local EffectsConfig = require(ReplicatedStorage.Shared.Config.Effects)
local Combat = require(ReplicatedStorage.Shared.Config.Combat)
local Fight = require(ReplicatedStorage.Shared.Rules.Fight)
local Track = require(ReplicatedStorage.Shared.Rules.Track)
local Flight = require(ReplicatedStorage.Shared.Rules.Flight)
local ShadeBurstArt = require(ReplicatedStorage.Shared.Config.ShadeBurstArt)
local Sounds = require(script.Parent.Sounds)
local Rows = require(script.Parent.Rows)
local UI = script.Parent.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local World = require(UI.World)
local Layers = require(UI.Layers)
local Text = require(UI.Kit.Text)
local Digits = require(UI.Kit.Digits)
local Rays = require(UI.Kit.Rays)
local Shine = require(UI.Kit.Shine)
local Hud = require(ReplicatedStorage.Shared.Rules.Hud)
local HudConfig = require(ReplicatedStorage.Shared.Config.Hud)
local UIKit = require(ReplicatedStorage.Shared.Config.UIKit)

local Effects = {}
Effects.TimeScale = 1

local LIGHT = Color3.fromRGB(225, 225, 225) -- the stand-ins' grey
local SPARK = Color3.fromRGB(255, 255, 255)
local HOT = Color3.new(1, 1, 1) -- a picture's own colours
local FRAME = 1 / 60 -- the clip's frame, which the art sheets count in
local HELD_END = 0.04 -- seconds before its end a Down's last frame is held (FighterController, Effects.HeldEnd)
local R6_ROOT_HEIGHT = 3 -- an R6 root stands 3 studs over the floor: an engine fact
local STAND_IN_DEPTH = 0.1 -- studs: a grey bar's thickness through its face
local PICTURE_DEPTH = 0.05 -- a picture's part, unseen
-- The ram's strength while lit, the content check's engine looks (AR1, section 7): above 5, bloom haloes it; below 3,
-- its cream band reads deeper than cold. Outside these takes a fresh check.
local GLOW_FLOOR, GLOW_CEILING = 3, 5

local folder: Folder? = nil
local function home(): Folder
	if folder == nil or folder.Parent == nil then
		local made = Instance.new("Folder")
		made.Name = "NL_Effects"
		made.Parent = workspace
		folder = made
	end
	return folder :: Folder
end

local function part(color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = material or Enum.Material.SmoothPlastic
	p.Color = color
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = home()
	return p
end

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function easeOut(t: number): number
	local c = math.clamp(t, 0, 1)
	return 1 - (1 - c) * (1 - c)
end

-- Timed effects that run on their own: each step gets seconds since it began, on Effects.TimeScale.
type Timed = { Age: number, Step: (age: number) -> boolean, Done: () -> () }
local timed: { Timed } = {}

local drops: { [BasePart]: Frame } = {} -- the shards won in the world now, and their name plates (Effects.Drop)

local function run(step: (age: number) -> boolean, done: () -> ())
	table.insert(timed, { Age = 0, Step = step, Done = done })
end

-- After the camera and before the World layer places its plates (Camera + 2), so a plate's rise and size this frame are
-- what the World layer keeps under the top band.
RunService:BindToRenderStep("NL_Effects", Enum.RenderPriority.Camera.Value + 1, function(dt: number)
	for index = #timed, 1, -1 do
		local item = timed[index]
		item.Age += dt * Effects.TimeScale
		local ok, alive = pcall(item.Step, item.Age)
		if not ok or not alive then
			table.remove(timed, index)
			item.Done()
		end
	end
end)

local function clear(bars: { Part })
	for _, p in bars do
		p:Destroy()
	end
	table.clear(bars)
end

local function bars(count: number, color: Color3): { Part }
	local list = {}
	for _ = 1, count do
		local p = part(color)
		p.Transparency = 1
		table.insert(list, p)
	end
	return list
end

-- A landed hit's spark at `at`, seen along the line from `from`. Heavy: larger and a frame longer.
function Effects.Spark(at: Vector3, from: Vector3, heavy: boolean)
	local ball = part(SPARK, Enum.Material.Neon)
	ball.Shape = Enum.PartType.Ball
	local streaks = bars(4, SPARK)
	for _, p in streaks do
		p.Material = Enum.Material.Neon
	end
	local line = Vector3.new(at.X - from.X, 0, at.Z - from.Z)
	local facing = CFrame.lookAt(at, at + (if line.Magnitude > 0.01 then line.Unit else Vector3.new(0, 0, -1)))
	local size = if heavy then 2.6 else 1.6
	local life = if heavy then 0.16 else 0.12
	local spin = math.random() * math.pi
	run(function(age: number): boolean
		local t = age / life
		if t >= 1 then
			return false
		end
		local grow = easeOut(math.min(1, t * 2.5))
		ball.Size = Vector3.one * lerp(0.4, size, grow)
		ball.CFrame = CFrame.new(at)
		ball.Transparency = lerp(0, 1, math.max(0, t - 0.4) / 0.6)
		for index, p in streaks do
			local angle = spin + (index - 1) * math.pi / 2
			local out = lerp(0.3, size * 1.1, grow)
			p.Size = Vector3.new(0.12, lerp(0.6, size * 0.7, grow), 0.12)
			p.CFrame = facing * CFrame.Angles(0, 0, angle) * CFrame.new(0, out, 0)
			p.Transparency = ball.Transparency
		end
		return true
	end, function()
		ball:Destroy()
		clear(streaks)
	end)
end

-- A signature's bar: one flat stroke of its picture, unlit and cut by its alpha, on the faces of a thin part; with no
-- picture yet, the part itself in grey, as transparent as the frame is eaten. Laid with its length along the CFrame's X,
-- its thickness along Y, and its faces along Z (Back, +Z, toward whoever it faces).
-- The engine draws a GUI shown or changed a picture late and one cleared at once (AR2, section 13), so a bar's faces
-- are made with it, always enabled, shown by their image, and cleared a step after its last frame (Was): every picture
-- is drawn, one behind, evenly (AR8 A).
type Face = { Gui: SurfaceGui, Label: ImageLabel }
type Bar = { Part: Part, Faces: { Face }, Was: boolean }
type Look = typeof(EffectsConfig.Haymaker)

local BAR_FACES = { Enum.NormalId.Front, Enum.NormalId.Back } -- every face a bar is laid with

local function newBar(): Bar
	local p = part(LIGHT)
	p.Transparency = 1
	local bar: Bar = { Part = p, Faces = {}, Was = false }
	for _, normal in BAR_FACES do
		local gui = Instance.new("SurfaceGui")
		gui.Face = normal
		gui.LightInfluence = 0 -- unlit, as the sheet draws it
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 64
		local label = Instance.new("ImageLabel")
		label.BackgroundTransparency = 1
		label.BorderSizePixel = 0
		label.Size = UDim2.fromScale(1, 1)
		label.ScaleType = Enum.ScaleType.Stretch
		label.ImageTransparency = 1
		label.Parent = gui
		gui.Parent = p
		table.insert(bar.Faces, { Gui = gui, Label = label })
	end
	return bar
end

local function hideBar(bar: Bar)
	bar.Part.Transparency = 1
	if bar.Was then
		bar.Was = false -- its last picture is drawn this frame: cleared on the next
		return
	end
	for _, face in bar.Faces do
		face.Label.ImageTransparency = 1
	end
end

local function layBar(bar: Bar, look: Look, at: CFrame, length: number, thick: number, frame: number, tint: Color3, faces: { Enum.NormalId })
	local p = bar.Part
	p.CFrame = at
	local k = math.clamp(frame, 0, #look.Eaten - 1)
	if look.Picture == "" then
		p.Size = Vector3.new(length, thick, STAND_IN_DEPTH)
		p.Color = Color3.new(LIGHT.R * tint.R, LIGHT.G * tint.G, LIGHT.B * tint.B)
		p.Transparency = look.Eaten[k + 1]
		for _, face in bar.Faces do
			face.Label.ImageTransparency = 1
		end
		return
	end
	p.Transparency = 1
	p.Size = Vector3.new(length / look.Span, thick / look.Body, PICTURE_DEPTH)
	bar.Was = true
	for _, face in bar.Faces do
		local label = face.Label
		if label.Image ~= look.Picture then
			label.Image = look.Picture
		end
		label.ImageRectSize = Vector2.new(look.FrameWidth, look.FrameHeight)
		label.ImageRectOffset = Vector2.new(0, k * look.FrameHeight)
		label.ImageColor3 = tint
		label.ImageTransparency = if table.find(faces, face.Gui.Face) then 0 else 1
	end
end

local UPRIGHT = { Enum.NormalId.Front, Enum.NormalId.Back } -- seen from either side of the line

-- Four bars round `at`'s centre in its X-Y plane, `side` apart and `length` long: a square.
local function square(take: () -> Bar, look: Look, at: CFrame, side: number, length: number, thick: number, frame: number)
	for _, sign in { -1, 1 } do
		layBar(take(), look, at * CFrame.new(0, sign * side / 2, 0), length, thick, frame, HOT, UPRIGHT)
		layBar(take(), look, at * CFrame.new(sign * side / 2, 0, 0) * CFrame.Angles(0, 0, math.pi / 2), length, thick, frame, HOT, UPRIGHT)
	end
end

local function outFast(u: number): number
	local c = math.clamp(u, 0, 1)
	return 1 - (1 - c) ^ 3 -- most of the way in the first third
end

-- Haymaker's look, a function of the action's clock: build one per press, step it with the clock each frame. The numbers
-- are read every frame, so a tune shows at once (Config.Effects.Haymaker).
-- `attacker` is the ram's fighter; `target` gives the target's root, read once at the strike.
-- A step gets the action's clock, which a hit's hold pauses, and `free`, the same clock run on through holds.
-- Struck, when an effect draws its own hit: `body` is struck on `beat` of its action; true when the effect takes the hit
-- on itself, and the spark then stays off. It calls `landed` on the frame it reaches the body, or at once if it already
-- has, so the body's hold, push and number come with it; `look`: it draws the hit's own look on the body there too (a
-- miss asks without it). Destroyed early, it calls every `landed` still waiting.
export type Running = {
	Step: (clock: number, free: number?) -> boolean,
	Destroy: () -> (),
	Struck: ((beat: string, body: Model, landed: () -> (), look: boolean) -> boolean)?,
}

function Effects.Haymaker(beats: { [string]: number }, attacker: Model, target: () -> BasePart?): Running
	local STRIKE, SHOCK = beats.Strike, beats.Shock
	local CHARGE, VENT = beats.Charge or 0, beats.Vent or SHOCK
	local arm = attacker:FindFirstChild("Right Arm") :: BasePart?
	local root = attacker:FindFirstChild("HumanoidRootPart") :: BasePart?
	-- Made at the start, as many as a frame lays at most (a square's four), so no bar's first picture waits on its making
	-- (AR8 A).
	local pool: { Bar } = {}
	for _ = 1, 4 do
		table.insert(pool, newBar())
	end
	local used = 0
	local line: CFrame? = nil -- on the floor under the knuckles at the strike, facing down the hit's line
	local knuckles: Vector3? = nil
	local strikeAt: number? = nil -- the clock on the first frame on or past Strike: its square holds there, through the hitstop
	local shockAt: number? = nil -- and on the first frame after it, for the Shock square

	-- The ram's heat: the attacker's pieces the glow mask lights (Config.Effects.Haymaker.Glow). A lead without them has none.
	local glows: { SurfaceAppearance } = {}
	for _, name in EffectsConfig.Haymaker.Glow.Pieces do
		local piece = attacker:FindFirstChild(name)
		local surface = if piece then piece:FindFirstChildOfClass("SurfaceAppearance") else nil
		if surface then
			table.insert(glows, surface)
		end
	end
	local function heat(clock: number): number
		local glow = EffectsConfig.Haymaker.Glow
		local peak = math.clamp(glow.Peak, GLOW_FLOOR, GLOW_CEILING)
		local step = math.clamp(glow.Step, GLOW_FLOOR, peak) -- it starts and ends here, never between 0 and it
		if clock < CHARGE or clock >= VENT then
			return 0
		elseif clock < STRIKE then
			return step + (peak - step) * ((clock - CHARGE) / math.max(FRAME, STRIKE - CHARGE)) ^ glow.Rise
		elseif clock < SHOCK then
			return peak
		end
		return step + (peak - step) * (1 - (clock - SHOCK) / math.max(FRAME, VENT - SHOCK)) ^ glow.Fall
	end
	local function light(strength: number)
		for _, surface in glows do
			if surface.Parent then
				surface.EmissiveStrength = strength
			end
		end
	end

	local function take(): Bar
		used += 1
		local bar = pool[used]
		if bar == nil then
			bar = newBar()
			pool[used] = bar
		end
		return bar
	end

	-- The ram's face: at the end of the arm, looking down it.
	local function face(): CFrame?
		if arm == nil or arm.Parent == nil then
			return nil
		end
		local a = arm :: BasePart
		local at = (a.CFrame * CFrame.new(0, -1.25, 0)).Position
		return CFrame.lookAt(at, at - a.CFrame.UpVector, a.CFrame.LookVector)
	end

	-- The line: from under the knuckles at the strike, along the floor, toward the target (or straight on): the strike's
	-- and the shock's squares stand on it.
	local function fix()
		local at = face()
		if at == nil or root == nil then
			return
		end
		local r = root :: BasePart
		knuckles = at.Position
		local floorY = r.Position.Y - R6_ROOT_HEIGHT
		local origin = Vector3.new(at.Position.X, floorY, at.Position.Z)
		local aim = target()
		local toward = if aim then Vector3.new(aim.Position.X - r.Position.X, 0, aim.Position.Z - r.Position.Z) else Vector3.zero
		if toward.Magnitude < 0.5 then
			local look = r.CFrame.LookVector
			toward = Vector3.new(look.X, 0, look.Z)
		end
		line = CFrame.lookAt(origin, origin + toward.Unit)
	end

	-- B5, the stamp (Config.Effects.Haymaker.Stamp), in its art (Stamp.Art): two posts and two rails of the kit's bar round
	-- its plate, then the floor's two runs, made at the start. It hangs over wherever the target is through the hold, and
	-- lands where it stood on Strike: pinned, the target stays there with it.
	type StampPiece = { Part: MeshPart, Look: SurfaceAppearance? }
	local art = EffectsConfig.Haymaker.Stamp.Art
	local stampMade: { MeshPart } = {}
	-- The player's own lead's square stands where the top band is: the band watches its hanging pieces and goes see-through
	-- while one is behind it (Config.Hud.SeeThrough.Tag). Another player's never fades your HUD.
	local mine = attacker:GetAttribute("Side") == "Lead" and attacker:GetAttribute("Owner") == Players.LocalPlayer.UserId
	local function stampPiece(name: string, kind: typeof(art.Frame), watched: boolean): StampPiece
		local p, look = Rows.Mesh(kind.Mesh, if art.Grey then kind.Grey else kind.Look)
		p.Name = name
		if watched and mine then
			CollectionService:AddTag(p, HudConfig.SeeThrough.Tag)
		end
		p.Parent = home()
		table.insert(stampMade, p)
		return { Part = p, Look = look }
	end
	local posts = { stampPiece("NL_StampPost", art.Frame, true), stampPiece("NL_StampPost", art.Frame, true) }
	local rails = { stampPiece("NL_StampRail", art.Frame, true), stampPiece("NL_StampRail", art.Frame, true) }
	local runs = { stampPiece("NL_StampRun", art.Frame, false), stampPiece("NL_StampRun", art.Frame, false) }
	local plate = stampPiece("NL_StampPlate", art.Plate, true)
	local landedAt: Vector3? = nil -- the target's floor point on Strike
	local targetTop: number? = nil -- the target's top over the floor, measured once
	local targetKind: string? = nil -- the target's Kind, read with its top

	local function stampFoot(): Vector3?
		if root == nil then
			return nil
		end
		local r = root :: BasePart
		local floorY = r.Position.Y - R6_ROOT_HEIGHT
		local aim = target()
		if aim then
			local body = aim.Parent
			if targetTop == nil and body and body:IsA("Model") and body ~= workspace then -- a fighter's body (Workspace is a Model)
				local box, extent = body:GetBoundingBox()
				targetTop = box.Position.Y + extent.Y / 2 - floorY
				targetKind = body:GetAttribute("Kind") :: string?
			end
			return Vector3.new(aim.Position.X, floorY, aim.Position.Z)
		end
		local look = Vector3.new(r.CFrame.LookVector.X, 0, r.CFrame.LookVector.Z)
		local ahead = if look.Magnitude > 1e-3 then look.Unit else Vector3.new(0, 0, -1)
		return Vector3.new(r.Position.X, floorY, r.Position.Z) + ahead * EffectsConfig.Haymaker.Stamp.Alone
	end

	local function hideStamp()
		for _, p in stampMade do
			p.Transparency = 1
		end
	end

	-- `f`: frames from Strike, on the action's clock.
	local function stampAt(f: number)
		local s = EffectsConfig.Haymaker.Stamp
		if f < -s.Rise then
			hideStamp()
			return
		end
		if f >= 0 and landedAt == nil then
			landedAt = stampFoot()
		end
		local foot = landedAt or stampFoot()
		local camera = workspace.CurrentCamera
		if foot == nil or camera == nil then
			hideStamp()
			return
		end
		-- stood up facing the camera, whichever way it looks: X across the square as it's seen, Z toward the camera
		local toward = camera.CFrame.Position - (foot :: Vector3)
		toward = Vector3.new(toward.X, 0, toward.Z)
		if toward.Magnitude < 1e-3 then
			toward = -Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
		end
		local facing = CFrame.lookAt(foot :: Vector3, (foot :: Vector3) + toward.Unit)
		local over = math.max(s.Over, (targetTop or 0) + s.Clear)
		local top = over + (s.Top - s.Over)
		local floorOver = 0.04 -- studs: its foot's bar on the floor
		-- The highest its top edge may stand over the floor: the screen's row Under pixels below the top bar's foot
		-- (Stamp.Under; UI.World.Ceiling) is a plane through the camera; each outer top corner of the frame, front and
		-- back, meets it at its own height, and the lowest of them holds (a top edge seen off-centre tilts on screen).
		-- Never below `lowest`: the hang's is Over, Clear above the head. Off against Stamp.Uncapped kinds.
		local eye: Vector3? = nil
		local row = Vector3.zero
		local edge = if targetKind and (s.Uncapped :: { [string]: boolean })[targetKind] then nil else World.Ceiling()
		if edge then
			local y = edge + s.Under * Layers.Scale()
			local left, right = camera:ViewportPointToRay(0, y), camera:ViewportPointToRay(camera.ViewportSize.X, y)
			row = left.Direction:Cross(right.Direction)
			if math.abs(row.Y) > 1e-6 then
				eye = left.Origin
			end
		end
		local depth = art.Depth * math.max(1, art.Rails) / 2
		local function capped(height: number, tall: number, half: number, lowest: number): number
			if eye == nil or height <= lowest then
				return height
			end
			local ceiling = math.huge
			for _, x in { -half, half } do
				for _, d in { -depth, depth } do
					local corner = (facing * CFrame.new(x, 0, d)).Position
					ceiling = math.min(ceiling, -row:Dot(corner - (eye :: Vector3)) / row.Y)
				end
			end
			return math.max(lowest, math.min(height, ceiling - tall))
		end
		local w, h, z, bar, gone = 0, 0, 0, 0, 0
		local run: number? = nil
		if f < -s.Drop then
			-- hung over the target's head through the hold, drawn tight as it rises to the top of its drop
			local u = math.clamp((f + s.Rise) / math.max(1, s.Rise - s.Drop - 2), 0, 1)
			local ease = Track.Ease(s.Tighten, u)
			w = s.Side * (s.Forms + (1 - s.Forms) * ease)
			h = w
			bar = s.FormBar + (s.Bar - s.FormBar) * ease
			z = capped(over + (top - over) * ease, h + bar / 2, w / 2 + bar / 2, over) -- the frame's outer edge, half a bar past its lines
		elseif f < 0 then
			-- slammed down, faster and faster, stretched tall while it's fast
			local fast = math.clamp((f + s.Drop) / math.max(1, s.Drop - 1), 0, 1)
			local u = math.clamp((f + s.Drop) / s.Drop, 0, 1)
			w, h = s.Side * (1 - s.Narrow * fast), s.Side * (1 + s.Stretch * fast)
			bar = s.Bar
			local hungAt = capped(top, s.Side + bar / 2, s.Side / 2 + bar / 2, over) -- where the hang was capped
			z = capped(floorOver + (hungAt - floorOver) * (1 - u * u), h + bar / 2, w / 2 + bar / 2, floorOver)
		else
			-- landed on Strike, squashed flat on Shock, eaten where it lies; the floor's bars run out from its feet
			local k = math.floor(f)
			h = s.Side * s.Squash[math.min(k, #s.Squash - 1) + 1]
			w = s.Side * (if k == 0 then s.Spread else s.Spreads + s.SpreadGain * math.clamp((f - 1) / 10, 0, 1))
			z = floorOver
			gone = math.clamp((f - s.Eat) / s.Eaten, 0, 1)
			bar = s.Bar * (1 - gone) + 0.02
			if f <= s.Run.Life then
				run = outFast(f / s.Run.Frames)
			end
		end
		-- Eaten as transparency. The kit's bar lies along its X, its faces along Z: a post is turned upright, a run face up.
		local glow = Track.Value(art.Glow, f) :: number
		local function lit(piece: StampPiece)
			if piece.Look then
				(piece.Look :: SurfaceAppearance).EmissiveStrength = glow
			end
		end
		for index, sign in { -1, 1 } do
			local post = posts[index]
			post.Part.Size = Vector3.new(h + bar, bar, art.Depth)
			post.Part.CFrame = facing * CFrame.new(sign * w / 2, z + h / 2, 0) * CFrame.Angles(0, 0, math.pi / 2)
			post.Part.Transparency = gone
			lit(post)
			local rail = rails[index]
			rail.Part.Size = Vector3.new(w, bar, art.Depth * art.Rails)
			rail.Part.CFrame = facing * CFrame.new(0, z + h * (index - 1), 0)
			rail.Part.Transparency = gone
			lit(rail)
			local floorBar = runs[index].Part
			if run then
				local reach = w / 2 + s.Run.Reach * run
				floorBar.Size = Vector3.new(reach - w / 2 + 0.01, s.Run.Width * (1 - run) + 0.05, 0.16)
				floorBar.CFrame = facing * CFrame.new(sign * (w / 2 + reach) / 2, 0.08, 0) * CFrame.Angles(math.pi / 2, 0, 0)
				floorBar.Transparency = 0
			else
				floorBar.Transparency = 1
			end
		end
		-- the plate inside the frame, set back in it; never shown thinner than a sliver
		local across, up = w - bar, h - bar
		if across < 0.02 or up < 0.02 then
			plate.Part.Transparency = 1
		else
			plate.Part.Size = Vector3.new(across, up, art.Pane)
			plate.Part.CFrame = facing * CFrame.new(0, z + h / 2, 0)
			plate.Part.Transparency = math.max(Track.Value(art.Charge, f) :: number, gone)
			lit(plate)
		end
	end

	local running: Running
	running = {
		Step = function(clock: number, _free: number?): boolean
			local look = EffectsConfig.Haymaker
			local stamp = look.Stamp
			local finish = math.max(STRIKE + (stamp.Eat + stamp.Eaten + 1) * FRAME, SHOCK + 2 * FRAME)
			if clock >= finish then
				running.Destroy()
				return false
			end
			light(heat(clock))
			used = 0
			local frameNow = math.floor(clock / FRAME + 0.5) -- the clip's frame, for a boil between two of the picture's
			-- The charge: it forms out of its chips round the ram's face, is drawn tight through the hold, and boils. Cut at the strike.
			local charge = look.Charge
			local from, held = STRIKE - charge.From * FRAME, STRIKE - charge.Held * FRAME
			local at = face()
			if at and clock >= from and clock < STRIKE then
				local f = (clock - from) / FRAME
				local side = charge.Side - charge.Tight * math.clamp(f / (charge.From - charge.Held), 0, 1) ^ 2 - charge.Last * math.clamp((clock - held) / (4 * FRAME), 0, 1)
				local k = if f < charge.Forms then math.max(0, charge.Forms - 1 - math.floor(f)) else frameNow % 2
				square(take, look, at, side, side + charge.Over, charge.Bar, k)
			end
			if clock >= STRIKE then
				if line == nil then
					fix()
				end
				if strikeAt == nil then
					-- the strike's cue, on the frame the strike's square is thrown (handbook/visuals/audio.md: on contact)
					local where = knuckles or (if root then (root :: BasePart).Position else nil)
					if where then
						Sounds.Play(look.Sound, where)
					end
				end
				strikeAt = strikeAt or clock
			end
			local path, hand = line, knuckles
			-- The punctuation: the square thrown open round the ram, on the Strike frame (held through the hitstop) and the next.
			if path and hand and strikeAt then
				local across = CFrame.lookAt(hand, hand + path.LookVector) * CFrame.new(0, 0, -look.Ahead)
				if clock < SHOCK or clock == strikeAt then
					square(take, look, across, look.Strike.Side, look.Strike.Side + look.Strike.Bar, look.Strike.Bar, look.Strike.Frame)
				else
					shockAt = shockAt or clock
					if clock < SHOCK + FRAME or clock == shockAt then
						square(take, look, across, look.Shock.Side, look.Shock.Side + look.Shock.Bar, look.Shock.Bar, look.Shock.Frame)
					end
				end
			end
			stampAt((clock - STRIKE) / FRAME)
			for index = used + 1, #pool do
				hideBar(pool[index])
			end
			return true
		end,
		Destroy = function()
			light(0)
			for _, bar in pool do
				bar.Part:Destroy()
			end
			table.clear(pool)
			for _, p in stampMade do
				p:Destroy()
			end
			table.clear(stampMade)
		end,
	} :: Running
	return running
end

local function smooth(u: number): number
	local c = math.clamp(u, 0, 1)
	return c * c * (3 - 2 * c)
end

-- A value eased between keys { frame, value }, held past either end.
local function keyed(keys: { { number } }, frame: number): number
	if frame <= keys[1][1] then
		return keys[1][2]
	end
	for index = 2, #keys do
		local a, b = keys[index - 1], keys[index]
		if frame <= b[1] then
			return a[2] + (b[2] - a[2]) * smooth((frame - a[1]) / math.max(1e-6, b[1] - a[1]))
		end
	end
	return keys[#keys][2]
end

-- An unlit picture facing the camera on `adornee`, white so the picture shows its own colours (AR4, section 8, the content
-- check's condition 1). Hidden until shown.
local function billboard(adornee: Instance, image: string): (BillboardGui, ImageLabel)
	local gui = Instance.new("BillboardGui")
	gui.Name = "NL_Effect"
	gui.Adornee = adornee
	gui.LightInfluence = 0
	gui.Enabled = false
	local label = Instance.new("ImageLabel")
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Size = UDim2.fromScale(1, 1)
	label.ScaleType = Enum.ScaleType.Stretch
	label.Image = image
	label.ImageColor3 = HOT
	label.Parent = gui
	gui.Parent = adornee
	return gui, label
end

-- A billboard shown by its image's transparency, never by Enabled, and cleared a step after its last frame: the engine
-- draws one shown or changed a picture late and one cleared at once (AR2, section 13), so this draws every picture, one
-- behind, evenly (AR8 A). `showBy(shown, true)` on each frame it has a picture, false on each it hasn't.
type Shown = { Gui: BillboardGui, Label: ImageLabel, Was: boolean }

local function shownBy(gui: BillboardGui, label: ImageLabel): Shown
	label.ImageTransparency = 1
	gui.Enabled = true
	return { Gui = gui, Label = label, Was = false }
end

local function showBy(shown: Shown, on: boolean)
	if on then
		shown.Label.ImageTransparency = 0
	elseif not shown.Was then
		shown.Label.ImageTransparency = 1
	end
	shown.Was = on
end

type LanternLook = typeof(EffectsConfig.LanternBurst)

-- A cell of the Lantern Burst's sheet: its offset and its size, in pixels.
local function cell(sheet: typeof(EffectsConfig.LanternBurst.Sheet), index: number): (Vector2, Vector2)
	if index < sheet.Bigs then
		return Vector2.new(index % sheet.Across * sheet.Big, math.floor(index / sheet.Across) * sheet.Big), Vector2.new(sheet.Big, sheet.Big)
	end
	return Vector2.new((index - sheet.Bigs) * sheet.Small, sheet.SmallTop), Vector2.new(sheet.Small, sheet.Small)
end

-- The burst's cell `frames` after the Burst beat: the leap, the boil (played BoilPlays times), the end; nil once gone.
local function burstCell(burst: typeof(EffectsConfig.LanternBurst.Burst), frames: number): number?
	local d = frames
	if d < 4 * burst.Leap then
		return math.floor(d / burst.Leap)
	end
	d -= 4 * burst.Leap
	local boil = 4 * burst.Boil * burst.BoilPlays
	if d < boil then
		return 4 + math.floor(d / burst.Boil) % 4
	end
	d -= boil
	if d < 8 * burst.End then
		return 8 + math.floor(d / burst.End)
	end
	return nil
end

-- The lantern's readout (research's tier 2, AR4, section 7): dark, then relit to cold over `seconds`, full when the
-- signature is ready. A newer one, or a new burst, takes over.
local relit: { [SurfaceAppearance]: number } = {}
local function relight(surface: SurfaceAppearance, seconds: number)
	local token = (relit[surface] or 0) + 1
	relit[surface] = token
	if seconds <= 0 then
		surface.EmissiveStrength = EffectsConfig.LanternBurst.Glow.Cold
		return
	end
	surface.EmissiveStrength = 0
	run(function(age: number): boolean
		if relit[surface] ~= token or surface.Parent == nil then
			return false
		end
		local glow = EffectsConfig.LanternBurst.Glow
		local u = math.clamp(age / seconds, 0, 1)
		surface.EmissiveStrength = glow.Cold * u ^ glow.Relight
		return u < 1
	end, function() end)
end
Effects.Relight = relight

-- Pip's Lantern Burst, a function of the action's clock (AR4, section 8): the lantern heats on the glow mask while the
-- heat's flame grows round it, it's thrown with a trail held from his cuff, and at the Burst its flame stands up over the
-- target, on the ground under where it stopped, and lifts off as a wisp. Then the lantern comes home dark and relights
-- over the cooldown. The throw's length follows the target (Config.Effects.LanternBurst.Throw). The numbers are read
-- every frame, so a tune shows at once.
function Effects.LanternBurst(beats: { [string]: number }, attacker: Model, target: () -> BasePart?, action: Actions.Action): Running
	local HEAT, SEND, BURST, RETURN = beats.Heat, beats.Send, beats.Burst, beats.Return
	local LENGTH, COOLDOWN = action.Length, action.Cooldown
	local burstHit = action.Hits.Burst
	local area = if burstHit and burstHit.Area then burstHit.Area else 5
	local root = attacker:FindFirstChild("HumanoidRootPart") :: BasePart?
	local torso = attacker:FindFirstChild("Torso")
	local lamp = attacker:FindFirstChild("Pip_Lamp") :: BasePart?
	local lantern = if lamp then lamp:FindFirstChild("Lantern") :: Attachment? else nil
	local surface = if lamp then lamp:FindFirstChildOfClass("SurfaceAppearance") else nil
	local motor = if torso then torso:FindFirstChild("Lamp") :: Motor6D? else nil
	local sendFrame = math.floor(SEND / FRAME + 0.5)
	local burstFrame = math.floor(BURST / FRAME + 0.5)
	local now = 0
	local done = false
	local burstFrom: number? = nil -- the free clock at the Burst beat: the flame runs on through the hit's hold
	if surface then
		relit[surface] = (relit[surface] or 0) + 1 -- the last readout is over
	end

	-- The heat, on the lantern.
	local heatGui, heatLabel = nil :: BillboardGui?, nil :: ImageLabel?
	local heatShown: Shown? = nil
	if lantern then
		local gui, label = billboard(lantern, EffectsConfig.LanternBurst.Picture)
		heatGui, heatLabel = gui, label
		heatShown = shownBy(gui, label)
	end
	-- The burst, on a part of its own that stays where the lantern stopped.
	local stand = part(LIGHT)
	stand.Transparency = 1
	stand.Size = Vector3.one * 0.2
	local burstGui, burstLabel = billboard(stand, EffectsConfig.LanternBurst.Picture)
	local burstShown = shownBy(burstGui, burstLabel)
	local burstAt: Vector3? = nil -- the burst's foot, on the ground under the lantern at the Burst
	local exit: Rows.Player? = nil -- the exit's rows, from the Burst (AR8, B1)
	local exitFrames = 0
	-- The trail: a beam between two points of its own.
	local ends = part(LIGHT)
	ends.Transparency = 1
	ends.Size = Vector3.one * 0.2
	if root then
		ends.CFrame = root.CFrame
	end
	local tail = Instance.new("Attachment")
	tail.Parent = ends
	local head = Instance.new("Attachment")
	head.Parent = ends
	local beam = Instance.new("Beam")
	-- A Beam runs its picture's height along it, top row at Attachment0 (handbook/visuals/vfx-engine-facts.md, "Beam"), so
	-- the trail is uploaded turned a quarter: its tongues' tips the top row at the tail, its round head the bottom at the
	-- lantern. Still, never sliding, or the head would wrap round to the tail.
	beam.Attachment0, beam.Attachment1 = tail, head
	beam.FaceCamera = true
	beam.Texture = EffectsConfig.LanternBurst.TrailPicture
	beam.TextureMode = Enum.TextureMode.Stretch
	beam.TextureLength = 1
	beam.TextureSpeed = 0
	beam.Color = ColorSequence.new(HOT)
	beam.LightInfluence = 0
	beam.Transparency = NumberSequence.new(0)
	beam.Segments = 1
	beam.Enabled = false
	beam.Parent = ends
	local flown: { [number]: Vector3 } = {} -- the lantern's place by clip frame, from Send

	-- The throw, scaled to the target at Send: the lamp's joint is offset on its C0, which the Animator leaves alone (it
	-- owns Transform, and a write there doesn't hold on a client). Each frame the clip's own lantern, in the world, is
	-- moved to Send's place plus its way from there times the scale, then handed back between Return and the clip's end.
	local throw: { Scale: number, From: Vector3, Out: Vector3 }? = nil
	local restC0 = if motor then motor.C0 else CFrame.identity
	-- Where the clip alone puts the lantern this frame, and the joint's frame it's offset in.
	local function clipLantern(): (Vector3?, CFrame?)
		local m, l, body = motor, lantern, torso
		if m == nil or l == nil or body == nil or not body:IsA("BasePart") then
			return nil, nil
		end
		local joint = (body :: BasePart).CFrame * restC0
		return (joint * m.Transform * m.C1:Inverse()) * l.Position, joint
	end
	local function offsetThrow(clock: number)
		local t = throw
		if motor == nil or t == nil or t.Scale == 1 then
			return
		end
		local at, joint = clipLantern()
		if at == nil or joint == nil then
			return
		end
		if clock <= RETURN then
			t.Out = (at - t.From) * (t.Scale - 1)
		end
		local hand = if clock <= RETURN then 1 else 1 - smooth((clock - RETURN) / math.max(FRAME, LENGTH - RETURN))
		motor.C0 = restC0 * CFrame.new((joint:VectorToObjectSpace(t.Out * hand)))
	end

	local function glowAt(clock: number): number
		local glow = EffectsConfig.LanternBurst.Glow
		if clock < HEAT then
			return glow.Cold
		elseif clock < SEND then
			return glow.Cold + (glow.Hot - glow.Cold) * ((clock - HEAT) / math.max(FRAME, SEND - HEAT)) ^ glow.Curve
		elseif clock < BURST then
			return glow.Hot
		end
		return 0
	end

	local function flownAt(frame: number): Vector3?
		for f = frame, sendFrame, -1 do
			if flown[f] then
				return flown[f]
			end
		end
		return nil
	end

	local running: Running
	running = {
		Step = function(clock: number, given: number?): boolean
			now = clock
			local free = given or clock
			if clock >= LENGTH then
				running.Destroy()
				return false
			end
			local look: LanternLook = EffectsConfig.LanternBurst
			local frame = math.floor(clock / FRAME + 1e-4)
			if burstFrom == nil and clock >= BURST then
				burstFrom = free - (clock - BURST)
			end
			-- Frames since the Burst on the free clock, so the hold on the hit never stills the leap (-1 before it).
			local after = if burstFrom then math.floor((free - burstFrom) / FRAME + 1e-4) else -1
			if surface and surface.Parent then
				surface.EmissiveStrength = glowAt(clock)
			end
			-- The throw's scale, once, at Send: from where the lantern is now, the clip's flight ends Flight ahead of him.
			if throw == nil and clock >= SEND then
				local from = clipLantern()
				local aim = target()
				if from and aim and root then
					local scale = 1
					local line = Vector3.new(aim.Position.X - root.Position.X, 0, aim.Position.Z - root.Position.Z)
					local t = look.Throw
					if line.Magnitude > 0.01 then
						local ahead = (from - root.Position):Dot(line.Unit) -- the lantern, toward the target
						scale = math.clamp((line.Magnitude - t.Short - ahead) / math.max(0.1, t.Flight - ahead), t.Min, t.Max)
					end
					throw = { Scale = scale, From = from, Out = Vector3.zero }
				end
			end
			offsetThrow(clock)
			-- The heat.
			if heatGui and heatLabel and heatShown then
				local heat = look.Heat
				if clock >= HEAT and clock < BURST then
					local size = keyed(heat.Keys, clock / FRAME)
					heatGui.Size = UDim2.new(size, 0, size, 0)
					heatGui.StudsOffsetWorldSpace = Vector3.new(0, (0.5 - heat.Belly) * size, 0)
					heatGui.Brightness = heat.Brightness
					local offset, extent = cell(look.Sheet, heat.First + math.floor((clock - HEAT) / FRAME / heat.PerCell + 1e-4) % 4)
					heatLabel.ImageRectOffset, heatLabel.ImageRectSize = offset, extent
					showBy(heatShown, true)
				else
					showBy(heatShown, false)
				end
			end
			-- Where the lantern flies, by frame, and where it stops.
			if lantern and clock >= SEND and frame <= burstFrame and flown[frame] == nil then
				flown[frame] = lantern.WorldPosition
			end
			if burstAt == nil and clock >= BURST and lantern and root then
				local at = lantern.WorldPosition
				burstAt = Vector3.new(at.X, root.Position.Y - R6_ROOT_HEIGHT, at.Z)
				if look.Exit ~= "" and burstAt then
					-- The exit's foot, facing along the throw: the coil's feet stand either side of the line.
					local foot = burstAt :: Vector3
					local way = Vector3.new(foot.X - root.Position.X, 0, foot.Z - root.Position.Z)
					if way.Magnitude < 0.01 then
						way = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
					end
					local rows = (EffectsConfig.Rows :: any)[look.Exit]
					exit = Rows.Play(look.Exit, CFrame.lookAt(foot, foot + way), area / (if rows then rows.Area else area))
				end
			end
			-- The trail, from the frame after Send until it has closed onto the burst.
			local trail = look.Trail
			local closed = if after >= 0 then after / math.max(1, trail.Close) else 0
			local headAt = if after >= 0 then flownAt(burstFrame) elseif lantern then lantern.WorldPosition else nil
			local tailAt = flownAt(math.max(sendFrame, frame - trail.Lag))
			if frame > sendFrame and closed < 1 and headAt and tailAt then
				tail.WorldPosition = tailAt:Lerp(headAt, closed)
				head.WorldPosition = headAt
				beam.Width0, beam.Width1 = trail.Width0, trail.Width1
				beam.Brightness = trail.Brightness
				beam.Enabled = true
			else
				beam.Enabled = false
			end
			-- The exit, on the free clock from the Burst, so the hold on the hit never stills it.
			if exit and burstFrom then
				exitFrames = (free - burstFrom) / FRAME
				if not exit.Step(exitFrames) then
					exit = nil
				end
			end
			-- The burst's picture, the before.
			local index = if burstAt and after >= 0 and look.Exit == "" then burstCell(look.Burst, after) else nil
			if index and burstAt then
				local size = look.Burst.PerArea * area
				local camera = workspace.CurrentCamera
				local away = if camera then Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z) else Vector3.zero
				away = if away.Magnitude > 0.01 then away.Unit else Vector3.zero
				stand.CFrame = CFrame.new(burstAt + Vector3.new(0, size / 2, 0) + away * look.Burst.Back)
				burstGui.Size = UDim2.new(size, 0, size, 0)
				burstGui.Brightness = look.Burst.Brightness
				local offset, extent = cell(look.Sheet, index)
				burstLabel.ImageRectOffset, burstLabel.ImageRectSize = offset, extent
				showBy(burstShown, true)
			else
				showBy(burstShown, false)
			end
			return true
		end,
		Destroy = function()
			if done then
				return
			end
			done = true
			if motor and motor.Parent then
				motor.C0 = restC0
			end
			if heatGui then
				heatGui:Destroy()
			end
			burstGui:Destroy()
			stand:Destroy()
			ends:Destroy()
			if exit then -- the exit outlives the clip: on in its own time, from where it was
				local rows, from = exit :: Rows.Player, exitFrames
				exit = nil
				run(function(age: number): boolean
					return rows.Step(from + age / FRAME)
				end, rows.Destroy)
			end
			if surface and surface.Parent then
				relight(surface, COOLDOWN - now) -- dark until here, full when it's ready
			end
		end,
	} :: Running
	return running
end

-- Lyric's speakers' rings, by name (points of her recipe: RingR and RingL).
local function rings(attacker: Model): { [string]: Attachment }
	local found: { [string]: Attachment } = {}
	for _, point in attacker:GetDescendants() do
		if point:IsA("Attachment") and (point.Name == "RingR" or point.Name == "RingL") then
			found[point.Name] = point
		end
	end
	return found
end

-- One crest of the Held Note, thrown on `Beat` at `Born` for `Life` seconds from where she stood, along the line to her
-- target. Its two Beams, the ribbon over the veil, share the arc's two ends. `Radius` (from the cone's point) and
-- `Shows` are as last laid.
type Crest = {
	Beat: string,
	Born: number,
	Life: number,
	Root: Vector3,
	Axis: Vector3,
	Floor: number,
	Hit: Actions.Hit,
	Holder: Part,
	Ends: { Attachment },
	Ribbon: Beam,
	Veil: Beam,
	Radius: number,
	Shows: number,
}

local function crestBeam(holder: Part, ends: { Attachment }, picture: string, z: number): Beam
	local beam = Instance.new("Beam")
	beam.Attachment0, beam.Attachment1 = ends[1], ends[2] -- the picture's top row on Attachment0, the arc's first end
	beam.FaceCamera = false -- upright: its width along the ends' Y
	beam.Texture = picture
	beam.TextureMode = Enum.TextureMode.Stretch
	beam.TextureLength = 1
	beam.TextureSpeed = 0
	beam.LightInfluence = 0
	beam.Color = ColorSequence.new(HOT)
	beam.Transparency = NumberSequence.new(1)
	beam.ZOffset = z
	beam.Parent = holder
	return beam
end

-- A crest `age` seconds out (Config.Effects.HeldNote): its arc's ends round the cone's point, its height and place eased
-- out from the rings, and how it shows by its age. False once it's done.
local function layCrest(crest: Crest, age: number): boolean
	local look = EffectsConfig.HeldNote
	local u = age / math.max(FRAME, crest.Life)
	if u >= 1 then
		return false
	end
	local hit = crest.Hit
	local reach, cone, apex = hit.Reach, math.rad(hit.Cone or 0), hit.Apex or 0
	local out = look.From + (reach - look.From) * (1 - (1 - u) ^ look.Ease) -- studs from her along the line
	local thin = math.clamp((out - (reach - look.Thin)) / math.max(look.Thin, 0.01), 0, 1)
	local shows = smooth((out - look.From) / math.max(look.Birth, 0.01)) * (1 - thin)
	local veil = shows * (1 - smooth((age / FRAME - look.VeilHold) / math.max(look.VeilFade, 0.01)))
	local tall = (look.Tall + look.Grow * (out - look.From)) * (1 - look.Narrow * thin) * look.Width
	local middle = crest.Floor + look.Up - look.Fall * (out - look.From)
	local radius = out + apex
	local point = crest.Root - crest.Axis * apex
	-- The first end on her left (a turn about +Y takes her forward to her left), where the picture's left end, its top
	-- row as uploaded, lies; +X along the arc toward her right, Y up, so the band stands upright.
	for index, angle in { cone, -cone } do
		local direction = CFrame.fromAxisAngle(Vector3.yAxis, angle):VectorToWorldSpace(crest.Axis)
		local at = point + direction * radius
		crest.Ends[index].WorldCFrame = CFrame.fromMatrix(Vector3.new(at.X, middle, at.Z), direction:Cross(Vector3.yAxis), Vector3.yAxis)
	end
	local curve = 4 / 3 * math.tan(cone / 2) * radius -- a circle's arc spanning twice the cone: 4/3 tan(span / 4) r
	for _, beam in { crest.Ribbon, crest.Veil } do
		beam.CurveSize0, beam.CurveSize1 = curve, curve
		beam.Width0, beam.Width1 = tall, tall
		beam.Segments = look.Segments
	end
	crest.Ribbon.Transparency = NumberSequence.new(1 - shows)
	crest.Veil.Transparency = NumberSequence.new(1 - veil)
	crest.Radius, crest.Shows = radius, shows
	return true
end

-- The Held Note's hit on `body`: the touch sheet's four cells on its root, toward the camera (Config.Effects.HeldNote.Hit).
local function touch(body: Model)
	local look = EffectsConfig.HeldNote
	local root = body:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root == nil then
		return
	end
	local hit = look.Hit
	local gui, label = billboard(root, look.Touch)
	gui.Size = UDim2.fromScale(hit.Size, hit.Size)
	gui.StudsOffset = Vector3.new(0, 0, hit.Toward) -- in the camera's space: toward the lens
	label.ImageRectOffset = Vector2.zero
	label.ImageRectSize = Vector2.new(look.Cell, look.Cell)
	gui.Enabled = true
	local over = false
	run(function(age: number): boolean
		local index = math.floor(age / (hit.Frames * FRAME))
		if over or gui.Parent == nil then
			return false
		end
		-- past its last cell, kept a step: drawn a picture late, it would go before its last cell was seen (AR8 A)
		over = index > 3
		label.ImageRectOffset = Vector2.new(math.min(index, 3) * look.Cell, 0)
		return true
	end, function()
		gui:Destroy()
	end)
end

-- A heal on `root`'s body: the touch sheet's ring, flat round it, rising as it narrows and fades
-- (Config.Effects.HeldNote.Heal).
function Effects.HealRing(root: BasePart)
	local look = EffectsConfig.HeldNote
	local heal = look.Heal
	local plate = part(HOT)
	plate.Transparency = 1
	local gui = Instance.new("SurfaceGui")
	gui.Name = "NL_Effect"
	gui.Face = Enum.NormalId.Top
	gui.LightInfluence = 0
	gui.CanvasSize = Vector2.new(look.Cell, look.Cell)
	gui.Adornee = plate
	local label = Instance.new("ImageLabel")
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Size = UDim2.fromScale(1, 1)
	label.Image = look.Touch
	label.ImageColor3 = HOT
	label.ImageRectOffset = Vector2.new(0, look.Cell)
	label.ImageRectSize = Vector2.new(look.Cell, look.Cell)
	label.Parent = gui
	gui.Parent = plate
	local function lay(age: number): boolean
		local frames = age / FRAME
		if frames > heal.Frames or root.Parent == nil then
			return false
		end
		local u = frames / heal.Frames
		local across = heal.Radius * (1 - (1 - heal.Shrink) * u) * 2 / heal.Drawn
		local floor = root.Position.Y - R6_ROOT_HEIGHT
		plate.Size = Vector3.new(across, PICTURE_DEPTH, across)
		plate.CFrame = CFrame.new(root.Position.X, floor + heal.From + (heal.To - heal.From) * outFast(u), root.Position.Z)
		label.ImageTransparency = math.clamp((frames - (heal.Frames - heal.Fade)) / math.max(heal.Fade, 0.01), 0, 1)
		return true
	end
	lay(0)
	run(lay, function()
		plate:Destroy()
	end)
end

-- Lyric's Held Note (LyricHeldNote), AR4's art sheet (Config.Effects.HeldNote): the flash swelling in her rings, then a
-- crest thrown across the cone on every beat that hits, each living until the next is halfway out, so one is always on
-- its way; the last runs out alone after the Release. A body the server strikes takes its hit when its crest reaches it
-- (Struck): the hit's cells in place of the spark, and its hold, push and number with them (AR4, section 10, fix 2).
function Effects.HeldNote(beats: { [string]: number }, attacker: Model, target: () -> BasePart?, action: Actions.Action): Running
	local look = EffectsConfig.HeldNote
	local root = attacker:FindFirstChild("HumanoidRootPart") :: BasePart?
	local flashes: { { Ring: Attachment, Gui: BillboardGui, Shown: Shown } } = {}
	for _, ring in rings(attacker) do
		local gui, label = billboard(ring, look.Touch)
		label.ImageRectOffset = Vector2.new(look.Cell, look.Cell)
		label.ImageRectSize = Vector2.new(look.Cell, look.Cell)
		table.insert(flashes, { Ring = ring, Gui = gui, Shown = shownBy(gui, label) })
	end
	local order: { string } = {}
	for name in beats do
		if action.Hits[name] then
			table.insert(order, name)
		end
	end
	table.sort(order, function(a: string, b: string): boolean
		return beats[a] < beats[b]
	end)
	local first = if order[1] then beats[order[1]] else 0
	local crests: { Crest } = {}
	local thrown: { [string]: boolean } = {}
	-- A body struck on a beat whose crest hasn't reached it yet: what lands then, and whether its cells are drawn.
	local struck: { { Beat: string, Body: Model, Look: boolean, Landed: { () -> () } } } = {}
	local reached: { [Model]: { [string]: boolean } } = {}
	local function land(hit: { Beat: string, Body: Model, Look: boolean, Landed: { () -> () } })
		local done = reached[hit.Body] or {}
		reached[hit.Body] = done
		done[hit.Beat] = true
		if hit.Look then
			touch(hit.Body)
		end
		for _, landed in hit.Landed do
			local ok, problem = pcall(landed)
			if not ok then
				warn(`Effects.HeldNote: a hit's landing: {problem}`)
			end
		end
	end
	local function throw(index: number)
		if root == nil then
			return
		end
		local name = order[index]
		local here = Vector3.new(root.Position.X, 0, root.Position.Z)
		local aim = target()
		local line = if aim then Vector3.new(aim.Position.X, 0, aim.Position.Z) - here else Vector3.zero
		if line.Magnitude < 0.01 then
			line = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
		end
		local gap = if order[index + 1] then beats[order[index + 1]] - beats[name] elseif index > 1 then beats[name] - beats[order[index - 1]] else 0.25
		local holder = part(HOT)
		holder.Transparency = 1
		holder.Size = Vector3.one * 0.2
		holder.CFrame = CFrame.new(root.Position)
		local ends = { Instance.new("Attachment"), Instance.new("Attachment") }
		for _, point in ends do
			point.Parent = holder
		end
		table.insert(crests, {
			Beat = name,
			Born = beats[name],
			Life = gap * 2 ^ (1 / look.Ease),
			Root = here,
			Axis = line.Unit,
			Floor = root.Position.Y - R6_ROOT_HEIGHT,
			Hit = action.Hits[name],
			Holder = holder,
			Ends = ends,
			Ribbon = crestBeam(holder, ends, look.Ribbon, 0.02),
			Veil = crestBeam(holder, ends, look.Veil, 0), -- under the ribbon
			Radius = 0,
			Shows = 0,
		})
	end
	-- The flash's size at `clock`, in studs, or nil when it's out.
	local function flashAt(clock: number): number?
		local flash = look.Flash
		local charge = look.Charge * FRAME
		if clock >= first - charge and clock < first then
			return flash.Swell[1] + (flash.Swell[2] - flash.Swell[1]) * smooth((clock - (first - charge)) / math.max(charge, FRAME))
		end
		for index, name in order do
			local into = clock - beats[name]
			if into >= 0 and into < 2 * FRAME then
				local sizes = if index == 1 then flash.Note else flash.Crest
				return sizes[if into < FRAME then 1 else 2]
			end
		end
		return nil
	end
	-- Each struck body's hit lands once its crest reaches it, or at once if its crest has run out or the body has gone.
	local function reach()
		for index = #struck, 1, -1 do
			local hit = struck[index]
			local crest: Crest? = nil
			for _, each in crests do
				if each.Beat == hit.Beat then
					crest = each
				end
			end
			local body = hit.Body:FindFirstChild("HumanoidRootPart") :: BasePart?
			local due = false
			if body == nil then
				due = true
			elseif crest then
				local point = crest.Root - crest.Axis * (crest.Hit.Apex or 0)
				local away = Vector3.new(body.Position.X - point.X, 0, body.Position.Z - point.Z).Magnitude
				due = crest.Shows > 0 and crest.Radius >= away - look.Hit.Short
			elseif thrown[hit.Beat] then
				due = true
			end
			if due then
				table.remove(struck, index)
				land(hit)
			end
		end
	end
	local gone = false
	local function destroy()
		gone = true
		for _, flash in flashes do
			flash.Gui:Destroy()
		end
		table.clear(flashes)
		for _, crest in crests do
			crest.Holder:Destroy()
		end
		table.clear(crests)
		-- Cut short (she's knocked down, or gone): what still waits lands now, so no number is lost.
		local waiting = table.clone(struck)
		table.clear(struck)
		for _, hit in waiting do
			hit.Look = false
			land(hit)
		end
	end
	return {
		Step = function(clock: number, _free: number?): boolean
			for index, name in order do
				if not thrown[name] and clock >= beats[name] then
					thrown[name] = true
					throw(index)
				end
			end
			for index = #crests, 1, -1 do
				local crest = crests[index]
				if not layCrest(crest, clock - crest.Born) then
					crest.Holder:Destroy()
					table.remove(crests, index)
				end
			end
			reach()
			local size = flashAt(clock)
			local forward = if root then root.CFrame.LookVector * 0.15 else Vector3.zero -- 0.15 out along her speakers' cones
			for _, flash in flashes do
				showBy(flash.Shown, size ~= nil)
				if size then
					flash.Gui.Size = UDim2.fromScale(size, size)
					flash.Gui.StudsOffsetWorldSpace = flash.Ring.WorldCFrame:VectorToObjectSpace(forward)
				end
			end
			local alive = clock < action.Length or #crests > 0
			if not alive then
				destroy()
			end
			return alive
		end,
		Destroy = destroy,
		Struck = function(beat: string, body: Model, landed: () -> (), drawn: boolean): boolean
			if action.Hits[beat] == nil then
				return false
			end
			local done = reached[body]
			if gone or (done and done[beat]) then
				landed() -- its crest has reached it already, or run out with the rest
				return true
			end
			for _, hit in struck do
				if hit.Beat == beat and hit.Body == body then
					hit.Look = hit.Look or drawn
					table.insert(hit.Landed, landed)
					return true
				end
			end
			table.insert(struck, { Beat = beat, Body = body, Look = drawn, Landed = { landed } })
			return true
		end,
	}
end

-- An action's effect as rows (Action.Effect; Config.Effects.Rows): the one player for every effect but the three older
-- signatures (Config.Effects.Older). Its rows play on the action's beats from its fighter's foot, facing as it does, at its
-- body's scale over the size they're written at. Up to their Free beat they run on the action's clock, which a hold
-- pauses, so what rides the body stays on the clip; from Free on, on the free clock, so a hold on the hit never stills
-- them. Ended early from Free on (its fighter fell), what it left in the street plays out and what rides the body goes;
-- before Free, or with none, it all goes at once, though a streak already thrown or a relight begun runs out its own time.
-- It never moves the camera: only the hit's shake does (the director, 2026-11-14).
-- Where a body's effect stands: at its foot, upright, facing as it faces. An R15 body (the replay's dummy) stands its
-- root's half height and its hip over the floor; an R6 one, 3 studs.
local function footOf(body: Model): CFrame
	local root = body:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = body:FindFirstChildOfClass("Humanoid")
	local stand = if root then root.CFrame else body:GetPivot()
	local drop = if root == nil then 0
		elseif humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then root.Size.Y / 2 + humanoid.HipHeight
		else R6_ROOT_HEIGHT * body:GetScale()
	local foot = stand.Position - Vector3.new(0, drop, 0)
	local facing = Vector3.new(stand.LookVector.X, 0, stand.LookVector.Z)
	facing = if facing.Magnitude > 0.01 then facing.Unit else Vector3.new(0, 0, -1)
	return CFrame.lookAt(foot, foot + facing)
end

function Effects.Play(beats: { [string]: number }, attacker: Model, target: () -> BasePart?, action: Actions.Action): Running
	local name = action.Effect :: string
	local written = (EffectsConfig.Rows :: any)[name] :: EffectsConfig.Rows
	assert(written, `{action.Id}: no rows "{name}"`)
	local bodyScale = attacker:GetScale()
	local marks: { [string]: number } = {}
	for beat, at in beats do
		marks[beat] = math.floor(at / FRAME + 0.5) -- the clip's markers stand on whole frames; the beats are written to 4 places
	end
	local rows = Rows.Play(name, footOf(attacker), bodyScale / written.Area, {
		Body = attacker,
		Marks = marks,
		Target = target,
		Hits = action.Hits,
		Cooldown = action.Cooldown,
		Run = run,
	})
	local FREE = if written.Free then beats[written.Free] else nil
	local LENGTH = action.Length
	local freeFrom: number? = nil
	local frames = 0
	local done = false

	local running: Running
	running = {
		Step = function(clock: number, given: number?): boolean
			if done then
				return false
			end
			if clock >= LENGTH then
				running.Destroy()
				return false
			end
			local free = given or clock
			if FREE and freeFrom == nil and clock >= FREE then
				freeFrom = free - (clock - FREE)
			end
			local seconds = if FREE and freeFrom then FREE + free - (freeFrom :: number) else clock
			frames = seconds / FRAME
			rows.Step(frames)
			return true
		end,
		Destroy = function()
			if done then
				return
			end
			done = true
			if FREE and frames >= FREE / FRAME and frames < rows.End then -- what it left plays out; the body's rows go
				rows.Let()
				local from = frames
				run(function(age: number): boolean
					return rows.Step(from + age / FRAME)
				end, rows.Destroy)
			else
				rows.Destroy()
			end
		end,
	} :: Running
	return running
end

-- A hit's look on a body (Definitions.Actions, Looks; Config.Effects.Lasting): its rows ride the body from now, on the
-- effects' clock, for as long as `holds` says, and go at once when it stops: Ground Wire's stop on each body it holds,
-- ended with its stun, and his shield, ended with it (AR11). Its foot is where the body stood when it began. Nil when the
-- look is left out or has no rows.
function Effects.Lasting(name: string, body: Model, holds: () -> boolean, done: (() -> ())?): Rows.Player?
	local written = (EffectsConfig.Rows :: any)[name] :: EffectsConfig.Rows?
	if written == nil or EffectsConfig.Lasting[name] ~= true then
		return nil
	end
	local rows = Rows.Play(name, footOf(body), body:GetScale() / written.Area, { Body = body, Run = run })
	local live = true
	run(function(age: number): boolean
		-- the switch read each frame, so a Tune to false takes it off at once
		return live and EffectsConfig.Lasting[name] == true and body.Parent ~= nil and holds() and rows.Step(age / FRAME)
	end, function()
		live = false
		rows.Destroy()
		if done then
			done()
		end
	end)
	return rows
end

-- The three older signatures, by the name an action's Effect gives (Config.Effects.Older), until the finish pass.
Effects.Older = {
	Haymaker = Effects.Haymaker,
	LanternBurst = Effects.LanternBurst,
	HeldNote = Effects.HeldNote,
} :: { [string]: (beats: { [string]: number }, attacker: Model, target: () -> BasePart?, action: Actions.Action) -> Running }

-- A box's lean on its action's clock: back to the strike, a lunge on it, and back. Rotates about the box's foot.
function Effects.BoxPose(beats: { [string]: number }, clock: number, height: number): CFrame
	local strike = beats.Strike or 0.5
	local recover = (beats.Recover or strike + 0.2) + 0.25
	local lean: number = 0
	local lunge: number = 0
	if clock < strike - 0.06 then
		lean = 14 * easeOut(clock / math.max(0.01, strike - 0.06))
	elseif clock < strike then
		local t = (clock - (strike - 0.06)) / 0.06
		lean = lerp(14, -20, t)
		lunge = lerp(0, 0.9, t)
	elseif clock < recover then
		local t = easeOut((clock - strike) / (recover - strike))
		lean = lerp(-20, 0, t)
		lunge = lerp(0.9, 0, t)
	end
	return CFrame.new(0, -height / 2, -lunge) * CFrame.Angles(math.rad(lean), 0, 0) * CFrame.new(0, height / 2, 0)
end

-- A box's flinch: thrown back a little, easing home over `seconds`, from `age` seconds in.
function Effects.BoxFlinch(age: number, seconds: number, height: number): CFrame
	local t = math.clamp(age / seconds, 0, 1)
	local lean = 10 * (1 - easeOut(t))
	return CFrame.new(0, -height / 2, 0) * CFrame.Angles(math.rad(lean), 0, 0) * CFrame.new(0, height / 2, 0)
end

-- A Shade falls: its whole body hidden on one frame, a flash and a scatter of paper from `at` (a Shade's collar, else its
-- pivot). The stand-in until AR2's burst of light and paper.
-- A Shade's burst, the sky lantern (AR2, section 11; Config.Effects.ShadeBurst): every picture on every frame from the art
-- sheet's table (Config.ShadeBurstArt), on billboards of the one picture, untinted and unlit. Up to the Down clip's Burst
-- marker it runs on the clip's own clock, so the killing hit's hold pauses the charge with the body; the charge rides the
-- collar as the Torso tips. On the marker the whole body hides on the flare's frame, the first picture the flare is drawn in,
-- and from then on it runs on the effects' clock, everything placed from where the collar stood, in the Shade's frame as it stood. The table is
-- an ordinary Shade's size, so a Shade's scale (the elite's) scales it. With no clip it starts at the Burst.
-- A keeper's fall (`fall`, Config.Effects.Falls) runs the same burst on its own Down clip: the table's frames are moved
-- to its Burst marker, and its Kept parts aren't hidden (Effects.LanternOut puts them out).
export type Fall = typeof(EffectsConfig.Falls.Lamplighter)
function Effects.ShadeBurst(model: Model, down: AnimationTrack?, collar: Attachment?, fall: Fall?)
	local look = EffectsConfig.ShadeBurst
	local scale = model:GetScale()
	local offset = if fall then ShadeBurstArt.Burst - fall.Burst else 0 -- the table's frame for a clip's frame
	local kept: { [string]: boolean } = {}
	for _, name in if fall then fall.Kept else {} do
		kept[name] = true
	end
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	local anchor = part(HOT)
	anchor.Name = "NL_ShadeBurst"
	anchor.Transparency = 1
	anchor.Size = Vector3.one * PICTURE_DEPTH
	anchor.CFrame = model:GetPivot()
	-- Every picture's billboard is made now, drawn and see-through, and shown by its image's transparency: a billboard made
	-- or enabled on the frame it's wanted isn't drawn on that frame, which would lose the flare, a frame long, entirely.
	local shown: { [string]: { Gui: BillboardGui, Label: ImageLabel } } = {}
	for _, pictures in ShadeBurstArt.Frames do
		for _, picture in pictures do
			local key = picture.Kind .. picture.Id
			if shown[key] == nil then
				local gui, label = billboard(anchor, look.Picture)
				gui.Brightness = look.Brightness
				gui.ClipsDescendants = false -- a scrap turns past its square
				gui.Enabled = true
				label.ImageTransparency = 1
				shown[key] = { Gui = gui, Label = label }
			end
		end
	end
	local reached = down == nil
	local marker: RBXScriptConnection? = nil
	if down then
		marker = down:GetMarkerReachedSignal("Burst"):Connect(function()
			reached = true
		end)
	end
	local burstTime = (ShadeBurstArt.Burst - offset) * FRAME
	local burstAge: number? = nil
	local stood: CFrame? = nil
	local function standing(): CFrame
		local turn = if root then root.CFrame.Rotation else model:GetPivot().Rotation
		local at = if collar and collar.Parent then collar.WorldPosition else model:GetPivot().Position
		return CFrame.new(at) * turn
	end
	local hidden = false
	local was: { [string]: boolean } = {} -- the pictures shown on the last step
	run(function(age: number): boolean
		-- A billboard set in this step is drawn a frame later than a part, so the body hides the step after the flare is
		-- set: the picture that first shows the flare is the first without the body.
		if burstAge ~= nil and not hidden then
			hidden = true
			for _, p in model:GetDescendants() do
				if p:IsA("BasePart") and not kept[p.Name] then
					p.LocalTransparencyModifier = 1
				end
			end
		end
		if burstAge == nil and model.Parent == nil then
			-- the body left before its marker (cleared, its pack replaced, streamed out): its clip's clock stops short of the
			-- Burst, so the charge goes with it rather than waiting on it for good (AR2, section 13)
			return false
		end
		if not reached and down and (down.TimePosition >= burstTime - 1e-3 or not down.IsPlaying or age >= burstTime + look.Wait) then
			reached = true -- the marker's signal can come a step late; the clip's own clock says it's there, or has stalled
		end
		if reached and burstAge == nil then
			burstAge = age
			stood = standing()
		end
		-- After the Burst, the nearest frame: a step runs a hair either side of a frame, and counting down would hold the
		-- flare, a frame long, for two pictures about every other burst.
		local frame = if burstAge then ShadeBurstArt.Burst + math.floor((age - (burstAge :: number)) / FRAME + 0.5) else math.floor((down :: AnimationTrack).TimePosition / FRAME + 1e-6) + offset
		if frame > ShadeBurstArt.Last then
			return false
		end
		local origin = stood or standing()
		anchor.CFrame = CFrame.new(origin.Position)
		local now: { [string]: boolean } = {}
		for _, picture in ShadeBurstArt.Frames[frame] or {} do
			local key = picture.Kind .. picture.Id
			local gui, label = shown[key].Gui, shown[key].Label
			local at = picture.At * scale -- the table's right, forward and up
			gui.Size = UDim2.fromScale(picture.Size.X * scale, picture.Size.Y * scale)
			gui.StudsOffsetWorldSpace = origin.RightVector * at.X + origin.LookVector * at.Y + origin.UpVector * at.Z
			label.ImageTransparency = 0
			label.ImageRectOffset = picture.Offset
			label.ImageRectSize = picture.Rect
			label.Rotation = picture.Rotation
			label.Size = UDim2.fromScale(picture.Squash, 1)
			label.Position = UDim2.fromScale((1 - picture.Squash) / 2, 0)
			now[key] = true
		end
		-- A billboard shown or changed is drawn a frame late, and one cleared is gone at once (seen in the take, AR2,
		-- section 13), so each picture is cleared a step after its last frame: the whole burst is drawn one frame behind,
		-- evenly, never with a blank frame where one picture hands over to the next.
		for key, item in shown do
			if not now[key] and not was[key] then
				item.Label.ImageTransparency = 1
			end
		end
		was = now
		return true
	end, function()
		if marker then
			marker:Disconnect()
		end
		anchor:Destroy()
	end)
end

-- A keeper's lantern goes out (AR7, section 5; Config.Effects.Falls): on its Down clip's clock, run on past the clip's held
-- last frame, the lantern's glow and its light steady at Glow to Gutter, flickering under a falling top to Out, dark from
-- there, its paper going down to Dark from Gutter, eased in, there by Out; on Gone its Kept parts go
-- to a handful of the burst's own paper scraps, the lantern's from the lantern, the pole's from between its foot and its
-- hook, each picture as the art table draws it from the Burst on (only rising, only shrinking), at the model's scale. The
-- parts hide the step after the scraps are set, as the body hides after the flare. Runs beside Effects.ShadeBurst.
function Effects.LanternOut(model: Model, down: AnimationTrack?, fall: Fall)
	local scale = model:GetScale()
	local lantern = model:FindFirstChild(fall.Lantern) :: BasePart?
	local pole = model:FindFirstChild(fall.Pole) :: BasePart?
	local glow = if lantern then lantern:FindFirstChildOfClass("SurfaceAppearance") else nil
	local light = if lantern then lantern:FindFirstChildWhichIsA("PointLight", true) else nil
	local brightness = if light then light.Brightness else 0
	local paper = if glow then glow.Color else nil
	local kept: { BasePart } = {}
	for _, name in fall.Kept do
		local p = model:FindFirstChild(name)
		if p and p:IsA("BasePart") then
			table.insert(kept, p)
		end
	end
	-- The scraps: ids by where they rise from, and a billboard each made now, drawn and see-through (a billboard made on
	-- the frame it's wanted isn't drawn on that frame).
	local from: { [number]: string } = {}
	for id = 1, fall.Scraps.Lantern do
		from[id] = "Lantern"
	end
	for id = fall.Scraps.Lantern + 1, fall.Scraps.Lantern + fall.Scraps.Pole do
		from[id] = "Pole"
	end
	local anchors: { [string]: Part } = {}
	for _, where in { "Lantern", "Pole" } do
		local anchor = part(HOT)
		anchor.Name = "NL_LanternOut"
		anchor.Transparency = 1
		anchor.Size = Vector3.one * PICTURE_DEPTH
		anchor.CFrame = model:GetPivot()
		anchors[where] = anchor
	end
	local shown: { [number]: { Gui: BillboardGui, Label: ImageLabel } } = {}
	for id, where in from do
		local gui, label = billboard(anchors[where], EffectsConfig.ShadeBurst.Picture)
		gui.Brightness = EffectsConfig.ShadeBurst.Brightness
		gui.ClipsDescendants = false
		gui.Enabled = true
		label.ImageTransparency = 1
		shown[id] = { Gui = gui, Label = label }
	end
	local function point(on: BasePart?, name: string): Vector3?
		local a = if on then on:FindFirstChild(name) else nil
		return if a and a:IsA("Attachment") then a.WorldPosition else nil
	end
	local function flicker(clock: number): number
		local n = math.floor(clock * fall.Flicker.Rate)
		local r = (math.sin(n * 12.9898 + 4.1414) * 43758.5453) % 1 -- the same jumps every fall
		return fall.Flicker.Low + (1 - fall.Flicker.Low) * r
	end
	local clock, last = 0, 0
	local goneAge: number? = nil
	local hidden = false
	local turn = CFrame.identity
	local was: { [number]: boolean } = {}
	run(function(age: number): boolean
		-- the clip's clock while it plays (a hold pauses it with the body), else on from where it stood: its end held too
		local ended = down ~= nil and down.Length > 0 and down.TimePosition >= down.Length - HELD_END
		if down and down.IsPlaying and not ended and goneAge == nil then
			clock = math.max(clock, down.TimePosition)
		else
			clock += age - last
		end
		last = age
		if goneAge ~= nil and not hidden then
			hidden = true
			for _, p in kept do
				p.LocalTransparencyModifier = 1
			end
		end
		if goneAge == nil then
			if model.Parent == nil then
				return false -- the body left before Gone: its parts went with it
			end
			local frame = clock / FRAME
			local g = fall.Glow
			if frame >= fall.Out then
				g = 0
			elseif frame >= fall.Gutter then
				g = fall.Glow * (1 - (frame - fall.Gutter) / (fall.Out - fall.Gutter)) * flicker(clock)
			end
			if glow then
				glow.EmissiveStrength = g
				if paper then
					local p = math.clamp((frame - fall.Gutter) / (fall.Out - fall.Gutter), 0, 1)
					glow.Color = paper:Lerp(fall.Dark, p ^ fall.Ease)
				end
			end
			if light then
				light.Brightness = brightness * g / fall.Glow
				light.Enabled = g > 0
			end
			if frame < fall.Gone then
				return true
			end
			goneAge = age
			turn = model:GetPivot().Rotation
			local up = Vector3.new(0, fall.Scraps.Lift * scale, 0)
			local at = point(lantern, "Lantern")
			if at then
				anchors.Lantern.CFrame = CFrame.new(at + up)
			end
			local foot, hook = point(pole, "PoleFoot"), point(pole, "HookTip")
			if foot and hook then
				anchors.Pole.CFrame = CFrame.new((foot + hook) / 2 + up)
			end
		end
		-- the scraps as the table draws them from the frame after its Burst, the nearest frame (as the burst counts)
		local artFrame = ShadeBurstArt.Burst + 1 + math.floor((age - (goneAge :: number)) / FRAME + 0.5)
		if artFrame > ShadeBurstArt.Last + 1 then
			return false
		end
		local now: { [number]: boolean } = {}
		for _, picture in ShadeBurstArt.Frames[artFrame] or {} do
			local item = if picture.Kind == "scrap" then shown[picture.Id] else nil
			if item then
				local at = picture.At * scale
				item.Gui.Size = UDim2.fromScale(picture.Size.X * scale, picture.Size.Y * scale)
				item.Gui.StudsOffsetWorldSpace = turn.RightVector * at.X + turn.LookVector * at.Y + turn.UpVector * at.Z
				item.Label.ImageTransparency = 0
				item.Label.ImageRectOffset = picture.Offset
				item.Label.ImageRectSize = picture.Rect
				item.Label.Rotation = picture.Rotation
				item.Label.Size = UDim2.fromScale(picture.Squash, 1)
				item.Label.Position = UDim2.fromScale((1 - picture.Squash) / 2, 0)
				now[picture.Id] = true
			end
		end
		-- each cleared a step after its last frame, as the burst's are: drawn one behind, evenly
		for id, item in shown do
			if not now[id] and not was[id] then
				item.Label.ImageTransparency = 1
			end
		end
		was = now
		return true
	end, function()
		for _, anchor in anchors do
			anchor:Destroy()
		end
	end)
end

-- A number over a body (docs/ui.md, "The HUD, in the world"; TR3): one for each `key` on it, so a flurry (one press's
-- hits) is one counting number and never a wall (Rules.Hud's Count; AR4 section 10, fix 1). Its look is a style of
-- Config.Hud.Numbers: Dealt, Element (in `colour`), Received, Heal, Critical, or Word (`word`, grey, on a pointer).
-- Each amount after the first, while it shows, joins it: it counts up to the new total over Combat.Numbers.Count,
-- swells Pop times and settles, and its fade starts over. A critical after makes it a critical from there. It rises
-- from the body and is placed clear of the numbers already up (Rules.Hud.Place). Drawn on the World layer (UI.World),
-- so a capture shows it; sizes are authored at the phone's (UI.Theme.Author) and scale with the layer.
-- Its size follows its hit's rung (`rung`; Rules.Hud.NumberScale; AR8 C, research's pass on A): a heavier hit joining it
-- makes it larger from there. While a heavier hit lands on the body, the lower numbers on it give way (Effects.Yield).
type Numbers = { Rise: number, Seconds: number, Size: number, Count: number, Pop: number }
export type NumberLook = { Style: string, Colour: Color3?, Word: string?, Rung: number? }
type Counting = {
	Rung: number?, -- its hit's, or nil for a word
	YieldAt: number?, -- its age when a heavier hit sent it aside
	Aside: Vector2, -- the way it leaves, a unit
	Age: number,
	Count: Hud.Count,
	Plate: Frame,
	Row: Frame,
	Sweep: ImageLabel?,
	Pointer: Frame?,
	Scale: UIScale,
	Style: string,
	Colour: Color3?,
	Prefix: string,
	Word: string?,
	Text: string, -- what it shows now
	Fade: number, -- its transparency now
	Big: boolean, -- a critical
	Where: () -> Vector3?,
	Shift: Vector2,
	W: number,
	H: number,
}
local counting: { [BasePart]: { [string]: Counting } } = {}
Effects.Counting = counting -- for the self-test

local GLYPH = 0.72 -- a digit's height, of its text size: the critical's stroke is as tall

-- A style's look and its size, read from Config at the number's birth, so a Tune shows on the next number.
local function lookOf(style: string, colour: Color3?): (Digits.Look, number)
	local config = HudConfig.Numbers
	if style == "Critical" then
		local c = config.Critical
		return { Top = c.Top, Foot = c.Foot, Outline = c.Outline, Weight = c.Weight, Gap = c.Gap, Italic = c.Italic }, c.Size
	end
	local s = config.Styles[style] or config.Styles.Dealt
	return { Colour = colour or s.Colour, Outline = s.Outline, Weight = s.Weight, Gap = s.Gap, Italic = s.Italic }, s.Size
end

local function textOf(c: Counting, numbers: Numbers): string
	if c.Word then
		return c.Word
	end
	return c.Prefix .. Hud.Digits(Hud.Shown(c.Count, c.Age, numbers.Count))
end

-- The critical's stroke behind its digits (CritSweep, round 2; Config.Hud.Numbers.Critical.Sweep).
local function sweep(c: Counting, size: number, look: Digits.Look)
	local config = HudConfig.Numbers.Critical.Sweep
	local w = Digits.Width(c.Text, size, look)
	local h = config.Height * GLYPH * size
	local digit = HudConfig.Numbers.Digit * size
	local image = c.Sweep
	if image == nil then
		local made = Instance.new("ImageLabel")
		made.Name = "Sweep"
		made.BackgroundTransparency = 1
		made.Image = UIKit.Images.CritSweep.Id
		made.ScaleType = Enum.ScaleType.Stretch
		made.AnchorPoint = Vector2.new(0, 0.5)
		made.ZIndex = 1
		made.Parent = c.Plate
		image = made
		c.Sweep = made
	end
	local s = image :: ImageLabel
	s.ImageColor3 = config.Tint
	s.Size = UDim2.fromOffset(math.max(config.Width * w, config.Least * h), h)
	s.Position = UDim2.new(0.5, -w / 2 - config.Left * digit, 0.5, 0)
end

local function restyle(c: Counting, numbers: Numbers)
	local look, share = lookOf(c.Style, c.Colour)
	local size = numbers.Size * share * Hud.NumberScale(c.Style, c.Rung, HudConfig.Numbers.Rung)
	Digits.Restyle(c.Row, size, look)
	c.W, c.H = Digits.Width(c.Text, size, look), size * 1.2
	c.Plate.Size = UDim2.fromOffset(c.W + size, c.H)
	if c.Style == "Critical" then
		sweep(c, size, look)
	end
end

-- Clear of the numbers already up: each one's box where it stands now, in authored pixels. And under the top band its
-- whole life (UI.World's band, the HUD's; TR3's verdict, fix 4): `rise` is how far it climbs, in studs.
local function place(c: Counting, rise: number)
	local camera = workspace.CurrentCamera
	local scale = Layers.Scale()
	local at = c.Where()
	if camera == nil or at == nil or scale <= 0 then
		return
	end
	local function box(other: Counting, point: Vector3): Hud.Box?
		local v = camera:WorldToViewportPoint(point)
		if v.Z <= 0 then
			return nil
		end
		return { X = v.X / scale + other.Shift.X, Y = v.Y / scale + other.Shift.Y - other.H / 2, W = other.W, H = other.H }
	end
	local want = box(c, at)
	if want == nil then
		return
	end
	local taken: { Hud.Box } = {}
	for _, onBody in counting do
		for _, other in onBody do
			local point = if other ~= c then other.Where() else nil
			local b = if point then box(other, point) else nil
			if b then
				table.insert(taken, b)
			end
		end
	end
	local peak = camera:WorldToViewportPoint(at + Vector3.new(0, rise, 0))
	local climb = if peak.Z > 0 then (want.Y + c.H / 2 - (peak.Y / scale + c.Shift.Y)) else 0 -- the rise, in authored pixels
	local dx, dy = Hud.Place(want, taken, HudConfig.Numbers.Slots, World.Edge(), climb)
	c.Shift = Vector2.new(dx, dy)
	World.Shift(c.Plate, c.Shift)
end

function Effects.Number(root: BasePart, key: string, amount: number?, look: NumberLook, numbers: Numbers)
	local onBody = counting[root] or {}
	counting[root] = onBody
	local live = onBody[key]
	if live then
		Hud.Add(live.Count, amount or 0, live.Age, numbers.Count)
		local heavier = look.Rung ~= nil and look.Rung > (live.Rung or 0)
		if heavier then
			live.Rung = look.Rung
		end
		if look.Style == "Critical" and not live.Big then
			live.Big, live.Style = true, "Critical"
			restyle(live, numbers)
		elseif heavier then
			restyle(live, numbers)
		end
		return
	end
	local rise = 0
	local where = function(): Vector3?
		return if root.Parent then root.Position + Vector3.new(0, 3 + rise, 0) else nil
	end
	local plate = World.Plate("Number", Vector2.new(numbers.Size * 4, numbers.Size * 1.2), where)
	local scale = Instance.new("UIScale")
	scale.Parent = plate
	local first, share = lookOf(look.Style, look.Colour)
	local c: Counting = {
		Rung = if amount == nil then nil else look.Rung,
		YieldAt = nil,
		Aside = Vector2.zero,
		Age = 0,
		Count = Hud.Count(amount or 0),
		Plate = plate,
		Row = Digits.new(plate, numbers.Size * share, first),
		Sweep = nil,
		Pointer = nil,
		Scale = scale,
		Style = look.Style,
		Colour = look.Colour,
		Prefix = if look.Style == "Heal" then "+" else "",
		Word = if amount == nil then (look.Word or "Dodge") else nil,
		Text = "",
		Fade = 0,
		Big = look.Style == "Critical",
		Where = where,
		Shift = Vector2.zero,
		W = 0,
		H = 0,
	}
	c.Text = textOf(c, numbers)
	Digits.Set(c.Row, c.Text)
	restyle(c, numbers)
	if c.Word then
		-- The word's pointer: a small grey diamond under it, pointing at the body.
		local pointer = Instance.new("Frame")
		pointer.Name = "Pointer"
		local side = HudConfig.Numbers.Pointer
		pointer.Size = UDim2.fromOffset(side, side)
		pointer.AnchorPoint = Vector2.new(0.5, 0.5)
		pointer.Position = UDim2.new(0.5, 0, 1, side * 0.2)
		pointer.Rotation = 45
		pointer.BackgroundColor3 = first.Colour or Color3.new(1, 1, 1)
		pointer.BorderSizePixel = 0
		pointer.ZIndex = 1
		pointer.Parent = plate
		c.Pointer = pointer
	end
	onBody[key] = c
	World.Below(plate)
	place(c, numbers.Rise)
	local function lay(age: number): boolean
		c.Age = age
		if not Hud.Live(c.Count, age, numbers.Seconds) then
			return false
		end
		local since = age - (if c.Count.Changed > -math.huge then c.Count.Changed else 0)
		local t = since / numbers.Seconds
		rise = numbers.Rise * easeOut(age / numbers.Seconds)
		local text = textOf(c, numbers)
		if text ~= c.Text then
			c.Text = text
			Digits.Set(c.Row, text)
			if c.Style == "Critical" then
				restyle(c, numbers)
			end
		end
		scale.Scale = 1 + (numbers.Pop - 1) * Hud.Swell(c.Count, age, numbers.Count)
		c.Fade = math.clamp((t - 0.6) / 0.4, 0, 1)
		local yieldAt = c.YieldAt
		if yieldAt then
			-- Giving way to a heavier hit: out of the body's middle and up, fading, eased in; gone, it's done.
			local yield = HudConfig.Numbers.Yield
			local fade, aside = Hud.Yield(age - yieldAt, yield.Seconds)
			c.Fade = math.max(c.Fade, fade)
			World.Shift(plate, c.Shift + c.Aside * yield.Aside * aside)
			if fade >= 1 then
				return false
			end
		end
		Digits.Fade(c.Row, c.Fade)
		local s = c.Sweep
		if s then
			local floor = HudConfig.Numbers.Critical.Sweep.Transparency
			s.ImageTransparency = floor + (1 - floor) * c.Fade
		end
		local pointer = c.Pointer
		if pointer then
			pointer.BackgroundTransparency = c.Fade
		end
		return true
	end
	lay(0)
	run(lay, function()
		if onBody[key] == c then
			onBody[key] = nil
		end
		if next(onBody) == nil and counting[root] == onBody then
			counting[root] = nil
		end
		World.Remove(plate)
	end)
end

-- A hit of `rung` landing on `root`: the numbers on it of a lower rung leave its middle, out to their side and up,
-- fading over Config.Hud.Numbers.Yield.Seconds, eased in, so the heavy hit's flash and tremble are seen (research's pass
-- on AR8 A, fix 1). Never down the body (the content check's condition 1). A number that gives way takes no more hits:
-- the next one on its key is a new number.
function Effects.Yield(root: BasePart, rung: number)
	local onBody = counting[root]
	if onBody == nil then
		return
	end
	for key, c in onBody do
		if c.YieldAt == nil and (c.Rung or 0) < rung then
			c.YieldAt = c.Age
			local side = if c.Shift.X < 0 then -1 else 1
			c.Aside = Vector2.new(side, -1).Unit
			onBody[key] = nil
		end
	end
end

-- A beam takes its transparency only at its segments' joints: one segment draws only its two ends, and the soft foot and
-- the fade at the top vanish. Twenty put a joint on every twentieth of it, where its keypoints fall.
local BEAM_SEGMENTS = 20

-- A level gained (Config.Effects.LevelUp), rung 5: light that rises. A column of experience's blue stands up out of the
-- feet past the head, brightest early; its foot then climbs after its top as it narrows and fades. A breath later a
-- wider, fainter sleeve of the same light climbs the body, over it. Each is a beam facing the camera, sized by the
-- lead, soft at its foot and fading to nothing at its top, so it reads as light and never as a solid. The new level
-- pops in clear over the lead's head as the column peaks, bright and edged in the blue, and rises, held long enough to
-- read, a sunburst behind it and one light band across it (TR6). All of it follows a walking lead. Returns the column, the word and the sleeve, for the self-test; each beam's
-- "Opaque" attribute is how opaque it is now.
function Effects.LevelUp(root: BasePart, level: number): (Beam, TextLabel, Beam)
	local look = EffectsConfig.LevelUp
	local c, s, w = look.Column, look.Sleeve, look.Word
	local xp = HudConfig.Card.Xp -- experience's one colour, the card's thread's (research's pass on TR3's fix round)
	local ends = part(xp)
	ends.Name = "LevelUp"
	ends.Transparency = 1
	ends.Size = Vector3.one * 0.2
	ends.CFrame = root.CFrame
	local function shaft(name: string): Beam
		local foot = Instance.new("Attachment")
		foot.Parent = ends
		local top = Instance.new("Attachment")
		top.Parent = ends
		local beam = Instance.new("Beam")
		beam.Name = name
		beam.Attachment0, beam.Attachment1 = foot, top -- 0 along it is the foot
		beam.FaceCamera = true
		beam.Color = ColorSequence.new(xp)
		beam.LightEmission = c.Emission
		beam.LightInfluence = 0
		beam.Segments = BEAM_SEGMENTS
		beam.Enabled = false
		beam:SetAttribute("Opaque", 0)
		beam.Parent = ends
		return beam
	end
	local column, sleeve = shaft("Column"), shaft("Sleeve")
	sleeve.ZOffset = s.Front
	-- The column's picture, stretched once along it, its top row at the foot; white at its peak (AR8 C, fix 2).
	column.Texture = c.Picture
	column.TextureMode = Enum.TextureMode.Stretch
	column.TextureLength = 1
	column.TextureSpeed = 0
	local white = Color3.new(1, 1, 1)
	local feet = root.Position - Vector3.new(0, R6_ROOT_HEIGHT - 0.1, 0)
	-- How tall the lead stands, feet to the top of its model, hat and all.
	local tall = look.Tall
	local model = root.Parent
	if model and model:IsA("Model") then
		local box, extent = model:GetBoundingBox()
		tall = math.max(box.Position.Y + extent.Y / 2 - feet.Y, 1)
	end
	local size = look.Size
	local rise = 0
	-- As wide as its words and its edge, so it stands aside from only what it would really cross.
	local words = `Level {level}`
	local wide = TextService:GetTextSize(words, size, Enum.Font.BuilderSansExtraBold, Vector2.new(1000, 100)).X + w.Edge * 2 + 4
	local plate = World.Plate("LevelUp", Vector2.new(wide, size * 1.6), function(): Vector3?
		-- The plate's foot, clear over the lead's top, hat and all, wherever it walks.
		local over = tall + w.Clear + rise - (R6_ROOT_HEIGHT - 0.1)
		return if root.Parent then root.Position + Vector3.new(0, over, 0) else nil
	end)
	World.Below(plate, true) -- under the cards and pills it crosses, and free in the sky between them (AR8 C, fix 1)
	local fill = Color3.new(1, 1, 1):Lerp(xp, w.Fill)
	local label = Text.new({ Name = "Level", Size = size, Font = Theme.Font.Number, Colour = fill, Align = Enum.TextXAlignment.Center, Parent = plate })
	label.Text = words
	label.TextTransparency = 1
	label.TextStrokeTransparency = 1
	local edge = Instance.new("UIStroke")
	edge.Color = xp
	edge.Thickness = w.Edge * Layers.Scale() -- a stroke's width isn't grown by the layer's UIScale
	edge.LineJoinMode = Enum.LineJoinMode.Round
	edge.Transparency = 1
	edge.Parent = label
	local swell = Instance.new("UIScale")
	swell.Scale = w.From
	swell.Parent = label
	local wordAt = c.Peak * c.Seconds
	-- A reward of rung 5 (TR6; docs/research/vfx-reference.md, "UI effects", DESIGN 3): a sunburst behind the word as it
	-- lands, and one light band sweeping across its fill and its edge together.
	local motion = HudConfig.Motion
	Rays.Play(plate, Vector2.new(wide, size * 1.6) / 2, size * motion.Rays.Size, white:Lerp(xp, 0.35), wordAt + motion.Rays.Delay)
	Shine.Play(Shine.Lay(label, fill), wordAt)
	Shine.Play(Shine.Lay(edge, xp), wordAt)
	-- A shaft of light standing over `at`: its foot and top in studs above, its width, how opaque at its fullest. Along
	-- it: soft at its foot, full a fifth of the way up, and fading to nothing over its top's Fade.
	local function lay(beam: Beam, at: Vector3, foot: number, top: number, width: number, opaque: number)
		local a0, a1 = beam.Attachment0 :: Attachment, beam.Attachment1 :: Attachment
		a0.WorldPosition = at + Vector3.new(0, foot, 0)
		a1.WorldPosition = at + Vector3.new(0, math.max(top, foot + 0.05), 0)
		beam.Width0, beam.Width1 = width, width
		beam.Enabled = opaque > 0
		beam:SetAttribute("Opaque", opaque)
		if opaque > 0 then
			beam.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1 - opaque * c.Foot),
				NumberSequenceKeypoint.new(0.2, 1 - opaque),
				NumberSequenceKeypoint.new(1 - c.Fade, 1 - opaque),
				NumberSequenceKeypoint.new(1, 1),
			})
		end
	end
	-- Where a shaft is at `t` of its life: its top up fast, then on up a little; its foot after its top, eased in; its
	-- width narrowing as its foot climbs; brightest at the peak, early.
	local function climb(t: number, height: number, width: number, narrow: number): (number, number, number, number)
		local top = height * (easeOut(t / c.Climb) + 0.2 * math.max(0, t - c.Climb) / (1 - c.Climb))
		local u = math.clamp((t - c.Peak) / (1 - c.Peak), 0, 1)
		return top * u * u, top, width * (1 - narrow * u * u), Hud.Pop(t, c.Peak)
	end
	local last = math.max(c.Seconds, s.Delay + s.Seconds, wordAt + look.Seconds)
	run(function(age: number): boolean
		if age >= last then
			return false
		end
		local at = if root.Parent then root.Position - Vector3.new(0, R6_ROOT_HEIGHT - 0.1, 0) else feet
		local tc = age / c.Seconds
		if tc < 1 then
			local foot, top, width, pop = climb(tc, tall + c.Over, tall * c.Wide, c.Narrow)
			lay(column, at, foot, top, width, pop * c.Opaque)
			column.Color = ColorSequence.new(white:Lerp(xp, 1 - pop)) -- white at its peak, the blue as it fades
		else
			lay(column, at, 0, 0, 0, 0)
		end
		local ts = (age - s.Delay) / s.Seconds
		if ts > 0 and ts < 1 then
			local foot, top, width, pop = climb(ts, tall + s.Over, tall * s.Wide, c.Narrow / 2)
			lay(sleeve, at, foot, top, width, pop * s.Alpha)
		else
			lay(sleeve, at, 0, 0, 0, 0)
		end
		local since = age - wordAt
		if since >= 0 then
			local t = since / look.Seconds
			local u = math.clamp(since / w.Pop, 0, 1) - 1
			swell.Scale = lerp(w.From, 1, 1 + 2.7 * u * u * u + 1.7 * u * u) -- in with a small overshoot (a Back ease)
			rise = look.Rise * easeOut(t)
			label.TextTransparency = math.clamp((t - 0.7) / 0.3, 0, 1)
			edge.Transparency = label.TextTransparency
		end
		return true
	end, function()
		ends:Destroy()
		World.Remove(plate)
	end)
	return column, label, sleeve
end

-- A shard won, in the world (Config.Effects.Drop; Rules.Flight; TR24's fix 8): it pops out of the fallen Shade at `from`
-- a step toward the avatar, bounces once on the floor, rests there with `name` over it, then is pulled into the avatar,
-- eased in, and lands in a small flash, when `landed` runs (the toast says it then). The hero shape is the shard alone,
-- spinning; its plate shows from the landing to the pull. `to` is read every frame, so it follows a walking avatar. No
-- `from`: it only lands, at once.
function Effects.Drop(from: Vector3?, to: () -> Vector3?, name: string, landed: (() -> ())?)
	local look = EffectsConfig.Drop
	local function arrive(at: Vector3?)
		if landed then
			task.spawn(landed)
		end
		if at == nil then
			return
		end
		local ball = part(Theme.Colour.Ready, Enum.Material.Neon)
		ball.Shape = Enum.PartType.Ball
		run(function(age: number): boolean
			local t = age / look.Flash.Seconds
			if t >= 1 then
				return false
			end
			ball.Size = Vector3.one * lerp(1, look.Flash.To, easeOut(t))
			ball.CFrame = CFrame.new(at)
			ball.Transparency = t
			return true
		end, function()
			ball:Destroy()
		end)
	end
	local start = to()
	if from == nil or start == nil then
		arrive(start)
		return
	end
	local fell: Vector3 = from
	local floor = fell.Y - R6_ROOT_HEIGHT
	local shard = part(Theme.Colour.Ready, Enum.Material.Neon)
	shard.Name = "Drop"
	shard.Size = Vector3.new(look.Size * 0.55, look.Size, look.Size * 0.55)
	local last: Vector3 = start
	local where: Vector3 = fell
	local beat: Flight.Beat = "Pop"
	local p = look.Plate
	local plate = World.Plate("Drop", Vector2.new(p.Width, p.Line + 8), function(): Vector3?
		return if beat == "Bounce" or beat == "Rest" then where + Vector3.new(0, look.Size / 2 + p.Lift, 0) else nil
	end)
	World.Below(plate)
	local label = Text.new({ Name = "Name", Size = Theme.Text.Body, Font = Theme.Font.Strong, Colour = Theme.Colour.Ready, Align = Enum.TextXAlignment.Center, Parent = plate })
	label.Text = name
	label.TextStrokeTransparency = 0.2
	drops[shard] = plate
	run(function(age: number): boolean
		last = to() or last
		local at, now = Flight.At(age, fell, floor, last, look)
		where, beat = at, now
		shard.CFrame = CFrame.new(at) * CFrame.Angles(0, age * look.Spin, math.rad(20))
		return now ~= "Done"
	end, function()
		drops[shard] = nil
		shard:Destroy()
		World.Remove(plate)
		arrive(last)
	end)
end

-- For tests: each drop in the world now and its name plate.
function Effects.Drops(): { [BasePart]: Frame }
	local out: { [BasePart]: Frame } = {}
	for shard, plate in drops do
		out[shard] = plate
	end
	return out
end

-- The camera's trauma (Config.Combat.Shake; Rules.Fight.Trauma): each jolt adds to it, it falls on its own, and the
-- camera shakes by its square, moving and turning (roll, and half as much pitch and yaw) on smooth noise. AR8 A.
local trauma = 0
local shaken = 0 -- seconds the noise has run
local SEED = math.random() * 100

-- A fallen lead leaving as light where it lay (TR12; Config.Effects.LeadLeaves), the builder's grey stand-in: a column
-- standing on the floor at `at` (a root's place), narrowing and fading as it rises.
function Effects.LeadLeaves(at: Vector3)
	local look = EffectsConfig.LeadLeaves
	local column = part(HOT, Enum.Material.Neon)
	local floor = at.Y - R6_ROOT_HEIGHT
	run(function(age: number): boolean
		local u = math.clamp(age / math.max(look.Seconds, 0.01), 0, 1)
		local wide = math.max(look.Width * (1 - u), 0.05)
		local high = look.High * (1 - 0.5 * u)
		column.Size = Vector3.new(wide, high, wide)
		column.CFrame = CFrame.new(at.X, floor + high / 2 + look.Rise * easeOut(u), at.Z)
		column.Transparency = u
		return u < 1
	end, function()
		column:Destroy()
	end)
end

-- Home's arrival (TR19), the builder's stand-in until Modulo's look: a flat ring of light on the floor under `at` (a
-- root's place), opening to `width` studs across and fading over `seconds`.
function Effects.Arrive(at: Vector3, width: number, seconds: number, colour: Color3)
	local disc = part(colour, Enum.Material.Neon)
	disc.Shape = Enum.PartType.Cylinder
	local floor = at.Y - R6_ROOT_HEIGHT + 0.1
	run(function(age: number): boolean
		local u = math.clamp(age / math.max(seconds, 0.01), 0, 1)
		local wide = math.max(width * easeOut(u), 0.2)
		disc.Size = Vector3.new(0.1, wide, wide)
		disc.CFrame = CFrame.new(at.X, floor, at.Z) * CFrame.Angles(0, 0, math.pi / 2)
		disc.Transparency = 0.2 + 0.8 * u
		return u < 1
	end, function()
		disc:Destroy()
	end)
end

function Effects.Jolt(add: number)
	trauma = Fight.Trauma(trauma, add)
end

function Effects.Trauma(): number -- for the self-test
	return trauma
end

-- math.noise stays mostly within half of its range: doubled and clamped, it fills -1 to 1.
local function wobble(x: number, y: number, z: number): number
	return math.clamp(math.noise(x, y, z) * 2, -1, 1)
end

RunService:BindToRenderStep("NL_FightShake", Enum.RenderPriority.Camera.Value + 1, function(dt: number)
	if trauma <= 0 then
		return
	end
	local shake = Combat.Shake
	local amount = Fight.ShakeOf(trauma)
	trauma = Fight.TraumaAfter(trauma, dt, shake.Decay)
	shaken += dt
	local t = shaken * shake.Rate
	local studs = shake.Studs * amount
	local angle = math.rad(shake.Degrees) * amount
	local camera = workspace.CurrentCamera
	camera.CFrame = camera.CFrame
		* CFrame.new(wobble(t, SEED, 0.5) * studs, wobble(SEED, t, 1.5) * studs, 0)
		* CFrame.Angles(wobble(t, 2.5, SEED) * angle * 0.5, wobble(3.5, t, SEED) * angle * 0.5, wobble(SEED, 4.5, t) * angle)
end)

-- A passive's shell (Config.Effects.Passives.Shell; Rook's Second Wind): a faint ball round `root` while `holds()` says
-- so, faded in and out. It ends once faded out; the caller starts another when the passive holds again.
function Effects.Shell(root: BasePart, holds: () -> boolean, done: () -> ())
	local look = EffectsConfig.Passives.Shell
	local shell = part(look.Colour, Enum.Material.ForceField)
	shell.Name = "NL_PassiveShell"
	shell.Shape = Enum.PartType.Ball
	shell.Size = Vector3.one * look.Size
	shell.Transparency = 1
	local shown, last = 0, 0
	run(function(age: number): boolean
		local dt = age - last
		last = age
		local on = root.Parent ~= nil and holds()
		local fade = math.max(look.Fade, 1e-3)
		shown = math.clamp(shown + (if on then dt else -dt) / fade, 0, 1)
		shell.Size = Vector3.one * look.Size
		shell.CFrame = root.CFrame
		shell.Transparency = lerp(1, look.Transparency, shown)
		return on or shown > 0
	end, function()
		shell:Destroy()
		done()
	end)
end

-- A passive's flare (Config.Effects.Passives.Flare; Pip's Kindle): a hot ball swelling at `at` and fading, with its light.
function Effects.Flare(at: Attachment)
	local look = EffectsConfig.Passives.Flare
	local ball = part(look.Colour, Enum.Material.Neon)
	ball.Name = "NL_PassiveFlare"
	ball.Shape = Enum.PartType.Ball
	local light = Instance.new("PointLight")
	light.Color = look.Colour
	light.Range = look.Range
	light.Parent = ball
	run(function(age: number): boolean
		if at.Parent == nil then
			return false
		end
		local grow = math.max(look.Grow, 1e-3)
		local swell = easeOut(age / grow)
		local fade = math.clamp((age - grow) / math.max(look.Fade, 1e-3), 0, 1)
		ball.Size = Vector3.one * look.Size * lerp(0.2, 1, swell)
		ball.CFrame = CFrame.new(at.WorldPosition)
		ball.Transparency = fade
		light.Brightness = look.Brightness * (1 - fade)
		return fade < 1
	end, function()
		ball:Destroy()
	end)
end

Effects.HeldEnd = HELD_END

return Effects
