--!strict
-- Strip cases (pure): the Strip's kit (AR17, "The plan laid again at 128"), taken as it is (Config.Kits.Strip). The plan
-- names only its manifest's pieces, as often as its budget counts them, with its seven lights; laid from the festival's
-- gate, as Lantern Row's plan is, its crossing's mark stands on the crossing; and the great shard's steady glow in
-- Config.Lighting is the manifest's own.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Kit = require(Shared.World.Kit)
local LightingConfig = require(Shared.Config.Lighting)
local Manifest = require(Shared.Config.Kits.Strip.Manifest) :: any
local Plan = require(Shared.Config.Kits.Strip.Plan) :: any

local GATE_Z = -200 -- the festival's gate, the plan's origin (its "origin": the world's (0, floor, -200))

return {
	{
		Name = "Strip: AR17, the plan names only its manifest's pieces, as often as its budget counts them, with its seven lights",
		Run = function(t: any)
			local counted: { [string]: number } = {}
			local strangers: { string } = {}
			for index, placement in Plan.placements do
				if Manifest.pieces[placement.piece] == nil then
					table.insert(strangers, `{index}: {tostring(placement.piece)}`)
				end
				counted[placement.piece] = (counted[placement.piece] or 0) + 1
			end
			t.Equal("every placement's piece is in the manifest", table.concat(strangers, "; "), "")
			t.Equal("as many placements as the budget", #Plan.placements, Plan.budget.placements)
			local off: { string } = {}
			for name, count in Plan.budget.pieces do
				if counted[name] ~= count then
					table.insert(off, `{name}: {counted[name] or 0}, the budget {count}`)
				end
			end
			t.Equal("each piece as often as the budget", table.concat(off, "; "), "")
			t.Equal("seven real lights", #Plan.lights, 7)
			local named: { [string]: boolean } = {}
			local twice: { string } = {}
			for _, light in Plan.lights do
				if named[light.name] then
					table.insert(twice, light.name)
				end
				named[light.name] = true
			end
			t.Equal("each light named once", table.concat(twice, ", "), "")
		end,
	},
	{
		Name = "Strip: AR17, laid from the festival's gate, the crossing's mark stands on the crossing, and the great shard's steady glow is the manifest's",
		Run = function(t: any)
			local mark: any = nil
			for _, placement in Plan.placements do
				if placement.piece == "CrossingMark" then
					mark = placement
				end
			end
			t.Check("the plan has the crossing's mark", mark ~= nil)
			if mark then
				local at = Kit.Place(mark, Manifest.pieces.CrossingMark, GATE_Z, 0).Position
				t.Check("on the crossing, the world's origin", Vector2.new(at.X, at.Z).Magnitude < 1e-3, `{at.X}, {at.Z}`)
			end
			t.Equal("the shard's steady glow", LightingConfig.Steady.CrossingShard, Manifest.pieces.CrossingShard.glowStrength)
			t.Check("brighter than the kit's", LightingConfig.Steady.CrossingShard > LightingConfig.Glow.Kit)
		end,
	},
}
