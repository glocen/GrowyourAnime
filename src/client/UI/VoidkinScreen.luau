--!strict
-- VoidkinScreen (client): the Voidkin screen, in grey (docs/ui.md, "The screens of the first loop", 4 and 5). The
-- collection, the lead first: any Voidkin can be made the lead, out of combat, a fallen one once it's whole (TR12), and
-- a row says when one is healing at home, training on the machine, or has points to spend. One Voidkin's stat board
-- (TR15; docs/design.md, "Skill points"; Rules.Board, never copied): its four stats as they stand, the points it has to
-- spend, each stat's gain on its button before a tap, and the reset with its price in Credits, a second tap to be sure.
-- Two layouts for the blockout's verdict (Config.Hud.Board.Layout, live): Split, the collection beside the chosen
-- Voidkin's board, the lead set from the board; Sheet, the collection as it was, and a tap on a name opens that board
-- over it, with Back. Every change is asked of the server through the owner's Act, and the screen is rebuilt from the
-- server's copy.
--   VoidkinScreen.Open(view, on)   builds it; again on each change of the save
--   VoidkinScreen.Tick()           a tuned layout, or a reset left unconfirmed, rebuilds
--   VoidkinScreen.Chosen()         the Voidkin whose board shows (nil: none), for tests
--   VoidkinScreen.Choose(id)       a tap on a Voidkin's name, for tests
--   VoidkinScreen.Built()          the layout last built, for tests

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Profile = require(Shared.Data.Profile)
local HudConfig = require(Shared.Config.Hud)
local StatsConfig = require(Shared.Config.Stats)
local Board = require(Shared.Rules.Board)
local Stats = require(Shared.Rules.Stats)
local Hud = require(Shared.Rules.Hud)
local UI = script.Parent
local Theme = require(UI.Theme)
local Read = require(UI.Read)
local Panel = require(UI.Kit.Panel)
local Text = require(UI.Kit.Text)
local Row = require(UI.Kit.Row)
local Button = require(UI.Kit.Button)
local Screen = require(UI.Kit.Screen)
local Toast = require(UI.Kit.Toast)

local VoidkinScreen = {}

export type On = { Act: (name: string, args: any) -> { [string]: any }, Healing: () -> { [string]: number } }

local NAME = "Voidkin"
local SIZES: { [string]: Vector2 } = { Split = Vector2.new(660, 320), Sheet = Vector2.new(440, 300) }
local LIST = 0.45 -- the collection's share of the width beside a board
local LINE = 18
local SURE = 3 -- seconds a reset waits for its second tap
local BUTTON = 96

local player = Players.LocalPlayer
local chosen: string? = nil
local sheetOpen = false
local sureOf: string? = nil -- the Voidkin whose reset waits for a second tap
local sureUntil = 0
local built: string? = nil
local lastView: Profile.View? = nil
local lastOn: On? = nil
local rebuild: () -> () = function() end

-- What a refused change says: the lead's (TR12, Rules.Carry) and the board's (Rules.Board).
local REFUSED: { [string]: string } = {
	InCombat = "Not during a fight",
	Healing = "Still healing at home",
	[Board.NoPoints] = "No points to spend",
	[Board.Short] = "Not enough Credits",
	[Board.Nothing] = "Nothing to reset",
	[Board.Stat] = "Not on the board",
	[Board.Unknown] = "Not one of yours",
}

local function refused(what: string, answer: { [string]: any })
	if answer.Ok ~= true then
		local said = REFUSED[tostring(answer.Error)]
		if said == nil then
			warn(`[VoidkinScreen] {what}: an unnamed refusal, {tostring(answer.Error)}`) -- the output names it; a player never reads a code
		end
		Toast.Show(`{what}: {said or "Not now"}`, Theme.Colour.TextDim)
	end
end

-- A stat's number: whole from 10 up, a tenth under, a hundredth under 1, so a point's gain never reads "+0".
local function amount(n: number): string
	if n >= 10 then
		return Read.Number(n)
	elseif n >= 1 then
		return string.format("%.1f", math.floor(n * 10 + 0.5) / 10)
	end
	return string.format("%.2f", math.floor(n * 100 + 0.5) / 100)
end
VoidkinScreen.Amount = amount

local function points(n: number): string
	return if n == 1 then "1 point" else `{n} points`
end

-- What the board says of the points to spend.
local function toSpend(left: number): string
	return if left > 0 then `{points(left)} to spend` else "No points to spend: each level gives one"
end
VoidkinScreen.ToSpend = toSpend

local function label(parent: Instance, name: string, text: string, size: number, box: UDim2, position: UDim2, props: { [string]: any }?): TextLabel
	local p: { [string]: any } = props or {}
	local made = Text.new({
		Name = name,
		Size = size,
		Font = p.Font,
		Colour = p.Colour,
		Align = p.Align,
		Box = box,
		Position = position,
		Truncate = p.Truncate,
		Parent = parent,
	})
	made.Text = text
	return made
end

