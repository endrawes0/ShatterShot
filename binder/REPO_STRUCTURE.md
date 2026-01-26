# Binder Repo Structure

This repository contains **Binder**, a docs-as-code knowledge base designed for:
- Human collaboration via GitHub PRs and reviews
- Machine readability for AI agents
- Fast retrieval for engineering workflows

## Layout

binder/
  README.md
  PROJECT_SPEC.md
  REPO_STRUCTURE.md
  AGENTS.md
  CONTRIBUTING.md
  STYLE.md
  CODEOWNERS

  entries/
    <domain>/
      <topic>.md

  schemas/
    binder-entry.schema.json

  templates/
    entry.template.md

  index/
    entries.json
    tags.json

  scripts/
    validate_entries.py
    build_index.py

  .github/
    workflows/
      binder_ci.yml

