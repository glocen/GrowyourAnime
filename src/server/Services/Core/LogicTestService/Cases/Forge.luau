--!strict
-- Forge cases (pure): the ram's strike through one Reinforce try (TR37; Rules.Forge, Config.World.Forge, the base plan's
-- machines.forge): at rest before and after, up to its tell and never past it, down to the plate and never through it,
-- held there for the hitstop, and each beat in its order. Expected values come from Config and the plan.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Forge = require(Shared.Rules.Forge)
local WorldConfig = require(Shared.Config.World)
local BasePlan: any = require(Shared.Config.Kits.Base.Plan)

local function near(a: number, b: number, tolerance: number?): boolean
	return math.abs(a - b) <= (tolerance or 1e-6)
end

return {
	{
		Name = "Forge: TR37, a strike lifts the ram to its tell, drops it on the plate, holds it there and settles it at rest",
		Run = function(t: any)
			local plan = BasePlan.machines.forge.ram
			local ram: Forge.Ram = { Rest = plan.rest, Tell = plan.tell, Contact = plan.contact }
			local timing: Forge.Timing = WorldConfig.Forge
			local up, down = ram.Tell - ram.Rest, ram.Contact - ram.Rest
			t.Equal("at rest before", Forge.Rise(0, ram, timing), 0)
			t.Check("at its tell as the lift ends", near(Forge.Rise(timing.Lift - 1e-9, ram, timing), up, 1e-6))
			t.Check("on the plate as the strike lands", near(Forge.Rise(timing.Lift + timing.Strike, ram, timing), down))
			t.Check("held there through the hitstop", near(Forge.Rise(timing.Lift + timing.Strike + timing.Hold * 0.5, ram, timing), down))
			t.Equal("at rest once done", Forge.Rise(Forge.Length(timing) + 0.01, ram, timing), 0)
			local highest, lowest = 0, 0
			for step = 0, 400 do
				local h = Forge.Rise(step / 400 * (Forge.Length(timing) + 0.05), ram, timing)
				highest, lowest = math.max(highest, h), math.min(lowest, h)
			end
			t.Check("never past its tell", highest <= up + 1e-9, `{highest}`)
			t.Check("never through the plate", lowest >= down - 1e-9, `{lowest}`)
			t.Check("the strike is quicker than the lift", timing.Strike < timing.Lift)
			local beats = {}
			for _, at in { 0.01, timing.Lift + 0.01, timing.Lift + timing.Strike + 0.01, timing.Lift + timing.Strike + timing.Hold + 0.01, Forge.Length(timing) + 0.01 } do
				table.insert(beats, Forge.Beat(at, timing))
			end
			t.Equal("its beats in order", table.concat(beats, " "), "Lift Strike Hold Back Done")
		end,
	},
}
