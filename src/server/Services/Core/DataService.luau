--!strict
-- DataService (server): the one place a player's save is opened, changed and closed (docs/engineering-plan.md, "The
-- builder's calls"). It wraps ProfileStore (src/libraries/README.md), which session-locks each save so two servers can't
-- write one player's data. Studio saves to the "Test" store and live servers to "Live", so a test never touches a player.
-- Every write is a Transaction: a client's request through the Act remote (an action registered here by its system's
-- service), or the server's own change (Change). Reading is free: Get, WaitFor. A client holds a read copy, sent whole after
-- each change (the Profile remote) and fetched once at start (ProfileGet).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local ProfileStore = require(ServerScriptService.Libraries.ProfileStore)

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Log = require(Shared.Util.Log)
local Signal = require(Shared.Util.Signal)
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Transaction = require(Shared.Data.Transaction)
local DataConfig = require(Shared.Config.Data)
local DebugService = require(script.Parent.DebugService)

-- A client's request: the draft to change, the client's arguments (untrusted: the action checks them), and who asked.
export type Action = (draft: Profile.Data, args: any, player: Player) -> Transaction.Answer

type Session = {
	Profile: any, -- ProfileStore's profile. Its Data is read from it every time, never kept elsewhere: one reference to the save
}

local STORE_NAME = if RunService:IsStudio() then "Test" else "Live"
local KEY_PREFIX = "Player_" -- never change it: every save is found by it
local KICK_DATA = "Your data couldn't load. Please rejoin."
local KICK_ELSEWHERE = "Your data was opened in another server. Please rejoin."
local KICK_OUTDATED = "This server is older than your save. Please rejoin."
local WAIT_STEP = 0.1

local DataService = {
	Priority = 10, -- before any service that reads a profile in its Start
}

DataService.Ready = Signal.new() -- (player, data) once a player's save is open and migrated
DataService.Changed = Signal.new() -- (player, data, answer) after every committed change

local store: any = nil
local sessions: { [Player]: Session } = {}
local actions: { [string]: Action } = {}

-- Refusal codes the save layer gives itself.
DataService.NoAction = "NoAction" -- no action by that name
DataService.NoProfile = "NoProfile" -- the player's save isn't open (still loading past the wait, or gone)

local function push(player: Player, data: Profile.Data)
	Net.Server.Fire("Profile", player, Profile.View(data))
end

-- Runs a change through the save's one door, then tells the client and the server's listeners.
local function run(player: Player, opId: string?, label: string, change: Transaction.Change): Transaction.Answer
	local session = sessions[player]
	if not session then
		return { Ok = false, Error = DataService.NoProfile }
	end
	local data: Profile.Data = session.Profile.Data
	local answer, changed, failure = Transaction.Run(data, opId, change, DataConfig.OpsKept)
	if failure then
		Log.Error("DataService", `{label} for {player.Name} errored, nothing applied: {failure}`)
	end
	if changed then
		push(player, data)
		DataService.Changed:Fire(player, data, answer)
	end
	return answer
end

-- The open save's data, or nil. Read only: every write goes through Change or an action.
function DataService.Get(player: Player): Profile.Data?
	local session = sessions[player]
	return if session then session.Profile.Data else nil
end

-- Waits for the save to open. Nil if the player left or it took longer than Config.Data.LoadWaitSeconds.
function DataService.WaitFor(player: Player): Profile.Data?
	local waited = 0
	while sessions[player] == nil and player.Parent == Players and waited < DataConfig.LoadWaitSeconds do
		waited += task.wait(WAIT_STEP)
	end
	return DataService.Get(player)
end

-- A change the server makes on its own: a drop, a keeper's fall. Its caller makes sure it runs once.
function DataService.Change(player: Player, label: string, change: Transaction.Change): Transaction.Answer
	return run(player, nil, label, change)
end

-- Registers what a client may ask for by name through the Act remote. Each system's service registers its own in Init.
function DataService.Action(name: string, action: Action)
	assert(actions[name] == nil, `action "{name}" registered twice`)
	actions[name] = action
end

local function onAct(player: Player, opId: any, name: any, args: any): Transaction.Answer
	local action = if type(name) == "string" then actions[name] else nil
	if not action then
		return { Ok = false, Error = DataService.NoAction }
	end
	if DataService.WaitFor(player) == nil then
		return { Ok = false, Error = DataService.NoProfile }
	end
	return run(player, opId, name, function(draft: Profile.Data): Transaction.Answer
		return action(draft, args, player)
	end)
end

local loading: { [Player]: boolean } = {}

