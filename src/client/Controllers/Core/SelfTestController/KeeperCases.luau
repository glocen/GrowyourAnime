--!strict
-- The Lamplighter in three phases (TR69 D; KeeperPhaseService, Config.Combat.Keeper.Phases), apart: Cases is at the type
-- checker's limit. One case stands a lamplighter on the lead by FightSpawn and lets the phases adopt it (the main place
-- has no keeper's ring), the switch On, and walks it through its turns by its health share, on the server's own paths:
-- * phase 1: six dark posts round it, a hit held at its line;
-- * the midpoint: untouchable while its posts light one by one, then phase 2;
-- * phase 2: pools go down round the ring in turn, drawn in grey; its slam brings a second After it, where the avatar
--   stood, and the window opens after the second, its hits Harder;
-- * the false ending: its posts dark and it held, then relit and phase 3;
-- * phase 3: its two adds, its slam's tell run quicker, its sweep's line turning its arc in its seconds, the window after;
-- * the switch off: its posts and its adds gone.
-- The switch and the spawned foes are put back at its end.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Combat = require(Shared.Config.Combat)
local Actions = require(Shared.Definitions.Actions)
local Keeper = require(Shared.Rules.Keeper)
local SlamController = require(script.Parent.Parent.Parent.Main.SlamController)
local Helpers = require(script.Parent.Helpers)

local KeeperCases = {}

local LEAD_SETTLE = 1.5 -- seconds for a cleared lead to settle by the avatar
local AHEAD = 12 -- studs ahead of the avatar the keeper stands
local REPLICATE = 2 -- seconds for an attribute or a remote to reach the client
local STEP = 0.25 -- seconds for the server's step to see a share set
local CHOOSE = 8 -- seconds a ready keeper may take to come into range and begin its slam
local TURNED = 20 -- degrees the sweep's line may miss its turn by, read on the client's clock

local player = Players.LocalPlayer
local waitFor = Helpers.waitFor

local function fighterModel(id: any): Model?
	local fighters = workspace:FindFirstChild("Fighters")
	for _, model in (if fighters then fighters:GetChildren() else {}) do
		if model:IsA("Model") and model:GetAttribute("Fighter") == id then
			return model
		end
	end
	return nil
end

local function myLead(): Model?
	local fighters = workspace:FindFirstChild("Fighters")
	for _, model in (if fighters then fighters:GetChildren() else {}) do
		if model:IsA("Model") and model:GetAttribute("Side") == "Lead" and model:GetAttribute("Owner") == player.UserId then
			return model
		end
	end
	return nil
end

local function now(): number
	return workspace:GetServerTimeNow()
end

local function drawn(kind: string): { SlamController.Drawing }
	local out = {}
	for _, h in SlamController.Hazards() do
		if h.Kind == kind then
			table.insert(out, h)
		end
	end
	return out
end

local function heading(v: Vector3): number
	return math.atan2(v.Z, v.X)
end

