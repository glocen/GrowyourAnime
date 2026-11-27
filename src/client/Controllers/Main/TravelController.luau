--!strict
-- TravelController (client): the trip's card (TR45; UI.TravelCard; TravelService). "Leaving": the card comes up and a
-- copy goes to Roblox as the teleport's own screen. "Failed": the card goes and a toast says so; "Back": it goes
-- quietly. On the far side the ReplicatedFirst script has put Roblox's copy up before anything else drew; it goes on
-- "Arrived", when the server says the stage stands, or Config.Travel.Hold seconds after this started at the latest.
--   TravelController.Showing() -> boolean   a trip's card is up, either side

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local TravelConfig = require(Shared.Config.Travel)

local UI = script.Parent.Parent.Parent.UI
local TravelCard = require(UI.TravelCard)
local Refuse = require(UI.Kit.Refuse)
local Cues = require(script.Parent.FighterController.Cues)

local TravelController = {}

local player = Players.LocalPlayer
local IN = 0.3 -- seconds the card takes to come up
local OUT = 0.4 -- and to go
local ARRIVAL = "TravelArrival" -- Roblox's copy on the far side, as the ReplicatedFirst script names it

local card: ScreenGui? = nil

local function backing(gui: Instance): Frame?
	local frame = gui:FindFirstChild("Backing")
	return if frame and frame:IsA("Frame") then frame else nil
end

local function lift(gui: ScreenGui?)
	if gui == nil or gui.Parent == nil then
		return
	end
	local frame = backing(gui)
	if frame == nil then
		gui:Destroy()
		return
	end
	for _, item in frame:GetDescendants() do
		if item:IsA("TextLabel") then
			TweenService:Create(item, TweenInfo.new(OUT), { TextTransparency = 1 }):Play()
		elseif item:IsA("Frame") then
			TweenService:Create(item, TweenInfo.new(OUT), { BackgroundTransparency = 1 }):Play()
		end
	end
	local tween = TweenService:Create(frame, TweenInfo.new(OUT, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 })
	tween.Completed:Connect(function()
		gui:Destroy()
	end)
	tween:Play()
end

local function arrival(): ScreenGui?
	local gui = player:WaitForChild("PlayerGui"):FindFirstChild(ARRIVAL)
	return if gui and gui:IsA("ScreenGui") then gui else nil
end

local function show(to: string)
	lift(card)
	local gui = TravelCard.new(to)
	local frame = backing(gui) :: Frame
	frame.BackgroundTransparency = 1
	gui.Parent = player:WaitForChild("PlayerGui")
	TweenService:Create(frame, TweenInfo.new(IN, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0 }):Play()
	card = gui
	Cues.Moment("Travel") -- a trip to another place, as its card comes up (TR64's gaps)
	pcall(function()
		TeleportService:SetTeleportGui(TravelCard.new(to) :: any) -- a ScreenGui, as Roblox wants, though its type says GuiObject
	end)
end

function TravelController.Showing(): boolean
	return (card ~= nil and card.Parent ~= nil) or arrival() ~= nil
end

function TravelController.Start()
	Net.Client.On("Travel", function(state: any, info: any)
		if state == "Leaving" then
			show(if type(info) == "table" and type(info.To) == "string" then info.To else "")
		elseif state == "Failed" then
			lift(card)
			card = nil
			Refuse.Words("Travel", "Failed")
		elseif state == "Back" then
			lift(card)
			card = nil
		elseif state == "Arrived" then
			lift(arrival())
		end
	end)
	task.delay(TravelConfig.Hold, function()
		lift(arrival()) -- the server never said: never a screen held for good
	end)
end

return TravelController
