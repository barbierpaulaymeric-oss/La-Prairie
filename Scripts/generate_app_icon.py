#!/usr/bin/env python3
"""Icône de l'app Jardin Intelligent — génération 100 % locale, zéro dépendance.

Rendu vectoriel (remplissage de polygones par scanline, suréchantillonnage 3×)
et encodeur PNG maison (zlib de la bibliothèque standard). Produit le PNG
1024×1024 plein cadre attendu par le catalogue d'assets (iOS applique lui-même
le masque arrondi — ne pas pré-arrondir, pas de transparence).

Usage :
    python3 Scripts/generate_app_icon.py
    → App/Resources/Assets.xcassets/AppIcon.appiconset/appicon-1024.png
"""

from __future__ import annotations

import math
import struct
import zlib
from pathlib import Path

SIZE = 1024          # taille finale
S = 3                # facteur de suréchantillonnage (anti-crénelage)
W = H = SIZE * S

# Palette de la charte
BG_TOP = (0xF7, 0xF3, 0xE1)
BG_BOTTOM = (0xE6, 0xED, 0xD3)
SUN = (0xF3, 0xEB, 0xC6)
SOIL_DARK = (0xC6, 0x9A, 0x66)
SOIL = (0xDE, 0xB8, 0x87)
STEM = (0x55, 0x6B, 0x2F)
LEAF_DARK = (0x2E, 0x8B, 0x57)
LEAF_LIGHT = (0x90, 0xEE, 0x90)
VEIN_ON_DARK = (0x9E, 0xCD, 0xAE)
VEIN_ON_LIGHT = (0x63, 0xB2, 0x6E)


# --- Géométrie (coordonnées dans l'espace 1024, mises à l'échelle au rendu) ---

def ellipse(cx: float, cy: float, rx: float, ry: float, segments: int = 160) -> list[tuple[float, float]]:
    return [(cx + rx * math.cos(2 * math.pi * i / segments),
             cy + ry * math.sin(2 * math.pi * i / segments)) for i in range(segments)]


