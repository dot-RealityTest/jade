#!/usr/bin/env python3

from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

from PIL import Image


def is_black_matte(red: int, green: int, blue: int, alpha: int, tolerance: int) -> bool:
    if alpha < 128:
        return False
    return red <= tolerance and green <= tolerance and blue <= tolerance


def strip_black_matte(path: Path, tolerance: int = 12) -> int:
    image = Image.open(path).convert("RGBA")
    width, height = image.size
    pixels = image.load()
    visited = [[False] * width for _ in range(height)]
    queue: deque[tuple[int, int]] = deque()

    for x, y in ((0, 0), (width - 1, 0), (0, height - 1), (width - 1, height - 1)):
        if is_black_matte(*pixels[x, y], tolerance):
            visited[y][x] = True
            queue.append((x, y))

    removed = 0
    while queue:
        x, y = queue.popleft()
        red, green, blue, alpha = pixels[x, y]
        pixels[x, y] = (red, green, blue, 0)
        removed += 1

        for next_x, next_y in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if not 0 <= next_x < width or not 0 <= next_y < height:
                continue
            if visited[next_y][next_x]:
                continue
            if not is_black_matte(*pixels[next_x, next_y], tolerance):
                continue
            visited[next_y][next_x] = True
            queue.append((next_x, next_y))

    image.save(path)
    return removed


def main() -> None:
    if len(sys.argv) != 2:
        print("Usage: strip-icon-black-matte.py path/to/icon.png", file=sys.stderr)
        sys.exit(1)

    target = Path(sys.argv[1])
    if not target.is_file():
        print(f"Error: file not found: {target}", file=sys.stderr)
        sys.exit(1)

    removed = strip_black_matte(target)
    print(f"Removed {removed} black matte pixels from {target}")


if __name__ == "__main__":
    main()
