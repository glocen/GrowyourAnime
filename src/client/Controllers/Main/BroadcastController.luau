--!strict
-- BroadcastController (client): the Broadcast's line (Rules.Broadcast; docs/research/cloud-2026-11-24/launch-design.md,
-- section 6). Each line the server sends is written in the chat at once, as a system message in its rarity's light
-- (TextChannel:DisplaySystemMessage runs only on a client), and runs once at the top centre for
-- Config.Broadcast.Banner.Seconds. The banner waits while a keeper's try, a reveal or a menu is up, at most
-- Banner.Waiting of them, and one held past Banner.Stale seconds is dropped: the chat keeps it. A stand-in plate until
-- the look is designed (NOT VERIFIED: built in the cloud, never seen in Studio).
--   BroadcastController.Shown()   the banner's words now, or nil: for tests

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config.Broadcast)
local HudConfig = require(Shared.Config.Hud)
local Net = require(Shared.Net)
local Broadcast = require(Shared.Rules.Broadcast)
local UI = script.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Layers = require(UI.Layers)
local Panel = require(UI.Kit.Panel)
local Screen = require(UI.Kit.Screen)
local Text = require(UI.Kit.Text)

local BroadcastController = {}

local WIDTH = 440 -- authored: the plate, its words cut with "…" past it
local HEIGHT = 34
local TOP = 56 -- authored pixels from the safe area's top (a seed, tuned by playing)
local SLIDE = 0.25 -- seconds in and out
local CHANNEL_WAIT = 10

type Held = { Words: string, Light: Color3, At: number }

local player = Players.LocalPlayer
local waiting: { Held } = {}
local plate: Frame? = nil
local running = false

local function lightOf(rarity: string): Color3
	return HudConfig.Card.Trim[rarity] or Theme.Colour.Text
end

local function anyShown(root: Instance): boolean
	for _, child in root:GetChildren() do
		if child:IsA("GuiObject") and child.Visible then
			return true
		end
	end
	return false
end

-- A keeper's try, a reveal on the overlay, or a menu: the line waits until after.
local function held(): boolean
	return player:GetAttribute("Try") ~= nil or Screen.Current() ~= nil or anyShown(Layers.Get("Overlay"))
end

local function chat(words: string, light: Color3)
	if TextChatService.ChatVersion ~= Enum.ChatVersion.TextChatService then
		return
	end
	task.spawn(function()
		local channels = TextChatService:WaitForChild("TextChannels", CHANNEL_WAIT)
		local general = if channels then channels:WaitForChild("RBXGeneral", CHANNEL_WAIT) else nil
		if general and general:IsA("TextChannel") then
			general:DisplaySystemMessage(`<font color="#{light:ToHex()}">{Broadcast.Escape(words)}</font>`)
		end
	end)
end

local function banner(line: Held)
	local made = Panel.new({ Name = "NL_Broadcast", Size = UDim2.fromOffset(WIDTH, HEIGHT), Parent = Layers.Get("Toasts") })
	made.AnchorPoint = Vector2.new(0.5, 0)
	made.Position = UDim2.new(0.5, 0, 0, -HEIGHT)
	Panel.Pad(made, Theme.Size.Pad)
	local label = Text.new({ Name = "Words", Size = Theme.Text.Body, Colour = line.Light, Align = Enum.TextXAlignment.Center, Truncate = true, Parent = made })
	label.Text = line.Words
	plate = made
	TweenService:Create(made, TweenInfo.new(SLIDE, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0, TOP) }):Play()
	task.wait(Config.Banner.Seconds)
	TweenService:Create(made, TweenInfo.new(SLIDE, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0.5, 0, 0, -HEIGHT) }):Play()
	task.wait(SLIDE)
	made:Destroy()
	plate = nil
end

-- One banner at a time, oldest first, each once nothing holds it.
local function run()
	if running then
		return
	end
	running = true
	task.spawn(function()
		while #waiting > 0 do
			if held() then
				task.wait(0.25)
			else
				local line = table.remove(waiting, 1) :: Held
				if os.clock() - line.At <= Config.Banner.Stale then
					banner(line)
				end
			end
			for index = #waiting, 1, -1 do
				if os.clock() - waiting[index].At > Config.Banner.Stale then
					table.remove(waiting, index)
				end
			end
		end
		running = false
	end)
end

function BroadcastController.Shown(): string?
	local made = plate
	local label = if made then made:FindFirstChild("Words", true) :: TextLabel? else nil
	return if label then label.Text else nil
end

function BroadcastController.Start()
	Net.Client.On("Broadcast", function(news: any)
		if type(news) ~= "table" or type(news.Kind) ~= "string" or type(news.Name) ~= "string" then
			return
		end
		local words, rarity = Broadcast.Line(news :: Broadcast.News)
		local light = lightOf(rarity)
		chat(words, light)
		Broadcast.Push(waiting, { Words = words, Light = light, At = os.clock() }, Config.Banner.Waiting)
		run()
	end)
end

return BroadcastController
