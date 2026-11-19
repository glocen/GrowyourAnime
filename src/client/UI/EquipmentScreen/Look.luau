--!strict
-- Equipment's look (client): what its three pages share, laid as Modulo's cut draws it (AR43, "The cut in B, for
-- Faber"; build/handoff/UI/equipment/equipment.json and ../seam/seam.json), in Seam's lit glass. Places are the cut's
-- points on the smallest phone (Config.Hud.Equipment); X and Y turn one into the block's own, the room under the band.
--   Look.X(x), Look.Y(y)                                    a cut point in the block
--   Look.Room(body)                                         the block, centred in a full screen's body, grown to its room
--   Look.Panel(parent, name, box, z)                        a panel in B, its box in cut points
--   Look.Text(parent, name, words, size, colour, x, y, align, strong, z, wide?) words with their top at y: Left from x,
--                                                           Right to x, Centre on x
--   Look.Fit(label, wide, size)                             shrunk until its words fit
--   Look.Cell(parent, name, x, y, side, rarity, image, class, z)  the bag's item cell (Bag.Art), its top left at x, y
--   Look.Press(parent, name, x, y, w, h, act, z)            a press; Look.Dress(press, kind, words, why?) lays its face:
--                                                           Lit (the one it can do), Quiet, or Off (the well's, faint
--                                                           words), which says `why` on a tap
--   Look.Socket(parent, name, x, y, side, light, rim, chosen, z)  a socket's well, light and rim
--   Look.Item(item) -> name, image, row                     what an owned item is called and shows
--   Look.Rarity(rarity)                                     a rarity's word colour (the bag's)
--   Look.Block(view)                                        the lead's stats, which a rating's share is read against
--   Look.Value(stat, points, block), Look.Gain(stat, from, to, block)  a stat's points as players read them
--   Look.Lines(stat)                                        a stat's name, a word a line

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Items = require(Shared.Definitions.Items)
local Stats = require(Shared.Rules.Stats)
local Sheet = require(Shared.Rules.Sheet)
local HudConfig = require(Shared.Config.Hud)
local UIKit = require(Shared.Config.UIKit)

local UI = script.Parent.Parent
local Button = require(UI.Kit.Button)
local Glass = require(UI.Kit.Glass)
local Skin = require(UI.Kit.Skin)
local Text = require(UI.Kit.Text)
local Cells = require(UI.VoidkinScreen.Bag)
local Layers = require(UI.Layers)

local Look = {}

local E = HudConfig.Equipment
local SEAM = UIKit.Palettes.SeamGlass
local ROOM = E.Block
Look.E = E
Look.Seam = SEAM
Look.Light = SEAM.Light :: Color3
Look.Ink = SEAM.Ink :: Color3
Look.Glint = SEAM.Glint
Look.White = Color3.new(1, 1, 1)
Look.Small = 14 -- the cut's words
Look.Big = 17 -- a level's

-- A page's handles, and what the screen hands it.
export type On = {
	Act: (name: string, args: any?) -> { [string]: any }, -- ProfileController.Act
	Say: (words: string) -> (), -- a toast
}
export type Context = {
	Group: CanvasGroup, -- the work: the block's points
	View: Profile.View,
	Item: string?,
	On: On,
	Parts: { [string]: Instance },
	Opening: boolean, -- the screen's opening beat: Reinforce's ring draws round, the gear grows in
	Latest: () -> Profile.View, -- the save as the client last heard it
	Row: (colour: Color3?) -> TextLabel?, -- the chosen row's words again, its level in `colour` (a rise's, a fail's): its level
	Busy: (busy: boolean) -> (), -- a try under way: no row, rail or Back's change of page until its beat ends
	Wallet: (credits: number) -> (), -- the band's Credits counted down to `credits`
}
export type Page = {
	Paint: (view: Profile.View) -> (),
	Stop: () -> (),
}

