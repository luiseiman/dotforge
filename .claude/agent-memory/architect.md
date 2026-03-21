## 2026-03-21 — Plugin marketplace restructuring

- **Decision:** Plugin-first architecture (Option A). The repo root IS the plugin. Factory dirs (template/, stacks/, registry/, practices/) coexist as extras ignored by the plugin system. Skills and agents already compatible. New files needed: root settings.json (deny-only), hooks/hooks.json (wiring), commands/ at root (moved from global/commands/).
- **Rejected:** Dual-root manifest (Option B) — maintenance drift between two manifests. Monorepo split (Option C) — too much tooling overhead for a markdown-only project.
- **Key risks:** bootstrap-project skill reads from template/hooks/ — needs path update or symlinks. forge.md dispatcher references need updating. Version bump to 3.0.0 justified by path changes.
- **Open:** Exact plugin.json schema for marketplace submission not yet confirmed. Need spec before finalizing manifest fields.
