# Release verification

## 0.1.0 first release

Published 2026-11-19 as [Workshop item 3842315081](https://steamcommunity.com/sharedfiles/filedetails/?id=3842315081). Build 42.22.2, revision 3d39148846. No dependencies.

Final qualification used `check.py mods/knox-scanner --published`, so its multiplayer gate hashed and staged the actual Steam download. Each run exited 0 with cleanup true. The full report is [qualification.json](../../docs/evidence/knox-scanner-0.1.0/qualification.json). Performance data is in [performance.json](../../docs/evidence/knox-scanner-0.1.0/performance.json).

- Portable (receipt 20261119T073155-8fbdb366ccaa): 14 tests pass on sublet. They cover the silent first poll, each event kind, the exact JSON line, the tick boxes and master switch, the note switch, cooldowns, the local-player death rule and quoted text. With the line write disabled, 7 of the first 11 failed.
- Static (receipt 20261119T073158-921b8dd31c87): the game's Kahlua compiler and API check pass on SERGBOOK.local. A renamed translation file and a missing method both fail as negative controls.
- Native and persistence (receipt 20261119T073204-ea72ca63eee4): a headless dedicated server that lists the mod loads the shared file, has no client options, writes no feed file and saves no mod data. The same holds after a full save and process restart.
- Multiplayer (downloaded runtime, receipt 20261119T073309-446bc374c442): two real clients on a loopback dedicated server. Each sees 14 translated tick boxes, the unbound key, the mod panel icon and three posters. The real `EveryOneMinute` hook records a silent baseline and then writes a kill milestone with its note. Each client then writes and reads back town, bitten, hurt, power, helicopter, days, request and horde lines from its own feed file. The horde is 45 real zombies spawned by the server. A tick box, the master switch and the note switch each silence their part. Beth restarts and reconnects: her feed file survives and her fresh baseline is silent. Alice dies for real and gets one death line. Beth's feed gets nothing from that death. The server counted zero mod network messages. All three client processes stayed hidden.
- Performance (receipt 20261119T073600-f26345640c96, Alice's client): switched-off poll 0.0005 ms (budget 0.005). Quiet poll 0.0055 ms (budget 0.05). Zombie scan 0.028 ms for 45 real zombies (budget 0.0015 ms per zombie). Line write 0.125 ms (budget 2). 20,000 polls retained 88.59 KiB of whole-JVM heap (budget 16,384). All are p95 of 31 batch means from a 1 ms clock. The slow-callback negative control fails the poll budget. The mod polls once per game minute and has no per-frame hook.
- Package: runtime-only ZIP SHA-256 44c73ee7c473d9bd8826a1d7ead3db197e1b34e56a414aeac2b10071f85dc861. Native Workshop validation and the hash-bound visual review pass.

Public Steam metadata reports result 1, app 108600, creator 76561198033173095, visibility 0 and banned 0. The title, the 4,750-character description and the preview bytes match the source exactly. The gallery is illustration, horde capture and options capture, and every public image byte matches. The Steam download matches all files in workshop/runtime-sha256.json.

Findings during development:

- The game's `getFileWriter` returns nil for any extension except ini, cfg, txt, log and json. The first native run crashed on `KnoxScanner.jsonl`. The portable fixture had accepted it. The feed is now `KnoxScanner.txt` and the fixture refuses other extensions.
- The first zombie scan read x and y for each zombie and took 0.134 ms for 90 zombies, over its 0.1 ms budget. One `DistToSquared` call per zombie took 0.036 ms for the same 90. The budget is now stated per zombie.
- The first performance probe ran its "quiet" polls beside the horde and wrote two stray horde lines. The quiet part now runs before any zombie exists, and both parts assert the real feed is untouched.
- Two test races were fixed. A client could see the other client's horde before its own quiet checks ended, so the server now waits for both. The real minute hook could write the horde line before the direct test poll, so the check counts lines across both.
- `addZombiesInOutfit` refuses to spawn in the shared zero-zombie fixture world and logs a warning per zombie. The fixture switches the sandbox option for the spawn and uses `createZombie`.
- The shell wrapper that routes Codex through the gateway has no image tool. The plain binary generated both illustrations.

Not verified: a landmark or storm line in a native run, a character walking across a town border, the helicopter schedule and storm start on a client of a live server, a real Discord webhook (the Discord message endpoint accepted the same line with its extra fields), the shipped shell and PowerShell scripts, Windows, and arbitrary mod lists.