local ALIGN = { Left = Enum.TextXAlignment.Left, Right = Enum.TextXAlignment.Right, Centre = Enum.TextXAlignment.Center }

function Look.X(x: number): number
	return x - E.Block.Left
end

function Look.Y(y: number): number
	return y - E.Block.Top
end

function Look.Text(parent: Instance, name: string, words: string, size: number, colour: Color3, x: number, y: number, align: string, strong: boolean, z: number, wide: number?): TextLabel
	local w = wide or 220
	local left = if align == "Right" then x - w elseif align == "Centre" then x - w / 2 else x
	return Glass.Label(parent, name, words, size, colour, left, y - 1, w, size + 2, ALIGN[align], strong, z)
end

-- A label at `size`, shrunk until its words fit `wide`, never under 10.
function Look.Fit(label: TextLabel, wide: number, size: number)
	local need = Text.Wide(label, label.Text) * size / (Text.Authored(label) or size)
	if need > wide then
		Text.Resize(label, math.max(10, math.floor(size * wide / need)))
	else
		Text.Resize(label, size)
	end
end

function Look.Cell(parent: Instance, name: string, x: number, y: number, side: number, rarity: string, image: string?, class: string?, z: number): Frame
	local holder = Instance.new("Frame")
	holder.Name = name
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromOffset(side, side)
	holder.Position = UDim2.fromOffset(x, y)
	holder.ZIndex = z
	holder.Parent = parent
	Cells.Art(holder, side, rarity, image, "", class, false)
	return holder
end

function Look.Press(parent: Instance, name: string, x: number, y: number, w: number, h: number, act: () -> boolean, z: number): TextButton
	local button = Button.new({
		Name = name,
		Text = "",
		Bare = true,
		Size = UDim2.fromOffset(w, h),
		Position = UDim2.fromOffset(x, y),
		Parent = parent,
		OnPress = act,
	})
	button.ZIndex = z
	return button
end

function Look.Dress(button: TextButton, kind: string, words: string, why: string?)
	Glass.Dress(button, kind, words, why, { Size = Look.Small })
end

