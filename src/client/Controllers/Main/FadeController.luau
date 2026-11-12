--!strict
-- FadeController (client): a fade to black and back around a move the server makes, so a keeper's try, its end and the
-- shortcut home never jump the camera in view (Net "Fade": out, hold, back seconds; KeeperService moves the avatar in the
-- middle of the hold; WorldService opens each arrival from black). The newest fade wins. In the black, the camera swings
-- behind the avatar: Roblox's camera keeps the old heading otherwise, and a player set down facing the keeper or their
-- Breaker would open their eyes looking away from it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Parts = require(Shared.Util.Parts)

local FadeController = {}

local BLACK = Color3.new(0, 0, 0)

-- In the black, after the move: the camera swings behind the avatar, at the distance and pitch it had, so the player opens
-- their eyes looking where the avatar was set down to look (the keeper, the shut gate, their Breaker). Roblox's camera
-- reads its look from the camera's own CFrame each frame, so setting it once holds.
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
	camera.CFrame = CFrame.lookAt(focus + back, focus)
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
	cover.BackgroundTransparency = 1
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
			if current == mine then
				behind()
				TweenService:Create(cover, TweenInfo.new(back, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
			end
		end)
	end)
end

return FadeController
