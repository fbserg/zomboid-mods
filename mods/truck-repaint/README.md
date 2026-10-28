# Truck Repaint

A Build 42.21 add-on for KI5's [’87 Ford B700/F700 Trucks](https://steamcommunity.com/sharedfiles/filedetails/?id=3110911330),
with optional support for KI5's [’86 Oshkosh P19A](https://steamcommunity.com/sharedfiles/filedetails/?id=2566953935).
It lets a player repaint a truck or bus into one of its plain factory skins with vanilla paint buckets and a paintbrush.

*No human has ever opened this folder. Good luck!*

Source: https://github.com/fbserg/truck-repaint (MIT). Workshop: [3828587831](https://steamcommunity.com/sharedfiles/filedetails/?id=3828587831).

## Gameplay

Right-click a supported vehicle from outside and pick **Repaint Truck**, then a color.
The tooltip lists the brush and the paint uses needed, in red when short.
The survivor walks to the driver door. The action takes about 12 wall-paint actions of time and plays the vanilla painting animation and sound.

| Vehicle | Paint jobs |
|---|---|
| F700 box | Blue and White, Red and Black, White, Yellow, Red and White |
| F700 bank | Red and Black, Silver and Black |
| F700 SWAT | Black |
| B700 military, school and prison buses | Redneck Camo |
| Oshkosh P19A USMC and FRTR55 | USMC Green, NATO Green, Desert Tan, Camo |
| Oshkosh P19A KYFD fire truck | Red, Yellow, Red and White |

- Every job costs 10 bucket uses. A solid color takes one full bucket. A two-tone job takes half a bucket of each color.
- Paint covers a livery but never creates one. Spiffo, Gigamart, U-Store-It, Knox Bank, SWAT, sheriff and US Army skins are not targets.
- KI5 ships one skin each for the school and prison buses. The mod appends the military bus's camo texture to them, since all three share one body model.
- The paintbrush is not used up. Empty buckets stay in the inventory.
- The Oshkosh entries stay idle unless that mod is loaded. It is not required.

## Add and remove

The mod adds no items, loot or saved data. It changes the vehicle's native skin index only.
Removal leaves every truck on a normal KI5 skin. A camo school or prison bus has index 1, which the game clamps back to a KI5 skin once the appended camo is gone.
Timed actions are not saved, so a paint job in progress simply disappears.

## Multiplayer

Install the same folder on the server and all clients, and add `TruckRepaint` after `87fordB700` in the server mod list.
The B42 server never calls `isValid` on a network action, so `complete` repeats every check (brush, paint, known skin, painter at the driver door)
before it spends paint. The server then sets and transmits the skin, and tells every client to rebuild the model.

## Reuse

- Vanilla owns the skin storage and sync (`setSkinIndex`, `transmitSkinIndex`), paint buckets and loot, the paintbrush tag,
  the paint animation and sound, and the timed-action network path. The action follows vanilla `ISWashVehicle`, `ISRemoveBurntVehicle` and `ISPaintAction`.
- KI5 owns the trucks and every skin texture. Nothing from KI5 is copied. Their developer allows add-on skins
  without asking ([thread](https://steamcommunity.com/workshop/filedetails/discussion/2642541073/3883851232928235825)).
- HDCP Immersive Vehicle Paint, Paint Your Ride and Vehicle Skin Changer informed the design. No code from them is used.

## Install and test

- `python3 install.py` copies the mod to `~/Zomboid/mods/TruckRepaint`.
- The portable Lua tests run with `uv run --no-project --python 3.12 --with lupa==2.6 python -m unittest discover -s tests -v`.
- The native server and client checks live in `fbserg/etc` under `mods/truck-repaint`, since they need the installed game and KI5 mods.
  `truck-engine` boots a headless B42 server, pins every skin index to its KI5 texture, and repaints a box truck with real buckets.
## Workshop assets

- `workshop/workshop.txt` holds the listing copy and the item ID. Keep the `id=` line. Without it, publish creates a second item.
- `workshop/preview.png` is the 512 × 512 primary thumbnail from `workshop/art/truck-avatar.png`, made with Codex's image generation from `workshop/art/truck-avatar.prompt.md`.
- `workshop/screenshots/` holds four native-client captures: menu with tooltip, painting, result, and camo bus.
- `workshop/art/paint-day.jpg` leads the gallery. Codex drew it from `workshop/art/paint-day.prompt.md`. Gallery order: promo, menu, painting, after, bus.
- Publish with `tools/pz-workshop/pz-workshop publish mods/truck-repaint` from `fbserg/etc`. It stages `~/Zomboid/Workshop/TruckRepaint`,
  checks the item ID and the Steam owner, and uses the installed game's uploader. `workshop/changenote.txt` is the update note.
  Gallery images and required items have no uploader API. Set them on the Steam item page.

## Limits

- The skin table pins KI5 skin indices. If KI5 reorders skins, `truck-engine` fails and names the texture.
- Nobody has run a live two-player session. The client model refresh after a server repaint is covered by the portable tests only.
