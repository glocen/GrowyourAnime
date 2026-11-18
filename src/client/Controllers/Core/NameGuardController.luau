--!strict
-- NameGuardController (client, every place): keeps every label that shows a Voidkin's name out of Roblox's automatic
-- translation (the director, 2026-11-18, D8; Rules.Names). One rule in one place, so no screen built later can forget
-- it: a label or button under PlayerGui or in the world whose text holds a name has AutoLocalize off, and gets it back
-- when its text no longer does. Only the labels it turned off are turned back on, so one a screen set off stays off.
-- The words around a name in the same label stay untranslated with it (a split label would translate them).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Names = require(ReplicatedStorage.Shared.Rules.Names)

local MARK = "NL_NameKept" -- the attribute on a label this guard turned off

local NameGuardController = {}
NameGuardController.Priority = 1 -- before the screens build

local function check(label: TextLabel)
	local held = Names.Found(label.Text) ~= nil
	if held and label.AutoLocalize then
		label.AutoLocalize = false
		label:SetAttribute(MARK, true)
	elseif not held and label:GetAttribute(MARK) then
		label.AutoLocalize = true
		label:SetAttribute(MARK, nil)
	end
end

local function watch(object: Instance)
	if object:IsA("TextLabel") or object:IsA("TextButton") then
		local label = object :: any
		check(label)
		label:GetPropertyChangedSignal("Text"):Connect(function()
			check(label)
		end)
	end
end

local function cover(root: Instance)
	for _, object in root:GetDescendants() do
		watch(object)
	end
	root.DescendantAdded:Connect(watch)
end

function NameGuardController.Start()
	cover(Players.LocalPlayer:WaitForChild("PlayerGui"))
	cover(workspace)
end

return NameGuardController
