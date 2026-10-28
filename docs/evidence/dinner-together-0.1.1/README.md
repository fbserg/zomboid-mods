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

The post-publication exact-copy check caught the vanilla full uploader appending Workshop/Mod IDs through getSubmitDescription. The earlier metadata-only path used getDescription. A native regression guard first failed before any write, then passed after both getters returned the authored copy. The full content upload was repeated to exercise the corrected path. Runtime files and the qualified ZIP did not change. This publisher-only follow-up uses native validation, actual upload and public byte/copy checks rather than repeat unchanged gameplay suites.

Postflight 20261028T183712-57950e830ce6 verified all seven downloaded files, then deliberately failed on an observed PlayerHitReactionState cancellation. Cleanup was true. Local safety flags did not fully isolate the fixture. The runner now writes a version-6 zero-zombie sandbox and disables PvP. The server asserts the zero population and clients reject a live local zombie before queuing food. No ordinary action or reward assertion was relaxed. The final complete qualification uses --published, so the actual Workshop download receives the stronger reconnect gate in the same full run. This supersedes the earlier attempt's fixture evidence.

## Final published qualification

The complete --published command passed. Qualification and performance JSON now contain the final peaceful-fixture results. Native restart passed on SERGBOOK.local at snapshot 15d7dc9fce998c6aa13d1700ce7698ce10e8c831. The downloaded two-client/reconnect gate passed at ddea308e3b866f81796b4af4ec5ca867a513d315, tree 1a1df90490104dd43116bbdfa40b9ef6e4be6d47, receipt 20261028T184157-a609ad5ca7dd, 157.298 s, cleanup true. The performance gate passed at 574ddcb3b1a0a0e7c99cdcff1840b07071006470, with added p95 batch means 0.01562/0.09375/0.1875 ms at 2/16/64 actors, 12.85 KiB retained whole-JVM heap, zero notifications in 10,000 cooldown meals and two passing negative controls. Every category, native Workshop validation, package check and hash-backed visual review passed.

Public title, description, preview and all gallery files matched after the corrected full upload. The illustration URL stayed unchanged. A read-only repeat of gallery replacement returned GALLERY_ALREADY_SET after byte checks. The local known seven-file prototype also matches the new runtime manifest. Public metadata is in public-metadata.json. The final downloaded receipt is downloaded-release.json.

Release ZIP SHA-256: 2d375083ab8182d6118dc0caaebc839d7b9dbbdf607ac4a4006961281cdfde18. Runtime Lua SHA-256 remains 1b915dfcb492245140f80736a909308988708cb48abfec878057ea156f1156d3.

The GitHub 0.1.1 release targets 9e692126f4d016145c098f5ddd82ac95281d4eb2. Its anonymous public download matched all 4,848,787 bytes of the qualified runtime ZIP and its SHA-256. See github-release.json.
