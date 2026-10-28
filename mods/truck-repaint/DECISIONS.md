# Decisions

## Skin swap, not color tint

KI5 shell textures are fully opaque (0.0% alpha below 250 on the B700 bus and F700 box shells), so the vanilla HSV tint never shows.
Repaint moves between KI5's existing skins. Reopen if KI5 ships tintable shells.

## Liveries are never targets

Paint covers a Spiffo's or Knox Bank livery but cannot create one. This keeps a bucket of paint from producing branded art.
The KYFD fire truck skins all carry the same FIRE / RESCUE lettering, so moving between them counts as a repaint.

## Bus camo by appending a skin

The school and prison buses ship one skin each. `VehicleScript:Load` appends a skin that points at KI5's military bus camo,
which uses the same `87fordB700Base` model. The client also runs `BaseVehicle.LoadVehicleTextures`. Removal is safe because
`BaseVehicle` clamps a saved skin index the script no longer has. Reopen if KI5 ships a second skin for either bus.

## complete() repeats isValid()

`zombie.core.NetTimedAction` never calls Lua `isValid` on the server. Without the repeat, a modified client could repaint any
loaded truck for free. Vanilla `ISWashVehicle:complete` re-checks its water for the same reason.

## No scripted photo harness

A scripted native client took the October 27 screenshots. It opened a game window on the owner's screen for minutes,
broke on frame timing, and was deleted once the photos existed (last version in fbserg/etc commit 69ecf42, `mods/truck-repaint/tests/photos.py`).
It found one real bug: the painter walked into the truck's center square. The portable tests and the headless
`truck-engine` server check gate changes. New photos come from a normal play session. Reopen if a client-only path
appears that the server check cannot reach.

## One repo per mod

Truck Repaint and Farm Trailer share no runtime code and have different dependencies. Each Workshop listing links its own
source and issue tracker. The native test harness stays in `fbserg/etc`. Reopen at a third mod, or when copying the harness
between repos becomes routine. Then consider one `pz-mods` repo with a folder per mod.


## 2026-10-28: consolidated source

The root DECISIONS.md supersedes the earlier separate-repository choice. Develop here. Keep the old Workshop item ID. The original repository remains intact as provenance.
