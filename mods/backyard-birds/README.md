# Backyard Birds

A Build 42.21 add-on. Wild Kentucky birds visit the vanilla bird bath. It needs no other mod.

*No human has ever opened this folder. Good luck!*

Source: https://github.com/fbserg/backyard-birds (MIT). Workshop: [3828619587](https://steamcommunity.com/sharedfiles/filedetails/?id=3828619587). The native test harness lives in `fbserg/etc` under `mods/backyard-birds`.

## Gameplay

Place or find a **Bird Bath** outdoors. Birds come by when a player is within 10 tiles.

- **Rhythm:** visits are most likely 06:00–09:00 (30% per bath every ten game minutes). They are rare at midday (8%) and pick up again 15:00–20:00 (18%). There are none at night, in rain, or at 0 °C or colder, since the water is frozen.
- **Weather:** a hot day (27 °C and up) and the two hours after rain each make a visit 1.5 times as likely.
- **Visits:** one to three birds of one species stay 4–12 game minutes, about 10–30 real seconds at the default day length. They land one by one, drink, bathe, hop and turn, then leave one by one. Short bursts of the vanilla "bird in tree" song play from the bath, with pauses of 0.5–3 seconds, until the last bird takes off.
- **Species:** Northern Cardinal, Blue Jay and Carolina Chickadee all year. American Robin from March to October. American Goldfinch from April to October. An **Eastern Bluebird** comes on about 1 visit in 20.
- **Scaring them off:** they leave when a zombie comes within 4 tiles, or when a player gets close. Sneaking gets you within 1.5 tiles, walking 3, running or sprinting 5. Birds still in flight do not land.
- **Mood:** a visit within 10 tiles lowers boredom by 5 and unhappiness by 3, at most once per game hour per player. The text "A Northern Cardinal visits the bird bath" shows with a green arrow when that happens. Other visits are silent, except for a rare bluebird in view.

## Add and remove

The mod adds no items, tiles, loot or saved data. Birds are drawn on the screen above the bath's tile and never enter the world or the save.
Removal stops the visits. Pending visits and boost cooldowns live only in memory.

## Multiplayer

Install the same folder on the server and all clients, and add `BackyardBirds` to the server's mod list.
The server picks visits and changes stats. It syncs boredom and unhappiness with the vanilla stat sync and sends each visit to every player within 40 tiles. Every nearby player sees the same species and flock size. Each client animates its own birds and its own scare-offs.

## Performance

- Every ten game minutes, about every 25 real seconds, the server scans the 21 × 21 tiles around each player for an outdoor bird bath. It skips the scan at night, in rain and below freezing.
- A visit costs one small screen element. It draws up to three 32 × 28 sprites, measures one distance and asks whether the song is still playing once per frame, and checks for zombies once a second.
- `birds-photos` measures both costs on the real game and fails above 20 ms per scan or 0.5 ms per visit per frame.

## Reuse

- Vanilla owns the bird bath tiles (`vegetation_ornamental_01_50` and `_51`, both named "Bird Bath"), the `BirdInTree` sound, the stat sync and the server command path.
- The on-screen birds follow the vanilla forage icons, which pin a UI element to a world tile with `isoToScreenX`/`isoToScreenY`.
- `art/make_birds.py` draws all 48 sprites from text pixel maps: 6 species, 4 frames, 2 facings.

## Install and test

- `python3 install.py` copies the mod to `~/Zomboid/mods/BackyardBirds`.
- The portable Lua tests run with `uv run --no-project --python 3.12 --with lupa==2.6 python -m unittest discover -s tests -v`.
  In `fbserg/etc` the suite is `backyard-birds`, and in the standalone repo it is `test`.
- `birds-engine` boots a headless B42 server. It finds a real bath, checks the stat sync masks and real noon weather, and runs one visit.
- `birds-photos` runs a native client with audio on and every volume at 0. It launches without a Dock icon or focus. It places three baths, checks each song starts, repeats while the birds stay, and stops when they are scared off, checks a walking player scares only the closest bath, runs the single-player scheduler, measures cost, and saves `workshop/screenshots/`.
- `birds-multiplayer` starts a loopback dedicated server and a scripted client that joins it as admin and teleports beside a bath.
  The server rolls a visit. The client must receive it with the mood flag and a playing song, and its boredom and unhappiness must match the server after the sync.
- The three native suites live only in `fbserg/etc`. Run them with `--local` on a Mac with the game installed.

## Workshop assets

- `workshop/workshop.txt` holds the listing copy and the item ID. Keep the `id=` line. Without it, publish creates a second item.
- `workshop/screenshots/` holds the native captures from `birds-photos`.
- `workshop/art/dawn-chorus.jpg` leads the gallery. Its prompt is `workshop/art/dawn-chorus.prompt.md`. Gallery order: promo, close, yard, halo.
- Publish with `tools/pz-workshop/pz-workshop publish mods/backyard-birds` from `fbserg/etc`. Gallery images have no uploader API. Upload them on the Steam item's image manager in the owner's Chrome. A synthetic drag does not stick there. Move the node inside `#sortable_previews` and call `Sortable.sortables['sortable_previews'].onUpdate`, then Save and Continue and reload to confirm.
- `workshop/preview.png` is the 512 × 512 primary thumbnail from `workshop/art/birds-avatar.png`, drawn from `workshop/art/birds-avatar.prompt.md`.

## Limits

- Birds draw on the UI layer. A wall or roof in front of a visible bath does not hide them. A world sprite would occlude properly but writes into the save (see DECISIONS.md).
- Hiding the HUD also hides the birds. Split-screen players beyond the first get no birds in multiplayer.
- `birds-multiplayer` uses one real client on a loopback server. Nobody has run a live session with two human players.
