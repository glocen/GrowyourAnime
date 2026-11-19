--!strict
-- A ground's stages (TR43), apart: Cases is at the type checker's limit. One case walks a run through the server's own
-- paths (StageService), the falls through the fight's (StageFell fells a group with the player as its hitter):
-- the gates shut and the set-back at one; a stage that's shut refused; Stage 1 on Normal counted to its quota and its
-- elite, written once, its card with what opened and Next; Next set down at Stage 2's start; the street left ending a
-- run; Hard's own foes for this player alone, ten levels up, the lead solo, the elite before the quota and the run done
-- after; the keeper lifted on Hard; the picker's locks; and the lead's fall's card. The player's record is put back at
-- its end. A fresh account through the Door is its own case, Manual: it wipes the save.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local WorldConfig = require(Shared.Config.World)
local StagesConfig = require(Shared.Config.Stages)
local Markers = require(Shared.World.Markers)
local Stages = require(Shared.Rules.Stages)
local Parts = require(Shared.Util.Parts)
local Profile = require(Shared.Data.Profile)
local ProfileController = require(script.Parent.Parent.ProfileController)
local StageController = require(script.Parent.Parent.Parent.Main.StageController)
local Helpers = require(script.Parent.Helpers)
local UI = script.Parent.Parent.Parent.Parent.UI
local Screen = require(UI.Kit.Screen)
local Button = require(UI.Kit.Button)
local Toast = require(UI.Kit.Toast)
local StageScreen = require(UI.StageScreen)

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

local function begin(difficulty: string, stage: number): { [string]: any }
	local ok, answer = pcall(Net.Client.Invoke, "Stage", GROUND, difficulty, stage)
	return if ok and type(answer) == "table" then answer else { Ok = false, Error = tostring(answer) }
end

local function line(difficulty: string): Profile.StageLine
	local view = ProfileController.Get()
	return if view then Stages.Line(view, GROUND, difficulty) else { Cleared = -1, Best = {} }
end

