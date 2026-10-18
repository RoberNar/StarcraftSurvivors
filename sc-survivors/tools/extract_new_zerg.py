import os
import shutil
import sys

tools_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(tools_dir)
from scformats import Grp, grp_to_sheet, write_png, read_wpe, player_remap

SRC = r"C:\Users\toffe\Desktop\SCsurvivors"
OUT = os.path.join(tools_dir, "..", "assets", "skins", "sd")
SPRITES_OUT = os.path.join(OUT, "sprites")
SFX_OUT = os.path.join(OUT, "sfx")

os.makedirs(SPRITES_OUT, exist_ok=True)
os.makedirs(SFX_OUT, exist_ok=True)

PAL = read_wpe(os.path.join(SRC, "TileSet", "badlands.wpe"))
TUNIT = os.path.join(SRC, "game", "tunit.pcx")
PLAYER_ZERG = 0  # Red (player 0) for Zerg enemies

def extract_sheet(rel_grp, name, cols=17, mode="normal", remap_player=PLAYER_ZERG):
    full_path = os.path.join(SRC, *rel_grp.split("/"))
    if not os.path.exists(full_path):
        print(f"ERROR: {full_path} not found")
        return
    g = Grp(full_path)
    remap = player_remap(TUNIT, remap_player) if remap_player is not None else None
    W, H, data, c, r = grp_to_sheet(g, PAL, columns=cols, remap=remap, mode=mode)
    out_file = os.path.join(SPRITES_OUT, name + ".png")
    write_png(out_file, W, H, data)
    print(f"Extracted {name}.png ({W}x{H}, {g.frame_count} frames, cell {g.width}x{g.height})")

def copy_sfx(src_rel, target_name):
    src_full = os.path.join(SRC, *src_rel.split("/"))
    target_full = os.path.join(SFX_OUT, target_name + ".wav")
    if os.path.exists(src_full):
        shutil.copy2(src_full, target_full)
        print(f"Copied SFX: {target_name}.wav")
    else:
        print(f"ERROR SFX: {src_full} not found")

print("=== 1. EXTRACTING GUARDIAN ===")
extract_sheet("unit/zerg/guardian.grp", "guardian", cols=17)
extract_sheet("unit/zerg/guardian.grp", "guardian_shadow", cols=17, mode="shadow")
extract_sheet("unit/zerg/zgudeath.grp", "guardian_death", cols=8)
extract_sheet("unit/bullet/spores.grp", "guardian_spore", cols=8)
extract_sheet("unit/thingy/sporehit.grp", "guardian_spore_hit", cols=8)
copy_sfx("sound/zerg/guardian/zgudth00.wav", "guardian_death")
copy_sfx("sound/zerg/guardian/zgupss00.wav", "guardian_attack")
copy_sfx("sound/zerg/guardian/zgurdy00.wav", "guardian_ready")

print("\n=== 2. EXTRACTING DEVOURER ===")
extract_sheet("unit/zerg/devour.grp", "devourer", cols=17)
extract_sheet("unit/zerg/devour.grp", "devourer_shadow", cols=17, mode="shadow")
extract_sheet("unit/zerg/zdvDeath.grp", "devourer_death", cols=8)
extract_sheet("unit/thingy/zdvPuke.grp", "devourer_acid", cols=17)
extract_sheet("unit/thingy/zdvHit.grp", "devourer_hit_fx", cols=8)
copy_sfx("sound/zerg/devourer/zdvdth00.wav", "devourer_death")
copy_sfx("sound/zerg/devourer/firesuck.wav", "devourer_attack")
copy_sfx("sound/zerg/devourer/goophit.wav", "devourer_hit")
copy_sfx("sound/zerg/devourer/zdvrdy00.wav", "devourer_ready")

print("\n=== 3. EXTRACTING QUEEN ===")
extract_sheet("unit/zerg/queen.grp", "queen", cols=17)
extract_sheet("unit/zerg/queen.grp", "queen_shadow", cols=17, mode="shadow")
extract_sheet("unit/zerg/zqudeath.grp", "queen_death", cols=8)
extract_sheet("unit/thingy/ensnare.grp", "queen_ensnare", cols=8)
copy_sfx("sound/zerg/queen/zqudth00.wav", "queen_death")
copy_sfx("sound/zerg/queen/zquens00.wav", "queen_ensnare")
copy_sfx("sound/zerg/queen/zqurdy00.wav", "queen_ready")

print("\n=== 4. EXTRACTING SCOURGE (AVENGER) ===")
extract_sheet("unit/zerg/avenger.grp", "scourge", cols=17)
extract_sheet("unit/zerg/avenger.grp", "scourge_shadow", cols=17, mode="shadow")
extract_sheet("unit/zerg/zavdeath.grp", "scourge_death", cols=8)
extract_sheet("unit/zerg/zavexplo.grp", "scourge_explo", cols=8)
copy_sfx("sound/zerg/avenger/zavatt00.wav", "scourge_charge")
copy_sfx("sound/zerg/avenger/zavhit00.wav", "scourge_explode")
copy_sfx("sound/zerg/avenger/zavdth00.wav", "scourge_death")
copy_sfx("sound/zerg/avenger/zavrdy00.wav", "scourge_ready")

print("\n=== 5. EXTRACTING OVERLORD ===")
extract_sheet("unit/zerg/overlord.grp", "overlord", cols=17)
extract_sheet("unit/zerg/overlord.grp", "overlord_shadow", cols=17, mode="shadow")
copy_sfx("sound/zerg/overlord/zovpss00.wav", "overlord_groan")
copy_sfx("sound/misc/zOvTra00.wav", "overlord_drop")

print("\n=== 6. EXTRACTING SUNKEN TENTACLE ===")
extract_sheet("unit/bullet/tentacle.grp", "sunken_tentacle", cols=6)
copy_sfx("sound/bullet/spooghit.wav", "sunken_hit")

print("\nExtraction finished successfully!")
