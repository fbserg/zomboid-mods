# Care Packages experiment: NOT FUNCTIONAL

Preserved unfinished native serialization spike from etc issue #142, branch fix/issue-142-care-packages. No package or Workshop item exists. Do not install this as a player mod. It is excluded from release and default test suites. The original worktree remains intact.

Observed failure on SERGBOOK.local, Build 42.21.0, snapshot 5c11bed97f43789469bc74ab6ce94d5b64e9efa1, receipt 20261028T162737-70e4be84b6e9: IsoDeadBody.save rejected an uninitialized human visual with "unhandled baseVisual class". The codec failed before inventory removal. This is a failed hypothesis, not a safe parcel implementation.

The test fixture records the desired native round trip: nested contents, food age, gun condition/ammo, notebook text, arbitrary mod data and real save/restart. None is proven by this failed run. Future work must preserve exact state and food ageing, establish atomic failure behavior, then prove two-client seal/open actions. Dinner Together release comes first.
