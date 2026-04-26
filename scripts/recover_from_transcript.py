# -*- coding: utf-8 -*-
"""
Recover files from Cursor agent transcript JSONL (tool_use Write contents).

Safety defaults (avoid clobbering a working tree or this script):
  - Never writes over this file (scripts/recover_from_transcript.py).
  - Unless YIBO_RECOVER_BACKEND=1, skips .java / .xml under *RuoYi-Vue* (backend rebuild is manual).
  - Set YIBO_RECOVER_DRY_RUN=1 to print planned writes only.

Environment:
  YIBO_RECOVER_BACKEND=1   Include ruoyi-business / ruoyi-admin Java and XML from transcripts.
  YIBO_TRANSCRIPT_DIR=     Override agent-transcripts directory (default: project under .cursor).
  YIBO_RECOVER_DRY_RUN=1   Do not write files.
"""
from __future__ import annotations

import glob
import html
import json
import os
import sys

# Project root: .../yibo 1.0
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROOT_PREFIX = os.path.normpath(ROOT).lower()

THIS_SCRIPT = os.path.normpath(os.path.abspath(__file__)).lower()


def default_transcript_dirs() -> list[str]:
    base = os.environ.get("USERPROFILE", "")
    if not base:
        return []
    project = os.path.join(
        base, ".cursor", "projects", "d-software-yibo-1-0", "agent-transcripts"
    )
    override = os.environ.get("YIBO_TRANSCRIPT_DIR", "").strip()
    if override:
        return [override]
    if os.path.isdir(project):
        return [project]
    # Fallback: any project with agent-transcripts
    pattern = os.path.join(base, ".cursor", "projects", "*", "agent-transcripts")
    return sorted(d for d in glob.glob(pattern) if os.path.isdir(d))


def list_jsonl(dirs: list[str]) -> list[str]:
    out: list[str] = []
    for d in dirs:
        out.extend(glob.glob(os.path.join(d, "**", "*.jsonl"), recursive=True))
    return sorted(set(out))


def should_skip_path(path: str) -> bool:
    norm = os.path.normpath(path).lower()
    if norm == THIS_SCRIPT:
        return True
    if not norm.startswith(ROOT_PREFIX + os.sep) and norm != ROOT_PREFIX:
        return False
    if os.environ.get("YIBO_RECOVER_BACKEND") == "1":
        return False
    if "ruoyi-vue" in norm.replace("/", "\\"):
        low = norm.replace("\\", "/")
        if low.endswith(".java") or low.endswith(".xml"):
            return True
    return False


def collect_writes(jsonl_paths: list[str]) -> dict[str, str]:
    """path -> last contents (str), last write wins across all lines and files."""
    writes: dict[str, str] = {}
    for transcript in jsonl_paths:
        lines_seen = 0
        try:
            with open(transcript, "r", encoding="utf-8", errors="replace") as f:
                for line in f:
                    lines_seen += 1
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        obj = json.loads(line)
                    except json.JSONDecodeError:
                        continue
                    msg = obj.get("message") or {}
                    content = msg.get("content")
                    if not isinstance(content, list):
                        continue
                    for block in content:
                        if block.get("type") != "tool_use":
                            continue
                        if block.get("name") != "Write":
                            continue
                        inp = block.get("input") or {}
                        path = inp.get("path", "")
                        body = inp.get("contents")
                        if not path or body is None:
                            continue
                        if not isinstance(body, str):
                            continue
                        norm_path = os.path.normpath(path)
                        if not norm_path.lower().startswith(ROOT_PREFIX):
                            continue
                        if should_skip_path(norm_path):
                            continue
                        if "<" in body or ">" in body or "&" in body:
                            body = html.unescape(body)
                        writes[norm_path] = body
        except OSError as e:
            print("Skip (read error):", transcript, e, file=sys.stderr)
    return writes


def main() -> None:
    dirs = default_transcript_dirs()
    if not dirs:
        print("No transcript directories found. Set YIBO_TRANSCRIPT_DIR or install under .cursor/projects/...")
        return
    jsonl_paths = list_jsonl(dirs)
    if not jsonl_paths:
        print("No *.jsonl under:", dirs)
        return
    writes = collect_writes(jsonl_paths)
    dry = os.environ.get("YIBO_RECOVER_DRY_RUN") == "1"
    print(
        "Transcripts:",
        len(jsonl_paths),
        "files | unique Write paths:",
        len(writes),
        "| dry_run=",
        dry,
        "| backend_java_xml=",
        os.environ.get("YIBO_RECOVER_BACKEND") == "1",
    )
    for path, body in sorted(writes.items()):
        data = body.encode("utf-8")
        if dry:
            print("Would write", len(data), "bytes ->", path)
            continue
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as out:
            out.write(data)
        print("Wrote", len(data), "bytes ->", path)


if __name__ == "__main__":
    main()
