
## 2026-04-13 — v3 spec docs authoring (COMPILER.md)
- **Learned:** When writing spec docs that cross-reference other specs, read all referenced files before writing — the DECISIONS.md may contradict the task brief (e.g., DECISIONS.md says `flock` but the task brief already decided on mkdir-based locking; trust the task brief for closed decisions).
- **Learned:** For compiler specs where the output is bash, the pseudocode-with-inline-comments pattern in Section 11 (showing compiler-generated structure without writing full implementation) is the right balance between specificity and staying within spec scope.
- **Avoid:** Do not write full implementation bash in a spec doc — show structure and intent with comments instead.

## 2026-04-08 — practices pipeline inbox→active migration
- **Learned:** When promoting inbox practices to active, the pattern is: Write new file to active/ with updated frontmatter (status, incorporated_in, effectiveness fields added), then rm original from inbox/. Single batch rm for all deletions is cleaner than individual calls.
- **Avoid:** Do not use Edit to move files — Write+rm is the correct approach since Edit only modifies in-place.
