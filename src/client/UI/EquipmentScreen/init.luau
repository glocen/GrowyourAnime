--!strict
-- EquipmentScreen (client): Equipment's three screens from Home, Reinforce, Jewels and War Emblems, in Seam's lit glass
-- (TR47's part A; AR43, "The cut in B, for Faber": build/handoff/UI/equipment/equipment.json and ../seam/seam.json; its
-- numbers Config.Hud.Equipment). One full screen: the band (Back to Home, its name, the Credits and the battery), the
-- rail of the three at its left, the lead's worn gear in a list, and the chosen item's work, which is the open page's
-- (EquipmentScreen.Reinforce, .Emblems, .Jewels). The chosen row is the glass lit from its right, pointing at the work.
-- Every change is the server's, through Act (Reinforce, Socket, Unsocket), each one step with its op id.
--   EquipmentScreen.Open(page, view, on)   opens on `page`, or switches to it when open
--   EquipmentScreen.Refresh(view)          the save changed: the band, the rows and the work painted again (never mid-try)
--   EquipmentScreen.Switch(page)           a rail tap; EquipmentScreen.Choose(id) a row's: for tests
--   EquipmentScreen.State()                the open page, the chosen item and whether a try is under way: for tests
--   EquipmentScreen.Parts()                its pieces by name, for tests

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Bag = require(Shared.Rules.Bag)
local Emblems = require(Shared.Rules.Emblems)
local Sets = require(Shared.Definitions.Emblems)
local HudConfig = require(Shared.Config.Hud)
local UIKit = require(Shared.Config.UIKit)

local UI = script.Parent
local Theme = require(UI.Theme)
local Read = require(UI.Read)
local Button = require(UI.Kit.Button)
local Screen = require(UI.Kit.Screen)
local Glass = require(UI.Kit.Glass)
local Skin = require(UI.Kit.Skin)
local Fade = require(UI.Kit.Fade)
local Text = require(UI.Kit.Text)
local Count = require(UI.Kit.Count)
local Look = require(script.Look)
local ReinforcePage = require(script.Reinforce)
local EmblemsPage = require(script.Emblems)
local JewelsPage = require(script.Jewels)

local EquipmentScreen = {}
EquipmentScreen.Name = "Equipment"

export type On = Look.On

local E = HudConfig.Equipment
local B, RAIL, LIST, MOTION = E.Block, E.Rail, E.List, E.Motion
local SEAM = UIKit.Palettes.SeamGlass
local X, Y = Look.X, Look.Y
local LIGHT = Look.Light
local PAGES: { [string]: { Build: (Look.Context) -> Look.Page } } = {
	Reinforce = ReinforcePage,
	["War Emblems"] = EmblemsPage,
	Jewels = JewelsPage,
}
local BUTTONS = RAIL.Buttons :: { [string]: { any } } -- each page's rail button: its middle, its mark
local PIECES = RAIL.Pieces :: { [string]: { { number } } } -- the rail's line, in pieces, with each page open
local CHIP = { Tall = 26, Icon = 18, Digit = 8.4, Gap = 6, Every = 0.5 } -- the band's Credits and battery chips, authored

type Row = { Id: string, Button: TextButton, Plate: Frame, Scale: UIScale, Holds: Frame, Top: number }

local parts: { [string]: Instance } = {}
local rows: { Row } = {}
local state = {
	Page = E.Pages[1] :: string,
	Item = nil :: string?,
	Busy = false,
	Tint = nil :: Color3?, -- the chosen row's level after a try, a rise's or a fail's, until the next press or row
	View = nil :: Profile.View?,
	On = nil :: On?,
}
local room: Frame? = nil -- the block
local page: Look.Page? = nil -- the open work
local work: CanvasGroup? = nil -- its group
local railFaces: { [string]: Frame } = {}
local creditsShown = 0


local block, panel = Look.Room, Look.Panel

-- The lead's worn gear, in the belt's order.
local function worn(view: Profile.View): { string }
	local data = view :: any
	local slots = Bag.Worn(data, data.Voidkin[data.Roles.Lead])
	local out = {}
	for _, group in Bag.Groups do
		for _, slot in group do
			local id = slots[slot]
			if id then
				table.insert(out, id)
			end
		end
	end
	return out
