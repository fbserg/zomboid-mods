# Project Zomboid mods

One source repository for independent Project Zomboid mods.
Runtime folders stay independent. Existing Workshop IDs stay the same.

See [the required quality checks](docs/mod-quality.md), [the release playbook](docs/releasing.md), [development](docs/zomboid-mod-development.md) and [decisions](DECISIONS.md).

| Mod | Workshop | Runtime |
|---|---|---|
| Farm Trailer | [3826535986](https://steamcommunity.com/sharedfiles/filedetails/?id=3826535986) | `mods/farm-trailer/FarmTrailer` |
| Truck Repaint | [3828587831](https://steamcommunity.com/sharedfiles/filedetails/?id=3828587831) | `mods/truck-repaint/TruckRepaint` |
| Backyard Birds | [3828619587](https://steamcommunity.com/sharedfiles/filedetails/?id=3828619587) | `mods/backyard-birds/BackyardBirds` |
| Dinner Together | [3828971865](https://steamcommunity.com/sharedfiles/filedetails/?id=3828971865) | `mods/dinner-together/DinnerTogether` |
| Grocery List | [3834928311](https://steamcommunity.com/sharedfiles/filedetails/?id=3834928311) | `mods/grocery-list/SharedGroceryList` |
| Clean Misses | [3842265515](https://steamcommunity.com/sharedfiles/filedetails/?id=3842265515) | `mods/clean-misses/CleanMisses` |
| Knox Scanner | [3842315081](https://steamcommunity.com/sharedfiles/filedetails/?id=3842315081) | `mods/knox-scanner/KnoxScanner` |
| Care Packages | [3842540313](https://steamcommunity.com/sharedfiles/filedetails/?id=3842540313) | `mods/care-packages/CarePackages` |

The [Care Packages release checks](mods/care-packages/VERIFICATION.md) cover parcel handoff and reconnect with two clients on the downloaded Workshop build. The [original serialization experiment](experiments/care-packages) is preserved as development history.

Original repositories and their history remain intact. Import commits record the exact upstream source.

The [development queue](https://github.com/fbserg/zomboid-mods/issues/1) lists [A Proper Goodbye](https://github.com/fbserg/zomboid-mods/issues/4) next, followed by [Our New Home](https://github.com/fbserg/zomboid-mods/issues/5).
