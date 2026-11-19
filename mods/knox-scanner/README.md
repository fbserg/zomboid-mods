# Knox Scanner

A Build 42.21 client mod with no dependencies. It writes your notable moments to `Zomboid/Lua/KnoxScanner.jsonl`, one Discord webhook message per line. A one-line command outside the game posts each line to a Discord channel. People can read the feed, and a bot can react to it.

Unreleased. Portable tests and the static check pass. No native game run, multiplayer run or Workshop package exists yet.

## Events

Each one has a tick box under Options, Mods, Knox Scanner. All start on.

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

A line looks like this:

```json
{"username":"Knox Scanner","content":"\ud83d\udce1 town | Muldraugh | day 12, 14:00 | A survivor reached Muldraugh."}
```

The content is `📡 kind | place | day N, HH:00 | text`. It carries no player or character name.

## Post the feed to Discord

Create a webhook in the channel: Edit Channel, Integrations, Webhooks, New Webhook, Copy Webhook URL. Then leave one of these running while you play.

- macOS and Linux: `companion/to-discord.sh WEBHOOK_URL`
- Windows: `companion\to-discord.ps1 WEBHOOK_URL`

The mod cannot post by itself, because game Lua has no network access.

## Add and remove

The runtime is `KnoxScanner/`. It runs on the client and reports the local player only. A multiplayer server must list `KnoxScanner` so its players load it. The mod adds no items and saves nothing in the world. Removal leaves the feed file behind.

## Limits

- Town borders are hand-drawn rectangles. Outside them the place reads "the countryside".
- The first game minute of a character records a baseline and reports nothing.
- The helicopter check reads the game clock's helicopter schedule. Nobody has checked that a multiplayer client receives that schedule.
- Every player's game reports the same helicopter, storm and blackout. A consumer should drop repeats.

## Tests

- `project-test --suite knox-scanner` runs the portable Lua tests.
- `project-test --local --suite scanner-static` compiles the mod with the installed game's compiler and resolves its API calls. It runs without `--prove`, because that mode needs a translation file and this mod has none.
