--!strict
-- NoticeCases (client, Studio only): the level-up's notice (AR12, take B; TR41 (c)), a list of its own that joins the run
-- apart from Cases (Cases is at the type checker's limit); its helpers are Helpers'. Its motion's numbers are Rules.Hud's
-- logic case; this list checks what the player sees of it: where it stands, what it's made of, and that a real level
-- gained plays it through, with no toast.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local Shared = ReplicatedStorage.Shared
local HudConfig = require(Shared.Config.Hud)
local Profile = require(Shared.Data.Profile)
local Hud = require(Shared.Rules.Hud)

local UI = script.Parent.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Layers = require(UI.Layers)
local Read = require(UI.Read)
local LevelNotice = require(UI.LevelNotice)
local Text = require(UI.Kit.Text)
local Toast = require(UI.Kit.Toast)
local ProfileController = require(script.Parent.Parent.ProfileController)
local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local Helpers = require(script.Parent.Helpers)

local LOOK = HudConfig.LevelNotice

local NoticeCases = {}

local function leadOf(view: Profile.View?): Profile.OwnedVoidkin?
	return if view then view.Voidkin[view.Roles.Lead] else nil
end

function NoticeCases.Cases(): { any }
	local waitFor, ANSWER = Helpers.waitFor, Helpers.ANSWER
	return {
		{
			Name = "HUD: TR41 (c), the level-up's notice: a level gained shows it under the lead's corner at the card's left edge, from Modulo's images, its name and LEVEL UP, sized to its words, with no toast; it slides in, its number lands with a flash and a knock, one sheen crosses, and it leaves",
			Run = function(t: any)
				local owned = leadOf(ProfileController.Get())
				t.Check("the player has a lead", owned ~= nil)
				if owned == nil then
					return
				end
				local was = owned.Level
				local parts = LevelNotice.Parts()
				local holder, body = parts.Holder, parts.Body
				local plate, flash, sheen = parts.Plate, parts.Flash :: ImageLabel, parts.Sheen :: ImageLabel
				local name, line, number = parts.Name :: TextLabel, parts.Line :: TextLabel, parts.Number :: TextLabel
				t.Check("mounted in the HUD's layer", holder ~= nil and holder.Parent == Layers.Get("Hud"))
				if holder == nil then
					return
				end
				-- Watched every frame from the level's arrival.
				local scale = Layers.Scale()
				local first, flashed, knocked, sheened, biggest, squashed = nil :: number?, 0, 0, false, 0, math.huge
				local slid, slidWant = math.huge, 0
				local said: { string } = {}
				local watch = RunService.RenderStepped:Connect(function()
					if not holder.Visible then
						return
					end
					local age = holder:GetAttribute("Age")
					if type(age) ~= "number" then
						return
					end
					if first == nil then
						-- Its first frame seen stands where the rule puts it at its age, out of the screen's left edge: its
						-- body's right end and its glow past the screen's edge at Away 1.
						first = age
						local wide = LevelNotice.Wide()
						local n = Hud.Notice(age, LOOK.Motion, wide, wide - LOOK.Tall * LOOK.Lean, GuiService.ReducedMotionEnabled)
						local off = holder.AbsolutePosition.X / scale + wide + LOOK.Images.Plate.Pad + 2
						slid, slidWant = (body.AbsolutePosition.X - holder.AbsolutePosition.X) / scale, n.Knock - n.Away * off
					end
					if flash.Visible then
						flashed = math.max(flashed, 1 - flash.ImageTransparency)
					end
					knocked = math.max(knocked, (body.AbsolutePosition.X - holder.AbsolutePosition.X) / scale)
					sheened = sheened or (sheen.Visible and sheen.ImageTransparency < 0.5)
					local swell = number:FindFirstChildOfClass("UIScale")
					if swell and number.TextTransparency < 0.99 then
						biggest = math.max(biggest, swell.Scale)
						squashed = math.min(squashed, swell.Scale)
					end
					for _, message in Toast.Shown() do
						table.insert(said, message)
					end
				end)
				local m = LOOK.Motion
				local ok, err = pcall(function()
					t.Check("a level gained", t.Server("LeadLevel", was + 1).Ok == true)
					t.Check("the notice shows", waitFor(t, ANSWER, function(): boolean
						return holder.Visible
					end))
					t.Wait(m.In + m.Fall + m.Settle + 0.1)
					-- At rest: its words, its place, its width, its stack.
					local now = leadOf(ProfileController.Get())
					t.Equal("the number is the new level", number.Text, tostring(was + 1))
					-- The card's badge says the same once it rests: it reads the lead's model, which the server sets in the
					-- same step as the save (LeadService's sync; research's question on TR41 (c), 2026-11-17).
					local badge = HudController.Parts().Lead:FindFirstChild("Level", true) :: TextLabel?
					t.Check("and the card's badge says it too, once it rests", badge ~= nil and badge.Text == tostring(was + 1), if badge then badge.Text else "no badge")
					t.Check("the name is the lead's, as shown to its owner", now ~= nil and name.Text == Read.VoidkinName(now), name.Text)
					t.Equal("and LEVEL UP under it", line.Text, LOOK.Words.Line.Text)
					-- The number's middle on the block's, by its label's own middle (centred text, anchored at its middle).
					local body = parts.Body
					local middleAt = number.AbsolutePosition.X + number.AbsoluteSize.X / 2
					local want = body.AbsolutePosition.X + LOOK.Words.Number.Middle.X * scale
					t.Check("its number centred on the block", number.TextXAlignment == Enum.TextXAlignment.Center and math.abs(middleAt - want) < 1,
						string.format("its middle at %.1f px, the block's %.1f", middleAt, want))
					local hud = HudController.Parts()
					local card = hud.Lead
					local corner = card.AbsolutePosition.Y + card.AbsoluteSize.Y + (HudConfig.Readout.Under + HudConfig.Readout.Size + LOOK.Below) * scale
					t.Check("at the card's left edge", math.abs(holder.AbsolutePosition.X - card.AbsolutePosition.X) < 1,
						string.format("%.1f, the card's %.1f", holder.AbsolutePosition.X, card.AbsolutePosition.X))
					t.Check("under the lead's corner, Below its readout's foot", math.abs(holder.AbsolutePosition.Y - corner) < 1,
						string.format("%.1f, want %.1f", holder.AbsolutePosition.Y, corner))
					local wide = math.ceil(LOOK.Base + math.max(Text.Wide(name, name.Text), Text.Wide(line, line.Text)))
					t.Check("as wide as its words ask, Base and the wider", math.abs(holder.AbsoluteSize.X / scale - wide) < 0.5 and LevelNotice.Wide() == wide,
						string.format("%.1f points, want %d", holder.AbsoluteSize.X / scale, wide))
					t.Check("its words inside its leaning end", name.AbsolutePosition.X + name.TextBounds.X <= holder.AbsolutePosition.X + holder.AbsoluteSize.X - LOOK.Tall * LOOK.Lean * scale / 2,
						string.format("the name ends %.1f px before its right", holder.AbsolutePosition.X + holder.AbsoluteSize.X - name.AbsolutePosition.X - name.TextBounds.X))
					local images = LOOK.Images
					-- Three plain pieces of Modulo's plate, not a Roblox slice, which drew it wrong under the layer's scale.
					local leftEnd, middle, rightEnd = plate:FindFirstChild("Left") :: ImageLabel?, plate:FindFirstChild("Middle") :: ImageLabel?, plate:FindFirstChild("Right") :: ImageLabel?
					local cut = images.Plate.Cut :: { number }
					t.Check("Modulo's plate in three plain pieces of its image", leftEnd ~= nil and middle ~= nil and rightEnd ~= nil)
					if leftEnd and middle and rightEnd then
						t.Check("each of its image, stretched plainly", leftEnd.Image == images.Plate.Id and middle.Image == images.Plate.Id and rightEnd.Image == images.Plate.Id
							and leftEnd.ScaleType == Enum.ScaleType.Stretch and middle.ScaleType == Enum.ScaleType.Stretch and rightEnd.ScaleType == Enum.ScaleType.Stretch)
						t.Check("its ends at their own size", math.abs(leftEnd.AbsoluteSize.X - cut[1] * scale) < 1 and math.abs(rightEnd.AbsoluteSize.X - cut[3] * scale) < 1,
							string.format("%.1f and %.1f px", leftEnd.AbsoluteSize.X, rightEnd.AbsoluteSize.X))
						t.Check("and its middle meets both, no seam", math.abs(leftEnd.AbsolutePosition.X + leftEnd.AbsoluteSize.X - middle.AbsolutePosition.X) < 0.5
							and math.abs(middle.AbsolutePosition.X + middle.AbsoluteSize.X - rightEnd.AbsolutePosition.X) < 0.5)
						t.Check("each its own share of the image", leftEnd.ImageRectSize.X + middle.ImageRectSize.X + rightEnd.ImageRectSize.X == images.Plate.Pixels.X
							and middle.ImageRectOffset.X == leftEnd.ImageRectSize.X and rightEnd.ImageRectOffset.X == leftEnd.ImageRectSize.X + middle.ImageRectSize.X)
					end
					t.Check("its glow past its body by its pad", math.abs(plate.AbsoluteSize.Y - (LOOK.Tall + 2 * images.Plate.Pad) * scale) < 1)
					t.Check("the flash and the sheen are Modulo's", flash.Image == images.Flash.Id and sheen.Image == images.Sheen.Id)
					t.Check("stacked as the json says: plate, flash, sheen, the words, the number", plate.ZIndex < flash.ZIndex and flash.ZIndex < sheen.ZIndex
						and sheen.ZIndex < name.ZIndex and name.ZIndex == line.ZIndex and line.ZIndex < number.ZIndex)
					t.Check("over the HUD's other parts", holder.ZIndex >= card.ZIndex)
					-- A second level while it's shown lands again, and it holds anew.
					t.Check("another level", t.Server("LeadLevel", was + 2).Ok == true)
					t.Check("the number takes it", waitFor(t, ANSWER, function(): boolean
						return number.Text == tostring(was + 2)
					end), number.Text)
					t.Wait(0.05)
					local age = holder:GetAttribute("Age")
					t.Check("and lands again: back at its arrival", type(age) == "number" and age < m.In + m.Fall + m.Settle + 0.3, tostring(age))
					t.Check("it leaves after its hold", waitFor(t, m.Hold + m.Out + 1, function(): boolean
						return not holder.Visible
					end))
					-- A nickname runs to 20 letters: shown here on this client alone, the widest, at the smallest phone, it stops a
					-- gap short of the step's chip over the dock (they share a row on a phone) and the name is cut with "…".
					Layers.Force(Theme.Scale.Floor)
					Layers.Box(Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height))
					t.Wait(0.3)
					local small = Layers.Scale()
					local chip = hud.Chip
					local wideName = string.rep("W", 20)
					LevelNotice.Show(wideName, was + 2)
					t.Wait(m.In + m.Fall + m.Settle + 0.1)
					local right = holder.AbsolutePosition.X + holder.AbsoluteSize.X
					t.Check("a long name: it stops a gap short of the step's chip", right <= chip.AbsolutePosition.X - Theme.Size.Gap * small + 1,
						string.format("its right at %.1f, the chip's left at %.1f", right, chip.AbsolutePosition.X))
					-- Across only: Text.Legible may stand a small word taller than its label, which TextFits counts too.
					t.Check("and the name is cut, inside its leaning end", name.Text == wideName and name.TextTruncate == Enum.TextTruncate.AtEnd
						and Text.Wide(name, wideName) > name.AbsoluteSize.X / small and name.TextBounds.X <= name.AbsoluteSize.X + 0.5
						and name.AbsolutePosition.X + name.AbsoluteSize.X <= right - (LOOK.Base - LOOK.Words.Name.At.X) * small + 1,
						string.format("needs %.1f points, has %.1f", Text.Wide(name, wideName), name.AbsoluteSize.X / small))
					t.Check("never narrower than LEVEL UP needs", line.TextBounds.X <= line.AbsoluteSize.X + 0.5,
						string.format("%.1f in %.1f px", line.TextBounds.X, line.AbsoluteSize.X))
					t.Check("it leaves", waitFor(t, m.Hold + m.Out + 1, function(): boolean
						return not holder.Visible
					end))
				end)
				watch:Disconnect()
				Layers.Box(nil)
				Layers.Force(nil)
				t.Server("LeadLevel", was)
				if not ok then
					error(err, 0)
				end
				local still = GuiService.ReducedMotionEnabled
				t.Check("seen from its first frame", first ~= nil and (first :: number) < 0.1, tostring(first))
				if not still then
					t.Check("it slid in from off the screen's left: its first frame where the rule puts it", math.abs(slid - slidWant) < 1 and slidWant < 0,
						string.format("%.1f points from its place, the rule's %.1f, at %.3f s", slid, slidWant, first or -1))
					t.Check(`its number fell from {m.From} times its size`, biggest > m.From - 0.2, string.format("%.2f", biggest))
					t.Check("and landed squashed", squashed < 1 and squashed >= m.Squash - 0.03, string.format("%.2f", squashed))
					t.Check("the block flashed as it landed", flashed > m.Flash.Strength * 0.5, string.format("%.2f", flashed))
					t.Check("the whole notice was knocked", knocked > 0.5, string.format("%.2f points", knocked))
					t.Check("one sheen crossed it", sheened)
				end
				local toastLevel = false
				for _, message in said do
					toastLevel = toastLevel or string.find(string.lower(message), "level", 1, true) ~= nil
				end
				t.Check("no toast says the level: the notice says it once", not toastLevel)
			end,
		},
		{
			Name = "Take: TR41 (c), the level-up's notice at the smallest phone, held at the age the driver writes, for research",
			Manual = true,
			Stay = true,
			Run = function(t: any)
				-- Research's read of TR41 (c) (docs/test-requests.md, TR41): the notice for the lead at its next level, then the
				-- longest name at 100, drawn at the age (seconds) ReplicatedStorage.NL_TakeStep holds: "Long" swaps to the long
				-- name, "Play" runs the clock, "End" finishes. Not played: shown for the take, no level is gained.
				local owned = leadOf(ProfileController.Get())
				t.Check("the player has a lead", owned ~= nil)
				if owned == nil then
					return
				end
				local step = Instance.new("StringValue")
				step.Name = "NL_TakeStep"
				step.Value = "1.5"
				step.Parent = ReplicatedStorage
				Layers.Force(Theme.Scale.Floor)
				Layers.Box(Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height))
				t.Wait(0.3)
				LevelNotice.Show(Read.VoidkinName(owned), owned.Level + 1)
				local shown = ""
				waitFor(t, 300, function(): boolean
					local value = step.Value
					if value ~= shown then
						shown = value
						if value == "Long" then
							LevelNotice.Show("Little Storm Cloud", 100)
							LevelNotice.Hold(1.5)
						elseif value == "Play" then
							LevelNotice.Hold(nil)
							LevelNotice.Show(Read.VoidkinName(owned), owned.Level + 1)
						elseif tonumber(value) then
							LevelNotice.Hold(tonumber(value))
						end
					end
					return value == "End"
				end)
				LevelNotice.Hold(nil)
				Layers.Box(nil)
				Layers.Force(nil)
				step:Destroy()
			end,
		},
	}
end

return NoticeCases
