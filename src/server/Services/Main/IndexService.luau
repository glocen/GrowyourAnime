--!strict
-- IndexService (server): the Index's claim (TR76; docs/design.md, "The Index"; Rules.Index, Rules.IndexBook). One
-- transaction through DataService's actions, so a repeated or retried request pays once. The records it reads are kept
-- where things happen: a Shade's fall in DropService, a gear design in Rules.Chests and Rules.Shop.
--   Act "IndexClaim" ()   "Claim all": Rules.Index.Claim's answer, or refused Nothing

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Index = require(Shared.Rules.Index)
local Core = script.Parent.Parent.Core
local DataService = require(Core.DataService)

local IndexService = {
	Priority = 30, -- after DataService
}

function IndexService.Init()
	DataService.Action("IndexClaim", function(draft: Profile.Data): { [string]: any }
		return Index.Claim(draft)
	end)
end

function IndexService.Start() end

return IndexService
