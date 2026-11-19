--!strict
-- SlamController (client): a keeper's marked slam as this player sees it, in grey (docs/test-requests.md, TR44;
-- FightService's Mark attributes; SlamService). While a fighter's footprint is down, a flat white ring of
-- Config.Combat.Keeper.Mark's radius lies on the ground at its centre, and inside it a translucent disc grows from the
-- middle and meets the ring on the Slam, so the fill tells the time; both go on the Slam, and the column takes over.
-- Nothing else is marked: no screen text, no icon. In mode B (Config.Combat.Keeper.Out.Mode, read live), and only in a
-- keeper's try, the Recall: a round button by the right thumb, R and the gamepad's ButtonY, its cooldown on its face.
--   SlamController.Ring(fighter) -> (ring, disc)?   a fighter's footprint's two adornments, for tests
--   SlamController.Recall() -> TextButton?          the Recall button while it shows, for tests
--   SlamController.Press() -> { [string]: any }     a Recall as a press asks it, the server's answer

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Combat = require(Shared.Config.Combat)
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

type Drawn = { Holder: BasePart, Ring: CylinderHandleAdornment, Disc: CylinderHandleAdornment, Slam: number, Down: number, Radius: number }

local drawn: { [Model]: Drawn } = {}
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

local function draw(model: Model)
	erase(model)
	local at, radius, down, slam = model:GetAttribute("MarkAt"), model:GetAttribute("MarkRadius"), model:GetAttribute("MarkDown"), model:GetAttribute("MarkSlam")
	if typeof(at) ~= "Vector3" or type(radius) ~= "number" or type(down) ~= "number" or type(slam) ~= "number" then
		return
	end
	local look = Combat.Keeper.Mark
	local y = groundUnder(at :: Vector3)
	local holder = Instance.new("Part")
	holder.Name = "NL_Mark"
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.new(0.2, 0.2, 0.2)
	-- a cylinder adornment's axis is its CFrame's look: turned to stand up, it lies flat on the ground
	holder.CFrame = CFrame.new((at :: Vector3).X, y + RING_UP, (at :: Vector3).Z) * CFrame.Angles(math.rad(90), 0, 0)
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
	drawn[model] = { Holder = holder, Ring = ring, Disc = disc, Slam = slam :: number, Down = down :: number, Radius = radius :: number }
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
	model.Destroying:Connect(function()
		erase(model)
	end)
end

local function stepMarks()
	local t = now()
	for model, d in drawn do
		if t >= d.Slam or model.Parent == nil then
			erase(model) -- gone on the Slam: the column takes over
			continue
		end
		-- the fill tells the time: it meets the ring on the Slam
		d.Disc.Radius = math.max(0.01, d.Radius * MarkRule.Fill(t, d.Down, d.Slam))
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
end

return SlamController
