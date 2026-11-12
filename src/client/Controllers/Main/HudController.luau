--!strict
-- HudController (client): the plain HUD of TR2 (docs/ui.md, "The HUD, in the world"; docs/test-requests.md, TR2, item 9),
-- in stock frames from the UI kit. Top left, the lead's card: name, level, health, experience; dimmed with the seconds
-- until it's back while it's down. Top centre, the target's card, only in a fight. Top right, two pills: Credits, and
-- Electricity stored over its cap with the rate. Bottom centre, the dock: Voidkin and Base. Toasts say what the server
-- gave: a shard, a level. Everything reads the fighters' attributes (FightService) or the save's copy
-- (ProfileController); nothing here decides anything. The Voidkin screen lists the collection and makes a lead.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local EffectsConfig = require(Shared.Config.Effects)
local Profile = require(Shared.Data.Profile)
local BaseConfig = require(Shared.Config.Base)
local Growth = require(Shared.Rules.Growth)
local Markers = require(Shared.World.Markers)
local UI = script.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Layers = require(UI.Layers)
local Read = require(UI.Read)
local Panel = require(UI.Kit.Panel)
local Text = require(UI.Kit.Text)
local Bar = require(UI.Kit.Bar)
local Button = require(UI.Kit.Button)
local Row = require(UI.Kit.Row)
local Screen = require(UI.Kit.Screen)
local Toast = require(UI.Kit.Toast)
local ProfileController = require(script.Parent.Parent.Core.ProfileController)
local Effects = require(script.Parent.FighterController.Effects)

local HudController = {}

local player = Players.LocalPlayer
local PAD = Theme.Size.Pad
local CARD = Vector2.new(210, 58)
local TARGET = Vector2.new(220, 46)
local PILL = Vector2.new(170, 28)
local BASE_EVERY = 0.25 -- seconds between reads of the base as it stands now: each copies the save
local DOCK = Vector2.new(96, Theme.Size.Tap)

type Card = { Frame: Frame, Name: TextLabel, Level: TextLabel, Health: Frame, Xp: Frame? }

local lead: Card
local target: Card
local credits: TextLabel
local electricity: TextLabel
local chip: Frame
local chipText: TextLabel
local dock: { [string]: TextButton } = {}
local lastView: Profile.View? = nil
local baseReadAt = 0

local function fighters(): { Instance }
	local folder = workspace:FindFirstChild("Fighters")
	return if folder then folder:GetChildren() else {}
end

local function myLead(): Model?
	for _, model in fighters() do
		if model:IsA("Model") and model:GetAttribute("Side") == "Lead" and model:GetAttribute("Owner") == player.UserId then
			return model
		end
	end
	return nil
end

local function fighterById(id: string): Model?
	for _, model in fighters() do
		if model:IsA("Model") and model:GetAttribute("Fighter") == id then
			return model
		end
	end
	return nil
end

local function card(name: string, size: Vector2, position: UDim2, anchor: Vector2, withXp: boolean): Card
	local frame = Panel.new({ Name = name, Size = UDim2.fromOffset(size.X, size.Y), Position = position, AnchorPoint = anchor, Parent = Layers.Get("Hud") })
	frame.Visible = false
	local inner = size.X - PAD * 2
	local title = Text.new({ Name = "Name", Font = Theme.Font.Strong, Truncate = true, Box = UDim2.fromOffset(inner - 70, 20), Position = UDim2.fromOffset(PAD, 5), Parent = frame })
	local level = Text.new({ Name = "Level", Colour = Theme.Colour.TextDim, Align = Enum.TextXAlignment.Right, Box = UDim2.fromOffset(70, 20), Position = UDim2.new(1, -PAD, 0, 5), AnchorPoint = Vector2.new(1, 0), Parent = frame })
	local health = Bar.new({ Name = "Health", Size = UDim2.fromOffset(inner, Theme.Size.Bar), Position = UDim2.fromOffset(PAD, 30), Colour = Theme.Colour.Health, Parent = frame })
	local xp = if withXp then Bar.new({ Name = "Xp", Size = UDim2.fromOffset(inner, 5), Position = UDim2.fromOffset(PAD, 44), Colour = Theme.Colour.Xp, Parent = frame }) else nil
	return { Frame = frame, Name = title, Level = level, Health = health, Xp = xp }
end

local function pill(name: string, order: number, colour: Color3): TextLabel
	local frame = Panel.new({
		Name = name,
		Size = UDim2.fromOffset(PILL.X, PILL.Y),
		Position = UDim2.new(1, -PAD, 0, PAD + (order - 1) * (PILL.Y + Theme.Size.Gap)),
		AnchorPoint = Vector2.new(1, 0),
		Parent = Layers.Get("Hud"),
	})
	local label = Text.new({ Name = "Value", Font = Theme.Font.Strong, Colour = colour, Align = Enum.TextXAlignment.Right, Box = UDim2.new(1, -PAD * 2, 1, 0), Position = UDim2.fromOffset(PAD, 0), Parent = frame })
	-- Shown once it has something to say: at a join the save's copy comes a moment after the HUD (TR2's rejoin take).
	frame.Visible = false
	label:GetPropertyChangedSignal("Text"):Connect(function()
		frame.Visible = label.Text ~= ""
	end)
	return label
