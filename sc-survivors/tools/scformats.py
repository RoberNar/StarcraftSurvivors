"""
Lectores de formatos clasicos de StarCraft 1 (SD) sin dependencias externas.

- GRP  : sprites paletizados con RLE por fila
- WPE  : paleta de tileset (256 * RGBX)
- PCX  : usado para tunit.pcx (colores de jugador)
- CV5 / VX4EX / VR4 : tiles del terreno
- PNG  : escritor RGBA minimo (zlib + struct)
"""
import struct
import zlib


# ---------------------------------------------------------------- PNG writer
def write_png(path, width, height, rgba):
    """Escribe un PNG RGBA de 8 bits. rgba = width*height*4 bytes."""
    raw = bytearray()
    stride = width * 4
    for y in range(height):
        raw.append(0)  # filtro None
        raw.extend(rgba[y * stride:(y + 1) * stride])

    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


# ---------------------------------------------------------------- Palettes
def read_wpe(path):
    data = open(path, "rb").read()
    return [(data[i * 4], data[i * 4 + 1], data[i * 4 + 2]) for i in range(256)]


def read_pcx_indices(path):
    """Devuelve (width, height, indices) de un PCX de 8 bits."""
    data = open(path, "rb").read()
    xmin, ymin, xmax, ymax = struct.unpack_from("<HHHH", data, 4)
    bpl = struct.unpack_from("<H", data, 66)[0]
    w, h = xmax - xmin + 1, ymax - ymin + 1
    out = bytearray()
    i = 128
    total = bpl * h
    while len(out) < total and i < len(data):
        b = data[i]
        i += 1
        if b >= 0xC0:
            n = b & 0x3F
            v = data[i]
            i += 1
            out.extend([v] * n)
        else:
            out.append(b)
    pixels = bytearray()
    for y in range(h):
        pixels.extend(out[y * bpl:y * bpl + w])
    return w, h, pixels


# ---------------------------------------------------------------- GRP
class Grp:
    def __init__(self, path):
        data = open(path, "rb").read()
        self.frame_count, self.width, self.height = struct.unpack_from("<HHH", data, 0)
        self.frames = []  # (indices, mask) por frame, tamano width*height
        for f in range(self.frame_count):
            xo, yo, fw, fh, off = struct.unpack_from("<BBBBI", data, 6 + f * 8)
            idx = bytearray(self.width * self.height)
            mask = bytearray(self.width * self.height)
            if fh == 0 or fw == 0:
                self.frames.append((idx, mask))
                continue
            first_roff = struct.unpack_from("<H", data, off)[0] if off + 2 <= len(data) else 0
            is_rle = (first_roff == fh * 2) and (off + first_roff < len(data))
            if is_rle:
                for row in range(fh):
                    roff = struct.unpack_from("<H", data, off + row * 2)[0]
                    p = off + roff
                    x = 0
                    base = (yo + row) * self.width + xo
                    while x < fw and p < len(data):
                        c = data[p]
                        p += 1
                        if c & 0x80:
                            x += c & 0x7F
                        elif c & 0x40:
                            n = c & 0x3F
                            if p >= len(data):
                                break
                            v = data[p]
                            p += 1
                            for k in range(n):
                                if base + x + k < len(idx):
                                    idx[base + x + k] = v
                                    mask[base + x + k] = 1
                            x += n
                        else:
                            n = c
                            for k in range(n):
                                if p + k < len(data) and base + x + k < len(idx):
                                    idx[base + x + k] = data[p + k]
                                    mask[base + x + k] = 1
                            p += n
                            x += n
            else:
                # Raw uncompressed
                for row in range(fh):
                    base = (yo + row) * self.width + xo
                    src_p = off + row * fw
                    for x in range(fw):
                        if src_p + x < len(data) and base + x < len(idx):
                            v = data[src_p + x]
                            idx[base + x] = v
                            mask[base + x] = 1
            self.frames.append((idx, mask))


def grp_to_sheet(grp, palette, frames=None, columns=17, remap=None, mode="normal"):
    """
    Genera una hoja de sprites RGBA con celdas de grp.width x grp.height.
    remap: dict indice->indice (colores de jugador).
    mode: 'normal' | 'shadow' (negro semitransparente) | 'glow' (brillo -> alpha).
    """
    if frames is None:
        frames = list(range(grp.frame_count))
    cols = min(columns, len(frames))
    rows = (len(frames) + cols - 1) // cols
    W, H = cols * grp.width, rows * grp.height
    out = bytearray(W * H * 4)
    for n, fi in enumerate(frames):
        idx, mask = grp.frames[fi]
        cx, cy = (n % cols) * grp.width, (n // cols) * grp.height
        for y in range(grp.height):
            for x in range(grp.width):
                o = y * grp.width + x
                if not mask[o]:
                    continue
                d = ((cy + y) * W + cx + x) * 4
                v = idx[o]
                if mode == "shadow":
                    out[d:d + 4] = bytes((0, 0, 0, 130))
                    continue
                if remap and v in remap:
                    v = remap[v]
                r, g, b = palette[v]
                if mode == "glow":
                    out[d:d + 4] = bytes((r, g, b, max(r, g, b)))
                else:
                    out[d:d + 4] = bytes((r, g, b, 255))
    return W, H, out, cols, rows


def player_remap(tunit_path, player):
    """Indices 8..15 del sprite -> colores del jugador segun tunit.pcx."""
    w, h, px = read_pcx_indices(tunit_path)
    return {8 + i: px[player * 8 + i] for i in range(8)}


# ---------------------------------------------------------------- Tileset
class Tileset:
    def __init__(self, base):
        self.palette = read_wpe(base + ".wpe")
        cv5 = open(base + ".cv5", "rb").read()
        self.groups = []
        for g in range(len(cv5) // 52):
            self.groups.append(struct.unpack_from("<16H", cv5, g * 52 + 20))
        self.vx4 = open(base + ".vx4ex", "rb").read()
        self.vr4 = open(base + ".vr4", "rb").read()

    def megatile_rgba(self, mt):
        """Devuelve 32x32 RGBA de un megatile."""
        out = bytearray(32 * 32 * 4)
        for m in range(16):
            v = struct.unpack_from("<I", self.vx4, mt * 64 + m * 4)[0]
            flip = v & 1
            base = (v >> 1) * 64
            mx, my = (m % 4) * 8, (m // 4) * 8
            for y in range(8):
                for x in range(8):
                    c = self.vr4[base + y * 8 + (7 - x if flip else x)]
                    r, g, b = self.palette[c]
                    d = ((my + y) * 32 + mx + x) * 4
                    out[d:d + 4] = bytes((r, g, b, 255))
        return out


def blit(dst, dw, src, sw, sh, dx, dy):
    for y in range(sh):
        s = y * sw * 4
        d = ((dy + y) * dw + dx) * 4
        dst[d:d + sw * 4] = src[s:s + sw * 4]
