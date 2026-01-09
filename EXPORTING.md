# Exporting & Releasing

## Prereqs
- Godot `4.5.1` installed.
- Export templates installed at `~/.local/share/godot/export_templates/4.5.1.stable/`.
- `export_presets.cfg` defines the export presets.

## Headless Exports
From the repo root (update the Godot path if needed):

```bash
../Godot_v4.5.1 --headless --export-release "Windows Desktop" builds/windows/ShatterShot.exe
../Godot_v4.5.1 --headless --export-release "Linux/X11" builds/linux/ShatterShot.x86_64
../Godot_v4.5.1 --headless --export-release "macOS" builds/mac/ShatterShot.app
```

Notes:
- `builds/` is ignored by git.
- The macOS bundle identifier comes from `export_presets.cfg`.

## Zip Artifacts
```bash
zip -r builds/ShatterShot-windows.zip builds/windows
zip -r builds/ShatterShot-linux.zip builds/linux
zip -r builds/ShatterShot-mac.zip builds/mac
```

## Tag & Publish (GitHub)
Decide the release version and title first (example uses `v0.1.0` / `Alpha`):

```bash
git tag -a v0.1.0 -m "Alpha"
git push origin v0.1.0
```

```bash
gh release create v0.1.0 --title "Alpha" --generate-notes \
  builds/ShatterShot-windows.zip \
  builds/ShatterShot-linux.zip \
  builds/ShatterShot-mac.zip
```

