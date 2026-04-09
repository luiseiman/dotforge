
## 2026-04-08 — practices pipeline inbox→active migration
- **Learned:** When promoting inbox practices to active, the pattern is: Write new file to active/ with updated frontmatter (status, incorporated_in, effectiveness fields added), then rm original from inbox/. Single batch rm for all deletions is cleaner than individual calls.
- **Avoid:** Do not use Edit to move files — Write+rm is the correct approach since Edit only modifies in-place.
