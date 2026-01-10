![ShatterShot Logo](assets/ShatterShot-Logo.png)

# ShatterShot Roguelike Deck Builder

## Overview
A single-player Godot project that fuses Breakout-style paddle/ball action with a roguelike deck-builder loop. Each room is a short combat encounter where you plan a volley by playing cards, then launch balls to clear a brick formation before threat damage wears you down.

## Quick Start
Prereqs: Godot `4.5.1` (the project targets Godot `4.5`).

- Open the project by importing `project.godot` in the Godot editor.
- Linux/macOS convenience script: run `./start.sh` (expects a Godot binary at `../Godot_v4.5.1`).

### Controls (Defaults)
- Move paddle: `A/D` or `Left/Right`.
- Precision move: hold `Ctrl` to slow paddle.
- Launch volley / reserve ball: `Space` (Godot `ui_accept`).
- Map preview: `M`.
- Back/menu: `Esc` (Godot `ui_cancel`).
- UI: mouse for cards, buttons, and tooltips.

## Development Docs
- Development notes: `DEVELOPMENT.md`
- Exporting and releases: `EXPORTING.md`
- Contributing: `CONTRIBUTING.md`
- Gameplay reference (cards, mods, buffs): `GAMEPLAY.md`

## Architecture
- Godot scenes:
  - `scenes/Main.tscn`: core gameplay scene with Paddle, Bricks container, Walls, and HUD panels.
  - `scenes/Paddle.tscn`, `scenes/Ball.tscn`, `scenes/Brick.tscn`: reusable gameplay actors.
  - `scenes/MainMenu.tscn`, `scenes/Help.tscn`, `scenes/Shop.tscn`: front-end flow and shop layout.
  - `scenes/Settings.tscn`: settings menu (resolution/window mode and gameplay/VFX modifiers).
- Core scripts:
  - `scripts/Main.gd`: main game controller. Owns the run state machine, deck/hand/discard, encounter setup, UI updates, and room flow (map, rewards, shop, rest, boss).
  - `scripts/Ball.gd`: ball physics, launch/bounce behavior, piercing logic, and loss handling.
  - `scripts/Paddle.gd`: horizontal movement, bounds clamping, and dynamic width changes.
  - `scripts/Brick.gd`: brick HP/threat, shields, regen-on-drop, and curse behavior.
- State machine:
  - `MAP -> PLANNING -> VOLLEY -> REWARD/SHOP/REST -> MAP` with `GAME_OVER` and `VICTORY` terminal states.
  - `PLANNING` is a card-play phase with energy and hand management; `VOLLEY` is the live ball phase.
- Data-driven cards:
  - Card metadata is centralized in `CARD_DATA` with cost, description, and type used for UI styling and effects.
  - Deck lifecycle: draw pile, hand, discard pile, and shuffle-on-empty.

## Gameplay Loop
1. Start in combat, then choose rooms from the map (combat, elite, rest, shop; boss at the end).
2. In combat, play cards to shape the next volley (damage, extra balls, block, buffs, etc.).
3. Launch the volley; balls collide with bricks and the paddle until they are lost or the board clears.
4. On ball loss or end of turn, take threat damage based on remaining bricks (mitigated by block).
5. Clear the room, take a reward, and progress deeper into the run.

## Combat Details
- Bricks are spawned in patterns (grid, stagger, pyramid, zigzag, ring) with scaling HP and variant modifiers.
- Threat is the sum of remaining brick HP plus encounter modifiers; taking too much threat ends the run.
- Elite rooms scale faster; boss rooms add a core cluster with stronger brick variants.
- Brick variants:
  - Shielded sides that negate hits from specific directions.
  - Regen-on-drop to grow HP after a ball is lost (↻ indicator).
  - Cursed bricks that add an unplayable Wound card to your deck (🗡 indicator).

## Deck and Cards
- Start with a small deck of offensive, defensive, and utility cards.
- Start each combat turn with 4 cards (max hand size 7) and energy to spend.

Full, up-to-date lists for cards, ball mods, and shop buffs live in `GAMEPLAY.md` (sourced from `data/balance/`).

## Progression
- Rewards after combat grant new cards or allow skips.
- Shops sell cards, buffs, and ball mod charges, and allow card removal.
- Rest rooms heal a flat amount.
- Victory is earned by clearing the final boss room.

## More Detail
See `PROJECT_DESCRIPTION.md` for the same information in a standalone description file.

## License
MIT. See `LICENSE`.
