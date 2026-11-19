--!strict
-- A foe on Hard (AR46, with AR47's masks): its rig's Hard look and its warm burst (Config.Shades.Hard). Apart from Cases.luau,
-- whose one table is past what the type solver takes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shades = require(ReplicatedStorage.Shared.Config.Shades)
local Helpers = require(script.Parent.Helpers)

local HardLooksCases = {}

local waitFor = Helpers.waitFor
local SHADE_AHEAD = 12 -- studs ahead of the avatar a test foe spawns, as Cases.luau's

-- The model of fighter `id` on this client, or nil.
local function fighterModel(id: string): Model?
	local fighters = workspace:FindFirstChild("Fighters")
	for _, model in (if fighters then fighters:GetChildren() else {}) do
		if model:IsA("Model") and model:GetAttribute("Fighter") == id then
			return model
		end
	end
	return nil
end

-- This player's lead in the world, or nil.
local function myLead(): Model?
	local fighters = workspace:FindFirstChild("Fighters")
	for _, model in (if fighters then fighters:GetChildren() else {}) do
		if model:IsA("Model") and model:GetAttribute("Side") == "Lead" and model:GetAttribute("Owner") == Players.LocalPlayer.UserId then
			return model
		end
	end
	return nil
end

-- The camera turned to where the test foes spawn, so the server's view of it counts them seen.
local function lookAhead(t: any)
	local camera = workspace.CurrentCamera
	local root = t.Root()
	local ahead = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	if camera and ahead.Magnitude > 1e-3 then
		local back = math.max(8, (camera.CFrame.Position - root.Position).Magnitude)
		camera.CFrame = CFrame.lookAt(root.Position - ahead.Unit * back + Vector3.new(0, 4, 0), root.Position + ahead.Unit * SHADE_AHEAD)
		t.Wait(0.5) -- the view's report reaches the server (ViewController, Net "View")
	end
end

function HardLooksCases.Cases(): { any }
	return {
	{
		Name = "Fight: a Hard foe wears its rig's Hard look and bursts warm",
		Run = function(t: any)
			-- AR46 with AR47's masks (Config.Shades.Hard): on Hard, the body and masks wear the rig's Hard look, the type's
			-- colour in the look's tint (TintMask) and the glow white; the masks keep their own light; the Lamplighter's
			-- lantern and pole keep their looks; the burst's pictures take Hard's tint and its scraps stay white.
			local lead = myLead()
			local level = if lead then lead:GetAttribute("Level") else nil
			t.Check("the lead is in the world", type(level) == "number")
			if type(level) ~= "number" then
				return
			end
			lookAhead(t)
			local white = Color3.new(1, 1, 1)
			local function spawn(def: string, difficulty: string?, ahead: number, part: string): (Model?, string?)
				local spawned = t.Server("FightSpawn", def, level, ahead, nil, difficulty)
				if type(spawned) ~= "table" or spawned.Ok ~= true then
					t.Check(`{def} spawns`, false, tostring(type(spawned) == "table" and spawned.Error))
					return nil, nil
				end
				local model: Model? = nil
				waitFor(t, 5, function(): boolean
					model = fighterModel(spawned.Id)
					return model ~= nil and model:FindFirstChild(part) ~= nil
				end)
				t.Check(`{def} on {difficulty or "Normal"} reaches this client`, model ~= nil)
				return model, spawned.Id
			end
			local function look(model: Model, name: string): SurfaceAppearance?
				local piece = model:FindFirstChild(name)
				return if piece then piece:FindFirstChildOfClass("SurfaceAppearance") else nil
			end
			local function bodyHard(body: SurfaceAppearance?, kind: string): boolean
				return body ~= nil
					and body.AlphaMode == Enum.AlphaMode.TintMask
					and body.Color == Shades.Tint[kind]
					and body.EmissiveTint == Shades.Hard.BodyTint
					and body.EmissiveStrength == Shades.Emissive
			end
			local function maskHard(mask: SurfaceAppearance?): boolean
				return mask ~= nil
					and mask.AlphaMode == Enum.AlphaMode.TintMask
					and mask.Color == white
					and mask.EmissiveTint == Shades.MaskTint
					and mask.EmissiveStrength == Shades.MaskEmissive
			end
			local function says(l: SurfaceAppearance?): string
				return if l then `{l.AlphaMode.Name}, {l.Color:ToHex()}, {l.EmissiveTint:ToHex()} at {l.EmissiveStrength}` else "no look"
			end
			-- the Shade: the elite, for its shoulder mask, beside a Normal one for its maps
			local normal = spawn("brawler", nil, SHADE_AHEAD, "Shade_Torso")
			local elite, eliteId = spawn("brawler_elite", "Hard", SHADE_AHEAD + 4, "Shade_Torso")
			if normal and elite then
				local kind = tostring(elite:GetAttribute("Type"))
				local body, mask, second = look(elite, "Shade_Torso"), look(elite, "Mask_Brawler"), look(elite, "EliteMask_Brawler")
				local plain = look(normal, "Shade_Torso")
				t.Check("the Shade says it's on Hard", elite:GetAttribute("Difficulty") == "Hard", tostring(elite:GetAttribute("Difficulty")))
				t.Check("its body: the type's colour in the look's tint, the glow white at the body's strength", bodyHard(body, kind), `{kind}: {says(body)}`)
				t.Check("its mask and its shoulder mask in a mask's own light, untinted", maskHard(mask) and maskHard(second), `{says(mask)}; {says(second)}`)
				t.Check(
					"its colour and glow maps are Hard's, its roughness its own",
					body ~= nil
						and plain ~= nil
						and body.ColorMapContent.Uri ~= plain.ColorMapContent.Uri
						and body.EmissiveMaskContent.Uri ~= plain.EmissiveMaskContent.Uri
						and body.RoughnessMapContent.Uri == plain.RoughnessMapContent.Uri
				)
				local normalKind = tostring(normal:GetAttribute("Type"))
				t.Check(
					"a Normal Shade keeps its look",
					plain ~= nil and plain.AlphaMode ~= Enum.AlphaMode.TintMask and plain.EmissiveTint == Shades.Tint[normalKind] and normal:GetAttribute("Difficulty") == nil,
					says(plain)
				)
			end
			-- the Lamplighter: body and head Hard, lantern and pole their own
			local keeper, keeperId = spawn("lamplighter", "Hard", SHADE_AHEAD + 8, "Lamplighter_Lantern")
			if keeper then
				local kind = tostring(keeper:GetAttribute("Type"))
				local body, head = look(keeper, "Lamplighter_Torso"), look(keeper, "Lamplighter_Head")
				local lantern, pole = look(keeper, "Lamplighter_Lantern"), look(keeper, "Lamplighter_Pole")
				t.Check("the Lamplighter's body on Hard", bodyHard(body, kind) and body ~= nil and body:GetAttribute("Glow") == "Body", `{kind}: {says(body)}`)
				t.Check("its head in a mask's light, untinted", maskHard(head) and head ~= nil and head:GetAttribute("Glow") == "Mask", says(head))
				t.Check(
					"its lantern and pole keep their looks",
					lantern ~= nil and pole ~= nil and lantern.AlphaMode ~= Enum.AlphaMode.TintMask and pole.AlphaMode ~= Enum.AlphaMode.TintMask and lantern:GetAttribute("Glow") == "Lantern"
				)
			end
			-- the burst: Hard's tint on every picture but the scraps
			if eliteId then
				t.Server("FightDefeat", eliteId)
			end
			if keeperId then
				t.Server("FightDefeat", keeperId)
			end
			local tinted, warm, scraps, whiteScraps = 0, 0, 0, 0
			waitFor(t, 3, function(): boolean
				local home = workspace:FindFirstChild("NL_Effects")
				local n = 0
				for _, anchor in (if home then home:GetChildren() else {}) do
					n += if anchor.Name == "NL_ShadeBurst" then 1 else 0
				end
				return n >= 2
			end)
			local home = workspace:FindFirstChild("NL_Effects")
			for _, anchor in (if home then home:GetChildren() else {}) do
				if anchor.Name == "NL_ShadeBurst" then
					for _, gui in anchor:GetChildren() do
						local image = gui:FindFirstChildOfClass("ImageLabel")
						if gui:IsA("BillboardGui") and image then
							if gui:GetAttribute("Kind") == "scrap" then
								scraps += 1
								whiteScraps += if image.ImageColor3 == white then 1 else 0
							else
								tinted += 1
								warm += if image.ImageColor3 == Shades.Hard.Burst then 1 else 0
							end
						end
					end
				end
			end
			t.Check("the Hard bursts' pictures in Hard's tint", tinted > 0 and warm == tinted, `{warm} of {tinted}`)
			t.Check("their scraps stay white", scraps > 0 and whiteScraps == scraps, `{whiteScraps} of {scraps}`)
			t.Server("FightSpawn") -- clears them
		end,
	},
	}
end

return HardLooksCases
