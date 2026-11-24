--!strict
-- SelfTestController (client, Studio only): runs the regression self-test inside a playtest and reports PASS/FAIL per check.
-- The checks live in Cases; the server half (test pad, scripted commands) is SelfTestService.
-- Run it from the MCP Client context or the client command bar:
--   game.ReplicatedStorage.NL_SelfTest:Invoke()            -- every check
--   game.ReplicatedStorage.NL_SelfTest:Invoke("Boot")      -- only checks whose name contains "Boot"
--   game.ReplicatedStorage.NL_SelfTest:Invoke("Scorecard") -- a Manual case list: numbers against targets, never in "every check"
-- A case with Place = "Main" or "Festival" runs only in that place's playtest, filtered or not (TR45; Util.PlaceRole);
-- the report's second line counts the ones left for the other place.
-- It returns the report as text. Leave the keyboard alone while it runs: real input would mix with the test's.
-- From the kit's controller, cut to this game: the player's avatar never fights (docs/design.md, "Combat"), so there's no
-- stamina, lock-on or entity state here. The lead's and the enemies' checks join when TR2 builds them.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScriptContext = game:GetService("ScriptContext")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Parts = require(Shared.Util.Parts)
local TestInput = require(Shared.Util.TestInput)
local PlaceRole = require(Shared.Util.PlaceRole)
local Cases = require(script.Cases)
local TowerCases = require(script.TowerCases)
local ModeCases = require(script.ModeCases)
local KitCases = require(script.KitCases)
local StateCases = require(script.StateCases)
local ButtonCases = require(script.ButtonCases)
local SoundCases = require(script.SoundCases)
local BreakerCases = require(script.BreakerCases)
local StripCases = require(script.StripCases)
local NoticeCases = require(script.NoticeCases)
local AuditionCases = require(script.AuditionCases)
local StageCases = require(script.StageCases)
local HardLooksCases = require(script.HardLooksCases)
local SlamCases = require(script.SlamCases)
local ShopCases = require(script.ShopCases)
local FunnelCases = require(script.FunnelCases)
local GearCases = require(script.GearCases)
local EquipmentCases = require(script.EquipmentCases)
local SettingsCases = require(script.SettingsCases)
local GoalCases = require(script.GoalCases)
local BaseController = require(script.Parent.Parent.Main.BaseController)
local Screen = require(script.Parent.Parent.Parent.UI.Kit.Screen)
local Button = require(script.Parent.Parent.Parent.UI.Kit.Button)
local Layers = require(script.Parent.Parent.Parent.UI.Layers)
local Theme = require(script.Parent.Parent.Parent.UI.Theme)
local GuiService = game:GetService("GuiService")

local BRIDGE_NAME = "NL_SelfTest"
local BASELINE = "Baseline" -- the preset the cases are written against
local SETTLE_TIMEOUT = 4 -- seconds to wait for the character to land and stand still on the pad
local SETTLED_SPEED = 0.5 -- studs/s: slower than this counts as standing still
local PRESS_TIME = 0.05

local player = Players.LocalPlayer

local SelfTestController = {}

export type Test = {
	Character: () -> Model,
	Root: () -> BasePart,
	Dummy: () -> Model?,
	Press: (action: string, hold: number?) -> (),
	Hold: (action: string, down: boolean) -> (),
	Move: (direction: Vector2) -> (), -- walks like a thumbstick: x right, y forward, from the camera; zero stops
	Wait: (seconds: number) -> (),
	Server: (command: string, ...any) -> ...any,
	Reset: () -> (),
	Check: (label: string, ok: boolean, detail: string?) -> (),
	Near: (label: string, actual: number, expected: number, tolerance: number) -> (),
	Equal: (label: string, actual: any, expected: any) -> (),
	Row: (label: string, low: number?, high: number?, ours: number?, unit: string) -> (), -- the Scorecard's: target, ours, pass or miss
}

local binding = TestInput.Binding
local moveBinding = TestInput.MoveBinding

