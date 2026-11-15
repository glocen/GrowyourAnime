--!strict
-- Home (config): home in one tap, the dock's Base tile (docs/test-requests.md, TR19). Seeds, UNVERIFIED: tuned in play
-- (Tune "Home.Charge"). The light is a stand-in until Modulo's look, and the sound waits for AR13's later pass.
return {
	Charge = 0.6, -- seconds the tile fills from its foot before the jump; a hit dealt or taken in them cancels it
	Cooldown = 20, -- seconds after a jump before the next, swept across the tile
	Fight = 4, -- a hit the player's side dealt or took this recently is "In a fight"
	-- The charge: the avatar's outline lifts in void light, to Outline's full over the charge.
	Outline = Color3.fromHex("#B48CFF"),
	-- The jump: a white-violet light at the screen's edges, up and gone in Flash seconds, Reach of the screen deep.
	Flash = 0.15,
	Edge = Color3.fromHex("#EEE4FF"),
	Reach = 0.22,
	-- The arrival: the camera's field of view Fov degrees wider, eased back over Settle seconds, and a puff of light at
	-- the feet, Puff studs across at its widest.
	Fov = 4,
	Settle = 0.3,
	Puff = 6,
	-- A refused tap: the tile shakes and says why (Config.Hud.Dock: Shake, Shook).
}
