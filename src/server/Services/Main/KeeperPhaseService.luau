--!strict
-- KeeperPhaseService (server): the Lamplighter in three phases (TR69 D, a signature piece, in grey;
-- docs/research/cloud-2026-11-24/grounds-and-encounters.md, section C; Rules.Keeper; Config.Combat.Keeper.Phases, read
-- live, Off until it's judged in play). FightService fights a try's keeper as before; while On, this adds:
-- * Its most health times Health as its phases begin (FightService.Toughen), so each phase shows its idea twice.
-- * Phase 1, the lesson (over From[1] of its most health): today's fight. Each slam it lands sticks its lantern in the
--   street: Window.Seconds Open, each hit on it Window.Harder times, its pose held (FightService.Window).
-- * Each phase's count of its idea, landed (the read-out's Counts): slams, phase 2's doubles, phase 3's sweeps.
-- * The midpoint, at From[1]: a hit never takes it past the line (its Floor). It stands, untouchable, Mid.Seconds
--   (FightService.Hold), while its ring's Mid.Posts posts light one by one; then phase 2.
-- * Phase 2, the street lights (to From[2]): every Pools.Every s from Pools.Start, a round of pools, one per post in turn,
--   Pools.Gap apart, each Pools.Radius with a Pools.Tell tell, inside the ring against its post (its edge at the post's
--   foot: Mid.Radius less its radius from the middle; KeeperLight's Pool). Its slam is double: the second lands
--   Double.After past the first's Slam where the avatar stood as it went down, a Double.Tell tell (KeeperSignature's
--   Slam), and the window comes Double.Window after the second (the first opens nothing).
-- * The false ending, at From[2]: its posts go dark, it kneels (stunned False.Kneel) and stays untouchable False.Dark
--   more; then the posts relight (Look.Relit) and phase 3.
-- * Phase 3, it's on (to its fall): Adds.Count of Adds.Def step in, Adds.Out studs from its middle, once (no ground:
--   nothing drops); its slam's tell runs Slam.Tell (its rate, Rules.Keeper.Rate); every Sweep.Every s from Sweep.Start,
--   its sweep (KeeperSweep): after a Sweep.Tell tell, a line Sweep.Length long, Sweep.Half either side, turns Sweep.Arc
--   degrees across its front over Sweep.Seconds (KeeperLight's Sweep), and the window comes Sweep.Window after it.
-- * Its fall, or its leaving the fight: its posts and its adds go.
-- The posts are grey stand-ins (Phases.Look), server parts under workspace.KeeperPosts: their light is their colour.
-- Studio: NL_Debug:Invoke("KeeperPhase", who) the player's keeper's phase and clocks; ("KeeperPhase", who, share) its
-- health set to that share of its most (past a line, the turn plays as a hit would bring it there); ("KeeperPhase", who,
-- true | false) the switch for every side (a Tune); ("KeeperPhase", who, "Adopt", id) a keeper stood by FightSpawn fights
-- in phases though no try stands it (the self-test's, on the main place, which has no keeper's ring).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Combat = require(Shared.Config.Combat)
local Keeper = require(Shared.Rules.Keeper)
local Actions = require(Shared.Definitions.Actions)
local Parts = require(Shared.Util.Parts)
local Log = require(Shared.Util.Log)
local Core = script.Parent.Parent.Core
local DebugService = require(Core.DebugService)
local TuneService = require(Core.TuneService)
local FightService = require(script.Parent.FightService)

local KeeperPhaseService = {
	Priority = 47, -- after the fight, the keeper's tries and the slams, whose signals it hears
}

type Fighter = FightService.Fighter

type Run = {
	Keeper: Fighter,
	Phase: number, -- 1, 2 or 3
	Turn: string?, -- "Mid" or "False" while a turn between phases plays
	TurnEnds: number,
	Posts: { BasePart },
	Rounds: { { number } }, -- its posts by the step they light at (Rules.Keeper.Rounds): one at a time, Hard's Per
	Lit: number, -- steps of Rounds lit so far in the midpoint's turn
	Adds: { Fighter },
	NextPools: number?,
	Pools: { { At: number, Post: number } }, -- a round's pools still to go down
	NextSweep: number?,
	Seconds: { [FightService.Mark]: boolean }, -- phase 2's second slams, whose Slam opens the window
	Counts: { { Slams: number, Doubles: number, Sweeps: number } }, -- by phase, what landed (the measure's)
	Tough: number, -- the health factor its begin gave it (Phases.Health), taken back as it ends: Off is the 45 s fight
}

local runs: { [Fighter]: Run } = {}
local adopted: { [Fighter]: boolean } = setmetatable({}, { __mode = "k" }) :: any -- Studio's, by "Adopt"
local folder: Folder? = nil

local function now(): number
	return workspace:GetServerTimeNow()
end

local function phases(): any
	return Combat.Keeper.Phases
end

-- Hard's rules (TR69 E; section C), on a keeper stood on Hard.
local function hard(f: Fighter): boolean
	return f.Difficulty == "Hard"
end

local function lines(f: Fighter): { number }
	return if hard(f) then phases().Hard.From else phases().From
end

-- A new tell on its difficulty: a circle's (Normal's `normal`, Hard's floor) or a line's.
local function tell(f: Fighter, normal: number, shape: "Circle" | "Line"): number
	return if hard(f) then phases().Hard.Tells[shape] else normal
end

-- A try's keeper (KeeperService gives it its ground; the replay's and the Tower's have none), or one a test adopted.
local function tried(f: Fighter): boolean
	return f.Kind == "Keeper" and (f.Ground ~= nil or adopted[f] == true) and FightService.Standing(f)
end

local function postsFolder(): Folder
	local found = folder
	if found and found.Parent then
		return found
	end
	local made = Instance.new("Folder")
	made.Name = "KeeperPosts"
	made.Parent = workspace
	folder = made
	return made
end

local function paintPost(post: BasePart, colour: Color3)
	post.Color = colour
	post.Material = if colour == phases().Look.Dark then Enum.Material.SmoothPlastic else Enum.Material.Neon
end

local function paint(run: Run, colour: Color3)
	for _, post in run.Posts do
		paintPost(post, colour)
	end
end

-- The ring's posts round its middle (the keeper's spawn), the first along its look, stood on the floor under each.
local function raisePosts(run: Run)
	local home = run.Keeper.Home
	if home == nil then
		return
	end
	local p = phases()
	local look = home.LookVector
	local centre = home.Position
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { run.Keeper.Model, postsFolder() }
	for index, spot in Keeper.Posts(centre.X, centre.Z, look.X, look.Z, p.Mid.Radius, p.Mid.Posts) do
		local from = Vector3.new(spot.X, centre.Y + 6, spot.Z)
		local hit = workspace:Raycast(from, Vector3.new(0, -30, 0), params)
		local foot = if hit then hit.Position.Y else centre.Y - 3
		local post = Instance.new("Part")
		post.Name = `Post{index}`
		post.Anchored = true
		post.CanCollide = false
		post.CanQuery = false
		post.CanTouch = false
		post.Size = p.Look.Size
		post.CFrame = CFrame.new(spot.X, foot + p.Look.Size.Y / 2, spot.Z)
		post.Color = p.Look.Dark
		post.Material = Enum.Material.SmoothPlastic
		post:SetAttribute("Keeper", run.Keeper.Id)
		post.Parent = postsFolder()
		table.insert(run.Posts, post)
	end
end

local function finish(f: Fighter)
	local run = runs[f]
	if run == nil then
		return
	end
	runs[f] = nil
	if run.Tough ~= 1 then
		FightService.Toughen(f, 1 / run.Tough) -- its own health again, kept as a share (none for a fallen one)
	end
	for _, post in run.Posts do
		post:Destroy()
	end
	for _, add in run.Adds do
		if FightService.Standing(add) then
			FightService.Remove(add)
		end
	end
	f.Floor, f.Rates = nil, nil
end

local function begin(f: Fighter)
	local run: Run = {
		Keeper = f,
		Phase = 1,
		Turn = nil,
		TurnEnds = 0,
		Posts = {},
		Rounds = {},
		Lit = 0,
		Adds = {},
		NextPools = nil,
		Pools = {},
		NextSweep = nil,
		Seconds = {},
		Counts = {
			{ Slams = 0, Doubles = 0, Sweeps = 0 },
			{ Slams = 0, Doubles = 0, Sweeps = 0 },
			{ Slams = 0, Doubles = 0, Sweeps = 0 },
		},
		Tough = phases().Health or 1,
	}
	runs[f] = run
	FightService.Toughen(f, run.Tough)
	raisePosts(run)
	run.Rounds = Keeper.Rounds(#run.Posts, if hard(f) then phases().Hard.Per else 1)
	Log.Info("KeeperPhase", `{f.Id}: phase 1`)
end

-- A turn between phases: the midpoint's lights, or the false ending.
local function turn(run: Run, at: number)
	local p = phases()
	local f = run.Keeper
	if run.Phase == 1 then
		run.Turn, run.TurnEnds, run.Lit = "Mid", at + p.Mid.Seconds, 0
		FightService.Hold(f, run.TurnEnds)
	else
		run.Turn, run.TurnEnds = "False", at + p.False.Kneel + p.False.Dark
		run.Pools, run.NextPools = {}, nil
		paint(run, p.Look.Dark)
		FightService.Hold(f, run.TurnEnds, p.False.Kneel)
	end
	f.Model:SetAttribute("KeeperTurn", run.Turn)
	Log.Info("KeeperPhase", `{f.Id}: turn {run.Turn}`)
end

local function enter(run: Run, phase: number, at: number)
	local p = phases()
	local f = run.Keeper
	run.Phase, run.Turn = phase, nil
	f.Model:SetAttribute("KeeperTurn", nil)
	f.Model:SetAttribute("KeeperPhase", phase)
	if phase == 2 then
		paint(run, p.Look.Lit)
		run.NextPools = at + p.Pools.Start
	elseif phase == 3 then
		paint(run, p.Look.Relit)
		local beats = Actions.ById.KeeperSignature.Beats
		local swing = Actions.ById.KeeperSweep.Beats
		f.Rates = {
			KeeperSignature = Keeper.Rate(beats.Slam - beats.Plant, tell(f, p.Slam.Tell, "Circle")),
			KeeperSweep = Keeper.Rate(swing.Sweep - swing.Wind, tell(f, p.Sweep.Tell, "Line")), -- its clip meets its tell
		}
		run.NextSweep = at + p.Sweep.Start
		local home = f.Home or f.Root.CFrame
		for index = 1, p.Adds.Count do
			local a = math.rad(90 + (index - 1) * 360 / p.Adds.Count)
			local spot = home * CFrame.new(math.cos(a) * p.Adds.Out, 0, -math.sin(a) * p.Adds.Out)
			local add = FightService.SpawnEnemy(p.Adds.Def, f.Block.Level, CFrame.lookAt(spot.Position, home.Position))
			if f.Target then
				add.Target = f.Target
			end
			table.insert(run.Adds, add)
		end
	end
	Log.Info("KeeperPhase", `{f.Id}: phase {phase}`)
end

local function pool(run: Run, index: number, at: number)
	local p = phases()
	local f = run.Keeper
	local post = run.Posts[index]
	local home = f.Home
	if post == nil or home == nil then
		return
	end
	local centre = home.Position
	local out = Vector3.new(post.Position.X - centre.X, 0, post.Position.Z - centre.Z)
	local reach = math.max(0, p.Mid.Radius - p.Pools.Radius)
	local spot = centre + (if out.Magnitude > 0.05 then out.Unit else Vector3.new(0, 0, -1)) * reach
	local mark: FightService.Mark = {
		X = spot.X,
		Z = spot.Z,
		Y = f.Root.Position.Y,
		Radius = p.Pools.Radius,
		Down = at,
		Slam = at + tell(f, p.Pools.Tell, "Circle"),
		Target = f.Target,
		Kind = "Pool",
	}
	FightService.Hazard(f, mark, "KeeperLight", "Pool")
end

local function sweep(run: Run, at: number): boolean
	local p = phases()
	local f = run.Keeper
	if not FightService.Act(f, "KeeperSweep") then
		return false
	end
	local look = f.Root.CFrame.LookVector
	local arc = math.rad(p.Sweep.Arc)
	local pos = f.Root.Position
	local mark: FightService.Mark = {
		X = pos.X,
		Z = pos.Z,
		Y = pos.Y,
		Radius = p.Sweep.Half,
		Down = at,
		Slam = at + tell(f, p.Sweep.Tell, "Line"),
		Target = f.Target,
		Length = p.Sweep.Length,
		Kind = "Sweep",
		From = math.atan2(look.Z, look.X) - arc / 2,
		Arc = arc,
		Turn = p.Sweep.Seconds,
		Back = if hard(f) and p.Hard.Back then true else nil,
	}
	FightService.Hazard(f, mark, "KeeperLight", "Sweep")
	return true
end

local function step()
	local p = phases()
	local at = now()
	for f, run in runs do
		if not tried(f) or not p.On then
			finish(f)
		end
	end
	if not p.On then
		return
	end
	for _, f in FightService.All() do
		if runs[f] == nil and tried(f) then
			begin(f)
		end
	end
	for f, run in runs do
		local most = f.Block.Health
		if run.Turn == "Mid" and #run.Rounds > 0 then
			local steps = #run.Rounds
			local lit = math.clamp(math.floor((1 - (run.TurnEnds - at) / p.Mid.Seconds) * steps) + 1, 1, steps)
			for step = run.Lit + 1, lit do
				for _, index in run.Rounds[step] do
					paintPost(run.Posts[index], p.Look.Lit)
				end
			end
			run.Lit = math.max(run.Lit, lit)
		end
		if run.Turn then
			if at >= run.TurnEnds then
				enter(run, run.Phase + 1, at)
			end
			continue
		end
		-- The line it stands at: past it, the turn plays.
		f.Floor = if run.Phase < 3 then Keeper.Floor(run.Phase, most, lines(f)) else nil
		if f.Floor and f.Health <= (f.Floor :: number) + 1e-6 then
			turn(run, at)
			continue
		end
		if run.Phase == 2 then
			if run.NextPools and at >= run.NextPools then
				run.NextPools = at + p.Pools.Every
				for step, posts in run.Rounds do
					for _, index in posts do
						table.insert(run.Pools, { At = at + (step - 1) * p.Pools.Gap, Post = index })
					end
				end
			end
			for index = #run.Pools, 1, -1 do
				local due = run.Pools[index]
				if at >= due.At then
					table.remove(run.Pools, index)
					pool(run, due.Post, at)
				end
			end
		elseif run.Phase == 3 then
			if run.NextSweep and at >= run.NextSweep and sweep(run, at) then
				run.NextSweep = at + p.Sweep.Every
			end
		end
	end
end

-- Its own footprints: phase 2's first slam brings the second; the second's Slam opens it.
local function marked(f: Fighter, mark: FightService.Mark)
	local run = runs[f]
	if run == nil or run.Turn or run.Phase ~= 2 or mark.Kind ~= nil then
		return
	end
	local p = phases()
	local down, slam = Keeper.Second(mark.Slam, p.Double.After, tell(f, p.Double.Tell, "Circle"))
	local owner = if mark.Target then mark.Target.Owner else nil
	task.delay(math.max(0, down - now()), function()
		if runs[f] ~= run or run.Turn or run.Phase ~= 2 then
			return
		end
		local avatar = if owner then Parts.Root(owner.Character) else nil
		local target = mark.Target
		local at = if avatar then avatar.Position elseif target then target.Root.Position else nil
		if at == nil then
			return
		end
		local second: FightService.Mark = {
			X = at.X,
			Z = at.Z,
			Y = mark.Y,
			Radius = mark.Radius,
			Down = now(),
			Slam = slam,
			Target = mark.Target,
			Kind = "Second",
		}
		if FightService.Hazard(f, second, "KeeperSignature", "Slam") then
			run.Seconds[second] = true
		end
	end)
end

-- Taken up: phase 1's slams open it Window.Seconds; phase 2's second, Double.Window; phase 3's sweep, Sweep.Window.
local function unmarked(f: Fighter, mark: FightService.Mark, struck: { Fighter }?)
	local run = runs[f]
	if run == nil or struck == nil then
		return
	end
	local p = phases()
	-- Hard: each slam that lands leaves its footprint burning
	if hard(f) and (mark.Kind == nil or run.Seconds[mark]) and mark.Length == nil then
		local burn = p.Hard.Burn
		local at = now()
		local lasting: FightService.Mark = {
			X = mark.X, Z = mark.Z, Y = mark.Y, Radius = mark.Radius, Down = at, Slam = at, Target = f.Target,
			Kind = "Burn", Turn = burn.Seconds, Every = burn.Every,
		}
		task.defer(FightService.Hazard, f, lasting, "KeeperLight", "Burn")
	end
	local count = run.Counts[run.Phase]
	if count and not run.Turn then
		if run.Seconds[mark] then
			count.Doubles += 1
		elseif mark.Kind == "Sweep" and not mark.Back then
			count.Sweeps += 1
		elseif mark.Kind == nil then
			count.Slams += 1
		end
	end
	local window: number? = nil
	if run.Seconds[mark] then
		run.Seconds[mark] = nil
		window = if run.Phase == 2 and not run.Turn then p.Double.Window else nil
	elseif mark.Kind == "Sweep" then
		window = if run.Phase == 3 and not run.Turn then p.Sweep.Window else nil
	elseif mark.Kind == nil and run.Phase == 1 and not run.Turn then
		window = p.Window.Seconds
	end
	if window then
		task.defer(FightService.Window, f, window, p.Window.Harder)
	end
end

local function keeperOf(player: Player): Fighter?
	for f in runs do
		if f.For == player or (f.Target and f.Target.Owner == player) then
			return f
		end
	end
	for _, f in FightService.All() do
		if tried(f) and (f.For == player or (f.Target and f.Target.Owner == player)) then
			return f
		end
	end
	return nil
end

local function command(who: any, what: any, extra: any): any
	if type(what) == "boolean" then
		TuneService.Set("Combat.Keeper.Phases.On", what)
		return { Ok = true, On = phases().On }
	end
	if what == "Adopt" then
		local f = FightService.All()[tostring(extra)]
		if f == nil or f.Kind ~= "Keeper" then
			return { Ok = false, Error = "NoKeeper" }
		end
		adopted[f] = true
		return { Ok = true, Most = if runs[f] then nil else f.Block.Health } -- its most before its phases toughen it
	end
	local player = DebugService.ResolvePlayer(who)
	local f = if player then keeperOf(player) else nil
	if f == nil then
		return { Ok = false, Error = "NoKeeper", On = phases().On }
	end
	if type(what) == "number" then
		FightService.SetHealthShare(f, math.clamp(what, 0.01, 1))
	end
	local run = runs[f]
	local at = now()
	local lit = 0
	for _, post in (if run then run.Posts else {}) do
		if post.Material == Enum.Material.Neon then
			lit += 1
		end
	end
	return {
		Ok = true,
		On = phases().On,
		Phase = if run then run.Phase else nil,
		Turn = if run then run.Turn else nil,
		Share = f.Health / math.max(1, f.Block.Health),
		Floor = f.Floor,
		Posts = if run then #run.Posts else 0,
		Adds = if run then #run.Adds else 0,
		NextPools = if run and run.NextPools then run.NextPools - at else nil,
		NextSweep = if run and run.NextSweep then run.NextSweep - at else nil,
		Lit = lit,
		Relit = if run and run.Posts[1] then run.Posts[1].Color == phases().Look.Relit else false,
		Held = if f.HeldUntil then f.HeldUntil - at else nil,
		Open = if f.OpenUntil then f.OpenUntil - at else nil,
		Harder = if f.HarderUntil and at < f.HarderUntil then f.Harder else nil,
		Rate = if f.Rates then f.Rates.KeeperSignature else nil,
		Counts = if run then run.Counts else nil,
		Pinned = if f.PinUntil then f.PinUntil - at else nil,
		Most = f.Block.Health,
		Id = f.Id,
	}
end

function KeeperPhaseService.Start()
	FightService.Marked:Connect(marked)
	FightService.Unmarked:Connect(unmarked)
	RunService.Heartbeat:Connect(step)
	Players.PlayerRemoving:Connect(function()
		for f in runs do
			if not tried(f) then
				finish(f)
			end
		end
	end)
	if RunService:IsStudio() then
		DebugService.Register("KeeperPhase", command)
	end
end

return KeeperPhaseService
