# Dinner Together

A small Build 42.21 social mod with no dependencies.

Finish food near another survivor and both feel a little better. Each person must consume
at least five hunger points in one completed food action, within ten game minutes of the
other person, within four tiles on the same floor and with clear sight between them.
Open doors count. Walls, closed doors and windows do not.

The meal removes five boredom and three unhappiness points for each person, at most once
per 24 game hours. Someone on cooldown can still share a meal with a friend who has not
had the benefit. The server decides the result and saves the cooldown across restarts.

No plates, chairs, matching food or new recipes. Vanilla and modded food which uses the
normal eat action can qualify. An interrupted action does not qualify, even if it consumed
a partial portion. Eating alone has no effect. Split-screen local play uses separate slots.
Network notifications currently target the first local player on each connected client.

## Add and remove

The runtime is `DinnerTogether/`. Install that directory under `~/Zomboid/mods`.
Enable `DinnerTogether` on the server and clients. This repo's packaging helper can make
a runtime-only archive and a fresh local install without replacing any existing mod.

The mod adds no world objects, items or loot. Removing it leaves only inert reward timestamps
in world mod data. A replacement character on the same account/slot keeps the cooldown.
Another mod that replaces ISEatFoodAction.complete without chaining is incompatible.

## Verification

Portable boundaries: `project-test --suite dinner-together` on sublet.
Native food/geometry/restart: `project-test --local --suite dinner-engine` on the Mac.
Two-client network actions: `project-test --local --suite dinner-multiplayer` on the Mac.
The native suites require the installed Steam game and JDK, not a Steam upload.

See [the development playbook](../../docs/zomboid-mod-development.md) for sources, repeatable
methods and the shared runner. Issue [#141](https://github.com/fbserg/etc/issues/141) and
PR [#145](https://github.com/fbserg/etc/pull/145) hold the original implementation evidence.
[Subscribe on Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3828971865).

New source and bugs: [fbserg/zomboid-mods](https://github.com/fbserg/zomboid-mods).
Release assets and native screenshots now live beside the runtime. The current publication status and exact check receipts are in [VERIFICATION.md](VERIFICATION.md).

Observed on 2026-10-28, Build 42.21.0, with executor cleanup confirmed:

| Gate | Host | Tested snapshot | Result |
|---|---|---|---|
| Portable Lua 5.1 | sublet | b4b0489157ade89fb20a381da633d1e467c79880 | 12 pass, 0.161 s executor time |
| Native food, geometry and restart | SERGBOOK.local | f8251829d60b6e898d1afb3d4c8f63a02d75c104 | 6 scenarios pass, 249.46 s |
| Dedicated server and two real clients | SERGBOOK.local | a932e37f02b6d134dac02c01a10a0996059a3540 | server and both clients pass, 219.577 s |

The negative control disabled the reward hook and failed four tests. The original prototype package and local install verified the three initial runtime files by SHA-256. The release verification record covers the added art and posters. Existing save mod lists stayed untouched.

## Artwork and release

[Release playbook](../../docs/releasing.md). Selected generated illustrations and exact built-in image_gen prompts are in [workshop/art](workshop/art/PROMPTS.md). Gameplay images are native captures with two connected clients in a disposable scene. No furniture is required by the mod.
