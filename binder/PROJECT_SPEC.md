# Binder Project Specification

## 1. Purpose
Binder is a Git-backed, collaboratively maintained knowledge base for engineering teams and AI agents.
It stores concise, actionable guidance with:
- Human readability (Markdown)
- Machine readability (structured frontmatter + required sections)
- Governance (PR review + ownership)
- Fast retrieval (generated indexes)

## 2. Non-goals
- Replace source-of-truth systems (running code, infrastructure configs, incident tooling).
- Store secrets, credentials, or sensitive customer data.
- Become an unbounded wiki. Binder entries should stay short and operational.

## 3. Core concepts

### 3.1 Entry
A single Markdown file under `binder/entries/<domain>/<topic>.md` with:
- YAML frontmatter that conforms to `binder/schemas/binder-entry.schema.json`
- Required H2 sections (see below)
- Concise, actionable content

### 3.2 Domain
A folder grouping related entries (e.g., `platform`, `security`, `databases`).

### 3.3 Index
Generated JSON files used by agents/tools for fast discovery:
- `binder/index/entries.json`
- `binder/index/tags.json`

## 4. Entry format

### 4.1 YAML frontmatter
Frontmatter appears at the top of the Markdown file:

---
id: example-entry
title: Example entry title
status: stable
domain: platform
tags: [example, tag]
owners: [platform-team]
created: 2026-01-01
last_reviewed: 2026-01-20
source: internal
applies_to: [service-a, repo-x]           # optional
references: ["RFC-12", "runbook:xyz"]     # optional
security: internal                        # optional
notes: "Optional caveats."                # optional
---

### 4.2 Required sections
Each entry must include these H2 headers:

## Summary
## When to use
## Default guidance
## Examples
## Pitfalls
## Verification
## Related

Sections should be short:
- Prefer bullets, steps, small snippets
- Avoid long narrative
- Point to deeper docs via `references` rather than copying

## 5. Validation rules

### 5.1 Schema validation
- All entries must parse YAML frontmatter.
- Frontmatter must validate against `binder/schemas/binder-entry.schema.json`.

### 5.2 Repo invariants
- `id` must be globally unique across all entries.
- `domain` must match the domain folder name.
- Filename must be `kebab-case.md`.
- Required H2 sections must exist.

### 5.3 Index generation
- `binder/index/entries.json` is generated from entry frontmatter + file paths.
- `binder/index/tags.json` maps each tag -> list of entry ids.

## 6. CI requirements

On every PR touching `binder/**`:
1. Run `validate_entries`:
   - schema validation
   - uniqueness checks
   - section checks
2. Run `build_index` and ensure indexes are up to date
   - CI should fail if generated outputs differ from committed files

## 7. Governance

### 7.1 Ownership
- Entries list `owners` to indicate accountable maintainers.
- CODEOWNERS should map domains to responsible teams.

### 7.2 Review cadence
- `last_reviewed` should be updated when an owner verifies accuracy.
- Optional policy: warn (not fail) when `last_reviewed` is older than N days.

### 7.3 Deprecation
- Set `status: deprecated`.
- In `## Summary`, include:
  - Why deprecated
  - Replacement entry link/path

## 8. Security and privacy requirements
- No secrets. Ever.
- Avoid internal hostnames and sensitive endpoints unless appropriate for your environment and classification.
- Use `security` to reflect intended distribution (public/internal/restricted), but treat it as advisory.

## 9. Agent integration expectations
Agents should:
- Use `binder/index/entries.json` to shortlist candidates
- Open 1-3 entries maximum unless needed
- Cite entry path + section
- Prefer code truth if conflicts exist; propose a PR to reconcile

