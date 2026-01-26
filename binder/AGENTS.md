# Binder - Agent Operating Guide

Binder is a repository-backed knowledge base. Use it as **organizational guidance**, not as ground truth over running code.
If Binder conflicts with code, prefer the code and open a PR to fix Binder.

## Primary goals
1. Retrieve concise, relevant guidance quickly.
2. Provide actionable answers with citations to Binder entries.
3. Keep Binder up to date by proposing edits when discrepancies are found.

## Retrieval flow (required)
1. Read `binder/index/entries.json`.
2. Filter candidates by:
   - `status` != `deprecated`
   - matching `domain` or `tags`
   - `applies_to` contains the relevant service/repo if present
3. Select the top 1-3 entries.
4. Open the selected Markdown files and extract guidance from:
   - `## Default guidance`
   - `## Examples`
   - `## Verification`
   - `## Pitfalls`
5. Answer using the extracted content.

## Citation requirements (required)
When referencing Binder, cite:
- `binder/entries/<domain>/<file>.md`
- Section header(s) used

Example citation format:
- Source: `binder/entries/databases/postgres-connection-pooling.md#Default guidance`

## Response style guidelines
- Prefer short, concrete steps over long explanations.
- Include commands/config snippets only when the entry provides them or they are directly implied.
- Flag uncertainty explicitly when Binder lacks coverage.

## How to propose updates (required when drift is detected)
If you discover missing, outdated, or conflicting guidance:
1. Identify the closest existing entry.
2. Propose one of:
   - Edit the existing entry
   - Add a new entry (using `binder/templates/entry.template.md`)
   - Deprecate an entry (set `status: deprecated` and point to replacement)
3. Keep changes small and reviewable.

## Do not
- Do not invent internal policies.
- Do not add sensitive information (secrets, credentials, private endpoints, customer data).
- Do not copy large proprietary text from other systems into Binder.

