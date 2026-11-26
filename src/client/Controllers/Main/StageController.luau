--!strict
-- StageController (client): a ground's run of stretches as this player sees it (docs/test-requests.md, TR43, TR50;
-- StageService). The Arc panel opens from the Play panel's "Choose Arc" (ModeController) or when the server sends it
-- (StagePick, through the Festival Door), the run's card at its end (StageDone; UI.StageScreen). The run reads under Roblox's top bar from the player's
-- attributes (StageRun, StageKills, StageQuota, StageLast), on the panel's glass (AR42; tools/blender/stage_seam.py's
-- stage_line): the stretch's mark and "Stretch 2 of 4", its Shades on a short road with a notch a Shade, lit as they
-- fall, to its last foe's ring, and what's left at the right ("then the elite"). A fall steps the count at once and
-- eases the light onto its notch with a flash; the last foe's ring pops lit as it rises, and takes a check once the
-- stretch is cleared. Each stretch's gate shows as the server keeps it: in a run, open behind the run and at its own
-- stretch once done (Rules.Stages.Through); outside one, open once cleared on Normal. A set-back at one says why. Another
-- player's Hard foes (their For) stand faded for this one: not theirs to fight.
--   StageController.Said() -> (boolean, string)   whether the run's line shows, and its words, for tests
--   StageController.Gate(stage) -> boolean?       whether stage's gate shows shut, nil before it's streamed in
--   StageController.Dare() -> { [string]: any }?  the stretch's dare as the line shows it, for tests (DareLine.Said)
--   StageController.Shard() -> { [string]: any }?  the base's shard as the line's tab shows it, for tests (ShardTab.Said)
--   StageController.Pick()                        the Arc panel, opened or closed if it's the one open
--   StageController.Begin(ground, difficulty) -> boolean   a run begun as the Arc panel's press begins it

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Markers = require(Shared.World.Markers)
local Stages = require(Shared.Rules.Stages)
local Profile = require(Shared.Data.Profile)
local HudConfig = require(Shared.Config.Hud)
local UIKit = require(Shared.Config.UIKit)

local UI = script.Parent.Parent.Parent.UI
local Layers = require(UI.Layers)
local Toast = require(UI.Kit.Toast)
local Glass = require(UI.Kit.Glass)
local StageScreen = require(UI.StageScreen)
local DareLine = require(UI.DareLine)
local ShardTab = require(UI.ShardTab)
local Read = require(UI.Read)
local PlaceRole = require(Shared.Util.PlaceRole)
local GoalDefs = require(Shared.Definitions.Goals)
local ProfileController = require(script.Parent.Parent.Core.ProfileController)
local WorldConfig = require(Shared.Config.World)
local Screen = require(UI.Kit.Screen)
local HudController = require(script.Parent.HudController)
local Cues = require(script.Parent.FighterController.Cues)
local Grounds = require(Shared.Definitions.Grounds)

local StageController = {}

local player = Players.LocalPlayer
local SHUT = 0.5 -- a shut gate's transparency, as WorldService lays it
local FADED = 0.75 -- another player's Hard foe
local LOOK_EVERY = 0.25 -- seconds between looks at the gates and the foes
local SAY_GAP = 2 -- seconds between two set-back toasts

local LOOK = HudConfig.Stages
local L = LOOK.Line
local SEAM = UIKit.Palettes.SeamGlass
local WHITE = Color3.new(1, 1, 1)
local ROAD_Y = 34 -- the road's middle, down the line
local ROAD_SHORT = 30 -- the last notch's end, this far in from the line's right: the Shades' share of the road
local END_IN = 16 -- the last foe's ring, this far in from the line's right
local WORDS_GAP = 12 -- kept between the count and the words at the right

local saidAt = -math.huge

-- The run's line as it stands: built again when its run or quota changes.
type Line = {
	Key: string,
	Frame: Frame,
	Name: TextLabel,
	Count: TextLabel,
	Words: TextLabel,
	Left: number, -- the road's start
	Wide: number, -- the line's width, as fit() gave it
	Tight: boolean, -- the count without "Shades": the line too narrow for it beside the words
	Run: (share: number) -> (),
	Share: number,
	Flash: ImageLabel,
	End: Frame?,
	Look: string, -- the end ring's: "Waiting", "Risen" or "Cleared"
	Hard: boolean,
}
local line: Line? = nil

