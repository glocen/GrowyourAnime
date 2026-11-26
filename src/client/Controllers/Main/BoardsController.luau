--!strict
-- BoardsController (client): the boards on the Strip, drawn on their plates (TR58; docs/design.md, "Being seen";
-- BoardsService; Config.Boards). Each plate of the Boards marker gets a SurfaceGui of its own: its title and four rows
-- (Rules.Boards.Face): the top three, a rank, a name and a number, then the viewer's own row, lit, rank first, when
-- they stand outside them, or the fourth (research's must-fix, 2026-11-26), at Config.Boards.Face's size; the news
-- plate shows the last every-server lines in the same type, its words built here from our definitions
-- (Rules.Broadcast), only the player's own when they show no others' finds. The boards are asked for once the plates stream in, then every
-- Config.Boards.Read seconds; a new every-server line joins the news as it's heard. A grey block: the look follows
-- research's verdict, the art Modulo's.
--   BoardsController.Refresh()     asks for the boards now and draws them (yields): for tests
--   BoardsController.Gui(board)    the SurfaceGui drawn for `board`, or nil: for tests

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config.Boards)
local HudConfig = require(Shared.Config.Hud)
local Net = require(Shared.Net)
local Broadcast = require(Shared.Rules.Broadcast)
local Boards = require(Shared.Rules.Boards)
local Hud = require(Shared.Rules.Hud)
local Settings = require(Shared.Rules.Settings)
local Markers = require(Shared.World.Markers)
local Tags = require(Shared.World.Tags)
local UI = script.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local ProfileController = require(script.Parent.Parent.Core.ProfileController)

local BoardsController = {}

local F = Config.Face

local player = Players.LocalPlayer
local guis: { [string]: SurfaceGui } = {}
local last: { [string]: any }? = nil -- the last answer drawn
local news: { Broadcast.News } = {}

local function label(parent: Instance, name: string, text: string, size: number, font: Font, colour: Color3, box: UDim2, at: UDim2, align: Enum.TextXAlignment): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Size = box
	l.Position = at
	l.FontFace = font
	l.TextSize = size
	l.TextColor3 = colour
	l.TextXAlignment = align
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.Text = text
	l.Parent = parent
	return l
end

