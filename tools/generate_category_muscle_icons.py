from pathlib import Path

from PIL import Image, ImageDraw


CANVAS = 256
SCALE = 4
BODY = (214, 218, 228, 255)
BODY_SHADE = (186, 191, 203, 255)
HIGHLIGHT = (255, 107, 53, 255)
HIGHLIGHT_SOFT = (255, 145, 104, 230)


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "GymTracker" / "Assets.xcassets"


def up(value: float) -> int:
    return int(round(value * SCALE))


def box(x1: float, y1: float, x2: float, y2: float) -> tuple[int, int, int, int]:
    return up(x1), up(y1), up(x2), up(y2)


def point(x: float, y: float) -> tuple[int, int]:
    return up(x), up(y)


def front_body(draw: ImageDraw.ImageDraw) -> None:
    draw.ellipse(box(101, 12, 155, 66), fill=BODY)
    draw.rounded_rectangle(box(116, 58, 140, 82), radius=up(8), fill=BODY)
    draw.rounded_rectangle(box(84, 78, 172, 164), radius=up(28), fill=BODY)
    draw.rounded_rectangle(box(98, 148, 158, 210), radius=up(18), fill=BODY)
    draw.rounded_rectangle(box(58, 84, 86, 160), radius=up(13), fill=BODY)
    draw.rounded_rectangle(box(170, 84, 198, 160), radius=up(13), fill=BODY)
    draw.rounded_rectangle(box(50, 148, 78, 226), radius=up(13), fill=BODY)
    draw.rounded_rectangle(box(178, 148, 206, 226), radius=up(13), fill=BODY)
    draw.rounded_rectangle(box(98, 204, 126, 252), radius=up(14), fill=BODY)
    draw.rounded_rectangle(box(130, 204, 158, 252), radius=up(14), fill=BODY)

    # Central shading to keep the silhouette from feeling flat.
    draw.rounded_rectangle(box(118, 84, 138, 208), radius=up(10), fill=BODY_SHADE)


def back_body(draw: ImageDraw.ImageDraw) -> None:
    draw.ellipse(box(101, 12, 155, 66), fill=BODY)
    draw.rounded_rectangle(box(116, 58, 140, 82), radius=up(8), fill=BODY)
    draw.rounded_rectangle(box(82, 78, 174, 168), radius=up(30), fill=BODY)
    draw.rounded_rectangle(box(100, 148, 156, 212), radius=up(18), fill=BODY)
    draw.rounded_rectangle(box(58, 84, 86, 160), radius=up(13), fill=BODY)
    draw.rounded_rectangle(box(170, 84, 198, 160), radius=up(13), fill=BODY)
    draw.rounded_rectangle(box(50, 148, 78, 226), radius=up(13), fill=BODY)
    draw.rounded_rectangle(box(178, 148, 206, 226), radius=up(13), fill=BODY)
    draw.rounded_rectangle(box(98, 204, 126, 252), radius=up(14), fill=BODY)
    draw.rounded_rectangle(box(130, 204, 158, 252), radius=up(14), fill=BODY)

    draw.rounded_rectangle(box(120, 82, 136, 212), radius=up(8), fill=BODY_SHADE)


def chest(draw: ImageDraw.ImageDraw) -> None:
    draw.rounded_rectangle(box(92, 94, 126, 126), radius=up(12), fill=HIGHLIGHT)
    draw.rounded_rectangle(box(130, 94, 164, 126), radius=up(12), fill=HIGHLIGHT)
    draw.rounded_rectangle(box(96, 84, 160, 102), radius=up(10), fill=HIGHLIGHT_SOFT)


def shoulders(draw: ImageDraw.ImageDraw) -> None:
    draw.ellipse(box(68, 78, 106, 118), fill=HIGHLIGHT)
    draw.ellipse(box(150, 78, 188, 118), fill=HIGHLIGHT)
    draw.rounded_rectangle(box(98, 78, 158, 100), radius=up(10), fill=HIGHLIGHT_SOFT)


