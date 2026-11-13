--!strict
-- RevealService (server): what the reveal's stage needs that only the server can make, put where every client reads it
-- (docs/test-requests.md, TR4). ReplicatedStorage.NL_Reveal holds the shard's pieces, MeshParts made from
-- Config.RevealArt's mesh ids, and a body for each Voidkin with a model (ServerStorage.Templates.<Model>) beside the grey
-- stand-in. Its Ready attribute turns true once all are in. The client clones them into its ViewportFrames
-- (src/client/UI/Reveal); nothing here decides what a player owns.

local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Shared
local Log = require(Shared.Util.Log)
local Art = require(Shared.Config.RevealArt)
local Voidkin = require(Shared.Definitions.Voidkin)
local FightService = require(script.Parent.FightService)

local LABEL = "Reveal"
local STAND_IN = "StandIn" -- the grey body's name among the figures

local RevealService = {}
RevealService.StandIn = STAND_IN

local folder: Folder

local function child(name: string, parent: Instance): Folder
	local made = Instance.new("Folder")
	made.Name = name
	made.Parent = parent
	return made
end

function RevealService.Init()
	folder = Instance.new("Folder")
	folder.Name = "NL_Reveal"
	child("Shard", folder)
	child("Figures", folder)
	folder:SetAttribute("Ready", false)
	folder.Parent = ReplicatedStorage
end

function RevealService.Start()
	local shard, figures = folder:FindFirstChild("Shard") :: Folder, folder:FindFirstChild("Figures") :: Folder
	for name, piece in Art.Shard.Pieces do
		local ok, made = pcall(function(): MeshPart
			return AssetService:CreateMeshPartAsync(Content.fromUri(piece.Id))
		end)
		if ok then
			made.Name = name
			made.Anchored = true
			made.CanCollide, made.CanQuery, made.CanTouch, made.CastShadow = false, false, false, false
			made.Parent = shard
		else
			Log.Error(LABEL, `the shard's {name} ({piece.Id}) didn't load: {made}`)
		end
	end
	local templates = ServerStorage:WaitForChild("Templates")
	for _, row in Voidkin.List do
		local model = (row :: any).Model :: string?
		local template = if model then templates:FindFirstChild(model) else nil
		if model and template and not figures:FindFirstChild(model) then
			local body = template:Clone()
			for _, item in body:GetDescendants() do
				if item:IsA("Script") or item:IsA("LocalScript") then
					item:Destroy()
				end
			end
			body.Parent = figures
		end
	end
	FightService.StandIn(STAND_IN).Parent = figures
	folder:SetAttribute("Ready", true)
end

return RevealService
