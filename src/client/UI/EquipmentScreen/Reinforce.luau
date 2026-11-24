--!strict
-- Reinforce's page (client), Equipment's first (TR47's part A; AR43, "The cut in B, for Faber": equipment.json's
-- layout.reinforce, reinforce.states and reinforce.motion; its numbers Config.Hud.Equipment.Reinforce). The chosen item
-- in its ring, its level now and after, the odds before every press (the two adding to 100), what the next level costs
-- in stones and Credits, and one press. The try is the server's: one Act, its roll the server's own. While it answers,
-- three stones fly from the pill into the ring and the ring breathes in (the anticipation). A rise flashes, sends a wave
-- and sparks out, kicks the gear and pops the level in the good (the release); a fail dulls the ring, cracks it, dims
-- and sinks the gear and shakes the work, the level staying, in the hurt (hitstop's cousin: the work jolts, nothing
-- else moves). Its state is the work's State attribute: Ready, Short (stones), Poor (Credits), Capped, Rose, Failed.
--   ReinforcePage.Build(context) -> { Paint, Stop }

local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Rules = require(Shared.Rules.Reinforce)
local Config = require(Shared.Config.Reinforce)
local Stats = require(Shared.Rules.Stats)
local Hud = require(Shared.Rules.Hud)
local HudConfig = require(Shared.Config.Hud)

local UI = script.Parent.Parent
local Read = require(UI.Read)
local Glass = require(UI.Kit.Glass)
local Skin = require(UI.Kit.Skin)
local Fade = require(UI.Kit.Fade)
local Count = require(UI.Kit.Count)
local Pop = require(UI.Kit.Pop)
local Shine = require(UI.Kit.Shine)
local Burst = require(UI.Kit.Burst)
local Text = require(UI.Kit.Text)
local Look = require(script.Parent.Look)

local ReinforcePage = {}

local E = HudConfig.Equipment
local R = E.Reinforce
local SEAM = Look.Seam
local X, Y = Look.X, Look.Y
local LIGHT = Look.Light
local WHITE = Look.White
local GOOD, HURT = E.Good, E.Hurt
local SMALL, BIG = Look.Small, Look.Big
local NOW_WIDE = 86 -- the now column's room, left of the ring's bloom: a longer stat shrinks to fit
local AFTER_WIDE = 86
local WHY: { [string]: string } = { Short = "Not enough stones", Poor = "Not enough Credits", Capped = `It's at +{Config.Cap} already` }

type Facts = { Item: Profile.OwnedItem, Level: number, Credits: number, Stones: { [string]: number }, Block: Stats.Block }
type Said = { Words: string, Colour: Color3, Strong: boolean }
type Result = { Won: boolean, Level: number, Stones: number, Grade: string, Credits: number }
type Beat = {
	Start: number,
	Answer: number?, -- seconds from the press to the answer shown
	Won: boolean?,
	From: Vector2, -- the stones' start, the pill's stone
	Stones: { ImageLabel },
	Shone: boolean,
}

-- One of the ring's images, its box's middle on the ring's.
local function centred(parent: GuiObject, image: string, side: number, tint: Color3?, alpha: number, z: number): ImageLabel
	local made = Skin.Lay(parent, image, { Name = image, Tint = tint, Alpha = alpha, Z = z })
	made.AnchorPoint = Vector2.new(0.5, 0.5)
	made.Position = UDim2.new()
	made.Size = UDim2.fromOffset(side, side)
	return made
end

-- Lit from above (equipment.json, ReinforceRing's and ReinforceRingOuter's tints): `top` held to `from`, `foot` from `to`.
local function lit(image: ImageLabel, top: number, from: number, foot: number, to: number)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, top),
		NumberSequenceKeypoint.new(from, top),
		NumberSequenceKeypoint.new(to, foot),
		NumberSequenceKeypoint.new(1, foot),
	})
	gradient.Parent = image
end

-- A circle of light round the ring's middle: its line a UIStroke, its fill the frame's own.
local function circle(parent: GuiObject, name: string, z: number): (Frame, UIStroke)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new()
	frame.ZIndex = z
	frame.Visible = false
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Transparency = 1
	stroke.Parent = frame
	frame.Parent = parent
	return frame, stroke
end

