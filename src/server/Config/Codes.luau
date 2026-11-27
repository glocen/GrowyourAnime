--!strict
-- The promo codes (server only; TR59; docs/design.md, "The welcome week and codes"). Here, never in Shared.Config: a list
-- in ReplicatedStorage reaches every client, and a code's words leak before it's posted (research's item 5, 2026-11-27,
-- from Gemini's audit, G2-029). What a code may give, the tries and the length stay in Config.Welcome.Codes, which the
-- client reads. WelcomeService redeems from this list; the logic case checks each row pays only what a code may.
-- One an update, each typed once an account; the list ships with its update. Where codes are posted is the director's.
-- None yet: the first code's gift and end date come at the first update.

local Welcome = require(game:GetService("ReplicatedStorage").Shared.Config.Welcome)

return {
	List = {} :: { Welcome.Code },
}
