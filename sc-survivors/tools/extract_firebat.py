import os
import shutil
import numpy as np
from PIL import Image

from scformats import Grp, grp_to_sheet, write_png, read_wpe, player_remap

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = r"C:\Users\toffe\Desktop\SCsurvivors"
OUT = os.path.join(HERE, "..", "assets", "skins", "sd")

PAL = read_wpe(os.path.join(SRC, "TileSet", "badlands.wpe"))
TUNIT = os.path.join(SRC, "game", "tunit.pcx")
PLAYER_BLUE = 1

def generate_firebat_sprites():
    grp_path = os.path.join(SRC, "unit", "terran", "firebat.grp")
    g = Grp(grp_path)
    remap = player_remap(TUNIT, PLAYER_BLUE)
    
    # Firebat native: 170 frames (17 cols x 10 rows), 32x32 pixels.
    # Marine and Medic are 17 cols x 14 rows, 64x64 pixels.
    # We create a 17 cols x 14 rows (1088x896) canvas for firebat,
    # placing each 32x32 frame centered at (x_offset=16, y_offset=16) in its 64x64 cell.
    # This aligns Firebat 1:1 with Marine/Medic collision, pivot, and shadow!
    
    # 1. Main sprite sheet
    w_raw, h_raw, data_raw, cols, rows = grp_to_sheet(g, PAL, remap=remap, columns=17)
    arr_raw = np.frombuffer(data_raw, dtype=np.uint8).reshape((h_raw, w_raw, 4))
    
    # 14 rows x 64 = 896, 17 cols x 64 = 1088
    full_w = 17 * 64
    full_h = 14 * 64
    full_sheet = np.zeros((full_h, full_w, 4), dtype=np.uint8)
    
    for r in range(10): # 10 rows from firebat.grp
        for c in range(17):
            src_cell = arr_raw[r*32:(r+1)*32, c*32:(c+1)*32]
            # Center in 64x64: offset x=16, y=16
            full_sheet[r*64 + 16 : r*64 + 16 + 32, c*64 + 16 : c*64 + 16 + 32] = src_cell
            
    # Copy death frames (row 13, frames 221-228) from marine.png so death animation works seamlessly
    marine_path = os.path.join(OUT, "sprites", "marine.png")
    if os.path.exists(marine_path):
        m_img = Image.open(marine_path)
        m_arr = np.array(m_img)
        # Row 13 in 14-row sheet: from y=13*64 = 832 to 896
        full_sheet[13*64:14*64, :] = m_arr[13*64:14*64, :]
        
    out_sprite = os.path.join(OUT, "sprites", "firebat.png")
    Image.fromarray(full_sheet).save(out_sprite)
    print(f"Generated firebat.png: {full_w}x{full_h}, cols=17, rows=14")
    
    # 2. Shadow sheet
    w_s_raw, h_s_raw, data_s_raw, cols_s, rows_s = grp_to_sheet(g, PAL, mode="shadow", columns=17)
    arr_s_raw = np.frombuffer(data_s_raw, dtype=np.uint8).reshape((h_s_raw, w_s_raw, 4))
    
    full_shadow = np.zeros((full_h, full_w, 4), dtype=np.uint8)
    for r in range(10):
        for c in range(17):
            src_s_cell = arr_s_raw[r*32:(r+1)*32, c*32:(c+1)*32]
            full_shadow[r*64 + 16 : r*64 + 16 + 32, c*64 + 16 : c*64 + 16 + 32] = src_s_cell
            
    # Copy death shadow from marine_shadow
    marine_s_path = os.path.join(OUT, "sprites", "marine_shadow.png")
    if os.path.exists(marine_s_path):
        ms_img = Image.open(marine_s_path)
        ms_arr = np.array(ms_img)
        full_shadow[13*64:14*64, :] = ms_arr[13*64:14*64, :]
        
    out_shadow = os.path.join(OUT, "sprites", "firebat_shadow.png")
    Image.fromarray(full_shadow).save(out_shadow)
    print(f"Generated firebat_shadow.png: {full_w}x{full_h}, cols=17, rows=14")

def generate_firebat_wireframe():
    grp_path = os.path.join(SRC, "unit", "wirefram", "wirefram.grp")
    g = Grp(grp_path)
    # Unit 32: Terran Firebat
    w, h, data, cols, rows = grp_to_sheet(g, PAL, frames=[32], columns=1)
    out_wire = os.path.join(OUT, "sprites", "wire_firebat.png")
    write_png(out_wire, w, h, data)
    print(f"Generated wire_firebat.png: {w}x{h}")

def generate_extreme_heat_cloud():
    # Extract Dark Swarm cloud (dswarm.grp: 10 frames of 252x188)
    # 5 cols x 2 rows = 1260 x 376
    grp_path = os.path.join(SRC, "unit", "thingy", "dswarm.grp")
    g = Grp(grp_path)
    w, h, data, cols, rows = grp_to_sheet(g, PAL, columns=5)
    out_cloud = os.path.join(OUT, "sprites", "extreme_heat_cloud.png")
    write_png(out_cloud, w, h, data)
    print(f"Generated extreme_heat_cloud.png: {w}x{h}, cols={cols}, rows={rows}")

def copy_firebat_audio():
    snd_dir = os.path.join(SRC, "SD", "sound", "terran", "firebat")
    sfx_out = os.path.join(OUT, "sfx")
    os.makedirs(sfx_out, exist_ok=True)
    
    mapping = {
        "tfbrdy00.wav": "firebat_ready.wav",
        "tfbdth00.wav": "firebat_death.wav",
        "tfbdth01.wav": "firebat_death1.wav",
        "tfbdth02.wav": "firebat_death2.wav",
        "tfbwht00.wav": "firebat_what0.wav",
        "tfbwht01.wav": "firebat_what1.wav",
        "tfbwht02.wav": "firebat_what2.wav",
        "tfbwht03.wav": "firebat_what3.wav",
        "tfbyes00.wav": "firebat_yes0.wav",
        "tfbyes01.wav": "firebat_yes1.wav",
        "tfbyes02.wav": "firebat_yes2.wav",
        "tfbyes03.wav": "firebat_yes3.wav",
    }
    
    for src_name, dst_name in mapping.items():
        src_file = os.path.join(snd_dir, src_name)
        dst_file = os.path.join(sfx_out, dst_name)
        if os.path.exists(src_file):
            shutil.copy2(src_file, dst_file)
            print(f"Copied {src_name} -> {dst_name}")

    # Copy cloud / swarm activation sound
    defiler_snd = os.path.join(SRC, "SD", "sound", "zerg", "defiler", "zdeblo00.wav")
    if os.path.exists(defiler_snd):
        shutil.copy2(defiler_snd, os.path.join(sfx_out, "extreme_heat_activate.wav"))
        print("Copied zdeblo00.wav -> extreme_heat_activate.wav")

if __name__ == "__main__":
    generate_firebat_sprites()
    generate_firebat_wireframe()
    generate_extreme_heat_cloud()
    copy_firebat_audio()
    print("All Firebat assets generated successfully!")
