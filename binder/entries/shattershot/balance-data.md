---
id: shattershot-balance-data
title: ShatterShot balance data (cards, mods, buffs)
status: stable
domain: shattershot
tags: [shattershot, balance, data, cards, mods, shop]
owners: ["@endrawes0"]
created: 2026-01-26
last_reviewed: 2026-01-26
source: internal
applies_to: [shattershot]
references: ["GAMEPLAY.md", "data/balance/cards.tres", "data/balance/basic.tres"]
---

## Summary
- Balance and content definitions live under `data/balance/` and are referenced by gameplay code and UI.

## When to use
- You need to change card costs/effects, mod pricing, shop buffs, or starting deck composition.

## Default guidance
- Prefer editing the `.tres` balance files rather than hard-coding values in scripts.
- Use `GAMEPLAY.md` as the human-readable “current list” view, sourced from `data/balance/`.
- Keep identifiers stable (`id`-like keys) so save/state and UI references remain valid.

## Examples
- Cards and starting deck:
  - `data/balance/cards.tres`
- Ball mods and shop buffs:
  - `data/balance/basic.tres`

## Pitfalls
- Renaming an existing card/mod id without updating all references.
- Updating balance without playtesting the core loop (planning → volley → threat).

## Verification
- Run a combat encounter and confirm:
  - Updated cards show correct cost/description in the UI.
  - Shop items reflect updated prices/values.

## Related
- `binder/entries/shattershot/gameplay-loop.md`
- `binder/entries/shattershot/project-structure.md`
