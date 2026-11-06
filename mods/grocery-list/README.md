# Grocery List

A small Build 42.21 social mod with no dependencies.

Craft a Grocery List from a sheet of paper, graph paper or a notepad. Write one item per line
with the vanilla notebook window (a pen or pencil is needed, as for any notebook). Whoever
carries the list gets each line marked `[x]` once a game minute when they carry a matching
item, bags included. Matching is case-insensitive and accepts part of the display name and
simple plurals. Bullets, `2 x` quantities, lines under three letters and `~` lines are ignored.

Finishing a list of three or more items removes 10 boredom and 5 unhappiness. If someone else
wrote it, the list is signed `~ Name <3` when the writer carries it again. The writer and the
online shopper each lose 10 unhappiness. Each reward pays each person at most once per 24 game
hours. The server decides everything and saves it across restarts. A finished list is not
read again, except by its writer until delivery, so new lines on it are ignored.

## Add and remove

The runtime is `SharedGroceryList/`. Enable `SharedGroceryList` on the server and clients.
Grocery List items need the mod. Removal leaves inert reward timestamps in world mod data. What the game does with the orphaned items on load is unverified.

The writer is the first holder the scan sees with text on the list. A hand-off inside one game
minute credits the receiver. Dedicated servers do not load mod translations, so the signature
is language-neutral and server-side matching uses the server's item names.

## Verification

Release qualification: `python3 tools/pz-test/check.py mods/grocery-list` from the repository root. The [quality contract](../../docs/mod-quality.md) requires portable boundaries, native items/restart, two real clients with reconnect and world/stat agreement, performance budgets, visual review and package validation. Results and limits are in [VERIFICATION.md](VERIFICATION.md).

[Subscribe on Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3834928311). Source and bugs: [fbserg/zomboid-mods](https://github.com/fbserg/zomboid-mods).

## Artwork and release

[Release playbook](../../docs/releasing.md). Generated illustrations and their exact prompts are in [workshop/art](workshop/art/PROMPTS.md). Gameplay images are native captures with two connected clients in a disposable scene.
