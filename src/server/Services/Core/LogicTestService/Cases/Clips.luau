--!strict
-- Clips cases (pure): every clip a shipped fighter plays has a published id (Config.Animations.Ids). Without one a
-- client plays it from Studio's own store (FighterController/Clips: KeyframeSequenceProvider), which a live server
-- can't, so the fighter stands still outside Studio. Read from the rows, so a Voidkin made later is checked as it ships:
-- each made Voidkin (Definitions.Voidkin.Made) and each enemy on a rig, with their rig's reactions, their layers, their
-- kit's clips, their own idle, a Voidkin's reveal, a kind's own clips (Animations.Kinds) and each clip's mirror.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau). That a published clip is the one
-- saved in the place is the self-test's (KitCases, the server's TestClips): it needs the place.

local Shared = game:GetService("ReplicatedStorage").Shared
local Animations = require(Shared.Config.Animations)
local Actions = require(Shared.Definitions.Actions)
local Voidkin = require(Shared.Definitions.Voidkin)
local Enemies = require(Shared.Definitions.Enemies)
local RevealConfig = require(Shared.Config.Reveal)

-- Every clip the shipped fighters play, each with who plays it, in a stable order.
local function played(): { { Clip: string, By: string } }
	local seen: { [string]: string } = {}
	local order: { string } = {}
	local function add(clip: string?, by: string)
		if clip and seen[clip] == nil then
			seen[clip] = by
			table.insert(order, clip)
		end
	end
	local function action(id: string?, by: string)
		local row = if id then Actions.ById[id] else nil
		add(if row then row.Clip else nil, by)
	end
	local function rig(name: string?, by: string)
		local set = if name then Animations.Rigs[name] else nil
		if set then
			local roles: { string } = {}
			for as in set do
				table.insert(roles, as)
			end
			table.sort(roles)
			for _, as in roles do
				add(set[as], by)
			end
		end
	end
	for _, row in Voidkin.List do
		if Voidkin.Made(row) then
			local kit = row.Kit :: any
			rig(row.Rig or "R6", row.Name)
			for _, clip in Animations.Layers[row.Id] or {} do
				add(clip, row.Name)
			end
			action(kit.Signature, row.Name)
			action(kit.Combo, row.Name)
			action(kit.Skip, row.Name)
			add(kit.Idle, row.Name)
			-- the reveal's and the Voidkin screen's: its own Reveal when it has one, else the stand-in's (UI/Reveal/Figure)
			local reveal = if row.Model then `{row.Model}Reveal` else ""
			add(if RevealConfig.Strikes[reveal] then reveal else RevealConfig.Fallback, row.Name)
		end
	end
	for _, row in Enemies.List do
		if Animations.Rigs[row.Rig] then
			local by = `{row.Name} ({row.Kind})`
			rig(row.Rig, by)
			action(row.Action, by)
			action(row.Signature, by)
			action(row.Enter, by)
			add(row.Idle, by)
			for _, clip in table.clone(order) do
				local own = (Animations.Kinds[row.Kind] or {})[clip]
				if own and seen[clip] ~= nil then
					add(own, by)
				end
			end
		end
	end
	for _, clip in table.clone(order) do
		add(Animations.Mirrors[clip], seen[clip])
	end
	local list = {}
	for _, clip in order do
		table.insert(list, { Clip = clip, By = seen[clip] })
	end
	return list
end

return {
	{
		Name = "Clips: every clip a shipped fighter plays has a published id, so it moves outside Studio",
		Run = function(t: any)
			local list = played()
			t.Check("the fighters' clips found", #list > 0, tostring(#list))
			local missing: { string } = {}
			for _, entry in list do
				if Animations.Ids[entry.Clip] == nil then
					table.insert(missing, `{entry.Clip} ({entry.By})`)
				end
			end
			t.Check(`each of the {#list} published`, #missing == 0, `{#missing} with no id: {table.concat(missing, ", ")}`)
			for clip, id in Animations.Ids do
				t.Check(`{clip}: its id a whole asset id`, type(id) == "number" and id > 0 and id % 1 == 0, tostring(id))
			end
		end,
	},
}
