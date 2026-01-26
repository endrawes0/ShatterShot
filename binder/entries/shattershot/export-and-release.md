---
id: shattershot-export-and-release
title: Export and release ShatterShot
status: stable
domain: shattershot
tags: [shattershot, export, release, godot, builds]
owners: ["@endrawes0"]
created: 2026-01-26
last_reviewed: 2026-01-26
source: internal
applies_to: [shattershot]
references: ["EXPORTING.md", "export_presets.cfg"]
---

## Summary
- How to create Windows/Linux/macOS release builds from `export_presets.cfg`, zip them, and publish a GitHub release.

## When to use
- You’re preparing a tagged release or need distributable artifacts for testing.

## Default guidance
- Use Godot `4.5.1` and install matching export templates under `~/.local/share/godot/export_templates/4.5.1.stable/`.
- Run headless exports from the repo root; outputs go under `builds/` (git-ignored).
- Zip per-platform build folders before uploading to GitHub Releases.

## Examples
- Headless exports (update the Godot path if needed):
  - `../Godot_v4.5.1 --headless --export-release "Windows Desktop" builds/windows/ShatterShot.exe`
  - `../Godot_v4.5.1 --headless --export-release "Linux/X11" builds/linux/ShatterShot.x86_64`
  - `../Godot_v4.5.1 --headless --export-release "macOS" builds/mac/ShatterShot.app`
- Zip artifacts:
  - `zip -r builds/ShatterShot-windows.zip builds/windows`
  - `zip -r builds/ShatterShot-linux.zip builds/linux`
  - `zip -r builds/ShatterShot-mac.zip builds/mac`

## Pitfalls
- Missing export templates (exports succeed only when templates are installed).
- Export preset name mismatches (must match `export_presets.cfg`).
- Forgetting that `builds/` is ignored by git (artifacts won’t be versioned).

## Verification
- Run the exported build for each platform and confirm it reaches the main menu.
- Confirm the zips contain the expected platform output folder layout.

## Related
- `binder/entries/shattershot/run-locally.md`
- `binder/entries/shattershot/overview.md`
