#!/usr/bin/env python3
"""Render Storm the dragon companion as a PNG poster (mirrors storm.svg)."""
from PIL import Image, ImageDraw, ImageFont, ImageFilter

W, H = 760, 580
OUT = ".claude/dragon/storm.png"
MONO = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"
SANS = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
SANS_I = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"

FIRE = [(0.0, (255, 243, 176)), (0.35, (255, 176, 0)),
        (0.70, (255, 106, 0)), (1.0, (214, 31, 31))]

DRAGON = [
    "              \\||/",
    "              |  @___oo",
    "    /\\  /\\   / (__,,,,|",
    "   ) /^\\) ^\\/ _)",
    "   )   /^\\/   _)",
    "   )   _ /  / _)",
    "   /\\  )/\\/ ||  | )_)",
    "  <  >      |(,,) )__)",
    "   ||      /    \\)___)\\",
    "   | \\____(      )___) )___",
    "    \\______(_______;;; __;;;",
]


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def fire_color(t):
    t = max(0.0, min(1.0, t))
    for i in range(len(FIRE) - 1):
        o0, c0 = FIRE[i]
        o1, c1 = FIRE[i + 1]
        if o0 <= t <= o1:
            return lerp(c0, c1, (t - o0) / (o1 - o0) if o1 > o0 else 0)
    return FIRE[-1][1]


def fire_band(y0, y1):
    """Full-size RGB image whose color follows the fire gradient over [y0,y1]."""
    band = Image.new("RGB", (1, H))
    px = band.load()
    for y in range(H):
        t = (y - y0) / (y1 - y0) if y1 > y0 else 0.0
        px[0, y] = fire_color(t)
    return band.resize((W, H))


def stamp(base, mask, y0, y1):
    """Composite fire-colored + glowing text (given its alpha mask) onto base."""
    glow = mask.filter(ImageFilter.GaussianBlur(4))
    orange = Image.new("RGB", (W, H), (255, 106, 0))
    base.paste(orange, (0, 0), glow.point(lambda v: int(v * 0.6)))
    base.paste(fire_band(y0, y1), (0, 0), mask)


def tracked(d, cx, baseline, text, font, tracking):
    widths = [font.getlength(ch) for ch in text]
    total = sum(widths) + tracking * (len(text) - 1)
    x = cx - total / 2
    for ch, w in zip(text, widths):
        d.text((x, baseline), ch, font=font, fill=255, anchor="ls")
        x += w + tracking


# --- background ---
base = Image.new("RGB", (W, H), (13, 15, 20))
glowL = Image.radial_gradient("L").resize((W, H))
base = Image.composite(Image.new("RGB", (W, H), (74, 40, 12)),
                       base, glowL.point(lambda v: int((255 - v) * 0.55)))
bd = ImageDraw.Draw(base)
bd.rounded_rectangle([6, 6, W - 7, H - 7], radius=22, outline=(128, 60, 18), width=2)

# --- title: STORM ---
title_font = ImageFont.truetype(SANS, 58)
m = Image.new("L", (W, H), 0)
tracked(ImageDraw.Draw(m), W // 2, 96, "STORM", title_font, 12)
stamp(base, m, 50, 110)

# --- subtitle ---
sd = ImageDraw.Draw(base)
tracked_sub = "DRAGON · COMPANION"
ssfont = ImageFont.truetype(SANS, 14)
# tracked subtitle in muted grey
mw = [ssfont.getlength(c) for c in tracked_sub]
tot = sum(mw) + 5 * (len(tracked_sub) - 1)
x = W / 2 - tot / 2
for c, w in zip(tracked_sub, mw):
    sd.text((x, 120), c, font=ssfont, fill=(154, 160, 170), anchor="ls")
    x += w + 5

# --- dragon art ---
mono = ImageFont.truetype(MONO, 22)
dm = Image.new("L", (W, H), 0)
dd = ImageDraw.Draw(dm)
start_y, pitch, left_x = 175, 27, 196
for i, line in enumerate(DRAGON):
    dd.text((left_x, start_y + i * pitch), line, font=mono, fill=255, anchor="ls")
stamp(base, dm, start_y - 18, start_y + (len(DRAGON) - 1) * pitch)

# --- tagline ---
tag_font = ImageFont.truetype(SANS_I, 18)
ImageDraw.Draw(base).text((W // 2, 540), "“your code burns bright”",
                          font=tag_font, fill=(255, 174, 92), anchor="ms")

# --- rounded corners ---
base = base.convert("RGBA")
corner = Image.new("L", (W, H), 0)
ImageDraw.Draw(corner).rounded_rectangle([0, 0, W - 1, H - 1], radius=26, fill=255)
base.putalpha(corner)
base.save(OUT)
print("wrote", OUT, base.size)
