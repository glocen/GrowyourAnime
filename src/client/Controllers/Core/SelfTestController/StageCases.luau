--!strict
-- A ground's run of stretches (TR43, TR50), apart: Cases is at the type checker's limit. One case walks a run through
-- the server's own paths (StageService), the falls through the fight's (StageFell fells a group with the player as its
-- hitter): the gates shut and the set-back at one; Hard refused while shut; a Normal run from the first stretch counted
-- to its quota and its elite, written once and moving on to the next stretch with no card, the gate behind it open; the
-- street left ending the run, its checkpoint kept; the Arc panel at that checkpoint, Hard's lock and why; the keeper's
-- fall on Normal, its card opening Hard; Hard's own foes for this player alone, ten levels up, the lead solo, the run
-- moving on to its next stretch's own foes; the keeper lifted on Hard; and a fall at stretch 3, its card and the next run
-- there. The player's record is put back at its end. A fresh account through the Door is its own case, Manual: it wipes
-- the save.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local WorldConfig = require(Shared.Config.World)
local StagesConfig = require(Shared.Config.Stages)
local HudConfig = require(Shared.Config.Hud)
local UIKit = require(Shared.Config.UIKit)
local Markers = require(Shared.World.Markers)
local Stages = require(Shared.Rules.Stages)
local Sheet = require(Shared.Rules.Sheet)
local Collection = require(Shared.Rules.Collection)
local Parts = require(Shared.Util.Parts)
local Profile = require(Shared.Data.Profile)
local ProfileController = require(script.Parent.Parent.ProfileController)
local StageController = require(script.Parent.Parent.Parent.Main.StageController)
local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local Helpers = require(script.Parent.Helpers)
local UI = script.Parent.Parent.Parent.Parent.UI
local Screen = require(UI.Kit.Screen)
local Button = require(UI.Kit.Button)
local Toast = require(UI.Kit.Toast)
local StageScreen = require(UI.StageScreen)
local VoidkinScreen = require(UI.VoidkinScreen)
local Layers = require(UI.Layers)
local Theme = require(UI.Theme)

local StageCases = {}

local GROUND = WorldConfig.Row.Ground
local MOVE = 2.5 -- seconds for a set-down's fade to move the avatar (KeeperService's)
local REPLICATE = 2 -- seconds for an attribute or a remote to reach the client
local R6_ROOT_HEIGHT = 3

local player = Players.LocalPlayer
local waitFor = Helpers.waitFor

local function root(): BasePart?
	return Parts.Root(player.Character)
end

-- This player's Hard foes standing in `stage`.
local function mine(stage: number, standing: boolean?): { Model }
	local found = {}
	local fighters = workspace:FindFirstChild("Fighters")
	for _, model in if fighters then fighters:GetChildren() else {} do
		if model:IsA("Model") and model:GetAttribute("For") == player.UserId and model:GetAttribute("Stage") == stage and not (standing and model:GetAttribute("State") == "Down") then
			table.insert(found, model)
		end
	end
	return found
end

local function begin(difficulty: string): { [string]: any }
	local ok, answer = pcall(Net.Client.Invoke, "Stage", GROUND, difficulty)
	return if ok and type(answer) == "table" then answer else { Ok = false, Error = tostring(answer) }
end

local function line(difficulty: string): Profile.StageLine
	local view = ProfileController.Get()
	return if view then Stages.Line(view, GROUND, difficulty) else { Cleared = -1, Best = {} }
end

