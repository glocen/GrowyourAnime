--!strict
-- SignsController (client): the names a place says over itself, on the World layer (TR24's fix 10: "the Door shows no
-- name ... the gate at 35 studs has no name either"). The player's own Festival Door says where it leads, its name over
-- the arch and the ground it goes to under it (docs/design.md, "The Festival Door": "Festival of Battles", with the
-- ground under it); the festival gate says its ground's name to the side street. Plates as the machines' are (UI/World,
-- UI/Kit/Panel), kept under the top band, the door's apart from the base's machine plates. Their words and reach are
-- Config.World.Signs'.
--   SignsController.Parts()   the signs' plates, for tests

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local WorldConfig = require(Shared.Config.World)
local Grounds = require(Shared.Definitions.Grounds)
local Markers = require(Shared.World.Markers)
local UI = script.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local World = require(UI.World)
local Panel = require(UI.Kit.Panel)
local Text = require(UI.Kit.Text)

local SignsController = {}

local FIND_EVERY = 1 -- seconds between looks for the markers: they stream in, and a relaid world replaces them

type Sign = { Marker: Instance, Plate: Frame }

local player = Players.LocalPlayer
local signs: { [string]: Sign } = {}

-- The top of a marker's model: its bounding box's top middle, Lift studs over it.
local function topOf(marker: Instance, lift: number): Vector3?
	if not marker.Parent then
		return nil
	end
	if marker:IsA("Model") then
		local frame, size = marker:GetBoundingBox()
		return frame.Position + Vector3.new(0, size.Y / 2 + lift, 0)
	elseif marker:IsA("BasePart") then
		return marker.Position + Vector3.new(0, marker.Size.Y / 2 + lift, 0)
	end
	return nil
end

-- A plate of `lines` over `marker`: the first line its name, Strong; the rest under it.
local function make(name: string, marker: Instance, lines: { string }, look: any, group: string?): Frame
	local line = look.Line
	local frame = World.Plate(name, Vector2.new(look.Width, #lines * line + Theme.Size.Pad), function(): Vector3?
		return topOf(marker, look.Lift)
	end, look.Reach)
	World.Below(frame)
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

local function place(key: string, marker: Instance?, lines: { string }, look: any, group: string?)
	local sign = signs[key]
	if sign and (sign.Marker ~= marker or not sign.Marker.Parent) then
		World.Remove(sign.Plate)
		signs[key] = nil
		sign = nil
	end
	if sign == nil and marker then
		signs[key] = { Marker = marker, Plate = make(`Sign{key}`, marker, lines, look, group) }
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
	place("Door", door, { config.Door.Name, ground }, config.Door, "Base")
	place("Gate", Markers.Find("FestivalGate"), { ground }, config.Gate, nil)
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
