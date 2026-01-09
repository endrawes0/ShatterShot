# Gameplay Reference

This document is intended to be a “source of truth” overview of the current cards, ball mods, and shop buffs as defined in the balance data under `data/balance/`.

## Cards
Card definitions live in `data/balance/cards.tres`.

### Starting Deck
From `starting_deck` in `data/balance/cards.tres`:
- Punch x4
- Twin Launch x2
- Guard x2
- Rally x1
- Focus x1

### Card Pool
The reward/shop pool is `card_pool` in `data/balance/cards.tres` (Wound is excluded).

### Card List
| ID | Name | Cost | Type | Description |
| --- | --- | --- | --- | --- |
| `punch` | Punch | 1 | Offense | +1 volley damage. |
| `twin` | Twin Launch | 1 | Offense | Gain an extra launch this volley. |
| `guard` | Guard | 1 | Defense | Gain 5 block. Block reduces threat damage this turn. |
| `widen` | Widen Paddle | 1 | Utility | Widen paddle for 2 turns. |
| `bomb` | Bomb | 2 | Offense | Destroy up to 3 random bricks. |
| `moab` | MOAB | 3 | Offense | Destroy up to 10 random bricks. |
| `parry` | Parry | 1 | Defense | Block wounds this volley. |
| `riposte` | Riposte | 2 | Offense | Discard a Parry card. Destroy a brick when Parry is used. |
| `rally` | Rally | 0 | Utility | Draw 2 cards. |
| `focus` | Focus | 0 | Utility | +1 energy this turn. |
| `haste` | Haste | 1 | Utility | Paddle moves faster for 2 turns. |
| `slow` | Sloth | 1 | Defense | Slow balls this volley. |
| `what_doesnt_kill_us` | What Doesn't Kill Us | 1 | Utility | If you have a Wound in hand, remove it and gain 2 energy. |
| `wound` | Wound | 1 | Curse | Pay 1 energy to remove it from your deck. |

## Ball Mods
Ball mod definitions live under `ball_mods` in `data/balance/basic.tres`.

| ID | Name | Cost | Description |
| --- | --- | --- | --- |
| `explosive` | Explosives | 50g | Explode bricks on hit. |
| `spikes` | Spikes | 50g | Ignore brick shields on hit. |
| `miracle` | Miracle | 75g | One floor bounce per ball. |

Notes:
- Mods are purchased as charges (e.g. `x2`) and selected in the Mods panel; selection applies to active balls.
- The “Persist” toggle keeps the selected mod active while charges remain.

## Shop Buffs
Buff costs and values are configured in `shop_data` in `data/balance/basic.tres`.

- Upgrade starting hand: `60g` (+1), capped by `max_hand_size` (default `7`).
- Vitality: `60g` (+25 max HP, heal 30).
- Surge: `70g` (+1 max energy), capped at +2 total.
- Wider Paddle: `60g` (+10 width).
- Paddle Speed: `60g` (+10%).
- Reserve Ball: `100g` (+1 per volley), capped at +1 total.
- Shop Discount: `50g` (-10% prices), up to 5 purchases.
- Shop Scribe: `70g` (+1 card on shop entry), capped by shop max card offers (default `7`).

## Shop Actions (Defaults)
- Card price: `40g`
- Remove a card: `30g`
- Reroll cards: base `20g`, scales by `1.8^rerolls`

