# -*- coding: utf-8 -*-
"""Replace ruoyi-admin .../controller/business with contents from RuoYi-Vue.zip."""
import os
import shutil
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ZIP_PATH = os.path.join(ROOT, "RuoYi-Vue.zip")
DEST = os.path.join(ROOT, "backend", "RuoYi-Vue")
PREFIX = "RuoYi-Vue/ruoyi-admin/src/main/java/com/ruoyi/web/controller/business/"


def should_skip(name: str) -> bool:
    return name.startswith("__MACOSX")


def main():
    pkg = os.path.join(
        DEST,
        "ruoyi-admin",
        "src",
        "main",
        "java",
        "com",
        "ruoyi",
        "web",
        "controller",
        "business",
    )
    if os.path.isdir(pkg):
        shutil.rmtree(pkg)
        print("Removed", pkg)
    os.makedirs(pkg, exist_ok=True)
    dest_rv = os.path.normpath(os.path.join(DEST, "RuoYi-Vue"))
    with zipfile.ZipFile(ZIP_PATH, "r") as zf:
        for info in zf.infolist():
            if should_skip(info.filename):
                continue
            if not info.filename.startswith(PREFIX):
                continue
            parts = [p for p in info.filename.split("/") if p]
            target = os.path.normpath(os.path.join(ROOT, "backend", *parts[1:]))
            if not target.startswith(dest_rv + os.sep):
                raise RuntimeError("bad path " + info.filename)
            if info.is_dir() or info.filename.endswith("/"):
                os.makedirs(target, exist_ok=True)
                continue
            os.makedirs(os.path.dirname(target), exist_ok=True)
            with zf.open(info, "r") as src, open(target, "wb") as out:
                shutil.copyfileobj(src, out)
    print("Restored controller/business from zip.")


if __name__ == "__main__":
    main()
