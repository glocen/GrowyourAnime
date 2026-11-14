--!strict
-- Fly (client kit): a reward's icons flying to its counter (TR6; docs/research/vfx-reference.md, "UI effects", DESIGN 3).
-- Rules.Hud.Flock of them by the reward's size, each from about where it was won, on its own curved arc (Rules.Hud.Arc,
-- bowed either way), staggered, gathering speed into the counter's icon, where it lands and goes. Drawn in a Folder on
-- the HUD's layer, so the UI lint never counts one as a piece. Config.Hud.Motion.Fly, read live. With the player's
-- reduced motion on, nothing flies: each lands at once (DESIGN 5).
--   Fly.Send(from, to, image, amount, landed?)   from: a point on the HUD layer, authored pixels; to: the icon it flies
--                                                to; image: the kit's; landed(k, n) as each lands, k of n landed so
--                                                far. Returns how many land (0: none, so the caller shows it itself).
--   Fly.From(world)                              a world point on the HUD layer, or nil off screen
--   Fly.Centre()                                 the HUD layer's middle
--   Fly.Middle(object)                           a GUI object's middle on the HUD layer
--   Fly.Holder()                                 the Folder the kit's loose pieces are drawn in (Fly's, Burst's)
--   Fly.Flying()                                 icons on their way now, for tests

local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Hud = require(Shared.Rules.Hud)
local HudConfig = require(Shared.Config.Hud)
local UIKit = require(Shared.Config.UIKit)
local Layers = require(script.Parent.Parent.Layers)

type Icon = {
	Image: ImageLabel,
	Scale: UIScale,
	From: Vector2,
	To: GuiObject,
	Bend: number,
	Start: number, -- os.clock() it leaves
	Seconds: number,
	Sent: { Landed: number }, -- shared by one send's icons
	Count: number,
	Landed: ((number, number) -> ())?,
}

local Fly = {}

local Z = 50 -- over the HUD's pieces
local flying: { Icon } = {}
local random = Random.new()
local folder: Folder? = nil

function Fly.Holder(): Folder
	if folder and folder.Parent then
		return folder
	end
	local made = Instance.new("Folder")
	made.Name = "NL_Fly"
	made.Parent = Layers.Get("Hud")
	folder = made
	return made
end

function Fly.Middle(object: GuiObject): Vector2
	local layer = Layers.Get("Hud")
	return (object.AbsolutePosition + object.AbsoluteSize / 2 - layer.AbsolutePosition) / Layers.Scale()
end

function Fly.Centre(): Vector2
	return Layers.Get("Hud").AbsoluteSize / 2 / Layers.Scale()
end

-- A viewport pixel less the top bar's inset is a GUI pixel, and the layer's corner is where it starts (UI.World's note).
function Fly.From(world: Vector3): Vector2?
	local camera = workspace.CurrentCamera
	if camera == nil then
		return nil
	end
	local screen, on = camera:WorldToViewportPoint(world)
	if not on or screen.Z <= 0 then
		return nil
	end
	local layer = Layers.Get("Hud")
	return (Vector2.new(screen.X, screen.Y) - GuiService:GetGuiInset() - layer.AbsolutePosition) / Layers.Scale()
end

function Fly.Send(from: Vector2, to: GuiObject, image: string, amount: number, landed: ((number, number) -> ())?): number
	local look = HudConfig.Motion.Fly
	local n = Hud.Flock(amount, look.Least, look.Most)
	if n <= 0 then
		return 0
	end
	if GuiService.ReducedMotionEnabled then
		if landed then
			for i = 1, n do
				landed(i, n)
			end
		end
		return n
	end
	local now = os.clock()
	local holder = Fly.Holder()
	local id = UIKit.Images[image].Id
	local sent = { Landed = 0 }
	for i = 1, n do
		local icon = Instance.new("ImageLabel")
		icon.Name = image
		icon.Image = id
		icon.BackgroundTransparency = 1
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Size = UDim2.fromOffset(look.Size, look.Size)
		icon.ZIndex = Z
		icon.Visible = false
		local scale = Instance.new("UIScale")
		scale.Parent = icon
		icon.Parent = holder
		local angle = random:NextNumber(0, 2 * math.pi)
		local scatter = Vector2.new(math.cos(angle), math.sin(angle)) * look.Spread * math.sqrt(random:NextNumber())
		table.insert(flying, {
			Image = icon,
			Scale = scale,
			From = from + scatter,
			To = to,
			Bend = look.Bend * (if random:NextNumber() < 0.5 then -1 else 1) * random:NextNumber(0.6, 1),
			Start = now + (i - 1) * look.Stagger,
			Seconds = look.Seconds * random:NextNumber(0.9, 1.1),
			Sent = sent,
			Count = n,
			Landed = landed,
		})
	end
	return n
end

function Fly.Flying(): number
	return #flying
end

RunService.RenderStepped:Connect(function()
	if #flying == 0 then
		return
	end
	local now = os.clock()
	local land = HudConfig.Motion.Fly.Land
	for i = #flying, 1, -1 do
		local f = flying[i]
		local t = (now - f.Start) / f.Seconds
		if t < 0 then
			continue
		end
		if t >= 1 or f.To.Parent == nil then
			f.Image:Destroy()
			table.remove(flying, i)
			f.Sent.Landed += 1
			if f.Landed then
				f.Landed(f.Sent.Landed, f.Count)
			end
			continue
		end
		local u = t * t -- gathering speed into its counter
		local at = Hud.Arc(f.From, Fly.Middle(f.To), f.Bend, u)
		f.Image.Position = UDim2.fromOffset(at.X, at.Y)
		f.Scale.Scale = (0.9 + 0.1 * math.min(1, t / 0.15)) * (1 - (1 - land) * u)
		f.Image.Visible = true
	end
end)

return Fly
