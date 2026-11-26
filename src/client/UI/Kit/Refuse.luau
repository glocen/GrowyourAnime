--!strict
-- Refuse (UI kit; TR71 B): a refusal said the one way. Its words come from the one table (Config.Refusals, through
-- Rules.Refusal), in grey (Theme.Colour.TextDim) on a toast; a code the table has no line for says the fallback and is
-- named in the output, never to a player. The pressed control's shake is the kit button's own (Button.Shake).
--   Refuse.Show(system, answer, fields?, where?) -> string   says it; `where` names the press in the output
--   Refuse.Words(system, code, fields?) -> string            says a refusal no server gave (a press refused on the client)

local Shared = game:GetService("ReplicatedStorage").Shared
local Refusal = require(Shared.Rules.Refusal)
local Theme = require(script.Parent.Parent.Theme)
local Toast = require(script.Parent.Toast)

local Refuse = {}

function Refuse.Show(system: string, answer: { [string]: any }?, fields: { [string]: any }?, where: string?): string
	local code = Refusal.Code(answer)
	if not Refusal.Has(system, code) then
		warn(`[Refuse] {where or system}: an unnamed refusal, {tostring(code)}`) -- the output names it; a player never reads a code
	end
	local words = Refusal.Of(system, answer, fields)
	Toast.Show(words, Theme.Colour.TextDim)
	return words
end

function Refuse.Words(system: string, code: string, fields: { [string]: any }?): string
	local words = Refusal.Words(system, code, fields)
	Toast.Show(words, Theme.Colour.TextDim)
	return words
end

return Refuse
