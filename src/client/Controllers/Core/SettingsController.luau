--!strict
-- SettingsController (client): the player's own levels as they play (AR43's Settings; Rules.Settings). The save's
-- copy (ProfileController) is the truth; a slider held shows its level at once, before the release saves it (Preview),
-- and the save's next copy takes over. Each owner reads its level where it plays: the music's group
-- (MusicController), every other sound's (FighterController/Sounds), the fight's particles and the camera's shake
-- (FighterController/Rows, Effects).
--   SettingsController.Level(name)          Music, Sound or Effects, 0 to 1
--   SettingsController.Preview(name, value) the level heard and seen while a slider is held; nil lets the save's show
--   SettingsController.Keep(name, value)    a released slider's level, kept until the save's copy says otherwise
--   SettingsController.Changed              (name, level) whenever one changes

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Settings = require(Shared.Rules.Settings)
local Signal = require(Shared.Util.Signal)

local ProfileController = require(script.Parent.ProfileController)

local SettingsController = {
	Priority = 15, -- before the controllers that read a level as they start
}

SettingsController.Changed = Signal.new()

local saved: { [string]: number } = {}
local held: { [string]: number } = {}
local shown: { [string]: number } = {}

local function show(name: string)
	local level = held[name] or saved[name] or 1
	if shown[name] ~= level then
		shown[name] = level
		SettingsController.Changed:Fire(name, level)
	end
end

local function read(view: Profile.View)
	for _, name in Settings.Levels do
		saved[name] = Settings.Level(view :: any, name)
		show(name)
	end
end

function SettingsController.Level(name: string): number
	return shown[name] or saved[name] or 1
end

function SettingsController.Preview(name: string, value: number?)
	held[name] = if value then math.clamp(value, 0, 1) else nil
	show(name)
end

function SettingsController.Keep(name: string, value: number)
	saved[name] = math.clamp(value, 0, 1)
	held[name] = nil
	show(name)
end

function SettingsController.Start()
	ProfileController.Changed:Connect(read)
	local view = ProfileController.Get()
	if view then
		read(view)
	end
end

return SettingsController
