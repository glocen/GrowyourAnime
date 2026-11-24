--!strict
-- The critical's shine on its land (AR44, take C, research's pick of 2026-11-19, 23:36; Modulo's cut,
-- build/handoff/UI/hud/critical_shine.json; Config.Hud.Numbers.Critical.Shine). Copies of the digits with no outline,
-- in the number's plate, so they pop, rise and fade with it:
--   the split   a cyan copy left and up and a red one right and down, behind the digits and over their cast, drawing in
--               from Land to Rest: an impact's aberration that settles to a hairline each side;
--   the flash   a white copy over the digits, clear from opaque at once;
--   the glint   a white copy over them in a CanvasGroup, under one UIGradient whose band of light crosses the number
--               once, leaning with the italic. One gradient over the whole number, never one a character: a UIGradient
--               turns in screen pixels (measured, 2026-11-23), but how far its 0..1 reaches along a turned box isn't the
--               box's width, so bands laid character by character broke at each character's edge.
-- The flash and the glint are destroyed once played; the split stays the number's life.
--   Shine.new(plate, row, base)   at the land; `base` is the critical's own size, the split's unit
--   Shine.Lay(shine, since, fade) each frame: `since` seconds from the land, `fade` the number's transparency
local Shared = game:GetService("ReplicatedStorage").Shared
local HudConfig = require(Shared.Config.Hud)
local Digits = require(script.Parent.Parent.Parent.Parent.UI.Kit.Digits)

local Shine = {}

type Config = typeof(HudConfig.Numbers.Critical.Shine)
export type Shine = {
	Config: Config, -- as at its land, so a Tune shows on the next critical
	Plate: Frame,
	Row: Frame,
	Base: number,
	Cyan: Frame,
	Red: Frame,
	Flash: Frame?,
	Glint: CanvasGroup?, -- holds GlintRow, its UIGradient the band
	GlintRow: Frame?,
}

-- In the plate: the splash 0, the digits' cast 1, the split 2, the digits 3, the flash and the glint 4.
local SPLIT, DIGITS, OVER = 2, 3, 4

-- A copy's look: the row's face, size and gap, in one colour, no outline.
local function copyOf(look: Digits.Look, colour: Color3): Digits.Look
	return {
		Colour = colour,
		Outline = look.Outline,
		Weight = 0,
		Gap = look.Gap,
		Italic = look.Italic,
		Face = look.Face,
		Font = look.Font,
		Digit = look.Digit,
		Bare = true,
	}
end

local function copy(row: Frame, parent: Instance, name: string, colour: Color3, z: number): Frame
	local made = Digits.new(parent, row:GetAttribute("Size") :: number, copyOf(Digits.Looks[row], colour))
	made.Name = name
	made.ZIndex = z
	Digits.Set(made, row:GetAttribute("Text") :: string)
	return made
end

-- A copy keeps the row's text and size: a joining hit counts the number up, a heavier one grows it.
local function follow(row: Frame, made: Frame)
	local size = row:GetAttribute("Size") :: number
	if made:GetAttribute("Size") ~= size then
		Digits.Restyle(made, size, Digits.Looks[made])
	end
	Digits.Set(made, row:GetAttribute("Text") :: string)
end

-- Its centre `dx`, `dy` authored pixels from the plate's middle, as a share of the plate's own size: an offset is whole
-- pixels, too coarse for a split of 4.6.
local function lay(plate: Frame, made: Frame, dx: number, dy: number)
	local w, h = plate.Size.X.Offset, plate.Size.Y.Offset
	made.Position = UDim2.fromScale(0.5 + (if w > 0 then dx / w else 0), 0.5 + (if h > 0 then dy / h else 0))
end

local function quadOut(x: number): number
	local k = math.clamp(x, 0, 1)
	return 1 - (1 - k) * (1 - k)
end

-- The glint's light at `d` from a band's middle, of its middle's: whole, half at `half`, none by twice it.
local function band(d: number, half: number): number
	if half <= 0 then
		return 0
	end
	local k = math.abs(d) / half
	return if k < 1 then 1 - 0.5 * k elseif k < 2 then 0.5 * (2 - k) else 0
end

