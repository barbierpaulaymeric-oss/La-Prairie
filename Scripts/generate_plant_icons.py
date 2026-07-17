#!/usr/bin/env python3
"""Générateur d'icônes de plantes pour Jardin Intelligent.

Produit des SVG 512x512 (fond transparent, style minimaliste, palette naturelle)
partageant le langage visuel des icônes paramétriques dessinées dans l'app
(PlantIconView). Utilisé pour les assets marketing/App Store et pour pré-remplir
le catalogue d'icônes. Génération 100 % locale et déterministe : pas d'API externe.

Usage :
    python3 Scripts/generate_plant_icons.py                    # SVG dans App/Resources/PlantIcons
    python3 Scripts/generate_plant_icons.py --png              # + PNG 512x512 (requiert cairosvg)
    python3 Scripts/generate_plant_icons.py --out /tmp/icons   # dossier de sortie personnalisé
"""

from __future__ import annotations

import argparse
import math
from pathlib import Path

SIZE = 512

# Palette imposée par la charte.
LEAF = "#2E8B57"
OLIVE = "#556B2F"
LIGHT = "#90EE90"
BEIGE = "#F5F5DC"
WOOD = "#DEB887"
TOMATO = "#C25B4E"
CARROT = "#DE9152"
AUBERGINE = "#6E5A8E"
BERRY = "#C96A7B"
LILAC = "#9C8ABF"


def pt(x: float, y: float) -> str:
    """Coordonnées normalisées (0..1) -> espace SVG avec marge de 8 %."""
    margin = SIZE * 0.08
    span = SIZE - 2 * margin
    return f"{margin + x * span:.1f},{margin + y * span:.1f}"


def leaf_path(base: tuple[float, float], tip: tuple[float, float], width: float, color: str,
              opacity: float = 1.0) -> str:
    """Feuille : deux quadratiques entre base et pointe, bombées de part et d'autre."""
    bx, by = base
    tx, ty = tip
    mx, my = (bx + tx) / 2, (by + ty) / 2
    dx, dy = tx - bx, ty - by
    norm = math.hypot(dx, dy) or 1e-6
    ox, oy = -dy / norm * width, dx / norm * width
    d = (f"M {pt(bx, by)} Q {pt(mx + ox, my + oy)} {pt(tx, ty)} "
         f"Q {pt(mx - ox, my - oy)} {pt(bx, by)} Z")
    return f'<path d="{d}" fill="{color}" fill-opacity="{opacity}"/>'


def stem(a: tuple[float, float], b: tuple[float, float], color: str = OLIVE,
         width: float = 0.045) -> str:
    return (f'<line x1="{pt(*a).split(",")[0]}" y1="{pt(*a).split(",")[1]}" '
            f'x2="{pt(*b).split(",")[0]}" y2="{pt(*b).split(",")[1]}" '
            f'stroke="{color}" stroke-width="{width * SIZE:.1f}" stroke-linecap="round"/>')


def ellipse(cx: float, cy: float, rx: float, ry: float, color: str, opacity: float = 1.0) -> str:
    x, y = pt(cx, cy).split(",")
    return (f'<ellipse cx="{x}" cy="{y}" rx="{rx * SIZE:.1f}" ry="{ry * SIZE:.1f}" '
            f'fill="{color}" fill-opacity="{opacity}"/>')


# ---------------------------------------------------------------------------
# Icônes (mêmes silhouettes que PlantIconView côté Swift)

def icon_sprout() -> list[str]:
    return [
        stem((0.5, 0.95), (0.5, 0.45)),
        leaf_path((0.5, 0.55), (0.18, 0.25), 0.16, LEAF),
        leaf_path((0.5, 0.5), (0.85, 0.15), 0.18, LIGHT),
    ]


def icon_basilic() -> list[str]:
    return [
        stem((0.5, 0.95), (0.5, 0.35)),
        leaf_path((0.5, 0.75), (0.14, 0.55), 0.17, LEAF),
        leaf_path((0.5, 0.75), (0.86, 0.55), 0.17, LEAF),
        leaf_path((0.5, 0.45), (0.22, 0.18), 0.16, LIGHT),
        leaf_path((0.5, 0.45), (0.78, 0.18), 0.16, LIGHT),
        leaf_path((0.5, 0.4), (0.5, 0.05), 0.14, LEAF),
    ]


def icon_menthe() -> list[str]:
    parts = [stem((0.5, 0.95), (0.5, 0.2))]
    for i, y in enumerate((0.72, 0.52, 0.32)):
        spread = 0.36 - i * 0.06
        c1, c2 = (LEAF, OLIVE) if i % 2 == 0 else (OLIVE, LEAF)
        parts.append(leaf_path((0.5, y), (0.5 - spread, y - 0.16), 0.13, c1))
        parts.append(leaf_path((0.5, y), (0.5 + spread, y - 0.16), 0.13, c2))
    parts.append(leaf_path((0.5, 0.24), (0.5, 0.02), 0.11, LIGHT))
    return parts


