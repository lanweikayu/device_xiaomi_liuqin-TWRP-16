#!/usr/bin/env python3
"""Subset TWRP NotoSansCJKsc to the full CJK Unified block plus ja/ru/es/pt glyphs.

The stock extra-languages font is 17MiB and does not fit in liuqin's 100MiB
recovery together with ufs_qcom.ko. This is not the old GB2312 cut: it keeps
U+4E00-9FFF (all common Chinese / kanji), kana, bopomofo, cyrillic, and latin.
"""
from __future__ import print_function

import os
import sys

from fontTools.subset import Options, Subsetter
from fontTools.ttLib import TTFont


def unicodes():
    ranges = [
        (0x20, 0x7F),  # ASCII
        (0xA0, 0x100),  # Latin-1
        (0x100, 0x250),  # Latin extended
        (0x400, 0x530),  # Cyrillic (ru)
        (0x1E00, 0x1F00),  # Latin extra (es/pt)
        (0x2000, 0x2070),  # punctuation
        (0x2E80, 0x2EF4),  # CJK radicals
        (0x3000, 0x3040),  # CJK punctuation
        (0x3040, 0x30FF),  # hiragana + katakana
        (0x3100, 0x3130),  # bopomofo
        (0x31F0, 0x3200),  # kana extended
        (0x4E00, 0xA000),  # CJK Unified Ideographs
        (0xF900, 0xFB00),  # compatibility ideographs
        (0xFE30, 0xFE70),
        (0xFF00, 0xFFEF),  # fullwidth
    ]
    out = set()
    for start, end in ranges:
        out.update(range(start, end))
    return out


def main():
    if len(sys.argv) != 3:
        print("usage: subset_cjk.py SRC DST", file=sys.stderr)
        return 2
    src, dst = sys.argv[1], sys.argv[2]
    os.makedirs(os.path.dirname(dst) or ".", exist_ok=True)
    opts = Options()
    opts.layout_features = "*"
    opts.notdef_outline = True
    opts.recommended_glyphs = True
    subsetter = Subsetter(options=opts)
    font = TTFont(src, lazy=True)
    subsetter.populate(unicodes=unicodes())
    subsetter.subset(font)
    font.save(dst)
    print("subset_cjk: %s -> %s (%d bytes)" % (src, dst, os.path.getsize(dst)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
