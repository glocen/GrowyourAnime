--!strict
-- Reveal (shared config): the reveal's numbers tuned by playing (docs/test-requests.md, TR4). Modulo's art, its places
-- and its timing are Config.RevealArt, written from reveal.json; the rules are Rules.Reveal; the stage is
-- src/client/UI/Reveal.

return {
	Skip = 1.0, -- seconds from the tap the skip opens, every rarity (reveal.json, "skip")
	CardHold = 0.3, -- seconds the card after it stands before a tap closes it, so the tap that skipped doesn't close it too
	-- Each Voidkin's Reveal clip: the marker his strike lands on, and its time in the clip. His clip is shifted so it falls
	-- on Rook's Knock, where the ceremony's colours run (RevealArt.Figure.Knock). The self-test reads the times back from
	-- the clips' own markers.
	Strikes = {
		RookReveal = { Marker = "Knock", Time = 0.85 },
		PipReveal = { Marker = "Flourish", Time = 0.9667 },
		LyricReveal = { Marker = "Strike", Time = 1.5 },
	} :: { [string]: { Marker: string, Time: number } },
	Fallback = "RookReveal", -- the clip a Voidkin without his own Reveal plays (the grey stand-in)
	-- His silhouette's rim: the light from behind him, its colour the rarity's, so his edge takes it and his front stays
	-- dark. The direction is in the camera's frame (x right, y up, z toward the camera).
	Rim = { Direction = Vector3.new(0.35, -0.2, 1) },
	-- His colours' light once they run: from over the camera's left shoulder, the room's light low around it.
	Lit = { Ambient = Color3.fromRGB(178, 172, 186), Light = Color3.fromRGB(150, 146, 140), Direction = Vector3.new(0.4, -0.6, -0.7) },
	-- The game's face (Builder Sans ExtraBold) set this much over the art's size, so its capitals stand as tall as the
	-- art's: the art sets the name in Blender's stand-in face, whose capitals are taller at a size (40 against 33 points
	-- at Uncommon, 42 against 35 at Rare, measured on reveal_parts_compare.png, 2026-11-13).
	NameFace = 1.2,
	NameDescent = 0.21, -- the name's line below its baseline, against its size: its box's foot sits this far under 214
	DisplayOrder = 35, -- over the overlay's cover, under the toasts (UI/Layers)
}
