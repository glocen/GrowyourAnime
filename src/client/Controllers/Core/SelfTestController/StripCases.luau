--!strict
-- StripCases (client, Studio only): the Strip's kit (AR17), a list of its own that joins the run apart from Cases (Cases is
-- at the type checker's limit); its helpers are Helpers'. The world report counts the kit against its plan on the server;
-- this list checks what the player sees of it at the crossing: laid from the festival's gate, and the great shard's steady
-- glow.

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Kit = require(Shared.World.Kit)
local LightingConfig = require(Shared.Config.Lighting)
local LightingController = require(script.Parent.Parent.Parent.Main.LightingController)
local Helpers = require(script.Parent.Helpers)

local STRIP = "Strip"
local ARRIVE = 8 -- seconds for a respawned avatar to land
local STREAM_IN = 6 -- seconds for the crossing's pieces to stream in round the avatar
local STAND = 4 -- the avatar's root over the crossing's paving (its top at 0.6), as it stands at home
local DRESSED = 1 -- seconds for a piece just streamed in to take its glow

local StripCases = {}

-- The Strip's piece `name` streamed in on this client, the nearest the crossing.
local function piece(name: string): BasePart?
	local best: BasePart? = nil
	for _, item in CollectionService:GetTagged(Kit.Tag) do
		if item:IsA("BasePart") and item:GetAttribute("Kit") == STRIP and item:GetAttribute("Piece") == name then
			if best == nil or item.Position.Magnitude < best.Position.Magnitude then
				best = item
			end
		end
	end
	return best
end

function StripCases.Cases(): { any }
	local waitFor = Helpers.waitFor
	return {
		{
			Name = "World: AR17, the Strip wears its kit: whole on the world report, laid from the festival's gate so the crossing's mark is on the crossing, and the great shard glows steady over it",
			Run = function(t: any)
				local problems = t.Server("DressReport", "Street")
				local stripLines = {}
				for _, line in (if type(problems) == "table" then problems else {}) do
					if string.find(line, "Strip", 1, true) then
						table.insert(stripLines, line)
					end
				end
				t.Check("the world report has no word on the Strip", type(problems) == "table" and #stripLines == 0, table.concat(stripLines, "; "))
				-- At the crossing (the world's origin), looking up the side street to the festival's gate: on the street's own
				-- height, never the test pad's (3000 up, past the streaming radius, so nothing of the crossing would come in).
				t.Server("TestStandAt", Vector3.new(0, STAND, 14), Vector3.new(0, STAND, -40))
				local mark, shard, post = nil, nil, nil
				waitFor(t, STREAM_IN, function(): boolean
					mark, shard, post = piece("CrossingMark"), piece("CrossingShard"), piece("StripPost")
					return mark ~= nil and shard ~= nil and post ~= nil
				end)
				t.Check("the crossing's mark, its great shard and a post stream in", mark ~= nil and shard ~= nil and post ~= nil)
				if mark then
					local flat = Vector2.new(mark.Position.X, mark.Position.Z)
					t.Check("the mark lies on the crossing, the world's origin", flat.Magnitude < 0.5, string.format("%.2f studs off", flat.Magnitude))
				end
				if shard then
					local flat = Vector2.new(shard.Position.X, shard.Position.Z)
					t.Check("the great shard hangs over it", flat.Magnitude < 3, string.format("%.2f studs off", flat.Magnitude))
				end
				-- Its glow is its own, times the phase's share without Clear's lift; a post's is the kit's, with the lift. A piece
				-- streamed in this frame is dressed by the lighting's deferred handler at the frame's end: DRESSED gives it that.
				local shardLook = if shard then shard:FindFirstChildOfClass("SurfaceAppearance") else nil
				local postLook = if post then post:FindFirstChildOfClass("SurfaceAppearance") else nil
				local steady, kit = 0, 0
				local function dressed(): boolean
					local look = LightingController.Look()
					steady, kit = LightingConfig.Steady.CrossingShard * look.Steady, LightingConfig.Glow.Kit * look.Glow
					return shardLook ~= nil and postLook ~= nil and math.abs(shardLook.EmissiveStrength - steady) < 1e-3
						and math.abs(postLook.EmissiveStrength - kit) < 1e-3
				end
				waitFor(t, DRESSED, dressed)
				t.Check("the great shard glows at its steady strength", shardLook ~= nil and math.abs(shardLook.EmissiveStrength - steady) < 1e-3,
					if shardLook then string.format("%.3f, want %.3f", shardLook.EmissiveStrength, steady) else "no look")
				t.Check("a post glows as the kit does", postLook ~= nil and math.abs(postLook.EmissiveStrength - kit) < 1e-3,
					if postLook then string.format("%.3f, want %.3f", postLook.EmissiveStrength, kit) else "no look")
				t.Check("the shard's steady share is the kit's without Clear's lift", steady < LightingConfig.Steady.CrossingShard * LightingController.Look().Glow,
					string.format("steady %.2f, the kit's share %.2f", LightingController.Look().Steady, LightingController.Look().Glow))
				-- Home again.
				local old = Players.LocalPlayer.Character
				t.Check("the avatar goes home", t.Server("Respawn") == true and waitFor(t, ARRIVE, function(): boolean
					local character = Players.LocalPlayer.Character
					return character ~= nil and character ~= old and character:FindFirstChild("HumanoidRootPart") ~= nil
				end))
			end,
		},
	}
end

return StripCases