-- Words' width at `size` in `font`, in the face's pixels, so a name takes what its rank and number leave.
local function measure(text: string, font: Font, size: number): number
	local params = Instance.new("GetTextBoundsParams")
	params.Text = text
	params.Font = font
	params.Size = size
	params.Width = 100_000
	local ok, bounds = pcall(TextService.GetTextBoundsAsync, TextService, params)
	return if ok then math.ceil((bounds :: Vector2).X) + 2 else math.ceil(#text * size * 0.6)
end

-- The plate's SurfaceGui, emptied for a new drawing.
local function surface(board: string, plate: BasePart): Frame
	local gui = guis[board]
	if gui == nil or gui.Adornee ~= plate then
		if gui then
			gui:Destroy()
		end
		local made = Instance.new("SurfaceGui")
		made.Name = `NL_Board_{board}`
		made.Face = Enum.NormalId.Front
		made.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		made.PixelsPerStud = F.Pixels
		made.LightInfluence = 0
		made.MaxDistance = F.Reach
		made.ResetOnSpawn = false
		made.Adornee = plate
		made.Parent = player:WaitForChild("PlayerGui")
		guis[board] = made
		gui = made
	end
	local surfaceGui = gui :: SurfaceGui
	surfaceGui:ClearAllChildren()
	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromOffset(F.Pad, F.Pad)
	body.Size = UDim2.new(1, -2 * F.Pad, 1, -2 * F.Pad)
	body.Parent = surfaceGui
	label(body, "Title", Config.Titles[board] or board, F.Title.Size, Theme.Font.Strong, Theme.Colour.Text, UDim2.new(1, 0, 0, F.Title.Tall), UDim2.new(), Enum.TextXAlignment.Center)
	return body
end

-- A ranked board's face: the top three, then the viewer's own row, lit, rank first, when they stand outside them, or
-- the fourth (Rules.Boards.Face). A name takes what its rank and number leave.
local function drawBoard(board: string, plate: BasePart, got: any)
	local body = surface(board, plate)
	local rows = if type(got) == "table" and type(got.Rows) == "table" then got.Rows else {}
	local face = Boards.Face(rows, if type(got) == "table" then got.Mine else nil, Config.Top, player.DisplayName)
	local function said(row: any): string
		if board == "Week" then
			return `Floor {tonumber(row.Floor) or 0}`
		end
		return Hud.Digits(tonumber(row.Value) or 0)
	end
	local function ranked(row: any): string
		return if row.Rank then Hud.Digits(row.Rank) else `{Config.Page}+`
	end
	local R = F.Row
	local wide = plate.Size.X * F.Pixels - 2 * F.Pad
	local rankWide = F.Rank
	for _, row in face do
		rankWide = math.max(rankWide, measure(ranked(row), Theme.Font.Number, R.Size))
	end
	local y = F.Title.Tall + F.Gap
	for index, row in face do
		local line = Instance.new("Frame")
		line.Name = `Row{index}`
		line.BackgroundTransparency = if row.Mine then F.Lit else 1
		line.BackgroundColor3 = Theme.Colour.PlateHigh
		line.BorderSizePixel = 0
		line.Position = UDim2.fromOffset(0, y)
		line.Size = UDim2.new(1, 0, 0, R.Tall)
		line.Parent = body
		local colour = if row.Mine then Theme.Colour.Ready else Theme.Colour.Text
		local value = said(row)
		local valueWide = measure(value, Theme.Font.Number, R.Size)
		label(line, "Rank", ranked(row), R.Size, Theme.Font.Number, if row.Mine then colour else Theme.Colour.TextDim, UDim2.fromOffset(rankWide, R.Tall), UDim2.new(), Enum.TextXAlignment.Right)
		local name = if type(row.Name) == "string" and row.Name ~= "" then row.Name else "A player"
		label(line, "Name", name, R.Size, Theme.Font.Body, colour, UDim2.fromOffset(math.max(0, wide - rankWide - valueWide - 2 * F.Space), R.Tall), UDim2.fromOffset(rankWide + F.Space, 0), Enum.TextXAlignment.Left)
		local number = label(line, "Value", value, R.Size, Theme.Font.Number, colour, UDim2.fromOffset(valueWide, R.Tall), UDim2.fromScale(1, 0), Enum.TextXAlignment.Right)
		number.AnchorPoint = Vector2.new(1, 0)
		y += R.Tall
	end
	if #face == 0 then
		label(body, "Empty", "No one yet", R.Size, Theme.Font.Body, Theme.Colour.TextDim, UDim2.new(1, 0, 0, R.Tall), UDim2.fromOffset(0, y), Enum.TextXAlignment.Center)
	end
end

-- The news: the last every-server lines, newest first, each in its rarity's light, wrapped to two lines at most.
local function drawNews(plate: BasePart)
	local body = surface("News", plate)
	local view = ProfileController.Get()
	local others = view == nil or Settings.On(view :: any, "ShowFinds")
	local N = F.News
	local y = F.Title.Tall + F.Gap
	local shown = 0
	for _, item in news do
		if shown >= Config.News then
			break
		end
		if others or item.User == player.UserId then
			local parts, rarity = Broadcast.Line(item)
			local light = HudConfig.Card.Trim[rarity] or Theme.Colour.Text
			local line = label(body, `Line{shown + 1}`, Broadcast.Rich(parts, light:ToHex()), N.Size, Theme.Font.Body, Theme.Colour.Text, UDim2.new(1, 0, 0, N.Tall), UDim2.fromOffset(0, y), Enum.TextXAlignment.Left)
			line.RichText = true
			line.TextWrapped = true
			line.TextYAlignment = Enum.TextYAlignment.Top
			y += N.Tall
			shown += 1
		end
	end
	if shown == 0 then
		label(body, "Empty", "Nothing yet", F.Row.Size, Theme.Font.Body, Theme.Colour.TextDim, UDim2.new(1, 0, 0, F.Row.Tall), UDim2.fromOffset(0, y), Enum.TextXAlignment.Center)
	end
end

local function plates(): { [string]: BasePart }
	local out: { [string]: BasePart } = {}
	local model = Markers.Find("Boards")
	if model then
		for _, board in Config.Order do
			local plate = model:FindFirstChild(board)
			if plate and plate:IsA("BasePart") then
				out[board] = plate
			end
		end
	end
	return out
end

local function draw()
	local found = plates()
	local got = last
	for _, board in Config.Order do
		local plate = found[board]
		if plate then
			if board == "News" then
				drawNews(plate)
			else
				drawBoard(board, plate, if got and type(got.Boards) == "table" then (got.Boards :: any)[board] else nil)
			end
		end
	end
end

local function hearNews(item: any)
	if type(item) ~= "table" or item.Reach ~= "All" or type(item.Id) ~= "string" then
		return
	end
	for _, held in news do
		if held.Id == item.Id then
			return
		end
	end
	table.insert(news, 1, item :: Broadcast.News)
	while #news > Config.News do
		table.remove(news)
	end
	local plate = plates().News
	if plate then
		drawNews(plate)
	end
end

function BoardsController.Refresh()
	local ok, got = pcall(Net.Client.Invoke, "Boards")
	if ok and type(got) == "table" and got.Ok == true then
		last = got
		news = if type(got.News) == "table" then got.News else {}
	end
	draw()
end

function BoardsController.Gui(board: string): SurfaceGui?
	return guis[board]
end

function BoardsController.Start()
	Net.Client.On("Broadcast", hearNews)
	CollectionService:GetInstanceAddedSignal(Tags.Boards.Tag):Connect(function()
		task.defer(draw) -- streamed in again: the last answer drawn on the new plates
	end)
	task.spawn(function()
		while true do
			if next(plates()) ~= nil then
				BoardsController.Refresh()
				task.wait(Config.Read)
			else
				task.wait(2)
			end
		end
	end)
end

return BoardsController
