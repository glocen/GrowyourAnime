--!strict
-- ShadeCases (client, Studio only): AR52's Guard and Dasher in a fight, a list of their own beside Cases, which joins it
-- as it joins SignatureCases (Cases is at what the type solver checks in one piece). Each spawns its Shade on the lead
-- through FightSpawn and plays it on the server's own paths (FightService, SlamService):
-- * the Guard raises its shield in the fight, standing to Drop; the lead's hits glance off it (its signature held, Auto
--   off, so it can't break the raise first), each a GuardGlance where the blow meets it; the lead's signature into a
--   raise breaks it open, the shield gone at once, a GuardBreak there, and the Guard staggered;
-- * the Dasher's line goes down from its feet through the lead, reaching the end on the hit; under A, a lead
--   that stays is hit and the Dasher runs on through it and lies there, its back to it, and an avatar that walks off takes its lead off the line and
--   the lunge hits empty stone, each counted under "Lunge A". The switch and Auto are put back at their ends.
-- * AR57: each elite swings Attack every time (AR2, section 10), wears its own mask twice and no other, and the Guard's
--   and the Dasher's play their own raise and lunge (Config.Animations.Kinds), never their kin's.
-- * AR58: a Support behind a Brawler of its pack: whole, the Brawler takes its shield for Shield.Seconds, the grey ball
--   round it to then; hurt, the Brawler is mended by Heal of its most, a grey pop on it; between casts it stands further
--   from the lead than the Brawler; with the Brawler down, it swings at the lead.
-- The shield and the line are their actions' rows (GuardShield, DasherLine), each checked drawn; while an action's rows
-- aren't written, or Config.Effects.Grey says, its grey stand-in is checked instead (SlamController).
-- * TR69 E, Hard changes behaviour: two Hard Guards on the lead raise in turn, never together; a Hard Dasher lunges twice
--   in a run; two Normal Dashers never have two marked strikes in flight on the lead at once (Config.Combat.Turns.Marks).
-- Their rules' own cases are the logic cases' (Cases/Shades, Cases/Support).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Combat = require(Shared.Config.Combat)
local EffectsConfig = require(Shared.Config.Effects)
local Actions = require(Shared.Definitions.Actions)
local Enemies = require(Shared.Definitions.Enemies)
local FightRule = require(Shared.Rules.Fight)
local MarkRule = require(Shared.Rules.Mark)
local Parts = require(Shared.Util.Parts)
local SlamController = require(script.Parent.Parent.Parent.Main.SlamController)
local FighterController = require(script.Parent.Parent.Parent.Main.FighterController)
local TapMoveController = require(script.Parent.Parent.Parent.Main.TapMoveController)
local Helpers = require(script.Parent.Helpers)

local ShadeCases = {}

-- AR52: whether `action`'s grey stand-in draws (SlamController's own reading of it), so a case checks what is drawn.
local function grey(action: string): boolean
	local def = Actions.ById[action]
	local effect = if def then def.Effect else nil
	return effect == nil or (EffectsConfig.Rows :: any)[effect] == nil or EffectsConfig.Grey[action] == true
end

local playing, drew = Helpers.rowsOn, Helpers.drew

-- AR52: the last look a blow on `guard`'s shield played (SlamController.Struck) is `name`, its rows drawn, where the blow
-- meets the shield (Config.Effects.Shield from its root, at its scale), its Front level along the ground.
local function met(t: any, guard: Model, what: string, name: string, rows: { string })
	local look: any = SlamController.Struck()
	t.Equal(`{what} plays its look`, if look then look.Name else "none", name)
	if look == nil or look.Name ~= name then
		return
	end
	t.Check(`{what}: its rows drawn`, drew(look.Rows, rows))
	local root = guard:FindFirstChild("HumanoidRootPart") :: BasePart?
	local meets, k = EffectsConfig.Shield, guard:GetScale()
	local off = if root then (look.Anchor.Position - root.Position).Magnitude else -1
	t.Near(`{what}: where the blow meets the shield (studs from its root)`, off, math.sqrt(meets.Up ^ 2 + meets.Ahead ^ 2) * k, 0.75)
	t.Check(`{what}: its front level, along the blow`, math.abs(look.Anchor.LookVector.Y) < 0.01, string.format("%.3f up", look.Anchor.LookVector.Y))
end

local REPLICATE = 2 -- seconds for an attribute or a remote to reach the client
local RAISES = 3 -- raises the Guard case waits through for a glance
-- and for a break: the lead fires its signature only once its swing ends, so a Haymaker can start too late to land
-- inside a raise (one began 0.75 s after the raise dropped, 2026-11-24); each raise is another try
local BREAK_RAISES = 6
local LUNGE_SOON = 6 -- seconds a ready Dasher may take to come into range and put its line down
local WALK = 7 -- studs the avatar walks off the line
local WATCH = 14 -- seconds an elite is watched for three swings and its own clip (its signature's cooldown is 4.8 or 6)
local PACK = "SelfTest" -- the pack a Support case's two Shades share (FightSpawn's pack)
local HURT = 0.6 -- the Brawler's share of its health for the Support's mend: under Combat.Support.Below
local HARD_WATCH = 14 -- seconds Hard's Shades are watched (TR69 E): a Guard's raise is 2.7 s of a 4.8 s cooldown, a lunge 2.3