-- Lets go of the stick, when the place has one.
local function releaseStick()
	local stick = moveBinding()
	if stick then
		stick:Fire(Vector2.zero)
	end
end

local function serverCall(command: string, ...: any): ...any
	local results = table.pack(Net.Client.Invoke("DebugCommand", command, ...))
	if not results[1] then
		error(`server command {command} failed: {tostring(results[2])}`, 2)
	end
	return table.unpack(results, 2, results.n)
end

local function run(filter: string?): string
	local lines: { string } = {}
	local passed, failed = 0, 0
	local current = ""
	local function record(ok: boolean, label: string, detail: string?, word: string?)
		if ok then
			passed += 1
		else
			failed += 1
		end
		table.insert(lines, `{word or if ok then "PASS" else "FAIL"}  {current} · {label}{if detail then " (" .. detail .. ")" else ""}`)
	end

	local t: Test
	t = {
		Character = function()
			return assert(player.Character, "no character")
		end,
		Root = function()
			return assert(Parts.Root(t.Character()), "no root")
		end,
		Dummy = function()
			return TestInput.PadDummy()
		end,
		Press = function(action: string, hold: number?)
			local b = binding(action)
			b:Fire(true)
			task.wait(hold or PRESS_TIME)
			b:Fire(false)
		end,
		Hold = function(action: string, down: boolean)
			binding(action):Fire(down)
		end,
		Move = function(direction: Vector2)
			local stick = assert(moveBinding(), "no character controls to steer: the place runs without Roblox's input-action controls")
			stick:Fire(direction)
		end,
		Wait = function(seconds: number)
			task.wait(seconds)
		end,
		Server = serverCall,
		-- Back on the pad, standing still on its floor, facing a fresh dummy when the game has one.
		Reset = function()
			releaseStick()
			serverCall("TestPad")
			local deadline = os.clock() + SETTLE_TIMEOUT
			repeat
				task.wait(0.1)
				local humanoid = Parts.Humanoid(t.Character())
				local settled = humanoid ~= nil
					and humanoid.FloorMaterial ~= Enum.Material.Air
					and t.Root().AssemblyLinearVelocity.Magnitude < SETTLED_SPEED
			until settled or os.clock() > deadline
			task.wait(0.2)
		end,
		Check = function(label: string, ok: boolean, detail: string?)
			record(ok, label, detail)
		end,
		Near = function(label: string, actual: number, expected: number, tolerance: number)
			record(math.abs(actual - expected) <= tolerance, label, `got {string.format("%.2f", actual)}, want {string.format("%.2f", expected)} ±{tolerance}`)
		end,
		-- The logic cases' own (LogicTestService), so a check moves between the two as it is.
		Equal = function(label: string, actual: any, expected: any)
			record(actual == expected, label, `got {tostring(actual)}, want {tostring(expected)}`)
		end,
		Row = function(label: string, low: number?, high: number?, ours: number?, unit: string)
			local reading = if ours then string.format("%.3g", ours) else "not measured"
			if not low or not high then
				table.insert(lines, `NOTE  {current} · {label} (ours {reading} {unit})`)
				return
			end
			local ok = ours ~= nil and ours >= low - 0.005 and ours <= high + 0.005 -- a frame's read lands on a target's edge
			local target = if low == high then string.format("%.3g", low) else string.format("%.3g to %.3g", low, high)
			record(ok, label, `target {target}, ours {reading} {unit}`, if ok then "PASS" else "MISS")
		end,
	}

	local started = os.clock()
	-- The client's frame rate over the run: a Studio window that isn't in front draws at 13-33 fps, and timing checks
	-- fail at that rate without anything being wrong.
	local frames = 0
	local counting = RunService.Heartbeat:Connect(function()
		frames += 1
	end)
	-- Script errors anywhere during the run fail it, on both sides: a case can pass while something it doesn't look at
	-- breaks.
	pcall(serverCall, "TestErrorsClear")
	local clientErrors: { string } = {}
	local watch = ScriptContext.Error:Connect(function(message: string, _trace: string, origin: Instance?)
		if origin and origin:IsDescendantOf(game) then -- the game's own scripts, not Studio plugins
			table.insert(clientErrors, `{message} ({origin:GetFullName()})`)
		end
	end)
	-- the cases are written against the game's own numbers, whichever preset is being played
	local benched, preset = pcall(serverCall, "Preset")
	if benched then
		serverCall("Preset", BASELINE)
		task.wait(0.3)
	end
	-- a shard that opens itself would race the cases that open theirs by hand (TR24's fix 5): off for the run, its own
	-- case turning it on
	local selfOpening = BaseController.SelfOpen(false)
	-- a screen left open hides the world's plates and holds the camera, failing cases that never touch it: closed, as a
	-- player's Back closes it (a run's held results, which open on join, are told seen and dropped from the save)
	if Screen.Current() ~= nil then
		Screen.Close()
		task.wait(0.3)
	end
	local cases: { any } = table.clone(Cases)
	-- more lists join here: table.move(More.Cases, 1, #More.Cases, #cases + 1, cases)
	local tower = TowerCases.Cases() -- the Tower's (TR29), apart: Cases is at the type checker's limit
	table.move(tower, 1, #tower, #cases + 1, cases)
	local kits = KitCases.Cases() -- a Voidkin's kit in play (AR11's install), apart for the same reason
	table.move(kits, 1, #kits, #cases + 1, cases)
	local states = StateCases.Cases() -- the element states in play (AR48), apart for the same reason
	table.move(states, 1, #states, #cases + 1, cases)
	local sounds = SoundCases.Cases() -- AR13's cues on the audio graph, apart for the same reason
	table.move(sounds, 1, #sounds, #cases + 1, cases)
	local breaker = BreakerCases.Cases() -- the galaxy Breaker (TR41), apart for the same reason
	table.move(breaker, 1, #breaker, #cases + 1, cases)
	local strip = StripCases.Cases() -- the Strip's kit (AR17), apart for the same reason
	table.move(strip, 1, #strip, #cases + 1, cases)
	local notice = NoticeCases.Cases() -- the level-up's notice (TR41 (c)), apart for the same reason
	table.move(notice, 1, #notice, #cases + 1, cases)
	local buttons = ButtonCases.Cases() -- the kit's buttons in the seam's make (AR30), apart for the same reason
	table.move(buttons, 1, #buttons, #cases + 1, cases)
	local audition = AuditionCases.Cases() -- the sound audition panel (TR42), apart for the same reason
	table.move(audition, 1, #audition, #cases + 1, cases)
	local stages = StageCases.Cases() -- a ground's stages (TR43), apart for the same reason
	table.move(stages, 1, #stages, #cases + 1, cases)
	local hard = HardLooksCases.Cases() -- a foe's Hard look (AR46), apart for the same reason
	table.move(hard, 1, #hard, #cases + 1, cases)
	local slams = SlamCases.Cases() -- the keeper's marked slam (TR44), apart for the same reason
	table.move(slams, 1, #slams, #cases + 1, cases)
	local shop = ShopCases.Cases() -- the Void Shop's screen and counter (AR38), apart for the same reason
	table.move(shop, 1, #shop, #cases + 1, cases)
	local funnel = FunnelCases.Cases() -- the first session measured (TR32), apart for the same reason
	table.move(funnel, 1, #funnel, #cases + 1, cases)
	local gear = GearCases.Cases() -- gear's own levels (TR47), apart for the same reason
	table.move(gear, 1, #gear, #cases + 1, cases)
	local equipment = EquipmentCases.Cases() -- Equipment's three in B (AR43), apart for the same reason
	table.move(equipment, 1, #equipment, #cases + 1, cases)
	local settings = SettingsCases.Cases() -- Settings in B (AR43), apart for the same reason
	table.move(settings, 1, #settings, #cases + 1, cases)
	local goals = GoalCases.Cases() -- TR54's goals: the Today list, the claim, the dare line and its card, apart for the same reason
	table.move(goals, 1, #goals, #cases + 1, cases)
	local modes = ModeCases.Cases() -- the Play panel (the director, 2026-11-24), apart for the same reason
	table.move(modes, 1, #modes, #cases + 1, cases)
	local elsewhere = 0
	pcall(serverCall, "TravelStub", true) -- no case ever leaves the place: each trip asked for is recorded (TR45)
	for _, case in cases do
		local chosen = if filter then string.find(case.Name, filter, 1, true) ~= nil else not case.Manual
		if chosen and case.Place ~= nil and not PlaceRole.Is(case.Place) then
			chosen = false
			elsewhere += 1
		end
		if chosen then
			current = case.Name
			local ok, err = pcall(function()
				if not case.Stay then -- Stay: the case checks the screen as it is
					t.Reset()
				end
				case.Run(t)
			end)
			if not ok then
				record(false, "crashed", tostring(err))
			end
		end
	end
	releaseStick() -- a case that crashed mid-walk never leaves the stick held
	BaseController.SelfOpen(selfOpening)
	pcall(serverCall, "TestPadClear")
	if benched then
		pcall(serverCall, "Preset", preset)
	end
	watch:Disconnect()
	current = "Script errors"
	local ok, serverErrors = pcall(serverCall, "TestErrors")
	local serverList = if ok and type(serverErrors) == "table" then serverErrors else {}
	record(#serverList == 0, "none on the server", serverList[1])
	record(#clientErrors == 0, "none on the client", clientErrors[1])

	pcall(serverCall, "TravelStub", false)
	counting:Disconnect()
	local seconds = os.clock() - started
	local rate = math.round(frames / math.max(seconds, 1e-3))
	table.insert(lines, 1, `SELF-TEST {if failed == 0 then "PASSED" else "FAILED"}: {passed} passed, {failed} failed ({string.format("%.1f", seconds)} s, {rate} fps)`)
	if rate < 50 then
		table.insert(lines, 2, `WARN  the client ran at {rate} fps: timing checks need about 60 (bring this Studio's window to the front)`)
	end
	if elsewhere > 0 then
		table.insert(lines, 2, `NOTE  {elsewhere} chosen case(s) belong to the other place: run them in its playtest ({PlaceRole.Current} here)`)
	end
	return table.concat(lines, "\n")
end

function SelfTestController.Start()
	if not RunService:IsStudio() then
		return
	end
	local bridge = Instance.new("BindableFunction")
	bridge.Name = BRIDGE_NAME
	bridge.OnInvoke = run
	bridge.Parent = ReplicatedStorage
	-- A kit button pressed by its path under PlayerGui, as a tap would: the MCP's mouse can't reach Roblox's top-bar row,
	-- where a band's buttons sit (Back, the stages' switch). game.ReplicatedStorage.NL_ClientPress:Invoke("NL_Band.Root...")
	local press = Instance.new("BindableFunction")
	press.Name = "NL_ClientPress"
	press.OnInvoke = function(path: string): (boolean, string)
		local at: Instance? = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
		for name in string.gmatch(path, "[^%.]+") do
			at = if at then at:FindFirstChild(name) else nil
		end
		if at == nil or not at:IsA("TextButton") then
			return false, `no kit button at {path}`
		end
		return Button.Press(at), at:GetFullName()
	end
	press.Parent = ReplicatedStorage
	-- The smallest phone for a capture: NL_ClientLayout:Invoke(true) lays every layer as the cases do (Theme.Smallest at
	-- the scale's floor, from the window's top left), :Invoke(false) the window again.
	local layout = Instance.new("BindableFunction")
	layout.Name = "NL_ClientLayout"
	layout.OnInvoke = function(smallest: boolean): string
		if smallest then
			Layers.Force(Theme.Scale.Floor)
			Layers.Box(Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height))
		else
			Layers.Box(nil)
			Layers.Force(nil)
		end
		return `scale {Layers.Scale()}`
	end
	layout.Parent = ReplicatedStorage
end

return SelfTestController
