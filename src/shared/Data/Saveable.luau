--!strict
-- Saveable (shared, pure): what a DataStore would silently lose or refuse in a value, listed by path. ProfileStore keeps only
-- the dense numeric part of an array and string keys of a map, and no Instances, functions or Roblox types
-- (handbook/engineering/data-and-saving.md, "ProfileStore"). Logic cases run it on every profile a rule leaves behind.
-- No Roblox API: it runs with Studio closed.

local Saveable = {}

local function walk(value: any, path: string, problems: { string }, seen: { [any]: boolean })
	local kind = type(value)
	if kind == "number" then
		if value ~= value or value == math.huge or value == -math.huge then
			table.insert(problems, `{path}: {value} isn't a finite number`)
		end
		return
	elseif kind == "string" or kind == "boolean" then
		return
	elseif kind ~= "table" then
		table.insert(problems, `{path}: a {typeof(value)} can't be saved`)
		return
	end
	if seen[value] then
		table.insert(problems, `{path}: the same table appears twice`)
		return
	end
	seen[value] = true
	local count, numeric, text = 0, 0, 0
	for key in value do
		count += 1
		if type(key) == "number" then
			numeric += 1
		elseif type(key) == "string" then
			text += 1
		else
			table.insert(problems, `{path}: a {typeof(key)} key can't be saved`)
		end
	end
	if numeric > 0 and text > 0 then
		table.insert(problems, `{path}: mixes numeric and string keys`)
	elseif numeric > 0 and #value ~= numeric then
		table.insert(problems, `{path}: an array with gaps ({numeric} entries, {#value} without a gap)`)
	end
	for key, inner in value do
		walk(inner, `{path}.{tostring(key)}`, problems, seen)
	end
end

-- Every problem in `value`, each with its path from `name`. An empty list means a save keeps it whole.
function Saveable.Problems(value: any, name: string?): { string }
	local problems: { string } = {}
	walk(value, name or "value", problems, {})
	return problems
end

return Saveable
