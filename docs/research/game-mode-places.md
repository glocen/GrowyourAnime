# A game mode in its own place: how it's done (Faber, 2026-11-19)

The director, 2026-11-19, 02:05 to 02:07 by the clock: "festival of battle is a game mode it need a new places not the main experience", "u can make a new place inside this experience (game)", and on the menu, "the teleport point of the base will simply open the menu ui of the game mode (the player can also just open the map button that should be renamed to play or something else and open FOB)". Then: "yes, do research on how pro dev make new places for game mode etc take note if there is geniune tips then go ahead".

What was read: Roblox's own pages and DevForum threads, by a read-only search on generic questions, labelled by evidence. OBSERVED is what a page says. DESIGN is our inference. What we build from it lives in `docs/engineering-plan.md`, "Places".

## The tips worth keeping

**Teleporting**
- OBSERVED: `TeleportService:TeleportAsync(placeId, players, TeleportOptions)` is the one current call, server only, at most 50 players at a time. `Teleport`, `TeleportToPlaceInstance`, `TeleportPartyAsync`, `ReserveServer` and `ShouldReserveServer` are deprecated. Routing goes in TeleportOptions: `ServerInstanceId` (a JobId), `ReservedServerId` or `ForcePublicServer`, one at a time ([TeleportService](https://create.roblox.com/docs/reference/engine/classes/TeleportService), [TeleportOptions](https://create.roblox.com/docs/reference/engine/classes/TeleportOptions)).
- OBSERVED: a reserved server is any `HttpService:GenerateGUID(false)` set as `ReservedServerId`. The first teleport makes it, the same id finds it again, and on arrival `game.PrivateServerId` is that id ([private servers](https://create.roblox.com/docs/projects/teleport-private-servers)). For D1's parties.
- OBSERVED: Roblox's own retry. Try the call up to 5 times, 1 s apart. On `TeleportInitFailed`, retry `Flooded` after 15 s and `Failure` after 1 s; anything else (`GameFull`, `Unauthorized`, `GameEnded`, `IsTeleporting`) is final ([teleport guide](https://create.roblox.com/docs/projects/teleport); [staff, 2022](https://devforum.roblox.com/t/1652500)). DESIGN: their handler has no cap, so ours counts attempts per player.
- OBSERVED: teleports have stalled with no error and no failure event, players waiting 60 s and more ([2024](https://devforum.roblox.com/t/3031861)). DESIGN: a watchdog. Still in the base 40 s after the call, the player gets their screen back and a line saying the trip failed.
- OBSERVED: a new server takes about 5 to 6 s to start (staff, [2023](https://devforum.roblox.com/t/2732748)); reports run from instant to over a minute. No official figure. DESIGN: the ticket carries its send time and the arrival logs the trip, so we measure ours.
- OBSERVED: no flash of bare world on arrival: a ReplicatedFirst script takes `GetArrivingTeleportGui()` at once, parents it, calls `RemoveDefaultLoadingScreen()`, and keeps it until our own boot is ready. `SetTeleportGui` is set on the client before each trip, and its scripts don't run ([DevForum](https://devforum.roblox.com/t/931618)).
- OBSERVED: teleport data is plain and passes through the client. `Player:GetJoinData()` on the server is the one to read: Roblox vouches it came from one of this game's servers for this player in the last 48 h, with a trustworthy `SourcePlaceId` ([Player](https://create.roblox.com/docs/reference/engine/classes/Player)). An old ticket can be replayed within those 48 h ([DevForum](https://devforum.roblox.com/t/2794032)). DESIGN: the ticket is a request, never a grant. The Festival checks the stage against the player's own save before starting it, and nothing valuable ever travels in it.
- OBSERVED: Studio's Test and Team Test now run teleports within the same game; the destination opens as a new test server, with JobId and PrivateServerId empty in Test ([teleport guide](https://create.roblox.com/docs/projects/teleport)). Older threads say the opposite. DESIGN: our place role is the workspace attribute, so it doesn't lean on those ids. Before trusting a test, check which version of the Festival place the test server loaded.

**The save across places**
- OBSERVED: ProfileStore, finding a profile still held by the server the player left, asks that server to save and let go, reads again after 5 s, then every 10 s, and takes it after about 40 s (ProfileStore's [source](https://raw.githubusercontent.com/MadStudioRoblox/ProfileStore/main/ProfileStore.luau)). `PlayerRemoving` fires when the player actually leaves, not when the teleport is asked ([DevForum](https://devforum.roblox.com/t/1789676)).
- DESIGN: so a trip with the session ended at leave costs at most one 5 s wait at the far end, never a lost write. We measure it before choosing the early release (end the session before the call, start it again if the trip fails), which takes a pause on every change during the trip.
- OBSERVED: writes after a session ends are dropped silently ([ProfileStore API](https://madstudioroblox.github.io/ProfileStore/api/)). A round trip base, Festival, base needs its own test ([an unanswered 2025 report](https://devforum.roblox.com/t/3190543/328)).

**The place**
- OBSERVED: a place is added with Studio's File, Publish As, the experience, "Add as a new place" ([publishing](https://create.roblox.com/docs/production/publishing/publish-games-and-places)). A removed place goes with no prompt.
- OBSERVED: access to a place other than the start place is set per place (Access, Direct Access; "Secure within universe only" lets only our servers send players there) ([teleport guide](https://create.roblox.com/docs/projects/teleport)). DESIGN: off for the Festival, so it's only ever reached from the base. Its arrival still handles a player with no ticket.
- OBSERVED: server size and fill are set per place; set sizes under 11 on the Creator Dashboard, not Studio's dialog ([DevForum](https://devforum.roblox.com/t/2486632)).
- OBSERVED: a server keeps the version it started on until it empties or is restarted, and "Restart only servers with outdated versions" works per place ([updates](https://create.roblox.com/docs/projects/update-games)). DESIGN: after a publish, both places restart their old servers together, and the ticket and the save carry a version, so new code reads what old code wrote.
- OBSERVED: players not sent on during a restart land in the start place, the base ([staff](https://devforum.roblox.com/t/4003952)). OBSERVED: wait about 2 s after a server starts before sending anyone out of it ([staff, 2026](https://devforum.roblox.com/t/3931691)).
- DESIGN: each place's world builds live only in that place, so a place is never overwritten by a file from Rojo or a publish by API. Each Studio connects to Rojo and saves its own place, as today.

**Coming back**
- DESIGN: the ticket carries the base's JobId. Home sends the player back to that server (`ServerInstanceId`); on `GameFull` or `GameEnded`, to any base server. The plot comes from the save, so any server works.
- OBSERVED: following a friend into a reserved server fails; route them through the start place ([DevForum](https://devforum.roblox.com/t/1456086)).

## Nothing solid found on

An official trip time, a rate limit beyond `Flooded`, a size limit for teleport data, how long a reserved server lives, whether custom matchmaking applies to teleports, and whether Studio's test destination loads the saved or the published copy of a place.
