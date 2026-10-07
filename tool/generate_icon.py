"""Draws the YT Playlist app icon and writes every Android resource for it.

Run from the project root:  python tool/generate_icon.py

The artwork is a white line-art folder (the same shape as the folder icon in the
app) with a red play triangle inside, on a near-black tile.
Needs Pillow (pip install pillow).
"""

import math
import os

from PIL import Image, ImageDraw

BG = (17, 17, 17, 255)  # #111111, the app's dark background
WHITE = (255, 255, 255, 255)
RED = (229, 50, 45, 255)  # #E5322D, the app's accent

RES = os.path.join("android", "app", "src", "main", "res")
SUPER = 4  # draw 4x bigger, then scale down for smooth edges

DENSITIES = {
    # name: (adaptive layer px, legacy launcher px)
    "mdpi": (108, 48),
    "hdpi": (162, 72),
    "xhdpi": (216, 96),
    "xxhdpi": (324, 144),
    "xxxhdpi": (432, 192),
}


def arc(cx, cy, r, start_deg, end_deg, steps=12):
    return [
        (
            cx + r * math.cos(math.radians(a)),
            cy + r * math.sin(math.radians(a)),
        )
        for a in [start_deg + (end_deg - start_deg) * i / steps for i in range(steps + 1)]
    ]


def folder_points():
    """The folder outline on a 24x24 grid (same path as the app's folder icon)."""
    pts = []
    pts += arc(5, 7, 2, 180, 270)  # top-left corner
    pts += [(9, 5), (11, 7), (19, 7)]  # tab, then the top edge
    pts += arc(19, 9, 2, 270, 360)  # top-right corner
    pts += arc(19, 17, 2, 0, 90)  # bottom-right corner
    pts += arc(5, 17, 2, 90, 180)  # bottom-left corner
    pts.append(pts[0])
    return pts


TRIANGLE = [(10.4, 10.4), (10.4, 16.0), (15.4, 13.2)]  # play triangle, 24 grid


def draw_mark(size, scale_frac, folder_color, triangle_color, stroke=1.9):
    """The folder + triangle on a transparent square of `size` px.

    `scale_frac` is the width of the folder as a fraction of the square.
    """
    big = size * SUPER
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    k = big * scale_frac / 18.0  # the folder is 18 grid units wide
    ox = big / 2 - 12 * k  # the grid centre (12, 12) goes to the middle
    oy = big / 2 - 12 * k

    def pt(p):
        return (ox + p[0] * k, oy + p[1] * k)

    width = max(1, round(stroke * k))
    folder = [pt(p) for p in folder_points()]
    d.line(folder, fill=folder_color, width=width, joint="curve")
    for x, y in (folder[0], folder[-1]):  # round the ends of the line
        d.ellipse([x - width / 2, y - width / 2, x + width / 2, y + width / 2], fill=folder_color)

    tri = [pt(p) for p in TRIANGLE]
    d.polygon(tri, fill=triangle_color)
    edge = max(1, round(0.7 * k))  # a thin outline rounds the triangle's corners
    d.line(tri + [tri[0]], fill=triangle_color, width=edge, joint="curve")
    for x, y in tri:
        d.ellipse([x - edge / 2, y - edge / 2, x + edge / 2, y + edge / 2], fill=triangle_color)

    return img.resize((size, size), Image.LANCZOS)


def rounded_tile(size, radius_frac=0.22):
    big = size * SUPER
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    ImageDraw.Draw(img).rounded_rectangle(
        [0, 0, big - 1, big - 1], radius=int(big * radius_frac), fill=BG
    )
    return img.resize((size, size), Image.LANCZOS)


def save(img, *parts):
    path = os.path.join(RES, *parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)


def write(text, *parts):
    path = os.path.join(RES, *parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def main():
    for name, (layer_px, legacy_px) in DENSITIES.items():
        # Adaptive icon (Android 8+): the system masks it, so the artwork stays
        # inside the middle 66% of the layer.
        save(
            draw_mark(layer_px, 0.50, WHITE, RED),
            f"drawable-{name}",
            "ic_launcher_foreground.png",
        )
        # Themed icon (Android 13+): one flat colour, the system recolours it.
        save(
            draw_mark(layer_px, 0.50, WHITE, WHITE),
            f"drawable-{name}",
            "ic_launcher_monochrome.png",
        )
        # Older Android: a finished rounded tile.
        tile = rounded_tile(legacy_px)
        tile.alpha_composite(draw_mark(legacy_px, 0.62, WHITE, RED))
        save(tile, f"mipmap-{name}", "ic_launcher.png")

    write(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<resources>\n"
        '    <color name="ic_launcher_background">#111111</color>\n'
        "</resources>\n",
        "values",
        "ic_launcher_background.xml",
    )
    write(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@drawable/ic_launcher_foreground"/>\n'
        '    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>\n'
        "</adaptive-icon>\n",
        "mipmap-anydpi-v26",
        "ic_launcher.xml",
    )

    # A big preview for the docs.
    preview = rounded_tile(512)
    preview.alpha_composite(draw_mark(512, 0.62, WHITE, RED))
    os.makedirs("docs", exist_ok=True)
    preview.save(os.path.join("docs", "app_icon.png"))
    print("Icon written.")


if __name__ == "__main__":
    main()
