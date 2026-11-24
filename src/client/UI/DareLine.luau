--!strict
-- DareLine (client UI): a stretch's dare under the run's line (TR54; AR53's look, build/handoff/UI/goals/goals.json,
-- "dare.line"; its numbers Config.Hud.Stages.Dare). A tab of the line's own glass hangs under the stretch's mark. As the
-- stretch begins it is open to the right with the dare's words for Config.Goals.Held seconds, then closes round its mark,
-- which never moves: lit while the dare holds, dark and split once it breaks (no words, no sound), a flare once as the
-- stretch clears with it kept. The line never grows, and the open tab stops Limit short of the Electricity pill, so it
-- lies over no other piece of the HUD. StageController draws the line and calls Show each time it or the dare changes.
--   DareLine.Show(frame, hard, textLeft, key, text, look)  the dare `key` ("<stage> <id>") on the line's frame
--   DareLine.Said(frame) -> { Open, Rows, Look, Words, Kit, Wide, Right, Clip }?   for tests

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")

local Shared = ReplicatedStorage.Shared
local HudConfig = require(Shared.Config.Hud)
local GoalsConfig = require(Shared.Config.Goals)
local UIKit = require(Shared.Config.UIKit)

local UI = script.Parent
local Layers = require(UI.Layers)
local Glass = require(UI.Kit.Glass)
local Text = require(UI.Kit.Text)
local StageScreen = require(UI.StageScreen)

local DareLine = {}

local LOOK = HudConfig.Stages.Dare
local IMAGES = { Holds = "DareMark", Broken = "DareMarkDark", Kept = "DareMarkKept" }
local Z = -5 -- the tab's glass under the line's own (its plate is laid at 1 to 5)
local MARK_Z = 9

type Drawn = {
	Key: string,
	Frame: Frame,
	Holder: Frame,
	Clip: Frame,
	Words: { TextLabel },
	Mark: ImageLabel,
	Scale: UIScale,
	Look: string,
	Open: boolean,
	Rows: number,
	Text: string,
	Wide: number, -- the open box's width
}

local drawn: { [Frame]: Drawn } = setmetatable({}, { __mode = "k" }) :: any
local shown: { [string]: boolean } = {} -- the dares already opened this run, so a line built again keeps its tab closed

-- The room the open tab has: Limit short of the Electricity pill when it stands beside the line, else the line's own.
local function limitOf(frame: Frame): number
	local scale = Layers.Scale()
	local hud = Layers.Get("Hud")
	local pill = hud:FindFirstChild("Electricity")
	local room = frame.AbsoluteSize.X / scale
	if pill and pill:IsA("GuiObject") and pill.Visible then
		local x = (pill.AbsolutePosition.X - frame.AbsolutePosition.X) / scale
		if x > 0 then
			room = math.min(room, x)
		end
	end
	return room - LOOK.Limit
end

local function word(parent: Instance, name: string, text: string, x: number, y: number, z: number): TextLabel
	-- the capitals' top at y: the label's box centred on the capitals' middle
	local size = LOOK.Words.Size
	local label = Glass.Label(parent, name, text, size, LOOK.Words.Colour, x, y + size * 0.36 - 10, 400, 20, Enum.TextXAlignment.Left, false, z)
	return label
end

-- The words' rows: one when they end Inside of the limit, else two, broken at the word that leaves the rows most alike.
local function rows(text: string, x: number, limit: number, measure: (s: string) -> number): { string }
	if x + measure(text) <= limit - LOOK.Inside then
		return { text }
	end
	local words = string.split(text, " ")
	local best, bestGap = { text }, math.huge
	for cut = 1, #words - 1 do
		local a = table.concat(words, " ", 1, cut)
		local b = table.concat(words, " ", cut + 1)
		local gap = math.abs(measure(a) - measure(b))
		if gap < bestGap then
			best, bestGap = { a, b }, gap
		end
	end
	return best
end

local function lay(made: Drawn, look: string)
	local record = UIKit.Images[IMAGES[look] or "DareMark"]
	made.Mark.Image = record.Id
	made.Mark:SetAttribute("Kit", IMAGES[look] or "DareMark")
end

local function flare(made: Drawn)
	local motion = LOOK.Motion.Flare
	Glass.Ease(made.Mark, motion.Seconds, function(u: number)
		-- up to its scale and back, quick out, slow home
		local k = if u < 0.35 then u / 0.35 else 1 - (u - 0.35) / 0.65
		made.Scale.Scale = 1 + (motion.Scale - 1) * math.sin(k * math.pi / 2)
	end, Enum.EasingStyle.Linear)
end

