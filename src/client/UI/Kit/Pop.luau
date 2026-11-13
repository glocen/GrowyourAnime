--!strict
-- Pop (client kit): a reward popping at its rung (docs/research/vfx-reference.md, rule 4; AR8 C). A piece swells to
-- Rules.Hud.PopScale of its size about its middle, its peak early, and settles (Config.Hud.Pop); a gain sends a "+N" up
-- off it, and wins within its life count up as one number. Driven every frame, so Config.Hud.Pop tunes live.
--   Pop.Centre(piece)                                   anchor it at its middle, same box, so it swells in place
--   Pop.Play(piece, rung, { Swell = bool, Paint = fn }) one pop; Paint(p) each frame with the pop's 0..1, and 0 at its end
--   Pop.Gain(piece, amount, colour, format)             a "+N" off its left side, rising
--   Pop.Active(piece) -> its swell now (1 at rest), for tests; Pop.Gained(piece) -> the "+N" it shows, or ""

local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Hud = require(Shared.Rules.Hud)
local HudConfig = require(Shared.Config.Hud)
local Theme = require(script.Parent.Parent.Theme)
local Text = require(script.Parent.Text)

local OUTLINE = Color3.fromHex("#15120E") -- the numbers' warm near-black (Config.Hud's DARK)

local Pop = {}

type Playing = { Born: number, Rung: number, Swell: boolean, Paint: ((number) -> ())? }
type Gaining = { Label: TextLabel, Count: Hud.Count, Born: number, Format: (number) -> string }

local playing: { [GuiObject]: Playing } = {}
local gaining: { [GuiObject]: Gaining } = {}

function Pop.Centre(piece: GuiObject)
	local a, size = piece.AnchorPoint, piece.Size
	local dx, dy = 0.5 - a.X, 0.5 - a.Y
	piece.Position = piece.Position + UDim2.new(size.X.Scale * dx, size.X.Offset * dx, size.Y.Scale * dy, size.Y.Offset * dy)
	piece.AnchorPoint = Vector2.new(0.5, 0.5)
end

local function scaleOf(piece: GuiObject): UIScale
	local found = piece:FindFirstChild("Pop")
	if found and found:IsA("UIScale") then
		return found
	end
	local made = Instance.new("UIScale")
	made.Name = "Pop"
	made.Parent = piece
	return made
end

type Options = { Swell: boolean?, Paint: ((number) -> ())? }

function Pop.Play(piece: GuiObject, rung: number, options: Options?)
	local o: Options = options or {}
	local paint = o.Paint
	local was = playing[piece]
	if was and was.Paint and was.Paint ~= paint then
		was.Paint(0)
	end
	playing[piece] = { Born = os.clock(), Rung = rung, Swell = o.Swell ~= false, Paint = paint }
end

function Pop.Gain(piece: GuiObject, amount: number, colour: Color3, format: (number) -> string)
	local now = os.clock()
	local count = HudConfig.Pop.Count
	local was = gaining[piece]
	if was and was.Label.Parent and Hud.Live(was.Count, now - was.Born, HudConfig.Pop.Gain) then
		Hud.Add(was.Count, amount, now - was.Born, count)
		return
	end
	if was then
		was.Label:Destroy()
	end
	local label = Text.new({
		Name = "Gain",
		Size = Theme.Text.Caption,
		Font = Theme.Font.Number,
		Colour = colour,
		Align = Enum.TextXAlignment.Right,
		Box = UDim2.fromOffset(90, 20),
		Position = UDim2.new(0, -6, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Parent = piece,
	})
	label.ZIndex = 20
	local outline = Instance.new("UIStroke")
	outline.Color = OUTLINE
	outline.Thickness = 1.5
	outline.Parent = label
	label.Text = "+" .. format(amount)
	gaining[piece] = { Label = label, Count = Hud.Count(amount), Born = now, Format = format }
end

function Pop.Active(piece: GuiObject): number
	local scale = piece:FindFirstChild("Pop")
	return if scale and scale:IsA("UIScale") then scale.Scale else 1
end

function Pop.Gained(piece: GuiObject): string
	local gain = gaining[piece]
	return if gain and gain.Label.Parent then gain.Label.Text else ""
end

RunService.RenderStepped:Connect(function()
	if next(playing) == nil and next(gaining) == nil then
		return
	end
	local now = os.clock()
	local cfg = HudConfig.Pop
	for piece, pop in playing do
		local t = if cfg.Seconds > 0 then (now - pop.Born) / cfg.Seconds else 1
		local p = Hud.Pop(t, cfg.Peak)
		local done = t >= 1 or piece.Parent == nil
		if pop.Swell then
			scaleOf(piece).Scale = if done then 1 else 1 + (Hud.PopScale(pop.Rung, cfg.Swell) - 1) * p
		end
		if pop.Paint then
			pop.Paint(if done then 0 else p)
		end
		if done then
			playing[piece] = nil
		end
	end
	for piece, gain in gaining do
		local age = now - gain.Born
		local label = gain.Label
		if label.Parent == nil or not Hud.Live(gain.Count, age, cfg.Gain) then
			label:Destroy()
			gaining[piece] = nil
			continue
		end
		-- It rises over the first half of its life and holds; it fades over the last third after its last win; a win that
		-- joins it swells it a little as it counts up.
		local last = if gain.Count.Changed > -math.huge then gain.Count.Changed else 0
		local fade = math.clamp(((age - last) / cfg.Gain - 2 / 3) * 3, 0, 1)
		local rise = Hud.Ease(age / (cfg.Gain * 0.5))
		label.Position = UDim2.new(0, -6, 0.5, -cfg.Rise * rise)
		label.TextTransparency = fade * fade
		local stroke = label:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Transparency = fade * fade
		end
		label.Text = "+" .. gain.Format(Hud.Shown(gain.Count, age, cfg.Count))
		scaleOf(label).Scale = 1 + cfg.Swell * Hud.Swell(gain.Count, age, cfg.Count)
	end
end)

return Pop
