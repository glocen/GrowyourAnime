--!strict
-- Hud (pure): the HUD's rules that need no engine, so they're tested with Studio closed (docs/ui.md, "The HUD, in the
-- world"; docs/test-requests.md, TR3). The flurry's one counting number, a number placed clear of its neighbours', the
-- type edge's arrow, a number's digits, and what a control says while it waits or can't be pressed; the UI effects'
-- shapes (TR6). The client draws them (src/client/UI); nothing here decides what a player owns.

local Shared = game:GetService("ReplicatedStorage").Shared
local Hit = require(Shared.Rules.Hit)
local Profile = require(Shared.Data.Profile)

local Hud = {}

-- A box on screen, in pixels.
export type Rect = { Left: number, Top: number, Right: number, Bottom: number }

-- Whether two boxes share any area (touching edges don't).
function Hud.Over(a: Rect, b: Rect): boolean
	return a.Left < b.Right and b.Left < a.Right and a.Top < b.Bottom and b.Top < a.Bottom
end

-- An element's transparency with its piece drawn at `opacity` of itself: a part of what shows of it (1 is whole).
function Hud.Faded(own: number, opacity: number): number
	return 1 - (1 - own) * math.clamp(opacity, 0, 1)
end

-- A piece's opacity at fade `share` (0 whole, 1 at its floor), its floor `floor`.
function Hud.Through(share: number, floor: number): number
	return 1 - math.clamp(share, 0, 1) * (1 - floor)
end

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

-- How far through its landing it is at `age`: 1 at its birth, 0 once it has settled over `count` (a critical lands
-- swollen and settles, the same swell a joining hit gives: AR44, research's second look).
function Hud.Land(age: number, count: number): number
	if count <= 0 then
		return 0
	end
	return 1 - Hud.Ease(age / count)
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
-- One moment of a number's rise: where it will be then, unmoved, and where the others will be.
export type Moment = { Want: Box, Taken: { Box } }

-- How much two boxes overlap, each kept `clear` pixels from the other: two that only touch overlap by `clear` across.
local function overlap(a: Box, b: Box, clear: number?): number
	local c = clear or 0
	local w = math.min(a.X + a.W / 2, b.X + b.W / 2) - math.max(a.X - a.W / 2, b.X - b.W / 2) + c
	local h = math.min(a.Y + a.H / 2, b.Y + b.H / 2) - math.max(a.Y - a.H / 2, b.Y - b.H / 2) + c
	return if w > 0 and h > 0 then w * h else 0
end

-- Where a new number goes, clear of the numbers already showing (research's read of Held Note's fixes, AR4 section 10:
-- two bodies close together overlapped their numbers). `slots` are offsets in the number's own widths and heights, in
-- the order tried; the first that overlaps nothing in `taken` wins, and when every one overlaps, the one that overlaps
-- least. Returns the offset in pixels.
-- `top`, when given, is the top band's lower edge (the cards' and the pills', plus a margin): a number's whole life stays
-- under it (TR3's verdict, fix 4). `rise` is how far it climbs after its birth, so one born near the band starts lower,
-- and no slot lifts it back over.
function Hud.Place(want: Box, taken: { Box }, slots: { { number } }, top: number?, rise: number?): (number, number)
	return Hud.PlaceAlong({ { Want = want, Taken = taken } }, slots, top, rise)
end

-- As Place, clear at every moment given, its birth first (AR44's verdict, fix 3): each number rises on its own eased
-- curve, so one born a beat after another climbs faster and catches it up, and only its birth was clear. A slot's
-- offset is the same at every moment; the overlaps of all the moments add up; and `clear` is the room every box
-- keeps from every other, so none touches. Held down by the band, a slot above folds onto where it's held and a slot
-- below counts down from there: on a phone the band can sit level with where numbers are born, and a slot below its
-- birth fell inside the hold, onto the one before it.
function Hud.PlaceAlong(moments: { Moment }, slots: { { number } }, top: number?, rise: number?, clear: number?): (number, number)
	local bestX, bestY, least = 0, 0, math.huge
	local want = moments[1].Want
	local lowest = if top then top + want.H / 2 + math.max(rise or 0, 0) - want.Y else -math.huge -- the highest a slot may sit
	local held = math.max(lowest, 0) -- where its own slot stands
	for _, slot in slots do
		local dx, dy = slot[1] * want.W, math.max(held + slot[2] * want.H, lowest)
		local covered = 0
		for _, moment in moments do
			local w = moment.Want
			local moved: Box = { X = w.X + dx, Y = w.Y + dy, W = w.W, H = w.H }
			for _, other in moment.Taken do
				covered += overlap(moved, other, clear)
			end
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

-- A whole number in its compact form, for a place too narrow for its digits (TR3's verdict, fix 6): three figures and
-- K, M, B or T, cut, never rounded up, so it never shows more than there is: "999", "1.25K", "12.5M", "125B", "1M".
local UNITS: { { Size: number, Mark: string } } = {
	{ Size = 1e12, Mark = "T" },
	{ Size = 1e9, Mark = "B" },
	{ Size = 1e6, Mark = "M" },
	{ Size = 1e3, Mark = "K" },
}

function Hud.Short(n: number): string
	local whole = math.floor(math.abs(n) + 0.5)
	local sign = if n < 0 and whole > 0 then "-" else ""
	for _, unit in UNITS do
		if whole >= unit.Size then
			local value = whole / unit.Size
			local places = if value < 10 then 2 elseif value < 100 then 1 else 0
			local step = 10 ^ places
			local cut = math.floor(value * step + 1e-9) / step
			local text = string.format(`%.{places}f`, cut)
			if places > 0 then
				text = text:gsub("0+$", ""):gsub("%.$", "")
			end
			return `{sign}{text}{unit.Mark}`
		end
	end
	return sign .. tostring(whole)
end

-- A card's health in whole points: a fighter still standing shows at least 1, and never more than its most, which is
-- whole points too ("882 / 881" came from rounding the most but not the health). `room`, when given, is how many
-- characters its bar holds: past it, both take their compact form (Hud.Short), if that's shorter. `tight`: no spaces round
-- the slash (the lead's card, 2026-11-13: its digits as set in the mock the director picked).
function Hud.Health(health: number, most: number, room: number?, tight: boolean?): string
	local top = math.max(math.ceil(most - 1e-6), 0)
	local now = math.clamp(math.ceil(health - 1e-6), 0, top)
	local slash = if tight then "/" else " / "
	local full = `{Hud.Digits(now)}{slash}{Hud.Digits(top)}`
	if room == nil or #full <= room then
		return full
	end
	local short = `{Hud.Short(now)}{slash}{Hud.Short(top)}`
	return if #short < #full then short else full
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

-- Why a Voidkin can't be made the lead, or nil when it can: its role ("Lead", "Bay 2" or ""). A stationed one can: its
-- Lead recalls it in the same step (Collection.SetLead; research's ruling, 2026-11-17), and says so (Hud.LeadNote).
function Hud.LeadReason(role: string, healingUntil: number?, now: number?, inCombat: boolean?): string?
	if role == "Lead" then
		return "Leading"
	elseif inCombat then
		return "In a fight" -- the lead never changes in a fight (TR12)
	elseif healingUntil and now and healingUntil > now then
		return `Healing {Hud.Clock(healingUntil - now)}` -- a fallen one, healing at home
	end
	return nil
end

-- Why a Voidkin can't be stationed, or nil and the bay it would go to, the first one empty (TR17's Station; the word
-- research's, on the director's remark, 2026-11-17). The lead fights and never works (Rules.Base, SetWorker), so its page
-- shows no Station; a stationed one's button recalls it.
function Hud.WorkReason(role: string, bays: { Profile.Bay }): (string?, number?)
	if role == "Lead" then
		return "Leading", nil
	elseif role ~= "" then
		return "Stationed", nil
	end
	for index, bay in bays do
		if bay.Worker == "" then
			return nil, index
		end
	end
	return if #bays == 0 then "No bay open yet" else "No bay free", nil
end

-- The line under a pressable Lead: "Leaves Bay 2" on a stationed one (role "Bay 2"), else nil.
function Hud.LeadNote(role: string): string?
	local bay = string.match(role, "^Bay (%d+)$")
	return if bay then `Leaves Bay {bay}` else nil
end

-- Seconds as minutes and seconds, rounded up: "1:05", "0:09".
function Hud.Clock(seconds: number): string
	local s = if seconds == seconds then math.max(0, math.ceil(seconds - 1e-9)) else 0
	return string.format("%d:%02d", s // 60, s % 60)
end

-- A drop's chance as a loot card writes it (TR10): whole percents from 10 up, a tenth under, cut, never rounded up, so a
-- chance short of certain never reads "100%" and one there is never reads "0%": "100%", "36%", "14%", "3.6%", "<0.1%".
function Hud.Chance(p: number): string
	if p ~= p or p <= 0 then
		return "0%"
	elseif p >= 1 then
		return "100%"
	end
	local percent = p * 100 + 1e-9
	if percent >= 10 then
		return `{math.floor(percent)}%`
	end
	local tenths = math.floor(percent * 10)
	if tenths <= 0 then
		return "<0.1%"
	end
	return if tenths % 10 == 0 then `{tenths // 10}%` else string.format("%.1f%%", tenths / 10)
end

-- What the lead's card says while its lead has fallen (TR12), or nil while it stands: "Down" as it falls; at home, its
-- healing and the time left; then "Training" on the machine, or "At home" waiting. "Healing 0:24", as a refusal says it
-- (LeadReason): take F's health line holds no more at the smallest phone ("Healing at home 0:24" ran 1.2 of its box).
function Hud.LeadStatus(state: string, untilAt: number, now: number, training: boolean): string?
	if state == "Down" then
		return "Down"
	elseif state ~= "Home" then
		return nil
	elseif untilAt > now then
		return `Healing {Hud.Clock(untilAt - now)}`
	end
	return if training then "Training" else "At home"
end

-- Another Voidkin the player owns, as a fallen lead's card weighs it: its role ("Lead", "Bay 1" or "", UI.Read.Role) and,
-- after a fall of its own, the server time it's whole (LeadService's "Healing").
export type Other = { Role: string, Healing: number? }

-- What a fallen lead's card offers (docs/test-requests.md, TR12 and TR19), or nil while the lead stands: "Send" while
-- another Voidkin could lead now (the next lead, whom Hud.LeadReason refuses nothing but the fight the fall just ended),
-- else "Home" while the player is out in a ground (`away`): the dock's Base tile takes the pip, since home is where the
-- lead waits; else nothing, the player already home. A Voidkin at work never makes it "Send": the card sends one from
-- home, never out of a bay (its Lead on its own page can, Collection.SetLead).
function Hud.AfterFall(down: boolean, others: { Other }, now: number, away: boolean): ("Send" | "Home")?
	if not down then
		return nil
	end
	for _, other in others do
		if (other.Role == "" or other.Role == "Lead") and Hud.LeadReason(other.Role, other.Healing, now, false) == nil then
			return "Send"
		end
	end
	return if away then "Home" else nil
end

-- The picture a shard of `grade` wears drawn `points` across (AR12, Modulo's six): its grade's own, or Standard's for a
-- grade with none drawn (Named and Starter, until a ruling); the small one under `large` points.
local PICTURED = { Standard = true, Enriched = true, Prismatic = true }
function Hud.ShardPicture(grade: string, points: number, large: number): string
	local name = `Shard{if PICTURED[grade] then grade else "Standard"}`
	return if points >= large then name else `{name}Small`
end

-- How many of the battery mark's three cells are lit (TR41 (e); research's must-fix: two readings of one value never
-- disagree, and a mark with cells reads as a gauge). Full only when full, as the Power pill's "full" says; empty only when
-- empty; between, a cell for each third begun, at most two.
function Hud.BatteryCells(kwh: number, capacity: number): number
	if capacity <= 0 or kwh <= 1e-6 then
		return 0
	end
	if kwh >= capacity - 1e-6 then
		return 3
	end
	return math.clamp(math.ceil(kwh / capacity * 3 - 1e-9), 1, 2)
end

-- The contrast of two colours, WCAG's: (L1 + 0.05) / (L2 + 0.05) of their relative luminances, the lighter over the
-- darker (docs/ui.md: text and icons 4.5:1 or more on their ground).
-- The Stars page's copies toward the next star: "3 of 5 copies for the next" while short of it, and once past it the
-- count and the need apart, "48 copies, 1 needed for the next star", never "48 of 1" (research's must-fix, 2026-11-17).
function Hud.Copies(have: number, need: number): string
	if have > need then
		return `{Hud.Digits(have)} copies, {Hud.Digits(need)} needed for the next star`
	end
	return `{Hud.Digits(have)} of {Hud.Digits(need)} copies for the next`
end

function Hud.Contrast(a: Color3, b: Color3): number
	local function channel(c: number): number
		return if c <= 0.04045 then c / 12.92 else ((c + 0.055) / 1.055) ^ 2.4
	end
	local function luminance(c: Color3): number
		return 0.2126 * channel(c.R) + 0.7152 * channel(c.G) + 0.0722 * channel(c.B)
	end
	local la, lb = luminance(a), luminance(b)
	return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05)
end

-- The festival tag on a shard's picture shown `side` points across (Config.Hud.ShardTag; TR41 (d)): the tag with its
-- thread from `large` up, else the mark on its disc. Its box is in points from the picture's middle: its left, its top,
-- its width and its height. `left`: the mark at the crystal's left foot, mirrored, where a bag cell's count holds the
-- right (TR41 (d)).
export type TagLook = {
	Tag: { Plaque: number, Tie: Vector2, At: Vector2, Third: { Upto: number, Of: number }, Quarter: { From: number, Of: number } },
	Mark: { Side: number, Least: number, Middle: Vector2 },
}
export type TagBox = { Kind: "Tag" | "Mark", X: number, Y: number, W: number, H: number }
function Hud.ShardTag(side: number, look: TagLook, large: number, image: Vector2, left: boolean?): TagBox
	if side >= large then
		local tag = look.Tag
		local t = math.clamp((side - tag.Third.Upto) / (tag.Quarter.From - tag.Third.Upto), 0, 1)
		local plaque = side * (tag.Third.Of + (tag.Quarter.Of - tag.Third.Of) * t)
		local s = plaque / tag.Plaque
		return { Kind = "Tag", X = tag.At.X * side - tag.Tie.X * s, Y = tag.At.Y * side - tag.Tie.Y * s, W = image.X * s, H = image.Y * s }
	end
	local mark = look.Mark
	local across = math.max(side * mark.Side, mark.Least)
	local x = (if left then -mark.Middle.X else mark.Middle.X) * side
	return { Kind = "Mark", X = x - across / 2, Y = mark.Middle.Y * side - across / 2, W = across, H = across }
end

-- Why the dock's Voidkin button can't be pressed, or nil when it can.
function Hud.VoidkinReason(owned: number): string?
	return if owned > 0 then nil else "No Voidkin"
end

-- AR8 C, the interface's motion (Config.Hud.Motion and Pop; docs/research/vfx-reference.md, rule 4).
export type Press = { Squeeze: number, In: number, Least: number, Out: number, Back: number }

-- A button's face, a share of its size, `now` seconds on: touched at `down`, let go at `up` (nil while held; an up
-- before the down is an old one). The squeeze comes in eased out; a quick tap stays squeezed for at least Least; it
-- comes back eased out with a small overshoot (a Back ease), to exactly 1.
function Hud.Squeeze(now: number, down: number?, up: number?, press: Press): number
	if down == nil then
		return 1
	end
	local squeezed = function(at: number): number
		local u = if press.In > 0 then math.clamp((at - down) / press.In, 0, 1) else 1
		return 1 - (1 - press.Squeeze) * Hud.Ease(u)
	end
	if up == nil or up < down then
		return squeezed(now)
	end
	local from = math.max(up, down + press.Least)
	if now <= from then
		return squeezed(now)
	end
	local u = if press.Out > 0 then math.clamp((now - from) / press.Out, 0, 1) else 1
	if u >= 1 then
		return 1
	end
	local start = squeezed(from)
	local c1 = press.Back
	local back = 1 + (c1 + 1) * (u - 1) ^ 3 + c1 * (u - 1) ^ 2 -- 0 to 1, past 1 for a moment when c1 > 0
	return start + (1 - start) * back
end

-- A pop's shape, 0 to 1 to 0 over its life `t` (0 to 1): up to its peak at `peak`, eased out, then down, eased in and
-- out (rule 3: the peak early, never a linear fade).
function Hud.Pop(t: number, peak: number): number
	if t <= 0 or t >= 1 then
		return 0
	end
	if t < peak then
		return Hud.Ease(t / peak)
	end
	local u = (t - peak) / (1 - peak)
	return 1 - u * u * (3 - 2 * u)
end

-- How large a pop swells at its rung: 1 + swell × (rung − 1).
function Hud.PopScale(rung: number, swell: number): number
	return 1 + swell * (math.max(rung, 1) - 1)
end

-- A number's size by its hit's rung: Grow of its style's size for each rung over the style's own, at most Most.
function Hud.NumberScale(style: string, rung: number?, by: { Grow: number, Most: number, Rungs: { [string]: number }, Default: number }): number
	local own = by.Rungs[style] or by.Default
	local over = math.max(0, (rung or own) - own)
	return math.min(1 + by.Grow * over, by.Most)
end

-- A number giving way to a heavier hit, `since` seconds after it landed: its fade (0 to 1, eased in) and how far it has
-- moved aside (0 to 1, eased out).
function Hud.Yield(since: number, seconds: number): (number, number)
	local u = if seconds > 0 then math.clamp(since / seconds, 0, 1) else 1
	return u * u, Hud.Ease(u)
end

-- The UI effects kit's shapes (TR6; docs/research/vfx-reference.md, "UI effects", DESIGN). The client draws them
-- (src/client/UI/Kit: Fly, Count, Rays, Shine, Burst).

-- Expo out: most of a count done fast and only its end eased (the study's countUp.js); exactly 1 at its end.
function Hud.ExpoOut(u: number): number
	local c = math.clamp(u, 0, 1)
	return if c >= 1 then 1 else 1 - 2 ^ (-10 * c)
end

-- How many icons a reward sends flying: `least` for a gain under 10, one more for each power of ten, at most `most`;
-- none for nothing.
function Hud.Flock(amount: number, least: number, most: number): number
	if amount <= 0 then
		return 0
	end
	local tens = math.floor(math.log10(math.max(amount, 1)) + 1e-9)
	return math.clamp(least + tens, least, math.max(least, most))
end

-- Where a flying icon is at `u` of its way (0 to 1): on a curve from `from` to `to`, bowed to one side by `bend` of the
-- way's length at its control point (the other side when negative), so its middle stands half that off the straight
-- line. A quadratic Bézier.
function Hud.Arc(from: Vector2, to: Vector2, bend: number, u: number): Vector2
	local t = math.clamp(u, 0, 1)
	local along = to - from
	local control = from + along / 2 + Vector2.new(-along.Y, along.X) * bend
	return from * ((1 - t) * (1 - t)) + control * (2 * (1 - t) * t) + to * (t * t)
end

-- A share's way toward `want`, `dt` seconds on from `share`: a spring with no overshoot, about 95% of the way in `seconds`
-- (three time constants), so a long frame never jumps it and a change of mind turns it smoothly (TR11, the spectate's
-- ease).
function Hud.Approach(share: number, want: number, dt: number, seconds: number): number
	local k = 1 - math.exp(-math.max(dt, 0) * 3 / math.max(seconds, 1e-3))
	return share + (want - share) * k
end

-- How full the signature's ring is: 0 the moment it fires, 1 once it's ready again.
function Hud.Ready(readyAt: number, cooldown: number, now: number): number
	if cooldown <= 0 then
		return 1
	end
	return math.clamp(1 - (readyAt - now) / cooldown, 0, 1)
end

-- The shards' hint over the dock (docs/ui.md, the HUD): the step that's next while the bag holds a shard, and only at the
-- base (the director, 2026-11-15: "should only show when we are at the base"). `first`: the one shard's name, when the bag
-- holds one alone. Nil: no hint.
function Hud.ShardHint(kinds: number, total: number, first: string?, home: boolean): string?
	if not home or total <= 0 then
		return nil
	end
	return if kinds == 1 and total == 1 and first then `{first}: into the Breaker` else `{total} shards: into the Breaker`
end

-- What the next-step line reads (TR24's fix 1): the first session's state, as HudController reads it.
export type StepState = {
	Home: boolean, -- the avatar stands on its own plot
	Chosen: boolean, -- the starter shard is chosen
	Ready: number, -- shards broken, waiting to be opened
	Breaking: number, -- shards in the Breaker's chambers
	Shards: number, -- shards in the bag
	Kinds: number, -- of how many kinds
	First: string?, -- the one shard's name, when the bag holds one alone
	Idle: string?, -- a Voidkin's name that neither leads, works nor trains, while a bay stands empty
	Bay: number?, -- the lowest empty bay
	Worked: boolean, -- a bay has a worker
	Won: boolean, -- a keeper beaten: the first session's guide is over
	Keeper: string?, -- out in a ground whose keeper waits at its gate: the keeper's name
	Ground: string, -- the name of the ground the Door opens on
}

export type Step = {
	Line: string,
	Target: "Starters" | "Breaker" | "Bay" | "Door" | "Gate", -- where the world's marker stands
	Bay: number?, -- which bay, for "Bay"
}

-- The next step (TR24's fix 1: one line and one marker on the next target, at every step of the first session). At home,
-- in turn: the first shard to choose; shards ready to open; shards in the bag (ShardHint's line, which stays after the
-- first session); a Voidkin to station in an empty bay; then, until a keeper is beaten, a shard breaking and the
-- Door to the grounds. Out in a ground, once a bay works and until a keeper is beaten, the keeper's gate; nothing else,
-- since the shards' hint shows only at the base (the director, 2026-11-15). Nil: nothing to say.
function Hud.NextStep(s: StepState): Step?
	if not s.Home then
		if s.Won or not s.Worked or s.Keeper == nil then
			return nil
		end
		local name = string.upper(string.sub(s.Keeper, 1, 1)) .. string.sub(s.Keeper, 2)
		return { Line = `{name} waits at the gate`, Target = "Gate" }
	end
	if not s.Chosen then
		return { Line = "Choose your first shard", Target = "Starters" }
	end
	if s.Ready > 0 then
		return { Line = if s.Ready == 1 then "Ready: open it at the Breaker" else `{s.Ready} ready: open them at the Breaker`, Target = "Breaker" }
	end
	local shards = Hud.ShardHint(s.Kinds, s.Shards, s.First, true)
	if shards then
		return { Line = shards, Target = "Breaker" }
	end
	if s.Idle and s.Bay then
		return { Line = `Station {s.Idle} in Bay {s.Bay}`, Target = "Bay", Bay = s.Bay }
	end
	if s.Won then
		return nil
	end
	if s.Breaking > 0 then
		return { Line = "Breaking: it opens at the Breaker", Target = "Breaker" }
	end
	return { Line = `Through the Door: {s.Ground}`, Target = "Door" }
end

-- The readout's light (AR12; Config.Hud.Readout): one gradient across the well's square, `side` points each way, turned
-- so its lines rise `lean` of a point for each point to the right. Returns its turn in degrees (90 is top to foot) and
-- its length in points: the square's reach along the gradient's way.
function Hud.FrontTurn(side: number, lean: number): (number, number)
	local angle = math.atan2(1, lean)
	return math.deg(angle), side * (math.abs(math.cos(angle)) + math.abs(math.sin(angle)))
end

-- A stop `below` the front's line, in points (above it: negative), as its place along a gradient `length` points long
-- whose middle is the line: 0 its top end, 1 its foot. Past either end it holds the end.
function Hud.FrontAt(below: number, length: number): number
	return math.clamp(0.5 + below / math.max(length, 1e-6), 0, 1)
end

-- How far the gradient is carried along its way for the well to stand `share` full: the line at the foot when empty, at
-- the top when full, in the middle at a half. `travel`: the carry that takes the line from the middle to the foot.
function Hud.FrontOffset(share: number, travel: number): number
	return (0.5 - math.clamp(if share == share then share else 0, 0, 1)) * 2 * travel
end

-- A carry `along` the gradient's way, as the UIGradient's Offset: Roblox moves a gradient along its element's own axes,
-- not its turned way (seen in Studio, 2026-11-15: an Offset across a gradient turned 83 degrees barely moved its line), so
-- the carry is turned with it. `turn` in degrees, as FrontTurn gives it; returns the Offset's x and y.
function Hud.FrontShift(along: number, turn: number): (number, number)
	local angle = math.rad(turn)
	return along * math.cos(angle), along * math.sin(angle)
end


-- The level-up's notice (AR12, take B; Modulo's levelup_notice.json; Config.Hud.LevelNotice.Motion), `age` seconds after
-- it was shown, on a plate `wide` points across whose foot ends `foot` points from its left (its far end leans):
--   Away     how far it stands off its place to the left, 0 at its place to 1 wholly off the screen
--   Size     the number's size against its own (0 before it appears)
--   Number   how solid the number is
--   Flash    how solid the block's white flash is
--   Knock    points it's knocked to the right
--   Sheen    the sheen's middle along the foot, points from the plate's left, or nil while it isn't crossing
--   Shine    how solid the sheen is there (it fades in over its first Fade points on the plate and out over its last)
--   Solid    the whole notice's opacity (reduced motion fades it; otherwise 1)
--   Done     it has left
-- The levers: the slide in, eased out (cubic); the number falls onto its block (quadratic in), squashes and settles
-- (quadratic out); the impact, a white flash on the block and a knock, both falling off quadratically; the follow-through,
-- one sheen across the whole plate (smooth step). With reduced motion it fades in at its place with its number set, and out.
export type NoticeMotion = {
	In: number,
	Fall: number,
	From: number,
	Squash: number,
	Settle: number,
	Flash: { Strength: number, Seconds: number },
	Knock: { Points: number, Seconds: number },
	Sheen: { After: number, Seconds: number, Reach: number, Fade: number },
	Hold: number,
	Out: number,
	Fade: number,
}
export type Notice = {
	Away: number,
	Size: number,
	Number: number,
	Flash: number,
	Knock: number,
	Sheen: number?,
	Shine: number,
	Solid: number,
	Done: boolean,
}

function Hud.Notice(age: number, m: NoticeMotion, wide: number, foot: number, reduced: boolean?): Notice
	local leave = m.In + m.Hold
	if reduced then
		local solid = math.clamp(age / math.max(m.Fade, 1e-6), 0, 1) * math.clamp(1 - (age - leave) / math.max(m.Fade, 1e-6), 0, 1)
		return { Away = 0, Size = 1, Number = 1, Flash = 0, Knock = 0, Sheen = nil, Shine = 0, Solid = solid, Done = age >= leave + m.Fade }
	end
	local away = 0
	if age < m.In then
		away = (1 - math.max(age, 0) / m.In) ^ 3 -- cubic out: most of the way in at once
	elseif age > leave then
		away = math.min((age - leave) / m.Out, 1) ^ 3 -- cubic in: it gathers speed as it goes
	end
	local land = m.In + m.Fall
	local size, number = 0, 0
	if age >= m.In and age < land then
		local u = (age - m.In) / m.Fall
		size = m.From + (m.Squash - m.From) * u * u
		number = math.min(u * 3, 1)
	elseif age >= land then
		local u = math.min((age - land) / m.Settle, 1)
		size = m.Squash + (1 - m.Squash) * (1 - (1 - u) ^ 2)
		number = 1
	end
	local flash, knock = 0, 0
	if age >= land and age < land + m.Flash.Seconds then
		flash = m.Flash.Strength * (1 - (age - land) / m.Flash.Seconds) ^ 2
	end
	if age >= land and age < land + m.Knock.Seconds then
		knock = m.Knock.Points * (1 - (age - land) / m.Knock.Seconds) ^ 2
	end
	local sheen, shine = nil, 0
	local start = land + m.Sheen.After
	if age >= start and age <= start + m.Sheen.Seconds then
		local u = (age - start) / m.Sheen.Seconds
		local at = -m.Sheen.Reach + (wide + 2 * m.Sheen.Reach) * u * u * (3 - 2 * u)
		sheen = at
		shine = math.clamp(at / m.Sheen.Fade, 0, 1) * math.clamp((foot - at) / m.Sheen.Fade, 0, 1)
	end
	return { Away = away, Size = size, Number = number, Flash = flash, Knock = knock, Sheen = sheen, Shine = shine, Solid = 1, Done = age >= leave + m.Out }
end

-- The foe card's skull (AR45; Config.Hud.Skulls): 1 grey, 2 white, 3 yellow, 4 red, by the foe's CR over the lead's.
-- Grey under cuts[1]; white up to cuts[2], that ratio included; yellow under cuts[3]; red from it. With no lead CR yet
-- the foe reads white, or red if it has any.
function Hud.Skull(foe: number, lead: number, cuts: { number }): number
	if lead <= 0 then
		return if foe > 0 then 4 else 2
	end
	local ratio = foe / lead
	if ratio < cuts[1] then
		return 1
	elseif ratio <= cuts[2] then
		return 2
	elseif ratio < cuts[3] then
		return 3
	end
	return 4
end

return Hud