local function round(frame: Frame, stroke: UIStroke, radius: number)
	local d = 2 * radius - stroke.Thickness
	frame.Size = UDim2.fromOffset(d, d)
end

local function span(t: number, from: number, length: number): number
	return if length > 0 then math.clamp((t - from) / length, 0, 1) else (if t >= from then 1 else 0)
end

local fit = Look.Fit

local function percent(chance: number): string
	local value = chance * 100
	return if math.abs(value - math.floor(value + 0.5)) < 1e-6 then `{math.floor(value + 0.5)}%` else string.format("%.1f%%", value)
end

function ReinforcePage.Build(context: Look.Context): Look.Page
	local group = context.Group
	local id = context.Item
	local M = R.Motion
	local stopped = false
	local beat: Beat? = nil
	local result: Result? = nil
	local stepping: RBXScriptConnection? = nil

	if id == nil or (context.View :: any).Items[id] == nil then
		group:SetAttribute("State", "None")
		Look.Text(group, "None", "Wear gear on your lead to reinforce it", SMALL, SEAM.Soft, X(433), Y(180), "Centre", false, 3, 230)
		return {
			Paint = function() end,
			Stop = function() end,
		}
	end
	local itemId = id :: string

	local function factsOf(view: Profile.View): Facts?
		local data = view :: any
		local item = data.Items[itemId]
		if item == nil then
			return nil
		end
		return { Item = item, Level = item.Reinforce, Credits = data.Currency.Credits, Stones = data.Bag.Stones, Block = Look.Block(view) }
	end

	-- The name over the work, still while it shakes.
	local first = factsOf(context.View) :: Facts
	local itemName = Look.Item(first.Item)
	Look.Text(group, "Name", itemName, SMALL, Look.Rarity(first.Item.Rarity), X(R.Name.X), Y(R.Name.Y), "Centre", true, 3, 236)

	-- Everything else, in a frame a fail shakes.
	local shaker = Instance.new("Frame")
	shaker.Name = "Shaker"
	shaker.BackgroundTransparency = 1
	shaker.Size = UDim2.fromScale(1, 1)
	shaker.ZIndex = 2
	shaker.Parent = group

	-- The ring (equipment.json, layout.reinforce.ring): its bloom, the ring lit from above, its outer line, the idle's
	-- comet; the breath, the flash, the wave and the crack drawn over it when they run.
	local ring = Instance.new("Frame")
	ring.Name = "Ring"
	ring.BackgroundTransparency = 1
	ring.Size = UDim2.new()
	ring.Position = UDim2.fromOffset(X(R.Ring.X), Y(R.Ring.Y))
	ring.ZIndex = 2
	ring.Parent = shaker
	local r = R.Radius
	local bloom = centred(ring, "ReinforceBloom", 94, Look.Rarity(first.Item.Rarity), 1 - R.Bloom, 1)
	local breathGlow = centred(ring, "ReinforceWaveGlow", 80, LIGHT, 0, 2)
	breathGlow.Visible = false
	local ringImage = centred(ring, "ReinforceRing", 66, LIGHT, 1, 3)
	lit(ringImage, 0.05, 0.091, 0.65, 0.909)
	local outer = centred(ring, "ReinforceRingOuter", 66, SEAM.Facet, 1, 3)
	lit(outer, 0.35, 0.03, 0.75, 0.97)
	local comet = centred(ring, "ReinforceComet", 78, SEAM.Glint, 1, 4)
	local inner, innerStroke = circle(ring, "Inner", 5)
	inner.BackgroundColor3 = SEAM.Glint
	innerStroke.Enabled = false
	local breath, breathStroke = circle(ring, "Breath", 6)
	breathStroke.Color = LIGHT
	breathStroke.Thickness = M.Breath.Line
	-- Over the gear: a rise's flash and wave, a fail's dull light and crack.
	local over = Instance.new("Frame")
	over.Name = "Over"
	over.BackgroundTransparency = 1
	over.Size = UDim2.new()
	over.Position = ring.Position
	over.ZIndex = 9
	over.Parent = shaker
	local dull, dullStroke = circle(over, "Dull", 9)
	dull.BackgroundColor3 = M.Dull.Tint
	dullStroke.Enabled = false
	round(dull, dullStroke, M.Dull.Round)
	local flash = centred(over, "ReinforceFlash", 88, WHITE, 0, 10)
	flash.Visible = false
	local waveGlow = centred(over, "ReinforceWaveGlow", 80, GOOD, 0, 11)
	waveGlow.Name = "WaveGlow"
	waveGlow.Visible = false
	local wave, waveStroke = circle(over, "Wave", 12)
	local crackClip = Instance.new("Frame")
	crackClip.Name = "CrackClip"
	crackClip.BackgroundTransparency = 1
	crackClip.ClipsDescendants = true
	crackClip.Position = UDim2.fromOffset(-30, -18)
	crackClip.Size = UDim2.fromOffset(0, 36)
	crackClip.ZIndex = 13
	crackClip.Visible = false
	crackClip.Parent = over
	local crack = Skin.Lay(crackClip, "ReinforceCrack", { Name = "Crack", Z = 13 })
	crack.Position = UDim2.new()
	crack.Size = UDim2.fromOffset(60, 36)

	-- The gear, in the kit's cell in its rarity, over the ring: it lifts, kicks, dims and sinks.
	local gear = Instance.new("Frame")
	gear.Name = "Gear"
	gear.BackgroundTransparency = 1
	gear.AnchorPoint = Vector2.new(0.5, 0.5)
	gear.Position = UDim2.fromOffset(X(R.Ring.X), Y(R.Ring.Y))
	gear.Size = UDim2.fromOffset(R.Cell, R.Cell)
	gear.ZIndex = 7
	gear.Parent = shaker
	local lift = Instance.new("UIScale")
	lift.Name = "Lift"
	lift.Parent = gear
	local _, image, row = Look.Item(first.Item)
	local cell = Look.Cell(gear, "Cell", 0, 0, R.Cell, first.Item.Rarity, image, if row then row.Class else nil, 7)
	local picture = cell:FindFirstChild("Picture") :: ImageLabel?
	local shine = if picture then Shine.Lay(picture, SEAM.Glint) else nil
	context.Parts.ReinforceGear = gear
	context.Parts.ReinforceRing = ring

	-- The level now, at the left; its stat under it.
	Look.Text(shaker, "NowWord", "Reinforce", SMALL, SEAM.Soft, X(R.Now.X), Y(R.Now.Word), "Left", false, 3, NOW_WIDE)
	local nowLevel = Look.Text(shaker, "NowLevel", "", BIG, LIGHT, X(R.Now.X), Y(R.Now.Level), "Left", true, 3, 60)
	local home = nowLevel.Position
	local nowStat = Look.Text(shaker, "NowStat", "", SMALL, SEAM.Text, X(R.Now.X), Y(R.Now.Stat), "Left", false, 3, NOW_WIDE)
	context.Parts.ReinforceNowLevel = nowLevel
	context.Parts.ReinforceNowStat = nowStat

	local press: TextButton
	local lines: Frame? = nil
	local pressFace: Instance? = nil

	-- A level's words, its box fitted to them so it pops about their middle (Pop.Centre moves its anchor there).
	local function levelOn(label: TextLabel, words: string, colour: Color3)
		label.AnchorPoint = Vector2.zero
		label.Position = home
		label.Text = words
		label.TextColor3 = colour
		label.Size = UDim2.fromOffset(math.ceil(Text.Wide(label, words)) + 2, label.Size.Y.Offset)
	end

	local function statWords(stat: string, points: number, block: Stats.Block): string
		return `{Look.Named(stat)} {Look.Value(stat, points, block)}`
	end

	-- What it shows for `facts`: its state, the said lines, the press.
	local function stateOf(facts: Facts): (string, Rules.Cost?, number)
		local level = facts.Level + 1
		if level > Config.Cap then
			return "Capped", nil, 0
		end
		local cost = Rules.Cost(facts.Item, level)
		local have = facts.Stones[cost.Grade] or 0
		if have < cost.Stones then
			return "Short", cost, have
		elseif facts.Credits < cost.Credits then
			return "Poor", cost, have
		end
		return "Ready", cost, have
	end

	-- The next rank's lines, in a frame of their own so a result crosses to them: the level after and its stat and gain,
	-- the stone it takes, the odds, the said lines and the cost.
	local function linesOf(facts: Facts, kind: string, cost: Rules.Cost?, have: number): Frame
		local frame = Instance.new("Frame")
		frame.Name = "Lines"
		frame.BackgroundTransparency = 1
		frame.Size = UDim2.fromScale(1, 1)
		frame.ZIndex = 3
		frame.Parent = shaker
		local item = facts.Item
		local main = item.Lines[1]
		local said: { Said } = {}
		local function line(words: string, colour: Color3, strong: boolean): Said
			return { Words = words, Colour = colour, Strong = strong }
		end
		if cost then
			local level = facts.Level + 1
			Look.Text(frame, "AfterWord", "Reinforce", SMALL, SEAM.Soft, X(R.After.X), Y(R.After.Word), "Right", false, 3, AFTER_WIDE)
			Look.Text(frame, "AfterLevel", `+{level}`, BIG, LIGHT, X(R.After.X), Y(R.After.Level), "Right", true, 3, AFTER_WIDE)
			if main then
				local _, now = Rules.Gain(item, facts.Level)
				local _, after = Rules.Gain(item, level)
				local stat = main.Stat
				local afterStat = Look.Text(frame, "AfterStat", statWords(stat, main.Value + after, facts.Block), SMALL, SEAM.Text, X(R.After.X), Y(R.After.Stat), "Right", false, 3, AFTER_WIDE)
				fit(afterStat, AFTER_WIDE, SMALL)
				Look.Text(frame, "Gain", Look.Gain(stat, main.Value + now, main.Value + after, facts.Block), SMALL, GOOD, X(R.After.X), Y(R.After.Gain), "Right", true, 3, AFTER_WIDE)
			end
			Look.Cell(frame, "Stone", X(R.Stone.At.X), Y(R.Stone.At.Y), R.Stone.Side, "Common", `Stone{cost.Grade}`, nil, 3)
			Glass.Edge(frame, "StoneLine", X(R.Stone.At.X), Y(R.Stone.At.Y), R.Stone.Side, R.Stone.Side, 4, SEAM.Edge, 1, nil, 9)
			local chance = Rules.Chance(level, item.Heat) -- warmed by its failures since its last success (forge heat)
			Look.Text(frame, "Success", `Success {percent(chance)}`, SMALL, LIGHT, X(R.Odds.Success), Y(R.Odds.Y), "Right", true, 3, 110)
			Look.Text(frame, "Dot", "·", SMALL, SEAM.Faint, X(R.Odds.Dot), Y(R.Odds.Y), "Centre", false, 3, 10)
			Look.Text(frame, "Fail", `Fail {percent(1 - chance)}`, SMALL, SEAM.Soft, X(R.Odds.Fail), Y(R.Odds.Y), "Left", false, 3, 110)
			-- The cost: the stones, short in the hurt, and the Credits, short in the hurt.
			local S, C = R.Stones, R.Credits
			Glass.Fill(frame, "StonesPill", X(S[1]), Y(S[2]), S[3] - S[1], S[4] - S[2], 4, SEAM.Channel, 3)
			Glass.Edge(frame, "StonesEdge", X(S[1]), Y(S[2]), S[3] - S[1], S[4] - S[2], 4, SEAM.Edge, 1, nil, 4)
			Skin.Icon(frame, `Stone{cost.Grade}`, X(S.Picture.X + S.Side / 2), Y(S.Picture.Y + S.Side / 2), S.Side, nil, 5)
			Look.Text(frame, "StonesCount", `x{cost.Stones}`, SMALL, if have < cost.Stones then HURT else SEAM.Text, X(S.Count), Y(281), "Right", true, 5, 40)
			Glass.Fill(frame, "CreditsPill", X(C[1]), Y(C[2]), C[3] - C[1], C[4] - C[2], 4, SEAM.Channel, 3)
			Glass.Edge(frame, "CreditsEdge", X(C[1]), Y(C[2]), C[3] - C[1], C[4] - C[2], 4, SEAM.Edge, 1, nil, 4)
			Skin.Icon(frame, "CoinMint", X(C.Picture.X + C.Side / 2), Y(C.Picture.Y + C.Side / 2), C.Side, nil, 5)
			local credits = Look.Text(frame, "CreditsCount", Read.Number(cost.Credits), SMALL, if facts.Credits < cost.Credits then HURT else SEAM.Text, X(C.Count), Y(281), "Right", true, 5, 46)
			fit(credits, 46, SMALL)
			local stones = `You have {have} {cost.Grade} stones`
			if kind == "Short" then
				said = { line(`{stones}: {cost.Stones - have} short`, HURT, true), line("Shades and keepers drop them", SEAM.Soft, false) }
			elseif kind == "Poor" then
				said = { line(`Not enough Credits: {Read.Number(cost.Credits - facts.Credits)} short`, HURT, true), line(stones, SEAM.Soft, false) }
			else
				said = { line(stones, SEAM.Soft, false) }
			end
		else
			said = { line(`+{Config.Cap} is as far as it goes`, LIGHT, true), line("Every level is reached", SEAM.Soft, false) }
		end
		-- A result keeps its line over the state's first until the next press (reinforce.states).
		if result and result.Won then
			said = { line(`Reinforced to +{result.Level}`, GOOD, true), said[1] }
		elseif result then
			said = { line(`Failed: it stays at +{result.Level}`, HURT, true), line(`Spent {result.Stones} {result.Grade} stones and {Read.Number(result.Credits)} Credits`, SEAM.Soft, false) }
		end
		for k, each in said do
			local label = Look.Text(frame, `Said{k}`, each.Words, SMALL, each.Colour, X(R.Said.At.X), Y(R.Said.At.Y + (k - 1) * R.Said.Pitch), "Left", each.Strong, 3, 232)
			fit(label, 232, SMALL)
		end
		return frame
	end

	-- The whole state for `facts`, at once; a result's colour on the level and the ring, else the light.
	local function paint(facts: Facts)
		local kind, cost, have = stateOf(facts)
		local colour = if result then (if result.Won then GOOD else HURT) else LIGHT
		levelOn(nowLevel, `+{facts.Level}`, colour)
		local main = facts.Item.Lines[1]
		if main then
			local _, now = Rules.Gain(facts.Item, facts.Level)
			nowStat.Text = statWords(main.Stat, main.Value + now, facts.Block)
			fit(nowStat, NOW_WIDE, SMALL)
		else
			nowStat.Text = ""
		end
		ringImage.ImageColor3 = colour
		bloom.ImageColor3 = if result then colour else Look.Rarity(facts.Item.Rarity)
		if lines then
			lines:Destroy()
		end
		lines = linesOf(facts, kind, cost, have)
		Look.Dress(press, if kind == "Ready" then "Lit" else "Off", "Reinforce", WHY[kind])
		pressFace = Skin.Of(press):FindFirstChild("Face")
		group:SetAttribute("State", if result then (if result.Won then "Rose" else "Failed") else kind)
		group:SetAttribute("Level", facts.Level)
	end

	-- The effects' rest: nothing of a beat showing.
	local function rest()
		for _, piece in { breath, inner, flash, waveGlow, wave, crackClip, breathGlow } :: { GuiObject } do
			piece.Visible = false
		end
		dull.Visible = false
		lift.Scale = 1
		Fade.Set(cell, 1)
		shaker.Position = UDim2.new()
		if pressFace then
			Fade.Set(pressFace, 1)
		end
	end

	local function stop()
		if stepping then
			stepping:Disconnect()
			stepping = nil
		end
	end

	local function finish()
		local b = beat
		if b then
			for _, stone in b.Stones do
				stone:Destroy()
			end
		end
		beat = nil
		stop()
		rest()
		context.Busy(false)
		local latest = factsOf(context.Latest())
		if latest and not stopped then
			paint(latest)
		end
	end

	-- One frame of a beat (reinforce.motion): the stones, the breath and the lift until the answer; then the hit.
	local function step()
		local b = beat
		if b == nil or stopped then
			return
		end
		local t = os.clock() - b.Start
		local a = b.Answer
		local age = if a then t - a else -1
		-- The stones: each leaves Apart after the last, eased in along a curve from the pill up and into the ring.
		local to = Vector2.new(X(R.Ring.X), Y(R.Ring.Y))
		local bend = Vector2.new(b.From.X, to.Y)
		for k, stone in b.Stones do
			local u = (t - (k - 1) * M.Apart) / M.Fly
			stone.Visible = u > 0 and u < 1
			if stone.Visible then
				local e = u * u
				local at = (1 - e) ^ 2 * b.From + 2 * (1 - e) * e * bend + e ^ 2 * to
				local side = R.Stones.Side * (1 - 0.4 * e)
				stone.Position = UDim2.fromOffset(at.X, at.Y)
				stone.Size = UDim2.fromOffset(side, side)
				stone.ImageTransparency = if u < 0.75 then 0 else (u - 0.75) / 0.25
			end
		end
		-- The breath: a ring of light closing in on the ring while the server answers, held once in.
		local B = M.Breath
		local u = span(t, B.From, M.Least - B.From)
		local breathing = t >= B.From and (a == nil or t < a + 0.03)
		breath.Visible, inner.Visible, breathGlow.Visible = breathing, breathing, breathing
		if breathing then
			local rr = r + M.Inhale * (1 - Look.In3(u))
			round(breath, breathStroke, rr)
			breathStroke.Transparency = 1 - (B.Light[1] + B.Light[2] * u)
			breathGlow.Size = UDim2.fromOffset(80 * rr / r, 80 * rr / r)
			breathGlow.ImageTransparency = 1 - B.Glow * u
			inner.Size = UDim2.fromOffset(2 * B.Inner, 2 * B.Inner)
			inner.BackgroundTransparency = 1 - B.Fill * u
		end
		-- The press's light holds at Pending from the press's Least until the answer, then comes back.
		if pressFace then
			local least = HudConfig.Motion.Press.Least
			local dim = if t < least then 1 elseif a == nil then M.Pending else M.Pending + (1 - M.Pending) * span(t, a, M.Return)
			Fade.Set(pressFace, dim)
		end
		if a == nil then
			lift.Scale = 1 + M.Lift * Look.In3(u)
			return
		end
		local P = HudConfig.Pop
		if b.Won then
			local f = (1 - span(age, 0, M.Flash)) ^ 2
			flash.Visible = f > 0
			flash.ImageTransparency = 1 - f
			local v = age / M.WaveFor
			local waving = v < 1
			wave.Visible, waveGlow.Visible = waving, waving
			if waving then
				local W = M.Waves
				local rr = r + M.Wave * Look.Out3(v)
				waveStroke.Thickness = W.Line[1] + W.Line[2] * (1 - v)
				waveStroke.Color = WHITE:Lerp(GOOD, math.min(W.Green * v, 1))
				waveStroke.Transparency = 1 - (1 - v) ^ 1.5
				round(wave, waveStroke, rr)
				waveGlow.Size = UDim2.fromOffset(80 * rr / r, 80 * rr / r)
				waveGlow.ImageTransparency = 1 - W.Glow * (1 - v)
			end
			local seconds = P.Seconds
			lift.Scale = 1 + M.Lift * (1 - Look.Out3(span(age, 0, seconds))) + M.Kick * Hud.Pop(age / seconds, P.Peak)
			if not b.Shone and shine then
				b.Shone = true
				Shine.Play(shine)
			end
		else
			local f = (1 - span(age, 0, M.Flash)) ^ 2
			dull.Visible = f > 0
			dull.BackgroundTransparency = 1 - M.Dull.Alpha * f
			local cracking = age < M.Crack + M.CrackFade
			crackClip.Visible = cracking
			if cracking then
				crackClip.Size = UDim2.fromOffset(60 * span(age, 0, M.Crack), 36)
				crack.ImageTransparency = span(age, M.Crack, M.CrackFade)
			end
			local dim = 1 - (1 - M.Dim) * (Look.Out3(span(age, 0, M.DimIn)) - Look.Smooth(span(age, M.DimFrom, M.DimBack - M.DimFrom)))
			Fade.Set(cell, dim)
			lift.Scale = 1 + M.Lift - (M.Lift + M.Sink) * Look.Out3(span(age, 0, M.SinkIn)) + M.Sink * Look.Smooth(span(age, M.SinkFrom, M.SinkFor))
			local dx = if age < M.ShakeFor then M.Shake * math.sin(age / M.ShakeFor * 6 * math.pi) * (1 - age / M.ShakeFor) else 0
			shaker.Position = UDim2.fromOffset(dx, 0)
		end
		if age >= M.Settle then
			finish()
		end
	end

	-- The answer, shown: the cost leaves, the ring and the levels turn, the hit plays, the next lines cross in.
	local function answered(b: Beat, answer: { [string]: any }, before: Facts)
		local won = answer.Success == true
		result = { Won = won, Level = answer.Level, Stones = answer.Stones, Grade = answer.Grade, Credits = answer.Credits }
		b.Answer = os.clock() - b.Start
		b.Won = won
		local stones = table.clone(before.Stones)
		stones[answer.Grade] = math.max(0, (stones[answer.Grade] or 0) - answer.Stones)
		local after: Facts = { Item = table.clone(before.Item), Level = answer.Level, Credits = before.Credits - answer.Credits, Stones = stones, Block = before.Block }
		after.Item.Reinforce = answer.Level
		after.Item.Heat = if type(answer.Heat) == "number" and answer.Heat > 0 then answer.Heat else nil
		context.Wallet(after.Credits)
		local colour = if won then GOOD else HURT
		-- The ring, its bloom and the level by it turn over Turn, the old fading as the new shows.
		local ringFrom, bloomFrom = ringImage.ImageColor3, bloom.ImageColor3
		local old = nowLevel:Clone()
		old.Name = "OldLevel"
		old.Parent = shaker
		levelOn(nowLevel, `+{answer.Level}`, colour)
		Fade.Set(nowLevel, 0)
		Glass.Ease(ring, M.Turn, function(e: number)
			local k = Look.Out3(e)
			ringImage.ImageColor3 = ringFrom:Lerp(colour, k)
			bloom.ImageColor3 = bloomFrom:Lerp(colour, k)
			Fade.Set(nowLevel, k)
			Fade.Set(old, 1 - k)
			if e >= 1 then
				old:Destroy()
			end
		end, Enum.EasingStyle.Linear)
		local rowLevel = context.Row(colour)
		if won then
			Pop.Centre(nowLevel)
			Pop.Play(nowLevel, HudConfig.Pop.Rungs.Level)
			if rowLevel then
				Pop.Centre(rowLevel)
				Pop.Play(rowLevel, HudConfig.Pop.Rungs.Level)
			end
			local main = before.Item.Lines[1]
			if main then
				local _, now = Rules.Gain(before.Item, before.Level)
				local _, next = Rules.Gain(after.Item, after.Level)
				local stat, block = main.Stat, before.Block
				Count.Run(nowStat, main.Value + now, main.Value + next, function(n: number): string
					return statWords(stat, n, block)
				end)
			end
			Burst.Play(Vector2.new(X(R.Ring.X), Y(R.Ring.Y)), GOOD, group, M.Edge)
		end
		-- The next rank's lines cross in at Texts (a fail's at half), over Cross.
		local going = lines
		local kind, cost, have = stateOf(after)
		local coming = linesOf(after, kind, cost, have)
		Fade.Set(coming, 0)
		task.delay(if won then M.Texts else M.Texts / 2, function()
			if stopped then
				return
			end
			Glass.Ease(coming, E.Motion.Cross, function(e: number)
				local k = Look.Out3(e)
				Fade.Set(coming, k)
				if going and going.Parent then
					Fade.Set(going, 1 - k)
				end
				if e >= 1 and going then
					going:Destroy()
				end
			end, Enum.EasingStyle.Linear)
		end)
		lines = coming
		Look.Dress(press, if kind == "Ready" then "Lit" else "Off", "Reinforce", WHY[kind])
		pressFace = Skin.Of(press):FindFirstChild("Face")
		group:SetAttribute("State", if won then "Rose" else "Failed")
		group:SetAttribute("Level", answer.Level)
	end

	-- A press: one try, the server's.
	local function try(): boolean
		local facts = factsOf(context.Latest())
		if beat or stopped or facts == nil or stateOf(facts) ~= "Ready" then
			return false
		end
		result = nil
		context.Busy(true)
		context.Row(nil)
		local from = Vector2.new(X(R.Stones.Picture.X + R.Stones.Side / 2), Y(R.Stones.Picture.Y + R.Stones.Side / 2))
		local flying: { ImageLabel } = {}
		local _, cost = stateOf(facts)
		local grade = if cost then cost.Grade else "Low"
		if not GuiService.ReducedMotionEnabled then
			for k = 1, M.Stones do
				local stone = Skin.Icon(group, `Stone{grade}`, from.X, from.Y, R.Stones.Side, nil, 40)
				stone.Name = `Flying{k}`
				stone.AnchorPoint = Vector2.new(0.5, 0.5)
				stone.Visible = false
				table.insert(flying, stone)
			end
		end
		local b: Beat = { Start = os.clock(), From = from, Stones = flying, Shone = false }
		beat = b
		rest()
		stepping = RunService.RenderStepped:Connect(step)
		local answer = context.On.Act("Reinforce", { Item = itemId })
		local waited = os.clock() - b.Start
		if waited < M.Least then
			task.wait(M.Least - waited)
		end
		if stopped then
			return answer.Ok == true
		end
		if answer.Ok ~= true then
			context.On.Say(Look.Refused(answer))
			finish()
			return false
		end
		answered(b, answer, facts)
		if GuiService.ReducedMotionEnabled then
			finish()
		else
			-- The beat ends on its frames; if they stall (a hidden window draws none), its clock ends it, so the screen is
			-- never left busy.
			task.delay(M.Settle + M.Return, function()
				if beat == b and not stopped then
					finish()
				end
			end)
		end
		return true
	end

	press = Look.Press(shaker, "Press", X(R.Press[1]), Y(R.Press[2]), R.Press[3] - R.Press[1], R.Press[4] - R.Press[2], try, 8)
	context.Parts.ReinforcePress = press
	paint(first)
	rest()

	-- The opening (context.Opening): the ring draws round from the top, clockwise, and the gear grows in.
	if context.Opening and not GuiService.ReducedMotionEnabled then
		local O = E.Motion
		local halves: { UIGradient } = {}
		local copies: { ImageLabel } = {}
		ringImage.ImageTransparency, comet.ImageTransparency = 1, 1
		for k, side in { "Right", "Left" } do
			local clip = Instance.new("Frame")
			clip.Name = `Draw{side}`
			clip.BackgroundTransparency = 1
			clip.ClipsDescendants = true
			clip.Position = UDim2.fromOffset(if k == 1 then 0 else -33, -33)
			clip.Size = UDim2.fromOffset(33, 66)
			clip.ZIndex = 3
			clip.Parent = ring
			local copy = Skin.Lay(clip, "ReinforceRing", { Name = "Copy", Tint = ringImage.ImageColor3, Z = 3 })
			copy.Position = UDim2.fromOffset(if k == 1 then -33 else 0, 0)
			copy.Size = UDim2.fromOffset(66, 66)
			local gradient = Instance.new("UIGradient")
			gradient.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.499, 0),
				NumberSequenceKeypoint.new(0.501, 1),
				NumberSequenceKeypoint.new(1, 1),
			})
			gradient.Rotation = if k == 1 then 0 else 180
			gradient.Parent = copy
			table.insert(halves, gradient)
			table.insert(copies, copy)
		end
		local P = O.Pop
		lift.Scale = P.From
		Fade.Set(cell, 0)
		task.delay(P.Start, function()
			Glass.Ease(gear, P.Time, function(e: number)
				if beat == nil then
					lift.Scale = P.From + (1 - P.From) * Look.BackOut(e, P.Back)
					Fade.Set(cell, Look.Out3(math.min(1, e * 2)))
				end
			end, Enum.EasingStyle.Linear)
		end)
		task.delay(O.Ring.Start, function()
			Glass.Ease(ring, O.Ring.Time, function(e: number)
				local p = Look.Out3(e)
				halves[1].Rotation = 360 * math.min(p, 0.5)
				halves[2].Rotation = 180 + 360 * math.max(p - 0.5, 0)
				if e >= 1 then
					Glass.Ease(comet, O.Ring.Swap, function(f: number)
						ringImage.ImageTransparency = 1 - f
						comet.ImageTransparency = 1 - f
						for _, copy in copies do
							copy.ImageTransparency = f
							if f >= 1 then
								(copy.Parent :: Instance):Destroy()
							end
						end
					end, Enum.EasingStyle.Linear)
				end
			end, Enum.EasingStyle.Linear)
		end)
	end

	-- The idle: the comet round the ring, clockwise, once a loop.
	Glass.Idle(group, function(phase: number)
		comet.Rotation = 360 * phase
	end)

	return {
		Paint = function(view: Profile.View)
			local facts = factsOf(view)
			if facts and beat == nil and not stopped then
				paint(facts)
			end
		end,
		Stop = function()
			stopped = true
			stop()
			if beat then
				beat = nil
				context.Busy(false)
			end
		end,
	}
end

return ReinforcePage
