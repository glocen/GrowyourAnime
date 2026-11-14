--!strict
-- Count (client kit): a counter's number counting to its new value (TR6; docs/research/vfx-reference.md, "UI effects",
-- DESIGN 3): from the old to the new over Config.Hud.Motion.Count.Seconds, Expo out (Rules.Hud.ExpoOut), most of it fast
-- and only its end eased. A count can wait for its start (a flying reward's first landing): until then the counter
-- shows the old value, and it starts by Count.Latest whatever lands. With the player's reduced motion on, it changes at
-- once (DESIGN 5).
--   Count.Show(label, value, format)          what the counter holds now: shown at once, or the running count heads there
--   Count.Run(label, from, to, format, wait?) a count from `from` to `to`; with `wait`, it waits for Count.Start
--   Count.Start(label)                        a waiting count starts now
--   Count.Counting(label)                     true while it counts or waits, for tests

local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Hud = require(Shared.Rules.Hud)
local HudConfig = require(Shared.Config.Hud)

type Running = {
	From: number,
	To: number,
	Start: number?, -- os.clock() it started, nil while it waits
	Latest: number, -- os.clock() it starts by
	Format: (number) -> string,
}

local Count = {}

local running: { [TextLabel]: Running } = {}

function Count.Show(label: TextLabel, value: number, format: (number) -> string)
	local r = running[label]
	if r then
		r.To = value
		r.Format = format
	else
		label.Text = format(value)
	end
end

function Count.Run(label: TextLabel, from: number, to: number, format: (number) -> string, wait: boolean?)
	if GuiService.ReducedMotionEnabled or from == to then
		running[label] = nil
		label.Text = format(to)
		return
	end
	local now = os.clock()
	local was = running[label]
	-- A count already under way goes on from what it shows.
	local shownFrom = if was and was.Start then was.From + (was.To - was.From) * Hud.ExpoOut((now - was.Start) / HudConfig.Motion.Count.Seconds) else from
	running[label] = {
		From = shownFrom,
		To = to,
		Start = if wait then nil else now,
		Latest = now + HudConfig.Motion.Count.Latest,
		Format = format,
	}
	label.Text = format(shownFrom)
end

function Count.Start(label: TextLabel)
	local r = running[label]
	if r and r.Start == nil then
		r.Start = os.clock()
	end
end

function Count.Counting(label: TextLabel): boolean
	return running[label] ~= nil
end

RunService.RenderStepped:Connect(function()
	local now = os.clock()
	local seconds = HudConfig.Motion.Count.Seconds
	for label, r in running do
		if label.Parent == nil then
			running[label] = nil
			continue
		end
		if r.Start == nil then
			if now < r.Latest then
				continue
			end
			r.Start = now
		end
		local u = if seconds > 0 then (now - (r.Start :: number)) / seconds else 1
		if u >= 1 then
			label.Text = r.Format(r.To)
			running[label] = nil
		else
			label.Text = r.Format(r.From + (r.To - r.From) * Hud.ExpoOut(u))
		end
	end
end)

return Count
