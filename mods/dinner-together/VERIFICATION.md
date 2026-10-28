# Release verification

Build 42.21.0, revision 4a0e9546ec. Runtime Lua is byte-identical to the original tested prototype. No dependencies.

## Consolidated repository checks

| Gate | Executor | Exact snapshot | Result |
|---|---|---|---|
| test | sublet | b46a8f300224bba0db9ebd9ca5bc7b6ef87e491c | 97 tests (54 farm, 10 repaint, 21 birds, 12 dinner), cleanup true, 0.456 s |
| dinner-static | SERGBOOK.local | 2c90a09db1f7187d2e1f0e14419edaa05e61554a | native compilation, API/JSON checks, two negative controls, cleanup true, 4.723 s |
| dinner-engine | SERGBOOK.local | 9c0030711565d1fbb761a9a6e21f5a759eeb38a3 | six native scenarios including full process restart, cleanup true, 74.71 s |
| workshop-ugc | SERGBOOK.local | c14b7a18722db67db4934b1758a24f4e43fdd760 | four existing gallery files read through native Steamworks, cleanup true, 0.413 s |
| dinner-photos | SERGBOOK.local | da03c1487e8712b11d975e2abfda141e08e188eb | two real clients, vanilla actions, stats and notification, cleanup true, 149.267 s |

## Pictures

Avatar: workshop/art/dinner-avatar.png. Wide illustration: workshop/art/good-company.png. Exact prompts and tool are in workshop/art/PROMPTS.md. Selected exports were inspected at 128 and 268 pixels. Both game screenshots are native 1440x900 frames, inspected after export. The scene uses server-provided clothing, apples, controlled noon weather and starting stats in a disposable world. The actual production meal rule, action and halo message run unmodified. No tables or plating feature is implied.

## Publication

Final photo-export and native panel gate passed on SERGBOOK.local, snapshot 452c169d6d8762dec5760744de4c3eb01b4282c4, 99.958 s, cleanup true. Both clients decoded the icon and all three posters. Both native screenshots were exported through the declared capture manifest and inspected. Steam owner 76561198033173095 ModeratExtremist verified through the game uploader and Steamworks. Native content validation passed. Gallery helper read-only query passed. A different non-empty gallery was deliberately rejected before a write.

The Care Packages experiment is not part of this release and remains unproved. Earlier failed or cancelled photo iterations were not counted as passes.
