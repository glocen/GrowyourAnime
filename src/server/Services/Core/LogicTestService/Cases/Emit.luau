--!strict
-- Logic cases (pure): AR9's emitter row (docs/asset-requests.md, AR9, "Waits"): the bursts an Emitter row lets go, its
-- Emit list and the vault's EmitCount at EmitDelay, and the draws a sheet's three passes share, so its line, its fill
-- and its dark twin leave as one particle (Rules.Emit). And the kit's sheets as Config.FxKit writes them: each pass
-- uploaded, the twin's colours dark and never red, the fill fading only toward the cool tone.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Emit = require(Shared.Rules.Emit)
local FxKit = require(Shared.Config.FxKit)

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

-- Whether a colour sits in the red to maroon range the sheets' content check rules out: red well over green and blue.
local function reddish(colour: Color3): boolean
	return colour.R > 0.25 and colour.R > colour.G * 1.5 and colour.R > colour.B * 1.5
end

return {
	{
		Name = "Emit: AR9, an Emitter row lets go its Emit list, then its EmitCount at EmitDelay, and nothing under one",
		Run = function(t: any)
			t.Equal("no bursts", #Emit.Bursts({}), 0)
			local listed = Emit.Bursts({ Emit = { { 8, 1 }, { 12, 6 } } })
			t.Equal("the list, in order", #listed == 2 and listed[1][1] == 8 and listed[1][2] == 1 and listed[2][1] == 12 and listed[2][2] == 6, true)
			local counted = Emit.Bursts({ Emitter = { EmitCount = 12, EmitDelay = 0.1 } })
			t.Equal("EmitCount at EmitDelay: 12 on frame 6", #counted == 1 and near(counted[1][1], 6) and counted[1][2] == 12, true)
			local now = Emit.Bursts({ Emitter = { EmitCount = 3 } })
			t.Equal("no delay: at the row's start", #now == 1 and now[1][1] == 0 and now[1][2] == 3, true)
			local early = Emit.Bursts({ Emitter = { EmitCount = 3, EmitDelay = -1 } })
			t.Equal("a delay under 0 is the start", early[1][1], 0)
			t.Equal("a count under one lets nothing go", #Emit.Bursts({ Emit = { { 4, 0 } }, Emitter = { EmitCount = 0.5 } }), 0)
			local both = Emit.Bursts({ Emit = { { 2, 4 } }, Emitter = { EmitCount = 2.7, EmitDelay = 0.5 } })
			t.Equal("both, the list first, a count whole", #both == 2 and both[1][1] == 2 and near(both[2][1], 30) and both[2][2] == 2, true)
			t.Equal("the kit's two keys are its own, never set on the emitter", Emit.Own.EmitCount and Emit.Own.EmitDelay and not Emit.Own.Drag, true)
		end,
	},
	{
		Name = "Emit: AR9, a sheet's passes share one draw: a range's value, a sequence's envelope, the twin's fade, the rate's count",
		Run = function(t: any)
			t.Equal("a number is itself", Emit.Pick(3, 0.7), 3)
			t.Equal("a range from its low", Emit.Pick({ 2, 6 }, 0), 2)
			t.Equal("a range at a chance", near(Emit.Pick({ 2, 6 }, 0.25), 3), true)
			local fixed = Emit.Fixed({ { 0, 1, 0.5 }, { 0.5, 2 }, { 1, 0, 0.2 } }, -1)
			t.Equal("each point by its envelope, one chance for all", near(fixed[1][2], 0.5) and near(fixed[2][2], 2) and near(fixed[3][2], -0.2), true)
			t.Equal("the envelope gone", fixed[1][3], nil)
			local twin = Emit.Twin({ { 0, 0 }, { 0.6, 0.5 }, { 1, 1 } }, 0.15)
			t.Equal("the twin as clear again by its extra", near(twin[1][2], 0.15) and near(twin[2][2], 1 - 0.5 * 0.85) and near(twin[3][2], 1), true)
			t.Equal("the twin gone when the passes are", twin[3][2], 1)
			local plain = Emit.Twin(nil, 0.15)
			t.Equal("no fade: the extra throughout", #plain == 2 and plain[1][2] == 0.15 and plain[2][2] == 0.15, true)
			local count, carry = Emit.Due(30, 0, 1 / 60)
			t.Equal("half a particle a frame: none yet", count, 0)
			count, carry = Emit.Due(30, carry, 1 / 60)
			t.Equal("then one", count == 1 and near(carry, 0), true)
			local many = Emit.Due(90, 0.5, 0.1)
			t.Equal("ninety a second over a tenth, with a half left: nine", many, 9)
			t.Equal("a rate of none lets nothing go", (Emit.Due(-5, 0, 1)), 0)
			local x, z = Emit.InDisc(2, 1, 0, true)
			t.Equal("the rim at its radius", near(x, 2) and near(z, 0), true)
			local inside = true
			for index = 0, 99 do
				local a, b = Emit.InDisc(2, (index % 10) / 10, math.floor(index / 10) / 10, false)
				inside = inside and a * a + b * b <= 4 + 1e-9
			end
			t.Equal("inside, never past it", inside, true)
			local ax, ay = Emit.Spread({ 30, 10 }, 1, 0)
			t.Equal("the spread to its edges", near(ax, math.rad(30)) and near(ay, math.rad(-10)), true)
			t.Equal("no spread: straight", select(1, Emit.Spread(nil, 0.3, 0.9)), 0)
		end,
	},
	{
		Name = "Emit: AR9, the kit's seven sheets, each pass uploaded, the twin dark, never red, the fill toward the cool tone",
		Run = function(t: any)
			local names = { "puff", "ring", "crescent", "starburst", "spark", "glint", "flame" }
			local look = FxKit.Sheet
			t.Equal("the flipbook a 4x4 played once", look.Layout == "Grid4x4" and look.Mode == "OneShot", true)
			t.Equal("the twin dark", look.Dark.R + look.Dark.G + look.Dark.B < 0.5, true)
			t.Equal("no pass's tint red", not reddish(look.Line) and not reddish(look.Fill) and not reddish(look.Dark) and not reddish(look.Cool), true)
			t.Equal("the twin a little clear", look.DarkTransparency > 0 and look.DarkTransparency < 0.5, true)
			for _, name in names do
				local sheet = FxKit.Sheets[name]
				t.Equal(`{name}: a sheet`, sheet ~= nil, true)
				if sheet == nil then
					continue
				end
				for _, pass in { sheet.Line, sheet.Fill, sheet.Dark } do
					local image = FxKit.Images[pass]
					t.Equal(`{name}: {pass} uploaded`, image ~= nil and string.match(image.Id, "^rbxassetid://%d+$") ~= nil, true)
				end
				t.Equal(`{name}: a life`, sheet.Life > 0 and sheet.Life < 3, true)
				local fill = sheet.FillColor
				t.Equal(`{name}: the fill starts at the fill's tint`, fill[1][1] == 0 and fill[1][2] == look.Fill, true)
				t.Equal(`{name}: and fades only to the cool tone`, fill[#fill][1] == 1 and fill[#fill][2] == look.Cool, true)
				local red = false
				for _, point in fill do
					red = red or reddish(point[2])
				end
				t.Equal(`{name}: never red`, red, false)
			end
		end,
	},
}
