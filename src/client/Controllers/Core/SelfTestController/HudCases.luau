--!strict
-- HudCases (client, Studio only): the HUD's and the kit's newer cases, a list of their own beside Cases, which joins it
-- as it joins VoidkinCases (Cases' one table had passed what the type solver checks in one piece). The dock's Base tile
-- as the way home (TR19) and everything that presses answering the pointer (TR20).

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Combat = require(Shared.Config.Combat)
local HomeConfig = require(Shared.Config.Home)
local HudConfig = require(Shared.Config.Hud)
local UIKit = require(Shared.Config.UIKit)
local Markers = require(Shared.World.Markers)
local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local BaseController = require(script.Parent.Parent.Parent.Main.BaseController)
local ProfileController = require(script.Parent.Parent.ProfileController)
local UI = script.Parent.Parent.Parent.Parent.UI
local BreakerScreen = require(UI.BreakerScreen)
local VoidkinScreen = require(UI.VoidkinScreen)
local Button = require(UI.Kit.Button)
local Hover = require(UI.Kit.Hover)
local Screen = require(UI.Kit.Screen)
local Toast = require(UI.Kit.Toast)

local HudCases = {}

-- Cases' own helpers and measures, one home each.
export type Given = {
	REPLICATE: number,
	LEAD_SETTLE: number,
	SET_DOWN: number,
	R6_ROOT_HEIGHT: number,
	waitFor: (t: any, seconds: number, ok: () -> boolean) -> boolean,
	streamed: (t: any, name: string, where: { [string]: any }?) -> Instance?,
	lintClean: (t: any, where: string) -> (),
	myLead: () -> Model?,
}

function HudCases.Cases(given: Given): { any }
	local REPLICATE, LEAD_SETTLE, SET_DOWN, R6_ROOT_HEIGHT = given.REPLICATE, given.LEAD_SETTLE, given.SET_DOWN, given.R6_ROOT_HEIGHT
	local waitFor, streamed, lintClean, myLead = given.waitFor, given.streamed, given.lintClean, given.myLead

	return {
		{
			-- TR19 (docs/test-requests.md, "Home in one tap: the dock's Base tile"): at home the tile is quiet and a tap does
			-- nothing; out on Lantern Row a tap charges, the tile filling from its foot and the avatar's outline lifting, then the
			-- player stands at their plot's spawn facing its Breaker with their lead beside them; the cooldown's veil is on the
			-- tile away from home; a fight, a hit in the charge and a keeper's try each refuse in plain words and shake the tile;
			-- a lead fallen alone out in a ground gives the tile its pip.
			Name = "HUD: TR19, the dock's Base tile takes the player home after its charge, refuses in plain words, is quiet at home, and wears the pip after a lone fall",
			Stay = true, -- it moves the avatar itself; the next case's reset takes it back to the pad
			Run = function(t: any)
				t.Wait(LEAD_SETTLE)
				Screen.Close()
				local player = Players.LocalPlayer
				local parts = HudController.Parts()
				local base = parts.Base :: TextButton
				local plot = player:GetAttribute("Plot")
				local where = if type(plot) == "number" then { Plot = plot } else nil
				local spawn = if where then streamed(t, "Spawn", where) else nil
				local breaker = if where then streamed(t, "Breaker", where) else nil
				local elite = streamed(t, "Elite")
				t.Check("the plot's spawn and Breaker, and the elite's square", spawn ~= nil and breaker ~= nil and elite ~= nil)
				if not (spawn and breaker and elite) then
					return
				end
				local function flat(a: Vector3, b: Vector3): number
					return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
				end
				local function shakes(): number
					return tonumber(base:GetAttribute("Shakes")) or 0
				end
				local function state(): any
					return t.Server("HomeState")
				end
				local function said(words: string): boolean
					return table.find(Toast.Shown(), words) ~= nil
				end
				-- Home before the elite comes back: left on its square, the lead fells it again, and it rests Back.Elite
				-- seconds, past the packs' case (seen 2026-11-15).
				local function restore()
					t.Server("HomeReady")
					t.Server("LeadHeal")
					t.Root().CFrame = CFrame.new(Markers.At(spawn).Position + Vector3.new(0, R6_ROOT_HEIGHT, 0))
					t.Wait(0.5)
					t.Server("PackBack", "Elite")
				end
				t.Server("HomeReady")
				t.Check("the elite's square is cleared", t.Server("PackDefeat", "Elite").Ok == true)
				local square = Markers.At(elite).Position + Vector3.new(0, R6_ROOT_HEIGHT, 0)
				local home = Markers.At(spawn).Position
				-- At home: quiet, and a tap does nothing.
				t.Root().CFrame = CFrame.new(home + Vector3.new(0, R6_ROOT_HEIGHT, 0))
				t.Wait(0.5)
				t.Check("at home the tile is quiet", waitFor(t, 1, function(): boolean
					return base:GetAttribute("Look") == "Quiet"
				end), tostring(base:GetAttribute("Look")))
				t.Equal("and the server says here", state().Refusal, "Here")
				local still = shakes()
				Button.Press(base)
				t.Wait(0.4)
				t.Check("a tap does nothing: no charge, nothing said", player:GetAttribute("HomeCharge") == nil and shakes() == still)
				-- Out on Lantern Row, nothing in the way: a tap charges, then home.
				t.Root().CFrame = CFrame.new(square)
				t.Wait(LEAD_SETTLE)
				t.Check("out in the ground the tile is at rest", waitFor(t, 1, function(): boolean
					return base:GetAttribute("Look") == "Rest" and base:GetAttribute("Mood") == nil
				end), tostring(base:GetAttribute("Look")))
				t.Equal("and the server would take them home", state().Refusal, "")
				local fov = workspace.CurrentCamera.FieldOfView
				local pressed = os.clock()
				t.Check("a tap begins the charge", Button.Press(base) and waitFor(t, REPLICATE, function(): boolean
					return player:GetAttribute("HomeCharge") ~= nil
				end))
				t.Check("the tile fills from its foot", waitFor(t, HomeConfig.Charge, function(): boolean
					local fill = base:GetAttribute("Fill")
					return type(fill) == "number" and fill > 0 and fill < 1
				end), tostring(base:GetAttribute("Fill")))
				local character = player.Character
				local glow = if character then character:FindFirstChild("NL_HomeCharge") else nil
				t.Check("and the avatar's outline lifts in void light", glow ~= nil and glow:IsA("Highlight") and glow.Enabled and glow.OutlineColor == HomeConfig.Outline)
				t.Check("then it lands", waitFor(t, HomeConfig.Charge + REPLICATE + 0.5, function(): boolean
					local landed = player:GetAttribute("HomeLanded")
					return type(landed) == "number" and landed >= pressed
				end))
				local took = (tonumber(player:GetAttribute("HomeLanded")) or pressed) - pressed
				t.Check("after the whole charge", took >= HomeConfig.Charge - 0.05, string.format("%.2f s", took))
				t.Wait(0.3) -- physics settles the set-down
				local root = t.Root()
				t.Near("at the plot's spawn (studs off)", flat(root.Position, home), 0, SET_DOWN)
				local toward = Markers.At(breaker).Position - root.Position
				local look = root.CFrame.LookVector
				local facing = Vector3.new(look.X, 0, look.Z).Unit:Dot(Vector3.new(toward.X, 0, toward.Z).Unit)
				t.Check("facing its Breaker", facing > math.cos(math.rad(10)), string.format("%.0f degrees off", math.deg(math.acos(math.clamp(facing, -1, 1)))))
				local mine = myLead()
				local beside = if mine then flat(mine:GetPivot().Position, root.Position) else math.huge
				t.Check("the lead beside them", beside < 5, string.format("%.1f studs", beside))
				local lit = glow ~= nil and glow:IsA("Highlight") and glow.Enabled
				t.Check("the charge's fill and outline are gone", base:GetAttribute("Fill") == nil and not lit)
				t.Check("the field of view settles back", waitFor(t, HomeConfig.Settle + 0.3, function(): boolean
					return math.abs(workspace.CurrentCamera.FieldOfView - fov) < 0.05
				end), string.format("%.2f", workspace.CurrentCamera.FieldOfView))
				-- The cooldown: quiet at home, its veil on the tile out in the ground, and a tap says how long.
				t.Check("home again, the tile is quiet", waitFor(t, 1, function(): boolean
					return base:GetAttribute("Look") == "Quiet"
				end))
				t.Root().CFrame = CFrame.new(square)
				t.Wait(0.5)
				local veil = base:GetAttribute("Veil")
				t.Check("away, the cooldown's veil covers what's left", type(veil) == "number" and veil > 0 and veil < 1, tostring(veil))
				t.Check("still tappable, to say why", Button.State(base) ~= "Disabled", Button.State(base))
				local before = shakes()
				Button.Press(base)
				t.Check("a tap says how long, and the tile shakes", waitFor(t, REPLICATE, function(): boolean
					for _, shown in Toast.Shown() do
						if string.match(shown, "^Ready in %d+ s$") then
							return shakes() > before
						end
					end
					return false
				end), table.concat(Toast.Shown(), " | "))
				t.Equal("the server agrees", state().Refusal, "Cooldown")
				-- In a fight: dim, and a tap says so.
				t.Server("HomeReady")
				t.Server("HomeHit")
				t.Check("a hit just now dims the tile", waitFor(t, REPLICATE, function(): boolean
					return base:GetAttribute("Look") == "Dim"
				end), tostring(base:GetAttribute("Look")))
				before = shakes()
				Button.Press(base)
				t.Check("a tap says it's in a fight, and shakes", waitFor(t, REPLICATE, function(): boolean
					return said("In a fight") and shakes() > before
				end))
				-- A hit in the charge cancels it, and nothing is spent.
				t.Server("HomeReady")
				t.Wait(REPLICATE)
				before = shakes()
				local from = t.Root().Position
				t.Check("a fresh charge", Button.Press(base) and waitFor(t, REPLICATE, function(): boolean
					return player:GetAttribute("HomeCharge") ~= nil
				end))
				t.Server("HomeHit")
				t.Check("a hit in it cancels it, said and shaken", waitFor(t, HomeConfig.Charge + REPLICATE, function(): boolean
					return player:GetAttribute("HomeCharge") == nil and shakes() > before
				end))
				t.Check("the player wasn't moved", flat(t.Root().Position, from) < SET_DOWN)
				t.Check("and no cooldown was spent", player:GetAttribute("HomeReady") == nil)
				-- A keeper's try: dim, and a tap says so.
				t.Server("HomeReady")
				t.Server("KeeperRest", 0)
				local try = t.Server("KeeperTry")
				local tried = type(try) == "table" and try.Ok == true
				t.Check("a try starts", tried, if type(try) == "table" then tostring(try.Error) else "")
				if tried then
					t.Check("in a boss's ground the tile dims", waitFor(t, REPLICATE + 1, function(): boolean
						return player:GetAttribute("Try") ~= nil and base:GetAttribute("Look") == "Dim"
					end), tostring(base:GetAttribute("Look")))
					before = shakes()
					Button.Press(base)
					t.Check("a tap says it's a boss's ground, and shakes", waitFor(t, REPLICATE, function(): boolean
						return said("Not in a boss's ground") and shakes() > before
					end))
					-- The keeper stands in its ring only once the try's fade has moved the player (the server says NoTry
					-- before), so the loss is asked until it's taken, then the try ends after the lead's fall.
					local fade = Combat.Keeper.Fade
					local ended: any = nil
					waitFor(t, fade.Out + fade.Hold + 1, function(): boolean
						ended = t.Server("KeeperEnd", "Loss")
						return type(ended) == "table" and ended.Ok == true
					end)
					t.Check("the try ends", type(ended) == "table" and ended.Ok == true and waitFor(t, Combat.Keeper.LossPause + fade.Out + fade.Hold + 2, function(): boolean
						return player:GetAttribute("Try") == nil
					end), if type(ended) == "table" then tostring(ended.Error) else "")
					t.Server("LeadHeal")
					t.Wait(LEAD_SETTLE)
				end
				-- A lead fallen alone out in a ground: the pip on the tile, gone at its return.
				t.Root().CFrame = CFrame.new(square)
				t.Wait(LEAD_SETTLE)
				t.Check("no pip while the lead stands", base:GetAttribute("New") ~= true)
				local alone = t.Server("VoidkinFallen")
				t.Check("none other ready", type(alone) == "table" and alone.Ok == true)
				t.Check("the lead falls", t.Server("FightHealth", 0).Ok == true)
				t.Check("then the tile wears its pip", waitFor(t, Combat.Lead.Leave + REPLICATE + 1, function(): boolean
					return base:GetAttribute("New") == true
				end))
				t.Check("and never the next lead's button", not parts.Next.Visible)
				lintClean(t, "a lead fallen alone, the Base tile's pip")
				t.Server("LeadHeal")
				t.Check("at the lead's return the pip is gone", waitFor(t, 2, function(): boolean
					return base:GetAttribute("New") ~= true
				end))
				restore()
			end,
		},
		{
			-- TR20 (docs/test-requests.md, "Everything that presses answers the pointer: hover"): a dock tile, a Breaker's
			-- chamber and a Voidkin card answer the mouse within a frame, lift and brighten in their own place, and go back;
			-- a dock tile's word shows after a moment, a refused one's reason; a pad's selection answers the same with a rim;
			-- a touch answers nothing.
			Name = "UI: TR20, a dock tile, a Breaker's chamber and a Voidkin card answer the pointer within a frame and move nothing round them; a pad's selection too; a touch nothing",
			Run = function(t: any)
				local motion = HudConfig.Motion.Hover
				local settle = math.max(motion.In, motion.Out) + 0.1
				Screen.Close()
				t.Wait(HudConfig.Motion.Screen.Exit + 0.1)
				local parts = HudController.Parts()
				local dock = parts.Dock :: Frame
				local scale = dock.AbsoluteSize.X / UIKit.Dock.Size.X
				local inventory = parts.Voidkin :: TextButton
				local tile = dock:FindFirstChild("InventoryTile") :: ImageLabel
				local halo = dock:FindFirstChild("InventoryHalo") :: ImageLabel
				local edge = dock:FindFirstChild("InventoryEdge") :: ImageLabel
				local word = dock:FindFirstChild("InventoryWord") :: TextLabel
				local others = { dock:FindFirstChild("BaseTile") :: ImageLabel, dock:FindFirstChild("MapTile") :: ImageLabel }
				local function at(piece: GuiObject): Vector2
					return piece.AbsolutePosition
				end
				local restTile = at(tile)
				local restOthers = { at(others[1]), at(others[2]) }
				local restButton = at(inventory)
				local function still(): boolean
					return (at(others[1]) - restOthers[1]).Magnitude < 0.5 and (at(others[2]) - restOthers[2]).Magnitude < 0.5 and (at(inventory) - restButton).Magnitude < 0.5
				end
				Hover.Pretend("Mouse")
				-- The dock: within a frame, then whole: lifted, its halo part lit, nothing else moved.
				Hover.Force(inventory, true)
				RunService.RenderStepped:Wait()
				RunService.RenderStepped:Wait()
				t.Check("a dock tile answers within a frame of the pointer's entry", Hover.Share(inventory) > 0, string.format("%.2f", Hover.Share(inventory)))
				t.Wait(settle)
				t.Near("whole once it's eased in", Hover.Share(inventory), 1, 1e-3)
				t.Near("it lifts its points", (restTile.Y - at(tile).Y) / scale, motion.Lift, 0.3)
				t.Check("its halo part lit", halo.Visible and math.abs(halo.ImageTransparency - (1 - motion.Halo)) < 0.02, string.format("%.2f", halo.ImageTransparency))
				t.Check("nothing round it moves, nor its tap", still())
				t.Check("its word shows after a moment", waitFor(t, motion.Word + 0.3, function(): boolean
					return word.Visible
				end) and word.Text == "Inventory", word.Text)
				Hover.Force(inventory, false)
				t.Wait(settle)
				t.Near("off it, it eases out", Hover.Share(inventory), 0, 1e-3)
				t.Check("back in its place, its word gone", (at(tile) - restTile).Magnitude < 0.5 and not word.Visible)
				-- A refused tile's word says why.
				local map = parts.Map :: TextButton
				local mapWord = dock:FindFirstChild("MapWord") :: TextLabel
				Hover.Force(map, true)
				t.Check("a refused tile's word is its reason", waitFor(t, motion.Word + 0.3, function(): boolean
					return mapWord.Visible
				end) and mapWord.Text == "The map isn't open yet", mapWord.Text)
				Hover.Force(map, nil)
				-- A touch answers nothing.
				Hover.Pretend("Touch")
				Hover.Force(inventory, true)
				t.Wait(settle)
				t.Equal("on touch nothing answers", Hover.Share(inventory), 0)
				Hover.Force(inventory, nil)
				-- A pad's selection answers the same, with the tile's rim.
				Hover.Pretend("Pad")
				GuiService.SelectedObject = inventory
				t.Wait(settle)
				t.Near("a pad's selection lifts it too", Hover.Share(inventory), 1, 1e-3)
				t.Check("and wears its rim", edge.Visible and edge.ImageTransparency < 0.05, string.format("%.2f", edge.ImageTransparency))
				GuiService.SelectedObject = nil
				t.Wait(settle)
				t.Check("deselected, the rim goes", not edge.Visible)
				Hover.Pretend("Mouse")
				-- A Breaker's chamber: its words lift inside it, its place and its neighbour's stay. A chamber takes a tap only
				-- while a shard breaks in it, so one goes in if the first stands empty (and is left breaking, as the Breaker's
				-- own cases leave theirs).
				local function firstWorks(): boolean
					local now = ProfileController.Get()
					local first = if now then now.Base.Chambers[1] else nil
					return first ~= nil and first.Work ~= nil
				end
				if not firstWorks() then
					local shard = "lanternrow_standard"
					local before = ProfileController.Get()
					local held = if before then before.Bag.Shards[shard] or 0 else 0
					t.Server("BaseGive", shard, 1)
					t.Check("a shard for the first chamber", waitFor(t, 2, function(): boolean
						local now = ProfileController.Get()
						return now ~= nil and (now.Bag.Shards[shard] or 0) == held + 1
					end) and ProfileController.Act("AddShard", { Shard = shard }).Ok == true and waitFor(t, 2, firstWorks))
				end
				Screen.Close()
				t.Wait(HudConfig.Motion.Screen.Exit + 0.1)
				BaseController.OpenBreaker()
				t.Check("the Breaker's screen opens", waitFor(t, 1, function(): boolean
					return Screen.Current() == BreakerScreen.Name
				end))
				t.Wait(HudConfig.Motion.Screen.Enter + 0.1)
				local screen = Screen.Frame(BreakerScreen.Name)
				local chamber = if screen then screen:FindFirstChild("Chamber1", true) :: Frame? else nil
				local neighbour = if screen then screen:FindFirstChild("Chamber2", true) :: Frame? else nil
				local tap = if chamber then chamber:FindFirstChild("Tap") :: TextButton? else nil
				local piece = if chamber then chamber:FindFirstChildWhichIsA("TextLabel") else nil
				t.Check("its first two chambers, a tap and words", chamber ~= nil and neighbour ~= nil and tap ~= nil and piece ~= nil)
				if chamber and neighbour and tap and piece then
					local restWords, restCell, restNext = at(piece), at(chamber), at(neighbour)
					Hover.Force(tap, true)
					t.Wait(settle)
					t.Near("a chamber's words lift inside it (points)", (restWords.Y - at(piece).Y) / scale, motion.Lift, 0.3)
					t.Check("its own place and its neighbour's stay", (at(chamber) - restCell).Magnitude < 0.5 and (at(neighbour) - restNext).Magnitude < 0.5)
					Hover.Force(tap, false)
					t.Wait(settle)
					t.Check("off it, its words are back", (at(piece) - restWords).Magnitude < 0.5)
					Hover.Force(tap, nil)
				end
				Screen.Close()
				t.Wait(HudConfig.Motion.Screen.Exit + 0.1)
				-- A Voidkin card on the strip: it scales in its own place and its rim lifts.
				local view = ProfileController.Get()
				t.Check("the save's copy is here", view ~= nil)
				if view == nil then
					Hover.Pretend(nil)
					return
				end
				t.Check("the Voidkin screen opens", Button.Press(inventory) and waitFor(t, 1, function(): boolean
					return Screen.Current() == "Voidkin"
				end))
				t.Wait(HudConfig.Motion.Screen.Enter + 0.1)
				local other: TextButton? = nil
				for id in view.Voidkin do
					local cell = VoidkinScreen.Find(id)
					if id ~= VoidkinScreen.Chosen() and cell and cell:IsA("TextButton") then
						other = cell
						break
					end
				end
				t.Check("a card besides the chosen one", other ~= nil)
				if other then
					local card = other :: TextButton
					local grow = card:FindFirstChild("Face") and (card:FindFirstChild("Face") :: Instance):FindFirstChild("Hover") :: UIScale?
					local rim = card:FindFirstChild("HoverRim") :: UIStroke?
					local restCard = at(card)
					Hover.Force(card, true)
					t.Wait(settle)
					t.Check("a card scales to its seed", grow ~= nil and math.abs(grow.Scale - motion.Card) < 1e-3 and math.abs(Button.Squeeze(card) - motion.Card) < 1e-3, if grow then string.format("%.3f", grow.Scale) else "no scale")
					t.Check("its rarity's rim lifts", rim ~= nil and rim.Transparency < 0.05)
					t.Check("in its own place", (at(card) - restCard).Magnitude < 0.5)
					Hover.Force(card, nil)
					t.Wait(settle)
					t.Check("off it, back to its size", grow ~= nil and math.abs(grow.Scale - 1) < 1e-3 and math.abs(Button.Squeeze(card) - 1) < 1e-3)
				end
				Screen.Close()
				Hover.Pretend(nil)
			end,
		},
	}
end

return HudCases
