--!strict
-- ReturnCard (client): the return card (TR53; AR55's look, build/handoff/UI/return/return.json): what the base did while
-- the player was away, from the save's Base.Card (Rules.Return), a line a change and one press. The server has already
-- credited it all; the press only shows it and lets the card go ("ReturnSeen"). The kit's System slab and pictures, a
-- line's well in AR55's cut (Config.Hud.Return.Images).
--   ReturnCard.Show(card, view, on, room?)  lays it at the HUD's right and rises; one already up is laid again in place.
--                                     room() is the height it may stand to, in points: its workers fold to fit it
--                                     (Rules.Return.Lines), and it's laid again when the HUD rescales
--   ReturnCard.Hide()                 sinks it
--   ReturnCard.Up()                   whether it stands
--   ReturnCard.Held(on)               hidden while a panel stands over its corner (the Today list: research's must-fix on
--                                     TR59), and back as it was when that closes; it still stands (Up)
--   ReturnCard.Parts()                for tests: the card, its lines' words and its press

local Shared = game:GetService("ReplicatedStorage").Shared
local HudConfig = require(Shared.Config.Hud)
local UIKit = require(Shared.Config.UIKit)
local Profile = require(Shared.Data.Profile)
local Shards = require(Shared.Definitions.Shards)
local Return = require(Shared.Rules.Return)
local Collection = require(Shared.Rules.Collection)
local Hud = require(Shared.Rules.Hud)

local UI = script.Parent
local Layers = require(UI.Layers)
local Read = require(UI.Read)
local Panel = require(UI.Kit.Panel)
local Button = require(UI.Kit.Button)
local Glass = require(UI.Kit.Glass)
local Skin = require(UI.Kit.Skin)
local Count = require(UI.Kit.Count)
local Portrait = require(UI.Kit.Portrait)
local Text = require(UI.Kit.Text)

local ReturnCard = {}

export type On = {
	Act: (name: string, args: any?) -> { [string]: any },
	Reveal: () -> (), -- a shard's among the lines: the reveal of the oldest ready
}

local R = HudConfig.Return
local SYSTEM = UIKit.Palettes.System
local FACE_OFFSET, FACE_SIZE = Vector2.new(110, 112), Vector2.new(148, 148) -- a small portrait's face, in its pixels
local COLOURS = R.Colours :: { [string]: Color3 }
local GROW = R.Picture.Grow :: { [string]: number }
local FACES: { [string]: boolean } = { Training = true, Worker = true, Workers = true } -- the lines a Voidkin's face pictures

local holder: CanvasGroup? = nil
local held = false
local up = false
local shown = "" -- the lines it stands with: the same card again is left as it is
local last: { Card: Profile.ReturnCard, View: Profile.View, On: On, Room: (() -> number?)? }? = nil -- laid again on a rescale

local function keyOf(lines: { Return.Line }): string
	local parts = {}
	for _, line in lines do
		table.insert(parts, `{line.Kind}:{line.Count}:{line.Grade or ""}:{line.Id or ""}:{line.Def or ""}:{line.More or ""}:{line.First or ""}`)
	end
	return table.concat(parts, "|")
end

local function plural(n: number, one: string, many: string): string
	return if n == 1 then one else many
end

-- A line's gain, counted to `n`, and its word.
local function format(line: Return.Line): (number) -> string
	if line.Kind == "Battery" then
		return function(n: number): string
			return `+{Read.Kwh(n)} kWh`
		end
	elseif line.Kind == "Stones" then
		return function(n: number): string
			return `+{math.floor(n + 0.5)}`
		end
	elseif line.Kind == "Training" or line.Kind == "Worker" or line.Kind == "Workers" then
		return function(n: number): string
			local whole = math.floor(n + 0.5)
			return `+{whole} {plural(line.Count, "level", "levels")}`
		end
	elseif line.Kind == "Full" then
		return function(_: number): string
			return "Full"
		end
	end
	return function(_: number): string
		return `{line.Count} {plural(line.Count, "shard", "shards")}`
	end
end

local function word(line: Return.Line, view: Profile.View): string
	if line.Kind == "Battery" then
		return "stored"
	elseif line.Kind == "Full" then
		return `+{Read.Number(line.Count)} {plural(line.Count, "Credit", "Credits")}`
	elseif line.Kind == "Stones" then
		return `{line.Grade} {plural(line.Count, "stone", "stones")}`
	elseif line.Kind == "Training" or line.Kind == "Worker" then
		local owned = if line.Id then view.Voidkin[line.Id] else nil
		return if owned then Collection.Name(owned) else ""
	elseif line.Kind == "Workers" then
		local more = line.More or 0
		return `{more} {if line.First then "" else "more "}{plural(more, "worker", "workers")}`
	end
	return "ready"
end

-- A fold of every worker (a short phone's) names its most-grown, whose face it wears: "Watt and 2 more" (research,
-- 2026-11-26). Nil on any other line; the row keeps its count ("3 workers") where the name doesn't fit beside the gain.
local function named(line: Return.Line, view: Profile.View): string?
	local owned = if line.Kind == "Workers" and line.First and line.Id then view.Voidkin[line.Id] else nil
	if owned == nil then
		return nil
	end
	local others = (line.More or 1) - 1
	return if others > 0 then `{Collection.Name(owned)} and {others} more` else Collection.Name(owned)
end

-- The line's picture in its well, centred at (cx, cy), `side` high.
local function picture(parent: GuiObject, line: Return.Line, view: Profile.View, cx: number, cy: number, side: number, z: number)
	if line.Kind == "Battery" or line.Kind == "Full" then
		Glass.Mark(parent, "Picture", HudConfig.Power.Images.Battery, cx, cy, side, Color3.new(1, 1, 1), z)
	elseif line.Kind == "Stones" then
		Skin.Icon(parent, `Stone{line.Grade}`, cx, cy, side, nil, z).Name = "Picture"
	elseif line.Kind == "Shards" then
		local def = if line.Def then Shards.ById[line.Def] else nil
		Skin.Icon(parent, Hud.ShardPicture(if def then def.Grade else "Standard", side, math.huge), cx, cy, side, nil, z).Name = "Picture"
	elseif FACES[line.Kind] then
		local owned = if line.Id then view.Voidkin[line.Id] else nil
		local image = UIKit.Images[(Portrait.Image(if owned then owned.Def else nil, true))]
		local face = Instance.new("ImageLabel")
		face.Name = "Picture"
		face.BackgroundTransparency = 1
		face.Image = if image then image.Id else ""
		face.ImageRectOffset, face.ImageRectSize = FACE_OFFSET, FACE_SIZE
		face.AnchorPoint = Vector2.new(0.5, 0.5)
		face.Position = UDim2.fromOffset(cx, cy)
		face.Size = UDim2.fromOffset(side, side)
		face.ZIndex = z
		face.Parent = parent
	end
end

function ReturnCard.Up(): boolean
	return up
end

function ReturnCard.Held(on: boolean)
	held = on
	if holder then
		holder.Visible = not on
	end
end

function ReturnCard.Hide()
	local was = holder
	holder, up, shown, last = nil, false, "", nil
	if was then
		Glass.Ease(was, R.Seconds, function(u: number)
			was.GroupTransparency = u
			was.Position = UDim2.new(1, -R.Right, 1, -R.Foot + R.Rise * u)
		end)
		task.delay(R.Seconds + 0.05, function()
			was:Destroy()
		end)
	end
end

function ReturnCard.Show(card: Profile.ReturnCard, view: Profile.View, on: On, room: (() -> number?)?)
	-- The lines its room holds at the tighter pitch, so a short phone folds its workers rather than climb the HUD.
	local tall = if room then room() else nil
	local lines = Return.Lines(card, if tall then math.max(1, math.floor((tall - R.Base) / R.Five)) else nil)
	if #lines == 0 then
		ReturnCard.Hide()
		return
	end
	local pitch = if #lines >= 5 or (tall and R.Base + #lines * R.Pitch > tall) then R.Five else R.Pitch
	local key = `{keyOf(lines)}@{pitch}`
	last = { Card = card, View = view, On = on, Room = room }
	if holder and key == shown then
		return
	end
	local again = holder ~= nil
	if holder then
		holder:Destroy()
	end
	shown = key
	local w, h = R.Wide, R.Base + #lines * pitch
	local group = Instance.new("CanvasGroup")
	group.Name = "ReturnCard"
	group.BackgroundTransparency = 1
	group.AnchorPoint = Vector2.new(1, 1)
	group.Size = UDim2.fromOffset(w, h)
	group.Position = UDim2.new(1, -R.Right, 1, -R.Foot + (if again then 0 else R.Rise))
	group.GroupTransparency = if again then 0 else 1
	group.Visible = not held
	group.Parent = Layers.Get("Hud")
	holder, up = group, true
	local slab = Panel.new({ Name = "Slab", Palette = "System", Size = UDim2.fromScale(1, 1), Parent = group })
	Glass.Label(slab, "Head", "While you were away", R.Head.Size, SYSTEM.Soft, R.Head.X, R.Head.Y, w - 2 * R.Head.X, R.Head.Size + 2, Enum.TextXAlignment.Left, false, 6)
	local seat = pitch - R.Seat.In
	for index, line in lines do
		local top = R.Top + (index - 1) * pitch
		local colour = COLOURS[line.Kind] or SYSTEM.Soft
		local row = Instance.new("Frame")
		row.Name = `Line{index}`
		row.BackgroundTransparency = 1
		row.Position = UDim2.fromOffset(0, top)
		row.Size = UDim2.fromOffset(w, pitch)
		row:SetAttribute("Kind", line.Kind)
		row.Parent = slab
		local rule = Instance.new("Frame")
		rule.Name = "Rule"
		rule.BorderSizePixel = 0
		rule.BackgroundColor3 = SYSTEM.Facet
		rule.BackgroundTransparency = R.Rule.Alpha
		rule.Position = UDim2.fromOffset(R.Rule.Inset, 0)
		rule.Size = UDim2.fromOffset(w - 2 * R.Rule.Inset, 1)
		rule.ZIndex = 6
		rule.Parent = row
		local wells = { X = R.Seat.X, Y = R.Seat.Y, Scale = seat / R.Seat.Of }
		Skin.LayOwn(row, R.Images.ReturnSeat, "Seat", { X = wells.X, Y = wells.Y, Scale = wells.Scale, Z = 6 })
		Skin.LayOwn(row, R.Images.ReturnSeatLight, "SeatLight", { X = wells.X, Y = wells.Y, Scale = wells.Scale, Tint = colour, Z = 7 })
		local side = if FACES[line.Kind] then pitch - R.Picture.Face else (pitch - R.Picture.In) * (GROW[line.Kind] or 1)
		picture(row, line, view, R.Seat.X + seat / 2, R.Seat.Y + seat / 2, side, 9)
		local gainX = R.Seat.X + seat + R.Gain.Gap
		local wordWide = w - R.Word.Right - gainX
		local show = format(line)
		local gain = Glass.Label(row, "Gain", show(line.Count), R.Gain.Size, SYSTEM.Text, gainX, (pitch - R.Gain.Size) / 2 - 1, wordWide, R.Gain.Size + 2, Enum.TextXAlignment.Left, true, 9)
		local said = Glass.Label(row, "Word", word(line, view), R.Word.Size, SYSTEM.Soft, gainX, (pitch - R.Word.Size) / 2 - 1, wordWide, R.Word.Size + 2, Enum.TextXAlignment.Right, false, 9)
		local name = named(line, view)
		if name and Text.Wide(gain, show(line.Count)) + R.Gain.Gap + Text.Wide(said, name) <= wordWide then
			said.Text = name
		end
		local counts = line.Kind == "Battery" or line.Kind == "Stones" or FACES[line.Kind] == true
		if counts and not again then
			gain.Text = show(0)
			task.delay(R.Seconds + (index - 1) * R.After, function()
				if gain.Parent then
					Count.Run(gain, 0, line.Count, show)
				end
			end)
		end
	end
	local reveal = lines[#lines].Kind == "Shards"
	local P = R.Press
	local pressed = false
	Button.new({
		Name = "Press",
		Text = if reveal then "Reveal" else "Collect",
		Size = UDim2.fromOffset(w - 2 * P.Inset, P.Tall),
		Position = UDim2.fromOffset(P.Inset, h - P.Over),
		Palette = "System",
		Primary = not reveal,
		Lit = reveal or nil,
		Light = if reveal then HudConfig.Make.Light.Ready else nil,
		TextSize = P.Size,
		Parent = slab,
		OnPress = function()
			if pressed then
				return
			end
			pressed = true
			local answer = on.Act("ReturnSeen")
			pressed = false
			-- Already seen (another press, another device): it goes all the same.
			if answer.Ok == true or answer.Error == Return.NoCard then
				if holder == group then
					ReturnCard.Hide()
				end
				if reveal then
					on.Reveal()
				end
			end
		end,
	})
	if not again then
		Glass.Ease(group, R.Seconds, function(u: number)
			group.GroupTransparency = 1 - u
			group.Position = UDim2.new(1, -R.Right, 1, -R.Foot + R.Rise * (1 - u))
		end)
	end
end

-- The HUD rescaled or resized (a turned phone, a resized window): the card's room changed, so it's laid again the
-- next frame, once the HUD's pieces stand where they will.
local relay = false
local function relaid()
	if relay then
		return
	end
	relay = true
	task.delay(0, function()
		relay = false
		local now = last
		if up and now then
			ReturnCard.Show(now.Card, now.View, now.On, now.Room)
		end
	end)
end
Layers.Changed:Connect(relaid)
Layers.Get("Hud"):GetPropertyChangedSignal("AbsoluteSize"):Connect(relaid)

function ReturnCard.Parts(): { Card: CanvasGroup?, Lines: { { Kind: string, Gain: string, Word: string } }, Press: TextButton? }
	local lines = {}
	local slab = if holder then holder:FindFirstChild("Slab") else nil
	if slab then
		for index = 1, math.huge do
			local row = slab:FindFirstChild(`Line{index}`)
			if row == nil then
				break
			end
			local gain, said = row:FindFirstChild("Gain") :: TextLabel?, row:FindFirstChild("Word") :: TextLabel?
			table.insert(lines, { Kind = row:GetAttribute("Kind") :: string, Gain = if gain then gain.Text else "", Word = if said then said.Text else "" })
		end
	end
	return { Card = holder, Lines = lines, Press = if slab then slab:FindFirstChild("Press") :: TextButton? else nil }
end

return ReturnCard
