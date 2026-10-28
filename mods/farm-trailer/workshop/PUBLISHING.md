# Farm Trailer Workshop publishing

Since October 27, 2026 every mode runs through the shared `tools/pz-workshop/pz-workshop` CLI
(`status`, `validate`, `publish`, `description`). It replaces this folder's WorkshopTool.java.
Older sections below describe that tool's history. Its Java setup and safety checks carried over unchanged.

## Published listing

Public item: https://steamcommunity.com/sharedfiles/filedetails/?id=3826535986.
Native upload succeeded under the verified account. All three dependencies were
attached through Steam's required-items picker. The three real screenshots were
uploaded and verified in the live gallery. The public metadata API confirms
visibility 0, result 1, app 108600 and no ban.

## Release inputs

- Owner verified in Chrome, Steam's public profile XML and the native Steam client:
  ModeratExtremist, Steam ID 76561198033173095.
- Title: Farm Trailer [B42] - RV Interior Add-on.
- Visibility: public.
- Required items: Project RV Interior (3543229299), Trailers! (3330403100),
  that DAMN Library (3171167894).
- Stage: `~/Zomboid/Workshop/FarmTrailer`.
- Content: the six tested runtime files under `Contents/mods/FarmTrailer`.
- Current preview: `preview.png`, a 512 × 512 pixel-cow PNG (441,555 bytes).
  Its full-size source is `thumbnails/pixel-cow.png`. The old `preview.svg` stays
  as the original artwork, not the source of the current PNG.
- Metadata: `workshop.txt`. Keep it in sync with the live player instructions.

The staged content passed the installed game's `SteamWorkshopItem.validateContents`.
The native Steam session matches the Chrome account. No password, cookie, browser
storage or Steam login token is exported. The publisher uses the game's own upload
API and keeps the returned item ID in the staged workshop.txt.

## Approval and execution

Serg's standing instruction on October 25, 2026 is "workshooe always yes".
Workshop publications and routine listing updates are pre-approved. Do not ask
for another final yes. Verify the Steam account and target item, finish packaging
and checks, then publish and verify the result. Never call `create` or
`submitUpdate` during a preflight.

Compile WorkshopTool against the installed Project Zomboid jar with Java 25 or
newer and `--release 25`. Run it with the game's bundled Java from its Contents/Java
folder, its native-library path, `-Dzomboid.steam=1`, and `SteamAppId=108600`
for Steam modes. Without the JVM property, SteamUtils deliberately starts offline.

- `validate STAGE CACHE` validates files and registers the result observers without
  creating a Workshop item.
- `status STAGE CACHE` confirms the active Steam client account without an upload.
- `publish STAGE CACHE EXPECTED_STEAM_ID` creates or updates the prepared listing.
  It refuses an unexpected active Steam account. It waits for Steam's result and
  reports any legal-agreement requirement before proceeding further.

For this stage, CACHE is `~/Zomboid`, since the game's uploader requires the stage
under its cache-directory Workshop prefix. Do not move the stage outside that prefix.

After publication, use the signed-in Steam Workshop item page to add all three
required items. Verify the public page title, description, preview, visibility,
required-item links and native upload result. Record the new Workshop ID in the
release docs and server instructions. Keep the live tab as the deliverable.

## Updates

Preserve the staged workshop.txt `id=` line after first publication. An absent ID
creates a different item. Do not overwrite that file with the ID-free source
metadata. Update only this mod's Contents subtree and preview. Do not bundle any
Workshop dependencies, game files, test fixtures or developer upload tools.

The native helper is a publishing tool only. It is never installed as part of the
mod, and the runtime remains pure Lua.

## Real demonstration photographs

Use the `farm-photos` project-test suite with `--local` and the three screenshot
artifact paths under `mods/farm-trailer/workshop/screenshots/`. It creates an isolated
APFS clone of the installed game, loads a disposable world and captures native
frames. Review every image before upload. A successful file capture alone does not
prove useful framing. Keep the staged-demo disclosure in the listing.

