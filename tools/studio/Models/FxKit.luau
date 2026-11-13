--!strict
-- The effect kit's templates (AR8, "The kit"; Config.FxKit), for the effect player (FighterController.Rows). Studio,
-- Edit mode, MCP:
--   local Assembly = require(game.ServerStorage.NL_Tools.ModelAssembly:Clone())
--   local kit = require(game.ServerStorage.NL_Tools.Models.FxKit:Clone())()
-- then Assembly.Serialize(kit) into src/shared/Assets/FxKit.rbxm (ReplicatedStorage.Shared.Assets.FxKit).
-- Meshes: one MeshPart per kit mesh, anchored, touching and casting nothing, at its unit size. Looks: one
-- SurfaceAppearance per mesh texture, the texture its own emissive mask (each pixel glows in its own colour, so the
-- effect reads at night as by day), at strength 1 and white tint; the player clones one onto a part and sets its strength
-- (a row's Glow). A script may set EmissiveTint and EmissiveStrength, never the maps, so the maps are set here.

local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function new(className: string, name: string, parent: Instance?): Instance
	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = parent
	return instance
end

return function(): Model
	local FxKit = require((ReplicatedStorage :: any).Shared.Config.FxKit:Clone()) :: any
	local kit = new("Model", "FxKit") :: Model
	local meshes = new("Folder", "Meshes", kit)
	for name, mesh in FxKit.Meshes do
		local part = AssetService:CreateMeshPartAsync(Content.fromUri(mesh.Id), {
			CollisionFidelity = Enum.CollisionFidelity.Box,
			RenderFidelity = Enum.RenderFidelity.Precise,
		})
		part.Name = name
		part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.Massless = true, false, false, false, true
		part.CastShadow = false
		part.Size = mesh.Size
		part.Parent = meshes
	end
	local looks = new("Folder", "Looks", kit)
	for name, image in FxKit.Images do
		if string.find(image.Use, "^MeshPart") then
			local look = new("SurfaceAppearance", name, looks) :: SurfaceAppearance
			look.ColorMapContent = Content.fromUri(image.Id)
			look.EmissiveMaskContent = Content.fromUri(image.Id)
			look.EmissiveStrength = 1
			look.EmissiveTint = Color3.new(1, 1, 1)
		end
	end
	return kit
end
