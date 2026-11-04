# Dinner Together 0.1.3 evidence

The user approved the 80/20 image reduction and an update comment, then requested explicit
IDs on the other three owned Workshop listings too. Those metadata-only updates are verified
in ../workshop-ids-2026-11-04.json and committed separately.

The Dinner runtime changes only modversion and the three menu posters. Each poster was
re-exported through the existing deterministic asset helper from the original illustration
or native screenshot, with a maximum edge of 768 pixels. All three outputs were inspected.
Original gallery files, illustration masters, avatar and preview remain unchanged. The visual
review preserves capture provenance and binds the three new poster hashes. The asset helper
now uses 768 pixels for future poster exports too.

The native menu probe measured a 256 × 256 icon and three 1024 × 512 padded textures.
Total RGBA base storage is 6,553,600 bytes, 6.25 MiB. The previous release measured 24.25 MiB.
The difference is 18 MiB, about 74%. This is padded base storage, not a measurement of GPU
residency, mipmaps, masks, decode buffers or driver overhead. The same four texture objects
and OpenGL IDs were reused through 100 actual native panel setter cycles. The heap after
those cycles and three later idle samples stayed within the declared 16 MiB growth budget.
The hidden native and owned-PID OS guards passed. Exact sample values, executor, immutable
snapshot/tree and cleanup result are in menu-memory.json and menu-memory-receipt.json.

The meal Lua and translation remain unchanged from 0.1.2. Saved cooldowns, meal rules and
compatibility limits remain the same. This release reduces a measured fixed image cost.
It does not establish the cause of the original one-line memory report or certify an
unknown mod stack. The new poster dimensions do not replace a gameplay/MP check.

The complete release checker passed all required categories, 18 portable tests on sublet,
native static/food/geometry/process-restart and two real-client reconnect rounds on
SERGBOOK.local, performance budgets, the updated visual hash review and runtime-only
packaging. Each immutable snapshot/tree and clean executor receipt is in qualification.json.
The 10,000 cooldown meals retained 42.83 KiB whole-JVM heap and produced zero notifications.
The two native performance negative controls passed. See performance.json.

Qualified ZIP SHA-256: `546e78e6b039f0644a3d0c000ce16a2183abcbca8e6b220641911b200f220fcc`.

The native uploader published 0.1.3 to existing item 3828971865 as verified Steam owner
76561198033173095, ModeratExtremist. Exact public description, owner, visibility, preview
and every full-size gallery byte matched source. All seven downloaded runtime files match
the release manifest. The personal local copy matched the previous release before its four
changed files were updated, and now matches 0.1.3. No saves or active mod lists changed.

The actual Steam download passed dinner-release on SERGBOOK.local, snapshot
77ce14b284428f582691b1fd316ab399a6b265a4, tree 42d509654740c35e2be3289868ad4c2abc1fdf82,
receipt 20261104T203215-75f07c3454df, 136.564 seconds, exit 0, cleanup true. Two
real clients completed both ordinary food rounds. Beth restarted/reconnected, world/stats
agreed, exactly two production notifications were sent and the reconnect received no
duplicate. All three client PIDs passed the native hidden-window guard and OS audit.

The user requested a shorter, plain-language update. Steam rejected an in-place edit
with "You are not allowed to edit this comment." The short replacement was posted as
ModeratExtremist, verified in the author view, and only the previous own comment was removed.
The new comment is 571553910742931412. It states the memory/image improvements, points to
the description for setup and asks for bug reports/logs. The two original reader comments
remain. See update-comment.json for exact text, the current permalink and review status.

The public GitHub 0.1.3 release targets 1de7372128acba1aefd704e57dfa4f0cdc30c96a. Its anonymously
downloaded 1,705,362-byte ZIP matches the qualified package byte for byte. See github-release.json.
