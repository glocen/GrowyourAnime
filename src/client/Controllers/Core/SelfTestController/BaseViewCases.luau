--!strict
-- The base view's Upgrade cases (TR21's block; docs/ui.md, 7; UI.BaseView, Rules.BaseLevels.Ask): the base's level
-- carries its press with the price, a tap on a chip opens that machine's panel at the side its chip isn't on, a press
-- shows only where there's a level to buy and takes no tap while it says why, and a second tap closes the panel. No case
-- here buys anything: what a press sends, and that the server takes it, is the logic cases' (Cases/BaseAsk).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local BaseViewConfig = require(Shared.Config.BaseView)
local BaseLevels = require(Shared.Rules.BaseLevels)
local Profile = require(Shared.Data.Profile)
local Helpers = require(script.Parent.Helpers)
local ProfileController = require(script.Parent.Parent.ProfileController)
local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local BaseController = require(script.Parent.Parent.Parent.Main.BaseController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Screen = require(UI.Kit.Screen)
local Button = require(UI.Kit.Button)
local BaseView = require(UI.BaseView)
local Layers = require(UI.Layers)
local Theme = require(UI.Theme)

local BaseViewCases = {}

-- Whether `inner` sits inside `outer`, to half a pixel.
local function within(inner: GuiObject, outer: GuiObject): boolean
	local p, q = inner.AbsolutePosition, outer.AbsolutePosition
	return p.X >= q.X - 0.5 and p.Y >= q.Y - 0.5 and p.X + inner.AbsoluteSize.X <= q.X + outer.AbsoluteSize.X + 0.5 and p.Y + inner.AbsoluteSize.Y <= q.Y + outer.AbsoluteSize.Y + 0.5
end

local function crosses(a: GuiObject, b: GuiObject): boolean
	local p, q = a.AbsolutePosition, b.AbsolutePosition
	return p.X < q.X + b.AbsoluteSize.X and q.X < p.X + a.AbsoluteSize.X and p.Y < q.Y + b.AbsoluteSize.Y and q.Y < p.Y + a.AbsoluteSize.Y
end

function BaseViewCases.Cases(): { any }
	return {
		{
			Name = "Base view: the base's level carries Upgrade with its price, a chip's tap opens its machine's panel with its own, and a shut press says why",
			Place = "Main", -- TR45: its world stands in that place only
			Run = function(t: any)
				Screen.Close()
				local seconds = BaseViewConfig.Lift.Seconds
				HudController.OpenView()
				t.Check("it opens", BaseView.IsOpen())
				t.Wait(seconds + 0.3)
				local ok, err = pcall(function()
					local view = ProfileController.Get() :: Profile.View
					local credits = view.Currency.Credits
					local parts = BaseView.Parts()
					local level, press = parts.Level :: Frame, parts.Upgrade :: TextButton
					local ask = BaseLevels.Ask(view.Base :: any, "Base", credits) :: BaseLevels.Ask
					t.Check("the base's press shows while there's a level to buy", press.Visible == (ask.Offer.Price ~= nil))
					if press.Visible then
						t.Check("on the level's plate, a touch high", within(press, level) and press.AbsoluteSize.Y >= Theme.Size.Touch - 0.5, `{math.floor(press.AbsoluteSize.Y)} px`)
						local words = press:FindFirstChildWhichIsA("TextLabel", true)
						t.Check("it carries the price", press:GetAttribute("Shows") ~= nil and string.find(tostring(press:GetAttribute("Shows")), "Upgrade · %d") ~= nil, if words then words.Text else "")
						if ask.Offer.Why ~= nil then
							t.Check(`shut ({ask.Offer.Why}), it takes no tap`, Button.Press(press) == false and view.Base.Level == (ProfileController.Get() :: Profile.View).Base.Level)
						end
					end
					local close = (level.Parent :: Frame):FindFirstChild("Close")
					t.Check("the plate stands clear of the X", close ~= nil and close:IsA("GuiObject") and not crosses(level, close))
					local last: string? = nil
					for name in BaseController.Says() do
						BaseView.Pick(name)
						task.wait()
						local now = BaseView.Parts()
						local side, own = now.Side, now.SidePress
						t.Check(`{name}: its panel opens`, side ~= nil and now.SideSpot == name)
						if side == nil or own == nil then
							continue
						end
						last = name
						local chip = now.Chips[name]
						t.Check(`{name}: the panel on the screen, and not over its own chip`, within(side, Layers.Get("Menus")) and (chip == nil or not chip.Visible or not crosses(side, chip)))
						local title, said = side:FindFirstChild("Title"), chip and chip:FindFirstChild("Title", true)
						t.Check(`{name}: it names the machine as its chip does`, title ~= nil and title:IsA("TextLabel") and said ~= nil and said:IsA("TextLabel") and title.Text == said.Text)
						local does, gain = side:FindFirstChild("Does"), side:FindFirstChild("Gain")
						t.Check(`{name}: it says what it does and what comes next`, does ~= nil and does:IsA("TextLabel") and does.Text ~= "" and gain ~= nil and gain:IsA("TextLabel") and gain.Text ~= "")
						local wanted = BaseLevels.Ask(view.Base :: any, name, credits)
						local buys = wanted ~= nil and wanted.Offer.Price ~= nil
						t.Check(`{name}: Upgrade only where there's a level to buy`, own.Visible == buys)
						if buys and wanted and wanted.Offer.Why ~= nil then
							t.Check(`{name}: shut ({wanted.Offer.Why}), it takes no tap`, Button.Press(own) == false)
						end
						Helpers.lintClean(t, `the base view with {name}'s panel`)
					end
					if last then
						BaseView.Pick(last)
						t.Check("a second tap on its chip closes the panel", BaseView.Parts().Side == nil)
					end
				end)
				BaseView.Close()
				t.Wait(seconds + 0.3)
				t.Check("Close takes the panel with it", BaseView.Parts().Side == nil and BaseView.Parts().Upgrade == nil)
				if not ok then
					error(err, 0)
				end
			end,
		},
	}
end

return BaseViewCases
