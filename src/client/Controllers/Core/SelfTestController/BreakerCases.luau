--!strict
-- BreakerCases (client, Studio only): the Breaker screen's newer cases, a list of their own that joins the run apart from
-- Cases, as the Tower's does (Cases is at the type checker's limit); its helpers are Helpers'. TR41: the galaxy Breaker,
-- AR12's images laid as Modulo's breaker_sky.json says, with research's one band of mist. TR41 (d): where a shard came
-- from, its ground's festival tag, laid as Modulo's shard_tag.json says.

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Profile = require(Shared.Data.Profile)
local HudConfig = require(Shared.Config.Hud)
local BaseLevels = require(Shared.Rules.BaseLevels)
local BaseController = require(script.Parent.Parent.Parent.Main.BaseController)
local ProfileController = require(script.Parent.Parent.ProfileController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Layers = require(UI.Layers)
local Theme = require(UI.Theme)
local Screen = require(UI.Kit.Screen)
local BreakerScreen = require(UI.BreakerScreen)
local Helpers = require(script.Parent.Helpers)
local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local Button = require(UI.Kit.Button)
local VoidkinScreen = require(UI.VoidkinScreen)

local BreakerCases = {}

function BreakerCases.Cases(): { any }
	local ANSWER, SKIP_ALL, waitFor, lintClean = Helpers.ANSWER, Helpers.SKIP_ALL, Helpers.waitFor, Helpers.lintClean
	local breakerPart, readyCount, openReadyDown = Helpers.breakerPart, Helpers.readyCount, Helpers.openReadyDown
	-- TR41 (d): two shards of `shard`, one into the Breaker (a chamber's picture) and one kept in the bag (its chip on the
	-- strip, its cell). Returns what puts the Breaker back: the second in too, the time skipped, both opened.
	local function tagShards(t: any, shard: string): (() -> ())?
		local view = ProfileController.Get()
		t.Check("the first shard is chosen", view ~= nil and view.Progress.Starter ~= "")
		if view == nil or view.Progress.Starter == "" then
			return nil
		end
		local before = readyCount(shard)
		local held = view.Bag.Shards[shard] or 0
		local function inBag(): number
			local now = ProfileController.Get()
			return if now then now.Bag.Shards[shard] or 0 else -1
		end
		t.Server("BaseGive", shard, 2)
		t.Check("the server gives two", waitFor(t, ANSWER, function(): boolean
			return inBag() == held + 2
		end))
		t.Check("one goes into the Breaker", ProfileController.Act("AddShard", { Shard = shard }).Ok == true and waitFor(t, ANSWER, function(): boolean
			return inBag() == held + 1
		end))
		return function()
			Screen.Close()
			if ProfileController.Act("AddShard", { Shard = shard }).Ok == true then
				waitFor(t, ANSWER, function(): boolean
					return inBag() == held
				end)
			end
			t.Server("BaseSkip", SKIP_ALL)
			waitFor(t, ANSWER, function(): boolean
				return readyCount(shard) > before
			end)
			openReadyDown(t, shard, before)
		end
	end
	local function openBag(t: any): boolean
		Screen.Close()
		local hud = HudController.Parts()
		VoidkinScreen.Last("Bag") -- the card opens the page last shown (AR49)
		local open = Button.Press(hud.Voidkin :: TextButton) and waitFor(t, 1, function(): boolean
			return Screen.Current() == VoidkinScreen.Name
		end)
		t.Wait(HudConfig.Motion.Screen.Enter + 0.1)
		VoidkinScreen.Show("Bag")
		t.Wait(0.2)
		return open
	end
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
				-- Over about a second; again if the panel was rebuilt in it (a chamber's work ending, as the whole suite's
				-- clock can bring), so the lumps measured are still the ones shown.
				local function slide(): number?
					local band = breakerPart("Mist")
					local each = if band then band:FindFirstChild("Lumps1") :: ImageLabel? else nil
					if each == nil then
						return nil
					end
					local x = shift(each)
					t.Wait(1)
					return if each.Parent then (x - shift(each)) % turn else nil
				end
				local star0 = stars[1].ImageTransparency
				local slid = slide()
				if slid == nil then
					slid = slide()
				end
				t.Near("the mist slides left at its drift (points in about a second)", slid or -1, sky.Mist.Drift, 0.6)
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
				local most = BaseLevels.ChambersShown(#now.Base.Chambers)
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
		{
			Name = "Breaker: TR41 (d), where a shard came from: its ground's tag hung from a chamber's picture, a band of its colour along a strip chip's foot, its mark on a disc in a bag cell, each where Modulo's json lays it",
			Run = function(t: any)
				local look = HudConfig.ShardTag
				local ground = look.Grounds.lanternrow
				local large = HudConfig.ShardArt.Large
				local after = tagShards(t, "lanternrow_standard")
				if after == nil then
					return
				end
				Screen.Close()
				BaseController.OpenBreaker()
				t.Check("the Breaker opens", waitFor(t, 2, function(): boolean
					return breakerPart("Machine") ~= nil
				end))
				t.Wait(HudConfig.Motion.Screen.Enter + 0.1)
				-- The plaque's share of the side: a third up to the third's end, a quarter from the quarter's start.
				local function share(points: number): number
					local tag = look.Tag
					local k = math.clamp((points - tag.Third.Upto) / (tag.Quarter.From - tag.Third.Upto), 0, 1)
					return tag.Third.Of + (tag.Quarter.Of - tag.Third.Of) * k
				end
				local function laid(root: Instance?, name: string): { GuiObject }
					local out: { GuiObject } = {}
					for _, piece in (if root then root:GetDescendants() else {}) do
						if piece:IsA("GuiObject") and piece.Name == name and piece:GetAttribute("Ground") ~= nil then
							table.insert(out, piece)
						end
					end
					return out
				end
				local scales = { { Name = "this screen", Scale = nil :: number? }, { Name = "the smallest phone", Scale = Theme.Scale.Floor :: number? } }
				for _, at in scales do
					Layers.Force(at.Scale)
					t.Wait(0.15)
					local frame = Screen.Frame(BreakerScreen.Name)
					local body = if frame then frame:FindFirstChild("Body") else nil
					-- A working chamber's picture (50 to 72 points): the tag over it, its thread's tie on the crystal's right
					-- shoulder, its plaque its share of the side.
					local tags, wrong = laid(body, "Tag"), {}
					for _, piece in tags do
						local tag = piece :: ImageLabel
						local picture = tag.Parent :: ImageLabel
						local side, points = picture.AbsoluteSize.X, picture.Size.X.Offset
						local s = tag.AbsoluteSize.X / ground.Tag.Points.X
						local tie = tag.AbsolutePosition + look.Tag.Tie * s
						local want = picture.AbsolutePosition + picture.AbsoluteSize / 2 + look.Tag.At * side
						local plaque = tag.AbsoluteSize.Y / ground.Tag.Points.Y * look.Tag.Plaque
						if tag.Image ~= ground.Tag.Id or not tag.Visible or tag.ZIndex < picture.ZIndex or points < large
							or (tie - want).Magnitude > 1 or math.abs(plaque - share(points) * side) > 1 then
							table.insert(wrong, string.format("at %d points: its tie %.1f px off, its plaque %.1f of %.1f", points, (tie - want).Magnitude, plaque, share(points) * side))
						end
					end
					t.Check(`at {at.Name}'s scale, a working chamber's picture wears its tag where the json hangs it`, #tags > 0 and #wrong == 0, if #tags == 0 then "no tag" else wrong[1])
					-- A strip chip: a band of the ground's colour along its foot, in the chip's own shape, under its edge.
					local bands, off = laid(body, "GroundBand"), {}
					for _, piece in bands do
						local skin = piece.Parent :: Instance -- the chip's skin frame (Skin.Of), in its NL_Skin folder
						local chip = (skin.Parent :: Instance).Parent :: GuiObject
						local scale = chip.AbsoluteSize.Y / chip.Size.Y.Offset
						local fill = piece:FindFirstChild("Fill") :: ImageLabel?
						local edge = skin:FindFirstChild("Edge", true) :: ImageLabel?
						local foot = piece.AbsolutePosition.Y + piece.AbsoluteSize.Y - (chip.AbsolutePosition.Y + chip.AbsoluteSize.Y)
						if fill == nil or edge == nil or fill.ImageColor3 ~= ground.Colour or edge.ZIndex <= piece.ZIndex
							or math.abs(piece.AbsoluteSize.Y - look.Band * scale) > 1 or math.abs(foot) > 1 or math.abs(piece.AbsoluteSize.X - chip.AbsoluteSize.X) > 1 then
							table.insert(off, string.format("%s: %.1f px high of %.1f, its foot %.1f px off the chip's", chip.Name, piece.AbsoluteSize.Y, look.Band * scale, foot))
						end
					end
					t.Check(`at {at.Name}'s scale, a strip chip's foot in the ground's colour, {look.Band} points, under its edge`, #bands > 0 and #off == 0, if #bands == 0 then "no band" else off[1])
					lintClean(t, `the tagged Breaker, at {at.Name}'s scale`)
				end
				-- In the smallest phone's own room (its scale and its height), built there: the chambers' row gives way, never the
				-- strip, so every chip and its band stand inside the panel (they ran past its foot there, cut, until TR41 (d)); a
				-- picture under the large's least wears the mark, from it up the tag.
				Layers.Box(Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height))
				Screen.Close()
				BaseController.OpenBreaker()
				waitFor(t, 2, function(): boolean
					return breakerPart("Machine") ~= nil
				end)
				t.Wait(HudConfig.Motion.Screen.Enter + 0.1)
				local panel = Screen.Frame(BreakerScreen.Name)
				local body = if panel then panel:FindFirstChild("Body") else nil
				local foot = if panel then panel.AbsolutePosition.Y + panel.AbsoluteSize.Y else 0
				local spilt = {}
				for _, chip in (if body then body:GetDescendants() else {}) do
					if chip:IsA("GuiObject") and chip.Parent and chip.Parent.Name == "Strip" and chip.AbsolutePosition.Y + chip.AbsoluteSize.Y > foot + 0.5 then
						table.insert(spilt, string.format("%s's foot %.1f px past the panel's", chip.Name, chip.AbsolutePosition.Y + chip.AbsoluteSize.Y - foot))
					end
				end
				local bands = laid(body, "GroundBand")
				t.Check("in the smallest phone's room, every strip chip inside the panel, its band to be seen", panel ~= nil and #bands > 0 and #spilt == 0, if #bands == 0 then "no band" else spilt[1])
				-- And the row takes all the room the strip leaves, worked out from the sizes (the entrance's scale once shrank it).
				local fade = breakerPart("StripFade") :: GuiObject?
				local left = if fade and body and body:IsA("GuiObject") then body.AbsolutePosition.Y + body.AbsoluteSize.Y - (fade.AbsolutePosition.Y + fade.AbsoluteSize.Y) else math.huge
				t.Check("and the chambers' row takes the rest, the strip at the body's foot", left >= -0.5 and left <= 1.5 * Layers.Scale(), string.format("%.1f px left under it", left))
				local looks, odd = 0, {}
				for _, piece in (if body then body:GetDescendants() else {}) do
					if piece:IsA("ImageLabel") and piece.Name == "Picture" and piece.Parent and string.find(piece.Parent.Name, "^Chamber") then
						looks += 1
						local points = piece.Size.X.Offset
						local tag = piece:FindFirstChild(if points >= large then "Tag" else "Mark")
						if tag == nil or points < HudConfig.ShardArt.Chip then
							table.insert(odd, `a chamber's picture at {points} points without its {if points >= large then "tag" else "mark"}`)
						end
					end
				end
				t.Check("and a chamber's picture, given way, wears the look of its size", looks > 0 and #odd == 0, if looks == 0 then "no picture" else odd[1])
				lintClean(t, "the tagged Breaker, in the smallest phone's room")
				Layers.Box(nil)
				Layers.Force(nil)
				-- A bag cell (its picture under the large's least): the mark on its disc at the crystal's left foot, mirrored, since
				-- the count holds the cell's right corner, and clear of it.
				t.Check("the bag opens", openBag(t))
				for _, at in scales do
					Layers.Force(at.Scale)
					VoidkinScreen.Show("Bag") -- built again at the scale
					t.Wait(0.2)
					local marks, wrong, over = laid(Screen.Frame(VoidkinScreen.Name), "Mark"), {}, {}
					for _, piece in marks do
						local mark = piece :: ImageLabel
						local picture = mark.Parent :: ImageLabel
						local side, points = picture.AbsoluteSize.X, picture.Size.X.Offset
						local across = math.max(points * look.Mark.Side, look.Mark.Least) / points * side
						local middle = mark.AbsolutePosition + mark.AbsoluteSize / 2
						local want = picture.AbsolutePosition + picture.AbsoluteSize / 2 + Vector2.new(-look.Mark.Middle.X, look.Mark.Middle.Y) * side
						if mark.Image ~= ground.Mark.Id or points >= large or math.abs(mark.AbsoluteSize.X - across) > 1 or (middle - want).Magnitude > 1 then
							table.insert(wrong, string.format("at %d points: %.1f px across of %.1f, %.1f px off", points, mark.AbsoluteSize.X, across, (middle - want).Magnitude))
						end
						local count = (picture.Parent :: Instance):FindFirstChild("Count") :: TextLabel?
						if count and count.Visible then
							local right = count.AbsolutePosition.X + count.AbsoluteSize.X
							local top = count.AbsolutePosition.Y + (count.AbsoluteSize.Y - count.TextBounds.Y) / 2
							local from, to = mark.AbsolutePosition, mark.AbsolutePosition + mark.AbsoluteSize
							if right - count.TextBounds.X < to.X and right > from.X and top < to.Y and top + count.TextBounds.Y > from.Y then
								table.insert(over, `"{count.Text}" over the mark`)
							end
						end
					end
					t.Check(`at {at.Name}'s scale, a shard's bag cell wears its mark on its disc at the crystal's left foot`, #marks > 0 and #wrong == 0, if #marks == 0 then "no mark" else wrong[1])
					t.Check(`and its count clear of it`, #over == 0, over[1])
				end
				Layers.Force(nil)
				after()
			end,
		},
		{
			Name = "Take: TR41 (d), the festival tag at the smallest phone, the Breaker then the bag as the driver writes, for research",
			Manual = true,
			Stay = true,
			Run = function(t: any)
				-- Research's read of TR41 (d) (docs/test-requests.md, TR41): the Breaker with a working chamber and a bag chip,
				-- then the bag, at the smallest phone, as ReplicatedStorage.NL_TakeStep says: "Breaker", "Bag", "End";
				-- "Large", the Breaker in this screen's own room, its chamber's picture wearing the tag.
				local after = tagShards(t, "lanternrow_standard")
				if after == nil then
					return
				end
				local step = Instance.new("StringValue")
				step.Name = "NL_TakeStep"
				step.Value = "Breaker"
				step.Parent = ReplicatedStorage
				Layers.Force(Theme.Scale.Floor)
				Layers.Box(Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height))
				t.Wait(0.3)
				local shown = ""
				waitFor(t, 600, function(): boolean
					local value = step.Value
					if value ~= shown then
						shown = value
						if value == "Breaker" then
							Screen.Close()
							BaseController.OpenBreaker()
						elseif value == "Bag" then
							openBag(t)
						elseif value == "Large" then -- this screen's own room and scale: a chamber's picture at its full 68
							Layers.Box(nil)
							Layers.Force(nil)
							Screen.Close()
							BaseController.OpenBreaker()
						end
					end
					return value == "End"
				end)
				Screen.Close()
				Layers.Box(nil)
				Layers.Force(nil)
				step:Destroy()
				after()
			end,
		},
		{
			Name = "Breaker: AR40's live look, Studio only: NL_ClientTheme sets the screens' colours and a palette's values on this client and Reset puts each back exactly; NL_RevealTest opens the Breaker; the ready and infused words are their own colours",
			Run = function(t: any)
				local UIKit = require(Shared.Config.UIKit)
				local Players = game:GetService("Players")
				local theme = Players.LocalPlayer:FindFirstChild("PlayerScripts") and Players.LocalPlayer.PlayerScripts:FindFirstChild("NL_ClientTheme")
				local reveal = ReplicatedStorage:FindFirstChild("NL_RevealTest")
				t.Check("both bridges stand", theme ~= nil and reveal ~= nil)
				if theme == nil or reveal == nil then
					return
				end
				local graphite = UIKit.Palettes.Graphite :: any
				local ready, words, edge, panel = Theme.Colour.Ready, Theme.Colour.ElectricityWords, graphite.Edge, graphite.Panel
				t.Check("today, each word is its light's colour", Theme.Colour.ElectricityWords == Theme.Colour.Electricity and Theme.Colour.OverWords == Theme.Colour.Over and Theme.Colour.ReadyWords == Theme.Colour.Backing)
				local set = (theme :: BindableFunction):Invoke("Set", { Colour = { Ready = "#102030", ElectricityWords = "#7A5800" }, Palette = "Graphite", Values = { Edge = "#2B3472", Panel = { "#F7F2E8", "#E7E0D2" }, Rim = 2 } })
				t.Check("Set takes colours, pairs and numbers", set == true and Theme.Colour.Ready == Color3.fromHex("#102030") and Theme.Colour.ElectricityWords == Color3.fromHex("#7A5800")
					and graphite.Edge == Color3.fromHex("#2B3472") and graphite.Panel[2] == Color3.fromHex("#E7E0D2") and graphite.Rim == 2)
				;(theme :: BindableFunction):Invoke("Set", { Colour = { Ready = "#405060" } }) -- a second Set still resets to the first values
				;(theme :: BindableFunction):Invoke("Reset")
				t.Check("Reset puts each back exactly, a key the palette didn't have taken away", Theme.Colour.Ready == ready and Theme.Colour.ElectricityWords == words and graphite.Edge == edge and graphite.Panel == panel and graphite.Rim == nil)
				Screen.Close()
				;(reveal :: BindableFunction):Invoke("Breaker")
				t.Check("the Breaker opens from the bridge", waitFor(t, 2, function(): boolean
					return Screen.Current() == BreakerScreen.Name
				end), tostring(Screen.Current()))
				Screen.Close()
			end,
		},
		{
			Name = "Breaker and Power on AR40's C (the system panel, sandstone and teal): each window on System's slab, its title and words in its ink, a main action's sand plate in ink and the rest's teal channel in ivory, the close cross in ivory, a chamber's head band in the slab's deep teal; the Breaker keeps its night (the director, 2026-11-15)",
			Run = function(t: any)
				local UIKit = require(Shared.Config.UIKit)
				local PowerScreen = require(UI.PowerScreen)
				local system = (UIKit.Palettes :: any).System
				t.Check("both windows name System", BreakerScreen.Palette == "System" and PowerScreen.Palette == "System" and system ~= nil, `{BreakerScreen.Palette} {PowerScreen.Palette}`)
				if system == nil then
					return
				end
				-- Every button in a window: its words by its kind, the close cross in its ink.
				local function faces(where: string, frame: Instance)
					local glass, channel, wrong = 0, 0, {}
					for _, each in frame:GetDescendants() do
						local kind = each:GetAttribute("Kind")
						local label = if each:IsA("TextButton") then each:FindFirstChild("Label", true) else nil
						if (kind == "Glass" or kind == "Channel") and each:GetAttribute("Disabled") == "" and label and label:IsA("TextLabel") and label.Text ~= "" and each:GetAttribute("Pick") == nil then
							local want = if kind == "Glass" then system.PrimaryWords else system.QuietWords
							if kind == "Glass" then
								glass += 1
							else
								channel += 1
							end
							if label.TextColor3 ~= want and label.TextColor3 ~= system.PrimaryEdge then
								table.insert(wrong, `{each.Name} {kind} {label.TextColor3:ToHex()}`)
							end
						end
					end
					t.Check(`{where}: each button's words in its face's ink ({glass} sand, {channel} teal)`, #wrong == 0 and glass + channel > 0, table.concat(wrong, ", "))
					local close = frame:FindFirstChild("Close", true)
					local icon = if close then close:FindFirstChild("Icon", true) else nil
					t.Check(`{where}: the close cross in the slab's ivory`, icon ~= nil and icon:IsA("ImageLabel") and icon.ImageColor3 == system.QuietWords, if icon and icon:IsA("ImageLabel") then icon.ImageColor3:ToHex() else "none")
					local title = frame:FindFirstChild("Title", true)
					t.Check(`{where}: its title in the slab's ink`, title ~= nil and title:IsA("TextLabel") and title.TextColor3 == system.Text)
					t.Equal(`{where}: the window wears System`, frame:GetAttribute("Palette"), "System")
				end
				Screen.Close()
				BaseController.OpenBreaker()
				t.Check("the Breaker opens", waitFor(t, 2, function(): boolean
					return Screen.Current() == BreakerScreen.Name
				end), tostring(Screen.Current()))
				local breaker = Screen.Frame(BreakerScreen.Name)
				if breaker then
					faces("the Breaker", breaker)
					local chamber = breaker:FindFirstChild("Chamber1", true)
					t.Check("a chamber's head band in the slab's deep teal, never the old navy", chamber ~= nil and chamber:GetAttribute("Body") == system.Glass, if chamber then tostring(chamber:GetAttribute("Body")) else "none")
					t.Check("the Breaker keeps its night (its room of its own, its stars)", breaker:FindFirstChild("Sky", true) ~= nil)
				end
				Screen.Close()
				local view = ProfileController.Get()
				if view and view.Base.Power.Open then
					BaseController.OpenPower()
					t.Check("the Power screen opens", waitFor(t, 2, function(): boolean
						return Screen.Current() == PowerScreen.Name
					end), tostring(Screen.Current()))
					local power = Screen.Frame(PowerScreen.Name)
					if power then
						faces("Power", power)
						local reading = PowerScreen.Parts().BatteryReading
						t.Check("Power: the battery's words in the slab's light words", reading ~= nil and reading:IsA("TextLabel") and reading.TextColor3 == system.ElectricityWords)
					end
					Screen.Close()
				else
					t.Check("Power: open on this save (the Power cases open it first)", false, "NOT VERIFIED here: the generator isn't open on this save")
				end
			end,
		},
	}
end

return BreakerCases
