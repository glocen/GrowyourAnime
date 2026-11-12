--!strict
-- Effects (client): the fight's stand-ins in grey, timing and size only (TR2; the looks come with the art sheets).
--   Spark     a landed hit: a burst of light where it lands, larger on a heavy hit. Light only: no wound, nothing left.
--   Haymaker  AR1's art sheet, the block-in's B with the floor's lines (research dropped the wake): the charge square,
--             the punctuation, one bracket thrown along the ground through the target and eaten as it cools, the two
--             lines it scores on the floor. One bar picture for all of it, or grey parts until it's uploaded
--             (Config.Effects.Haymaker; docs/asset-requests.md, AR1, section 5). And the ram's heat on its glow mask,
--             and the strike's sound (Config.Sounds).
--   LanternBurst  Pip's signature, AR4's art sheet: the heat in the cage on his glow mask, the throw with its trail, the
--             flame let out over the target, and the lantern relit over the cooldown as its readout
--             (Config.Effects.LanternBurst; docs/asset-requests.md, AR4, section 8).
--   LanternShots  Pip's combo, a grey block: a streak from the lantern to the target on each shot (Config.Effects.Shot).
--   SpeakerShots  Lyric's combo, the same from her speakers' rings, the ones each shot names.
--   HeldNote  Lyric's signature, AR4's art sheet (Config.Effects.HeldNote; AR4, section 10): the flash in her rings, a
--             crest thrown across the cone on every half-beat (a ribbon over a veil that falls away), and the hit's
--             cells on each Shade it reaches. HealRing: the heal's ring rising round each body it mends.
--   BoxPose   a Shade box's stand-in motion on its action's beats: it leans back, then lunges.
--   ShadeBurst  a Shade falls: AR2's art sheet, the sky lantern. A flame swells in its collar, flares the coat's size on
--             its clip's marker as the body goes, and climbs away with its paper (docs/design.md, "Combat": no gore).
--   Number    a damage number over the target: one counting number for a flurry, one press's hits on one body.
--   Shake     the camera, on the player's own heavy hit or a hard hit taken.
-- Effects driven by an action take its clock on screen, which hitstop pauses; the rest run on Effects.TimeScale, which a
-- capture sets to 0 to hold a frame (.claude/skills/ga-studio-test, "Captures").

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Actions = require(ReplicatedStorage.Shared.Definitions.Actions)
local EffectsConfig = require(ReplicatedStorage.Shared.Config.Effects)
local ShadeBurstArt = require(ReplicatedStorage.Shared.Config.ShadeBurstArt)
local Sounds = require(script.Parent.Sounds)
local UI = script.Parent.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local World = require(UI.World)
local Text = require(UI.Kit.Text)

local Effects = {}
Effects.TimeScale = 1

local LIGHT = Color3.fromRGB(225, 225, 225) -- the stand-ins' grey
local SPARK = Color3.fromRGB(255, 255, 255)
local HOT = Color3.new(1, 1, 1) -- a picture's own colours
local FRAME = 1 / 60 -- the clip's frame, which the art sheets count in
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

local function run(step: (age: number) -> boolean, done: () -> ())
	table.insert(timed, { Age = 0, Step = step, Done = done })
end

