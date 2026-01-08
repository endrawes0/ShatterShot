# Refactoring Report

## Findings

- RR-2 (High): Addressed by extracting deck/encounter/map/HUD responsibilities into managers and wiring `Main.gd` as a coordinator. Remaining items are captured in RR-3/RR-7 for panel helpers and shop builder cleanup.
- RR-3 (Medium): UI state transitions are duplicated (shop and deck/discard/remove panels). Consolidate into a shared panel-opening helper.
- RR-4 (Medium): Card/mod data and shop tuning data still live in code. Move to resources (`.tres`) or JSON for easier balancing.
- RR-5 (Medium): Ball mod behavior is embedded in `scripts/Ball.gd`. Consider a mod strategy map or dedicated mod effect classes for easier expansion.
- RR-6 (Low): Styling helpers mix presentation with game flow. Keep style setup separate from game state updates.

## Additional Opportunities

- RR-10 (Medium): Return-panel state is stringly-typed and repeated in deck/discard/remove flows; wrap in a helper or enum-based return state.
- RR-8 (Medium): Brick spawning mixes layout, pattern, and variant rolls; separate grid positioning from brick data rolls.
- RR-7 (Low): Shop button creation is a long block; extract small builder methods for cards, buffs, and mods.
- RR-9 (Low): Scene show/hide logic repeats between overlays; consider a scene stack/manager to centralize `process_mode` and visibility.

## Level Design and Extensibility

- RR-11 (Medium): Encounter configs are now data-driven via `EncounterConfig` resources in `data/encounters/`, loaded by `EncounterManager` (no edits to `_start_encounter()`/`_start_boss()` required).
- RR-12 (Medium): Pattern selection is data-driven via `PatternRegistry` and `EncounterConfig.pattern_id` (use `auto` for rotation or specify a pattern).
- RR-13 (Medium): Variant behavior is data-driven via `VariantPolicy` resources in `data/variant_policies/` and assigned per encounter config.
- RR-14 (Low): Room choices are data-driven via the floor plan generator config (`data/floor_plans/generator_config.tres`) and traversed by `MapManager`.
