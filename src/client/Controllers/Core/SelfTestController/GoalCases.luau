--!strict
-- GoalCases: TR54's goals in play (Rules.Goals; GoalService; UI.TodayList, UI.DareLine, the run's card), apart: Cases is
-- at the type checker's limit.
-- - Home's Today card and its list, from a save set for the test: the card's pips and its gold rim while a goal waits;
--   the list in the glass alone, Next at its head, today's three then yesterday's under its heading, each row as its
--   state says; a done row's press claims its shard once, a repeated claim pays nothing, the back press brings the
--   cards back. The save's goals and shards are put back at the end.
-- - A stretch's dare on the run's line (the Festival's place): it unfolds with its words clear of the Electricity pill,
--   folds round its mark, goes dark as the lead drops to half and lights again healed; the stretch cleared with it kept
--   pays one stone of the ground's grade and flares; the run's fall card shows the kept chip and the road's mark.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local WorldConfig = require(Shared.Config.World)
local StagesConfig = require(Shared.Config.Stages)
local HudConfig = require(Shared.Config.Hud)
local GoalsConfig = require(Shared.Config.Goals)
local DropsConfig = require(Shared.Config.Drops)
local Goals = require(Shared.Rules.Goals)
local GoalFacts = require(Shared.Rules.GoalFacts)
local Stages = require(Shared.Rules.Stages)
local Defs = require(Shared.Definitions.Goals)
local ProfileController = require(script.Parent.Parent.ProfileController)
local StageController = require(script.Parent.Parent.Parent.Main.StageController)
local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local Helpers = require(script.Parent.Helpers)
local UI = script.Parent.Parent.Parent.Parent.UI
local Screen = require(UI.Kit.Screen)
local Button = require(UI.Kit.Button)
local HomePanel = require(UI.HomePanel)
local TodayList = require(UI.TodayList)
local StageScreen = require(UI.StageScreen)
local Layers = require(UI.Layers)
local Theme = require(UI.Theme)

local GoalCases = {}

local GROUND = WorldConfig.Row.Ground
local REPLICATE = 2 -- seconds for a save's copy or an attribute to reach the client
local SHARD = GoalsConfig.Reward.Shard

local player = Players.LocalPlayer
local waitFor = Helpers.waitFor

-- The save's count, read once on the server; a wait polls the client's copy instead (the bridge allows 30 calls a second).
local function shards(t: any): number
	local data = t.Server("Data") :: any
	return data.Bag.Shards[SHARD] or 0
end

local function shown(): number
	local view = ProfileController.Get() :: any
	return if view then view.Bag.Shards[SHARD] or 0 else -1
end

local function begin(difficulty: string): { [string]: any }
	local ok, answer = pcall(Net.Client.Invoke, "Stage", GROUND, difficulty)
	return if ok and type(answer) == "table" then answer else { Ok = false, Error = tostring(answer) }
end

-- Ends a run the case left going, by the game's own way out: its lead's fall (StageBegin would begin another). Its card
-- comes Results.After later and is closed; the lead is healed.
local function endRun(t: any)
	if type(player:GetAttribute("StageRun")) ~= "string" then
		return
	end
	t.Server("FightHealth", 0)
	waitFor(t, REPLICATE, function(): boolean
		return player:GetAttribute("StageRun") == nil
	end)
	waitFor(t, StagesConfig.Results.After + 1, function(): boolean
		return Screen.Current() == StageScreen.Name
	end)
	Screen.Close()
	t.Server("LeadHeal")
end

-- The day's rows as the list shows them, in order: "<id> <state> <right>".
local function rows(said: { [string]: any }): { string }
	local out = {}
	for _, row in said.Rows do
		table.insert(out, `{row.Id} {row.State} {row.Right}`)
	end
	return out
end

function GoalCases.Cases(): { any }
	return {
		{
			Name = "Goals (TR54): Home's Today card and its list; Next at its head; a done row claims its shard once; back to the cards",
			Run = function(t: any)
				Screen.Close()
				local home = HudConfig.Home
				local was = t.Server("Goals") :: any
				local today = was.Today
				local heldBefore = shards(t)
				-- today's three: one done, one counting, one claimed; yesterday's: one done, one counting an hour, one open
				local set = {
					{ Day = today - 1, Picks = { "Lamplighter", "BaysHour", "NewLead" }, Have = { 0, 900, 1 }, Claimed = { false, false, false } },
					{ Day = today, Picks = { "KeepDare", "ThreeShards", "LevelUp" }, Have = { 1, 1, 1 }, Claimed = { false, false, true } },
				}
				local function restore()
					t.Server("GoalsSet", was.Days)
					local gained = shards(t) - heldBefore
					if gained ~= 0 then
						t.Server("BaseGive", SHARD, -gained)
					end
					local panel = HudController.Home()
					TodayList.Hide(panel, true)
				end
				t.Check("the save set for the test", (t.Server("GoalsSet", set) :: any).Ok == true)
				local function copied(): boolean
					local view = ProfileController.Get() :: any
					local days = view and view.Goals and view.Goals.Days
					return days ~= nil and #days == 2 and days[2].Picks[1] == "KeepDare" and days[1].Have[3] == 1
				end
				t.Check("its copy reached the client", waitFor(t, REPLICATE, copied))
				local panel = HudController.Home()
				if not HomePanel.Shown(panel) then
					Button.Press(HudController.Parts().Home :: TextButton)
				end
				t.Wait(home.Open.Grow + 0.2)
				local said = TodayList.Said(panel) :: any
				t.Check("the card's rim in gold while a goal waits", said.Waits == true)
				t.Equal("its pips: today's three, done, open and claimed", table.concat(said.Pips, " "), "GoalPipDone GoalPipOpen GoalPipClaimed")
				local card = panel.Cards.Today
				t.Check("the card's word, whole", (function(): boolean
					local word = card.Holder:FindFirstChild("Word") :: TextLabel?
					return word ~= nil and word.Text == Defs.Labels.Today and word.TextFits
				end)())
				-- the list
				t.Check("the card's press opens the list", Button.Press(card.Button) and waitFor(t, home.Step.Lit + 0.5, function(): boolean
					return TodayList.Shown(panel)
				end))
				t.Wait(home.Today.Switch + 0.1)
				said = TodayList.Said(panel) :: any
				t.Check("the panel stays, the cards step out", HomePanel.Shown(panel) and not panel.Cards.Settings.Button.Visible and not card.Button.Visible)
				local view = ProfileController.Get() :: any
				local index = Goals.Next(Defs.Next, GoalFacts.Of(view))
				local step = Defs.Next[math.min(index, #Defs.Next)]
				t.Equal("Next: the first step not done, then what it opens", table.concat(said.Next, " | "), if step.Opens then `{step.Text} | {step.Opens}` else step.Text)
				t.Equal("today's three, then yesterday's left to claim", table.concat(rows(said), ", "), "KeepDare Done Claim, ThreeShards Open 1 / 3, LevelUp Claimed , Lamplighter Open , BaysHour Open 0:15 / 1:00, NewLead Done Claim")
				local list = panel.Frame:FindFirstChild("TodayList") :: Frame?
				local scroll = if list then list:FindFirstChild("Rows") :: ScrollingFrame? else nil
				local heading = if scroll then scroll:FindFirstChild("Day1") else nil
				local headingWords = if heading then heading:FindFirstChild("Words") :: TextLabel? else nil
				t.Equal("yesterday under its heading", if headingWords then headingWords.Text else nil, Defs.Labels.Days[1])
				t.Check("the rows pass the room: the thumb shows", said.Thumb == true)
				local cut = {}
				for _, label in if list then list:GetDescendants() else {} do
					if label:IsA("TextLabel") and label.Text ~= "" and not label.TextFits then
						table.insert(cut, label.Text)
					end
				end
				t.Check("every word whole", #cut == 0, table.concat(cut, ", "))
				-- a claim: the done row's press, its shard paid once
				local first = said.Rows[1]
				t.Check("a done row is the claim's press", first.Button ~= nil)
				Button.Press(first.Button)
				t.Check("claimed: one shard paid", waitFor(t, REPLICATE + 1, function(): boolean
					return shown() == heldBefore + 1
				end) and shards(t) == heldBefore + 1, `{shards(t) - heldBefore}`)
				t.Check("the row sinks and takes its check", waitFor(t, REPLICATE, function(): boolean
					local now = TodayList.Said(panel) :: any
					return now.Rows[1].State == "Claimed" and now.Rows[1].Button == nil
				end))
				local again = t.Server("Act", "GoalClaim", { Day = today, Slot = 1 }) :: any
				t.Check("claimed again: refused, nothing paid", again.Ok == false and again.Error == "Claimed" and shards(t) == heldBefore + 1, `{again.Error}`)
				-- the same request twice (the op ledger): one shard
				local op = `tr54-claim-{math.floor(os.clock() * 1000)}` -- letters, digits and dashes only (OpLedger.ValidId)
				local a = t.Server("Act", "GoalClaim", { Day = today - 1, Slot = 3 }, op) :: any
				local b = t.Server("Act", "GoalClaim", { Day = today - 1, Slot = 3 }, op) :: any
				t.Check("a repeated request pays once", a.Ok == true and b.Ok == true and shards(t) == heldBefore + 2, `{a.Ok} {b.Ok} {shards(t) - heldBefore}`)
				t.Check("nothing waits: the card's rim back to rest", waitFor(t, REPLICATE, function(): boolean
					return (TodayList.Said(panel) :: any).Waits == false
				end))
				-- back
				local back = (TodayList.Said(panel) :: any).Back :: TextButton
				Button.Press(back)
				t.Check("the back press brings the cards back", waitFor(t, 0.5, function(): boolean
					return not TodayList.Shown(panel) and card.Button.Visible and panel.Cards.Settings.Button.Visible
				end))
				Helpers.lintClean(t, "Home with the Today card")
				HomePanel.Close(panel)
				t.Wait(home.Open.Leave + 0.1)
				restore()
			end,
		},
		{
			Name = "Goals (TR54): a stretch's dare on the run's line: unfolds clear of the pill, folds, dark below half, a kept dare's stone and flare, the fall card's chip",
			Place = "Festival", -- TR45: its world stands in that place only
			Run = function(t: any)
				if Screen.Current() ~= nil then
					Screen.Close()
					t.Wait(0.3)
				end
				local before = t.Server("Stage") :: any
				local held = before.Checkpoint or { Normal = 1, Hard = 1 }
				local was = {
					Normal = { before.Normal and before.Normal.Cleared or 0, held.Normal },
					Hard = { before.Hard and before.Hard.Cleared or 0, held.Hard },
				}
				local goalsWas = (t.Server("Goals") :: any).Days
				local stones = function(): number
					return ((t.Server("Data") :: any).Bag.Stones[GoalsConfig.Dare.Grade[GROUND] or "Low"] or 0)
				end
				local stonesBefore = stones()
				local function restore()
					endRun(t)
					t.Server("StageLine", "Hard", 0)
					t.Server("StageLine", "Normal", was.Normal[1], was.Normal[2])
					t.Server("StageLine", "Hard", was.Hard[1], was.Hard[2])
					t.Server("LeadHeal")
					for _, name in { "Pack 1", "Elite 1", "Pack 2", "Elite 2" } do
						t.Server("PackBack", name)
					end
					t.Server("GoalsSet", goalsWas)
				end
				t.Server("LeadHeal")
				t.Server("StageLine", "Hard", 0)
				t.Server("StageLine", "Normal", 0)
				local run = begin("Normal")
				t.Check("a Normal run from stretch 1", run.Ok == true and run.Stage == 1, `{run.Error} {run.Stage}`)
				local dare = Defs.Dares[1]
				t.Check("its dare opens on the server", waitFor(t, REPLICATE, function(): boolean
					return player:GetAttribute("StageDare") == `1 {dare.Id}` and player:GetAttribute("StageDareLook") == "Holds"
				end), `{player:GetAttribute("StageDare")} {player:GetAttribute("StageDareLook")}`)
				local look = HudConfig.Stages.Dare
				t.Check("it unfolds under the line with its words", waitFor(t, REPLICATE, function(): boolean
					local said = StageController.Dare()
					return said ~= nil and said.Open == true and said.Words == dare.Text and said.Kit == "DareMark"
				end), `{(StageController.Dare() or {} :: any).Words}`)
				local said = StageController.Dare() :: any
				local value = HudController.Parts().Electricity :: GuiObject
				local pill = value.Parent :: GuiObject -- the Power pill's root, the value in it
				local pillLeft = if pill.Visible then pill.AbsolutePosition.X else math.huge
				t.Check("its open box ends clear of the Electricity pill", said.Right <= pillLeft - (look.Limit - 1), string.format("right %.0f, pill %.0f", said.Right, pillLeft))
				t.Check("it folds round its mark after it's read", waitFor(t, look.Motion.Open + GoalsConfig.Held + look.Motion.Close + 0.6, function(): boolean
					local now = StageController.Dare()
					return now ~= nil and now.Open == false and now.Clip == false
				end))
				t.Server("FightHealth", 0.3)
				t.Check("below half: the mark goes dark", waitFor(t, REPLICATE, function(): boolean
					local now = StageController.Dare()
					return now ~= nil and now.Look == "Broken" and now.Kit == "DareMarkDark"
				end), `{(StageController.Dare() or {} :: any).Kit}`)
				t.Server("FightHealth", 1) -- the live lead whole again (LeadHeal mends the save's)
				t.Check("healed: lit again", waitFor(t, REPLICATE, function(): boolean
					local now = StageController.Dare()
					return now ~= nil and now.Look == "Holds" and now.Kit == "DareMark"
				end))
				-- the stretch cleared with its dare kept
				-- the falls' own stones off while it's measured, so the bag's gain is the dare's alone
				local chanceWas = DropsConfig.StoneChance.Normal
				t.Server("Tune", "Drops.StoneChance.Normal", 0)
				local stonesAt = stones()
				local quota = (Stages.Of(GROUND) :: any)[1].Quota
				local fallen = 0
				for _ = 1, 4 do -- the quota through Pack 1's falls, the pack stood again between (StageCases' way)
					if fallen >= quota then
						break
					end
					t.Server("PackBack", "Pack 1")
					fallen += (t.Server("StageFell", "Pack 1") :: any).Felled or 0
				end
				t.Server("PackBack", "Elite 1")
				t.Server("StageFell", "Elite 1")
				t.Check("cleared with it kept: its mark flares", waitFor(t, REPLICATE + 1, function(): boolean
					local now = StageController.Dare()
					return now ~= nil and now.Look == "Kept" and now.Kit == "DareMarkKept"
				end), `{player:GetAttribute("StageDareLook")}`)
				t.Equal("one stone of the ground's grade paid", stones() - stonesAt, GoalsConfig.Dare.Count)
				local paid = stones()
				local dare2 = Goals.Dare(Defs.Dares, Defs.Fallback, 2, GoalsConfig.Ready)
				t.Check("stretch 2 brings its own dare", waitFor(t, StagesConfig.Results.After + REPLICATE + 1, function(): boolean
					return player:GetAttribute("StageDare") == `2 {dare2.Id}`
				end), `{player:GetAttribute("StageDare")}`)
				-- its line is built again for stretch 2 after the dare comes: it unfolds there all the same
				t.Check("stretch 2's dare unfolds with its words", waitFor(t, REPLICATE, function(): boolean
					local said = StageController.Dare()
					return said ~= nil and said.Open == true and said.Words == dare2.Text
				end), `{(StageController.Dare() or {} :: any).Open} {(StageController.Dare() or {} :: any).Words}`)
				-- a fall takes nothing back; its card shows the kept dare
				t.Server("FightHealth", 0)
				t.Check("the fall's card", waitFor(t, REPLICATE + 1, function(): boolean
					return Screen.Current() ~= nil and StageScreen.Parts().Retry ~= nil
				end))
				local parts = StageScreen.Parts()
				local chip = parts.Dare :: Frame?
				local words = if chip then chip:FindFirstChild("Words") :: TextLabel? else nil
				local count = if chip then chip:FindFirstChild("Count") :: TextLabel? else nil
				t.Check("its chip: Dare kept, +1", words ~= nil and words.Text == Defs.Labels.DareKept and count ~= nil and count.Text == `+{GoalsConfig.Dare.Count}`, if words then words.Text else "no chip")
				local card = Screen.Current() and chip and chip:FindFirstAncestorWhichIsA("ScreenGui")
				local mark = if card then card:FindFirstChild("Dare1", true) else nil
				t.Check("the road's mark on stretch 1", mark ~= nil and mark:GetAttribute("Kit") == "DareMarkKept")
				t.Check("the fall took no stone back", stones() >= paid, `{stones() - paid}`)
				t.Server("Tune", "Drops.StoneChance.Normal", chanceWas)
				Helpers.lintClean(t, "the fall's card with a dare kept")
				Screen.Close()
				t.Wait(0.4)
				t.Check("the run over: the dare leaves the line", waitFor(t, REPLICATE, function(): boolean
					return player:GetAttribute("StageDare") == nil
				end))
				restore()
				local gained = stones() - stonesBefore
				if gained ~= 0 then
					t.Server("StonesGive", GoalsConfig.Dare.Grade[GROUND] or "Low", -gained)
				end
			end,
		},
		{
			Name = "Take: TR54, the goals held for stills on the smallest phone, for research",
			Place = "Festival", -- the run's line and its cards stand in that place only
			Manual = true,
			Stay = true,
			Run = function(t: any)
				-- Each state is held until the driver moves ReplicatedStorage.NL_TakeStep on and captures it: "Phone", then
				-- "DareOpen", "DareFolded", "DareBroken", "DareKept", "DareNext" (the stretch it's on cleared, the next one's dare
				-- unfolding), "Fall" (its card
				-- with the kept chip), "Win" (the keeper's card with the chip on its time row), "Home" (the Today card),
				-- "List", "End". The dare stays open Held seconds and a cleared stretch Wait seconds, tuned live for the
				-- stills and put back; the save's stretches, goals and stones are put back at the end.
				local step = Instance.new("StringValue")
				step.Name = "NL_TakeStep"
				step.Value = "Ready"
				step.Parent = ReplicatedStorage
				local HELD, WAIT = 5, 6
				local before = t.Server("Stage") :: any
				local held = before.Checkpoint or { Normal = 1, Hard = 1 }
				local was = {
					Normal = { before.Normal and before.Normal.Cleared or 0, held.Normal },
					Hard = { before.Hard and before.Hard.Cleared or 0, held.Hard },
				}
				local goalsWas = (t.Server("Goals") :: any).Days
				local grade = GoalsConfig.Dare.Grade[GROUND] or "Low"
				local stonesWas = ((t.Server("Data") :: any).Bag.Stones[grade] or 0)
				local heldWas, afterWas = GoalsConfig.Held, StagesConfig.Results.After
				t.Server("Tune", "Goals.Held", HELD)
				t.Server("Tune", "Stages.Results.After", WAIT)
				local count = #(Stages.Of(GROUND) :: { any })
				local panel = HudController.Home()
				local function said(): { [string]: any }
					return StageController.Dare() or {}
				end
				local function clear(stage: number)
					local quota = (Stages.Of(GROUND) :: any)[stage].Quota
					local fallen = 0
					for _ = 1, 6 do
						if fallen >= quota then
							break
						end
						t.Server("PackBack", `Pack {stage}`)
						fallen += (t.Server("StageFell", `Pack {stage}`) :: any).Felled or 0
					end
					t.Server("PackBack", `Elite {stage}`)
					t.Server("StageFell", `Elite {stage}`)
				end
				local states: { [string]: () -> () } = {
					Phone = function()
						Screen.Close()
						Layers.Force(Theme.Scale.Floor)
						Layers.Box(Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height))
						t.Wait(0.3)
					end,
					DareOpen = function()
						t.Server("LeadHeal")
						t.Server("FightHealth", 1)
						t.Server("StageLine", "Hard", 0)
						t.Server("StageLine", "Normal", 0)
						begin("Normal")
						waitFor(t, REPLICATE, function(): boolean
							return said().Open == true
						end)
						t.Wait(0.35)
					end,
					DareFolded = function()
						waitFor(t, HELD + 2, function(): boolean
							return said().Open == false and said().Clip == false
						end)
					end,
					DareBroken = function()
						t.Server("FightHealth", 0.3)
						waitFor(t, REPLICATE, function(): boolean
							return said().Look == "Broken"
						end)
					end,
					DareKept = function()
						t.Server("FightHealth", 1)
						waitFor(t, REPLICATE, function(): boolean
							return said().Look == "Holds"
						end)
						clear(1)
						waitFor(t, REPLICATE, function(): boolean
							return said().Look == "Kept"
						end)
						t.Wait(0.5) -- the flare spent
					end,
					DareNext = function()
						local _, stage = Stages.Parse(player:GetAttribute("StageRun"))
						local at = stage or 1
						clear(at)
						waitFor(t, WAIT + REPLICATE + 1, function(): boolean
							return string.match(tostring(player:GetAttribute("StageDare")), "^(%d+) ") == tostring(at + 1) and said().Open == true
						end)
						t.Wait(0.35)
					end,
					Fall = function()
						t.Server("FightHealth", 0)
						waitFor(t, WAIT + REPLICATE + 1, function(): boolean
							return Screen.Current() == StageScreen.Name
						end)
						t.Wait(0.8)
					end,
					Win = function()
						Screen.Close()
						t.Wait(0.4)
						t.Server("LeadHeal")
						t.Server("StageLine", "Normal", count - 1, count)
						t.Server("KeeperRest", 0)
						begin("Normal")
						t.Wait(2.5)
						t.Server("KeeperTry")
						t.Wait(2.5)
						t.Server("KeeperEnd", "Win")
						waitFor(t, WAIT + REPLICATE + 2, function(): boolean
							return Screen.Current() == StageScreen.Name
						end)
						t.Wait(0.8)
					end,
					Home = function()
						Screen.Close()
						t.Wait(0.4)
						local today = (t.Server("Goals") :: any).Today
						t.Server("GoalsSet", {
							{ Day = today - 1, Picks = { "Lamplighter", "BaysHour", "NewLead" }, Have = { 0, 900, 1 }, Claimed = { false, false, false } },
							{ Day = today, Picks = { "KeepDare", "ThreeShards", "LevelUp" }, Have = { 1, 1, 1 }, Claimed = { false, false, true } },
						})
						t.Wait(REPLICATE)
						if not HomePanel.Shown(panel) then
							Button.Press(HudController.Parts().Home :: TextButton)
						end
						t.Wait(HudConfig.Home.Open.Grow + 0.4)
					end,
					List = function()
						Button.Press(panel.Cards.Today.Button)
						t.Wait(HudConfig.Home.Step.Lit + HudConfig.Home.Today.Switch + 0.4)
					end,
				}
				local shown = "Ready"
				local began = os.clock()
				while step.Value ~= "End" and os.clock() - began < 600 do
					if step.Value ~= shown then
						shown = step.Value
						local apply = states[shown]
						if apply then
							apply()
						end
						step:SetAttribute("Shown", shown)
					end
					t.Wait(0.1)
				end
				TodayList.Hide(panel, true)
				HomePanel.Close(panel)
				Screen.Close()
				Layers.Box(nil)
				Layers.Force(nil)
				t.Server("Tune", "Goals.Held", heldWas)
				t.Server("Tune", "Stages.Results.After", afterWas)
				endRun(t)
				t.Server("StageLine", "Hard", 0)
				t.Server("StageLine", "Normal", was.Normal[1], was.Normal[2])
				t.Server("StageLine", "Hard", was.Hard[1], was.Hard[2])
				t.Server("LeadHeal")
				t.Server("GoalsSet", goalsWas)
				local gained = ((t.Server("Data") :: any).Bag.Stones[grade] or 0) - stonesWas
				if gained ~= 0 then
					t.Server("StonesGive", grade, -gained)
				end
				step:Destroy()
				t.Check("the driver ended it", shown == "End" or step.Value == "End", shown)
			end,
		},
	}
end

return GoalCases
