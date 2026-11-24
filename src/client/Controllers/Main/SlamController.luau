--!strict
-- SlamController (client): a keeper's marked slam as this player sees it, in grey (docs/test-requests.md, TR44;
-- FightService's Mark attributes; SlamService). While a fighter's footprint is down, a flat white ring of
-- Config.Combat.Keeper.Mark's radius lies on the ground at its centre, and inside it a translucent disc grows from the
-- middle and meets the ring on the Slam, so the fill tells the time; both go on the Slam, and the column takes over.
-- Nothing else is marked: no screen text, no icon. In mode B (Config.Combat.Keeper.Out.Mode, read live), and only in a
-- keeper's try, the Recall: a round button by the right thumb, R and the gamepad's ButtonY, its cooldown on its face.
-- AR52's two tells, in grey until the effects teammate's looks (Config.Combat.Guard.Look, Dasher.Line):
-- * a Dasher's line (MarkTo set): a lane outlined on the ground from its feet to the line's end, its fill growing from
--   the Dasher and reaching the end on the hit;
-- * a Guard's raised shield (GuardUntil): a grey pane before it, that brightens as a hit glances off and flashes white
--   and goes when one breaks it (GuardBroke).
-- AR58's Support, in grey until the effects teammate's (Config.Combat.Support.Look):
-- * a shield it gave (ShieldLook "SupportShield"): a grey ball round the one it shields while ShieldUntil holds, until a
--   Lasting row of that name is switched on (Config.Effects);
-- * a heal it gave (a Heal whose healer is casting SupportCast): a light ball on the one it mends, growing and fading,
--   until a SupportHeal row is written.
--   SlamController.Veil(fighter) -> SphereHandleAdornment?   a Support's shield's ball, for tests
--   SlamController.Ring(fighter) -> (ring, disc)?   a fighter's footprint's two adornments, for tests
--   SlamController.Line(fighter) -> (edges, fill)?  a Dasher's line's outline and fill, for tests
--   SlamController.Pane(fighter) -> BoxHandleAdornment?   a Guard's raised pane, for tests
--   SlamController.Recall() -> TextButton?          the Recall button while it shows, for tests
--   SlamController.Press() -> { [string]: any }     a Recall as a press asks it, the server's answer

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Combat = require(Shared.Config.Combat)
local EffectsConfig = require(Shared.Config.Effects)
local MarkRule = require(Shared.Rules.Mark)

local UI = script.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Layers = require(UI.Layers)
local Text = require(UI.Kit.Text)
local Button = require(UI.Kit.Button)
local Skin = require(UI.Kit.Skin)

local SlamController = {}

local player = Players.LocalPlayer
local RING_UP = 0.06 -- studs over the ground: clear of it, so it never flickers into the paving
local RING_THICK = 0.04
local GROUND_RAY = 14 -- studs down from the fighter's root height that the ground is looked for
local RECALL_SIDE = 84 -- the button's side, authored: past the 52 a touch needs at the smallest scale
local RECALL_INSET = Vector2.new(28, 118) -- from the screen's bottom right corner: by the right thumb, over the dock's line
local ACTION = "NL_Recall"

-- A footprint drawn: the keeper's ring and disc, or a line's outline and fill (Length long).
type Drawn = {
	Holder: BasePart,
	Ring: CylinderHandleAdornment?,
	Disc: CylinderHandleAdornment?,
	Edges: { BoxHandleAdornment }?,
	Fill: BoxHandleAdornment?,
	Length: number,
	Slam: number,
	Down: number,
	Radius: number,
}
-- A Guard's pane: its adornment, and when a glance last brightened it (os.clock).
type Pane = { Box: BoxHandleAdornment, Glanced: number }

local drawn: { [Model]: Drawn } = {}
local panes: { [Model]: Pane } = {}
local veils: { [Model]: SphereHandleAdornment } = {}
local PANE_GREY = Color3.fromRGB(196, 199, 206)
local PANE_THICK = 0.12
local recall: TextButton? = nil
local recallFace: Frame? = nil
local recallWord: TextLabel? = nil
local bound = false

