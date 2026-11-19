--!strict
-- ShopCases (client, Studio only): the Void Shop's screen and counter (AR38; UI.ShopScreen; ShopController; ShopService),
-- a list of their own beside Cases. The rule's math is Rules.Shop's logic cases; these check what the player sees and
-- presses: the counter's prompt, the band's clock and Credits, each line's words and price, a buy landing in the bag and
-- its count, bought out, out of reach, the second press a piece of a missing class asks for, the Drop rates, the
-- countdown chip. The case stands on the next featured stock (ShopService's "ShopStock") and puts the clock, the
-- Credits, the shards and the piece back as it found them.

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Markers = require(Shared.World.Markers)
local Items = require(Shared.Definitions.Items)
local Voidkin = require(Shared.Definitions.Voidkin)
local Hud = require(Shared.Rules.Hud)
local Odds = require(Shared.Rules.Odds)
local Shop = require(Shared.Rules.Shop)
local ShopConfig = require(Shared.Config.Shop)
local HudConfig = require(Shared.Config.Hud)
local Main = script.Parent.Parent.Parent.Main
local ShopController = require(Main.ShopController)
local ProfileController = require(script.Parent.Parent.ProfileController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Button = require(UI.Kit.Button)
local Screen = require(UI.Kit.Screen)
local Read = require(UI.Read)
local ShopScreen = require(UI.ShopScreen)
local Layers = require(UI.Layers)
local Theme = require(UI.Theme)
local Helpers = require(script.Parent.Helpers)

local ShopCases = {}

local function said(name: string, under: string?): string?
	local root = if under then ShopScreen.Find(under) else nil
	local found = if root then root:FindFirstChild(name, true) else ShopScreen.Find(name)
	return if found and found:IsA("TextLabel") then found.Text else nil
end

local function buyOf(panel: string): TextButton?
	local root = ShopScreen.Find(panel)
	local found = if root then root:FindFirstChild("Buy") else nil
	return if found and found:IsA("TextButton") then found else nil
end

-- A button's word: its label, or its reason while it's off (Kit.Button).
local function word(button: TextButton?): string?
	local found = if button then button:FindFirstChild("Label") else nil
	return if found and found:IsA("TextLabel") then found.Text else nil
end

local function credits(): number
	local view = ProfileController.Get()
	return if view then view.Currency.Credits else 0
end

function ShopCases.Cases(): { any }
	local waitFor, lintClean = Helpers.waitFor, Helpers.lintClean
	return {
		{
			Name = "Shop: the Void Shop's counter and screen (AR38): the band's clock and Credits, each line's words and price, a buy into the bag, bought out, out of reach, a missing class's second press, the Drop rates, the countdown chip",
			Run = function(t: any)
				Screen.Close()
				-- The counter's prompt, before the Shop (ShopController).
				local marker = Markers.Find("Shop")
				local counter = if marker then marker:FindFirstChild("ShopCounter") else nil
				local prompt = if counter then counter:FindFirstChildOfClass("ProximityPrompt") else nil
				t.Check("the counter's prompt stands before the Shop", prompt ~= nil and prompt.ActionText == "Open" and prompt.ObjectText == "Void Shop", if prompt then prompt.ObjectText else "none")

				local start = credits()
				local stood = t.Server("ShopStock")
				t.Check("the test stands on a featured stock", type(stood) == "table" and stood.Ok == true and stood.Featured == true, if type(stood) == "table" then tostring(stood.Error) else "no answer")
				t.Check("the counts forgotten", (t.Server("ShopForget") :: any).Ok == true)
				local opened = ShopController.Open()
				t.Check("the screen opens on the standing shelf", opened and waitFor(t, 2, function(): boolean
					return Screen.Current() == ShopScreen.Name
				end))
				local shelf = ShopScreen.Shelf()
				if shelf == nil or type(stood) ~= "table" then
					t.Check("a shelf to test", false)
					t.Server("ShopStock", 0)
					return
				end
				t.Check("its shelf is the stock stood on, featured", shelf.Stock == stood.Stock and shelf.Featured == true and shelf.Lines.Featured ~= nil)

				-- The band: its name, the clock, the Credits.
				local left = shelf.Ends - workspace:GetServerTimeNow()
				t.Check("the band: Void Shop", said("ShopName") == "Void Shop")
				local time = said("Time", "Clock")
				t.Check("the clock: the stock's time left as m:ss", time ~= nil and (time == Hud.Clock(left) or time == Hud.Clock(left + 1)), `{time} for {left}`)
				local count = math.ceil(ShopConfig.Period / 60)
				local clock = ShopScreen.Find("Clock") :: Frame
				local lights, right = 0, true
				for index = 1, count do
					local track = clock:FindFirstChild(`Light{index}`)
					local fill = if track then track:FindFirstChild("Fill") :: Frame? else nil
					local share = math.clamp((left - (count - index) * 60) / 60, 0, 1)
					lights += if fill then 1 else 0
					right = right and fill ~= nil and math.abs(fill.Size.Y.Scale - share) < 0.05
				end
				t.Check(`the clock: {count} lights, a minute each, the running one falling`, lights == count and right)
				local wallet = ShopScreen.Find("Credits")
				local value = if wallet then wallet:FindFirstChild("Value") else nil
				t.Check("the band: the player's Credits", value ~= nil and (value :: TextLabel).Text == Read.Number(credits()))

				-- Each line's words.
				t.Check("Featured: how often one comes, always on it", said("Note", "Featured") == `about 1 stock in {math.round(1 / ShopConfig.Featured.Chance)}`)
				t.Check("Shards: the limit each player, each stock", said("Note", "Shards") == `{ShopConfig.Shard.Limit} each player, each stock`)
				local piece = (shelf.Lines.Featured :: Shop.Line).Item :: any
				local row = Items.ById[piece.Def]
				t.Check("Featured: its slot and whom it fits", said("What", "Featured") == `{row.Slot}, {if row.Class then `{row.Class} only` else "any class"}`, said("What", "Featured"))
				t.Check("Featured: its rarity", said("Rarity", "Featured") == piece.Rarity)
				t.Check("Featured: its stats", (said("Stats", "Featured") or "") ~= "", said("Stats", "Featured"))
				t.Check("Shards: the Standard shard", said("Name", "Shards") == "Standard shard")
				-- Research's 15:56: the offer is the hero, the shard the same at its own size, with no rarity under it, both on
				-- the bag's room.
				local function heroOf(panel: string): (Frame?, number)
					local root = ShopScreen.Find(panel)
					local found = if root then root:FindFirstChild("Hero") else nil
					local name = if root then root:FindFirstChild("Name") else nil
					if found and found:IsA("Frame") and name and name:IsA("GuiObject") and found:FindFirstChild("Picture", true) and found:FindFirstChild("Light", true) then
						local under = name.AbsolutePosition.Y >= found.AbsolutePosition.Y + found.AbsoluteSize.Y - 1
						return found, if under then found.Size.X.Offset else -found.Size.X.Offset
					end
					return nil, 0
				end
				local featHero, featSide = heroOf("Featured")
				local shardHero, shardSide = heroOf("Shards")
				local least = HudConfig.Shop.Hero.Least
				t.Check("Featured: its picture is the hero, large on its light, its words under it", featHero ~= nil and featSide >= least, featSide)
				t.Check("Shards: the shard's the same at its own size", shardHero ~= nil and shardSide >= least and shardSide <= featSide, shardSide)
				t.Check("Shards: no rarity under the shard (its odds say it)", said("Rarity", "Shards") == nil, said("Rarity", "Shards"))
				t.Check("the screen stands on the bag's room", ShopScreen.Find("Room") ~= nil)
				t.Check("the foot: how a stock works", said("Foot") == `A new stock every {ShopConfig.Period // 60} minutes, in every server. Your counts are your own.`, said("Foot"))
				local shardLine = shelf.Lines.Shard :: Shop.Line
				local featLine = shelf.Lines.Featured :: Shop.Line
				local shardBuy, featBuy = buyOf("Shards"), buyOf("Featured")
				t.Check("each Buy says its price", shardBuy ~= nil and featBuy ~= nil and word(shardBuy) == Read.Number(shardLine.Price) and word(featBuy) == Read.Number(featLine.Price))
				lintClean(t, "the Shop")

				-- Out of reach: short of the piece by 150.
				t.Server("DataCredits", featLine.Price - 150 - credits())
				waitFor(t, Helpers.ANSWER, function(): boolean
					return said("Count", "Featured") == "Need 150 more"
				end)
				featBuy = buyOf("Featured")
				t.Check("out of reach: the count's place says how far, Buy dimmed on its price", said("Count", "Featured") == "Need 150 more" and featBuy ~= nil and Button.State(featBuy) == "Disabled" and word(featBuy) == Read.Number(featLine.Price), said("Count", "Featured"))

				-- A shard bought, twice: into the bag, then bought out.
				t.Server("DataCredits", featLine.Price + shardLine.Price * 2 - credits())
				waitFor(t, Helpers.ANSWER, function(): boolean
					return said("Count", "Featured") == "1 left"
				end)
				local def = shardLine.Shard :: string
				local view = ProfileController.Get() :: any
				local before, coins = view.Bag.Shards[def] or 0, credits()
				for bought = 1, ShopConfig.Shard.Limit do
					shardBuy = buyOf("Shards")
					t.Check(`shard {bought}: pressed`, shardBuy ~= nil and Button.Press(shardBuy))
					waitFor(t, Helpers.ANSWER, function(): boolean
						local now = ProfileController.Get() :: any
						return (now.Bag.Shards[def] or 0) == before + bought
					end)
					local now = ProfileController.Get() :: any
					t.Check(`shard {bought}: in the bag, its price spent`, (now.Bag.Shards[def] or 0) == before + bought and credits() == coins - shardLine.Price * bought, `{now.Bag.Shards[def]} held, {credits()}`)
					waitFor(t, 1, function(): boolean
						return said("Count", "Shards") == (if bought < ShopConfig.Shard.Limit then `{ShopConfig.Shard.Limit - bought} left` else "None left")
					end)
				end
				shardBuy = buyOf("Shards")
				t.Check("bought out: None left, Buy reads Bought, dimmed", said("Count", "Shards") == "None left" and word(shardBuy) == "Bought" and shardBuy ~= nil and Button.State(shardBuy) == "Disabled", said("Count", "Shards"))

				-- The piece: a class the player has none of asks once more.
				local missing = false
				if row.Class then
					missing = true
					for _, owned in (ProfileController.Get() :: any).Voidkin do
						local each = Voidkin.ById[owned.Def]
						missing = missing and not (each and each.Class == row.Class)
					end
				end
				t.Check("a missing class says so in red, only then", (said("Missing", "Featured") ~= nil) == missing, said("Missing", "Featured"))
				local held = 0
				for _ in (ProfileController.Get() :: any).Items do
					held += 1
				end
				featBuy = buyOf("Featured")
				if missing and featBuy then
					Button.Press(featBuy)
					t.Wait(0.3)
					t.Check("the first press asks: Buy anyway?", word(featBuy) == "Buy anyway?" and credits() == coins - shardLine.Price * 2, word(featBuy))
				end
				t.Check("the piece: pressed", featBuy ~= nil and Button.Press(featBuy))
				local id: string? = nil
				waitFor(t, Helpers.ANSWER, function(): boolean
					for key, item in (ProfileController.Get() :: any).Items do
						if item.Def == piece.Def and item.Rarity == piece.Rarity and Shop.Bought(ProfileController.Get() :: any, shelf.Stock, "Featured") == 1 then
							id = key
						end
					end
					return id ~= nil
				end)
				local after = 0
				for _ in (ProfileController.Get() :: any).Items do
					after += 1
				end
				t.Check("the piece: in the bag, its price spent", id ~= nil and after == held + 1 and credits() == coins - shardLine.Price * 2 - featLine.Price, `{after - held} new, {credits()}`)
				waitFor(t, 1, function(): boolean
					return said("Count", "Featured") == "None left"
				end)
				t.Check("the piece bought out", said("Count", "Featured") == "None left")

				-- The Drop rates, in the shard's place.
				ShopScreen.Rates(true)
				local list = ShopScreen.Find("Chances")
				local rows = 0
				for _, group in Odds.Rates(def, 0) do
					rows += 1 + #group.Rates
				end
				local shown = 0
				for _, child in (if list then list:GetChildren() else {}) do
					shown += if child:IsA("Frame") then 1 else 0
				end
				t.Check("Drop rates: every rarity and Voidkin, in the shard's place", list ~= nil and shown == rows and said("Name", "Shards") == nil, `{shown} of {rows}`)
				lintClean(t, "the Shop's Drop rates")
				ShopScreen.Rates(false)

				-- The chip under the pills, by the world's clock.
				local now = workspace:GetServerTimeNow()
				local last = Shop.Ends(Shop.Stock(now)) - now <= ShopConfig.Warn
				Screen.Close()
				t.Wait(0.3)
				local chip = ShopController.Chip()
				local edge = math.abs(Shop.Ends(Shop.Stock(now)) - now - ShopConfig.Warn) < 1
				t.Check("the countdown chip shows only in a stock's last minute", chip ~= nil and (edge or chip.Visible == last), `{chip and chip.Visible} at {Shop.Ends(Shop.Stock(now)) - now}`)

				-- As found: the piece, the shards, the Credits, the clock.
				if id then
					local answer = ProfileController.Act("SalvageItem", { Item = id })
					t.Check("the piece salvaged again", answer.Ok == true, tostring(answer.Error))
				end
				t.Server("BaseGive", def, -ShopConfig.Shard.Limit)
				t.Server("DataCredits", start - credits())
				t.Server("ShopStock", 0)
				t.Server("ShopForget")
				t.Check("Credits and shards as found", waitFor(t, Helpers.ANSWER, function(): boolean
					return credits() == start and ((ProfileController.Get() :: any).Bag.Shards[def] or 0) == before
				end), `{credits()} for {start}`)
			end,
		},
		{
			Name = "Take: AR38, the Void Shop held for stills: a featured stock, out of reach, bought out, the Drop rates, none featured, then the smallest phone, for research",
			Manual = true,
			Stay = true,
			Run = function(t: any)
				-- AR38's captures: each state is held until the driver moves ReplicatedStorage.NL_TakeStep on ("Featured",
				-- "Poor", "Bought", "Rates", "None", "Phone", "PhoneRates", "PhoneNone", "End") and captures it. The
				-- clock, the Credits, the shards and the counts are put back at the end.
				local step = Instance.new("StringValue")
				step.Name = "NL_TakeStep"
				step.Value = "Ready"
				step.Parent = ReplicatedStorage
				local start = credits()
				local view = ProfileController.Get() :: any
				local def = "lanternrow_standard"
				local held = view.Bag.Shards[def] or 0
				local function featuredStock()
					t.Server("ShopStock")
					t.Server("ShopForget")
					ShopController.Open()
					t.Wait(0.6)
				end
				local function plainStock()
					for ahead = 1, 40 do
						local stood = t.Server("ShopStock", ahead) :: any
						if stood.Ok and not stood.Featured then
							break
						end
					end
					ShopController.Open()
					t.Wait(0.6)
				end
				local function line(name: string): Shop.Line?
					local shelf = ShopScreen.Shelf()
					return if shelf then shelf.Lines[name] else nil
				end
				local function phone()
					Screen.Close()
					t.Wait(0.4)
					Layers.Force(Theme.Scale.Floor)
					Layers.Box(Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height))
					t.Wait(0.2)
				end
				local states = {
					Featured = function()
						t.Server("DataCredits", 46800 - credits())
						featuredStock()
					end,
					Poor = function()
						local shard = line("Shard")
						if shard then
							t.Server("DataCredits", shard.Price - 150 - credits())
						end
						t.Wait(0.6)
					end,
					Bought = function()
						t.Server("DataCredits", 46800 - credits())
						t.Wait(0.4)
						for _ = 1, ShopConfig.Shard.Limit do
							local buy = buyOf("Shards")
							if buy then
								Button.Press(buy)
							end
							t.Wait(1)
						end
					end,
					Rates = function()
						ShopScreen.Rates(true)
						t.Wait(0.3)
					end,
					None = function()
						ShopScreen.Rates(false)
						plainStock()
					end,
					Phone = function()
						phone()
						t.Server("ShopForget")
						featuredStock()
					end,
					PhoneRates = function()
						ShopScreen.Rates(true)
						t.Wait(0.3)
					end,
					PhoneNone = function()
						ShopScreen.Rates(false)
						plainStock()
					end,
				}
				local shown = step.Value
				local began = os.clock()
				while step.Value ~= "End" and os.clock() - began < 300 do
					if step.Value ~= shown then
						shown = step.Value
						local apply = states[shown]
						if apply then
							apply()
						end
						step:SetAttribute("Shown", shown)
					end
					t.Wait(0.1)
				end
				Screen.Close()
				Layers.Box(nil)
				Layers.Force(nil)
				local now = ProfileController.Get() :: any
				local extra = (now.Bag.Shards[def] or 0) - held
				if extra > 0 then
					t.Server("BaseGive", def, -extra)
				end
				t.Server("ShopStock", 0)
				t.Server("ShopForget")
				t.Server("DataCredits", start - credits())
				step:Destroy()
				t.Check("the driver ended it", shown == "End" or step.Value == "End", shown)
			end,
		},
	}
end

return ShopCases
