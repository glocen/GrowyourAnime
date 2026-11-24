--!strict
-- WelcomeController (client): the welcome week's gift told as a toast (Rules.Welcome.Said; launch-design.md, section 8),
-- in the ready colour, once the server has given it. The words are stand-ins until research writes them (NOT VERIFIED:
-- built in the cloud, never seen in Studio).

local Shared = game:GetService("ReplicatedStorage").Shared
local Net = require(Shared.Net)
local Welcome = require(Shared.Rules.Welcome)
local UI = script.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Toast = require(UI.Kit.Toast)

local WelcomeController = {}

function WelcomeController.Start()
	Net.Client.On("Gift", function(answer: any)
		if type(answer) == "table" and type(answer.Gift) == "number" then
			Toast.Show(Welcome.Said(answer), Theme.Colour.Ready)
		end
	end)
end

return WelcomeController