The Mac native-app controller could not bind the game window. The test-only native
loader continuation replaces that interactive step. Copy the existing options so
the game keeps its prior terms acceptance, then disable the survival guide, use
the full ISUIHandler hide operation and set clear weather in the disposable scene.
Do not symlink the Java asset tree: native prefix checks reject canonical paths
outside the clone. An APFS clone avoids that failure without a full physical copy.

Steam's creation callback supplies the new ID. Assign and persist it explicitly
before submission. The command-line helper calls the native Workshop submit
method after validation, since the UI item's submit wrapper requires a render
context. Preserve the ID even if a later upload fails.

The project-test artifact limit is 1 MiB for the entire run. The photo exporter
keeps each JPEG under 320 KB without a resize. Do not raise the shared runner
limit for a screenshot job. Native visibility getters are read-only despite
legacy setter names. Explore the disposable plot and use only `setIsSeen` for
photo framing.

## Solid walls, full stack and copy pass

Use `farm-full-stack-engine` and `farm-full-stack-photos` for the recorded 83-mod
profile. The manifest pins IDs, installed folders and mod.info hashes, and names
the source connection log. It does not contain server addresses or credentials.
The staging helper checks actual native load-log IDs so copied-but-disabled mods
cannot count as coverage. Keep all test dependencies outside Workshop Contents.

Some client mods open a paused welcome panel after world entry. The photo fixture
uses the native OnTickEvenPaused event to hide test UI and resume the demo. This
fixture is never installed or published with the runtime.

The Workshop copy follows `docs/page-design.md` and the shared AItells Vale rules.
Strip Steam formatting into a temporary HTML document and run Vale with the
repository config. Keep a few short jokes around clear player instructions. Omit
conversation history, test narratives and packaging disclaimers. The owner removed
the promotional-art sentence and visible Workshop/Mod ID footer on October 27.
Keep the empty-plot and furnished-demo explanation.

The full client comparison excludes Farm Trailer completely: only the recorded
83 mods and the photo fixture load. Compare mod Lua frames with and without the
add-on. Keep diagnostic reports so an existing mod's startup noise cannot be
misattributed to the farm. Public gameplay photos use the three required mods.

Steam's PNG batch upload produced an alert in this run. Browser dialog handling
could not dismiss it. A fresh tab in the same browser accepted the screenshot
updates and a JPEG export of the artwork. The reason for the PNG rejection is
unconfirmed. Refresh managepreviews after an upload to verify stored file sizes,
since the immediate page can retain the previous size. Do not confuse that stale
caption with a failed update.


## Open-source listing refresh

The standalone source is https://github.com/fbserg/farm-trailer under MIT.
Keep that link with the credits. Retain dependency credits and the staged-photo
explanation. State the supported game version and setup requirements.
Do not re-upload runtime files for a description-only change.

The saved gallery order is generated artwork, overview, crops, then livestock.
Current preview IDs are `48290279`, `48289439`, `48289441`, `48289440` in that
order. Verify each ID against its actual image before any rearrangement. Use the
image manager's drag control and Save and Continue. Keep all four images.
Description edits can trigger Steam's automated content check. The owner may see
the saved listing while signed-out readers see an unavailable item. Verify public
access after the check clears, and report that limit if it remains pending.


## Safety release procedure

1. Develop in the standalone source repo. Run its portable suite on sublet.
2. Mirror the committed runtime and portable tests here for native snapshots.
   Compare every byte. Keep etc as a release/test mirror, not a second source.
3. Review installed dependency changes before updating the manifest. Hash complete
   required-dependency content, then run native creation/reload on the recorded stack.
4. Preserve Steam item 3826535986 and owner 76561198033173095. Status is read-only.
   Use both SteamAppId=108600 and -Dzomboid.steam=1 for the native publisher.
