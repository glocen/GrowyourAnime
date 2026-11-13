--!strict
-- FadeController (client): a fade to black and back around a move the server makes, so a keeper's try, its end and the
-- shortcut home never jump the camera in view (Net "Fade": out, hold, back seconds; KeeperService moves the avatar in the
-- middle of the hold; WorldService opens each arrival from black). The newest fade wins. In the black, the camera swings
-- behind the avatar: Roblox's camera keeps the old heading otherwise, and a player set down facing the keeper or their
-- Breaker would open their eyes looking away from it.
-- At a join the screen shows whole or not at all (research's read of TR2's closing takes, 2026-11-12): the cover is black
-- from the client's first frame, the HUD and the plates draw beneath it, and the first lift waits for HudController to say
-- they're whole, at most OPEN_MOST seconds, so a player is never left in the dark.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Parts = require(Shared.Util.Parts)
local CameraTurn = require(Shared.Util.CameraTurn)

local FadeController = {}

local BLACK = Color3.new(0, 0, 0)
local OPEN_MOST = 8 -- seconds the join's black waits at most for the screen to be whole
local OPEN_BACK = 0.6 -- seconds the black lifts over when no arrival's fade came to lift it

local startedAt = os.clock()
local wholeAt: number? = nil -- when HudController said the screen is whole, by os.clock()
local opened: { At: number, Whole: boolean }? = nil -- the first lift: when, and whether the screen was whole then

-- HudController, once both pills have their numbers, the lead's card its name, and the frames run smooth.
function FadeController.Whole()
	wholeAt = wholeAt or os.clock()
end

-- For the self-test: the join's first lift, seconds after the client started, and whether it waited for a whole screen.
function FadeController.Opened(): { At: number, Whole: boolean }?
	return opened
end

-- Yields until the screen is whole or OPEN_MOST has passed since the client started; at once after the first time.
local function untilWhole()
	while wholeAt == nil and os.clock() - startedAt < OPEN_MOST do
		RunService.RenderStepped:Wait()
	end
	opened = opened or { At = os.clock() - startedAt, Whole = wholeAt ~= nil }
end

-- In the black, after the move: the camera swings behind the avatar, at the distance and pitch it had, so the player opens
-- their eyes looking where the avatar was set down to look (the keeper, the shut gate, their Breaker). Through CameraTurn,
-- or a phone's camera turns back.
local function behind()
	local camera = workspace.CurrentCamera
	local root = Parts.Root(Players.LocalPlayer.Character)
	if camera == nil or root == nil then
		return
	end
	local focus = camera.Focus.Position
	local offset = camera.CFrame.Position - focus
	local distance = offset.Magnitude
	local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	if distance < 0.5 or look.Magnitude < 1e-3 then
		return -- first person, or a root looking straight up: leave it be
	end
	local pitch = math.asin(math.clamp(offset.Y / distance, -1, 1))
	local back = -look.Unit * math.cos(pitch) * distance + Vector3.new(0, math.sin(pitch) * distance, 0)
	CameraTurn.To(CFrame.lookAt(focus + back, focus))
end

function FadeController.Start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Fade"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 100 -- over every screen
	local cover = Instance.new("Frame")
	cover.Name = "Cover"
	cover.Size = UDim2.fromScale(1, 1)
	cover.BackgroundColor3 = BLACK
	cover.BackgroundTransparency = 0 -- black from the first frame: the join opens whole or not at all
	cover.BorderSizePixel = 0
	cover.Active = false
	cover.Parent = gui
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	local current = 0
	Net.Client.On("Fade", function(out: any, hold: any, back: any)
		if type(out) ~= "number" or type(hold) ~= "number" or type(back) ~= "number" then
			return
		end
		current += 1
		local mine = current
		TweenService:Create(cover, TweenInfo.new(out, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0 }):Play()
		task.delay(out + hold, function()
			untilWhole()
			if current == mine then
				behind()
				TweenService:Create(cover, TweenInfo.new(back, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
			end
		end)
	end)
	-- No arrival's fade to lift the join's black (a client that started after it was sent): lift it here.
	task.spawn(function()
		untilWhole()
		task.wait(OPEN_BACK)
		if current == 0 then
			TweenService:Create(cover, TweenInfo.new(OPEN_BACK, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
		end
	end)
end

return FadeController
