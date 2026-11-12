--!strict
-- Markers (shared): the one way code reads the world's markers (World.Tags), and the way a world builder stamps them.
-- Only markers inside workspace are live: masters and backups in storage carry the same tags. Report is the world report:
-- a place checked against the contract (handbook/engineering/architecture.md, "The world contract").

local CollectionService = game:GetService("CollectionService")

local Tags = require(script.Parent.Tags)
local Enemies = require(script.Parent.Parent.Definitions.Enemies)

local Markers = {}

local GROUND_REACH = 8 -- studs under a marker's centre the world report looks for its floor

local function spec(name: string): Tags.Spec
	local found = Tags[name]
	assert(found, `no marker "{name}" in World.Tags`)
	return found
end

-- Every live marker of `name`.
function Markers.All(name: string): { Instance }
	local live = {}
	for _, item in CollectionService:GetTagged(spec(name).Tag) do
		if item:IsDescendantOf(workspace) then
			table.insert(live, item)
		end
	end
	return live
end

-- The live marker of `name` whose attributes match every one in `where`, or nil.
function Markers.Find(name: string, where: { [string]: any }?): Instance?
	for _, item in Markers.All(name) do
		local matches = true
		for attribute, value in where or {} do
			if item:GetAttribute(attribute) ~= value then
				matches = false
				break
			end
		end
		if matches then
			return item
		end
	end
	return nil
end

-- Where a marker stands: a part's CFrame, a model's pivot.
function Markers.At(marker: Instance): CFrame
	if marker:IsA("BasePart") then
		return marker.CFrame
	elseif marker:IsA("Model") then
		return marker:GetPivot()
	end
	error(`marker {marker:GetFullName()} is neither a part nor a model`)
end

-- Marks `item` as a `name` marker with `attributes`, each checked against the contract.
function Markers.Stamp(item: Instance, name: string, attributes: { [string]: any }?)
	local s = spec(name)
	for attribute, value in attributes or {} do
		local want = s.Attributes[attribute]
		assert(want ~= nil, `{name} has no attribute {attribute}`)
		assert(typeof(value) == string.gsub(want, "%?$", ""), `{name}.{attribute} is a {want}, not a {typeof(value)}`)
		item:SetAttribute(attribute, value)
	end
	item:AddTag(s.Tag)
end

local function standsOnGround(item: Instance): boolean
	local at = Markers.At(item).Position
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { item }
	return workspace:Raycast(at + Vector3.new(0, 1, 0), Vector3.new(0, -GROUND_REACH, 0), params) ~= nil
end

-- What's wrong with this place's markers, against the contract and `plots` plots. Empty: the world is whole.
function Markers.Report(plots: number): { string }
	local problems = {}
	local function problem(text: string)
		table.insert(problems, text)
	end
	local names = {}
	for name in Tags do
		table.insert(names, name)
	end
	table.sort(names)
	for _, name in names do
		local s = Tags[name]
		local live = Markers.All(name)
		for _, item in live do
			local where = item:GetFullName()
			if not (item:IsA("BasePart") or item:IsA("Model")) then
				problem(`{name}: {where} is a {item.ClassName}, not a part or a model`)
				continue
			end
			for attribute, want in s.Attributes do
				local value = item:GetAttribute(attribute)
				local optional = string.sub(want, -1) == "?"
				if value == nil then
					if not optional then
						problem(`{name}: {where} has no {attribute}`)
					end
				elseif typeof(value) ~= string.gsub(want, "%?$", "") then
					problem(`{name}: {where}'s {attribute} is a {typeof(value)}, not a {want}`)
				end
			end
			local def = item:GetAttribute("Def")
			if s.Attributes.Def and type(def) == "string" and Enemies.ById[def] == nil then
				problem(`{name}: {where} names no enemy "{def}"`)
			end
			local plot = item:GetAttribute("Plot")
			if s.Attributes.Plot and type(plot) == "number" and (plot < 1 or plot > plots or plot % 1 ~= 0) then
				problem(`{name}: {where}'s Plot {plot} isn't 1 to {plots}`)
			end
			if s.Ground and not standsOnGround(item) then
				problem(`{name}: {where} has no ground under it`)
			end
		end
		if name == "Plot" then
			local seen: { [number]: boolean } = {}
			for _, item in live do
				local plot = item:GetAttribute("Plot")
				if type(plot) == "number" then
					if seen[plot] then
						problem(`Plot: {plot} is marked twice`)
					end
					seen[plot] = true
				end
			end
			for plot = 1, plots do
				if not seen[plot] then
					problem(`Plot: {plot} isn't marked`)
				end
			end
		elseif s.Per == "Plot" then
			for plot = 1, plots do
				local count = 0
				for _, item in live do
					if item:GetAttribute("Plot") == plot then
						count += 1
					end
				end
				if (s.Count and count ~= s.Count) or (s.Count == nil and count == 0) then
					problem(`{name}: plot {plot} has {count}, wants {s.Count or "one at least"}`)
				end
			end
		elseif (s.Count and #live ~= s.Count) or (s.Count == nil and #live == 0) then
			problem(`{name}: {#live} in the world, wants {s.Count or "one at least"}`)
		end
	end
	return problems
end

return Markers
