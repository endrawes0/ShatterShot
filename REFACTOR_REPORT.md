# Refactoring Report

## Findings

- RR-2 (High): Addressed by extracting deck/encounter/map/HUD responsibilities into managers and wiring `Main.gd` as a coordinator. Remaining items are captured in RR-3/RR-7 for panel helpers and shop builder cleanup.
- RR-3 (Medium): UI state transitions are duplicated. `_show_shop` repeats panel hiding after `_hide_all_panels()` (`scripts/Main.gd:599-610`), and the deck/discard/remove panels repeat the same return-panel logic (`scripts/Main.gd:1214-1266`). Consolidate into a shared panel-opening helper.
- RR-4 (Medium): Card and mod data are hard-coded in `Main.gd` (`scripts/Main.gd:5-52`, `scripts/Main.gd:30-40`), and shop prices/boosts are scattered (`scripts/Main.gd:626-678`). Move to data resources (`.tres`) or JSON for balancing and testability.
- RR-5 (Medium): Ball mod behavior is embedded in `Ball.gd` (`scripts/Ball.gd:37-77`, `scripts/Ball.gd:107-116`). Use a mod strategy map or dedicated mod effect classes for easier expansion.
- RR-6 (Low): `_apply_persist_checkbox_style()` mixes styling with game flow by calling `_build_map_buttons()` and `_update_labels()` (`scripts/Main.gd:323-348`). Keep style setup separate from game state updates.

## Additional Opportunities

- RR-10 (Medium): Return-panel state is stringly-typed and repeated in deck/discard/remove flows (`scripts/Main.gd:1214-1276`); wrap in a helper or enum-based return state.
- RR-8 (Medium): `scripts/Main.gd:766-845` brick spawning mixes layout, pattern, and variant rolls; separate grid positioning from brick data rolls.
- RR-7 (Low): `scripts/Main.gd:616-704` shop button creation is a long block; extract small builder methods for cards, buffs, and mods.
- RR-9 (Low): `scripts/App.gd:25-90` duplicates scene show/hide logic; consider a scene stack/manager to centralize `process_mode` and visibility.

## Level Design and Extensibility

- RR-11 (Medium): Encounter configs are now data-driven via `EncounterConfig` resources in `data/encounters/`, loaded by `EncounterManager` (no edits to `_start_encounter()`/`_start_boss()` required).
- RR-12 (Medium): Pattern selection is data-driven via `PatternRegistry` and `EncounterConfig.pattern_id` (use `auto` for rotation or specify a pattern).
- RR-13 (Medium): Variant behavior is data-driven via `VariantPolicy` resources in `data/variant_policies/` and assigned per encounter config.
- RR-14 (Low): Room choices are data-driven via the floor plan generator config (`data/floor_plans/generator_config.tres`) and traversed by `MapManager`.