-- A lost run's results while its card may come back: Send another's picker closing over it brings it back, Retry lit if
-- someone leads now (docs/design.md, "A fall in the Festival").
local fell: { [string]: any }? = nil
local sendAnother: () -> ()

local on: StageScreen.On = {
	Begin = function(ground: string, difficulty: string): { [string]: any }
		local ok, answer = pcall(Net.Client.Invoke, "Stage", ground, difficulty)
		return if ok and type(answer) == "table" then answer else { Ok = false, Error = "NoAnswer" }
	end,
	Home = function(): { [string]: any }
		local ok, answer = pcall(Net.Client.Invoke, "Home")
		return if ok and type(answer) == "table" then answer else { Ok = false }
	end,
	Say = function(words: string)
		Toast.Show(words)
	end,
	Lead = function(): (boolean, number?)
		local lead = HudController.Lead()
		local state = if lead then lead:GetAttribute("State") else nil
		if lead and state ~= "Down" and state ~= "Home" and state ~= "Reset" then
			return true, nil
		end
		local untilAt = if lead and state == "Home" then lead:GetAttribute("StateUntil") else nil
		return false, if type(untilAt) == "number" and untilAt > 0 then untilAt else nil
	end,
	Another = function()
		sendAnother()
	end,
}

sendAnother = function()
	local results = fell
	HudController.SendAnother()
	local picker = Screen.Current()
	if results == nil or picker == nil or picker == StageScreen.Name then
		return
	end
	local connection: any = nil
	connection = Screen.Closed:Connect(function(name: string)
		if name ~= picker then
			return
		end
		connection:Disconnect()
		-- back on the card, unless a run began or another screen opened meanwhile (deferred: a screen opening closes the one
		-- before it first, so Closed fires before the new one is open)
		task.defer(function()
			if fell == results and Screen.Current() == nil and player:GetAttribute("StageRun") == nil then
				StageScreen.Results(results :: { [string]: any }, on)
			end
		end)
	end)
end

-- Where the line stands, in the HUD's points: the screen's middle, moved clear of the HUD's pieces beside it (L.Clear:
-- the lead's card at the left, the Credits at the right) when the middle would meet them, and narrower only when the room
-- between them is (the smallest phones), its road the shorter. Returns its width and its left.
local function fit(): (number, number)
	local hud = Layers.Get("Hud")
	local scale = Layers.Scale()
	local room = hud.AbsoluteSize / scale
	local from, to = 0, room.X
	local top, foot = L.Down, L.Down + L.Tall
	for _, name in L.Clear do
		local piece = hud:FindFirstChild(name)
		if piece and piece:IsA("GuiObject") then
			local at = (piece.AbsolutePosition - hud.AbsolutePosition) / scale
			local size = piece.AbsoluteSize / scale
			if size.X > 0 and at.Y < foot and at.Y + size.Y > top then
				if at.X + size.X / 2 < room.X / 2 then
					from = math.max(from, at.X + size.X + L.Gap)
				else
					to = math.min(to, at.X - L.Gap)
				end
			end
		end
	end
	local wide = math.clamp(math.floor(to - from), L.Least, L.Wide)
	return wide, math.clamp(room.X / 2 - wide / 2, from, math.max(from, to - wide))
end

