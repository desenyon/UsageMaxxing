#!/usr/bin/env python3
from pathlib import Path
from PIL import Image, ImageDraw
import subprocess

ROOT = Path(__file__).resolve().parents[1]
ICONSET = ROOT / "UsageMaxxing" / "Resources" / "AppIcon.iconset"
ICNS = ROOT / "UsageMaxxing" / "Resources" / "AppIcon.icns"
PNG = ROOT / "docs" / "assets" / "usage-maxxing-logo.png"


def draw_icon(size: int) -> Image.Image:
    scale = size / 128
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    def p(value: float) -> float:
        return value * scale

    draw.rounded_rectangle([0, 0, size, size], radius=p(28), fill=(16, 17, 20, 255))
    box = [p(30), p(44), p(98), p(112)]
    width = max(1, int(p(12)))
    draw.arc(box, start=180, end=360, fill=(44, 49, 56, 255), width=width)
    draw.arc(box, start=180, end=305, fill=(72, 217, 138, 255), width=width)
    draw.arc(box, start=305, end=360, fill=(242, 193, 78, 255), width=width)
    draw.line([p(64), p(78), p(88), p(54)], fill=(242, 95, 92, 255), width=max(1, int(p(8))))
    draw.ellipse([p(57), p(71), p(71), p(85)], fill=(244, 247, 251, 255))
    draw.rounded_rectangle([p(38), p(91), p(90), p(99)], radius=p(4), fill=(244, 247, 251, 184))
    draw.polygon(
        [
            (p(103), p(27)), (p(106), p(34)), (p(113), p(37)), (p(106), p(40)),
            (p(103), p(47)), (p(100), p(40)), (p(93), p(37)), (p(100), p(34)),
        ],
        fill=(244, 247, 251, 255),
    )
    return image


def main() -> None:
    ICONSET.mkdir(parents=True, exist_ok=True)
    PNG.parent.mkdir(parents=True, exist_ok=True)
    draw_icon(1024).save(PNG)

    sizes = [
        (16, "icon_16x16.png"),
        (32, "icon_16x16@2x.png"),
        (32, "icon_32x32.png"),
        (64, "icon_32x32@2x.png"),
        (128, "icon_128x128.png"),
        (256, "icon_128x128@2x.png"),
        (256, "icon_256x256.png"),
        (512, "icon_256x256@2x.png"),
        (512, "icon_512x512.png"),
        (1024, "icon_512x512@2x.png"),
    ]
    for pixels, name in sizes:
        draw_icon(pixels).save(ICONSET / name)

    subprocess.run(["iconutil", "-c", "icns", str(ICONSET), "-o", str(ICNS)], check=True)


if __name__ == "__main__":
    main()