-- A socket (equipment.json's images): the chosen one's glow under its well; the well; a held or coloured one's light in
-- `light`; its rim, lit when chosen, else in `rim` (left out, the screen's edge, fainter: an empty emblem socket's and a
-- jewel bag cell's). Returns its holder, `side` across, its top left at x, y.
function Look.Socket(parent: Instance, name: string, x: number, y: number, side: number, light: Color3?, rim: Color3?, chosen: boolean, z: number): Frame
	local S = E.Socket
	local holder = Instance.new("Frame")
	holder.Name = name
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromOffset(side, side)
	holder.Position = UDim2.fromOffset(x, y)
	holder.ZIndex = z
	holder.Parent = parent
	if chosen then
		Skin.Lay(holder, "SocketGlow", { Name = "Glow", X = -18, Y = -18, W = side + 36, H = side + 36, Tint = Look.Light, Alpha = 1 - S.Glow, Z = z })
	end
	Skin.Lay(holder, "SocketFill", { Name = "Fill", W = side, H = side, Z = z + 1 })
	if light then
		local lit = Skin.Lay(holder, "SocketLight", { Name = "Light", Tint = light, Z = z + 2 })
		lit.Size = UDim2.fromOffset(side, side)
		lit.Position = UDim2.new()
	end
	if chosen then
		Skin.Lay(holder, "SocketEdgeLit", { Name = "Edge", X = -2, Y = -2, W = side + 4, H = side + 4, Tint = Look.Light, Z = z + 3 })
	else
		local alpha = 1 - (if rim then S.Edge else S.EmptyEdge)
		Skin.Lay(holder, "SocketEdge", { Name = "Edge", X = -2, Y = -2, W = side + 4, H = side + 4, Tint = rim or SEAM.Edge, Alpha = alpha, Z = z + 3 })
	end
	return holder
end

function Look.Item(item: Profile.OwnedItem): (string, string?, Items.Row?)
	local row = Items.ById[item.Def]
	local design = Items.Design(item)
	local name = if design then design.Name elseif row then row.Name else item.Def
	return name, if design then design.Image else nil, row
end

function Look.Rarity(rarity: string): Color3
	return HudConfig.Bag.Rarity[rarity] or SEAM.Text
end

function Look.Block(view: Profile.View): Stats.Block
	local data = view :: any
	local owned = data.Voidkin[data.Roles.Lead]
	if owned == nil then
		return Stats.Empty(1)
	end
	return (Stats.Resolve(owned, Stats.PresetOf(data, owned), data))
end

function Look.Value(stat: string, points: number, block: Stats.Block): string
	if Sheet.Rated[stat] then
		return Sheet.Percent(Sheet.Adds(stat, points, block))
	end
	return Sheet.Amount(stat, points)
end

function Look.Gain(stat: string, from: number, to: number, block: Stats.Block): string
	if Sheet.Rated[stat] then
		return Sheet.Change(stat, Sheet.Adds(stat, to, block) - Sheet.Adds(stat, from, block))
	end
	return Sheet.Change(stat, to - from)
end

function Look.Named(stat: string): string
	return Sheet.Said[stat] or stat
end

function Look.Lines(stat: string): { string }
	local lines = {}
	for word in string.gmatch(Look.Named(stat), "%S+") do
		table.insert(lines, word)
	end
	return lines
end

-- What a refusal says.
local SAID: { [string]: string } = {
	InCombat = "Not during a fight",
	Capped = "It's at the most already",
	Poor = "Not enough Credits",
	NoStones = "Not enough stones",
	NoneLeft = "None of that emblem left",
	Empty = "That socket is empty",
}
function Look.Refused(answer: { [string]: any }): string
	local error = answer.Error
	return if type(error) == "string" and SAID[error] then SAID[error] else "Not now"
end

-- Eases (seam.json, motion.easing).
function Look.Out3(u: number): number
	local v = math.clamp(u, 0, 1)
	return 1 - (1 - v) ^ 3
end

function Look.In3(u: number): number
	local v = math.clamp(u, 0, 1)
	return v ^ 3
end

function Look.Smooth(u: number): number
	local v = math.clamp(u, 0, 1)
	return v * v * (3 - 2 * v)
end

function Look.BackOut(u: number, s: number): number
	local v = math.clamp(u, 0, 1)
	return 1 + (s + 1) * (v - 1) ^ 3 + s * (v - 1) ^ 2
end

-- The cut's room under the band, scaled to the room the screen has, at most Grow, its middle the room's (StageScreen's).
function Look.Room(body: Frame): Frame
	local frame = Instance.new("Frame")
	frame.Name = "Block"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromOffset(ROOM.Wide, ROOM.Tall)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	local scale = Instance.new("UIScale")
	scale.Parent = frame
	local menus = Layers.Get("Menus")
	local function refit()
		local space = menus.AbsoluteSize / Layers.Scale()
		if space.X > 0 and space.Y > 0 then
			scale.Scale = math.min(space.X / ROOM.Wide, space.Y / ROOM.Tall, ROOM.Grow)
		end
	end
	local resized = menus:GetPropertyChangedSignal("AbsoluteSize"):Connect(refit)
	local rescaled = Layers.Changed:Connect(refit)
	frame.Destroying:Connect(function()
		resized:Disconnect()
		rescaled:Disconnect()
	end)
	refit()
	frame.Parent = body
	return frame
end

-- A panel in B (seam.json, panel): the kit's fill in the Panel's colours top to foot, its lift across the top, its edge
-- in the facet lit from above, the light along its top-left corner.
function Look.Panel(parent: Instance, name: string, box: { number }, z: number): Frame
	return Glass.Panel(parent, name, Look.X(box[1]), Look.Y(box[2]), box[3] - box[1], box[4] - box[2], SEAM, z)
end

return Look
