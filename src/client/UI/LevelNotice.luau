--!strict
-- LevelNotice (client): the level-up's notice (AR12, take B, the director's pick of 2026-11-15; Modulo's
-- build/handoff/UI/hud/levelup/levelup_notice.json; TR41 (c)). When the lead gains a level, a plate in the lead card's
-- violet slides out of the screen's left edge under the lead's corner: its new level falls onto its lavender block, the
-- Voidkin's name and "LEVEL UP" beside it, then it holds and slides back. It says the event once, in one place: the old
-- toast and the word over the lead are gone, and the column of light stays (Effects.LevelUp). The motion is
-- Rules.Hud.Notice; every number is in Config.Hud.LevelNotice. Every place across the plate is a share of its width,
-- since a UDim's offset is a whole number and the json's places aren't. Its width is the json's rule up to its room: the
-- step's chip over the dock shares its row on a phone, so it stops short of it and a longer name is cut with "…" (a
-- nickname runs to 20 letters). The plate is three plain pieces of its image, not Roblox's slice (Config.Hud.LevelNotice).
--   LevelNotice.Mount(parent)       once, in the HUD's layer
--   LevelNotice.Place(left, top, room?)  its body's top left and the most it may be across, in the layer's points
--   LevelNotice.Show(name, level)   a level gained: one still shown takes the new level and lands it again
--   LevelNotice.Hold(age)           for a still: draws it at `age` seconds and holds there; nil runs the clock again
--   LevelNotice.Parts(), .Wide()    for tests

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local HudConfig = require(ReplicatedStorage.Shared.Config.Hud)
local Hud = require(ReplicatedStorage.Shared.Rules.Hud)

local Theme = require(script.Parent.Theme)
local Layers = require(script.Parent.Layers)
local Skin = require(script.Parent.Kit.Skin)
local Text = require(script.Parent.Kit.Text)

local LOOK = HudConfig.LevelNotice
local TALL = LOOK.Tall

local LevelNotice = {}

local parts: { [string]: GuiObject } = {}
local shownAt: number? = nil
local held: number? = nil
local wide = 0
local room = math.huge
local stepping: RBXScriptConnection? = nil
local epoch = -1

-- A word's label laid by its capitals: `left` its left end and `top` its capitals' top, in the plate's points; `across`
-- its width.
local function word(label: TextLabel, left: number, top: number, size: number, across: number)
	local caps = LOOK.Capitals
	label.Size = UDim2.fromOffset(math.max(math.floor(across), 1), size)
	label.Position = UDim2.fromScale(left / wide, (top - size * caps.Top) / TALL)
end

-- The plate's width for its words (the json's rule: Base + the wider of the name and the line), whole points so the
-- holder's own offset is true, and no more than its room (never narrower than its line); then every part laid as a
-- share of it. The name's label ends where the rule's Base leaves room for the leaning end, so a long name is cut there.
local function fit()
	local name, line, number = parts.Name :: TextLabel?, parts.Line :: TextLabel?, parts.Number :: TextLabel?
	local holder, flash, sheen = parts.Holder, parts.Flash, parts.Sheen
	if not (name and line and number and holder and flash and sheen) then
		return
	end
	local words = LOOK.Words
	local lineWide = Text.Wide(line, line.Text)
	local want = math.ceil(LOOK.Base + math.max(Text.Wide(name, name.Text), lineWide))
	wide = math.max(math.min(want, math.floor(room)), math.ceil(LOOK.Base + lineWide))
	epoch = Text.Epoch()
	holder.Size = UDim2.fromOffset(wide, TALL)
	local ends = LOOK.Base - words.Name.At.X -- from the words' right to the plate's: the leaning end's room
	word(name, words.Name.At.X, words.Name.At.Y, words.Name.Size, wide - words.Name.At.X - ends)
	word(line, words.Line.At.X, words.Line.At.Y, words.Line.Size, wide - words.Line.At.X)
	-- The number centred on its block by its figures' middle.
	local digits = LOOK.Digits
	local size = number:GetAttribute("NL_TextSize") :: number
	number.Size = UDim2.fromOffset(LOOK.Block, size)
	number.Position = UDim2.fromScale(words.Number.Middle.X / wide, (words.Number.Middle.Y - size * (digits.Top + digits.Tall / 2 - 0.5)) / TALL)
	local images = LOOK.Images
	flash.Size = UDim2.fromScale(images.Flash.Points.X / wide, 1)
	flash.Position = UDim2.fromScale((images.Flash.At :: Vector2).X / wide, 0)
	sheen.Size = UDim2.fromScale(images.Sheen.Points.X / wide, 1)
