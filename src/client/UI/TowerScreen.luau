--!strict
-- TowerScreen (client): a Tower run's results, in grey (TR29; docs/design.md, "The Tower", "Death ends the run"). The
-- highest floor this run and the record if it's beaten, the opponents defeated, the Credits and the chests won, from
-- the save's Progress.Tower.Results (the server's, written once by the run's end). Closing it, by its button or its
-- exit, tells the server they've been seen (Act "TowerSeen"), so they open once. The rarity light on a rare reward and
-- the screen's look wait for the shared finish.
--   TowerScreen.Open(results, on)   builds it (on: Act)
--   TowerScreen.Parts()             its pieces by name, for tests

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Profile = require(Shared.Data.Profile)
local ChestRows = require(Shared.Definitions.Chests)
local Hud = require(Shared.Rules.Hud)

local UI = script.Parent
local Theme = require(UI.Theme)
local Text = require(UI.Kit.Text)
local Button = require(UI.Kit.Button)
local Screen = require(UI.Kit.Screen)

local TowerScreen = {}
TowerScreen.Name = "Tower"

export type On = { Act: (name: string, args: any?) -> { [string]: any } }

local SIZE = Vector2.new(340, 316)
local ROW = 26

local parts: { [string]: Instance } = {}
local shown: string? = nil
local closing: { [string]: boolean } = {} -- results already told seen, so a closed screen asks once

function TowerScreen.Open(results: Profile.TowerResults, on: On)
	table.clear(parts)
	shown = results.Id
	local body = Screen.Open(TowerScreen.Name, "Tower", SIZE)
	for _, child in body:GetChildren() do
		child:Destroy()
	end
	local pad = Theme.Size.Pad
	local wide = SIZE.X - pad * 2
	local y = pad
	local function line(name: string, text: string, size: number, colour: Color3?, font: Font?, tall: number?)
		local label = Text.new({
			Name = name,
			Size = size,
			Font = font or Theme.Font.Body,
			Colour = colour or Theme.Colour.Text,
			Align = Enum.TextXAlignment.Center,
			Box = UDim2.fromOffset(wide, tall or ROW),
			Position = UDim2.fromOffset(pad, y),
			Parent = body,
		})
		label.Text = text
		parts[name] = label
		y += (tall or ROW) + 2
		return label
	end
	line("Floor", `Floor {results.Floor}`, Theme.Text.Big, Theme.Colour.Text, Theme.Font.Number, 36)
	if results.Record then
		line("Record", if results.Best > 0 then `A new record, past floor {results.Best}` else "A new record", Theme.Text.Body, Theme.Colour.Ready, Theme.Font.Strong)
	else
		line("Record", `Your record: floor {results.Best}`, Theme.Text.Body, Theme.Colour.TextDim)
	end
	y += 4
	line("Defeated", `{results.Floor} {if results.Floor == 1 then "opponent" else "opponents"} defeated`, Theme.Text.Body)
	line("Credits", `+{Hud.Digits(results.Credits)} Credits`, Theme.Text.Body, Theme.Colour.Credits, Theme.Font.Number)
	local names = {}
	for id in results.Chests do
		table.insert(names, id)
	end
	table.sort(names)
	if #names == 0 then
		line("Chests", "No chests this run", Theme.Text.Caption, Theme.Colour.TextDim)
	else
		for index, id in names do
			local row = ChestRows.ById[id]
			line(`Chest{index}`, `{if row then row.Name else id} ×{Hud.Digits(results.Chests[id])}`, Theme.Text.Body)
		end
	end
	local close = Button.new({
		Name = "Close",
		Text = "Close",
		Size = UDim2.fromOffset(wide, Theme.Size.Tap),
		Position = UDim2.fromOffset(pad, math.max(y + 6, SIZE.Y - Theme.Size.Tap - pad - 44)),
		Parent = body,
		Primary = true,
		OnPress = function(): boolean
			Screen.Close()
			return true
		end,
	})
	parts.Close = close
	parts.Body = body
	local id = results.Id
	Screen.Closed:Once(function(name: string)
		if name == TowerScreen.Name and not closing[id] then
			closing[id] = true
			task.spawn(on.Act, "TowerSeen", { Id = id })
		end
	end)
end

-- The id of the results last opened: whether those on screen are the ones the save holds.
function TowerScreen.Shown(): string?
	return shown
end

-- Whether results `id` were told seen from this client.
function TowerScreen.Told(id: string): boolean
	return closing[id] == true
end

function TowerScreen.Parts(): { [string]: Instance }
	return parts
end

return TowerScreen
