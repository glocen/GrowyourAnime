--!strict
-- BoardsCases: the boards on the Strip (TR58; BoardsController; BoardsService). At the crossing, facing the Shop: the four
-- plates stream in on the Shop's side, facing the Strip, in Config.Boards' order; a made-up page's face draws its top
-- three with their names, then the viewer's own row, lit, rank first, when they're outside, and lit in place with the
-- fourth under when they're among them (TR58's must-fix); the news plate holds the last every-server lines in our words.
-- The made-up pages are put back, and the avatar goes home.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config.Boards)
local WorldConfig = require(Shared.Config.World)
local Broadcast = require(Shared.Rules.Broadcast)
local Hud = require(Shared.Rules.Hud)
local Markers = require(Shared.World.Markers)
local BoardsController = require(script.Parent.Parent.Parent.Main.BoardsController)
local Helpers = require(script.Parent.Helpers)

local BoardsCases = {}

local waitFor = Helpers.waitFor
local STAND = 4 -- the avatar's root over the crossing's paving, as StripCases stands it
local STREAM_IN = 8 -- seconds for the plates to stream in round the avatar
local ARRIVE = 8 -- seconds for a respawned avatar to land
local TOP = 10_000_000 -- the made-up page's best, past any lead a test account holds

local function rowsOf(gui: SurfaceGui?): { Frame }
	local out: { Frame } = {}
	local body = if gui then gui:FindFirstChild("Body") else nil
	for index = 1, Config.Top + 2 do
		local row = if body then body:FindFirstChild(`Row{index}`) else nil
		if row and row:IsA("Frame") then
			table.insert(out, row)
		end
	end
	return out
end

local function text(parent: Instance?, name: string): string
	local found = if parent then parent:FindFirstChild(name, true) else nil
	return if found and found:IsA("TextLabel") then found.ContentText else ""
end

