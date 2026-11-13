--!strict
-- FxKit (shared config): AR8's effect kit, made by Modulo (tools/blender/fx_kit.py; its recipe build/handoff/FxKit/fx_kit.json,
-- AR8 "The kit") and uploaded under the group on 2026-11-13. Written from the recipe and the uploads' ids: a remade kit
-- is uploaded and written again, never edited by hand.
-- Meshes: Size is the mesh's box at the unit size, and it's centred on that box; a MeshPart's Size over it is its scale.
-- Centre is that box's centre from the mesh's own origin in Blender (a coil's foot on the ground), at the unit size.
-- A coil's burn band (Of, Band 1 at the foot) sits at the coil's centre plus Offset times the coil's scale; they fade
-- foot first. The crescent's Tail and Head are its two ends, in its unit space. Texture names the image family it takes
-- (<P> a palette).
-- Images: the mesh textures in four palettes, opaque and in their own colours (a fade is the part's transparency); the
-- white ones are tinted by Color, for Beams, Trails and particles, set as Use says. The content check's conditions:
-- fx_ember is never tinted red or maroon, and never shed from a struck body falling under gravity; fx_flame is never
-- tinted red or dark.

export type Mesh = { Id: string, Size: Vector3, Centre: Vector3, Texture: string, Of: string?, Band: number?, Offset: Vector3?, Tail: Vector3?, Head: Vector3? }
export type Image = { Id: string, Use: string }

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
		FxShell = { Id = "rbxassetid://133905388943735", Size = Vector3.new(2, 2, 2), Centre = Vector3.new(0, 0, 0), Texture = "fx_rise_<P> or fx_ribs_<P>" },
		FxHoop = { Id = "rbxassetid://87488287563359", Size = Vector3.new(2, 0.3, 2), Centre = Vector3.new(0, 0.15, 0), Texture = "fx_rise_<P>" },
		FxCrescent = { Id = "rbxassetid://87541901111854", Size = Vector3.new(0.827, 0.1709, 1.9696), Centre = Vector3.new(0.58648, 0.08554, 0), Texture = "fx_across_<P>", Tail = Vector3.new(-0.413, 0.085, 0.983), Head = Vector3.new(-0.413, 0.085, -0.983) },
		FxColumn = { Id = "rbxassetid://91771342329834", Size = Vector3.new(2, 2, 2), Centre = Vector3.new(0, 1, 0), Texture = "fx_rise_<P> or fx_ribs_<P>" },
		FxChip1 = { Id = "rbxassetid://80126931509779", Size = Vector3.new(1, 0.1424, 0.3469), Centre = Vector3.new(0, 0.00791, -0.02275), Texture = "fx_rise_<P>, or none: Neon in a Color" },
		FxChip2 = { Id = "rbxassetid://73433857318703", Size = Vector3.new(1, 0.1435, 0.3142), Centre = Vector3.new(0, 0.00797, -0.00961), Texture = "fx_rise_<P>, or none: Neon in a Color" },
		FxChip3 = { Id = "rbxassetid://98316106150756", Size = Vector3.new(1, 0.1578, 0.3694), Centre = Vector3.new(0, 0.00877, -0.0075), Texture = "fx_rise_<P>, or none: Neon in a Color" },
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
		fx_beam = { Id = "rbxassetid://109017225338468", Use = "Beam or Trail: across it a bright core and a lower edge, clear outside; tiles along; TextureMode Wrap or Stretch; TextureSpeed 0 unless it flows" },
		fx_tongues = { Id = "rbxassetid://80204991292755", Use = "Beam or Trail: a flame's tongues off Attachment0's side (the image's left), tiles along; TextureSpeed for the lick to travel" },
		fx_streak = { Id = "rbxassetid://134352081493152", Use = "ParticleEmitter: a needle, moving left; Orientation VelocityParallel; Squash negative stretches it" },
		fx_spark = { Id = "rbxassetid://83717118055497", Use = "ParticleEmitter: a four-point glint" },
		fx_ember = { Id = "rbxassetid://89537844986662", Use = "ParticleEmitter: embers, one blob each; FlipbookMode Loop, FlipbookStartRandom on, FlipbookFramerate 0; Grid4" },
		fx_glow = { Id = "rbxassetid://94939686233018", Use = "ParticleEmitter or a card: a soft round light" },
		fx_flame = { Id = "rbxassetid://91223745290707", Use = "ParticleEmitter: a small flame, three tongues licking up from an open foot; FlipbookMode OneShot; Lifetime .3 to .5 s; frame 1 reads alone; Grid4" },
	} :: { [string]: Image },
	-- Each palette's four colours, core to edge: a light or a tint that matches a mesh texture.
	Palettes = {
		Grey = { Core = Color3.fromHex("#F2F2F2"), Mid = Color3.fromHex("#C4C4C4"), Deep = Color3.fromHex("#8E8E8E"), Edge = Color3.fromHex("#55575C") },
		Flame = { Core = Color3.fromHex("#FFF4DC"), Mid = Color3.fromHex("#FFC65A"), Deep = Color3.fromHex("#FF8A3D"), Edge = Color3.fromHex("#A85A1A") },
		Warm = { Core = Color3.fromHex("#FFF3DC"), Mid = Color3.fromHex("#FFEBC2"), Deep = Color3.fromHex("#FFC98A"), Edge = Color3.fromHex("#A8682E") },
		Ember = { Core = Color3.fromHex("#FFF1CC"), Mid = Color3.fromHex("#FFCF73"), Deep = Color3.fromHex("#FFA630"), Edge = Color3.fromHex("#7A3E0E") },
	} :: { [string]: { [string]: Color3 } },
}
