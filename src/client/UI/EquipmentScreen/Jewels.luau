--!strict
-- Jewels' page (client), Equipment's second: in part A only its five slots, empty and marked as coming (TR47's part A:
-- "The Jewels page shows its five empty slots, marked as coming"; part B, the jewels themselves, waits on the director).
-- Laid as the cut's (AR43, "The cut in B, for Faber"; equipment.json, layout.jewels): the item's name, a socket a colour
-- in the colours' order, each in its colour with its empty ring and a faint "-", the rule, and two lines saying what
-- comes. Its presses stand off, saying so on a tap.
--   JewelsPage.Build(context) -> { Paint, Stop }

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local HudConfig = require(Shared.Config.Hud)

local UI = script.Parent.Parent
local Skin = require(UI.Kit.Skin)
local Look = require(script.Parent.Look)

local JewelsPage = {}

local E = HudConfig.Equipment
local J = E.Jewels
local SEAM = Look.Seam
local X, Y = Look.X, Look.Y
local SMALL = Look.Small
local COMING = "Jewels are coming"

-- The rule under the sockets: a hairline in the facet.
local function rule(parent: Instance, y: number, ends: { number }, alpha: number)
	local line = Instance.new("Frame")
	line.Name = "Rule"
	line.BorderSizePixel = 0
	line.BackgroundColor3 = SEAM.Facet
	line.BackgroundTransparency = alpha
	line.Position = UDim2.fromOffset(X(ends[1]), Y(y))
	line.Size = UDim2.fromOffset(ends[2] - ends[1], 1)
	line.ZIndex = 2
	line.Parent = parent
end
JewelsPage.Rule = rule

function JewelsPage.Build(context: Look.Context): Look.Page
	local group = context.Group
	local id = context.Item
	local item = if id then (context.View :: any).Items[id] else nil
	group:SetAttribute("State", "Coming")
	if item then
		local name = Look.Item(item)
		Look.Text(group, "Name", name, SMALL, Look.Rarity(item.Rarity), X(433), Y(66), "Centre", true, 3, 236)
	end
	local S = J.Sockets
	for k, colour in J.Order do
		local tint = J.Colours[colour]
		local x, y = S.First.X + (k - 1) * S.Pitch, S.First.Y
		local socket = Look.Socket(group, `Socket{colour}`, X(x), Y(y), S.Side, tint, tint, false, 3)
		local ring = Skin.Icon(socket, "SocketEmptyJewel", S.Side / 2, S.Side / 2, 16, tint, 8)
		ring.ImageTransparency = E.Socket.EmptyJewel
		Look.Text(group, `Value{colour}`, "-", SMALL, SEAM.Faint, X(x + S.Value.X), Y(y + S.Value.Y), "Centre", true, 3, 40)
	end
	rule(group, J.Rule.Y, J.Rule.Ends, J.Rule.Alpha)
	local said = J.Said
	Look.Text(group, "Said1", COMING, SMALL, SEAM.Text, X(said.At.X), Y(said.At.Y), "Left", true, 3, 232)
	Look.Text(group, "Said2", "Each slot will hold a jewel of its colour", SMALL, SEAM.Soft, X(said.At.X), Y(said.At.Y + said.Pitch), "Left", false, 3, 232)
	-- The presses, as the cut stands them, off until jewels come.
	local P = E.Emblems.Press
	local combine = Look.Press(group, "Combine", X(P.Right - P.Put - 8 - P.Out), Y(P.Top), P.Out, P.Foot - P.Top, function(): boolean
		return false
	end, 8)
	Look.Dress(combine, "Off", "Combine", COMING)
	local put = Look.Press(group, "PutIn", X(P.Right - P.Put), Y(P.Top), P.Put, P.Foot - P.Top, function(): boolean
		return false
	end, 8)
	Look.Dress(put, "Off", "Put in", COMING)
	context.Parts.JewelsPutIn = put
	return {
		Paint = function(_view: Profile.View) end,
		Stop = function() end,
	}
end

return JewelsPage
