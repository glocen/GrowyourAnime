--!strict
-- TravelCard (client): the card over the screen while the player travels between the base and the Festival of Battles
-- (TR45). One ScreenGui, edge to edge over everything (the fade is 100), with where they're going: shown as they leave,
-- handed to Roblox as the teleport's own screen (SetTeleportGui), and kept on the far side until the server says the
-- stage stands. Roblox runs no script inside it, so it holds still. Grey: its look waits for AR42's art.
--   TravelCard.new(to) -> ScreenGui    to: "Festival" or "Main"
--   TravelCard.Name                    the ScreenGui's name, on both sides

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local WorldConfig = require(Shared.Config.World)

local UI = script.Parent
local Theme = require(UI.Theme)

local TravelCard = {}

TravelCard.Name = "TravelCard"

local ORDER = 110 -- over the fade (FadeController, 100)

local WORDS: { [string]: string } = {
	Festival = WorldConfig.Signs.Door.Name,
	Main = "Home",
}

function TravelCard.new(to: string): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = TravelCard.Name
	gui.DisplayOrder = ORDER
	gui.IgnoreGuiInset = true
	gui.ScreenInsets = Enum.ScreenInsets.None
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local backing = Instance.new("Frame")
	backing.Name = "Backing"
	backing.Size = UDim2.fromScale(1, 1)
	backing.BackgroundColor3 = Theme.Colour.Backing
	backing.BorderSizePixel = 0
	backing.Parent = gui
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.fromScale(0.5, 0.46)
	title.Size = UDim2.fromScale(0.8, 0.1)
	title.BackgroundTransparency = 1
	title.FontFace = Theme.Font.Strong
	title.TextColor3 = Theme.Colour.Text
	title.TextScaled = true
	title.Text = WORDS[to] or ""
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = Theme.Text.Title
	limit.MaxTextSize = Theme.Text.Big * 1.5
	limit.Parent = title
	title.Parent = backing
	local rule = Instance.new("Frame")
	rule.Name = "Rule"
	rule.AnchorPoint = Vector2.new(0.5, 0.5)
	rule.Position = UDim2.fromScale(0.5, 0.54)
	rule.Size = UDim2.new(0.18, 0, 0, 2)
	rule.BackgroundColor3 = Theme.Colour.Line
	rule.BorderSizePixel = 0
	rule.Parent = backing
	return gui
end

return TravelCard
