# Farm Trailer verification

Verified October 24, 2026. Public release:
[Steam Workshop item 3826535986](https://steamcommunity.com/sharedfiles/filedetails/?id=3826535986).
The five runtime files total 19,874 bytes. Steam's public metadata confirms that
size, public visibility, app 108600, success and no ban. The installed local mod,
staged package and source files match byte for byte. Existing saves, installed
dependencies and live server settings were not edited.

## Portable behaviour

- Executor: `sublet`, project-test `farm-trailer`.
- Tested snapshot: `1647e10389b4b3a50cd632c74b7449b9bcfa9bf2`.
- Tree: `b8f64d2c51500234d413c276d794ecfd51db98ef`.
- Result: **21 passed**, cleanup complete.
- Receipt: `20261024T223934-76d5f94dab26` under `~/.cache/project-tests/runs/`.

Checks cover registration, pool boundaries/collisions, finite water delivery,
overflow, destroyed collectors, unloaded storage, pump prerequisites and battery
use, water mass, safe exits and scoped client controls. A new regression proves
that a rejected pool leaves every parent trailer registration intact. It failed
before the preflight fix and passed after it.

## Recorded server stack

`tests/server-stack.json` records the 83 active mod IDs from the last successful
multiplayer session in `Logs/logs_2026-10-24_00-29/2026-10-23_22-20_DebugLog.txt`.
That session used **42.21.0**. All 83 installed mod folders were available. The
manifest pins their IDs, paths within Workshop and mod.info hashes. The local
servertest.ini is an empty default profile, not the real server's stack.

Tests use isolated worlds and the currently installed copies of those mods.
The live remote server's present version/settings were not queried. A live
remote co-op peer has not been exercised.

## Native server and full restart

- Executor: `SERGBOOK.local`, explicit local `farm-full-stack-engine`.
- Tested snapshot: `c96b46e1abd157a90c2f31bcee594d75bef9633e`.
- Tree: `327bfb2ae51bb74fc81646c280cc557d943acd44`.
- Result: **creation and full restart passed** with the recorded 83-mod stack.
- Receipt: `20261024T231352-fb08783b1784`, cleanup complete.

Both server phases verified all 85 requested mod IDs in the native load log.

Native checks prove:

- All 480 usable squares remain outdoors without a roof.
- New perimeter walls collide and lack the transparent north/west flags.
- Two 400 L collectors start empty. Consumption, capacity and taint persist.
- Re-entry does not rebuild or reset objects.
- A native watered crop advances to its next growth stage.
- Native cattle handoffs preserve identity and custom state in both directions.
- Shoreline intake uses a native hose, water flag and tow battery.
- Water adds vehicle mass and the expected battery charge is consumed.
- Parent entry and the farm exit preserve crops, livestock, corpse and water.
- Those contents survive a full server restart.

## Graphical client and comparison run

- Executor: `SERGBOOK.local`, explicit local `farm-full-stack-photos`.
- Tested snapshot: `08bb81afbff44d571f15e862c1670c3d5da6178c`.
- Tree: `d64b3ce93e681a3104f9cd6e861aa08ee7f471b6`.
- Result: **85 requested IDs loaded**, three native captures passed.
- Receipt: `20261024T225616-515b87350a50`, cleanup complete.

The 85 IDs are the 83 recorded mods, Farm Trailer and the photo fixture. The
runner fails if any requested ID is absent or any Farm Trailer/fixture Lua stack
frame appears. No farm or fixture Lua error appeared.

The automated full client shows mod-options/audio errors and native asset
warnings. The comparison suite `farm-stack-baseline` reproduced the same mod Lua
frames with Farm Trailer absent: Survivor Briefing and Vanilla Vehicles Animated.
This is not a claim that the entire third-party stack is error-free. The isolated
bootstrap, disabled audio and fresh client settings differ from a normal session.
Reports are saved as `tests/stack-baseline-errors.json` and
`tests/stack-farm-errors.json`. Baseline receipt: `20261024T225217-1fd1c55b09e1`.

## Public screenshots, art and copy

The clean gameplay gallery uses only the three required mods plus Farm Trailer.
Native `farm-photos` captured all three 1440 × 900 frames on `SERGBOOK.local`.
Snapshot: `f14207e434abbef244975220e89e0b72b9696877`, tree
`db4ae409de9ae7cb6279c0913a85b0e05bd3dafc`. Receipt:
`20261024T225218-b6921b92153b`, passed and cleanup complete. Its report contains
no mod Lua error frames. All three images were visually reviewed.

The disposable scene adds two cows, advanced native crops, paths and a pen.
Clear weather, explored squares and the dressed character serve only the photos.
No test fixture, Java bridge, third-party mod or artwork is in Workshop Contents.
New plots have solid wooden perimeter walls. Existing plots keep their layout.

`workshop/art/too-many-cows.png` is built-in imagegen promotional art. Its prompt
is saved beside it. The JPEG export is in the live gallery and the description
labels it as generated art. The three gameplay images were replaced in place.
`workshop/screenshots/workshop-page.jpg` shows the verified public listing.

The copy follows `docs/page-design.md` and the shared AItells Vale rules.
The extracted description passed Vale with **zero warnings/errors**. All three
required items and the exact updated description were verified on Steam.


## Standalone open-source export

Published https://github.com/fbserg/farm-trailer as a public MIT-licensed
repository. Initial commit: `53c1bec02d9ace276d5a7d75f012adc0eeafe550`.
GitHub reports public visibility and identifies the MIT license. All five runtime
files match this release byte for byte. The export includes the portable tests,
installer, gameplay screenshots, credits and Workshop description. It excludes
game/dependency files, private server logs and generated promotional art.

- Executor: `sublet`, standalone `project-test --suite test`.
- Tested commit: `53c1bec02d9ace276d5a7d75f012adc0eeafe550`.
- Tree: `81db75911c0b85b7ee79bdc91953ed716bbd90da`.
- Result: **21 passed**, cleanup complete.
- Receipt: `20261025T023902-c9d3f9254f61`.

The revised Workshop description passed Vale with zero warnings/errors.
Published the approved description and image order on October 25, 2026.
Signed-out Steam HTML confirms the source link, new copy and all four previews
in order: overview `48289439`, crops `48289441`, livestock `48289440`, generated
artwork `48290279`. Steam's automated content check briefly hid the item, then
cleared. The public listing is accessible again. The owner view and signed-out
page both show the update. `workshop/screenshots/workshop-page.jpg` captures the
published description and source link.

The staged Workshop metadata now has the same description and retains item ID
3826535986. No runtime file was changed or uploaded for this editorial update.
The owner has pre-approved future Workshop publications and routine edits.
See the publishing guide for the exact standing instruction.

## October 26, 2026 safety update

Source commit: `75b3ac32c8896a60eaec12fd4956f2b03a4d3b84` in fbserg/farm-trailer.
This directory mirrors those exact runtime bytes for native test snapshots.

- Portable: **32 passed** on sublet, snapshot `d53a8a38c778c6928edf3f3ef19d816a22b9a691`,
  tree `a0bcaa9d1947e5f774f3e07a89a804ea8cfd5e4c`, receipt `20261027T020918-0cf6d91c06c3`.
- Native required dependencies: creation and full restart passed on SERGBOOK.local,
  snapshot `17e673552f4b0e42d314055505394f669614655d`, tree `a74f904f344b7a4ac4e6508ac8f714120ac909c1`,
  receipt `20261027T020834-b36d3ebc6f63`.
- Native recorded 83-mod stack: creation and full restart passed on SERGBOOK.local,
  snapshot `b23ce05631fc2f5411460847a1951967e3b698e1`, tree `d8a94b20c5caf834861190ce05eac55340476a4b`,
  receipt `20261027T021051-0b7551bee6a3`. All 85 requested IDs loaded in both phases.

New checks prove that the current parent's real entry function preserves an old
trailer assignment without consuming a farm, and two native player records enter
and exit independently. A native animal carrier refuses the wrong farm and retains
its animal identity and destination marker through world save/reload in a container.
Existing crop, water, corpse and live-cow restart checks still pass. Portable checks
cover exterior zombie-only cleanup, restored registry references after errors and
nested entry, full-pool legacy menus, stale player records, native release failure,
and completion-side lock/distance validation before pickup.

The server harness uses two IsoPlayer objects, not two network clients. Actual
remote co-op and inventory packet ordering remain unverified. Carrier persistence
uses a world container, not a disconnected client's inventory database.

The dependency manifest refresh retains the recorded mod-ID set. Six installed
metadata files had changed. It now hashes complete content for the three required
dependencies, so an unreviewed Lua change cannot evade the metadata gate. The current
Project RV Interior supplies RVHooks. The previous release did not require it.

The original native fixture spawned a locked trailer, which the strengthened action
correctly rejected. The fixture now explicitly unlocks it. Its interrupted-carrier
setup uses the native trailer pickup path because a just-spawned animal is not yet
eligible for native floor pickup in the same tick. Neither adjustment weakens the
runtime validity check.

A separate read-only adversarial review found no material release blocker. The
standalone DECISIONS.md records the registry scope, fail-closed exit policy and
server-authoritative animal handoff. No live save, remote server or dependency was
edited by the update.

### Published safety package

Steam's native upload callback succeeded for the existing item 3826535986 under
owner 76561198033173095 (ModeratExtremist). Public metadata after upload reports
result 1, visibility 0, no ban, updated 2026-10-26 22:14:55 EDT, and file_size 23651.
That exactly matches the five source runtime files. Source, staged Workshop package
and local mod install match byte for byte. The description includes the safety
update and retains the remote-co-op warning. The publisher preserves the item ID,
preview and required-item relationships. The direct public HTML request returned
HTTP 429, so this release's verification uses the native upload result and public
metadata API rather than a fresh rendered listing inspection.

Source main: `75b3ac32c8896a60eaec12fd4956f2b03a4d3b84`.
Native harness changes: `848dc07`, merged onto etc main as `a681d6a`.
The local install update first verified every existing file against the previous
published source commit `53c1bec`. No unknown local edit was overwritten.

## Permanent boundary, water feedback and livestock carrier update

October 26, 2026, Toronto time. Standalone runtime commit `0a1224b`.

- Portable suite: **54 passed** on `sublet`, snapshot
  `2b994e01528145f035e95782759b84fbc4948784`, receipt
  `20261027T033627-8a711237792f`. The threshold inversion failed one new test.
  The animal regression reproduced forced placement of a previous carrier.
- Native engine: creation and full restart passed on `SERGBOOK.local` with all
  85 requested IDs loaded (83 recorded mods, add-on and test fixture). Snapshot
  `0cac5a4a61af086b7084564e1234a9f1ad66a8b8`, receipt
  `20261027T033740-feedea696221`.
- Native boundary checks cover all four edges and diagonal corners for player,
  hen and cow objects, climb rejection, attack target rejection, sledge completion,
  fire, and 116 outer tiles without duplication. A saved original fence upgrades
  in place after restart and retains its custom data.
- Native livestock removal leaves zero animals and zero occupied size points in
  the exterior trailer. Existing water mass behavior remains unchanged.
- Exterior livestock capacity is 500 size points in the installed KI5 script.
  Native removeAnimalFromTrailer recalculates that occupancy. Animal size points
  are independent of the chassis and water mass fields. No explicit farm cap exists.
- Copy check: Vale reported zero errors, warnings and suggestions.

The native server uses two player objects, not two network peers. Live remote
co-op remains unverified. Custom player construction can prevent an automatic
boundary upgrade on the occupied square. No live saves were edited.

Graphical check: `farm-photos` passed on SERGBOOK.local, snapshot
`052109db3cebdef16276fa731f040c73423b0280`, receipt
`20261027T033943-d6b34e2d69df`. Three native frames were inspected. Wooden walls
render and the outer border is invisible. The real SP postEnter hook measured
empty native collectors and executed the native low-water halo path, with the
expected exterior snapshot text. All five requested IDs loaded and no mod Lua
error frame appeared. Existing native asset warnings remain outside this mod.

Published at **23:45:23 EDT, October 26, 2026** to existing item 3826535986.
Native Steam callback reported success. Public metadata confirmed owner
76561198033173095, visibility 0, result 1, no ban, and **32,766 bytes** across six
runtime files. Source, local installation and staged Contents match byte for byte.
The public description includes the boundary behavior, water threshold and animal
capacity/unload instructions. Standalone merged source is
`39437a40f39e1e237884c80da76c6bd21093cf5b` (PR #3, closes issue #1).
The live game/server was not restarted or modified. The update applies after
server and clients load the new package on restart.
