--!strict
-- The Tower's case (TR29, AR56): a run from the gate's door, in the player's own room far from the map; each floor's foe
-- a Voidkin of the pool at its floor's level, in its enemy look, for this player alone; floors won through the fight
-- itself or Studio's TowerWin, each written to the run's ledger once with Rules.Tower's own reward; no heal between floors
-- and at most the cap in one; the lead, its stars and its Regalia frozen; the room's slab showing the floor and the next,
-- its foe's steps risen at a rise and down in the fight; the lead's fall ending the run at its last floor won, the ledger
-- granted once, the record on the gate's slab and the results, which open once and clear when closed, the avatar set down
-- before its gate and the room gone. Then a walk out of the room, set back and asked, Stay, the HUD's Leave ending the
-- run at its last floor won (TR67), and a crash's run ended at the next join. The
-- results' Home and Retry (TR46): Home sets the avatar down at its plot's spawn, Retry in its gate's door, where the next
-- run begins once rested. The heal cap told once, under the lead's
-- corner, and never again; the week's line on the results, its board a tap away and back (TR46). The case's record,
-- Credits and chests are put back at its end.

local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local TowerConfig = require(Shared.Config.Tower)
local ChestRows = require(Shared.Definitions.Chests)
local Profile = require(Shared.Data.Profile)
local Markers = require(Shared.World.Markers)
local Tower = require(Shared.Rules.Tower)
local ProfileController = require(script.Parent.Parent.ProfileController)
local TowerRoomController = require(script.Parent.Parent.Parent.Main.TowerRoomController)
local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local TowerController = require(script.Parent.Parent.Parent.Main.TowerController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Screen = require(UI.Kit.Screen)
local Button = require(UI.Kit.Button)
local TowerScreen = require(UI.TowerScreen)
local Theme = require(UI.Theme)
local Layers = require(UI.Layers)

local TowerCases = {}

-- Whether `part` shows inside `top`: it and every frame between them visible.
local function seen(part: Instance?, top: Instance): boolean
	local at = part
	while at ~= nil and at ~= top do
		if at:IsA("GuiObject") and not at.Visible then
			return false
		end
		at = at.Parent
	end
	return at == top
end

-- The children of `parent` (offsets only, as the Tower's card lays them) that end outside a `box` from its top left.
local function outside(parent: Instance, box: Vector2): { string }
	local out = {}
	for _, each in parent:GetChildren() do
		if each:IsA("GuiObject") and each.Visible then
			local p, s = each.Position, each.Size
			local right, foot = p.X.Offset + s.X.Offset, p.Y.Offset + s.Y.Offset
			if p.X.Offset < -0.5 or p.Y.Offset < -0.5 or right > box.X + 0.5 or foot > box.Y + 0.5 then
				table.insert(out, `{each.Name} to {math.floor(foot + 0.5)}`)
			end
		end
	end
	return out
end

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
			Name = "Tower (TR29, AR56): a run from the gate's door into its own room, floors won into the ledger, the heal cap, the freeze, the room's slab and steps, the fall, the record on the gate, the results once, leaving the room, a crash's run ended at the join; the results' Home and Retry, the heal cap told once (TR46)",
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
					-- The gate's door: the avatar set down in it starts a run, into the player's own room.
					-- The gate, its pieces streamed in round the avatar set down before it (a case before may have taken the
					-- avatar far enough away to stream them out).
					local plot = me:GetAttribute("Plot")
					local ring = if type(plot) == "number" then Markers.Find("TowerRing", { Plot = plot }) else nil
					if ring == nil then
						t.Check("the plot's gate", false, "no TowerRing")
						return
					end
					local lot = Tower.Lot(Markers.At(ring))
					local bx, bz = Tower.Before()
					t.Server("TestStandAt", (lot * CFrame.new(bx, 3, bz)).Position)
					t.Check("the plot's gate", waitFor(t, 10, function()
						return ring:FindFirstChild("GateVeil") ~= nil and ring:FindFirstChild("Record") ~= nil
					end))
					local doorX, doorZ = Tower.Door()
					local veil = ring:FindFirstChild("GateVeil") :: BasePart?
					local door = lot * CFrame.new(doorX, if veil then lot:PointToObjectSpace(veil.Position - Vector3.new(0, veil.Size.Y / 2, 0)).Y else 1.09, doorZ)
					local function inDoor(): boolean
						local root = me.Character and me.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
						local at = if root then lot:PointToObjectSpace(root.Position) else nil
						return at ~= nil and Tower.InGate(at.X, at.Y - 3, at.Z, 1)
					end
					t.Server("TestStandAt", door.Position + Vector3.new(0, 3, 0))
					t.Check("stepping into the door starts a run", waitFor(t, 3, function()
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
					-- The room: the player's own, far from the map, the avatar set down on its floor in the fade.
					local room: Model? = nil
					t.Check("the player's own room", waitFor(t, 3, function()
						room = TowerRoomController.Room()
						return room ~= nil
					end))
					local mine = 0
					for _, item in CollectionService:GetTagged("GA_TowerRoom") do
						if item:GetAttribute("For") == me.UserId then
							mine += 1
						end
					end
					t.Equal("one room for the player", mine, 1)
					local roomAt = state().Room
					t.Check("far from the map, out of its streaming", typeof(roomAt) == "Vector3" and (roomAt - Markers.At(ring).Position).Magnitude > 1024 + 200)
					local slab = if room then room:FindFirstChild("CrownSlab") :: BasePart? else nil
					local full = Tower.Beat(TowerConfig.Rise)
					local stepsUp = false
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
							local off = if root and typeof(s.Room) == "Vector3" then root.Position - s.Room else nil
							t.Check(`floor {s.Floor}: the avatar on its room's floor`, off ~= nil and math.abs(off.Y - 3) < 2 and (off * Vector3.new(1, 0, 1)).Magnitude <= 48, if off then `{off}` else "no root")
							-- The slab: one face shows the floor fought, the other the next.
							local faces = if slab then TowerRoomController.Numbers(slab) else nil
							local floorSaid, nextSaid = tostring(s.Floor), tostring(s.Floor + 1)
							t.Check(`floor {s.Floor}: the slab shows it and the next`, faces ~= nil and ((faces.Front == floorSaid and faces.Back == nextSaid) or (faces.Back == floorSaid and faces.Front == nextSaid)), if faces then `{faces.Front} / {faces.Back}` else "no slab")
							-- Once the beat's sink is over, the foe's steps wait under their places again.
							local beatStart = me:GetAttribute("TowerBeat")
							if type(beatStart) == "number" and workspace:GetServerTimeNow() - beatStart > full.Sink[2] + 0.2 then
								local steps = TowerRoomController.Steps() or {}
								local down = next(steps) ~= nil
								for _, step in full.Steps do
									down = down and math.abs((steps[step.Tag] or 0) - step.Rest) < 0.05
								end
								t.Check(`floor {s.Floor}: the foe's steps down in the fight`, down)
							end
							if caught == 1 then
								-- The floor reads once, by the room's slab: no line on the HUD says it over the slab (research's must-fix on AR56).
								t.Check("the floor read by the slab alone, no HUD line", Layers.Get("Hud"):FindFirstChild("TowerFloor") == nil)
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
								-- The heal cap told once (TR46): the account made untold, a heal far past the cap shows
								-- research's line under the lead's corner, with Config's share, and the save keeps it told;
								-- once the note has faded out, a second capped heal tells nothing. The account's own put back.
								local told0 = view().Progress.Tower.HealTold == true
								t.Server("TowerHealTold", false)
								t.Check("the account untold", waitFor(t, 2, function()
									return view().Progress.Tower.HealTold ~= true
								end))
								t.Server("TowerHurt", 0.3)
								t.Server("TowerMend", 1e6)
								local said: string? = nil
								waitFor(t, 3, function()
									said = HudController.Noted()
									return said ~= nil
								end)
								local share = `{math.floor(TowerConfig.HealCap * 100 + 0.5)}% of your lead's health`
								t.Check("the cap told: its line under the lead's corner, Config's share in it", said ~= nil and string.find(said, "Healing capped for this floor", 1, true) ~= nil and string.find(said, share, 1, true) ~= nil, said)
								t.Check("the save keeps it told", waitFor(t, 2, function()
									return view().Progress.Tower.HealTold == true
								end))
								t.Check("the note fades out on its own", waitFor(t, 8, function()
									return HudController.Noted() == nil
								end))
								t.Server("TowerHurt", 0.3)
								t.Server("TowerMend", 1e6)
								t.Wait(1)
								t.Check("told once: a second capped heal shows nothing", HudController.Noted() == nil, HudController.Noted())
								t.Server("TowerHealTold", told0)
							end
							t.Server("TowerWin")
							task.wait(0.15)
						elseif s.Phase == "Rising" or s.Phase == "Won" then
							if s.HealRoom ~= nil and s.HealRoom ~= 0 then
								t.Check(`floor {s.Floor}: no heal between floors`, false, tostring(s.HealRoom))
							end
							for _, step in full.Steps do
								local under = (TowerRoomController.Steps() or {})[step.Tag]
								if under and under > step.Rest + 1 then
									stepsUp = true
								end
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
					t.Check("the foe's steps rose in a rise", stepsUp)
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
					waitFor(t, TowerConfig.Rise + 1, function()
						return me:GetAttribute("Tower") == saved.Floor + 1
					end)
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
					t.Check("the room's gone once the avatar's out", waitFor(t, 3, function()
						return TowerRoomController.Room() == nil
					end))
					local outside = (lot * CFrame.new(bx, 0, bz)).Position
					local root = me.Character and me.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
					local fromBefore = if root then ((root.Position - outside) * Vector3.new(1, 0, 1)).Magnitude else nil
					t.Check("the fall sets the avatar down before its gate", fromBefore ~= nil and fromBefore < 6, `{fromBefore} studs`)
					-- The gate's slab shows the record, on both faces.
					-- Found again each look: streamed back in round the avatar, it's a new part.
					local best = tostring(view().Progress.Tower.Best)
					t.Check("the gate's slab shows the record, both faces", waitFor(t, 5, function()
						local record = ring:FindFirstChild("Record") :: BasePart?
						local said = if record then TowerRoomController.Numbers(record) else nil
						return said ~= nil and said.Front == best and said.Back == best
					end), best)
					-- The results open once, and clear when closed.
					t.Check("the results open", waitFor(t, 3, function()
						return Screen.Current() == TowerScreen.Name
					end))
					local parts = TowerScreen.Parts()
					local floorLine = parts.Floor
					t.Check("they say the floor", floorLine ~= nil and floorLine:IsA("TextLabel") and floorLine.Text == `Floor {results.Floor}`)
					-- The week's board (TR46): the line says the account's place and floor this week, the save's climb;
					-- a tap shows the board on the card, its title and the player's own row; a tap on it goes back.
					local climb = view().Progress.Tower.Week
					t.Check("the save keeps this week's climb, at least this run's floor", climb ~= nil and climb.Week == Tower.Week(os.time()) and climb.Floor >= results.Floor, if climb then `{climb.Week} {climb.Floor}` else "none")
					local words = parts.WeekWords :: TextLabel?
					local said = ""
					waitFor(t, 5, function()
						said = if words then words.Text else ""
						return string.find(said, "#", 1, true) ~= nil or said == Tower.WeekLine(nil)
					end)
					local rank, floorSaid = string.match(said, "^This week: #(%d+%+?) · floor (%d+)$")
					t.Check("the week's line: its place and the climb's floor", rank ~= nil and climb ~= nil and tonumber(floorSaid) == climb.Floor, said)
					t.Check("a tap on it is taken", TowerScreen.Tap("Week"))
					local board = TowerScreen.Parts().Board :: GuiObject?
					t.Check("it shows the board on the card", board ~= nil and board.Visible and board:IsDescendantOf(parts.Body))
					t.Check("the results step aside under it", not seen(parts.Week, parts.Body) and not seen(parts.Floor, parts.Body) and not seen(parts.Home, parts.Body))
					local title = TowerScreen.Parts().BoardTitle :: TextLabel?
					t.Check("titled This week's climb", title ~= nil and title.Text == "This week's climb")
					local ownRow: TextLabel? = nil
					for name, part in TowerScreen.Parts() do
						if name ~= "Floor" and string.sub(name, -5) == "Floor" and part:IsA("TextLabel") and part.TextColor3 == Theme.Colour.Ready then
							ownRow = part
						end
					end
					t.Check("the player's own row on it, in the record's colour", ownRow ~= nil and climb ~= nil and ownRow.Text == `floor {climb.Floor}`, if ownRow then ownRow.Text else "none")
					t.Check("a tap on the board goes back to the results", TowerScreen.Tap("Board") and board ~= nil and not board.Visible and Screen.Current() == TowerScreen.Name)
					t.Check("the results stand again", seen(parts.Week, parts.Body) and seen(parts.Floor, parts.Body) and seen(parts.Home, parts.Body))
					-- Home (TR46): set down at the plot's spawn, free, and the results closed.
					local home = parts.Home
					t.Check("in the base, Retry and Home, no Close", home ~= nil and parts.Retry ~= nil and parts.Close == nil)
					if home and home:IsA("TextButton") then
						Button.Press(home)
					end
					t.Check("closed, they're cleared from the save", waitFor(t, 3, function()
						return view().Progress.Tower.Results == nil
					end))
					-- The server moves the avatar before it answers; the client sees the move a moment later (a run once read it first).
					local spawn = Markers.Find("Spawn", { Plot = plot })
					local fromSpawn: number? = nil
					local pressed = os.clock()
					local landed = waitFor(t, 2, function(): boolean
						local root = me.Character and me.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
						fromSpawn = if spawn and root then ((root.Position - Markers.At(spawn).Position) * Vector3.new(1, 0, 1)).Magnitude else nil
						return fromSpawn ~= nil and fromSpawn < 6
					end)
					t.Check("Home sets the avatar down at its plot's spawn", landed, `{fromSpawn} studs, seen after {string.format("%.2f", os.clock() - pressed)} s`)
					-- A Home pressed in the fall's fade once came undone: the set-down beside the ring, asked first, landed after it.
					local race = t.Server("MoveRace", 30)
					t.Check("a move made while a faded one waits wins over it", type(race) == "table" and race.Ok == true and race.Off < 1, if type(race) == "table" then tostring(race.Off or race.Error) else "no answer")
					task.wait(0.5)
					t.Check("and don't open again", Screen.Current() ~= TowerScreen.Name)
					-- A walk out of the room never ends a run unasked (TR67): the avatar is set back on its floor and asked; Stay
					-- keeps the run, and the HUD's Leave, asked and answered, ends it at its last floor won, with what it won.
					t.Server("LeadHeal")
					local again = t.Server("TowerStart")
					t.Check("another run", type(again) == "table" and again.Ok == true, tostring(again and again.Error))
					waitFor(t, TowerConfig.Rise + 2, function()
						return state().Phase == "Fighting"
					end)
					t.Server("TowerWin")
					t.Check("a floor won before the leave", waitFor(t, TowerConfig.Rise + 4, function()
						local held = view().Progress.Tower.Run
						return held ~= nil and held.Floor >= 1 and state().Phase == "Fighting"
					end))
					t.Server("TowerOff")
					t.Check("a walk out of the room asks whether to leave", waitFor(t, 3, function()
						return Screen.Current() == TowerScreen.AskName
					end), tostring(Screen.Current()))
					local middle = state().Room
					local avatar = me.Character and me.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
					local off = if middle and avatar then avatar.Position - middle else Vector3.new(1e4, 0, 0)
					t.Check("and sets the avatar back in its room, the run going on", me:GetAttribute("Tower") ~= nil and view().Progress.Tower.Run ~= nil
						and not Tower.Left(off.X, 0, off.Z), string.format("%.1f studs from its middle", (off * Vector3.new(1, 0, 1)).Magnitude))
					local stay = TowerScreen.Parts().Stay :: TextButton?
					t.Check("Stay keeps the run", stay ~= nil and Button.Press(stay) ~= false and waitFor(t, 2, function(): boolean
						return Screen.Current() == nil
					end) and me:GetAttribute("Tower") ~= nil and view().Progress.Tower.Run ~= nil)
					local leave = TowerController.Parts().Leave :: TextButton?
					t.Check("the HUD's Leave shows during a run", leave ~= nil and leave.Visible)
					local held = view().Progress.Tower.Run
					local wonBefore = if held then held.Floor else -1
					t.Check("its press asks first", leave ~= nil and Button.Press(leave) ~= false and Screen.Current() == TowerScreen.AskName, tostring(Screen.Current()))
					local line = TowerScreen.Parts().AskLine :: TextLabel?
					t.Check("saying where the run ends", line ~= nil and line.Text == TowerScreen.AskLine(wonBefore), if line then line.Text else "no line")
					local yes = TowerScreen.Parts().Leave :: TextButton?
					t.Check("Leave ends the run at its last floor won", yes ~= nil and Button.Press(yes) ~= false and waitFor(t, 3, function(): boolean
						local results = view().Progress.Tower.Results
						return me:GetAttribute("Tower") == nil and view().Progress.Tower.Run == nil and results ~= nil and results.Floor == wonBefore
					end), `{wonBefore} won before`)
					t.Check("the HUD's Leave hides out of a run", leave == nil or not leave.Visible)
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
					waitFor(t, TowerConfig.Rise + 2, function()
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
					-- Retry (TR46), on the crash's results: set in the gate's door, and the next run begins once the rest is up.
					t.Check("the crash's results open", waitFor(t, 3, function()
						return Screen.Current() == TowerScreen.Name
					end))
					t.Server("LeadHeal")
					local retry = TowerScreen.Parts().Retry
					if retry and retry:IsA("TextButton") then
						Button.Press(retry)
					end
					-- Rested already, the door takes it in at once: only the door starts a run, so a run begun counts.
					local inGate = waitFor(t, 3, function(): boolean
						return inDoor() or me:GetAttribute("Tower") == 1
					end)
					t.Check("Retry sets the avatar in its gate's door, the results closed", inGate and Screen.Current() ~= TowerScreen.Name)
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
		{
			-- Research's launch bug 1 (2026-11-27): a run mostly ends in a fall, and Retry, refused while the lead heals, said
			-- nothing. A refused press says why, with the heal's time when the server gives it, and the results stay open.
			Name = "Tower card: a refused Retry says why, with the time the lead heals in",
			Place = "Main",
			Run = function(t: any)
				local refusal: { [string]: any } = { Ok = false, Error = "NoLead", Time = "1:05" }
				local function answer(): { [string]: any }
					return { Ok = true }
				end
				local on = {
					Act = answer,
					Retry = function(): { [string]: any }
						return refusal
					end,
					Home = answer,
					Board = function(): { [string]: any }
						return { Ok = true, Week = 0, Rows = {}, Mine = nil }
					end,
				}
				local ok, problem = pcall(function()
					TowerScreen.Open({ Id = "selftest-refused", Floor = 4, Best = 130, Record = false, Credits = 100, Chests = {} } :: any, on)
					task.wait()
					local retry = TowerScreen.Parts().Retry
					if retry and retry:IsA("TextButton") then
						Button.Press(retry)
					end
					t.Equal("healing: said with its time", TowerScreen.Said() or "nothing", "Still healing at base. Ready in 1:05.")
					t.Check("the results still open", Screen.Current() == TowerScreen.Name)
					refusal = { Ok = false, Error = "NoLead" }
					if retry and retry:IsA("TextButton") then
						Button.Press(retry)
					end
					t.Equal("no time given: the plain words", TowerScreen.Said() or "nothing", "Wait for your lead to heal")
				end)
				if Screen.Current() == TowerScreen.Name then
					Screen.Close()
				end
				if not ok then
					error(problem, 0)
				end
			end,
		},
		{
			-- TR46: the week's line made the card taller than a phone's room. Laid out from the room it was fitted to, its
			-- rows close up, and past that its lines scroll; the board's rows close up too. Opened on its own, with the
			-- results and the board answered here, never the save's or the store's.
			Name = "Tower card (TR46): the results and the week's board inside the card's body, in this window and on the smallest phone, one chest and three, the fullest board",
			Place = "Main",
			Run = function(t: any)
				local ids = {}
				for id in ChestRows.ById do
					table.insert(ids, id)
				end
				table.sort(ids)
				local rows = {}
				for rank = 1, TowerConfig.Board.Shown do
					table.insert(rows, { Rank = rank, Name = if rank == 2 then string.rep("W", 20) else `Climber{rank}`, Floor = 400 - rank, Mine = false })
				end
				local function answer(): { [string]: any }
					return { Ok = true }
				end
				local on = {
					Act = answer,
					Retry = answer,
					Home = answer,
					Board = function(): { [string]: any }
						return { Ok = true, Week = 0, Rows = rows, Mine = { Rank = 57, Floor = 123 } }
					end,
				}
				local ok, problem = pcall(function()
					for _, room in { "this window", "the smallest phone" } do
						if room == "the smallest phone" then
							Layers.Force(Theme.Scale.Floor)
							Layers.Box(Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height))
							t.Wait(0.2)
						end
						for _, count in { 1, 3 } do
							local chests = {}
							for index = 1, count do
								chests[ids[index]] = index * 7
							end
							local where = `{room}, {count} {if count == 1 then "chest" else "chests"}`
							-- Opened and read in one go: a change to the save would close a card it doesn't hold.
							TowerScreen.Open({ Id = `selftest-card-{room}-{count}`, Floor = 123, Best = 130, Record = false, Credits = 123456, Chests = chests }, on)
							local parts = TowerScreen.Parts()
							local body = parts.Body :: Frame
							local panel = body.Parent :: Frame
							local box = Vector2.new(panel.Size.X.Offset - Theme.Size.Pad * 4, panel.Size.Y.Offset - Screen.Head - Theme.Size.Pad)
							local out = outside(body, box)
							t.Check(`{where}: the results inside the body`, #out == 0, if #out == 0 then `{math.floor(box.Y)} high` else table.concat(out, ", "))
							local list = parts.Lines :: ScrollingFrame?
							local week = parts.Week :: GuiObject
							if list then
								t.Check(`{where}: past the closed-up rows, the lines scroll to the week's`, week.Position.Y.Offset + week.Size.Y.Offset <= list.CanvasSize.Y.Offset + 0.5 and list.CanvasSize.Y.Offset > list.Size.Y.Offset, `canvas {list.CanvasSize.Y.Offset}, window {list.Size.Y.Offset}`)
							end
							t.Row(`{where}: a row, authored px`, nil, nil, (parts.Record :: GuiObject).Size.Y.Offset, if list then "scrolls" else "")
							t.Check(`{where}: the week's line answered`, (parts.WeekWords :: TextLabel).Text == "This week: #57 · floor 123")
							t.Check(`{where}: its board opens`, TowerScreen.Tap("Week") and seen(parts.Board, body))
							local board = parts.Board :: GuiObject
							local held = outside(board, Vector2.new(board.Size.X.Offset, board.Size.Y.Offset))
							t.Check(`{where}: the board's ten, its own row and its title inside it`, #held == 0 and board.Size.Y.Offset <= box.Y + 0.5, table.concat(held, ", "))
							local mine = parts.MineRank :: TextLabel?
							t.Check(`{where}: its own row under the ten`, mine ~= nil and mine.Text == "#57" and (parts.Row10Rank :: TextLabel?) ~= nil)
							t.Check(`{where}: back to the results`, TowerScreen.Tap("Board") and not board.Visible and seen(parts.Home, body))
							Screen.Close()
							t.Wait(0.4)
						end
					end
				end)
				Layers.Box(nil)
				Layers.Force(nil)
				if Screen.Current() == TowerScreen.Name then
					Screen.Close()
				end
				if not ok then
					error(problem, 0)
				end
			end,
		},
	}
end

return TowerCases
