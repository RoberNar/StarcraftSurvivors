"""
Genera la textura de la cueva zerg (suelo de creep circular con bordes rocosos y oscuridad)
y los sprites de los pilares para la pelea del jefe.
"""
import os
import math
import random
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.append(HERE)
from scformats import Tileset, blit, write_png, read_wpe, Grp, grp_to_sheet

SRC = r"C:\Users\toffe\Desktop\SCsurvivors"
OUT = os.path.join(HERE, "..", "assets", "skins", "sd")

def gen_cave():
    print("Generando suelo de la Cueva Zerg...")
    t = Tileset(os.path.join(SRC, "TileSet", "badlands"))
    pal = t.palette
    
    creep_mts = [mt for mt in t.groups[1] if mt != 0]
    dirt_mts = [mt for mt in t.groups[2] if mt != 0]
    rock_mts = [mt for mt in t.groups[12] if mt != 0]
    
    # 40 x 40 megatiles de 32px = 1280 x 1280 px
    size = 40
    W = H = size * 32
    center_x = W / 2.0
    center_y = H / 2.0
    creep_radius = 450.0
    transition_radius = 540.0
    cave_wall_radius = 610.0
    
    cache = {}
    rnd = random.Random(1998)
    img = bytearray(W * H * 4)
    
    # Dibujar megatiles base
    for ty in range(size):
        for tx in range(size):
            cx = (tx + 0.5) * 32.0
            cy = (ty + 0.5) * 32.0
            dist = math.hypot(cx - center_x, cy - center_y)
            
            if dist < creep_radius:
                mt = rnd.choice(creep_mts)
            elif dist < transition_radius:
                p_creep = (transition_radius - dist) / (transition_radius - creep_radius)
                if rnd.random() < p_creep:
                    mt = rnd.choice(creep_mts)
                else:
                    mt = rnd.choice(rock_mts)
            elif dist < cave_wall_radius:
                mt = rnd.choice(rock_mts)
            else:
                mt = rnd.choice(rock_mts)
                
            if mt not in cache:
                cache[mt] = t.megatile_rgba(mt)
            blit(img, W, cache[mt], 32, 32, tx * 32, ty * 32)
            
    # Oscurecer progresivamente hacia el borde de la cueva para dar efecto de túnel/pared cerrada
    for y in range(H):
        dy = y - center_y
        row_offset = y * W * 4
        for x in range(W):
            dx = x - center_x
            dist = math.hypot(dx, dy)
            px_idx = row_offset + x * 4
            
            # Viñeta cavernosa circular
            if dist > creep_radius - 30.0:
                factor = 1.0 - (dist - (creep_radius - 30.0)) / (cave_wall_radius - (creep_radius - 30.0))
                factor = max(0.04, min(1.0, factor))
                
                # Tintado orgánico / subterráneo oscuro
                img[px_idx] = int(img[px_idx] * factor * 0.9)
                img[px_idx + 1] = int(img[px_idx + 1] * factor * 0.75)
                img[px_idx + 2] = int(img[px_idx + 2] * factor * 0.85)
            else:
                # Sutil pulso orgánico en el creep (un poco más vivo)
                img[px_idx] = min(255, int(img[px_idx] * 1.05))
                img[px_idx + 1] = min(255, int(img[px_idx + 1] * 0.95))
                img[px_idx + 2] = min(255, int(img[px_idx + 2] * 1.1))

    dest = os.path.join(OUT, "tiles", "boss_cave_floor.png")
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    write_png(dest, W, H, img)
    print(f"Cueva guardada: {dest} ({W}x{H})")

def gen_pillars():
    print("Generando sprites de pilares y escombros...")
    pal = read_wpe(os.path.join(SRC, "TileSet", "badlands.wpe"))
    
    # 1. Pilar intacto (hdrock01)
    g = Grp(os.path.join(SRC, "unit", "thingy", "tileset", "badlands", "hdrock01.grp"))
    W, H, data, cols, rows = grp_to_sheet(g, pal, columns=1)
    dest_pillar = os.path.join(OUT, "sprites", "boss_pillar.png")
    write_png(dest_pillar, W, H, data)
    print(f"Pilar intacto: {dest_pillar} ({W}x{H})")
    
    # 2. Pilar agrietado (con fisuras rojas/doradas por daño de impacto)
    cracked_data = bytearray(data)
    rnd = random.Random(777)
    # Dibujar fisuras y astillado
    for y in range(20, H - 20):
        for x in range(10, W - 10):
            idx = (y * W + x) * 4
            if cracked_data[idx + 3] > 0:
                # Grietas diagonales
                if abs((x * 2 - y + 10) % 23) < 2 or abs((x + y * 1.5 - 60) % 27) < 2:
                    if rnd.random() < 0.85:
                        cracked_data[idx] = 255      # R (brillo de impacto / fisura)
                        cracked_data[idx + 1] = 160  # G
                        cracked_data[idx + 2] = 50   # B
    dest_cracked = os.path.join(OUT, "sprites", "boss_pillar_cracked.png")
    write_png(dest_cracked, W, H, cracked_data)
    print(f"Pilar agrietado: {dest_cracked} ({W}x{H})")
    
    # 3. Escombros de pilar destruido (primer frame de zrubblel)
    g_rubble = Grp(os.path.join(SRC, "unit", "thingy", "zrubblel.grp"))
    Wr, Hr, data_rubble, _, _ = grp_to_sheet(g_rubble, pal, frames=[0], columns=1)
    dest_rubble = os.path.join(OUT, "sprites", "boss_pillar_rubble.png")
    write_png(dest_rubble, Wr, Hr, data_rubble)
    print(f"Escombros: {dest_rubble} ({Wr}x{Hr})")

if __name__ == "__main__":
    gen_cave()
    gen_pillars()
