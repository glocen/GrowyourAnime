--!strict
-- Reveal (pure): the reveal's ceremony as numbers, from a rarity's plan and the seconds since the tap (AR3, section 5;
-- docs/test-requests.md, TR4). The rules are Modulo's, written out in build/handoff/Reveal/parts/reveal.json and laid by
-- tools/blender/reveal_art.py's engine stage; the numbers they read are Config.RevealArt, what's tuned by playing
-- Config.Reveal. The client's stage (src/client/UI/Reveal) lays what Reveal.At says and decides nothing. Points are on
-- the 844 by 390 screen, x right, y down; t is seconds from the tap, tau seconds from the split, the clip where his
-- Reveal clip is (Rook's timing: another Voidkin's clip is shifted onto it, Reveal.Figure).

local Shared = game:GetService("ReplicatedStorage").Shared
local Art = require(Shared.Config.RevealArt)
local RevealConfig = require(Shared.Config.Reveal)

local W = Art.Screen.X
local WHITE = Color3.new(1, 1, 1)
local CX = 600 -- where he and the window stand once the name is down: he steps right as he opens up
local STEP = { 0.4, 0.3 } -- he steps at this point of his clip, over this long
local RUNG = { Swell = 0.05, Tick = 0.08, Light = 0.8 } -- a rung's answer: the shard swells, ticks aside, burns brighter
local GONE = { 0.18, 0.25 } -- the pieces fade from this long after the split, over this long
local SHARD_FOR = 0.7 -- the shard's ViewportFrame stays this long past the split
local BEAMS = "beams"

local Reveal = {}

export type Rarity = Art.Rarity

-- The curves ------------------------------------------------------------------------------------------------------------

function Reveal.Smooth(u: number): number
	local c = math.clamp(u, 0, 1)
	return c * c * (3 - 2 * c)
end

-- Past 1 and back: the window opening.
function Reveal.Back(u: number): number
	local v = math.clamp(u, 0, 1) - 1
	return 1 + v * v * (2.70158 * v + 1.70158)
end

-- A seam opening: past its width at once, then settled.
function Reveal.Snap(a: number): number
	if a < 0 then
		return 0
	end
	return if a < 0.03 then 1.35 * a / 0.03 else 1 + 0.35 * math.exp(-(a - 0.03) / 0.05)
end

-- A rung's answer `a` seconds on: up in about 0.025 s, gone by about 0.25; 1 at its height.
function Reveal.Bump(a: number): number
	if a < 0 then
		return 0
	end
	return math.exp(-a / 0.06) * (1 - math.exp(-a / 0.015)) / 0.5364
end

-- How far down him his colours have run, 0 to 1: quick off the strike, easing down his legs.
function Reveal.Run(u: number): number
	return 1 - (1 - math.clamp(u, 0, 1)) ^ 1.4
end

-- The name's size against its own, `u` seconds from landing: 1.7 times in, down in three frames, under its size on the
-- frame it lands, a small rebound, still. Nil before it shows.
function Reveal.Slam(u: number): number?
	if u < -0.05 then
		return nil
	end
	if u < 0 then
		return 0.93 + 0.77 * (-u / 0.05) ^ 1.6
	end
	return 1 - 0.07 * math.exp(-u / 0.03) * math.cos(u / 0.05 * math.pi)
end

-- Points the screen sits below its rest as the name lands: down at once, a rebound, still in about 0.2 s.
function Reveal.Kick(u: number, shake: number): number
	if u < 0 then
		return 0
	end
	return shake * math.exp(-u / 0.05) * math.cos(u / 0.09 * 2 * math.pi)
end

-- The light ------------------------------------------------------------------------------------------------------------