local function close(made: Drawn)
	if not made.Open then
		return
	end
	made.Open = false
	local tab = LOOK.Tab
	local from = made.Wide
	Glass.Ease(made.Holder, LOOK.Motion.Close, function(u: number)
		made.Clip.Size = UDim2.fromOffset(tab[1] + from - (from - tab[3]) * u + 20, made.Clip.Size.Y.Offset)
		for _, w in made.Words do
			w.TextTransparency = math.min(1, u * 2)
		end
		if u >= 1 then
			made.Clip.Visible = false
		end
	end, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
end

local function open(made: Drawn)
	made.Open = true
	made.Clip.Visible = true
	local tab = LOOK.Tab
	local to = made.Wide
	for _, w in made.Words do
		w.TextTransparency = 1
	end
	Glass.Ease(made.Holder, LOOK.Motion.Open, function(u: number)
		made.Clip.Size = UDim2.fromOffset(tab[1] + tab[3] + (to - tab[3]) * u + 20, made.Clip.Size.Y.Offset)
		for _, w in made.Words do
			w.TextTransparency = 1 - math.clamp((u - 0.4) / 0.6, 0, 1)
		end
	end, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	task.delay(LOOK.Motion.Open + GoalsConfig.Held, function()
		if drawn[made.Frame] == made then
			close(made)
		end
	end)
end

local function build(frame: Frame, hard: boolean, textLeft: number, key: string, text: string, look: string, unfold: boolean): Drawn
	local holder = Instance.new("Frame")
	holder.Name = "Dare"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.ZIndex = Z
	holder.Parent = frame
	local tab = LOOK.Tab
	-- the folded tab, always there under the open box
	StageScreen.Plate(holder, tab[1], tab[2], tab[3], tab[4], hard, LOOK.Corner[1], Z)
	-- the words, measured once laid, then broken into rows
	local limit = limitOf(frame)
	local probe = word(holder, "Probe", text, textLeft, 0, Z)
	probe.Visible = false
	local function measure(s: string): number
		return Text.Wide(probe, s)
	end
	local lines = rows(text, textLeft, limit, measure)
	local widest = 0
	for _, s in lines do
		widest = math.max(widest, measure(s))
	end
	probe:Destroy()
	local n = #lines
	local foot = LOOK.Foot[n] or LOOK.Foot[#LOOK.Foot]
	local right = math.min(textLeft + widest + LOOK.Pad, limit)
	local wide = right - tab[1]
	-- the open box, in a holder that clips it from the right as it opens and closes
	local clip = Instance.new("Frame")
	clip.Name = "Open"
	clip.BackgroundTransparency = 1
	clip.ClipsDescendants = true
	clip.Position = UDim2.fromOffset(-20, 0)
	clip.Size = UDim2.fromOffset(tab[1] + wide + 20, foot + 20)
	clip.ZIndex = Z + 5
	clip.Visible = false
	clip.Parent = holder
	StageScreen.Plate(clip, tab[1] + 20, LOOK.Top, wide, foot - LOOK.Top, hard, LOOK.Corner[n] or LOOK.Corner[1], Z + 5)
	local words = {}
	for i, s in lines do
		local y = (LOOK.Words.Y[n] or LOOK.Words.Y[1])[i]
		table.insert(words, word(clip, `Words{i}`, s, textLeft + 20, y, Z + 11))
	end
	-- the mark, its middle where it folds, over both
	local record = UIKit.Images.DareMark
	local mark = Instance.new("ImageLabel")
	mark.Name = "DareMark"
	mark.BackgroundTransparency = 1
	mark.AnchorPoint = Vector2.new(0.5, 0.5)
	mark.Position = UDim2.fromOffset(LOOK.Mark.X, LOOK.Mark.Y)
	mark.Size = UDim2.fromOffset(record.Points.X, record.Points.Y)
	mark.ZIndex = MARK_Z
	mark.Parent = frame
	local scale = Instance.new("UIScale")
	scale.Parent = mark
	local made: Drawn = {
		Key = key,
		Frame = frame,
		Holder = holder,
		Clip = clip,
		Words = words,
		Mark = mark,
		Scale = scale,
		Look = look,
		Open = false,
		Rows = n,
		Text = text,
		Wide = wide,
	}
	lay(made, look)
	if unfold then
		open(made)
	end
	return made
end

local function drop(made: Drawn?)
	if made then
		if made.Holder then
			made.Holder:Destroy()
		end
		if made.Mark then
			made.Mark:Destroy()
		end
	end
end

function DareLine.Show(frame: Frame, hard: boolean, textLeft: number, key: string?, text: string?, look: string?)
	local was = drawn[frame]
	if key == nil or text == nil then
		drop(was)
		drawn[frame] = nil
		table.clear(shown)
		return
	end
	local state = look or "Holds"
	if was and was.Key == key then
		if was.Look ~= state then
			was.Look = state
			if was.Mark then
				lay(was, state)
				if state == "Kept" and not GuiService.ReducedMotionEnabled then
					flare(was)
				end
			end
		end
		return
	end
	drop(was)
	-- laid on the next frame, so its words measure in the line's own scale; a look that comes meanwhile is kept. It counts
	-- as shown only once laid: at a stretch's advance the dare comes before the line is built again for its stretch, and
	-- the line it first came to is gone by then
	local waiting = { Key = key, Look = state } :: any
	drawn[frame] = waiting
	task.defer(function()
		if drawn[frame] ~= waiting or frame.Parent == nil then
			return
		end
		local unfold = not shown[key]
		shown[key] = true
		drawn[frame] = build(frame, hard, textLeft, key, text, waiting.Look, unfold)
	end)
end

function DareLine.Said(frame: Frame?): { [string]: any }?
	local made = if frame then drawn[frame] else nil
	if made == nil or made.Mark == nil then
		return nil
	end
	local words = {}
	for _, w in made.Words do
		table.insert(words, w.Text)
	end
	-- Right: the open box's right edge, in screen pixels (the clip's, which ends where its plate does)
	local right = made.Frame.AbsolutePosition.X + (LOOK.Tab[1] + made.Wide) * Layers.Scale()
	return { Open = made.Open, Rows = made.Rows, Look = made.Look, Words = table.concat(words, " "), Kit = made.Mark:GetAttribute("Kit"), Wide = made.Wide, Right = right, Clip = made.Clip.Visible }
end

function DareLine.Preload()
	Glass.Preload({ UIKit.Images.DareMark, UIKit.Images.DareMarkDark, UIKit.Images.DareMarkKept })
end

return DareLine
