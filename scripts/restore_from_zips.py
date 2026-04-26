# -*- coding: utf-8 -*-
"""Restore corrupted null-filled files by extracting original zips in-place (overwrite)."""
import os
import shutil
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

ZIP_BACKEND = os.path.join(ROOT, "RuoYi-Vue.zip")
ZIP_FRONT = os.path.join(ROOT, "ruoyi-ui.zip")


def should_skip_backend_member(name: str) -> bool:
    return name.startswith("__MACOSX")


def should_skip_frontend_member(name: str) -> bool:
    if name.startswith("__MACOSX"):
        return True
    if "/node_modules/" in name or name.endswith("/node_modules"):
        return True
    if "/dist/" in name or name.endswith("/dist"):
        return True
    if "/.idea/" in name or name.endswith("/.idea"):
        return True
    return False


def extract_filtered(zf: zipfile.ZipFile, dest_dir: str, skip) -> int:
    os.makedirs(dest_dir, exist_ok=True)
    count = 0
    dest_norm = os.path.normpath(os.path.abspath(dest_dir))
    for info in zf.infolist():
        if skip(info.filename):
            continue
        target = os.path.normpath(os.path.join(dest_dir, info.filename))
        if not os.path.normpath(os.path.abspath(target)).startswith(dest_norm + os.sep):
            raise RuntimeError(f"Unsafe path: {info.filename}")
        if info.is_dir():
            os.makedirs(target, exist_ok=True)
            continue
        os.makedirs(os.path.dirname(target), exist_ok=True)
        with zf.open(info, "r") as src, open(target, "wb") as out:
            shutil.copyfileobj(src, out)
        count += 1
    return count


def main():
    backend_dest = os.path.join(ROOT, "backend")
    os.makedirs(backend_dest, exist_ok=True)

    with zipfile.ZipFile(ZIP_BACKEND, "r") as zf:
        n = extract_filtered(zf, backend_dest, should_skip_backend_member)
        print(f"Backend extracted: {n} files -> {backend_dest}")

    front_dest = os.path.join(ROOT, "frontend")
    os.makedirs(front_dest, exist_ok=True)
    with zipfile.ZipFile(ZIP_FRONT, "r") as zf:
        n = extract_filtered(zf, front_dest, should_skip_frontend_member)
        print(f"Frontend extracted: {n} files -> {front_dest}")

    readme_zip_path = "RuoYi-Vue/README.md"
    with zipfile.ZipFile(ZIP_BACKEND, "r") as zf:
        data = zf.read(readme_zip_path)
    with open(os.path.join(ROOT, "README.md"), "wb") as f:
        f.write(data)
    print("Wrote README.md from zip")

    start_bat = os.path.join(ROOT, "start.bat")
    if os.path.isfile(start_bat):
        with open(start_bat, "rb") as f:
            sample = f.read(200)
    else:
        sample = b""
    if len(sample) < 10 or sample.count(bytes([0])) / max(1, len(sample)) > 0.5:
        txt = """@echo off
cd /d %~dp0
echo YiBo project root. Use scripts\\startup\\start_backend.bat and start_frontend.bat
pause
"""
        with open(start_bat, "w", encoding="utf-8", newline="\r\n") as f:
            f.write(txt)
        print("Rewrote start.bat stub")

    print("Done. Run npm install in frontend\\ruoyi-ui (node_modules not in zip).")


if __name__ == "__main__":
    main()
