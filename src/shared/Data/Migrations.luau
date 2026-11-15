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
	-- 3: the stat board taken out, on the director's word (2026-11-14, night: "Remove now, tree later"). Touches
	-- Voidkin[id]: each owned Voidkin's Points goes, with every point spent on it; skill points come back in the tree.
	function(data: any)
		for _, owned in data.Voidkin or {} do
			if type(owned) == "table" then
				owned.Points = nil
			end
		end
	end,
	-- 4: the base as a power plant (TR18, 2026-11-15). Touches Base and Training: the battery's electricity becomes its
	-- charge in kWh, a tenth of it, so a full old battery (600) is a full new one (60); the Training machine's stamp goes,
	-- its time now kept by the base's clock. Reconcile has already added Base.Charge, Base.Power and Training's Trainee
	-- and Banked; a new profile has no Battery, so its charge stays the template's.
	function(data: any)
		local base = data.Base
		if type(base) == "table" and type(base.Battery) == "number" then
			base.Charge = base.Battery / 10
			base.Battery = nil
		end
		if type(data.Training) == "table" then
			data.Training.Stamp = nil
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
