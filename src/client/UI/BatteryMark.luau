--!strict
-- BatteryMark (client): the battery's mark, AR12's V2 Battery (TR41 (e)), its three cells lit by the charge in thirds
-- (Rules.Hud.BatteryCells; research's must-fix: two readings of one value never disagree). The image draws two cells lit
-- and an empty slot behind the third, so each cell is laid over it as a crop of the image itself, a lit cell or the
-- slot's dark stretched over its part of the battery's inside (Config.Hud.Power.Cells): no other image. On the Power
-- screen's plate and in the HUD's Power pill.
--   BatteryMark.new(parent, side, z)        the mark, `side` points square, named "Mark"; the caller places it
--   BatteryMark.Set(mark, kwh, capacity)    its cells for this charge; the count lit is its attribute Cells

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HudConfig = require(ReplicatedStorage.Shared.Config.Hud)
local Hud = require(ReplicatedStorage.Shared.Rules.Hud)

local IMAGE = HudConfig.Power.Images.Battery
local CELLS = HudConfig.Power.Cells

local BatteryMark = {}

-- A share of the image's pixels, so the cells hold at every size.
local function share(pixels: Vector2): UDim2
	return UDim2.fromScale(pixels.X / IMAGE.Pixels.X, pixels.Y / IMAGE.Pixels.Y)
end

-- Where cell `index` lies, in the image's pixels: lit, the cell itself; empty, its tile of the battery's inside.
local function spot(index: number, lit: boolean): (Vector2, Vector2)
	local at = CELLS.At + Vector2.new(CELLS.Every * (index - 1), 0)
	local inside = CELLS.Inside
	if lit then
		-- The third ends at the inside's right, a pixel short of the others: the image's slot is that much narrower.
		return at, Vector2.new(math.min(CELLS.Size.X, inside.Right - at.X), CELLS.Size.Y)
	end
	local half = (CELLS.Every - CELLS.Size.X) / 2 -- half the gap between two cells
	local left = if index == 1 then inside.Left else at.X - half
	local right = if index == 3 then inside.Right else at.X + CELLS.Size.X + half
	return Vector2.new(left, inside.Top), Vector2.new(right - left, inside.Foot - inside.Top)
end

local function lay(cell: ImageLabel, index: number, lit: boolean)
	local at, size = spot(index, lit)
	cell.ImageRectOffset = if lit then CELLS.Lit else CELLS.Dark.From
	cell.ImageRectSize = if lit then size else CELLS.Dark.Size
	cell.Size = share(size)
	cell.Position = share(at)
	cell:SetAttribute("Lit", lit)
end

function BatteryMark.new(parent: Instance, side: number, z: number): ImageLabel
	local mark = Instance.new("ImageLabel")
	mark.Name = "Mark"
	mark.BackgroundTransparency = 1
	mark.BorderSizePixel = 0
	mark.Image = IMAGE.Id
	mark.Size = UDim2.fromOffset(side, side)
	mark.ZIndex = z
	for index = 1, 3 do
		local cell = Instance.new("ImageLabel")
		cell.Name = `Cell{index}`
		cell.BackgroundTransparency = 1
		cell.BorderSizePixel = 0
		cell.Image = IMAGE.Id
		cell.ZIndex = z
		lay(cell, index, false)
		cell.Parent = mark
	end
	mark:SetAttribute("Cells", 0)
	mark.Parent = parent
	return mark
end

function BatteryMark.Set(mark: ImageLabel, kwh: number, capacity: number)
	local lit = Hud.BatteryCells(kwh, capacity)
	if mark:GetAttribute("Cells") == lit then
		return
	end
	mark:SetAttribute("Cells", lit)
	for index = 1, 3 do
		local cell = mark:FindFirstChild(`Cell{index}`)
		if cell and cell:IsA("ImageLabel") then
			lay(cell, index, index <= lit)
		end
	end
end

return BatteryMark
