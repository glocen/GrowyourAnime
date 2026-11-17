--!strict
-- SignsController (client): the names a place says of itself, on the World layer (TR24's fix 10: "the Door shows no
-- name ... the gate at 35 studs has no name either"). The player's own Festival Door says where it leads, its name and
-- the ground it goes to under it (docs/design.md, "The Festival Door": "Festival of Battles", with the ground under it);
-- the festival gate says its ground's name to the side street. Plates as the machines' are (UI/World, UI/Kit/Panel),
-- kept under the top band, the door's apart from the base's machine plates. Their words and reach are
-- Config.World.Signs'.
-- A sign never covers the landmark it names, nor says again what the landmark's own plate says (research's must-fix on
-- AR15, 2026-11-17): it stands beside the landmark, level with its middle on the screen, hides wherever the HUD's
-- room sets it over the landmark (World.Clear), and the Door's steps away while the Door's own plate reads from the
-- camera. Under the top band a sign over the arch was pushed down onto the Door.
--   SignsController.Parts()        the signs' plates, for tests
--   SignsController.Aside(door)    whether a door's sign stands aside now, its plate reading, for tests
--   SignsController.Box(marker)    the landmark's box on the screen (viewport pixels), or nil, for tests

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local WorldConfig = require(Shared.Config.World)
local Grounds = require(Shared.Definitions.Grounds)
local Markers = require(Shared.World.Markers)
local UI = script.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Layers = require(UI.Layers)
local World = require(UI.World)
local Panel = require(UI.Kit.Panel)
local Text = require(UI.Kit.Text)

local SignsController = {}

local FIND_EVERY = 1 -- seconds between looks for the markers: they stream in, and a relaid world replaces them

type Sign = { Marker: Instance, Plate: Frame }

local player = Players.LocalPlayer
local signs: { [string]: Sign } = {}
local sides: { [string]: "Right" | "Left" } = {} -- the side each sign stands on, kept while it fits

-- A landmark's box on the screen, viewport pixels (the World layer's own measure), and its middle's distance from the
-- camera; nil while it's gone or any corner is behind the camera.
local function boxOf(marker: Instance): (Vector2?, Vector2?, number?)
	local camera = workspace.CurrentCamera
	if camera == nil or marker.Parent == nil then
		return nil, nil, nil
	end
	local frame: CFrame, extent: Vector3
	if marker:IsA("Model") then
		frame, extent = marker:GetBoundingBox()
	elseif marker:IsA("BasePart") then
		frame, extent = marker.CFrame, marker.Size
	else
		return nil, nil, nil
	end
	local left, top, right, bottom = math.huge, math.huge, -math.huge, -math.huge
	for _, x in { -0.5, 0.5 } do
		for _, y in { -0.5, 0.5 } do
			for _, z in { -0.5, 0.5 } do
				local at = camera:WorldToViewportPoint(frame * (extent * Vector3.new(x, y, z)))
				if at.Z <= 0 then
					return nil, nil, nil
				end
				left, top, right, bottom = math.min(left, at.X), math.min(top, at.Y), math.max(right, at.X), math.max(bottom, at.Y)
			end
		end
	end
	return Vector2.new(left, top), Vector2.new(right, bottom), (frame.Position - camera.CFrame.Position).Magnitude
end

-- Where sign `key`, `size` authored pixels, stands beside `marker`: its middle level with the landmark's on the screen,
-- Gap authored pixels off its side. On the right while it fits there: the lead's corner is top left, and a plate under it
-- is slid right, onto the landmark (the phone at 40 studs, 2026-11-17). On the left while the right has no room, back to
-- the right once it has Gap to spare, so it never flips at the edge; nil while neither side fits.
local function beside(key: string, marker: Instance, size: Vector2, gap: number): Vector3?
	local camera = workspace.CurrentCamera
	local low, high, depth = boxOf(marker)
	if camera == nil or low == nil or high == nil or depth == nil then
		return nil
	end
	local scale = Layers.Scale()
	local width, off = size.X * scale, gap * scale
	local room = camera.ViewportSize.X
	local right, left = high.X + off + width <= room, low.X - off - width >= 0
	local side = sides[key]
	if side == "Left" and high.X + 2 * off + width <= room then
		side = "Right"
	elseif side == nil or (side == "Right" and not right) or (side == "Left" and not left) then
		side = if right then "Right" elseif left then "Left" else nil
	end
	sides[key] = side
	if side == nil then
		return nil
	end
	local x = if side == "Right" then high.X + off + width / 2 else low.X - off - width / 2
	local ray = camera:ViewportPointToRay(x, (low.Y + high.Y) / 2 + size.Y * scale / 2) -- its foot: World anchors there
	return ray.Origin + ray.Direction * depth
end

