--!strict
-- Hud (pure): the HUD's rules that need no engine, so they're tested with Studio closed (docs/ui.md, "The HUD, in the
-- world"; docs/test-requests.md, TR3). The flurry's one counting number, a number placed clear of its neighbours', the
-- type edge's arrow, a number's digits, and what a control says while it waits or can't be pressed. The client draws
-- them (src/client/UI); nothing here decides what a player owns.

local Shared = game:GetService("ReplicatedStorage").Shared
local Hit = require(Shared.Rules.Hit)

local Hud = {}

-- Out fast, settling: how a number counts and rises.
function Hud.Ease(u: number): number
	local c = math.clamp(u, 0, 1)
	return 1 - (1 - c) * (1 - c)
end

-- A flurry's number (research's fix 1 to Held Note, AR4 section 10): one press of one fighter's action on one body is
-- one number. Each hit while it shows adds to it, and it counts from what it showed to the new total. Ages are seconds
-- since the number was born.
export type Count = {
	Total: number,
	From: number, -- what it showed when the last amount came
	Changed: number, -- its age then, or -inf before any
}

function Hud.Count(amount: number): Count
	return { Total = amount, From = amount, Changed = -math.huge }
end

-- What it shows at `age`, counting over `count` seconds since its last amount.
function Hud.Shown(c: Count, age: number, count: number): number
	if c.Changed == -math.huge or count <= 0 then
		return c.Total
	end
	return c.From + (c.Total - c.From) * Hud.Ease((age - c.Changed) / count)
end

-- `amount` joins it at `age` (0 for a word said again: it pops and its fade starts over).
function Hud.Add(c: Count, amount: number, age: number, count: number)
	c.From = Hud.Shown(c, age, count)
	c.Total += amount
	c.Changed = age
end

-- Whether it still shows at `age`: it lives `seconds` from its last amount, or from its birth. While it shows, a hit of
-- the same press joins it; after, the next hit is a new number.
function Hud.Live(c: Count, age: number, seconds: number): boolean
	return age - (if c.Changed > -math.huge then c.Changed else 0) < seconds
end

-- How far through its swell it is at `age`: 1 the moment an amount joins, 0 once it has settled over `count`.
function Hud.Swell(c: Count, age: number, count: number): number
	if c.Changed == -math.huge or count <= 0 then
		return 0
	end
	return 1 - Hud.Ease((age - c.Changed) / count)
end

-- A box on the screen: its centre and size, in the layer's authored pixels.
export type Box = { X: number, Y: number, W: number, H: number }

local function overlap(a: Box, b: Box): number
	local w = math.min(a.X + a.W / 2, b.X + b.W / 2) - math.max(a.X - a.W / 2, b.X - b.W / 2)
	local h = math.min(a.Y + a.H / 2, b.Y + b.H / 2) - math.max(a.Y - a.H / 2, b.Y - b.H / 2)
	return if w > 0 and h > 0 then w * h else 0
end

-- Where a new number goes, clear of the numbers already showing (research's read of Held Note's fixes, AR4 section 10:
-- two bodies close together overlapped their numbers). `slots` are offsets in the number's own widths and heights, in
-- the order tried; the first that overlaps nothing in `taken` wins, and when every one overlaps, the one that overlaps
-- least. Returns the offset in pixels.
function Hud.Place(want: Box, taken: { Box }, slots: { { number } }): (number, number)
	local bestX, bestY, least = 0, 0, math.huge
	for _, slot in slots do
		local dx, dy = slot[1] * want.W, slot[2] * want.H
		local moved: Box = { X = want.X + dx, Y = want.Y + dy, W = want.W, H = want.H }
		local covered = 0
		for _, other in taken do
			covered += overlap(moved, other)
		end
		if covered == 0 then
			return dx, dy
		end
		if covered < least then
			bestX, bestY, least = dx, dy, covered
		end
	end
	return bestX, bestY
end

-- The type edge's arrow on the target's card, before the first hit (docs/ui.md): "Up" when the lead's type beats the
-- target's, "Down" when the target's beats the lead's, "" when neither does or a type is unknown.
function Hud.Arrow(mine: string?, theirs: string?): string
	local relation = Hit.TypeRelation(mine or "", theirs or "")
	return if relation > 0 then "Up" elseif relation < 0 then "Down" else ""
end

-- A whole number as the HUD writes it, rounded, with a comma every three digits (docs/ui.md: "thousands separators"):
-- "7", "2,357", "-1,200".
function Hud.Digits(n: number): string
	local whole = tostring(math.floor(math.abs(n) + 0.5))
	local grouped = whole:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if grouped:sub(1, 1) == "," then
		grouped = grouped:sub(2)
	end
	return if n < 0 and grouped ~= "0" then "-" .. grouped else grouped
end

-- A card's health in whole points: a fighter still standing shows at least 1, and never more than its most, which is
-- whole points too ("882 / 881" came from rounding the most but not the health).
function Hud.Health(health: number, most: number): string
	local top = math.max(math.ceil(most - 1e-6), 0)
	local now = math.clamp(math.ceil(health - 1e-6), 0, top)
	return `{Hud.Digits(now)} / {Hud.Digits(top)}`
end

-- What a control says (docs/ui.md, rule 4: "A disabled button says why"): "…" while it waits on the server, its reason
-- while it can't be pressed, its label otherwise.
Hud.Pending = "…"

function Hud.Says(label: string, disabled: string?, pending: boolean): string
	if pending then
		return Hud.Pending
	end
	if disabled ~= nil and disabled ~= "" then
		return disabled
	end
	return label
end

-- Why a Voidkin can't be made the lead, or nil when it can: its role in the save ("Lead", "Worker", or "").
function Hud.LeadReason(role: string): string?
	if role == "Lead" then
		return "Leading"
	elseif role ~= "" then
		return "At work"
	end
	return nil
end

-- Why the dock's Voidkin button can't be pressed, or nil when it can.
function Hud.VoidkinReason(owned: number): string?
	return if owned > 0 then nil else "No Voidkin"
end

-- The seconds a fallen lead's card shows until it's back: whole seconds, rounded up, never below 1 while it's down.
function Hud.Back(untilAt: number, now: number): number
	return math.max(1, math.ceil(untilAt - now))
end

-- How full the signature's ring is: 0 the moment it fires, 1 once it's ready again.
function Hud.Ready(readyAt: number, cooldown: number, now: number): number
	if cooldown <= 0 then
		return 1
	end
	return math.clamp(1 - (readyAt - now) / cooldown, 0, 1)
end

return Hud