def icon_sprig(color: str) -> list[str]:
    parts = [stem((0.35, 0.95), (0.62, 0.08), OLIVE, 0.04)]
    for step in range(7):
        t = 0.15 + step * 0.11
        bx = 0.35 + (0.62 - 0.35) * (1 - t)
        by = 0.95 - t * 0.87 + 0.05
        parts.append(leaf_path((bx, by), (bx - 0.2, by - 0.1), 0.045, color))
        parts.append(leaf_path((bx, by), (bx + 0.16, by - 0.14), 0.045, color, 0.8))
    return parts


def icon_lavande() -> list[str]:
    parts = [
        stem((0.5, 0.95), (0.5, 0.45), LEAF),
        leaf_path((0.5, 0.85), (0.28, 0.62), 0.06, LEAF),
        leaf_path((0.5, 0.8), (0.72, 0.58), 0.06, LEAF),
    ]
    for row in range(4):
        y = 0.42 - row * 0.1
        w = 0.16 - row * 0.03
        color = LILAC if row % 2 == 0 else AUBERGINE
        parts.append(ellipse(0.5, y, w, 0.048, color, 0.9))
    return parts


def icon_tomate() -> list[str]:
    parts = [
        ellipse(0.5, 0.61, 0.36 * 0.84, 0.31 * 0.84, TOMATO),
        ellipse(0.42, 0.52, 0.12, 0.09, "#FFFFFF", 0.14),
    ]
    for angle in (-0.9, -0.3, 0.3, 0.9):
        tx = 0.5 + math.cos(angle - math.pi / 2) * 0.2
        ty = 0.33 + math.sin(angle - math.pi / 2) * 0.16 + 0.12
        parts.append(leaf_path((0.5, 0.34), (tx, ty), 0.05, OLIVE))
    parts.append(stem((0.5, 0.3), (0.5, 0.12), OLIVE, 0.05))
    return parts


def icon_courgette() -> list[str]:
    d = (f"M {pt(0.16, 0.82)} Q {pt(0.2, 0.25)} {pt(0.82, 0.3)} "
         f"Q {pt(0.95, 0.85)} {pt(0.3, 0.92)} Z")
    stripe = f"M {pt(0.26, 0.78)} Q {pt(0.35, 0.42)} {pt(0.74, 0.4)}"
    return [
        f'<path d="{d}" fill="{LEAF}"/>',
        stem((0.82, 0.3), (0.92, 0.16), OLIVE, 0.05),
        f'<path d="{stripe}" fill="none" stroke="{LIGHT}" stroke-opacity="0.7" '
        f'stroke-width="{0.035 * SIZE:.1f}" stroke-linecap="round"/>',
    ]


def icon_concombre() -> list[str]:
    x, y = pt(0.2, 0.18).split(",")
    tendril = f"M {pt(0.46, 0.5)} Q {pt(0.72, 0.38)} {pt(0.8, 0.55)}"
    return [
        f'<rect x="{x}" y="{y}" width="{0.26 * SIZE:.1f}" height="{0.72 * SIZE:.1f}" '
        f'rx="{0.13 * SIZE:.1f}" fill="{LEAF}"/>',
        leaf_path((0.42, 0.3), (0.82, 0.12), 0.16, LIGHT),
        f'<path d="{tendril}" fill="none" stroke="{OLIVE}" '
        f'stroke-width="{0.03 * SIZE:.1f}" stroke-linecap="round"/>',
    ]


def icon_carotte() -> list[str]:
    d = (f"M {pt(0.34, 0.35)} Q {pt(0.36, 0.75)} {pt(0.5, 0.95)} "
         f"Q {pt(0.64, 0.75)} {pt(0.66, 0.35)} Z")
    return [
        f'<path d="{d}" fill="{CARROT}"/>',
        leaf_path((0.5, 0.36), (0.26, 0.06), 0.1, LEAF),
        leaf_path((0.5, 0.36), (0.5, 0.02), 0.09, LIGHT),
        leaf_path((0.5, 0.36), (0.74, 0.06), 0.1, LEAF),
    ]


def icon_radis() -> list[str]:
    return [
        ellipse(0.5, 0.63, 0.22, 0.21, BERRY),
        stem((0.5, 0.84), (0.5, 0.95), BERRY, 0.03),
        leaf_path((0.5, 0.45), (0.32, 0.08), 0.11, LEAF),
        leaf_path((0.5, 0.45), (0.68, 0.08), 0.11, LIGHT),
    ]


