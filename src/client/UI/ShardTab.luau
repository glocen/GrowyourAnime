--!strict
-- ShardTab (client UI): the base's shard during a run (TR53's Festival half; AR55's look, build/handoff/UI/return/
-- return.json, "run"; its numbers Config.Hud.Return.Run). A tab of the run's line's own glass hangs under the line, the
-- dare's tab's twin to its right: the shard breaking at home, its small picture and its time left. Broken, it reads
-- "Ready" over a soft glow until the player is home, and the notice opens right from it once ("Your shard broke." /
-- "Its Voidkin waits at home."), then folds back to the tab. While the dare's tab is open the tab rides its foot. No
-- shard in the Breaker, no tab. StageController draws the line and calls Show each time it or the base changes.
--   ShardTab.Show(frame, hard, state?)   the tab on the line's frame; nil takes it away
--   ShardTab.Notice(frame)               the notice, once, from the tab already shown
--   ShardTab.Said(frame) -> { Ready, Words, Def, Drop, Notice, Wide }?   for tests

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")

local Shared = ReplicatedStorage.Shared
local HudConfig = require(Shared.Config.Hud)
local Shards = require(Shared.Definitions.Shards)
local Hud = require(Shared.Rules.Hud)

local UI = script.Parent
local Read = require(UI.Read)
local Glass = require(UI.Kit.Glass)
local Skin = require(UI.Kit.Skin)
local Text = require(UI.Kit.Text)
local StageScreen = require(UI.StageScreen)
local DareLine = require(UI.DareLine)

local ShardTab = {}

export type State = {
	Def: string, -- the shard: breaking, or the newest broken
	Ready: boolean,
	Left: number?, -- seconds until it breaks, while it breaks
}

local RUN = HudConfig.Return.Run
local IMAGES = HudConfig.Return.Images
local DARE = HudConfig.Stages.Dare
local Z = -5 -- under the line's own glass, as the dare's tab
local TEXT_Z = Z + 11

type Drawn = {
	Frame: Frame,
	Holder: Frame,
	Body: Frame,
	Plate: Frame,
	Words: TextLabel,
	Hard: boolean,
	Def: string,
	Ready: boolean,
	Wide: number,
	Drop: number,
	Notice: Frame?,
}

local drawn: { [Frame]: Drawn } = setmetatable({}, { __mode = "k" }) :: any

local function wordsOf(state: State): string
	return if state.Ready then "Ready" else Read.Clock(state.Left or 0)
end

-- A label with its capitals' top at y, as the dare's words are laid.
local function label(parent: Instance, name: string, text: string, x: number, y: number, w: number, colour: Color3, strong: boolean, align: Enum.TextXAlignment): TextLabel
	local size = RUN.Words.Size
	return Glass.Label(parent, name, text, size, colour, x, y + size * 0.36 - 10, w, 20, align, strong, TEXT_Z)
end

local function picture(parent: Instance, def: string, x: number, y: number, tall: number, z: number)
	local row = Shards.ById[def]
	Skin.Icon(parent :: GuiObject, Hud.ShardPicture(if row then row.Grade else "Standard", tall, math.huge), x, y, tall, nil, z).Name = "Picture"
end

-- The tab's glass and its words' box, as wide as its words.
local function lay(made: Drawn, text: string)
	local tab = RUN.Tab
	local probe = label(made.Holder, "Probe", text, 0, 0, 400, RUN.Words.Colour, made.Ready, Enum.TextXAlignment.Left)
	probe.Visible = false
	local wide = math.max(RUN.Least, RUN.Room + Text.Wide(probe, text))
	probe:Destroy()
	made.Wide = wide
	made.Plate:ClearAllChildren()
	StageScreen.Plate(made.Plate, tab[1], tab[2], wide, tab[4], made.Hard, RUN.Corner[1], Z)
	local right = tab[1] + wide - RUN.Words.Right
	made.Words.Position = UDim2.fromOffset(right - 200, made.Words.Position.Y.Offset)
end

local function build(frame: Frame, hard: boolean, state: State): Drawn
	local holder = Instance.new("Frame")
	holder.Name = "ShardTab"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.ZIndex = Z
	holder.Parent = frame
	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Size = UDim2.fromScale(1, 1)
	body.ZIndex = Z
	body.Parent = holder
	local plate = Instance.new("Frame")
	plate.Name = "Glass"
	plate.BackgroundTransparency = 1
	plate.Size = UDim2.fromScale(1, 1)
	plate.ZIndex = Z
	plate.Parent = body
	local P = RUN.Picture
	if state.Ready then
		Skin.LayOwn(body, IMAGES.ReturnGlow, "Glow", { X = P.X, Y = P.Y, Tint = RUN.Glow, Z = Z + 6 })
	end
	picture(body, state.Def, P.X, P.Y, P.Tall, Z + 7)
	local text = wordsOf(state)
	local words = label(body, "Words", text, 0, RUN.Words.Y, 200, if state.Ready then RUN.Words.Ready else RUN.Words.Colour, state.Ready, Enum.TextXAlignment.Right)
	local made: Drawn = {
		Frame = frame,
		Holder = holder,
		Body = body,
		Plate = plate,
		Words = words,
		Hard = hard,
		Def = state.Def,
		Ready = state.Ready,
		Wide = 0,
		Drop = 0,
		Notice = nil,
	}
	lay(made, text)
	return made
