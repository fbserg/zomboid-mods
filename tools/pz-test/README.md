# Mod test loop

- `static.py MOD_DIR --prove` downloads pinned PZ_DevHarness into the executor workspace,
  compiles runtime Lua with Kahlua and validates references/JSON. It proves two bad inputs fail.
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
