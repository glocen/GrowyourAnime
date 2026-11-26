--!strict
-- Logic cases (pure): one refusal (TR71 B; Rules.Refusal, Config.Refusals). Every code a rule refuses with has its
-- line, no line says "can't" or shows a code, a line fills its number grouped and says its plain words without it, an
-- unknown code says the fallback, and the shake dies away to rest. Runs in Studio (LogicTests) and with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Refusals = require(Shared.Config.Refusals)
local Refusal = require(Shared.Rules.Refusal)
local Base = require(Shared.Rules.Base)
local BaseLevels = require(Shared.Rules.BaseLevels)
local Shop = require(Shared.Rules.Shop)
local Collection = require(Shared.Rules.Collection)
local Carry = require(Shared.Rules.Carry)
local Chests = require(Shared.Rules.Chests)
local Regalia = require(Shared.Rules.Regalia)
local Reinforce = require(Shared.Rules.Reinforce)
local Emblems = require(Shared.Rules.Emblems)
local Codes = require(Shared.Rules.Codes)
local Stages = require(Shared.Rules.Stages)

-- A code's line is a fallback on purpose: a request of the wrong shape, or for nothing that exists.
local FALLBACK_OK = { Unknown = true, BadArgs = true }

-- Each rule module's refusal codes (its string fields), the system whose lines word them.
local function codesOf(module: any): { string }
	local list = {}
	for key, value in module do
		if type(key) == "string" and type(value) == "string" and string.match(key, "^%u") then
			table.insert(list, value)
		end
	end
	table.sort(list)
	return list
end

-- Every line's words, filled with a number for each field.
local function everyLine(): { { System: string, Code: string, Words: string } }
	local all = {}
	for system, lines in Refusals.Lines do
		for code, line in lines do
			local texts = if type(line) == "string" then { line } else { line.Words, line.Plain }
			for _, text in texts do
				local filled = text:gsub("{%w+}", "12")
				table.insert(all, { System = system, Code = code, Words = filled })
			end
		end
	end
	return all
end

