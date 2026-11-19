--!strict
-- TowerController (client): the Tower as players see it, in grey (TR29; docs/design.md, "The Tower"). For every player
-- in a run (their "Tower" attribute, the floor being fought or risen to; TowerService), the platforms over their ring:
-- at most three, the floor's and the two below, the newest assembling as it comes; older ones fold into one thin
-- column, so the height still reads. The server holds only one floor's collision. At the run's end the platforms fall
-- away (a fade in grey; their light waits for the finish). The own player's floor reads at the top of the screen, and
-- the run's results open once from the save (UI.TowerScreen).
--   TowerController.Platforms(player) -> { [floor]: BasePart }, Column?   what stands for a player, for tests
--   TowerController.Label() -> TextLabel?                                  the floor's line, for tests

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local TowerConfig = require(Shared.Config.Tower)
local Markers = require(Shared.World.Markers)
local Profile = require(Shared.Data.Profile)
local Net = require(Shared.Net)

local UI = script.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Layers = require(UI.Layers)
local Text = require(UI.Kit.Text)
local Screen = require(UI.Kit.Screen)
local TowerScreen = require(UI.TowerScreen)
local ProfileController = require(script.Parent.Parent.Core.ProfileController)
local HudController = require(script.Parent.HudController)

local TowerController = {}

local STANDING = 3 -- platforms that stand: the floor's and two below
local GREY = Color3.fromRGB(150, 152, 160)
local COLUMN = Color3.fromRGB(104, 106, 114)
local ASSEMBLE = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local FALL = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

type Stack = { Floor: number, Discs: { [number]: BasePart }, Column: BasePart? }

local stacks: { [Player]: Stack } = {}
local label: TextLabel? = nil
local folder: Folder? = nil

local function holder(): Folder
	if folder == nil or folder.Parent == nil then
		local made = Instance.new("Folder")
		made.Name = "TowerPlatforms"
		made.Parent = workspace
		folder = made
	end
	return folder :: Folder
end

local function ringOf(player: Player): Vector3?
	local plot = player:GetAttribute("Plot")
	local ring = if type(plot) == "number" then Markers.Find("TowerRing", { Plot = plot }) else nil
	return if ring then Markers.At(ring).Position else nil
end

