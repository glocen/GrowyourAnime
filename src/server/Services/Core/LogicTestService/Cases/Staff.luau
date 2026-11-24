--!strict
-- Logic cases (pure): a bay's picker (Rules.Power.Staff). Every owned Voidkin once; the gain it shows is the gain the
-- server's own SetWorker gives, whether the Voidkin is free, works another bay, or would send the worker here out; the
-- most gain first; the worker here and the lead last, and neither can be stationed. Runs in Studio (LogicTests) and with
-- Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Transaction = require(Shared.Data.Transaction)
local Voidkin = require(Shared.Definitions.Voidkin)
local DataConfig = require(Shared.Config.Data)
local Base = require(Shared.Rules.Base)
local BaseLevels = require(Shared.Rules.BaseLevels)
local Breaker = require(Shared.Rules.Breaker)
local Collection = require(Shared.Rules.Collection)
local Power = require(Shared.Rules.Power)

local NOW = 1_800_000_000

-- A base at its top level, six Voidkin of mixed levels, the first leading; ids in the order uncovered.
local function staffed(): (Profile.Data, { string })
	local data = Profile.Template()
	Migrations.Run(data)
	Breaker.Advance(data, NOW)
	data.Base.Level = BaseLevels.Top()
	while #data.Base.Bays < BaseLevels.Bays(data.Base.Level) do
		table.insert(data.Base.Bays, { Worker = "", Level = 1 } :: any)
	end
	local ids: { string } = {}
	local levels = { 30, 4, 12, 1, 20, 7 }
	for index, row in Voidkin.List do
		if index > #levels then
			break
		end
		local id = Collection.Uncover(data, row.Id, NOW).Id
		data.Voidkin[id].Level = levels[index]
		ids[index] = id
	end
	data.Roles.Lead = ids[1]
	return data, ids
end

local function station(data: Profile.Data, bay: number, id: string): any
	return (Transaction.Run(data, nil, function(draft: Profile.Data): any
		return Base.Actions.SetWorker(draft, { Bay = bay, Voidkin = id }, NOW, 0.5)
	end, DataConfig.OpsKept))
end

return {
	{
		Name = "Staff: a bay's picker shows the gain the server gives, the most first, the worker here and the lead last",
		Run = function(t: any)
			local data, ids = staffed()
			local bays = #data.Base.Bays
			t.Check("the base has bays to staff", bays >= 3 and #ids >= 5, `{bays} bays, {#ids} Voidkin`)
			data.Base.Bays[2].Level = 6 -- a bay that pays more than the others
			t.Check("two at work", station(data, 1, ids[2]).Ok == true and station(data, 2, ids[4]).Ok == true)
			for bay = 1, bays do
				local hands = Power.Staff(data, bay)
				local seen: { [string]: boolean } = {}
				local stage, last = 1, math.huge
				for _, hand in hands do
					t.Check(`bay {bay}, {hand.Id}: once`, not seen[hand.Id] and data.Voidkin[hand.Id] ~= nil)
					seen[hand.Id] = true
					local now = if hand.Where == "Lead" then 3 elseif hand.Where == "Here" then 2 else 1
					t.Check(`bay {bay}, {hand.Id}: the stationable, then the one here, then the lead`, now >= stage)
					if now > stage then
						stage, last = now, math.huge
					end
					t.Check(`bay {bay}, {hand.Id}: the most gain first`, hand.Gain <= last + 1e-9, `{hand.Gain} after {last}`)
					last = hand.Gain
					-- the server's own answer, on a copy
					local copy = Profile.DeepCopy(data)
					local before = Power.Generation(copy)
					local answer = station(copy, bay, hand.Id)
					if hand.Where == "Lead" then
						t.Check(`bay {bay}: the lead is refused, and gains nothing`, answer.Error == Base.Leading and hand.Gain == 0)
					else
						t.Check(`bay {bay}, {hand.Id}: the server stations it`, answer.Ok == true, tostring(answer.Error))
						local got = Power.Generation(copy) - before
						t.Check(`bay {bay}, {hand.Id}: the gain shown is the gain got`, math.abs(got - hand.Gain) < 1e-6, `{hand.Gain} for {got}`)
						local out = Power.Output(copy.Voidkin[hand.Id]) * BaseLevels.BayOutput(copy.Base.Bays[bay].Level or 1)
						t.Check(`bay {bay}, {hand.Id}: its output here`, math.abs(out - hand.Kw) < 1e-6, `{hand.Kw} for {out}`)
					end
					t.Check(`bay {bay}, {hand.Id}: where it stands`, (hand.Where == "Lead") == (hand.Id == data.Roles.Lead) and (hand.Where == "Here") == (data.Base.Bays[bay].Worker == hand.Id) and (hand.Where == "Bay") == (hand.Bay ~= nil))
				end
				local owned = 0
				for _ in data.Voidkin do
					owned += 1
				end
				t.Equal(`bay {bay}: every owned Voidkin`, #hands, owned)
			end
			t.Equal("a bay that isn't open has no picker", #Power.Staff(data, bays + 1), 0)
			-- pressing the first row of each empty bay in turn never lowers the base's generation
			local made = Power.Generation(data)
			for bay = 1, bays do
				local first = Power.Staff(data, bay)[1]
				if first and first.Where ~= "Here" and first.Where ~= "Lead" and first.Gain > 0 then
					station(data, bay, first.Id)
					t.Check(`bay {bay}: the first row raised the generation`, Power.Generation(data) > made)
					made = Power.Generation(data)
				end
			end
			t.Check("two reads agree", (function(): boolean
				local a, b = Power.Staff(data, 1), Power.Staff(data, 1)
				for index, hand in a do
					if b[index].Id ~= hand.Id then
						return false
					end
				end
				return true
			end)())
		end,
	},
}
