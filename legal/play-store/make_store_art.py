"""Regenerate Play Store feature graphic from in-game assets (new bg_cyber).

Icon and screenshots are produced separately:
  - icon_512.png via NovelAI + Pillow resize
  - screenshot_*.png via Godot scenes/store_capture.tscn
"""
from PIL import Image, ImageDraw, ImageFont, ImageEnhance
from pathlib import Path

ASSETS = Path(r"C:\Users\sian\only-nine\godot\assets")
OUT = Path(r"C:\Users\sian\only-nine\legal\play-store")
OUT.mkdir(parents=True, exist_ok=True)
UI = ASSETS / "ui"
UNITS = ASSETS / "sprites" / "units"
MON = ASSETS / "sprites" / "monsters"


def load(p):
    return Image.open(p).convert("RGBA")


def fit(img, size, cover=True):
    tw, th = size
    iw, ih = img.size
    scale = max(tw / iw, th / ih) if cover else min(tw / iw, th / ih)
    nw, nh = max(1, int(iw * scale)), max(1, int(ih * scale))
    img = img.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    canvas.paste(img, ((tw - nw) // 2, (th - nh) // 2), img)
    return canvas


def paste_center(base, overlay, xy, scale=1.0):
    ow = max(1, int(overlay.width * scale))
    oh = max(1, int(overlay.height * scale))
    o = overlay.resize((ow, oh), Image.Resampling.LANCZOS)
    x, y = xy
    base.alpha_composite(o, (int(x - ow / 2), int(y - oh / 2)))


def font(size):
    for name in [
        r"C:\Windows\Fonts\malgunbd.ttf",
        r"C:\Windows\Fonts\malgun.ttf",
        r"C:\Windows\Fonts\segoeuib.ttf",
        r"C:\Windows\Fonts\arial.ttf",
    ]:
        if Path(name).exists():
            return ImageFont.truetype(name, size)
    return ImageFont.load_default()


bg = load(UI / "bg_cyber.png")
prism = load(UNITS / "PRISM_L1.png")
dart = load(UNITS / "DART_L1.png")
spike = load(UNITS / "SPIKE_L1.png")
dragon = load(MON / "DRAGON.png")

# Feature 1024x500 — new sci-fi bg (no crypto)
feat = Image.new("RGBA", (1024, 500), (8, 10, 18, 255))
fb = ImageEnhance.Brightness(fit(bg, (1024, 500))).enhance(0.55)
feat.alpha_composite(fb)
grad = Image.new("RGBA", (1024, 500), (0, 0, 0, 0))
gd = ImageDraw.Draw(grad)
for x in range(560):
    a = int(200 * (1 - x / 560))
    gd.line([(x, 0), (x, 500)], fill=(5, 8, 16, a))
feat.alpha_composite(grad)
paste_center(feat, prism, (720, 260), 0.85)
paste_center(feat, dart, (860, 320), 0.55)
paste_center(feat, spike, (940, 200), 0.5)
paste_center(feat, dragon, (980, 400), 0.35)
fd = ImageDraw.Draw(feat)
fd.text((48, 140), "ONLY NINE", font=font(64), fill=(232, 240, 255, 255))
fd.text((48, 220), "오직 아홉", font=font(42), fill=(56, 189, 248, 255))
fd.text((48, 290), "아홉 유닛 · 세 진영 · 타워디펜스", font=font(26), fill=(180, 190, 210, 255))
feat.save(OUT / "feature_1024x500.png")

print("Wrote feature_1024x500.png", Image.open(OUT / "feature_1024x500.png").size)