return {
	{
		Name = "Refusal: every code a rule refuses with has its line (TR71 B)",
		Run = function(t: any)
			local systems = {
				{ "Base", Base, nil },
				{ "Levels", BaseLevels, nil },
				{ "Shop", Shop, nil },
				{ "Voidkin", Collection, nil },
				{ "Voidkin", Carry, nil },
				{ "Chests", Chests, { NotEnough = true, BagFull = true } },
				{ "Salvage", Chests, { NotOwned = true, Worn = true } },
				{ "Equip", Regalia, nil },
				{ "Gear", Reinforce, nil },
				{ "Gear", Emblems, nil },
				{ "Codes", Codes, { Unknown = true, Ended = true, Used = true, Wait = true } },
				{ "Stages", Stages, { Before = true, Keeper = true, Ground = true, Locked = true } },
			}
			for _, row in systems do
				local system, module, only = row[1] :: string, row[2], row[3] :: { [string]: boolean }?
				local codes = codesOf(module)
				t.Check(`{system}: its module's codes read`, #codes >= 2, tostring(#codes))
				for _, code in codes do
					if only and not only[code] then
						continue
					end
					if FALLBACK_OK[code] and not (only and only[code]) then
						continue
					end
					t.Check(`{system} {code}: its line`, Refusals.Lines[system] ~= nil and Refusals.Lines[system][code] ~= nil)
				end
			end
			for _, code in { "Boss", "Event", "Fight", "Cooldown", "Here" } do
				t.Check(`Home {code}: its line`, Refusals.Lines.Home[code] ~= nil)
			end
		end,
	},
	{
		Name = "Refusal: no line says can't or shows a code, and each is about six words (docs/ui.md, Words players read)",
		Run = function(t: any)
			for _, row in everyLine() do
				local lower = row.Words:lower()
				local name = `{row.System} {row.Code}`
				t.Check(`{name}: no "can't"`, not (lower:find("can't", 1, true) or lower:find("cannot", 1, true) or lower:find("can not", 1, true)), row.Words)
				t.Check(`{name}: no code in its words`, row.Words:find("%u%l+%u%l") == nil, row.Words)
				t.Check(`{name}: no "!"`, row.Words:find("!", 1, true) == nil)
				local words = 0
				for _ in row.Words:gmatch("%S+") do
					words += 1
				end
				t.Check(`{name}: at most 10 words`, words <= 10, `{words}: {row.Words}`)
			end
			t.Check("the fallback says the fix", Refusals.Fallback == "That didn't go through. Try again.")
		end,
	},
	{
		Name = "Refusal: a line fills its number grouped, says its plain words without it, and a code it doesn't know is the fallback",
		Run = function(t: any)
			for _, row in { { 0, "0" }, { 7, "7" }, { 999, "999" }, { 1000, "1,000" }, { 1200, "1,200" }, { 12345, "12,345" }, { 1234567, "1,234,567" }, { 12.6, "13" }, { -1500, "-1,500" } } do
				t.Equal(`{row[1]} grouped`, Refusal.Number(row[1] :: number), row[2])
			end
			t.Equal("Credits short, with its number", Refusal.Words("Levels", "Short", { Need = 1200 }), "Need 1,200 more Credits")
			t.Equal("without it, the plain words", Refusal.Words("Levels", "Short"), "Not enough Credits")
			t.Equal("a line with no field", Refusal.Words("Shop", "Limit"), "None left for you this stock")
			t.Equal("a word field", Refusal.Words("Stages", "Keeper", { Keeper = "Lamplighter" }), "Beat the Lamplighter on Normal")
			t.Equal("a field-only line missing its field: the fallback", Refusal.Words("Stages", "Before"), Refusals.Fallback)
			t.Equal("an unknown code", Refusal.Words("Shop", "Nonsense"), Refusals.Fallback)
			t.Equal("no code", Refusal.Words("Shop", nil), Refusals.Fallback)
			t.Equal("an unknown system", Refusal.Words("Nowhere", "Poor"), Refusals.Fallback)
			t.Equal("a server's answer", Refusal.Of("Shop", { Ok = false, Error = "Poor" }, { Need = 50 }), "Need 50 more Credits")
			t.Equal("an answer's own fields", Refusal.Of("Home", { Refusal = "Cooldown", Seconds = 3 }), "Ready in 3 s")
			t.Equal("fields over the answer's", Refusal.Of("Home", { Refusal = "Cooldown", Seconds = 3 }, { Seconds = 9 }), "Ready in 9 s")
			t.Equal("no answer", Refusal.Of("Shop", nil), Refusals.Fallback)
			t.Equal("an answer's code: its Error", Refusal.Code({ Ok = false, Error = "Poor", Refusal = "Gone" }), "Poor")
			t.Equal("or its Refusal", Refusal.Code({ Refusal = "Cooldown" }), "Cooldown")
			t.Equal("a code that isn't a string: none", Refusal.Code({ Error = 7 }), nil)
			t.Check("a line it has", Refusal.Has("Shop", "Poor"))
			t.Check("a code it hasn't", not Refusal.Has("Shop", "Nonsense"))
			t.Check("no code", not Refusal.Has("Shop", nil))
		end,
	},
	{
		Name = "Refusal: the shake swings three times and dies away, at rest at both ends",
		Run = function(t: any)
			local points = 4
			t.Equal("at rest before", Refusal.Shift(0, points), 0)
			t.Equal("at rest after", Refusal.Shift(1, points), 0)
			t.Equal("past its end", Refusal.Shift(1.5, points), 0)
			local most, turns, last = 0, 0, 0
			for i = 1, 199 do
				local s = Refusal.Shift(i / 200, points)
				most = math.max(most, math.abs(s))
				if last ~= 0 and s ~= 0 and (s > 0) ~= (last > 0) then
					turns += 1
				end
				if s ~= 0 then
					last = s
				end
			end
			t.Check("never past its points", most <= points + 1e-9, tostring(most))
			t.Check("it moves", most > points * 0.5, tostring(most))
			t.Equal("three swings each way: five turns", turns, 5)
			t.Check("it dies away", math.abs(Refusal.Shift(0.95, points)) < math.abs(Refusal.Shift(0.05, points)) + 1e-9)
		end,
	},
}
