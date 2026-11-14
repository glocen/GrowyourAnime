--!strict
-- Migrations (shared, pure): how an older save becomes today's shape. Reconcile only adds keys the template gained; anything
-- that renames, moves or transforms is a step here (handbook/engineering/data-and-saving.md, "Migrations").
-- STEPS[n] upgrades a save from version n - 1 to n. A shipped step is never changed or reordered: add a new one, give it a
-- logic case, and list every table whose keys it touches. No Roblox API: it runs with Studio closed.

local Migrations = {}

local STEPS: { (data: any) -> () } = {
	function(_data: any) end, -- 1: the first shape (TR2, 2026-11-12)
	-- 2: the stat board (TR15, 2026-11-14). Touches Voidkin[id]: each owned Voidkin gains Points, nothing spent, so its
	-- points earned wait to be spent.
	function(data: any)
		for _, owned in data.Voidkin or {} do
			if type(owned) == "table" and type(owned.Points) ~= "table" then
				owned.Points = {}
			end
		end
	end,
}

-- The version a save reaches once migrated: the number of steps.
Migrations.Latest = #STEPS

-- Runs every step the save hasn't had yet, in order, after Reconcile and before the game reads it.
-- Returns how many ran. A save from a newer version than this server knows is left alone and reported, so an old server
-- never rewrites a newer shape; the caller refuses to play it (DataService).
function Migrations.Run(data: any): (number, boolean)
	local from = data.Version or 0
	if from > #STEPS then
		return 0, false
	end
	for version = from + 1, #STEPS do
		STEPS[version](data)
		data.Version = version
	end
	return #STEPS - from, true
end

return Migrations
