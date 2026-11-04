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