function KeeperCases.Cases(): { any }
	return {
		{
			Name = "Keeper (TR69 D): the Lamplighter's three phases in grey: the midpoint's posts, phase 2's pools and double slam, the false ending, phase 3's adds, quicker slam and sweep",
			Run = function(t: any)
				local p = Combat.Keeper.Phases
				local wasOn = t.Server("KeeperPhase").On
				local holding = true
				local function finish()
					holding = false
					t.Server("KeeperPhase", wasOn == true)
					t.Server("FightSpawn")
				end
				t.Server("KeeperPhase", true)
				t.Server("LeadHeal")
				t.Server("LeadCalm")
				t.Server("FightSpawn")
				t.Wait(LEAD_SETTLE)
				local lead = myLead()
				local level = if lead then lead:GetAttribute("Level") else nil
				local spawned = t.Server("FightSpawn", "lamplighter", if type(level) == "number" then level else 1, AHEAD, true)
				local id = if type(spawned) == "table" then spawned.Id else nil
				local adopted = t.Server("KeeperPhase", "Adopt", id)
				t.Check("a lamplighter stands and the phases take it", lead ~= nil and type(adopted) == "table" and adopted.Ok == true, tostring(id))
				if lead == nil or id == nil then
					finish()
					return
				end
				-- the lead kept whole the whole way: the case is the keeper's
				task.spawn(function()
					while holding do
						t.Server("FightHealth", 1)
						task.wait(0.5)
					end
				end)
				local keeper: Model? = nil
				waitFor(t, REPLICATE, function(): boolean
					keeper = fighterModel(id)
					return keeper ~= nil
				end)
				local function read(): { [string]: any }
					return t.Server("KeeperPhase")
				end

				-- Phase 1: six dark posts round it, its line at From[1].
				local s = read()
				waitFor(t, REPLICATE, function(): boolean
					s = read()
					return s.Phase == 1 and s.Posts == p.Mid.Posts
				end)
				t.Check("phase 1: its posts stand round it, dark", s.Phase == 1 and s.Posts == p.Mid.Posts and s.Lit == 0, `phase {s.Phase}, {s.Posts} posts, {s.Lit} lit`)
				local posts = workspace:FindFirstChild("KeeperPosts")
				local mine = 0
				for _, post in (if posts then posts:GetChildren() else {}) do
					if post:GetAttribute("Keeper") == id then
						mine += 1
					end
				end
				t.Equal("they reach the client", mine, p.Mid.Posts)

				-- The midpoint: at its line it stands untouchable while the posts light one by one.
				t.Server("KeeperPhase", p.From[1] - 0.01)
				t.Wait(STEP)
				s = read()
				t.Check("at its line: the midpoint's turn, held", s.Turn == "Mid" and type(s.Held) == "number" and s.Held > p.Mid.Seconds - 0.6, `turn {s.Turn}, held {s.Held}`)
				local share = s.Share
				t.Wait(p.Mid.Seconds / 2)
				s = read()
				t.Check("halfway: some posts lit, not all", s.Lit > 0 and s.Lit < p.Mid.Posts, `{s.Lit} lit`)
				t.Check("untouchable meanwhile", s.Share >= share - 1e-6, `{share} to {s.Share}`)
				waitFor(t, p.Mid.Seconds, function(): boolean
					s = read()
					return s.Phase == 2
				end)
				t.Check("then phase 2, every post lit", s.Phase == 2 and s.Turn == nil and s.Lit == p.Mid.Posts, `phase {s.Phase}, {s.Lit} lit`)

				-- Phase 2's pools: round the ring in turn, each drawn as a ring inside it.
				local seen: { [BasePart]: Vector3 } = {}
				local count = 0
				waitFor(t, p.Pools.Start + 2 * p.Pools.Gap + 1, function(): boolean
					for _, h in drawn("Pool") do
						if seen[h.Holder] == nil then
							seen[h.Holder] = h.At
							count += 1
						end
					end
					return count >= 3
				end)
				t.Check("its pools go down one after another", count >= 3, `{count}`)
				local home = if keeper then keeper:GetPivot().Position else Vector3.zero
				local inside = true
				for _, at in seen do
					inside = inside and Vector3.new(at.X - home.X, 0, at.Z - home.Z).Magnitude <= p.Mid.Radius + 6 -- it may have stepped
				end
				t.Check("inside its ring", inside)

				-- Phase 2's double slam: its slam made ready, the second follows After it; the window comes after the second.
				t.Server("Slam", "Ready")
				local first: number? = nil
				waitFor(t, CHOOSE, function(): boolean
					local slam = if keeper then keeper:GetAttribute("MarkSlam") else nil
					first = if type(slam) == "number" then slam else nil
					return first ~= nil
				end)
				local second: SlamController.Drawing? = nil
				if first then
					waitFor(t, (first :: number) - now() + 1, function(): boolean
						second = drawn("Second")[1]
						return second ~= nil
					end)
				end
				t.Check("its slam brings a second", first ~= nil and second ~= nil, `first {first}`)
				if first and second then
					local s2 = second :: SlamController.Drawing
					t.Check("After the first, its tell Tell long", math.abs(s2.Slam - (first :: number) - p.Double.After) < 0.05 and math.abs(s2.Slam - s2.Down - p.Double.Tell) < 0.2, `{s2.Slam - first}, tell {s2.Slam - s2.Down}`)
					waitFor(t, s2.Slam - now() + 1, function(): boolean
						s = read()
						return type(s.Open) == "number" and s.Open > 0
					end)
					t.Check("the window after the second, its hits Harder", type(s.Open) == "number" and s.Open > p.Double.Window - 0.8 and s.Harder == p.Window.Harder, `open {s.Open}, harder {s.Harder}`)
				end

				-- The false ending: posts dark, held, then relit and phase 3.
				t.Wait(p.Double.Window)
				t.Server("KeeperPhase", p.From[2] - 0.01)
				t.Wait(STEP)
				s = read()
				t.Check("at its last line: it kneels, its posts dark", s.Turn == "False" and s.Lit == 0 and type(s.Held) == "number" and s.Held > 1, `turn {s.Turn}, {s.Lit} lit, held {s.Held}`)
				waitFor(t, p.False.Kneel + p.False.Dark + 1, function(): boolean
					s = read()
					return s.Phase == 3
				end)
				t.Check("then phase 3, its posts relit", s.Phase == 3 and s.Relit == true, `phase {s.Phase}`)
				t.Equal("its adds step in", s.Adds, p.Adds.Count)
				local beats = Actions.ById.KeeperSignature.Beats
				local rate = Keeper.Rate(beats.Slam - beats.Plant, p.Slam.Tell)
				t.Check("its slam's tell runs quicker", type(s.Rate) == "number" and math.abs(s.Rate - rate) < 1e-3, `{s.Rate} against {rate}`)

				-- Phase 3's sweep: its line lies on the first side, then turns its arc in its seconds.
				local sweep: SlamController.Drawing? = nil
				waitFor(t, p.Sweep.Start + 4, function(): boolean
					sweep = drawn("Sweep")[1]
					return sweep ~= nil
				end)
				t.Check("its sweep goes down", sweep ~= nil and (sweep :: SlamController.Drawing).Line ~= nil)
				if sweep then
					local sw = sweep :: SlamController.Drawing
					waitFor(t, sw.Slam - now() + 0.5, function(): boolean
						return now() >= sw.Slam + 0.1
					end)
					local from = heading(sw.Holder.CFrame.LookVector)
					local early = now() - sw.Slam
					waitFor(t, p.Sweep.Seconds, function(): boolean
						return now() >= sw.Slam + p.Sweep.Seconds - 0.2
					end)
					local to = heading(sw.Holder.CFrame.LookVector)
					local late = now() - sw.Slam
					local turned = math.deg((to - from + math.pi) % (2 * math.pi) - math.pi)
					local want = p.Sweep.Arc * (late - early) / p.Sweep.Seconds
					t.Check("its line turns its arc in its seconds", math.abs(turned - want) < TURNED, `{turned} against {want}`)
					waitFor(t, 1.2, function(): boolean
						s = read()
						return type(s.Open) == "number" and s.Open > 0
					end)
					t.Check("the window after it", type(s.Open) == "number" and s.Open > p.Sweep.Window - 1.2, `open {s.Open}`)
					t.Check("its drawing gone after it", #drawn("Sweep") == 0)
				end

				-- Off: its posts and adds go.
				t.Server("KeeperPhase", false)
				t.Wait(STEP)
				s = read()
				t.Check("off: its run ends, its posts gone", s.Phase == nil and s.Posts == 0, `phase {s.Phase}, {s.Posts} posts`)
				finish()
			end,
		},
	}
end

return KeeperCases
