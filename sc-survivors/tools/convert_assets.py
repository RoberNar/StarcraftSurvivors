"""
Convierte los assets clasicos (SD) de StarCraft 1 a PNG/WAV para Godot.

Uso:
    python convert_assets.py [ruta_assets_sc] [ruta_salida]

Por defecto lee  C:/Users/toffe/Desktop/SCsurvivors
y escribe en   ../assets/skins/sd

La estructura 'skins/<nombre>' esta pensada para agregar en el futuro
los skins HD (Remastered) y Carbot con los mismos nombres de archivo.
"""
import os
import shutil
import struct
import sys
import random

from scformats import (Grp, grp_to_sheet, write_png, read_wpe, read_pcx_indices,
                       player_remap, Tileset, blit)

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = sys.argv[1] if len(sys.argv) > 1 else r"C:\Users\toffe\Desktop\SCsurvivors"
OUT = sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, "..", "assets", "skins", "sd")

TILESET = "badlands"
PLAYER_MARINE = 1   # 0 rojo, 1 azul, 2 verde azulado, 3 violeta, 4 naranja, 5 marron, 6 blanco, 7 amarillo
PLAYER_ZERG = 0


def src(*p):
    return os.path.join(SRC, *p)


def out(*p):
    path = os.path.join(OUT, *p)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    return path


PAL = read_wpe(src("TileSet", TILESET + ".wpe"))
TUNIT = src("game", "tunit.pcx")


# ------------------------------------------------------------------ sprites
def sheet(rel, name, player=None, mode="normal", frames=None, columns=17):
    g = Grp(src(*rel.split("/")))
    remap = player_remap(TUNIT, player) if player is not None else None
    W, H, data, cols, rows = grp_to_sheet(g, PAL, frames=frames, columns=columns, remap=remap, mode=mode)
    write_png(out("sprites", name + ".png"), W, H, data)
    print(f"  {name:18s} {g.frame_count:4d} frames  celda {g.width}x{g.height}  hoja {cols}x{rows}")


def convert_sprites():
    print("Sprites:")
    sheet("unit/terran/marine.grp", "marine", PLAYER_MARINE)
    sheet("unit/terran/marine.grp", "marine_shadow", mode="shadow")
    sheet("unit/terran/tmadeath.grp", "marine_remains", PLAYER_MARINE, columns=8)
    sheet("unit/zerg/zergling.grp", "zergling", PLAYER_ZERG)
    sheet("unit/zerg/zzeshad.grp", "zergling_shadow", mode="shadow")
    sheet("unit/zerg/zzedeath.grp", "zergling_remains", PLAYER_ZERG, columns=8)
    sheet("unit/thingy/blood01.grp", "blood_hit", columns=15)
    sheet("game/icons.grp", "resource_icons", columns=8)
    sheet("unit/wirefram/wirefram.grp", "wire_marine", frames=[0], columns=1)
    sheet("unit/wirefram/wirefram.grp", "wire_civilian", frames=[15], columns=1)


# ------------------------------------------------------------------ terreno
def convert_ground(size=64, seed=1998):
    """Hornea un suelo de size x size megatiles (32px) con variantes de tierra."""
    print("Terreno:")
    t = Tileset(src("TileSet", TILESET))
    rnd = random.Random(seed)

    def variants(groups):
        v = []
        for g in groups:
            v += [mt for mt in t.groups[g] if mt != 0]
        return v

    dirt = variants([2, 3])
    rocky = variants([12, 13])
    cache = {}
    W = H = size * 32
    img = bytearray(W * H * 4)
    for ty in range(size):
        for tx in range(size):
            pool = rocky if rnd.random() < 0.06 else dirt
            mt = rnd.choice(pool)
            if mt not in cache:
                cache[mt] = t.megatile_rgba(mt)
            blit(img, W, cache[mt], 32, 32, tx * 32, ty * 32)
    write_png(out("tiles", "ground.png"), W, H, img)
    print(f"  ground.png {W}x{H}  ({len(dirt)} variantes de tierra, {len(rocky)} rocosas)")


# ------------------------------------------------------------------ DDS sin comprimir
def dds_to_png(path, dest):
    d = open(path, "rb").read()
    h, w = struct.unpack_from("<II", d, 12)
    bits = struct.unpack_from("<I", d, 88)[0]
    rm, gm, bm, am = struct.unpack_from("<IIII", d, 92)
    if bits != 32:
        raise ValueError(f"{path}: solo DDS de 32 bits sin comprimir")

    def shift(m):
        s = 0
        while m and not (m >> s) & 1:
            s += 1
        return s

    rs, gs, bs, as_ = shift(rm), shift(gm), shift(bm), shift(am)
    rgba = bytearray(w * h * 4)
    for i in range(w * h):
        px = struct.unpack_from("<I", d, 128 + i * 4)[0]
        rgba[i * 4] = (px & rm) >> rs
        rgba[i * 4 + 1] = (px & gm) >> gs
        rgba[i * 4 + 2] = (px & bm) >> bs
        rgba[i * 4 + 3] = ((px & am) >> as_) if am else 255
    write_png(dest, w, h, rgba)
    print(f"  {os.path.basename(dest)} {w}x{h}")


