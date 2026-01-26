# Contributing to Binder

## Adding an entry

1. Create a new file under `binder/entries/<domain>/<topic>.md` (kebab-case).
2. Use the template: `binder/templates/entry.template.md`.
3. Ensure required `##` sections are present.
4. Run:
   - `binder validate .`
   - `binder build-index . --apply`

## Updating an entry

Keep changes small and operational. Prefer adding `references` rather than copying long text.

