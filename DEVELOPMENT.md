# Development

## Requirements
- Godot `4.5.1` (project targets Godot `4.5`).

## Run Locally
- Import `project.godot` in the Godot editor and press Play.
- Linux/macOS: `./start.sh` (expects a Godot binary at `../Godot_v4.5.1`; edit `start.sh` if your path differs).

## Inputs
- The paddle uses Godot actions `ui_left` / `ui_right`. `scripts/App.gd` ensures `A` and `D` are bound at runtime; arrow keys work via Godot’s defaults.
- Combat flow uses `ui_accept` (launch volley / launch reserve ball) and `ui_select` (end turn) along with mouse UI for cards and buttons.

## Settings
- Saved settings live at `user://settings.cfg` (see `scripts/App.gd`).

## Project Layout
- `scenes/`: gameplay and UI scenes (`MainMenu`, `Main`, `Shop`, `Settings`, etc.).
- `scripts/`: gameplay logic and managers; `scripts/Main.gd` coordinates the run loop.
- `data/`: balancing and run content (encounters, variant policies, floor plans).
- `themes/`: UI theme resources.
- `assets/`: icons, logo, fonts, and audio.

