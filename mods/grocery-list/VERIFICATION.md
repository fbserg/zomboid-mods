# Release verification

## 0.1.0 first release

Published 2026-11-06 as [Workshop item 3834928311](https://steamcommunity.com/sharedfiles/filedetails/?id=3834928311). Build 42.21.0, revision 4a0e9546ec. No dependencies.

Final qualification used `check.py mods/grocery-list --published`, so its multiplayer gate hashed and staged the actual Steam download. All runs share tree ef9853e226714ecae4c6bb127aea3193fcf3ce0d. Each exited 0 with cleanup true. The full report is [qualification.json](../../docs/evidence/grocery-list-0.1.0/qualification.json). Performance data is in [performance.json](../../docs/evidence/grocery-list-0.1.0/performance.json).

- Portable: 18 tests pass on sublet. They cover parsing, plural matching, nested bags, short lists, used items, re-edited pages, delivery, offline shoppers, cooldown and reload, dead holders, split-screen slots and client authority. Disabling the cross-off fails 11 of them.
- Static: the game's Kahlua compiler and API check pass on SERGBOOK.local. A renamed translation file and a missing method both fail as negative controls.
- Native: on a headless server, a real Grocery List item, the craft recipe, vanilla items and a Small Backpack cross off a real page. Hand-back signs the list and pays both players once. A list on the floor is ignored. A full save and process restart keeps the page, the list's mod data and the cooldown.
- Multiplayer (downloaded runtime, receipt 20261106T214634-fc9fb202e358, 153 s): Alice writes through the vanilla journal window on a real client. The server receives the page and credits her. Beth's client shows every `[x]` mark. After hand-back, Alice's client shows the signed page. Notification counts are exact per player, stats agree on server and clients, and the world snapshot is unchanged. Forged client reward commands do nothing. Beth then restarts and reconnects. Round 2 shows the notices without paying again, so the username cooldown holds. All three client processes stayed hidden.
- Performance: with idle players, the added p95 is 0.03/0.09/0.09 ms at 2/16/64 players (budget 0.5/0.5/2 ms). With every player holding a 10-line list and 100 items, it is 0.22/1.41/5.97 ms (budget 0.5 ms per holder). Steady state sends no notifications or item syncs. 10,000 scans retained no measurable whole-JVM heap. The slow-callback and object-leak negative controls pass.
- Package: runtime-only ZIP SHA-256 8d7cba6d4b38d641bebfecf3bbca768c5f1c0d787e581bb4bec72bf7fb107eab. Native Workshop validation and the hash-bound visual review pass.

Public Steam metadata reports result 1, app 108600, creator 76561198033173095, visibility 0 and banned 0. The title, description and preview bytes match the source exactly. The gallery is illustration, list capture and thanks capture, and a repeat upload verified every public image byte. The Steam download matches all 10 files in workshop/runtime-sha256.json.

Findings during development:

- The dedicated server returns raw keys for this mod's translations, while vanilla item names translate. The signature was therefore made language-neutral.
- An empty server-command table arrives on the client as nil. The client crashed on `args.text` until the fix. The shared runner then missed the error because Kahlua tags mod errors with the display name. `native.py` now matches both the ID and the display name, which also covers Dinner Together.
- One qualification attempt failed on 2.04 points of natural boredom drift against a ±2 tolerance. The tolerance is now ±4 and the rewards are 10 points. A second attempt hit a sublet network timeout before any test ran. Neither attempt counts as a pass.

Not verified: a real crafting action, physical split-screen controllers, arbitrary mod lists, and what the game does with orphaned Grocery List items after removal.
