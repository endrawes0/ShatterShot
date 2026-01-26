#!/usr/bin/env python3
from __future__ import annotations

import argparse
import subprocess
import sys


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("path", nargs="?", default=".", help="Repo path (default: .)")
    parser.add_argument("--check", action="store_true", help="Fail if indexes are out of date.")
    parser.add_argument("--apply", action="store_true", help="Write indexes.")
    args = parser.parse_args()

    cmd = ["binder", "build-index", args.path]
    if args.check:
        cmd.append("--check")
    if args.apply:
        cmd.append("--apply")

    # Wrapper for CI/local usage inside a repo that contains binder/.
    # Requires `binder` CLI to be installed in the environment.
    return subprocess.call(cmd, cwd=".")


if __name__ == "__main__":
    raise SystemExit(main())
