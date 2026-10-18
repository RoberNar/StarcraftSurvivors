import os
import shutil
import cv2
import numpy as np
from PIL import Image

from scformats import Grp, grp_to_sheet, write_png, read_wpe, player_remap

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = r"C:\Users\toffe\Desktop\SCsurvivors"
OUT = os.path.join(HERE, "..", "assets", "skins", "sd")

PAL = read_wpe(os.path.join(SRC, "TileSet", "badlands.wpe"))
TUNIT = os.path.join(SRC, "game", "tunit.pcx")
PLAYER_BLUE = 1

def generate_medic_sprites():
    grp_path = os.path.join(SRC, "unit", "terran", "medic.grp")
    g = Grp(grp_path)
    remap = player_remap(TUNIT, PLAYER_BLUE)
    
    # 1. Main sprite sheet
    w, h, data, cols, rows = grp_to_sheet(g, PAL, remap=remap, columns=17)
    out_sprite = os.path.join(OUT, "sprites", "medic.png")
    write_png(out_sprite, w, h, data)
    print(f"Generated medic.png: {w}x{h}, cols={cols}, rows={rows}")
    
    # 2. Shadow sheet
    w_s, h_s, data_s, cols_s, rows_s = grp_to_sheet(g, PAL, mode="shadow", columns=17)
    out_shadow = os.path.join(OUT, "sprites", "medic_shadow.png")
    write_png(out_shadow, w_s, h_s, data_s)
    print(f"Generated medic_shadow.png: {w_s}x{h_s}, cols={cols_s}, rows={rows_s}")

def generate_medic_portrait():
    # 60x56 frames, 10 cols x 3 rows = 600x168
    port_dir = os.path.join(SRC, "SD", "portrait", "tmedic")
    videos = [
        os.path.join(port_dir, "TMEfid00.webm"), # 10 frames -> row 0
        os.path.join(port_dir, "TMEtlk00.webm"), # 10 frames -> row 1
        os.path.join(port_dir, "TMEtlk01.webm"), # 10 frames -> row 2
    ]
    
    sheet = np.zeros((56 * 3, 60 * 10, 4), dtype=np.uint8)
    
    for row_idx, vid_path in enumerate(videos):
        cap = cv2.VideoCapture(vid_path)
        col_idx = 0
        while cap.isOpened() and col_idx < 10:
            ret, frame = cap.read()
            if not ret:
                break
            # Convert BGR to RGBA
            frame_rgba = cv2.cvtColor(frame, cv2.COLOR_BGR2RGBA)
            # Ensure exact 60x56
            if frame_rgba.shape[0] != 56 or frame_rgba.shape[1] != 60:
                frame_rgba = cv2.resize(frame_rgba, (60, 56), interpolation=cv2.INTER_NEAREST)
            
            y_start = row_idx * 56
            y_end = y_start + 56
            x_start = col_idx * 60
            x_end = x_start + 60
            sheet[y_start:y_end, x_start:x_end] = frame_rgba
            col_idx += 1
        cap.release()
    
    out_port = os.path.join(OUT, "portrait", "medic_portrait.png")
    os.makedirs(os.path.dirname(out_port), exist_ok=True)
    img = Image.fromarray(sheet)
    img.save(out_port)
    print(f"Generated medic_portrait.png: {img.size}")

def copy_medic_audio():
    snd_dir = os.path.join(SRC, "SD", "sound", "terran", "medic")
    sfx_out = os.path.join(OUT, "sfx")
    os.makedirs(sfx_out, exist_ok=True)
    
    mapping = {
        "TMdRdy00.wav": "medic_ready.wav",
        "TMdDth00.wav": "medic_death.wav",
        "Tmedheal.wav": "medic_heal.wav",
        "TMdWht00.wav": "medic_what0.wav",
        "TMdWht01.wav": "medic_what1.wav",
        "TMdWht02.wav": "medic_what2.wav",
        "TMdWht03.wav": "medic_what3.wav",
        "TMdYes00.wav": "medic_yes0.wav",
        "TMdYes01.wav": "medic_yes1.wav",
        "TMdYes02.wav": "medic_yes2.wav",
        "TMdYes03.wav": "medic_yes3.wav",
    }
    
    for src_name, dst_name in mapping.items():
        src_file = os.path.join(snd_dir, src_name)
        dst_file = os.path.join(sfx_out, dst_name)
        if os.path.exists(src_file):
            shutil.copy2(src_file, dst_file)
            print(f"Copied {src_name} -> {dst_name}")

if __name__ == "__main__":
    generate_medic_sprites()
    generate_medic_portrait()
    copy_medic_audio()
    print("All medic assets successfully generated!")
