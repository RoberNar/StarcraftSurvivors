import os
import sys

tools_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(tools_dir)
from scformats import Grp

SRC = r"C:\Users\toffe\Desktop\SCsurvivors"
zerg_dir = os.path.join(SRC, "unit", "zerg")

units = ["guardian", "devour", "queen", "avenger", "defiler"]

print("--- Checking Zerg Grps ---")
for u in units:
    grp_file = os.path.join(zerg_dir, u + ".grp")
    if os.path.exists(grp_file):
        g = Grp(grp_file)
        print(f"FOUND {u}.grp: {g.frame_count} frames, size {g.width}x{g.height}")
    else:
        print(f"NOT FOUND: {u}.grp")

print("\n--- Checking Shadow Grps ---")
all_files = os.listdir(zerg_dir)
for f in all_files:
    if "shad" in f.lower() or "death" in f.lower() or "explo" in f.lower():
        print(f"Effect/Shadow: {f}")
