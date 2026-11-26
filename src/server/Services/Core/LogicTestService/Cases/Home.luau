--!strict
-- Logic cases (pure): TR19, "Home in one tap: the dock's Base tile" (docs/test-requests.md): every refusal in its order,
-- its words, the cooldown, a charge broken by a hit; and what a fallen lead's card offers, the next lead or, out alone,
-- the Base tile's pip (TR16's offer, its chip and trail gone).
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Hud = require(Shared.Rules.Hud)
local Home = require(Shared.Rules.Home)
local HomeConfig = require(Shared.Config.Home)

local NOW = 1_800_000_000

-- Out on the street, the lead standing beside the avatar, nothing in the way.
local function out(change: { [string]: any }?): Home.Situation
	local s: Home.Situation = { Now = NOW, HitAt = nil, Engaged = false, Standing = true, Try = false, Event = false, ReadyAt = 0, OnPlot = false }
	for key, value in change or {} do
		(s :: any)[key] = value
	end
	return s
end

local RULES = { Fight = 4 }

return {
	{
		Name = "Home: TR19, a tap goes home out in a ground, and every refusal says why, in its order",
		Run = function(t: any)
			t.Equal("out on the street, nothing in the way: home", Home.Refusal(out(), RULES), nil)
			t.Equal("on their own plot: here, and a tap does nothing", Home.Refusal(out({ OnPlot = true }), RULES), "Here")
			t.Equal("here says nothing", Home.Says("Here", out({ OnPlot = true })), nil)
			t.Equal("but the tile's word says why a tap does nothing (TR20)", Home.Word("Here", out({ OnPlot = true })), "Back at your base")
			t.Equal("a refused tile's word is its toast's", Home.Word("Fight", out({ Engaged = true })), "In a fight")
			t.Equal("a ready tile has no word of its own", Home.Word(nil, out()), nil)
			t.Equal("in a keeper's try: a boss's ground", Home.Refusal(out({ Try = true }), RULES), "Boss")
			t.Equal("its words", Home.Says("Boss", out({ Try = true })), "Not during a keeper fight")
			t.Equal("an event on", Home.Refusal(out({ Event = true }), RULES), "Event")
			t.Equal("its words", Home.Says("Event", out({ Event = true })), "Not during an event")
			t.Equal("a hit just now: in a fight", Home.Refusal(out({ HitAt = NOW }), RULES), "Fight")
			t.Equal("a hit 3.9 s ago: still", Home.Refusal(out({ HitAt = NOW - 3.9 }), RULES), "Fight")
			t.Equal("a hit 4 s ago: out of it", Home.Refusal(out({ HitAt = NOW - 4 }), RULES), nil)
			t.Equal("its words", Home.Says("Fight", out({ HitAt = NOW })), "In a fight")
			t.Equal("the cooldown running", Home.Refusal(out({ ReadyAt = NOW + 11.2 }), RULES), "Cooldown")
			t.Equal("its words count the whole seconds left", Home.Says("Cooldown", out({ ReadyAt = NOW + 11.2 })), "Ready in 12 s")
			t.Equal("12 s exactly", Home.Says("Cooldown", out({ ReadyAt = NOW + 12 })), "Ready in 12 s")
			t.Equal("a moment left still reads a second", Home.Says("Cooldown", out({ ReadyAt = NOW + 0.01 })), "Ready in 1 s")
			t.Equal("the cooldown over", Home.Refusal(out({ ReadyAt = NOW }), RULES), nil)
			t.Equal("home before anything: a try never stands on the plot, and here is what the tile shows",
				Home.Refusal(out({ OnPlot = true, HitAt = NOW, ReadyAt = NOW + 5 }), RULES), "Here")
			t.Equal("a boss's ground before the fight in it", Home.Refusal(out({ Try = true, HitAt = NOW }), RULES), "Boss")
			t.Equal("an event before a fight", Home.Refusal(out({ Event = true, HitAt = NOW }), RULES), "Event")
			t.Equal("a fight before the cooldown", Home.Refusal(out({ HitAt = NOW, ReadyAt = NOW + 5 }), RULES), "Fight")
			t.Equal("the config's fight is the spec's 4 s", HomeConfig.Fight, 4)
		end,
	},
	{
		Name = "Home: TR19, a fight is the game's one meaning of it, or a hit's tail while the lead stands (research's verdict)",
		Run = function(t: any)
			-- Research's verdict in motion on TR19 (2026-11-15): "In a fight" is FightService.InCombat or a hit in the last
			-- 4 s, the tail only while the lead stands. InCombat's two ways in (the lead's target, a Shade's) are one fact here.
			t.Equal("the closing gap: the lead has its target and no hit yet", Home.Refusal(out({ Engaged = true }), RULES), "Fight")
			t.Equal("a Shade has the lead and no hit yet", Home.Refusal(out({ Engaged = true, HitAt = NOW - 30 }), RULES), "Fight")
			t.Equal("its words", Home.Says("Fight", out({ Engaged = true })), "In a fight")
			t.Equal("engaged, still under a boss's ground", Home.Refusal(out({ Engaged = true, Try = true }), RULES), "Boss")
			t.Equal("engaged before the cooldown", Home.Refusal(out({ Engaged = true, ReadyAt = NOW + 5 }), RULES), "Fight")
			t.Equal("engaged at home is still home", Home.Refusal(out({ Engaged = true, OnPlot = true }), RULES), "Here")
			t.Equal("after a fall, a hit just now leaves no tail", Home.Refusal(out({ Standing = false, HitAt = NOW }), RULES), nil)
			t.Equal("after a fall, the cooldown still counts", Home.Refusal(out({ Standing = false, HitAt = NOW, ReadyAt = NOW + 5 }), RULES), "Cooldown")
			t.Equal("no lead out: no tail either", Home.Refusal(out({ Standing = false, HitAt = NOW - 1 }), RULES), nil)
			t.Equal("standing, the tail holds", Home.Refusal(out({ HitAt = NOW - 1 }), RULES), "Fight")
		end,
	},
	{
		Name = "Home: TR19, a hit dealt or taken in the charge cancels it, and the charge and the cooldown run 0 to 1",
		Run = function(t: any)
			t.Check("no hit: the charge holds", not Home.Broken(NOW, nil))
			t.Check("a hit before it began: holds", not Home.Broken(NOW, NOW - 0.1))
			t.Check("a hit as it began: broken", Home.Broken(NOW, NOW))
			t.Check("a hit in it: broken", Home.Broken(NOW, NOW + 0.3))
			t.Equal("the charge's start", Home.Share(NOW, HomeConfig.Charge, NOW), 0)
			t.Check("its middle (server time's float, to a millionth)", math.abs(Home.Share(NOW, 0.6, NOW + 0.3) - 0.5) < 1e-6)
			t.Equal("its end, and past it", Home.Share(NOW, 0.6, NOW + 2), 1)
			t.Equal("before it: none", Home.Share(NOW, 0.6, NOW - 1), 0)
			t.Equal("no length: done", Home.Share(NOW, 0, NOW), 1)
		end,
	},
	{
		Name = "Home: a fallen card offers the next lead while another is ready, else, out in a ground, home: the Base tile's pip",
		Run = function(t: any)
			local ready: Hud.Other = { Role = "" }
			local healingOne: Hud.Other = { Role = "", Healing = NOW + 30 }
			local healed: Hud.Other = { Role = "", Healing = NOW - 1 }
			local worker: Hud.Other = { Role = "Bay 1" }
			t.Equal("the lead standing: nothing", Hud.AfterFall(false, {}, NOW, true), nil)
			t.Equal("one Voidkin fallen, out on the street: the pip", Hud.AfterFall(true, {}, NOW, true), "Home")
			t.Equal("one fallen, the player already home: nothing", Hud.AfterFall(true, {}, NOW, false), nil)
			t.Equal("a second one ready: the next lead, and no pip", Hud.AfterFall(true, { ready }, NOW, true), "Send")
			t.Equal("a second one ready, at the base too", Hud.AfterFall(true, { ready }, NOW, false), "Send")
			t.Equal("a second still healing from its own fall: the pip", Hud.AfterFall(true, { healingOne }, NOW, true), "Home")
			t.Equal("that second once whole: the next lead", Hud.AfterFall(true, { healed }, NOW, true), "Send")
			t.Equal("a second at work in a bay can't lead: the pip", Hud.AfterFall(true, { worker }, NOW, true), "Home")
			t.Equal("among several, one ready is enough", Hud.AfterFall(true, { worker, healingOne, ready }, NOW, true), "Send")
			t.Equal("the lead itself, were it listed, never sends", Hud.AfterFall(true, { { Role = "Lead" } }, NOW, true), "Home")
			t.Equal("the lead's return: gone, whoever else is ready", Hud.AfterFall(false, { worker, ready }, NOW, true), nil)
			t.Equal("the lead's return alone: gone", Hud.AfterFall(false, {}, NOW, true), nil)
		end,
	},
}
