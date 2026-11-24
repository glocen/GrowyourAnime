--!strict
-- ButtonCases (client, Studio only): the kit's buttons in the seam's make (AR30), a list of their own that joins Cases in
-- the runner, as the Tower's does (Cases is at the type checker's limit).

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local HudConfig = require(Shared.Config.Hud)
local UIKit = require(Shared.Config.UIKit)
local UI = script.Parent.Parent.Parent.Parent.UI
local Button = require(UI.Kit.Button)
local Screen = require(UI.Kit.Screen)
local Layers = require(UI.Layers)
local Theme = require(UI.Theme)
local VoidkinScreen = require(UI.VoidkinScreen)
local BaseView = require(UI.BaseView)
local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local BaseController = require(script.Parent.Parent.Parent.Main.BaseController)

local ButtonCases = {}

local function waitFor(t: any, seconds: number, ok: () -> boolean): boolean
	local began = os.clock()
	while os.clock() - began < seconds do
		if ok() then
			return true
		end
		t.Wait(0.1)
	end
	return ok()
end

-- A button by name on any layer a screen draws on, or nil.
local function find(name: string): TextButton?
	for _, layer in { "Menus", "Band", "Hud" } do
		local found = Layers.Get(layer):FindFirstChild(name, true)
		if found and found:IsA("TextButton") then
			return found
		end
	end
	return nil
end

-- AR30's stills: "<Phone|Large> <screen> <button held, or none>", a screen being Voidkin, Bag, Power, Breaker or View;
-- Bag's card opens on "Bag:<cell>", one Voidkin's page on "Voidkin:<id>". Held until the driver writes End.
local function show(t: any, room: string, screen: string)
	Layers.Force(if room == "Phone" then Theme.Scale.Floor else nil)
	Layers.Box(if room == "Phone" then Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height) else nil)
	if BaseView.IsOpen() then
		BaseView.Close()
		t.Wait(1.5)
	end
	Screen.Close()
	t.Wait(HudConfig.Motion.Screen.Exit + 0.1)
	local page, cell = string.match(screen, "^(%a+):?(.*)$")
	if page == "Voidkin" or page == "Bag" then
		VoidkinScreen.Last("Bag") -- the card opens the page last shown (AR49)
		Button.Press(HudController.Parts().Voidkin :: TextButton)
		waitFor(t, 1, function(): boolean
			return Screen.Current() == VoidkinScreen.Name
		end)
		t.Wait(HudConfig.Motion.Screen.Enter + 0.1)
		if page == "Voidkin" then
			if cell and cell ~= "" then
				VoidkinScreen.Choose(cell) -- "Voidkin:<id>": that one's page (a stationed one's, for research's still)
			end
			VoidkinScreen.Show("Overview") -- it opens on the Items page (TR28): Lead and Station are Overview's
			t.Wait(0.4)
		elseif page == "Bag" then
			VoidkinScreen.Show("Bag")
			t.Wait(0.3)
			local tap = if cell and cell ~= "" then VoidkinScreen.Find(cell) else nil
			if tap then
				VoidkinScreen.Tap(tap)
			end
		end
	elseif page == "Power" then
		BaseController.OpenPower()
	elseif page == "Breaker" then
		BaseController.OpenBreaker()
	elseif page == "View" then
		BaseController.OpenView()
		t.Wait(1.5)
	end
	t.Wait(0.6)
end

