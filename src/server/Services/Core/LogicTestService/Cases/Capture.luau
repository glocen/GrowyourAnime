--!strict
-- Logic cases (pure): the capture after a reveal (Rules.Capture; TR60). The tile on every Voidkin's card and on an item's
-- from Epic up; a share's launch data is the sharer's UserId alone, read back on a friend's join, and nothing else is.
-- Runs in Studio (LogicTests) and with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Capture = require(Shared.Rules.Capture)
local Rarity = require(Shared.Definitions.Rarity)

return {
	{
		Name = "Capture (TR60): the tile on every Voidkin's card and an item's from Epic up, never elsewhere",
		Run = function(t: any)
			for _, rarity in Rarity.Order do
				t.Check(`a {rarity} Voidkin's card offers it`, Capture.Offered("Voidkin", rarity))
				t.Equal(`a {rarity} item's card: from Epic up`, Capture.Offered("Item", rarity), Rarity.Rank[rarity] >= Rarity.Rank.Epic)
			end
			t.Check("an item without a rarity, or one unknown: no tile", not Capture.Offered("Item", nil) and not Capture.Offered("Item", "Shiny"))
			t.Check("a chest's or anything else's card: no tile", not Capture.Offered("Chest", "Legendary") and not Capture.Offered("", "Epic"))
		end,
	},
	{
		Name = "Capture (TR60): a share's launch data is the sharer's UserId alone, read back on a friend's join; nothing else is a share",
		Run = function(t: any)
			local data = Capture.Launch(123456789)
			t.Equal("the sharer's id, and nothing more", data, "share:123456789")
			t.Equal("read back on a friend's join", Capture.Sharer(data, 42), 123456789)
			t.Equal("its own sharer joining: not counted", Capture.Sharer(data, 123456789), nil)
			t.Equal("a whole id kept whole", Capture.Sharer(Capture.Launch(9_007_199_254), 1), 9_007_199_254)
			for _, bad in { "", "share:", "share:abc", "share:-5", "share:0", "share:12x", "invite:12", " share:12", "share:12 ", "share:1.5", string.rep("9", 80) } do
				t.Equal(`"{bad}": not a share`, Capture.Sharer(bad, 42), nil)
			end
			t.Check("no launch data, or not a string: not a share", Capture.Sharer(nil, 42) == nil and Capture.Sharer(12 :: any, 42) == nil and Capture.Sharer({} :: any, 42) == nil)
		end,
	},
}
