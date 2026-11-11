--!strict
-- Presets (shared): named sets of Config values, switched while a server runs (Util.Preset). Baseline is the game's own
-- numbers, which the self-test and the logic tests are written against, so it changes nothing. A preset that tries
-- other numbers adds { Set = { ["Module.Key"] = value } } here and a place in Order.

export type Preset = { Set: { [string]: any } }

return {
	List = {
		Baseline = { Set = {} },
	} :: { [string]: Preset },
	Order = { "Baseline" } :: { string },
	Default = "Baseline",
}
