--!strict
-- The Festival of Battles in its own place (TR45), apart: Cases is at the type checker's limit. Every trip a case asks
-- for is recorded by TravelService's stub, which the run turns on (init), so nothing leaves the place under test.
-- * In the base's place: the plot's Festival Door and the dock's Play tile open the stages' menu; a pick asks for the
--   trip with that stage on its ticket, the trip's card up and naming where; a second pick meanwhile is refused; Roblox
--   refusing it brings the screen back with a line; a flooded server keeps it under way; a shut stage asks for none.
-- * In the Festival's place: the player lands at the street's landing, out of every pack's reach; a ticket's stage begins
--   on arrival, set down at its start; a ticket for a stage the save keeps shut opens the menu instead; the ground's
--   door, and the dock's Base tile after its charge, ask for the trip home; in a keeper's try the tile dims and says why.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Combat = require(Shared.Config.Combat)
local HomeConfig = require(Shared.Config.Home)
local WorldConfig = require(Shared.Config.World)
local Markers = require(Shared.World.Markers)
local Stages = require(Shared.Rules.Stages)
local ProfileController = require(script.Parent.Parent.ProfileController)
local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local TravelController = require(script.Parent.Parent.Parent.Main.TravelController)
local Helpers = require(script.Parent.Helpers)
local UI = script.Parent.Parent.Parent.Parent.UI
local Screen = require(UI.Kit.Screen)
local Layers = require(UI.Layers)
local Button = require(UI.Kit.Button)
local Toast = require(UI.Kit.Toast)
local StageScreen = require(UI.StageScreen)

local TravelCases = {}

local GROUND = WorldConfig.Row.Ground
local MOVE = 2.5 -- seconds for a set-down's fade to move the avatar (KeeperService's)
local REMOTE_GAP = 0.6 -- seconds between two calls of the Stage remote (two a second at most)
local FAILED = "The trip didn't go through. Try again."

local player = Players.LocalPlayer
local waitFor = Helpers.waitFor
local lastTrip = Helpers.lastTrip

