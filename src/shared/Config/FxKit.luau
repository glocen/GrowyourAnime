--!strict
-- FxKit (shared config): AR8's effect kit, made by Modulo (tools/blender/fx_kit.py; its recipe build/handoff/FxKit/fx_kit.json,
-- AR8 "The kit") and uploaded under the group on 2026-11-13. Written from the recipe and the uploads' ids: a remade kit
-- is uploaded and written again, never edited by hand.
-- Meshes: Size is the mesh's box at the unit size, and it's centred on that box; a MeshPart's Size over it is its scale.
-- Centre is that box's centre from the mesh's own origin in Blender (a coil's foot on the ground), at the unit size.
-- A coil's burn band (Of, Band 1 at the foot) sits at the coil's centre plus Offset times the coil's scale; they fade
-- foot first. A burning front (Of, Front n) sits where band n meets n + 1, the same way, shown while band n burns. The
-- crescent's Tail and Head are its two ends, in its unit space. Texture names the image family it takes (<P> a palette).
-- Images: the mesh textures in four palettes, opaque and in their own colours (a fade is the part's transparency); the
-- white ones are tinted by Color, for Beams, Trails and particles, set as Use says. The content check's conditions:
-- fx_ember is never tinted red or maroon, and never shed from a struck body falling under gravity; fx_flame is never
-- tinted red or dark.
-- Sheets (AR9, uploaded under the group on 2026-11-14, from build/handoff/FxKit/sheets/fx_sheets.json): seven flipbooks
-- in Grid4x4, each in three passes drawn white, its line on top, its fill and its dark twin under both, played as one
-- particle by an Emitter row's Sheet (Config.Effects). Sheet holds their tints, as the json gives them, and Layer, the
-- studs of ZOffset between passes. A sheet's Life is its drawn life in seconds, Break where it starts and ends tearing
-- (a share of its life), and FillColor the fill's colour over its life toward the cool tone, the last colour held to 1.
-- The content check's conditions (2026-11-14): no pass tinted in the red to maroon range, the fill only as FillColor
-- fades; the dark twin never plays alone, and performance mode drops it, never a bright pass; the starburst keeps its
-- nine uneven arms, never tinted dark as its main colour, never a fixed ground decal; the flame and the puff face the
-- camera, never laid flat; a hit's starburst or spark is a flash at the impact, never sprayed out of a body; no fixed
-- emblem from the crescent and the glint.

export type Mesh = { Id: string, Size: Vector3, Centre: Vector3, Texture: string, Of: string?, Band: number?, Front: number?, Offset: Vector3?, Tail: Vector3?, Head: Vector3? }
export type Image = { Id: string, Use: string }
export type Sheet = { Line: string, Fill: string, Dark: string, Life: number, Break: { number }, FillColor: { { any } } }

return {
	Meshes = {
		FxCoil3 = { Id = "rbxassetid://129024949260288", Size = Vector3.new(1.9611, 2.4696, 1.9192), Centre = Vector3.new(0.09147, 0.96654, 0.02642), Texture = "fx_across_<P>" },
		FxCoil3_Burn1 = { Id = "rbxassetid://94315196077634", Size = Vector3.new(1.955, 0.8783, 1.9192), Centre = Vector3.new(0.09452, 0.1709, 0.02642), Texture = "fx_across_<P>", Of = "FxCoil3", Band = 1, Offset = Vector3.new(0.0031, -0.7956, 0) },
		FxCoil3_Burn2 = { Id = "rbxassetid://115740508472757", Size = Vector3.new(1.6234, 0.8277, 1.7081), Centre = Vector3.new(-0.07735, 0.53713, 0.05406), Texture = "fx_across_<P>", Of = "FxCoil3", Band = 2, Offset = Vector3.new(-0.1688, -0.4294, 0.0276) },
		FxCoil3_Burn3 = { Id = "rbxassetid://140655357947421", Size = Vector3.new(1.4526, 0.776, 1.4348), Centre = Vector3.new(-0.00745, 0.90366, -0.07881), Texture = "fx_across_<P>", Of = "FxCoil3", Band = 3, Offset = Vector3.new(-0.0989, -0.0629, -0.1052) },
		FxCoil3_Burn4 = { Id = "rbxassetid://79064571481519", Size = Vector3.new(1.2702, 0.718, 1.2471), Centre = Vector3.new(0.05125, 1.26737, 0.02348), Texture = "fx_across_<P>", Of = "FxCoil3", Band = 4, Offset = Vector3.new(-0.0402, 0.3008, -0.0029) },
		FxCoil3_Burn5 = { Id = "rbxassetid://137270680317735", Size = Vector3.new(1.0574, 0.603, 1.0864), Centre = Vector3.new(-0.05515, 1.60843, 0.02447), Texture = "fx_across_<P>", Of = "FxCoil3", Band = 5, Offset = Vector3.new(-0.1466, 0.6419, -0.002) },
		FxCoil3_Burn6 = { Id = "rbxassetid://136137775020393", Size = Vector3.new(0.9251, 0.4446, 0.9362), Centre = Vector3.new(0.00597, 1.97905, -0.03968), Texture = "fx_across_<P>", Of = "FxCoil3", Band = 6, Offset = Vector3.new(-0.0855, 1.0125, -0.0661) },
		FxCoil2 = { Id = "rbxassetid://81311581474232", Size = Vector3.new(2.144, 2.4847, 1.7421), Centre = Vector3.new(0, 0.95923, 0), Texture = "fx_across_<P>" },
		FxCoil2_Burn1 = { Id = "rbxassetid://115148012192383", Size = Vector3.new(2.144, 0.9105, 1.608), Centre = Vector3.new(0, 0.17215, 0), Texture = "fx_across_<P>", Of = "FxCoil2", Band = 1, Offset = Vector3.new(0, -0.7871, 0) },
		FxCoil2_Burn2 = { Id = "rbxassetid://100232257515750", Size = Vector3.new(1.0445, 0.865, 1.7421), Centre = Vector3.new(0, 0.53841, 0), Texture = "fx_across_<P>", Of = "FxCoil2", Band = 2, Offset = Vector3.new(0, -0.4208, 0) },
		FxCoil2_Burn3 = { Id = "rbxassetid://77909537078760", Size = Vector3.new(1.3938, 0.8181, 1.3902), Centre = Vector3.new(0, 0.90479, 0), Texture = "fx_across_<P>", Of = "FxCoil2", Band = 3, Offset = Vector3.new(0, -0.0544, 0) },
		FxCoil2_Burn4 = { Id = "rbxassetid://120291802591756", Size = Vector3.new(1.3802, 0.7629, 1.0609), Centre = Vector3.new(0, 1.26762, 0), Texture = "fx_across_<P>", Of = "FxCoil2", Band = 4, Offset = Vector3.new(0, 0.3084, 0) },
		FxCoil2_Burn5 = { Id = "rbxassetid://106340762792151", Size = Vector3.new(0.7479, 0.6384, 1.111), Centre = Vector3.new(0, 1.60345, 0), Texture = "fx_across_<P>", Of = "FxCoil2", Band = 5, Offset = Vector3.new(0, 0.6442, 0) },
		FxCoil2_Burn6 = { Id = "rbxassetid://133240805993086", Size = Vector3.new(0.9028, 0.4576, 0.8986), Centre = Vector3.new(0, 1.9728, 0), Texture = "fx_across_<P>", Of = "FxCoil2", Band = 6, Offset = Vector3.new(0, 1.0136, 0) },
		FxCoil2_Front1 = { Id = "rbxassetid://110439867753165", Size = Vector3.new(1.1769, 0.7766, 1.7458), Centre = Vector3.new(0.00133, 0.47936, -0.00177), Texture = "fx_rise_<P>", Of = "FxCoil2", Front = 1, Offset = Vector3.new(0.0013, -0.4799, -0.0018) },
		FxCoil2_Front2 = { Id = "rbxassetid://82936505617570", Size = Vector3.new(1.0668, 0.7738, 1.5207), Centre = Vector3.new(0.00832, 0.86686, -0.00011), Texture = "fx_rise_<P>", Of = "FxCoil2", Front = 2, Offset = Vector3.new(0.0083, -0.0924, -0.0001) },
		FxCoil2_Front3 = { Id = "rbxassetid://81419179068803", Size = Vector3.new(1.4185, 0.5969, 0.3605), Centre = Vector3.new(0.0004, 1.16803, -0.0033), Texture = "fx_rise_<P>", Of = "FxCoil2", Front = 3, Offset = Vector3.new(0.0004, 0.2088, -0.0033) },
		FxCoil2_Front4 = { Id = "rbxassetid://114437914813899", Size = Vector3.new(0.8605, 0.6229, 1.157), Centre = Vector3.new(0.00432, 1.57586, -0.00269), Texture = "fx_rise_<P>", Of = "FxCoil2", Front = 4, Offset = Vector3.new(0.0043, 0.6166, -0.0027) },
		FxCoil2_Front5 = { Id = "rbxassetid://114537610593818", Size = Vector3.new(0.6552, 0.2451, 0.9612), Centre = Vector3.new(-0.00047, 1.85606, -0.00085), Texture = "fx_rise_<P>", Of = "FxCoil2", Front = 5, Offset = Vector3.new(-0.0005, 0.8968, -0.0008) },
		FxShell = { Id = "rbxassetid://133905388943735", Size = Vector3.new(2, 2, 2), Centre = Vector3.new(0, 0, 0), Texture = "fx_rise_<P> or fx_ribs_<P>" },
		FxHoop = { Id = "rbxassetid://87488287563359", Size = Vector3.new(2, 0.3, 2), Centre = Vector3.new(0, 0.15, 0), Texture = "fx_rise_<P>" },
		FxCrescent = { Id = "rbxassetid://87541901111854", Size = Vector3.new(0.827, 0.1709, 1.9696), Centre = Vector3.new(0.58648, 0.08554, 0), Texture = "fx_across_<P>", Tail = Vector3.new(-0.413, 0.085, 0.983), Head = Vector3.new(-0.413, 0.085, -0.983) },
		FxColumn = { Id = "rbxassetid://91771342329834", Size = Vector3.new(2, 2, 2), Centre = Vector3.new(0, 1, 0), Texture = "fx_rise_<P> or fx_ribs_<P>" },
		FxChip1 = { Id = "rbxassetid://80126931509779", Size = Vector3.new(1, 0.1424, 0.3469), Centre = Vector3.new(0, 0.00791, -0.02275), Texture = "fx_rise_<P>, or none: Neon in a Color" },
		FxChip2 = { Id = "rbxassetid://73433857318703", Size = Vector3.new(1, 0.1435, 0.3142), Centre = Vector3.new(0, 0.00797, -0.00961), Texture = "fx_rise_<P>, or none: Neon in a Color" },
		FxChip3 = { Id = "rbxassetid://98316106150756", Size = Vector3.new(1, 0.1578, 0.3694), Centre = Vector3.new(0, 0.00877, -0.0075), Texture = "fx_rise_<P>, or none: Neon in a Color" },
		FxBar = { Id = "rbxassetid://83429427811229", Size = Vector3.new(1, 1, 1), Centre = Vector3.new(0, 0, 0), Texture = "fx_across_<P>" },
		FxPlate = { Id = "rbxassetid://139534490464484", Size = Vector3.new(1, 1, 1), Centre = Vector3.new(0, 0, 0), Texture = "fx_rise_<P>" },
	} :: { [string]: Mesh },
	Images = {
		fx_across_Grey = { Id = "rbxassetid://139956977840496", Use = "MeshPart.TextureID: a coil's strands, the crescent" },
		fx_rise_Grey = { Id = "rbxassetid://86505958331228", Use = "MeshPart.TextureID: the column, the hoop, a shell, chips" },
		fx_ribs_Grey = { Id = "rbxassetid://72309753292474", Use = "MeshPart.TextureID: a lantern's ribs on a shell or a column" },
		fx_across_Flame = { Id = "rbxassetid://129312661900604", Use = "MeshPart.TextureID: a coil's strands, the crescent" },
		fx_rise_Flame = { Id = "rbxassetid://128227047654175", Use = "MeshPart.TextureID: the column, the hoop, a shell, chips" },
		fx_ribs_Flame = { Id = "rbxassetid://129765589635628", Use = "MeshPart.TextureID: a lantern's ribs on a shell or a column" },
		fx_across_Warm = { Id = "rbxassetid://139431469525913", Use = "MeshPart.TextureID: a coil's strands, the crescent" },
		fx_rise_Warm = { Id = "rbxassetid://108051234030070", Use = "MeshPart.TextureID: the column, the hoop, a shell, chips" },
		fx_ribs_Warm = { Id = "rbxassetid://133557308623166", Use = "MeshPart.TextureID: a lantern's ribs on a shell or a column" },
		fx_across_Ember = { Id = "rbxassetid://116333297359044", Use = "MeshPart.TextureID: a coil's strands, the crescent" },
		fx_rise_Ember = { Id = "rbxassetid://117388118542904", Use = "MeshPart.TextureID: the column, the hoop, a shell, chips" },
		fx_ribs_Ember = { Id = "rbxassetid://110868798137696", Use = "MeshPart.TextureID: a lantern's ribs on a shell or a column" },
		-- The Void palette's rise ramp (AR37's colour pass), alone of its set, uploaded under the group on 2026-11-23.
		fx_rise_Void = { Id = "rbxassetid://84217908322822", Use = "MeshPart.TextureID: the column, the hoop, a shell, chips" },
		fx_fire_Flame = { Id = "rbxassetid://122793873593321", Use = "MeshPart.TextureID: a coil's strands on fire (B1's bands)" },
		fx_beam = { Id = "rbxassetid://109017225338468", Use = "Beam or Trail: across it a bright core and a lower edge, clear outside; tiles along; TextureMode Wrap or Stretch; TextureSpeed 0 unless it flows" },
		fx_tongues = { Id = "rbxassetid://80204991292755", Use = "Beam or Trail: a flame's tongues off Attachment0's side (the image's left), tiles along; TextureSpeed for the lick to travel" },
		fx_streak = { Id = "rbxassetid://134352081493152", Use = "ParticleEmitter: a needle, moving left; Orientation VelocityParallel; Squash negative stretches it" },
		fx_spark = { Id = "rbxassetid://83717118055497", Use = "ParticleEmitter: a four-point glint" },
		fx_ember = { Id = "rbxassetid://89537844986662", Use = "ParticleEmitter: embers, one blob each; FlipbookMode Loop, FlipbookStartRandom on, FlipbookFramerate 0; Grid4" },
		fx_glow = { Id = "rbxassetid://94939686233018", Use = "ParticleEmitter or a card: a soft round light" },
		fx_flame = { Id = "rbxassetid://91223745290707", Use = "ParticleEmitter: a small flame, three tongues licking up from an open foot; FlipbookMode OneShot; Lifetime .3 to .5 s; frame 1 reads alone; Grid4" },
		fx_puff_line = { Id = "rbxassetid://80015808536826", Use = "ParticleEmitter: the puff sheet, its line pass, on top; Grid4x4, OneShot (Sheets)" },
		fx_puff_fill = { Id = "rbxassetid://104897900818095", Use = "ParticleEmitter: the puff sheet, its fill pass, under the line; Grid4x4, OneShot (Sheets)" },
		fx_puff_dark = { Id = "rbxassetid://75238188380938", Use = "ParticleEmitter: the puff sheet, its dark twin, under both, never alone; Grid4x4, OneShot (Sheets)" },
		fx_ring_line = { Id = "rbxassetid://87712839763842", Use = "ParticleEmitter: the ring sheet, its line pass, on top; Grid4x4, OneShot (Sheets)" },
		fx_ring_fill = { Id = "rbxassetid://83666517993335", Use = "ParticleEmitter: the ring sheet, its fill pass, under the line; Grid4x4, OneShot (Sheets)" },
		fx_ring_dark = { Id = "rbxassetid://128252841840506", Use = "ParticleEmitter: the ring sheet, its dark twin, under both, never alone; Grid4x4, OneShot (Sheets)" },
		fx_crescent_line = { Id = "rbxassetid://90373812318062", Use = "ParticleEmitter: the crescent sheet, its line pass, on top; Grid4x4, OneShot (Sheets)" },
		fx_crescent_fill = { Id = "rbxassetid://133187725108594", Use = "ParticleEmitter: the crescent sheet, its fill pass, under the line; Grid4x4, OneShot (Sheets)" },
		fx_crescent_dark = { Id = "rbxassetid://128621985420483", Use = "ParticleEmitter: the crescent sheet, its dark twin, under both, never alone; Grid4x4, OneShot (Sheets)" },
		fx_starburst_line = { Id = "rbxassetid://131453068509308", Use = "ParticleEmitter: the starburst sheet, its line pass, on top; Grid4x4, OneShot (Sheets)" },
		fx_starburst_fill = { Id = "rbxassetid://109794962011122", Use = "ParticleEmitter: the starburst sheet, its fill pass, under the line; Grid4x4, OneShot (Sheets)" },
		fx_starburst_dark = { Id = "rbxassetid://84399803865674", Use = "ParticleEmitter: the starburst sheet, its dark twin, under both, never alone; Grid4x4, OneShot (Sheets)" },
		fx_spark_line = { Id = "rbxassetid://111646557963038", Use = "ParticleEmitter: the spark sheet, its line pass, on top; Grid4x4, OneShot (Sheets)" },
		fx_spark_fill = { Id = "rbxassetid://97944193181411", Use = "ParticleEmitter: the spark sheet, its fill pass, under the line; Grid4x4, OneShot (Sheets)" },
		fx_spark_dark = { Id = "rbxassetid://126162968625202", Use = "ParticleEmitter: the spark sheet, its dark twin, under both, never alone; Grid4x4, OneShot (Sheets)" },
		fx_glint_line = { Id = "rbxassetid://127281761210366", Use = "ParticleEmitter: the glint sheet, its line pass, on top; Grid4x4, OneShot (Sheets)" },
		fx_glint_fill = { Id = "rbxassetid://98662090313268", Use = "ParticleEmitter: the glint sheet, its fill pass, under the line; Grid4x4, OneShot (Sheets)" },
		fx_glint_dark = { Id = "rbxassetid://102947252250145", Use = "ParticleEmitter: the glint sheet, its dark twin, under both, never alone; Grid4x4, OneShot (Sheets)" },
		fx_flame_line = { Id = "rbxassetid://89644885567823", Use = "ParticleEmitter: the flame sheet, its line pass, on top; Grid4x4, OneShot (Sheets)" },
		fx_flame_fill = { Id = "rbxassetid://121992633153804", Use = "ParticleEmitter: the flame sheet, its fill pass, under the line; Grid4x4, OneShot (Sheets)" },
		fx_flame_dark = { Id = "rbxassetid://96115015773612", Use = "ParticleEmitter: the flame sheet, its dark twin, under both, never alone; Grid4x4, OneShot (Sheets)" },
	} :: { [string]: Image },
	Sheet = { Layout = "Grid4x4", Mode = "OneShot", Line = Color3.fromHex("#FFF6E6"), Fill = Color3.fromHex("#E9E2D6"), Dark = Color3.fromHex("#1C1726"), Cool = Color3.fromHex("#5B5670"), DarkTransparency = 0.15, Layer = 0.05 },
	Sheets = {
		puff = { Line = "fx_puff_line", Fill = "fx_puff_fill", Dark = "fx_puff_dark", Life = 0.6, Break = { 0.45, 1 }, FillColor = { { 0, Color3.fromHex("#E9E2D6") }, { 0.45, Color3.fromHex("#E9E2D6") }, { 1, Color3.fromHex("#5B5670") } } },
		ring = { Line = "fx_ring_line", Fill = "fx_ring_fill", Dark = "fx_ring_dark", Life = 0.5, Break = { 0.34, 0.96 }, FillColor = { { 0, Color3.fromHex("#E9E2D6") }, { 0.34, Color3.fromHex("#E9E2D6") }, { 0.96, Color3.fromHex("#5B5670") }, { 1, Color3.fromHex("#5B5670") } } },
		crescent = { Line = "fx_crescent_line", Fill = "fx_crescent_fill", Dark = "fx_crescent_dark", Life = 0.4, Break = { 0.3, 0.97 }, FillColor = { { 0, Color3.fromHex("#E9E2D6") }, { 0.3, Color3.fromHex("#E9E2D6") }, { 0.97, Color3.fromHex("#5B5670") }, { 1, Color3.fromHex("#5B5670") } } },
		starburst = { Line = "fx_starburst_line", Fill = "fx_starburst_fill", Dark = "fx_starburst_dark", Life = 0.55, Break = { 0.36, 0.98 }, FillColor = { { 0, Color3.fromHex("#E9E2D6") }, { 0.36, Color3.fromHex("#E9E2D6") }, { 0.98, Color3.fromHex("#5B5670") }, { 1, Color3.fromHex("#5B5670") } } },
		spark = { Line = "fx_spark_line", Fill = "fx_spark_fill", Dark = "fx_spark_dark", Life = 0.3, Break = { 0.3, 1 }, FillColor = { { 0, Color3.fromHex("#E9E2D6") }, { 0.3, Color3.fromHex("#E9E2D6") }, { 1, Color3.fromHex("#5B5670") } } },
		glint = { Line = "fx_glint_line", Fill = "fx_glint_fill", Dark = "fx_glint_dark", Life = 0.35, Break = { 0.85, 1 }, FillColor = { { 0, Color3.fromHex("#E9E2D6") }, { 0.85, Color3.fromHex("#E9E2D6") }, { 1, Color3.fromHex("#5B5670") } } },
		flame = { Line = "fx_flame_line", Fill = "fx_flame_fill", Dark = "fx_flame_dark", Life = 0.7, Break = { 0.36, 0.98 }, FillColor = { { 0, Color3.fromHex("#E9E2D6") }, { 0.36, Color3.fromHex("#E9E2D6") }, { 0.98, Color3.fromHex("#5B5670") }, { 1, Color3.fromHex("#5B5670") } } },
	} :: { [string]: Sheet },
	-- Each palette's four colours, core to edge: a light or a tint that matches a mesh texture.
	Palettes = {
		Grey = { Core = Color3.fromHex("#F2F2F2"), Mid = Color3.fromHex("#C4C4C4"), Deep = Color3.fromHex("#8E8E8E"), Edge = Color3.fromHex("#55575C") },
		Flame = { Core = Color3.fromHex("#FFF4DC"), Mid = Color3.fromHex("#FFC65A"), Deep = Color3.fromHex("#FF8A3D"), Edge = Color3.fromHex("#A85A1A") },
		Warm = { Core = Color3.fromHex("#FFF3DC"), Mid = Color3.fromHex("#FFEBC2"), Deep = Color3.fromHex("#FFC98A"), Edge = Color3.fromHex("#A8682E") },
		Ember = { Core = Color3.fromHex("#FFF1CC"), Mid = Color3.fromHex("#FFCF73"), Deep = Color3.fromHex("#FFA630"), Edge = Color3.fromHex("#7A3E0E") },
	} :: { [string]: { [string]: Color3 } },
}
