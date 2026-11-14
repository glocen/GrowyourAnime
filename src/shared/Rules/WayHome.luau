--!strict
-- WayHome (shared, pure): the trail home after a lone fall (docs/test-requests.md, TR16), from the avatar to the ground's
-- home door, the Festival Door's twin at the gate. Its points lie on the floor at the door's height, and the client joins
-- them with thin segments (Controllers.Main.WayHomeController). The street is one straight walled lane, so a line
-- between two points inside it stays inside it; an avatar out past the lane (in the elite's square, which opens wider
-- than the street) first steps square into it, so no leg crosses a stall front.
-- No Roblox API: it runs with Studio closed.

local WayHome = {}

-- The trail's points, from the avatar at `from` to the door at `door`, keeping to the lane `half` studs either side of
-- the street's middle at `centreX`: two points, or three when the avatar stands outside the lane.
function WayHome.Route(from: Vector3, door: Vector3, centreX: number, half: number): { Vector3 }
	local y = door.Y
	local lane = math.max(half, 0)
	local x = math.clamp(from.X, centreX - lane, centreX + lane)
	local points = { Vector3.new(from.X, y, from.Z) }
	if math.abs(x - from.X) > 1e-6 then
		table.insert(points, Vector3.new(x, y, from.Z))
	end
	table.insert(points, Vector3.new(door.X, y, door.Z))
	return points
end

-- How far the avatar at `from` stands from the door, on the floor.
function WayHome.Left(from: Vector3, door: Vector3): number
	return Vector3.new(from.X - door.X, 0, from.Z - door.Z).Magnitude
end

-- Whether the avatar has reached the door: within `reach` studs of it on the floor, where the trail is gone.
function WayHome.Arrived(from: Vector3, door: Vector3, reach: number): boolean
	return WayHome.Left(from, door) <= reach
end

-- A trail's length along its points.
function WayHome.Length(points: { Vector3 }): number
	local total = 0
	for index = 2, #points do
		total += (points[index] - points[index - 1]).Magnitude
	end
	return total
end

return WayHome