end

-- How far under its place the tab rides: the open dare's foot, under one row or two, as far as it stands under the line.
local function dropOf(frame: Frame): number
	local said = DareLine.Said(frame)
	if said == nil or said.Open ~= true then
		return 0
	end
	return (DARE.Foot[said.Rows] or DARE.Foot[#DARE.Foot]) - RUN.Line
end

local function ride(made: Drawn)
	local to = dropOf(made.Frame)
	if to == made.Drop then
		return
	end
	local from = made.Drop
	made.Drop = to
	if GuiService.ReducedMotionEnabled then
		made.Body.Position = UDim2.fromOffset(0, to)
		return
	end
	Glass.Ease(made.Body, RUN.Ride, function(u: number)
		made.Body.Position = UDim2.fromOffset(0, from + (to - from) * u)
	end, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

function ShardTab.Show(frame: Frame, hard: boolean, state: State?)
	local was = drawn[frame]
	if state == nil then
		if was then
			was.Holder:Destroy()
			drawn[frame] = nil
		end
		return
	end
	if was == nil or was.Def ~= state.Def or was.Ready ~= state.Ready or was.Hard ~= hard or was.Holder.Parent == nil then
		if was then
			was.Holder:Destroy()
		end
		was = build(frame, hard, state)
		drawn[frame] = was
	end
	local made = was :: Drawn
	local text = wordsOf(state)
	if made.Words.Text ~= text then
		made.Words.Text = text
		lay(made, text)
	end
	ride(made)
end

-- The notice: opened right from the tab, two rows beside the broken shard's picture, held, then folded back.
function ShardTab.Notice(frame: Frame)
	local made = drawn[frame]
	if made == nil or made.Notice ~= nil then
		return
	end
	local N = RUN.Notice
	local box = N.Box
	local clip = Instance.new("Frame")
	clip.Name = "Notice"
	clip.BackgroundTransparency = 1
	clip.ClipsDescendants = true
	clip.Position = UDim2.fromOffset(-20, 0)
	clip.Size = UDim2.fromOffset(box[1] + made.Wide + 20, box[2] + box[4] + 20)
	clip.ZIndex = Z + 5
	clip.Parent = made.Body
	StageScreen.Plate(clip, box[1] + 20, box[2], box[3], box[4], made.Hard, RUN.Corner[2], Z + 5)
	picture(clip, made.Def, N.Picture.X + 20, N.Picture.Y, N.Picture.Tall, Z + 12)
	local rows = {}
	for index, row in N.Rows do
		local words = label(clip, `Row{index}`, N.Words[index], row.X + 20, row.Y, box[3] - row.X + box[1], if index == 1 then RUN.Words.Ready else RUN.Words.Colour, index == 1, Enum.TextXAlignment.Left)
		table.insert(rows, words)
	end
	made.Notice = clip
	local function width(u: number)
		clip.Size = UDim2.fromOffset(box[1] + made.Wide + (box[3] - made.Wide) * u + 20, clip.Size.Y.Offset)
		for _, words in rows do
			words.TextTransparency = 1 - math.clamp((u - 0.4) / 0.6, 0, 1)
		end
	end
	if GuiService.ReducedMotionEnabled then
		width(1)
	else
		width(0)
		Glass.Ease(clip, N.Open, width, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end
	task.delay(N.Open + N.Held, function()
		local still = rawequal(made.Notice, clip)
		if not still or clip.Parent == nil then
			return
		end
		local function shut()
			clip:Destroy()
			if rawequal(made.Notice, clip) then
				made.Notice = nil
			end
		end
		if GuiService.ReducedMotionEnabled then
			shut()
			return
		end
		Glass.Ease(clip, N.Close, function(u: number)
			width(1 - u)
		end, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(N.Close + 0.02, shut)
	end)
end

function ShardTab.Said(frame: Frame?): { [string]: any }?
	local made = if frame then drawn[frame] else nil
	if made == nil or made.Holder.Parent == nil then
		return nil
	end
	local rows = {}
	local notice = made.Notice
	if notice then
		for index = 1, #RUN.Notice.Rows do
			local row = notice:FindFirstChild(`Row{index}`) :: TextLabel?
			table.insert(rows, if row then row.Text else "")
		end
	end
	return {
		Ready = made.Ready,
		Words = made.Words.Text,
		Def = made.Def,
		Drop = made.Drop,
		Wide = made.Wide,
		Notice = if notice then table.concat(rows, " ") else nil,
		Holder = made.Holder,
	}
end

return ShardTab