function BoardsCases.Cases(): { any }
	return {
		{
			Name = "Boards on the Strip (TR58): four plates on the Shop's side facing the Strip; a made-up page's top three with names, the own row lit, the news",
			Run = function(t: any)
				t.Server("TestStandAt", Vector3.new(0, STAND, 14), Vector3.new(0, STAND, 40))
				local model: Instance? = nil
				waitFor(t, STREAM_IN, function(): boolean
					model = Markers.Find("Boards")
					return model ~= nil and #model:GetChildren() >= 2 * #Config.Order
				end)
				t.Check("the boards stream in at the crossing", model ~= nil)
				local edge = WorldConfig.Strip.Wide * WorldConfig.Walk / 2
				local lastX = math.huge
				for _, board in Config.Order do
					local plate = if model then model:FindFirstChild(board) else nil
					local ok = plate ~= nil and plate:IsA("BasePart")
					t.Check(`{board}: a plate on the Shop's side, facing the Strip, left to right as the viewer comes back`, ok
						and (plate :: BasePart).Position.Z > edge and (plate :: BasePart).CFrame.LookVector.Z < -0.99 and (plate :: BasePart).Position.X < lastX,
						if ok then tostring((plate :: BasePart).Position) else "no plate")
					if ok then
						lastX = (plate :: BasePart).Position.X
					end
				end
				-- A made-up page past the account's own: the top three with their names, then the account's own row, lit.
				local entries = {}
				for i = 1, 30 do
					table.insert(entries, { Id = 900_000 + i, Score = TOP - 1000 * i, Name = `Tester {i}` })
				end
				t.Check("a made-up page set", (t.Server("BoardsPage", "Lead", entries) :: any).Ok == true)
				local read = t.Server("Boards") :: any
				local mine = if type(read) == "table" and read.Boards and read.Boards.Lead then read.Boards.Lead.Mine else nil
				BoardsController.Refresh()
				local gui = BoardsController.Gui("Lead")
				local rows = rowsOf(gui)
				t.Check("its title", text(gui, "Title") == Config.Titles.Lead, text(gui, "Title"))
				t.Equal("four rows: the top three and the account's own", #rows, Config.Top + 1)
				t.Check("best first, a name and a number", rows[1] ~= nil and text(rows[1], "Rank") == "1" and text(rows[1], "Name") == "Tester 1"
					and text(rows[1], "Value") == Hud.Digits(TOP - 1000), if rows[1] then `{text(rows[1], "Name")} {text(rows[1], "Value")}` else "no row")
				local clear, sized = true, true
				for _, row in rows do
					local name, value = row:FindFirstChild("Name") :: TextLabel?, row:FindFirstChild("Value") :: TextLabel?
					clear = clear and name ~= nil and value ~= nil and value.TextFits
						and name.AbsolutePosition.X + name.AbsoluteSize.X <= value.AbsolutePosition.X + 1
					sized = sized and name ~= nil and name.TextSize == Config.Face.Row.Size
				end
				t.Check("a name never runs into its number, every number whole", clear)
				t.Check("rows at the face's size, about three times the first's 20", sized and Config.Face.Row.Size >= 2.5 * 20)
				local lit = function(row: Frame?): boolean
					return row ~= nil and row.BackgroundTransparency < 1
				end
				local own = rows[Config.Top + 1]
				t.Check("the account's own row, lit, rank first", type(mine) == "table" and lit(own) and not lit(rows[1])
					and text(own, "Rank") == (if mine.Rank then Hud.Digits(mine.Rank) else `{Config.Page}+`)
					and text(own, "Name") == Players.LocalPlayer.DisplayName and text(own, "Value") == Hud.Digits(mine.Value),
					if own then `{text(own, "Rank")} {text(own, "Name")} {text(own, "Value")}` else "no row")
				-- Among the top three: lit where they stand, the fourth row the fourth.
				local value = if type(mine) == "table" then tonumber(mine.Value) or 0 else 0
				if value >= 8 then
					local near = { { Id = 900_001, Score = value + 1000, Name = "Tester 1" } }
					for i = 2, 6 do
						table.insert(near, { Id = 900_000 + i, Score = value - i, Name = `Tester {i}` })
					end
					t.Server("BoardsPage", "Lead", near)
					BoardsController.Refresh()
					rows = rowsOf(BoardsController.Gui("Lead"))
					t.Check("among the top three: lit where they stand, the fourth row the fourth", #rows == Config.Top + 1 and lit(rows[2])
						and not lit(rows[4]) and text(rows[4], "Rank") == "4" and text(rows[4], "Name") == "Tester 3",
						`{#rows} rows; the fourth {if rows[4] then text(rows[4], "Rank") .. " " .. text(rows[4], "Name") else "none"}`)
				else
					t.Check("the account has a lead to stand among the top with", false, `its number {value}`)
				end
				t.Server("BoardsPage", "Lead", nil)
				-- The news: every-server lines, newest first, in our words.
				t.Server("BroadcastTell", "Stars", "rook", "Common", 7)
				t.Wait(0.5)
				read = t.Server("Boards") :: any
				local news = if type(read) == "table" and type(read.News) == "table" then read.News else {}
				BoardsController.Refresh()
				local plate = BoardsController.Gui("News")
				local want = math.min(#news, Config.News)
				local drawn = 0
				for index = 1, Config.News do
					if text(plate, `Line{index}`) ~= "" then
						drawn += 1
					end
				end
				t.Equal("the news plate holds the server's last every-server lines", drawn, want)
				if want > 0 then
					local parts = Broadcast.Line(news[1])
					t.Equal("newest first, in our words", text(plate, "Line1"), Broadcast.Plain(parts))
				else
					t.Equal("none yet: its empty line", text(plate, "Empty"), "Nothing yet")
				end
				-- Home again.
				local old = Players.LocalPlayer.Character
				t.Check("the avatar goes home", t.Server("Respawn") == true and waitFor(t, ARRIVE, function(): boolean
					local character = Players.LocalPlayer.Character
					return character ~= nil and character ~= old and character:FindFirstChild("HumanoidRootPart") ~= nil
				end))
			end,
		},
	}
end

return BoardsCases
