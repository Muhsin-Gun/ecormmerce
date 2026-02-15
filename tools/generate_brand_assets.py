#!/usr/bin/env python3
"""Generate ProMarket splash/icon PNG assets without binary files in git.

Outputs:
- assets/images/splash_static.png
- assets/icons/background.png
- assets/icons/foreground.png
- android/app/src/main/res/drawable-nodpi/splash_static.png
"""

import math
import os
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def save_png(path: Path, width: int, height: int, pixel_fn):
    path.parent.mkdir(parents=True, exist_ok=True)
    raw = bytearray()
    for y in range(height):
        raw.append(0)
        for x in range(width):
            r, g, b, a = pixel_fn(x, y, width, height)
            raw.extend((r, g, b, a))

    def chunk(tag: bytes, data: bytes) -> bytes:
        return (
            struct.pack("!I", len(data))
            + tag
            + data
            + struct.pack("!I", zlib.crc32(tag + data) & 0xFFFFFFFF)
        )

    png = (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack("!2I5B", width, height, 8, 6, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(bytes(raw), 9))
        + chunk(b"IEND", b"")
    )
    path.write_bytes(png)


def bg_gradient(x: int, y: int, w: int, h: int):
    t = y / (h - 1)
    r = int(11 + 70 * t)
    g = int(18 + 35 * t)
    b = int(32 + 115 * t)
    return r, g, b, 255


def fg_icon(x: int, y: int, w: int, h: int):
    cx, cy = w // 2, h // 2
    dx, dy = x - cx, y - cy

    # rounded bag body
    body_w, body_h = 520, 470
    rx, ry = body_w / 2, body_h / 2
    bx = abs(dx) / rx
    by = abs(dy - 40) / ry
    in_body = (bx**4 + by**4) <= 1.0

    # handle arc
    r = math.sqrt(dx * dx + (dy + 125) * (dy + 125))
    in_handle = 165 < r < 205 and dy < -35

    if in_body:
        return 138, 88, 255, 255
    if in_handle:
        return 220, 200, 255, 255
    return 0, 0, 0, 0


def main():
    splash = ROOT / "assets/images/splash_static.png"
    bg = ROOT / "assets/icons/background.png"
    fg = ROOT / "assets/icons/foreground.png"
    android_splash = ROOT / "android/app/src/main/res/drawable-nodpi/splash_static.png"

    save_png(splash, 1024, 1024, bg_gradient)
    save_png(bg, 1024, 1024, bg_gradient)
    save_png(fg, 1024, 1024, fg_icon)
    android_splash.parent.mkdir(parents=True, exist_ok=True)
    android_splash.write_bytes(splash.read_bytes())

    print("Generated assets:")
    print(f"- {splash.relative_to(ROOT)}")
    print(f"- {bg.relative_to(ROOT)}")
    print(f"- {fg.relative_to(ROOT)}")
    print(f"- {android_splash.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
