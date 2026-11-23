--!strict
-- BaseFit (pure rules): part 7's tests for the base's size (docs/research/rework-2026-11-16.md, part 7, "The tests for
-- picking the size"), on the base plan's layout (Config.Kits.Base's `layout`) with each machine at its widest footprint
-- (Config.World.Fit.Prints, Stage III's, measured on the handoff's meshes). Across the plot from its middle line, inward
-- from its front edge, the gate's middle at (0, 0); a spot may turn its machine by quarter turns (`turn`, degrees).
--   Breaker  seconds at the walk from the gate to the Breaker's nearest side, at most Fit.Breaker
--   Least    the least gap between any two footprints, edge to edge, and its pair: at least Fit.Clear. Part 7 asks it of a
--            machine's front; the grey boxes have no front, so every side is held to it
--   Way      the machines on the way in: Fit.Avenue wide down the middle line, from the gate to the generator, none
--   Outside  the machines over the square's edge (Fit.Margin in), nearer the gate than Fit.Apron, or into the kept back
--   View     the widest corner's angle off the camera's line, the camera Fit.Camera.Back behind the gate looking in; all in
--            one view when it's under the horizontal half-view (Fit.Camera's vertical Fov at Aspect)
-- No Roblox API: it runs with Studio closed.

local BaseFit = {}

export type Spot = { across: number, inward: number, turn: number? }
export type Layout = {
	spawn: Spot,
	stations: { [string]: Spot },
	laterBays: { Spot },
	sleeping: { [string]: Spot },
}
-- A footprint: its middle's offset from its spot, its size across and inward, and its height.
export type Print = { Across: number, Inward: number, Wide: number, Deep: number, High: number }
export type Box = { Name: string, Kind: string, X0: number, X1: number, Z0: number, Z1: number, High: number }
export type Fit = {
	Breaker: number,
	Clear: number,
	Avenue: number,
	Apron: number,
	Margin: number,
	Camera: { Back: number, Fov: number, Aspect: number },
	Prints: { [string]: Print },
}
export type Report = {
	Size: number,
	Breaker: number,
	Least: number,
	Pair: { string },
	Way: { string },
	Outside: { string },
	View: number,
	HalfView: number,
	Row: number,
}

