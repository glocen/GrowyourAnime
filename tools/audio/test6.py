"""AR13, the sound test: writes every layer of the six cues, then their numbers and their picture.

    py tools/audio/test6.py

Writes build/handoff/Audio/test6/: the takes as 48 kHz mono OGG, test6.json and test6_numbers.md (every take measured
on its file read back), and test6_layers.png (each layer's first take as a wave over its spectrum through time).
"""
import audiokit as ak
import critical
import heavy_hit
import light_hit
import shade_burst
import shade_hurt
import shade_swipe

if __name__ == "__main__":
    records = [record for cue in (shade_swipe, shade_hurt, shade_burst, light_hit, heavy_hit, critical)
               for record in cue.make()]
    ak.sheet(records)
    ak.picture(records, ak.OUT / "test6_layers.png")
    failed = [f"{r['layer']}: {k}" for r in records for k, v in r["checks"].items() if not v]
    print("every check passes" if not failed else "FAILS: " + "; ".join(failed))
