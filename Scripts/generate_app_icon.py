#!/usr/bin/env python3
"""Icône de l'app Jardin Intelligent — génération 100 % locale, zéro dépendance.

Moteur de rendu vectoriel maison : remplissage de polygones par scanline avec
dégradés verticaux par forme, composition alpha (ombres, halos),
suréchantillonnage 3× ; encodeur PNG sur zlib (bibliothèque standard).

Design : pousse stylisée à tige courbée et effilée, feuilles à deux tons avec
reflet et nervure, collines en couches pour la profondeur, butte de terre,
soleil au halo doux. Plein cadre 1024×1024 sans transparence (iOS applique
lui-même le masque arrondi — ne pas pré-arrondir).

Usage :
    python3 Scripts/generate_app_icon.py
    → App/Resources/Assets.xcassets/AppIcon.appiconset/appicon-1024.png
"""

from __future__ import annotations

import math
import struct
import zlib
from pathlib import Path

SIZE = 1024
S = 3
W = H = SIZE * S

Color = tuple[int, int, int]


def hx(code: str) -> Color:
    code = code.lstrip("#")
    return (int(code[0:2], 16), int(code[2:4], 16), int(code[4:6], 16))


# --- Géométrie ---------------------------------------------------------------

def ellipse(cx: float, cy: float, rx: float, ry: float, segments: int = 180) -> list[tuple[float, float]]:
    return [(cx + rx * math.cos(2 * math.pi * i / segments),
             cy + ry * math.sin(2 * math.pi * i / segments)) for i in range(segments)]


