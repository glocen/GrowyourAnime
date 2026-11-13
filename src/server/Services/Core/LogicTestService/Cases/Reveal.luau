--!strict
-- Reveal cases (pure): the reveal's ceremony as numbers (docs/test-requests.md, TR4, "Checks"). Every rarity has its
-- ceremony on Rook's timing, the skip opens at a second, the light lands on the rarity's own, the leak's sets cross whole,
-- the shard rests whole and parts, the name fits, the strike falls on the colours' time, each Voidkin's strike on Rook's
-- Knock, and the split's flash fades in its time.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Reveal = require(Shared.Rules.Reveal)
local Art = require(Shared.Config.RevealArt)
local RevealConfig = require(Shared.Config.Reveal)
local Rarity = require(Shared.Definitions.Rarity)
local Voidkin = require(Shared.Definitions.Voidkin)
local SoundConfig = require(Shared.Config.Sounds)
local SoundRule = require(Shared.Rules.Sound)

local FPS = 60
local CLOSE = 1e-4 -- the generated config's rounding

local function near(a: number, b: number, within: number?): boolean
	return math.abs(a - b) <= (within or 1e-9) * math.max(1, math.abs(b))
end

-- Each rarity's frames at 60 a second, from the tap to the card.
local function frames(r: Reveal.Rarity, fn: (t: number) -> ())
	for i = 0, math.ceil(r.Times.Card * FPS) do
		fn(i / FPS)
	end
end

