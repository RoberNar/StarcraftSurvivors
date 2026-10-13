"""Genera la mascara de caminabilidad de la base Terran desde los datos reales
de StarCraft (scenario.chk + platform.cv5/vf4) y la exporta como rectangulos
de colision fusionados (JSON) para Godot."""
import struct, json
from collections import deque
from PIL import Image, ImageDraw

CHK = r'C:\Users\toffe\Desktop\SCsurvivors\SD\campaign\EXPTerran\Terran02\staredit\scenario.chk'
CV5 = r'C:\Users\toffe\Desktop\SCsurvivors\TileSet\platform.cv5'
VF4 = r'C:\Users\toffe\Desktop\SCsurvivors\TileSet\platform.vf4'
X0, Y0, TW, TH = 108, 76, 60, 36
SPAWN = (750, 600)
OUT_JSON = 'assets/skins/sd/tiles/terran_base_collision.json'


def read_chk_section(data, name):
    i = 0
    while i < len(data) - 8:
        n = data[i:i + 4]
        ln = struct.unpack('<i', data[i + 4:i + 8])[0]
        if n == name:
            return data[i + 8:i + 8 + ln]
        i += 8 + max(ln, 0)
    return None


data = open(CHK, 'rb').read()
mw, mh = struct.unpack('<HH', read_chk_section(data, b'DIM ')[:4])
mtxm = read_chk_section(data, b'MTXM')
tiles = struct.unpack(f'<{len(mtxm)//2}H', mtxm)
cv5 = open(CV5, 'rb').read()
vf4 = open(VF4, 'rb').read()

W, H = TW * 4, TH * 4  # minitiles de 8x8
walk = [[False] * W for _ in range(H)]
for ty in range(TH):
    for tx in range(TW):
        t = tiles[(Y0 + ty) * mw + (X0 + tx)]
        g, s = t >> 4, t & 15
        off = g * 52 + 20 + s * 2
        mega = struct.unpack('<H', cv5[off:off + 2])[0]
        flags = struct.unpack('<16H', vf4[mega * 32:mega * 32 + 32])
        for my in range(4):
            for mx in range(4):
                walk[ty * 4 + my][tx * 4 + mx] = bool(flags[my * 4 + mx] & 1)

# Solo la componente conectada mas grande (la plataforma principal)
reach = [[False] * W for _ in range(H)]
seen = [[False] * W for _ in range(H)]
best = []
for y0 in range(H):
    for x0 in range(W):
        if walk[y0][x0] and not seen[y0][x0]:
            comp = [(x0, y0)]; seen[y0][x0] = True; q = deque(comp)
            while q:
                x, y = q.popleft()
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < W and 0 <= ny < H and walk[ny][nx] and not seen[ny][nx]:
                        seen[ny][nx] = True; q.append((nx, ny)); comp.append((nx, ny))
            if len(comp) > len(best):
                best = comp
for x, y in best:
    reach[y][x] = True

# Celdas solidas relevantes: a <=3 celdas de una caminable (borde grueso)
solid = [[False] * W for _ in range(H)]
for y in range(H):
    for x in range(W):
        if reach[y][x]:
            continue
        near = False
        for dy in range(-3, 4):
            for dx in range(-3, 4):
                yy, xx = y + dy, x + dx
                if 0 <= yy < H and 0 <= xx < W and reach[yy][xx]:
                    near = True; break
            if near: break
        solid[y][x] = near

# Fusion voraz en rectangulos
used = [[False] * W for _ in range(H)]
rects = []
for y in range(H):
    x = 0
    while x < W:
        if solid[y][x] and not used[y][x]:
            w = 0
            while x + w < W and solid[y][x + w] and not used[y][x + w]:
                w += 1
            h = 1
            while y + h < H and all(solid[y + h][x + k] and not used[y + h][x + k] for k in range(w)):
                h += 1
            for yy in range(y, y + h):
                for xx in range(x, x + w):
                    used[yy][xx] = True
            rects.append([x * 8, y * 8, w * 8, h * 8])
            x += w
        else:
            x += 1

json.dump({'size': [W * 8, H * 8], 'rects': rects}, open(OUT_JSON, 'w'))
print('walkable cells:', sum(map(sum, reach)), 'rects:', len(rects))

im = Image.open('assets/skins/sd/tiles/terran_base_floor.png').convert('RGB')
ov = Image.new('RGBA', im.size, (0, 0, 0, 0))
d = ImageDraw.Draw(ov)
for x, y, w, h in rects:
    d.rectangle([x, y, x + w - 1, y + h - 1], fill=(255, 0, 0, 90))
im = Image.alpha_composite(im.convert('RGBA'), ov)
im.resize((960, 576)).save('scratch/collision_preview.png')
