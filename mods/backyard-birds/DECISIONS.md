# Decisions

## The vanilla bird bath, no new feeder

B42 has no bird feeder. The vanilla Bird Bath already spawns in yards, can be picked up and placed, and has two tiles named "Bird Bath".
Reusing it needs no tile pack, recipe or item, so the mod saves nothing. Reopen if Serg wants a craftable feeder with seed upkeep.

## Screen-drawn birds, not world sprites

Two world routes exist: an `IsoObject` with a sprite loaded from a loose PNG, or a sprite attached to the bath object.
Both are written into the save, so a removed mod or a crash mid-visit could leave stray objects. Screen birds pinned to the
tile like forage icons cost one UI element and leave no trace. The price is no occlusion by walls and roofs in front of the bath.
Reopen if that looks wrong in play, or if B42 gets a transient world-sprite API.

## Server picks visits, clients animate

The server rolls visits and changes stats, the same path vanilla flower harvests use, then syncs them with `syncPlayerStats`.
Every nearby player sees the same flock. Arrival order, idle animation and scare-offs stay on each client, so they cost no network traffic.
A scare on one client does not end the visit for others.

## Short, rhythmic visits

The first build put birds at a bath about 40% of daylight. Serg asked for visits that feel like moments. Visits now last 4–12 game minutes,
cluster in the morning and evening, stop on frozen water, and land and leave one bird at a time. The mood text shows only on a boost (hourly) or a rare bird.
Reopen the chances in `BackyardBirds.CHANCE` if play shows too few or too many.

## No feather or droppings drops

Items would need loot rules, a server path and saved data, and Ammo Maker already turns a feeder into droppings. Reopen on request.

## Native photo harness kept

Truck Repaint dropped its scripted client because it stole the screen. This mod's product is visual, so the photo client stays.
It launches as a UI-element app with all volumes at 0, so it takes no focus and plays no sound, but it still runs FMOD for the song checks.

## Third mod, still one repo per mod

Truck Repaint's decision said to reopen the one-repo-per-mod rule at a third mod. This mod shares no runtime code with the other two
and has no dependencies, so it got its own repo, `fbserg/backyard-birds`, like the others. Its native harness stays in `fbserg/etc` and
reuses `farm-trailer/tests/FarmEngineMain.java` and `FarmPhotoMain.java` by path. Reopen at a fourth mod, or when mods start sharing Lua.
