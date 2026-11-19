"""Render the draft Workshop mark and wordmark at a 160 px pixel grid."""
from pathlib import Path

from PIL import Image, ImageDraw


GLYPHS = {
    "A": ("01110", "11011", "11011", "11111", "11011", "11011", "11011"),
    "C": ("01111", "11000", "11000", "11000", "11000", "11000", "01111"),
    "E": ("11111", "11000", "11000", "11110", "11000", "11000", "11111"),
    "G": ("01111", "11000", "11000", "11011", "11011", "11011", "01111"),
    "K": ("11011", "11011", "11110", "11100", "11110", "11011", "11011"),
    "P": ("11110", "11011", "11011", "11110", "11000", "11000", "11000"),
    "R": ("11110", "11011", "11011", "11110", "11100", "11010", "11011"),
    "S": ("01111", "11000", "11000", "01110", "00011", "00011", "11110"),
}


def word(draw: ImageDraw.ImageDraw, text: str, y: int, size: int) -> None:
    left = (160 - (6 * len(text) - 1) * size) // 2
    for index, character in enumerate(text):
        for row, pattern in enumerate(GLYPHS[character]):
            for column, pixel in enumerate(pattern):
                if pixel == "1":
                    x = left + (6 * index + column) * size
                    top = y + row * size
                    draw.rectangle((x + 1, top + 2, x + size, top + size + 1), fill="#122324")
                    draw.rectangle((x, top, x + size - 1, top + size - 1), fill="#f3dfaa")


def main() -> None:
    image = Image.new("RGB", (160, 160), "#294546")
    draw = ImageDraw.Draw(image)
    draw.rectangle((0, 156, 159, 159), fill="#233b3b")
    draw.rectangle((5, 5, 154, 154), outline="#44615b")
    word(draw, "CARE", 14, 4)
    word(draw, "PACKAGES", 46, 3)

    draw.polygon(((42, 131), (91, 151), (124, 140), (136, 128), (97, 112)), fill="#1d3333")
    draw.polygon(((32, 98), (84, 78), (129, 95), (130, 127), (81, 148), (32, 129)), fill="#152d2c")
    draw.polygon(((36, 101), (83, 120), (83, 144), (36, 126)), fill="#aa7042")
    draw.polygon(((83, 120), (126, 99), (126, 125), (83, 144)), fill="#84563a")
    draw.polygon(((36, 99), (84, 81), (125, 96), (83, 117)), fill="#cb9656")
    draw.line(((40, 100), (83, 115), (119, 98)), fill="#e8b976", width=2)
    draw.line(((65, 89), (105, 105), (105, 134)), fill="#e9cb8a", width=4)
    draw.line(((56, 106), (99, 87)), fill="#f0d39a", width=3)
    draw.polygon(((65, 94), (90, 100), (83, 115), (58, 107)), fill="#f1daa1")
    draw.line(((68, 100), (82, 103)), fill="#624838", width=2)
    draw.line(((65, 104), (78, 107)), fill="#86614d", width=2)
    draw.rectangle((68, 97, 69, 98), fill="#9e6c47")

    image.resize((960, 960), Image.Resampling.NEAREST).save(Path(__file__).with_name("care-cover.png"))


if __name__ == "__main__":
    main()
