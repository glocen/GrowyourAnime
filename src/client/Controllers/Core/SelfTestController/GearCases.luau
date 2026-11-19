--!strict
-- GearCases: gear's own levels in a playtest (TR47; Rules.Reinforce, Rules.Emblems, Services.Main.RegaliaService). The
-- rules' cases run with Studio closed (LogicTestService/Cases/Reinforce.luau); these prove the acts' wire: a try spends
-- once through its op id and its roll is the server's, an emblem goes in and out through the bag, and the transfer moves
-- a level on the player's Yes. Everything given is taken back at the end.

local HttpService = game:GetService("HttpService")

local GearCases = {}

local function view(t: any): any
	return t.Server("Data")
end

function GearCases.Cases(): { any }
	return {
		{
			Name = "Gear: TR47, the acts' wire: a Reinforce try spends once for a repeated op id; an emblem in and out through the bag; the equip transfer on Yes",
			Run = function(t: any)
				local given = t.Server("ItemGive", "helmet", "Rare", { { Stat = "Health", Value = 300 } })
				local second = t.Server("ItemGive", "helmet", "Rare", { { Stat = "Health", Value = 200 } })
				t.Check("two helmets given", given and given.Ok == true and second and second.Ok == true)
				if not (given and given.Ok and second and second.Ok) then
					return
				end
				local id, other = given.Id, second.Id
				local before = view(t)
				local wornBefore = before.Presets[1].Slots.Helmet
				t.Server("DataCredits", 100000)
				t.Server("StonesGive", "Low", 20)
				local op = HttpService:GenerateGUID(false)
				local first = t.Server("Act", "Reinforce", { Item = id }, op)
				t.Check("a try: +1 at 100%", first and first.Ok == true and first.Success == true and first.Level == 1 and first.Chance == 1)
				local spent = view(t)
				local again = t.Server("Act", "Reinforce", { Item = id }, op)
				local after = view(t)
				t.Check("its repeat: the first answer, nothing spent twice", again and again.Level == 1 and after.Currency.Credits == spent.Currency.Credits and after.Bag.Stones.Low == spent.Bag.Stones.Low and after.Items[id].Reinforce == 1)
				t.Equal("one try's price taken", before.Currency.Credits + 100000 - after.Currency.Credits, first.Credits)
				t.Server("EmblemGive", "warhorn:Hit", 1)
				local put = t.Server("Act", "Socket", { Item = id, Socket = 1, Emblem = "warhorn:Hit" })
				local socketed = view(t)
				t.Check("in: the socket holds it, the bag none", put and put.Ok == true and socketed.Items[id].Sockets[1] == "warhorn:Hit" and socketed.Bag.Emblems["warhorn:Hit"] == nil)
				t.Server("Act", "Equip", { Preset = 1, Slot = "Helmet", Item = id })
				local moved = t.Server("Act", "Equip", { Preset = 1, Slot = "Helmet", Item = other, Move = true })
				local swapped = view(t)
				t.Check("Yes: the level and the emblem move to the new helmet", moved and moved.Moved == true and swapped.Items[other].Reinforce == 1 and swapped.Items[other].Sockets[1] == "warhorn:Hit" and swapped.Items[id].Reinforce == 0)
				local out = t.Server("Act", "Unsocket", { Item = other, Socket = 1 })
				t.Check("out: back to the bag", out and out.Ok == true and view(t).Bag.Emblems["warhorn:Hit"] == 1)
				-- Back as it was: the helmet worn before, the items, Credits, stones and emblem taken back.
				t.Server("Act", "Equip", { Preset = 1, Slot = "Helmet", Item = wornBefore or "" })
				t.Server("EmblemGive", "warhorn:Hit", -1)
				t.Server("ItemTake", id)
				t.Server("ItemTake", other)
				local now = view(t)
				t.Server("DataCredits", before.Currency.Credits - now.Currency.Credits)
				t.Server("StonesGive", "Low", (before.Bag.Stones.Low or 0) - (now.Bag.Stones.Low or 0))
				local restored = view(t)
				t.Check("put back: Credits, stones, the helmet worn", restored.Currency.Credits == before.Currency.Credits and (restored.Bag.Stones.Low or 0) == (before.Bag.Stones.Low or 0) and restored.Presets[1].Slots.Helmet == wornBefore and restored.Items[id] == nil)
			end,
		},
	}
end

return GearCases