type Start = { Id: string, At: number, End: number } -- server time; End math.huge while it runs
type Watched = { Model: Model, Starts: { Start } }
-- each elite: its def, its own clip in place of its kin's and that kin's ("" for none)
local ELITES = {
	{ "brawler_elite", "", "" },
	{ "guard_elite", "ShadeGuardElite", "ShadeGuard" },
	{ "dasher_elite", "ShadeLungeElite", "ShadeLunge" },
}

local player = Players.LocalPlayer

local function fighterModel(id: any): Model?
	local fighters = workspace:FindFirstChild("Fighters")
	for _, model in (if fighters then fighters:GetChildren() else {}) do
		if model:IsA("Model") and model:GetAttribute("Fighter") == id then
			return model
		end
	end
	return nil
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function now(): number
	return workspace:GetServerTimeNow()
end

-- Cases' own helpers and measures, one home each.
export type Given = {
	LEAD_SETTLE: number,
	SHADE_AHEAD: number,
	SHADE_TOUGHER: number,
	SHADE_TIMEOUT: number,
	waitFor: (t: any, seconds: number, ok: () -> boolean) -> boolean,
	myLead: () -> Model?,
}

function ShadeCases.Cases(given: Given): { any }
	local LEAD_SETTLE, SHADE_AHEAD, SHADE_TOUGHER, SHADE_TIMEOUT = given.LEAD_SETTLE, given.SHADE_AHEAD, given.SHADE_TOUGHER, given.SHADE_TIMEOUT
	local waitFor, myLead = given.waitFor, given.myLead

	-- The player's lead whole and out of any fight, and a Shade of `def` coming for it, tough enough to last; in `pack`, when
	-- given.
	local function begin(t: any, def: string, pack: string?): (Model?, Model?)
		t.Server("LeadHeal")
		t.Server("LeadCalm")
		t.Server("FightSpawn")
		t.Wait(LEAD_SETTLE)
		local lead = myLead()
		if lead == nil then
			t.Check("a lead to fight with", false)
			return nil, nil
		end
		local level = lead:GetAttribute("Level")
		local spawned = t.Server("FightSpawn", def, (if type(level) == "number" then level else 1) + SHADE_TOUGHER, SHADE_AHEAD, true, nil, nil, pack)
		t.Check(`a {def} spawns`, type(spawned) == "table" and spawned.Ok == true)
		local foe: Model? = nil
		waitFor(t, REPLICATE, function(): boolean
			foe = fighterModel(if type(spawned) == "table" then spawned.Id else nil)
			return foe ~= nil
		end)
		t.Check(`its model reaches the client`, foe ~= nil)
		t.Check("the lead takes it on", waitFor(t, SHADE_TIMEOUT, function(): boolean
			local id = lead:GetAttribute("Target")
			return type(id) == "string" and id ~= ""
		end))
		return lead, foe
	end

	return {
		{
			Name = "Shades (AR57): each elite swings Attack every time, wears its mask twice, and the Guard's and the Dasher's play their own raise and lunge",
			Run = function(t: any)
				for _, elite in ELITES do
					local def, own, kin = elite[1], elite[2], elite[3]
					local _, foe = begin(t, def)
					local animator: Animator? = nil
					waitFor(t, REPLICATE, function(): boolean
						local humanoid = if foe then foe:FindFirstChildOfClass("Humanoid") else nil
						animator = if humanoid then humanoid:FindFirstChildOfClass("Animator") else nil
						return animator ~= nil and foe ~= nil and foe:FindFirstChild("Shade_Torso") ~= nil
					end)
					if foe == nil or animator == nil then
						t.Check(`{def}: its rig reaches the client`, false)
						t.Server("FightSpawn")
						continue
					end
					-- its masks: its own, twice (the second on its Left Arm), and no other
					local mask = Enemies.ById[def].Mask
					local masks = {}
					for _, part in foe:GetChildren() do
						if part:IsA("BasePart") and (part.Name:sub(1, 5) == "Mask_" or part.Name:sub(1, 10) == "EliteMask_") then
							table.insert(masks, part.Name)
						end
					end
					table.sort(masks)
					t.Check(`{def}: wears its mask twice and no other`, #masks == 2 and masks[1] == `EliteMask_{mask}` and masks[2] == `Mask_{mask}`, table.concat(masks, ", "))
					-- the clips it starts: a track that wasn't playing a frame ago, or went back
					local swings: { string } = {}
					local played: { [string]: boolean } = {}
					local seen: { [AnimationTrack]: number } = {}
					local ends = os.clock() + WATCH
					while os.clock() < ends and foe.Parent ~= nil and (#swings < 3 or (own ~= "" and not played[own])) do
						local seenNow: { [AnimationTrack]: number } = {}
						for _, track in (animator :: Animator):GetPlayingAnimationTracks() do
							local before = seen[track]
							local name = if track.Animation then track.Animation.Name else ""
							if before == nil or track.TimePosition < before then
								played[name] = true
								if name == "ShadeAttack" or name == "ShadeAttackLeft" then
									table.insert(swings, name)
								end
							end
							seenNow[track] = track.TimePosition
						end
						seen = seenNow
						task.wait()
					end
					t.Server("FightSpawn")
					local right = #swings >= 2
					for _, name in swings do
						right = right and name == "ShadeAttack"
					end
					t.Check(`{def}: every swing is Attack`, right, table.concat(swings, ", "))
					if own ~= "" then
						t.Check(`{def}: it plays its own {own}`, played[own] == true)
						t.Check(`{def}: never its kin's {kin}`, played[kin] ~= true)
					end
				end
			end,
		},
		{
			Name = "Shades (AR52): the Guard raises its shield in the fight, its pane standing to Drop; hits glance off; a signature breaks it open, staggered",
			Run = function(t: any)
				local lead, foe = begin(t, "guard")
				if lead == nil or foe == nil then
					t.Server("FightSpawn")
					return
				end
				local guard = foe :: Model
				local raise = Actions.ById.GuardRaise
				local glanced, broke, whole = 0, 0, 0
				local onHit = Net.Client.On("Hit", function(hit: any)
					if type(hit) ~= "table" or hit.T ~= guard or hit.Dodged then
						return
					end
					if hit.Guarded == "Glanced" then
						glanced += 1
					elseif hit.Guarded == "Broke" then
						broke += 1
					else
						whole += 1
					end
				end)
				local function raised(): boolean
					local up = guard:GetAttribute("GuardUntil")
					return type(up) == "number" and now() < up
				end
				local auto = player:GetAttribute("SignatureAuto") ~= false
				Net.Client.Invoke("Signature", "Auto", false) -- its signature held: a heavy hit would break the raise
				local ok, err = pcall(function()
					-- Its raises, read until a glance is seen (a ranged lead may close in on the second).
					local first = true
					for _ = 1, RAISES do
						local up = waitFor(t, if first then SHADE_TIMEOUT else raise.Cooldown + 2, raised)
						if first then
							t.Check("it raises its shield in the fight", up)
						end
						if not up then
							break
						end
						local untilAt = guard:GetAttribute("GuardUntil") :: number
						local startedAt = guard:GetAttribute("ActionAt")
						if first and grey("GuardRaise") then
							t.Check("its grey pane stands before it", waitFor(t, 0.5, function(): boolean
								return SlamController.Pane(guard) ~= nil
							end))
						elseif first then
							t.Check("its shield's rows play from the raise (GuardShield)", waitFor(t, 0.5, function(): boolean
								return drew(playing(guard, "GuardShield"), { "Ink", "Core" }) -- the ward's rows (Scintilla's redo)
							end))
							t.Check("and no grey pane beside them", SlamController.Pane(guard) == nil)
						end
						if first then
							if type(startedAt) == "number" then
								t.Near("held to its Drop (s from the raise's start)", untilAt - startedAt, raise.Beats.Drop, 0.05)
							end
						end
						waitFor(t, raise.Beats.Drop + 1, function(): boolean
							return now() >= untilAt + 0.15
						end)
						if first and grey("GuardRaise") then
							t.Check("its pane goes at Drop", SlamController.Pane(guard) == nil)
						elseif first then
							t.Check("its shield's rows end with the raise", waitFor(t, raise.Length - raise.Beats.Drop + 0.5, function(): boolean
								return playing(guard, "GuardShield") == nil
							end))
						end
						first = false
						if glanced > 0 then
							break
						end
					end
					t.Check("the lead's hits glance off it while it's raised", glanced > 0, `{glanced} glanced, {whole} whole`)
					if glanced > 0 and not grey("GuardRaise") then
						met(t, guard, "a glance", "GuardGlance", { "GlintLine", "Skate" })
					end
					-- The break: the lead's signature into a raise, Auto on and its ring made full as the raise goes up.
					local broken = false
					local signature = FightRule.Signature(Actions.KitOf(tostring(lead:GetAttribute("Def"))))
					Net.Client.Invoke("Signature", "Auto", true)
					for _ = 1, BREAK_RAISES do
						if not waitFor(t, raise.Cooldown + 2, raised) then
							break
						end
						local before = guard:GetAttribute("GuardBroke")
						t.Server("LeadReady")
						broken = waitFor(t, raise.Beats.Drop, function(): boolean
							local now = guard:GetAttribute("GuardBroke")
							return now ~= nil and now ~= before
						end)
						if broken then
							break
						end
					end
					t.Check("the lead's signature breaks it open", broken, if signature then signature.Id else "no signature")
					if broken and grey("GuardRaise") then
						t.Check("its pane goes at once", waitFor(t, 0.3, function(): boolean
							return SlamController.Pane(guard) == nil
						end))
					elseif broken then
						t.Check("its shield's rows go at once", waitFor(t, 0.3, function(): boolean
							return playing(guard, "GuardShield") == nil
						end))
						met(t, guard, "the break", "GuardBreak", { "TearLine", "Chip1" })
					end
					if broken then
						t.Check("the breaking hit lands whole", waitFor(t, 0.5, function(): boolean
							return broke >= 1
						end))
						local stunned = waitFor(t, 0.5, function(): boolean
							return guard:GetAttribute("State") == "Stun"
						end)
						t.Check("staggered: it stands stunned", stunned)
						if stunned then
							local from = os.clock()
							waitFor(t, 4, function(): boolean
								return guard:GetAttribute("State") ~= "Stun"
							end)
							-- its Stagger, or the signature's own stun when that's longer
							local most = Combat.Guard.Stagger
							for _, hit in (if signature then signature.Hits else {}) :: { [string]: Actions.Hit } do
								most = math.max(most, hit.Stun or 0)
							end
							local took = os.clock() - from
							t.Check("for its Stagger", took >= Combat.Guard.Stagger - 0.3 and took <= most + 0.3, string.format("%.2f s (%.2f to %.2f)", took, Combat.Guard.Stagger, most))
						end
					end
				end)
				onHit:Disconnect()
				Net.Client.Invoke("Signature", "Auto", auto)
				t.Server("FightSpawn")
				if not ok then
					error(err, 0)
				end
			end,
		},
		{
			Name = "Shades (AR52): the Dasher's line goes down through the lead and fills to its end on the hit; under A, staying it hits and runs on through, walking off it hits empty stone; each counted",
			Run = function(t: any)
				local was = t.Server("Slam").Mode
				-- A's walk off the line is the rule only while tap to move is off (Config.Combat.TapMove): off for this case
				local tapWas = Combat.TapMove.On
				t.Server("Tune", "Combat.TapMove.On", false)
				t.Server("Slam", "A")
				t.Server("Slam", "Reset")
				local lead, foe = begin(t, "dasher")
				if lead == nil or foe == nil then
					t.Server("FightSpawn")
					t.Server("Slam", was)
					t.Server("Tune", "Combat.TapMove.On", tapWas)
					return
				end
				local dasher = foe :: Model
				local lunge = Actions.ById.DasherLunge
				local move = (lunge.Moves :: any).Lunge :: Actions.Move
				local line = Combat.Dasher.Line
				local struck = 0
				local onHit = Net.Client.On("Hit", function(hit: any)
					if type(hit) == "table" and hit.A == dasher and hit.T == lead and hit.Action == lunge.Id then
						struck += 1
					end
				end)
				-- One lunge: made ready, its line read as it goes down; `during` runs each frame of its tell.
				local function one(during: (() -> ())?): { [string]: any }?
					-- the lead standing in its fight first, as the Dasher's own First waits for (a lead still walking in
					-- circles to its place and steps off a line by itself)
					t.Check("the lead is in its fight", waitFor(t, SHADE_TIMEOUT, function(): boolean
						local acting = lead:GetAttribute("Action")
						return type(acting) == "string" and acting ~= ""
					end))
					-- a lunge of its own already going down (its First, as the lead takes its place) lands and is counted
					-- first, so Ready never cuts one short and each read counts its own lunge only (two counted in one read,
					-- 2026-11-24)
					waitFor(t, LUNGE_SOON, function(): boolean
						return dasher:GetAttribute("MarkSlam") == nil
					end)
					t.Wait(0.4) -- the server's count
					local prior = (t.Server("Slam").Counts or {})["Lunge A"] or {}
					t.Server("Slam", "Ready")
					local down = waitFor(t, LUNGE_SOON, function(): boolean
						return dasher:GetAttribute("MarkSlam") ~= nil
					end)
					if not down then
						return nil
					end
					local at, to = dasher:GetAttribute("MarkAt"), dasher:GetAttribute("MarkTo")
					local read: any = {
						At = at,
						To = to,
						Radius = dasher:GetAttribute("MarkRadius"),
						Down = dasher:GetAttribute("MarkDown"),
						Slam = dasher:GetAttribute("MarkSlam"),
						From = dasher:GetPivot().Position,
						Half = -1,
						Before = struck,
						Prior = prior,
					}
					if typeof(at) ~= "Vector3" or typeof(to) ~= "Vector3" then
						return read
					end
					local way = flat(to - at)
					read.Length = way.Magnitude
					read.Shape = { X = at.X, Z = at.Z, Radius = read.Radius, Length = read.Length, DirX = way.Unit.X, DirZ = way.Unit.Z }
					local leadAt = lead:GetPivot().Position
					read.LeadOn = MarkRule.Covers(read.Shape, leadAt.X, leadAt.Z)
					read.Edges, read.Fill = SlamController.Line(dasher)
					read.Rows = false
					local avatarFrom = Parts.Root(player.Character)
					local avatarAt = if avatarFrom then avatarFrom.Position else Vector3.zero
					while now() < read.Slam - 0.05 and dasher:GetAttribute("MarkSlam") ~= nil do
						-- where the lead and the avatar stand as it lands, for the checks and their detail
						local here = lead:GetPivot().Position
						read.OnAtHit = MarkRule.Covers(read.Shape, here.X, here.Z)
						local l = flat(here - at)
						read.Last = string.format(
							"the lead %.1f down, %.1f off; away %s; the avatar moved %.1f",
							l:Dot(way.Unit),
							math.abs(l:Dot(Vector3.new(-way.Unit.Z, 0, way.Unit.X))),
							tostring(lead:GetAttribute("Away")),
							if avatarFrom then flat(avatarFrom.Position - avatarAt).Magnitude else -1
						)
						read.Rows = read.Rows or drew(playing(dasher, "DasherLine"), { "Lane", "LaneNear", "LaneFar", "Fuse1", "Fuse6" })
						if read.Half < 0 and now() >= (read.Down + read.Slam) / 2 then
							local _, fill = SlamController.Line(dasher)
							read.Half = if fill then fill.Size.Z else 0
						end
						if during then
							during()
						end
						RunService.Heartbeat:Wait()
					end
					read.Gone = waitFor(t, 1, function(): boolean
						local edges = SlamController.Line(dasher)
						return dasher:GetAttribute("MarkSlam") == nil and edges == nil
					end)
					t.Wait(0.4) -- its glide's end and the server's count
					read.Went = flat(dasher:GetPivot().Position - read.From):Dot(way.Unit)
					read.LeadAlong = flat(lead:GetPivot().Position - at):Dot(way.Unit)
					local look = flat(dasher:GetPivot().LookVector)
					read.LookAfter = if look.Magnitude > 0.01 then look.Unit:Dot(way.Unit) else 0 -- inside its 0.8 s back open
					read.Hits = struck - read.Before
					-- this lunge's own counts: the server's since the reset, less what stood before its Ready
					local after = (t.Server("Slam").Counts or {})["Lunge A"]
					read.Counts = if after then {
						Slams = (after.Slams or 0) - (prior.Slams or 0),
						Hit = (after.Hit or 0) - (prior.Hit or 0),
						Missed = (after.Missed or 0) - (prior.Missed or 0),
						OnPurpose = (after.OnPurpose or 0) - (prior.OnPurpose or 0),
					} else nil
					return read
				end
				local ok, err = pcall(function()
					-- Staying: the lead fights on, on the line.
					local stay = one(nil)
					t.Check("its line goes down in the fight", stay ~= nil and typeof(stay.To) == "Vector3")
					if stay and stay.Length then
						t.Near("its tell, Line to Land (s)", stay.Slam - stay.Down, lunge.Beats.Land - lunge.Beats.Line, 0.02)
						t.Near("as long as its lunge and Past (studs)", stay.Length, (move.Most or 0) + line.Past, 0.05)
						t.Near("Half either side (studs)", stay.Radius, line.Half, 0.01)
						local gap = flat(stay.From - stay.At).Magnitude
						t.Check("from the Dasher's feet", gap < 0.75, string.format("%.2f studs off", gap))
						t.Check("through the lead", stay.LeadOn == true)
						if grey("DasherLunge") then
							t.Check("an outline of three edges, an edge wide", stay.Edges ~= nil and #stay.Edges == 3 and math.abs(stay.Edges[1].Size.X - math.min(line.Edge, line.Half)) < 0.01)
							t.Check("a fill, see-through", stay.Fill ~= nil and math.abs(stay.Fill.Transparency - line.Fill) < 0.01)
							t.Near("halfway through the tell, the fill half the line (studs)", stay.Half, (stay.Length :: number) / 2, 1.2)
						else
							t.Check("its lane and fuse play through the tell (DasherLine)", stay.Rows == true)
							t.Check("and no grey line beside them", stay.Edges == nil)
						end
						t.Check("all gone with the hit", stay.Gone == true)
						t.Check("staying, the lunge hits the lead", stay.Hits >= 1, `{stay.Hits} hits; at its hit, {stay.Last}`)
						-- on through it, never short of it; a blow of the lead's landing mid-lunge pushes it as any glide is pushed
						t.Check("and runs on through it, its back to the lead", stay.Went > stay.LeadAlong, string.format("went %.1f studs, the lead %.1f down the line", stay.Went, stay.LeadAlong))
						t.Check("its back open: still facing down its line, its back to the lead", stay.LookAfter > 0.9, string.format("its look along the line %.2f", stay.LookAfter))
						t.Row("the lunge's travel through the lead (studs; its Most unless a blow pushed it)", nil, move.Most, stay.Went, "")
						local tally = stay.Counts
						t.Check("counted under Lunge A: hit", tally ~= nil and tally.Slams == 1 and tally.Hit == 1, if tally then `{tally.Slams} lunges, {tally.Hit} hit` else "none")
					end
					-- Walking off: the avatar leaves the line, its lead with it.
					local followed, walked = false, false
					local off = one(function()
						local root = Parts.Root(player.Character)
						local humanoid = Parts.Humanoid(player.Character)
						local at, to = dasher:GetAttribute("MarkAt"), dasher:GetAttribute("MarkTo")
						if not walked and root and humanoid and typeof(at) == "Vector3" and typeof(to) == "Vector3" then
							walked = true
							local way = flat(to - at).Unit
							local side = Vector3.new(-way.Z, 0, way.X) -- across the line
							local from = flat(root.Position - at)
							local out = if from:Dot(side) < 0 then -side else side
							humanoid:MoveTo(root.Position + out * WALK)
						end
						if lead:GetAttribute("Away") == true then
							followed = true
						end
					end)
					t.Check("a second line", off ~= nil and typeof(off.To) == "Vector3")
					if off and off.Length then
						t.Check("the lead followed the avatar off the line", followed)
						t.Check("and stood off it at the hit", off.OnAtHit == false, off.Last)
						t.Check("walking off, the lunge misses", off.Hits == 0, `{off.Hits} hits`)
						t.Check("and hits empty stone, its lunge's length down the line", off.Went >= (move.Most or 0) * 0.5, string.format("went %.1f studs", off.Went))
						t.Row("the missed lunge's travel (studs)", nil, nil, off.Went, "")
						local tally = off.Counts
						t.Check("counted under Lunge A: missed, on purpose", tally ~= nil and tally.Slams == 1 and tally.Missed == 1 and tally.OnPurpose == 1, if tally then `{tally.Slams} lunges, {tally.Hit} hit, {tally.OnPurpose} on purpose` else "none")
					end
				end)
				onHit:Disconnect()
				t.Server("FightSpawn")
				t.Server("Slam", was)
				t.Server("Tune", "Combat.TapMove.On", tapWas)
				if not ok then
					error(err, 0)
				end
			end,
		},
		{
			Name = "Shades (AR58): the Support behind a Brawler of its pack shields it whole, mends it hurt, keeps behind it, and swings alone",
			Run = function(t: any)
				local lead, foe = begin(t, "brawler", PACK)
				if lead == nil or foe == nil then
					t.Server("FightSpawn")
					return
				end
				local brawler = foe :: Model
				local cast = Actions.ById.SupportCast
				local seeds = Combat.Support
				local level = lead:GetAttribute("Level")
				local spawned = t.Server("FightSpawn", "support", (if type(level) == "number" then level else 1) + SHADE_TOUGHER, SHADE_AHEAD + seeds.Back, true, nil, nil, PACK)
				t.Check("a Support spawns in its pack", type(spawned) == "table" and spawned.Ok == true)
				local support: Model? = nil
				waitFor(t, REPLICATE, function(): boolean
					support = fighterModel(if type(spawned) == "table" then spawned.Id else nil)
					return support ~= nil
				end)
				t.Check("its model reaches the client", support ~= nil)
				if support == nil then
					t.Server("FightSpawn")
					return
				end
				local healer = support :: Model
				t.Server("FoeHealth", brawler:GetAttribute("Fighter"), 1) -- whole for the first cast
				local heals: { any } = {}
				local onHeal = Net.Client.On("Heal", function(heal: any)
					if type(heal) == "table" and heal.A == healer and heal.T == brawler then
						table.insert(heals, heal)
					end
				end)
				local shields: { any } = {}
				local onShield = Net.Client.On("Shield", function(shield: any)
					if type(shield) == "table" and shield.A == healer and shield.T == brawler then
						table.insert(shields, shield)
					end
				end)
				local function casting(): boolean
					return healer:GetAttribute("Action") == "SupportCast"
				end
				-- AR58's link, once its rows are taken: the beam from the healer's light to the one its cast lands on
				local rowsLink = (EffectsConfig.Rows :: any).SupportLink ~= nil
				local linkWas: any = nil
				local function linkMark()
					local view = FighterController.Views[healer]
					linkWas = if view then view.Link else nil
				end
				local function linked(): boolean
					local view = FighterController.Views[healer]
					return view ~= nil and view.Link ~= nil and view.Link ~= linkWas
				end
				-- Its looks: Scintilla's rows once written and switched on (AR58), else SlamController's grey stand-ins.
				local lookName = seeds.Shield.Look
				local function veiled(): boolean
					local view = FighterController.Views[brawler]
					return if EffectsConfig.Lasting[lookName] == true and (EffectsConfig.Rows :: any)[lookName] ~= nil
						then view ~= nil and view.Looks[lookName] ~= nil
						else SlamController.Veil(brawler) ~= nil
				end
				local rowsMend = (EffectsConfig.Rows :: any).SupportHeal ~= nil
				local mendWas = if FighterController.Views[brawler] then FighterController.Views[brawler].Mend else nil
				local function mendShown(): boolean
					if rowsMend then
						local view = FighterController.Views[brawler]
						return view ~= nil and view.Mend ~= nil and view.Mend ~= mendWas
					end
					local root = brawler:FindFirstChild("HumanoidRootPart")
					return root ~= nil and root:FindFirstChild("NL_SupportMend") ~= nil
				end
				local ok, err = pcall(function()
					-- Whole and engaged: its first cast shields it.
					linkMark()
					t.Check("it casts in the fight", waitFor(t, SHADE_TIMEOUT, casting))
					local castAt = healer:GetAttribute("ActionAt")
					local shielded = waitFor(t, cast.Beats.Cast + REPLICATE, function(): boolean
						local up = brawler:GetAttribute("ShieldUntil")
						return brawler:GetAttribute("ShieldLook") == lookName and type(up) == "number" and now() < up
					end)
					t.Check("the whole Brawler takes its shield", shielded, `{#heals} heals`)
					if shielded and type(castAt) == "number" then
						local up = brawler:GetAttribute("ShieldUntil") :: number
						t.Near("for Shield.Seconds from its Cast beat (s)", up - castAt, cast.Beats.Cast + seeds.Shield.Seconds, 0.1)
						t.Check("its shield's look stands round it", waitFor(t, 0.5, veiled))
						t.Check("every client is told who shielded it, on its Cast beat", waitFor(t, 0.5, function(): boolean
							return #shields > 0
						end) and shields[1].Beat == cast.Support, `{#shields} shields`)
						if rowsLink then
							t.Check("the link plays from the healer to it", waitFor(t, 0.5, linked))
						end
					end
					-- Between casts: further from the lead than the Brawler.
					waitFor(t, cast.Length + 1, function(): boolean
						return not casting()
					end)
					local behind = false
					local detail = ""
					waitFor(t, 2.5, function(): boolean
						local a, b, l = Parts.Root(healer), Parts.Root(brawler), Parts.Root(lead)
						if a == nil or b == nil or l == nil then
							return false
						end
						local mine, its = flat(a.Position - l.Position).Magnitude, flat(b.Position - l.Position).Magnitude
						detail = string.format("%.1f studs from the lead, the Brawler %.1f", mine, its)
						behind = mine > its + seeds.Back / 2
						return behind
					end)
					t.Check("between casts it keeps behind the Brawler, from the lead", behind, detail)
					if shielded then
						local up = brawler:GetAttribute("ShieldUntil") :: number
						waitFor(t, seeds.Shield.Seconds + 1, function(): boolean
							return now() >= up + 0.2
						end)
						t.Check("its look goes when the shield ends", not veiled())
					end
					-- Hurt: its next cast mends it, by Heal of its most.
					t.Server("FoeHealth", brawler:GetAttribute("Fighter"), HURT)
					linkMark()
					local popped = false
					local linking = false
					local mended = waitFor(t, cast.Cooldown + REPLICATE, function(): boolean
						popped = popped or mendShown()
						linking = linking or (rowsLink and linked())
						return #heals > 0
					end)
					t.Check("the hurt Brawler is mended", mended)
					if mended then
						local heal = heals[1]
						t.Near("by Heal of its most", heal.Amount, seeds.Heal * heal.MaxHealth, heal.MaxHealth * 0.01)
						t.Check("its mend's look plays on it", popped or waitFor(t, 0.3, mendShown))
						if rowsLink then
							t.Check("and the link from the healer to it", linking or waitFor(t, 0.3, linked))
						end
					end
					-- Alone: it swings at the lead.
					t.Server("FightDefeat", brawler:GetAttribute("Fighter"))
					t.Check("alone, it swings at the lead", waitFor(t, SHADE_TIMEOUT, function(): boolean
						return healer:GetAttribute("Action") == Enemies.ById.support.Action
					end))
				end)
				onHeal:Disconnect()
				onShield:Disconnect()
				t.Server("FightSpawn")
				if not ok then
					error(err, 0)
				end
			end,
		},
		{
			Name = "Hard (TR69 E): two Hard Guards raise in turn, never together; a Hard Dasher lunges twice in a run; two Normal Dashers never have two lines in flight at once",
			Run = function(t: any)
				-- `defs` stood on the lead at `difficulty`, kept whole (the lead and they), and watched HARD_WATCH seconds:
				-- each one's actions, by id, from their start to their end in server time (the server's ActionAt, which
				-- start and endAction both set: a raise a break ends early ends there).
				local function watch(defs: { string }, difficulty: string?): { Watched }
					t.Server("LeadHeal")
					t.Server("LeadCalm")
					t.Server("FightSpawn")
					t.Wait(LEAD_SETTLE)
					local lead = myLead()
					local level = if lead then lead:GetAttribute("Level") else nil
					local out: { Watched } = {}
					local ids: { string } = {}
					for index, def in defs do
						local spawned = t.Server("FightSpawn", def, if type(level) == "number" then level else 1, SHADE_AHEAD + 3 * (index - 1), true, difficulty, nil, PACK)
						if type(spawned) == "table" and spawned.Id then
							table.insert(ids, spawned.Id)
						end
					end
					for _, id in ids do
						local model: Model? = nil
						waitFor(t, REPLICATE, function(): boolean
							model = fighterModel(id)
							return model ~= nil
						end)
						if model then
							local one: Watched = { Model = model, Starts = {} }
							table.insert(out, one)
						end
					end
					t.Check(`{#defs} {difficulty or "Normal"} {defs[1]}s stand`, #out == #defs, `{#out}`)
					local connections = {}
					for _, one in out do
						local open: Start? = nil
						table.insert(connections, one.Model:GetAttributeChangedSignal("ActionAt"):Connect(function()
							local id, at = one.Model:GetAttribute("Action"), one.Model:GetAttribute("ActionAt")
							if type(at) ~= "number" then
								return
							end
							if open then
								open.End = at
								open = nil
							end
							if type(id) == "string" and id ~= "" then
								local each: Start = { Id = id, At = at, End = math.huge }
								open = each
								table.insert(one.Starts, each)
							end
						end))
					end
					local untilAt = os.clock() + HARD_WATCH
					while os.clock() < untilAt do
						t.Server("FightHealth", 1)
						for _, id in ids do
							t.Server("FoeHealth", id, 1)
						end
						t.Wait(0.5)
					end
					for _, connection in connections do
						connection:Disconnect()
					end
					t.Server("FightSpawn")
					return out
				end
				local function runs(one: Watched, id: string): { Start }
					local list = {}
					for _, each in one.Starts do
						if each.Id == id then
							table.insert(list, each)
						end
					end
					return list
				end
				-- How many of `a`'s runs share time with `b`'s, each cut to `upTo` seconds from its start when given.
				local function together(a: { Start }, b: { Start }, upTo: number?): number
					local count = 0
					for _, x in a do
						for _, y in b do
							local xEnd = math.min(x.End, x.At + (upTo or math.huge))
							local yEnd = math.min(y.End, y.At + (upTo or math.huge))
							if x.At < yEnd - 0.05 and y.At < xEnd - 0.05 then
								count += 1
							end
						end
					end
					return count
				end

				-- Two Hard Guards: their raises never overlap, and each raises.
				local guards = watch({ "guard", "guard" }, "Hard")
				if #guards == 2 then
					local a, b = runs(guards[1], "GuardRaise"), runs(guards[2], "GuardRaise")
					t.Check("each Hard Guard raises", #a >= 1 and #b >= 1, `{#a} and {#b}`)
					t.Check("never together: one's raise starts after the other's has ended", together(a, b) == 0, `{together(a, b)} overlapping`)
				end

				-- One Hard Dasher: its lunges come in twos, the second as the first ends.
				local lunge = Actions.ById.DasherLunge
				local dashers = watch({ "dasher" }, "Hard")
				if #dashers == 1 then
					local list = runs(dashers[1], "DasherLunge")
					local paired = false
					for index = 2, #list do
						if math.abs(list[index].At - list[index - 1].At - lunge.Length) < 0.25 then
							paired = true
						end
					end
					t.Check("a Hard Dasher lunges twice in a run, the second as the first ends", paired, `{#list} lunges`)
				end

				-- Two Normal Dashers: one line in flight on the lead at a time (from its start to its Land beat).
				local land = lunge.Beats.Land
				local normal = watch({ "dasher", "dasher" }, nil)
				if #normal == 2 then
					local a, b = runs(normal[1], "DasherLunge"), runs(normal[2], "DasherLunge")
					t.Check("both Normal Dashers lunge", #a >= 1 and #b >= 1, `{#a} and {#b}`)
					t.Check("never two lines in flight on the lead at once (Normal's one)", together(a, b, land) == 0, `{together(a, b, land)} together`)
				end
			end,
		},
		{
			Name = "Tap to move (TR69's block): a drag never moves the lead, a tap past reach clamps, one in recovery does nothing, and a melee lead tapped clear holds its spot through the slam, then swings",
			Run = function(t: any)
				local tap = Combat.TapMove
				if not tap.On then
					t.Check("tap to move is on", false)
					return
				end
				t.Server("TapMove", "Ready")
				local lead, foe = begin(t, "brawler_elite")
				if lead == nil or foe == nil then
					t.Server("FightSpawn")
					return
				end
				local own = lead:GetAttribute("Def")
				t.Row("the lead", nil, nil, tostring(own), if type(own) == "string" and Actions.Skips[own] then "its skip back's clip" else "melee: TapStep")
				local function rootOf(model: Model): BasePart?
					local root = model:FindFirstChild("HumanoidRootPart")
					return if root and root:IsA("BasePart") then root else nil
				end
				local camera = workspace.CurrentCamera
				local middle = if camera then camera.ViewportSize / 2 else Vector2.new(400, 300)
				-- a drag: held too long, or moved too far; nothing is asked, so no tap-move happens
				t.Check("a long press asks nothing", TapMoveController.Press(middle, tap.Drag.Seconds + 0.15, 0) == nil)
				t.Check("a swipe asks nothing", TapMoveController.Press(middle, 0.05, tap.Drag.Pixels + 20) == nil)
				t.Wait(0.4)
				t.Check("a drag never moves the lead (no tap-move)", player:GetAttribute("TapMoveReady") == nil, tostring(player:GetAttribute("TapMoveReady")))
				-- a tap 40 studs off: clamped to Reach along its line
				local root, foeRoot = rootOf(lead), rootOf(foe)
				if root == nil or foeRoot == nil then
					t.Check("their roots", false)
					t.Server("FightSpawn")
					return
				end
				local from = root.Position
				local away = flat(from - foeRoot.Position)
				local side = if away.Magnitude > 0.1 then Vector3.new(-away.Unit.Z, 0, away.Unit.X) else Vector3.new(1, 0, 0)
				local far = TapMoveController.Ask(from + side * 40)
				t.Check("a far tap goes", far.Ok == true, tostring(far.Error))
				local went = if typeof(far.At) == "Vector3" then flat(far.At - from).Magnitude else -1
				t.Check("clamped to Reach", went > 0.5 and went <= tap.Reach + 0.1, string.format("%.2f studs", went))
				t.Check("its ring marks the spot", TapMoveController.Ring() ~= nil)
				local again = TapMoveController.Ask(from - side * 4)
				t.Equal("a tap in recovery does nothing", again.Error, "Recovering")
				t.Check("and the recovery stands", type(player:GetAttribute("TapMoveReady")) == "number")
				-- the overhead's footprint on the lead, then a tap clear of it
				t.Wait(tap.Skip + 0.2)
				t.Server("TapMove", "Ready")
				t.Server("Slam", "Ready")
				local markAt: Vector3? = nil
				waitFor(t, LUNGE_SOON + 4, function(): boolean
					local m = foe:GetAttribute("MarkAt")
					markAt = if typeof(m) == "Vector3" then m else nil
					return markAt ~= nil and foe:GetAttribute("MarkTo") == nil
				end)
				local slam, radius = foe:GetAttribute("MarkSlam"), foe:GetAttribute("MarkRadius")
				if markAt == nil or type(slam) ~= "number" or type(radius) ~= "number" then
					t.Check("the overhead's footprint goes down", false)
					t.Server("FightSpawn")
					return
				end
				local leadAt = root.Position
				local out = flat(leadAt - markAt)
				local dir = if out.Magnitude > 0.1 then out.Unit else side
				local hit = false
				local onHit = Net.Client.On("Hit", function(h: any)
					if type(h) == "table" and h.A == foe and h.T == lead then
						hit = true
					end
				end)
				local clear = TapMoveController.Ask(markAt + dir * (radius + 3))
				t.Check("the tap clear goes", clear.Ok == true, tostring(clear.Error))
				local landAt = now() + tap.Skip + 0.05
				local spot = if typeof(clear.At) == "Vector3" then clear.At else leadAt
				local drift = 0
				while now() < slam + 0.05 and lead.Parent ~= nil do
					if now() >= landAt then
						drift = math.max(drift, flat(root.Position - spot).Magnitude)
					end
					task.wait()
				end
				t.Check("it holds its spot through the slam", drift <= 0.75, string.format("%.2f studs", drift))
				t.Check("clear of the footprint", not MarkRule.Inside(markAt.X, markAt.Z, radius, root.Position.X, root.Position.Z))
				t.Wait(0.2)
				t.Check("the overhead misses it", not hit)
				onHit:Disconnect()
				t.Check("then it swings again", waitFor(t, tap.Hold + 2, function(): boolean
					local action = lead:GetAttribute("Action")
					local row = if type(action) == "string" then Actions.ById[action] else nil
					return row ~= nil and row.Range > 0 -- a kit's action: never the step or a skip back (Range 0)
				end), tostring(lead:GetAttribute("Action")))
				t.Server("FightSpawn")
				t.Server("TapMove", "Ready")
			end,
		},
	}
end

return ShadeCases