-- Whether `door`'s own plate reads from the camera, so its sign on the screen stands aside (research's must-fix on AR15,
-- 2026-11-17: a screen sign never covers the landmark it names, nor says again what its own sign says): its name written,
-- the camera within the plate's Reads, in front of its face past Facing, and the plate on screen.
local function plateReads(door: Instance): boolean
	local host = door:FindFirstChild("Name")
	local camera = workspace.CurrentCamera
	if host == nil or not host:IsA("BasePart") or host:FindFirstChild("DoorName") == nil or camera == nil then
		return false
	end
	local look = WorldConfig.Signs.Door.Plate
	local toward = camera.CFrame.Position - host.Position
	if toward.Magnitude > look.Reads or toward.Magnitude < 1e-3 then
		return false
	end
	local face = host.CFrame:VectorToWorldSpace(Vector3.FromNormalId(Enum.NormalId.Back)) -- writeName's face
	if toward.Unit:Dot(face) < look.Facing then
		return false
	end
	local _, onScreen = camera:WorldToViewportPoint(host.Position)
	return onScreen
end

-- A plate of `lines` beside `marker`: the first line its name, Strong; the rest under it. Hidden while `aside(marker)`.
local function make(key: string, marker: Instance, lines: { string }, look: any, group: string?, aside: ((Instance) -> boolean)?): Frame
	local line = look.Line
	local size = Vector2.new(look.Width, #lines * line + Theme.Size.Pad)
	local frame = World.Plate(`Sign{key}`, size, function(): Vector3?
		if aside and aside(marker) then
			return nil
		end
		return beside(key, marker, size, look.Gap)
	end, look.Reach)
	World.Below(frame)
	-- and never over it, wherever the band, the lead's corner or its group set it
	World.Clear(frame, function(): (Vector2?, Vector2?)
		local low, high = boxOf(marker)
		return low, high
	end)
	-- nor over the player's own avatar: at the plot's gate, the Door's plate stood on it (AR16, 2026-11-17)
	World.Off(frame)
	if group then
		World.Apart(frame, group)
	end
	local panel = Panel.new({ Name = "Panel", Size = UDim2.fromScale(1, 1), Parent = frame })
	Panel.Pad(panel, 4, 10)
	Panel.List(panel, nil, 0)
	for index, words in lines do
		local label = Text.new({
			Name = `Line{index}`,
			Size = if index == 1 then Theme.Text.Body else Theme.Text.Caption,
			Font = if index == 1 then Theme.Font.Strong else nil,
			Colour = if index == 1 then nil else Theme.Colour.TextDim,
			Truncate = true,
			Box = UDim2.new(1, 0, 0, line),
			Parent = panel,
		})
		label.LayoutOrder = index
		label.Text = words
	end
	return frame
end

local function place(key: string, marker: Instance?, lines: { string }, look: any, group: string?, aside: ((Instance) -> boolean)?)
	local sign = signs[key]
	if sign and (sign.Marker ~= marker or not sign.Marker.Parent) then
		World.Remove(sign.Plate)
		signs[key] = nil
		sign = nil
	end
	if sign == nil and marker then
		signs[key] = { Marker = marker, Plate = make(key, marker, lines, look, group, aside) }
	end
end

-- The Door's name on its own plate (AR15, section 7), on every plot's Door: written on the face of its unseen Name,
-- toward the way in (+Z, the part's Back), once each time the part streams in.
local function writeName(door: Instance)
	local host = door:FindFirstChild("Name")
	if host == nil or not host:IsA("BasePart") or host:FindFirstChild("DoorName") then
		return
	end
	local look = WorldConfig.Signs.Door.Plate
	local gui = Instance.new("SurfaceGui")
	gui.Name = "DoorName"
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = look.PixelsPerStud
	gui.LightInfluence = 0
	gui.Brightness = look.Brightness
	gui.MaxDistance = look.Reach
	local pad = look.Pad / host.Size.Y
	local label = Instance.new("TextLabel")
	label.Name = "Words"
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.fromScale(1 - 2 * look.Pad / host.Size.X, 1 - 2 * pad)
	label.BackgroundTransparency = 1
	label.FontFace = Theme.Font.Strong
	label.TextColor3 = Color3.fromHex(look.Colour)
	label.TextScaled = true
	label.TextWrapped = true
	label.Text = WorldConfig.Signs.Door.Name
	label.Parent = gui
	gui.Parent = host
end

local function find()
	local config = WorldConfig.Signs
	local row = Grounds.ById[WorldConfig.Row.Ground]
	local ground = if row then row.Name else WorldConfig.Row.Ground
	local plot = player:GetAttribute("Plot")
	local door = if type(plot) == "number" then Markers.Find("FestivalDoor", { Plot = plot }) else nil
	for _, each in Markers.All("FestivalDoor") do
		writeName(each)
	end
	place("Door", door, { config.Door.Name, ground }, config.Door, "Base", plateReads)
	-- The gate names its ground on the screen only: the kit's gate carries no words.
	place("Gate", Markers.Find("FestivalGate"), { ground }, config.Gate, nil)
end

function SignsController.Aside(door: Instance): boolean
	return plateReads(door)
end

function SignsController.Box(marker: Instance): (Vector2?, Vector2?)
	local low, high = boxOf(marker)
	return low, high
end

function SignsController.Parts(): { [string]: Frame }
	local out: { [string]: Frame } = {}
	for key, sign in signs do
		out[key] = sign.Plate
	end
	return out
end

function SignsController.Start()
	task.spawn(function()
		while true do
			local ok, problem = pcall(find)
			if not ok then
				warn(`SignsController: {problem}`)
			end
			task.wait(FIND_EVERY)
		end
	end)
end

return SignsController