function StageCases.Cases(): { any }
	return {
		{
			Name = "Stages (AR57): the square holds the Guard's elite on the street and the Dasher's elite in a Hard run's stretch, its fall the stretch's last",
			Place = "Festival", -- TR45: its world stands in that place only
			Run = function(t: any)
				if Screen.Current() ~= nil then
					Screen.Close()
					t.Wait(0.3)
				end
				local square = Helpers.SQUARE
				local stop: WorldConfig.Stop? = nil
				for _, each in WorldConfig.Row.Stops do
					stop = if each.Square then each else stop
				end
				t.Check("a square down the street", stop ~= nil and square.Stage > 0)
				if stop == nil then
					return
				end
				local street: { [string]: any }? = nil
				for _, group in t.Server("Packs") do
					street = if group.Name == square.Name then group else street
				end
				t.Equal("on the street (Normal): the Guard's elite", if street then street.Def else nil, "guard_elite")
				local before = t.Server("Stage")
				local held = before.Checkpoint or { Normal = 1, Hard = 1 }
				local was = {
					Normal = { before.Normal and before.Normal.Cleared or 0, held.Normal },
					Hard = { before.Hard and before.Hard.Cleared or 0, held.Hard },
				}
				local count = #(Stages.Of(GROUND) :: { any })
				local ok, err = pcall(function()
					Helpers.endRun(t)
					t.Server("LeadHeal")
					t.Server("StageLine", "Normal", count)
					t.Server("StageLine", "Hard", square.Stage - 1, square.Stage)
					local answer = begin("Hard")
					t.Check(`a Hard run at stretch {square.Stage}`, answer.Ok == true and waitFor(t, REPLICATE, function(): boolean
						return player:GetAttribute("StageRun") == `Hard {square.Stage}`
					end), `{tostring(answer.Error)} {tostring(player:GetAttribute("StageRun"))}`)
					local elite: Model? = nil
					waitFor(t, REPLICATE, function(): boolean
						for _, model in mine(square.Stage) do
							local def = model:GetAttribute("Def")
							elite = if def == "dasher_elite" or def == "guard_elite" or def == "brawler_elite" then model else elite
						end
						return elite ~= nil
					end)
					t.Equal("its square: the Dasher's elite", if elite then elite:GetAttribute("Def") else nil, "dasher_elite")
					t.Equal("lifted to Hard's level", if elite then elite:GetAttribute("Level") else nil, Stages.Level((stop :: WorldConfig.Stop).Level, "Hard"))
					local fell = t.Server("StageFell", `{square.Name} mine`)
					t.Check("its fall is the stretch's last", fell.Ok == true and waitFor(t, REPLICATE, function(): boolean
						return player:GetAttribute("StageLast") == true
					end), tostring(fell.Error))
				end)
				Helpers.endRun(t)
				t.Server("StageLine", "Hard", 0)
				t.Server("StageLine", "Normal", was.Normal[1], was.Normal[2])
				t.Server("StageLine", "Hard", was.Hard[1], was.Hard[2])
				t.Server("LeadHeal")
				if Screen.Current() == StageScreen.Name then
					Screen.Close()
				end
				if not ok then
					error(err, 0)
				end
			end,
		},
		{
			Name = "Stages (fall card): a fall's card holds Retry, Send another and Home; Retry dim with the healing time while its lead heals beside the Arrival pad, a tap then doing nothing; the picker brings the card back; Retry lights once its lead is up and starts the run",
			Place = "Festival", -- TR45: its world stands in that place only
			Run = function(t: any)
				if Screen.Current() ~= nil then
					Screen.Close()
					t.Wait(0.3)
				end
				Helpers.endRun(t)
				t.Server("LeadHeal")
				local before = t.Server("Stage")
				local held = before.Checkpoint or { Normal = 1, Hard = 1 }
				local was = { before.Normal and before.Normal.Cleared or 0, held.Normal }
				local function restore()
					Helpers.endRun(t)
					t.Server("StageLine", "Normal", was[1], was[2])
					t.Server("LeadHeal")
					if Screen.Current() ~= nil then
						Screen.Close()
					end
				end
				local function words(button: Instance?, name: string): TextLabel?
					return if button then button:FindFirstChild(name, true) :: TextLabel? else nil
				end
				local function whole(label: TextLabel?): boolean
					return label ~= nil and label.TextFits and label.TextBounds.X <= label.AbsoluteSize.X + 0.5
				end
				local run = begin("Normal")
				t.Check("a run starts", run.Ok == true, tostring(run.Error))
				if run.Ok ~= true then
					restore()
					return
				end
				t.Server("FightHealth", 0)
				t.Check("the lead's fall: its card", waitFor(t, StagesConfig.Results.After + REPLICATE, function(): boolean
					return Screen.Current() == StageScreen.Name and StageScreen.Parts().Another ~= nil
				end))
				local parts = StageScreen.Parts()
				local retry, another = parts.Retry :: TextButton?, parts.Another :: TextButton?
				t.Check("Retry, Send another and Home, no Hard", retry ~= nil and another ~= nil and parts.Home ~= nil and parts.Next == nil)
				local said = words(another, "Words")
				t.Check("\"Send another\" whole on its press", said ~= nil and said.Text == "Send another" and whole(said), if said then `{said.TextBounds.X} in {said.AbsoluteSize.X}` else "none")
				t.Check("the fallen lead heals at home", waitFor(t, 4, function(): boolean
					local lead = HudController.Lead()
					return lead ~= nil and lead:GetAttribute("State") == "Home"
				end))
				local landing = t.Server("TestStream", "DoorLanding", { Ground = GROUND })
				local lead = HudController.Lead()
				local aside = if typeof(landing) == "Vector3" and lead then ((lead:GetPivot().Position - landing) * Vector3.new(1, 0, 1)).Magnitude else nil
				t.Near("beside the Arrival pad, by LeadAside (studs from the landing)", aside or -1, WorldConfig.Row.LeadAside, 1)
				local dim = words(retry, "DimWords")
				t.Check("Retry dim with the time its lead heals in", retry ~= nil and retry:GetAttribute("Led") == false and dim ~= nil and string.match(dim.Text, "^Retry  %d+:%d%d$") ~= nil, if dim then dim.Text else "none")
				local toasts = #Toast.Shown()
				t.Check("a tap on it is taken", retry ~= nil and Button.Press(retry))
				t.Wait(REPLICATE)
				t.Check("and does nothing: no run, no refusal, the card stays", player:GetAttribute("StageRun") == nil and #Toast.Shown() == toasts and Screen.Current() == StageScreen.Name, table.concat(Toast.Shown(), " | "))
				t.Check("Send another opens the picker", another ~= nil and Button.Press(another) and waitFor(t, 2, function(): boolean
					return Screen.Current() == VoidkinScreen.Name
				end), tostring(Screen.Current()))
				Screen.Close("Back")
				t.Check("closing it brings the card back", waitFor(t, 2, function(): boolean
					return Screen.Current() == StageScreen.Name and StageScreen.Parts().Another ~= nil
				end), tostring(Screen.Current()))
				t.Wait(1)
				retry = StageScreen.Parts().Retry :: TextButton?
				t.Check("Retry still dim", retry ~= nil and retry:GetAttribute("Led") == false)
				-- whole at home in the Festival, it's up on its own (FightService's playerHome)
				t.Server("FightHealth", 1)
				t.Check("its lead up, Retry lights by itself", waitFor(t, REPLICATE + HudConfig.Stages.Card.Fall.Lit + 1, function(): boolean
					return retry ~= nil and retry:GetAttribute("Led") == true
				end))
				local up = HudController.Lead()
				t.Check("the lead rose on its own", up ~= nil and up:GetAttribute("State") ~= "Home" and up:GetAttribute("State") ~= "Down", tostring(up and up:GetAttribute("State")))
				t.Wait(HudConfig.Stages.Card.Fall.Lit + 0.1)
				local lit = if retry then retry:FindFirstChild("Lit", true) :: CanvasGroup? else nil
				t.Check("its lit face shows", lit ~= nil and lit.GroupTransparency < 0.01)
				t.Check("Retry lit starts the run", retry ~= nil and Button.Press(retry) and waitFor(t, REPLICATE, function(): boolean
					return type(player:GetAttribute("StageRun")) == "string"
				end))
				-- the smallest phone: "Send another" still whole
				Helpers.endRun(t)
				local stub = function(): { [string]: any }
					return { Ok = false }
				end
				Layers.Force(Theme.Scale.Floor)
				Layers.Box(Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height))
				local ok, problem = pcall(StageScreen.Results, { Ground = GROUND, Difficulty = "Normal", Stage = 2, Count = #(Stages.Of(GROUND) :: { any }), Won = false, Checkpoint = 2, Lead = "Kirra" },
					{ Begin = stub, Home = stub, Say = function(_: string, _refused: boolean?) end, Lead = function(): (boolean, number?)
						return false, workspace:GetServerTimeNow() + 75
					end, Another = function() end })
				t.Wait(1.2)
				local small = words(StageScreen.Parts().Another, "Words")
				t.Check("at the smallest phone, \"Send another\" whole", ok and whole(small), if small then `{small.TextBounds.X} in {small.AbsoluteSize.X}` else tostring(problem))
				local clock = words(StageScreen.Parts().Retry, "DimWords")
				t.Check("and Retry's time whole", clock ~= nil and whole(clock), if clock then clock.Text else "none")
				Layers.Box(nil)
				Layers.Force(nil)
				restore()
			end,
		},
		{
			Name = "Stages (TR50): the gates, a Normal run moving on from its first stretch, leaving, the Arc panel at the checkpoint, the keeper's card opening Hard, Hard's own foes moving on, the keeper lifted, a fall at stretch 3",
			Place = "Festival", -- TR45: its world stands in that place only
			Run = function(t: any)
				-- A card a case before left open (a keeper's try lost is the keeper's stretch's run: its card) would read as
				-- this run's.
				if Screen.Current() ~= nil then
					Screen.Close()
					t.Wait(0.3)
				end
				local before = t.Server("Stage")
				local held = before.Checkpoint or { Normal = 1, Hard = 1 }
				local was = {
					Normal = { before.Normal and before.Normal.Cleared or 0, held.Normal },
					Hard = { before.Hard and before.Hard.Cleared or 0, held.Hard },
				}
				local count = #(Stages.Of(GROUND) :: { any })
				local function restore()
					Helpers.endRun(t)
					t.Server("StageLine", "Hard", 0)
					t.Server("StageLine", "Normal", was.Normal[1], was.Normal[2])
					t.Server("StageLine", "Hard", was.Hard[1], was.Hard[2])
					t.Server("KeeperRest", 0)
					t.Server("LeadHeal")
					for _, name in { "Pack 1", Helpers.SQUARE.Name, "Elite 1" } do
						t.Server("PackBack", name)
					end
					if Screen.Current() == StageScreen.Name then
						Screen.Close()
					end
				end
				local function cardTitle(): string?
					local title = StageScreen.Parts().Title :: TextLabel?
					return if Screen.Current() == StageScreen.Name and title then title.Text else nil
				end
				local named = (require(Shared.Definitions.Grounds) :: any).ById[GROUND].Name
				-- the fall's title names the lead, as a list shows it (research's lines, TR54)
				local function leadFell(): string
					local view = ProfileController.Get() :: any
					local owned = if view then view.Voidkin[view.Roles.Lead] else nil
					return if owned then `{Collection.Name(owned)} fell` else "Your lead fell"
				end
				t.Server("LeadHeal")
				t.Server("StageLine", "Hard", 0)
				t.Server("StageLine", "Normal", 0)
				local shut = t.Server("Stage")
				t.Equal("a record of nothing: every gate shut to the player", table.concat(shut.Shut, ","), "1,2,3")
				-- The gates on the client, and a walk across the first.
				local served = t.Server("TestStream", "StageGate", { Stage = 1 })
				local gate = if typeof(served) == "Vector3" then served else nil
				t.Check("stretch 1's gate laid", gate ~= nil)
				if gate == nil then
					restore()
					return
				end
				t.Check("it shows shut to the player", waitFor(t, REPLICATE, function(): boolean
					return StageController.Gate(1) == true
				end))
				local shown = Markers.Find("StageGate", { Stage = 1 })
				local floorY = if shown and shown:IsA("BasePart") then shown.Position.Y - shown.Size.Y / 2 else gate.Y
				local from = Vector3.new(gate.X, floorY + R6_ROOT_HEIGHT, gate.Z + 10)
				t.Server("TestStandAt", from, from + Vector3.new(0, 0, -10))
				t.Wait(0.4)
				local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid:MoveTo(Vector3.new(gate.X, floorY, gate.Z - 14))
				end
				t.Check("a walk across it shut is set back before it", waitFor(t, 4, function(): boolean
					return table.find(Toast.Shown(), "Clear Stretch 1 to go on") ~= nil
				end), table.concat(Toast.Shown(), " | "))
				t.Wait(0.3)
				local r = root()
				t.Check("standing on the near side", r ~= nil and r.Position.Z > gate.Z, if r then `{r.Position.Z - gate.Z} past` else nil)
				if humanoid and r then
					humanoid:MoveTo(r.Position)
				end
				-- Hard refused while shut; Normal begun at its first stretch.
				t.Equal("Hard refused, waiting for the keeper", begin("Hard").Needs, Stages.Keeper)
				local first = begin("Normal")
				t.Check("Normal begins at the first stretch", first.Ok == true and first.Stage == 1, `{first.Error} {first.Stage}`)
				t.Check("its run on the player", waitFor(t, REPLICATE, function(): boolean
					return player:GetAttribute("StageRun") == "Normal 1"
				end))
				local row = (Stages.Of(GROUND) :: any)[1]
				t.Equal("its quota, Config.Stages'", player:GetAttribute("StageQuota"), row.Quota)
				local said = ""
				t.Check("its line at the top of the screen", waitFor(t, REPLICATE, function(): boolean
					local up, words = StageController.Said()
					said = words
					return up and string.find(words, `Stretch 1 of {count}`, 1, true) ~= nil and string.find(words, `0 / {row.Quota}`, 1, true) ~= nil
				end), said)
				-- The quota through Pack 1's falls, the pack stood again between.
				local fallen = 0
				for _ = 1, 4 do
					if fallen >= row.Quota then
						break
					end
					t.Server("PackBack", "Pack 1")
					local felled = t.Server("StageFell", "Pack 1")
					fallen += felled.Felled or 0
				end
				t.Check("its Shades counted, up to the quota", waitFor(t, REPLICATE, function(): boolean
					return player:GetAttribute("StageKills") == math.min(fallen, row.Quota)
				end), `{player:GetAttribute("StageKills")} of {fallen} felled`)
				t.Check("not done before its elite", player:GetAttribute("StageRun") == "Normal 1" and player:GetAttribute("StageLast") ~= true)
				t.Server("PackBack", "Elite 1")
				local elite = t.Server("StageFell", "Elite 1")
				t.Check("its elite falls", elite.Ok == true, tostring(elite.Error))
				-- The stretch's clear: written once, the run moving on, no card between stretches.
				t.Check("written once: stretch 1 cleared on Normal, the checkpoint at stretch 2", waitFor(t, REPLICATE, function(): boolean
					return line("Normal").Cleared == 1 and line("Normal").Reached == 2
				end), `{line("Normal").Cleared} {line("Normal").Reached}`)
				t.Check("the run moves on to stretch 2, Results.After later", waitFor(t, StagesConfig.Results.After + REPLICATE, function(): boolean
					return player:GetAttribute("StageRun") == "Normal 2" and player:GetAttribute("StageKills") == 0
				end), tostring(player:GetAttribute("StageRun")))
				t.Check("no card between stretches", Screen.Current() == nil, tostring(Screen.Current()))
				t.Check("its line says stretch 2", waitFor(t, REPLICATE, function(): boolean
					local up, words = StageController.Said()
					said = words
					return up and string.find(words, `Stretch 2 of {count}`, 1, true) ~= nil
				end), said)
				t.Check("stretch 1's gate opens to the player, behind the run", waitFor(t, 1, function(): boolean
					return StageController.Gate(1) == false
				end))
				-- Off the street ends the run; its checkpoint stays.
				local first1 = t.Server("TestStream", "StageStart", { Stage = 1 })
				local off = (if typeof(first1) == "Vector3" then first1 else gate) + Vector3.new(0, R6_ROOT_HEIGHT, StagesConfig.Off + 20)
				t.Server("TestStandAt", off, off + Vector3.new(0, 0, 1))
				t.Check("off the street, the run ends", waitFor(t, 1.5, function(): boolean
					return player:GetAttribute("StageRun") == nil
				end))
				t.Equal("its checkpoint stays at stretch 2", line("Normal").Reached, 2)
				-- The Arc panel through the Door: Normal at its checkpoint, Hard shut and why.
				t.Server("StageArrive")
				t.Check("through the Door, not fresh: the Arc panel", waitFor(t, REPLICATE, function(): boolean
					return Screen.Current() == StageScreen.Name and StageScreen.Parts().Normal ~= nil
				end))
				local pick = StageScreen.Parts()
				local normalSays, hardSays = pick.NormalSays :: TextLabel?, pick.HardSays :: TextLabel?
				t.Equal("Normal: the next run starts at stretch 2", if normalSays then normalSays.Text else nil, `Stretch 2 of {count}`)
				t.Equal("its checkpoint, the save's", if pick.Normal then (pick.Normal :: Instance):GetAttribute("Checkpoint") else nil, 2)
				local way = pick.NormalPress :: TextLabel?
				t.Equal("its lit press says Continue", if way then way.Text else nil, "Continue")
				t.Equal("Hard shut", if pick.Hard then Button.State(pick.Hard :: TextButton) else nil, "Disabled")
				t.Check("and why", hardSays ~= nil and string.find(hardSays.Text, "on Normal", 1, true) ~= nil, if hardSays then hardSays.Text else nil)
				for _, which in Stages.Difficulties do
					local cp = pick[`{which}Power`] :: TextLabel?
					t.Check(`{which}'s recommended Combat Power`, cp ~= nil and string.find(cp.Text, Sheet.Said.Power, 1, true) ~= nil, if cp then cp.Text else nil)
				end
				Helpers.lintClean(t, "the Arc panel")
				t.Check("Normal's press begins the run at its checkpoint", pick.Normal ~= nil and Button.Press(pick.Normal :: TextButton) and waitFor(t, REPLICATE, function(): boolean
					return player:GetAttribute("StageRun") == "Normal 2"
				end), tostring(player:GetAttribute("StageRun")))
				t.Check("the panel closes", waitFor(t, 1, function(): boolean
					return Screen.Current() == nil
				end))
				-- The keeper's fall on Normal: the run's card, Hard opened, its press into Hard.
				t.Server("StageLine", "Normal", count - 1, count)
				t.Server("KeeperRest", 0)
				local keeperRun = begin("Normal")
				t.Check("a run at the keeper's stretch, the checkpoint", keeperRun.Ok == true and keeperRun.Stage == count, `{keeperRun.Error} {keeperRun.Stage}`)
				t.Wait(MOVE)
				local try = t.Server("KeeperTry")
				t.Check("a try", try.Ok == true, tostring(try.Error))
				t.Wait(MOVE)
				t.Server("KeeperEnd", "Win")
				t.Check("the keeper's fall: the run's card, once the try's fade is back", waitFor(t, Stages.After(GROUND, count) + REPLICATE + 2, function(): boolean
					return cardTitle() == `{named} cleared`
				end), tostring(cardTitle()))
				local done = StageScreen.Parts()
				-- Hard's opening said by its press (research's lines, TR54): shut under Hard's lock, then lit as it lifts
				t.Check("no banner: the card's words don't say Hard opened", done.Opened == nil)
				local hardPress = done.Next :: TextButton?
				t.Equal("its Hard press comes in shut", if hardPress then hardPress:GetAttribute("Shut") else nil, true)
				t.Check("under Hard's lock", hardPress ~= nil and (hardPress:FindFirstChild("Lock", true) :: ImageLabel?) ~= nil)
				local U = HudConfig.Stages.Card.Unlock
				local beats = HudConfig.Stages.Motion.RunAt + HudConfig.Stages.Motion.RunSeconds
				t.Check("and the lock lifts as it lights, past the card's beats", hardPress ~= nil and waitFor(t, beats + U.After + U.Seconds + 1, function(): boolean
					return hardPress:GetAttribute("Shut") == false
				end), if hardPress then tostring(hardPress:GetAttribute("Shut")) else "no press")
				t.Wait(U.Seconds + 0.1)
				local lock = if hardPress then hardPress:FindFirstChild("Lock", true) :: ImageLabel? else nil
				t.Check("the lock gone, the press lit", lock ~= nil and lock.ImageTransparency > 0.95 and ((hardPress :: TextButton):FindFirstChild("Lit", true) :: CanvasGroup).GroupTransparency < 0.05, if lock then string.format("%.2f", lock.ImageTransparency) else "no lock")
				t.Check("Retry, Hard and Home", done.Retry ~= nil and done.Next ~= nil and done.Home ~= nil)
				t.Check("the keeper's stretch written, the checkpoint cleared", waitFor(t, REPLICATE, function(): boolean
					return line("Normal").Cleared == count and line("Normal").Reached == nil
				end), `{line("Normal").Cleared} {line("Normal").Reached}`)
				Helpers.lintClean(t, "the run's card")
				t.Wait(MOVE + 2) -- the win's pause and fade out of the copy
				-- Hard: its own foes, the lead solo, the run moving on to the next stretch's.
				t.Check("its Hard press begins Hard at its first stretch", done.Next ~= nil and Button.Press(done.Next :: TextButton) and waitFor(t, REPLICATE, function(): boolean
					return player:GetAttribute("StageRun") == "Hard 1"
				end), tostring(player:GetAttribute("StageRun")))
				local packs, eliteLevel = 0, 0
				for _, stop in row.Stops do
					packs += if stop.Kind == "Pack" then stop.Count or 1 else 0
					eliteLevel = if stop.Kind == "Elite" then stop.Level else eliteLevel
				end
				t.Check("its own foes stand, each stop's", waitFor(t, REPLICATE, function(): boolean
					return #mine(1) == packs + 1
				end), `{#mine(1)} of {packs + 1}`)
				local lifted = false
				for _, model in mine(1) do
					lifted = lifted or model:GetAttribute("Level") == Stages.Level(eliteLevel, "Hard")
				end
				t.Check("ten levels up", lifted)
				t.Check("the lead fights alone", t.Server("Stage").Alone == true)
				local hardElite = t.Server("StageFell", "Elite 1 mine")
				t.Check("its elite first", hardElite.Ok == true and waitFor(t, REPLICATE, function(): boolean
					return player:GetAttribute("StageLast") == true
				end), tostring(hardElite.Error))
				t.Check("not done before the quota", player:GetAttribute("StageRun") == "Hard 1")
				local hardFallen = 0
				for _ = 1, 4 do
					local some = t.Server("StageFell", "Pack 1 mine")
					hardFallen += some.Felled or 0
					if player:GetAttribute("StageRun") ~= "Hard 1" or hardFallen >= row.Quota then
						break
					end
					-- its own pack stands again Row.Respawn after its last falls, while the stretch lasts (the fallen, still
					-- fading, aren't counted)
					t.Wait(0.5)
					waitFor(t, WorldConfig.Row.Respawn + 2, function(): boolean
						return #mine(1, true) >= packs
					end)
				end
				t.Check("its quota after the elite: the run moves on to stretch 2", waitFor(t, StagesConfig.Results.After + REPLICATE, function(): boolean
					return player:GetAttribute("StageRun") == "Hard 2"
				end), `{hardFallen} felled, {player:GetAttribute("StageRun")}`)
				t.Check("stretch 1's own foes gone, stretch 2's standing", waitFor(t, REPLICATE, function(): boolean
					return #mine(1) == 0 and #mine(2) > 0
				end), `{#mine(1)} and {#mine(2)}`)
				t.Check("no card between stretches", Screen.Current() == nil, tostring(Screen.Current()))
				-- The keeper on Hard: lifted ten, its card with nothing after.
				t.Server("StageLine", "Hard", count - 1, count)
				t.Server("KeeperRest", 0)
				local hardKeeper = begin("Hard")
				t.Check("Hard's keeper stretch begins, its checkpoint", hardKeeper.Ok == true and hardKeeper.Stage == count, `{hardKeeper.Error} {hardKeeper.Stage}`)
				t.Wait(MOVE)
				local hardTry = t.Server("KeeperTry")
				t.Check("a try", hardTry.Ok == true, tostring(hardTry.Error))
				local keeperDef = (Stages.Last(GROUND, count) :: any)
				t.Check("the keeper ten levels up", waitFor(t, MOVE + 1, function(): boolean
					return (t.Server("Keeper").KeeperLevel or 0) == Stages.Level(keeperDef.Level, "Hard")
				end), `{t.Server("Keeper").KeeperLevel}`)
				t.Server("KeeperEnd", "Win")
				t.Check("its fall clears Hard's keeper stretch, the checkpoint cleared", waitFor(t, StagesConfig.Results.After + REPLICATE + 2, function(): boolean
					return line("Hard").Cleared == count and line("Hard").Reached == nil
				end), `{line("Hard").Cleared} {line("Hard").Reached}`)
				t.Check("its card, once the fade is back: Retry and Home, nothing after", waitFor(t, Stages.After(GROUND, count) + REPLICATE, function(): boolean
					return cardTitle() == `{named} cleared`
				end) and StageScreen.Parts().Next == nil and StageScreen.Parts().Home ~= nil)
				t.Wait(MOVE + 2)
				-- A fall at stretch 3: its card, and the next run starts there.
				if Screen.Current() then
					Screen.Close()
					t.Wait(0.4)
				end
				t.Server("StageLine", "Normal", 2, 3)
				t.Server("LeadHeal")
				local third = begin("Normal")
				t.Check("a run from the checkpoint at stretch 3", third.Ok == true and third.Stage == 3, `{third.Error} {third.Stage}`)
				t.Server("FightHealth", 0)
				t.Check("the lead's fall: its card says so", waitFor(t, REPLICATE, function(): boolean
					return cardTitle() == leadFell()
				end), tostring(cardTitle()))
				local fell = StageScreen.Parts()
				local time = fell.Time
				local where = if time then time:FindFirstChild("Said") :: TextLabel? else nil
				t.Equal("and where the next run starts", if where then where.Text else nil, "Next run starts at Stretch 3")
				t.Check("Retry and Home, no Hard", fell.Retry ~= nil and fell.Home ~= nil and fell.Next == nil)
				t.Equal("the checkpoint stays at stretch 3", line("Normal").Reached, 3)
				Helpers.lintClean(t, "the fall's card")
				restore()
			end,
		},
		{
			Name = "Stages (TR43): a fresh account through the Festival Door is in the run's first stretch on Normal with no screen (wipes the save)",
			Place = "Festival", -- TR45: its world stands in that place only
			Manual = true,
			Run = function(t: any)
				t.Server("DataWipe")
				t.Wait(REPLICATE)
				t.Check("fresh", t.Server("Stage").Fresh == true)
				t.Server("StageArrive")
				t.Check("the first stretch on Normal at once", waitFor(t, REPLICATE, function(): boolean
					return player:GetAttribute("StageRun") == "Normal 1"
				end))
				t.Check("no screen", Screen.Current() == nil)
			end,
		},
		{
			Name = "HUD: TR50's dusk, the Arc panel on the festival's dusk street with Seam's glass, and the run's card over the street in dark wine",
			Place = "Main",
			Run = function(t: any)
				if Screen.Current() ~= nil then
					Screen.Close()
					t.Wait(0.5)
				end
				local ARC, BED, CARD = HudConfig.Stages.Arc, HudConfig.Stages.Bed, HudConfig.Stages.Card
				local function hex(colour: Color3?): string
					return if colour then colour:ToHex() else "none"
				end
				local tile = HudController.Parts().Map :: TextButton
				t.Check("the dock's Play opens the Arc panel (by the Play panel's Choose Arc)", Helpers.openArc(t, tile, 2, function(): boolean
					return Screen.Current() == StageScreen.Name and StageScreen.Parts().Arc ~= nil
				end), tostring(Screen.Current()))
				t.Wait(1) -- its rise
				local pick = StageScreen.Parts()
				local body = pick.Body :: Frame?
				local ground = if body then body:FindFirstChild("Ground") else nil
				local ramp = if ground then ground:FindFirstChildOfClass("UIGradient") else nil
				local keys = if ramp then ramp.Color.Keypoints else nil
				t.Check("the ground behind the glass in the street's rose", keys ~= nil and hex(keys[1].Value) == hex(ARC.Backing[1]) and hex(keys[#keys].Value) == hex(ARC.Backing[2]),
					if keys then `{hex(keys[1].Value)} to {hex(keys[#keys].Value)}` else "no ramp")
				local panel = pick.Arc :: Frame?
				local group = if panel then panel.Parent :: GuiObject? else nil
				local bed = if panel then panel:FindFirstChild("Bed") :: Frame? else nil
				local bloom = pick.GroundBloom :: ImageLabel?
				t.Check("the street's light behind the bed, on the ground under the tile", bloom ~= nil and group ~= nil and bloom.Parent == group.Parent and bloom.ZIndex < group.ZIndex
					and hex(bloom.ImageColor3) == hex(ARC.Bloom.Colour) and math.abs(bloom.ImageTransparency - (1 - ARC.Bloom.Alpha)) < 1e-3)
				if bloom and bed then
					local away = (bed.AbsolutePosition + bed.AbsoluteSize / 2) - (bloom.AbsolutePosition + bloom.AbsoluteSize / 2)
					t.Check("its middle the bed's", away.Magnitude <= 1.5, `{string.format("%.1f", away.Magnitude)} px away`)
				end
				local glow = if panel then panel:FindFirstChild("Glow") :: ImageLabel? else nil
				local edge = if panel then panel:FindFirstChild("Edge") :: ImageLabel? else nil
				t.Check("the light round the panel in lantern light, its rim in ivory", glow ~= nil and edge ~= nil and hex(glow.ImageColor3) == hex(ARC.Glow) and hex(edge.ImageColor3) == hex(ARC.Rim),
					`{hex(glow and glow.ImageColor3)}, {hex(edge and edge.ImageColor3)}`)
				local bedLight = if bed then bed:FindFirstChild("Bloom") :: ImageLabel? else nil
				local bedEdge = if panel then panel:FindFirstChild("BedEdge") :: ImageLabel? else nil
				t.Check("the bed's light pooled low in amber, its hairline in rosewood", bedLight ~= nil and bedEdge ~= nil and hex(bedLight.ImageColor3) == hex(BED.Bloom.Colour)
					and math.abs(bedLight.ImageTransparency - (1 - BED.Bloom.Alpha)) < 1e-3 and hex(bedEdge.ImageColor3) == hex(BED.Edge))
				local band = Screen.Band(StageScreen.Name)
				local back = if band and band.Parent then band.Parent:FindFirstChild("Back") else nil
				local under = if back then back:FindFirstChild("Under", true) :: ImageLabel? else nil
				t.Check("Back's underline in ivory", under ~= nil and hex(under.ImageColor3) == hex(ARC.Rim), hex(under and under.ImageColor3))
				-- The run's card: over the street dimmed in dark wine, its Back in the kit's light again.
				local on = {
					Begin = function(): { [string]: any }
						return { Ok = false }
					end,
					Home = function(): { [string]: any }
						return { Ok = false }
					end,
					Say = function(_: string, _refused: boolean?) end,
					Lead = function(): (boolean, number?)
						return true, nil
					end,
					Another = function() end,
				}
				local count = #((Stages.Of(GROUND) or {}) :: { any })
				local ok, problem = pcall(StageScreen.Results, { Ground = GROUND, Difficulty = "Normal", Stage = 2, Count = count, Won = false, Then = 2, Checkpoint = 2, From = 1, Seconds = 40, Credits = 0 }, on)
				t.Check("the run's card opens", ok and Screen.Current() == StageScreen.Name, tostring(problem))
				t.Wait(1)
				local cover = Screen.Cover(StageScreen.Name)
				t.Check("its cover in dark wine, at Card.Dim", cover ~= nil and hex(cover.BackgroundColor3) == hex(CARD.Cover) and math.abs(cover.BackgroundTransparency - CARD.Dim) < 0.02,
					if cover then `{hex(cover.BackgroundColor3)} at {string.format("%.2f", cover.BackgroundTransparency)}` else "none")
				local cardBand = Screen.Band(StageScreen.Name)
				local cardBack = if cardBand and cardBand.Parent then cardBand.Parent:FindFirstChild("Back") else nil
				local cardUnder = if cardBack then cardBack:FindFirstChild("Under", true) :: ImageLabel? else nil
				t.Check("the card's Back in the kit's light, not the panel's ivory (the card reopens the panel's screen)", cardUnder ~= nil and hex(cardUnder.ImageColor3) ~= hex(ARC.Rim), hex(cardUnder and cardUnder.ImageColor3))
				-- The panel opened over the card (the server's StagePick) reopens the same screen, which keeps its cover and its
				-- Back: the panel puts its own back.
				StageScreen.Pick(GROUND, ProfileController.Get() :: Profile.View, on)
				t.Wait(1)
				local again = Screen.Cover(StageScreen.Name)
				t.Check("the panel over the card: its cover the glass's own again", again ~= nil and hex(again.BackgroundColor3) == hex(UIKit.Palettes.SeamGlass.Backing), hex(again and again.BackgroundColor3))
				local bandAgain = Screen.Band(StageScreen.Name)
				local backAgain = if bandAgain and bandAgain.Parent then bandAgain.Parent:FindFirstChild("Back") else nil
				local underAgain = if backAgain then backAgain:FindFirstChild("Under", true) :: ImageLabel? else nil
				t.Check("and Back's underline in ivory again", underAgain ~= nil and hex(underAgain.ImageColor3) == hex(ARC.Rim), hex(underAgain and underAgain.ImageColor3))
				Screen.Close()
				t.Wait(0.6)
				t.Check("closed", Screen.Current() == nil)
			end,
		},
		{
			Name = "Take: TR50, the dock's Play to the Arc panel at the save's checkpoint and at stretch 3, the run's card, then a stretch's line, at the smallest phone, each held for a still, for research",
			Place = "Main",
			Manual = true,
			Stay = true,
			Run = function(t: any)
				-- Each state is held until the driver moves ReplicatedStorage.NL_TakeStep on ("Panel", "Stretch3", "Card",
				-- "Line", "End") and captures it. The panel opens from the dock's Play as a player taps it; stretch 3 is the record set
				-- to Normal's stretch 2 cleared, its checkpoint at 3; the line is the run's attributes set on this client alone
				-- (the line reads them), the same line a run in the Festival shows. The record is put back after.
				local step = Instance.new("StringValue")
				step.Name = "NL_TakeStep"
				step.Value = "Ready"
				step.Parent = ReplicatedStorage
				local function await(name: string): boolean
					return waitFor(t, 300, function(): boolean
						return step.Value == name or step.Value == "End"
					end) and step.Value == name
				end
				local before = t.Server("Stage")
				local held = before.Checkpoint or { Normal = 1, Hard = 1 }
				local was = { before.Normal and before.Normal.Cleared or 0, held.Normal }
				local count = #(Stages.Of(GROUND) :: { any })
				local tile = HudController.Parts().Map :: TextButton
				local function open()
					if Screen.Current() ~= nil then
						Screen.Close()
						t.Wait(0.5)
					end
					t.Check("the dock's Play opens the Arc panel (by the Play panel's Choose Arc)", Helpers.openArc(t, tile, 2, function(): boolean
						return Screen.Current() == StageScreen.Name and StageScreen.Parts().Normal ~= nil
					end), tostring(Screen.Current()))
					t.Wait(1) -- its rise and the plays' ease
				end
				Layers.Force(Theme.Scale.Floor)
				Layers.Box(Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height))
				local ok, problem = pcall(function()
					if await("Panel") then
						open()
						local pick = StageScreen.Parts()
						local way = pick.NormalPress :: TextLabel?
						t.Equal("Normal's lit press", if way then way.Text else nil, if was[2] > 1 then "Continue" else "Fight")
						local hardPress = pick.Hard :: Instance?
						local lock = if hardPress then hardPress:FindFirstChild("Lock", true) else nil
						t.Check("Hard shut wears the closed lock", lock ~= nil and lock:IsA("ImageLabel") and lock.Image == HudConfig.Voidkin.Chrome.Images.LockOn.Id)
						local normalPress = pick.Normal :: Instance?
						local marks = if normalPress then normalPress:FindFirstChild("MarksRoad", true) else nil
						local first = if normalPress then normalPress:FindFirstChild("Mark1Fill", true) else nil
						t.Check("the track starts under node 1, no stub before it", marks ~= nil and first ~= nil and (marks :: GuiObject).AbsolutePosition.X > (first :: GuiObject).AbsolutePosition.X)
					end
					if await("Stretch3") then
						t.Server("StageLine", "Normal", math.max(was[1], 2), 3)
						t.Wait(REPLICATE)
						open()
						local pick = StageScreen.Parts()
						local says = pick.NormalSays :: TextLabel?
						t.Equal("Normal's checkpoint reads stretch 3", if says then says.Text else nil, `Stretch 3 of {count}`)
						local way = pick.NormalPress :: TextLabel?
						t.Equal("its lit press says Continue", if way then way.Text else nil, "Continue")
						local face = pick.Normal :: Instance?
						t.Check("cleared nodes wear their tick, not their number", face ~= nil and face:FindFirstChild("Check1", true) ~= nil and face:FindFirstChild("Mark1Number", true) == nil and face:FindFirstChild("Mark3Number", true) ~= nil)
					end
					if await("Card") then
						-- The run's card over the world, stretch 3 cleared on Normal (its cover in TR50's dusk).
						Screen.Close()
						t.Wait(0.5)
						local stub = function(): { [string]: any }
							return { Ok = false }
						end
						StageScreen.Results({ Ground = GROUND, Difficulty = "Normal", Stage = 3, Count = count, Won = true, Seconds = 185, Best = 185, Checkpoint = 4, Credits = 240, Shards = 2, Chests = 1 },
							{ Begin = stub, Home = stub, Say = function(_: string, _refused: boolean?) end, Lead = function(): (boolean, number?)
								return true, nil
							end, Another = function() end })
						t.Check("the run's card", Screen.Current() == StageScreen.Name)
						t.Wait(1)
					end
					if await("Line") then
						Screen.Close()
						t.Wait(0.5)
						local row = (Stages.Of(GROUND) :: any)[2]
						player:SetAttribute("StageQuota", row.Quota)
						player:SetAttribute("StageKills", math.floor(row.Quota / 2))
						player:SetAttribute("StageRun", "Normal 2")
						local said = ""
						t.Check("the stretch's line", waitFor(t, 2, function(): boolean
							local up, words = StageController.Said()
							said = words
							return up and string.find(words, `Stretch 2 of {count}`, 1, true) ~= nil
						end), said)
						t.Check("its last foe by name", string.find(said, "then the elite", 1, true) ~= nil, said)
						local shown = Players.LocalPlayer.PlayerGui:FindFirstChild("StageRun", true)
						t.Check("its badge the difficulty's chevron, no second number", shown ~= nil and shown:FindFirstChild("MarkChevrons") ~= nil and shown:FindFirstChild("MarkNumber") == nil)
					end
					await("End")
				end)
				player:SetAttribute("StageRun", nil)
				player:SetAttribute("StageKills", nil)
				player:SetAttribute("StageQuota", nil)
				t.Server("StageLine", "Normal", was[1], was[2])
				if Screen.Current() ~= nil then
					Screen.Close()
				end
				Layers.Box(nil)
				Layers.Force(nil)
				step:Destroy()
				if not ok then
					error(problem, 0)
				end
			end,
		},
	}
end

return StageCases