-- The light's colour and level: the climb's steps mixed in as they come, the breath drawing it down, the rarity's own
-- from the split.
function Reveal.Light(r: Rarity, t: number): (Color3, number)
	if t >= r.Times.Split then
		return r.Light.Colour, r.Light.Level
	end
	local colour, level = Art.Shard.Colour, 0
	for _, s in r.Steps do
		if t >= s.When then
			local w = Reveal.Smooth((t - s.When) / 0.06)
			colour, level = colour:Lerp(s.Colour, w), level * (1 - w) + s.Level * w
		end
	end
	local breath = r.Breath
	if breath and t >= breath[1] then
		level *= 1 - 0.8 * Reveal.Smooth((t - breath[1]) / (breath[2] - breath[1]) * 1.6)
	end
	return colour, level
end

-- How far the rungs have widened the seams: 1 before any.
function Reveal.Widen(r: Rarity, t: number): number
	local widen = 1
	for _, s in r.Steps do
		if t >= s.When then
			widen = math.max(widen, 1 + (s.Wide - 1) * Reveal.Smooth((t - s.When) / 0.08))
		end
	end
	return widen
end

-- How much brighter the seams burn on a rung: 1, up to 1.8 just after a new colour.
function Reveal.Push(r: Rarity, t: number): number
	local top = 0
	for i = 2, #r.Steps do
		local s = r.Steps[i]
		top = math.max(top, Reveal.Bump(t - s.When) * (0.6 + 0.4 * s.Level))
	end
	return 1 + RUNG.Light * top
end

-- The shard ------------------------------------------------------------------------------------------------------------

export type Pose = {
	Gaps: { number }, -- seams A to D open, in the shard's units
	Fly: number, -- how far the pieces have flown
	Spin: number,
	At: Vector2, -- the root's sway: x along its X, y along its up
	Scale: Vector2, -- across, up
	Core: number, -- the core's scale
	Cover: number, -- the pieces' fade
}

function Reveal.Pose(r: Rarity, t: number): Pose
	local split = r.Times.Split
	local widen = Reveal.Widen(r, t)
	local gaps = {}
	for i, crack in r.Cracks do
		gaps[i] = 0.045 * Reveal.Snap(t - crack) * widen
	end
	local _, level = Reveal.Light(r, t)
	local shake = if t < 0 then 0 else 0.006 + 0.022 * level * widen / 2
	local ax, az = math.sin(t * 173) * shake, 0.03 * math.sin(t * 3.1) + math.sin(t * 211 + 1) * shake
	local tap = if t >= 0 then math.exp(-t / 0.035) else 0
	local sx, sz = 1 + 0.07 * tap, 1 - 0.07 * tap
	local rise = if #r.Steps > 1 then 0.25 * Reveal.Smooth((t - 0.4) / 0.6) else 0
	local swell = 1 + 0.05 * Reveal.Smooth((t - (split - 0.15)) / 0.15)
	local breath = r.Breath
	if breath then
		local b0, b1 = breath[1], breath[2]
		swell = 1 + 0.06 * Reveal.Smooth((t - 0.4) / 0.6) - 0.16 * Reveal.Smooth((t - b0) / (b1 - b0) * 1.4)
		if t >= b0 then
			ax, az = ax * 0.2, az * 0.2 + 0.03
		end
	end
	az += rise
	sx, sz = sx * swell, sz * swell
	for i = 2, #r.Steps do -- each rung answered: a swell, and a tick aside that settles, side to side
		local s = r.Steps[i]
		local age, amp = t - s.When, 0.6 + 0.4 * s.Level
		if age >= 0 and age < 0.3 then
			local grow = 1 + RUNG.Swell * amp * Reveal.Bump(age)
			local jolt = RUNG.Tick * amp * math.exp(-age / 0.025) * math.cos(age / 0.05 * 2 * math.pi)
			sx, sz = sx * grow, sz * grow
			ax += (if i % 2 == 0 then 1 else -1) * jolt
			az += 0.35 * jolt
		end
	end
	local tau = t - split
	local fly = if tau > 0 then r.Reach * (1 - math.exp(-tau / 0.13)) else 0
	return {
		Gaps = gaps,
		Fly = fly,
		Spin = math.max(0, tau) * 5 + fly * 0.22,
		At = Vector2.new(ax, az),
		Scale = Vector2.new(sx, sz),
		Core = if tau <= 0 then 1 else math.max(0, 1 - tau / 0.09),
		Cover = 1 - Reveal.Smooth((tau - GONE[1]) / GONE[2]),
	}
