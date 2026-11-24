--!strict
-- The foes' looks on Hard (AR46, with AR47's masks): for each rig, the one SurfaceAppearance its body and masks wear on a
-- Hard stage, the cracks lit from within and the masks' cuts in the ember. The rig's lantern and pole keep their own.
-- Studio, Edit mode, MCP, after the rigs' templates are in ServerStorage.Templates:
--   local Assembly = require(game.ServerStorage.NL_Tools.ModelAssembly:Clone())
--   local looks = require(game.ServerStorage.NL_Tools.Models.HardLooks:Clone())()
-- then Assembly.Serialize(looks) into src/storage/HardLooks.rbxm (ServerStorage.Templates.HardLooks), which FightService
-- clones from: a script can't set a SurfaceAppearance's maps, only clone one that has them.
-- Each look is new, never a clone of the rig's: a published look can carry a texture pack of its maps (TexturePackContent,
-- which no script reads or clears), and a clone would keep the Normal maps' pack. It takes the Hard colour and glow maps,
-- and its roughness, metalness and normal map from the rig's body look. The
-- colour map is untinted, its alpha the type's share (AlphaMode TintMask): a spawn sets the look's Color to its type's,
-- which the glow carries, so one look serves every type (AR46, "The cut, for Faber"; the route, Faber's 2026-11-19).

local ServerStorage = game:GetService("ServerStorage")

-- Published under the group, 2026-11-19 (docs/asset-log.md), by tools/upload/upload_asset.py; the Shade's again on
-- 2026-11-23, cut on AR52's and AR58's masks.
local MAPS = {
	Shade = { Body = "Shade_Torso", Color = "rbxassetid://88064997894432", Emissive = "rbxassetid://117193991278361" },
	Lamplighter = {
		Body = "Lamplighter_Torso",
		Color = "rbxassetid://88822098427583",
		Emissive = "rbxassetid://98970262588387",
	},
}

return function(): Folder
	local templates = ServerStorage:WaitForChild("Templates")
	local folder = Instance.new("Folder")
	folder.Name = "HardLooks"
	for rig, maps in MAPS do
		local body = (templates:WaitForChild(rig) :: Model):FindFirstChild(maps.Body) :: MeshPart
		local own = body:FindFirstChildOfClass("SurfaceAppearance") :: SurfaceAppearance
		local look = Instance.new("SurfaceAppearance")
		look.Name = rig
		look.RoughnessMapContent = own.RoughnessMapContent
		look.MetalnessMapContent = own.MetalnessMapContent
		look.NormalMapContent = own.NormalMapContent
		look.ColorMapContent = Content.fromUri(maps.Color)
		look.EmissiveMaskContent = Content.fromUri(maps.Emissive)
		look.AlphaMode = Enum.AlphaMode.TintMask
		look.Color = Color3.new(1, 1, 1)
		look.Parent = folder
	end
	return folder
end
