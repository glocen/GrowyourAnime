--!strict
-- War Emblems' page (client), Equipment's third (TR47's part A; AR43, "The cut in B, for Faber": equipment.json's
-- layout.emblems and presses; numbers Config.Hud.Equipment.Emblems). The chosen item's sockets, as many as its rarity
-- gives, centred under its name: each holds an emblem, its points and its stat, or stands empty. Under the rule, the
-- bag's emblems in a row, highest rarity first (or by stat), each stack with its count. Choose a socket, then an
-- emblem: the one lit press puts it in or replaces the one there (which goes back to the bag); a socket chosen alone
-- with one in it takes it out. Both free, the server's (Socket, Unsocket), frozen in a fight. A press with nothing to do
-- stands off and says why on a tap. An emblem put in pops in its socket and shines. The heading row's Combine pill
-- (TR56) folds three of the chosen emblem's stat and rarity into one of the next rarity, the server's (Combine; the
-- made one's set its roll), and the made one's stack is chosen and pops; off, it says why.
--   EmblemsPage.Build(context) -> { Paint, Stop }

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Emblems = require(Shared.Rules.Emblems)
local Sets = require(Shared.Definitions.Emblems)
local Chests = require(Shared.Config.Chests)
local EmblemsConfig = require(Shared.Config.Emblems)
local Stats = require(Shared.Rules.Stats)
local HudConfig = require(Shared.Config.Hud)

local UI = script.Parent.Parent
local Read = require(UI.Read)
local Glass = require(UI.Kit.Glass)
local Skin = require(UI.Kit.Skin)
local Button = require(UI.Kit.Button)
local Pop = require(UI.Kit.Pop)
local Shine = require(UI.Kit.Shine)
local Look = require(script.Parent.Look)
local Jewels = require(script.Parent.Jewels)

local EmblemsPage = {}

local E = HudConfig.Equipment
local M = E.Emblems
local SEAM = Look.Seam
local X, Y = Look.X, Look.Y
local SMALL = Look.Small
local SAID_WIDE = 140 -- from the said lines' left to the press's
local SORTS = { "Rarity", "Stat" }

type Entry = { Key: string, Set: Sets.Row, Stat: string, Points: number, Count: number }

local function rank(rarity: string): number
	return table.find(Chests.Rarities, rarity) or 0
end

local function setOrder(id: string): number
	for k, row in Sets.List do
		if row.Id == id then
			return k
		end
	end
	return math.huge
end

-- The bag's emblems, a stack each, in the sort's order: by rarity, highest first, then the sets' order and the stat;
-- or by stat, then rarity.
local function bagOf(view: Profile.View, sort: string): { Entry }
	local entries: { Entry } = {}
	for key, count in (view :: any).Bag.Emblems do
		local parsed = Emblems.Parse(key)
		if parsed and count > 0 then
			local stat, points = Emblems.Points(key)
			table.insert(entries, { Key = key, Set = parsed.Set, Stat = stat or parsed.Stat, Points = points, Count = count })
		end
	end
	table.sort(entries, function(a: Entry, b: Entry): boolean
		local ra, rb = rank(a.Set.Rarity), rank(b.Set.Rarity)
		if sort == "Stat" and a.Stat ~= b.Stat then
			return a.Stat < b.Stat
		end
		if ra ~= rb then
			return ra > rb
		end
		if a.Set.Id ~= b.Set.Id then
			return setOrder(a.Set.Id) < setOrder(b.Set.Id)
		end
		return a.Stat < b.Stat
	end)
	return entries
end

-- An emblem's points as players read them: "+12", "+1.5%".
local function points(stat: string, value: number, block: Stats.Block): string
	return Look.Gain(stat, 0, value, block)
end

function EmblemsPage.Build(context: Look.Context): Look.Page
	local group = context.Group
	local id = context.Item
	local stopped = false
	local busy = false
	local chosenSocket: number? = nil
	local chosenKey: string? = nil
	local sort = SORTS[1]
	local scrollAt = 0
	local content: Frame? = nil
	local paint: (view: Profile.View, popped: number?) -> ()

	if id == nil or (context.View :: any).Items[id] == nil then
		group:SetAttribute("State", "None")
		Look.Text(group, "None", "Wear gear on your lead to set emblems in it", SMALL, SEAM.Soft, X(433), Y(180), "Centre", false, 3, 230)
		return {
			Paint = function() end,
			Stop = function() end,
		}
	end
	local itemId = id :: string

	local first = (context.View :: any).Items[itemId] :: Profile.OwnedItem
	chosenSocket = table.find(first.Sockets, "") or 1
	local name = Look.Item(first)
	Look.Text(group, "Name", name, SMALL, Look.Rarity(first.Rarity), X(M.Name.X), Y(M.Name.Y), "Centre", true, 3, 236)
	Jewels.Rule(group, M.Rule.Y, M.Rule.Ends, M.Rule.Alpha)
	Look.Text(group, "Heading", "Your emblems", SMALL, SEAM.Soft, X(M.Heading.X), Y(M.Heading.Y), "Left", false, 3, 150)

	-- One change, the server's; the page waits on it, and the screen keeps its row and page until it answers.
	local function act(name: string, args: { [string]: any }, popAt: number?): boolean
		if busy or stopped then
			return false
		end
		busy = true
		context.Busy(true)
		local answer = context.On.Act(name, args)
		busy = false
		context.Busy(false)
		if stopped then
			return answer.Ok == true
		end
		if answer.Ok ~= true then
			context.On.Say(Look.Refused(answer))
			paint(context.Latest())
			return false
		end
		chosenKey = nil
		paint(context.Latest(), popAt)
		context.Row(nil)
		return true
	end

	-- Three of the chosen emblem's stat and rarity into one of the next: its stack is chosen after, and pops.
	local poppedKey: string? = nil
	local function combine(rarity: string, stat: string): boolean
		if busy or stopped then
			return false
		end
		busy = true
		context.Busy(true)
		local answer = context.On.Act("Combine", { Rarity = rarity, Stat = stat })
		busy = false
		context.Busy(false)
		if stopped then
			return answer.Ok == true
		end
		if answer.Ok ~= true then
			context.On.Say(Look.Refused(answer))
			paint(context.Latest())
			return false
		end
		chosenKey = if type(answer.Emblem) == "string" then answer.Emblem else nil
		poppedKey = chosenKey
		context.On.Say(`{EmblemsConfig.Combine.Take} {Look.Named(stat)} emblems → 1 {answer.Rarity}`)
		paint(context.Latest())
		poppedKey = nil
		return true
	end

	paint = function(view: Profile.View, popped: number?)
		local data = view :: any
		local item = data.Items[itemId] :: Profile.OwnedItem?
		if item == nil then
			return
		end
		local block = Look.Block(view)
		local bag = bagOf(view, sort)
		local found = false
		for _, entry in bag do
			found = found or entry.Key == chosenKey
		end
		if not found then
			chosenKey = nil
		end
		if chosenSocket == nil or item.Sockets[chosenSocket] == nil then
			chosenSocket = 1
		end
		if content then
			local old = content:FindFirstChild("Bag") :: ScrollingFrame?
			if old then
				scrollAt = old.CanvasPosition.X
			end
			content:Destroy()
		end
		local frame = Instance.new("Frame")
		frame.Name = "Content"
		frame.BackgroundTransparency = 1
		frame.Size = UDim2.fromScale(1, 1)
		frame.ZIndex = 3
		frame.Parent = group
		content = frame
		-- The sockets, centred under the name.
		local S = M.Sockets
		local n = #item.Sockets
		local left = S.Middle - (n - 1) * S.Pitch / 2 - S.Side / 2
		for k, key in item.Sockets do
			local x = left + (k - 1) * S.Pitch
			local parsed = if key ~= "" then Emblems.Parse(key) else nil
			local chosen = k == chosenSocket
			local button = Look.Press(frame, `Socket{k}`, X(x), Y(S.Top), S.Side, S.Side, function(): boolean
				if busy then
					return false
				end
				chosenSocket = k
				paint(context.Latest())
				return true
			end, 4)
			local skin = Skin.Of(button)
			local colour = if parsed then Look.Rarity(parsed.Set.Rarity) else nil
			local socket = Look.Socket(skin, "Socket", 0, 0, S.Side, colour, colour, chosen, 1)
			if parsed then
				local picture = Skin.Icon(socket, parsed.Set.Image, S.Side / 2, S.Side / 2, S.Side - 2, nil, 6)
				picture.Name = "Emblem"
				local stat, value = Emblems.Points(key)
				local said = stat or parsed.Stat
				Look.Text(frame, `Value{k}`, points(said, value, block), SMALL, SEAM.Text, X(x + S.Side / 2), Y(S.Top + S.Value), "Centre", true, 3, 56)
				for j, word in Look.Lines(said) do
					Look.Text(frame, `Stat{k}_{j}`, word, SMALL, SEAM.Soft, X(x + S.Side / 2), Y(S.Top + S.Stat + (j - 1) * S.StatPitch), "Centre", false, 3, 60)
				end
				if popped == k then
					Pop.Centre(button)
					Pop.Play(button, HudConfig.Pop.Rungs.Credits)
					Shine.Play(Shine.Lay(picture, SEAM.Glint))
				end
			else
				local mark = Skin.Icon(socket, "SocketEmptyEmblem", S.Side / 2, S.Side / 2, 28, SEAM.Faint, 6)
				mark.ImageTransparency = E.Socket.EmptyEmblem
				Look.Text(frame, `Value{k}`, "Empty", SMALL, SEAM.Faint, X(x + S.Side / 2), Y(S.Top + S.Value), "Centre", false, 3, 56)
			end
			button:SetAttribute("Emblem", key)
			button:SetAttribute("Chosen", chosen)
		end
		-- The sort's pill: a tap turns it to the next sort.
		local P = M.Sort
		local pw, ph = P[3] - P[1], P[4] - P[2]
		local pill = Look.Press(frame, "Sort", X(P[1]), Y(P[2] + ph / 2 - 22), pw, 44, function(): boolean
			if busy then
				return false
			end
			sort = SORTS[(table.find(SORTS, sort) or 1) % #SORTS + 1]
			scrollAt = 0
			paint(context.Latest())
			return true
		end, 4)
		local face = Skin.Of(pill)
		Glass.Fill(face, "Fill", 0, 22 - ph / 2, pw, ph, 4, SEAM.Button[1], 1)
		Glass.Edge(face, "Edge", 0, 22 - ph / 2, pw, ph, 4, SEAM.Edge, 1, nil, 2)
		Glass.Label(face, "Words", sort, 12, SEAM.Text, 0, 0, pw, 44, nil, true, 3)
		pill:SetAttribute("Sort", sort)
		-- The combine's pill: lit while the chosen emblem's stat and rarity are held three times and a rarity sits above.
		local chosenParsed = if chosenKey then Emblems.Parse(chosenKey) else nil
		local held = if chosenParsed then Emblems.Held(data, chosenParsed.Set.Rarity, chosenParsed.Stat) else 0
		local above = if chosenParsed then Emblems.Above(chosenParsed.Set.Rarity) else nil
		local cKind, cWhy = "Off", "Choose an emblem below"
		if chosenParsed and above == nil then
			cWhy = "Legendary is the top"
		elseif chosenParsed and held < EmblemsConfig.Combine.Take then
			cWhy = `Combining takes {EmblemsConfig.Combine.Take}: {held} held`
		elseif chosenParsed then
			cKind, cWhy = "Lit", nil
		end
		local CP = M.Combine
		local cw, ch = CP[3] - CP[1], CP[4] - CP[2]
		local combinePill = Look.Press(frame, "Combine", X(CP[1]), Y(CP[2] + ch / 2 - 22), cw, 44, function(): boolean
			local parsed = chosenParsed
			if cKind ~= "Lit" or parsed == nil then
				return false
			end
			return combine(parsed.Set.Rarity, parsed.Stat)
		end, 4)
		local cFace = Skin.Of(combinePill)
		Glass.Fill(cFace, "Fill", 0, 22 - ch / 2, cw, ch, 4, if cKind == "Lit" then SEAM.Button[1] else SEAM.Channel, 1)
		Glass.Edge(cFace, "Edge", 0, 22 - ch / 2, cw, ch, 4, if cKind == "Lit" then SEAM.Edge else SEAM.Faint, 1, nil, 2)
		Glass.Label(cFace, "Words", "Combine", 12, if cKind == "Lit" then SEAM.Text else SEAM.Faint, 0, 0, cw, 44, nil, true, 3)
		combinePill:SetAttribute("Ready", cKind == "Lit") -- its own name: the kit keeps Kind for its button's make
		combinePill:SetAttribute("Why", cWhy or "")
		Button.Set(combinePill, { Disabled = if cKind == "Off" then cWhy or "Not now" else false }) -- the kit says why on a tap
		context.Parts.EmblemsCombine = combinePill
		-- The bag's row, scrolling sideways inside the panel's edge.
		local B = M.Bag
		local scroll = Instance.new("ScrollingFrame")
		scroll.Name = "Bag"
		scroll.BackgroundTransparency = 1
		scroll.BorderSizePixel = 0
		scroll.ScrollBarThickness = 0
		scroll.ScrollBarImageTransparency = 1 -- Roblox draws its own thumb even at nought
		scroll.ScrollingDirection = Enum.ScrollingDirection.X
		scroll.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
		scroll.Position = UDim2.fromOffset(X(B.Clip[1]), Y(B.Top - 4))
		scroll.Size = UDim2.fromOffset(B.Clip[2] - B.Clip[1], B.Side + 8)
		scroll.CanvasSize = UDim2.fromOffset(math.max(B.Clip[2] - B.Clip[1], B.First - B.Clip[1] + #bag * B.Pitch), 0)
		scroll.ZIndex = 4
		scroll.Parent = frame
		for k, entry in bag do
			local x = B.First - B.Clip[1] + (k - 1) * B.Pitch
			local chosen = entry.Key == chosenKey
			local button = Look.Press(scroll, `Bag{k}`, x, 4, B.Side, B.Side, function(): boolean
				if busy then
					return false
				end
				chosenKey = if chosenKey == entry.Key then nil else entry.Key
				paint(context.Latest())
				return true
			end, 2)
			local skin = Skin.Of(button)
			if chosen then
				Skin.Lay(skin, "SocketGlow", { Name = "Glow", X = -19.5, Y = -19.5, W = B.Side + 39, H = B.Side + 39, Tint = Look.Light, Alpha = 1 - E.Socket.Glow, Z = 1 })
			end
			local cell = Look.Cell(skin, "Cell", 0, 0, B.Side, entry.Set.Rarity, entry.Set.Image, nil, 2)
			cell.ZIndex = 2
			if chosen then
				Skin.Lay(skin, "SocketEdgeLit", { Name = "Lit", X = -1.5, Y = -1.5, W = B.Side + 3, H = B.Side + 3, Tint = Look.Light, Z = 8 })
			end
			if entry.Count > 1 then
				local chip = Instance.new("Frame")
				chip.Name = "Count"
				chip.BorderSizePixel = 0
				chip.BackgroundColor3 = SEAM.Channel
				chip.Position = UDim2.fromOffset(18, 25)
				chip.Size = UDim2.fromOffset(20.5, 13.5)
				chip.ZIndex = 9
				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0, 3)
				corner.Parent = chip
				chip.Parent = skin
				Glass.Label(chip, "Number", Read.Number(entry.Count), 11, SEAM.Text, 0, 0, 20.5, 13.5, nil, true, 10)
			end
			button:SetAttribute("Emblem", entry.Key)
			button:SetAttribute("Chosen", chosen)
			if poppedKey == entry.Key then
				Pop.Centre(button)
				Pop.Play(button, HudConfig.Pop.Rungs.Credits)
				Shine.Play(Shine.Lay(cell, SEAM.Glint))
			end
		end
		if #bag == 0 then
			Look.Text(frame, "BagNone", "No emblems yet: Shades and keepers drop them", SMALL, SEAM.Faint, X(B.First), Y(B.Top + 12), "Left", false, 3, 230)
		end
		scroll.CanvasPosition = Vector2.new(math.min(scrollAt, math.max(0, scroll.CanvasSize.X.Offset - scroll.Size.X.Offset)), 0)
		-- What's chosen, in two lines, and the one press.
		local key = item.Sockets[chosenSocket :: number]
		local shownKey = chosenKey or (if key ~= "" then key else nil)
		local A = M.Said.At
		if shownKey then
			local parsed = Emblems.Parse(shownKey)
			local stat, value = Emblems.Points(shownKey)
			if parsed then
				local one = Look.Text(frame, "Said1", `{parsed.Set.Name} · {parsed.Set.Rarity}`, SMALL, Look.Rarity(parsed.Set.Rarity), X(A.X), Y(A.Y), "Left", true, 3, SAID_WIDE)
				Look.Fit(one, SAID_WIDE, SMALL)
				local said = stat or parsed.Stat
				local two = Look.Text(frame, "Said2", `{Look.Named(said)} {points(said, value, block)}`, SMALL, SEAM.Text, X(A.X), Y(A.Y + M.Said.Pitch), "Left", false, 3, SAID_WIDE)
				Look.Fit(two, SAID_WIDE, SMALL)
			end
		else
			Look.Text(frame, "Said1", "Choose an emblem", SMALL, SEAM.Soft, X(A.X), Y(A.Y), "Left", false, 3, SAID_WIDE)
			Look.Text(frame, "Said2", "for the lit socket", SMALL, SEAM.Faint, X(A.X), Y(A.Y + M.Said.Pitch), "Left", false, 3, SAID_WIDE)
		end
		local R = M.Press
		local kind, words, why = "Off", "Put in", "Choose an emblem below"
		local doing: () -> boolean = function(): boolean
			return false
		end
		local socket = chosenSocket :: number
		if chosenKey then
			local wanted = chosenKey :: string
			kind, words, why = "Lit", if key == "" then "Put in" else "Replace", nil
			doing = function(): boolean
				return act("Socket", { Item = itemId, Socket = socket, Emblem = wanted }, socket)
			end
		elseif key ~= "" then
			kind, words, why = "Lit", "Take out", nil
			doing = function(): boolean
				return act("Unsocket", { Item = itemId, Socket = socket })
			end
		end
		local wide = if words == "Take out" then R.Out else R.Put
		local press = Look.Press(frame, "Press", X(R.Right - wide), Y(R.Top), wide, R.Foot - R.Top, doing, 6)
		Look.Dress(press, kind, words, why)
		context.Parts.EmblemsPress = press
		context.Parts.EmblemsBag = scroll
		group:SetAttribute("State", if kind == "Lit" then words else "Choose")
		group:SetAttribute("Socket", chosenSocket)
		group:SetAttribute("Chosen", chosenKey or "")
	end

	paint(context.View)

	return {
		Paint = function(view: Profile.View)
			if not busy and not stopped then
				paint(view)
			end
		end,
		Stop = function()
			stopped = true
			if busy then
				busy = false
				context.Busy(false)
			end
		end,
	}
end

return EmblemsPage
