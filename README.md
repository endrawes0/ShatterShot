![ShatterShot Logo](https://github.com/endrawes0/BlockBreaker/blob/main/assets/ShatterShot-Logo.png?raw=true)

# ShatterShot Roguelike Deck Builder

## Overview
A single-player Godot project that fuses Breakout-style paddle/ball action with a roguelike deck-builder loop. Each room is a short combat encounter where you plan a volley by playing cards, then launch balls to clear a brick formation before threat damage wears you down.

## Architecture
- Godot scenes:
  - `scenes/Main.tscn`: core gameplay scene with Paddle, Bricks container, Walls, and HUD panels.
  - `scenes/Paddle.tscn`, `scenes/Ball.tscn`, `scenes/Brick.tscn`: reusable gameplay actors.
  - `scenes/MainMenu.tscn`, `scenes/Help.tscn`, `scenes/Shop.tscn`: front-end flow and shop layout.
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

### Card List
| Card | Cost | Type | Effect |
| --- | --- | --- | --- |
| Strike | 1 | Offense | +1 volley damage. |
| Twin Launch | 1 | Offense | +1 ball this volley. |
| Guard | 1 | Defense | Gain 4 block. Block reduces threat damage this turn. |
| Widen Paddle | 1 | Utility | Widen paddle for 2 turns. |
| Bomb | 2 | Offense | Destroy up to 3 random bricks. |
| Rally | 0 | Utility | Draw 2 cards. |
| Focus | 1 | Utility | +1 energy this turn. |
| Haste | 1 | Utility | Paddle moves faster for 2 turns. |
| Stasis | 1 | Defense | Slow balls this volley. |
| Wound | 9 | Curse | Unplayable. Clutters your hand until end of turn. |

### Buffs (Run-Specific)
- Upgrade starting hand: +1 to starting hand size.
- Vitality: +10 max HP and heal 10.

### Ball Mods (Run-Specific)
- Explosives: explode bricks on hit.
- Spikes: ignore shielded sides on hit; consumed on shielded break or ball drop.
- Miracle: one floor bounce per use; can be reselected mid-volley.
- Persist toggle keeps the selected mod active while charges remain.

## Progression
- Rewards after combat grant new cards or allow skips.
- Shops sell cards, buffs, and ball mod charges, and allow card removal.
- Rest rooms heal a flat amount.
- Victory is earned by clearing the final boss room.

## More Detail
See `PROJECT_DESCRIPTION.md` for the same information in a standalone description file.
