--!strict
-- ElementsEven (Studio tool, during a playtest, from the Server context): AR48's even-elements check (docs/design.md,
-- "States in a fight", "The elements stay even"). The player's lead, at level 1 and bare (its Voidkin's own block, no
-- stars, nothing worn: NL_Debug LeadElement), hits in each element by turns against Lantern Row's first pack stood on a pad
-- of its own: four brawlers at level 1 in the pack's ring (Rules.Fight.PackRing, Config.World.Row.Spread), 24 studs ahead.
-- Each run starts with the lead whole and 11 s after the last, so its cooldowns are back; each round plays every element
-- once, its order turned by one. A run's line: its clear time (to the last fall), the lead's health lost, its falls and the
-- freezes it saw. Spawned Shades pay no experience, so the lead stays at level 1. A timing test: one at a time, the window
-- in front. About 32 s a run. It puts the lead's level and experience back as it found them, and its own block.
--   require(game.ServerStorage.NL_Tools.ElementsEven:Clone())(10)   ten rounds, detached; then read the lines in
--   game.ServerStorage.NL_ElementsEven.Value, ending DONE (or ERROR), and summarise them with
--   py tools/balance/elements_even.py <file>

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Fight = require(ReplicatedStorage.Shared.Rules.Fight)
local WorldConfig = require(ReplicatedStorage.Shared.Config.World)

local ELEMENTS = { "Fire", "Frost", "Storm", "Void" }
local PACK = { Def = "brawler", Count = 4, Level = 1 } -- Lantern Row's Pack 1 (Config.World.Row.Stops)
local PAD_AT = Vector3.new(800, 2500, 0) -- far from the map, the replay's pad and the self-test's
local PAD_SIZE = Vector3.new(200, 4, 200)
local AHEAD = 24 -- studs from the player to the pack's centre
local REST = 11 -- seconds between runs
local LONGEST = 120 -- seconds a run may take before it's called

local function debug(...: any): any
	local ok, result = (ServerStorage :: any).NL_Debug:Invoke(...)
	if not ok then
		error(`NL_Debug: {tostring(result)}`)
	end
	return result
end

local function leadOf(player: Player): Model?
	local fighters = workspace:FindFirstChild("Fighters")
	for _, model in (if fighters then fighters:GetChildren() else {}) do
		if model:IsA("Model") and model:GetAttribute("Side") == "Lead" and model:GetAttribute("Owner") == player.UserId then
			return model
		end
	end
	return nil
end

local function shades(): { [Model]: boolean }
	local list = {}
	local fighters = workspace:FindFirstChild("Fighters")
	for _, model in (if fighters then fighters:GetChildren() else {}) do
		if model:IsA("Model") and model:GetAttribute("Side") == "Shade" then
			list[model] = true
		end
	end
	return list
end

