--!strict
-- DownController (client): the marker while one of Lantern Row's elites, or this player's own keeper, is down
-- (docs/test-requests.md, TR10; the director, 2026-11-14), in grey. Over the elite while the server's timer for it runs
-- (its Elite marker's BackAt, server time, from PackService), the nearest down elite to the player when more than one of
-- the stages' three is (TR43); at the keeper's gate while this player's own runs (their
-- save's Progress.Grounds[ground].Back, Rules.Progress.Resting), the gate's Challenge hidden for them meanwhile. Each
-- shows its icon (a grey stand-in until Modulo's), its name, the time left, and a small card of its loot with each drop's
-- chance (Rules.Drops.Card, Rules.Hud.Chance): when to come back, and why. Config.Hud.Down picks the layout, tuned live;
-- Compare shows the three side by side over the elite's square, for one capture.
--   DownController.Plate(kind, layout?)   the plate of "Elite" or "Keeper" in that layout (the picked one), or nil before
--                                         it's first shown: for the self-test, with its attributes Kind, Layout, Left
--                                         (whole seconds), Lines (its card's), Chances ("1,1,0.144"), Card (shown or not)
--   DownController.Challenge()            the keeper gate's Challenge prompt, or nil

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local HudConfig = require(Shared.Config.Hud)
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

local LAYOUTS = { "Stack", "Row", "Badge" }
local KINDS = { "Elite", "Keeper" }
local LINE = 20 -- authored pixels a card's line takes
local NAME = 18 -- the name's line
local TIME = 26 -- the time's line
local PAD = 6 -- inside the plate, round its pieces
local APART = 12 -- authored pixels between plates side by side (Compare)
local FIND_EVERY = 1 -- seconds between looks for the markers: a relaid world replaces them

-- What's down, for its card: its kind for Rules.Drops, its definition, level and ground.
type What = { Kind: string, Def: string, Level: number, Ground: string }
type Plate = {
	Kind: string, -- "Elite" or "Keeper"
	Layout: string,
	Frame: Frame,
	Icon: Frame,
	Initial: TextLabel,
	Name: TextLabel,
	Time: TextLabel,
	Card: Frame,
	Key: string, -- what its card was last filled for
	Lines: number,
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

-- A name as a plate's title writes it: "the Lamplighter" is "The Lamplighter".
local function title(def: string): string
	local row = Enemies.ById[def]
	local name = if row then row.Name else def
	return string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)
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

local function make(kind: string, layout: string): Plate
	local config = HudConfig.Down
	local frame = World.Plate(`Down{kind}{layout}`, Vector2.new(config.Width, 100), function(): Vector3?
		local plate = plates[`{kind}/{layout}`]
		return if plate then plate.Point else nil
	end, config.Reach)
	World.Below(frame)
	frame:SetAttribute("Kind", kind)
	frame:SetAttribute("Layout", layout)
	local panel = Panel.new({ Name = "Panel", Size = UDim2.fromScale(1, 1), Parent = frame })
	local icon = Instance.new("Frame")
	icon.Name = "Icon"
	icon.BackgroundColor3 = Theme.Colour.PlateHigh
	icon.BorderSizePixel = 0
	icon.Parent = panel
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.25, 0)
	corner.Parent = icon
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Colour.Line
	stroke.Thickness = 1.5
	stroke.Parent = icon
	local letter = Text.new({ Name = "Initial", Size = Theme.Text.Title, Font = Theme.Font.Strong, Colour = Theme.Colour.TextDim, Align = Enum.TextXAlignment.Center, Parent = icon })
	local name = Text.new({ Name = "Name", Size = Theme.Text.Caption, Colour = Theme.Colour.TextDim, Truncate = true, Parent = panel })
	local time = Text.new({ Name = "Time", Size = Theme.Text.Title, Font = Theme.Font.Number, Parent = panel })
	local card = Instance.new("Frame")
	card.Name = "Card"
	card.BackgroundTransparency = 1
	card.Parent = panel
	local plate: Plate = {
		Kind = kind,
		Layout = layout,
		Frame = frame,
		Icon = icon,
		Initial = letter,
		Name = name,
		Time = time,
		Card = card,
		Key = "",
		Lines = 0,
		Point = nil,
	}
	plates[`{kind}/{layout}`] = plate
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
		row.Size = UDim2.new(1, 0, 0, LINE)
		row.Position = UDim2.fromOffset(0, (count - 1) * LINE)
		row.Parent = plate.Card
		local left = Text.new({ Name = "What", Size = Theme.Text.Caption, Truncate = true, Box = UDim2.new(1, -44, 1, 0), Parent = row })
		left.Text = lineText(line)
		local right = Text.new({ Name = "Chance", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Align = Enum.TextXAlignment.Right, Box = UDim2.fromScale(1, 1), Parent = row })
		right.Text = Hud.Chance(line.Chance)
		right.TextColor3 = if line.Chance >= 1 then Theme.Colour.TextDim else Theme.Colour.Ready
	end
	plate.Lines = count
	plate.Name.Text = if plate.Layout == "Row" then `{title(what.Def)} · back in` else title(what.Def)
	plate.Initial.Text = initial(what.Def)
	plate.Frame:SetAttribute("Lines", count)
	plate.Frame:SetAttribute("Chances", table.concat(chances, ","))
end

-- Lays its pieces out for its layout, the card shown or not; the plate as tall as what it holds.
local function lay(plate: Plate, card: boolean)
	local config = HudConfig.Down
	local width, size = config.Width, config.Icon
	local inner = width - 2 * PAD
	local cardHigh = if card then plate.Lines * LINE else 0
	local high: number
	plate.Name.Visible = plate.Layout ~= "Badge"
	if plate.Layout == "Row" then
		local head = math.max(size, NAME + TIME)
		plate.Icon.Size = UDim2.fromOffset(size, size)
		plate.Icon.Position = UDim2.fromOffset(PAD, PAD + (head - size) / 2)
		local beside = PAD + size + PAD
		plate.Name.Size = UDim2.fromOffset(width - beside - PAD, NAME)
		plate.Name.Position = UDim2.fromOffset(beside, PAD + (head - NAME - TIME) / 2)
		plate.Time.Size = UDim2.fromOffset(width - beside - PAD, TIME)
		plate.Time.Position = UDim2.fromOffset(beside, PAD + (head - NAME - TIME) / 2 + NAME)
		plate.Time.TextXAlignment = Enum.TextXAlignment.Left
		plate.Card.Position = UDim2.fromOffset(PAD, PAD + head + (if card then PAD else 0))
		high = PAD + head + (if card then PAD + cardHigh else 0) + PAD
	elseif plate.Layout == "Badge" then
		-- The icon, a touch larger, with the time on a strip across its foot.
		local big = size + 8
		plate.Icon.Size = UDim2.fromOffset(big, big)
		plate.Icon.Position = UDim2.fromOffset((width - big) / 2, PAD)
		plate.Time.Size = UDim2.fromOffset(inner, TIME)
		plate.Time.Position = UDim2.fromOffset(PAD, PAD + big - TIME / 2)
		plate.Time.TextXAlignment = Enum.TextXAlignment.Center
		local head = big + TIME / 2
		plate.Card.Position = UDim2.fromOffset(PAD, PAD + head + (if card then PAD else 0))
		high = PAD + head + (if card then PAD + cardHigh else 0) + PAD
	else -- Stack
		plate.Icon.Size = UDim2.fromOffset(size, size)
		plate.Icon.Position = UDim2.fromOffset((width - size) / 2, PAD)
		plate.Name.Size = UDim2.fromOffset(inner, NAME)
		plate.Name.Position = UDim2.fromOffset(PAD, PAD + size + 2)
		plate.Name.TextXAlignment = Enum.TextXAlignment.Center
		plate.Time.Size = UDim2.fromOffset(inner, TIME)
		plate.Time.Position = UDim2.fromOffset(PAD, PAD + size + 2 + NAME)
		plate.Time.TextXAlignment = Enum.TextXAlignment.Center
		local head = size + 2 + NAME + TIME
		plate.Card.Position = UDim2.fromOffset(PAD, PAD + head + (if card then PAD else 0))
		high = PAD + head + (if card then PAD + cardHigh else 0) + PAD
	end
	if plate.Layout ~= "Stack" then
		plate.Name.TextXAlignment = Enum.TextXAlignment.Left
	end
	plate.Card.Size = UDim2.fromOffset(inner, cardHigh)
	plate.Card.Visible = card
	plate.Frame.Size = UDim2.fromOffset(width, high)
	plate.Frame:SetAttribute("Card", card)
end

-- What's down now, the seconds left, and where its marker stands on the floor: the elite's square, or the keeper's gate.
local function down(kind: string, now: number): (What?, number, Vector3?)
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

local function step()
	look()
	local config = HudConfig.Down
	local now = workspace:GetServerTimeNow()
	local pick = if table.find(LAYOUTS, config.Layout) then config.Layout else "Stack"
	for _, kind in KINDS do
		local what, left, floor = down(kind, now)
		if kind == "Keeper" then
			local prompt = DownController.Challenge()
			local open = what == nil
			if prompt and prompt.Enabled ~= open then
				prompt.Enabled = open -- this player's alone: a prompt set on a client stays on it
			end
		end
		local compare = config.Compare == true and kind == "Elite"
		for index, layout in LAYOUTS do
			local wanted = what ~= nil and floor ~= nil and (layout == pick or compare)
			local plate = plates[`{kind}/{layout}`]
			if not wanted then
				if plate then
					plate.Point = nil
					plate.Frame:SetAttribute("Left", 0)
				end
				continue
			end
			local shown = plate or make(kind, layout)
			fill(shown, what :: What)
			local up = (config.Up :: any)[kind] or 10
			shown.Point = (floor :: Vector3) + Vector3.new(0, up, 0)
			lay(shown, layout ~= "Badge" or near(floor :: Vector3))
			World.Shift(shown.Frame, Vector2.new(if compare then (index - 2) * (config.Width + APART) else 0, 0))
			local clock = Hud.Clock(left)
			shown.Time.Text = clock
			shown.Frame:SetAttribute("Left", math.ceil(left - 1e-9))
		end
	end
end

function DownController.Plate(kind: string, layout: string?): Frame?
	local plate = plates[`{kind}/{layout or HudConfig.Down.Layout}`]
	return if plate then plate.Frame else nil
end

function DownController.Start()
	RunService.Heartbeat:Connect(step)
end

return DownController
