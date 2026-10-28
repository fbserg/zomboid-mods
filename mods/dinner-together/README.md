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

Release qualification: `python3 tools/pz-test/check.py mods/dinner-together` from the repository root. The [quality contract](../../docs/mod-quality.md) requires portable boundaries, native food/geometry/restart, two real clients with reconnect and world/stat agreement, performance budgets, visual review and package validation. Portable tests run on sublet. Native tests run invisibly on SERGBOOK through project-test. No test helper ships to players.

Build 42.21.0 is the tested engine. The native authority probe uses synthetic actors. Physical split-screen controller flow and arbitrary mod combinations have not been verified. The actual public release, exact test snapshots and coverage limits are in [VERIFICATION.md](VERIFICATION.md).

[Subscribe on Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3828971865). Source and bugs: [fbserg/zomboid-mods](https://github.com/fbserg/zomboid-mods).

## Artwork and release

[Release playbook](../../docs/releasing.md). Selected generated illustrations and exact built-in image_gen prompts are in [workshop/art](workshop/art/PROMPTS.md). Gameplay images are native captures with two connected clients in a disposable scene. The home, lighting, food, time and starting stats are staged for the photos. No furniture is required by the mod.
