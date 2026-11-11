--!strict
-- Cases (server, Studio only): every logic case list, one child module per rule module, joined in name order.
-- A list whose rules are pure also runs with Studio closed, from the project's folder:
--   lune run tools/checks/logic_offline.luau src/server/Services/Core/LogicTestService/Cases
-- So a pure list requires its rules through game:GetService("ReplicatedStorage"), never through `script`.

local all = {}
local lists = script:GetChildren()
table.sort(lists, function(a: Instance, b: Instance): boolean
	return a.Name < b.Name
end)
for _, list in lists do
	if list:IsA("ModuleScript") then
		for _, case in require(list :: any) :: { any } do
			table.insert(all, case)
		end
	end
end
return all