5. Verify staged/local files still match the previous known release before replacing
   them. Never alter saves. Validate, publish under standing approval, then confirm
   public metadata size, owner, visibility and description against the package.
6. Keep remote co-op explicitly unverified unless real network peers were exercised.

## Description-only edits

Run `tools/pz-workshop/pz-workshop description mods/farm-trailer`. The shared CLI stages the
mod, checks that workshop.txt still names item 3826535986 and that Steam runs as the owner,
then calls the native start, description and submit methods only. `workshop/changenote.txt`
supplies the update note. The CLI replaces this folder's old WorkshopTool for every mode. The normal public submit wrapper also sends Content,
so do not use publish for text-only changes. Verify exact description equality
through Steam public metadata and confirm file size remains unchanged.

On October 26, Serg reported that the mod works in their live multiplayer session.
On October 27 Serg confirmed it again and asked for the listing to say so. The public copy
now states it works in live multiplayer on the author's own server. Do not portray automated two-player objects as
a separate live network test or general compatibility certification.

The first description-only native update passed on October 26, 2026. Steam's
callback reported DESCRIPTION_UPDATED. Public API description matched the staged
text exactly, owner/visibility stayed correct and runtime size stayed 32,766 bytes.
The publisher compiled against the installed Java 25 game API. Vale passed with
zero errors or warnings. No game runtime files changed in this copy update.


## October 27 player-copy refresh

The owner requested a shorter, lightly funny description and cute artwork first.
The first English copy pass had 627 words, with Steam headings, numbered controls and
server setup IDs. Keep test history and internal conversation out of player copy.

The signed-in owner editor saved the text and gallery order. Steam completed its
content check. Five release checks passed on SERGBOOK: public metadata, owner/game
identity, exact description (normalize Steam CRLF), four-image order, and required
items plus balanced markup. Vale reported zero errors or warnings. The staged
workshop.txt description matches the saved source. No runtime upload occurred.

The next owner pass removed the promotional-art sentence and visible ID footer.
The live description is now 614 words. Four focused checks passed on SERGBOOK:
exact public text, all requested cuts, owner/visibility/runtime size, and staged
metadata equality. Vale passed with zero findings.

Three new square thumbnail options are saved under `thumbnails/`: retro comic,
clay diorama and pixel cow. `thumbnails/PROMPTS.md` records the exact built-in
imagegen prompts. These are review options, not a published thumbnail change.

## October 27 primary-thumbnail update

The owner delegated selection and asked for the correct Steam format. Choose the
pixel cow for its large face and readable title. The primary thumbnail is separate
from the gallery. Keep the cute gallery artwork first.

The item page requests a 268 × 268 image. The responsive browse grid requested
322 × 322 and rendered at about 218 or 246 CSS pixels in the two checked windows.
Check readability at 128 px too. Ship a 512 × 512 PNG, one of the two square sizes
accepted by the installed game's validator, and keep it under 1,024,000 bytes.
The selected image is 441,555 bytes. Retain the full-size original for future exports.

Use `preview STAGE CACHE EXPECTED_STEAM_ID` with WorkshopTool for image-only
updates. It validates the stage and account, fixes the target to item 3826535986,
and calls native start, set-preview and submit only. It never sends Content or
description. Start the installed Steam client if status reports no active client.

The native callback returned PREVIEW_UPDATED on SERGBOOK. Five release checks
passed: PNG size/dimensions, changed public preview URL, unchanged other metadata
and runtime, exact CDN image bytes, and unchanged four-image gallery order.
The live item page and browse card both displayed the new thumbnail. The compiled
Java helper used the installed Java 25 game API. No runtime files were uploaded.

Sources: [live item](https://steamcommunity.com/sharedfiles/filedetails/?id=3826535986),
[browse grid](https://steamcommunity.com/workshop/browse/?appid=108600&searchtext=Farm+Trailer),
[primary-preview API](https://partner.steamgames.com/doc/api/ISteamUGC#SetItemPreview).