return {
	{
		Name = "Reveal: every rarity has its ceremony, on Rook's timing",
		Run = function(t: any)
			local last = 0
			for _, name in Rarity.Order do
				local r = Art.Rarities[name]
				t.Check(`{name} has a ceremony`, r ~= nil)
				if r then
					local times = r.Times
					t.Check(`{name}: the colours run on Rook's Knock`, near(times.Colours, times.Split + Art.Figure.Knock - r.Offset, CLOSE))
					t.Check(`{name}: the name lands on his Name marker`, near(times.Name, times.Split + Art.Figure.NameMarker - r.Offset, CLOSE))
					t.Check(`{name}: the card after the name's hold`, near(times.Card, times.Name + r.Hold, CLOSE))
					t.Check(`{name}: no shorter than the rarity under it`, times.Split >= last)
					t.Check(`{name}: its grade is the shard's`, Art.Shard.Grades[r.Grade] ~= nil)
					t.Check(`{name}: four cracks`, #r.Cracks == 4)
					last = times.Split
				end
			end
		end,
	},
	{
		Name = "Reveal: the skip is shut before a second and open from it",
		Run = function(t: any)
			t.Check("shut just before", not Reveal.SkipOpen(RevealConfig.Skip - 1 / FPS))
			t.Check("open at a second", Reveal.SkipOpen(RevealConfig.Skip))
			t.Equal("a second, every rarity (reveal.json)", RevealConfig.Skip, 1)
			for _, name in Rarity.Order do
				t.Check(`{name}: the card comes after the skip opens`, Art.Rarities[name].Times.Card > RevealConfig.Skip)
			end
		end,
	},
	{
		Name = "Reveal: the light climbs from the shard's and lands on the rarity's",
		Run = function(t: any)
			for _, name in Rarity.Order do
				local r = Art.Rarities[name]
				local colour, level = Reveal.Light(r, -0.01)
				t.Check(`{name}: dark before the tap`, level == 0 and colour == Art.Shard.Colour)
				colour, level = Reveal.Light(r, r.Times.Split)
				t.Check(`{name}: the rarity's own from the split`, colour == r.Light.Colour and level == r.Light.Level)
				local most = 0
				frames(r, function(time: number)
					local _, lv = Reveal.Light(r, time)
					most = math.max(most, lv)
				end)
				t.Check(`{name}: never past full`, most <= 1)
				local breath = r.Breath
				if breath then
					local _, held = Reveal.Light(r, breath[1])
					local _, drawn = Reveal.Light(r, breath[2] - 0.01)
					t.Check(`{name}: the breath draws the light down`, drawn < held * 0.5, `{held} to {drawn}`)
				end
			end
		end,
	},
	{
		Name = "Reveal: the leak's sets cross whole and stay in the atlas",
		Run = function(t: any)
			local widths = { 1, 1.2, 1.45, 1.7, 2.3, 2.8 }
			for g = 1, 3.2, 0.05 do
				local sum = 0
				for _, p in Reveal.Shares(g, widths) do
					sum += p.Share
				end
				t.Check(`two sets make one at {g}`, near(sum, 1, 1e-9))
			end
			t.Check("blend leaves the ends", Reveal.Blend(0) == 0 and Reveal.Blend(1) == 1)
			t.Check("blend brings the upper in sooner", Reveal.Blend(0.5) > 0.5)
			for _, name in Rarity.Order do
				local r = Art.Rarities[name]
				local bad, none = 0, 0
				for i = 0, math.ceil(r.Times.Split * FPS) do
					local time = i / FPS
					local picked, over = Reveal.LeakPick(r, time)
					for _, p in picked do
						if p.Set < 0 or p.Set >= #Art.Leak.Sets or p.Share < 0 or p.Share > 1 + 1e-9 or over < 1 then
							bad += 1
						end
					end
					local _, level = Reveal.Light(r, time)
					if time > r.Cracks[1] + 0.05 and level > 0 and #Reveal.Leak(r, time, level, 1) == 0 then
						none += 1
					end
				end
				t.Equal(`{name}: every pick a set in the atlas, its share 0 to 1`, bad, 0)
				t.Equal(`{name}: the seams leak once cracked`, none, 0)
			end
		end,
	},
	{
		Name = "Reveal: the shard rests whole before the tap, parts at the split, and is gone after",
		Run = function(t: any)
			for _, name in Rarity.Order do
				local r = Art.Rarities[name]
				local pose = Reveal.Pose(r, -0.05)
				t.Check(`{name}: no seam open before the tap`, pose.Gaps[1] == 0 and pose.Gaps[4] == 0)
				t.Check(`{name}: still before the tap`, pose.Fly == 0 and pose.Spin == 0 and pose.Core == 1)
				local whole = true
				for piece, cf in Reveal.Pieces(pose) do
					whole = whole and (cf.Position - Art.Shard.Pieces[piece].Centre).Magnitude < 1e-9
				end
				t.Check(`{name}: every piece at its own place`, whole)
				local open = Reveal.Pose(r, r.Cracks[4] + 0.1)
				t.Check(`{name}: four seams open once cracked`, open.Gaps[4] > 0.04)
				local parted = Reveal.Pose(r, r.Times.Split + 0.3)
				t.Check(`{name}: the pieces fly`, parted.Fly > 0.8 * r.Reach and parted.Spin > 0)
				t.Equal(`{name}: the core gone 0.09 s after the split`, Reveal.Pose(r, r.Times.Split + 0.09 + 1e-9).Core, 0)
				t.Check(`{name}: the shard there until 0.7 s past`, Reveal.At(r, r.Times.Split + 0.69).Shard ~= nil)
				t.Check(`{name}: and gone from then`, Reveal.At(r, r.Times.Split + 0.7).Shard == nil)
				local moved = 0
				for piece, cf in Reveal.Pieces(parted) do
					if (cf.Position - Art.Shard.Pieces[piece].Centre).Magnitude > 1 then
						moved += 1
					end
				end
				t.Equal(`{name}: every piece but the core moved off`, moved, 7)
			end
		end,
	},
	{
		Name = "Reveal: the name slams to its size and never lands wider than the widest",
		Run = function(t: any)
			local stamp = RevealConfig.Stamp
			local lead = stamp.Frames / FPS
			t.Check("not before it shows", Reveal.Slam(-lead - 0.001) == nil)
			t.Check("large as it shows", near(Reveal.Slam(-lead) :: number, stamp.From))
			t.Check("under its size as it lands", near(Reveal.Slam(0) :: number, stamp.Under))
			-- research's TR4 fix 2: a stamp's fall over about four frames, faster each frame, so it reads as a stamp, not a cut
			t.Check("it falls over about four frames", stamp.Frames >= 3 and stamp.Frames <= 5, `{stamp.Frames}`)
			local last = nil
			for k = stamp.Frames, 1, -1 do
				local step = (Reveal.Slam(-k / FPS) :: number) - (Reveal.Slam(-(k - 1) / FPS) :: number)
				t.Check(`frame {stamp.Frames - k + 1}: smaller, and by more than the frame before`, step > 0 and (last == nil or step > last), `{step}`)
				last = step
			end
			t.Check("still at its size", near(Reveal.Slam(0.5) :: number, 1, 1e-6))
			for _, name in Rarity.Order do
				local r = Art.Rarities[name]
				for _, width in { 80, 200, 300, 379.2, 420, 700 } do
					local size = Reveal.NameSize(r, width)
					t.Check(`{name}: a name {width} wide fits`, width * size / Art.Name.Size <= Art.Name.Widest + 1e-9)
				end
				t.Check(`{name}: a short name at its own size`, near(Reveal.NameSize(r, 120), Art.Name.Size * r.NameScale * RevealConfig.NameFace))
				local landed = Reveal.At(r, r.Times.Name, 200).Name
				t.Check(`{name}: the name on its time`, landed ~= nil and near(landed.Slam, 0.93) and near(landed.Burn, 1))
				t.Check(`{name}: the screen kicked as it lands`, near(Reveal.At(r, r.Times.Name).Kick, r.Shake))
				local coming = Reveal.At(r, r.Times.Name - 0.03, 200).Name
				t.Check(`{name}: no wash before it lands`, coming ~= nil and coming.Wash == 0)
				t.Check(`{name}: the wash on the landing`, landed ~= nil and near(landed.Wash, 0.3))
				t.Check(`{name}: still by the card`, math.abs(Reveal.At(r, r.Times.Card).Kick) < 0.01)
			end
		end,
	},
	{
		Name = "Reveal: the strike falls on the colours' time, and each Voidkin's on Rook's Knock",
		Run = function(t: any)
			for _, name in Rarity.Order do
				local r = Art.Rarities[name]
				local colours = r.Times.Colours
				t.Check(`{name}: no strike before`, Reveal.At(r, colours - 0.002).Strike == nil)
				t.Check(`{name}: the strike at the colours' time`, Reveal.At(r, colours + 0.002).Strike ~= nil)
				t.Check(`{name}: over in 0.25 s`, Reveal.At(r, colours + 0.251).Strike == nil)
				local figure = Reveal.At(r, colours + 0.002).Figure
				t.Check(`{name}: his colours start running`, figure ~= nil and figure.Edge ~= nil and figure.Edge > 0)
				local before = Reveal.At(r, colours - 0.002).Figure
				t.Check(`{name}: dark before`, before ~= nil and before.Edge == nil)
			end
			t.Check("the fallback has its strike", RevealConfig.Strikes[RevealConfig.Fallback] ~= nil)
			for _, row in Voidkin.List do
				local model = (row :: any).Model
				if model then
					local strike = RevealConfig.Strikes[`{model}Reveal`]
					t.Check(`{row.Name}'s Reveal has its strike`, strike ~= nil)
					if strike then
						t.Check(`{row.Name}'s strike falls on Rook's Knock`, near(Reveal.Figure(Art.Figure.Knock, strike.Time), strike.Time))
					end
				end
			end
			t.Check("Rook's own clip unshifted", near(Reveal.Figure(0.3, RevealConfig.Strikes.RookReveal.Time), 0.3))
		end,
	},
	{
		Name = "Reveal: the colours' profile keeps the tile's ends right as the run passes them",
		Run = function(t: any)
			local row, height, soft = 97.5, 390, 45
			for _, edge in { 20, 100, 202, 325.8 } do
				local function f(d: number): number
					return 1 - math.clamp((edge - d) / soft, 0, 1)
				end
				local keys = Reveal.Profile(row, height, f, { 0, edge - soft, edge })
				t.Check(`edge {edge}: from the top to the foot`, keys[1][1] == 0 and keys[#keys][1] == 1)
				t.Check(`edge {edge}: the top as far as the row`, near(keys[1][2], f(row)))
				t.Check(`edge {edge}: the foot as far as the row`, near(keys[#keys][2], f(height - row)))
				local ordered = true
				for i = 2, #keys do
					ordered = ordered and keys[i][1] > keys[i - 1][1]
				end
				t.Check(`edge {edge}: in order`, ordered)
			end
		end,
	},
	{
		Name = "Reveal: the sounds land on their beats, research's cues at each rarity",
		Run = function(t: any)
			local s = RevealConfig.Sounds
			local function length(_: string): number
				return 0.5
			end
			for index, name in Rarity.Order do
				local r = Art.Rarities[name]
				local cues = Reveal.Cues(r, name, index, "HaymakerStrike", length)
				local by: { [string]: { Reveal.Cue } } = {}
				local ordered = true
				for i, c in cues do
					by[c.Cue] = by[c.Cue] or {}
					table.insert(by[c.Cue], c)
					ordered = ordered and (i == 1 or c.At >= cues[i - 1].At)
				end
				t.Check(`{name}: in time order`, ordered)
				local cracks = by[s.Crack.Cue] or {}
				t.Equal(`{name}: a crack at each seam`, #cracks, #r.Cracks)
				t.Check(`{name}: each crack a semitone over the last`, #cracks >= 2 and near((cracks[2].Speed :: number) / (cracks[1].Speed :: number), 2 ^ (1 / 12)))
				t.Equal(`{name}: a rung at each new colour`, #(by[s.Rung.Cue] or {}), #r.Steps - 1)
				local breath = by[s.Breath.Cue]
				t.Check(`{name}: a breath only where the art breathes`, (breath ~= nil) == (r.Breath ~= nil))
				if breath then
					local cut = breath[1].Until :: number
					t.Check(`{name}: the breath cut dead before the split`, near(cut, r.Times.Split - s.Breath.Cut) and near(breath[1].At + 0.5, cut))
				end
				local high = by[s.SplitHigh.Cue]
				t.Check(`{name}: the full burst only at the two peaks`, (high ~= nil) == (name == "Legendary" or name == "Mythical"))
				local split = (high or by[s.SplitLow.Cue] or {})[1]
				t.Check(`{name}: the split on its frame`, split ~= nil and near(split.At, r.Times.Split))
				local strike = (by.HaymakerStrike or {})[1]
				t.Check(`{name}: his strike on the Knock, shortened`, strike ~= nil and near(strike.At, r.Times.Colours) and near(strike.Until :: number, r.Times.Colours + s.Strike.Length))
				t.Check(`{name}: the bed from Rare up`, (by[s.Bed.Cue] ~= nil) == (index >= 3))
				local stamp = (by[s.Name.Cue] or {})[1]
				t.Check(`{name}: the stamp a frame after the slam`, stamp ~= nil and near(stamp.At, r.Times.Name + 1 / 60))
			end
			local function one(cues: { Reveal.Cue }, cue: string, last: boolean?): Reveal.Cue?
				local found = nil
				for _, c in cues do
					if c.Cue == cue and (found == nil or last) then
						found = c
					end
				end
				return found
			end
			local mythical = Reveal.Cues(Art.Rarities.Mythical, "Mythical", #Rarity.Order, nil, length)
			local top = one(mythical, s.Rung.Cue, true)
			t.Check("the top rung at its level", top ~= nil and near(top.Db, s.Rung.Db[2]))
			local burst = one(mythical, s.SplitHigh.Cue)
			t.Check("Mythical's burst a touch lower", burst ~= nil and near(burst.Speed, 0.9))
			local stamp = one(mythical, s.Name.Cue)
			t.Check("Mythical's stamp at its level", stamp ~= nil and near(stamp.Db, s.Name.Db[2]))
			local common = Reveal.Cues(Art.Rarities.Common, "Common", 1, nil, length)
			t.Check("no strike without his own", one(common, "HaymakerStrike") == nil)
			local pop = one(common, s.SplitLow.Cue)
			t.Check("Common's pop at its level", pop ~= nil and near(pop.Db, s.SplitLow.Db.Common))
			local last = math.huge
			local deeper = true
			for index, name in Rarity.Order do
				local low = one(Reveal.Cues(Art.Rarities[name], name, index, nil, length), s.SplitLow.Cue)
				if low then
					deeper = deeper and low.Speed < last
					last = low.Speed
				end
			end
			t.Check("the pop deeper and longer as it climbs", deeper and last < 1)
			local commonStamp = one(common, s.Name.Cue)
			t.Check("Common's stamp at its level, its loudest", commonStamp ~= nil and near(commonStamp.Db, s.Name.Db[1]) and pop ~= nil and commonStamp.Db > pop.Db)
			local cues = SoundConfig.Cues :: { [string]: SoundConfig.Cue }
			for index, name in Rarity.Order do
				for _, c in Reveal.Cues(Art.Rarities[name], name, index, "HaymakerStrike", length) do
					local cue = cues[c.Cue]
					local volume = if cue then SoundRule.Gain(cue) * cue.Volume * 10 ^ (c.Db / 20) else math.huge
					t.Check(`{name}'s {c.Cue} plays no louder than twice its file`, volume <= SoundConfig.Gain[2], string.format("%.2f", volume))
				end
			end
		end,
	},
	{
		Name = "Reveal: a ring takes its nearest cell, and the split's flash fades in its time",
		Run = function(t: any)
			for i, cell in Art.Rings do
				local got, size = Reveal.Ring(100, 100 * cell.Ratio)
				t.Equal(`a ring {cell.Ratio} wide takes its own cell`, got, i)
				t.Check(`drawn {cell.Radius} across a radius`, near(size, 100 / cell.Radius))
			end
			for _, name in Rarity.Order do
				local r = Art.Rarities[name]
				local split = r.Times.Split
				local flash = Reveal.At(r, split).Split
				local top = if r.Flash.Radius then r.Flash.Strength else math.min(r.Flash.Strength, RevealConfig.WholeFlash.Most)
				t.Check(`{name}: the flash at full on the split`, flash ~= nil and near(flash.Alpha, top))
				if flash and r.Flash.Radius == nil then
					-- research's TR4 fix 1: the whole screen never pure white, so the split's pieces show through
					local c = flash.Colour
					t.Check(`{name}: the whole screen's flash in its own light, not white`, math.min(c.R, c.G, c.B) < 0.95, tostring(c))
					t.Check(`{name}: and short of opaque`, flash.Alpha <= 0.9, `{flash.Alpha}`)
				end
				t.Check(`{name}: gone in its time`, Reveal.At(r, split + r.Flash.Seconds + 1e-9).Split == nil)
				t.Check(`{name}: none before`, Reveal.At(r, split - 0.001).Split == nil)
			end
			t.Check("the Mythical's flash is the whole screen", Art.Rarities.Mythical.Flash.Radius == nil)
		end,
	},
}
