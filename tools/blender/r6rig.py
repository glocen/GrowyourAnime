"""The R6 rig's numbers, in plain Python: Roblox's own Motor6D joints, the parts' sizes and the held parts' welds.

The joints and sizes are engine facts. The WEAPONS, STOWS, tips and claws below are one game's example: replace them with your own.

One home for both sides of the parity check: tools/blender/r6anim.py builds its Blender rig from them, and
tools/blender/r6parity.py (no Blender) poses the same rig from an export. Change a number here and both move together.
CFrames are Roblox's 12 components (x, y, z, R00 ... R22).
"""

PARTS = ("Torso", "Head", "Right Arm", "Left Arm", "Right Leg", "Left Leg")  # each part's Part0 comes before it
ROOT_HEIGHT = 3.0  # studs from the floor to the HumanoidRootPart's centre

# Part1: (Part0, C0, C1), measured on a live R6 character.
_BASE = (-1, 0, 0, 0, 0, 1, 0, 1, 0)
_RIGHT = (0, 0, 1, 0, 1, 0, -1, 0, 0)
_LEFT = (0, 0, -1, 0, 1, 0, 1, 0, 0)
JOINTS = {
    "Torso": ("HumanoidRootPart", (0, 0, 0) + _BASE, (0, 0, 0) + _BASE),
    "Head": ("Torso", (0, 1, 0) + _BASE, (0, -0.5, 0) + _BASE),
    "Right Arm": ("Torso", (1, 0.5, 0) + _RIGHT, (-0.5, 0.5, 0) + _RIGHT),
    "Left Arm": ("Torso", (-1, 0.5, 0) + _LEFT, (0.5, 0.5, 0) + _LEFT),
    "Right Leg": ("Torso", (1, -1, 0) + _RIGHT, (0.5, 1, 0) + _RIGHT),
    "Left Leg": ("Torso", (-1, -1, 0) + _LEFT, (-0.5, 1, 0) + _LEFT),
}
SIZES = {"Torso": (2, 2, 1), "Head": (2, 1, 1), "Right Arm": (1, 2, 1), "Left Arm": (1, 2, 1),
         "Right Leg": (1, 2, 1), "Left Leg": (1, 2, 1), "Right Shin": (1, 1, 1), "Left Shin": (1, 1, 1)}
# The head as the game draws it: the 2x1x1 part shows a head mesh at Scale 1.25, about 1.25 studs each way.
HEAD_DRAWN = (1.25, 1.25, 1.25)

# Held parts: (Part0, weld C0, weld C1, review box size), read from your live welds, where
# Part1 = Part0 * C0 * C1:Inverse(). GRIP is each hand's grip; the weapons' own scripts put their origins there.
GRIP = (0, -1, 0, 1, 0, 0, 0, 0, 1, 0, -1, 0)
WEAPONS = {
    "HeldRight": ("Right Arm", GRIP, (0, 0.0091, 0.1707, 1, 0, 0, 0, 1, 0, 0, 0, 1), (0.39, 1.42, 0.64)),
    "HeldRightBlade": ("HeldRight", (0, 2.1374, 0.2578, 1, 0, 0, 0, 1, 0, 0, 0, 1), (0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), (0.05, 3.35, 0.43)),
    "HeldLeft": ("Left Arm", GRIP, (0, -0.2009, 0.9275, 1, 0, 0, 0, 1, 0, 0, 0, 1), (0.19, 0.98, 2.09)),
}
WELDED = ("HeldRight", "HeldLeft")  # what the parity JSON reports: the parts welded to a hand
# Who carries what (a clip's "Character", a rig's name): a character not listed carries nothing, so the checks and the
# audit leave weapons out for it.
LOADOUTS = {"Hero": ("HeldRight", "HeldRightBlade", "HeldLeft")}
# Weapon points in their grip frames (Roblox studs): the right-hand blade's tip and the left-hand weapon's muzzle,
# for the floor checks.
HELD_TIP = (0, 3.80, 0.28)
MUZZLE = (0, 0.42, -2.03)

# The weapon wrist: a Motor6D per hand in
# place of the weld, with the weld's C0 and C1, so a clip can turn the weapon in the hand; unkeyed, it sits exactly
# where the weld did. Its Part1 is the held weapon's root part under one name per hand: hand -> (joint, the weapon
# part held today).
WRISTS = {"Right Arm": ("GripR", "HeldRight"), "Left Arm": ("GripL", "HeldLeft")}
GRIPS = tuple(joint for joint, _ in WRISTS.values())
# The knees: a joint at each leg's middle on the R6 body,
# named by its Part1, the shin, as any joint's Transform is. The hip stays R6's. Straight, thigh and shin are the leg's one box, so a clip
# that keys no knee stands exactly as it did. No ankle: a leaning shin stands on the edge of its sole.
KNEES = {"Right Leg": "Right Shin", "Left Leg": "Left Shin"}
KNEE_C0 = (0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)  # the knee in the leg's frame
KNEE_C1 = (0, 0.5, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)  # the knee in the shin's frame
# A creature's claws: a rigid mesh on a
# wrist of its own per arm, as the weapons' are, so a clip can twitch them: hand -> (the Motor6D, its Part1 (the claws'
# MeshPart, the name the clips key), C0 on the arm: the cuff's end, the sleeve's 0.12 inboard, the grip's axes). C1 is
# C0 less the claws' mesh centre (the "c" in its JSON); unkeyed, the joint holds them as a weld would.
CLAW_WRISTS = {"Right Arm": ("ClawR", "Creature_ClawsR", (-0.12, -0.92, -0.03, 1, 0, 0, 0, 0, 1, 0, -1, 0)),
               "Left Arm": ("ClawL", "Creature_ClawsL", (0.12, -0.92, -0.03, 1, 0, 0, 0, 0, 1, 0, -1, 0))}
# Each held weapon's own axes in its grip frame (the grip's -Z runs down the forearm, out of the fist; +Y is the hand's
# front): its length (a blade; a barrel, along the forearm) and its top (the blade's back; the barrel's top).
WEAPON_AXES = {"Right Arm": ((0, 1, 0), (0, 0, 1)), "Left Arm": ((0, 0, -1), (0, 1, 0))}
# Where a weapon rides while its hand lets go of it for a moment (a cast with the free hand): its grip frame on the
# hand's Part0 (the torso) as (grip point, length, top), Roblox studs and directions. The hand lays it there and finds
# it there; the wrist carries it in between (r6anim.stow), and once the fist is STOWED studs off it the audit checks it
# against its whole arm.
# Example: a short weapon rides at the left hip, a long blade at the right hip with its point back. Hang a long part too steep
# and its end meets the floor as the body leans.
STOWS = {"HeldLeft": ((-1.53, -1.0, 0.0), (-0.05, -0.82, 0.57), (0.0, -0.57, -0.82)),
         "HeldRight": ((1.53, -1.0, 0.0), (0.05, -0.37, 0.93), (0.0, 0.93, 0.37))}
STOWED = 1.0  # studs: a fist this far off its weapon's grip isn't holding it; nearer, it's reaching for it or letting
# go (a fist is a stud across, the weapon's box reaches past its grip), so only the arm above the fist is checked