def flatten_quad(p0, c, p1, segments: int = 48) -> list[tuple[float, float]]:
    points = []
    for i in range(segments + 1):
        t = i / segments
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * c[0] + t ** 2 * p1[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * c[1] + t ** 2 * p1[1]
        points.append((x, y))
    return points


def leaf(base, tip, width: float) -> list[tuple[float, float]]:
    """Feuille : deux quadratiques bombées de part et d'autre de l'axe base→pointe."""
    mx, my = (base[0] + tip[0]) / 2, (base[1] + tip[1]) / 2
    dx, dy = tip[0] - base[0], tip[1] - base[1]
    norm = math.hypot(dx, dy) or 1e-6
    ox, oy = -dy / norm * width, dx / norm * width
    side1 = flatten_quad(base, (mx + ox, my + oy), tip)
    side2 = flatten_quad(tip, (mx - ox, my - oy), base)
    return side1 + side2[1:]


def thick_line(a, b, width: float) -> list[tuple[float, float]]:
    """Segment épais à bouts arrondis (rectangle + demi-cercles approchés)."""
    dx, dy = b[0] - a[0], b[1] - a[1]
    norm = math.hypot(dx, dy) or 1e-6
    ux, uy = dx / norm, dy / norm
    ox, oy = -uy * width / 2, ux * width / 2
    points: list[tuple[float, float]] = []
    for i in range(17):  # demi-cercle côté b
        ang = math.atan2(oy, ox) + math.pi * i / 16
        points.append((b[0] + math.cos(ang) * width / 2, b[1] + math.sin(ang) * width / 2))
    for i in range(17):  # demi-cercle côté a
        ang = math.atan2(-oy, -ox) + math.pi * i / 16
        points.append((a[0] + math.cos(ang) * width / 2, a[1] + math.sin(ang) * width / 2))
    return points


# --- Rasterisation ---

def fill_polygon(rows: list[bytearray], polygon: list[tuple[float, float]], color: tuple[int, int, int]) -> None:
    pts = [(x * S, y * S) for x, y in polygon]
    ymin = max(0, int(min(p[1] for p in pts)))
    ymax = min(H - 1, int(max(p[1] for p in pts)) + 1)
    n = len(pts)
    color_bytes = bytes(color)
    for y in range(ymin, ymax + 1):
        yc = y + 0.5
        xs = []
        for i in range(n):
            x1, y1 = pts[i]
            x2, y2 = pts[(i + 1) % n]
            if (y1 <= yc < y2) or (y2 <= yc < y1):
                xs.append(x1 + (yc - y1) * (x2 - x1) / (y2 - y1))
        xs.sort()
        row = rows[y]
        for j in range(0, len(xs) - 1, 2):
            x0 = max(0, int(math.ceil(xs[j] - 0.5)))
            x1 = min(W - 1, int(math.floor(xs[j + 1] - 0.5)))
            if x1 >= x0:
                row[x0 * 3:(x1 + 1) * 3] = color_bytes * (x1 - x0 + 1)


def render() -> list[bytearray]:
    # Fond : dégradé vertical
    rows = []
    for y in range(H):
        t = y / (H - 1)
        r = int(BG_TOP[0] + (BG_BOTTOM[0] - BG_TOP[0]) * t)
        g = int(BG_TOP[1] + (BG_BOTTOM[1] - BG_TOP[1]) * t)
        b = int(BG_TOP[2] + (BG_BOTTOM[2] - BG_TOP[2]) * t)
        rows.append(bytearray(bytes((r, g, b)) * W))

    # Soleil discret
    fill_polygon(rows, ellipse(800, 210, 96, 96), SUN)

    # Sol : liseré sombre puis butte de terre
    fill_polygon(rows, ellipse(512, 1215, 800, 420), SOIL_DARK)
    fill_polygon(rows, ellipse(512, 1238, 800, 420), SOIL)

    # Pousse emblème (même langage que les icônes in-app)
    fill_polygon(rows, thick_line((512, 862), (512, 470), 36), STEM)
    fill_polygon(rows, leaf((512, 600), (296, 336), 150), LEAF_DARK)
    fill_polygon(rows, leaf((512, 545), (736, 296), 158), LEAF_LIGHT)

    # Nervures
    fill_polygon(rows, leaf((498, 582), (330, 372), 7), VEIN_ON_DARK)
    fill_polygon(rows, leaf((524, 528), (700, 330), 7), VEIN_ON_LIGHT)

    return rows


def downsample(rows: list[bytearray]) -> list[bytearray]:
    out = []
    area = S * S
    for oy in range(SIZE):
        out_row = bytearray(SIZE * 3)
        src = [rows[oy * S + k] for k in range(S)]
        for ox in range(SIZE):
            x0 = ox * S * 3
            r = g = b = 0
            for row in src:
                for k in range(S):
                    idx = x0 + k * 3
                    r += row[idx]
                    g += row[idx + 1]
                    b += row[idx + 2]
            base = ox * 3
            out_row[base] = r // area
            out_row[base + 1] = g // area
            out_row[base + 2] = b // area
        out.append(out_row)
    return out


def write_png(path: Path, size: int, rows: list[bytearray]) -> None:
    raw = b"".join(b"\x00" + bytes(row) for row in rows)

    def chunk(tag: bytes, data: bytes) -> bytes:
        payload = tag + data
        return struct.pack(">I", len(data)) + payload + struct.pack(">I", zlib.crc32(payload) & 0xFFFFFFFF)

    header = struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0)  # RGB 8 bits
    png = (b"\x89PNG\r\n\x1a\n"
           + chunk(b"IHDR", header)
           + chunk(b"IDAT", zlib.compress(raw, 9))
           + chunk(b"IEND", b""))
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(png)


def main() -> None:
    out = Path("App/Resources/Assets.xcassets/AppIcon.appiconset/appicon-1024.png")
    rows = downsample(render())
    write_png(out, SIZE, rows)
    print(f"Icône écrite : {out} ({out.stat().st_size // 1024} Ko)")


if __name__ == "__main__":
    main()
