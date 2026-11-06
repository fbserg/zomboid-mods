# Decisions

## 2026-11-06: the list is the vanilla notepad page

Decision: a one-page CanBeWrite literature item. Players write through the vanilla journal window.
The server reads `seePage(1)` and writes `[x] ` marks and the signature back into the same page.
Evidence: B42.21 SyncItemFieldsPacket carries customPages, the custom name and mod data both ways.
The native MP gate wrote through the real window on one client, saw the page on the server and
saw the server's marks on the other client. No custom UI, packet or item format is needed.
Reopen if a build stops syncing customPages, or players need quantities enforced.

## 2026-11-06: server minute scan, carried items only

Decision: EveryOneMinute scans online players (local slots in single player) for carried lists.
A line is crossed off once any carried item's display name contains it or a simple singular.
Crossed-off state lives in the list's mod data, so used items stay crossed off.
Evidence: inventory transfers, crafting, looting and foraging have no single completion hook.
The scan measured 0.06 ms at 64 idle players and about 0.09 ms per list holder with 100 items.
Steady state sends no notifications or item syncs. Reopen if a measured stack needs event hooks.

## 2026-11-06: rewards and identity

Decision: finish a list of 3+ lines for -10 boredom/-5 unhappiness. Hand someone else's
finished list back for -10 unhappiness each and a `~ Name <3` signature. Each kind pays each
person once per 24 game hours in world ModData. Notices still show inside the cooldown.
The first holder seen with text is the writer.
Evidence: matches Dinner Together's small, social reward scale. A writer hook would need the
client UI path, which the server cannot trust. The scan already sees the first holder.
Reopen if hand-offs inside one game minute misattribute lists in practice.

## 2026-11-06: no server-side translations

Decision: the signature is `~ Forename <3`, built without getText. Clients translate notices.
Evidence: the native dedicated server returned raw keys for this mod's IG_UI and ItemName
entries while vanilla item names were translated. Reopen if the server loads mod translations.

## 2026-11-06: finished lists stop scanning

Decision: skip a finished list unless it is someone else's list in its writer's hands, awaiting delivery.
New lines on a finished list are ignored. Players start a new list for new errands.
Evidence: Serg asked for a small performance win. Kept lists otherwise re-parsed every game minute
forever. Portable tests count page reads for own, shopped and delivered lists.
Reopen if players expect finished lists to accept new lines.