local function now(): number
	return workspace:GetServerTimeNow()
end

local function fighters(): Instance?
	return workspace:FindFirstChild("Fighters")
end

local function groundUnder(at: Vector3): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local skip = {}
	for _, d in { fighters(), player.Character } do
		if d then
			table.insert(skip, d)
		end
	end
	params.FilterDescendantsInstances = skip
	local hit = workspace:Raycast(at + Vector3.new(0, 1, 0), Vector3.new(0, -GROUND_RAY, 0), params)
	return if hit then hit.Position.Y else at.Y - 3
end

local function erase(model: Model)
	local d = drawn[model]
	if d then
		drawn[model] = nil
		d.Holder:Destroy()
	end
end

local function holderAt(cframe: CFrame): BasePart
	local holder = Instance.new("Part")
	holder.Name = "NL_Mark"
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.new(0.2, 0.2, 0.2)
	holder.CFrame = cframe
	return holder
end

-- A Dasher's line (AR52): the holder at its start, looking down it, so a box's -Z runs along the line.
local function drawLine(model: Model, at: Vector3, to: Vector3, half: number, down: number, slam: number)
	local line = Combat.Dasher.Line
	local y = groundUnder(at)
	local from = Vector3.new(at.X, y + RING_UP, at.Z)
	local way = Vector3.new(to.X - at.X, 0, to.Z - at.Z)
	local length = way.Magnitude
	if length < 0.1 then
		return
	end
	local holder = holderAt(CFrame.lookAt(from, from + way))
	local function box(name: string, size: Vector3, offset: CFrame, transparency: number): BoxHandleAdornment
		local a = Instance.new("BoxHandleAdornment")
		a.Name = name
		a.Adornee = holder
		a.Size = size
		a.CFrame = offset
		a.Color3 = Color3.new(1, 1, 1)
		a.Transparency = transparency
		a.AlwaysOnTop = false
		a.ZIndex = 1
		a.Parent = holder
		return a
	end
	local edge = math.min(line.Edge, half)
	local edges = {
		box("Left", Vector3.new(edge, RING_THICK, length), CFrame.new(-half + edge / 2, 0, -length / 2), 0.05),
		box("Right", Vector3.new(edge, RING_THICK, length), CFrame.new(half - edge / 2, 0, -length / 2), 0.05),
		box("End", Vector3.new(half * 2, RING_THICK, edge), CFrame.new(0, 0, -length + edge / 2), 0.05),
	}
	local fill = box("Fill", Vector3.new(math.max(0.01, half * 2 - edge * 2), RING_THICK, 0.01), CFrame.new(0, 0, -0.005), line.Fill)
	holder.Parent = workspace
	drawn[model] = { Holder = holder, Edges = edges, Fill = fill, Length = length, Slam = slam, Down = down, Radius = half }
end

local function draw(model: Model)
	erase(model)
	local at, radius, down, slam = model:GetAttribute("MarkAt"), model:GetAttribute("MarkRadius"), model:GetAttribute("MarkDown"), model:GetAttribute("MarkSlam")
	if typeof(at) ~= "Vector3" or type(radius) ~= "number" or type(down) ~= "number" or type(slam) ~= "number" then
		return
	end
	local to = model:GetAttribute("MarkTo")
	if typeof(to) == "Vector3" then
		drawLine(model, at :: Vector3, to :: Vector3, radius :: number, down :: number, slam :: number)
		return
	end
	local look = Combat.Keeper.Mark
	local y = groundUnder(at :: Vector3)
	-- a cylinder adornment's axis is its CFrame's look: turned to stand up, it lies flat on the ground
	local holder = holderAt(CFrame.new((at :: Vector3).X, y + RING_UP, (at :: Vector3).Z) * CFrame.Angles(math.rad(90), 0, 0))
	local function adorn(name: string, transparency: number): CylinderHandleAdornment
		local a = Instance.new("CylinderHandleAdornment")
		a.Name = name
		a.Adornee = holder
		a.Height = RING_THICK
		a.Color3 = Color3.new(1, 1, 1)
		a.Transparency = transparency
		a.AlwaysOnTop = false
		a.ZIndex = 1
		a.Parent = holder
		return a
	end
	local ring = adorn("Ring", 0.05)
	ring.Radius = radius :: number
	ring.InnerRadius = math.max(0, (radius :: number) - look.Edge)
	local disc = adorn("Disc", look.Fill)
	disc.Radius = 0.01
	holder.Parent = workspace
	drawn[model] = { Holder = holder, Ring = ring, Disc = disc, Length = 0, Slam = slam :: number, Down = down :: number, Radius = radius :: number }
