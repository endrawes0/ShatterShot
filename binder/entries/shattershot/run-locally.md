---
id: shattershot-run-locally
title: Run ShatterShot locally
status: stable
domain: shattershot
tags: [shattershot, godot, development, run]
owners: ["@endrawes0"]
created: 2026-01-26
last_reviewed: 2026-01-26
source: internal
applies_to: [shattershot]
references: ["README.md", "DEVELOPMENT.md", "start.sh", "project.godot"]
---

## Summary
- How to run ShatterShot from the editor or via the convenience script.

## When to use
- You want to playtest changes, reproduce a bug, or verify balance tweaks.

## Default guidance
- Use Godot `4.5.1` (project targets Godot `4.5`).
- Import `project.godot` in the Godot editor and press Play.
- On Linux/macOS, `./start.sh` launches the project using a Godot binary at `../Godot_v4.5.1` (edit the script if your path differs).
- Controls rely on Godot actions (`ui_left`, `ui_right`, `ui_accept`, `ui_cancel`); the project binds `A`/`D` at runtime.
- Saved settings are stored in `user://settings.cfg`.

## Examples
- Launch via script:
  - `./start.sh`
- Find the main scene:
  - `project.godot` → `[application] run/main_scene`

## Pitfalls
- Using the wrong Godot version and getting import/runtime issues.
- Forgetting to update `start.sh` if your local Godot binary path differs.
- Confusing `user://` paths (per-user data) with repo files.

## Verification
- Boot to the main menu and start a run.
- Confirm basic inputs: move paddle (`A/D` or arrows), launch (`Space`), back (`Esc`).

## Related
- `binder/entries/shattershot/overview.md`
- `binder/entries/shattershot/export-and-release.md`
