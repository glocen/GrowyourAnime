--!strict
-- BoardsCases: the boards on the Strip (TR58; BoardsController; BoardsService). At the crossing, facing the Shop: the four
-- plates stream in on the Shop's side, facing the Strip, in Config.Boards' order; a made-up page draws its first ten with
-- their names, and the viewer's own rank under them when they're outside; the news plate holds the last every-server
-- lines in our words. The made-up pages are put back, and the avatar goes home.

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
	for index = 1, Config.Shown + 1 do
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
			Name = "Boards on the Strip (TR58): four plates on the Shop's side facing the Strip; a made-up page's top ten with names, the own rank under, the news",
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
				-- A made-up page past the account's own: ten rows with their names, the account's rank under.
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
				t.Equal("ten rows", #rows, Config.Shown)
				t.Check("best first, a name and a number", rows[1] ~= nil and text(rows[1], "Rank") == "1" and text(rows[1], "Name") == "Tester 1"
					and text(rows[1], "Value") == Hud.Digits(TOP - 1000), if rows[1] then `{text(rows[1], "Name")} {text(rows[1], "Value")}` else "no row")
				local nameFits = true
				for _, row in rows do
					local name = row:FindFirstChild("Name") :: TextLabel?
					nameFits = nameFits and name ~= nil and name.TextFits
				end
				t.Check("every name fits its column", nameFits)
				local wantOwn = if type(mine) == "table" and mine.Rank then `You · #{Hud.Digits(mine.Rank)} · {Hud.Digits(mine.Value)}` else nil
				t.Check("the account's own rank under the ten", wantOwn ~= nil and text(gui, "Own") == wantOwn, `{text(gui, "Own")}, want {tostring(wantOwn)}`)
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
