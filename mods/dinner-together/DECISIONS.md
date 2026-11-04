# Decisions

## Server food completion, no client reward request

Decision: chain vanilla ISEatFoodAction.complete and qualify at least five hunger points
actually consumed. The client only displays the server's notification.
Evidence: installed B42.21 shared Lua uses complete for Eat, perform for local cleanup.
Reopen if the installed build changes its authoritative food path. Other mods must chain
this method too. A later mod which replaces it without chaining is incompatible.

## Saved rolling cooldown, transient meals

Decision: reward each username at most once per 24 game hours, in world ModData. Recent
meals expire after ten game minutes. Singleplayer keys use the local player slot.
Evidence: per-object memory would reset after reconnect, and client-owned state could
reset after a restart. World storage stays under the authority that changes stats.
Reopen if per-character cooldowns are requested. A new character on the same account/slot
currently keeps that account's cooldown. Removal leaves only inert cooldown entries.

## Fourth mod stays in etc

Decision: keep this series' source and native harness together under mods/ in etc.
Evidence: older ledgers explicitly reopen at the fourth mod. The user limits this task to
etc, and repeated native launchers already cost more than runtime Lua. Do not edit or
synchronize the separate source repos from this task.
Reopen on an explicit request to split this series into its own public source repository.

## Clean native runs before hot reload

Decision: reuse the existing engine bridges and extract only a common runner. No Forge
Live or PZ_DevHarness dependency yet. Evidence and sources are in the development playbook.
Reopen if probe repetition or startup cost dominates measured iteration time.

## Issue #146: borrow static checks, keep bounded test ownership

Decision: pin PZ_DevHarness externally for native compilation/API/reference checks. Use its
dev-mod bootstrap approach against installed assets. Keep our owned process lifecycle and
batch the two network scenarios in one lease. Do not adopt detached stock --stay processes.
Evidence: wrong JSON filename and missing method fail before boot; restored source passes.
The final no-focus two-client batch passed in 99.779 s, with fixture stat reset and one notification
per client across both rounds. Runtime snapshots still launch fresh, so edits cannot reuse
stale completion wrappers. Actual restart proof remains separate.
Reopen if external static checks reject valid new game APIs, or a bounded upstream test
runner can replace more code while preserving no-focus behaviour and executor cleanup.


## 2026-10-28: source consolidation

Serg explicitly requested one Git project. The root DECISIONS.md supersedes the earlier fourth-mod-in-etc choice. This source now lives in fbserg/zomboid-mods with its shared tools. Runtime Lua is unchanged from the native-tested prototype.

## 2026-11-04: transient meals retain no player objects

Decision: cache only username/local-slot keys, native instance UID strings, coordinates and
meal times. Resolve live players only during a completed meal. Keep the existing event-only
execution and saved account cooldowns.
Evidence: two garbage-collection regressions fail against 0.1.1 because its cache keys retain
player objects after the game releases them. Scalar records pass those probes. The installed
IsoMovingObject constructor gives each instance a UID with a UUID. It survives as a string
without the player reference and distinguishes reconnects even if an online ID is reused. The user's
Workshop memory report supplies no log, memory measurement or reproduction, so this finding
does not establish the cause of that user's memory growth. The multiplayer client branch
only displays server notifications and never records meals.
Reopen: a measured native or player reproduction shows further retained growth, or the engine
changes instance UID lifetime. Do not
add a recurring world scan or weaken cooldown persistence without new evidence.
