#!/usr/bin/env python3
"""生成游戏界面用的中文字体子集(网页版必需:浏览器里读不到系统字体,不嵌字体就全是方块)。
用法: python3 tools/subset_font.py
- 源字体: tools/fonts_src/NotoSansSC-Variable.ttf (Google Fonts 的 Noto Sans SC,SIL OFL)
- 输出:   assets/fonts/NotoSansSC-Game.ttf (常规粗细,约 1~2 MB)
- 收录:   游戏代码里出现的全部字符 + ASCII + 常用标点 + GB2312 一级常用汉字(约 3755 个)
  改了文案后重新运行一次即可;依赖 fonttools (pip install fonttools)。
"""
import os, re, glob, sys
from fontTools import subset
from fontTools.varLib import instancer
from fontTools.ttLib import TTFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "tools/fonts_src/NotoSansSC-Variable.ttf")
OUT = os.path.join(ROOT, "assets/fonts/NotoSansSC-Game.ttf")

chars = set()
for pat in ["autoload/*.gd", "scripts/*.gd", "scripts/rooms/*.gd"]:
    for f in glob.glob(os.path.join(ROOT, pat)):
        chars |= set(open(f, encoding="utf-8").read())
chars |= {chr(c) for c in range(0x20, 0x7F)}
chars |= set("·—–…“”‘’【】《》「」『』（），。！？：；、～￥％＋－×÷①②③④⑤⑥⑦⑧⑨⑩●○◀▶▲▼■□★☆✉✓✗←→↑↓░▒▓█　0123456789")
# GB2312 一级汉字(按拼音排序的 3755 个常用字):区 16~55
for hi in range(0xB0, 0xD8):
    for lo in range(0xA1, 0xFF):
        try:
            chars.add(bytes([hi, lo]).decode("gb2312"))
        except UnicodeDecodeError:
            pass
chars = {c for c in chars if c.isprintable() or c == "　"}

font = TTFont(SRC)
font = instancer.instantiateVariableFont(font, {"wght": 400})
opts = subset.Options()
opts.layout_features = ["*"]
opts.name_IDs = ["*"]
opts.notdef_outline = True
sub = subset.Subsetter(opts)
sub.populate(text="".join(sorted(chars)))
sub.subset(font)
font.save(OUT)
print(f"{len(chars)} chars -> {OUT} ({os.path.getsize(OUT) / 1024:.0f} KB)")
