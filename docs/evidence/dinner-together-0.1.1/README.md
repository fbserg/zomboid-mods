# Dinner Together 0.1.1 evidence

Cosmetic release on Build 42.21.0 revision 4a0e9546ec. Runtime Lua and translation remain byte-identical to 0.1.0. The installed game jar pin is in qualification.json.

The quality adapter runs the required portable, static, native, multiplayer/reconnect, persistence and performance gates, then visual and package checks. Its report and native performance artifact are saved here after a successful run. Each entry records the host, exact snapshot/tree, receipt and cleanup result. Native and persistence share one full server restart suite.

Additional checks before qualification:

| Suite | Host | Snapshot | Result |
|---|---|---|---|
| All four portable suites | sublet | 3c03a97212fdd93264d8cb9c3595fc7e2484d52f | 97 tests, 0.484 s, cleanup true |
| Evidence guard tests | sublet | f507e6aa990f2ff57eb340fcbffa97bfa19c3918 | 6 tests, 0.422 s, cleanup true |
| Final native home captures | SERGBOOK.local | ec6158b98fb27d741c0e9bc464e7aba230fac223 | Real queued actions, both clients/world/stats, one notification each, hidden native and OS checks, two JPEG artifacts, cleanup true |
| Legacy Birds photo runner | SERGBOOK.local | 0d6fdbae23ac631e8e06a7f9a9af9eb3c6b3a77b | Hidden clone-app launcher and valid nonblack frames, scan/draw budgets pass, cleanup true |

Final photo receipt: 20261028T182128-4be7e83335e0. An existing furnished home at 10767,10634,0 supplies the cupboards, fridge magnets, dining table and lamp. Test setup controls clothing, food, lighting, weather, time and initial stats. No photo furniture enters the player mod. Native eating animations and production reward text are unchanged. Both full JPEGs, game posters and avatar at 128/268 pixels were inspected. workshop/visual-review.json binds approval to exact asset hashes.

Earlier photo fixtures that failed a native API call, desynchronized the world, or produced foreground lines were rejected. An interrupted reconnect round with overlapping player spawns is not counted as a pass. The final bounded reconnect fixture separates the actors.

The performance scaling actors are synthetic native players, not 64 network connections. The separate multiplayer gate uses two real clients and restarts one of them. The headless native geometry suite does not establish physical split-screen controller UI flow. No arbitrary mod-list compatibility is claimed.

Qualification attempt 20261028T182521-91368b53d438 failed its first MP round: Alice queued food but never reached server completion, while Beth completed. Cleanup was true. The test-only client now applies the same local invincible/ghost flags as the previously successful photo clients, and traces native food start/perform/stop without replacing their behavior. Cancellation fails immediately. The old log did not identify the cancellation cause. Encounter controls now apply on both sides. This failed attempt is not a release pass.
