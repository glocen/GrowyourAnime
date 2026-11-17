--!strict
-- BreakerCases (client, Studio only): the Breaker screen's newer cases, a list of their own that joins the run apart from
-- Cases, as the Tower's does (Cases is at the type checker's limit); its helpers are Helpers'. TR41: the galaxy Breaker,
-- AR12's images laid as Modulo's breaker_sky.json says, with research's one band of mist.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Profile = require(Shared.Data.Profile)
local HudConfig = require(Shared.Config.Hud)
local BaseConfig = require(Shared.Config.Base)
local BaseController = require(script.Parent.Parent.Parent.Main.BaseController)
local ProfileController = require(script.Parent.Parent.ProfileController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Layers = require(UI.Layers)
local Theme = require(UI.Theme)
local Screen = require(UI.Kit.Screen)
local BreakerScreen = require(UI.BreakerScreen)
local Helpers = require(script.Parent.Helpers)

local BreakerCases = {}

function BreakerCases.Cases(): { any }
	local ANSWER, SKIP_ALL, waitFor, lintClean = Helpers.ANSWER, Helpers.SKIP_ALL, Helpers.waitFor, Helpers.lintClean
	local breakerPart, readyCount, openReadyDown = Helpers.breakerPart, Helpers.readyCount, Helpers.openReadyDown
	return {
		{
			Name = "Breaker: TR41, the galaxy: the night in the panel's shape, a river of mist sliding behind the windows, six stars breathing, a star falling in the last window, a working shard's light, each chamber glass with every word on its solid strip or plate, and all still when held",
			Run = function(t: any)
				-- AR12's images as the json lays them (build/handoff/UI/breaker/breaker_sky.json), research's one band of mist.
				local view = ProfileController.Get()
				t.Check("the first shard is chosen", view ~= nil and view.Progress.Starter ~= "")
				if view == nil or view.Progress.Starter == "" then
					return
				end
				local shard = "lanternrow_standard"
				local held = view.Bag.Shards[shard] or 0
				t.Server("BaseGive", shard, 1)
				t.Check("the server gives one", waitFor(t, ANSWER, function(): boolean
					local now = ProfileController.Get()
					return now ~= nil and (now.Bag.Shards[shard] or 0) == held + 1
				end))
				t.Check("it goes into the Breaker", ProfileController.Act("AddShard", { Shard = shard }).Ok == true)
				t.Check("the save shows it", waitFor(t, ANSWER, function(): boolean
					local now = ProfileController.Get()
					return now ~= nil and (now.Bag.Shards[shard] or 0) == held
				end))
				local before = readyCount(shard)
				Screen.Close()
				BaseController.OpenBreaker()
				t.Check("the screen opens", waitFor(t, 2, function(): boolean
					return breakerPart("Machine") ~= nil
				end))
				t.Wait(HudConfig.Motion.Screen.Enter + 0.1)
				local sky = HudConfig.Breaker.Sky
				local panel = Screen.Frame(BreakerScreen.Name)
				local skin = if panel then panel:FindFirstChild("NL_Skin") else nil
				local night = if skin then skin:FindFirstChild("Sky", true) :: Frame? else nil
				local left = if night then night:FindFirstChild("Left") :: ImageLabel? else nil
				local right = if night then night:FindFirstChild("Right") :: ImageLabel? else nil
				t.Check(
					"the night's two halves span the panel, the group's images",
					left ~= nil and right ~= nil and left.Image == sky.Images.Left and right.Image == sky.Images.Right
						and math.abs(left.Position.X.Scale) < 1e-3 and math.abs(right.Position.X.Scale + right.Size.X.Scale - 1) < 1e-3
						and math.abs(left.Size.Y.Scale - 1) < 1e-3 and right.Position.X.Scale < left.Size.X.Scale
				)
				local fill = if skin then skin:FindFirstChild("Fill", true) :: ImageLabel? else nil
				local edge = if skin then skin:FindFirstChild("Edge", true) :: ImageLabel? else nil
				t.Check("over the panel's fill and under its edge", night ~= nil and fill ~= nil and edge ~= nil and night.ZIndex > fill.ZIndex and edge.ZIndex > night.ZIndex)
				local stars: { ImageLabel } = {}
				for index, star in sky.Stars.Each do
					local made = if night then night:FindFirstChild(`Star{index}`) :: ImageLabel? else nil
					if made and made.Image == sky.Images.Star and made.ImageColor3:ToHex():upper() == star.Tint:sub(2):upper() and made.Size.X.Offset == math.floor(sky.Stars.Side * star.Size + 0.5) then
						table.insert(stars, made)
					end
				end
				t.Check("its six stars, each at its size in its tint", #stars == #sky.Stars.Each, `{#stars}`)
				local mist = breakerPart("Mist") :: CanvasGroup?
				local lumps = if mist then mist:FindFirstChild("Lumps1") :: ImageLabel? else nil
				local row = breakerPart("Chambers") :: Frame?
				t.Check(
					"one band of mist in a group carrying the river's colour, behind the chambers' row",
					mist ~= nil and mist:IsA("CanvasGroup") and mist:FindFirstChild("River") ~= nil and lumps ~= nil and lumps:FindFirstChild("Down") ~= nil
						and row ~= nil and row.ZIndex > mist.ZIndex
				)
				if mist == nil or lumps == nil or row == nil or #stars == 0 then
					Screen.Close()
					return
				end
				local turn = lumps:GetAttribute("Turn") :: number
				-- Where the lumps stand, in points: slid by scale (an offset is whole points).
				local function shift(of: ImageLabel): number
					local group = of.Parent :: GuiObject
					return of.Position.X.Scale * group.AbsoluteSize.X / math.max(of.AbsoluteSize.X / turn, 1e-6)
				end
				local x0, star0 = shift(lumps), stars[1].ImageTransparency
				t.Wait(1)
				local slid = (x0 - shift(lumps)) % turn
				t.Near("the mist slides left at its drift (points in about a second)", slid, sky.Mist.Drift, 0.6)
				t.Check("the stars breathe", math.abs(stars[1].ImageTransparency - star0) > 1e-3)
				-- A working chamber: its light in the window, under its shard, breathing round its rest.
				local now = ProfileController.Get() :: Profile.View
				local working: number? = nil
				for index, chamber in now.Base.Chambers do
					if chamber.Work and working == nil then
						working = index
					end
				end
				local cell = if working then breakerPart(`Chamber{working}`) :: Frame? else nil
				local window = if cell then cell:FindFirstChild("Window") :: Frame? else nil
				local light = if window then window:FindFirstChild("Light") :: ImageLabel? else nil
				local picture = if cell then cell:FindFirstChild("Picture") :: ImageLabel? else nil
				t.Check(
					"a working chamber's light, in its tint, in its window only, under its shard",
					light ~= nil and window ~= nil and picture ~= nil and window.ClipsDescendants and picture.ZIndex > window.ZIndex
						and light.ImageColor3:ToHex():upper() == sky.Light.Tint:sub(2):upper() and math.abs(light.Size.X.Offset - sky.Light.Side * sky.Light.Radius) < 1e-3
				)
				if light then
					t.Near("its cover breathes round its rest", 1 - light.ImageTransparency, sky.Light.Cover, sky.Light.Swell + 1e-3)
				end
				-- Each chamber's glass: solid on its strip and plate, Window's cover between (Locked's when locked), and every
				-- word on a solid part.
				local function sample(sequence: NumberSequence, x: number): number
					local keys = sequence.Keypoints
					for i = 1, #keys - 1 do
						local a, b = keys[i], keys[i + 1]
						if x >= a.Time and x <= b.Time then
							local share = if b.Time > a.Time then (x - a.Time) / (b.Time - a.Time) else 0
							return a.Value + (b.Value - a.Value) * share
						end
					end
					return keys[#keys].Value
				end
				local wrong: { string } = {}
				local most = math.max(BaseConfig.Breaker.MostChambers, #now.Base.Chambers)
				for index = 1, most do
					local each = breakerPart(`Chamber{index}`) :: Frame?
					local folder = if each then each:FindFirstChild("NL_Skin") else nil
					local body = if folder then folder:FindFirstChild("Fill", true) :: ImageLabel? else nil
					local gradient = if body then body:FindFirstChildOfClass("UIGradient") else nil
					if each == nil or body == nil or gradient == nil then
						table.insert(wrong, `chamber {index}: no glass`)
						continue
					end
					local pad = body.Size.Y.Offset / 2
					local whole = each.Size.Y.Offset + 2 * pad
					local function cover(y: number): number
						return 1 - sample(gradient.Transparency, (y + pad) / whole)
					end
					local open = index <= #now.Base.Chambers
					local strip = HudConfig.Breaker.Strip
					local middle = cover(strip + (each.Size.Y.Offset - strip) * 0.3)
					local want = if open then sky.Glass.Window else sky.Glass.Locked
					if math.abs(cover(strip / 2) - 1) > 1e-3 or math.abs(cover(each.Size.Y.Offset - 4) - 1) > 1e-3 or math.abs(middle - want) > 1e-3 then
						table.insert(wrong, `chamber {index}: strip {cover(strip / 2)}, window {middle}, plate {cover(each.Size.Y.Offset - 4)}`)
					end
					if each:FindFirstChild("Shadow", true) then
						table.insert(wrong, `chamber {index} keeps a shadow under its window`)
					end
					for _, word in each:GetChildren() do
						if word:IsA("TextLabel") and word.Visible then
							local y0, y1 = word.Position.Y.Offset, word.Position.Y.Offset + word.Size.Y.Offset
							if cover(y0 + 0.5) < 1 - 1e-3 or cover(y1 - 0.5) < 1 - 1e-3 then
								table.insert(wrong, `chamber {index}'s "{word.Text}" over the window`)
							end
						end
					end
				end
				t.Check("each chamber is glass: solid strip and plate, the window's cover between, every word on a solid part", #wrong == 0, wrong[1])
				-- The falling star: in the last chamber's window, first due First seconds after the opening.
				local function fallen(): ImageLabel?
					local box = breakerPart("Falling")
					return if box then box:FindFirstChild("Star") :: ImageLabel? else nil
				end
				local box = breakerPart("Falling") :: Frame?
				t.Check("the falling star waits in the last window, clipped to it, under its glass", box ~= nil and box.ClipsDescendants and box.ZIndex < row.ZIndex and fallen() ~= nil)
				t.Check(`the first star falls within {sky.Falling.First[2]} s of the opening`, waitFor(t, sky.Falling.First[2] + 0.5, function(): boolean
					local star = fallen()
					return star ~= nil and star.ImageTransparency < 0.5
				end))
				t.Wait(sky.Falling.Seconds + 0.1)
				local star = fallen()
				t.Check("and goes out at its end", star ~= nil and star.ImageTransparency > 1 - 1e-3)
				-- Made to be caught at the smallest phone (TR41 (a)'s must-fix): at its made size.
				local made = UDim2.fromOffset(sky.Falling.Points.X, sky.Falling.Points.Y)
				t.Check(`the star at its made size, {sky.Falling.Points.X} by {sky.Falling.Points.Y}`, star ~= nil and star.Size == made, if star then tostring(star.Size) else nil)
				-- The ready row ends at the machine's column, by the detail panel, fading out over its last share (the other).
				local fade = breakerPart("StripFade") :: CanvasGroup?
				local column = breakerPart("Machine") :: Frame?
				local soft = if fade then fade:FindFirstChildOfClass("UIGradient") else nil
				local keys: { NumberSequenceKeypoint } = if soft then soft.Transparency.Keypoints else {}
				local last = keys[#keys]
				t.Check("the ready row ends at the machine's column", fade ~= nil and column ~= nil
					and fade.AbsolutePosition.X + fade.AbsoluteSize.X <= column.AbsolutePosition.X + column.AbsoluteSize.X + 0.5
					and (fade:FindFirstChild("Strip") :: Instance?) ~= nil)
				t.Check(`and fades out over its last {HudConfig.Breaker.Fade * 100}%`, #keys == 3 and last ~= nil and last.Value > 1 - 1e-3
					and math.abs(keys[2].Time - (1 - HudConfig.Breaker.Fade)) < 1e-3 and keys[2].Value < 1e-3)
				-- Held still, as reduced motion holds it: the mist and the stars at their start, and no star falls.
				BreakerScreen.Still(true)
				t.Wait(0.2)
				local first = sky.Stars.Each[1]
				local rest = 1 - (0.775 + 0.225 * math.sin(2 * math.pi * first.Start))
				lumps = breakerPart("Lumps1") :: ImageLabel?
				t.Check("held still: the mist at its start, a star at its rest", lumps ~= nil and math.abs(shift(lumps)) < 1e-3 and math.abs(stars[1].ImageTransparency - rest) < 1e-3)
				BreakerScreen.Fall()
				t.Wait(0.3)
				star = fallen()
				t.Check("and no star falls", star ~= nil and star.ImageTransparency > 1 - 1e-3)
				BreakerScreen.Still(nil)
				for _, at in { { Name = "this screen", Scale = nil }, { Name = "the smallest phone", Scale = Theme.Scale.Floor } } do
					Layers.Force(at.Scale)
					t.Wait(0.1)
					local cut: { string } = {}
					for index = 1, most do
						local number = breakerPart(`Chamber{index}`)
						local words = if number then number:FindFirstChild("Number") :: TextLabel? else nil
						if words == nil or not words.TextFits then
							table.insert(cut, `chamber {index}`)
						end
					end
					t.Check(`at {at.Name}'s scale, each chamber's number whole on its strip`, #cut == 0, cut[1])
					lintClean(t, `the galaxy, at {at.Name}'s scale`)
				end
				Layers.Force(nil)
				Screen.Close()
				t.Server("BaseSkip", SKIP_ALL)
				waitFor(t, ANSWER, function(): boolean
					return readyCount(shard) > before
				end)
				openReadyDown(t, shard, before)
			end,
		},
	}
end

return BreakerCases
