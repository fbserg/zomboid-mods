# Mod release playbook

One repository, independent runtime folders and Workshop items. Read DECISIONS.md before reopening a design choice. Keep the source and prompts next to each mod. Start with the smallest real feature and finish one mod before the next.

## 1. Establish the facts

Read the installed vanilla caller and the mod's decision ledger. Record the exact build, runtime ID, Workshop ID, owner, dependencies and player controls. Reuse native actions, persistence and network sync. Do not add custom formats or helpers when the game already owns the data. For item serialization, preserve every native/modded property or stop the spike before inventory changes.

The release record must distinguish working features from experiments. Care Packages has failed its native codec spike and is not a release. The funeral and housewarming ideas remain in the queue. See the [monorepo tracker](https://github.com/fbserg/zomboid-mods/issues/1).

## 2. Prove the feature efficiently

From the repository root, use `python3 tools/pz-test/check.py mods/<slug>` for release qualification. Use `--fast` during edits. The [required mod checks](mod-quality.md) define each gate, upstream projects, performance budgets and honest coverage limits.

The standard run requires portable, static, native, real multiplayer/reconnect, persistence and performance suites, then visual evidence and runtime-only packaging. Missing gates fail. The wrapper reuses project-test and returns a machine-readable report. No new background test service is introduced. A quick run does not qualify a release.

## 3. Make the pictures

Use the built-in image_gen skill for new raster art. Keep the selected original, exact prompt, tool and date in `workshop/art/`. Read earlier mods' prompts and thumbnails first. Reuse their family: chunky pixels, warm amber against dusty teal, expressive large subjects, giant cream title, one quiet apocalypse joke. Make one square avatar and one wide gallery illustration. Inspect the output for spelling, hands, food, composition and accidental extra text.

The avatar must read at 128 and 268 pixels. The feature must remain the subject. Dinner Together needs no table, chairs or plates, even though a kitchen suits its illustration. Public copy must not imply the artwork's props are new game features.

Capture actual game frames for gameplay images. Stage a disposable scene with clear weather, visible players and an uncluttered view. Let the ordinary food action and production notification run. Hide unnecessary UI a frame before capture. Keep useful gameplay evidence visible. Save originals through the project-test artifact lifecycle. Inspect every exported image. A successful capture can still show a black screen, overlapping players, a hidden reward or a useless camera angle.

For Dinner Together:

```sh
project-test --local --suite dinner-photos \
  --artifact mods/dinner-together/workshop/screenshots/dinner-meal.jpg mods/dinner-together/workshop/screenshots/dinner-meal.jpg \
  --artifact mods/dinner-together/workshop/screenshots/dinner-company.jpg mods/dinner-together/workshop/screenshots/dinner-company.jpg
python3 tools/pz-workshop/assets.py mods/dinner-together \
  --avatar mods/dinner-together/workshop/art/dinner-avatar.png \
  --hero mods/dinner-together/workshop/art/good-company.png \
  --screenshots mods/dinner-together/workshop/screenshots/dinner-meal.jpg mods/dinner-together/workshop/screenshots/dinner-company.jpg
```

The exporter uses macOS sips, no new image dependency. It creates the 512px Workshop preview, 256px game icon, ordered posters and small thumbnail review copies. Keep each returned native JPEG below 320KB. The shared executor budget stays 1MiB. Put the illustration first, then action and result. Keep the scene setup and capture commit in the release record. Never generate a picture and label it a game screenshot.

## 4. Finish the player information

Keep `README.md`, `42/mod.info` and `workshop/workshop.txt` aligned. Lead with the actual player benefit and controls. State version, requirements, single-player/multiplayer setup, limits, compatibility, removal and credits. Include source and bug-report links. Use a short joke if it fits. Keep test-only details out of the normal player instructions.

`mod.info` needs author, modversion, versionMin, category, URL, icon and every poster in order. Workshop copy needs title, repeated description lines, tags, public visibility and the existing item ID. Native screenshots must state when the scene is staged. Never claim all mods, builds or split-screen variants are covered by a narrower test.

## 5. Package, publish, verify

```sh
python3 tools/pz-test/package.py mods/dinner-together output/DinnerTogether-0.1.1-b42.21.zip
tools/pz-workshop/pz-workshop validate mods/dinner-together
tools/pz-workshop/pz-workshop status mods/dinner-together
```

The package contains only the runtime folder and common directory. Check file hashes, poster paths and preview dimensions. The native uploader checks contents and the signed-in owner. Expected Steam owner is ModeratExtremist, 76561198033173095. The account guard must pass before writes.

Standing Workshop authorization is recorded in [the existing publishing record](../mods/farm-trailer/workshop/PUBLISHING.md#approval-and-execution): Serg said "workshooe always yes". Routine Workshop releases and listing updates need no repeated final yes. This supersedes the initial epic's extra confirmation assumption. Other destructive operations retain their own approval requirements.

```sh
tools/pz-workshop/pz-workshop publish mods/dinner-together --new
```

Use `--new` only for the first item. Persist the returned ID immediately and commit it. Later updates keep it. Use `description` or `preview` for those fields alone. Never upload another mod, dependencies, dev fixtures or game files. Gallery upload uses `python3 tools/pz-workshop/ugc.py gallery MOD_DIR IMAGE...`, in display order. It calls the installed Steamworks library with Python ctypes. Valve documents [AddItemPreviewFile](https://partner.steamgames.com/doc/api/isteamugc#AddItemPreviewFile), queries and downloads. ABI packing follows [Valve's headers](https://github.com/ValveSoftware/source-sdk-2013/tree/master/src/public/steam). The helper checks the active owner, refuses a non-empty different gallery in new-gallery mode, and verifies the stored filenames after submission. Repeating the exact gallery is a read-only success only after the stored public CDN bytes also match. It never removes existing images. For an intentional gallery refresh, use `replace-gallery MOD_DIR IMAGE...` with all existing filenames in the same order. It requires the exact saved remote gallery, updates only changed slots, preserves untouched slots, checks Cloud growth and verifies every public image byte before it updates published.json. Run `query` after any interrupted upload before a retry. This replaces the earlier browser-only assumption. Required-item management remains on Steam's signed-in item editor for mods that need it. Agent browser sessions stay headless.

Check the public page and Steam public metadata for app 108600, correct owner/ID, visibility 0, result 1, no ban, exact copy and preview. Check the saved gallery order and required items. Steam's content review can delay public access. Do not call owner-only visibility public proof.

Finally download the item with `python3 tools/pz-workshop/ugc.py download MOD_DIR` (no subscription change) and compare its runtime hashes with the tested release. Run the installed release through the native gate. Save compact evidence in the mod's VERIFICATION.md. Commit and push completed work. Preserve older repositories and IDs. Do not archive or delete them as part of consolidation.

## Observed traps

- MP character preview outfits do not equip the network players. Use actual server-owned clothing and its native sync in photo fixtures. A client call to sendClothing does nothing on 42.21. Read the installed implementation before reuse.
- Hide startup panels after OnGameStart has completed its UI setup. Capture after the ordinary action begins, not the frame it enters the queue.
- Keep the failure's Lua stack in the runner error. The final few log lines may belong to another client and hide the actual fault.
- The Steam application can be closed even when the game is installed. Start Steam in the background, then recheck the exact account. No passwords or cookies enter scripts.

- Preflight the whole gallery batch with `ugc.py quota MOD_DIR`. This account/app's observed Cloud quota is 1,000,000 bytes total, so three individually valid sub-1MB files can still exceed it. Dinner Together's 910,343-byte batch passed. Keep the PNG masters. The wide gallery JPEG exports at 1280px, quality 75. Never remove unrelated Cloud files to make room. A failed batch can reserve space for its own temporary files. Inspect the actual names, sizes and empty gallery before cleaning only that failed job's staging.
- The vanilla Workshop description getter appends an ID footer. The shared publisher overrides that getter with authored description lines. Exact public API comparison caught this behavior, and description-only submission verified the fix.
- A warm test must target the server-issued food ID and wait for the previous native action to finish. Taking the first item of a type can race with inventory/action cleanup. The fixed fixture asserts real hunger consumption for each round.

For final release proof use `project-test --local --suite dinner-release`. It hashes the Steam download against source, stages that downloaded runtime and runs two real-client rounds.

Use the visual brief as a gate. For cozy mods, a technically valid roadside frame is not a suitable gallery image. Use a furnished home, warm native light and a clear view of the actual mechanic. Keep foreground wires, setup panels and clutter out of the capture.

- Build 42 can execute server-folder development Lua on clients. Role-guard the test authority before it changes the world. The upstream state comparison caught duplicate photo furniture when this guard was absent.
- Separate test actors by two tiles before a reconnect. An overlapping spawn can cancel a queued food action. Bound the action round so this failure reports promptly.
