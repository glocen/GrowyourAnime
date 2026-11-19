--!strict
-- Migrations (shared, pure): how an older save becomes today's shape. Reconcile only adds keys the template gained; anything
-- that renames, moves or transforms is a step here (handbook/engineering/data-and-saving.md, "Migrations").
-- STEPS[n] upgrades a save from version n - 1 to n. A shipped step is never changed or reordered: add a new one, give it a
-- logic case, and list every table whose keys it touches. No Roblox API: it runs with Studio closed.

local Items = require(game:GetService("ReplicatedStorage").Shared.Definitions.Items)

local Migrations = {}

-- The five attributes of 2026-11-16 and the one of the two that took each one's job (TR36; docs/balance.md, "The stats"):
-- Strength the power and precision, Endurance the toughness and recovery. Step 8 reads it.
Migrations.OldAttributes = {
	Might = "Strength",
	Finesse = "Strength",
	Insight = "Strength",
	Vigor = "Endurance",
	Spirit = "Endurance",
} :: { [string]: string }

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
	-- 5: the base's levels (TR21, 2026-11-15). Touches Base.Bays: each bay gains its level, 1, and a base with fewer than
	-- level 1's two bays (TR2 opened one) gains empty ones up to two. Reconcile has already added Base.Level and
	-- Base.Machines.
	function(data: any)
		local base = data.Base
		if type(base) ~= "table" or type(base.Bays) ~= "table" then
			return
		end
		for _, bay in base.Bays do
			if type(bay) == "table" and type(bay.Level) ~= "number" then
				bay.Level = 1
			end
		end
		while #base.Bays < 2 do
			table.insert(base.Bays, { Worker = "", Level = 1 })
		end
	end,
	-- 6: class rules (TR26, 2026-11-16). Touches Presets[n]: each preset gains Hands, each class's weapon pair, and a hand
	-- found in its Slots moves under its item's class, or goes when its item is gone or isn't that hand's weapon. No save
	-- should hold one, since no item was granted before this step; the step makes sure.
	function(data: any)
		local items = if type(data.Items) == "table" then data.Items else {}
		for _, preset in data.Presets or {} do
			if type(preset) ~= "table" then
				continue
			end
			if type(preset.Hands) ~= "table" then
				preset.Hands = {}
			end
			local slots = if type(preset.Slots) == "table" then preset.Slots else {}
			for _, hand in { "Main Hand", "Off Hand" } do
				local id = slots[hand]
				if id == nil then
					continue
				end
				slots[hand] = nil
				local item = items[id]
				local row = if type(item) == "table" then Items.ById[item.Def] else nil
				if row and row.Class and row.Slot == hand then
					preset.Hands[row.Class] = preset.Hands[row.Class] or {}
					preset.Hands[row.Class][hand] = id
				end
			end
		end
	end,
	-- 7: an item's design (docs/design.md, Regalia, "An item's design"; 2026-11-16). Touches Items[id]: an item with no
	-- Design takes the one its id gives over the launch's three (Items.LaunchDesign), so it never moves after.
	function(data: any)
		for id, item in (if type(data.Items) == "table" then data.Items else {}) :: { [any]: any } do
			if type(item) == "table" and type(item.Design) ~= "number" then
				item.Design = Items.LaunchDesign(tostring(item.Id or id))
			end
		end
	end,
	-- 8: two attributes (TR36, the director's word of 2026-11-17). Touches Items[id].Lines: a line of one of the five
	-- retired attributes becomes the one of the two that took its job (OLD_ATTRIBUTES), its value kept, so the item still
	-- gives what it gave in points. Two old lines that land on one attribute merge into one line, their values summed,
	-- since an item never has a stat twice; the merged line takes the first one's place.
	function(data: any)
		for _, item in (if type(data.Items) == "table" then data.Items else {}) :: { [any]: any } do
			if type(item) ~= "table" or type(item.Lines) ~= "table" then
				continue
			end
			local kept: { any } = {}
			local at: { [string]: any } = {}
			for _, line in item.Lines do
				if type(line) ~= "table" then
					continue
				end
				local stat = if type(line.Stat) == "string" then (Migrations.OldAttributes[line.Stat] or line.Stat) else line.Stat
				local same = if type(stat) == "string" then at[stat] else nil
				if same and type(same.Value) == "number" and type(line.Value) == "number" then
					same.Value += line.Value
				else
					line.Stat = stat
					table.insert(kept, line)
					if type(stat) == "string" then
						at[stat] = line
					end
				end
			end
			item.Lines = kept
		end
	end,
	-- 9: the bays by base level, 2, 3 and 4 (D5, the director's yes of 2026-11-18), in place of 2, 4 and 6. Touches
	-- Base.Bays: a base holding more than its level opens keeps its first ones. A worker in a bay that goes is free again
	-- (the Voidkin stays owned: a bay only names it), and the bay's own level goes with it. Only Studio's Test saves can
	-- hold one, since the game hadn't opened. The counts are written here, not read from Config, so the step never moves.
	function(data: any)
		local base = data.Base
		if type(base) ~= "table" or type(base.Bays) ~= "table" then
			return
		end
		local level = if type(base.Level) == "number" then math.clamp(math.floor(base.Level), 1, 3) else 1
		local open = ({ 2, 3, 4 })[level]
		while #base.Bays > open do
			table.remove(base.Bays)
		end
	end,
	-- 10: the onboarding funnel's marks (TR32, Rules.Funnel). Touches Funnel. A save that had chosen its starter before the
	-- funnel was measured has played its first session already, so every step is marked and none is ever logged for it; a
	-- new account (its starter still "") keeps none, and logs each as it plays. The names are written here, not read from
	-- the rule, so the step never moves.
	function(data: any)
		if type(data.Funnel) ~= "table" then
			data.Funnel = {}
		end
		local progress = data.Progress
		if type(progress) ~= "table" or type(progress.Starter) ~= "string" or progress.Starter == "" then
			return
		end
		for _, name in { "Arrive", "Choose", "Reveal", "Fight", "Find", "Work", "Build", "Want" } do
			data.Funnel[name] = true
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