end

-- The Voidkin screen: the collection, the lead first; any other can be made the lead.
local function voidkinScreen()
	local view = ProfileController.Get()
	if view == nil then
		return
	end
	local body = Screen.Open("Voidkin", "Voidkin", Vector2.new(440, 300))
	local list = Row.List(body, "List")
	local roster = Read.Roster(view)
	if #roster == 0 then
		Row.new({ Parent = list, Order = 1, Text = "No Voidkin yet", Detail = "Break a shard at the Breaker", Colour = Theme.Colour.TextDim })
	end
	for index, owned in roster do
		local role = Read.Role(view, owned.Id)
		Row.new({
			Name = owned.Id,
			Parent = list,
			Order = index,
			Text = Read.VoidkinName(owned),
			Detail = `Lv {owned.Level}{if role ~= "" then " · " .. role else ""}`,
			Action = "Lead",
			Disabled = if role == "Lead" then "Leading" elseif role ~= "" then "At work" else nil,
			OnPress = function()
				local answer = ProfileController.Act("SetLead", { Voidkin = owned.Id })
				if answer.Ok ~= true then
					Toast.Show(`Can't lead: {tostring(answer.Error)}`, Theme.Colour.TextDim)
				end
			end,
		})
	end
end

local function avatarAt(): Vector3?
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	return if root and root.Parent then root.Position else nil
end

-- Where a shard just won leaps from: the nearest fallen Shade to the avatar, within ShardLeap.From.
local function fallenNear(): Vector3?
	local at = avatarAt()
	local best: Vector3? = nil
	local bestGap = EffectsConfig.ShardLeap.From
	for _, model in fighters() do
		if model:IsA("Model") and model:GetAttribute("Side") == "Shade" and model:GetAttribute("State") == "Down" and at then
			local where = model:GetPivot().Position
			local gap = (where - at).Magnitude
			if gap < bestGap then
				best, bestGap = where, gap
			end
		end
	end
	return best
end

-- Whether the avatar stands on its own plot.
local function atHome(): boolean
	local plot = player:GetAttribute("Plot")
	local floor = if type(plot) == "number" then Markers.Find("Plot", { Plot = plot }) else nil
	local at = avatarAt()
	if floor == nil or not floor:IsA("BasePart") or at == nil then
		return false
	end
	local offset = floor.CFrame:PointToObjectSpace(at)
	return math.abs(offset.X) <= floor.Size.X / 2 and math.abs(offset.Z) <= floor.Size.Z / 2
end

-- The chip over the dock while the bag holds a shard: the hook home stays in view until it's in the Breaker, and names
-- the step that's next: in the field "break it at home", at home "into the Breaker" (research's verdict on TR2 and its
-- read of the fixes, 2026-11-12).
local function showChip(view: Profile.View)
	local kinds, total, first = 0, 0, nil :: string?
	for shard, count in view.Bag.Shards do
		if count > 0 then
			kinds += 1
			total += count
			first = first or shard
		end
	end
	chip.Visible = total > 0
	if first then
		local home = atHome()
		local step = if home then "into the Breaker" elseif total == 1 then "break it at home" else "break them at home"
		chipText.Text = if kinds == 1 and total == 1 then `{Read.ShardName(first)}: {step}` else `{total} shards: {step}`
	end
end

-- What changed since the last copy, said once: a shard gained (it leaps to the avatar), a level gained.
local function notice(old: Profile.View?, new: Profile.View)
	if old == nil then
		return
	end
	for shard, count in new.Bag.Shards do
		local gained = count - (old.Bag.Shards[shard] or 0)
		if gained > 0 then
			Toast.Show(`+{gained} {Read.ShardName(shard)}`, Theme.Colour.Ready)
			Effects.ShardLeap(fallenNear(), avatarAt)
		end
	end
	local id = new.Roles.Lead
	local was, now = old.Voidkin[id], new.Voidkin[id]
	if was and now and now.Level > was.Level then
		Toast.Show(`{Read.VoidkinName(now)} reached level {now.Level}`, Theme.Colour.Xp)
	end
end

local function showView(view: Profile.View)
	credits.Text = `Credits {Read.Number(view.Currency.Credits)}`
	showChip(view)
	Button.Set(dock.Voidkin, { Disabled = if next(view.Voidkin) ~= nil then false else "No Voidkin" })
	if Screen.Current() == "Voidkin" then
		voidkinScreen()
	end
end