end

local function paneOff(model: Model)
	local pane = panes[model]
	if pane then
		panes[model] = nil
		pane.Box:Destroy()
	end
end

-- A Guard's shield raised (AR52): its grey pane before its root, while the server's GuardUntil holds.
local function paneOn(model: Model)
	local untilTime = model:GetAttribute("GuardUntil")
	local root = model:FindFirstChild("HumanoidRootPart")
	if type(untilTime) ~= "number" or now() >= untilTime or root == nil or not root:IsA("BasePart") then
		paneOff(model)
		return
	end
	if panes[model] then
		return
	end
	local look = Combat.Guard.Look
	local k = model:GetScale() -- the elite's pane at its size (AR57)
	local box = Instance.new("BoxHandleAdornment")
	box.Name = "NL_GuardPane"
	box.Adornee = root
	box.Size = Vector3.new(look.Wide * k, look.High * k, PANE_THICK)
	box.CFrame = CFrame.new(0, look.Up * k, -look.Ahead * k)
	box.Color3 = PANE_GREY
	box.Transparency = look.Transparency
	box.AlwaysOnTop = false
	box.ZIndex = 1
	box.Parent = root
	panes[model] = { Box = box, Glanced = -math.huge }
end

-- Broken open: a white flash where the pane stood, gone in Flash seconds.
local function paneBreak(model: Model)
	paneOff(model)
	local root = model:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") then
		return
	end
	local look = Combat.Guard.Look
	local k = model:GetScale()
	local box = Instance.new("BoxHandleAdornment")
	box.Name = "NL_GuardBreak"
	box.Adornee = root
	box.Size = Vector3.new(look.Wide * 1.15 * k, look.High * 1.15 * k, PANE_THICK)
	box.CFrame = CFrame.new(0, look.Up * k, -look.Ahead * k)
	box.Color3 = Color3.new(1, 1, 1)
	box.Transparency = 0.05
	box.AlwaysOnTop = false
	box.ZIndex = 1
	box.Parent = root
	task.delay(look.Flash, function()
		box:Destroy()
	end)
end

-- AR58: a shield from a Support holds on `model`, and no look of the effects teammate's draws it yet.
local function veiled(model: Model): boolean
	local untilTime = model:GetAttribute("ShieldUntil")
	return model.Parent ~= nil and model:GetAttribute("ShieldLook") == "SupportShield" and EffectsConfig.Lasting.SupportShield ~= true
		and type(untilTime) == "number" and now() < untilTime and model:GetAttribute("State") ~= "Down"
end

local function veilOff(model: Model)
	local ball = veils[model]
	if ball then
		veils[model] = nil
		ball:Destroy()
	end
end

local function veilOn(model: Model)
	local root = model:FindFirstChild("HumanoidRootPart")
	if not veiled(model) or root == nil or not root:IsA("BasePart") then
		veilOff(model)
		return
	end
	if veils[model] then
		return
	end
	local look = Combat.Support.Look
	local ball = Instance.new("SphereHandleAdornment")
	ball.Name = "NL_SupportVeil"
	ball.Adornee = root
	ball.Radius = look.Radius * model:GetScale()
	ball.Color3 = PANE_GREY
	ball.Transparency = look.Transparency
	ball.AlwaysOnTop = false
	ball.ZIndex = 1
	ball.Parent = root
	veils[model] = ball
end