-- The band's light across the group, as its gradient's transparency: `middle` and `trail` are the two bands' middles,
-- `half` and `trailHalf` their half widths, all shares of the group's width from its left (the gradient's 0..1 read
-- along the group's middle row; turned by the Lean, its 0..1 spans 0.93 to 1.12 of the box's width by the box's shape,
-- measured 2026-11-23, always centred, so the band lands true at the middle and a few pixels off near the ends).
local function light(g: any, middle: number, trail: number, half: number, trailHalf: number): NumberSequence
	local ts = { 0, 1 }
	for _, t in { middle - 2 * half, middle - half, middle, middle + half, middle + 2 * half, trail - 2 * trailHalf, trail - trailHalf, trail, trail + trailHalf, trail + 2 * trailHalf } do
		if t > 0 and t < 1 then
			table.insert(ts, t)
		end
	end
	table.sort(ts)
	local points: { NumberSequenceKeypoint } = {}
	for _, t in ts do
		local before = points[#points]
		if before and t - before.Time < 1e-4 then
			if t < 1 then
				continue
			end
			points[#points] = nil -- the last keypoint is at 1 exactly
		end
		local lit = math.max(g.Strength * band(t - middle, half), g.TrailStrength * band(t - trail, trailHalf))
		table.insert(points, NumberSequenceKeypoint.new(t, 1 - lit))
	end
	return NumberSequence.new(points)
end

function Shine.new(plate: Frame, row: Frame, base: number): Shine
	local config = HudConfig.Numbers.Critical.Shine
	local split = config.Split
	row.ZIndex = DIGITS
	local cast = Digits.Shadows[row]
	if cast then
		cast.ZIndex = 1
	end
	local group = Instance.new("CanvasGroup")
	group.Name = "Glint"
	group.BackgroundTransparency = 1
	group.AnchorPoint = Vector2.new(0.5, 0.5)
	group.Position = UDim2.fromScale(0.5, 0.5)
	group.Size = UDim2.fromScale(1, 1)
	group.ZIndex = OVER
	group.GroupTransparency = 1 -- unlit until its Start
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = config.Glint.Lean -- in screen pixels, the top to the right
	gradient.Parent = group
	group.Parent = plate
	local shine: Shine = {
		Config = config,
		Plate = plate,
		Row = row,
		Base = base,
		Cyan = copy(row, plate, "SplitCyan", split.Cyan, SPLIT),
		Red = copy(row, plate, "SplitRed", split.Red, SPLIT),
		Flash = copy(row, plate, "Flash", config.Flash.Colour, OVER),
		Glint = group,
		GlintRow = copy(row, group, "Digits", Color3.new(1, 1, 1), 1),
	}
	Shine.Lay(shine, 0, 0)
	return shine
end

function Shine.Lay(shine: Shine, since: number, fade: number)
	local config, row, plate = shine.Config, shine.Row, shine.Plate
	local function clear(own: number): number
		return 1 - (1 - fade) * (1 - own)
	end
	-- The split: symmetric, the two together, always (the content check's condition).
	local split = config.Split
	local e = quadOut(if split.Seconds > 0 then since / split.Seconds else 1)
	local grown = (row:GetAttribute("Size") :: number) / shine.Base
	local d = (split.Land + (split.Rest - split.Land) * e) * grown
	local own = split.LandClear + (split.RestClear - split.LandClear) * e
	for _, pair in { { shine.Cyan, -1 }, { shine.Red, 1 } } do
		local made, side = pair[1] :: Frame, pair[2] :: number
		follow(row, made)
		lay(plate, made, side * d, side * d * split.Across)
		Digits.Fade(made, clear(own))
	end
	-- The flash: opaque at the land, clear by its Seconds.
	local flash = shine.Flash
	if flash then
		local k = if config.Flash.Seconds > 0 then since / config.Flash.Seconds else 1
		if k >= 1 then
			flash:Destroy()
			shine.Flash = nil
		else
			follow(row, flash)
			Digits.Fade(flash, clear(k))
		end
	end
	-- The glint: once across, from Start over Seconds.
	local group, glintRow = shine.Glint, shine.GlintRow
	if group and glintRow then
		local g = config.Glint
		local k = if g.Seconds > 0 then (since - g.Start) / g.Seconds else 2
		if k >= 1 then
			group:Destroy()
			shine.Glint, shine.GlintRow = nil, nil
			return
		end
		follow(row, glintRow)
		local across, width = group.AbsoluteSize.X, row.AbsoluteSize.X
		if k < 0 or across <= 0 or width <= 0 then
			group.GroupTransparency = 1
			return
		end
		group.GroupTransparency = fade
		-- Shares of the group's width: the row's left edge and width in it, the band from Reach of the number's width
		-- before it to Reach past it.
		local left = (row.AbsolutePosition.X - group.AbsolutePosition.X) / across
		local share = width / across
		local middle = left + share * (-g.Reach + (1 + 2 * g.Reach) * k)
		local gradient = group:FindFirstChildOfClass("UIGradient") :: UIGradient
		gradient.Transparency = light(g, middle, middle - g.Trail * share, g.Half * share, g.TrailHalf * share)
	end
end

return Shine