local function flat(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function pick(difficulty: string): { [string]: any }
	local ok, answer = pcall(Net.Client.Invoke, "Stage", GROUND, difficulty)
	return if ok and type(answer) == "table" then answer else { Ok = false, Error = tostring(answer) }
end

local function card(): ScreenGui?
	local gui = player:WaitForChild("PlayerGui"):FindFirstChild("TravelCard")
	return if gui and gui:IsA("ScreenGui") then gui else nil
end

local function closeScreen(t: any)
	if Screen.Current() ~= nil then
		Screen.Close()
		t.Wait(0.4)
	end
end

-- The first stage this save keeps shut, Normal then Hard, or nil when it opens every one.
-- Whether this save keeps Hard shut (TR50: a run begins at its checkpoint, so only Hard's lock can shut a pick).
local function hardShut(): boolean
	local view = ProfileController.Get()
	return view ~= nil and Stages.Needs(view :: any, GROUND, "Hard", 1) == Stages.Keeper
end

-- The checkpoint a run on `difficulty` begins at, by this save.
local function checkpoint(difficulty: string): number
	local view = ProfileController.Get()
	return if view then Stages.Checkpoint(view :: any, GROUND, difficulty) else 1
end

function TravelCases.Cases(given: { [string]: any }): { any }
	local REPLICATE, SET_DOWN, R6_ROOT_HEIGHT = given.REPLICATE, given.SET_DOWN, given.R6_ROOT_HEIGHT
	local streamed, walkThrough, lintClean = given.streamed, given.walkThrough, given.lintClean
	return {
		{
			Name = "Places (TR45): in the base, the plot's door and the dock's Play tile open the Arc panel; a pick is the trip there with its checkpoint on the ticket and its card up; a failed trip says so; a shut Hard stays",
			Place = "Main",
			Stay = true, -- it moves the avatar itself; the next case's reset takes it back to the pad
			Run = function(t: any)
				t.Server("TravelStub", true)
				closeScreen(t)
				local plot = player:GetAttribute("Plot")
				local where = if type(plot) == "number" then { Plot = plot } else nil
				local door = if where then streamed(t, "FestivalDoor", where) else nil
				local spawn = if where then streamed(t, "Spawn", where) else nil
				t.Check("the plot has its door and its spawn", door ~= nil and spawn ~= nil)
				if not (door and spawn) then
					return
				end
				-- From the spawn, as a player arrives.
				t.Root().CFrame = Markers.At(spawn) + Vector3.new(0, R6_ROOT_HEIGHT, 0)
				t.Wait(0.5)
				local fromSpawn = flat(Markers.At(door).Position, Markers.At(spawn).Position)
				t.Check("the door stands near the spawn, in view", fromSpawn < 60, `{math.floor(fromSpawn)} studs`)
				t.Check("walking into it opens the Festival's menu", walkThrough(t, door, true, function(): boolean
					return Screen.Current() == StageScreen.Name
				end), tostring(Screen.Current()))
				local record = t.Server("TravelSent")
				t.Check("and asks for no trip on its own", #record.Sent == 0 and record.Going == false, `{#record.Sent} asked`)
				t.Root().CFrame = Markers.At(spawn) + Vector3.new(0, R6_ROOT_HEIGHT, 0)
				closeScreen(t)
				-- The dock's tile, its word Play (the director, 2026-11-19).
				local parts = HudController.Parts()
				local tile = parts.Map :: TextButton
				local word = (parts.Dock :: Frame):FindFirstChild("MapWord", true)
				t.Equal("the dock's tile says Play", if word and word:IsA("TextLabel") then word.Text else nil, "Play")
				t.Check("its tap opens the menu", Button.Press(tile) and waitFor(t, 1, function(): boolean
					return Screen.Current() == StageScreen.Name
				end), tostring(Screen.Current()))
				t.Check("a second tap closes it", Button.Press(tile) and waitFor(t, 1, function(): boolean
					return Screen.Current() == nil
				end), tostring(Screen.Current()))
				-- A pick: the trip there, the run's checkpoint on its ticket, the card up.
				Button.Press(tile)
				waitFor(t, 1, function(): boolean
					return StageScreen.Parts().Normal ~= nil
				end)
				local difficulty = "Normal"
				local at = checkpoint(difficulty)
				local first = StageScreen.Parts().Normal :: TextButton?
				t.Check("the panel has Normal", first ~= nil)
				if first == nil then
					return
				end
				Button.Press(first)
				local trip: { [string]: any }? = nil
				t.Check("a pick asks for the trip to the Festival", waitFor(t, Helpers.TRIP_ASKED, function(): boolean
					trip = lastTrip(t, "Festival")
					return trip ~= nil
				end))
				local ticket = if trip then trip.Ticket else nil
				t.Check("its ticket names the run's checkpoint", type(ticket) == "table" and ticket.Go == "Stage" and ticket.Ground == GROUND and ticket.Difficulty == difficulty and ticket.Stage == at, if type(ticket) == "table" then `{ticket.Go} {ticket.Ground} {ticket.Difficulty} {ticket.Stage}` else "none")
				t.Check("the menu closes", waitFor(t, 1, function(): boolean
					return Screen.Current() == nil
				end), tostring(Screen.Current()))
				t.Check("the trip's card comes up", waitFor(t, REPLICATE, function(): boolean
					return TravelController.Showing() and card() ~= nil
				end))
				local shown = card()
				local title = if shown then shown:FindFirstChild("Title", true) else nil
				t.Equal("it names where", if title and title:IsA("TextLabel") then title.Text else nil, WorldConfig.Signs.Door.Name)
				-- The menu sinks away as it closes (Screen.Close's Rise), out of the safe area by design: the card is read once
				-- it has left.
				local menus = Layers.Get("Menus")
				waitFor(t, 1, function(): boolean
					for _, piece in menus:GetChildren() do
						if string.sub(piece.Name, -7) == "Leaving" then
							return false
						end
					end
					return true
				end)
				lintClean(t, "the trip's card")
				t.Wait(REMOTE_GAP)
				t.Equal("a second pick while it's under way is refused", pick(difficulty).Error, "Busy")
				-- Roblox refuses it: the screen back, with a line.
				t.Check("Roblox refuses the trip", t.Server("TravelFail", "Unauthorized") == true)
				t.Check("the card goes", waitFor(t, REPLICATE, function(): boolean
					return card() == nil
				end))
				t.Check("and a line says so", table.find(Toast.Shown(), FAILED) ~= nil, table.concat(Toast.Shown(), " | "))
				t.Equal("nothing under way", t.Server("TravelSent").Going, false)
				-- A flooded server: tried again after its wait, under way meanwhile.
				t.Wait(REMOTE_GAP)
				t.Check("a pick again", pick(difficulty).Ok == true)
				t.Server("TravelFail", "Flooded")
				record = t.Server("TravelSent")
				t.Check("Roblox's server flooded: still under way, to be tried again", record.Going == true and record.Failed == 1, `going {record.Going}, failed {record.Failed}`)
				t.Server("TravelStub", true)
				t.Check("the stub's reset brings the screen back quietly", waitFor(t, REPLICATE, function(): boolean
					return card() == nil
				end))
				-- Hard while the save keeps it shut, and a difficulty that isn't one: refused, no trip asked.
				local shutHard = hardShut()
				if shutHard then
					t.Wait(REMOTE_GAP)
					t.Equal("Hard, shut: refused", pick("Hard").Error, Stages.Locked)
				end
				t.Wait(REMOTE_GAP)
				t.Equal("a difficulty that isn't one: unknown", pick("Nightmare").Error, Stages.Unknown)
				record = t.Server("TravelSent")
				t.Check(`neither asks for a trip{if shutHard then "" else " (this save keeps Hard open)"}`, #record.Sent == 0 and record.Going == false, `{#record.Sent} asked`)
			end,
		},
		{
			Name = "Places (TR45): in the Festival, the player lands out of every pack's reach; a ticket's stage begins on arrival; a shut one opens the menu; the ground's door and the Base tile ask for the trip home, the tile dim in a keeper's try",
			Place = "Festival",
			Stay = true, -- it moves the avatar itself; the next case's reset takes it back to the pad
			Run = function(t: any)
				t.Server("TravelStub", true)
				closeScreen(t)
				local landing = streamed(t, "DoorLanding", { Ground = GROUND })
				local door = streamed(t, "GroundDoor", { Ground = GROUND })
				local start = streamed(t, "StageStart", { Ground = GROUND, Stage = 1 })
				local world = workspace:FindFirstChild("World")
				local arrival = if world then world:FindFirstChild("Arrival") else nil
				t.Check("the landing, the ground's door, Stage 1's start and the place's spawn", landing ~= nil and door ~= nil and start ~= nil and arrival ~= nil and arrival:IsA("SpawnLocation"))
				if not (landing and door and start and arrival and arrival:IsA("SpawnLocation")) then
					return
				end
				-- Where a player lands: the spawn at the landing, out of the lead's leash of every pack.
				local at = Markers.At(landing)
				t.Near("the place's spawn stands on the landing (studs off)", flat(arrival.Position, at.Position), 0, SET_DOWN)
				local nearest = math.huge
				for _, pack in Markers.All("Pack") do
					nearest = math.min(nearest, flat(Markers.At(pack).Position, at.Position))
				end
				t.Check("no pack within the lead's leash of it", nearest > Combat.Lead.Leash, `{math.floor(nearest)} studs to the nearest`)
				-- A ticket's run begins on arrival at its checkpoint, set down at that stretch's start.
				t.Root().CFrame = at + Vector3.new(0, R6_ROOT_HEIGHT, 0)
				t.Server("LeadHeal")
				t.Wait(0.5)
				t.Check("a ticket for Normal is taken", t.Server("StageArriveBy", "Normal", 1).Ok == true)
				local reached = checkpoint("Normal")
				t.Check("its run begins at the checkpoint", waitFor(t, REPLICATE + 1, function(): boolean
					return player:GetAttribute("StageRun") == `Normal {reached}`
				end), `{player:GetAttribute("StageRun")}, the checkpoint {reached}`)
				if reached ~= 1 then
					start = streamed(t, "StageStart", { Ground = GROUND, Stage = reached }) or start
				end
				t.Wait(MOVE)
				t.Near("set down at its start (studs off)", flat(t.Root().Position, Markers.At(start).Position), 0, SET_DOWN)
				t.Check("with no menu up", Screen.Current() == nil, tostring(Screen.Current()))
				-- A ticket for Hard while the save keeps it shut, as a forged or stale one would be: the panel, no run.
				if hardShut() then
					t.Server("StageArriveBy", "Hard", 1)
					t.Check("a ticket for Hard, shut: the panel instead", waitFor(t, REPLICATE + 1, function(): boolean
						return Screen.Current() == StageScreen.Name
					end), tostring(Screen.Current()))
					t.Check("and no run", player:GetAttribute("StageRun") == nil, tostring(player:GetAttribute("StageRun")))
					closeScreen(t)
				end
				-- The ground's door: the trip home.
				t.Check("walking into the ground's door asks for the trip home", walkThrough(t, door, true, function(): boolean
					return lastTrip(t, "Main") ~= nil
				end))
				local home = lastTrip(t, "Main")
				t.Equal("its ticket says home", if home then home.Ticket.Go else nil, "Home")
				t.Check("its card comes up, naming home", waitFor(t, REPLICATE, function(): boolean
					local shown = card()
					local title = if shown then shown:FindFirstChild("Title", true) else nil
					return title ~= nil and title:IsA("TextLabel") and title.Text == "Home"
				end))
				t.Root().CFrame = at + Vector3.new(0, R6_ROOT_HEIGHT, 0) -- off the door, before the trip's reset
				t.Wait(0.3)
				t.Server("TravelStub", true)
				-- The dock's Base tile: its charge, then the trip home.
				local base = HudController.Parts().Base :: TextButton
				t.Server("HomeReady")
				t.Server("LeadCalm")
				t.Wait(REPLICATE)
				t.Equal("away from the base the server would take them", t.Server("HomeState").Refusal, "")
				t.Check("a tap begins the charge", Button.Press(base) and waitFor(t, REPLICATE, function(): boolean
					return player:GetAttribute("HomeCharge") ~= nil
				end))
				t.Check("then it asks for the trip home", waitFor(t, HomeConfig.Charge + REPLICATE + 1, function(): boolean
					return lastTrip(t, "Main") ~= nil
				end))
				t.Server("TravelStub", true)
				t.Server("HomeReady")
				-- A keeper's try: dim, and a tap says so.
				t.Server("KeeperRest", 0)
				local try = t.Server("KeeperTry")
				local tried = type(try) == "table" and try.Ok == true
				t.Check("a try starts", tried, if type(try) == "table" then tostring(try.Error) else "")
				if tried then
					t.Check("in a boss's ground the tile dims", waitFor(t, REPLICATE + 1, function(): boolean
						return player:GetAttribute("Try") ~= nil and base:GetAttribute("Look") == "Dim"
					end), tostring(base:GetAttribute("Look")))
					local before = tonumber(base:GetAttribute("Shakes")) or 0
					Button.Press(base)
					t.Check("a tap says it's a boss's ground, and shakes", waitFor(t, REPLICATE, function(): boolean
						return table.find(Toast.Shown(), "Not in a boss's arena") ~= nil and (tonumber(base:GetAttribute("Shakes")) or 0) > before
					end))
					-- The keeper stands in its ring only once the try's fade has moved the player (the server says NoTry
					-- before), so the loss is asked until it's taken, then the try ends after the lead's fall.
					local fade = Combat.Keeper.Fade
					local ended: any = nil
					waitFor(t, fade.Out + fade.Hold + 1, function(): boolean
						ended = t.Server("KeeperEnd", "Loss")
						return type(ended) == "table" and ended.Ok == true
					end)
					t.Check("the try ends", type(ended) == "table" and ended.Ok == true and waitFor(t, Combat.Keeper.LossPause + fade.Out + fade.Hold + 2, function(): boolean
						return player:GetAttribute("Try") == nil
					end), if type(ended) == "table" then tostring(ended.Error) else "")
				end
				closeScreen(t) -- the lost try's card
				t.Server("LeadHeal")
				t.Server("HomeReady")
				t.Root().CFrame = at + Vector3.new(0, R6_ROOT_HEIGHT, 0)
			end,
		},
	}
end

return TravelCases
