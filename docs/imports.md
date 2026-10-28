# Source provenance

The import commits preserve byte-identical trees from these public repositories.

| Source | Commit |
|---|---|
| fbserg/farm-trailer | f9262de92e96379615b74eb08086dc8d696efc42 |
| fbserg/truck-repaint | 6b29c71d37a9eddd688229e8ad1aff3352d0c312 |
| fbserg/backyard-birds | 7ea4ea5ae2f320e72d6c74a36647ffbe6fa1de5b |
| fbserg/etc, Dinner Together, shared tools, native tests and later art/panels | a682c54ae444e020f7806bfe16d2b0b0732cbc50 |

Then add etc's missing development fixtures, generated art, native screenshots and in-game panels.
Only mod.info and changenote.txt differ among overlapping source files. Runtime Lua for all three existing mods is identical between the two sources. The more complete standalone Farm Trailer README is retained. Original licenses are retained.

Old histories and source repos remain intact. This repo uses explicit import snapshots, not rewritten history.
Care Packages' failed serialization spike remains at etc/tmp/worktrees/issue-142, branch fix/issue-142-care-packages.
Original queue: https://github.com/fbserg/etc/issues/140.
