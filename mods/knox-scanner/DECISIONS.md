# Decisions

## 2026-11-19: a text file is the interface

Decision: the mod appends one JSON line per event to `Zomboid/Lua/KnoxScanner.txt`. Each line holds a ready Discord webhook body and plain fields. A command outside the game posts or reads the lines.
Evidence: game Lua has no network access. `getFileWriter` refuses every extension except ini, cfg, txt, log and json. The first native run failed on `.jsonl` for that reason.
Reopen if the game gives mods an HTTP call.

## 2026-11-19: client only, no network messages

Decision: all behaviour runs on each player's client and reports the local character. The server loads the shared file and does nothing.
Evidence: every event is visible to the client that owns the character. The two-client gate counted zero mod network messages. A server-side version would see every player, but a dedicated server writes to its own disk, where players cannot run the outside command.
Reopen if server owners ask for one feed for the whole server.

## 2026-11-19: one poll per game minute, horde scan behind a cooldown

Decision: `EveryOneMinute` reads a handful of values and compares them with the last poll. The zombie scan runs only with its tick box on and its 6-hour cooldown elapsed, and uses one `DistToSquared` call per zombie.
Evidence: the quiet poll measured 0.005 ms. The first scan read x and y separately and took 0.134 ms for 90 zombies, over its budget. One distance call took 0.036 ms for the same 90.
Reopen if a measured city-sized zombie list makes the scan visible.

## 2026-11-19: no player names in the feed

Decision: lines say "a survivor" and carry no username or character name.
Evidence: the feed is meant for shared channels and bots. A consumer that needs identity can add it from the webhook or the machine it runs on.
Reopen on request.

## 2026-11-19: performance evidence comes from the multiplayer suite

Decision: `tests/checks.json` points the performance gate at `scanner-qualified-mp` and takes the artifact from Alice's client. The shared `--performance` runner is a server probe and cannot load a client mod.
Evidence: the mod has no server behaviour to measure.
Reopen if the shared runner gains a client performance mode.
