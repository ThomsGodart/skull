"""Draws the app icon and writes it for every platform.

Run from the project root: `python3 tool/app_icon.py` (needs Pillow).

The icon is the skull and the crown of the Noto Emoji font the app already
ships, in the colours of `lib/theme/tokens.dart`.
"""

import json
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
FONT = ROOT / "assets/fonts/NotoEmoji.ttf"

GOLD = (0xE0, 0xA9, 0x3B)
PARCHMENT = (0xF3, 0xE7, 0xCC)
# The flat background of the Android adaptive icon (values/colors.xml).
NAVY = (0x16, 0x30, 0x4D)
# The radial gradient of the other icons, from the centre to the corners.
NAVY_CENTRE = (0x23, 0x44, 0x6A)
NAVY_CORNER = (0x0F, 0x1E, 0x2F)

# Everything is drawn at this size, then reduced.
MASTER = 2048

# Proportions, as fractions of the skull's width.
CROWN_WIDTH = 0.622
CROWN_RISE = 0.405  # how far the crown's top stands above the skull's top
LIFT = 0.08  # the emblem sits a little above the centre: the crown is light

# Proportions, as fractions of the icon's side.
BORDER = 6 / 192
CORNER_RADIUS = 0.23
SKULL_FRAMED = 0.474  # skull width inside the framed icon
SKULL_ADAPTIVE = 148 / 432  # skull width on the Android foreground layer
SKULL_FULL_BLEED = 0.44  # skull width where the system crops the icon itself
SKULL_MASKABLE = 0.36  # web maskable icons keep only the central 80 %


def _glyph(char, width, colour):
    """The glyph, cropped to its ink and scaled to `width` pixels wide."""
    font = ImageFont.truetype(str(FONT), 1000)
    font.set_variation_by_axes([700])
    mask = Image.new("L", (1600, 1600), 0)
    ImageDraw.Draw(mask).text((100, 100), char, font=font, fill=255)
    mask = mask.crop(mask.getbbox())
    height = round(mask.height * width / mask.width)
    mask = mask.resize((width, height), Image.LANCZOS)
    glyph = Image.new("RGBA", mask.size, colour + (0,))
    glyph.putalpha(mask)
    return glyph


def emblem(side, skull_fraction):
    """The crowned skull, centred on a transparent square of `side` pixels."""
    skull = _glyph("☠", round(side * skull_fraction), PARCHMENT)
    crown = _glyph("\U0001F451", round(skull.width * CROWN_WIDTH), GOLD)
    rise = round(skull.width * CROWN_RISE)
    layer = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    left = (side - skull.width) // 2
    top = (side - skull.height - rise) // 2 - round(skull.width * LIFT)
    layer.alpha_composite(skull, (left, top + rise))
    layer.alpha_composite(crown, ((side - crown.width) // 2, top))
    return layer


def gradient(side):
    """The navy background, lighter in the centre."""
    small = 256
    half = (small - 1) / 2
    corner = (2 * half * half) ** 0.5
    pixels = []
    for y in range(small):
        for x in range(small):
            t = (((x - half) ** 2 + (y - half) ** 2) ** 0.5) / corner
            pixels.append(
                tuple(
                    round(a + (b - a) * t)
                    for a, b in zip(NAVY_CENTRE, NAVY_CORNER)
                )
                + (255,)
            )
    image = Image.new("RGBA", (small, small))
    image.putdata(pixels)
    return image.resize((side, side), Image.BICUBIC)


def framed():
    """A rounded square with a gold border: used where nothing crops it."""
    side = MASTER
    radius = round(side * CORNER_RADIUS)
    border = round(side * BORDER)
    image = Image.new("RGBA", (side, side), GOLD + (255,))
    inner = Image.new("L", (side, side), 0)
    ImageDraw.Draw(inner).rounded_rectangle(
        (border, border, side - 1 - border, side - 1 - border),
        radius - border,
        fill=255,
    )
    image.paste(gradient(side), (0, 0), inner)
    image.alpha_composite(emblem(side, SKULL_FRAMED))
    outer = Image.new("L", (side, side), 0)
    ImageDraw.Draw(outer).rounded_rectangle(
        (0, 0, side - 1, side - 1), radius, fill=255
    )
    image.putalpha(ImageChops.multiply(image.getchannel("A"), outer))
    return image


def full_bleed(skull_fraction):
    """An opaque square, for the systems that cut the icon's shape."""
    image = gradient(MASTER)
    image.alpha_composite(emblem(MASTER, skull_fraction))
    return image.convert("RGB")


def padded(image, fraction):
    """`image` reduced to `fraction` of a transparent canvas of its size."""
    side = image.width
    inner = round(side * fraction)
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    offset = (side - inner) // 2
    canvas.alpha_composite(
        image.resize((inner, inner), Image.LANCZOS), (offset, offset)
    )
    return canvas


def save(image, path, side):
    path = ROOT / path
    path.parent.mkdir(parents=True, exist_ok=True)
    image.resize((side, side), Image.LANCZOS).save(path)


def android(framed_icon):
    res = "android/app/src/main/res"
    foreground = emblem(MASTER, SKULL_ADAPTIVE)
    densities = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
    for density, scale in densities.items():
        folder = f"{res}/mipmap-{density}"
        save(framed_icon, f"{folder}/ic_launcher.png", round(48 * scale))
        save(
            foreground,
            f"{folder}/ic_launcher_foreground.png",
            round(108 * scale),
        )


def ios(square):
    folder = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.loads((ROOT / folder / "Contents.json").read_text())
    for entry in contents["images"]:
        points = float(entry["size"].split("x")[0])
        scale = int(entry["scale"].rstrip("x"))
        save(square, f"{folder}/{entry['filename']}", round(points * scale))


def macos(framed_icon):
    folder = "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    # macOS icons leave a margin around their shape.
    icon = padded(framed_icon, 824 / 1024)
    for side in (16, 32, 64, 128, 256, 512, 1024):
        save(icon, f"{folder}/app_icon_{side}.png", side)


def web(framed_icon):
    maskable = full_bleed(SKULL_MASKABLE)
    save(framed_icon, "web/favicon.png", 32)
    for side in (192, 512):
        save(framed_icon, f"web/icons/Icon-{side}.png", side)
        save(maskable, f"web/icons/Icon-maskable-{side}.png", side)


def windows(framed_icon):
    sizes = [(side, side) for side in (16, 24, 32, 48, 64, 128, 256)]
    framed_icon.resize((256, 256), Image.LANCZOS).save(
        ROOT / "windows/runner/resources/app_icon.ico", sizes=sizes
    )


def main():
    framed_icon = framed()
    android(framed_icon)
    ios(full_bleed(SKULL_FULL_BLEED))
    macos(framed_icon)
    web(framed_icon)
    windows(framed_icon)


if __name__ == "__main__":
    main()