return function(rounds: number?)
	local player = Players:GetPlayers()[1]
	assert(player and player.Character, "a player in the playtest")
	local out = ServerStorage:FindFirstChild("NL_ElementsEven") :: StringValue? or Instance.new("StringValue")
	local report = out :: StringValue
	report.Name = "NL_ElementsEven"
	report.Value = "starting"
	report.Parent = ServerStorage
	local firstLead = leadOf(player)
	assert(firstLead, "a lead out")
	local data = debug("Data", player)
	local owned = data.Voidkin[data.Roles.Lead]
	local level, xp = owned.Level, owned.Xp
	local pad = Instance.new("Part")
	pad.Name = "NL_ElementsEvenPad"
	pad.Anchored = true
	pad.Size = PAD_SIZE
	pad.Position = PAD_AT
	pad.Color = Color3.fromRGB(88, 90, 96)
	pad.Material = Enum.Material.SmoothPlastic
	pad.Parent = workspace
	local top = PAD_AT.Y + PAD_SIZE.Y / 2
	local stand = Vector3.new(PAD_AT.X, top + 3, PAD_AT.Z + 40)
	local centre = Vector3.new(PAD_AT.X, top, PAD_AT.Z + 40 - AHEAD)
	local facing = Vector3.new(centre.X, stand.Y, centre.Z)
	local ring = Fight.PackRing(PACK.Count, WorldConfig.Row.Spread)
	task.spawn(function()
		local lines = {}
		local ok, err = pcall(function()
			local root = (player.Character :: Model):FindFirstChild("HumanoidRootPart") :: BasePart
			local back = root.CFrame
			for round = 1, rounds or 10 do
				for k = 0, #ELEMENTS - 1 do
					local element = ELEMENTS[((round - 1 + k) % #ELEMENTS) + 1]
					debug("FightSpawn", player)
					root.AssemblyLinearVelocity = Vector3.zero
					root.CFrame = CFrame.lookAt(stand, facing)
					local lead = leadOf(player) :: Model
					lead:PivotTo(CFrame.lookAt(stand + Vector3.new(4, 0, 0), facing))
					debug("LeadLevel", player, 1, 0)
					task.wait(0.5)
					debug("LeadElement", player, element, true)
					task.wait(REST)
					debug("LeadHeal", player) -- a fallen lead up
					task.wait(0.2)
					debug("FightHealth", player, 1) -- and a standing one whole
					lead = leadOf(player) :: Model
					lead:PivotTo(CFrame.lookAt(stand + Vector3.new(4, 0, 0), facing))
					task.wait(0.3)
					local before = shades()
					for _, offset in ring do
						local spot = centre + Vector3.new(offset[1], 0, offset[2])
						local flat = Vector3.new(spot.X - stand.X, 0, spot.Z - stand.Z)
						root.CFrame = CFrame.lookAt(stand, stand + flat)
						debug("FightSpawn", player, PACK.Def, PACK.Level, flat.Magnitude)
					end
					root.CFrame = CFrame.lookAt(stand, facing)
					local foes = {}
					for model in shades() do
						if not before[model] then
							table.insert(foes, model)
						end
					end
					local start = lead:GetAttribute("Health") :: number
					local last = start
					local taken, fell, clear, freezes = 0, false, nil :: number?, 0
					local seen: { [string]: boolean } = {}
					local began = os.clock()
					while os.clock() - began < LONGEST do
						RunService.Heartbeat:Wait()
						local health = lead:GetAttribute("Health") :: number
						if health < last then
							taken += last - health
						end
						last = health
						if lead:GetAttribute("State") == "Down" or lead.Parent == nil then
							fell = true
							break
						end
						local up = 0
						for i, model in foes do
							if model.Parent ~= nil and model:GetAttribute("State") ~= "Down" and ((model:GetAttribute("Health") :: number?) or 0) > 0 then
								up += 1
								if model:GetAttribute("State") == "Stun" and model:GetAttribute("StunLook") == "StateFreeze" then
									local key = `{i}|{tostring(model:GetAttribute("StateUntil"))}`
									if not seen[key] then
										seen[key] = true
										freezes += 1
									end
								end
							end
						end
						if up == 0 then
							clear = os.clock() - began
							break
						end
					end
					local held = debug("LeadElement", player, element, true)
					table.insert(
						lines,
						string.format(
							"%s|%d|foes=%d|start=%.1f|taken=%.1f|max=%.1f|clear=%s|fell=%s|freezes=%d|el=%s",
							element,
							round,
							#foes,
							start,
							taken,
							lead:GetAttribute("MaxHealth") :: number,
							if clear then string.format("%.2f", clear) else "none",
							tostring(fell),
							freezes,
							tostring(held.Element)
						)
					)
					report.Value = table.concat(lines, "\n")
					if fell then
						task.wait(3)
						debug("LeadHeal", player)
					end
				end
			end
			root.CFrame = back
		end)
		pcall(debug, "FightSpawn", player)
		pcall(debug, "LeadElement", player, nil)
		pcall(debug, "LeadLevel", player, level, xp)
		pcall(debug, "FightHealth", player, 1)
		pad:Destroy()
		table.insert(lines, if ok then "DONE" else `ERROR {tostring(err)}`)
		report.Value = table.concat(lines, "\n")
	end)
end
