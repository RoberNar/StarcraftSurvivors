import os
from PIL import Image

OUT = r"c:\Users\toffe\Desktop\autocalabazas\sc-survivors\assets\skins\sd\sprites"

files = [
    "guardian.png", "guardian_shadow.png", "guardian_death.png", "guardian_spore.png", "guardian_spore_hit.png",
    "devourer.png", "devourer_shadow.png", "devourer_death.png", "devourer_acid.png", "devourer_hit_fx.png",
    "queen.png", "queen_shadow.png", "queen_death.png", "queen_ensnare.png",
    "scourge.png", "scourge_shadow.png", "scourge_death.png", "scourge_explo.png"
]

for f in files:
    p = os.path.join(OUT, f)
    if os.path.exists(p):
        im = Image.open(p)
        print(f"{f:22s} size={im.size}")
    else:
        print(f"{f:22s} NOT FOUND")
