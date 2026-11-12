--!strict
-- ProfileController (client): the player's read copy of their save, and the one way to ask the server to change it.
-- The copy comes whole from the server after every change (Services/Core/DataService); nothing here decides anything.
-- Act gives each request a fresh operation id and retries once with the same id, so a lost answer never applies twice.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Log = require(Shared.Util.Log)
local Signal = require(Shared.Util.Signal)
local Profile = require(Shared.Data.Profile)

local RETRY_AFTER = 1 -- seconds before the one retry of a request that got no answer

local ProfileController = {}

ProfileController.Changed = Signal.new() -- (view) whenever a new copy arrives

local view: Profile.View? = nil

local function take(newView: any)
	if type(newView) ~= "table" then
		return
	end
	view = newView
	ProfileController.Changed:Fire(newView)
end

-- The latest copy, or nil before the save has loaded.
function ProfileController.Get(): Profile.View?
	return view
end

-- Asks the server for an action by name and waits for its answer: { Ok = true, ... } or { Ok = false, Error = code }.
function ProfileController.Act(name: string, args: any?): { [string]: any }
	local opId = HttpService:GenerateGUID(false)
	for attempt = 1, 2 do
		local ok, answer = pcall(Net.Client.Invoke, "Act", opId, name, args)
		if ok and type(answer) == "table" then
			return answer
		end
		if attempt == 1 then
			task.wait(RETRY_AFTER)
		else
			Log.Warn("ProfileController", `{name} got no answer twice: {if ok then "none" else tostring(answer)}`)
		end
	end
	return { Ok = false, Error = "NoAnswer" }
end

function ProfileController.Init()
	Net.Client.On("Profile", take)
end

function ProfileController.Start()
	local first = Net.Client.Invoke("ProfileGet")
	if view == nil then -- a change may have arrived first, and it's newer
		take(first)
	end
end

return ProfileController