-- The line's frame and its fixed pieces, for a run of `stage` on Hard or not, with `quota` Shades.
local function build(key: string, hard: boolean, stage: number, quota: number): Line
	local wide, x0 = fit()
	local roadRight, endX = wide - ROAD_SHORT, wide - END_IN
	local frame = Instance.new("Frame")
	frame.Name = "StageRun"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromOffset(wide, L.Tall)
	frame.Position = UDim2.fromOffset(x0, L.Down)
	StageScreen.Plate(frame, 0, 0, wide, L.Tall, hard, L.Corner, 1)
	StageScreen.Mark(frame, "Mark", 8, 9, hard, 6)
	local tx = 8 + LOOK.Badge.Side + 10
	local head = Instance.new("Frame")
	head.Name = "Head"
	head.BackgroundTransparency = 1
	head.Position = UDim2.fromOffset(tx, 3)
	head.Size = UDim2.fromOffset(wide - tx - 130, 22)
	head.ZIndex = 7
	head.Parent = frame
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, 12)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = head
	local stretches = #((Stages.Of(WorldConfig.Row.Ground) or {}) :: { any })
	local name = Glass.Label(head, "Name", `Stretch {stage} of {stretches}`, LOOK.Text.Title, SEAM.Text, 0, 0, 0, 22, Enum.TextXAlignment.Left, true, 7)
	name.AutomaticSize = Enum.AutomaticSize.X
	name.LayoutOrder = 1
	local count = Glass.Label(head, "Count", "", LOOK.Text.Small, SEAM.Text, 0, 0, 0, 22, Enum.TextXAlignment.Left, false, 7)
	count.AutomaticSize = Enum.AutomaticSize.X
	count.LayoutOrder = 2
	local words = Glass.Label(frame, "Words", "", LOOK.Text.Small, SEAM.Soft, wide - 10 - 130, 5, 130, 20, Enum.TextXAlignment.Right, false, 7)
	-- Its road: a dark conduit with a notch a Shade, its light from under the name toward the ring.
	local left = tx
	Glass.Fill(frame, "Road", left, ROAD_Y - 3, endX - 6 - left, 6, 1.5, SEAM.Channel, 6)
	Glass.Edge(frame, "RoadEdge", left, ROAD_Y - 3, endX - 6 - left, 6, 1.5, SEAM.Edge, 0.9, nil, 6)
	for i = 1, quota - 1 do
		local notch = Instance.new("Frame")
		notch.Name = `Notch{i}`
		notch.BorderSizePixel = 0
		notch.BackgroundColor3 = SEAM.Edge
		notch.Size = UDim2.fromOffset(1, 5)
		notch.Position = UDim2.fromOffset(left + i * (roadRight - left) / quota - 0.5, ROAD_Y - 2.5)
		notch.ZIndex = 7 -- under the light: the lit road runs unbroken, the dark one shows its notches
		notch.Parent = frame
	end
	local _, run = StageScreen.Road(frame, "Lit", left + 1, endX - 6, ROAD_Y, 1.6, endX - 6 - left, hard, 8)
	local flash = Glass.Bloom(frame, "Flash", left, ROAD_Y, 16, 10, WHITE, 0, 12)
	flash.ImageTransparency = 1
	run(0)
	frame.Parent = Layers.Get("Hud")
	return {
		Key = key,
		Frame = frame,
		Name = name,
		Count = count,
		Words = words,
		Left = left,
		Wide = wide,
		Tight = false,
		Run = run,
		Share = 0,
		Flash = flash,
		End = nil,
		Look = "",
		Hard = hard,
	}
end

