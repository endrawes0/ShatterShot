---
id: shattershot-overview
title: ShatterShot overview
status: stable
domain: shattershot
tags: [shattershot, godot, roguelike, deck-builder, breakout]
owners: ["@endrawes0"]
created: 2026-01-26
last_reviewed: 2026-01-26
source: internal
applies_to: [shattershot]
references: ["README.md", "PROJECT_DESCRIPTION.md"]
---

## Summary
- ShatterShot is a single-player Godot game that combines Breakout-style paddle/ball combat with a roguelike deck-builder loop.
- Encounters alternate between a card-planning phase and a live volley phase.

## When to use
- You need a high-level mental model of the game before changing gameplay, UI flow, or data.
- You’re onboarding and want the “what goes where” view of the project.

## Default guidance
- Treat `scripts/Main.gd` as the run controller: encounter flow, deck lifecycle, UI updates, and room transitions.
- Treat `data/` as the balancing/source-of-truth for cards/mods/buffs; keep numbers and pools data-driven.
- Keep Binder entries short and operational; when details drift, prefer the code and update Binder.

## Examples
- Start here for the game loop: `scripts/Main.gd`.
- Main scenes to open for context:
  - `scenes/MainMenu.tscn` (front-end flow)
  - `scenes/Main.tscn` (core combat scene)

## Pitfalls
- Mixing responsibilities between phases: keep deck/energy/card effects in `PLANNING` and physics/resolution in `VOLLEY`.
- Hard-coding balance values in scripts instead of updating `data/balance/` (and the derived reference in `GAMEPLAY.md`).
- Editing `project.godot` manually for complex changes (prefer the editor UI) and accidentally breaking autoloads/settings.
- Adding state transitions without updating HUD/input gating (card play should be disabled outside `PLANNING`).

## Verification
- Run the game and confirm you can reach the main menu and start a run.
- Open `scenes/Main.tscn` and confirm the HUD and core gameplay nodes load without missing references.

## Related
- `binder/entries/shattershot/run-locally.md`
- `binder/entries/shattershot/project-structure.md`
- `binder/entries/shattershot/gameplay-loop.md`
- `binder/entries/shattershot/balance-data.md`
- `binder/entries/shattershot/export-and-release.md`
