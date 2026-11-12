--!strict
-- Shades (shared Config): how a Shade's body is lit, AR2's model (build/handoff/Shade/Shade.recipe.json). The body's lit
-- edges take its type's colour, and the mask its own warm white whatever the type, so it reads as paper at dusk. The
-- tints are the sheet's proposal until AR3's gems fix them; the mask's is tuned in the engine under the game's lighting:
-- NL_Debug:Invoke("Tune", "Shades.MaskTint", Color3.fromHex("FFE2B8")), then spawn again.

return {
	Emissive = 2, -- the glow's strength on every piece (SurfaceAppearance.EmissiveStrength)
	Tint = {
		Strength = Color3.fromHex("EA4B4F"),
		Endurance = Color3.fromHex("F4902A"),
		Agility = Color3.fromHex("3F9DF2"),
		Intelligence = Color3.fromHex("A470F2"),
		Technique = Color3.fromHex("42CC7E"),
	} :: { [string]: Color3 },
	MaskTint = Color3.fromHex("FFE2B8"),
}