end

-- Draws the notice at `age` seconds. Returns whether it's still shown.
local function draw(age: number): boolean
	local body, plate, flash, sheen = parts.Body, parts.Plate, parts.Flash :: ImageLabel, parts.Sheen :: ImageLabel
	local name, line, number = parts.Name :: TextLabel, parts.Line :: TextLabel, parts.Number :: TextLabel
	if Text.Epoch() ~= epoch then
		fit()
	end
	local n = Hud.Notice(age, LOOK.Motion, wide, wide - TALL * LOOK.Lean, GuiService.ReducedMotionEnabled)
	-- Wholly off the screen's left edge at Away 1: past its own left on the screen, its width and its glow.
	local holder = parts.Holder
	local scale = math.max(Layers.Scale(), 0.01)
	local off = holder.AbsolutePosition.X / scale + wide + LOOK.Images.Plate.Pad + 2
	body.Position = UDim2.fromScale((n.Knock - n.Away * off) / wide, 0)
	local solid = n.Solid
	for _, piece in plate:GetChildren() do
		if piece:IsA("ImageLabel") then
			piece.ImageTransparency = 1 - solid
		end
	end
	name.TextTransparency, line.TextTransparency = 1 - solid, 1 - solid
	number.TextTransparency = 1 - n.Number * solid
	local swell = number:FindFirstChildOfClass("UIScale")
	if swell then
		swell.Scale = math.max(n.Size, 0.01)
	end
	flash.ImageTransparency = 1 - n.Flash * solid
	flash.Visible = n.Flash > 0
	sheen.Visible = n.Sheen ~= nil and n.Shine > 0
	if n.Sheen then
		sheen.Position = UDim2.fromScale((n.Sheen - LOOK.Sheen.Middle) / wide, 0)
		sheen.ImageTransparency = 1 - n.Shine * solid
	end
	holder:SetAttribute("Age", age)
	holder.Visible = not n.Done
	return not n.Done
end

local function stop()
	if stepping then
		stepping:Disconnect()
		stepping = nil
	end
end

local function step()
	local at = shownAt
	if at == nil then
		stop()
		return
	end
	if not draw(held or (os.clock() - at)) and held == nil then
		shownAt = nil
		stop()
	end
end