function StageCases.Cases(): { any }
	return {
		{
			Name = "Stages (TR43): the gates, a Normal run to its card, Next, leaving, Hard's own foes, the keeper lifted, the picker's locks, a lost run",
			Place = "Festival", -- TR45: its world stands in that place only
			Run = function(t: any)
				-- A card a case before left open (a keeper's try lost is Stage 4's run: its card) would read as this run's.
				if Screen.Current() ~= nil then
					Screen.Close()
					t.Wait(0.3)
				end
				local before = t.Server("Stage")
				local was = { Normal = before.Normal and before.Normal.Cleared or 0, Hard = before.Hard and before.Hard.Cleared or 0 }
				local count = #(Stages.Of(GROUND) :: { any })
				local function restore()
					t.Server("StageBegin", "Normal", 1) -- ends any run (refused when shut, which ends nothing: then the walk off does)
					t.Server("StageLine", "Hard", 0)
					t.Server("StageLine", "Normal", was.Normal)
					t.Server("StageLine", "Hard", was.Hard)
					t.Server("KeeperRest", 0)
					t.Server("LeadHeal")
					for _, name in { "Pack 1", Helpers.SQUARE.Name, "Elite 1" } do
						t.Server("PackBack", name)
					end
					if Screen.Current() == StageScreen.Name then
						Screen.Close()
					end
				end
				t.Server("LeadHeal")
				t.Server("StageLine", "Hard", 0)
				t.Server("StageLine", "Normal", 0)
				local shut = t.Server("Stage")
				t.Equal("a record of nothing: every gate shut to the player", table.concat(shut.Shut, ","), "1,2,3")
				-- The gates on the client, and a walk across the first.
				local served = t.Server("TestStream", "StageGate", { Stage = 1 })
				local gate = if typeof(served) == "Vector3" then served else nil
				t.Check("Stage 1's gate laid", gate ~= nil)
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
					return table.find(Toast.Shown(), "Clear Stage 1 to go on") ~= nil
				end), table.concat(Toast.Shown(), " | "))
				t.Wait(0.3)
				local r = root()
				t.Check("standing on the near side", r ~= nil and r.Position.Z > gate.Z, if r then `{r.Position.Z - gate.Z} past` else nil)
				if humanoid and r then
					humanoid:MoveTo(r.Position)
				end
				-- A shut stage refused, Stage 1 begun.
				local refused = begin("Normal", 2)
				t.Check("Stage 2 refused, waiting for Stage 1", refused.Ok == false and refused.Needs == Stages.Before and refused.Waits == 1, `{refused.Error} {refused.Needs} {refused.Waits}`)
				t.Equal("Hard refused, waiting for the keeper", begin("Hard", 1).Needs, Stages.Keeper)
				local first = begin("Normal", 1)
				t.Check("Stage 1 on Normal begins", first.Ok == true, tostring(first.Error))
				t.Check("its run on the player", waitFor(t, REPLICATE, function(): boolean
					return player:GetAttribute("StageRun") == "Normal 1"
				end))
				local row = (Stages.Of(GROUND) :: any)[1]
				t.Equal("its quota, Config.Stages'", player:GetAttribute("StageQuota"), row.Quota)
				local label: TextLabel? = nil
				t.Check("its line at the top of the screen", waitFor(t, REPLICATE, function(): boolean
					label = StageController.Label()
					return label ~= nil and label.Visible and string.find(label.Text, "Stage 1", 1, true) ~= nil and string.find(label.Text, `0 / {row.Quota}`, 1, true) ~= nil
				end), if label then (label :: TextLabel).Text else "no line")
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
				t.Check("its card opens, Results.After later", waitFor(t, StagesConfig.Results.After + REPLICATE, function(): boolean
					return Screen.Current() == StageScreen.Name and StageScreen.Parts().Title ~= nil
				end))
				local parts = StageScreen.Parts()
				local title, opened = parts.Title :: TextLabel?, parts.Opened :: TextLabel?
				t.Equal("it names the stage cleared", if title then title.Text else nil, "Stage 1 cleared")
				t.Equal("it says what opened", if opened then opened.Text else nil, "Stage 2 is open")
				t.Check("Retry, Next and Home", parts.Retry ~= nil and parts.Next ~= nil and parts.Home ~= nil)
				t.Check("written once: Stage 1 cleared on Normal", waitFor(t, REPLICATE, function(): boolean
					return line("Normal").Cleared == 1 and (line("Normal").Best[1] or 0) >= 0
				end), `{line("Normal").Cleared}`)
				t.Check("the run over", player:GetAttribute("StageRun") == nil)
				t.Check("Stage 1's gate opens to the player", waitFor(t, 1, function(): boolean
					return StageController.Gate(1) == false
				end))
				-- Next: Stage 2, set down at its start.
				local stage2 = Markers.Find("StageStart", { Stage = 2 })
				t.Check("Next begins Stage 2", parts.Next ~= nil and Button.Press(parts.Next :: TextButton))
				t.Check("set down at Stage 2's start", stage2 ~= nil and waitFor(t, MOVE + 1, function(): boolean
					local at = root()
					return at ~= nil and stage2 ~= nil and (at.Position - Markers.At(stage2).Position).Magnitude < 8
				end))
				t.Equal("its run", player:GetAttribute("StageRun"), "Normal 2")
				-- Off the street ends it.
				local first1 = t.Server("TestStream", "StageStart", { Stage = 1 })
				local off = (if typeof(first1) == "Vector3" then first1 else gate) + Vector3.new(0, R6_ROOT_HEIGHT, StagesConfig.Off + 20)
				t.Server("TestStandAt", off, off + Vector3.new(0, 0, 1))
				t.Check("off the street, the run ends", waitFor(t, 1.5, function(): boolean
					return player:GetAttribute("StageRun") == nil
				end))
				-- Hard: its own foes, the lead solo.
				t.Server("StageLine", "Normal", count)
				t.Check("Hard opens with every Normal stage cleared", waitFor(t, REPLICATE, function(): boolean
					local view = ProfileController.Get()
					return view ~= nil and Stages.Needs(view, GROUND, "Hard", 1) == nil
				end))
				local hard = begin("Hard", 1)
				t.Check("Hard Stage 1 begins", hard.Ok == true, tostring(hard.Error))
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
				local state = t.Server("Stage")
				t.Check("the lead fights alone", state.Alone == true)
				local hardElite = t.Server("StageFell", "Elite 1 mine")
				t.Check("its elite first", hardElite.Ok == true and waitFor(t, REPLICATE, function(): boolean
					return player:GetAttribute("StageLast") == true
				end), tostring(hardElite.Error))
				t.Check("not done before the quota", player:GetAttribute("StageRun") == "Hard 1")
				local hardFallen = 0
				for _ = 1, 4 do
					local some = t.Server("StageFell", "Pack 1 mine")
					hardFallen += some.Felled or 0
					if player:GetAttribute("StageRun") == nil or hardFallen >= row.Quota then
						break
					end
					-- its own pack stands again Row.Respawn after its last falls, while the run lasts (the fallen, still
					-- fading, aren't counted)
					t.Wait(0.5)
					waitFor(t, WorldConfig.Row.Respawn + 2, function(): boolean
						return #mine(1, true) >= packs
					end)
				end
				t.Check("its quota after the elite: done, its card", waitFor(t, StagesConfig.Results.After + REPLICATE, function(): boolean
					local cardTitle = StageScreen.Parts().Title :: TextLabel?
					return cardTitle ~= nil and cardTitle.Text == "Hard Stage 1 cleared"
				end), `{hardFallen} felled`)
				t.Check("its own foes gone with it", waitFor(t, REPLICATE, function(): boolean
					return #mine(1) == 0
				end))
				t.Check("the lead fights the street again", t.Server("Stage").Alone == false)
				-- The keeper on Hard: lifted ten.
				t.Server("StageLine", "Hard", count - 1)
				t.Server("KeeperRest", 0)
				local keeperRun = begin("Hard", count)
				t.Check("Hard's keeper stage begins", keeperRun.Ok == true, tostring(keeperRun.Error))
				t.Wait(MOVE)
				local try = t.Server("KeeperTry")
				t.Check("a try", try.Ok == true, tostring(try.Error))
				local keeperDef = (Stages.Last(GROUND, count) :: any)
				t.Check("the keeper ten levels up", waitFor(t, MOVE + 1, function(): boolean
					return (t.Server("Keeper").KeeperLevel or 0) == Stages.Level(keeperDef.Level, "Hard")
				end), `{t.Server("Keeper").KeeperLevel}`)
				t.Server("KeeperEnd", "Win")
				t.Check("its fall clears the keeper's stage on Hard", waitFor(t, StagesConfig.Results.After + REPLICATE + 2, function(): boolean
					return line("Hard").Cleared == count
				end), `{line("Hard").Cleared}`)
				t.Wait(MOVE + 2) -- the win's pause and fade out of the copy
				-- The picker's locks.
				t.Server("StageLine", "Hard", 0)
				t.Server("StageLine", "Normal", 1)
				t.Wait(REPLICATE)
				if Screen.Current() then
					Screen.Close()
					t.Wait(0.4)
				end
				t.Server("StageArrive")
				t.Check("through the Door, not fresh: the picker", waitFor(t, REPLICATE, function(): boolean
					return Screen.Current() == StageScreen.Name and StageScreen.Parts().Stage1 ~= nil
				end))
				local pick = StageScreen.Parts()
				t.Check("a tile a stage", pick[`Stage{count}`] ~= nil)
				t.Equal("Stage 2 open after Stage 1", if pick.Stage2 then Button.State(pick.Stage2 :: TextButton) ~= "Disabled" else nil, true)
				t.Equal("Stage 3 shut", if pick.Stage3 then Button.State(pick.Stage3 :: TextButton) else nil, "Disabled")
				local line3 = pick.Stage3Line :: TextLabel?
				t.Check("each tile's recommended Combat Power", line3 ~= nil and string.find(line3.Text, "Recommended", 1, true) ~= nil, if line3 then line3.Text else nil)
				Helpers.lintClean(t, "the picker")
				t.Check("Hard's side", pick.Hard ~= nil and Button.Press(pick.Hard :: TextButton) and waitFor(t, 0.5, function(): boolean
					return StageScreen.Difficulty() == "Hard"
				end))
				t.Equal("Hard's first tile shut while Hard is", if pick.Stage1 then Button.State(pick.Stage1 :: TextButton) else nil, "Disabled")
				Helpers.lintClean(t, "the picker on Hard, shut")
				if pick.Normal then
					Button.Press(pick.Normal :: TextButton)
				end
				Screen.Close()
				-- A lost run's card.
				local lost = begin("Normal", 1)
				t.Check("a run to lose", lost.Ok == true, tostring(lost.Error))
				t.Server("FightHealth", 0)
				t.Check("the lead's fall: its card says so", waitFor(t, REPLICATE, function(): boolean
					local cardTitle = StageScreen.Parts().Title :: TextLabel?
					return Screen.Current() == StageScreen.Name and cardTitle ~= nil and cardTitle.Text == "Your lead fell"
				end))
				t.Check("Retry and Home, no Next", StageScreen.Parts().Retry ~= nil and StageScreen.Parts().Home ~= nil and StageScreen.Parts().Next == nil)
				Helpers.lintClean(t, "the lost card")
				restore()
			end,
		},
		{
			Name = "Stages (TR43): a fresh account through the Festival Door is in Stage 1 on Normal with no screen (wipes the save)",
			Place = "Festival", -- TR45: its world stands in that place only
			Manual = true,
			Run = function(t: any)
				t.Server("DataWipe")
				t.Wait(REPLICATE)
				t.Check("fresh", t.Server("Stage").Fresh == true)
				t.Server("StageArrive")
				t.Check("Stage 1 on Normal at once", waitFor(t, REPLICATE, function(): boolean
					return player:GetAttribute("StageRun") == "Normal 1"
				end))
				t.Check("no screen", Screen.Current() == nil)
			end,
		},
	}
end

return StageCases
