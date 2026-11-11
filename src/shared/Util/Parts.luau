--!strict
-- Parts: lookups on character-like models.

local Parts = {}

-- An R6 body's parts by name, so each is spelled once.
Parts.Limb = {
	Head = "Head", Torso = "Torso", LeftArm = "Left Arm", RightArm = "Right Arm", LeftLeg = "Left Leg", RightLeg = "Right Leg",
}

function Parts.Root(model: Instance?): BasePart?
	return if model then model:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
end

function Parts.Humanoid(model: Instance?): Humanoid?
	return if model then model:FindFirstChildOfClass("Humanoid") else nil
end

return Parts
