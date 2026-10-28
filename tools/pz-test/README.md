# Mod test loop

Use `python3 tools/pz-test/check.py MOD_DIR` for release qualification. See the [required quality gates](../../docs/mod-quality.md). `--fast` is portable/static only. Each mod needs its own `tests/checks.json`.

- `static.py MOD_DIR --prove` downloads pinned PZ_DevHarness into the executor workspace,
  compiles runtime Lua with Kahlua and validates references/JSON. Its current --prove fixtures target Dinner Together and prove two bad inputs fail. Other mods need their own negative fixtures.
- `native.py MOD_DIR` checks the real server, quits and restarts for persistence proof.
- `native.py MOD_DIR --multiplayer` uses two actual clients without copying game assets.
- `native.py MOD_DIR --multiplayer --rounds 2` batches fixture reset and cooldown checks.
- `package.py MOD_DIR OUTPUT [--install]` packages only runtime files.

Run configured project-test suites, never ad-hoc test copies. Every batch owns and stops
its games. The old APFS launcher remains behind `--legacy-copy` for comparison.
Sources, commands, timing evidence and limits: [playbook](../../docs/zomboid-mod-development.md).
No development helper ships to players.

- `native.py MOD_DIR --multiplayer --photos` appends the mod-specific `tests/photos.lua` fixture and exports the captures named in `tests/photos.json`. Native capture and visual inspection are separate gates.
- `portable.py` runs all four portable suites in one lease.

- `native.py MOD_DIR --multiplayer --rounds 2 --reconnect` restarts one real client and checks identity, state and duplicate notifications.
- `native.py MOD_DIR --performance` runs the mod-specific native budget probe and returns its metrics through a project-test artifact.
- All graphical runners use `window.py`, the fail-closed JVM window policy and an owned-PID macOS window auditor. Hidden clients still render real frames.