-- The end ring: the channel's disc while its last foe waits; lit with an ink dot once it's up (popping over, then
-- settling); a check once the stage is cleared.
local function ending(made: Line, look: string, pop: boolean)
	if made.Look == look then
		return
	end
	made.Look = look
	local old = made.End
	if old then
		old:Destroy()
	end
	local a = StageScreen.Accent(made.Hard)
	local holder: Frame
	if look == "Cleared" then
		holder = StageScreen.Check(made.Frame, "End", made.Wide - END_IN, ROAD_Y, 7.5, made.Hard, 11)
		Glass.Bloom(holder, "Glow", 0, 0, 30, 30, a.Glow, 0.45, 10)
	else
		holder = Instance.new("Frame")
		holder.Name = "End"
		holder.BackgroundTransparency = 1
		holder.Position = UDim2.fromOffset(made.Wide - END_IN, ROAD_Y)
		holder.ZIndex = 11
		local scale = Instance.new("UIScale")
		scale.Parent = holder
		if look == "Risen" then
			Glass.Bloom(holder, "Glow", 0, 0, 34, 34, a.Glow, 0.6, 10)
			Glass.Disc(holder, "Disc", 0, 0, 6.5, a.Lit, 11)
			Glass.Circle(holder, "Edge", 0, 0, 6.5, WHITE, 1, 0.9, nil, 12)
			Glass.Disc(holder, "Dot", 0, 0, 2.2, SEAM.Ink :: Color3, 13)
		else
			Glass.Disc(holder, "Disc", 0, 0, 6.5, SEAM.Channel, 11)
			Glass.Circle(holder, "Edge", 0, 0, 6.5, SEAM.Edge, 1.2, 1, nil, 12)
		end
		holder.Parent = made.Frame
	end
	made.End = holder
	local scale = holder:FindFirstChildOfClass("UIScale")
	if pop and scale and look ~= "Waiting" and not GuiService.ReducedMotionEnabled then
		local M = LOOK.Motion
		local grown = scale :: UIScale
		grown.Scale = M.Pop
		Glass.Ease(holder, M.Settle, function(u: number)
			grown.Scale = M.Pop + (1 - M.Pop) * u
		end, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end
end

-- On a narrow line (the smallest phones, where text keeps its legible floor) the words give way to the count, a frame
-- after it's laid: the count drops "Shades" first, then the words step out; the ring at the road's end still says it.
local function tidy(made: Line)
	if line ~= made or made.Frame.Parent == nil then
		return
	end
	local count, words = made.Count, made.Words
	local function clear(): boolean
		local before = if count.Text ~= "" then count else made.Name
		local ends = before.AbsolutePosition.X + before.TextBounds.X
		return ends + WORDS_GAP * Layers.Scale() <= words.AbsolutePosition.X + words.AbsoluteSize.X - words.TextBounds.X
	end
	words.Visible = true
	if not clear() and not made.Tight and count.Text ~= "" then
		made.Tight = true
		count.Text = (string.gsub(count.Text, " Shades$", ""))
	end
	words.Visible = clear()
end

-- The stretch's dare under the line (TR54): StageDare "<stage> <id>", StageDareLook its mark's state.
local function dareText(id: string): string?
	for _, row in GoalDefs.Dares do
		if row.Id == id then
			return row.Text
		end
	end
	return if GoalDefs.Fallback.Id == id then GoalDefs.Fallback.Text else nil
end

local function showDare()
	local made = line
	if made == nil or made.Frame.Parent == nil then
		return
	end
	local key = player:GetAttribute("StageDare")
	local look = player:GetAttribute("StageDareLook")
	local id = if type(key) == "string" then string.match(key, "^%d+ (%w+)$") else nil
	local text = if id then dareText(id) else nil
	DareLine.Show(made.Frame, made.Hard, made.Left, if text then key :: string else nil, text, if type(look) == "string" then look else nil)
end

-- The base's shard under the line (TR53's Festival half; UI.ShardTab), away from the base only: the newest broken while
-- any waits at home, else the one breaking soonest and its time left, read on a copy advanced to now. The notice once a
-- shard breaks (the save's Ready grows), after the dare's tab has closed.
local readyHad: number? = nil -- the save's broken shards when last looked at, nil before the first look
local noticeOwed = false
local function shardState(view: Profile.View): ShardTab.State?
	local ready = view.Base.Ready
	if #ready > 0 then
		return { Def = ready[#ready].Def, Ready = true }
	end
	local base = Read.Base(view, workspace:GetServerTimeNow())
	local ahead = base.Data.Base.Ready
	if #ahead > 0 then
		return { Def = ahead[1].Def, Ready = false, Left = 0 } -- broken on the copy: the server's word is on its way
	end
	local soonest, def = math.huge, nil
	for _, chamber in base.Data.Base.Chambers do
		if chamber.Work then
			local left = Read.Left(base, chamber.Work)
			if left < soonest then
				soonest, def = left, chamber.Work.Def
			end
		end
	end
	return if def then { Def = def, Ready = false, Left = soonest } else nil
end

local function showShard()
	local view = ProfileController.Get()
	if view and not PlaceRole.Is("Main") then
		local count = #view.Base.Ready
		if readyHad ~= nil and count > readyHad then
			noticeOwed = true
		end
		readyHad = count
	end
	local made = line
	if made == nil or made.Frame.Parent == nil or not made.Frame.Visible then
		return
	end
	local state = if view and not PlaceRole.Is("Main") then shardState(view) else nil
	ShardTab.Show(made.Frame, made.Hard, state)
	if noticeOwed and state and state.Ready then
		local dare = DareLine.Said(made.Frame)
		if dare == nil or dare.Open ~= true then
			noticeOwed = false
			ShardTab.Notice(made.Frame)
		end
	end
end

local function showLine()
	local run = player:GetAttribute("StageRun")
	if type(run) ~= "string" then
		if line then
			DareLine.Show(line.Frame, line.Hard, line.Left, nil, nil, nil)
			ShardTab.Show(line.Frame, line.Hard, nil)
			line.Frame.Visible = false
		end
		return
	end
	local difficulty, stage = Stages.Parse(run)
	local kills, quota, last = player:GetAttribute("StageKills"), player:GetAttribute("StageQuota"), player:GetAttribute("StageLast")
	local q = if type(quota) == "number" then quota else 0
	local k = if type(kills) == "number" then kills else 0
	local key = `{run} {q}`
	local was = line
	local fresh = was == nil or was.Key ~= key or was.Frame.Parent == nil
	local now: Line
	if fresh or was == nil then
		if was then
			was.Frame:Destroy()
		end
		now = build(key, difficulty == "Hard", stage or 1, q)
		line = now
	else
		now = was
	end
	now.Frame.Visible = true
	now.Count.Text = if q <= 0 then "" elseif now.Tight then `{math.min(k, q)} / {q}` else `{math.min(k, q)} / {q} Shades`
	-- Its last foe by name: the elite, or on the keeper's stretch the keeper (research's must-fix 4 on TR50).
	local ground = WorldConfig.Row.Ground
	local final = Stages.Last(ground, stage or 1)
	local foe = if final and final.Kind == "Keeper" then `the {StageScreen.KeeperName(ground)}` else "the elite"
	if last == true then
		now.Words.Text = if q > 0 and k < q then `{foe} down` else "cleared"
	else
		now.Words.Text = if q > 0 then `then {foe}` else foe
	end
	-- The light: to the Shades fallen, or through to the ring once the last foe is up.
	local left, stop = now.Left, now.Wide - END_IN - 6
	local risen = q == 0 or k >= q
	local head = if risen then stop else left + math.min(k, q) / math.max(q, 1) * (now.Wide - ROAD_SHORT - left)
	local share = math.clamp((head - left - 1) / math.max(stop - left - 1, 1), 0, 1)
	local from = now.Share
	now.Share = share
	if fresh or share <= from or GuiService.ReducedMotionEnabled then
		now.Run(share)
	else
		local flash, M = now.Flash, LOOK.Motion
		Glass.Ease(now.Frame, M.Notch, function(u: number)
			local at = from + (share - from) * u
			now.Run(at)
			flash.Position = UDim2.fromOffset(left + 1 + at * (stop - left - 1), ROAD_Y)
			flash.ImageTransparency = 1 - 0.8 * (1 - u)
		end, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end
	ending(now, if last == true then "Cleared" elseif risen then "Risen" else "Waiting", not fresh)
	task.defer(tidy, now)
	showDare()
	showShard()
end

local function look()
	local view = ProfileController.Get()
	-- The gates, shut or open to this player: in a run, by the run's own order (its stretch done once its quota and its
	-- last stop are in), else by the record (StageService's `shut`).
	local _, at = Stages.Parse(player:GetAttribute("StageRun"))
	local kills, quota = player:GetAttribute("StageKills"), player:GetAttribute("StageQuota")
	local done = player:GetAttribute("StageLast") == true and (if type(kills) == "number" then kills else 0) >= (if type(quota) == "number" then quota else 0)
	for _, gate in Markers.All("StageGate") do
		if not gate:IsA("BasePart") then
			continue
		end
		local stage, ground = gate:GetAttribute("Stage"), gate:GetAttribute("Ground")
		local open = false
		if type(stage) == "number" and type(ground) == "string" then
			open = if at then Stages.Through(stage, at, done) else view ~= nil and Stages.Passes(view, ground, stage)
		end
		gate.Transparency = if open then 1 else SHUT
	end
	-- Another player's Hard foes, faded.
	local fighters = workspace:FindFirstChild("Fighters")
	for _, model in if fighters then fighters:GetChildren() else {} do
		local owner = model:GetAttribute("For")
		if type(owner) ~= "number" or model:GetAttribute("Stage") == nil then
			continue
		end
		local fade = if owner == player.UserId then 0 else FADED
		if model:GetAttribute("Faded") ~= fade then
			model:SetAttribute("Faded", fade)
			for _, part in model:GetDescendants() do
				if part:IsA("BasePart") then
					part.LocalTransparencyModifier = fade
				end
			end
		end
	end
end

function StageController.Said(): (boolean, string)
	local now = line
	if now == nil or now.Frame.Parent == nil then
		return false, ""
	end
	local words = { now.Name.Text }
	if now.Count.Text ~= "" then
		table.insert(words, now.Count.Text)
	end
	if now.Words.Visible then
		table.insert(words, now.Words.Text)
	end
	return now.Frame.Visible, table.concat(words, "   ·   ")
end

function StageController.Gate(stage: number): boolean?
	local gate = Markers.Find("StageGate", { Stage = stage })
	return if gate and gate:IsA("BasePart") then gate.Transparency < 1 else nil
end

-- The Festival of Battles' menu, from the dock's Play tile or the base's door (TR45): closed if it's the one open.
function StageController.Pick()
	local view = ProfileController.Get()
	if view == nil then
		return
	end
	if Screen.Current() == StageScreen.Name then
		Screen.Close()
		return
	end
	StageScreen.Pick(WorldConfig.Row.Ground, view, on)
end

-- A run on `difficulty` begun from the Play panel (ModeController), through the Arc panel's own begin. True once begun.
function StageController.Begin(ground: string, difficulty: string): boolean
	return StageScreen.Begin(on, ground, difficulty)
end

function StageController.Dare(): { [string]: any }?
	return DareLine.Said(if line then line.Frame else nil)
end

function StageController.Shard(): { [string]: any }?
	return ShardTab.Said(if line then line.Frame else nil)
end

function StageController.Start()
	-- A new best's card for the listening panel (TR64, Play the moment): the first ground's first stretch, won in its best.
	Cues.Stage("Record", function()
		local ground = Grounds.List[1].Id
		local count = #((Stages.Of(ground) or {}) :: { any })
		StageScreen.Results({ Ground = ground, Difficulty = "Normal", Stage = count, Count = count, Won = true, Seconds = 185, Best = 185, From = 1, Credits = 240, Shards = 2, Chests = 1 }, on)
		Cues.Moment("Record")
	end)
	Net.Client.On("StagePick", function(payload: any)
		local view = ProfileController.Get()
		if type(payload) == "table" and type(payload.Ground) == "string" and view then
			StageScreen.Pick(payload.Ground, view, on)
		end
	end)
	Net.Client.On("StageDone", function(results: any)
		if type(results) == "table" and type(results.Ground) == "string" and type(results.Stage) == "number" then
			fell = if results.Won ~= true then results else nil
			StageScreen.Results(results, on)
			if StageScreen.NewBest(results) then
				Cues.Moment("Record") -- a new best (TR64), as its card rises
			end
		end
	end)
	Net.Client.On("StageGate", function(payload: any)
		local now = os.clock()
		if type(payload) == "table" and type(payload.Stage) == "number" and now - saidAt > SAY_GAP then
			saidAt = now
			Toast.Show(`Clear Stretch {payload.Stage} to go on`)
		end
	end)
	for _, name in { "StageRun", "StageKills", "StageQuota", "StageLast" } do
		player:GetAttributeChangedSignal(name):Connect(showLine)
		player:GetAttributeChangedSignal(name):Connect(look)
	end
	DareLine.Preload()
	player:GetAttributeChangedSignal("StageDare"):Connect(showDare)
	player:GetAttributeChangedSignal("StageDareLook"):Connect(showDare)
	showLine()
	-- The screen's room changed: the line stands again clear of the HUD's pieces, built again if its width changes.
	local function refit()
		local made = line
		if made and made.Frame.Parent then
			local wide, x0 = fit()
			if wide ~= made.Wide then
				made.Key = ""
				showLine()
			else
				made.Frame.Position = UDim2.fromOffset(x0, L.Down)
			end
		end
	end
	Layers.Changed:Connect(function()
		task.defer(refit)
	end)
	Layers.Get("Hud"):GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		task.defer(refit)
	end)
	ProfileController.Changed:Connect(function(_view: Profile.View)
		look()
		showShard()
	end)
	local since, shardSince = 0, 0
	RunService.Heartbeat:Connect(function(dt: number)
		shardSince += dt
		if shardSince >= HudConfig.Return.Run.Every then
			shardSince = 0
			showShard()
		end
		since += dt
		if since >= LOOK_EVERY then
			since = 0
			look()
		end
	end)
end

return StageController
