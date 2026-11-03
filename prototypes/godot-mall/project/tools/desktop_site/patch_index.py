"""Give an exported play/index.html the two-site pack addresses (design/godot-build-hosting.md "Two sites").

usage: python3 patch_index.py <play/index.html> <web/shell.html>

Builds exported before Nov 3 2026 ask for every pack next to the page. Since then web/shell.html sends the
computer packs to the second site (MALL_DESKTOP_SITE). This copies that block from shell.html into an older
export's index.html. An export that already has it is left alone, so it is safe on every deploy.
Exits non-zero, and changes nothing, if the old lines are not found exactly once.
"""
import re
import sys

OLD_PACK = "const MALL_PACK = (w) => 'w' + w + window.__mallYear + '.' + window.__mallPack + '.pck';\n"
OLD_URL = "const mallPackUrl = (w, year) => new URL('w' + w + (year"
NEW_URL = "const mallPackUrl = (w, year) => new URL(MALL_PACK_BASE() + 'w' + w + (year"


def main(index_path, shell_path):
    s = open(index_path, encoding="utf-8").read()
    if "MALL_DESKTOP_SITE" in s:
        print("patch_index: already two-site, unchanged")
        return 0
    shell = open(shell_path, encoding="utf-8").read()
    m = re.search(r"^// Two sites .*?^const MALL_PACK = .*?\n", shell, re.S | re.M)
    if not m:
        print("patch_index: no two-site block in", shell_path)
        return 1
    if s.count(OLD_PACK) != 1 or s.count(OLD_URL) != 1:
        print("patch_index: the old pack lines are not in", index_path, "exactly once; nothing changed")
        return 1
    s = s.replace(OLD_PACK, m.group(0)).replace(OLD_URL, NEW_URL)
    open(index_path, "w", encoding="utf-8").write(s)
    print("patch_index: computer packs now come from the second site")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1], sys.argv[2]))