RunService.RenderStepped:Connect(function(dt: number)
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
type Face = { Gui: SurfaceGui, Label: ImageLabel }
type Bar = { Part: Part, Faces: { Face } }
type Look = typeof(EffectsConfig.Haymaker)

local function newBar(): Bar
	local p = part(LIGHT)
	p.Transparency = 1
	return { Part = p, Faces = {} }
end

local function hideBar(bar: Bar)
	bar.Part.Transparency = 1
	for _, face in bar.Faces do
		face.Gui.Enabled = false
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
			face.Gui.Enabled = false
		end
		return
	end
	p.Transparency = 1
	p.Size = Vector3.new(length / look.Span, thick / look.Body, PICTURE_DEPTH)
	if #bar.Faces == 0 then
		for _, normal in faces do
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
			label.Parent = gui
			gui.Parent = p
			table.insert(bar.Faces, { Gui = gui, Label = label })
		end
	end
	for _, face in bar.Faces do
		face.Gui.Enabled = true
		local label = face.Label
		if label.Image ~= look.Picture then
			label.Image = look.Picture
		end
		label.ImageRectSize = Vector2.new(look.FrameWidth, look.FrameHeight)
		label.ImageRectOffset = Vector2.new(0, k * look.FrameHeight)
		label.ImageColor3 = tint
	end
end

local UPRIGHT = { Enum.NormalId.Front, Enum.NormalId.Back } -- seen from either side of the line
local ON_FLOOR = { Enum.NormalId.Back } -- seen from above

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
	local pool: { Bar } = {}
	local used = 0
	local line: CFrame? = nil -- on the floor under the knuckles at the strike, facing down the hit's line
	local knuckles: Vector3? = nil
	local aimAt: Vector3? = nil -- the target's centre on the floor at the strike; nil, and the line runs Reach straight on
	local sideOn = 1 -- how side-on the hit's line runs to this client's camera at the strike: 0 at or away from it, 1 across it
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

	-- The line: from under the knuckles at the strike, along the floor, to Past beyond the target (or Reach straight on). The
	-- bracket faces down the hit's line, the attacker's body to the target, which the server pushes the target along: what
	-- was hit is driven out through it (section 8).
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
		aimAt = if aim then Vector3.new(aim.Position.X, floorY, aim.Position.Z) else nil
		if toward.Magnitude < 0.5 then
			local look = r.CFrame.LookVector
			toward = Vector3.new(look.X, 0, look.Z)
		end
		line = CFrame.lookAt(origin, origin + toward.Unit)
		local camera = workspace.CurrentCamera
		if camera then
			local view = camera.CFrame.LookVector
			local flat = Vector3.new(view.X, 0, view.Z)
			if flat.Magnitude > 1e-3 then
				local across = math.clamp(math.abs(flat.Unit:Cross(toward.Unit).Y), 0, 1)
				sideOn = math.asin(across) / (math.pi / 2)
			end
		end
	end

	-- How far down the line the hero is, as the line's share, `f` frames after Shock: it never quite stops.
	local function far(hero: typeof(EffectsConfig.Haymaker.Hero), f: number): number
		return outFast(f / hero.Fly) + math.max(0, f - hero.Fly) * hero.Drift
	end

	-- The frame after Shock the hero passes `share` of the line.
	local function passes(hero: typeof(EffectsConfig.Haymaker.Hero), share: number): number
		if share >= 1 then
			return hero.Fly + (share - 1) / hero.Drift
		end
		return hero.Fly * (1 - (1 - share) ^ (1 / 3))
	end

	-- The bracket's foot point and facing at `share` of the line: it flies from the knuckles to the line's end, facing the
	-- hit's line all the way.
	local function standAt(hero: typeof(EffectsConfig.Haymaker.Hero), path: CFrame, share: number): CFrame
		local ends = if aimAt then aimAt + path.LookVector * hero.Past else path.Position + path.LookVector * hero.Reach
		return path + (ends - path.Position) * share
	end

	local function size(hero: typeof(EffectsConfig.Haymaker.Hero), share: number): (number, number, number)
		return hero.Width + hero.WidthGain * share, hero.Height + hero.HeightGain * share, hero.Bar + hero.BarGain * share
	end

	local running: Running
	running = {
		Step = function(clock: number, _free: number?): boolean
			local look = EffectsConfig.Haymaker
			local hero, floor = look.Hero, look.Floor
			local lastPiece = passes(hero, (floor.Pieces - 1) / floor.Pieces)
			local finish = SHOCK + (math.max(hero.Fly + hero.Leaves, lastPiece + floor.Life) + 1) * FRAME
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
			local past = false -- the squares have had their frames: the hero's turn
			if path and hand and strikeAt then
				local across = CFrame.lookAt(hand, hand + path.LookVector) * CFrame.new(0, 0, -look.Ahead)
				if clock < SHOCK or clock == strikeAt then
					square(take, look, across, look.Strike.Side, look.Strike.Side + look.Strike.Bar, look.Strike.Bar, look.Strike.Frame)
				else
					shockAt = shockAt or clock
					if clock < SHOCK + FRAME or clock == shockAt then
						square(take, look, across, look.Shock.Side, look.Shock.Side + look.Shock.Bar, look.Shock.Bar, look.Shock.Frame)
					else
						past = true
					end
				end
			end
			if path and past then
				local f = (clock - SHOCK) / FRAME
				local lean = math.rad(hero.Lean * sideOn)
				-- The hero: one bracket down the line, boiling while it flies, then eaten as it opens and its feet lift.
				if f > 0 and f <= hero.Fly + hero.Leaves then
					local share = far(hero, f)
					local leaves = math.clamp((f - hero.Fly) / hero.Leaves, 0, 1)
					local w, h, bar = size(hero, share)
					local opens = 1 + hero.Opens * leaves
					w, h = w * opens, h * opens
					local low = h * hero.Lift * leaves * leaves
					local k = if leaves == 0 then frameNow % 2 else math.min(#look.Eaten - 1, 1 + math.floor(leaves * (#look.Eaten - 2) + 0.5))
					local stand = standAt(hero, path, share) * CFrame.Angles(-lean, 0, 0)
					local post = h - low + bar
					for _, sign in { -1, 1 } do
						layBar(take(), look, stand * CFrame.new(sign * w / 2, low + (h - low) / 2, 0) * CFrame.Angles(0, 0, math.pi / 2), post, bar, k, HOT, UPRIGHT)
					end
					layBar(take(), look, stand * CFrame.new(0, h, 0), w + bar, bar, k, HOT, UPRIGHT) -- flush at the corners: a bracket, not a gate
				end
				-- The floor's lines: under the posts' feet, in pieces from the frame the hero passed each, hot, then a scorch.
				local reached = far(hero, f)
				for index = 0, floor.Pieces - 1 do
					local a = index / floor.Pieces
					local age = f - passes(hero, a)
					local b = if age >= 0 then math.min((index + 1) / floor.Pieces, reached) else a
					if b - a < 0.01 or age > floor.Life then
						continue
					end
					local tint = if age < floor.Hot then HOT else look.Scorch
					local k = if age < floor.Eat then 0 else math.floor(age - floor.Eat)
					for _, sign in { -1, 1 } do
						local wa, wb = (size(hero, a)), (size(hero, b))
						local from3 = (standAt(hero, path, a) * CFrame.new(sign * wa / 2, floor.Over, 0)).Position
						local to3 = (standAt(hero, path, b) * CFrame.new(sign * wb / 2, floor.Over, 0)).Position
						local along = to3 - from3
						if along.Magnitude < 1e-3 then
							continue
						end
						local x = along.Unit
						local up = Vector3.yAxis
						local laid = CFrame.fromMatrix((from3 + to3) / 2, x, up:Cross(x), up)
						layBar(take(), look, laid, along.Magnitude + floor.Overlap * look.Span, floor.Bar, k, tint, ON_FLOOR)
					end
				end
			end
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
	if lantern then
		heatGui, heatLabel = billboard(lantern, EffectsConfig.LanternBurst.Picture)
	end
	-- The burst, on a part of its own that stays where the lantern stopped.
	local stand = part(LIGHT)
	stand.Transparency = 1
	stand.Size = Vector3.one * 0.2
	local burstGui, burstLabel = billboard(stand, EffectsConfig.LanternBurst.Picture)
	local burstAt: Vector3? = nil -- the burst's foot, on the ground under the lantern at the Burst
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
	beam.Attachment0, beam.Attachment1 = tail, head -- the picture's U runs tail to lantern
	beam.FaceCamera = true
	beam.Texture = EffectsConfig.LanternBurst.TrailPicture
	beam.TextureMode = Enum.TextureMode.Stretch
	beam.TextureLength = 1
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
			if heatGui and heatLabel then
				local heat = look.Heat
				if clock >= HEAT and clock < BURST then
					local size = keyed(heat.Keys, clock / FRAME)
					heatGui.Size = UDim2.new(size, 0, size, 0)
					heatGui.StudsOffsetWorldSpace = Vector3.new(0, (0.5 - heat.Belly) * size, 0)
					heatGui.Brightness = heat.Brightness
					local offset, extent = cell(look.Sheet, heat.First + math.floor((clock - HEAT) / FRAME / heat.PerCell + 1e-4) % 4)
					heatLabel.ImageRectOffset, heatLabel.ImageRectSize = offset, extent
					heatGui.Enabled = true
				else
					heatGui.Enabled = false
				end
			end
			-- Where the lantern flies, by frame, and where it stops.
			if lantern and clock >= SEND and frame <= burstFrame and flown[frame] == nil then
				flown[frame] = lantern.WorldPosition
			end
			if burstAt == nil and clock >= BURST and lantern and root then
				local at = lantern.WorldPosition
				burstAt = Vector3.new(at.X, root.Position.Y - R6_ROOT_HEIGHT, at.Z)
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
			-- The burst.
			local index = if burstAt and after >= 0 then burstCell(look.Burst, after) else nil
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
				burstGui.Enabled = true
			else
				burstGui.Enabled = false
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
			if surface and surface.Parent then
				relight(surface, COOLDOWN - now) -- dark until here, full when it's ready
			end
		end,
	} :: Running
	return running
end

-- A grey streak from `from` to `to` (Config.Effects.Shot), over its Life; a heavy shot's is wider.
local function streak(from: Vector3, to: Vector3, heavy: boolean)
	local length = (to - from).Magnitude
	if length < 0.1 then
		return
	end
	local bar = part(LIGHT, Enum.Material.Neon)
	local placed = CFrame.lookAt((from + to) / 2, to)
	run(function(age: number): boolean
		local shot = EffectsConfig.Shot
		local t = age / math.max(FRAME, shot.Life)
		if t >= 1 then
			return false
		end
		local width = (if heavy then shot.Heavy else shot.Width) * (1 - t)
		bar.Size = Vector3.new(width, width, length)
		bar.CFrame = placed
		bar.Transparency = t
		return true
	end, function()
		bar:Destroy()
	end)
end

-- A streak to the target on each beat that hits, from each of the points `from` gives for that beat.
local function shots(beats: { [string]: number }, target: () -> BasePart?, action: Actions.Action, from: (beat: string) -> { Attachment }): Running
	local fired: { [string]: boolean } = {}
	return {
		Step = function(clock: number, _free: number?): boolean
			for name, at in beats do
				local hit = action.Hits[name]
				if hit and not fired[name] and clock >= at then
					fired[name] = true
					local aim = target()
					if aim then
						for _, point in from(name) do
							streak(point.WorldPosition, aim.Position, hit.Heavy)
						end
					end
				end
			end
			return clock < action.Length
		end,
		Destroy = function() end,
	}
end

-- Pip's shots (PipCombo), a grey block: a streak from the lantern to the target on each beat that hits.
function Effects.LanternShots(beats: { [string]: number }, attacker: Model, target: () -> BasePart?, action: Actions.Action): Running
	local lamp = attacker:FindFirstChild("Pip_Lamp")
	local lantern = if lamp then lamp:FindFirstChild("Lantern") :: Attachment? else nil
	return shots(beats, target, action, function(_beat: string): { Attachment }
		return if lantern then { lantern } else {}
	end)
end

-- Lyric's speakers' rings, by name (tools/studio/Models/Lyric.luau: RingR and RingL).
local function rings(attacker: Model): { [string]: Attachment }
	local found: { [string]: Attachment } = {}
	for _, point in attacker:GetDescendants() do
		if point:IsA("Attachment") and (point.Name == "RingR" or point.Name == "RingL") then
			found[point.Name] = point
		end
	end
	return found
end

-- Lyric's shots (LyricCombo), a grey block: a streak from a speaker's ring to the target on each shot, from the rings
-- Config.Effects.Shot.Speakers names for it.
function Effects.SpeakerShots(beats: { [string]: number }, attacker: Model, target: () -> BasePart?, action: Actions.Action): Running
	local found = rings(attacker)
	return shots(beats, target, action, function(beat: string): { Attachment }
		local out = {}
		for _, name in EffectsConfig.Shot.Speakers[beat] or {} do
			local point = found[name]
			if point then
				table.insert(out, point)
			end
		end
		return out
	end)
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
	run(function(age: number): boolean
		local index = math.floor(age / (hit.Frames * FRAME))
		if index > 3 or gui.Parent == nil then
			return false
		end
		label.ImageRectOffset = Vector2.new(index * look.Cell, 0)
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
	local flashes: { { Ring: Attachment, Gui: BillboardGui } } = {}
	for _, ring in rings(attacker) do
		local gui, label = billboard(ring, look.Touch)
		label.ImageRectOffset = Vector2.new(look.Cell, look.Cell)
		label.ImageRectSize = Vector2.new(look.Cell, look.Cell)
		table.insert(flashes, { Ring = ring, Gui = gui })
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
				flash.Gui.Enabled = size ~= nil
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
function Effects.ShadeBurst(model: Model, down: AnimationTrack?, collar: Attachment?)
	local look = EffectsConfig.ShadeBurst
	local scale = model:GetScale()
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
	local burstTime = ShadeBurstArt.Burst * FRAME
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
				if p:IsA("BasePart") then
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
		local frame = if burstAge then ShadeBurstArt.Burst + math.floor((age - (burstAge :: number)) / FRAME + 0.5) else math.floor((down :: AnimationTrack).TimePosition / FRAME + 1e-6)
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

-- A number over a body: one for each `key` on it, so a flurry (one press's hits) is one counting number and never a wall
-- (docs/ui.md, "Damage numbers"; Config.Combat.Numbers). The first rises over `root`: `prefix` and `amount` in `color`,
-- larger when `big`. Each one after it, while it shows, adds its amount: the number counts up to the new total over
-- Count seconds, swelling Pop times and settling, and its fade starts over. A big one after makes it big from there, in
-- its colour. With `amount` nil it's the word `prefix` (Miss), popped again on a repeat. Drawn on the World layer
-- (UI.World), so a capture shows it; its size is authored at the phone's (UI.Theme.Author) and scales with the layer.
type Numbers = { Rise: number, Seconds: number, Size: number, Count: number, Pop: number }
type Counting = {
	Age: number,
	Total: number,
	From: number, -- what it showed when the last amount came
	Changed: number, -- its age then, or -inf before any
	Label: TextLabel,
	Scale: UIScale,
	Grown: number, -- 1, or the big size's share once a big one came after it
	Big: boolean,
	Prefix: string,
	Word: boolean,
}
local counting: { [BasePart]: { [string]: Counting } } = {}
Effects.Counting = counting -- for the self-test

local BIG = 1.35 -- a critical's or a heavy hit's number, against a plain one

local function counted(c: Counting, numbers: Numbers): number
	local u = if numbers.Count > 0 then easeOut((c.Age - c.Changed) / numbers.Count) else 1
	return c.From + (c.Total - c.From) * u
end

function Effects.Number(root: BasePart, key: string, amount: number?, prefix: string, color: Color3, big: boolean, numbers: Numbers)
	local onBody = counting[root] or {}
	counting[root] = onBody
	local live = onBody[key]
	if live then
		if amount then
			live.From = counted(live, numbers)
			live.Total += amount
		end
		live.Changed = live.Age
		if big and not live.Big then
			live.Big, live.Grown = true, BIG
			live.Label.TextColor3 = color
		end
		return
	end
	local spread = (math.random() - 0.5) * 1.2
	local rise = 0
	local size = if big then numbers.Size * BIG else numbers.Size
	local plate = World.Plate("Number", Vector2.new(size * 5, size * 1.6), function(): Vector3?
		return if root.Parent then root.Position + Vector3.new(spread, 3 + rise, 0) else nil
	end)
	local label = Text.new({ Name = "Number", Size = size, Font = Theme.Font.Number, Colour = color, Align = Enum.TextXAlignment.Center, Parent = plate })
	label.TextStrokeTransparency = 0.2
	local scale = Instance.new("UIScale")
	scale.Parent = plate
	local c: Counting = {
		Age = 0,
		Total = amount or 0,
		From = amount or 0,
		Changed = -math.huge,
		Label = label,
		Scale = scale,
		Grown = 1,
		Big = big,
		Prefix = prefix,
		Word = amount == nil,
	}
	onBody[key] = c
	local function lay(age: number): boolean
		c.Age = age
		local since = age - (if c.Changed > -math.huge then c.Changed else 0) -- its fade runs from the last amount
		local t = since / numbers.Seconds
		if t >= 1 then
			return false
		end
		rise = numbers.Rise * easeOut(age / numbers.Seconds)
		label.Text = if c.Word then c.Prefix else `{c.Prefix}{math.floor(counted(c, numbers) + 0.5)}`
		local pop = if numbers.Count > 0 then 1 - easeOut((age - c.Changed) / numbers.Count) else 0
		scale.Scale = c.Grown * (1 + (numbers.Pop - 1) * pop)
		label.TextTransparency = math.clamp((t - 0.6) / 0.4, 0, 1)
		label.TextStrokeTransparency = math.max(0.2, label.TextTransparency)
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

-- A level gained (Config.Effects.LevelUp): the reward's two beats at once, a ring of light spreading from the feet, eased
-- out so it bursts and settles, and the new level rising over the lead, held long enough to read.
function Effects.LevelUp(root: BasePart, level: number)
	local look = EffectsConfig.LevelUp
	local ring = part(Theme.Colour.Xp, Enum.Material.Neon)
	ring.Shape = Enum.PartType.Cylinder
	local feet = root.Position - Vector3.new(0, R6_ROOT_HEIGHT - 0.1, 0)
	local size = look.Size
	local rise = 0
	local plate = World.Plate("LevelUp", Vector2.new(size * 7, size * 1.6), function(): Vector3?
		return if root.Parent then root.Position + Vector3.new(0, 3.5 + rise, 0) else nil
	end)
	local label = Text.new({ Name = "Level", Size = size, Font = Theme.Font.Number, Colour = Theme.Colour.Xp, Align = Enum.TextXAlignment.Center, Parent = plate })
	label.TextStrokeTransparency = 0.2
	label.Text = `Level {level}`
	run(function(age: number): boolean
		if age >= math.max(look.Seconds, look.Ring.Seconds) then
			return false
		end
		local r = math.clamp(age / look.Ring.Seconds, 0, 1)
		local across = lerp(look.Ring.From, look.Ring.To, easeOut(r))
		ring.Size = Vector3.new(look.Ring.Thick, across, across)
		ring.CFrame = CFrame.new(if root.Parent then root.Position - Vector3.new(0, R6_ROOT_HEIGHT - 0.1, 0) else feet) * CFrame.Angles(0, 0, math.pi / 2)
		ring.Transparency = if r >= 1 then 1 else r * r
		local t = age / look.Seconds
		rise = look.Rise * easeOut(t)
		label.TextTransparency = math.clamp((t - 0.7) / 0.3, 0, 1)
		label.TextStrokeTransparency = math.max(0.2, label.TextTransparency)
		return true
	end, function()
		ring:Destroy()
		World.Remove(plate)
	end)
end

-- A shard won (Config.Effects.ShardLeap): it leaves the fallen Shade in an arc, eased in and out so it lifts off and
-- settles, spinning, and lands on the avatar in a small flash. `to` is read every frame, so it follows a walking avatar.
function Effects.ShardLeap(from: Vector3?, to: () -> Vector3?)
	local look = EffectsConfig.ShardLeap
	local function flash(at: Vector3)
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
		if start then
			flash(start)
		end
		return
	end
	local shard = part(Theme.Colour.Ready, Enum.Material.Neon)
	shard.Size = Vector3.new(look.Size * 0.6, look.Size, look.Size * 0.6)
	local last: Vector3 = start
	run(function(age: number): boolean
		local t = math.clamp(age / look.Seconds, 0, 1)
		last = to() or last
		local eased = t * t * (3 - 2 * t)
		local at = from:Lerp(last, eased) + Vector3.new(0, look.Height * 4 * t * (1 - t), 0)
		shard.CFrame = CFrame.new(at) * CFrame.Angles(0, age * look.Spin, math.rad(45))
		return t < 1
	end, function()
		shard:Destroy()
		flash(last)
	end)
end

-- The camera's shake: each one adds its own, and fades on its own.
type Shaking = { Magnitude: number, Roughness: number, Fade: number, Age: number, Seed: number }
local shakes: { Shaking } = {}

function Effects.Shake(params: { Magnitude: number, Roughness: number, Fade: number })
	table.insert(shakes, { Magnitude = params.Magnitude, Roughness = params.Roughness, Fade = params.Fade, Age = 0, Seed = math.random() * 100 })
end

RunService:BindToRenderStep("NL_FightShake", Enum.RenderPriority.Camera.Value + 1, function(dt: number)
	if #shakes == 0 then
		return
	end
	local offset = Vector3.zero
	for index = #shakes, 1, -1 do
		local s = shakes[index]
		s.Age += dt
		local left = 1 - s.Age / s.Fade
		if left <= 0 then
			table.remove(shakes, index)
			continue
		end
		local t = s.Age * s.Roughness
		offset += Vector3.new(math.noise(t, s.Seed), math.noise(s.Seed, t), 0) * s.Magnitude * left * 0.25
	end
	local camera = workspace.CurrentCamera
	camera.CFrame = camera.CFrame * CFrame.new(offset)
end)

return Effects
