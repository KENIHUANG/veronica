#!/usr/bin/env python3
"""提取所有含中文的 GDScript 字符串字面量,对照 scripts/en_strings.gd。
用法: python3 tools/extract_strings.py [--missing] [--obsolete] [--doc]
  --doc  重新生成 docs/script_all_zh.md
"""
import re, sys, os, glob
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CJK = re.compile(r'[一-鿿　-〿＀-￯]')
LIT = re.compile(r'"((?:[^"\\\n]|\\.)*)"')
def files():
    out = []
    for pat in ["autoload/*.gd", "scripts/*.gd", "scripts/rooms/*.gd"]:
        out += sorted(glob.glob(os.path.join(ROOT, pat)))
    return [f for f in out if not f.endswith("en_strings.gd")]
def strip_comment(line):
    # 去掉行尾注释(不在字符串里的 #)
    q = False; esc = False
    for i, ch in enumerate(line):
        if esc: esc = False; continue
        if ch == '\\': esc = True; continue
        if ch == '"': q = not q
        elif ch == '#' and not q: return line[:i]
    return line
def code_strings():
    res = {}
    for f in files():
        rel = os.path.relpath(f, ROOT)
        for line in open(f, encoding="utf-8"):
            if line.lstrip().startswith("#"): continue
            for m in LIT.finditer(strip_comment(line)):
                s = m.group(1)
                if CJK.search(s):
                    res.setdefault(rel, [])
                    if s not in res[rel]: res[rel].append(s)
    return res
def en_keys():
    txt = open(os.path.join(ROOT, "scripts/en_strings.gd"), encoding="utf-8").read()
    keys = {}
    for line in txt.splitlines():
        m = re.match(r'\s*"((?:[^"\\]|\\.)*)"\s*:\s*"((?:[^"\\]|\\.)*)",?\s*$', line)
        if m: keys[m.group(1)] = m.group(2)
    return keys
def expand(s):
    """'名字|台词' 形式:翻译时名字和台词分开查。"""
    if "|" in s and not s.startswith("["):
        a, b = s.split("|", 1)
        return [a, b]
    return [s]
if __name__ == "__main__":
    cs = code_strings(); ek = en_keys()
    allc = []
    for v in cs.values(): allc += v
    need = set(allc)
    if "--missing" in sys.argv:
        for s in sorted(need):
            if s not in ek and not any(s == x for x in ek):
                print(s)
    if "--obsolete" in sys.argv:
        for k in ek:
            if k not in need: print(k)
    if "--doc" in sys.argv:
        out = ["# 全部游戏文案(按来源文件分组)", "> 由 tools/extract_strings.py --doc 生成。修改后需同步 scripts/en_strings.gd(以中文原文为键)。", ""]
        for rel, ss in cs.items():
            out.append("## " + rel)
            out += ["- " + s for s in ss]
            out.append("")
        open(os.path.join(ROOT, "docs/script_all_zh.md"), "w", encoding="utf-8").write("\n".join(out))
        print("docs/script_all_zh.md written")
