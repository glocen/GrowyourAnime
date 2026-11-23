--!strict
-- DownController (client): the marker while one of Lantern Row's elites, or this player's own keeper, is down
-- (docs/test-requests.md, TR10; the director, 2026-11-14). Over the elite while the server's timer for it runs (its
-- Elite marker's BackAt, server time, from PackService), the nearest down elite to the player when more than one of the
-- stages' three is (TR43); at the keeper's gate while this player's own runs (their save's Progress.Grounds[ground].Back,
-- Rules.Progress.Resting), the gate's Challenge hidden for them meanwhile.
-- Badge, research's pick (TR10, 2026-11-23, 16:41): far, its icon (Modulo's picture, its row's Marker, on the tile; the
-- name's letter for a row without one) with the time left on the tile's foot, and nothing round them (must-fix 2). Near,
-- a card of its loot with each drop's chance (Rules.Drops.Card, Rules.Hud.Chance) unfolds from the tile, the tile held
-- still: when to come back, and why. It takes its size from the world (must-fix 1; Config.Hud.Down).
--   DownController.Plate(kind)            the plate of "Elite" or "Keeper", or nil before it's first shown: for the
--                                         self-test, with its attributes Kind, Left (whole seconds), Lines (its card's),
--                                         Chances ("1,1,0.144"), Picture, Size (its world size, 1 today's), Unfold (its
--                                         card's, 0 folded to 1 whole) and Card (whole)
--   DownController.Challenge()            the keeper gate's Challenge prompt, or nil
--   DownController.Try(kind, what?, left?, floor?)  the self-test's and its takes' only: stands `kind`'s marker for
--                                         `what` ({ Kind, Def, Level, Ground }) over `floor`, `left` seconds, as if it
--                                         were down there, where the world has no square or gate (the main place); nil
--                                         lets the world say again

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local HudConfig = require(Shared.Config.Hud)
local UIKit = require(Shared.Config.UIKit)
local WorldConfig = require(Shared.Config.World)
local Enemies = require(Shared.Definitions.Enemies)
local Markers = require(Shared.World.Markers)
local Cooldown = require(Shared.Rules.Cooldown)
local Progress = require(Shared.Rules.Progress)
local Drops = require(Shared.Rules.Drops)
local Hud = require(Shared.Rules.Hud)
local Parts = require(Shared.Util.Parts)
local PlaceRole = require(Shared.Util.PlaceRole)
local UI = script.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Read = require(UI.Read)
local World = require(UI.World)
local Panel = require(UI.Kit.Panel)
local Text = require(UI.Kit.Text)
local ProfileController = require(script.Parent.Parent.Core.ProfileController)

local DownController = {}

local player = Players.LocalPlayer

local KINDS = { "Elite", "Keeper" }
local LINE = 20 -- authored pixels a card's line takes, at least
local PAD = 6 -- inside the plate, round its pieces
local MARGIN = 16 -- round the card's group: the panel's shadow stands past it (UIKit's PanelShadow, its Pad)
local OUTLINE = 2 -- the time's dark outline, authored: it reads over the street with no panel behind it
local FIND_EVERY = 1 -- seconds between looks for the markers: a relaid world replaces them

-- What's down, for its card: its kind for Rules.Drops, its definition, level and ground.
type What = { Kind: string, Def: string, Level: number, Ground: string }
type Plate = {
	Kind: string, -- "Elite" or "Keeper"
	Frame: Frame,
	Size: UIScale, -- its size from the world
	Back: CanvasGroup, -- the card's panel and its lines, fading as they unfold
	Icon: Frame,
	Initial: TextLabel,
	Picture: ImageLabel,
	Time: TextLabel,
	Card: Frame, -- the window its lines show through, as tall as it has unfolded
	Rows: { Frame },
	Words: { TextLabel }, -- the card's labels
	Key: string, -- what its card was last filled for
	Lines: number,
	Unfold: number, -- the card's, 0 folded to 1 whole, before its ease
	Point: Vector3?, -- where it stands now, or nil while hidden
}

local plates: { [string]: Plate } = {}
local found: { [string]: Instance? } = {}
local elites: { Instance } = {}
local lookedAt = -math.huge

local function marker(name: string): Instance?
	local m = found[name]
	if m and m.Parent then
		return m
	end
	return nil
end

local function look()
	-- The street's markers stream in, so each frame looks again until they're all found; the base's place has none to
	-- find (TR45), so it looks only every FIND_EVERY.
	local whole = not PlaceRole.Is("Festival") or (elites[1] and elites[1].Parent and marker("KeeperGate") and marker("Ring"))
	if os.clock() - lookedAt < FIND_EVERY and whole then
		return
	end
	lookedAt = os.clock()
	for _, name in { "KeeperGate", "Ring" } do
		found[name] = Markers.Find(name)
	end
	elites = Markers.All("Elite")
end

-- The gate's Challenge: KeeperService's own part at the gate's foot.
function DownController.Challenge(): ProximityPrompt?
	local folder = workspace:FindFirstChild("Keeper")
	local holder = if folder then folder:FindFirstChild("Challenge") else nil
	return if holder then holder:FindFirstChildOfClass("ProximityPrompt") else nil
end

-- The stand-in icon's letter: the name's first, past "the ".
local function initial(def: string): string
	local row = Enemies.ById[def]
	local name = string.gsub(if row then row.Name else def, "^[Tt]he%s+", "")
	return string.upper(string.sub(name, 1, 1))
end

local function lineText(line: Drops.Line): string
	if line.Kind == "Credits" then
		return `Credits {Hud.Digits(line.Amount)}`
	elseif line.Kind == "Xp" then
		return `Experience {Hud.Digits(line.Amount)}`
	end
	return Read.ShardName(line.Shard)
end

local function make(kind: string): Plate
	local config = HudConfig.Down
	local frame = World.Plate(`Down{kind}`, Vector2.new(config.Icon, config.Icon), function(): Vector3?
		local plate = plates[kind]
		return if plate then plate.Point else nil
	end, config.Reach)
	-- Its world size, made before World.Below so the band's rule reads it (a plate's UIScale, grown from its foot). Open:
	-- it stands over its square between the band's pieces, only stepping from one it would cross. Held under the whole
	-- band, it stood on the avatar's head from the game's camera at any distance (TR10's walk, 2026-11-23).
	local size = Instance.new("UIScale")
	size.Name = "WorldSize"
	size.Parent = frame
	World.Below(frame, true)
	frame:SetAttribute("Kind", kind)
	-- The card: its panel and its lines in one group, past the plate by MARGIN for the panel's shadow.
	local back = Instance.new("CanvasGroup")
	back.Name = "Back"
	back.BackgroundTransparency = 1
	back.Position = UDim2.fromOffset(-MARGIN, -MARGIN)
	back.Size = UDim2.new(1, 2 * MARGIN, 1, 2 * MARGIN)
	back.GroupTransparency = 1
	back.Visible = false
	back.ZIndex = 1
	back.Parent = frame
	Panel.new({ Name = "Panel", Position = UDim2.fromOffset(MARGIN, MARGIN), Size = UDim2.new(1, -2 * MARGIN, 1, -2 * MARGIN), Parent = back })
	local card = Instance.new("Frame")
	card.Name = "Card"
	card.BackgroundTransparency = 1
	card.ClipsDescendants = true
	card.ZIndex = 2
	card.Parent = back
	local icon = Instance.new("Frame")
	icon.Name = "Icon"
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.Position = UDim2.new(0.5, 0, 0, PAD)
	icon.BackgroundColor3 = Theme.Colour.PlateHigh
	icon.BorderSizePixel = 0
	icon.ZIndex = 2
	icon.Parent = frame
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.25, 0)
	corner.Parent = icon
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Colour.Line
	stroke.Thickness = 1.5
	stroke.Parent = icon
	local letter = Text.new({ Name = "Initial", Size = Theme.Text.Title, Font = Theme.Font.Strong, Colour = Theme.Colour.TextDim, Align = Enum.TextXAlignment.Center, Parent = icon })
	-- Its picture fills the tile over the tile's own colour, clipped to its corner, never tinted (TR10's content check,
	-- condition 4: nothing pushes the elite's red further)
	local picture = Instance.new("ImageLabel")
	picture.Name = "Picture"
	picture.BackgroundTransparency = 1
	picture.Size = UDim2.fromScale(1, 1)
	picture.ScaleType = Enum.ScaleType.Fit
	picture.Visible = false
	picture.ZIndex = letter.ZIndex + 1
	picture.Parent = icon
	local clip = Instance.new("UICorner")
	clip.CornerRadius = corner.CornerRadius
	clip.Parent = picture
	-- The time across the tile's foot, outlined: far, nothing stands behind its lower half but the street.
	local time = Text.new({ Name = "Time", Size = Theme.Text.Title, Font = Theme.Font.Number, Align = Enum.TextXAlignment.Center, Parent = frame })
	time.AnchorPoint = Vector2.new(0.5, 0.5)
	time.ZIndex = 3
	local outline = Instance.new("UIStroke")
	outline.Color = Theme.Colour.Channel
	outline.Thickness = OUTLINE
	outline.Parent = time
	local plate: Plate = {
		Kind = kind,
		Frame = frame,
		Size = size,
		Back = back,
		Icon = icon,
		Initial = letter,
		Picture = picture,
		Time = time,
		Card = card,
		Rows = {},
		Words = {},
		Key = "",
		Lines = 0,
		Unfold = 0,
		Point = nil,
	}
	plates[kind] = plate
	return plate
end

-- Its card's lines for `what`, each drop's name and amount left, its chance right.
local function fill(plate: Plate, what: What)
	local key = `{what.Kind}|{what.Def}|{what.Level}|{what.Ground}`
	if plate.Key == key then
		return
	end
	plate.Key = key
	plate.Card:ClearAllChildren()
	table.clear(plate.Rows)
	table.clear(plate.Words)
	local chances = {}
	local count = 0
	for _, line in Drops.Card(what.Kind, what.Level, what.Ground) do
		if line.Chance <= 0 then
			continue
		end
		count += 1
		table.insert(chances, tostring(line.Chance))
		local row = Instance.new("Frame")
		row.Name = `Line{count}`
		row.BackgroundTransparency = 1
		row.AnchorPoint = Vector2.new(0.5, 0)
		row.Parent = plate.Card
		local left = Text.new({ Name = "What", Size = Theme.Text.Caption, Truncate = true, Box = UDim2.new(1, -44, 1, 0), Parent = row })
		left.Text = lineText(line)
		local right = Text.new({ Name = "Chance", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Align = Enum.TextXAlignment.Right, Box = UDim2.fromScale(1, 1), Parent = row })
		right.Text = Hud.Chance(line.Chance)
		right.TextColor3 = if line.Chance >= 1 then Theme.Colour.TextDim else Theme.Colour.Ready
		table.insert(plate.Rows, row)
		table.insert(plate.Words, left)
		table.insert(plate.Words, right)
	end
	plate.Lines = count
	plate.Initial.Text = initial(what.Def)
	local row = Enemies.ById[what.Def]
	local image = if row and row.Marker then UIKit.Images[row.Marker] else nil
	plate.Picture.Image = if image then image.Id else ""
	plate.Picture.Visible = image ~= nil
	plate.Initial.Visible = image == nil
	plate.Frame:SetAttribute("Picture", if image and row then row.Marker else "")
	plate.Frame:SetAttribute("Lines", count)
	plate.Frame:SetAttribute("Chances", table.concat(chances, ","))
end

-- A label authored at `authored` in a plate drawn at `size` of today's: large enough to read at Theme.Text.Minimum on
-- the smallest phone (Text.Legible, at the floor's scale times the plate's), the same on every screen, so the marker
-- keeps the phone's proportions and a take on the phone's frame shows them.
local function legible(authored: number, size: number): number
	return math.max(authored, math.ceil(Theme.Text.Minimum / (Theme.Scale.Floor * size)))
end

local function sized(label: TextLabel, want: number)
	if label.TextSize ~= want then
		label.TextSize = want
	end
end

local function easeOut(x: number): number
	local k = math.clamp(x, 0, 1)
	return 1 - (1 - k) * (1 - k)
end

-- Lays its pieces out at `size` of today's, its card unfolded by `k` (0 folded to 1 whole). Far, the tile and its time
-- alone, the plate as wide as the wider. As it unfolds, the panel grows from round them to the card's width and down
-- over its lines, fading in. The tile stays where it stood: the plate is shifted down by what it grew.
local function lay(plate: Plate, size: number, k: number)
	local config = HudConfig.Down
	local side = config.Icon
	plate.Size.Scale = size
	local timeSize, wordSize = legible(Theme.Text.Title, size), legible(Theme.Text.Caption, size)
	sized(plate.Time, timeSize)
	sized(plate.Initial, timeSize)
	for _, label in plate.Words do
		sized(label, wordSize)
	end
	local tall = timeSize + 6
	local wide = math.max(side, Text.Wide(plate.Time, plate.Time.Text) + 2 * OUTLINE + 2)
	local head = PAD + side + tall / 2
	local line = math.max(LINE, wordSize + 3)
	local lines = plate.Lines * line
	local folded = wide + 2 * PAD
	local whole = math.max(config.Width, folded)
	local width = folded + (whole - folded) * k
	local grown = (PAD + lines) * k
	plate.Frame.Size = UDim2.fromOffset(width, head + grown + PAD)
	plate.Icon.Size = UDim2.fromOffset(side, side)
	plate.Time.Size = UDim2.fromOffset(wide, tall)
	plate.Time.Position = UDim2.new(0.5, 0, 0, PAD + side)
	-- The card's window inside the panel: its lines centred in it at their whole width, shown as far as it has grown.
	plate.Card.Position = UDim2.fromOffset(MARGIN + PAD, MARGIN + head + PAD)
	plate.Card.Size = UDim2.fromOffset(width - 2 * PAD, lines * k)
	for index, row in plate.Rows do
		row.Position = UDim2.new(0.5, 0, 0, (index - 1) * line)
		row.Size = UDim2.fromOffset(whole - 2 * PAD, line)
	end
	plate.Back.Visible = k > 0
	plate.Back.GroupTransparency = 1 - k
	World.Shift(plate.Frame, Vector2.new(0, grown * size))
	plate.Frame:SetAttribute("Size", size)
	plate.Frame:SetAttribute("Unfold", k)
	plate.Frame:SetAttribute("Card", k >= 1)
end

local tries: { [string]: { What: What, Left: number, Floor: Vector3 } } = {}

-- What's down now, the seconds left, and where its marker stands on the floor: the elite's square, or the keeper's gate.
local function down(kind: string, now: number): (What?, number, Vector3?)
	local try = tries[kind]
	if try then
		return try.What, try.Left, try.Floor
	end
	if kind == "Elite" then
		-- The down elite nearest the player.
		local root = Parts.Root(player.Character)
		local elite: Instance?, left, nearest = nil, 0, math.huge
		for _, each in elites do
			local backAt = each:GetAttribute("BackAt")
			local its = if each.Parent then Cooldown.Left(if type(backAt) == "number" then backAt else nil, now, "Elite") else 0
			local away = if root then (Markers.At(each).Position - root.Position).Magnitude else 0
			if its > 0 and away < nearest then
				elite, left, nearest = each, its, away
			end
		end
		if elite == nil then
			return nil, 0, nil
		end
		local def, level, ground = elite:GetAttribute("Def"), elite:GetAttribute("Level"), elite:GetAttribute("Ground")
		if left <= 0 or type(def) ~= "string" or type(level) ~= "number" then
			return nil, 0, nil
		end
		local what: What = { Kind = "Elite", Def = def, Level = level, Ground = if type(ground) == "string" then ground else WorldConfig.Row.Ground }
		return what, left, Markers.At(elite).Position
	end
	local gate, ring = marker("KeeperGate"), marker("Ring")
	local view = ProfileController.Get()
	if gate == nil or ring == nil or view == nil then
		return nil, 0, nil
	end
	local def, level, ground = ring:GetAttribute("Def"), ring:GetAttribute("Level"), ring:GetAttribute("Ground")
	if type(def) ~= "string" or type(level) ~= "number" or type(ground) ~= "string" then
		return nil, 0, nil
	end
	-- The save keeps os.time(); the server's time here is the same clock.
	local left = Progress.Resting(view, ground, now)
	if left <= 0 then
		return nil, 0, nil
	end
	return { Kind = "Keeper", Def = def, Level = level, Ground = ground }, left, Markers.At(gate).Position
end

-- Whether the avatar stands within Near studs, flat, of a floor point.
local function near(point: Vector3): boolean
	local root = Parts.Root(player.Character)
	if root == nil then
		return false
	end
	local gap = root.Position - point
	return Vector2.new(gap.X, gap.Z).Magnitude <= HudConfig.Down.Near
end

-- Its size `away` studs from the camera: today's within Full, Full / away past it, never under Least's floor.
local function worldSize(away: number): number
	local config = HudConfig.Down
	local least = math.min(1, config.Least / (config.Icon * Theme.Scale.Floor))
	return math.clamp(config.Full / math.max(away, 1e-3), least, 1)
end

local function step(dt: number)
	look()
	local config = HudConfig.Down
	local now = workspace:GetServerTimeNow()
	local camera = workspace.CurrentCamera
	for _, kind in KINDS do
		local what, left, floor = down(kind, now)
		if kind == "Keeper" then
			local prompt = DownController.Challenge()
			local open = what == nil
			if prompt and prompt.Enabled ~= open then
				prompt.Enabled = open -- this player's alone: a prompt set on a client stays on it
			end
		end
		local plate = plates[kind]
		if what == nil or floor == nil then
			if plate then
				plate.Point = nil
				plate.Unfold = 0 -- shown again, it starts folded
				plate.Frame:SetAttribute("Left", 0)
			end
			continue
		end
		local shown = plate or make(kind)
		fill(shown, what)
		local up = (config.Up :: any)[kind] or 10
		local point = floor + Vector3.new(0, up, 0)
		shown.Point = point
		local want = if near(floor) then 1 else 0
		local rate = if config.Unfold > 0 then dt / config.Unfold else 1
		shown.Unfold = if want > shown.Unfold then math.min(want, shown.Unfold + rate) else math.max(want, shown.Unfold - rate)
		shown.Time.Text = Hud.Clock(left)
		lay(shown, worldSize(if camera then (point - camera.CFrame.Position).Magnitude else config.Full), easeOut(shown.Unfold))
		shown.Frame:SetAttribute("Left", math.ceil(left - 1e-9))
	end
end

function DownController.Plate(kind: string): Frame?
	local plate = plates[kind]
	return if plate then plate.Frame else nil
end

function DownController.Try(kind: string, what: What?, left: number?, floor: Vector3?)
	tries[kind] = if what and left and floor then { What = what, Left = left, Floor = floor } else nil
end

function DownController.Start()
	RunService.Heartbeat:Connect(step)
end

return DownController
