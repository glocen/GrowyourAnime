--!strict
-- The Tower's case (TR29): a run from the ring's step; each floor's foe a Voidkin of the pool at its floor's level, in its
-- enemy look, for this player alone; floors won through the fight itself or Studio's TowerWin, each written to the run's
-- ledger once with Rules.Tower's own reward; no heal between floors and at most the cap in one; the lead, its stars and
-- its Regalia frozen; at most three platforms and the column; the lead's fall ending the run at its last floor won, the ledger
-- granted once, the record and the results, which open once and clear when closed. Then the avatar stepping off its
-- platform, and a crash's run ended at the next join. The results' Home and Retry (TR46): Home sets the avatar down at
-- its plot's spawn, Retry in its ring, where the next run begins once rested. The case's record, Credits and chests are
-- put back at its end.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local TowerConfig = require(Shared.Config.Tower)
local Profile = require(Shared.Data.Profile)
local Markers = require(Shared.World.Markers)
local Tower = require(Shared.Rules.Tower)
local ProfileController = require(script.Parent.Parent.ProfileController)
local TowerController = require(script.Parent.Parent.Parent.Main.TowerController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Screen = require(UI.Kit.Screen)
local Button = require(UI.Kit.Button)
local TowerScreen = require(UI.TowerScreen)

local TowerCases = {}

local function view(): Profile.View
	return ProfileController.Get() :: Profile.View
end

local function rivalOf(player: Player): Model?
	for _, item in workspace:GetDescendants() do
		if item:IsA("Model") and item:GetAttribute("Kind") == "Rival" and item:GetAttribute("For") == player.UserId then
			return item
		end
	end
	return nil
end

local function waitFor(t: any, seconds: number, ok: () -> boolean): boolean
	local began = os.clock()
	while os.clock() - began < seconds do
		if ok() then
			return true
		end
		t.Wait(0.1)
	end
	return ok()
end

function TowerCases.Cases(): { any }
	return {
		{
			Name = "Tower (TR29): a run from the ring, floors won into the ledger, the heal cap, the freeze, three platforms, the fall, the results once, stepping off, a crash's run ended at the join; the results' Home and Retry (TR46)",
			Place = "Main", -- TR45: its world stands in that place only
			Run = function(t: any)
				-- The bays step out for the run and back after it: a full battery spills a working bay's power into Credits,
				-- which would read as a grant mid-run (Rules.Breaker's Spill). And the foes strike for next to nothing, by
				-- a Tune put back after: a lifted foe's signature takes about two fifths of a level 5 lead, so the climb
				-- would test the run's seed, not the ledger (the lead's fall is its own step, by TowerFell).
				local attack = TowerConfig.Lift.Attack
				t.Server("Tune", "Tower.Lift.Attack", 0.01)
				local working: { [number]: string } = {}
				for bay, seat in view().Base.Bays do
					if seat.Worker ~= "" then
						working[bay] = seat.Worker
						t.Check(`bay {bay}'s worker steps out for the run`, t.Server("Act", "SetWorker", { Bay = bay, Voidkin = "" }).Ok == true)
					end
				end
				local ok, problem = pcall(function()
					local me = Players.LocalPlayer
					t.Server("TowerEnd")
					t.Server("LeadHeal")
					local credits0 = view().Currency.Credits
					local best0 = view().Progress.Tower.Best
					local chests0 = table.clone(view().Bag.Chests)
					local function state(): { [string]: any }
						return t.Server("TowerState")
					end
					local function granted(): { [string]: number }
						local held = view().Bag.Chests
						local out = {}
						for id, count in held do
							local more = count - (chests0[id] or 0)
							if more > 0 then
								out[id] = more
							end
						end
						return out
					end
					-- The ring's step: the avatar set down inside it starts a run.
					local plot = me:GetAttribute("Plot")
					local ring = if type(plot) == "number" then Markers.Find("TowerRing", { Plot = plot }) else nil
					t.Check("the plot's ring", ring ~= nil)
					if ring == nil then
						return
					end
					local middle = Markers.At(ring).Position
					t.Server("TestStandAt", middle + Vector3.new(0, 3, 0))
					t.Check("stepping into the ring starts a run", waitFor(t, 3, function()
						return me:GetAttribute("Tower") == 1
					end))
					if me:GetAttribute("Tower") ~= 1 then
						return
					end
					-- The climb: floors 1 to 3 won, by the lead or by TowerWin, each checked as it's fought and as it's written.
					local caught = 0
					local rising = 0
					local deadline = os.clock() + TowerConfig.Rise * 4 + 25
					-- The attribute replicates before the save's copy: the run in the copy, waited for.
					waitFor(t, 3, function()
						return view().Progress.Tower.Run ~= nil
					end)
					local run = view().Progress.Tower.Run
					t.Check("the run in the save, its floor none won", run ~= nil and run.Floor == 0, if run then `{run.Floor}` else "none")
					local seed = if run then run.Seed else 0
					while os.clock() < deadline do
						local s = state()
						local saved = view().Progress.Tower.Run
						if saved and saved.Floor >= 3 then
							break
						end
						if s.Phase == "Fighting" and type(s.Floor) == "number" and s.Floor <= 3 then
							caught += 1
							local foe = rivalOf(me)
							t.Check(`floor {s.Floor}: its foe is of the pool at its level`, table.find(Tower.Pool(), s.Foe) ~= nil and s.FoeLevel == Tower.Level(s.Floor), `{s.Foe}, {s.FoeLevel}`)
							t.Check(`floor {s.Floor}: in its enemy look, for this player`, foe ~= nil and foe:FindFirstChild("RivalLook") ~= nil)
							t.Check(`floor {s.Floor}: healing within the cap`, type(s.HealRoom) == "number" and s.HealRoom <= TowerConfig.HealCap * s.LeadMax + 1e-6)
							local root = me.Character and me.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
							t.Check(`floor {s.Floor}: the avatar on its platform`, root ~= nil and math.abs(root.Position.Y - 3 - s.Top) < 2, if root then `{root.Position.Y - 3} against {s.Top}` else "no root")
							if caught == 1 then
								-- The freeze (D10): gear and the lead stay as they are through the run.
								local equip = t.Server("Act", "Equip", { Preset = 1, Slot = "Helmet", Item = "none" })
								t.Check("gear frozen", type(equip) == "table" and equip.Error == "InCombat", tostring(equip and equip.Error))
								local other
								for id in view().Voidkin do
									if id ~= view().Roles.Lead then
										other = id
										break
									end
								end
								if other then
									local swap = t.Server("Act", "SetLead", { Voidkin = other })
									t.Check("the lead frozen", type(swap) == "table" and swap.Ok ~= true and swap.Error == "InCombat", tostring(swap and swap.Error))
								end
								local stars = t.Server("Act", "SpendCopies", { Voidkin = view().Roles.Lead })
								t.Check("the lead's stars frozen", type(stars) == "table" and stars.Error == "InCombat", tostring(stars and stars.Error))
								-- The cap at work: hurt to half, then never more than the cap back in this floor.
								local hurt = t.Server("TowerHurt", 0.5)
								task.wait(1.5)
								local after = state()
								if after.Phase == "Fighting" and after.Floor == s.Floor and type(hurt) == "table" then
									t.Check("at most the cap healed in the floor", after.LeadHealth - hurt.Health <= TowerConfig.HealCap * after.LeadMax + 1e-3, `{after.LeadHealth - hurt.Health}`)
								end
							end
							t.Server("TowerWin")
							task.wait(0.15)
						elseif s.Phase == "Rising" or s.Phase == "Won" then
							if s.HealRoom ~= nil and s.HealRoom ~= 0 then
								t.Check(`floor {s.Floor}: no heal between floors`, false, tostring(s.HealRoom))
							end
							rising += 1
							task.wait(0.1)
						else
							task.wait(0.1)
						end
					end
					local saved = view().Progress.Tower.Run
					t.Check("three floors won", saved ~= nil and saved.Floor >= 3, if saved then `{saved.Floor}` else "no run")
					t.Check("a floor caught in its fight", caught >= 1, `{caught}`)
					t.Check("a rise caught between floors", rising >= 1)
					if saved == nil then
						return
					end
					-- Only hard floors pay: a floor is fast by the lead's level against its foe's, as TowerService fights it.
					local function fastAt(floor: number): boolean
						local lead = view().Voidkin[view().Roles.Lead]
						return lead ~= nil and Tower.Fast(lead.Level, Tower.Level(floor))
					end
					local ledger = 0
					for floor = 1, saved.Floor do
						ledger += Tower.Reward(floor, best0, seed, fastAt(floor)).Credits
					end
					t.Equal("the ledger holds each floor's reward once", saved.Credits, ledger)
					t.Equal("nothing granted mid-run", view().Currency.Credits, credits0)
					-- Floor 4's stack: three platforms and the column under them.
					waitFor(t, TowerConfig.Rise + 1, function()
						return me:GetAttribute("Tower") == saved.Floor + 1
					end)
					local discs, column = TowerController.Platforms(me)
					local floors = {}
					for floor in discs do
						table.insert(floors, floor)
					end
					table.sort(floors)
					local top = me:GetAttribute("Tower") :: number
					t.Check("at most three platforms, the floor's and two below", #floors == math.min(3, top) and floors[#floors] == top, table.concat(floors, ", "))
					t.Check("older floors in one column", (column ~= nil) == (top > 3))
					-- The fall: the run ends at its last floor won, granted once.
					local won = (view().Progress.Tower.Run :: Profile.TowerRun).Floor
					t.Server("TowerFell")
					t.Check("the fall ends the run", waitFor(t, 5, function()
						return me:GetAttribute("Tower") == nil and view().Progress.Tower.Run == nil
					end))
					local results = view().Progress.Tower.Results
					t.Check("its results", results ~= nil and results.Floor >= won, if results then `{results.Floor}` else "none")
					if results == nil then
						return
					end
					local total = 0
					for floor = 1, results.Floor do
						total += Tower.Reward(floor, best0, seed, fastAt(floor)).Credits
					end
					t.Equal("their Credits are the ledger's", results.Credits, total)
					t.Equal("granted once", view().Currency.Credits, credits0 + results.Credits)
					for id, count in results.Chests do
						t.Equal(`{id} granted`, granted()[id], count)
					end
					t.Check("the record", view().Progress.Tower.Best == math.max(best0, results.Floor) and results.Record == (results.Floor > best0))
					t.Check("the platforms fall away", waitFor(t, 2, function()
						return next((TowerController.Platforms(me))) == nil
					end))
					-- The results open once, and clear when closed.
					t.Check("the results open", waitFor(t, 3, function()
						return Screen.Current() == TowerScreen.Name
					end))
					local parts = TowerScreen.Parts()
					local floorLine = parts.Floor
					t.Check("they say the floor", floorLine ~= nil and floorLine:IsA("TextLabel") and floorLine.Text == `Floor {results.Floor}`)
					-- Home (TR46): set down at the plot's spawn, free, and the results closed.
					local home = parts.Home
					t.Check("in the base, Retry and Home, no Close", home ~= nil and parts.Retry ~= nil and parts.Close == nil)
					if home and home:IsA("TextButton") then
						Button.Press(home)
					end
					t.Check("closed, they're cleared from the save", waitFor(t, 3, function()
						return view().Progress.Tower.Results == nil
					end))
					local spawn = Markers.Find("Spawn", { Plot = plot })
					local root = me.Character and me.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
					local fromSpawn = if spawn and root then (root.Position - Markers.At(spawn).Position) * Vector3.new(1, 0, 1) else nil
					t.Check("Home sets the avatar down at its plot's spawn", fromSpawn ~= nil and fromSpawn.Magnitude < 6, tostring(fromSpawn and fromSpawn.Magnitude))
					task.wait(0.5)
					t.Check("and don't open again", Screen.Current() ~= TowerScreen.Name)
					-- Stepping off the platform ends a run where it stands.
					t.Server("LeadHeal")
					local again = t.Server("TowerStart")
					t.Check("another run", type(again) == "table" and again.Ok == true, tostring(again and again.Error))
					waitFor(t, TowerConfig.Rise + 1, function()
						return state().Phase == "Fighting"
					end)
					t.Server("TowerOff")
					t.Check("stepping off ends it", waitFor(t, 3, function()
						return me:GetAttribute("Tower") == nil and view().Progress.Tower.Run == nil and view().Progress.Tower.Results ~= nil
					end))
					t.Check("its results open", waitFor(t, 3, function()
						return Screen.Current() == TowerScreen.Name
					end))
					-- A crash: the run dropped unended, its ledger in the save; the join ends it. Started over the stepped-off
					-- run's results still open: the save drops them, and they close (the next run's open in their place).
					t.Server("LeadHeal")
					local third = t.Server("TowerStart")
					t.Check("a third run", type(third) == "table" and third.Ok == true)
					t.Check("a run started over results still open closes them", waitFor(t, 3, function()
						return Screen.Current() ~= TowerScreen.Name and view().Progress.Tower.Results == nil
					end))
					waitFor(t, TowerConfig.Rise + 1, function()
						return state().Phase == "Fighting"
					end)
					t.Server("TowerWin")
					waitFor(t, 3, function()
						local held = view().Progress.Tower.Run
						return held ~= nil and held.Floor >= 1
					end)
					local before = view().Currency.Credits
					local left = view().Progress.Tower.Run
					t.Server("TowerCrash")
					t.Check("a crash leaves the run in the save", view().Progress.Tower.Run ~= nil)
					t.Server("TowerRecover")
					t.Check("the join ends it, its ledger granted", waitFor(t, 3, function()
						return view().Progress.Tower.Run == nil and left ~= nil and view().Currency.Credits == before + left.Credits
					end))
					-- Retry (TR46), on the crash's results: set in the ring, and the next run begins once the rest is up.
					t.Check("the crash's results open", waitFor(t, 3, function()
						return Screen.Current() == TowerScreen.Name
					end))
					t.Server("LeadHeal")
					local retry = TowerScreen.Parts().Retry
					if retry and retry:IsA("TextButton") then
						Button.Press(retry)
					end
					local inRing = waitFor(t, 2, function()
						local at = me.Character and me.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
						return at ~= nil and ((at.Position - middle) * Vector3.new(1, 0, 1)).Magnitude <= TowerConfig.Ring
					end)
					t.Check("Retry sets the avatar in its ring, the results closed", inRing and Screen.Current() ~= TowerScreen.Name)
					t.Check("and the next run begins once rested", waitFor(t, TowerConfig.Rest + 3, function()
						return me:GetAttribute("Tower") == 1
					end))
					t.Server("TowerEnd")
					-- Put back: the record, the Credits and the chests the case won.
					waitFor(t, 3, function()
						return Screen.Current() == TowerScreen.Name
					end)
					if Screen.Current() == TowerScreen.Name then
						Screen.Close()
					end
					task.wait(0.3)
					t.Server("TowerBest", best0)
					t.Server("DataCredits", credits0 - view().Currency.Credits)
					for id, count in granted() do
						t.Server("ChestGive", id, -count)
					end
					t.Server("LeadHeal")
					t.Check("the save as it was", view().Progress.Tower.Best == best0 and view().Currency.Credits == credits0 and next(granted()) == nil)
				end)
				for bay, id in working do
					t.Check(`bay {bay}'s worker back at work`, t.Server("Act", "SetWorker", { Bay = bay, Voidkin = id }).Ok == true)
				end
				t.Server("Tune", "Tower.Lift.Attack", attack)
				if not ok then
					error(problem, 0)
				end
			end,
		},
	}
end

return TowerCases