def icon_laitue() -> list[str]:
    parts = []
    for i, angle in enumerate((-1.2, -0.6, 0.0, 0.6, 1.2)):
        tx = 0.5 + math.sin(angle) * 0.4
        ty = 0.9 - (0.75 - abs(angle) * 0.12)
        color = LIGHT if i % 2 == 0 else LEAF
        parts.append(leaf_path((0.5, 0.9), (tx, ty), 0.16, color))
    parts.append(leaf_path((0.5, 0.9), (0.5, 0.3), 0.14, BEIGE))
    return parts


def icon_epinard() -> list[str]:
    parts = []
    for i, angle in enumerate((-0.8, 0.0, 0.8)):
        tx = 0.5 + math.sin(angle) * 0.32
        color = LEAF if i == 1 else OLIVE
        parts.append(leaf_path((0.5, 0.92), (tx, 0.12), 0.18, color))
    return parts


def icon_persil() -> list[str]:
    parts = []
    for angle in (-0.5, 0.0, 0.5):
        tx = 0.5 + math.sin(angle) * 0.3
        ty = 0.35
        parts.append(stem((0.5, 0.95), (tx, ty), LEAF, 0.03))
        for ox, oy in ((-0.12, -0.1), (0.12, -0.1), (0.0, -0.18)):
            parts.append(ellipse(tx + ox, ty + oy, 0.09, 0.09, LEAF, 0.9))
    return parts


def icon_ciboulette() -> list[str]:
    parts = []
    for i, x in enumerate((0.3, 0.42, 0.54, 0.66)):
        bend = -0.06 if i % 2 == 0 else 0.06
        top_y = 0.1 + i * 0.04
        d = f"M {pt(x, 0.95)} Q {pt(x + bend * 2, 0.5)} {pt(x + bend, top_y)}"
        color = LEAF if i % 2 == 0 else OLIVE
        parts.append(f'<path d="{d}" fill="none" stroke="{color}" '
                     f'stroke-width="{0.05 * SIZE:.1f}" stroke-linecap="round"/>')
    parts.append(ellipse(0.3, 0.1, 0.06, 0.06, LILAC))
    return parts


def icon_fraise() -> list[str]:
    d = (f"M {pt(0.2, 0.4)} Q {pt(0.22, 0.85)} {pt(0.5, 0.95)} "
         f"Q {pt(0.78, 0.85)} {pt(0.8, 0.4)} Q {pt(0.5, 0.28)} {pt(0.2, 0.4)} Z")
    parts = [f'<path d="{d}" fill="{TOMATO}"/>']
    for sx, sy in ((0.38, 0.55), (0.55, 0.62), (0.45, 0.75), (0.62, 0.5)):
        parts.append(ellipse(sx, sy, 0.02, 0.028, BEIGE))
    parts += [
        leaf_path((0.5, 0.38), (0.3, 0.22), 0.08, LEAF),
        leaf_path((0.5, 0.38), (0.7, 0.22), 0.08, LEAF),
        stem((0.5, 0.36), (0.5, 0.14), OLIVE, 0.04),
    ]
    return parts


def icon_framboise() -> list[str]:
    centers = ((0.4, 0.5), (0.6, 0.5), (0.34, 0.66), (0.5, 0.62), (0.66, 0.66),
               (0.42, 0.8), (0.58, 0.8), (0.5, 0.92))
    parts = [ellipse(cx, cy, 0.09, 0.09, BERRY) for cx, cy in centers]
    parts += [
        leaf_path((0.5, 0.42), (0.28, 0.16), 0.09, LEAF),
        leaf_path((0.5, 0.42), (0.72, 0.16), 0.09, LEAF),
    ]
    return parts


def icon_arbre() -> list[str]:
    trunk = (f"M {pt(0.44, 0.95)} L {pt(0.47, 0.5)} L {pt(0.53, 0.5)} "
             f"L {pt(0.56, 0.95)} Z")
    return [
        f'<path d="{trunk}" fill="{WOOD}"/>',
        ellipse(0.5, 0.34, 0.35, 0.26, LEAF),
        ellipse(0.46, 0.16, 0.18, 0.14, LIGHT, 0.7),
        ellipse(0.645, 0.345, 0.045, 0.045, TOMATO),
    ]


def icon_haricot() -> list[str]:
    parts = []
    for i, off in enumerate((-0.14, 0.0, 0.14)):
        d = (f"M {pt(0.3 + off, 0.2)} Q {pt(0.28 + off, 0.65)} {pt(0.55 + off, 0.9)} "
             f"Q {pt(0.5 + off, 0.6)} {pt(0.36 + off, 0.22)} Z")
        parts.append(f'<path d="{d}" fill="{LEAF if i == 1 else OLIVE}"/>')
    parts.append(stem((0.32, 0.18), (0.62, 0.12), OLIVE, 0.035))
    return parts


