# Release verification

## 0.1.3 smaller menu posters

Published release inputs reduce only the three in-game posters to 768 pixels and set modversion 0.1.3. Meal Lua, translations, full-size Workshop/gallery files, preview and icon remain unchanged from 0.1.2. All three outputs were visually inspected and their new hashes are in the existing visual review.

The native menu probe measures 6.25 MiB padded RGBA base storage versus 24.25 MiB before, an 18 MiB reduction (about 74%). It reuses all four textures through 100 actual native panel setter cycles and passes the retained-heap budget and hidden-window/OS audit. It does not measure GPU residency or certify the reporter's unknown mod stack.

The complete release checker passed 18 portable tests on sublet, static/API negative controls, native food/geometry and full server restart, two real clients with reconnect, performance budgets, visual hashes and runtime-only packaging. Exact snapshots/trees and cleanup receipts are in [the 0.1.3 evidence bundle](../../docs/evidence/dinner-together-0.1.3/README.md). The 10,000 cooldown meals produced no notifications and retained 42.83 KiB whole-JVM heap, below 16 MiB.

Qualified ZIP SHA-256: 546e78e6b039f0644a3d0c000ce16a2183abcbca8e6b220641911b200f220fcc.

The [GitHub 0.1.3 release](https://github.com/fbserg/zomboid-mods/releases/tag/dinner-together-v0.1.3) serves a 1,705,362-byte ZIP that matches the qualified package byte for byte. The requested [Steam update comment](https://steamcommunity.com/sharedfiles/filedetails/?id=3828971865#comment_571553910742931412) was posted as the verified owner after downloaded-release checks. The shortened replacement comment is visible anonymously and matches the prepared text. See update-comment.json in the evidence bundle. No duplicate was posted.

The published Workshop download matches all seven runtime hashes and passed the real two-client/reconnect release suite on SERGBOOK.local, snapshot 77ce14b284428f582691b1fd316ab399a6b265a4, tree 42d509654740c35e2be3289868ad4c2abc1fdf82, receipt 20261104T203215-75f07c3454df, 136.564 seconds, exit 0, cleanup true. Both food rounds, stats/world agreement, cooldowns and notification counts passed. All three client processes remained hidden. Public copy/preview and every full-size gallery byte passed exact verification. The guarded personal local install now matches 0.1.3 too.

## 0.1.2 memory retention and multiplayer setup

Full release qualification passed on 2026-11-04. The [evidence bundle](../../docs/evidence/dinner-together-0.1.2/README.md) records the original failed retention probes, before/after performance, exact test snapshots and coverage limits.

- 18 portable tests passed on sublet, including collection after a player leaves and stale-session rejection for reused network IDs and local slots.
- Native Build 42.21 compilation/API checks and both negative controls passed. Native food, geometry, instance UID and full server restart checks passed on SERGBOOK.local.
- Two real hidden clients completed two meal rounds, with Beth restarted between rounds. World/stats agreed, cooldowns persisted and the server sent exactly two production notifications. Native visibility/focus guards and the owned-PID OS audit passed.
- Native 2/16/64-actor callback budgets passed at 0.03125/0.125/0.1875 ms added p95 batch means. The 10,000-meal cooldown probe retained 64.95 KiB whole-JVM heap after collection, below 16 MiB, with zero notifications. Both performance negative controls passed.
- Runtime-only packaging, native Workshop validation and the unchanged hash-backed visual review passed.

The original 0.1.1 cache retained player objects until another meal pruned them. The new cache stores only scalar meal records and native instance UID strings. This fixes that retention path without an idle hook. The original steady-meal benchmark also passed. No reporter log or reproduction exists, so the full reported memory problem is not established by this fix. The multiplayer client only displays notifications.

The description now supplies Workshop ID 3828971865, Mod ID DinnerTogether and copyable server settings.

### 0.1.2 live and downloaded proof

The existing public Workshop item now serves 0.1.2. Exact public copy, owner, visibility, preview bytes and all three gallery files/order passed verification. All seven downloaded runtime files match workshop/runtime-sha256.json. The personal local copy matched the previous manifest before its two changed files were updated, and now matches 0.1.2.

The downloaded runtime passed two real-client meal rounds plus a fresh Beth reconnect on SERGBOOK.local, snapshot 2600a1c068b51c7c8f095180f65cea939863e518, tree ba181f967ae2859892a5bf9e6432b21665eebc58, receipt 20261104T200549-d266f8b3924a, 130.953 s, exit 0, cleanup true. Both clients' food, world/stats and notifications passed. The server sent exactly two production notifications and the reconnect received no duplicate. All three client PIDs passed the native hidden-window policy and OS audit. See [downloaded-release.json](../../docs/evidence/dinner-together-0.1.2/downloaded-release.json).

Qualified ZIP SHA-256: 0c2330493f5b05c8507ac13cc0ccfda5ed2be4cc384233f6ab156d7ccc59bad5.

The [public GitHub 0.1.2 release](https://github.com/fbserg/zomboid-mods/releases/tag/dinner-together-v0.1.2) serves the qualified ZIP. Its anonymous 4,848,866-byte download matches byte for byte. See [github-release.json](../../docs/evidence/dinner-together-0.1.2/github-release.json).

## 0.1.1 quality and home captures

The complete required check command passed on 2026-10-28. Exact receipts, executor hosts, snapshot commits/trees, measured performance and coverage limits are in [the evidence bundle](../../docs/evidence/dinner-together-0.1.1/README.md), [qualification.json](../../docs/evidence/dinner-together-0.1.1/qualification.json) and [performance.json](../../docs/evidence/dinner-together-0.1.1/performance.json).

- Portable Dinner rules: 12 pass on sublet. The complete four-mod portable run passed 97 tests, and six check-runner evidence guards passed on sublet.
- Installed-build static/API compilation: pass with two discriminating negative controls.
- Native behavior: six scenarios including a full server save and process restart pass on SERGBOOK.local.
- Multiplayer: two real clients, two rounds, a fresh Beth process/reconnect, forged command rejection, real food completion, world/stat agreement, exactly two total production notifications and preserved cooldowns pass on SERGBOOK.local.
- Performance: added p95 batch mean is within timer noise at two native actors, 0.09375 ms at 16, and 0.1875 ms at 64. Budgets are 0.5/0.5/2 ms. Retained whole-JVM heap after 10,000 cooldown meals was 12.85 KiB, below 16 MiB. Zero notifications. The slow callback and native object leak negative controls both passed. Synthetic scaling actors are not network clients.
- Every monitored game window stayed invisible/unfocused by native attributes and the owned-PID macOS audit. Both native guard negative controls passed without showing a window. Real game screenshots still render.
- The runtime-only package, native Workshop validation and hash-backed visual review passed. The two new home photos show ordinary queued food actions and real reward text in an existing furnished kitchen. The avatar and lead illustration remain unchanged. No furniture is required or added by the mod.

Runtime Lua and translation are byte-identical to 0.1.0. The release changes metadata and the two game posters. Physical split-screen controller UI flow and arbitrary mod-list compatibility remain unverified. One earlier MP qualification attempt failed before the client fixture safeguards/traces were aligned. It is not counted as a pass.

## 0.1.1 live and downloaded proof

Published to the existing [Workshop item 3828971865](https://steamcommunity.com/sharedfiles/filedetails/?id=3828971865). Public metadata reports result 1, app 108600, creator 76561198033173095, visibility 0 and banned 0. Exact authored title/description, preview and every gallery byte match. The illustration slot/URL is unchanged. Only the two gameplay slots were replaced. The new replacement helper's idempotent read-only retry also verified every public image byte. See workshop/published.json and public-metadata.json in the evidence bundle.

The final complete checker used --published. Its MP gate hashes and stages the actual Steam download. SERGBOOK.local, snapshot ddea308e3b866f81796b4af4ec5ca867a513d315, tree 1a1df90490104dd43116bbdfa40b9ef6e4be6d47, 157.298 s, exit 0, cleanup true. Both real clients completed both normal food actions, Beth restarted/rejoined, world/stats agreed, Alice kept one notice and the reconnected Beth received zero new notices. The server sent exactly two production notifications across both rounds. The native visibility/focus guards and owned-PID OS audit passed for all three client processes. All seven runtime files match workshop/runtime-sha256.json.

The final native fixture declares and asserts a zero-zombie sandbox and disables PvP. Earlier native hit reactions could cancel an unrelated meal despite safety flags. Both failed postflight/qualification attempts remain documented and were not counted. The ordinary timed actions and their completion assertions remain intact.

The full uploader's submission-description getter appended a footer after the earlier metadata-only getter fix. A native regression guard first failed before a write, then passed after both getters returned the authored text. A repeated full upload and exact public API comparison verified the corrected path. No runtime file changed for that publisher fix.

The known seven-file local prototype was checked against the old manifest before update, then verified against 0.1.1. Saves and active mod lists stayed untouched.

The [GitHub 0.1.1 release](https://github.com/fbserg/zomboid-mods/releases/tag/dinner-together-v0.1.1) is public. Its downloaded 4,848,787-byte asset exactly matches the qualified ZIP. See github-release.json in the evidence bundle.

Runtime-only ZIP: DinnerTogether-0.1.1-b42.21.zip, SHA-256 2d375083ab8182d6118dc0caaebc839d7b9dbbdf607ac4a4006961281cdfde18. No development helper enters this archive.

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
