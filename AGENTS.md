# Zomboid mods

Keep runtime mods independent and pure Lua. Test fixtures, upload tools and game files never enter a Workshop package.
Read DECISIONS.md and docs/releasing.md first. Preserve each Workshop ID.
Portable tests use project-test on sublet. Native game checks use explicit project-test --local on SERGBOOK.
Capture actual game frames for screenshots. Generated art is promotional illustration. Inspect every exported image.
Keep the existing source repos intact. No history rewrite, archival or removal is part of consolidation.

Every feature/release needs the categories in docs/mod-quality.md, including declared performance budgets and real MP coverage. Use tools/pz-test/check.py. Missing checks or stale visual-review hashes block release qualification. Never launch a graphical game probe without the shared hidden-window policy and OS audit.