def icon_poivron() -> list[str]:
    x, y = pt(0.28, 0.28).split(",")
    groove = f"M {pt(0.44, 0.34)} Q {pt(0.4, 0.6)} {pt(0.44, 0.84)}"
    return [
        f'<rect x="{x}" y="{y}" width="{0.44 * SIZE:.1f}" height="{0.62 * SIZE:.1f}" '
        f'rx="{0.18 * SIZE:.1f}" fill="{TOMATO}"/>',
        leaf_path((0.5, 0.3), (0.66, 0.14), 0.07, LEAF),
        stem((0.5, 0.28), (0.48, 0.1), OLIVE, 0.05),
        f'<path d="{groove}" fill="none" stroke="#FFFFFF" stroke-opacity="0.15" '
        f'stroke-width="{0.03 * SIZE:.1f}" stroke-linecap="round"/>',
    ]


def icon_aubergine() -> list[str]:
    d = (f"M {pt(0.58, 0.22)} Q {pt(0.85, 0.4)} {pt(0.72, 0.75)} "
         f"Q {pt(0.6, 1.0)} {pt(0.35, 0.9)} Q {pt(0.2, 0.45)} {pt(0.58, 0.22)} Z")
    return [
        f'<path d="{d}" fill="{AUBERGINE}"/>',
        leaf_path((0.58, 0.24), (0.4, 0.12), 0.08, LEAF),
        stem((0.6, 0.22), (0.66, 0.08), OLIVE, 0.045),
    ]


def icon_fleur() -> list[str]:
    parts = [
        stem((0.5, 0.95), (0.5, 0.5), LEAF),
        leaf_path((0.5, 0.8), (0.3, 0.66), 0.08, LEAF),
    ]
    for k in range(6):
        angle = k / 6 * 2 * math.pi
        tx = 0.5 + math.cos(angle) * 0.22
        ty = 0.32 + math.sin(angle) * 0.22
        parts.append(leaf_path((0.5, 0.32), (tx, ty), 0.09, LILAC))
    parts.append(ellipse(0.5, 0.32, 0.08, 0.08, CARROT))
    return parts


ICONS: dict[str, list[str]] = {
    "basilic": icon_basilic(),
    "menthe": icon_menthe(),
    "romarin": icon_sprig(OLIVE),
    "thym": icon_sprig(LEAF),
    "persil": icon_persil(),
    "ciboulette": icon_ciboulette(),
    "sauge": icon_basilic(),
    "origan": icon_menthe(),
    "lavande": icon_lavande(),
    "tomate": icon_tomate(),
    "courgette": icon_courgette(),
    "concombre": icon_concombre(),
    "carotte": icon_carotte(),
    "radis": icon_radis(),
    "laitue": icon_laitue(),
    "epinard": icon_epinard(),
    "haricot-vert": icon_haricot(),
    "poivron": icon_poivron(),
    "aubergine": icon_aubergine(),
    "fraisier": icon_fraise(),
    "framboisier": icon_framboise(),
    "pommier": icon_arbre(),
    "oeillet-d-inde": icon_fleur(),
    "plante-generique": icon_sprout(),
}


def svg_document(parts: list[str], background: str | None = None) -> str:
    body = "\n  ".join(parts)
    bg = (f'<rect width="{SIZE}" height="{SIZE}" rx="{SIZE * 0.22:.0f}" fill="{background}"/>\n  '
          if background else "")
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{SIZE}" height="{SIZE}" '
            f'viewBox="0 0 {SIZE} {SIZE}">\n  {bg}{body}\n</svg>\n')


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", default="App/Resources/PlantIcons",
                        help="dossier de sortie (défaut : App/Resources/PlantIcons)")
    parser.add_argument("--png", action="store_true",
                        help="générer aussi des PNG 512x512 (requiert cairosvg)")
    args = parser.parse_args()

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)

    for name, parts in ICONS.items():
        (out / f"{name}.svg").write_text(svg_document(parts), encoding="utf-8")

    # Icône d'app : pousse sur fond beige arrondi (à exporter en PNG 1024 pour l'App Store).
    (out / "appicon.svg").write_text(svg_document(icon_sprout(), background=BEIGE),
                                     encoding="utf-8")

    print(f"{len(ICONS) + 1} SVG écrits dans {out}/")

    if args.png:
        try:
            import cairosvg
        except ImportError:
            raise SystemExit("cairosvg manquant : pip install cairosvg")
        for svg_file in out.glob("*.svg"):
            size = 1024 if svg_file.stem == "appicon" else SIZE
            cairosvg.svg2png(url=str(svg_file),
                             write_to=str(svg_file.with_suffix(".png")),
                             output_width=size, output_height=size)
        print("PNG générés.")


if __name__ == "__main__":
    main()
