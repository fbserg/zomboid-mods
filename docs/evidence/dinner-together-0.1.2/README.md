# Dinner Together 0.1.2 evidence

Investigated two public Workshop comments on item 3828971865 on 2026-11-04. One reports
"kills my memory" without a reproduction, log or memory figures. The other asks for the
Workshop and mod IDs for multiplayer setup.

The original cache keeps player objects as strong keys until another qualifying meal
prunes them. Two portable garbage-collection probes demonstrate that disconnected/dead
character objects can remain reachable from that cache. Both fail on 0.1.1 as expected
(retention-negative-control.json). Version 0.1.2 stores only strings, numbers and coordinate
records. It resolves live actors during the food callback. No idle hook or world scan is
added. Native instance UID strings distinguish replacement characters even when account,
local slot or network IDs repeat. Account cooldown persistence is unchanged.

This establishes an avoidable retention path, not the cause of the reporter's full memory
problem. The multiplayer client never records meals. The unchanged 0.1.1 native performance
probe passed 10,000 cooldown meals with 0.71 KiB whole-JVM retained growth and no notices.
That probe does not model disconnect retention or prove a user's mod stack is leak-free.
The actual measurements and receipt are performance-before.json and
performance-before-receipt.json. Comparisons of post-collection heap are noisy and cannot
measure the retained size of an individual character.

The first native fixture attempt failed because Kahlua cannot convert a Lua number to
setOnlineID's Java short parameter (receipt 20261104T195904-2f23318b17b3, cleanup true).
The two synthetic players already have the same native online ID. The fixture now asserts
that fact and tests different native instance UIDs without changing an online ID. No
production behavior or assertion was relaxed. That failed attempt is not a pass.

Existing art and screenshots are unchanged. The existing visual review still binds their
hashes. Physical split-screen UI flow and arbitrary mod-list compatibility remain outside
this release's evidence. The CPU scaling probe uses synthetic native actors. The separate
multiplayer gate uses two real clients, normal actions and a fresh reconnect.

## Qualification and public publication

The complete release command passed every required category. qualification.json records
exact immutable snapshots/trees and executor receipts. The portable suite has 18 passes on
sublet. Native behavior/persistence, real multiplayer/reconnect, static/API checks and
performance pass on SERGBOOK.local. Native and OS hidden-window audits pass. All executor
leases report cleanup true. Existing image hashes and runtime-only packaging pass.

Post-change performance added p95 batch means are 0.03125/0.125/0.1875 ms at 2/16/64 actors,
within the declared 0.5/0.5/2 ms budgets. The 10,000 cooldown meals produce zero notices and
64.95 KiB whole-JVM retained growth, below the 16 MiB ceiling. Both negative controls pass.
See performance.json. The pre-change result was also under budget. These figures do not
establish the cause or size of the player's reported memory spike.

The guarded native uploader published to existing item 3828971865 as Steam owner
76561198033173095, ModeratExtremist. public-metadata.json confirms public visibility,
app 108600, result 1 and no ban. The public title and description exactly equal authored
copy. The primary preview and all three public gallery images match source bytes, and the
queried gallery slots/order equal the saved published record. No gallery changes were made.

All seven downloaded Workshop files equal the runtime manifest before postflight starts.
The personal local install also matched the previous release manifest exactly before its
two changed files were updated. Its resulting seven files equal 0.1.2. No save or active
mod list was changed.

Qualified runtime ZIP SHA-256:
`0c2330493f5b05c8507ac13cc0ccfda5ed2be4cc384233f6ab156d7ccc59bad5`.

## Downloaded release proof

The actual downloaded runtime passed dinner-release on SERGBOOK.local, snapshot
2600a1c068b51c7c8f095180f65cea939863e518, tree ba181f967ae2859892a5bf9e6432b21665eebc58,
receipt 20261104T200549-d266f8b3924a, 130.953 s, exit 0, cleanup true. Both real
clients completed two ordinary food rounds. Beth restarted and reconnected. Server/client
stats and world state agreed. Exactly two production notifications were sent. Alice kept
one notification across both rounds and the reconnected Beth received no duplicate. All
three client processes passed native visibility/focus guards and the owned-PID OS audit.
The fixture asserted all seven downloaded runtime hashes before launch.

The public GitHub release targets 48bf42f90ac388fe1282925423ed2171eb84bdbb. Its anonymously downloaded
4,848,866-byte ZIP equals the qualified package byte for byte. See github-release.json.
