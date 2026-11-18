--!strict
-- Names (shared, pure): which Voidkin's name a text holds. The names never go to Roblox's automatic translation (the
-- director, 2026-11-18, D8): "Rook" or "Lyric" would come back as a common word. A whole word only, so "Rookie" and
-- "Watts" hold none, and a tag around it ("<b>Rook</b>") doesn't hide it. Read by NameGuardController, which keeps
-- such a label out of translation, and by the UI lint, which checks it did.

local Shared = game:GetService("ReplicatedStorage").Shared
local Voidkin = require(Shared.Definitions.Voidkin)

local Names = {}

-- The first Voidkin's name `text` holds as a whole word, in the roster's order, or nil.
function Names.Found(text: string): string?
	for _, row in Voidkin.List do
		if string.find(text, `%f[%a]{row.Name}%f[%A]`) then
			return row.Name
		end
	end
	return nil
end

return Names