local function load(player: Player)
	if loading[player] or sessions[player] then
		return -- PlayerAdded and Start's sweep can both see an early joiner: one load each
	end
	loading[player] = true
	local profile = store:StartSessionAsync(`{KEY_PREFIX}{player.UserId}`, {
		Cancel = function(): boolean
			return player.Parent ~= Players -- stop trying once they've left
		end,
	})
	if profile == nil then
		if player.Parent == Players then
			player:Kick(KICK_DATA)
		end
		return
	end
	profile:AddUserId(player.UserId) -- ties the save to the user, for data deletion requests
	profile:Reconcile() -- fills keys the template gained since this save
	local ran, known = Migrations.Run(profile.Data)
	if not known then
		Log.Warn("DataService", `{player.Name}'s save is version {profile.Data.Version}, newer than this server's {Migrations.Latest}`)
		profile:EndSession()
		player:Kick(KICK_OUTDATED)
		return
	end
	local session: Session = { Profile = profile }
	profile.OnSessionEnd:Connect(function()
		if sessions[player] ~= session then
			return -- ended by their leaving, which already let go of it
		end
		sessions[player] = nil
		player:Kick(KICK_ELSEWHERE)
	end)
	if player.Parent ~= Players then
		profile:EndSession() -- they left while it loaded: release the lock now
		return
	end
	sessions[player] = session
	if ran > 0 then
		Log.Info("DataService", `{player.Name}'s save migrated by {ran} step(s) to version {Migrations.Latest}`)
	end
	DataService.Ready:Fire(player, profile.Data)
	push(player, profile.Data)
end

local function registerDebug()
	-- Studio only: read a save, and start a player over as a new account (the template, migrated).
	DebugService.Register("Data", function(who: any): any
		local player = DebugService.ResolvePlayer(who)
		local data = player and DataService.Get(player)
		return if data then Profile.View(data) else nil
	end)
	DebugService.Register("DataWipe", function(who: any): any
		local player = DebugService.ResolvePlayer(who)
		if not player then
			return { Ok = false, Error = "NoPlayer" }
		end
		return DataService.Change(player, "DataWipe", function(draft: Profile.Data): Transaction.Answer
			local fresh = Profile.Template()
			Migrations.Run(fresh)
			for key in draft :: any do
				(draft :: any)[key] = nil
			end
			for key, value in fresh :: any do
				(draft :: any)[key] = value
			end
			return { Ok = true }
		end)
	end)
	-- Adds Credits through the same door as any change, so a save and a rejoin can be checked without a menu.
	DebugService.Register("DataCredits", function(who: any, amount: any): any
		local player = DebugService.ResolvePlayer(who)
		if not player or type(amount) ~= "number" or amount ~= math.floor(amount) then
			return { Ok = false, Error = "BadArgs" }
		end
		return DataService.Change(player, "DataCredits", function(draft: Profile.Data): Transaction.Answer
			draft.Currency.Credits += amount
			return { Ok = true, Credits = draft.Currency.Credits }
		end)
	end)
	DebugService.Register("DataState", function(): string
		return `{STORE_NAME} store, DataStoreState {ProfileStore.DataStoreState}`
	end)
end

function DataService.Init()
	store = ProfileStore.New(STORE_NAME, Profile.Template() :: any) -- its type wants plain JSON; Saveable's case proves it
	-- The library retries on its own; these lines make a DataStore outage visible in the server's output.
	ProfileStore.OnError:Connect(function(message: string, storeName: string, key: string)
		Log.Warn("DataService", `DataStore error ({storeName}, {key}): {message}`)
	end)
	ProfileStore.OnCriticalToggle:Connect(function(critical: boolean)
		Log.Warn("DataService", if critical then "DataStore calls are failing often: saves are at risk" else "DataStore calls recovered")
	end)
	Net.Server.Handle("Act", onAct)
	Net.Server.Handle("ProfileGet", function(player: Player): Profile.View?
		local data = DataService.WaitFor(player)
		return if data then Profile.View(data) else nil
	end)
	if RunService:IsStudio() then
		registerDebug()
	end
end

function DataService.Start()
	Players.PlayerRemoving:Connect(function(player: Player)
		local session = sessions[player]
		sessions[player] = nil
		loading[player] = nil -- a load still running sees them gone and lets go of the save itself
		if session then
			session.Profile:EndSession()
		end
	end)
	Players.PlayerAdded:Connect(load)
	for _, player in Players:GetPlayers() do -- anyone who joined before Start
		task.spawn(load, player)
	end
	if RunService:IsStudio() then
		task.delay(5, function()
			Log.Info("DataService", `{STORE_NAME} store, DataStoreState {ProfileStore.DataStoreState}`)
		end)
	end
end

return DataService