-- A tap target over the left of a row, where its name is; its button keeps its own taps.
local function tapOver(row: Frame, room: number, onTap: () -> ())
	local tap = Instance.new("TextButton")
	tap.Name = "Choose"
	tap.Text = ""
	tap.BackgroundTransparency = 1
	tap.Size = UDim2.new(1, -room, 1, 0)
	tap.ZIndex = 5
	tap.Activated:Connect(function()
		onTap()
	end)
	tap.Parent = row
end

local function choose(id: string?)
	chosen = id
	sheetOpen = id ~= nil
	rebuild()
end

-- Who the lead change refuses, and why: its role, a fall still healing, a fight (Rules.Hud.LeadReason).
local function leadReason(view: Profile.View, owned: Profile.OwnedVoidkin, on: On, now: number): string?
	return Hud.LeadReason(Read.Role(view, owned.Id), on.Healing()[owned.Id], now, player:GetAttribute("InCombat") == true)
end

local function makeLead(on: On, owned: Profile.OwnedVoidkin)
	refused("Can't lead", on.Act("SetLead", { Voidkin = owned.Id }))
end

-- The collection, the lead first. `lead`: each row has its Lead button, as before the board; without it, a tap anywhere
-- on a row chooses it and the board sets the lead.
local function listOf(parent: Instance, view: Profile.View, on: On, box: UDim2, lead: boolean)
	local list = Row.List(parent, "List", box)
	local roster = Read.Roster(view)
	if #roster == 0 then
		Row.new({ Parent = list, Order = 1, Text = "No Voidkin yet", Detail = "Break a shard at the Breaker", Colour = Theme.Colour.TextDim })
		return
	end
	local wholeAt, now = on.Healing(), workspace:GetServerTimeNow()
	local onMachine = player:GetAttribute("Training")
	for index, owned in roster do
		local whole = wholeAt[owned.Id]
		local status = if whole and whole > now then `Healing at home {Hud.Clock(whole - now)}`
			elseif onMachine == owned.Id then "Training"
			else Read.Role(view, owned.Id)
		local left = Board.Left(owned)
		local row = Row.new({
			Name = owned.Id,
			Parent = list,
			Order = index,
			Text = Read.VoidkinName(owned),
			Detail = `Lv {owned.Level}{if status ~= "" then " · " .. status else ""}{if left > 0 then ` · {left} to spend` else ""}`,
			Colour = if not lead and owned.Id == chosen then Theme.Colour.Primary else nil,
			Action = if lead then "Lead" else nil,
			Disabled = if lead then leadReason(view, owned, on, now) else nil,
			OnPress = function()
				makeLead(on, owned)
			end,
		})
		tapOver(row, if lead then BUTTON + Theme.Size.Pad else 0, function()
			choose(owned.Id)
		end)
	end
end

