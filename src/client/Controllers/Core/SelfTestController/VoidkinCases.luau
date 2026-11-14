--!strict
-- VoidkinCases (client, Studio only): the Voidkin screen's cases (TR17), a list of their own beside Cases, which joins
-- them as it joins Takes. One case per layout, each on the screen as it stands at home (Stay): opened from the dock, the
-- figure whole in its stage at its measured share, Combat Power from its stats, each tab on the save's numbers, Lead and
-- Send to work and the marks in view, favourite and lock set and cleared, a switch by the strip and by a flick, a tap's
-- flourish, a turn, and the UI lint in this window and on the smallest phone. Stage's case also sends one Voidkin to work
-- and brings it home. VoidkinCases.Own gives the account Rook, Pip and Lyric when it lacks them, for these and the takes.

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local HudConfig = require(Shared.Config.Hud)
local VoidkinConfig = require(Shared.Config.Voidkin)
local Profile = require(Shared.Data.Profile)
local Stats = require(Shared.Rules.Stats)
local Hud = require(Shared.Rules.Hud)
local Voidkin = require(Shared.Definitions.Voidkin)
local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local ProfileController = require(script.Parent.Parent.ProfileController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Layers = require(UI.Layers)
local Read = require(UI.Read)
local Screen = require(UI.Kit.Screen)
local Button = require(UI.Kit.Button)
local VoidkinScreen = require(UI.VoidkinScreen)
local Figure = require(UI.VoidkinScreen.Figure)

local VoidkinCases = {}

local DEFS = { "rook", "pip", "lyric" } -- the three with their own bodies and Reveals
local LAYOUTS = { "Stage", "Flank", "Rail" }

export type Given = {
	ANSWER: number,
	REPLICATE: number,
	waitFor: (t: any, seconds: number, ok: () -> boolean) -> boolean,
	lintClean: (t: any, where: string) -> (),
}

type WaitFor = (t: any, seconds: number, ok: () -> boolean) -> boolean

-- The account's Voidkin, lead first, given Rook, Pip and Lyric when it lacks one.
function VoidkinCases.Own(t: any, waitFor: WaitFor, answer: number): { string }
	for _, def in DEFS do
		local view = ProfileController.Get()
		local has = false
		for _, owned in (if view then view.Voidkin else {}) :: { [string]: Profile.OwnedVoidkin } do
			has = has or owned.Def == def
		end
		if not has then
			local given = t.Server("VoidkinGive", def)
			local id = if type(given) == "table" and given.Ok == true then given.Id else nil
			if type(id) == "string" then
				waitFor(t, answer, function(): boolean
					local now = ProfileController.Get()
					return now ~= nil and now.Voidkin[id] ~= nil
				end)
			end
		end
	end
	local ids = {}
	local view = ProfileController.Get()
	for _, owned in (if view then Read.Roster(view) else {}) :: { Profile.OwnedVoidkin } do
		table.insert(ids, owned.Id)
	end
	return ids
end

-- The figure's crown and soles as shares of its stage's height, from the stage camera's own framing.
local function framed(figure: Figure.Figure): (number, number)
	local camera = figure.View.CurrentCamera :: Camera
	local at, size = figure.Body:GetBoundingBox()
	local half = math.tan(math.rad(camera.FieldOfView) / 2)
	local function share(y: number): number
		local rel = camera.CFrame:PointToObjectSpace(Vector3.new(at.Position.X, y, at.Position.Z))
		return 0.5 - (rel.Y / -rel.Z) / (2 * half)
	end
	return share(at.Position.Y + size.Y / 2), share(at.Position.Y - size.Y / 2)
end

-- A piece of the open screen that shows, whole, inside the screen's frame.
local function inView(name: string): boolean
	local frame = Screen.Frame(VoidkinScreen.Name)
	local piece = VoidkinScreen.Find(name)
	if frame == nil or piece == nil or not piece:IsA("GuiObject") then
		return false
	end
	local up: Instance? = piece
	while up and up ~= frame do
		if up:IsA("GuiObject") and not up.Visible then
			return false
		end
		up = up.Parent
	end
	local a, b = frame.AbsolutePosition, frame.AbsolutePosition + frame.AbsoluteSize
	local c, d = piece.AbsolutePosition, piece.AbsolutePosition + piece.AbsoluteSize
	return c.X >= a.X - 1 and c.Y >= a.Y - 1 and d.X <= b.X + 1 and d.Y <= b.Y + 1
end

local function labelOf(button: Instance?): string
	local label = button and button:FindFirstChild("Label", true)
	return if label and label:IsA("TextLabel") then label.Text else ""
end

local function button(name: string): TextButton?
	local found = VoidkinScreen.Find(name)
	return if found and found:IsA("TextButton") then found else nil
end

function VoidkinCases.Cases(given: Given): { any }
	local ANSWER, REPLICATE = given.ANSWER, given.REPLICATE
	local waitFor, lintClean = given.waitFor, given.lintClean

	-- The figure whole between the stage's top and Combat Power's plate, and its share of the screen's height noted.
	local function whole(t: any, where: string)
		local figure = VoidkinScreen.Figure()
		local plate = VoidkinScreen.Find("Power")
		t.Check(`{where}: a figure on the stage`, figure ~= nil)
		if figure == nil or plate == nil or not plate:IsA("GuiObject") then
			return
		end
		local crown, soles = framed(figure)
		local stage = figure.Stage
		local solesAt = stage.AbsolutePosition.Y + soles * stage.AbsoluteSize.Y
		t.Check(`{where}: its crown under the stage's top`, crown >= 0, string.format("%.3f", crown))
		t.Check(`{where}: its soles over Combat Power`, solesAt <= plate.AbsolutePosition.Y + 1, string.format("%.0f against %.0f", solesAt, plate.AbsolutePosition.Y))
		local room = Layers.Get("Menus").AbsoluteSize.Y
		t.Row(`{where}: the figure's share of the screen's height (aim {HudConfig.Voidkin.Figure.Height})`, nil, nil, (soles - crown) * stage.AbsoluteSize.Y / room, "")
		local framedFor = VoidkinScreen.Measure()
		t.Row(`{where}: framed for, on a stage {math.floor(framedFor.Stage)} authored px tall, its {figure.Studs} studs`, nil, nil, framedFor.Height, "")
	end

	local function case(layout: string): any
		return {
			Name = `Voidkin screen (TR17), {layout}: one Voidkin full size, its power, its tabs and its actions, switched by the strip and a flick`,
			Stay = true,
			Run = function(t: any)
				local ids = VoidkinCases.Own(t, waitFor, ANSWER)
				t.Check("three Voidkin to switch between", #ids >= 3, `{#ids}`)
				if #ids < 3 then
					return
				end
				local was = HudConfig.Voidkin.Layout
				t.Server("Tune", "Hud.Voidkin.Layout", layout)
				t.Check("the layout tuned on this client", waitFor(t, REPLICATE, function(): boolean
					return HudConfig.Voidkin.Layout == layout
				end))
				Screen.Close()
				local hud = HudController.Parts()
				t.Check("the dock's Voidkin opens it", Button.Press(hud.Voidkin :: TextButton) and waitFor(t, 1, function(): boolean
					return Screen.Current() == VoidkinScreen.Name
				end))
				t.Wait(HudConfig.Motion.Screen.Enter + 0.1)
				local view = ProfileController.Get() :: Profile.View
				local lead = view.Roles.Lead
				t.Check("on the lead", VoidkinScreen.Chosen() == lead, tostring(VoidkinScreen.Chosen()))
				local owned = view.Voidkin[lead]
				local figure = VoidkinScreen.Figure()
				local row = if owned then Voidkin.ById[owned.Def] else nil
				local body = if row and row.Model then row.Model else "StandIn"
				t.Check("its own body on the stage", figure ~= nil and figure.Body.Name == body, if figure then figure.Body.Name else "no figure")
				t.Check("on its Idle", figure ~= nil and figure.Idle ~= nil and (figure.Idle :: AnimationTrack).IsPlaying)
				whole(t, "this window")
				if owned then
					local block = Stats.Resolve(owned, Stats.PresetOf(view :: any, owned), view :: any)
					local number = VoidkinScreen.Find("Number")
					local said = if number and number:IsA("TextLabel") then number.Text else "none"
					t.Check("Combat Power at its feet, from its stats", said == Hud.Digits(Stats.Power(block)), said)
				end
				for _, name in { "Lead", "Work", "Favourite", "Lock", "Rename" } do
					t.Check(`{name} in view`, inView(name))
				end
				t.Check("the lead's own reads Leading", labelOf(button("Lead")) == "Leading", labelOf(button("Lead")))
				-- Each tab, on the save's numbers.
				for _, name in VoidkinScreen.Tabs do
					VoidkinScreen.Show(name)
					t.Wait(if layout == "Flank" then HudConfig.Voidkin.Ease + 0.1 else 0.1)
					local tabs = VoidkinScreen.Find("Tabs")
					local chosen = tabs and tabs:FindFirstChild(name)
					t.Check(`the {name} tab chosen`, chosen ~= nil and Button.State(chosen :: TextButton) == "Selected")
					local scroll = VoidkinScreen.Find("Tab")
					local lines = 0
					for _, child in (if scroll then scroll:GetChildren() else {}) :: { Instance } do
						lines += if child:IsA("GuiObject") then 1 else 0
					end
					t.Check(`{name} shows its lines`, lines > 0, `{lines}`)
					if scroll and owned then
						if name == "Overview" then
							local now = scroll:FindFirstChild("Now")
							local under = now and now:FindFirstChild("Under")
							t.Check("Overview: the lead's Now reads Leading", under ~= nil and (under :: TextLabel).Text == "Leading", if under then (under :: TextLabel).Text else "none")
						elseif name == "Stats" then
							local block = Stats.Resolve(owned, Stats.PresetOf(view :: any, owned), view :: any)
							local health = scroll:FindFirstChild("Health")
							local right = health and health:FindFirstChild("Right")
							t.Check("Stats: its Health, resolved", right ~= nil and (right :: TextLabel).Text == Hud.Digits(block.Health), if right then (right :: TextLabel).Text else "none")
						elseif name == "Kit" then
							local signature = false
							for _, child in scroll:GetChildren() do
								signature = signature or string.find(child.Name, "^Signature · ") ~= nil
							end
							t.Check("Kit: its signature by name", signature)
						elseif name == "Stars" then
							local pips = scroll:FindFirstChild("Pips")
							local count = 0
							for _, child in (if pips then pips:GetChildren() else {}) :: { Instance } do
								count += if child:IsA("Frame") then 1 else 0
							end
							t.Check(`Stars: {VoidkinConfig.MaxStars} pips`, count == VoidkinConfig.MaxStars, `{count}`)
						end
					end
				end
				if layout == "Flank" then
					t.Check("Flank: the panel in, inside the screen", inView("Panel"))
					for _, name in { "Lead", "Work" } do
						t.Check(`Flank: {name} on the panel's foot`, inView(name))
					end
					whole(t, "Flank with the panel in")
					VoidkinScreen.Slide(false)
					t.Wait(HudConfig.Voidkin.Ease + 0.1)
					t.Check("Flank: the panel out of sight once hidden", not inView("Panel"))
					t.Check("Flank: Lead back at the figure's feet", inView("Lead"))
				end
				-- Favourite and lock, set and cleared on the server.
				for _, mark in { { Name = "Favourite", Field = "Favourite" }, { Name = "Lock", Field = "Locked" } } do
					local before = ((ProfileController.Get() :: Profile.View).Voidkin[lead] :: any)[mark.Field] == true
					for _, want in { not before, before } do
						Button.Press(button(mark.Name) :: TextButton)
						t.Check(`{mark.Name}: {if want then "set" else "cleared"} in the save`, waitFor(t, ANSWER, function(): boolean
							local now = ProfileController.Get()
							return now ~= nil and (now.Voidkin[lead] :: any)[mark.Field] == want
						end))
						t.Check(`{mark.Name}: its button shows it`, waitFor(t, 1, function(): boolean
							local found = button(mark.Name)
							return found ~= nil and (Button.State(found) == "Selected") == want
						end))
					end
				end
				-- The strip: the second, then the third.
				for index = 2, 3 do
					local id = ids[index]
					local cell = button(id)
					t.Check(`the strip's cell {index} pressed`, cell ~= nil and Button.Press(cell))
					local def = (ProfileController.Get() :: Profile.View).Voidkin[id].Def
					t.Check(`and Voidkin {index} on the stage`, waitFor(t, 1, function(): boolean
						local now = VoidkinScreen.Figure()
						return VoidkinScreen.Chosen() == id and now ~= nil and now.Def == def
					end), tostring(VoidkinScreen.Chosen()))
					local chosen = button(id)
					t.Check(`its cell marked`, chosen ~= nil and Button.State(chosen) == "Selected")
				end
				-- A flick: the left brings the next (round to the first), the right the one before.
				local swipe = HudConfig.Voidkin.Swipe
				for _, step in { { Delta = -(swipe.Distance + 30), Want = ids[3 % #ids + 1] }, { Delta = swipe.Distance + 30, Want = ids[3] } } do
					local now = VoidkinScreen.Figure()
					local kind = if now then Figure.Gesture(now, Vector2.new(step.Delta, 6), swipe.Time / 2) else "none"
					t.Check(`a flick of {step.Delta} px is a swipe`, kind == "Swipe", kind)
					t.Check(`and goes to {step.Want}`, waitFor(t, 1, function(): boolean
						return VoidkinScreen.Chosen() == step.Want
					end), tostring(VoidkinScreen.Chosen()))
				end
				-- A tap plays the end of its Reveal; a drag turns it.
				t.Wait(HudConfig.Voidkin.Figure.Back + 0.1)
				local now = VoidkinScreen.Figure()
				t.Check("a tap is a tap", now ~= nil and Figure.Gesture(now, Vector2.new(2, 1), swipe.TapTime / 2) == "Tap")
				t.Check("and plays its flourish", now ~= nil and now.Reveal ~= nil and (now.Reveal :: AnimationTrack).IsPlaying)
				local slow = if now then Figure.Gesture(now, Vector2.new(swipe.Distance + 30, 0), swipe.Time * 3) else "none"
				t.Check("a slow drag across only turns it", slow == "Turn" and VoidkinScreen.Chosen() == ids[3], slow)
				if now then
					local from = now.Yaw
					Figure.Turn(now, 40)
					local _, yaw = now.Body:GetPivot():ToEulerAnglesYXZ()
					t.Check("turned 40°", math.abs(((from + 40) % 360) - now.Yaw) < 1e-6 and math.abs(math.deg(yaw) - ((from + 40 + 180) % 360 - 180)) < 0.5, string.format("%.1f°", math.deg(yaw)))
				end
				-- Stage's case only: one sent to work and brought home (or, every bay busy, home and back), and a rename.
				if layout == "Stage" then
					local current = ProfileController.Get() :: Profile.View
					local free: string?, worker: string?, working = nil, nil, 0
					for _, id in ids do
						local at = Read.Role(current, id)
						free = free or (if at == "" then id else nil)
						local bay = tonumber(string.match(at, "^Bay (%d+)$"))
						if bay and worker == nil then
							worker, working = id, bay
						end
					end
					local _, empty = Hud.WorkReason("", current.Base.Bays)
					local function role(id: string, want: string): boolean
						return waitFor(t, ANSWER, function(): boolean
							local after = ProfileController.Get()
							return after ~= nil and Read.Role(after, id) == want
						end)
					end
					local function shows(want: string): boolean
						return waitFor(t, 1, function(): boolean
							return labelOf(button("Work")) == want
						end)
					end
					if free and empty then
						VoidkinScreen.Choose(free)
						t.Check("Send to work", Button.Press(button("Work") :: TextButton) and role(free, `Bay {empty}`))
						t.Check("and its button brings it home", shows("Bring home"), labelOf(button("Work")))
						t.Check("Bring home", Button.Press(button("Work") :: TextButton) and role(free, ""))
					elseif worker then
						VoidkinScreen.Choose(worker)
						t.Check("every bay busy: a worker reads Bring home", labelOf(button("Work")) == "Bring home", labelOf(button("Work")))
						t.Check("Bring home", Button.Press(button("Work") :: TextButton) and role(worker, ""))
						t.Check("and its button sends it", shows("Send to work"), labelOf(button("Work")))
						t.Check("Send to work, to the bay it left", Button.Press(button("Work") :: TextButton) and role(worker, `Bay {working}`))
					else
						t.Check("a Voidkin to send or to bring home", false)
					end
					-- A rename: tidied, through the filter, its own name beneath; then taken off.
					VoidkinScreen.Choose(lead)
					local own = (Voidkin.ById[(ProfileController.Get() :: Profile.View).Voidkin[lead].Def] :: Voidkin.Row).Name
					for _, try in { { Typed = "  Test   Name ", Want = "Test Name" }, { Typed = "", Want = "" } } do
						t.Check(`Rename opens its box (to {if try.Want == "" then "take it off" else try.Want})`, Button.Press(button("Rename") :: TextButton) and waitFor(t, 1, function(): boolean
							return VoidkinScreen.Find("NameBox") ~= nil
						end))
						local box = VoidkinScreen.Find("NameBox")
						if box and box:IsA("TextBox") then
							box:ReleaseFocus()
							box.Text = try.Typed
							t.Check("Save", Button.Press(button("Save") :: TextButton))
							t.Check(`the save's nickname "{try.Want}"`, waitFor(t, ANSWER, function(): boolean
								local now = ProfileController.Get()
								return now ~= nil and now.Voidkin[lead].Nickname == try.Want
							end), tostring(((ProfileController.Get() :: Profile.View).Voidkin[lead]).Nickname))
							t.Check("the box closed", waitFor(t, 1, function(): boolean
								return VoidkinScreen.Find("NameBox") == nil
							end))
							local named = VoidkinScreen.Find("Name")
							local title = named and named:FindFirstChild("Title")
							local under = named and named:FindFirstChild("Under")
							local read = if title and title:IsA("TextLabel") then title.Text else "none"
							t.Check(`the name reads {if try.Want == "" then own else try.Want}`, read == (if try.Want == "" then own else try.Want), read)
							if try.Want ~= "" then
								t.Check("its own name beneath", under ~= nil and under:IsA("TextLabel") and under.Text == own, if under and under:IsA("TextLabel") then under.Text else "none")
							end
						end
					end
				end
				-- The UI lint, in this window and on the smallest phone.
				t.Wait(0.3)
				lintClean(t, `{layout}, this window`)
				Layers.Force(Theme.Scale.Floor)
				Layers.Box(Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height))
				t.Wait(0.1)
				VoidkinScreen.Show("Overview") -- built again at the phone's size
				t.Wait(if layout == "Flank" then HudConfig.Voidkin.Ease + 0.1 else 0.1)
				whole(t, "the smallest phone")
				lintClean(t, `{layout}, the smallest phone`)
				if layout == "Flank" then
					VoidkinScreen.Slide(false)
					t.Wait(HudConfig.Voidkin.Ease + 0.1)
					whole(t, "the smallest phone, the panel out")
					lintClean(t, "Flank, the smallest phone, the panel out")
				end
				Layers.Box(nil)
				Layers.Force(nil)
				Screen.Close()
				t.Server("Tune", "Hud.Voidkin.Layout", was)
			end,
		}
	end

	local cases = {}
	for _, layout in LAYOUTS do
		table.insert(cases, case(layout))
	end
	return cases
end

return VoidkinCases