-- AR58: one a Support mends, a light ball growing from its body's size and fading out over Pop.Seconds.
local function mendPop(model: Model)
	local root = model:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") or (EffectsConfig.Rows :: any).SupportHeal ~= nil then
		return
	end
	local look = Combat.Support.Look
	local pop = look.Pop
	local size = look.Radius * model:GetScale()
	local ball = Instance.new("SphereHandleAdornment")
	ball.Name = "NL_SupportMend"
	ball.Adornee = root
	ball.Radius = size
	ball.Color3 = Color3.new(1, 1, 1)
	ball.Transparency = pop.Transparency
	ball.AlwaysOnTop = false
	ball.ZIndex = 1
	ball.Parent = root
	local began = os.clock()
	local connection: RBXScriptConnection? = nil
	connection = RunService.RenderStepped:Connect(function()
		local share = (os.clock() - began) / math.max(pop.Seconds, 0.01)
		if share >= 1 or ball.Parent == nil then
			(connection :: RBXScriptConnection):Disconnect()
			ball:Destroy()
			return
		end
		ball.Radius = size * (1 + (pop.Grow - 1) * share)
		ball.Transparency = pop.Transparency + (1 - pop.Transparency) * share
	end)
end

local function watch(model: Instance)
	if not model:IsA("Model") then
		return
	end
	if model:GetAttribute("MarkSlam") ~= nil then
		draw(model)
	end
	model:GetAttributeChangedSignal("MarkSlam"):Connect(function()
		if model:GetAttribute("MarkSlam") ~= nil then
			draw(model)
		else
			erase(model)
		end
	end)
	paneOn(model)
	model:GetAttributeChangedSignal("GuardUntil"):Connect(function()
		paneOn(model)
	end)
	model:GetAttributeChangedSignal("GuardBroke"):Connect(function()
		paneBreak(model)
	end)
	veilOn(model)
	model:GetAttributeChangedSignal("ShieldUntil"):Connect(function()
		veilOn(model)
	end)
	model.Destroying:Connect(function()
		erase(model)
		paneOff(model)
		veilOff(model)
	end)
end

local function stepMarks()
	local t = now()
	for model, d in drawn do
		if t >= d.Slam or model.Parent == nil then
			erase(model) -- gone on the Slam: the column takes over
			continue
		end
		-- the fill tells the time: it meets the ring on the Slam, or the line's end on its hit
		local share = MarkRule.Fill(t, d.Down, d.Slam)
		local disc, fill = d.Disc, d.Fill
		if disc then
			disc.Radius = math.max(0.01, d.Radius * share)
		elseif fill then
			local long = math.max(0.01, d.Length * share)
			fill.Size = Vector3.new(fill.Size.X, RING_THICK, long)
			fill.CFrame = CFrame.new(0, 0, -long / 2)
		end
	end
	local look = Combat.Guard.Look
	for model, pane in panes do
		local untilTime = model:GetAttribute("GuardUntil")
		if model.Parent == nil or type(untilTime) ~= "number" or t >= untilTime or model:GetAttribute("State") == "Down" then
			paneOff(model)
			continue
		end
		-- a glance brightens it, easing back over Flash
		local since = os.clock() - pane.Glanced
		local lift = math.clamp(1 - since / math.max(look.Flash, 0.01), 0, 1)
		pane.Box.Transparency = look.Transparency * (1 - 0.7 * lift)
	end
	for model in veils do
		if not veiled(model) then
			veilOff(model)
		end
	end
end

-- B's Recall: what a press asks the server.
function SlamController.Press(): { [string]: any }
	local ok, answer = pcall(Net.Client.Invoke, "Recall")
	return if ok and type(answer) == "table" then answer else { Ok = false, Error = "NoAnswer" }
end

local function shows(): boolean
	return MarkRule.Mode(Combat.Keeper.Out.Mode) == "B" and player:GetAttribute("Try") ~= nil
end

