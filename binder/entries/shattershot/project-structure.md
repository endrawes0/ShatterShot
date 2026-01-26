---
id: shattershot-project-structure
title: ShatterShot project structure
status: stable
domain: shattershot
tags: [shattershot, godot, architecture, scenes, scripts, data]
owners: ["@endrawes0"]
created: 2026-01-26
last_reviewed: 2026-01-26
source: internal
applies_to: [shattershot]
references: ["README.md", "DEVELOPMENT.md", "project.godot"]
---

## Summary
- Map of where ShatterShot keeps scenes, scripts, balancing data, and UI resources.

## When to use
- You’re adding a feature and need to know where to put code/data.
- You need to locate the “owner” file for a behavior (scene vs script vs data).

## Default guidance
- `scenes/` contains gameplay and UI scenes (`MainMenu`, `Main`, `Shop`, `Settings`, etc.).
- `scripts/` contains gameplay logic and managers; `scripts/Main.gd` coordinates the run loop.
- `data/` contains balancing and run content (encounters, variant policies, floor plans).
- `themes/` contains UI theme resources.
- `assets/` contains icons, fonts, audio, and other static art.
- Autoload singletons are defined in `project.godot` under `[autoload]` (e.g., `App`, `Audio`).

## Examples
- Core scenes:
  - `scenes/Main.tscn`, `scenes/Paddle.tscn`, `scenes/Ball.tscn`, `scenes/Brick.tscn`
- Core scripts:
  - `scripts/Main.gd`, `scripts/Paddle.gd`, `scripts/Ball.gd`, `scripts/Brick.gd`
- Balance data:
  - `data/balance/cards.tres`, `data/balance/basic.tres`

## Pitfalls
- Editing `project.godot` manually for complex changes (prefer the editor UI).
- Hard-coding balance values in scripts when they belong under `data/`.

## Verification
- Open `scenes/Main.tscn` and confirm referenced scripts/resources resolve.
- Search for a behavior’s owner file before making changes:
  - `rg -n \"<term>\" scripts data scenes`

## Related
- `binder/entries/shattershot/overview.md`
- `binder/entries/shattershot/balance-data.md`
