--!strict
-- BoardsController (client): the boards on the Strip, drawn on their plates (TR58; docs/design.md, "Being seen";
-- BoardsService; Config.Boards). Each plate of the Boards marker gets a SurfaceGui of its own: its title, its first
-- Config.Boards.Shown rows, a name and a number, and the viewer's own rank under them when they're outside; the news
-- plate shows the last every-server lines, its words built here from our definitions (Rules.Broadcast), only the
-- player's own when they show no others' finds. The boards are asked for once the plates stream in, then every
-- Config.Boards.Read seconds; a new every-server line joins the news as it's heard. A grey block: the look follows
-- research's verdict, the art Modulo's.
--   BoardsController.Refresh()     asks for the boards now and draws them (yields): for tests
--   BoardsController.Gui(board)    the SurfaceGui drawn for `board`, or nil: for tests

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config.Boards)
local HudConfig = require(Shared.Config.Hud)
local Net = require(Shared.Net)
local Broadcast = require(Shared.Rules.Broadcast)
local Hud = require(Shared.Rules.Hud)
local Settings = require(Shared.Rules.Settings)
local Markers = require(Shared.World.Markers)
local Tags = require(Shared.World.Tags)
local UI = script.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local ProfileController = require(script.Parent.Parent.Core.ProfileController)

local BoardsController = {}

local PIXELS = 40 -- a plate's pixels a stud: a 14-stud plate draws 560 across
local REACH = 120 -- studs the words draw from
local PAD = 18 -- authored pixels round a plate's words
local TITLE, ROW, NEWS = 30, 26, 30 -- line heights, authored pixels
local RANK = 44 -- the rank's column

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
		made.PixelsPerStud = PIXELS
		made.LightInfluence = 0
		made.MaxDistance = REACH
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
	body.Position = UDim2.fromOffset(PAD, PAD)
	body.Size = UDim2.new(1, -2 * PAD, 1, -2 * PAD)
	body.Parent = surfaceGui
	label(body, "Title", Config.Titles[board] or board, Theme.Text.Big, Theme.Font.Strong, Theme.Colour.Text, UDim2.new(1, 0, 0, TITLE), UDim2.new(), Enum.TextXAlignment.Center)
	return body
end

-- A ranked board: its rows, then the viewer's own line when they're outside the first Shown.
local function drawBoard(board: string, plate: BasePart, got: any)
	local body = surface(board, plate)
	local rows = if type(got) == "table" and type(got.Rows) == "table" then got.Rows else {}
	local function said(row: any): string
		if board == "Week" then
			return `Floor {tonumber(row.Floor) or 0}`
		end
		return Hud.Digits(tonumber(row.Value) or 0)
	end
	local y = TITLE + 8
	for index, row in rows :: { any } do
		if index > Config.Shown then
			break
		end
		local line = Instance.new("Frame")
		line.Name = `Row{index}`
		line.BackgroundTransparency = if row.Mine then 0.4 else 1
		line.BackgroundColor3 = Theme.Colour.PlateHigh
		line.BorderSizePixel = 0
		line.Position = UDim2.fromOffset(0, y)
		line.Size = UDim2.new(1, 0, 0, ROW)
		line.Parent = body
		local colour = if row.Mine then Theme.Colour.Ready else Theme.Colour.Text
		label(line, "Rank", tostring(row.Rank or ""), Theme.Text.Title, Theme.Font.Number, Theme.Colour.TextDim, UDim2.fromOffset(RANK - 10, ROW), UDim2.new(), Enum.TextXAlignment.Right)
		label(line, "Name", if row.Name ~= "" then row.Name else "A player", Theme.Text.Title, Theme.Font.Body, colour, UDim2.new(0.62, -RANK, 0, ROW), UDim2.fromOffset(RANK, 0), Enum.TextXAlignment.Left)
		label(line, "Value", said(row), Theme.Text.Title, Theme.Font.Number, colour, UDim2.new(0.38, 0, 0, ROW), UDim2.fromScale(0.62, 0), Enum.TextXAlignment.Right)
		y += ROW
	end
	if #rows == 0 then
		label(body, "Empty", "No one yet", Theme.Text.Title, Theme.Font.Body, Theme.Colour.TextDim, UDim2.new(1, 0, 0, ROW), UDim2.fromOffset(0, y), Enum.TextXAlignment.Center)
	end
	local own = if type(got) == "table" then got.Mine else nil
	if type(own) == "table" and (own.Rank == nil or own.Rank > Config.Shown) then
		local where = if own.Rank then `#{Hud.Digits(own.Rank)}` else `Past the top {Config.Page}`
		label(body, "Own", `You · {where} · {said(own)}`, Theme.Text.Title, Theme.Font.Strong, Theme.Colour.Ready, UDim2.new(1, 0, 0, ROW), UDim2.new(0, 0, 1, -ROW), Enum.TextXAlignment.Center)
	end
end

-- The news: the last every-server lines, newest first, each in its rarity's light.
local function drawNews(plate: BasePart)
	local body = surface("News", plate)
	local view = ProfileController.Get()
	local others = view == nil or Settings.On(view :: any, "ShowFinds")
	local y = TITLE + 8
	local shown = 0
	for _, item in news do
		if shown >= Config.News then
			break
		end
		if others or item.User == player.UserId then
			local parts, rarity = Broadcast.Line(item)
			local light = HudConfig.Card.Trim[rarity] or Theme.Colour.Text
			local line = label(body, `Line{shown + 1}`, Broadcast.Rich(parts, light:ToHex()), Theme.Text.Body + 2, Theme.Font.Body, Theme.Colour.Text, UDim2.new(1, 0, 0, NEWS), UDim2.fromOffset(0, y), Enum.TextXAlignment.Left)
			line.RichText = true
			y += NEWS
			shown += 1
		end
	end
	if shown == 0 then
		label(body, "Empty", "Nothing yet", Theme.Text.Title, Theme.Font.Body, Theme.Colour.TextDim, UDim2.new(1, 0, 0, ROW), UDim2.fromOffset(0, y), Enum.TextXAlignment.Center)
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
