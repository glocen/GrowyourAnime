--!strict
-- Shades (shared Config): how a Shade's body is lit, AR2's model (build/handoff/Shade/Shade.recipe.json). The body's lit
-- edges take its type's colour, and the mask its own warm white whatever the type, so it reads as paper at dusk. The
-- tints are the sheet's proposal until AR3's gems fix them; the mask's is tuned in the engine under the game's lighting:
-- NL_Debug:Invoke("Tune", "Shades.MaskTint", Color3.fromHex("FFE2B8")), then spawn again.

return {
	-- The glow's strengths (SurfaceAppearance.EmissiveStrength), the recipe's (AR2, section 4): the glow mask is written for
	-- these two over the colour map, so tune both by the same factor, and look again at 64 px.
	Emissive = 32, -- the body's five pieces
	MaskEmissive = 12, -- a mask, the elite's second too
	Tint = {
		Strength = Color3.fromHex("EA4B4F"),
		Endurance = Color3.fromHex("F4902A"),
		Agility = Color3.fromHex("3F9DF2"),
		Intelligence = Color3.fromHex("A470F2"),
		Technique = Color3.fromHex("42CC7E"),
	} :: { [string]: Color3 },
	MaskTint = Color3.fromHex("FFE2B8"),
}
