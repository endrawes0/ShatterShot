# Agent Notes

## Export Process (Windows/Linux/macOS)

Prereqs:
- Godot 4.5.1 installed.
- Export templates installed at `~/.local/share/godot/export_templates/4.5.1.stable/`.
- Export presets live in `export_presets.cfg`.

Build commands (from repo root, update the Godot path if needed):
```bash
../Godot_v4.5.1-stable_linux.x86_64 --headless --export-release "Windows Desktop" builds/windows/BlockBreaker.exe
../Godot_v4.5.1-stable_linux.x86_64 --headless --export-release "Linux/X11" builds/linux/BlockBreaker.x86_64
../Godot_v4.5.1-stable_linux.x86_64 --headless --export-release "macOS" builds/mac/BlockBreaker.app
```

Zip artifacts for release:
```bash
zip -r builds/BlockBreaker-windows.zip builds/windows
zip -r builds/BlockBreaker-linux.zip builds/linux
zip -r builds/BlockBreaker-mac.zip builds/mac
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
  builds/BlockBreaker-windows.zip \
  builds/BlockBreaker-linux.zip \
  builds/BlockBreaker-mac.zip
```
