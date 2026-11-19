# Knox Scanner

A Build 42.22 client mod with no dependencies. It writes the big moments of your run to `Zomboid/Lua/KnoxScanner.txt`, one JSON line each. A one-line command outside the game posts each line to a Discord channel, where people can read the feed and a bot, a stream overlay or anything else can react.

## Events

Each one has a tick box under Options, Mods, Knox Scanner, next to a master switch. All start on.

| Kind | Fires when |
|---|---|
| `death` | Your character dies |
| `bitten` | A new zombie bite |
| `hurt` | Health drops below half. Fires again after a recovery to 70 |
| `town` | You reach a different town |
| `landmark` | You walk into a police station, gun store, prison, fire station, pharmacy, hospital, clinic, Spiffo's, army storeroom, church, bank or school |
| `helicopter` | The helicopter event starts |
| `power` | The power grid shuts off while you play |
| `storm` | A thunderstorm, tropical storm or blizzard starts |
| `horde` | 40 or more zombies within 20 tiles, at most once per 6 game hours |
| `kills` | Every 100 zombie kills |
| `days` | Every 7th day survived |
| `request` | You press the "Request a broadcast" key. Unbound by default |

"Show a note" puts a short note above your character each time a line is written.

A line looks like this:

```json
{"username":"Knox Scanner","content":"\ud83d\udce1 horde | Muldraugh | day 12, 14:00 | A horde of about 45 zombies is closing in on a survivor.","kind":"horde","place":"Muldraugh","day":12,"hour":14,"text":"A horde of about 45 zombies is closing in on a survivor."}
```

`username` and `content` make the line a ready Discord webhook message. `kind`, `place`, `day`, `hour` and `text` are for every other tool. The line carries no player or character name.

## Post the feed to Discord

Create a webhook in the channel: Edit Channel, Integrations, Webhooks, New Webhook, Copy Webhook URL. Then leave one of these running while you play.

- macOS and Linux: `companion/to-discord.sh WEBHOOK_URL`
- Windows: `companion\to-discord.ps1 WEBHOOK_URL`

The mod cannot post by itself, because game Lua has no network access.

## Other tools

- A Discord bot that reads the channel can keep a death counter, a leaderboard or a running story.
- OBS scripts or Streamer.bot can follow the file and fire an alert on a bite or a death.
- The same command can call a Home Assistant webhook instead of Discord.
- Appending the lines to a spreadsheet gives a timeline of each character.
- A language model and a voice can narrate the run from the lines.

## Add and remove

The runtime is `KnoxScanner/`. It runs on the client and reports the local player only. A multiplayer server must list `KnoxScanner` so its players load it. The server does nothing with it and the mod sends nothing over the network. It adds no items and saves nothing in the world. Removal leaves the feed file behind.

## Limits

- Town borders are hand-drawn rectangles. Outside them the place reads "the countryside".
- The first game minute of a character records a baseline and reports nothing.
- Landmark and storm lines have logic tests only. No native run produced one.
- The helicopter check reads the game clock's helicopter schedule. Nobody has confirmed that a client on a live server receives that schedule.
- Every player's game reports the same helicopter, storm and blackout. A consumer should drop repeats.
- A Discord webhook was not available during development. The Discord message endpoint accepted the same line with its extra fields.

## Verification

Release qualification: `python3 tools/pz-test/check.py mods/knox-scanner` from the repository root. Results and limits are in [VERIFICATION.md](VERIFICATION.md). Decisions are in [DECISIONS.md](DECISIONS.md).

Source and bugs: [fbserg/zomboid-mods](https://github.com/fbserg/zomboid-mods).

## Artwork and release

[Release playbook](../../docs/releasing.md). Generated illustrations and their exact prompts are in [workshop/art](workshop/art/PROMPTS.md). Gameplay images are native captures from two connected clients in a disposable scene.
