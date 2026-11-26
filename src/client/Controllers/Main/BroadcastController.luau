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
--   BroadcastController.Chatted()   the last line written in the chat, plain, and its rarity's colour (hex), or nil:
--                                   for tests

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
local MOST = 460 -- the plate's widest, and never past the band between the lead's card and the pills (band)
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
local chattedLight: string? = nil

local function lightOf(rarity: string): Color3
	return HudConfig.Card.Trim[rarity] or Theme.Colour.Text
end

-- On the chat's dark panel a rarity takes the bag's word colours, lifted toward white so Common's grey reads (research's
-- must-fix on TR57, 2026-11-26).
local function chatLightOf(rarity: string): Color3
	return HudConfig.Bag.Rarity[rarity] or lightOf(rarity)
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
	chattedLight = chatLightOf(rarity):ToHex()
	task.spawn(function()
		local channels = TextChatService:WaitForChild("TextChannels", CHANNEL_WAIT)
		local general = if channels then channels:WaitForChild("RBXGeneral", CHANNEL_WAIT) else nil
		if general and general:IsA("TextChannel") then
			general:DisplaySystemMessage(Broadcast.Rich(parts, chatLightOf(rarity):ToHex()))
		end
	end)
end

local function measure(words: string, across: number): Vector2
	local ok, size = pcall(function(): Vector2
		return TextService:GetTextSize(words, Theme.Text.Body, Enum.Font.BuilderSansMedium, Vector2.new(across, 1000))
	end)
	return if ok then size else Vector2.new(#words * Theme.Text.Body * 0.55, Theme.Text.Body)
end

-- The band the plate may take, authored: centred where it stands, clear of the lead's card and the pills by a gap each
-- side (on the smallest phone about the target card's own width, so a long line wraps there rather than cover the
-- Electricity pill).
local function band(): number
	local parts = HudController.Parts()
	local root = Layers.Get("Hud")
	local pill = (parts.Electricity :: GuiObject).Parent :: GuiObject
	local lead = parts.Lead
	local centre = root.AbsolutePosition.X + root.AbsoluteSize.X / 2
	local half = math.min(centre - (lead.AbsolutePosition.X + lead.AbsoluteSize.X), pill.AbsolutePosition.X - centre)
	return math.max(2 * PAD + Theme.Text.Body, 2 * (half / Layers.Scale() - Theme.Size.Gap))
end

-- The plate, in the target card's place, for Seconds, then gone; the line stays in the chat.
local function lay(item: Broadcast.News)
	local parts, rarity = Broadcast.Line(item)
	local light = lightOf(rarity)
	local plain = Broadcast.Plain(parts)
	local spot = HudController.TargetSpot()
	local one = measure(plain, 10000)
	local width = math.min(MOST, band(), math.ceil(one.X) + 2 * PAD)
	local laid = parts
	if math.ceil(one.X) + 2 * PAD > width then
		-- short of room: the break falls before the lit words, so the rarity and its name stand whole on their own line
		laid = table.clone(parts)
		for index, each in laid do
			if each.Lit and index > 1 then
				local before = laid[index - 1]
				laid[index - 1] = { Text = (string.gsub(before.Text, "%s+$", "")) .. "\n", Lit = before.Lit }
				break
			end
		end
	end
	local lines = measure(Broadcast.Plain(laid), width - 2 * PAD)
	local height = HEIGHT + math.max(0, math.ceil(lines.Y - one.Y)) -- a second line when the band is short
	local group = Instance.new("CanvasGroup")
	group.Name = "NL_Broadcast"
	group.AnchorPoint = Vector2.new(0.5, 0)
	group.Position = spot
	group.Size = UDim2.fromOffset(width, height)
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
	words.TextWrapped = true
	words.TextTruncate = Enum.TextTruncate.AtEnd
	words.RichText = true
	words.Text = Broadcast.Rich(laid, light:ToHex())
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

function BroadcastController.Chatted(): (string?, string?)
	return chatted, chattedLight
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
