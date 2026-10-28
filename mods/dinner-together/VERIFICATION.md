# Release verification

## 0.1.1 quality and home captures

The complete required check command passed on 2026-10-28. Exact receipts, executor hosts, snapshot commits/trees, measured performance and coverage limits are in [the evidence bundle](../../docs/evidence/dinner-together-0.1.1/README.md), [qualification.json](../../docs/evidence/dinner-together-0.1.1/qualification.json) and [performance.json](../../docs/evidence/dinner-together-0.1.1/performance.json).

- Portable Dinner rules: 12 pass on sublet. The complete four-mod portable run passed 97 tests, and six check-runner evidence guards passed on sublet.
- Installed-build static/API compilation: pass with two discriminating negative controls.
- Native behavior: six scenarios including a full server save and process restart pass on SERGBOOK.local.
- Multiplayer: two real clients, two rounds, a fresh Beth process/reconnect, forged command rejection, real food completion, world/stat agreement, exactly two total production notifications and preserved cooldowns pass on SERGBOOK.local.
- Performance: added p95 batch mean is within timer noise at two native actors, 0.0625 ms at 16, and 0.21875 ms at 64. Budgets are 0.5/0.5/2 ms. Retained whole-JVM heap after 10,000 cooldown meals was 140.77 KiB, below 16 MiB. Zero notifications. The slow callback and native object leak negative controls both passed. Synthetic scaling actors are not network clients.
- Every monitored game window stayed invisible/unfocused by native attributes and the owned-PID macOS audit. Both native guard negative controls passed without showing a window. Real game screenshots still render.
- The runtime-only package, native Workshop validation and hash-backed visual review passed. The two new home photos show ordinary queued food actions and real reward text in an existing furnished kitchen. The avatar and lead illustration remain unchanged. No furniture is required or added by the mod.

Runtime Lua and translation are byte-identical to 0.1.0. The release changes metadata and the two game posters. Physical split-screen controller UI flow and arbitrary mod-list compatibility remain unverified. One earlier MP qualification attempt failed before the client fixture safeguards/traces were aligned. It is not counted as a pass.

## 0.1.0 historical verification

Build 42.21.0, revision 4a0e9546ec. Runtime Lua is byte-identical to the original tested prototype. No dependencies.

## Consolidated repository checks

| Gate | Executor | Exact snapshot | Result |
|---|---|---|---|
| test | sublet | b46a8f300224bba0db9ebd9ca5bc7b6ef87e491c | 97 tests (54 farm, 10 repaint, 21 birds, 12 dinner), cleanup true, 0.456 s |
| dinner-static | SERGBOOK.local | 2c90a09db1f7187d2e1f0e14419edaa05e61554a | native compilation, API/JSON checks, two negative controls, cleanup true, 4.723 s |
| dinner-engine | SERGBOOK.local | 9c0030711565d1fbb761a9a6e21f5a759eeb38a3 | six native scenarios including full process restart, cleanup true, 74.71 s |
| workshop-ugc | SERGBOOK.local | c14b7a18722db67db4934b1758a24f4e43fdd760 | four existing gallery files read through native Steamworks, cleanup true, 0.413 s |
| dinner-photos | SERGBOOK.local | da03c1487e8712b11d975e2abfda141e08e188eb | two real clients, vanilla actions, stats and notification, cleanup true, 149.267 s |

## Pictures

Avatar: workshop/art/dinner-avatar.png. Wide illustration: workshop/art/good-company.png. Exact prompts and tool are in workshop/art/PROMPTS.md. Selected exports were inspected at 128 and 268 pixels. Both game screenshots are native 1440x900 frames, inspected after export. The scene uses server-provided clothing, apples, controlled noon weather and starting stats in a disposable world. The actual production meal rule, action and halo message run unmodified. No tables or plating feature is implied.

## Publication

Published Workshop item [3828971865](https://steamcommunity.com/sharedfiles/filedetails/?id=3828971865), public, app 108600, creator 76561198033173095, result 1, visibility 0, banned 0. The public API description exactly matches workshop.txt, with the vanilla ID footer removed by the shared uploader. Preview and all three gallery files match the public CDN bytes exactly. Gallery order is good-company.jpg, dinner-meal.jpg, dinner-company.jpg. See workshop/published.json.

Final photo-export and native panel gate passed on SERGBOOK.local, snapshot 452c169d6d8762dec5760744de4c3eb01b4282c4, 99.958 s, cleanup true. Both clients decoded the icon and all three posters. Both native screenshots were exported through the declared capture manifest and inspected. Steam owner 76561198033173095 ModeratExtremist verified through the game uploader and Steamworks. Native content validation passed. Gallery helper read-only query passed. A different non-empty gallery was deliberately rejected before a write.

The Care Packages experiment is not part of this release and remains unproved. Earlier failed or cancelled photo iterations were not counted as passes.

## Downloaded-release end to end

Downloaded through installed Steamworks without changing subscriptions. All seven runtime files match workshop/runtime-sha256.json and the release source. The native runner staged the actual downloaded runtime, not a source substitute.

Executor SERGBOOK.local, exact snapshot f1b4b42970f531b4137502aa07348c49b3cdf06d, tree a10b95898bbcf7f6f153a08001e9865b66764de8, suite dinner-release, 112.071 s, exit 0, cleanup true. Both real clients completed two normal food actions each. Each had one production notification across both rounds. Server stats, client sync and saved cooldown timestamps passed. Both game clients decoded the icon and three posters.

The initial downloaded-release batch stalled in round two and was interrupted, receipt 20261028T165628-08dfe04fbbe0, cleanup true. It is not a pass. The fixture now uses the server-issued food item ID and waits for the previous action to finish before acknowledging a round. A stricter native assertion verifies real hunger consumption on every action. Runtime Lua did not change.

The earlier local prototype was hash-checked against its original three-file source before its metadata/assets update. The resulting seven-file local install matches the published runtime. No saves or active mod lists changed.

Runtime-only ZIP SHA-256: 8b964a3e80e44a861c3e5f28d2a8bb4eeef68c75c7a5feac4c97ed3dadfa3988. It includes common/ and the seven runtime files.

## Gallery limit and correction

Steam's first gallery batch returned result 25. GetQuota reported total 1,000,000 bytes and 109,018 available. The exact 890,982-byte reservation matched the first two files of our failed batch. The gallery remained empty. Only those two zero-byte staging files created by this session were cleared. No other Cloud files or Workshop content changed. The next batch totaled 910,343 bytes and succeeded. All three public image bytes were checked. The helper now checks the entire batch against available Cloud quota before upload. The selected PNG originals remain unchanged.

Anonymous Steam HTML returned HTTP 429 during the browser check. Public API data and direct public CDN files were verified without a web login, and the native download/run passed.