end

-- The squash across against up, which the ViewportFrame can't draw (it scales evenly by its height): the pieces carry
-- it, on X and Z of the root. Exact while they haven't turned, which is all the while it isn't 1.
function Reveal.Squash(pose: Pose): Vector3
	local q = pose.Scale.X / pose.Scale.Y
	return Vector3.new(q, 1, q)
end

-- Every piece's and bud's CFrame from the root, and the core's (scaled by pose.Core about the root): reveal.json, "pose",
-- "piece". A bud rides its host. The ViewportFrame's own size carries the root's even scale.
function Reveal.Pieces(pose: Pose): { [string]: CFrame }
	local shard = Art.Shard
	local squash = Reveal.Squash(pose)
	local placed: { [string]: CFrame } = {}
	for name, p in shard.Pieces do
		local order, side, away, reach = p.Order, p.SideA, p.Away, p.Reach
		if order and side and away and reach then
			local move = shard.ANormal * (side * pose.Gaps[1] / 2) + away * (pose.Fly * reach)
			local slides = p.Slides
			if slides then
				move += slides.Along * (slides.Way * pose.Gaps[slides.Seam])
			end
			local spin = pose.Spin
			placed[name] = CFrame.new(move)
				* CFrame.fromAxisAngle(Vector3.yAxis, (2 - order) * spin * 0.3)
				* CFrame.fromAxisAngle(Vector3.zAxis, -(order - 2) * spin * 0.8)
				* CFrame.fromAxisAngle(Vector3.xAxis, (0.5 + order) * spin * 0.6)
		end
	end
	local out: { [string]: CFrame } = {}
	for name, p in shard.Pieces do
		local base = placed[name] or (if p.Host then placed[p.Host] else nil)
		local cf = if base then base * CFrame.new(p.Centre) else CFrame.new(p.Centre * pose.Core) -- the core
		out[name] = CFrame.new(cf.Position * squash) * cf.Rotation
	end
	return out
end

-- The core's colour: dark, mixed toward the light run hot as the light climbs.
function Reveal.CoreColour(colour: Color3, level: number): Color3
	local hot = colour:Lerp(WHITE, 0.55 + 0.45 * level)
	return Art.Figure.Dark:Lerp(hot, math.min(1, level + 0.35))
end

-- The leak -------------------------------------------------------------------------------------------------------------

export type Pick = { Set: number, Share: number } -- a leak set (0 to 8, as the cells are named) and how much of it

local WIDTHS: { number } = {} -- the rung sets' widths, sets 3 to 8
for j = 4, #Art.Leak.Sets do
	table.insert(WIDTHS, Art.Leak.Sets[j].Width)
end

-- The upper set's share as two sets cross: one laid over the other dims where both are bright, so the upper comes in
-- sooner.
function Reveal.Blend(f: number): number
	return f / (1 - 0.6 * (1 - f))
end