-- One Voidkin's board: its name and the points to spend over one column that scrolls: the four stats as they stand,
-- each with its gain on its button, then the reset.
local function board(parent: Instance, view: Profile.View, owned: Profile.OwnedVoidkin?, on: On, box: UDim2, position: UDim2, back: boolean)
	local frame = Panel.new({ Name = "Board", Size = box, Position = position, Parent = parent })
	frame.ZIndex = 10
	frame.Active = true -- a tap on the board stays on it, never reaching the list under the sheet
	local pad, gap = Theme.Size.Pad, Theme.Size.Gap
	if owned == nil then
		label(frame, "Empty", "No Voidkin yet. Break a shard at the Breaker.", Theme.Text.Caption, UDim2.new(1, -pad * 2, 0, LINE * 2), UDim2.fromOffset(pad, pad), { Colour = Theme.Colour.TextDim })
		return
	end
	local it = owned :: Profile.OwnedVoidkin
	local now = workspace:GetServerTimeNow()
	local left = Board.Left(it)
	local buttons = if back then 2 else 1
	local right = buttons * (BUTTON + pad)
	label(frame, "Title", `{Read.VoidkinName(it)} · Lv {it.Level}`, Theme.Text.Body, UDim2.new(1, -pad * 2 - right, 0, 22), UDim2.fromOffset(pad, pad), { Font = Theme.Font.Strong, Truncate = true })
	label(frame, "Points", toSpend(left), Theme.Text.Caption, UDim2.new(1, -pad * 2 - right, 0, LINE), UDim2.fromOffset(pad, pad + 22), { Colour = if left > 0 then Theme.Colour.Ready else Theme.Colour.TextDim, Truncate = true })
	local leadButton = Button.new({ Name = "Lead", Text = "Lead", Size = UDim2.fromOffset(BUTTON, Theme.Size.Tap), Position = UDim2.new(1, -pad - (buttons - 1) * (BUTTON + gap), 0, pad), AnchorPoint = Vector2.new(1, 0), Parent = frame, OnPress = function()
		makeLead(on, it)
	end })
	local why = leadReason(view, it, on, now)
	if why then
		Button.Set(leadButton, { Disabled = why })
	end
	if back then
		Button.new({ Name = "Back", Text = "Back", Size = UDim2.fromOffset(BUTTON, Theme.Size.Tap), Position = UDim2.new(1, -pad, 0, pad), AnchorPoint = Vector2.new(1, 0), Parent = frame, OnPress = function()
			sheetOpen = false
			rebuild()
		end })
	end
	local top = pad + math.max(22 + LINE, Theme.Size.Tap) + gap
	local column = Row.List(frame, "Stats", UDim2.new(1, -pad, 1, -(top + pad)), UDim2.fromOffset(pad, top))
	local block = Stats.Resolve(it, Stats.PresetOf(view, it), view)
	for order, stat in StatsConfig.Board.Stats do
		local count = Board.On(it, stat)
		local gain = "+" .. amount(Stats.PointGain(it, stat))
		local value = amount((block :: any)[stat] :: number) .. (if stat == "Regen" then " a second" else "")
		Row.new({
			Name = stat,
			Parent = column,
			Order = order,
			Text = stat,
			Detail = if count > 0 then `{value} · {points(count)}` else value,
			Action = gain,
			ActionWidth = 80,
			Primary = left > 0,
			Disabled = if left > 0 then nil else gain, -- greyed with its gain kept on it: the line above says why
			OnPress = function()
				refused("Can't add", on.Act("SpendPoint", { Voidkin = it.Id, Stat = stat }))
			end,
		})
	end
	local price = Board.ResetCost(it)
	local spent = Board.Spent(it)
	local short = view.Currency.Credits < price
	local sure = sureOf == it.Id and os.clock() < sureUntil
	local action = if sure then "Sure?" else "Reset"
	Row.new({
		Name = "Reset",
		Parent = column,
		Order = #StatsConfig.Board.Stats + 1,
		Text = "Reset the board",
		Detail = if spent == 0 then "Nothing spent yet"
			elseif short then `Needs {Read.Number(price)} Credits`
			else `Every point back for {Read.Number(price)} Credits`,
		Action = action,
		ActionWidth = 80,
		Disabled = if spent == 0 or short then action else nil, -- the line beside it says why
		OnPress = function()
			if not sure then
				sureOf, sureUntil = it.Id, os.clock() + SURE
				rebuild()
				return
			end
			sureOf = nil
			refused("Can't reset", on.Act("ResetPoints", { Voidkin = it.Id }))
			rebuild() -- the save's copy may have come first
		end,
	})
end

-- The Voidkin whose board shows: the one chosen if it's still owned, else the lead, else the first.
local function settle(view: Profile.View): Profile.OwnedVoidkin?
	if chosen and view.Voidkin[chosen] then
		return view.Voidkin[chosen]
	end
	local roster = Read.Roster(view)
	chosen = if roster[1] then roster[1].Id else nil
	return roster[1]
end

local function build(view: Profile.View, on: On)
	lastView, lastOn = view, on
	local layout = if SIZES[HudConfig.Board.Layout] then HudConfig.Board.Layout else "Split"
	built = HudConfig.Board.Layout
	local owned = settle(view)
	local gap = Theme.Size.Gap
	if layout == "Sheet" then
		local body = Screen.Open(NAME, "Voidkin", SIZES.Sheet)
		if sheetOpen and owned ~= nil then
			board(body, view, owned, on, UDim2.fromScale(1, 1), UDim2.new(), true) -- over the whole screen, Back to the list
		else
			listOf(body, view, on, UDim2.fromScale(1, 1), true)
		end
	else
		local body = Screen.Open(NAME, "Voidkin", SIZES.Split)
		listOf(body, view, on, UDim2.new(LIST, -gap / 2, 1, 0), false)
		board(body, view, owned, on, UDim2.new(1 - LIST, -gap / 2, 1, 0), UDim2.new(LIST, gap / 2, 0, 0), false)
	end
end

rebuild = function()
	if lastView and lastOn and Screen.Current() == NAME then
		build(lastView, lastOn)
	end
end

function VoidkinScreen.Open(view: Profile.View, on: On)
	if Screen.Current() ~= NAME then -- a fresh open starts on the collection, the lead's board beside it
		chosen, sheetOpen, sureOf = nil, false, nil
	end
	build(view, on)
end

function VoidkinScreen.Tick()
	if Screen.Current() ~= NAME then
		return
	end
	if built ~= HudConfig.Board.Layout then
		rebuild()
	elseif sureOf and os.clock() >= sureUntil then
		sureOf = nil
		rebuild()
	end
end

function VoidkinScreen.Chosen(): string?
	local layout = if SIZES[HudConfig.Board.Layout] then HudConfig.Board.Layout else "Split"
	if Screen.Current() ~= NAME or (layout == "Sheet" and not sheetOpen) then
		return nil
	end
	return chosen
end

function VoidkinScreen.Choose(id: string?)
	choose(id)
end

-- The layout last built, for tests: a tuned layout is built on the next tick.
function VoidkinScreen.Built(): string?
	return built
end

VoidkinScreen.Name = NAME
VoidkinScreen.Refused = REFUSED

return VoidkinScreen
