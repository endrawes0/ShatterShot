# Agent Notes

- Direct questions should be answered directly instead of proposing or making code changes.
- Commit changes to a `feature/` or `bugfix/` branch, not directly to `main`.
- Commit early and often while working on changes.
- If you notice unexpected changes you didn't make, show the diff when asking how to proceed.
- When commenting in a PR, start the comment with "🤖:" to indicate it's from Codex.
- Avoid double-escaping newlines in `gh` API/CLI calls (use literal newlines in bodies).
- Prefer `gh api` over `gh pr edit` for updating PR metadata.
- GDScript type inference can fail with "Cannot infer the type" parse errors; avoid relying on inference and prefer explicit types for variables/values.

## Export Process (Windows/Linux/macOS)

Prereqs:
- Godot 4.5.1 installed.
- Export templates installed at `~/.local/share/godot/export_templates/4.5.1.stable/`.
- Template download: https://downloads.godotengine.org/?version=4.5.1&flavor=stable&slug=export_templates.tpz&platform=templates
- Tools available: `zip` (or Python 3 for zipping if `zip` is missing).
- Export presets live in `export_presets.cfg`.

Build commands (from repo root, update the Godot path if needed):
```bash
../Godot_v4.5.1 --headless --export-release "Windows Desktop" builds/windows/ShatterShot.exe
../Godot_v4.5.1 --headless --export-release "Linux/X11" builds/linux/ShatterShot.x86_64
../Godot_v4.5.1 --headless --export-release "macOS" builds/mac/ShatterShot.app
```

Zip artifacts for release:
```bash
zip -r builds/ShatterShot-windows.zip builds/windows
zip -r builds/ShatterShot-linux.zip builds/linux
zip -r builds/ShatterShot-mac.zip builds/mac
```

Notes:
- `builds/` is ignored by git.
- macOS uses bundle identifier `com.endrawes0.blockbreaker` from `export_presets.cfg`.

## Release Tag + Upload

Ask the user for the release version and title before running release commands.

Tag and push:
```bash
git tag -a v0.1.0 -m "Alpha"
git push origin v0.1.0
```

Create release and upload assets (requires `gh` auth):
```bash
gh release create v0.1.0 --title "Alpha" --generate-notes \
  builds/ShatterShot-windows.zip \
  builds/ShatterShot-linux.zip \
  builds/ShatterShot-mac.zip
```
