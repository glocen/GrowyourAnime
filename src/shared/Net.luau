--!strict
-- Net: every RemoteEvent and RemoteFunction the game uses is declared in REMOTES below.
-- The server creates them under Shared.Remotes at boot; clients wait for them.
-- Server handlers are rate limited per player and wrapped in pcall, so spammed or malformed payloads
-- can't break anything. Handlers still check their own arguments: client data is untrusted.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Log = require(script.Parent.Util.Log)

type Kind = "Event" | "Unreliable" | "Function"
type Spec = {
	Kind: Kind,
	RatePerSecond: number, -- client-to-server calls allowed per second per player (bursts up to 2x)
}

local REMOTES: { [string]: Spec } = {
	-- The kit's own. The game's remotes join below them, one line each, saying what they carry.
	ClientReady = { Kind = "Event", RatePerSecond = 1 }, -- client -> server: (bootErrors) how the client's boot went
	Tune = { Kind = "Event", RatePerSecond = 0 }, -- server -> clients, Studio only: (path, value) a Config change (TuneService)
	DebugCommand = { Kind = "Function", RatePerSecond = 30 }, -- client -> server, answered only in Studio: (name, ...) runs a DebugService command
	-- The save (DataService).
	Act = { Kind = "Function", RatePerSecond = 10 }, -- client -> server: (opId, action, args) -> answer; a repeated opId gets its first answer
	ProfileGet = { Kind = "Function", RatePerSecond = 1 }, -- client -> server: () -> the player's read copy, once it's loaded
	Profile = { Kind = "Event", RatePerSecond = 0 }, -- server -> client: (view) the whole read copy after each change
	-- The fight (FightService).
	Hit = { Kind = "Event", RatePerSecond = 0 }, -- server -> clients: (hit) one landed or dodged hit, for its hold, spark and number
	Heal = { Kind = "Event", RatePerSecond = 0 }, -- server -> clients: (heal) the health a hit's heal or a Regen burst (Regen = true, TR40) gave a lead, for its number
	Shield = { Kind = "Event", RatePerSecond = 0 }, -- server -> clients: (shield) { A, T, Beat }: a Support's cast shielded T (AR58), for its link from A
	-- The Broadcast (BroadcastService, TR57).
	Broadcast = { Kind = "Event", RatePerSecond = 0 }, -- server -> clients: (news) a line worth telling (Rules.Broadcast.News), its words built on the client
	-- The keeper's try (KeeperService).
	Fade = { Kind = "Event", RatePerSecond = 0 }, -- server -> client: (out, hold, back) seconds of a fade to black and back, around a move
	-- Home in one tap (HomeService, TR19).
	Home = { Kind = "Function", RatePerSecond = 4 }, -- client -> server: () -> { Ok, Refusal?, Says? }: the charge begins, or why not
	-- The Tower's results (TowerService, TR46).
	TowerRetry = { Kind = "Function", RatePerSecond = 2 }, -- client -> server: () -> { Ok, Error?, Waits? }: set in the ring, the run begins once rested
	TowerHome = { Kind = "Function", RatePerSecond = 2 }, -- client -> server: () -> { Ok, Error? }: set down at the plot's spawn, free
	TowerGo = { Kind = "Function", RatePerSecond = 2 }, -- client -> server: () -> { Ok, Error? }: set down before the player's own gate, facing it (TR65)
	TowerLeave = { Kind = "Function", RatePerSecond = 2 }, -- client -> server: () -> { Ok, Error? }: the run ends at its last floor won, asked first (TR67)
	TowerEdge = { Kind = "Event", RatePerSecond = 0 }, -- server -> client: () the avatar walked out of its room and was set back: ask whether to leave (TR67)
	TowerHealCap = { Kind = "Event", RatePerSecond = 0 }, -- server -> client: (share) the heal cap bound for the first time on this account
	TowerBoard = { Kind = "Function", RatePerSecond = 1 }, -- client -> server: () -> { Ok, Rows, Mine? }: the week's board (TowerBoardService)
	Boards = { Kind = "Function", RatePerSecond = 1 }, -- client -> server: () -> { Ok, Boards, News }: the Strip's boards (BoardsService, TR58)
	HomeJump = { Kind = "Event", RatePerSecond = 0 }, -- server -> client: (landed, says?) the jump home, or the charge broken and why
	-- A ground's one run of stretches (StageService, TR43, TR50).
	Stage = { Kind = "Function", RatePerSecond = 2 }, -- client -> server: (ground, difficulty) -> { Ok, Error?, Needs?, Waits? }: a run begins at that difficulty's checkpoint, or why not
	StagePick = { Kind = "Event", RatePerSecond = 0 }, -- server -> client: ({ Ground, Refused? }) the picker opens: by the base's Festival Door, or on arriving in the Festival with no stage to begin
	-- The trip between places (TravelService, TR45).
	Travel = { Kind = "Event", RatePerSecond = 0 }, -- server -> client: (state, info) "Leaving" { To }: the trip's card; "Failed" { Result }: the screen back, with a line; "Back": the screen back; "Arrived": the far side stands, the arrival card lifts
	StageDone = { Kind = "Event", RatePerSecond = 0 }, -- server -> client: (results) a run ended, won or lost, for its card
	StageGate = { Kind = "Event", RatePerSecond = 0 }, -- server -> client: ({ Stage, Ground }) set back at a gate shut to them
	-- The Void Shop (ShopService, AR38).
	Shop = { Kind = "Function", RatePerSecond = 2 }, -- client -> server: () -> { Ok, Shelf?, Left?, Error? }: the standing stock's shelf and its seconds left
	-- The fight in the camera's view (FightService, TR24's fixes 2 and 3).
	Recall = { Kind = "Function", RatePerSecond = 4 }, -- client -> server: () -> { Ok, Error?, Ready? }: the lead dashes to the avatar, or why not (TR44's B)
	View = { Kind = "Unreliable", RatePerSecond = 8 }, -- client -> server: (bearing) degrees, where the camera looks, flat: atan2(Z, X)
	-- The signature on a tap (FightService, TR52's block).
	Signature = { Kind = "Function", RatePerSecond = 8 }, -- client -> server: ("Tap") -> { Ok, Error?, Fired? }: the lead's signature armed, fired now if it can; ("Auto", on) -> { Ok, Auto }
}

local CLASS_FOR_KIND: { [Kind]: string } = {
	Event = "RemoteEvent",
	Unreliable = "UnreliableRemoteEvent",
	Function = "RemoteFunction",
}

local FOLDER_NAME = "Remotes"
local WAIT_TIMEOUT = 30
local DROP_WARN_INTERVAL = 10

local Net = {}
Net.Server = {}
Net.Client = {}

local folder: Folder? = nil
local cache: { [string]: any } = {}

local function spec(name: string): Spec
	local found = REMOTES[name]
	if not found then
		error(`Net: unknown remote "{name}" (declare it in Net's REMOTES table)`, 3)
	end
	return found
end

local function remote(name: string): any
	local found = cache[name]
	if found then
		return found
	end
	local remoteSpec = spec(name)
	if RunService:IsServer() then
		assert(folder, "Net.Server.Setup() must run before remotes are used")
		found = folder:FindFirstChild(name)
	else
		local remotes = script.Parent:WaitForChild(FOLDER_NAME, WAIT_TIMEOUT)
		assert(remotes, "Net: the Remotes folder never appeared")
		found = remotes:WaitForChild(name, WAIT_TIMEOUT)
	end
	assert(found and found.ClassName == CLASS_FOR_KIND[remoteSpec.Kind], `Net: remote "{name}" is missing or has the wrong class`)
	cache[name] = found
	return found
end

-- Rate limiting: one token bucket per player per remote.
type Bucket = { tokens: number, last: number, dropped: number, warnedAt: number }
local buckets: { [Player]: { [string]: Bucket } } = {}
local droppedTotal: { [string]: number } = {}

local function allow(player: Player, name: string): boolean
	local rate = REMOTES[name].RatePerSecond
	local perPlayer = buckets[player]
	if not perPlayer then
		perPlayer = {}
		buckets[player] = perPlayer
	end
	local now = os.clock()
	local bucket = perPlayer[name]
	if not bucket then
		bucket = { tokens = rate * 2, last = now, dropped = 0, warnedAt = -math.huge }
		perPlayer[name] = bucket
	end
	bucket.tokens = math.min(rate * 2, bucket.tokens + (now - bucket.last) * rate)
	bucket.last = now
	if bucket.tokens >= 1 then
		bucket.tokens -= 1
		return true
	end
	bucket.dropped += 1
	droppedTotal[name] = (droppedTotal[name] or 0) + 1
	if now - bucket.warnedAt >= DROP_WARN_INTERVAL then
		bucket.warnedAt = now
		Log.Warn("Net", `dropping "{name}" from {player.Name}: over {rate}/s ({bucket.dropped} dropped so far)`)
	end
	return false
end

local function guard(name: string, handler: (Player, ...any) -> ...any): (Player, ...any) -> ...any
	return function(player: Player, ...: any): ...any
		if not allow(player, name) then
			return nil
		end
		local results = table.pack(pcall(handler, player, ...))
		if not results[1] then
			Log.Warn("Net", `handler for "{name}" errored (player {player.Name}): {results[2]}`)
			return nil
		end
		return table.unpack(results, 2, results.n)
	end
end

-- Server --------------------------------------------------------------------------------------------

-- Creates every declared remote. The server Boot calls this once, before anything else.
function Net.Server.Setup()
	assert(RunService:IsServer(), "Net.Server.Setup is server-only")
	if folder then
		return
	end
	local newFolder = Instance.new("Folder")
	newFolder.Name = FOLDER_NAME
	for name, remoteSpec in REMOTES do
		local instance = Instance.new(CLASS_FOR_KIND[remoteSpec.Kind])
		instance.Name = name
		instance.Parent = newFolder
	end
	newFolder.Parent = script.Parent
	folder = newFolder

	Players.PlayerRemoving:Connect(function(player)
		buckets[player] = nil
	end)
end

function Net.Server.On(name: string, handler: (Player, ...any) -> ())
	assert(spec(name).Kind ~= "Function", `Net: "{name}" is a Function; use Net.Server.Handle`)
	remote(name).OnServerEvent:Connect(guard(name, handler))
end

function Net.Server.Handle(name: string, handler: (Player, ...any) -> ...any)
	assert(spec(name).Kind == "Function", `Net: "{name}" is not a Function`)
	remote(name).OnServerInvoke = guard(name, handler)
end

function Net.Server.Fire(name: string, player: Player, ...: any)
	remote(name):FireClient(player, ...)
end

function Net.Server.FireAll(name: string, ...: any)
	remote(name):FireAllClients(...)
end

function Net.Server.FireList(name: string, players: { Player }, ...: any)
	local instance = remote(name)
	for _, player in players do
		instance:FireClient(player, ...)
	end
end

-- How many calls the rate limiter dropped since the server started, by remote name.
function Net.Server.DroppedCounts(): { [string]: number }
	return table.clone(droppedTotal)
end

-- Client --------------------------------------------------------------------------------------------

function Net.Client.Fire(name: string, ...: any)
	remote(name):FireServer(...)
end

function Net.Client.On(name: string, handler: (...any) -> ()): RBXScriptConnection
	return remote(name).OnClientEvent:Connect(handler)
end

function Net.Client.Invoke(name: string, ...: any): ...any
	return remote(name):InvokeServer(...)
end

return Net
