"""Genera hojas de previsualizacion para identificar frames y tiles. Uso: python preview.py"""
import os
import sys
from scformats import Grp, grp_to_sheet, write_png, read_wpe, player_remap, Tileset, blit

SRC = r"C:\Users\toffe\Desktop\SCsurvivors"
OUT = sys.argv[1] if len(sys.argv) > 1 else "preview"
os.makedirs(OUT, exist_ok=True)

pal = read_wpe(os.path.join(SRC, "TileSet", "badlands.wpe"))
blue = player_remap(os.path.join(SRC, "game", "tunit.pcx"), 1)

for rel in ["unit/terran/marine.grp", "unit/terran/tmadeath.grp", "unit/zerg/zergling.grp",
            "unit/zerg/zzedeath.grp", "unit/zerg/zzeshad.grp", "unit/thingy/tmnexplo.grp",
            "unit/bullet/tspark.grp", "unit/thingy/bblood01.grp", "unit/thingy/blood01.grp"]:
    g = Grp(os.path.join(SRC, rel))
    W, H, data, c, r = grp_to_sheet(g, pal, remap=blue)
    name = os.path.basename(rel).replace(".grp", "")
    write_png(os.path.join(OUT, name + ".png"), W, H, data)
    print(name, "frames", g.frame_count, "size", g.width, g.height)

for ts in ["badlands", "jungle"]:
    t = Tileset(os.path.join(SRC, "TileSet", ts))
    n = min(len(t.groups), 1024)
    cols = 32
    rows = (n + cols - 1) // cols
    W, H = cols * 32, rows * 32
    img = bytearray(W * H * 4)
    for gi in range(n):
        mt = t.groups[gi][0]
        blit(img, W, t.megatile_rgba(mt), 32, 32, (gi % cols) * 32, (gi // cols) * 32)
    write_png(os.path.join(OUT, ts + "_groups.png"), W, H, img)
    print(ts, "groups", len(t.groups))
