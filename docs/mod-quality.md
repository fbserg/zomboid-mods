# Required checks for a mod

Use one release command from the repository root:

```sh
python3 tools/pz-test/check.py mods/dinner-together
```

For quick edits, add `--fast`. That runs portable and static checks only and does not qualify a release. The adapter calls the existing project-test executor, not another test service. Portable tests run on sublet. Native game tests use explicit `--local` on SERGBOOK. No test process, world or game copy survives its lease.

Each mod declares `tests/checks.json`. All six test categories need real configured suites. A missing declaration, failed receipt, failed cleanup, changed test/runtime source or changed image fails the command. Native and persistence can share the same restart suite and run once. The report records the executor, exact snapshot/tree, timings and stated coverage limits for each check. Performance data returns as a JSON artifact. The final package and visual checks run after the suites.

| Check | Required evidence |
|---|---|
| Portable behavior | Normal use, nothing happens when it should not, limits, cancellation, invalid/stale input, and a discriminating negative control for new behavior. Cover single-player and server/client branches. |
| Static/API/load | Compile with the installed game's Kahlua compiler, resolve actual API/reference/translation names, load the mod on the native authority/client it targets, and reject mod Lua errors. Keep known vanilla noise distinct. |
| Native behavior | Real items, actions, geometry and stats. A direct completion probe verifies engine interfaces. It does not establish the network action queue or human UI flow. State the difference. |
| Multiplayer | Two real clients, normal queued actions, server ownership, forged/stale/duplicate request rejection where relevant, both clients' state/notifications, bounded message counts, and a real reconnect. Compare world state if objects can change. Do not call synthetic actors 64-player multiplayer proof. |
| Persistence/removal | Full process save/restart for stateful mods, reconnect identity/cooldown behavior, add/remove behavior and old-save implications. Verify inventory transactions fail without loss or duplication. No-state mods still document what remains after removal. |
| Performance | Declare workload and budgets before measuring. Measure normal and stressful scale, paired baseline/noise, callback cost and retained memory. Count network messages. For render/tick mods, also measure idle cost and frame tails. Do not substitute whole test duration for gameplay cost. |
| Package/compatibility | Runtime-only ZIP, every icon/poster/translation/dependency path, native Workshop content validation, exact supported build and tested dependency set. Check hook chaining and conflicts that can block the mod. Do not certify arbitrary mod lists from a vanilla run. |
| Visual/release | Human-style visual inspection with asset hashes, useful native frames and clear instructions. Match the feature's feeling, not just its API. After publication, check public copy/images and download the exact runtime for another native smoke test. |

## What we reuse

Research read on 2026-10-28:

| Project | Useful part | Adoption |
|---|---|---|
| [PZ_DevHarness](https://github.com/CalebFenton/PZ_DevHarness), `2a23ec6ddb0cb7d90bab43a14017e0edf6d28480` | Real action tests, fixture restore, server/client comparisons, world leak snapshots, trace timings and static checks | Our pinned external dependency supplies the static checker and the actual shared Snapshot module. It is fetched into the executor workspace with its archive checksum verified. No upstream code is vendored or shipped to players. Its full action library is the first choice to evaluate for new complex action mods. Keep our bounded two-client and hidden-window adapter. |
| [pzkit](https://github.com/knoxy4/pzkit), `afa3311ae695e9ce924bf1077c09560b38f360ad`, MIT | Native script indexing, reference checks, boot/error verdict and clean-boot noise comparison | Useful for data-heavy mods. Its boot check does not replace this feature's real multiplayer, restart and performance tests. Do not add a second overlapping static tool here without a measured benefit. |
| [PZ_Optimization](https://github.com/xD3I/PZ_Optimization), `adef184123cc38be97c9494be315a686ccb20ad6` | Paired benchmark baselines, frame tails, utilization and run-to-run noise floors | Reuse the measurement method. Its renderer patches and Linux/Windows capture stack are not dependencies for these pure Lua mods. No blanket repository license was declared at inspection, so do not vendor its code. |

PZ_DevHarness has no blanket LICENSE file at this pin, but documents external harness adoption. We execute the pinned external tool for development. The download is checksum-checked and disappears with the executor workspace. Never package it as part of a player mod.

## Dinner Together's performance contract

The mod runs on food completion and server notifications. It has no custom per-frame renderer or recurring idle hook. Its primary budget is the added server cost of a real native food completion.

- Warm the vanilla and wrapped paths, then take two vanilla baselines and 31 samples of 32 actions per workload. Use the native millisecond clock. Report percentiles of batch means, with the 1/32 ms timer floor. These are not individual-call p95 timings or whole-game FPS.
- Stress 2, 16 and 64 nearby native actors. Budget added p95 batch mean at 0.5 ms/action for 2/16 and 2 ms/action for 64. Actors in this scaling probe are synthetic. The separate MP gate uses real sockets and clients.
- Run 10,000 cooldown meals. Require zero production notifications and less than 16 MiB retained JVM heap growth after collection. Kahlua's `collectgarbage('count')` reports the whole JVM heap, not Lua-only memory. Native world threads can add noise, so record the measured delta and interpret it accordingly.
- A deliberately slow callback must fail the same timing predicate. The upstream Snapshot module must detect a deliberately placed native object and then confirm its removal. The ordinary workload must leave the world unchanged.

If a future change adds a periodic scan or UI renderer, this contract must gain idle/scan/draw and frame-tail budgets before that change qualifies. Use the same scene, settings and hidden-render mode for baseline and candidate. A hidden renderer's FPS is not a claim about a user's visible desktop FPS.

## Invisible native clients

A native graphical client still needs macOS WindowServer and renders real frames. It is not a display-free server. The test-only agent forces invisible/unfocused creation hints, suppresses show/focus calls, disables the GLFW-created menu bar and checks the native visibility/focus flags during event processing. A macOS auditor separately checks only owned PIDs for on-screen windows and foreground focus. The guard's negative controls run without showing a window. A policy failure aborts the check.

All graphical test entry points must attach this shared policy and poll the OS auditor. No Dock/window hiding after a visible launch is accepted. No game file is patched. The agent and auditor never enter runtime ZIPs.

## Visual acceptance

A screenshot can prove a feature and still be a bad listing image. Dinner Together needs a furnished, lived-in home, readable survivors and meal/comfort cues. Road shoulders, foreground wires, empty setup rooms and random UI panels fail that brief. Use ordinary native furniture, food and lighting in a disposable scene. State that the furniture is staged and optional.

Write `workshop/visual-review.json` only after inspecting the actual exported images, thumbnail sizes and game posters. Record the capture snapshot, selected art sources, exact file hashes and every visual criterion. A changed asset invalidates the review. Keep generated illustration and game captures distinct. Do not draw a fake gameplay screenshot.

## Existing mods

This contract applies to new features and releases. Dinner Together is the first complete adopter in this pass. Older mod-specific tests remain available. Their old evidence does not automatically become a pass under this stronger contract. In particular, a one-client loopback remains a one-client loopback, and a per-callback timing remains a per-callback timing. An older mod needs its own declared suites and current evidence before the new command can qualify its next behavior release.
