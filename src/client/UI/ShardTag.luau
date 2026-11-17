--!strict
-- ShardTag (client): where a shard came from, laid on its picture (AR12, "Where a shard came from"; Modulo's
-- build/handoff/UI/shards/tag/shard_tag.json; TR41 (d)). The picture keeps its place and size; the tag is laid over it,
-- by the side it's shown at: the ground's tag hung from the crystal's shoulder on a large picture, its mark on a disc on
-- a small one, a band of its colour along a Breaker chip's foot. The numbers are Config.Hud.ShardTag, the box is
-- Rules.Hud.ShardTag. A shard of a ground with no tag drawn yet shows none.
--   ShardTag.Lay(picture, def, side, left?)  on a shard's picture `side` points square: its tag or its mark; `left`, the
--                                      mark at the crystal's left foot, where a bag cell's count holds the right
--   ShardTag.Band(chip, def, tall)     along a chip `tall` points high: a band inside its edge. Returns the band

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HudConfig = require(ReplicatedStorage.Shared.Config.Hud)
local Hud = require(ReplicatedStorage.Shared.Rules.Hud)
local Shards = require(ReplicatedStorage.Shared.Definitions.Shards)

local Skin = require(script.Parent.Kit.Skin)

local LOOK = HudConfig.ShardTag

local ShardTag = {}

local function groundOf(def: string): (string, typeof(LOOK.Grounds.lanternrow)?)
	local row = Shards.ById[def]
	if row == nil then
		return "", nil
	end
	return row.Ground, LOOK.Grounds[row.Ground]
end

function ShardTag.Lay(picture: ImageLabel, def: string, side: number, left: boolean?): ImageLabel?
	local id, ground = groundOf(def)
	if ground == nil then
		return nil
	end
	local box = Hud.ShardTag(side, LOOK, HudConfig.ShardArt.Large, ground.Tag.Points, left)
	local tag = box.Kind == "Tag"
	local image = Skin.LayOwn(picture, if tag then ground.Tag else ground.Mark, if tag then "Tag" else "Mark", { Z = picture.ZIndex })
	-- A share of the picture's side, so it holds at every size (a UDim's offset is a whole number).
	image.Size = UDim2.fromScale(box.W / side, box.H / side)
	image.Position = UDim2.fromScale(0.5 + box.X / side, 0.5 + box.Y / side)
	image:SetAttribute("Ground", id)
	return image
end

function ShardTag.Band(chip: GuiObject, def: string, tall: number): Frame?
	local id, ground = groundOf(def)
	if ground == nil then
		return nil
	end
	-- The chip's own fill, in the ground's colour, seen only along its foot: so the band keeps the chip's corners and
	-- lies under its edge (Panel.Paint: the fill at 2, the edge at 4).
	local share = LOOK.Band / tall
	local band = Instance.new("Frame")
	band.Name = "GroundBand"
	band.BackgroundTransparency = 1
	band.BorderSizePixel = 0
	band.ClipsDescendants = true
	band.Size = UDim2.fromScale(1, share)
	band.Position = UDim2.fromScale(0, 1 - share)
	band.ZIndex = 3
	band:SetAttribute("Ground", id)
	band.Parent = Skin.Of(chip)
	local fill = Skin.Lay(band, "PanelFill", { Name = "Fill", Tint = ground.Colour, Z = 3 })
	fill.Size = UDim2.fromScale(1, 1 / share)
	fill.Position = UDim2.fromScale(0, 1 - 1 / share)
	return band
end

return ShardTag
