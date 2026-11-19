--!strict
-- StageController (client): a ground's stages as this player sees them, in grey (docs/test-requests.md, TR43;
-- StageService). The picker opens when the server sends it (StagePick, through the Festival Door), the results card at a
-- run's end (StageDone; UI.StageScreen). The run reads at the top of the screen from the player's attributes (StageRun,
-- StageKills, StageQuota, StageLast): "Stage 2 · 7 / 10 Shades · elite next". Each stage gate shows shut to this player
-- until they've cleared its stage on Normal, and clear once they have; a set-back at one says why. Another player's Hard
-- foes (their For) stand faded for this one: not theirs to fight.
--   StageController.Label() -> TextLabel?      the run's line, for tests
--   StageController.Gate(stage) -> boolean?    whether stage's gate shows shut, nil before it's streamed in

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Markers = require(Shared.World.Markers)
local Stages = require(Shared.Rules.Stages)
local Profile = require(Shared.Data.Profile)

local UI = script.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Layers = require(UI.Layers)
local Text = require(UI.Kit.Text)
local Toast = require(UI.Kit.Toast)
local StageScreen = require(UI.StageScreen)
local ProfileController = require(script.Parent.Parent.Core.ProfileController)
local HudController = require(script.Parent.HudController)
local WorldConfig = require(Shared.Config.World)
local Screen = require(UI.Kit.Screen)

local StageController = {}

local player = Players.LocalPlayer
local SHUT = 0.5 -- a shut gate's transparency, as WorldService lays it
local FADED = 0.75 -- another player's Hard foe
local LOOK_EVERY = 0.25 -- seconds between looks at the gates and the foes
local SAY_GAP = 2 -- seconds between two set-back toasts

local label: TextLabel? = nil
local saidAt = -math.huge

local on: StageScreen.On = {
	Begin = function(ground: string, difficulty: string, stage: number): { [string]: any }
		local ok, answer = pcall(Net.Client.Invoke, "Stage", ground, difficulty, stage)
		return if ok and type(answer) == "table" then answer else { Ok = false, Error = "NoAnswer" }
	end,
	Home = function(): { [string]: any }
		local ok, answer = pcall(Net.Client.Invoke, "Home")
		return if ok and type(answer) == "table" then answer else { Ok = false }
	end,
	Say = function(words: string)
		Toast.Show(words)
	end,
}

local function showLabel()
	local run = player:GetAttribute("StageRun")
	if type(run) ~= "string" then
		if label then
			label.Visible = false
		end
		return
	end
	if label == nil or label.Parent == nil then
		local made = Text.new({
			Name = "StageRun",
			Size = Theme.Text.Body,
			Font = Theme.Font.Number,
			Align = Enum.TextXAlignment.Center,
			Box = UDim2.fromOffset(320, 26),
			Position = UDim2.new(0.5, 0, 0, 56),
			AnchorPoint = Vector2.new(0.5, 0),
			Parent = Layers.Get("Hud"),
		})
		made.TextStrokeTransparency = 0.4
		label = made
	end
	local difficulty, stage = string.match(run, "^(%a+) (%d+)$")
	local kills, quota, last = player:GetAttribute("StageKills"), player:GetAttribute("StageQuota"), player:GetAttribute("StageLast")
	local words = { if difficulty == "Hard" then `Hard Stage {stage}` else `Stage {stage}` }
	if type(quota) == "number" and quota > 0 then
		table.insert(words, `{kills or 0} / {quota} Shades`)
	end
	if last == true then
		table.insert(words, if type(quota) == "number" and type(kills) == "number" and kills < quota then "its last foe down" else "cleared")
	else
		table.insert(words, if type(quota) == "number" and quota > 0 then "then its last foe" else "the keeper")
	end
	local l = label :: TextLabel
	l.Text = table.concat(words, "   ·   ")
	l.Visible = true
end

local function look()
	local view = ProfileController.Get()
	-- The gates, shut or open to this player.
	for _, gate in Markers.All("StageGate") do
		if not gate:IsA("BasePart") then
			continue
		end
		local stage, ground = gate:GetAttribute("Stage"), gate:GetAttribute("Ground")
		local open = view ~= nil and type(stage) == "number" and type(ground) == "string" and Stages.Passes(view, ground, stage)
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

function StageController.Label(): TextLabel?
	return label
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

function StageController.Start()
	HudController.OpenPlay = StageController.Pick
	Net.Client.On("StagePick", function(payload: any)
		local view = ProfileController.Get()
		if type(payload) == "table" and type(payload.Ground) == "string" and view then
			StageScreen.Pick(payload.Ground, view, on)
		end
	end)
	Net.Client.On("StageDone", function(results: any)
		if type(results) == "table" and type(results.Ground) == "string" and type(results.Stage) == "number" then
			StageScreen.Results(results, on)
		end
	end)
	Net.Client.On("StageGate", function(payload: any)
		local now = os.clock()
		if type(payload) == "table" and type(payload.Stage) == "number" and now - saidAt > SAY_GAP then
			saidAt = now
			Toast.Show(`Clear Stage {payload.Stage} to go on`)
		end
	end)
	for _, name in { "StageRun", "StageKills", "StageQuota", "StageLast" } do
		player:GetAttributeChangedSignal(name):Connect(showLabel)
	end
	showLabel()
	ProfileController.Changed:Connect(function(_view: Profile.View)
		look()
	end)
	local since = 0
	RunService.Heartbeat:Connect(function(dt: number)
		since += dt
		if since >= LOOK_EVERY then
			since = 0
			look()
		end
	end)
end

return StageController
