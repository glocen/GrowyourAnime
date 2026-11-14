--!strict
-- ModelAssembly: the Studio half of our art pipeline. tools/blender models and bakes; this publishes the meshes and
-- assembles game models from them. It runs in Edit mode from MCP execute_luau (plugin context), never in a game:
--   local Assembly = require(game.ServerStorage.NL_Tools.ModelAssembly:Clone()) -- a clone, so Rojo edits always load
-- Mesh data arrives through ServerStorage.NL_Import: build/import/<Name>.txt holds blcommon.export_mesh_json's JSON.
-- A published mesh keeps its vertex origin as the MeshPart's position, so exports are centred and record the centre
-- ("c"): parts are placed at Assembly.Centre(name). Slow work (publishing) runs as a named job: Assembly.Start(name, fn)
-- returns at once, Assembly.Status(name) reports "running", "done" (with the result) or the error.
-- A skinned mesh (tools/blender/skinfile.py) adds three fields to the import: "b", the bones, a parent always before its
-- children, each [name, the parent's index or -1, x, y, z, nine rotation numbers] in the space of "p"; "vb", four bone
-- indices a point; "vw", their four weights. The published mesh carries that skeleton and its weights, but a MeshPart
-- made from it has no Bone under it (measured on a two-bone bar): Assembly.Bones makes them, and a clip then moves them.
-- A model the asset maker hands off as a recipe is built by Assembly.Build(name), through ModelRecipe (one assembler for
-- every model: docs/engineering-plan.md, "Content at scale", item 2):
--   py tools/upload/stage_model.py <Name>   -- the recipe and the meshes to build/import, for NL_Import
--   local model = Assembly.Build("<Name>") -- from NL_Import.<Name>.recipe and NL_Tools.Models.<Name> (its install)
-- then Assembly.Serialize(model) into src/storage/<Name>.rbxm (ServerStorage.Templates.<Name>), and check it with
-- lune run tools/checks/models_offline.luau <Name>.

local AssetService = game:GetService("AssetService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local SerializationService = game:GetService("SerializationService")
local ServerStorage = game:GetService("ServerStorage")

local ModelRecipe = require(ServerStorage:WaitForChild("NL_Tools"):WaitForChild("ModelRecipe"):Clone()) :: any

type MeshData = {
	p: { number },
	n: { number },
	t: { number },
	f: { number },
	c: { number },
	b: { { any } }?,
	vb: { number }?,
	vw: { number }?,
}
type Job = { status: string, result: any }

local Assembly = {}

local FACE_BATCH = 2000 -- triangles added between yields, so Studio stays responsive
local BONE_SLOTS = 4 -- bones a point may follow: Roblox's limit, and the width of "vb" and "vw"
local BASE64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function import(name: string): any
	local value = ServerStorage:WaitForChild("NL_Import"):WaitForChild(name, 10)
	assert(value and value:IsA("StringValue"), `No import {name} (build/import/{name}.txt)`)
	return HttpService:JSONDecode(value.Value)
end

-- Where an import's mesh sits in model space (its bounding-box centre, the published mesh's origin).
function Assembly.Centre(name: string): Vector3
	local c = import(name).c
	return Vector3.new(c[1], c[2], c[3])
end

-- A bone's rest frame in the import's space, from its row of "b".
local function boneFrame(bone: { any }): CFrame
	return (CFrame.new :: any)(table.unpack(bone, 3, 14))
end

-- The skeleton and each point's weights. A slot with no weight is left out, so a point names each bone once (a spare
-- slot repeats the first bone); SetVertexBones comes before SetVertexBoneWeights.
local function skin(mesh: EditableMesh, vertices: { number }, data: MeshData)
	local rows, vb, vw = data.b :: { { any } }, data.vb :: { number }, data.vw :: { number }
	assert(#vb == #vertices * BONE_SLOTS and #vw == #vb, `"vb" and "vw" hold {BONE_SLOTS} slots a point`)
	local bones = {}
	for i, row in rows do
		local parent = bones[row[2] + 1]
		assert(parent or row[2] == -1, `{row[1]}: its parent comes after it`)
		bones[i] = mesh:AddBone({ Name = row[1], ParentId = parent, CFrame = boneFrame(row), Virtual = false })
	end
	for v, vertex in vertices do
		local ids, weights = {}, {}
		for slot = (v - 1) * BONE_SLOTS + 1, v * BONE_SLOTS do
			if vw[slot] > 0 then
				table.insert(ids, bones[vb[slot] + 1])
				table.insert(weights, vw[slot])
			end
		end
		mesh:SetVertexBones(vertex, ids)
		mesh:SetVertexBoneWeights(vertex, weights)
	end
end

-- An EditableMesh from an import: centred positions, per-face normals and UVs ("f" holds 9 indices a triangle), and
-- the skin when the import has one.
local function editable(data: MeshData): EditableMesh
	local mesh = AssetService:CreateEditableMesh()
	local p, n, t, f = data.p, data.n, data.t, data.f
	local vertices, normals, uvs = {}, {}, {}
	for i = 1, #p, 3 do
		table.insert(vertices, mesh:AddVertex(Vector3.new(p[i], p[i + 1], p[i + 2])))
	end
	for i = 1, #n, 3 do
		table.insert(normals, mesh:AddNormal(Vector3.new(n[i], n[i + 1], n[i + 2])))
	end
	for i = 1, #t, 2 do
		table.insert(uvs, mesh:AddUV(Vector2.new(t[i], t[i + 1])))
	end
	for i = 1, #f, 9 do
		local face = mesh:AddTriangle(vertices[f[i] + 1], vertices[f[i + 1] + 1], vertices[f[i + 2] + 1])
		mesh:SetFaceNormals(face, { normals[f[i + 3] + 1], normals[f[i + 4] + 1], normals[f[i + 5] + 1] })
		if #uvs > 0 then
			mesh:SetFaceUVs(face, { uvs[f[i + 6] + 1], uvs[f[i + 7] + 1], uvs[f[i + 8] + 1] })
		end
		if (i - 1) % (FACE_BATCH * 9) == 0 then
			task.wait()
		end
	end
	if data.b then
		skin(mesh, vertices, data)
	end
	return mesh
end

-- The import as an EditableMesh, nothing published: a local MeshPart to look at before an upload
-- (AssetService:CreateMeshPartAsync(Content.fromObject(mesh))).
function Assembly.Editable(name: string): EditableMesh
	return editable(import(name))
end

-- Publishes an import as a Mesh asset owned by the place's creator; returns the asset id. Yields for seconds.
function Assembly.PublishMesh(name: string, assetName: string, description: string): number
	local result, id = AssetService:CreateAssetAsync(editable(import(name)), Enum.AssetType.Mesh, {
		Name = assetName,
		Description = description,
		CreatorId = game.CreatorId,
		CreatorType = if game.CreatorType == Enum.CreatorType.Group
			then Enum.AssetCreatorType.Group
			else Enum.AssetCreatorType.User,
	})
	assert(result == Enum.CreateAssetResult.Success, `{assetName}: {result}`)
	return id
end

-- A new instance with properties, parented last.
function Assembly.New(className: string, parent: Instance, props: { [string]: any }?): Instance
	local instance = Instance.new(className)
	for key, value in props or {} do
		(instance :: any)[key] = value
	end
	instance.Parent = parent
	return instance
end

-- A published mesh as a MeshPart, its box for collisions and its triangles drawn whole.
local function meshPart(meshId: number): MeshPart
	return AssetService:CreateMeshPartAsync(Content.fromAssetId(meshId), {
		CollisionFidelity = Enum.CollisionFidelity.Box,
		RenderFidelity = Enum.RenderFidelity.Precise,
	})
end

-- A MeshPart of a published mesh at a model-space position, with no physics or queries (a held or worn prop).
function Assembly.MeshPart(model: Model, name: string, meshId: number, position: Vector3, props: { [string]: any }?): MeshPart
	return ModelRecipe.Place(meshPart(meshId), model, name, position, props)
end

-- Roblox's plain R6, cleaned of what a body of ours never wears (its scripts, face, meshes, colours, clothes), standing
-- with its root at (0, 3, 0): the recipe's frame.
function Assembly.R6(): Model
	local model = Players:CreateHumanoidModelFromDescriptionAsync(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R6)
	for _, item in model:GetDescendants() do
		if item:IsA("LuaSourceContainer") or item:IsA("Decal") or item:IsA("SpecialMesh") or item:IsA("BodyColors") or item:IsA("Clothing") or item:IsA("Accessory") or item:IsA("HumanoidDescription") then
			item:Destroy()
		end
	end
	model.PrimaryPart = model:FindFirstChild("HumanoidRootPart") :: BasePart
	model:PivotTo(CFrame.new(0, 3, 0))
	return model
end

-- A model from its recipe (NL_Import.<name>.recipe: tools/upload/stage_model.py copies it from the handoff) and its
-- install (NL_Tools.Models.<name>, tools/studio/Models/<name>.json: the published ids and the builder's calls).
function Assembly.Build(name: string): Model
	local installs = ServerStorage:WaitForChild("NL_Tools"):WaitForChild("Models")
	local install = installs:FindFirstChild(name)
	assert(install and install:IsA("ModuleScript"), `No install {name} (tools/studio/Models/{name}.json)`)
	return ModelRecipe.Build(import(`{name}.recipe`), require(install:Clone()) :: any, { Rig = Assembly.R6, Mesh = meshPart })
end

-- The Bones of a skinned import under its MeshPart, nested as the skeleton is, each at its rest frame; returns them by
-- name. A MeshPart's origin is its mesh's box centre, so the frames are taken from that centre, and a Bone that stands
-- away from the mesh's own bone would bend the skin at rest.
function Assembly.Bones(part: MeshPart, name: string): { [string]: Bone }
	local data = import(name)
	assert(data.b, `{name} has no bones ("b")`)
	local low, high = Vector3.one * math.huge, Vector3.one * -math.huge
	for i = 1, #data.p, 3 do
		local point = Vector3.new(data.p[i], data.p[i + 1], data.p[i + 2])
		low, high = low:Min(point), high:Max(point)
	end
	local origin = CFrame.new(((low :: Vector3) + (high :: Vector3)) / 2)
	local frames: { CFrame }, made: { Bone }, byName: { [string]: Bone } = {}, {}, {}
	for i, row in data.b do
		local parent = row[2] + 1
		local bone = Instance.new("Bone")
		bone.Name = row[1]
		frames[i] = boneFrame(row)
		bone.CFrame = (frames[parent] or origin):ToObjectSpace(frames[i])
		bone.Parent = made[parent] or part
		made[i], byName[row[1]] = bone, bone
	end
	return byName
end

-- Holds `part` to `to` where it stands now: a Weld with an explicit C0 (WeldConstraints in a cloned model don't hold
-- under Server Authority).
function Assembly.Weld(to: BasePart, part: BasePart): Weld
	return ModelRecipe.Weld(to, part)
end

-- An Attachment on `part` at a model-space position.
function Assembly.Attach(part: BasePart, name: string, position: Vector3): Attachment
	return ModelRecipe.Attach(part, name, position)
end

-- The model as .rbxm bytes in base64; decode it into src/shared/Assets/... (py -c "import base64 ...").
function Assembly.Serialize(model: Model): string
	local data = SerializationService:SerializeInstancesAsync({ model })
	local n = buffer.len(data)
	local out = table.create(math.ceil(n / 3))
	for i = 0, n - 1, 3 do
		local a = buffer.readu8(data, i)
		local b = if i + 1 < n then buffer.readu8(data, i + 1) else 0
		local c = if i + 2 < n then buffer.readu8(data, i + 2) else 0
		local v = a * 65536 + b * 256 + c
		local function char(shift: number): string
			local k = bit32.extract(v, shift, 6) + 1
			return BASE64:sub(k, k)
		end
		table.insert(out, char(18) .. char(12) .. (if i + 1 < n then char(6) else "=") .. (if i + 2 < n then char(0) else "="))
	end
	return table.concat(out)
end

-- Jobs live in _G: every require is a fresh clone, and the poll comes from a later MCP call.
local function jobs(): { [string]: Job }
	local shared = _G :: any
	shared.NL_Jobs = shared.NL_Jobs or {}
	return shared.NL_Jobs
end

function Assembly.Start(name: string, fn: () -> any)
	local job: Job = { status = "running", result = nil }
	jobs()[name] = job
	task.spawn(function()
		local ok, result = pcall(fn)
		job.status = if ok then "done" else `error: {result}`
		job.result = result
	end)
end

function Assembly.Status(name: string): (string, any)
	local job = jobs()[name]
	if not job then
		return "unknown", nil
	end
	return job.status, job.result
end

return Assembly
