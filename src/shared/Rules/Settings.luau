--!strict
-- Settings (shared, pure): a player's own levels (AR43, Settings in B; docs/ui.md, "Settings (music, sound,
-- effects)"). Music is the music's volume, Sound every other sound's, Effects how much of the fight's particles and
-- camera shake plays. Each is 0 to 1, kept in the save (Profile.Settings) so it follows the player to any server and
-- device, and set in whole hundredths, the slider's percent. Anything else is refused and changes nothing.
--   Settings.Levels                 the three, in the card's order
--   Settings.Level(data, name)      a level, 1 for a name the save doesn't hold
--   Settings.Set(data, args)        args { Name, Value }: { Ok, Name, Value } or { Ok = false, Error }
--   Settings.Said(value)            "Off" at nought, else its percent: "80%"

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)

local Settings = {}

Settings.Levels = { "Music", "Sound", "Effects" }
Settings.Unknown = "Unknown" -- not one of the three
Settings.Bad = "Bad" -- not a number from 0 to 1

function Settings.Level(data: Profile.Data, name: string): number
	local value = (data.Settings :: any)[name]
	return if type(value) == "number" then value else 1
end

function Settings.Set(data: Profile.Data, args: any): { [string]: any }
	local name = if type(args) == "table" then args.Name else nil
	local value = if type(args) == "table" then args.Value else nil
	if type(name) ~= "string" or table.find(Settings.Levels, name) == nil then
		return { Ok = false, Error = Settings.Unknown }
	end
	if type(value) ~= "number" or value ~= value or value < 0 or value > 1 then
		return { Ok = false, Error = Settings.Bad }
	end
	local kept = math.floor(value * 100 + 0.5) / 100
	;(data.Settings :: any)[name] = kept
	return { Ok = true, Name = name, Value = kept }
end

function Settings.Said(value: number): string
	local percent = math.floor(value * 100 + 0.5)
	return if percent <= 0 then "Off" else `{percent}%`
end

return Settings
