--!strict
-- Markers (shared): the one way code reads the world's markers (World.Tags), and the way a world builder stamps them.
-- Only markers inside workspace are live: masters and backups in storage carry the same tags. Report is the world report:
-- a place checked against the contract (handbook/engineering/architecture.md, "The world contract").

local CollectionService = game:GetService("CollectionService")

local Tags = require(script.Parent.Tags)
local Enemies = require(script.Parent.Parent.Definitions.Enemies)
local Grounds = require(script.Parent.Parent.Definitions.Grounds)
local WorldConfig = require(script.Parent.Parent.Config.World)

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

-- Whether `position` stands over plot `plot`'s floor (its "Plot" marker), at any height: a player's home, for the
-- HUD's chips and a lead's heal at home (docs/design.md, "Health carries"). No plot, no floor, or no position: false.
function Markers.OnPlot(plot: number?, position: Vector3?): boolean
	local floor = if plot then Markers.Find("Plot", { Plot = plot }) else nil
	if floor == nil or not floor:IsA("BasePart") or position == nil then
		return false
	end
	local offset = floor.CFrame:PointToObjectSpace(position)
	return math.abs(offset.X) <= floor.Size.X / 2 and math.abs(offset.Z) <= floor.Size.Z / 2
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

-- Takes every contract tag off `item` and all inside it: a copy of a marked thing that isn't a marker itself.
function Markers.Unstamp(item: Instance)
	for _, s in Tags do
		item:RemoveTag(s.Tag)
		for _, inside in item:GetDescendants() do
			inside:RemoveTag(s.Tag)
		end
	end
end

local function standsOnGround(item: Instance): boolean
	local at = Markers.At(item).Position
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { item }
	return workspace:Raycast(at + Vector3.new(0, 1, 0), Vector3.new(0, -GROUND_REACH, 0), params) ~= nil
end

-- What's wrong with this place's markers, against the contract and `plots` plots. Empty: the world is whole. With
-- `owned`, a plot's own markers are wanted only on the plots in it, and none on the rest (a bare lot until its owner
-- arrives); without it, on every plot. With `place`, only that place's markers are checked, and the other place's must
-- be absent (Tags' Place, TR45).
function Markers.Report(plots: number, owned: { [number]: boolean }?, place: string?): { string }
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
		local wanted = if s.Cut and WorldConfig.Cut[s.Cut] then 0 else s.Count -- none while it's cut (AR65)
		if place and s.Place ~= place then
			if #live > 0 then
				problem(`{name}: {#live} in the world, wants none: it belongs in the {s.Place} place`)
			end
			continue
		end
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
			for _, attribute in { "Def", "With" } do
				local def = item:GetAttribute(attribute)
				if s.Attributes[attribute] and type(def) == "string" and Enemies.ById[def] == nil then
					problem(`{name}: {where}'s {attribute} names no enemy "{def}"`)
				end
			end
			local ground = item:GetAttribute("Ground")
			if s.Attributes.Ground and type(ground) == "string" and Grounds.ById[ground] == nil then
				problem(`{name}: {where} names no ground "{ground}"`)
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
				if owned and not owned[plot] then
					if count > 0 then
						problem(`{name}: plot {plot} is no one's and has {count}, wants none`)
					end
				elseif (wanted and count ~= wanted) or (wanted == nil and count == 0) then
					problem(`{name}: plot {plot} has {count}, wants {if wanted == 0 then "none while it's cut" else wanted or "one at least"}`)
				end
			end
		elseif (wanted and #live ~= wanted) or (wanted == nil and #live == 0) then
			problem(`{name}: {#live} in the world, wants {if wanted == 0 then "none while it's cut" else wanted or "one at least"}`)
		end
	end
	return problems
end

return Markers
