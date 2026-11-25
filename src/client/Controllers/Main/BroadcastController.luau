--!strict
-- BroadcastController (client): the Broadcast's plate and chat line (TR57; docs/design.md, "Being seen"; Rules.Broadcast).
-- Each line the server sends is met once (Broadcast.Fresh), and waits for the plate in the target card's place at the
-- top centre (Broadcast.Hear): a stranger's every-server line past the cap goes to the chat only. The plate shows one
-- line at a time, Config.Broadcast.Plate.Seconds, at most one every Gap, this server's and friends' lines first, and
-- never over a fight's card, a keeper's try, a reveal or an open screen (Broadcast.Step); a line still waiting after
-- Stale goes to the chat only. Every line shown stays in the chat as a system line. A grey block: its look follows
-- research's verdict. The words are built here from our definitions, ids and the finder's display name, since
-- TextChannel:DisplaySystemMessage isn't filtered.
--   BroadcastController.Shown()     the plate's words now, plain, or nil: for tests
--   BroadcastController.Chatted()   the last line written in the chat, plain, or nil: for tests

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config.Broadcast)
local HudConfig = require(Shared.Config.Hud)
local Net = require(Shared.Net)
local Broadcast = require(Shared.Rules.Broadcast)
local UI = script.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Layers = require(UI.Layers)
local Screen = require(UI.Kit.Screen)
local HudController = require(script.Parent.HudController)
local BaseController = require(script.Parent.BaseController)

local BroadcastController = {}

local HEIGHT = 34 -- authored: the plate's height
local PAD = 14 -- the words' room at each end
local MOST = 460 -- the plate's widest; its words cut with "…" past it
local FADE_IN, FADE_OUT = 0.2, 0.3 -- seconds
local LOOK = 0.25 -- seconds between looks at the queue
local CHANNEL_WAIT = 10

local player = Players.LocalPlayer
local queue = Broadcast.Queue()
local seen: Broadcast.Seen = {}
local friends: { [number]: boolean } = {}
local plate: CanvasGroup? = nil
local shown: string? = nil
local chatted: string? = nil

local function lightOf(rarity: string): Color3
	return HudConfig.Card.Trim[rarity] or Theme.Colour.Text
end

-- This server's line, the player's own, or a friend's (asked once a user, the answer kept).
local function near(item: Broadcast.News): boolean
	if item.Reach == "Server" or Players:GetPlayerByUserId(item.User) ~= nil then
		return true
	end
	local known = friends[item.User]
	if known == nil then
		friends[item.User] = false
		task.spawn(function()
			local ok, yes = pcall(function(): boolean
				return player:IsFriendsWithAsync(item.User)
			end)
			friends[item.User] = ok and yes == true
		end)
		return false
	end
	return known
end

-- A fight's card, a keeper's try, a reveal or an open screen: the plate waits.
local function covered(): boolean
	local _, fighting = HudController.TargetSpot()
	return fighting or player:GetAttribute("Try") ~= nil or BaseController.Revealed() ~= nil or Screen.Current() ~= nil
end

local function chat(item: Broadcast.News)
	if not Config.ChatKeeps or TextChatService.ChatVersion ~= Enum.ChatVersion.TextChatService then
		return
	end
	local parts, rarity = Broadcast.Line(item)
	chatted = Broadcast.Plain(parts)
	task.spawn(function()
		local channels = TextChatService:WaitForChild("TextChannels", CHANNEL_WAIT)
		local general = if channels then channels:WaitForChild("RBXGeneral", CHANNEL_WAIT) else nil
		if general and general:IsA("TextChannel") then
			general:DisplaySystemMessage(Broadcast.Rich(parts, lightOf(rarity):ToHex()))
		end
	end)
end

local function wide(words: string): number
	local ok, size = pcall(function(): Vector2
		return TextService:GetTextSize(words, Theme.Text.Body, Enum.Font.BuilderSansMedium, Vector2.new(10000, 100))
	end)
	return if ok then size.X else #words * Theme.Text.Body * 0.55
end

-- The plate, in the target card's place, for Seconds, then gone; the line stays in the chat.
local function lay(item: Broadcast.News)
	local parts, rarity = Broadcast.Line(item)
	local light = lightOf(rarity)
	local plain = Broadcast.Plain(parts)
	local spot = HudController.TargetSpot()
	local width = math.min(MOST, math.ceil(wide(plain)) + 2 * PAD)
	local group = Instance.new("CanvasGroup")
	group.Name = "NL_Broadcast"
	group.AnchorPoint = Vector2.new(0.5, 0)
	group.Position = spot
	group.Size = UDim2.fromOffset(width, HEIGHT)
	group.BackgroundTransparency = 1
	group.GroupTransparency = 1
	group.ZIndex = 5
	local back = Instance.new("Frame")
	back.Name = "Plate"
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Theme.Colour.Backing
	back.BackgroundTransparency = 0.2
	back.BorderSizePixel = 0
	back.Parent = group
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = back
	local edge = Instance.new("UIStroke")
	edge.Color = light
	edge.Thickness = 1.2
	edge.Transparency = 0.25
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Parent = back
	local words = Instance.new("TextLabel")
	words.Name = "Words"
	words.BackgroundTransparency = 1
	words.Position = UDim2.fromOffset(PAD, 0)
	words.Size = UDim2.new(1, -2 * PAD, 1, 0)
	words.FontFace = Theme.Font.Body
	words.TextSize = Theme.Text.Body
	words.TextColor3 = Theme.Colour.Text
	words.TextTruncate = Enum.TextTruncate.AtEnd
	words.RichText = true
	words.Text = Broadcast.Rich(parts, light:ToHex())
	words.Parent = back
	group.Parent = Layers.Get("Hud")
	plate, shown = group, plain
	TweenService:Create(group, TweenInfo.new(FADE_IN), { GroupTransparency = 0 }):Play()
	chat(item)
	task.delay(Config.Plate.Seconds, function()
		TweenService:Create(group, TweenInfo.new(FADE_OUT), { GroupTransparency = 1 }):Play()
		task.wait(FADE_OUT)
		group:Destroy()
		if plate == group then
			plate, shown = nil, nil
		end
	end)
end

local function hear(item: any)
	if type(item) ~= "table" or type(item.Id) ~= "string" or type(item.Kind) ~= "string" or type(item.Name) ~= "string" then
		return
	end
	local news = item :: Broadcast.News
	local now = os.clock()
	if not Broadcast.Fresh(seen, news.Id, now) then
		return
	end
	if Broadcast.Hear(queue, news, now, near(news)) == "Chat" then
		chat(news)
	end
end

function BroadcastController.Shown(): string?
	return shown
end

function BroadcastController.Chatted(): string?
	return chatted
end

function BroadcastController.Start()
	Net.Client.On("Broadcast", hear)
	local since = 0
	RunService.Heartbeat:Connect(function(dt: number)
		since += dt
		if since < LOOK then
			return
		end
		since = 0
		local now = os.clock()
		local next, stale = Broadcast.Step(queue, now, plate ~= nil or covered())
		for _, item in stale do
			chat(item)
		end
		if next then
			lay(next)
		end
	end)
end

return BroadcastController
