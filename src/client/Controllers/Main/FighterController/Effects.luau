--!strict
-- Effects (client): the fight's stand-ins in grey, timing and size only (TR2; the looks come with the art sheets).
--   Spark     a landed hit: a burst of light where it lands, larger on a heavy hit. Light only: no wound, nothing left.
--   Haymaker  AR1's art sheet, the block-in's B with the floor's lines (research dropped the wake): the charge square,
--             the punctuation, one bracket thrown along the ground through the target and eaten as it cools, the two
--             lines it scores on the floor. One bar picture for all of it, or grey parts until it's uploaded
--             (Config.Effects.Haymaker; docs/asset-requests.md, AR1, section 5). And the ram's heat on its glow mask,
--             and the strike's sound (Config.Sounds).
--   BoxPose   a Shade box's stand-in motion on its action's beats: it leans back, then lunges.
--   Burst     a Shade falls: it bursts into light and paper (docs/design.md, "Combat": no gore), on its clip's marker.
--   Number    a damage number over the target.
--   Shake     the camera, on the player's own heavy hit or a hard hit taken.
-- Effects driven by an action take its clock on screen, which hitstop pauses; the rest run on Effects.TimeScale, which a
-- capture sets to 0 to hold a frame (.claude/skills/ga-studio-test, "Captures").

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EffectsConfig = require(ReplicatedStorage.Shared.Config.Effects)
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
export type Running = { Step: (clock: number) -> boolean, Destroy: () -> () }

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
		Step = function(clock: number): boolean
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
	}
	return running
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
function Effects.Burst(model: Model, at: CFrame?)
	local pivot = at or model:GetPivot()
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.LocalTransparencyModifier = 1
		end
	end
	local flash = part(SPARK, Enum.Material.Neon)
	flash.Shape = Enum.PartType.Ball
	local paper: { { Part: Part, Velocity: Vector3, Spin: Vector3 } } = {}
	for _ = 1, 12 do
		local p = part(LIGHT)
		p.Size = Vector3.new(0.55, 0.55, 0.05)
		p.CFrame = pivot * CFrame.new((math.random() - 0.5) * 2, (math.random() - 0.3) * 3, (math.random() - 0.5) * 1)
		local out = Vector3.new(math.random() - 0.5, 0.6 + math.random(), math.random() - 0.5).Unit * (8 + math.random() * 8)
		table.insert(paper, { Part = p, Velocity = out, Spin = Vector3.new(math.random() * 9, math.random() * 9, math.random() * 9) })
	end
	local last = 0
	run(function(age: number): boolean
		local dt = age - last
		last = age
		if age >= 0.9 then
			return false
		end
		flash.Size = Vector3.one * lerp(2, 7, easeOut(age / 0.25))
		flash.CFrame = pivot
		flash.Transparency = math.clamp(age / 0.25, 0, 1)
		for _, sheet in paper do
			sheet.Velocity += Vector3.new(0, -14 * dt, 0) -- paper drifts down slowly
			sheet.Velocity *= (1 - math.min(1, 2.2 * dt))
			sheet.Part.CFrame = (sheet.Part.CFrame + sheet.Velocity * dt) * CFrame.Angles(sheet.Spin.X * dt, sheet.Spin.Y * dt, sheet.Spin.Z * dt)
			sheet.Part.Transparency = math.clamp((age - 0.4) / 0.5, 0, 1)
		end
		return true
	end, function()
		flash:Destroy()
		for _, sheet in paper do
			sheet.Part:Destroy()
		end
	end)
end

-- A number rising over `root`: `text` in `color`, larger when `big`. Drawn on the World layer (UI.World), so a capture
-- shows it; its size is authored at the phone's (UI.Theme.Author) and scales with the layer.
function Effects.Number(root: BasePart, text: string, color: Color3, big: boolean, numbers: { Rise: number, Seconds: number, Size: number })
	local spread = (math.random() - 0.5) * 1.2
	local rise = 0
	local size = if big then numbers.Size * 1.35 else numbers.Size
	local plate = World.Plate("Number", Vector2.new(size * 5, size * 1.6), function(): Vector3?
		return if root.Parent then root.Position + Vector3.new(spread, 3 + rise, 0) else nil
	end)
	local label = Text.new({ Name = "Number", Size = size, Font = Theme.Font.Number, Colour = color, Align = Enum.TextXAlignment.Center, Parent = plate })
	label.TextStrokeTransparency = 0.2
	label.Text = text
	run(function(age: number): boolean
		local t = age / numbers.Seconds
		if t >= 1 then
			return false
		end
		rise = numbers.Rise * easeOut(t)
		label.TextTransparency = math.clamp((t - 0.6) / 0.4, 0, 1)
		label.TextStrokeTransparency = math.max(0.2, label.TextTransparency)
		return true
	end, function()
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
