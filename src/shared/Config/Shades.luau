--!strict
-- Shades (shared Config): how a Shade's body is lit, AR2's model (build/handoff/Shade/Shade.recipe.json). The body's lit
-- edges take its type's colour, and the mask its own warm white whatever the type, so it reads as paper at dusk. The
-- mask's tint is tuned in the engine under the game's lighting:
-- NL_Debug:Invoke("Tune", "Shades.MaskTint", Color3.fromHex("FFE2B8")), then spawn again.

return {
	-- The glow's strengths (SurfaceAppearance.EmissiveStrength), research's pick from the engine strip (AR2, section 6),
	-- half the recipe's 32 and 12: at 32 the bloom and tone map washed every type toward white. The glow mask is written
	-- for the two together, so tune both by the same factor, and look again at 64 px.
	Emissive = 16, -- the body's five pieces
	MaskEmissive = 6, -- a mask, the elite's second too
	-- The glow's tint for each type, the sheet's, except Red and Orange, which carry no green or blue: at 16 any
	-- green or blue in a tint passes the tone map's knee and lifts it toward white, so the sheet's showed coral and gold,
	-- these red and orange (AR2, section 6). Only the Shade's glow compensates: the type colours elsewhere stay.
	Tint = {
		Red = Color3.fromHex("E80000"),
		Orange = Color3.fromHex("F23000"),
		Blue = Color3.fromHex("3F9DF2"),
		Purple = Color3.fromHex("A470F2"),
		Green = Color3.fromHex("42CC7E"),
	} :: { [string]: Color3 },
	MaskTint = Color3.fromHex("FFE2B8"),
	-- A foe on a Hard stage (AR46, with AR47's masks): its body and masks wear its rig's Hard look
	-- (ServerStorage.Templates.HardLooks, tools/studio/Models/HardLooks.luau), the coat's cracks lit from within and the
	-- masks' cuts in the ember. The type's colour moves from the glow's tint into the look's own (SurfaceAppearance.Color,
	-- AlphaMode TintMask), which the glow carries, so the body's glow takes BodyTint at the same strength and every lit
	-- texel draws as on Normal; the masks keep MaskTint and MaskEmissive. Its burst's pictures take Burst, the scraps
	-- excepted: they stay white on every difficulty (the content check's condition, 2026-11-19, 18:19).
	Hard = {
		BodyTint = Color3.new(1, 1, 1),
		Burst = Color3.fromHex("FFB4A0"),
	},
}
