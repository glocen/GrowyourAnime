--!strict
-- Travel (pure rules): the trip between the base and the Festival of Battles (TR45; docs/engineering-plan.md, "Places";
-- Config.Travel). A ticket is what the sending server asks of the far one, carried in the teleport's data. It passes
-- through the player's client, so it is a request, never a grant: the far server reads it back through Read, which keeps
-- only well-formed fields, and checks a stage against the player's own save (Arrival). Nothing valuable ever rides in it.
-- No Roblox API.

local Shared = script.Parent.Parent
local Profile = require(Shared.Data.Profile)
local TravelConfig = require(Shared.Config.Travel)
local Stages = require(Shared.Rules.Stages)
local StagesConfig = require(Shared.Config.Stages)

local Travel = {}

Travel.Version = 1

export type Go = "Stage" | "Home"

export type Ticket = {
	V: number,
	Go: Go,
	Ground: string?,
	Difficulty: string?,
	Stage: number?,
	Alone: boolean?, -- the Keeper alone (TR74): the run begins at the keeper's stretch, as Rules.Stages.Alone allows
	From: string?, -- the base server's JobId, so the way home finds it again
	Sent: number, -- unix seconds with milliseconds, so the far side logs the trip's length
}

-- What a retry does next: wait so long, and go to any server of the place instead of the one asked for.
export type Step = { Wait: number, Open: boolean }

-- What an arrival starts: a stage's run, or the menu where they stand.
export type Arrival = { Begin: boolean, Difficulty: string?, Stage: number?, Alone: boolean?, Refused: string? }

local MAX_TEXT = 64

local function text(value: any): string?
	return if type(value) == "string" and #value > 0 and #value <= MAX_TEXT then value else nil
end

-- A trip out to a stage; `alone` for the Keeper alone.
function Travel.Stage(ground: string, difficulty: string, stage: number, from: string?, sent: number, alone: boolean?): Ticket
	return { V = Travel.Version, Go = "Stage", Ground = ground, Difficulty = difficulty, Stage = stage, Alone = if alone == true then true else nil, From = from, Sent = sent }
end

-- A trip home.
function Travel.Home(sent: number): Ticket
	return { V = Travel.Version, Go = "Home", Sent = sent }
end

-- The ticket the far server got, kept only if well formed: anything else is nil, as if none came.
function Travel.Read(data: any): Ticket?
	if type(data) ~= "table" or data.V ~= Travel.Version or type(data.Sent) ~= "number" or data.Sent ~= data.Sent then
		return nil
	end
	if data.Go == "Home" then
		return Travel.Home(data.Sent)
	elseif data.Go ~= "Stage" then
		return nil
	end
	local ground, difficulty, stage = text(data.Ground), text(data.Difficulty), data.Stage
	if ground == nil or difficulty == nil or type(stage) ~= "number" or stage ~= math.floor(stage) or stage < 1 or stage > 99 then
		return nil
	end
	return Travel.Stage(ground, difficulty, stage, text(data.From), data.Sent, data.Alone == true)
end

-- The ticket a joining player brought (TravelService, from Player:GetJoinData()), read only when they came by teleport
-- from one of this universe's places (`places`: Config.Game.Places), so teleport data from anywhere else is none; Read
-- keeps the rest well formed.
function Travel.Joined(join: any, places: { [string]: number }): Ticket?
	if type(join) ~= "table" or type(join.SourcePlaceId) ~= "number" then
		return nil
	end
	for _, id in places do
		if id == join.SourcePlaceId then
			return Travel.Read(join.TeleportData)
		end
	end
	return nil
end

-- After a failed trip: the next try, or nil to give up. `failed` counts this trip's failures so far, this one included;
-- `routed` when it asked for one server. A flood waits long, a plain failure briefly; a server full or gone sends the
-- player to any server of the place instead, once. Anything else is final.
function Travel.Next(result: string, failed: number, routed: boolean): Step?
	if failed > TravelConfig.Most then
		return nil
	elseif result == "Flooded" then
		return { Wait = TravelConfig.Flooded, Open = false }
	elseif result == "Failure" then
		return { Wait = TravelConfig.Failure, Open = false }
	elseif routed and (result == "GameFull" or result == "GameEnded") then
		return { Wait = 0, Open = true }
	end
	return nil
end

-- What a player arriving in the Festival starts. A ticket's run begins at its checkpoint if the save opens it (TR50);
-- refused, or with no ticket, a fresh player begins the first stretch on Normal (TR43) and anyone else gets the Arc
-- panel where they land. A ticket for the Keeper alone begins at the keeper's stretch if Rules.Stages.Alone allows it at
-- `now` (the keeper's rest included), else refused as any.
function Travel.Arrival(ticket: Ticket?, data: Profile.Data, ground: string, now: number): Arrival
	local refused: string? = nil
	if ticket and ticket.Go == "Stage" and ticket.Ground == ground and ticket.Alone then
		local alone = Stages.Alone(data, ground, ticket.Difficulty :: string, now)
		if alone.Ok then
			return { Begin = true, Difficulty = ticket.Difficulty, Stage = alone.Stage, Alone = true }
		end
		refused = alone.Needs or alone.Error
	elseif ticket and ticket.Go == "Stage" and ticket.Ground == ground then
		-- the run begins at its checkpoint, as the save has it on arrival (TR50); the ticket's stage is the one it saw
		local difficulty = ticket.Difficulty :: string
		local stage = if StagesConfig.Offset[difficulty] ~= nil then Stages.Checkpoint(data, ground, difficulty) else ticket.Stage :: number
		local needs = Stages.Needs(data, ground, difficulty, stage)
		if needs == nil then
			return { Begin = true, Difficulty = difficulty, Stage = stage }
		end
		refused = needs
	elseif ticket and ticket.Go == "Stage" then
		refused = Stages.Unknown
	end
	if Stages.Fresh(data) then
		return { Begin = true, Difficulty = "Normal", Stage = 1, Refused = refused }
	end
	return { Begin = false, Refused = refused }
end

-- The trip's length in seconds, from the ticket's send to `now`, or nil when the clocks disagree past belief.
function Travel.Took(ticket: Ticket, now: number): number?
	local took = now - ticket.Sent
	return if took >= 0 and took < 600 then took else nil
end

return Travel
