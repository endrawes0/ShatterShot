---
id: shattershot-gameplay-loop
title: ShatterShot gameplay loop and states
status: stable
domain: shattershot
tags: [shattershot, gameplay, state-machine, combat, deck-builder]
owners: ["@endrawes0"]
created: 2026-01-26
last_reviewed: 2026-01-26
source: internal
applies_to: [shattershot]
references: ["README.md", "PROJECT_DESCRIPTION.md", "scripts/Main.gd"]
---

## Summary
- A run alternates between choosing rooms on a map and short combat encounters.
- Each combat encounter alternates between `PLANNING` (play cards) and `VOLLEY` (live ball phase).

## When to use
- You’re modifying encounter flow, adding new room types, or changing turn/phase rules.
- You need to understand when cards apply (planning) vs when physics applies (volley).

## Default guidance
- Keep phase boundaries explicit:
  - `PLANNING`: spend energy, play cards, prepare the volley.
  - `VOLLEY`: launch balls and resolve collisions until balls are lost or the board clears.
- Threat damage is tied to what remains on the board; block mitigates threat.
- Prefer to express rule changes as data/config when possible, then wire behavior in `scripts/Main.gd`.

## Examples
- Typical encounter:
  - Enter `PLANNING`, draw cards, spend energy.
  - Press `ui_accept` to launch the volley and enter `VOLLEY`.
  - When balls are gone (or board clears), apply threat/outcome and transition to rewards/shop/rest/map.

## Pitfalls
- Mixing planning-only effects (deck/hand/energy) into live volley code paths.
- Adding new transitions without ensuring the HUD and input handlers respect the current state.

## Verification
- Play an encounter and confirm:
  - Cards can only be played in `PLANNING`.
  - Launch inputs work in `PLANNING` and (for reserve balls) in `VOLLEY`.
  - End-of-encounter transitions correctly show rewards/shop/rest/map.

## Related
- `binder/entries/shattershot/overview.md`
- `binder/entries/shattershot/balance-data.md`
