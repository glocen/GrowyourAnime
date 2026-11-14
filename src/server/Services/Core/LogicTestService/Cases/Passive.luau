--!strict
-- Passive cases (pure): every passive row is whole and points at what exists, each Voidkin with a kit has one, the three
-- seeds (TR7, part 3), and each kind's rule at its edges, the Reduction through a whole hit.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Passives = require(Shared.Definitions.Passives)
local Actions = require(Shared.Definitions.Actions)
local Voidkin = require(Shared.Definitions.Voidkin)
local Passive = require(Shared.Rules.Passive)
local Stats = require(Shared.Rules.Stats)
local Hit = require(Shared.Rules.Hit)

local NONE: Hit.Rolls = { Dodge = 0.999999, Critical = 0.999999, Block = 0.999999 } -- nothing rolls in

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-9
end

local function inKit(def: string, action: string): boolean
	for _, id in Actions.Kits[def] or {} do
		if id == action then
			return true
		end
	end
	return false
end

return {
	{
		Name = "Passive: every row is whole, short and simple, and names what exists; each Voidkin with a kit has one",
		Run = function(t: any)
			local cues = { Shell = "Reduction", Flare = "Extra" }
			for _, row in Passives.List do
				t.Check(`{row.Id}: a Voidkin`, Voidkin.ById[row.Id] ~= nil)
				t.Check(`{row.Id}: a name`, #row.Name > 0)
				t.Check(`{row.Id}: a share between 0 and 1`, row.Share > 0 and row.Share < 1, `{row.Share}`)
				if row.Kind == "Reduction" then
					t.Check(`{row.Id}: a health share below which it holds`, row.Below ~= nil and row.Below > 0 and row.Below < 1)
				elseif row.Kind == "Extra" then
					local action = Actions.ById[row.Action or ""]
					t.Check(`{row.Id}: its action in its kit`, action ~= nil and inKit(row.Id, action.Id), row.Action)
					t.Check(`{row.Id}: a beat that hits`, action ~= nil and action.Hits[row.Beat or ""] ~= nil, row.Beat)
				elseif row.Kind == "Cooldown" then
					local action = Actions.ById[row.Action or ""]
					t.Check(`{row.Id}: its action in its kit, with a cooldown`, action ~= nil and inKit(row.Id, action.Id) and action.Cooldown > 0, row.Action)
				else
					t.Check(`{row.Id}: a known kind`, false, row.Kind)
				end
				if row.Cue then
					t.Equal(`{row.Id}: its cue fits its kind`, cues[row.Cue], row.Kind)
				end
				if row.Cue == "Flare" then
					t.Check(`{row.Id}: where it flares`, row.At ~= nil and #(row.At :: string) > 0)
				end
			end
			for def in Actions.Kits do
				t.Check(`{def}: a passive`, Passives.ById[def] ~= nil)
			end
		end,
	},
	{
		Name = "Passive: the seeds, Second Wind, Kindle and Tempo (TR7, part 3)",
		Run = function(t: any)
			local rook, pip, lyric = Passives.ById.rook, Passives.ById.pip, Passives.ById.lyric
			t.Check("Rook: 20% less below 30%", rook.Kind == "Reduction" and rook.Share == 0.2 and rook.Below == 0.3 and rook.Cue == "Shell")
			t.Check("Pip: 40% again on his combo's third shot, at the lantern", pip.Kind == "Extra" and pip.Share == 0.4 and pip.Action == "PipCombo" and pip.Beat == "Shot3" and pip.Cue == "Flare" and pip.At == "Lantern")
			t.Check("Lyric: Held Note 20% sooner, no cue", lyric.Kind == "Cooldown" and lyric.Share == 0.2 and lyric.Action == "LyricHeldNote" and lyric.Cue == nil)
		end,
	},
	{
		Name = "Passive: a Reduction holds under its share and standing, and takes its share off a whole hit",
		Run = function(t: any)
			local rook = Passives.ById.rook
			t.Equal("at 29%: holds", Passive.Holds(rook, 29, 100), true)
			t.Equal("at 30%: not", Passive.Holds(rook, 30, 100), false)
			t.Equal("fallen: not", Passive.Holds(rook, 0, 100), false)
			t.Equal("no most: not", Passive.Holds(rook, 1, 0), false)
			t.Equal("no row: not", Passive.Holds(nil, 1, 100), false)
			t.Equal("another kind: not", Passive.Holds(Passives.ById.pip, 1, 100), false)
			t.Equal("its share while it holds", Passive.Reduction(rook, 20, 100), 0.2)
			t.Equal("none above", Passive.Reduction(rook, 50, 100), 0)
			local a = Stats.Empty(1)
			a.Attack = 100
			local d = Stats.Empty(1)
			local plain = Hit.Resolve(a, d, 1, NONE, { Reduction = Passive.Reduction(rook, 50, 100) })
			local held = Hit.Resolve(a, d, 1, NONE, { Reduction = Passive.Reduction(rook, 20, 100) })
			t.Equal("a hit above it, whole", plain.Total, 100)
			t.Check("a hit under it, 20% less", near(held.Total, 80), `{held.Total}`)
		end,
	},
	{
		Name = "Passive: an Extra adds its share on its beat alone; a Cooldown shortens its action alone",
		Run = function(t: any)
			local pip, lyric = Passives.ById.pip, Passives.ById.lyric
			t.Check("on the third shot, 40% of it", near(Passive.Extra(pip, "PipCombo", "Shot3", 50), 20))
			t.Equal("the second shot: none", Passive.Extra(pip, "PipCombo", "Shot2", 50), 0)
			t.Equal("another action's Shot3: none", Passive.Extra(pip, "LyricCombo", "Shot3", 50), 0)
			t.Equal("a dodged shot (nothing dealt): none", Passive.Extra(pip, "PipCombo", "Shot3", 0), 0)
			t.Equal("no row: none", Passive.Extra(nil, "PipCombo", "Shot3", 50), 0)
			t.Equal("another kind: none", Passive.Extra(lyric, "PipCombo", "Shot3", 50), 0)
			local held = Actions.ById.LyricHeldNote.Cooldown
			t.Check("Held Note, 20% sooner", near(Passive.Cooldown(lyric, "LyricHeldNote", held), held * 0.8))
			t.Equal("her combo: unchanged", Passive.Cooldown(lyric, "LyricCombo", 0), 0)
			t.Equal("another's signature: unchanged", Passive.Cooldown(lyric, "PipLanternBurst", 10), 10)
			t.Equal("no row: unchanged", Passive.Cooldown(nil, "LyricHeldNote", held), held)
			t.Equal("another kind: unchanged", Passive.Cooldown(pip, "LyricHeldNote", held), held)
		end,
	},
}
