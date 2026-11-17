--!strict
-- KitCases (client, Studio only): a Voidkin's kit in play, a list of its own that joins Cases in the runner, as the
-- Tower's does (Cases is at the type checker's limit). AR11's install: Watt's Ground Wire, its stop, its held pose and its
-- shield, through the replay. AR26's spacing: a lead stands off a bigger Shade by its depth.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Actions = require(Shared.Definitions.Actions)
local Enemies = require(Shared.Definitions.Enemies)
local Combat = require(Shared.Config.Combat)
local FighterController = require(script.Parent.Parent.Parent.Main.FighterController)
local ProfileController = require(script.Parent.Parent.ProfileController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Read = require(UI.Read)

local KitCases = {}

local LEAD_SETTLE = 1.5 -- seconds for the lead to catch up after the reset's teleport, as Cases'
local REPLAY_PAUSE = 5 -- seconds past the action before a second press, longer than the case waits, as Cases'

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

-- This player's lead's body, or nil.
local function myLead(): Model?
	local fighters = workspace:FindFirstChild("Fighters")
	for _, model in (if fighters then fighters:GetChildren() else {}) do
		if model:IsA("Model") and model:GetAttribute("Side") == "Lead" and model:GetAttribute("Owner") == Players.LocalPlayer.UserId then
			return model
		end
	end
	return nil
end

-- How far a rig's face stands before its root, read on this client: its visible torso's (`<Rig>_Torso`) nearest face along
-- its root's facing, as the server reads it (FightService, frontOf). Nil without one.
local function frontOf(model: Model): number?
	local root = model:FindFirstChild("HumanoidRootPart")
	local torso: BasePart? = nil
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") and string.sub(part.Name, -6) == "_Torso" then
			torso = part
		end
	end
	if torso == nil or not (root and root:IsA("BasePart")) then
		return nil
	end
	local placed = root.CFrame:ToObjectSpace(torso.CFrame)
	local half = torso.Size / 2
	local front = -math.huge
	for _, x in { -1, 1 } do
		for _, y in { -1, 1 } do
			for _, z in { -1, 1 } do
				front = math.max(front, -(placed * Vector3.new(x * half.X, y * half.Y, z * half.Z)).Z)
			end
		end
	end
	return front
end

function KitCases.Cases(): { any }
	return {
		{
			-- AR26's spacing (Modulo's ask, approved for research 2026-11-17): a lead stands off its target by the target's own
			-- depth, its torso's face before its root past an ordinary Shade's (FightService, Fighter.Depth), so a touch placed
			-- for the ordinary Shade meets a bigger body's surface. Read here from the bodies as this client sees them, never
			-- from a number: the elite is the ordinary Shade at its Scale, the Lamplighter its own rig. The replay stands the
			-- lead off as a fight does.
			Name = "Fight: a lead stands off a bigger Shade by its depth, read from its own torso (AR26's spacing)",
			Run = function(t: any)
				local lead = myLead()
				local def = if lead then lead:GetAttribute("Def") else nil
				if type(def) ~= "string" then
					t.Check("the lead is in the world", false)
					return
				end
				local action: any = nil
				for _, one in Actions.KitOf(def) do
					if action == nil and one.Cooldown == 0 and one.Range > 0 then
						action = one
					end
				end
				if action == nil then
					t.Check(`{def} has a basic attack`, false)
					return
				end
				local fronts: { [string]: number } = {}
				for _, foe in { "brawler", "brawler_elite", "lamplighter" } do
					local started = t.Server("Replay", action.Id, action.Length + REPLAY_PAUSE, foe)
					t.Check(`{foe}: the replay starts on it`, type(started) == "table" and started.Ok == true, tostring(type(started) == "table" and started.Error))
					if type(started) ~= "table" or started.Ok ~= true then
						continue
					end
					local body: Model? = nil
					waitFor(t, 6, function(): boolean
						local fighters = workspace:FindFirstChild("Fighters")
						for _, model in (if fighters then fighters:GetChildren() else {}) do
							if model:IsA("Model") and model:GetAttribute("Def") == foe and frontOf(model) ~= nil then
								body = model
							end
						end
						return body ~= nil
					end)
					local front = if body then frontOf(body) else nil
					local depth = if body then body:GetAttribute("Depth") else nil
					if front == nil or type(depth) ~= "number" then
						t.Check(`{foe}: its body and its depth reach this client`, false)
						continue
					end
					fronts[foe] = front
					local plain = fronts.brawler
					if foe == "brawler" then
						t.Check("the ordinary Shade's depth is none", math.abs(depth) < 0.005, string.format("%.3f", depth))
					elseif plain then
						t.Check(`{foe}: its depth is its face past the ordinary Shade's`, depth > 0 and math.abs(depth - (front - plain)) < 0.01,
							string.format("%.3f, its face %.3f before its root, the Shade's %.3f", depth, front, plain))
						local scale = Enemies.ById[foe].Scale or 1
						if Enemies.ById[foe].Rig == "Shade" then
							t.Check(`{foe}: the ordinary Shade grown by its Scale`, math.abs(depth - plain * (scale - 1)) < 0.01,
								string.format("%.3f against %.3f", depth, plain * (scale - 1)))
						end
					end
					local spot, target = started.Spot, started.Target
					if typeof(spot) == "Vector3" and typeof(target) == "Vector3" then
						local gap = Vector3.new(spot.X - target.X, 0, spot.Z - target.Z).Magnitude
						local want = action.Range - Combat.Approach + depth
						t.Check(`{foe}: the lead stands off it by its depth`, math.abs(gap - want) < 0.02, string.format("%.3f studs root to root, %.3f wanted", gap, want))
					else
						t.Check(`{foe}: the lead stands off it by its depth`, false, "no spot")
					end
				end
				t.Server("Replay")
			end,
		},
		{
			-- AR11's install: Ground Wire's pulse stops what stands round Watt for his hold, Plant to Release, never throwing it,
			-- and shields him past it (Actions.Hit.Round, Stun, Shield); a stopped body holds the pose it was stopped in until it
			-- lets go (FighterController, onState). Since the retake (research's must-fix, 2026-11-17) it's played on a brawler
			-- swinging at him on his clock (the replay's foe), so the stop meets a blow mid-swing, and his shield is an outline.
			Name = "Fight: Watt's Ground Wire stops a brawler mid-swing for his hold, its pose held, and shields him past it",
			Run = function(t: any)
				local def = "watt"
				local action = Actions.ById.WattGroundWire
				local plant = action.Hits.Plant
				local stun, shield = plant.Stun :: number, plant.Shield :: { Share: number, Seconds: number }
				local looks: { Stun: string?, Shield: string? } = plant.Looks or {} -- AR11's stop and shield, played on the bodies (Effects.Lasting)
				local swipe = Actions.ById.ShadeSwipe -- the brawler's (Definitions.Enemies)
				-- his shield's look shows: its rows ride him, or its outline is on his Highlight (Config.Effects.Outlines)
				local function shieldOn(mine: any): boolean
					if looks.Shield == nil or mine == nil then
						return false
					end
					if mine.Looks[looks.Shield] ~= nil then
						return true
					end
					local glow = mine.Glow :: Highlight?
					return mine.Outline ~= nil and mine.Outline.Name == looks.Shield and glow ~= nil and glow.Parent ~= nil and glow.Enabled
						and glow.OutlineTransparency < 1
				end
				local view = ProfileController.Get()
				local was = if view then view.Roles.Lead else nil
				local function leading(): Model?
					local found = myLead()
					return if found and found:GetAttribute("Def") == def then found else nil
				end
				local freed: { Bay: number, Id: string }? = nil -- a bay it was taken from for the run, put back after
				if leading() == nil then -- one free to lead, owned or given, or taken off its bay
					local now = ProfileController.Get()
					local id: string? = nil
					for owned, voidkin in (if now then now.Voidkin else {}) :: { [string]: any } do
						if voidkin.Def == def and Read.Role(now :: any, owned) == "" then
							id = owned
							break
						end
					end
					for bay, slot in (if id == nil and now then now.Base.Bays else {}) :: { any } do
						local working = if now then now.Voidkin[slot.Worker] else nil
						if working and working.Def == def then
							local off = t.Server("Act", "SetWorker", { Bay = bay, Voidkin = "" })
							if type(off) == "table" and off.Ok == true then
								freed = { Bay = bay, Id = slot.Worker }
								id = slot.Worker
								waitFor(t, 2, function(): boolean
									local latest = ProfileController.Get()
									return latest ~= nil and Read.Role(latest :: any, slot.Worker) == ""
								end)
							end
							break
						end
					end
					if id == nil then
						local given = t.Server("VoidkinGive", def)
						local newId = if type(given) == "table" and given.Ok == true then given.Id else nil
						local arrived = type(newId) == "string" and waitFor(t, 2, function(): boolean
							local latest = ProfileController.Get()
							return latest ~= nil and latest.Voidkin[newId] ~= nil
						end)
						if arrived then
							id = newId
						end
					end
					if id then
						t.Server("Act", "SetLead", { Voidkin = id })
					end
				end
				waitFor(t, LEAD_SETTLE * 2, function(): boolean
					return leading() ~= nil
				end)
				local lead = leading()
				local function restore()
					if was then
						t.Server("Act", "SetLead", { Voidkin = was })
					end
					if freed then
						t.Server("Act", "SetWorker", { Bay = freed.Bay, Voidkin = freed.Id })
					end
				end
				t.Check("Watt leads", lead ~= nil)
				if lead == nil then
					restore()
					return
				end
				local struck: Model? = nil
				local swungAt: number? = nil -- server time, the brawler's swipe pressed before the Plant
				local blows = 0 -- its swipes landed on Watt
				local onHit = Net.Client.On("Hit", function(hit: any)
					if type(hit) == "table" and hit.A == lead and hit.Action == action.Id and hit.Beat == "Plant" and typeof(hit.T) == "Instance" then
						struck = hit.T
					elseif type(hit) == "table" and hit.T == lead and hit.Action == swipe.Id then
						blows += 1
					end
				end)
				local fighters = workspace:FindFirstChild("Fighters")
				local watched: { RBXScriptConnection } = {}
				local function watchSwing(model: Instance)
					if model:IsA("Model") then -- the replay's brawler, as it arrives
						table.insert(watched, model:GetAttributeChangedSignal("ActionAt"):Connect(function()
							local at = model:GetAttribute("ActionAt")
							if swungAt == nil and model:GetAttribute("Def") == "brawler" and model:GetAttribute("Action") == swipe.Id and type(at) == "number" then
								swungAt = at
							end
						end))
					end
				end
				if fighters then
					table.insert(watched, fighters.ChildAdded:Connect(watchSwing))
				end
				local pressed: number? = nil -- server time, the press's own (the action's end moves ActionAt)
				local onPress = lead:GetAttributeChangedSignal("ActionAt"):Connect(function()
					local at = lead:GetAttribute("ActionAt")
					if pressed == nil and lead:GetAttribute("Action") == action.Id and type(at) == "number" then
						pressed = at
					end
				end)
				local started = t.Server("Replay", action.Id, action.Length + REPLAY_PAUSE, "brawler")
				local ok = type(started) == "table" and started.Ok == true
				t.Check("the replay presses Ground Wire at a brawler", ok, if type(started) == "table" then tostring(started.Error) else tostring(started))
				local stoppedUntil: number? = nil -- server time
				local stoppedAt: Vector3? = nil
				local held, heldWhen = false, false
				local letGo: number? = nil -- server time
				local drift = 0
				local stopWorn, shieldWorn = false, false
				local stopFoot: number? = nil -- studs from the floor to the stop's ring's foot, mid-stop
				local began = os.clock()
				while ok and os.clock() - began < action.Length + 1.5 do
					RunService.Heartbeat:Wait()
					local body = struck
					local root = if body then body:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
					if body == nil or root == nil then
						continue
					end
					local state = body:GetAttribute("State")
					if state == "Stun" then
						if stoppedUntil == nil then
							local untilTime = body:GetAttribute("StateUntil")
							stoppedUntil = if type(untilTime) == "number" then untilTime else nil
							stoppedAt = root.Position
						end
						drift = math.max(drift, (root.Position - (stoppedAt :: Vector3)).Magnitude)
						local shown = (FighterController.Views :: any)[body]
						local left = if stoppedUntil then stoppedUntil - workspace:GetServerTimeNow() else 0
						if shown and left > 0.3 and left < stun - 0.3 then -- its middle: held, the hit's own hold long over
							heldWhen = true
							held = shown.Rate == 0
							local stop = if looks.Stun then shown.Looks[looks.Stun] else nil
							stopWorn = stop ~= nil
							local leadRoot = lead:FindFirstChild("HumanoidRootPart") :: BasePart?
							for _, made in if stop and leadRoot then stop.Parts("Lock") else {} do
								if made:IsA("BasePart") and made.Size.Y > 0.1 then -- the ring, not its carrier
									stopFoot = (made.Position.Y - made.Size.Y / 2) - (leadRoot :: BasePart).Position.Y + 3 -- his R6 foot: the pad's floor
								end
							end
							local mine = (FighterController.Views :: any)[lead]
							shieldWorn = shieldOn(mine)
						end
					elseif stoppedUntil and letGo == nil then
						letGo = workspace:GetServerTimeNow()
						break
					end
				end
				onHit:Disconnect()
				onPress:Disconnect()
				for _, connection in watched do
					connection:Disconnect()
				end
				-- the stop's look goes with its stun, at once; the shield's stays to its own end
				local stopGone: boolean? = nil
				local afterStop = os.clock()
				while letGo and os.clock() - afterStop < 0.2 do
					RunService.Heartbeat:Wait()
					local shown = if struck then (FighterController.Views :: any)[struck] else nil
					stopGone = shown == nil or shown.Looks[looks.Stun] == nil
					if stopGone then
						break
					end
				end
				local mine = (FighterController.Views :: any)[lead]
				local shieldStays = shieldOn(mine)
				local shieldEnd = lead:GetAttribute("ShieldUntil")
				local shieldGone: boolean? = nil
				local shieldEarly = false
				while type(shieldEnd) == "number" and workspace:GetServerTimeNow() < shieldEnd + 0.25 do
					RunService.Heartbeat:Wait()
					shieldGone = not shieldOn(mine)
					if shieldGone and workspace:GetServerTimeNow() < shieldEnd - 0.1 then
						shieldEarly = true
					end
					if shieldGone and workspace:GetServerTimeNow() >= shieldEnd then
						break
					end
				end
				t.Server("Replay")
				local plantAt = if pressed then pressed + action.Beats.Plant else nil
				t.Check("pressed", pressed ~= nil)
				t.Check("the Plant lands on the brawler", struck ~= nil and struck:GetAttribute("Def") == "brawler")
				t.Check("it's stopped", stoppedUntil ~= nil)
				-- mid-swing: its swipe pressed before the Plant and short of its blow there, which never lands
				local swung = if swungAt and plantAt then plantAt - swungAt else nil
				t.Check("stopped mid-swing, its blow not yet landed", swung ~= nil and swung > 0 and swung < swipe.Beats.Hit,
					if swung then string.format("%.2f s into its swing, its blow at %.2f", swung, swipe.Beats.Hit) else "no swing seen")
				t.Check("and its blow never lands on him", blows == 0, `{blows} landed`)
				if stoppedUntil and plantAt then
					local off = stoppedUntil - (plantAt + stun)
					t.Check("for his hold, Plant to Release", math.abs(off) <= 0.1, string.format("%+.3f s against the Plant's time plus %.2f", off, stun))
				end
				t.Check("its pose held in the middle of it", heldWhen and held, if heldWhen then (if held then "held" else "still playing") else "never watched mid-stop")
				t.Check("never thrown while stopped", drift <= 0.3, string.format("%.2f studs", drift))
				if letGo and stoppedUntil then
					local late = letGo - stoppedUntil
					t.Check("and let go when it ends", late >= -0.05 and late <= 0.35, string.format("%+.2f s", late))
				else
					t.Check("and let go when it ends", false, "still stopped")
				end
				local shieldUntil = lead:GetAttribute("ShieldUntil")
				if type(shieldUntil) == "number" and plantAt then
					local off = shieldUntil - (plantAt + shield.Seconds)
					t.Check("his shield from the Plant, past the stop", math.abs(off) <= 0.1, string.format("%+.3f s", off))
				else
					t.Check("his shield from the Plant, past the stop", false, "no shield")
				end
				t.Check("the stop's look on the brawler mid-stop", stopWorn, tostring(looks.Stun))
				t.Check("its ring on the floor at its foot, not under it", stopFoot ~= nil and math.abs(stopFoot :: number) <= 0.15, if stopFoot then string.format("%+.2f studs", stopFoot) else "no ring")
				t.Check("and gone within 0.2 s of its stun's end", stopGone == true, tostring(stopGone))
				t.Check("the shield's look on him mid-stop", shieldWorn, tostring(looks.Shield))
				t.Check("still on him as the stop ends", shieldStays)
				t.Check("and gone at the shield's end, never before", shieldGone == true and not shieldEarly, `gone {shieldGone}, early {shieldEarly}`)
				restore()
			end,
		},
	}
end

return KitCases