def arms(draw: ImageDraw.ImageDraw) -> None:
    draw.rounded_rectangle(box(58, 88, 86, 162), radius=up(13), fill=HIGHLIGHT)
    draw.rounded_rectangle(box(170, 88, 198, 162), radius=up(13), fill=HIGHLIGHT)
    draw.rounded_rectangle(box(50, 150, 78, 224), radius=up(13), fill=HIGHLIGHT_SOFT)
    draw.rounded_rectangle(box(178, 150, 206, 224), radius=up(13), fill=HIGHLIGHT_SOFT)


def core(draw: ImageDraw.ImageDraw) -> None:
    draw.polygon(
        [point(96, 116), point(112, 104), point(112, 178), point(98, 188), point(88, 152)],
        fill=HIGHLIGHT_SOFT,
    )
    draw.polygon(
        [point(160, 116), point(144, 104), point(144, 178), point(158, 188), point(168, 152)],
        fill=HIGHLIGHT_SOFT,
    )
    for row in range(3):
        y = 116 + row * 22
        draw.rounded_rectangle(box(116, y, 127, y + 16), radius=up(5), fill=HIGHLIGHT)
        draw.rounded_rectangle(box(129, y, 140, y + 16), radius=up(5), fill=HIGHLIGHT)


def legs(draw: ImageDraw.ImageDraw) -> None:
    draw.rounded_rectangle(box(98, 202, 126, 252), radius=up(14), fill=HIGHLIGHT)
    draw.rounded_rectangle(box(130, 202, 158, 252), radius=up(14), fill=HIGHLIGHT)
    draw.rounded_rectangle(box(98, 174, 126, 204), radius=up(14), fill=HIGHLIGHT_SOFT)
    draw.rounded_rectangle(box(130, 174, 158, 204), radius=up(14), fill=HIGHLIGHT_SOFT)


def back(draw: ImageDraw.ImageDraw) -> None:
    draw.polygon(
        [point(108, 82), point(148, 82), point(160, 110), point(96, 110)],
        fill=HIGHLIGHT_SOFT,
    )
    draw.polygon(
        [point(94, 108), point(118, 118), point(120, 182), point(98, 194), point(78, 150)],
        fill=HIGHLIGHT,
    )
    draw.polygon(
        [point(162, 108), point(138, 118), point(136, 182), point(158, 194), point(178, 150)],
        fill=HIGHLIGHT,
    )
    draw.ellipse(box(70, 82, 102, 114), fill=HIGHLIGHT_SOFT)
    draw.ellipse(box(154, 82, 186, 114), fill=HIGHLIGHT_SOFT)


def render_category(name: str) -> Image.Image:
    canvas = Image.new("RGBA", (CANVAS * SCALE, CANVAS * SCALE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)

    if name == "back":
        back_body(draw)
        back(draw)
    else:
        front_body(draw)

        if name == "chest":
            chest(draw)
        elif name == "legs":
            legs(draw)
        elif name == "arms":
            arms(draw)
        elif name == "shoulders":
            shoulders(draw)
        elif name == "core":
            core(draw)
        elif name == "fullBody":
            shoulders(draw)
            chest(draw)
            arms(draw)
            core(draw)
            legs(draw)

    return canvas.resize((CANVAS, CANVAS), Image.Resampling.LANCZOS)


def save_category(name: str, filename: str) -> None:
    image = render_category(name)
    image.save(ASSETS / filename, "PNG")


def main() -> None:
    save_category("chest", "CategoryChest.imageset/category-chest.png")
    save_category("back", "CategoryBack.imageset/category-back.png")
    save_category("legs", "CategoryLegs.imageset/category-legs.png")
    save_category("arms", "CategoryArms.imageset/category-arms.png")
    save_category("shoulders", "CategoryShoulders.imageset/category-shoulders.png")
    save_category("core", "CategoryCore.imageset/category-core.png")
    save_category("fullBody", "CategoryFullBody.imageset/category-full-body.png")


if __name__ == "__main__":
    main()