def convert_ui():
    print("UI:")
    dds_to_png(src("SD", "game", "tconsole.DDS"), out("ui", "tconsole.png"))
    dds_to_png(src("SD", "glue", "title", "title.DDS"), out("ui", "title.png"))
    # cursor clasico
    g = Grp(src("cursor", "arrow.grp"))
    W, H, data, c, r = grp_to_sheet(g, PAL, frames=[0], columns=1)
    write_png(out("ui", "cursor.png"), W, H, data)
    print(f"  cursor.png {W}x{H}")


# ------------------------------------------------------------------ fuente FNT -> BMFont
def convert_font(name="font16", out_name="sc_font16"):
    print("Fuente:")
    d = open(src("SD", "font", name + ".fnt"), "rb").read()
    assert d[:4] == b"FONT"
    lo, hi, mw, mh = d[4], d[5], d[6], d[7]
    offs = struct.unpack_from("<%dI" % (hi - lo + 1), d, 8)
    shade = {1: 255, 2: 205, 3: 155, 4: 105, 5: 80, 6: 60, 7: 40}
    glyphs = {}
    for i, o in enumerate(offs):
        ch = lo + i
        if o == 0:
            continue
        w, h, xo, yo = d[o], d[o + 1], d[o + 2], d[o + 3]
        cw, chh = xo + w, mh
        px = bytearray(cw * chh * 4)
        p, pos = o + 4, 0
        while pos < w * h:
            b = d[p]
            p += 1
            pos += b >> 3
            if pos >= w * h:
                break
            c = b & 7
            x, y = pos % w + xo, pos // w + yo
            if 0 <= y < chh:
                g = shade.get(c, 255)
                k = (y * cw + x) * 4
                px[k:k + 4] = bytes((g, g, g, 255))
            pos += 1
        glyphs[ch] = (cw, chh, px, w)
    # atlas
    cols = 16
    cellw, cellh = mw + 2, mh + 2
    rows = (len(glyphs) + cols - 1) // cols
    AW, AH = cols * cellw, rows * cellh
    atlas = bytearray(AW * AH * 4)
    lines = []
    for n, (ch, (cw, chh, px, w)) in enumerate(sorted(glyphs.items())):
        x, y = (n % cols) * cellw, (n // cols) * cellh
        blit(atlas, AW, px, cw, chh, x, y)
        lines.append(f"char id={ch} x={x} y={y} width={cw} height={chh} xoffset=0 yoffset=0 "
                     f"xadvance={cw + 1} page=0 chnl=15")
    # espacio
    if 32 not in glyphs:
        lines.append(f"char id=32 x=0 y=0 width=0 height=0 xoffset=0 yoffset=0 xadvance={max(4, mw // 3)} page=0 chnl=15")
    write_png(out("fonts", out_name + ".png"), AW, AH, atlas)
    with open(out("fonts", out_name + ".fnt"), "w", encoding="ascii") as f:
        f.write(f'info face="{out_name}" size={mh} bold=0 italic=0 charset="" unicode=0 '
                f'stretchH=100 smooth=0 aa=0 padding=0,0,0,0 spacing=0,0\n')
        f.write(f"common lineHeight={mh} base={mh - 4} scaleW={AW} scaleH={AH} pages=1 packed=0\n")
        f.write(f'page id=0 file="{out_name}.png"\n')
        f.write(f"chars count={len(lines)}\n")
        f.write("\n".join(lines) + "\n")
    print(f"  {out_name}.fnt ({len(lines)} glifos)")


# ------------------------------------------------------------------ audio
AUDIO = {
    "music/terran1.wav": ("SD", "music", "terran1.wav"),
    "music/tdefeat.wav": ("SD", "music", "tdefeat.wav"),
    "sfx/marine_fire.wav": ("sound", "bullet", "tmafir00.wav"),
    "sfx/marine_death0.wav": ("sound", "terran", "marine", "tmadth00.wav"),
    "sfx/marine_death1.wav": ("sound", "terran", "marine", "tmadth01.wav"),
    "sfx/marine_ready.wav": ("sound", "terran", "marine", "tmardy00.wav"),
    "sfx/marine_stim0.wav": ("sound", "terran", "marine", "tmasti00.wav"),
    "sfx/marine_stim1.wav": ("sound", "terran", "marine", "tmasti01.wav"),
    "sfx/zergling_death.wav": ("sound", "zerg", "zergling", "zzedth00.wav"),
    "sfx/youlose.wav": ("sound", "misc", "youlose.wav"),
}


def convert_audio():
    print("Audio:")
    for dst, parts in AUDIO.items():
        s = src(*parts)
        if os.path.exists(s):
            shutil.copyfile(s, out(*dst.split("/")))
            print("  " + dst)
        else:
            print("  (falta) " + s)


if __name__ == "__main__":
    print(f"Origen: {SRC}\nDestino: {os.path.abspath(OUT)}\n")
    convert_sprites()
    convert_ui()
    convert_font()
    convert_audio()
    convert_ground()
    print("\nListo.")
