# Decisions

## 2026-10-28: one repository

Decision: use fbserg/zomboid-mods for all four mods, shared development tools and release assets.
Evidence: Serg explicitly requested one Git project after the fourth mod exposed duplicated testing and publishing instructions. This supersedes earlier per-mod repository choices. Latest standalone remote trees are imported intact, with commit provenance. Existing repositories remain available, without force pushes, archival or deletion.
Reopen: independent maintainers require separate access or release ownership.

## 2026-10-28: complete Dinner Together first

Decision: finish Dinner Together assets, game metadata and publication before more feature work.
Evidence: Serg asked to finish the parked mod first. Care Packages failed its native serialization spike before any inventory mutation. It remains an experiment, not a functioning release. Funeral and housewarming remain separate queued work.
Reopen: Dinner Together release has observed live evidence.

## 2026-10-28: pictures and release truth

Decision: keep a reproducible generated illustration plus native screenshots, with prompts and test receipts beside the release. Use the established cream-title pixel-art family.
Evidence: prior three mods use this family. Native two-client proof already passes for Dinner Together. Generated images cannot prove a working feature.
Reopen: actual Steam thumbnail inspection or gameplay captures show a clarity problem.

## 2026-10-28: native Steamworks gallery and download

Decision: use the installed Steamworks library through a small ctypes helper for gallery queries/uploads and release downloads. Keep the game's uploader for runtime/description/preview.
Evidence: four existing Birds gallery entries were read, a different non-empty gallery was rejected, Dinner Together's gallery was uploaded and every public CDN byte matched. The actual downloaded release passed two native client rounds. A whole-batch quota preflight prevents the observed partial reservation failure.
Reopen: installed interface version changes or a documented game API replaces these bindings. No browser credentials, runtime Java or third-party SDK is distributed.

## 2026-10-28: mandatory quality gates and upstream reuse

Decision: qualify each release through one project-test adapter with portable, static, native, real multiplayer/reconnect, persistence, performance, package and visual gates. Dinner Together adopts the contract first. Older mods need current evidence before promotion.
Evidence: Serg requested performance and MP as general modmaking checks. PZ_DevHarness supplies the pinned, checksum-verified static checker and actual Snapshot module. Its world-state comparison caught a duplicate photo fixture on clients. pzkit overlaps the existing static path. PZ_Optimization supplies a useful measurement method but its renderer stack is excessive here. See docs/mod-quality.md for pins, sources and limits.
Reopen: a new mod requires data indexing, frame-tail profiling or complex action orchestration that the current small adapter cannot cover.

## 2026-10-28: hidden windows from creation

Decision: suppress native show/focus calls and create invisible, unfocused windows. Audit actual GLFW attributes and macOS on-screen/foreground state for owned PIDs. Apply the shared policy to every graphical runner.
Evidence: the earlier agent suppressed focus but still called glfwShowWindow. Two real clients and the legacy Birds launcher now pass the native and OS hidden checks while producing valid rendered images. Guard negative controls reject visibility and focus without displaying a window. No installed game file changes.
Reopen: the installed GLFW/game implementation changes, a policy check fails, or a supported display-free graphical engine becomes available.

## 2026-10-28: a home is part of the visual brief

Decision: replace Dinner Together's roadside captures with an authentic native furnished home. Keep illustration, staged props and actual gameplay distinct. Bind visual approval to asset hashes.
Evidence: Serg rejected the cold roadside mood. The first kitchen frames passed gameplay checks but still failed visual review due to foreground lines. A functional test alone cannot approve listing images.
Reopen: thumbnail or native poster inspection fails readability, warmth or an honest feature demonstration.

## 2026-10-28: deterministic encounters in meal fixtures

Decision: disable PvP and declare a versioned zero-zombie sandbox for the disposable social-mod runner. Assert the setting and no local zombies, keep normal action duration and fail on cancellation.
Evidence: a downloaded-runtime run showed PlayerHitReactionState during a cancelled food action despite ghost/invincible flags. The installed 42.21 sandbox defines Zombie Count option 6 as None and PopulationMultiplier zero. The real download then completed both meal rounds and a fresh client reconnect with ordinary native actions and state agreement.
Reopen: a combat/encounter mod needs an explicit mod-owned sandbox and encounter probe. Do not use a peaceful social fixture as combat proof.