end

-- The band: Back, the screen's name, then the Credits and the battery at its right (equipment.json, frame.band).
local function band(view: Profile.View)
	local bar = Screen.Band(EquipmentScreen.Name)
	if bar == nil then
		return
	end
	local title = Glass.Label(bar, "Title", "Equipment", Look.Big, SEAM.Text, Screen.BandLeft + 4, 0, 200, 0, Enum.TextXAlignment.Left, true, 3)
	title.Size = UDim2.new(0, 200, 1, 0)
	parts.Title = title
	local holder = Instance.new("Frame")
	holder.Name = "Wallet"
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(1, 0.5)
	holder.Position = UDim2.new(1, -Theme.Size.Pad, 0.5, 0)
	holder.Size = UDim2.fromOffset(0, CHIP.Tall)
	holder.Parent = bar
	parts.Wallet = holder
	local right = 0
	local function chip(name: string, icon: string, longest: number): TextLabel
		local wide = 8 + CHIP.Icon + 6 + math.ceil(longest * CHIP.Digit) + 8
		local made = Instance.new("Frame")
		made.Name = name
		made.BackgroundTransparency = 1
		made.AnchorPoint = Vector2.new(1, 0)
		made.Position = UDim2.new(1, -right, 0, 0)
		made.Size = UDim2.fromOffset(wide, CHIP.Tall)
		made.Parent = holder
		Glass.Fill(made, "Fill", 0, 0, wide, CHIP.Tall, 4, SEAM.Channel, 1)
		Glass.Edge(made, "Edge", 0, 0, wide, CHIP.Tall, 4, SEAM.Edge, 1, nil, 2)
		Skin.Icon(made, icon, 8 + CHIP.Icon / 2, CHIP.Tall / 2, CHIP.Icon, nil, 3)
		right += wide + CHIP.Gap
		local value = Glass.Label(made, "Value", "", Look.Small, SEAM.Text, 8 + CHIP.Icon + 4, 0, wide - CHIP.Icon - 20, CHIP.Tall, Enum.TextXAlignment.Right, true, 3)
		return value
	end
	local data = view :: any
	local cap = Read.Kwh(Read.Base(view, workspace:GetServerTimeNow()).Data.Base.Charge)
	local battery = chip("Electricity", "Bolt", math.max(#cap, 5))
	local credits = chip("Credits", "CoinMint", math.max(#Read.Number(data.Currency.Credits), 5))
	holder.Size = UDim2.fromOffset(right - CHIP.Gap, CHIP.Tall)
	parts.Credits = credits
	parts.Battery = battery
	creditsShown = data.Currency.Credits
	Count.Show(credits, creditsShown, Read.Number)
	local readAt = -math.huge
	local reading = RunService.Heartbeat:Connect(function()
		if os.clock() - readAt < CHIP.Every then
			return
		end
		readAt = os.clock()
		local now = state.View
		if now then
			battery.Text = Read.Kwh(Read.Base(now, workspace:GetServerTimeNow()).Data.Base.Charge)
		end
	end)
	holder.Destroying:Connect(function()
		reading:Disconnect()
	end)
end

-- The rail (seam.json, rail): a button for each page down the left, the open one grown and lit, a line between them in
-- pieces, a light running down it once a loop.
local function railFace(parent: Instance, name: string, chosen: boolean): Frame
	local def = BUTTONS[name]
	local r = if chosen then RAIL.Chosen else RAIL.Rest
	local side = 2 * (RAIL.Chosen + 24)
	local face = Instance.new("Frame")
	face.Name = `{name}Face`
	face.BackgroundTransparency = 1
	face.AnchorPoint = Vector2.new(0.5, 0.5)
	face.Position = UDim2.fromOffset(X(def[1]), Y(def[2]))
	face.Size = UDim2.fromOffset(side, side)
	face.ZIndex = 3
	face.Parent = parent
	local scale = Instance.new("UIScale")
	scale.Name = "Grow"
	scale.Parent = face
	local function lay(image: string, laid: number, tint: Color3?, alpha: number, z: number): ImageLabel
		local made = Skin.Lay(face, image, { Name = image, Tint = tint, Alpha = alpha, Z = z })
		made.AnchorPoint = Vector2.new(0.5, 0.5)
		made.Position = UDim2.fromScale(0.5, 0.5)
		made.Size = UDim2.fromOffset(laid, laid)
		return made
	end
	if chosen then
		lay("RailGlow", 2 * (r + 24), LIGHT, 1 - RAIL.Glow, 3)
	end
	local disc = lay("RailDisc", 2 * (r + 1), nil, 1, 4)
	local colours = (if chosen then SEAM.Card else SEAM.Button) :: { Color3 }
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, colours[1]),
		ColorSequenceKeypoint.new(1 / 56, colours[1]),
		ColorSequenceKeypoint.new(55 / 56, colours[2]),
		ColorSequenceKeypoint.new(1, colours[2]),
	})
	gradient.Parent = disc
	lay("RailSheen", 2 * (r + 1), SEAM.Glint, 1 - (if chosen then RAIL.Sheen.Chosen else RAIL.Sheen.Rest), 5)
	if chosen then
		lay("RailLight", 2 * (r + 1), LIGHT, 1 - RAIL.Light, 6)
		lay("RailRingChosen", 2 * (r + 4.5), LIGHT, 1, 7)
		lay("RailEdgeChosen", 2 * (r + 1), SEAM.Facet, 1 - RAIL.Edge, 8)
		local comet = lay("RailComet", 2 * (r + 4.5), SEAM.Glint, 1 - RAIL.Comet, 10)
		comet.Name = "Comet"
	else
		lay("RailRing", 2 * (r + 4.5), SEAM.Facet, 1, 7)
		lay("RailEdge", 2 * (r + 1), SEAM.Edge, 1 - RAIL.Edge, 8)
	end
	local record = UIKit.Images[def[3]] or HudConfig.Voidkin.Chrome.Images[def[3]]
	local tall = 1.05 * r
	local mark = Glass.Mark(face, "Mark", record, side / 2, side / 2, tall * record.Points.X / record.Points.Y, if chosen then SEAM.Glint else SEAM.Soft, 9)
	mark.Name = "Mark"
	face:SetAttribute("Chosen", chosen)
	return face
end

local function railWord(parent: Instance, name: string, chosen: boolean): TextLabel
	local def = BUTTONS[name]
	local r = if chosen then RAIL.Chosen else RAIL.Rest
	local size = if chosen then RAIL.Word.Chosen else RAIL.Word.Rest
	local word = Look.Text(parent, `{name}Word`, name, size, if chosen then LIGHT else SEAM.Soft, X(def[1]), Y(def[2] + r + RAIL.Word.Gap), "Centre", chosen, 3, 92)
	return word
end

local switch: (name: string) -> boolean

local function rail(parent: Frame)
	local holder = Instance.new("Frame")
	holder.Name = "Rail"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.ZIndex = 3
	holder.Parent = parent
	parts.Rail = holder
	local line = Instance.new("Frame")
	line.Name = "Line"
	line.BackgroundTransparency = 1
	line.Size = UDim2.fromScale(1, 1)
	line.ZIndex = 1
	line.Parent = holder
	for _, name in E.Pages do
		local def = BUTTONS[name]
		local button = Button.new({
			Name = `Rail{name}`,
			Text = "",
			Bare = true,
			Size = UDim2.fromOffset(92, 79),
			Position = UDim2.fromOffset(X(def[1]) - 46, Y(def[2]) - 31),
			Parent = holder,
			Still = true,
			OnPress = function(): boolean
				return switch(name)
			end,
		})
		button.ZIndex = 4
		parts[`Rail{name}`] = button
	end
end

-- The rail's line in the open page's pieces, with the runner's light clipped to each.
local function railLine()
	local holder = parts.Rail :: Frame
	local line = holder:FindFirstChild("Line") :: Frame
	line:ClearAllChildren()
	for k, piece in PIECES[state.Page] do
		local clip = Instance.new("Frame")
		clip.Name = `Piece{k}`
		clip.BackgroundTransparency = 1
		clip.ClipsDescendants = true
		clip.Position = UDim2.fromOffset(X(RAIL.X) - 2, Y(piece[1]))
		clip.Size = UDim2.fromOffset(4, piece[2] - piece[1])
		clip.ZIndex = 1
		clip.Parent = line
		local stroke = Instance.new("Frame")
		stroke.Name = "Stroke"
		stroke.BorderSizePixel = 0
		stroke.BackgroundColor3 = SEAM.Facet
		stroke.BackgroundTransparency = RAIL.Line.Alpha
		stroke.Position = UDim2.fromOffset(2 - RAIL.Line.Wide / 2, 0)
		stroke.Size = UDim2.new(0, RAIL.Line.Wide, 1, 0)
		stroke.ZIndex = 1
		stroke.Parent = clip
		local runner = Skin.Lay(clip, "RailRunner", { Name = "Runner", Tint = SEAM.Glint, Alpha = 1 - RAIL.Runner, Z = 2 })
		runner.Position = UDim2.fromOffset(0, -200)
		runner:SetAttribute("Top", piece[1])
	end
end

-- The rail's faces and words for the open page; `grow` runs the switch's grow from the last.
local function railPaint(last: string?)
	local holder = parts.Rail :: Frame
	for _, name in E.Pages do
		local chosen = name == state.Page
		local old = railFaces[name]
		local was = if old then old:GetAttribute("Chosen") == true else nil
		local word = holder:FindFirstChild(`{name}Word`)
		if old and was == chosen then
			continue
		end
		if old then
			old:Destroy()
		end
		if word then
			word:Destroy()
		end
		local face = railFace(holder, name, chosen)
		railFaces[name] = face
		local made = railWord(holder, name, chosen)
		if last ~= nil and old ~= nil then
			local from = if chosen then RAIL.Rest / RAIL.Chosen else RAIL.Chosen / RAIL.Rest
			local grow = face:FindFirstChild("Grow") :: UIScale
			grow.Scale = from
			Glass.Ease(face, MOTION.Switch, function(u: number)
				grow.Scale = from + (1 - from) * Look.BackOut(u, MOTION.Back)
			end, Enum.EasingStyle.Linear)
			Fade.Set(made, 0)
			Glass.Ease(made, MOTION.Cross, function(u: number)
				Fade.Set(made, Look.Smooth(u))
			end, Enum.EasingStyle.Linear)
		end
	end
	railLine()
end

-- A row's words under its name, the open page's (equipment.json: rowSecond, rowHolds). Returns Reinforce's level, which
-- a rise pops.
local function holds(row: Row, view: Profile.View, colour: Color3?): TextLabel?
	local frame = row.Holds
	frame:ClearAllChildren()
	local tint = colour or (if row.Id == state.Item then state.Tint else nil)
	local data = view :: any
	local item = data.Items[row.Id]
	if item == nil then
		return nil
	end
	local L = LIST
	if state.Page == "Reinforce" then
		local word = Look.Text(frame, "Word", "Reinforce", Look.Small, SEAM.Soft, L.Name[1], L.Holds, "Left", false, 1, 80)
		local x = L.Name[1] + math.ceil(Text.Wide(word, "Reinforce")) + 3
		local words = `+{item.Reinforce}`
		local level = Look.Text(frame, "Level", words, Look.Small, tint or LIGHT, x, L.Holds, "Left", true, 1, 40)
		level.Size = UDim2.fromOffset(math.ceil(Text.Wide(level, words)) + 2, level.Size.Y.Offset)
		return level
	elseif state.Page == "War Emblems" then
		local first = 161 - LIST.Box[1]
		for k, key in item.Sockets do
			local cx, cy = first + (k - 1) * 22, 32
			local parsed = if key ~= "" then Emblems.Parse(key) else nil
			if parsed then
				local picture = Skin.Icon(frame, parsed.Set.Image, cx, cy, 22, nil, 1)
				picture.Name = `Emblem{k}`
			else
				local empty = Skin.Icon(frame, "RowEmptyEmblem", cx, cy, 16, SEAM.Faint, 1)
				empty.ImageTransparency = E.Socket.RowEmblem
				empty.Name = `Empty{k}`
			end
		end
	else
		local first = 160 - LIST.Box[1]
		for k, colourName in E.Jewels.Order do
			local level = item.Jewels[colourName]
			local cx, cy = first + (k - 1) * 20, 32
			if level then
				local picture = Skin.Icon(frame, `Jewel{colourName}{level}`, cx, cy, 18, nil, 1)
				picture.Name = `Jewel{colourName}`
			else
				local ring = Skin.Icon(frame, "RowEmptyJewel", cx, cy, 12, E.Jewels.Colours[colourName], 1)
				ring.ImageTransparency = E.Socket.RowJewel
				ring.Name = `Empty{colourName}`
			end
		end
	end
	return nil
end

local function rowOf(id: string?): Row?
	for _, row in rows do
		if row.Id == id then
			return row
		end
	end
	return nil
end

-- The chosen row's glass (equipment.json, rowImages), one marker gliding from row to row.
local function markerMade(parent: Instance): Frame
	local L = LIST
	local w, h = L.Box[2] - L.Box[1], L.Tall
	local marker = Instance.new("Frame")
	marker.Name = "Marker"
	marker.BackgroundTransparency = 1
	marker.Size = UDim2.fromOffset(w, h)
	marker.ZIndex = 1
	marker.Parent = parent
	Skin.Lay(marker, "RowGlassGlow", { Name = "Glow", X = -21, Y = -21, W = w + 42, H = h + 42, Tint = LIGHT, Alpha = 1 - L.Glow, Z = 1 })
	Skin.Lay(marker, "RowGlass", { Name = "Glass", W = w, H = h, Z = 2 })
	local wash = Skin.Lay(marker, "RowGlassWash", { Name = "Wash", Tint = LIGHT, Alpha = 1 - L.Wash, Z = 3 })
	wash.Size = UDim2.fromOffset(w, h)
	wash.Position = UDim2.new()
	local clip = Instance.new("Frame")
	clip.Name = "GlintClip"
	clip.BackgroundTransparency = 1
	clip.ClipsDescendants = true
	clip.Size = UDim2.fromOffset(w, h)
	clip.ZIndex = 4
	clip.Parent = marker
	local glint = Skin.Lay(clip, "RowGlint", { Name = "Glint", Tint = SEAM.Glint, Alpha = 1 - L.Glint, Z = 4 })
	glint.Position = UDim2.fromOffset(-200, 0)
	Skin.Lay(marker, "RowEdge", { Name = "Edge", X = -1, Y = -1, W = w + 2, H = h + 2, Tint = SEAM.Facet, Alpha = 1 - L.EdgeChosen, Z = 5 })
	Skin.Lay(marker, "RowGlassLight", { Name = "Light", X = w - 11, Y = -10, Tint = LIGHT, Z = 6 })
	Skin.Lay(marker, "RowPoint", { Name = "Point", X = w, Y = 14, Tint = LIGHT, Z = 7 })
	return marker
end

local choose: (id: string, touch: boolean?) -> boolean

-- The list: the lead's worn gear, a row each, scrolling inside its panel; three layers, so the marker glides between
-- the rows' plates and their words.
local function list(parent: Frame, view: Profile.View)
	local L = LIST
	local old = parent:FindFirstChild("List")
	if old then
		old:Destroy()
	end
	table.clear(rows)
	local ids = worn(view)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "List"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 0
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	scroll.Position = UDim2.fromOffset(X(L.Panel[1]), Y(L.Panel[2]))
	scroll.Size = UDim2.fromOffset(L.Panel[3] - L.Panel[1] + 12, L.Panel[4] - L.Panel[2]) -- the point stands past the panel
	scroll.CanvasSize = UDim2.fromOffset(0, L.First - L.Panel[2] + #ids * L.Pitch)
	scroll.ZIndex = 4
	scroll.Parent = parent
	parts.List = scroll
	local layers: { [string]: Frame } = {}
	for z, name in { "Plates", "Glass", "Rows" } do
		local layer = Instance.new("Frame")
		layer.Name = name
		layer.BackgroundTransparency = 1
		layer.Size = UDim2.fromScale(1, 1)
		layer.ZIndex = z
		layer.Parent = scroll
		layers[name] = layer
	end
	local marker = markerMade(layers.Glass)
	marker.Visible = false
	parts.Marker = marker
	local data = view :: any
	local w, h = L.Box[2] - L.Box[1], L.Tall
	for k, id in ids do
		local item = data.Items[id]
		local top = L.First - L.Panel[2] + (k - 1) * L.Pitch
		local x0 = L.Box[1] - L.Panel[1]
		local plate = Instance.new("Frame")
		plate.Name = `Plate{k}`
		plate.BackgroundTransparency = 1
		plate.AnchorPoint = Vector2.new(0.5, 0.5)
		plate.Position = UDim2.fromOffset(x0 + w / 2, top + h / 2)
		plate.Size = UDim2.fromOffset(w, h)
		plate.Parent = layers.Plates
		local squeeze = Instance.new("UIScale")
		squeeze.Parent = plate
		Skin.Lay(plate, "RowPlate", { Name = "Plate", W = w, H = h, Z = 1 })
		Skin.Lay(plate, "RowEdge", { Name = "Edge", X = -1, Y = -1, W = w + 2, H = h + 2, Tint = SEAM.Edge, Z = 2 })
		local button = Button.new({
			Name = `Row{k}`,
			Text = "",
			Bare = true,
			Size = UDim2.fromOffset(w, h),
			Position = UDim2.fromOffset(x0, top),
			Parent = layers.Rows,
			OnPress = function(): boolean
				return choose(id, true)
			end,
		})
		button:SetAttribute("Item", id)
		local face = Instance.new("Frame")
		face.Name = "Face"
		face.BackgroundTransparency = 1
		face.Size = UDim2.fromScale(1, 1)
		face.Parent = Skin.Of(button)
		local name, image, row = Look.Item(item)
		Look.Cell(face, "Cell", L.Cell[1], L.Cell[2], L.Cell[3], item.Rarity, image, if row then row.Class else nil, 2)
		Look.Text(face, "Name", name, Look.Small, SEAM.Text, L.Name[1], L.Name[2], "Left", true, 3, w - L.Name[1] - 4)
		local held = Instance.new("Frame")
		held.Name = "Holds"
		held.BackgroundTransparency = 1
		held.Size = UDim2.fromScale(1, 1)
		held.ZIndex = 3
		held.Parent = face
		local entry: Row = { Id = id, Button = button, Plate = plate, Scale = squeeze, Holds = held, Top = top }
		table.insert(rows, entry)
		holds(entry, view)
	end
	if #ids == 0 then
		local said = Look.Text(layers.Rows, "None", "Your lead wears no gear yet", Look.Small, SEAM.Soft, (L.Panel[3] - L.Panel[1]) / 2, 20, "Centre", false, 3, 190)
		said.TextWrapped = true
	end
end

-- The work: a group over the work's panel holding the open page, `how` it comes in: "Open", "Row" (a row tapped) or
-- "Dip" (a rail tap).
local function workIn(how: string)
	local made = room
	local view = state.View
	local on = state.On
	if made == nil or view == nil or on == nil then
		return
	end
	local old, oldPage = work, page
	if oldPage then
		oldPage.Stop()
	end
	local group = Instance.new("CanvasGroup")
	group.Name = "Work"
	group.BackgroundTransparency = 1
	group.Size = UDim2.fromOffset(B.Wide, B.Tall)
	group.ZIndex = 5
	group.GroupTransparency = 1
	work = group
	parts.Work = group
	local context: Look.Context = {
		Group = group,
		View = view,
		Item = state.Item,
		On = on,
		Parts = parts,
		Opening = how == "Open",
		Latest = function(): Profile.View
			return state.View or view
		end,
		Row = function(colour: Color3?): TextLabel?
			state.Tint = colour
			local row = rowOf(state.Item)
			return if row then holds(row, state.View or view, colour) else nil
		end,
		Busy = function(busy: boolean)
			state.Busy = busy
		end,
		Wallet = function(credits: number)
			local label = parts.Credits :: TextLabel?
			if label then
				Count.Run(label, creditsShown, credits, Read.Number)
				creditsShown = credits
			end
		end,
	}
	page = PAGES[state.Page].Build(context)
	group.Parent = made
	if how == "Open" then
		task.delay(MOTION.WorkStart, function()
			Glass.Ease(group, MOTION.WorkTime, function(u: number)
				group.GroupTransparency = 1 - Look.Out3(u)
			end, Enum.EasingStyle.Linear)
		end)
	elseif how == "Row" then
		group.Position = UDim2.fromOffset(MOTION.Slide, 0)
		Glass.Ease(group, MOTION.Enter, function(u: number)
			local e = Look.Out3(u)
			group.GroupTransparency = 1 - e
			group.Position = UDim2.fromOffset(MOTION.Slide * (1 - e), 0)
		end, Enum.EasingStyle.Linear)
	else
		local half = MOTION.Cross / 2
		task.delay(half, function()
			Glass.Ease(group, half, function(u: number)
				group.GroupTransparency = 1 - Look.Smooth(u)
			end, Enum.EasingStyle.Linear)
		end)
	end
	if old then
		local going = old
		local seconds = if how == "Row" then MOTION.Leave else MOTION.Cross / 2
		local from = going.GroupTransparency
		Glass.Ease(going, seconds, function(u: number)
			local e = Look.Smooth(u)
			going.GroupTransparency = from + (1 - from) * e
			if how == "Row" then
				going.Position = UDim2.fromOffset(-MOTION.Slide * e, 0)
			end
			if u >= 1 then
				going:Destroy()
			end
		end, Enum.EasingStyle.Linear)
	end
end

-- The marker to the chosen row: gliding, or there at once.
local function mark(glide: boolean)
	local marker = parts.Marker :: Frame?
	local row = rowOf(state.Item)
	if marker == nil then
		return
	end
	marker.Visible = row ~= nil
	for _, each in rows do
		each.Plate.Visible = each ~= row
	end
	if row == nil then
		return
	end
	local to = UDim2.fromOffset(LIST.Box[1] - LIST.Panel[1], row.Top)
	if glide then
		TweenService:Create(marker, TweenInfo.new(MOTION.Glide, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), { Position = to }):Play()
	else
		marker.Position = to
	end
end

choose = function(id: string, touch: boolean?): boolean
	if state.Busy or room == nil then
		return false
	end
	if id == state.Item then
		return true
	end
	local glide = state.Item ~= nil
	state.Item = id
	state.Tint = nil
	local view = state.View
	if view then
		for _, row in rows do
			holds(row, view)
		end
	end
	mark(glide)
	workIn("Row")
	return true
end

switch = function(name: string): boolean
	if state.Busy or room == nil or PAGES[name] == nil then
		return false
	end
	if name == state.Page then
		return true -- the open one: nothing
	end
	local last = state.Page
	state.Page = name
	state.Tint = nil
	railPaint(last)
	local view = state.View
	if view then
		for _, row in rows do
			holds(row, view)
			Fade.Set(row.Holds, 0)
			local held = row.Holds
			Glass.Ease(held, MOTION.Cross, function(u: number)
				Fade.Set(held, Look.Smooth(u))
			end, Enum.EasingStyle.Linear)
		end
	end
	workIn("Dip")
	return true
end

-- The opening: each row slides in from the left after the last; the band and the rail are there from the start.
local function rowsIn()
	local L = LIST
	local x0 = L.Box[1] - L.Panel[1]
	local w, h = L.Box[2] - L.Box[1], L.Tall
	for k, row in rows do
		local button, plate = row.Button, row.Plate
		local marker = if row.Id == state.Item then parts.Marker :: Frame? else nil
		local function at(e: number)
			local dx = -MOTION.RowFrom * (1 - e)
			button.Position = UDim2.fromOffset(x0 + dx, row.Top)
			plate.Position = UDim2.fromOffset(x0 + w / 2 + dx, row.Top + h / 2)
			Fade.Set(button, e)
			Fade.Set(plate, e)
			if marker then
				marker.Position = UDim2.fromOffset(x0 + dx, row.Top)
				Fade.Set(marker, e)
			end
		end
		at(0)
		task.delay(MOTION.RowStart + (k - 1) * MOTION.RowGap, function()
			Glass.Ease(button, MOTION.RowTime, function(u: number)
				at(Look.Out3(u))
			end, Enum.EasingStyle.Linear)
		end)
	end
end

-- The idle (seam.json, idle): one phase for the rail's comet and runner and the chosen row's glint; the plates
-- squeeze with their rows.
local function idle(phase: number)
	local comet = railFaces[state.Page] and railFaces[state.Page]:FindFirstChild("Comet") :: ImageLabel?
	if comet then
		comet.Rotation = 360 * phase
	end
	local line = (parts.Rail :: Frame):FindFirstChild("Line")
	if line then
		local y = 66 + (306 - 66) * phase
		for _, clip in line:GetChildren() do
			local runner = clip:FindFirstChild("Runner") :: ImageLabel?
			local top = if runner then runner:GetAttribute("Top") else nil
			if runner and type(top) == "number" then
				runner.Position = UDim2.fromOffset(0, y - top - 48)
			end
		end
	end
	local marker = parts.Marker :: Frame?
	local glint = if marker then marker:FindFirstChild("GlintClip") and (marker:FindFirstChild("GlintClip") :: Frame):FindFirstChild("Glint") :: ImageLabel? else nil
	if glint then
		local w = LIST.Box[2] - LIST.Box[1]
		local at = -40 + (w + 80) * phase
		glint.Position = UDim2.fromOffset(at - 27, 0)
	end
end

local function squeeze()
	for _, row in rows do
		row.Scale.Scale = Button.Squeeze(row.Button)
	end
end

function EquipmentScreen.Open(name: string, view: Profile.View, on: On)
	local wanted = if PAGES[name] then name else E.Pages[1]
	state.View, state.On = view, on
	if Screen.Current() == EquipmentScreen.Name and room and room.Parent then
		switch(wanted)
		return
	end
	if page then
		page.Stop()
		page = nil
	end
	table.clear(parts)
	table.clear(railFaces)
	state.Page, state.Busy, state.Tint = wanted, false, nil
	local body = Screen.Full(EquipmentScreen.Name, "Equipment", "SeamGlass")
	parts.Body = body
	Glass.Ground(body, 1)
	local made = block(body)
	made.ZIndex = 2
	room = made
	work = nil
	parts.Block = made
	local bloom = E.Bloom
	Glass.Bloom(made, "Bloom", X(bloom.At.X), Y(bloom.At.Y), bloom.Size.X, bloom.Size.Y, bloom.Tint, 1 - bloom.Alpha, 1)
	band(view)
	panel(made, "ListPanel", LIST.Panel, 2)
	panel(made, "WorkPanel", E.Work, 2)
	rail(made)
	railPaint(nil)
	list(made, view)
	local ids = worn(view)
	state.Item = if state.Item and table.find(ids, state.Item) then state.Item else ids[1]
	mark(false)
	rowsIn()
	workIn("Open")
	Glass.Idle(made, idle)
	local squeezing = RunService.RenderStepped:Connect(squeeze)
	made.Destroying:Connect(function()
		squeezing:Disconnect()
		if page then
			page.Stop()
			page = nil
		end
	end)
end

function EquipmentScreen.Refresh(view: Profile.View)
	state.View = view
	local made = room
	if Screen.Current() ~= EquipmentScreen.Name or made == nil or made.Parent == nil or state.Busy then
		return
	end
	local label = parts.Credits :: TextLabel?
	local data = view :: any
	if label then
		creditsShown = data.Currency.Credits
		Count.Show(label, creditsShown, Read.Number)
	end
	local ids = worn(view)
	local same = #ids == #rows
	for k, row in rows do
		same = same and ids[k] == row.Id
	end
	if not same then
		list(made, view)
		if state.Item == nil or table.find(ids, state.Item) == nil then
			state.Item = ids[1]
			mark(false)
			workIn("Row")
			return
		end
		mark(false)
	else
		for _, row in rows do
			holds(row, view)
		end
	end
	if page then
		page.Paint(view)
	end
end

function EquipmentScreen.Switch(name: string): boolean
	return switch(name)
end

function EquipmentScreen.Choose(id: string): boolean
	return choose(id)
end

function EquipmentScreen.State(): { Page: string, Item: string?, Busy: boolean }
	return { Page = state.Page, Item = state.Item, Busy = state.Busy }
end

function EquipmentScreen.Parts(): { [string]: Instance }
	return parts
end

-- The twelve War Emblems' sets, for the page's tests.
EquipmentScreen.Sets = Sets

return EquipmentScreen
