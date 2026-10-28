# Small Zomboid mods

Use the installed build as the authority. Current research target: Steam Build 42.21.0,
revision 4a0e9546ec. Do not copy game code into a published mod.

## Fast loop

1. Read the vanilla caller before choosing a hook. Find the authoritative completion,
   item tags, existing animations, native persistence and network sync before adding any.
2. Keep a mod under `mods/<slug>/<ModID>/42/`, with an empty `common/` directory.
   Runtime files stay separate from `tests/`, art source and Workshop metadata.
3. Write portable behavioural boundaries with Lua 5.1 through pinned `lupa==2.6`.
   Put the suite and snapshot paths in `.project-tests.json`. Run through project-test on sublet.
4. Disable the core effect temporarily. At least one behavioural check must fail. Restore it.
5. Run a native server probe. Use real items, loaded map squares and the actual completion
   method. A directly called completion does not prove the network timed-action path.
6. For multiplayer features, run two actual clients against a loopback dedicated server.
   Queue normal timed actions. Check both the server result and client stats/notifications.
7. For saved state, quit and restart the server against the same disposable cache.
   Reloading Lua against an in-memory table is only a portable approximation.
8. Run only affected gates after changes. Capture host, tested snapshot/tree, game build,
   pass counts and cleanup receipts. Distinguish engine, network and visual evidence.
9. Install/package the runtime folder only. Publish through the existing Workshop CLI
   after the exact public release has been authorized. A draft PR is not a released mod.

## Commands for Dinner Together

From the repo root:

```sh
project-test --suite dinner-together
project-test --local --suite dinner-static
project-test --local --suite dinner-engine
project-test --local --suite dinner-multiplayer
project-test --local --suite dinner-warm
python3 tools/pz-test/package.py mods/dinner-together /tmp/DinnerTogether.zip --install
```

The explicit Mac checks use the existing installed game. They run through project-test's
immutable workspace lifecycle. They never use personal saves or edit the Steam install.
The native runner in `tools/pz-test/native.py` stages the mod and its test-only `PZProbe`.
The mod supplies `tests/engine.lua`, `tests/mp.lua`, and `tests/mp-client.lua`.
`@ROLE@` becomes Alice or Beth. Use `PZ_TEST_*` verdicts so failures stop the run.

The server probe restarts once to prove persistence. Multiplayer uses two silent native
clients with no Dock icon or focus. It needs a logged-in Mac desktop and the game/JDK.
Every owned process stops before project-test retires its workspace. A shared lock keeps
these new native probes sequential across worktrees. Existing older probes do not use
that lock, so do not run them alongside this runner. Never reuse fixed ports on a live server.

The runner reuses the repo's test-only Java chunk loader and load-screen continuation.
Neither belongs in runtime distributions. Client logs are in cachedir/console.txt, not
necessarily launcher stdout. Inspect both. Native library inspection can delay cold startup.

## Tools researched on 2026-10-28

| Tool | What its source offers | Choice for this series |
|---|---|---|
| Existing `tools/pz-workshop/pz-workshop` | Stage, validate and publish through the installed game's uploader | Reuse for release. No new uploader. |
| Existing native probes | Headless server, silent native client, actual stats and network paths | Extract the repeated launcher into the small runner above. |
| [PZ_DevHarness](https://github.com/CalebFenton/PZ_DevHarness) | Unattended action tests, static checks, disposable worlds and multiplayer mode | Pinned external static checker via tools/pz-test/static.py. Native compiler, API and JSON checks are exercised, including negative controls. Stock detached warm launcher is not used. |
| [Forge Live](https://github.com/Twynzen/pz-forge-live) | Lua watcher and client/server reload through a bridge and RCON | Defer. Its README calls it alpha, verified on 42.20, and repeated-handler correctness is unmeasured. Completion wrappers need clean restarts. |
| [Umbrella](https://pz-umbrella.github.io/wiki/index.html) | Lua API stubs for editor/type hints | Useful optional editor aid. Verify signatures against installed Lua and jar before use. |

Do not make development helpers dependencies for players. Do not substitute mocked engine
interfaces for native evidence. Add shared runtime Lua only after two shipped mods need it.

## Parcel follow-up

Try normal nested-container persistence and native access checks first. If a seal cannot
block inventory, crafting and nearby transfer paths, test native item save/load before
choosing serialization. Preserve original food age and every custom property. Never invent
a property allowlist that silently drops modded data. Issue #142 owns this spike.

B42.21 translations use JSON, as in installed `Translate/EN/IG_UI.json`.
The copy-free launcher starts Java from the installed game directory, with private test
classes and cache paths. It does not construct a replacement asset tree.
The bootstrap is a dev mod, enabled before the main menu. B42 needs reset-mods-42_00.txt,
or it silently clears the fresh cache's selected mods. The installed game is never patched. A test-only Java agent suppresses GLFW focus calls
in the test process, using the JDK class-file API. The runner rejects any test process
that becomes the foreground app. Neither the launcher nor agent enters mod packages.
`--legacy-copy` retains the previous APFS clone launcher for comparison.

## Measured workflow for issue #146

PZ_DevHarness is downloaded into the disposable workspace, pinned to
`2a23ec6ddb0cb7d90bab43a14017e0edf6d28480`, with the archive SHA-256 checked.
No upstream source is vendored. Its documented external adoption supplies the static checker.
Its Java probe compiles our Lua with the game's Kahlua compiler and exports the actual API.
The Python checker validates references and JSON. A wrong translation filename and a missing
method must fail, then the restored runtime must pass. No skipped check counts as a pass.

Use portable checks during edits, static checks before native tests, and a native batch after
a meaningful runtime change. The warm suite runs two real-client scenarios in one lease:
a shared meal, then a repeated meal with reset fixture stats and no duplicate reward.
All processes stop when that batch ends. Every new source snapshot starts cold. This avoids
stale wrappers after runtime edits. Cold two-client and actual save/restart gates remain.

SERGBOOK.local, Build 42.21.0, observed timings (not guaranteed future runtimes):

| Gate | Earlier | New observation |
|---|---|---|
| Two real clients | 219.577 s, one scenario | 105.591 s, two scenarios, snapshot 72664935632c26e2f462761583078ebf44a5eeb5 |
| Food/geometry/save/restart | 249.460 s | 74.782 s, snapshot 0faefd0459be934cc0bc3521183456fe4dfa7107 |
| Upstream static proof | No equivalent | 21.888 s cold including compile/API export, snapshot 565e8ebc3286ee01d82e9fd00f8deb4a06564c42 |
| Static checker with its data warm | No equivalent | 0.060 s per check inside the same lease |

Those receipts report exit 0 and cleanup true. An intentionally interrupted native run
exited 130 with cleanup true; the next server reused its port successfully. A failing launch
also cleaned up. No processes are detached and no existing process is polled or stopped.

Final no-focus batch: 99.779 s, snapshot `2a272bc2b21e2e75c4d97f48331a4486cacb0739` on SERGBOOK.local.
Both real clients completed both rounds, with one notification each. The foreground-process
guard remained enabled throughout. Cleanup was true. The prior unpatched focus run failed
that guard, so the check has an observed negative control.
