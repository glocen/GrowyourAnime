--!strict
-- LintCases (client, Studio only): the lint's own cases (TR63, item 2), on a made-up screen of its own, a list that joins
-- Cases in the runner: apart, since Cases is at the type checker's limit. WCAG 2's ratios, as UiLint reads them: each
-- label's text against what's behind it, large text held to 3:1, a stroke counted, a lower sibling plate read, and art or
-- the world left unread.

local Players = game:GetService("Players")

local UiLint = require(script.Parent.UiLint)

local LintCases = {}

function LintCases.Cases(): { any }
	return {
	{
		-- TR63, item 2: the lint reads contrast, on a made-up screen of its own (WCAG 2's ratios, UiLint).
		Name = "UI: the lint reads each label's contrast against what's behind it (TR63)",
		Run = function(t: any)
			t.Check("its ratio: white on black is 21:1", math.abs(UiLint.Ratio(Color3.new(1, 1, 1), Color3.new(0, 0, 0)) - 21) < 0.01)
			local grey = UiLint.Ratio(Color3.fromRGB(118, 118, 118), Color3.new(1, 1, 1))
			t.Check("and #767676 on white is 4.54:1, WCAG's own example", math.abs(grey - 4.54) < 0.01, string.format("%.3f", grey))
			local screen = Instance.new("ScreenGui")
			screen.Name = "NL_LintTest"
			screen.ResetOnSpawn = false
			screen.DisplayOrder = 50
			screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			local regular = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Regular)
			local bold = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
			local function frame(name: string, parent: Instance, x: number, y: number, w: number, h: number, colour: Color3?, z: number?): Frame
				local f = Instance.new("Frame")
				f.Name = name
				f.Position, f.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(w, h)
				f.BackgroundColor3 = colour or Color3.new(0, 0, 0)
				f.BackgroundTransparency = if colour then 0 else 1
				f.BorderSizePixel = 0
				f.ZIndex = z or 1
				f.Parent = parent
				return f
			end
			local labels: { [string]: TextLabel } = {}
			local function label(name: string, parent: Instance, y: number, colour: Color3, size: number, font: Font, z: number?): TextLabel
				local l = Instance.new("TextLabel")
				l.Name = name
				l.Text = name
				l.Position, l.Size = UDim2.fromOffset(10, y), UDim2.fromOffset(200, size + 6)
				l.BackgroundTransparency = 1
				l.TextColor3, l.TextSize, l.FontFace = colour, size, font
				l.TextXAlignment = Enum.TextXAlignment.Left
				l.ZIndex = z or 2
				l.Parent = parent
				labels[name] = l
				return l
			end
			local panel = frame("Panel", screen, 40, 80, 460, 330, Color3.fromRGB(16, 16, 20))
			label("Clear", panel, 6, Color3.new(1, 1, 1), 16, regular)
			label("Low", panel, 32, Color3.fromRGB(58, 58, 64), 16, regular)
			label("LargeBold", panel, 58, Color3.fromRGB(106, 106, 106), 26, bold)
			label("SmallSame", panel, 96, Color3.fromRGB(106, 106, 106), 14, regular)
			local stroked = label("Stroked", panel, 122, Color3.fromRGB(40, 40, 44), 16, regular)
			local stroke = Instance.new("UIStroke")
			stroke.ApplyStrokeMode, stroke.Color, stroke.Thickness = Enum.ApplyStrokeMode.Contextual, Color3.new(1, 1, 1), 1.5
			stroke.Parent = stroked
			-- a clear card on the panel, its white plate a lower sibling of its words
			local card = frame("Card", panel, 230, 6, 220, 60, nil, 2)
			frame("Plate", card, 0, 0, 220, 60, Color3.new(1, 1, 1), 1)
			label("OnPlate", card, 10, Color3.new(0, 0, 0), 16, regular, 3)
			-- over art, and over the world: not known from here
			local art = Instance.new("ImageLabel")
			art.Name = "Art"
			art.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
			art.Position, art.Size = UDim2.fromOffset(230, 80), UDim2.fromOffset(220, 60)
			art.BackgroundTransparency = 1
			art.Parent = panel
			label("OnArt", art, 10, Color3.new(1, 1, 1), 16, regular)
			label("OverWorld", screen, 430, Color3.new(1, 1, 1), 16, regular)
			-- a fade from black to white, left to right, read where the words' middle falls (110 of its 400: 0.275 grey)
			local fade = frame("Fade", panel, 10, 160, 400, 60, Color3.new(1, 1, 1))
			local ramp = Instance.new("UIGradient")
			ramp.Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(1, 1, 1))
			ramp.Parent = fade
			label("OnFade", fade, 10, Color3.new(1, 1, 1), 16, regular)
			-- glass over the world: a dark pane covering 0.6 of it (white words pass over any world, pale ones fail over a
			-- white one), and a haze covering 0.2
			local glass = frame("Glass", screen, 520, 80, 220, 120, Color3.new(0, 0, 0))
			glass.BackgroundTransparency = 0.4
			label("OnGlass", glass, 10, Color3.new(1, 1, 1), 16, regular)
			label("PaleOnGlass", glass, 60, Color3.fromRGB(200, 200, 200), 16, regular)
			local haze = frame("Haze", screen, 520, 220, 220, 60, Color3.new(0, 0, 0))
			haze.BackgroundTransparency = 0.8
			label("OnHaze", haze, 10, Color3.new(1, 1, 1), 16, regular)
			-- a shadow: the same words in ink, two pixels under the face drawn over them
			label("EchoDrop", panel, 252, Color3.fromRGB(20, 20, 24), 16, regular).Text = "Echo"
			label("Echo", panel, 250, Color3.new(1, 1, 1), 16, regular, 3)
			-- the game's own screens hidden while it reads, so nothing of theirs lies under its world and its glass
			local gui = Players.LocalPlayer:WaitForChild("PlayerGui")
			local hidden: { ScreenGui } = {}
			for _, other in gui:GetChildren() do
				if other:IsA("ScreenGui") and other.Enabled then
					other.Enabled = false
					table.insert(hidden, other)
				end
			end
			screen.Parent = gui
			t.Wait(0.2)
			local read, failed = pcall(function()
				local function said(name: string): string
					local has, need = UiLint.ContrastOf(labels[name])
					return if has then string.format("%.2f:1 for %.1f", has, need) else `unread, for {need}`
				end
				local function has(name: string): (number?, number)
					local ratio, need = UiLint.ContrastOf(labels[name])
					return ratio, need
				end
				local clear = has("Clear")
				t.Check("white on the dark panel: passes", clear ~= nil and clear >= 4.5, said("Clear"))
				local low = has("Low")
				t.Check("dark grey on it: under 4.5:1", low ~= nil and low < 4.5, said("Low"))
				local large, largeNeed = has("LargeBold")
				t.Check("a grey at about 3.5:1, large and bold: held to 3:1, and passes", large ~= nil and largeNeed == 3 and large >= 3 and large < 4.5, said("LargeBold"))
				local small, smallNeed = has("SmallSame")
				t.Check("the same grey small: held to 4.5:1, and fails", small ~= nil and smallNeed == 4.5 and small < 4.5, said("SmallSame"))
				local strokedHas = has("Stroked")
				t.Check("dark letters with a white stroke: read by the stroke", strokedHas ~= nil and strokedHas >= 4.5, said("Stroked"))
				local plate = has("OnPlate")
				t.Check("black words on a white plate beneath them, a lower sibling: read on the plate", plate ~= nil and plate > 20, said("OnPlate"))
				local fadeHas = has("OnFade")
				local fadeWant = UiLint.Ratio(Color3.new(1, 1, 1), Color3.new(0.275, 0.275, 0.275))
				t.Check("white words on a fade: read on the fade's own colour under their middle", fadeHas ~= nil and math.abs(fadeHas - fadeWant) < 0.05,
					`{said("OnFade")}, for {string.format("%.2f", fadeWant)}`)
				local glassHas = has("OnGlass")
				t.Check("white on a dark glass: read over a white world too, and passes", glassHas ~= nil and glassHas >= 4.5, said("OnGlass"))
				local paleHas = has("PaleOnGlass")
				local paleWant = UiLint.Ratio(Color3.fromRGB(200, 200, 200), Color3.new(0.4, 0.4, 0.4))
				t.Check("pale words on a thinner glass: judged over a white world, and fail", paleHas ~= nil and paleHas < 4.5 and math.abs(paleHas - paleWant) < 0.05,
					`{said("PaleOnGlass")}, for {string.format("%.2f", paleWant)}`)
				t.Check("words on a haze over the world: unread", has("OnHaze") == nil, said("OnHaze"))
				t.Check("words on art: unread, never passed or failed", has("OnArt") == nil, said("OnArt"))
				t.Check("words over the world: unread", has("OverWorld") == nil, said("OverWorld"))
				local report = UiLint.Run()
				local named: { [string]: boolean } = {}
				for _, line in report.Contrast do
					local where = string.match(line, "^NL_LintTest%.[%w%.]-([%w]+) %(")
					if where then
						named[where] = true
					end
				end
				t.Check("the lint names the three that fail, and only them", named.Low == true and named.SmallSame == true and named.PaleOnGlass == true
					and not named.Clear and not named.LargeBold and not named.Stroked and not named.OnPlate and not named.OnArt and not named.OverWorld
					and not named.OnFade and not named.OnGlass and not named.OnHaze, UiLint.Detail(report.Contrast, report.Checked))
				t.Check("and counts what it can't read, and why: one on art, two over the world", report.Unread == 3 and report.UnreadBy.art == 1 and report.UnreadBy.world == 2,
					UiLint.Unread(report))
				t.Check("and says why one is unread", select(3, UiLint.ContrastOf(labels.OnArt)) == "art" and select(3, UiLint.ContrastOf(labels.OverWorld)) == "world")
				t.Check("a shadow under the same words: skipped, neither read nor counted", select(3, UiLint.ContrastOf(labels.EchoDrop)) == "shadow" and not named.EchoDrop
					and has("Echo") ~= nil, said("Echo"))
			end)
			screen:Destroy()
			for _, other in hidden do
				other.Enabled = true
			end
			if not read then
				error(failed, 0)
			end
		end,
	},
	}
end

return LintCases