function LevelNotice.Mount(parent: Instance)
	local holder = Instance.new("Frame")
	holder.Name = "LevelNotice"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromOffset(140, TALL)
	holder.Visible = false
	holder.ZIndex = LOOK.Z
	holder.Parent = parent
	-- The body is what slides and is knocked; the holder keeps the place.
	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Size = UDim2.fromScale(1, 1)
	body.Parent = holder
	local images = LOOK.Images
	-- The plate: its ends at their own size and its middle stretched, cut where the json cuts it, each a plain piece of
	-- the image (a Roblox slice drew its rows wrong under the layer's scale: Config.Hud.LevelNotice). Its glow stands Pad
	-- past the body all round.
	local own = images.Plate
	local cut, pad, perPoint = own.Cut :: { number }, own.Pad, own.Pixels.X / own.Points.X
	local plate = Instance.new("Frame")
	plate.Name = "Plate"
	plate.BackgroundTransparency = 1
	plate.Size = UDim2.new(1, 2 * pad, 1, 2 * pad)
	plate.Position = UDim2.fromOffset(-pad, -pad)
	plate.ZIndex = 1
	plate.Parent = body
	local function piece(name: string, from: number, across: number, size: UDim2, at: UDim2, anchor: Vector2)
		local image = Instance.new("ImageLabel")
		image.Name = name
		image.BackgroundTransparency = 1
		image.Image = own.Id
		image.ImageRectOffset = Vector2.new(from * perPoint, 0)
		image.ImageRectSize = Vector2.new(across * perPoint, own.Pixels.Y)
		image.Size, image.Position, image.AnchorPoint = size, at, anchor
		image.Parent = plate
	end
	local left, right = cut[1], cut[3]
	piece("Left", 0, left, UDim2.new(0, left, 1, 0), UDim2.new(), Vector2.zero)
	piece("Middle", left, own.Points.X - left - right, UDim2.new(1, -left - right, 1, 0), UDim2.fromOffset(left, 0), Vector2.zero)
	piece("Right", own.Points.X - right, right, UDim2.new(0, right, 1, 0), UDim2.fromScale(1, 0), Vector2.new(1, 0))
	local flash = Skin.LayOwn(body, images.Flash, "Flash", { Z = 2 })
	flash.Visible = false
	local sheen = Skin.LayOwn(body, images.Sheen, "Sheen", { Z = 3 })
	sheen.Visible = false
	local words = LOOK.Words
	local name = Text.new({ Name = "Name", Size = words.Name.Size, Font = Theme.Font.Body, Colour = words.Name.Colour, Truncate = true, Parent = body })
	local line = Text.new({ Name = "Line", Size = words.Line.Size, Font = Theme.Font.Body, Colour = words.Line.Colour, Parent = body })
	line.Text = words.Line.Text
	local number = Text.new({ Name = "Number", Size = words.Number.Sizes[1], Font = Theme.Font.Strong, Colour = words.Number.Colour, Align = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(0.5, 0.5), Parent = body })
	local swell = Instance.new("UIScale")
	swell.Parent = number
	name.ZIndex, line.ZIndex, number.ZIndex = 4, 4, 5
	parts = { Holder = holder, Body = body, Plate = plate, Flash = flash, Sheen = sheen, Name = name, Line = line, Number = number }
end

function LevelNotice.Place(left: number, top: number, most: number?)
	local holder = parts.Holder
	if holder == nil then
		return
	end
	holder.Position = UDim2.fromOffset(left, top)
	local r = most or math.huge
	if r ~= room and not (math.abs(r - room) <= 0.5) then
		room = r
		if holder.Visible then
			fit()
		end
	end
end

function LevelNotice.Show(name: string, level: number)
	local nameLabel, number = parts.Name :: TextLabel?, parts.Number :: TextLabel?
	if nameLabel == nil or number == nil then
		return
	end
	nameLabel.Text = name
	local digits = string.format("%d", level)
	number.Text = digits
	local sizes = LOOK.Words.Number.Sizes
	number:SetAttribute("NL_TextSize", sizes[math.clamp(#digits, 1, #sizes)])
	number.TextSize = Text.Legible(number:GetAttribute("NL_TextSize") :: number, Layers.Scale())
	fit()
	local now = os.clock()
	local m = LOOK.Motion
	local age = if shownAt then now - shownAt else math.huge
	if age < m.In then
		-- Still sliding in: the new level falls as it arrives.
	elseif age < m.In + m.Hold + math.max(m.Out, m.Fade) then
		shownAt = now - m.In -- at its place, or leaving: back at its place, the new level lands and it holds anew
	else
		shownAt = now
	end
	if stepping == nil then
		stepping = RunService.RenderStepped:Connect(step)
	end
	step()
end

function LevelNotice.Hold(age: number?)
	held = age
	if age and shownAt == nil then
		shownAt = os.clock()
	end
	if age and stepping == nil then
		stepping = RunService.RenderStepped:Connect(step)
	end
	step()
end

function LevelNotice.Parts(): { [string]: GuiObject }
	return parts
end

function LevelNotice.Wide(): number
	return wide
end

return LevelNotice
