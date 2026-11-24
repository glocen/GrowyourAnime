--!strict
-- ShopController (client): the Void Shop's counter and its screen (AR38; UI.ShopScreen; ShopService). A prompt at the
-- Shop's counter opens the screen on the standing shelf, fetched from the server (Net "Shop"); a buy goes through the
-- profile's Act ("ShopBuy"), and the copy that lands refills the screen. When the stock gives way while it's open, the
-- new shelf is fetched. In a stock's last Config.Shop.Warn seconds a chip under the HUD's pills counts it down (docs/ui.md,
-- "Under the pills"); the stock's clock is the world's, so the chip needs no shelf. The Shop's building runs the same
-- clock on its five minutes (WorldService's dressShop; Rules.Shop.Minute), here on the client.
--   ShopController.Open(): boolean     fetches the shelf and opens the screen (the counter's prompt, and tests)
--   ShopController.Chip(): Frame?      the countdown chip, for tests

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Markers = require(Shared.World.Markers)
local ShopConfig = require(Shared.Config.Shop)
local HudConfig = require(Shared.Config.Hud)
local Hud = require(Shared.Rules.Hud)
local Shop = require(Shared.Rules.Shop)
local UI = script.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Layers = require(UI.Layers)
local Text = require(UI.Kit.Text)
local Toast = require(UI.Kit.Toast)
local Screen = require(UI.Kit.Screen)
local ShopScreen = require(UI.ShopScreen)
local ProfileController = require(script.Parent.Parent.Core.ProfileController)
local HudController = require(script.Parent.HudController)

local ShopController = {}

local FIND_EVERY = 1 -- seconds between looks for the Shop's marker: it streams in, and a relaid world replaces it
local REACH = 10 -- studs from the counter it can be pressed
local COUNTER = CFrame.new(0, 3, 0) -- the counter's prompt from the Shop's marker, before its front
local TICK = 0.1 -- seconds between the clocks' reads
local RETRY = 1 -- seconds between fetches of a stock the server hasn't turned yet

local player = Players.LocalPlayer
local anchor: Part? = nil
local fetching = false
local retryAt = 0
local chip: Frame? = nil
local chipWords: TextLabel? = nil

local function fetch(): Shop.Shelf?
	local ok, answer = pcall(Net.Client.Invoke, "Shop")
	if ok and type(answer) == "table" and answer.Ok == true and type(answer.Shelf) == "table" then
		return answer.Shelf :: Shop.Shelf
	end
	return nil
end

local on: ShopScreen.On

-- The stock turned while the screen is open: the new shelf, once the server has it.
local function refresh()
	if fetching or os.clock() < retryAt then
		return
	end
	fetching = true
	retryAt = os.clock() + RETRY
	task.spawn(function()
		local got = fetch()
		fetching = false
		local view = ProfileController.Get()
		local shown = ShopScreen.Shelf()
		if got and view and shown and (got.Stock ~= shown.Stock or got.Ends ~= shown.Ends) then
			ShopScreen.Open(view, got, on)
		end
	end)
end

on = {
	Buy = function(line: string, stock: number): { [string]: any }
		return ProfileController.Act("ShopBuy", { Stock = stock, Line = line, Count = 1 })
	end,
	Refresh = function()
		retryAt = 0
		refresh()
	end,
}

function ShopController.Open(): boolean
	local view = ProfileController.Get()
	if view == nil then
		return false
	end
	local got = fetch()
	if got == nil then
		Toast.Show(ShopScreen.Refused.Closed, Theme.Colour.TextDim)
		return false
	end
	ShopScreen.Open(view, got, on)
	return true
end

-- The counter's prompt, on a client part before the Shop: made again when a relaid world replaces the marker.
local function counter()
	if anchor and anchor.Parent then
		return
	end
	local marker = Markers.Find("Shop")
	if marker == nil then
		return
	end
	local part = Instance.new("Part")
	part.Name = "ShopCounter"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.new(1, 1, 1)
	part.CFrame = Markers.At(marker) * COUNTER
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Shop"
	prompt.ObjectText = "Void Shop"
	prompt.ActionText = "Open"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = REACH
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	prompt.Triggered:Connect(function(who: Player)
		if who == player and Screen.Current() ~= ShopScreen.Name then
			ShopController.Open()
		end
	end)
	part.Parent = marker
	anchor = part
end

-- The countdown under the pills, in a stock's last minute.
local function makeChip()
	local look = HudConfig.Shop.Chip
	local made = Instance.new("Frame")
	made.Name = "ShopChip"
	made.BorderSizePixel = 0
	made.BackgroundColor3 = Theme.Colour.Backing
	made.BackgroundTransparency = 0.25
	made.AnchorPoint = Vector2.new(1, 0)
	made.Position = HudController.UnderPills()
	made.Size = UDim2.fromOffset(look.Wide, look.Tall)
	made.Visible = false
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Theme.Size.Corner)
	corner.Parent = made
	local words = Text.new({ Name = "Words", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Align = Enum.TextXAlignment.Center, Parent = made })
	made.Parent = Layers.Get("Hud")
	HudController.Beneath(made) -- the plates in its column keep under it (AR51's must-fix 3)
	chip, chipWords = made, words
end

-- The chip's width fits its words at the layers' scale: measured again when the words change or the scale does (the
-- text keeps its legible floor on the smallest phone, so it grows there against the chip).
local function fitChip()
	local made, words = chip, chipWords
	if made and words and words.Text ~= "" then
		made.Size = UDim2.fromOffset(math.ceil(Text.Wide(words, words.Text)) + Theme.Size.Pad * 2, HudConfig.Shop.Chip.Tall)
	end
end

-- The building's clock: a spent minute hidden, the running one as tall as its share left, hung from its root under the
-- slab, so it shrinks upward; the server lays them full and never touches them again.
local function minutes(left: number)
	local marker = Markers.Find("Shop")
	if marker == nil then
		return
	end
	local hung: { BasePart } = {}
	for _, item in marker:GetChildren() do
		if item:IsA("BasePart") and type(item:GetAttribute("Minute")) == "number" then
			table.insert(hung, item)
		end
	end
	for _, part in hung do
		local root, full, centre = part:GetAttribute("Root"), part:GetAttribute("Full"), part:GetAttribute("Centre")
		if typeof(root) ~= "CFrame" or typeof(full) ~= "Vector3" or typeof(centre) ~= "Vector3" then
			continue
		end
		local share = Shop.Minute(left, part:GetAttribute("Minute") :: number, #hung)
		part.Transparency = if share > 0 then 0 else 1
		local size = Vector3.new(full.X, full.Y * math.max(share, 0.01), full.Z)
		if (part.Size - size).Magnitude > 1e-3 then
			part.Size = size
			part.CFrame = root * CFrame.new(centre.X, centre.Y * size.Y / full.Y, centre.Z)
		end
	end
end

local function tick()
	local now = workspace:GetServerTimeNow()
	local left = Shop.Ends(Shop.Stock(now)) - now
	minutes(left)
	local made, words = chip, chipWords
	if made and words then
		local shown = left <= ShopConfig.Warn and Screen.Current() ~= ShopScreen.Name
		made.Visible = shown
		if shown then
			local said = `Void Shop restock {Hud.Clock(left)}`
			if words.Text ~= said then
				words.Text = said
				fitChip()
			end
			made:SetAttribute("Left", left)
		end
	end
	if ShopScreen.Tick() then
		refresh()
	end
end

function ShopController.Chip(): Frame?
	return chip
end

function ShopController.Start()
	makeChip()
	Layers.Changed:Connect(function()
		task.defer(fitChip)
	end)
	ProfileController.Changed:Connect(function(view)
		local shown = ShopScreen.Shelf()
		if shown then
			ShopScreen.Open(view, shown, on)
		end
	end)
	local last = 0
	RunService.Heartbeat:Connect(function()
		if os.clock() - last >= TICK then
			last = os.clock()
			tick()
		end
	end)
	while true do
		counter()
		task.wait(FIND_EVERY)
	end
end

return ShopController