def quad_point(p0, c, p1, t: float) -> tuple[float, float]:
    return ((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * c[0] + t ** 2 * p1[0],
            (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * c[1] + t ** 2 * p1[1])


def flatten_quad(p0, c, p1, segments: int = 56) -> list[tuple[float, float]]:
    return [quad_point(p0, c, p1, i / segments) for i in range(segments + 1)]


def leaf(base, tip, width: float) -> list[tuple[float, float]]:
    """Feuille : deux quadratiques bombées de part et d'autre de l'axe base→pointe."""
    mx, my = (base[0] + tip[0]) / 2, (base[1] + tip[1]) / 2
    dx, dy = tip[0] - base[0], tip[1] - base[1]
    norm = math.hypot(dx, dy) or 1e-6
    ox, oy = -dy / norm * width, dx / norm * width
    side1 = flatten_quad(base, (mx + ox, my + oy), tip)
    side2 = flatten_quad(tip, (mx - ox, my - oy), base)
    return side1 + side2[1:]


def tapered_quad_stroke(p0, c, p1, w0: float, w1: float,
                        segments: int = 56) -> list[tuple[float, float]]:
    """Ruban le long d'une quadratique, largeur interpolée w0 (base) → w1 (pointe)."""
    center = flatten_quad(p0, c, p1, segments)
    left, right = [], []
    for i, (x, y) in enumerate(center):
        t = i / segments
        # tangente approchée
        j0, j1 = max(0, i - 1), min(segments, i + 1)
        dx = center[j1][0] - center[j0][0]
        dy = center[j1][1] - center[j0][1]
        norm = math.hypot(dx, dy) or 1e-6
        half = (w0 + (w1 - w0) * t) / 2
        nx, ny = -dy / norm * half, dx / norm * half
        left.append((x + nx, y + ny))
        right.append((x - nx, y - ny))
    return left + right[::-1]


# --- Rasterisation -----------------------------------------------------------

def fill_polygon(rows: list[bytearray], polygon: list[tuple[float, float]],
                 color_top: Color, color_bottom: Color | None = None,
                 alpha: float = 1.0) -> None:
    """Remplissage scanline : dégradé vertical sur la hauteur de la forme,
    composition alpha optionnelle (lecture-mélange-écriture par pixel)."""
    pts = [(x * S, y * S) for x, y in polygon]
    ymin = max(0, int(min(p[1] for p in pts)))
    ymax = min(H - 1, int(max(p[1] for p in pts)) + 1)
    span_h = max(ymax - ymin, 1)
    bottom = color_bottom or color_top
    n = len(pts)

    for y in range(ymin, ymax + 1):
        yc = y + 0.5
        xs = []
        for i in range(n):
            x1, y1 = pts[i]
            x2, y2 = pts[(i + 1) % n]
            if (y1 <= yc < y2) or (y2 <= yc < y1):
                xs.append(x1 + (yc - y1) * (x2 - x1) / (y2 - y1))
        if not xs:
            continue
        xs.sort()
        t = (y - ymin) / span_h
        r = int(color_top[0] + (bottom[0] - color_top[0]) * t)
        g = int(color_top[1] + (bottom[1] - color_top[1]) * t)
        b = int(color_top[2] + (bottom[2] - color_top[2]) * t)
        row = rows[y]
        for j in range(0, len(xs) - 1, 2):
            x0 = max(0, int(math.ceil(xs[j] - 0.5)))
            x1 = min(W - 1, int(math.floor(xs[j + 1] - 0.5)))
            if x1 < x0:
                continue
            if alpha >= 1.0:
                row[x0 * 3:(x1 + 1) * 3] = bytes((r, g, b)) * (x1 - x0 + 1)
            else:
                inv = 1 - alpha
                for x in range(x0 * 3, (x1 + 1) * 3, 3):
                    row[x] = int(row[x] * inv + r * alpha)
                    row[x + 1] = int(row[x + 1] * inv + g * alpha)
                    row[x + 2] = int(row[x + 2] * inv + b * alpha)


# --- Composition -------------------------------------------------------------

def render() -> list[bytearray]:
    # Ciel : dégradé crème → vert d'eau
    top, bottom = hx("FBF7E9"), hx("E2EBD1")
    rows = []
    for y in range(H):
        t = y / (H - 1)
        r = int(top[0] + (bottom[0] - top[0]) * t)
        g = int(top[1] + (bottom[1] - top[1]) * t)
        b = int(top[2] + (bottom[2] - top[2]) * t)
        rows.append(bytearray(bytes((r, g, b)) * W))

    # Soleil : double halo doux puis disque
    fill_polygon(rows, ellipse(818, 196, 150, 150), hx("F0E3AE"), alpha=0.22)
    fill_polygon(rows, ellipse(818, 196, 116, 116), hx("F0E3AE"), alpha=0.30)
    fill_polygon(rows, ellipse(818, 196, 84, 84), hx("F2E6B4"), hx("EEDD9E"))

    # Collines en couches (profondeur)
    fill_polygon(rows, ellipse(210, 1225, 980, 485), hx("CCD9A8"), hx("BFCF97"))
    fill_polygon(rows, ellipse(905, 1265, 1010, 505), hx("AFC585"), hx("9DB574"))

    # Butte de terre : liseré sombre puis masse en dégradé
    fill_polygon(rows, ellipse(512, 1290, 880, 478), hx("C09361"), hx("B3854F"))
    fill_polygon(rows, ellipse(512, 1315, 880, 478), hx("E3BF8F"), hx("D2A671"))

    # Ombre portée de la pousse sur la terre
    fill_polygon(rows, ellipse(524, 872, 168, 30), hx("4A5A28"), alpha=0.16)

    # Tige courbée, effilée vers le haut
    stem = dict(p0=(516, 874), c=(462, 652), p1=(524, 462))
    fill_polygon(rows, tapered_quad_stroke(stem["p0"], stem["c"], stem["p1"], 42, 22),
                 hx("647D38"), hx("495C26"))

    # Petit bourgeon au sommet
    fill_polygon(rows, leaf((522, 478), (556, 384), 36), hx("7FC96F"), hx("63B258"))

    # Feuille gauche (vert profond) : corps, reflet, nervure
    lbase, ltip = (497, 606), (288, 340)
    fill_polygon(rows, leaf(lbase, ltip, 152), hx("389A61"), hx("23744A"))
    fill_polygon(rows, leaf((484, 580), (330, 386), 58), hx("4FAE74"), hx("368A57"))
    fill_polygon(rows, leaf((491, 592), (322, 378), 6.5), hx("A9D8BA"))

    # Feuille droite (vert clair) : corps, reflet, nervure
    rbase, rtip = (523, 546), (752, 294)
    fill_polygon(rows, leaf(rbase, rtip, 160), hx("9FEE9C"), hx("77D178"))
    fill_polygon(rows, leaf((542, 522), (704, 336), 62), hx("C2F7BF"), hx("A2E7A0"))
    fill_polygon(rows, leaf((534, 532), (712, 328), 6.5), hx("5FAF66"))

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

    header = struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0)
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