-- Each machine's spot by its name, as the plot names its stations: the seven stations, bays 3 to 6 from laterBays, and
-- the three sleeping places. Its kind, for its print: every bay is "bay" (a sleeping one wakes into one, so it's held to
-- a bay's), and the Forge, the Condenser and the Lab are their own.
function BaseFit.Spots(layout: Layout): { [string]: Spot }
	local out: { [string]: Spot } = {}
	for name, spot in layout.stations do
		out[name] = spot
	end
	for index, spot in layout.laterBays do
		out[`bay{index + 2}`] = spot
	end
	for name, spot in layout.sleeping do
		out[name] = spot
	end
	return out
end

function BaseFit.Kind(name: string): string
	if string.match(name, "^bay%d+$") then
		return "bay"
	end
	return name
end

-- A print as its spot turns it, by quarter turns about the spot (as tools/blender/base_fit.py turns a mesh: a half
-- turn mirrors its offset, a quarter swaps its size across and inward).
function BaseFit.Turned(print: Print, turn: number?): Print
	local quarters = math.round((turn or 0) / 90) % 4
	local across, inward = print.Across, print.Inward
	for _ = 1, quarters do
		across, inward = inward, -across
	end
	local swap = quarters % 2 == 1
	return {
		Across = across,
		Inward = inward,
		Wide = if swap then print.Deep else print.Wide,
		Deep = if swap then print.Wide else print.Deep,
		High = print.High,
	}
end

-- Every machine's footprint, sorted by name. A machine whose kind has no print is left out.
function BaseFit.Boxes(layout: Layout, prints: { [string]: Print }): { Box }
	local out: { Box } = {}
	for name, spot in BaseFit.Spots(layout) do
		local kind = BaseFit.Kind(name)
		local print = if prints[kind] then BaseFit.Turned(prints[kind], spot.turn) else nil
		if print then
			local x, z = spot.across + print.Across, spot.inward + print.Inward
			table.insert(out, {
				Name = name,
				Kind = kind,
				X0 = x - print.Wide / 2,
				X1 = x + print.Wide / 2,
				Z0 = z - print.Deep / 2,
				Z1 = z + print.Deep / 2,
				High = print.High,
			})
		end
	end
	table.sort(out, function(a: Box, b: Box): boolean
		return a.Name < b.Name
	end)
	return out
end

-- The gap between two footprints, edge to edge; minus the least way out of each other when they overlap.
function BaseFit.Gap(a: Box, b: Box): number
	local dx = math.max(0, math.max(a.X0, b.X0) - math.min(a.X1, b.X1))
	local dz = math.max(0, math.max(a.Z0, b.Z0) - math.min(a.Z1, b.Z1))
	if dx > 0 or dz > 0 then
		return math.sqrt(dx * dx + dz * dz)
	end
	return -math.min(a.X1 - b.X0, b.X1 - a.X0, a.Z1 - b.Z0, b.Z1 - a.Z0)
end

-- The horizontal half-view of a camera with vertical field `fov` degrees at `aspect`, in degrees.
function BaseFit.HalfView(fov: number, aspect: number): number
	return math.deg(math.atan(math.tan(math.rad(fov / 2)) * aspect))
end

-- The plot's own numbers, in studs: the walk a second, between neighbours, the kept back.
export type Plot = { Walk: number, Between: number, Kept: number }

-- Part 7's measures for `layout` on a `size`-stud square plot (a row of four end to end: Row).
function BaseFit.Measure(layout: Layout, size: number, fit: Fit, plot: Plot): Report
	local boxes = BaseFit.Boxes(layout, fit.Prints)
	local least, pair = math.huge, {}
	for i = 1, #boxes do
		for j = i + 1, #boxes do
			local gap = BaseFit.Gap(boxes[i], boxes[j])
			if gap < least then
				least, pair = gap, { boxes[i].Name, boxes[j].Name }
			end
		end
	end
	local generator: Box? = nil
	local breaker: Box? = nil
	for _, box in boxes do
		if box.Name == "generator" then
			generator = box
		elseif box.Name == "breaker" then
			breaker = box
		end
	end
	local way, outside = {}, {}
	local half = size / 2 - fit.Margin
	local view = 0
	for _, box in boxes do
		if box.X0 < -half or box.X1 > half or box.Z0 < fit.Apron or box.Z1 > size - plot.Kept then
			table.insert(outside, box.Name)
		end
		if generator and box ~= generator and box.Z0 < generator.Z0 and box.X0 < fit.Avenue / 2 and box.X1 > -fit.Avenue / 2 then
			table.insert(way, box.Name)
		end
		for _, x in { box.X0, box.X1 } do
			for _, z in { box.Z0, box.Z1 } do
				view = math.max(view, math.deg(math.atan2(math.abs(x), z + fit.Camera.Back)))
			end
		end
	end
	local seconds = math.huge
	if breaker then
		local x = math.clamp(0, breaker.X0, breaker.X1)
		local z = math.clamp(0, breaker.Z0, breaker.Z1)
		seconds = math.sqrt(x * x + z * z) / plot.Walk
	end
	return {
		Size = size,
		Breaker = seconds,
		Least = least,
		Pair = pair,
		Way = way,
		Outside = outside,
		View = view,
		HalfView = BaseFit.HalfView(fit.Camera.Fov, fit.Camera.Aspect),
		Row = 4 * size + 3 * plot.Between,
	}
end

-- Whether a report passes part 7's tests, and the ones it fails, in words.
function BaseFit.Passes(report: Report, fit: Fit): (boolean, { string })
	local fails = {}
	if report.Breaker > fit.Breaker then
		table.insert(fails, string.format("the Breaker %.1f s from the gate", report.Breaker))
	end
	if report.Least < fit.Clear then
		table.insert(fails, string.format("%s and %s %.1f studs apart", report.Pair[1] or "?", report.Pair[2] or "?", report.Least))
	end
	if #report.Way > 0 then
		table.insert(fails, `on the way in: {table.concat(report.Way, ", ")}`)
	end
	if #report.Outside > 0 then
		table.insert(fails, `outside: {table.concat(report.Outside, ", ")}`)
	end
	if report.View > report.HalfView then
		table.insert(fails, string.format("out of one view: %.0f° off the line, %.0f° seen", report.View, report.HalfView))
	end
	return #fails == 0, fails
end

-- One line for a report: its size, the measures and the verdict.
function BaseFit.Line(report: Report, fit: Fit): string
	local ok, fails = BaseFit.Passes(report, fit)
	return string.format(
		"%d studs: Breaker %.1f s, least gap %.1f (%s, %s), widest %.0f° of %.0f°, a row of four %d studs: %s",
		report.Size,
		report.Breaker,
		report.Least,
		report.Pair[1] or "?",
		report.Pair[2] or "?",
		report.View,
		report.HalfView,
		report.Row,
		if ok then "PASS" else `FAIL ({table.concat(fails, "; ")})`
	)
end

return BaseFit