-- Every frame: the cards from the fighters' attributes, the electricity from the base as it stands now.
local function step()
	local model = myLead()
	lead.Frame.Visible = model ~= nil and model:GetAttribute("Title") ~= nil -- a fighter's attributes come a moment after it
	local foe: Model? = nil
	if model then
		local health, most = model:GetAttribute("Health"), model:GetAttribute("MaxHealth")
		local share = if type(health) == "number" and type(most) == "number" and most > 0 then health / most else 0
		Bar.Set(lead.Health, share)
		lead.Name.Text = tostring(model:GetAttribute("Title") or "")
		local down = model:GetAttribute("State") == "Down"
		if down then
			local untilTime = model:GetAttribute("StateUntil")
			local left = if type(untilTime) == "number" and untilTime > 0 then untilTime - workspace:GetServerTimeNow() else 0
			lead.Level.Text = `Back in {Read.Seconds(left)}`
		else
			lead.Level.Text = `Lv {tostring(model:GetAttribute("Level") or "")}`
		end
		lead.Frame.BackgroundTransparency = if down then 0.55 else Theme.Transparency.Plate
		local view = ProfileController.Get()
		local owned = if view then view.Voidkin[view.Roles.Lead] else nil
		if owned and lead.Xp then
			local need = Growth.XpToNext(owned.Level)
			Bar.Set(lead.Xp, if need and need > 0 then owned.Xp / need else 1)
		end
		local id = model:GetAttribute("Target")
		foe = if type(id) == "string" and id ~= "" then fighterById(id) else nil
	end
	target.Frame.Visible = foe ~= nil
	if foe then
		local health, most = foe:GetAttribute("Health"), foe:GetAttribute("MaxHealth")
		Bar.Set(target.Health, if type(health) == "number" and type(most) == "number" and most > 0 then health / most else 0)
		target.Name.Text = tostring(foe:GetAttribute("Title") or "")
		target.Level.Text = `Lv {tostring(foe:GetAttribute("Level") or "")}`
	end
	local view = ProfileController.Get()
	if view and os.clock() - baseReadAt >= BASE_EVERY then
		baseReadAt = os.clock()
		local base = Read.Base(view, workspace:GetServerTimeNow())
		local stored = base.Data.Base.Battery
		local rate = if stored >= BaseConfig.Battery.Capacity - 1e-6 then "full" else Read.Rate(base.Rates.Net)
		electricity.Text = `{Read.Stored(stored)} / {Read.Number(BaseConfig.Battery.Capacity)} · {rate}`
		showChip(view) -- home or the field, as the avatar moves
	end
end

-- Opens the Base screen: BaseController's, set by it at Start.
HudController.OpenBase = function() end

function HudController.Start()
	lead = card("Lead", CARD, UDim2.fromOffset(PAD, PAD), Vector2.zero, true)
	target = card("Target", TARGET, UDim2.new(0.5, 0, 0, PAD), Vector2.new(0.5, 0), false)
	Bar.Colour(target.Health, Theme.Colour.EnemyHealth)
	credits = pill("Credits", 1, Theme.Colour.Credits)
	electricity = pill("Electricity", 2, Theme.Colour.Electricity)
	chip = Panel.new({
		Name = "Chip",
		Size = UDim2.fromOffset(DOCK.X * 3, PILL.Y),
		Position = UDim2.new(0.5, 0, 1, -PAD - DOCK.Y - Theme.Size.Gap),
		AnchorPoint = Vector2.new(0.5, 1),
		Parent = Layers.Get("Hud"),
	})
	chip.Visible = false
	chipText = Text.new({ Name = "Value", Font = Theme.Font.Strong, Colour = Theme.Colour.Ready, Align = Enum.TextXAlignment.Center, Truncate = true, Box = UDim2.new(1, -PAD * 2, 1, 0), Position = UDim2.fromOffset(PAD, 0), Parent = chip })
	local holder = Instance.new("Frame")
	holder.Name = "Dock"
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 1)
	holder.Position = UDim2.new(0.5, 0, 1, -PAD)
	holder.Size = UDim2.fromOffset(DOCK.X * 2 + Theme.Size.Gap, DOCK.Y)
	Panel.List(holder, Enum.FillDirection.Horizontal)
	holder.Parent = Layers.Get("Hud")
	for order, name in { "Voidkin", "Base" } do
		dock[name] = Button.new({
			Name = name,
			Text = name,
			Size = UDim2.fromOffset(DOCK.X, DOCK.Y),
			LayoutOrder = order,
			Parent = holder,
			OnPress = function()
				if Screen.Current() == name then
					Screen.Close()
				elseif name == "Voidkin" then
					voidkinScreen()
				else
					HudController.OpenBase()
				end
			end,
		})
	end
	ProfileController.Changed:Connect(function(view: Profile.View)
		notice(lastView, view)
		lastView = view
		showView(view)
	end)
	local view = ProfileController.Get()
	if view then
		lastView = view
		showView(view)
	end
	RunService.RenderStepped:Connect(step)
end

-- For tests: the HUD's parts by name.
function HudController.Parts(): { [string]: GuiObject }
	return {
		Lead = lead.Frame,
		LeadName = lead.Name,
		LeadLevel = lead.Level,
		LeadHealth = lead.Health,
		Target = target.Frame,
		TargetName = target.Name,
		TargetHealth = target.Health,
		Credits = credits,
		Electricity = electricity,
		Chip = chip,
		ChipText = chipText,
		Voidkin = dock.Voidkin,
		Base = dock.Base,
	}
end

return HudController
