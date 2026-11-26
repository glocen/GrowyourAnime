--!strict
-- CaptureCases: the capture after a reveal (TR60; UI/Reveal/Capture; docs/design.md, "Being seen", the capture). The
-- camera tile beside a Voidkin's card takes its own press, and a take shows the frame without the HUD, then puts every
-- layer, the tile and "Continue" back. Apart from Cases, which is past the type solver's size.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Voidkin = require(Shared.Definitions.Voidkin)
local RevealConfig = require(Shared.Config.Reveal)
local RevealArt = require(Shared.Config.RevealArt)
local BaseController = require(script.Parent.Parent.Parent.Main.BaseController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Layers = require(UI.Layers)
local RevealCapture = require(UI.Reveal.Capture)
local Helpers = require(script.Parent.Helpers)

local CaptureCases = {}

local waitFor = Helpers.waitFor

function CaptureCases.Cases(): { any }
	return {
		{
			Name = "Reveal: TR60, the capture's tile beside a Voidkin's card takes its own press; a take hides all but the world, the overlay and the card, then puts each back, and the card stays",
			Run = function(t: any)
				-- TR60 (docs/design.md, "Being seen", the capture): the camera tile stands beside the card's top right while it
				-- holds. A take (here without the share sheet) turns off every layer but the world's and the overlay's, hides the
				-- tile and "Continue" for its frame, then turns back on exactly what it turned off.
				local c = RevealConfig.Plate.Capture
				local rook = Voidkin.ById.rook
				BaseController.Reveal({ Def = rook.Id, Outcome = "New", Lead = false, Credits = 0 }, { Rarity = "Epic", Name = rook.Name, Model = rook.Model })
				BaseController.Seek(RevealArt.Rarities.Epic.Times.Card)
				t.Check("the card comes", waitFor(t, 1, function(): boolean
					local shown = BaseController.Revealed()
					return shown ~= nil and shown.Card
				end))
				local holder = Layers.Get("Overlay"):FindFirstChild("Reveal")
				local stage = holder and holder:FindFirstChild("Stage", true)
				local card = stage and stage:FindFirstChild("Card")
				local tile = card and card:FindFirstChild("Capture")
				if not (stage and stage:IsA("GuiObject") and card and card:IsA("Frame") and tile and tile:IsA("GuiButton")) then
					t.Check("the tile on the card", false)
					BaseController.Dismiss()
					return
				end
				local scale = stage.AbsoluteSize.X / RevealArt.Screen.X
				t.Check("the tile shows", tile.Visible)
				t.Near(`{c.Size} points wide`, tile.AbsoluteSize.X, c.Size * scale, 1)
				t.Near("square", tile.AbsoluteSize.Y, tile.AbsoluteSize.X, 0.5)
				t.Near("level with the card's top", tile.AbsolutePosition.Y, card.AbsolutePosition.Y, 1)
				t.Near(`{c.Gap} points right of the card`, tile.AbsolutePosition.X - (card.AbsolutePosition.X + card.AbsoluteSize.X), c.Gap * scale, 1)
				local view = workspace.CurrentCamera.ViewportSize
				local far = tile.AbsolutePosition + tile.AbsoluteSize
				t.Check("on screen", far.X <= view.X + 0.5 and far.Y <= view.Y + 0.5, string.format("%.0f,%.0f in %.0f,%.0f", far.X, far.Y, view.X, view.Y))
				-- Its own press: the first piece at its middle that takes one is the tile, not the reveal's tap cover. The hit
				-- list is the drawn frame's, so a plate made this frame isn't in it yet.
				RunService.RenderStepped:Wait()
				RunService.RenderStepped:Wait()
				local gui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui
				local middle = tile.AbsolutePosition + tile.AbsoluteSize / 2
				local taker: GuiObject? = nil
				for _, object in gui:GetGuiObjectsAtPosition(middle.X, middle.Y) do
					if object:IsA("GuiButton") or object.Active then
						taker = object
						break
					end
				end
				t.Check("a press at its middle lands on it", taker == tile, if taker then taker:GetFullName() else "nothing")
				t.Wait(RevealConfig.CardHold + 0.1)
				local skip = card:FindFirstChild("Skip")
				t.Check(`"Continue" shows before the take`, skip ~= nil and skip:IsA("GuiObject") and skip.Visible)
				-- The take: which of the layers were on, then what it leaves on. A layer is a ScreenGui of ours with its own
				-- UIScale (UI/Layers); the reveal's safe-area probe draws nothing and isn't one.
				local on: { [ScreenGui]: boolean } = {}
				for _, child in gui:GetChildren() do
					if child:IsA("ScreenGui") and string.sub(child.Name, 1, 3) == "NL_" and child:FindFirstChildOfClass("UIScale") ~= nil then
						on[child] = child.Enabled
					end
				end
				local function kept(layer: ScreenGui): boolean
					return layer.Name == "NL_World" or layer.Name == "NL_Overlay"
				end
				local before = RevealCapture.Last()
				local started = false
				task.spawn(function()
					started = RevealCapture.Take(card, false)
				end)
				RunService.RenderStepped:Wait()
				t.Check("a second take meanwhile is refused", not RevealCapture.Take(card, false))
				local wrong: { string } = {}
				for layer, was in on do
					if layer.Enabled ~= (kept(layer) and was) then
						table.insert(wrong, `{layer.Name} {if layer.Enabled then "on" else "off"}`)
					end
				end
				t.Check("in its frame, only the world's and the overlay's layers are on", #wrong == 0, table.concat(wrong, ", "))
				t.Check("and the tile is hidden", not tile.Visible)
				t.Check(`and "Continue"`, skip ~= nil and skip:IsA("GuiObject") and not skip.Visible)
				t.Check("the take ends within its timeout", waitFor(t, c.Timeout + 0.5, function(): boolean
					return RevealCapture.Last() ~= before
				end))
				t.Check("it was taken", started)
				local taken = RevealCapture.Last()
				local turned = 0
				for layer, was in on do
					if was and not kept(layer) then
						turned += 1
					end
				end
				t.Equal("it counts the layers it turned off", if taken then taken.Off else nil, turned)
				t.Check(`the engine answered ({if taken then taken.Result else "none"})`, taken ~= nil and taken.Result ~= "Timeout")
				local back: { string } = {}
				for layer, was in on do
					if layer.Enabled ~= was then
						table.insert(back, layer.Name)
					end
				end
				t.Check("then every layer as it was", #back == 0, table.concat(back, ", "))
				t.Check("the tile back", tile.Visible)
				t.Check(`"Continue" back`, skip ~= nil and skip:IsA("GuiObject") and skip.Visible)
				local shown = BaseController.Revealed()
				t.Check("the card still holds", shown ~= nil and shown.Card ~= nil)
				BaseController.Dismiss()
				t.Check("it closes", BaseController.Revealed() == nil)
			end,
		},
	}
end

return CaptureCases