local function makeRecall(): TextButton
	local side = RECALL_SIDE
	local button = Button.new({
		Name = "Recall",
		Text = "",
		Bare = true,
		Size = UDim2.fromOffset(side, side),
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -RECALL_INSET.X, 1, -RECALL_INSET.Y),
		Parent = Layers.Get("Hud"),
		OnPress = function(): boolean
			local answer = SlamController.Press()
			return answer.Ok == true
		end,
	})
	local skin = Skin.Of(button) -- in the face, so it squeezes with it
	local face = Instance.new("Frame")
	face.Name = "Round"
	face.Size = UDim2.fromScale(1, 1)
	face.BackgroundColor3 = Theme.Colour.PlateHigh
	face.BackgroundTransparency = Theme.Transparency.Plate
	face.ZIndex = 10
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = face
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Colour.Text
	stroke.Thickness = 2
	stroke.Transparency = 0.2
	stroke.Parent = face
	face.Parent = skin
	local word = Text.new({ Name = "Word", Size = Theme.Text.Body, Font = Theme.Font.Strong, Parent = face })
	word.Text = "Recall"
	word.ZIndex = 11
	recallFace, recallWord = face, word
	return button
end

local function bind(on: boolean)
	if on == bound then
		return
	end
	bound = on
	if on then
		ContextActionService:BindAction(ACTION, function(_, state: Enum.UserInputState): Enum.ContextActionResult
			if state == Enum.UserInputState.Begin and recall then
				Button.Press(recall)
			end
			return Enum.ContextActionResult.Sink
		end, false, Enum.KeyCode.R, Enum.KeyCode.ButtonY)
	else
		ContextActionService:UnbindAction(ACTION)
	end
end

local function stepRecall()
	local show = shows()
	if show and recall == nil then
		recall = makeRecall()
	end
	local button = recall
	if button then
		button.Visible = show
	end
	bind(show)
	local face, word = recallFace, recallWord
	if not show or face == nil or word == nil then
		return
	end
	-- the cooldown on its face: the seconds left, dimmed, until it's ready
	local ready = player:GetAttribute("RecallReady")
	local left = if type(ready) == "number" then ready - now() else 0
	if left > 0 then
		word.Text = tostring(math.ceil(left))
		face.BackgroundTransparency = 0.5
		word.TextTransparency = 0.3
	else
		word.Text = "Recall"
		face.BackgroundTransparency = Theme.Transparency.Plate
		word.TextTransparency = 0
	end
end

function SlamController.Ring(model: Model): (CylinderHandleAdornment?, CylinderHandleAdornment?)
	local d = drawn[model]
	return if d then d.Ring else nil, if d then d.Disc else nil
end

function SlamController.Line(model: Model): ({ BoxHandleAdornment }?, BoxHandleAdornment?)
	local d = drawn[model]
	return if d then d.Edges else nil, if d then d.Fill else nil
end

function SlamController.Pane(model: Model): BoxHandleAdornment?
	local pane = panes[model]
	return if pane then pane.Box else nil
end

function SlamController.Veil(model: Model): SphereHandleAdornment?
	return veils[model]
end

function SlamController.Recall(): TextButton?
	return if recall and recall.Visible then recall else nil
end

function SlamController.Start()
	local function hook(folder: Instance)
		for _, model in folder:GetChildren() do
			watch(model)
		end
		folder.ChildAdded:Connect(watch)
	end
	local folder = fighters()
	if folder then
		hook(folder)
	else
		task.spawn(function()
			hook(workspace:WaitForChild("Fighters"))
		end)
	end
	RunService.RenderStepped:Connect(stepMarks)
	RunService.Heartbeat:Connect(stepRecall)
	Net.Client.On("Hit", function(hit: any)
		local pane = if type(hit) == "table" and hit.Guarded == "Glanced" then panes[hit.T] else nil
		if pane then
			pane.Glanced = os.clock()
		end
	end)
	Net.Client.On("Heal", function(heal: any)
		local healer, healed = if type(heal) == "table" then heal.A else nil, if type(heal) == "table" then heal.T else nil
		if typeof(healer) == "Instance" and healer:GetAttribute("Action") == "SupportCast" and typeof(healed) == "Instance" and healed:IsA("Model") then
			mendPop(healed)
		end
	end)
end

return SlamController
