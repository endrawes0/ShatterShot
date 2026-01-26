#!/usr/bin/env python3
from __future__ import annotations

import argparse
import subprocess
import sys


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("path", nargs="?", default=".", help="Repo path (default: .)")
    args = parser.parse_args()

    # Wrapper for CI/local usage inside a repo that contains binder/.
    # Requires `binder` CLI to be installed in the environment.
    return subprocess.call(["binder", "validate", args.path], cwd=".")


if __name__ == "__main__":
    raise SystemExit(main())
