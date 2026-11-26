--!strict
-- BaseView (client): the base screen's command view, TR21's blockout (docs/ui.md, 7; docs/test-requests.md, TR21). At
-- home the Base tile lifts the camera over the player's own base, from its gate's side, until all of it is in view, and a
-- plain chip hangs over each machine and bay: its name, its level, and what it's doing now. The base's level stands at
-- the top with what the next one opens and its price. Close brings the camera back behind the lead. The HUD and the
-- machines' own plates step back meanwhile, and the avatar stands still. Plain on purpose, in grey.
-- Upgrade (TR21's block; docs/ui.md, 7): the base's level carries its press, and a tap on a chip opens that machine's
-- panel at the side, away from the chip: what it does, its level, what the next level gives, its price, and Upgrade.
-- What a press asks for is Rules.BaseLevels.Ask's, so it sends exactly what the server takes; a press that can't be
-- pressed says why on its own face. A bay's worker by tap, the Power tab and the camera's hold on the change wait.
-- Its numbers are Config.BaseView's.
--   BaseView.Open({ Plot = floor, Spots = { Breaker = Vector3, Bay1 = Vector3, ... }, View = ProfileController.Get,
--                   Act = ProfileController.Act })
--   BaseView.Close()
--   BaseView.IsOpen()
--   BaseView.Pick(spot)   opens that machine's panel, or closes it when it's the one open (a chip's tap)
--   BaseView.Framing(ground, points, aspect, edge?) -> the camera's CFrame, for tests
--   BaseView.Parts() -> its chips by spot name, its level plate and its press, the side panel and its press, for tests

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local BaseViewConfig = require(Shared.Config.BaseView)
local HudConfig = require(Shared.Config.Hud)
local BaseLevels = require(Shared.Rules.BaseLevels)
local Power = require(Shared.Rules.Power)
local Signal = require(Shared.Util.Signal)
local Theme = require(script.Parent.Theme)
local Layers = require(script.Parent.Layers)
local Read = require(script.Parent.Read)
local World = require(script.Parent.World)
local Panel = require(script.Parent.Kit.Panel)
local Text = require(script.Parent.Kit.Text)
local Button = require(script.Parent.Kit.Button)
local Toast = require(script.Parent.Kit.Toast)

export type Options = {
	Plot: BasePart, -- the plot's floor
	Spots: { [string]: Vector3 }, -- each machine's and bay's spot on the floor, by name (BaseController.Says)
	View: () -> Profile.View?,
	Act: ((name: string, args: any?) -> { [string]: any })?, -- asks the server (ProfileController.Act); none: nothing is bought
}
type Chip = { Frame: Frame, Title: TextLabel, Doing: TextLabel, Ground: Vector3 }
type Side = { Frame: Frame, Spot: string, Title: TextLabel, Does: TextLabel, Gain: TextLabel, Press: TextButton }
type Saved = { Type: Enum.CameraType, CFrame: CFrame, Fov: number }
type Row = World.Row -- a chip on the screen, authored pixels
type State = {
	Options: Options,
	Holder: Frame,
	Level: Frame,
	Upgrade: TextButton, -- the base's own press, on its level's plate
	Side: Side?, -- the machine's panel a chip's tap opened
	Busy: boolean, -- a press is with the server
	Chips: { [string]: Chip },
	Saved: Saved,
	Beat: RBXScriptConnection,
	ReadAt: number,
}

local BaseView = {}
BaseView.Closed = Signal.new()

local LINE = 20 -- authored pixels a chip's line takes
local AHEAD = 36 -- what the base's next level opens: two lines of Caption

-- What each machine does, one line, on its panel.
local DOES: { [string]: string } = {
	Breaker = "Breaks Void Shards into Voidkin.",
	Battery = "Stores spare power.",
	Generator = "Power made against power used.",
	Training = "Trains one Voidkin. Its rate is fixed.",
	Bay = "A Voidkin works here and makes power.",
}
-- A refusal the server gave after the press was open: someone else's tap got there first, or the view was behind.
local REFUSED: { [string]: string } = {
	Short = "Not enough Credits",
	Stale = "Already bought",
	Cap = "That's the top level for now",
	Ceiling = "Upgrade the base first",
	Asleep = "Not open yet",
	NoAnswer = "That didn't go through. Try again.",
}

local state: State? = nil
local closing = false

-- The avatar stands still while the view is up: the camera no longer follows it. Roblox's PlayerModule now lives under
-- StarterPlayer and takes ControlModule.Enabled; an older place keeps it in PlayerScripts with GetControls. Looked up
-- at once, never waited for: a wait blocked the view's opening when the module wasn't where it was asked for.
local function controls(on: boolean)
	pcall(function()
		local module = game:GetService("StarterPlayer"):FindFirstChild("PlayerModule")
		local api = if module and module:IsA("ModuleScript") then (require(module) :: any) else nil
		if api and type(api.ControlModule) == "table" then
			api.ControlModule.Enabled = on
			return
		end
		local scripts = Players.LocalPlayer:FindFirstChild("PlayerScripts")
		local old = scripts and scripts:FindFirstChild("PlayerModule")
		if old and old:IsA("ModuleScript") then
			local made = (require(old) :: any):GetControls()
			if on then
				made:Enable()
			else
				made:Disable()
			end
		end
	end)
end

-- The camera's CFrame that sees every point of `points` from the gate's side of `ground` (the plot's floor, its local -Z
-- toward the gate) on a screen of `aspect`, by Config.BaseView.Lift. The points' box is foreshortened at its pitch.
-- `edge` (0 to 0.5) is the share of the screen's half-width kept clear at each side, so a chip over the outermost point
-- stands whole: AR16's later bays stand at the plot's sides.
function BaseView.Framing(ground: CFrame, points: { Vector3 }, aspect: number, edge: number?): CFrame
	local c = BaseViewConfig.Lift
	local lowX: number, lowZ: number, highX: number, highZ: number = math.huge, math.huge, -math.huge, -math.huge
	for _, point in points do
		local at = ground:PointToObjectSpace(point)
		lowX = math.min(lowX, at.X)
		lowZ = math.min(lowZ, at.Z)
		highX = math.max(highX, at.X)
		highZ = math.max(highZ, at.Z)
	end
	if #points == 0 then
		lowX, lowZ, highX, highZ = 0, 0, 0, 0
	end
	local halfX = math.max((highX - lowX) / 2 + c.Pad, c.Least)
	local halfZ = math.max((highZ - lowZ) / 2 + c.Pad, c.Least)
	local pitch = math.rad(c.Pitch)
	local tall = math.tan(math.rad(c.Fov) / 2)
	local wide = tall * math.max(aspect, 0.1) * (1 - math.clamp(edge or 0, 0, 0.5))
	local away = math.max(halfX / wide, halfZ * math.sin(pitch) / tall)
	local aim = Vector3.new((lowX + highX) / 2, 0, (lowZ + highZ) / 2)
	local eye = aim + Vector3.new(0, math.sin(pitch), -math.cos(pitch)) * away
	return ground * CFrame.lookAt(eye, aim)
end

local pick: (name: string) -> ()

-- A chip is a touch high, since a tap on it opens its machine's panel.
local function chip(name: string, ground: Vector3): Chip
	local c = BaseViewConfig.Chip
	local tall = math.max(2 * LINE + Theme.Size.Pad, Theme.Size.Tap)
	local frame = World.Plate(`View{name}`, Vector2.new(c.Width, tall), function(): Vector3?
		return if state then ground + Vector3.new(0, c.Rise, 0) else nil
	end)
	local panel = Panel.new({ Name = "Panel", Size = UDim2.fromScale(1, 1), Parent = frame })
	Panel.Pad(panel, (tall - 2 * LINE) / 2, 10)
	local tap = Instance.new("TextButton")
	tap.Name = "Tap"
	tap.Text = ""
	tap.BackgroundTransparency = 1
	tap.Size = UDim2.fromScale(1, 1)
	tap.ZIndex = 5
	tap.Activated:Connect(function()
		pick(name)
	end)
	tap.Parent = frame
	Panel.List(panel, nil, 0)
	local title = Text.new({ Name = "Title", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Truncate = true, Box = UDim2.new(1, 0, 0, LINE), Parent = panel })
	title.LayoutOrder = 1
	local doing = Text.new({ Name = "Doing", Size = Theme.Text.Caption, Colour = Theme.Colour.TextDim, Truncate = true, Box = UDim2.new(1, 0, 0, LINE), Parent = panel })
	doing.LayoutOrder = 2
	return { Frame = frame, Title = title, Doing = doing, Ground = ground }
end

-- No chip covers another, nor the base's level at the top: the one lowest on the screen, the nearest, stands at its
-- machine, and each one above it takes the free place nearest its machine, over or under a chip already placed, Chip.Gap
-- clear of it, between the level's foot and the screen's bottom. Every frame, so the chips sort themselves out while
-- the camera lifts, and on any layout, however tight its machines stand.
local function spread(now: State)
	local camera = workspace.CurrentCamera
	local layer = Layers.Get("World")
	local scale = Layers.Scale()
	if camera == nil or scale <= 0 then
		return
	end
	local c = BaseViewConfig.Chip
	-- In the World layer's authored pixels, as World.Plate places a plate: a viewport pixel less the top bar's inset is a
	-- GUI pixel, and the layer's corner is where it starts.
	local corner = GuiService:GetGuiInset() + layer.AbsolutePosition
	local ceiling = (now.Level.AbsolutePosition.Y + now.Level.AbsoluteSize.Y - layer.AbsolutePosition.Y) / scale + c.Gap
	local bottom = layer.AbsoluteSize.Y / scale
	local rows: { Row } = {}
	for _, one in now.Chips do
		local at = camera:WorldToViewportPoint(one.Ground + Vector3.new(0, c.Rise, 0))
		if at.Z > 0 then
			local size = one.Frame.Size
			table.insert(rows, { Frame = one.Frame, Middle = (at.X - corner.X) / scale, Foot = (at.Y - corner.Y) / scale, Half = size.X.Offset / 2, Tall = size.Y.Offset })
		else
			World.Shift(one.Frame, Vector2.zero)
		end
	end
	local feet = World.Settle(rows, c.Gap, ceiling, bottom)
	for _, row in rows do
		World.Shift(row.Frame, Vector2.new(0, feet[row.Frame] - row.Foot))
	end
end

-- What a chip says: its name and level, and what it's doing now.
local function said(name: string, at: Read.Base): (string, string)
	local data = at.Data
	local base = data.Base
	if name == "Breaker" then
		local busy, least = 0, math.huge
		for _, chamber in base.Chambers do
			local work = chamber.Work
			if work then
				busy += 1
				least = math.min(least, Read.Left(at, work))
			end
		end
		local doing = if busy > 0
			then `{busy} of {#base.Chambers} breaking · {Read.Seconds(least)}`
			elseif #base.Ready > 0 then `{#base.Ready} ready to open`
			else "Empty"
		return `Void Breaker · Lv {base.Machines.Breaker or 1}`, doing
	elseif name == "Battery" then
		return "Battery", `{Read.Kwh(base.Charge)} / {Read.Number(at.Rates.Capacity)} kWh`
	elseif name == "Generator" then
		return "Generator", Read.Against(at.Rates.Generation, at.Rates.Demand)
	elseif name == "Training" then
		local trainee = if at.Rates.Trainee then data.Voidkin[at.Rates.Trainee] else nil
		return "Training", if trainee then `{Read.VoidkinName(trainee)} training` else "Empty"
	end
	local index = tonumber(string.match(name, "^Bay(%d+)$")) or 0
	local bay = base.Bays[index]
	if bay == nil then
		local level = BaseLevels.OpensAt(index)
		return `Bay {index}`, if level then `Opens at base level {level}` else "Opens with more Voidkin"
	end
	local worker = if bay.Worker ~= "" then data.Voidkin[bay.Worker] else nil
	local doing = if worker
		then `{Read.VoidkinName(worker)} · {Read.Kw(Power.Output(worker) * BaseLevels.BayOutput(bay.Level or 1))}`
		else "Empty"
	return `Bay {index} · Lv {bay.Level or 1}`, doing
end

-- The base's level and what the next one opens, in plain words.
local function levelLines(data: Profile.View): (string, string)
	local level = data.Base.Level or 1
	local offer = BaseLevels.Next(level, data.Currency.Credits)
	if offer.Price == nil then
		return `Base · Level {level}`, "The top level for now"
	end
	local gains = {}
	for _, gain in offer.Gains do
		if gain.What == "Bays" then
			table.insert(gains, `{gain.To} bays`)
		elseif gain.What == "Battery" then
			table.insert(gains, `{Read.Number(gain.To)} kWh battery`)
		elseif gain.What == "Ceiling" then
			table.insert(gains, `machines to Lv {gain.To}`)
		elseif gain.What == "Condenser" then
			table.insert(gains, "the Stone Condenser wakes")
		elseif gain.What == "Presets" then
			table.insert(gains, `{gain.To} gear presets`)
		end
	end
	return `Base · Level {level}`, `Level {offer.Level}: {table.concat(gains, ", ")}` -- its price is on its press
end

-- Why an offer's press can't be pressed, for its own face; nil when it can.
local function why(ask: BaseLevels.Ask, view: Profile.View): string?
	local offer = ask.Offer
	if offer.Why == nil then
		return nil
	elseif offer.Why == BaseLevels.Short and offer.Price then
		return `Need {Read.Number(offer.Price - view.Currency.Credits)} more`
	elseif offer.Why == BaseLevels.AtCeiling then
		return `Base level {(view.Base.Level or 1) + 1} first`
	elseif offer.Why == BaseLevels.Asleep then
		return "Not awake yet"
	end
	return "Top level"
end

-- A machine's level against its first, as a percentage: 1.04 reads "104%".
local function percent(against: number): string
	return `{math.floor(against * 100 + 0.5)}%`
end

-- What a machine's next level gives, in plain numbers.
local function gives(offer: BaseLevels.Offer): string
	local list: { string } = {}
	for _, gain in offer.Gains do
		if gain.What == "Speed" then
			table.insert(list, `speed {percent(gain.From)} to {percent(gain.To)}`)
		elseif gain.What == "Output" then
			table.insert(list, `output {percent(gain.From)} to {percent(gain.To)}`)
		elseif gain.What == "Chambers" then
			table.insert(list, `{gain.To} chambers`)
		elseif gain.What == "Rate" then
			table.insert(list, `{Read.Number(gain.To)} stones an hour`)
		elseif gain.What == "Tray" then
			table.insert(list, `a tray of {Read.Number(gain.To)}`)
		end
	end
	return `Level {offer.Level}: {table.concat(list, ", ")}`
end

-- A press shown with its price, hidden, or off with its reason on its face; touched only when that changes, since the
-- view reads often.
local function set(press: TextButton, price: number?, off: string?)
	local words = if price then `Upgrade · {Read.Number(price)}` else "Upgrade"
	local mark = if price then `{words}|{off or ""}` else "hidden"
	if press:GetAttribute("Shows") == mark then
		return
	end
	press:SetAttribute("Shows", mark)
	press.Visible = price ~= nil
	Button.Set(press, { Text = words, Disabled = off or false })
end

local function read(now: State)
	local view = now.Options.View()
	if view == nil then
		return
	end
	local at = Read.Base(view, workspace:GetServerTimeNow())
	for name, made in now.Chips do
		local title, doing = said(name, at)
		made.Title.Text, made.Doing.Text = title, doing
	end
	local top, ahead = levelLines(view)
	local first, second = now.Level:FindFirstChild("Title", true), now.Level:FindFirstChild("Next", true)
	if first and first:IsA("TextLabel") and second and second:IsA("TextLabel") then
		first.Text, second.Text = top, ahead
	end
	local credits = view.Currency.Credits
	local base = BaseLevels.Ask(view.Base :: any, "Base", credits)
	local buys = now.Options.Act ~= nil
	set(now.Upgrade, if base and buys then base.Offer.Price else nil, if base then why(base, view) else nil)
	local side = now.Side
	if side == nil then
		return
	end
	local title, doing = said(side.Spot, at)
	side.Title.Text = title
	local ask = BaseLevels.Ask(view.Base :: any, side.Spot, credits)
	local price = if ask then ask.Offer.Price else nil
	if ask == nil then
		-- No level of its own, or a bay not open yet: the chip's own line says when it opens.
		side.Gain.Text = if string.match(side.Spot, "^Bay") then doing else "It grows with the base's level."
	elseif price == nil then
		side.Gain.Text = "The top level for now."
	else
		side.Gain.Text = gives(ask.Offer)
	end
	set(side.Press, if buys then price else nil, if ask then why(ask, view) else nil)
end

-- A press: what the spot can buy now, asked of the server once. A refusal that slipped past the press's own face is
-- said in words. True once it's bought.
local function buy(now: State, spot: string): boolean
	local view, act = now.Options.View(), now.Options.Act
	if view == nil or act == nil or now.Busy then
		return false
	end
	local ask = BaseLevels.Ask(view.Base :: any, spot, view.Currency.Credits)
	if ask == nil or ask.Offer.Why ~= nil then
		return false
	end
	now.Busy = true
	local answer = act(ask.Act, ask.Args)
	now.Busy = false
	if state ~= now then
		return answer.Ok == true -- the view closed while the server answered
	end
	if answer.Ok ~= true then
		Toast.Show(REFUSED[tostring(answer.Error)] or "That didn't go through. Try again.", Theme.Colour.TextDim)
	end
	read(now)
	return answer.Ok == true
end

-- A machine's panel at the side, the side its chip isn't on: its name and level, what it does, what the next level
-- gives, and its press with its price.
local function side(now: State, spot: string): Side
	local pad, gap, tap = Theme.Size.Pad, Theme.Size.Gap, Theme.Size.Tap
	local wide = BaseViewConfig.Side.Width
	local rows = { Title = 24, Does = 38, Gain = 38 }
	local tall = pad + rows.Title + rows.Does + rows.Gain + gap + tap + pad
	local camera = workspace.CurrentCamera
	local made = now.Chips[spot]
	local left = false
	if camera and made then
		left = camera:WorldToViewportPoint(made.Ground).X > camera.ViewportSize.X / 2
	end
	local frame = Panel.new({
		Name = "Side",
		Size = UDim2.fromOffset(wide, tall),
		Position = if left then UDim2.new(0, pad, 0.5, 0) else UDim2.new(1, -pad, 0.5, 0),
		AnchorPoint = Vector2.new(if left then 0 else 1, 0.5),
		Parent = now.Holder,
	})
	local y = pad
	local function line(name: string, high: number, size: number, colour: Color3, font: Font, wrap: boolean): TextLabel
		local label = Text.new({ Name = name, Size = size, Font = font, Colour = colour, Align = Enum.TextXAlignment.Left, Box = UDim2.new(1, -pad * 2, 0, high), Position = UDim2.fromOffset(pad, y), Parent = frame, Wrap = wrap, Truncate = not wrap })
		y += high
		return label
	end
	local title = line("Title", rows.Title, Theme.Text.Body, Theme.Colour.Text, Theme.Font.Strong, false)
	local does = line("Does", rows.Does, Theme.Text.Caption, Theme.Colour.TextDim, Theme.Font.Body, true)
	local gain = line("Gain", rows.Gain, Theme.Text.Caption, Theme.Colour.Text, Theme.Font.Body, true)
	does.Text = DOES[spot] or DOES.Bay
	local press = Button.new({ Name = "Upgrade", Text = "Upgrade", Size = UDim2.fromOffset(wide - pad * 2, tap), Position = UDim2.fromOffset(pad, y + gap), Parent = frame, OnPress = function(): boolean
		return buy(now, spot)
	end })
	return { Frame = frame, Spot = spot, Title = title, Does = does, Gain = gain, Press = press }
end

pick = function(name: string)
	local now = state
	if now == nil or now.Chips[name] == nil then
		return
	end
	local open = now.Side
	if open then
		open.Frame:Destroy()
		now.Side = nil
		if open.Spot == name then
			return
		end
	end
	now.Side = side(now, name)
	read(now)
end

function BaseView.Pick(spot: string)
	pick(spot)
end

function BaseView.IsOpen(): boolean
	return state ~= nil
end

function BaseView.Open(options: Options)
	local camera = workspace.CurrentCamera
	if state or closing or camera == nil then
		return
	end
	local pad = Theme.Size.Pad
	local holder = Instance.new("Frame")
	holder.Name = "BaseView"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.Parent = Layers.Get("Menus")
	local close = HudConfig.Make.Close -- AR30: Close is the X, top right
	Button.new({ Name = "Close", Text = "", Icon = HudConfig.Make.Images.SeamClose, IconSide = close.Side, Size = UDim2.fromOffset(close.Box, close.Box), Position = UDim2.new(1, -pad, 0, pad), AnchorPoint = Vector2.new(1, 0), Parent = holder, OnPress = function()
		BaseView.Close()
		return nil
	end })
	-- The base's level, top middle: its name and what the next level opens at the left, its press with the price at
	-- the right, a touch high. Narrow enough to stand clear of the X on the smallest phone.
	local plate = BaseViewConfig.Level
	local tap = Theme.Size.Tap
	local tall = math.max(LINE + AHEAD, tap) + pad
	local level = Panel.new({ Name = "Level", Size = UDim2.fromOffset(plate.Width + plate.Press + pad * 3, tall), Position = UDim2.new(0.5, 0, 0, pad), AnchorPoint = Vector2.new(0.5, 0), Parent = holder })
	local top = (tall - LINE - AHEAD) / 2
	Text.new({ Name = "Title", Size = Theme.Text.Body, Font = Theme.Font.Strong, Align = Enum.TextXAlignment.Left, Box = UDim2.fromOffset(plate.Width, LINE), Position = UDim2.fromOffset(pad, top), Parent = level })
	Text.new({ Name = "Next", Size = Theme.Text.Caption, Colour = Theme.Colour.TextDim, Align = Enum.TextXAlignment.Left, Wrap = true, Box = UDim2.fromOffset(plate.Width, AHEAD), Position = UDim2.fromOffset(pad, top + LINE), Parent = level })

	local saved = { Type = camera.CameraType, CFrame = camera.CFrame, Fov = camera.FieldOfView }
	local now: State = { Options = options, Holder = holder, Level = level, Upgrade = nil :: any, Side = nil, Busy = false, Chips = {}, Saved = saved, Beat = nil :: any, ReadAt = -math.huge }
	now.Upgrade = Button.new({ Name = "Upgrade", Text = "Upgrade", Size = UDim2.fromOffset(plate.Press, tap), Position = UDim2.new(1, -pad, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Parent = level, Primary = true, OnPress = function(): boolean
		return buy(now, "Base")
	end })
	state = now
	local points = {}
	for name, ground in options.Spots do
		now.Chips[name] = chip(name, ground)
		table.insert(points, ground)
	end
	read(now)
	now.Beat = RunService.Heartbeat:Connect(function()
		spread(now)
		if os.clock() - now.ReadAt >= BaseViewConfig.Chip.Every then
			now.ReadAt = os.clock()
			read(now)
		end
	end)

	controls(false)
	Layers.Get("Hud").Visible = false
	camera.CameraType = Enum.CameraType.Scriptable
	local size = camera.ViewportSize
	local ground = options.Plot.CFrame * CFrame.new(0, options.Plot.Size.Y / 2, 0)
	local lift = BaseViewConfig.Lift
	local info = TweenInfo.new(lift.Seconds, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local edge = (BaseViewConfig.Chip.Width / 2 + BaseViewConfig.Chip.Gap) * Layers.Scale() / math.max(size.X / 2, 1)
	TweenService:Create(camera, info, { CFrame = BaseView.Framing(ground, points, size.X / math.max(size.Y, 1), edge), FieldOfView = lift.Fov }):Play()
end

function BaseView.Close()
	local was = state
	local camera = workspace.CurrentCamera
	if was == nil then
		return
	end
	state = nil
	was.Beat:Disconnect()
	for _, made in was.Chips do
		World.Remove(made.Frame)
	end
	was.Holder:Destroy()
	Layers.Get("Hud").Visible = true
	BaseView.Closed:Fire()
	if camera == nil then
		controls(true)
		return
	end
	closing = true
	local info = TweenInfo.new(BaseViewConfig.Lift.Seconds * 0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
	local back = TweenService:Create(camera, info, { CFrame = was.Saved.CFrame, FieldOfView = was.Saved.Fov })
	back.Completed:Connect(function()
		camera.CameraType = was.Saved.Type
		closing = false
		controls(true)
	end)
	back:Play()
end

function BaseView.Parts(): { Chips: { [string]: Frame }, Level: Frame?, Upgrade: TextButton?, Side: Frame?, SideSpot: string?, SidePress: TextButton? }
	local chips = {}
	if state then
		for name, made in state.Chips do
			chips[name] = made.Frame
		end
	end
	local side = if state then state.Side else nil
	return {
		Chips = chips,
		Level = if state then state.Level else nil,
		Upgrade = if state then state.Upgrade else nil,
		Side = if side then side.Frame else nil,
		SideSpot = if side then side.Spot else nil,
		SidePress = if side then side.Press else nil,
	}
end

return BaseView