function ButtonCases.Cases(): { any }
	return {
		{
			Name = "Kit: AR30, every button in the seam's make: a main action the glass lit from its foot, a second the channel with its underline, each state as Modulo's numbers say",
			Run = function(t: any)
				local make = HudConfig.Make
				local seam = UIKit.Palettes.Seam
				local G, C, U = make.Glass, make.Channel, make.Underline
				local function near(a: number, b: number): boolean
					return math.abs(a - b) < 0.02
				end
				local function same(a: Color3, b: Color3): boolean
					return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B) < 0.01
				end
				local function layer(button: Instance, name: string): ImageLabel
					return (button:FindFirstChild("NL_Skin") :: Instance):FindFirstChild(name, true) :: ImageLabel
				end
				local function settled()
					t.Wait(math.max(make.Down, make.Up) + 0.1)
				end
				local wide = 160
				local main = Button.new({ Name = "SelfTestMain", Text = "Lead", Primary = true, Under = true, Size = UDim2.fromOffset(wide, 52), Parent = Layers.Get("Hud"), OnPress = function() end })
				local second = Button.new({ Name = "SelfTestSecond", Text = "Station", Under = true, Size = UDim2.fromOffset(wide, 52), Parent = Layers.Get("Hud"), OnPress = function() end })
				local ready = Button.new({ Name = "SelfTestClaim", Text = "Claim", Primary = true, Light = make.Light.Ready, Size = UDim2.fromOffset(wide, 52), Parent = Layers.Get("Hud"), OnPress = function() end })
				local label = main:FindFirstChild("Label") :: TextLabel
				t.Wait(0.1)
				-- A main action at rest: the glass at L 1, every layer at its T.
				t.Check("a main action: the glass at L 1", main:GetAttribute("Kind") == "Glass" and main:GetAttribute("L") == make.L.Main)
				t.Check("its fill the Panel gradient at T 0.03", near(layer(main, "Fill").ImageTransparency, G.Fill) and layer(main, "Fill"):FindFirstChildOfClass("UIGradient") ~= nil)
				t.Check("its ring's glow, wash, edge and foot's glow at 1 - k·L", near(layer(main, "RingGlow").ImageTransparency, 1 - G.RingGlow) and near(layer(main, "Wash").ImageTransparency, 1 - 1 / G.Wash)
					and near(layer(main, "Edge").ImageTransparency, 1 - G.Edge) and near(layer(main, "FootGlow").ImageTransparency, 1 - G.FootGlow))
				t.Check("its foot lit, in the seam's light, along its foot", layer(main, "Foot").Visible and same(layer(main, "Foot").ImageColor3, seam.Light :: Color3)
					and layer(main, "Foot").Position.Y.Scale == 1 and layer(main, "Foot").Size.Y.Offset == G.Foot)
				t.Check("the foot's glow reaching past each side and below", layer(main, "FootGlow").Size.X.Offset == 2 * G.Reach and layer(main, "FootGlow").Position.Y.Offset == -G.Reach)
				t.Check("no underline on a main action", not layer(main, "Under").Visible)
				t.Check("a kind's own light: Claim's foot in Ready", same(layer(ready, "Foot").ImageColor3, make.Light.Ready) and same(layer(ready, "Edge").ImageColor3, make.Light.Ready))
				-- Pressed: it sinks, and its light rises to 1.45; let go, it falls back.
				Button.Touch(main, true)
				settled()
				t.Check("pressed: L 1.45, the wash at its whole", main:GetAttribute("L") == make.L.Pressed and near(layer(main, "Wash").ImageTransparency, 0))
				local skin = layer(main, "Fill").Parent :: GuiObject
				t.Check("and it sinks", skin.Position.Y.Offset == math.round(make.Sink) and label.Position.Y.Offset == math.round(make.Sink))
				Button.Touch(main, false)
				t.Wait(make.Up * 0.3)
				local falling = layer(main, "Wash").ImageTransparency
				settled()
				t.Check("let go, its light falls back over Up (the release flash)", falling > 0.02 and falling < 1 - 1 / G.Wash - 0.02 and near(layer(main, "Wash").ImageTransparency, 1 - 1 / G.Wash), string.format("%.3f", falling))
				-- Set: L 0.6, its mark at the word's left and the word in the light.
				Button.Set(main, { Selected = true })
				settled()
				local mark = label:FindFirstChild("Mark") :: ImageLabel?
				t.Check("set: L 0.6, its mark, its word in the light, the pair shifted", main:GetAttribute("L") == make.L.Set and mark ~= nil and mark.Visible
					and same(label.TextColor3, seam.Light :: Color3) and label.Position.X.Offset == make.Mark.Shift)
				-- Set, it wears the rail's chosen tab's light (research's ruling, 2026-11-17): the tab's fill, edge, glow and wash.
				local tab = HudConfig.Voidkin.Chrome.Rail.Tab
				local washed = layer(main, "Wash"):FindFirstChildOfClass("UIGradient")
				local foot = washed and washed.Transparency.Keypoints[#washed.Transparency.Keypoints].Value
				t.Check("set: the chosen tab's plate, its fill, edge and glow", main:GetAttribute("Kind") == "Plate" and near(layer(main, "Fill").ImageTransparency, 1 - tab.Fill)
					and near(layer(main, "Edge").ImageTransparency, 1 - tab.Edge) and near(layer(main, "RingGlow").ImageTransparency, 1 - tab.Glow))
				t.Check("and its wash rising to its foot as the tab's to the line", near(layer(main, "Wash").ImageTransparency, 0) and foot ~= nil
					and near(foot, 1 - (tab.Wash.Base + tab.Wash.Rise)), tostring(foot))
				-- A note under an enabled button's name (Station's bay), gone with false.
				Button.Set(second, { Note = "Bay 3" })
				local note = second:FindFirstChild("Reason") :: TextLabel?
				t.Check("a note under an enabled name: Bay 3", note ~= nil and note.Visible and note.Text == "Bay 3" and Button.State(second) ~= "Disabled")
				Button.Set(second, { Note = false })
				t.Check("and gone with false", note ~= nil and not note.Visible)
				-- Unavailable: the channel at 0.3, its name over its reason, both soft.
				Button.Set(main, { Selected = false, Disabled = "Warrior only" })
				local reason = main:FindFirstChild("Reason") :: TextLabel?
				t.Check("unavailable: the channel at 0.3, no foot", main:GetAttribute("Kind") == "Channel" and near(layer(main, "Fill").ImageTransparency, C.Main) and not layer(main, "Foot").Visible)
				t.Check("its name soft over the middle, its reason under", same(label.TextColor3, seam.Soft :: Color3) and label.Position.Y.Offset == -make.Word.Rise
					and reason ~= nil and reason.Visible and reason.Position.Y.Offset == make.Word.Fall)
				-- A second action: the channel, its word a little over the middle, its underline short.
				local function span(half: number): number
					return math.round(2 * half * U.Span)
				end
				local under = layer(second, "Under")
				local rest = span(U.Rest * math.min(U.Share * wide, U.Most))
				t.Check("a second action: the channel at 0.22, no foot", second:GetAttribute("Kind") == "Channel" and near(layer(second, "Fill").ImageTransparency, C.Rest) and not layer(second, "Foot").Visible)
				t.Check("its underline short, over its foot", under.Visible and under.Size.X.Offset == rest and under.Position.Y.Offset == -U.Over and near(under.ImageTransparency, U.Line[1]), `{under.Size.X.Offset} of {rest}`)
				Button.Touch(second, true)
				t.Wait(0.05)
				t.Check("pressed: washed with the light, its edge brighter, its underline whole", layer(second, "Wash").Visible and near(layer(second, "Wash").ImageTransparency, 0)
					and same(layer(second, "Edge").ImageColor3, C.PressedEdge) and under.Size.X.Offset == span(math.min(U.Share * wide, U.Most)) and near(under.ImageTransparency, U.Line[2]))
				Button.Touch(second, false)
				Button.Set(second, { Selected = true })
				t.Check("on: the glass at 0.75, no underline", second:GetAttribute("Kind") == "Glass" and second:GetAttribute("L") == make.L.On and not under.Visible)
				Button.Set(second, { Selected = false, Disabled = "No bay free" })
				t.Check("unavailable: the channel at 0.38", near(layer(second, "Fill").ImageTransparency, C.Off) and not under.Visible)
				-- Waiting: the light runs round its ring (its gradient kept, not lost to a tint).
				local hold = Instance.new("BindableEvent")
				local waits = Button.new({ Name = "SelfTestWaits", Text = "Open", Primary = true, Size = UDim2.fromOffset(wide, 52), Parent = Layers.Get("Hud"), OnPress = function()
					hold.Event:Wait()
					return nil
				end })
				Button.Press(waits)
				t.Wait(0.05)
				local run = layer(waits, "Ring"):FindFirstChildOfClass("UIGradient")
				t.Check("waiting: its ring shown, the light running round it", layer(waits, "Ring").Visible and run ~= nil and run.Enabled)
				hold:Fire()
				-- The X: no plate, its icon in Text; pressed, in the light over its halo, a short line under it.
				local I = make.Icon
				local x = Button.new({ Name = "SelfTestX", Text = "", Icon = make.Images.SeamClose, IconSide = make.Close.Side, Size = UDim2.fromOffset(make.Close.Box, make.Close.Box), Parent = Layers.Get("Hud"), OnPress = function() end })
				local icon, halo = layer(x, "Icon"), layer(x, "Halo")
				t.Check("the X: no plate, its icon in Text", not layer(x, "Fill").Visible and not layer(x, "Edge").Visible and icon.Visible and same(icon.ImageColor3, seam.Text :: Color3)
					and icon.Size.X.Offset == math.round(make.Close.Side) and not halo.Visible)
				Button.Touch(x, true)
				t.Check("pressed: in the light over its halo, a short line under it", same(icon.ImageColor3, seam.Light :: Color3) and halo.Visible
					and layer(x, "Under").Visible and layer(x, "Under").Position.Y.Offset == I.Below and layer(x, "Under").Size.X.Offset == span(I.Half))
				Button.Touch(x, false)
				for _, each in { main, second, ready, waits, x } :: { Instance } do
					each:Destroy()
				end
				hold:Destroy()
			end,
		},
		{
			Name = "Take: AR30, every button in the seam's make, a screen held with a button down as the driver writes, for research",
			Manual = true,
			Stay = true,
			Run = function(t: any)
				local step = Instance.new("StringValue")
				step.Name = "NL_TakeStep"
				step.Value = "Large Voidkin none"
				step.Parent = ReplicatedStorage
				local held: TextButton? = nil
				local function apply(said: string)
					local room, screen, press = string.match(said, "^(%a+) (%S+) (%S+)$")
					if room == nil or screen == nil or press == nil then
						return
					end
					if held then
						Button.Touch(held, false)
						held = nil
					end
					show(t, room, screen)
					if press ~= "none" then
						held = find(press)
						if held then
							Button.Touch(held, true)
						end
					end
					t.Wait(0.4)
					step:SetAttribute("Shown", `{said}{if press ~= "none" and held == nil then " (no such button)" else ""}`)
				end
				apply(step.Value)
				local shown = step.Value
				waitFor(t, 900, function(): boolean
					if step.Value ~= shown then
						shown = step.Value
						if shown ~= "End" then
							apply(shown)
						end
					end
					return step.Value == "End"
				end)
				if held then
					Button.Touch(held, false)
				end
				if BaseView.IsOpen() then
					BaseView.Close()
				end
				Layers.Box(nil)
				Layers.Force(nil)
				Screen.Close()
				step:Destroy()
			end,
		},
		{
			Name = "Kit: a window over the HUD is opaque in every palette, so none of the HUD's words show through it",
			Run = function(t: any)
				-- Research's must-fix 1 on AR40's C (2026-11-19, 21:25): at the system panel's 0.95, the HUD's "4 ready" and
				-- the lead card's health read through the Power window as ghost text. Every panel palette, the default first.
				local names: { string } = {}
				for name, p in UIKit.Palettes :: any do
					if type(p) == "table" and p.Panel ~= nil and p.Alpha ~= nil then
						table.insert(names, name)
					end
				end
				table.sort(names)
				table.insert(names, 1, "")
				local clear = 0
				for _, name in names do
					local palette = if name == "" then nil else name
					Screen.Open("SelfTestScreen", "Self-test", Vector2.new(300, 200), palette)
					local frame = Screen.Frame("SelfTestScreen")
					local skin = if frame then frame:FindFirstChild("NL_Skin") else nil
					local fill = if skin then skin:FindFirstChild("Fill", true) :: ImageLabel? else nil
					if fill == nil or fill.ImageTransparency ~= 0 then
						clear += 1
						t.Check(`{name ~= "" and name or "the default"}'s slab is opaque`, false, if fill then string.format("%.2f see-through", fill.ImageTransparency) else "no fill")
					end
				end
				t.Check(`every one of {#names} slabs is opaque`, clear == 0 and #names > 1, `{clear} see-through`)
				Screen.Close()
			end,
		},
	}
end

return ButtonCases
