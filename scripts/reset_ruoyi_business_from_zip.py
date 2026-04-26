# -*- coding: utf-8 -*-
"""Remove ruoyi-business Java/resources sources and re-extract from RuoYi-Vue.zip (no orphan files)."""
import os
import shutil
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ZIP_PATH = os.path.join(ROOT, "RuoYi-Vue.zip")
BUSINESS = os.path.join(ROOT, "backend", "RuoYi-Vue", "ruoyi-business")
SRC_MAIN = os.path.join(BUSINESS, "src", "main")


def should_skip(name: str) -> bool:
    return name.startswith("__MACOSX")


def main():
    if not os.path.isfile(ZIP_PATH):
        raise SystemExit("Missing " + ZIP_PATH)
    for sub in ("java", "resources"):
        p = os.path.join(SRC_MAIN, sub)
        if os.path.isdir(p):
            shutil.rmtree(p)
            print("Removed", p)
    prefix = "RuoYi-Vue/ruoyi-business/src/main/"
    with zipfile.ZipFile(ZIP_PATH, "r") as zf:
        dest = os.path.join(ROOT, "backend")
        for info in zf.infolist():
            if should_skip(info.filename):
                continue
            if not info.filename.startswith(prefix):
                continue
            rel = info.filename[len("RuoYi-Vue/") :]
            target = os.path.normpath(os.path.join(dest, rel))
            if not target.startswith(os.path.normpath(os.path.join(dest, "RuoYi-Vue")) + os.sep):
                raise RuntimeError("bad path " + info.filename)
            if info.is_dir():
                os.makedirs(target, exist_ok=True)
                continue
            os.makedirs(os.path.dirname(target), exist_ok=True)
            with zf.open(info, "r") as src, open(target, "wb") as out:
                shutil.copyfileobj(src, out)
    print("Re-extracted ruoyi-business src/main from zip.")


if __name__ == "__main__":
    main()
