# Care Packages 0.1.0 verification

Project Zomboid Build 42.22, revision `3d39148846`. The installed engine hash and gate definitions are in [tests/checks.json](tests/checks.json). The Workshop metadata and gallery are a local draft.

| Check | Evidence |
| --- | --- |
| Portable | Six checks on sublet, including invalid labels, inaccessible and stale actions, cancellation and a deliberately disabled seal. Receipt `20261119T171753-9bfaab6c7b00`. |
| Native and restart | The engine crafted one parcel from two sheets and one use of twine. Native completion kept cargo identities and food aged while sealed. A full process restart preserved the seal, label, food age and temperature, the nested bag, ammo, condition, journal text and unrelated mod data. Receipt `20261119T172128-4887ae897e52`. |
| Multiplayer | Alice dropped a sealed parcel for Beth. Beth picked it up, opened it and read the note. Beth resealed it, reconnected in a fresh client process, and handed it back to Alice. The server saw one parcel at each stage, four metadata syncs and a clean world snapshot at the end. Receipt `20261119T171744-542572fbf390`. |
| Performance | The native stress suite passed 10,000 transitions with exactly two packet requests per commit. Added p95 batch means measured 0.125 ms with two items and 0.094 ms with 64 against a 0.5 ms budget. Post-GC whole-JVM heap showed no net growth in this run. Receipt `20261119T172215-ff2f66474f36`. |

The native checks use a disposable dedicated server and two local network clients. The
handcraft probe calls the real recipe engine directly. The multiplayer probe uses actual
inventory menus, timed actions, and the normal floor handoff. It covers the vanilla
inventory and nearby crafting paths. Custom inventories and crafting systems can apply
their own access rules. The labels remain with the parcel after opening. Empty parcels
before removing the mod.

## Public Workshop release, 2026-11-19

[Care Packages](https://steamcommunity.com/sharedfiles/filedetails/?id=3842540313) is public for app 108600 under ModeratExtremist. The anonymous listing matched the authored description and preview. All three Steam gallery downloads matched their local bytes, in the order recorded in workshop/published.json. The wide ImageGen illustration precedes the two native captures.

The downloaded Workshop runtime matched the tested hashes. Native two-client handoff and reconnect passed against that download on Build 42.22. Receipt: 20261119T175518-ee0ed2279c84.