-- Which of the sets drawn at `widths` a seam opened g times shows, and how much of each (0-based).
function Reveal.Shares(g: number, widths: { number }): { Pick }
	if g <= widths[1] then
		return { { Set = 0, Share = math.max(0, g / widths[1]) } }
	end
	for i = 1, #widths - 1 do
		if g <= widths[i + 1] then
			local f = (g - widths[i]) / (widths[i + 1] - widths[i])
			return { { Set = i - 1, Share = 1 - f }, { Set = i, Share = f } }
		end
	end
	return { { Set = #widths - 1, Share = 1 } }
end

-- Which leak sets show, how much of each, and how much stronger than its own width the light runs: a seam snaps open
-- past its width, and a rung widens the seams while they still crack. The lower set is laid first.
function Reveal.LeakPick(r: Rarity, t: number): ({ Pick }, number)
	local snaps, n = {}, 0
	for i, crack in r.Cracks do
		snaps[i] = Reveal.Snap(t - crack)
		if t >= crack then
			n += 1
		end
	end
	if n == 0 then
		return {}, 0
	end
	local sum = 0
	for i = 1, n do
		sum += snaps[i]
	end
	local over = math.max(1, sum / n)
	local widen = Reveal.Widen(r, t)
	if n < 4 or snaps[4] < 1 then
		local f = math.min(1, snaps[n])
		if n > 1 then
			return { { Set = n - 2, Share = 1 - f }, { Set = n - 1, Share = Reveal.Blend(f) } }, over * widen
		end
		return { { Set = 0, Share = f } }, over * widen
	end
	local picked = Reveal.Shares(widen, WIDTHS)
	if #picked == 2 then
		picked[2].Share = Reveal.Blend(picked[2].Share)
	end
	for _, p in picked do
		p.Set += 3
	end
	return picked, over
end

-- A leak cell's alpha at a drive: a scale turns it down below it, a ramp brings a boost in between its ends, a curve is
-- straight between its points and held past its ends.
function Reveal.LeakAlpha(cell: Art.Cell, drive: number): number
	local curve, ramp = cell.Curve, cell.Ramp
	if curve then
		if drive <= curve[1][1] then
			return curve[1][2]
		end
		for i = 2, #curve do
			local a, b = curve[i - 1], curve[i]
			if drive <= b[1] then
				local span = b[1] - a[1]
				return a[2] + (b[2] - a[2]) * (if span > 0 then (drive - a[1]) / span else 1)
			end
		end
		return curve[#curve][2]
	end
	if ramp then
		return math.clamp((drive - ramp[1]) / (ramp[2] - ramp[1]), 0, 1)
	end
	return math.min(1, drive / (cell.Scale or 1))
end

export type Lay = { Name: string, Alpha: number, White: boolean } -- a leak cell, white or tinted the light

-- The leak's cells in the order they're laid: each kind, each picked set's cell and then its Boost. A cell missing from
-- the atlas held nothing.
local KINDS: { { any } } = {
	{ "wide", "a", false },
	{ "piecesHot", "a", true },
	{ BEAMS, "b", false },
	{ "tight", "c", false },
	{ "hot", "c", true },
}
function Reveal.Leak(r: Rarity, t: number, level: number, core: number): { Lay }
	local out: { Lay } = {}
	if level <= 0 or core <= 0 then
		return out
	end
	local picked, over = Reveal.LeakPick(r, t)
	local burn = Reveal.Push(r, t) * over
	local m = math.min(1, level + 0.35)
	local a = m * level * burn * core
	local drives = {
		a = a,
		b = if #r.Steps > 1 and t > r.Steps[2].When then a else 0,
		c = m * burn * core,
	}
	for _, kind in KINDS do
		local drive = drives[kind[2]]
		if kind[1] ~= BEAMS or drive > 0 then
			for _, p in picked do
				for _, name in { `{kind[1]}{p.Set}`, `{kind[1]}{p.Set}Boost` } do
					local cell = Art.Leak.Cells[name]
					if cell then
						table.insert(out, { Name = name, Alpha = Reveal.LeakAlpha(cell, drive) * p.Share, White = kind[3] })
					end
				end
			end
		end
	end
	return out
end

-- A strength over the figure's tile, top to bottom, by distance from a row: f(d) at each of `ds` (points, 0 and up)
-- either side of the row, and at the tile's ends, straight between. Keys as {at 0 to 1, value}, in order; a mark past
-- either end is dropped, the ends standing for it (the colours' run and its hot line, UI/Reveal/Figure).
function Reveal.Profile(row: number, height: number, f: (d: number) -> number, ds: { number }): { { number } }
	local marks: { { number } } = { { 0, f(row) }, { 1, f(height - row) } }
	for _, d in ds do
		if d >= 0 then
			table.insert(marks, { (row - d) / height, f(d) })
			table.insert(marks, { (row + d) / height, f(d) })
		end
	end
	table.sort(marks, function(a: { number }, b: { number }): boolean
		return a[1] < b[1]
	end)
	local keys: { { number } } = {}
	local last = -1
	for _, m in marks do
		local at = m[1]
		if at >= 0 and at <= 1 and at > last + 1e-4 and (at == 0 or at == 1 or (at > 1e-4 and at < 1 - 1e-4)) then
			table.insert(keys, { at, math.clamp(m[2], 0, 1) })
			last = at
		end
	end
	return keys
end

-- Rings, the name, the skip -------------------------------------------------------------------------------------------

-- A ring of radius R and width w: the rings cell whose width over radius is nearest (in ratio), and its size across.
function Reveal.Ring(radius: number, width: number): (number, number)
	local want, best, gap = width / radius, 1, math.huge
	for i, cell in Art.Rings do
		local d = math.abs(math.log(want / cell.Ratio))
		if d < gap then
			best, gap = i, d
		end
	end
	return best, radius / Art.Rings[best].Radius
end

-- The name's text size: 58 times the rarity's scale, times the game's face over the art's (Config.Reveal.NameFace),
-- smaller if it would land wider than Widest. Never cut. `width` is the name's width at 58 in the game's face.
function Reveal.NameSize(r: Rarity, width: number): number
	local face = RevealConfig.NameFace
	local size = Art.Name.Size * r.NameScale * face
	local wide = width * r.NameScale * face
	return if wide > Art.Name.Widest then size * Art.Name.Widest / wide else size
end

-- The skip opens a second in, every rarity.
function Reveal.SkipOpen(t: number): boolean
	return t >= RevealConfig.Skip
end

-- Where his own Reveal clip is at a point of Rook's: shifted so his strike marker lands on Rook's Knock.
function Reveal.Figure(clip: number, strike: number): number
	return clip + strike - Art.Figure.Knock
end

-- Where the window and he stand.
function Reveal.Cx(r: Rarity, t: number): number
	local clip = t - r.Times.Split + r.Offset
	return W / 2 + (CX - W / 2) * Reveal.Smooth((clip - STEP[1]) / STEP[2])
end

-- A frame ---------------------------------------------------------------------------------------------------------------

export type Ring = { Radius: number, Width: number, Alpha: number }
export type Frame = {
	Tau: number,
	Clip: number, -- where Rook's Reveal is
	Cx: number,
	Colour: Color3,
	Level: number,
	Hot: Color3, -- the light run toward white
	Glow: number, -- the room's light
	Rings: { Ring }, -- off each rung, at (cx, cy)
	Flash: number, -- a rung's flash at the shard
	Window: { Sx: number, Sy: number, Rays: number, Turn: number, Sill: number, Framed: number }?, -- from the split
	Shard: { Pose: Pose, Point: Vector2, Leak: { Lay } }?, -- until 0.7 s past the split
	Figure: { Cover: number, Rim: number, Edge: number?, Line: number }?, -- from the split
	Strike: { Ring: Ring, Dot: number, Column: { Width: number, Alpha: number }? }?, -- 0.25 s from the Knock
	Name: { U: number, Slam: number, Burn: number, Landed: number, Glint: { X: number, Alpha: number }?, Wash: number, Right: number, Span: number }?,
	Split: { Radius: number?, Alpha: number }?, -- the split's flash; no radius: the whole screen
	Kick: number,
	Done: boolean, -- the card's time
}

-- Everything the stage lays at `t`, for a name `width` points wide where it lands (Widest if not given).
function Reveal.At(r: Rarity, t: number, width: number?): Frame
	local split = r.Times.Split
	local tau = t - split
	local clip = tau + r.Offset
	local colour, level = Reveal.Light(r, t)
	local frame: Frame = {
		Tau = tau,
		Clip = clip,
		Cx = Reveal.Cx(r, t),
		Colour = colour,
		Level = level,
		Hot = colour:Lerp(WHITE, 0.55),
		Glow = if level > 0 then 0.34 * level else 0,
		Rings = {},
		Flash = 0,
		Kick = Reveal.Kick(t - r.Times.Name, r.Shake),
		Done = t >= r.Times.Card,
	}
	for i = 2, #r.Steps do
		local s = r.Steps[i]
		local age = t - s.When
		if age >= 0 and age < 0.3 then
			table.insert(frame.Rings, { Radius = 30 + age * 900, Width = 10 + age * 60, Alpha = 0.5 * s.Level * (1 - age / 0.3) })
		end
		if age >= 0 and age < 0.08 then
			frame.Flash = math.max(frame.Flash, 0.35 * s.Level * (1 - age / 0.08))
		end
	end
	if tau >= 0 then
		local opened = Reveal.Back(tau / 0.16)
		frame.Window = {
			Sx = 0.03 + 0.97 * opened,
			Sy = 0.72 + 0.28 * Reveal.Smooth(tau / 0.12),
			Rays = if r.Light.Rays > 0 then math.min(1, opened) else 0,
			Turn = 0.12 * tau,
			Sill = 0.45 * level,
			Framed = Reveal.Smooth((tau - 0.08) / 0.12),
		}
		local flood = Art.Figure.Flood
		local u = (clip - Art.Figure.Knock) / flood.Seconds
		frame.Figure = {
			Cover = Reveal.Smooth((tau - 0.03) / 0.08),
			Rim = 0.8 * math.min(1, 0.45 + 0.55 * level) * Reveal.Back(tau / 0.16),
			Edge = if u > 0 then flood.Reach * Reveal.Run(u) else nil,
			Line = if u > 0 and u < 1.3 then (1 - u / 1.3) * 0.8 else 0,
		}
		local age = clip - Art.Figure.Knock
		if age >= 0 and age < 0.25 then
			local fade = 1 - age / 0.25
			frame.Strike = {
				Ring = { Radius = 14 + age * 820, Width = 5 + age * 40, Alpha = (0.35 + 0.5 * r.Light.Level) * fade },
				Dot = 0.7 * math.max(0, 1 - age / 0.06),
				Column = if r.Light.Rays > 0 then { Width = 7 + 30 * age / 0.25, Alpha = 0.8 * fade } else nil,
			}
		end
		local flash = r.Flash
		if tau < flash.Seconds then
			if flash.Radius then
				frame.Split = { Radius = flash.Radius, Alpha = flash.Strength * (1 - tau / flash.Seconds) ^ 2 }
			else
				local fade = if tau < 0.035 then 1 else (1 - (tau - 0.035) / (flash.Seconds - 0.035)) ^ 1.5
				frame.Split = { Alpha = flash.Strength * fade }
			end
		end
	end
	if t < split + SHARD_FOR then
		local pose = Reveal.Pose(r, t)
		local root = Art.Shard.Root
		frame.Shard = {
			Pose = pose,
			Point = root.Origin + root.PerX * pose.At.X + root.PerZ * pose.At.Y,
			Leak = Reveal.Leak(r, t, level, pose.Core),
		}
	end
	local u = t - r.Times.Name
	local slam = Reveal.Slam(u)
	if slam then
		local name = Art.Name
		local right = name.Left + (width or name.Widest)
		local glint = nil
		if u >= 0 and u < 0.3 then
			glint = { X = name.Left - 10 + u / 0.2 * (right + 32 - name.Left), Alpha = 1 - u / 0.3 }
		end
		frame.Name = {
			U = u,
			Slam = slam,
			Burn = math.max(0, 1 - math.max(u, 0) / 0.14) ^ 2,
			Landed = Reveal.Smooth((u + 0.02) / 0.03),
			Glint = glint,
			Wash = if u >= 0 then 0.3 * math.max(0, 1 - u / 0.1) else 0, -- from the landing, as the art lays it
			Right = right,
			Span = math.min(right + 22, name.Left + name.Widest + 6) - (name.Left - 10),
		}
	end
	return frame
end

return Reveal
