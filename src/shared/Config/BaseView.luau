--!strict
-- BaseView (shared config): the base screen's command view, TR21's blockout (docs/ui.md, 7; docs/test-requests.md,
-- TR21). The camera lifts over the player's own base and looks down on all of it, and a plain chip hangs over each
-- machine and bay; the base's level and a tapped machine's panel carry Upgrade. Seeds, UNVERIFIED: the builder's, tuned in play (NL_Debug:Invoke("Tune", "BaseView.Lift.Pitch", 60)),
-- until research's verdict on the take.
return {
	-- Where the camera stands: from the gate's side, Pitch degrees down onto the middle of the base's machines, as far as
	-- their box needs to fit the screen at Fov, Pad studs round it and at least Least studs from its middle each way. So
	-- the view frames today's base and the one AR16 spreads across the plot alike.
	Lift = {
		Pitch = 58,
		Fov = 50, -- degrees, vertical
		Pad = 16,
		Least = 40,
		Seconds = 0.9, -- the lift, and the way back behind the lead
	},
	-- A chip over a machine or a bay: its name and level, and what it's doing now.
	Chip = {
		Width = 168, -- authored pixels
		Rise = 7, -- studs over the machine's spot on the floor
		Every = 0.25, -- seconds between readings
		Gap = 6, -- authored pixels between two chips: one that would cover another rises over it
	},
	-- The base's level, top middle, authored pixels: its lines Width across, its Upgrade press beside them. With the
	-- pads, 534 across: clear of the X on the smallest phone, 666 authored pixels wide.
	Level = { Width = 350, Press = 160 },
	Side = { Width = 264 }, -- a machine's panel, opened by a tap on its chip, at the side its chip isn't on
}
