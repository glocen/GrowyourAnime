-- TR70 B's captures (Scintilla's; tools/fx/reveal_targets.py): run in a playtest, Client context, through the Studio
-- MCP's execute_luau, while tools/capture/grab.ps1 records the window. Nothing here is game code: it lays its own
-- ScreenGui and takes it away.
--
-- Each step holds HOLD seconds, a 12 px marker at the viewport's top left stamped with its number (red 255; green
-- 16 + 32 x (step mod 8); blue 16 + 48 x (step div 8)), so tools/fx/reveal_frames.py finds each step's frames in the
-- take. Steps, in order:
--   "world":  the screen as it stands, HUD hidden (the frame the void closes over)
--   "matte":  each figure on a full-screen ViewportFrame lit as today's figure's colours (Config.Reveal.Lit), seen as
--             today's camera sees it (Config.RevealArt.Figure), its clip pinned at each time: over black, then white
--   "today":  today's stage (UI/Reveal) pinned at each time of TR70 B's strip, the plate laid at the card

local MODES = { "world", "matte", "today" }
local HOLD = 0.6
local MATTES = { -- clip times (seconds into {Model}Reveal), in this order; LyricReveal's strike is at 1.5, RookReveal's at 0.85
	{ "Lyric", { 1.4, 1.5, 1.6, 1.75, 2.0, 2.25, 2.6, 2.95 } },
	{ "Rook", { 0.85, 1.2, 1.6 } },
}
local TODAY = {
	{ Rarity = "Rare", Name = "Lyric", Model = "Lyric", Def = "lyric", Outcome = "New", Times = { 0.15, 0.35, 0.75, 0.87, 0.95, 1.1, 1.6, 2.4 } },
	{ Rarity = "Common", Name = "Rook", Model = "Rook", Def = "rook", Outcome = "Copy", Times = { 0.1, 0.3, 0.55, 0.7, 1.1, 1.62 } },
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")
local client = player.PlayerScripts.Client
local Art = require(ReplicatedStorage.Shared.Config.RevealArt)
local RevealConfig = require(ReplicatedStorage.Shared.Config.Reveal)
local Clips = require(client.Controllers.Main.FighterController.Clips)
local Stage = require(client.UI.Reveal)
local Plate = require(client.UI.Reveal.Plate)

local old = gui:FindFirstChild("NL_ScintillaCapture")
if old then
	old:Destroy()
end
local screen = Instance.new("ScreenGui")
screen.Name = "NL_ScintillaCapture"
screen.IgnoreGuiInset = true
screen.ResetOnSpawn = false
screen.DisplayOrder = 1000
screen.Parent = gui
local marker = Instance.new("Frame")
marker.BorderSizePixel = 0
marker.Size = UDim2.fromOffset(12, 12)
marker.Position = UDim2.fromOffset(0, 0)
marker.ZIndex = 100
marker.Parent = screen

local step = 0
local function mark()
	step += 1
	marker.BackgroundColor3 = Color3.fromRGB(255, 16 + 32 * (step % 8), 16 + 48 * (step // 8))
	task.wait(HOLD)
end

local hidden = {}
local function hud(on: boolean)
	if on then
		for g, was in hidden do
			g.Enabled = was
		end
		table.clear(hidden)
	else
		for _, g in gui:GetChildren() do
			if g:IsA("ScreenGui") and g ~= screen and g.Enabled then
				hidden[g] = true
				g.Enabled = false
			end
		end
	end
end

local function matte(model: string, times: { number })
	local view = Instance.new("ViewportFrame")
	view.Size = UDim2.fromScale(1, 1)
	view.BorderSizePixel = 0
	view.BackgroundTransparency = 0
	view.Ambient, view.LightColor = RevealConfig.Lit.Ambient, RevealConfig.Lit.Light
	view.Parent = screen
	local world = Instance.new("WorldModel")
	world.Parent = view
	local body = ReplicatedStorage.NL_Reveal.Figures[model]:Clone()
	local root = body:FindFirstChild("HumanoidRootPart") :: BasePart
	body.PrimaryPart = root
	root.Anchored = true
	body:PivotTo(body:GetPivot() * root.CFrame:Inverse() * CFrame.new(0, 3, 0)) -- its root at the hip, facing -Z (Figure.luau)
	body.Parent = world
	local camera = Instance.new("Camera")
	camera.FieldOfView = Art.Figure.Fov
	local target = Vector3.new(0, 3.5, 0)
	camera.CFrame = CFrame.lookAt(target + Art.Figure.Direction.Unit * Art.Figure.Distance, target)
	camera.Parent = view
	view.CurrentCamera = camera
	view.LightDirection = camera.CFrame:VectorToWorldSpace(RevealConfig.Lit.Direction.Unit)
	-- fit its whole height to 86% of the screen: today's camera, narrowed (its direction and distance kept)
	local _, size = body:GetBoundingBox()
	local tall = math.max(size.Y, size.X) * 1.15
	camera.FieldOfView = math.deg(2 * math.atan(tall / 0.86 / 2 / Art.Figure.Distance))
	local animator = body:FindFirstChildWhichIsA("Animator", true) :: Animator
	local track = animator:LoadAnimation(Clips.Animation(`{model}Reveal`) :: Animation)
	track.Looped = false
	track.Priority = Enum.AnimationPriority.Action4
	track:Play(0, 1, 0)
	for _, t in times do
		track.TimePosition = math.min(t, track.Length - 1 / 60)
		view.BackgroundColor3 = Color3.new(0, 0, 0)
		mark()
		view.BackgroundColor3 = Color3.new(1, 1, 1)
		mark()
	end
	view:Destroy()
end

local function today(row)
	local plate
	local stage = Stage.Play({ Rarity = row.Rarity, Name = row.Name, Model = row.Model }, function() end)
	for _, t in row.Times do
		stage.Seek(t)
		if t >= stage.Rarity.Times.Card and not plate then
			plate = Plate.new(stage, { Def = row.Def, Rarity = row.Rarity, Outcome = row.Outcome, Lead = false, Credits = 0 })
		end
		mark()
	end
	stage.Destroy()
end

task.spawn(function()
	hud(false)
	task.wait(0.3)
	for _, mode in MODES do
		if mode == "world" then
			mark()
		elseif mode == "matte" then
			for _, pair in MATTES do
				matte(pair[1], pair[2])
			end
		else
			for _, row in TODAY do
				today(row)
			end
		end
	end
	hud(true)
	screen:Destroy()
end)
return "steps queued"