local function disc(name: string, top: Vector3, radius: number): BasePart
	local p = TowerConfig.Platform
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Cylinder
	part.Anchored = true
	part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = GREY
	part.Size = Vector3.new(p.Thick, radius * 2, radius * 2)
	part.CFrame = CFrame.new(top - Vector3.new(0, p.Thick / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	part.Parent = holder()
	return part
end

local function fallAway(part: BasePart)
	local tween = TweenService:Create(part, FALL, { Transparency = 1, CFrame = part.CFrame - Vector3.new(0, 3, 0) })
	tween.Completed:Connect(function()
		part:Destroy()
	end)
	tween:Play()
end

-- `player`'s platforms as their floor stands: the floor's and two below, the column under them.
local function draw(player: Player)
	local floor = player:GetAttribute("Tower")
	local stack = stacks[player]
	local ring = ringOf(player)
	if type(floor) ~= "number" or ring == nil then
		if stack then
			stacks[player] = nil
			for _, part in stack.Discs do
				fallAway(part)
			end
			if stack.Column then
				fallAway(stack.Column)
			end
		end
		return
	end
	if stack == nil then
		local made: Stack = { Floor = 0, Discs = {}, Column = nil }
		stacks[player] = made
		stack = made
	end
	local s = stack :: Stack
	local p = TowerConfig.Platform
	local lowest = math.max(1, floor - STANDING + 1)
	for at, part in s.Discs do
		if at < lowest or at > floor then
			part:Destroy()
			s.Discs[at] = nil
		end
	end
	for at = lowest, floor do
		if s.Discs[at] == nil then
			local top = ring + Vector3.new(0, at * p.Height, 0)
			local part = disc(`Floor{at}_{player.UserId}`, top, p.Radius)
			part:SetAttribute("Floor", at)
			s.Discs[at] = part
			if at == floor then
				-- The new one assembles: from a narrow core out to its edge.
				local whole = part.Size
				part.Size = Vector3.new(whole.X, whole.Y * 0.2, whole.Z * 0.2)
				TweenService:Create(part, ASSEMBLE, { Size = whole }):Play()
			end
		end
	end
	-- Older floors, folded into one thin column from the ground to under the lowest platform standing.
	local under = lowest - 1
	if under >= 1 then
		local high = under * p.Height
		local column = s.Column
		if column == nil then
			column = Instance.new("Part")
			local c = column :: Part
			c.Name = `Column_{player.UserId}`
			c.Shape = Enum.PartType.Cylinder
			c.Anchored = true
			c.CanCollide, c.CanQuery, c.CanTouch = false, false, false
			c.Material = Enum.Material.SmoothPlastic
			c.Color = COLUMN
			c.Parent = holder()
			s.Column = c
		end
		local c = s.Column :: BasePart
		c.Size = Vector3.new(high, 4, 4)
		c.CFrame = CFrame.new(ring + Vector3.new(0, high / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	elseif s.Column then
		s.Column:Destroy()
		s.Column = nil
	end
	s.Floor = floor
end

local function showLabel()
	local floor = Players.LocalPlayer:GetAttribute("Tower")
	if type(floor) ~= "number" then
		if label then
			label.Visible = false
		end
		return
	end
	if label == nil or label.Parent == nil then
		local made = Text.new({
			Name = "TowerFloor",
			Size = Theme.Text.Big,
			Font = Theme.Font.Number,
			Align = Enum.TextXAlignment.Center,
			Box = UDim2.fromOffset(240, 34),
			Position = UDim2.new(0.5, 0, 0, 56),
			AnchorPoint = Vector2.new(0.5, 0),
			Parent = Layers.Get("Hud"),
		})
		made.TextStrokeTransparency = 0.4
		label = made
	end
	local view = ProfileController.Get()
	local best = if view then view.Progress.Tower.Best else 0
	local l = label :: TextLabel
	l.Text = if best > 0 then `Floor {floor}   ·   best {best}` else `Floor {floor}`
	l.Visible = true
end

-- The results the save holds, opened once they're the client's to see: out of a run, never twice. Results on screen the
-- save no longer holds close: a run started over them dropped them (Rules.Tower.Start), and its own open at its end.
local function results(view: Profile.View?)
	local held = if view then view.Progress.Tower.Results else nil
	local open = Screen.Current() == TowerScreen.Name
	if open and (held == nil or TowerScreen.Shown() ~= held.Id) then
		Screen.Close()
		open = false
	end
	if held == nil or Players.LocalPlayer:GetAttribute("Tower") ~= nil or TowerScreen.Told(held.Id) or open then
		return
	end
	TowerScreen.Open(held, {
		Act = ProfileController.Act,
		Retry = function(): { [string]: any }
			return Net.Client.Invoke("TowerRetry")
		end,
		Home = function(): { [string]: any }
			return Net.Client.Invoke("TowerHome")
		end,
		Board = function(): { [string]: any }
			return Net.Client.Invoke("TowerBoard")
		end,
	})
end

function TowerController.Platforms(player: Player): ({ [number]: BasePart }, BasePart?)
	local stack = stacks[player]
	return if stack then table.clone(stack.Discs) else {}, if stack then stack.Column else nil
end

function TowerController.Label(): TextLabel?
	return label
end

function TowerController.Start()
	-- The heal cap, told once per account the first time it binds (TR46; research's words, the share from Config).
	Net.Client.On("TowerHealCap", function(share: any)
		local percent = math.floor((if type(share) == "number" then share else TowerConfig.HealCap) * 100 + 0.5)
		HudController.Note(`Healing capped for this floor: {percent}% of your lead's health.`)
	end)
	local function watch(player: Player)
		player:GetAttributeChangedSignal("Tower"):Connect(function()
			draw(player)
			if player == Players.LocalPlayer then
				showLabel()
				results(ProfileController.Get())
			end
		end)
		draw(player)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		local stack = stacks[player]
		stacks[player] = nil
		if stack then
			for _, part in stack.Discs do
				part:Destroy()
			end
			if stack.Column then
				stack.Column:Destroy()
			end
		end
	end)
	ProfileController.Changed:Connect(function(view: Profile.View)
		results(view)
		showLabel()
	end)
	results(ProfileController.Get())
end

return TowerController
