# Dinner Together client memory investigation

Two fresh hidden native menu clients on Build 42.21, runtime 0.1.2, no runtime modifications.
The new opt-in `dinner-menu-memory` suite reuses project-test, the existing native launcher,
window suppression, owned-PID OS audit and cleanup. Six existing evidence guard tests also
pass on sublet. Exact source snapshots/trees, hosts and cleanup results are in the receipts.

## Findings

| Asset | Image pixels | Native padded pixels | RGBA base storage |
|---|---|---|---|
| Icon | 256 × 256 | 256 × 256 | 0.25 MiB |
| Illustration poster | 1440 × 960 | 2048 × 1024 | 8 MiB |
| Meal screenshot poster | 1440 × 900 | 2048 × 1024 | 8 MiB |
| Company screenshot poster | 1440 × 900 | 2048 × 1024 | 8 MiB |
| Total | | | 24.25 MiB |

The values come from native Texture width/height getters after assets report ready and have
positive OpenGL IDs. They are padded RGBA base storage, not measured GPU residency or mipmap,
compression, mask, temporary decode or driver overhead. The game caches these texture objects.
Both runs checked the actual native ModInfoPanel description/thumbnail setters 100 times.
Every cached texture object and OpenGL ID stayed the same.

The final run's retained whole-JVM heap changed from 681694.08 KiB after initial asset load
to 681718.77 KiB after 100 setter cycles, a 24.69 KiB increase. Three later idle samples end
at 681719.63 KiB, a 25.55 KiB increase from initial load. That is below the declared 16 MiB
retained-growth ceiling. The first run's repeat-cycle heap delta was negative, with a later
roughly 0.5 MiB one-time idle step. Neither short run shows unbounded growth in this path.

In the second run process RSS fell from roughly 2.83 GiB to 1.83 GiB while live Java heap
stayed near 665.74 MiB and all texture objects/IDs stayed cached. RSS is not retained Java
heap. Native libraries, mappings, committed heap, OS residency and graphics make raw process
readings unsuitable as proof of a mod leak. This run does not attribute that RSS change to
any particular allocator. A no-mod fresh-process baseline and longer soak are required to
attribute whole-process trends to the runtime.

Native source inspection found that production notifications use HaloTextHelper's two
fixed four-slot string arrays. Dinner Together sends at most one daily reward notification
per account. No growing message queue or idle callback exists in this mod. Saved cooldowns
retain one timestamp per rewarded account, which can grow with unique historical server
accounts. It does not grow with repeat meals on the same account. No new evidence justifies
changing the saved-cooldown policy.

Four other locally installed hooks also wrap food completion. The inspected wrappers call
the previous completion function. This is not a compatibility test of that stack, and it is
not the reporter's mod list. A one-line report cannot identify a conflict. No dependency code
was copied or altered.

## Smallest next steps

- Keep this diagnostic outside the runtime. It already covers the previously missing menu
  asset path without a second launcher, a permanent monitor or runtime Java.
- A 768-pixel-wide cap on the three shipped in-game posters would give 1024 × 512 padded
  textures, reducing estimated total RGBA base storage from 24.25 to 6.25 MiB. The full-size
  source/gallery art can stay separate. This is a prospective 18 MiB saving, not a measured
  release or a fix for a demonstrated gigabyte leak. No images changed in this investigation.
- If an actual report persists, identify whether it starts at the mod menu, world load,
  ordinary meals or repeated deaths/reconnects. Get the matching game build, RAM, mod list
  and console log. Reproduce the same route with the mod alone and the exact stack. Bisect
  only a stack-specific reproduction. Capture a heap histogram/dump when retained Java heap
  grows. If only process/graphics memory grows, use native allocation evidence instead.

Oracle's [Native Memory Tracking limits](https://docs.oracle.com/en/java/javase/23/vm/native-memory-tracking.html)
also exclude third-party native allocations. JVM-only checks cannot qualify all client memory.

## Limits

This measures one frontend, actual native panel setters and about 25 seconds after initial
menu warmup. It does not navigate the complete mod-selector UI, run a long gameplay session,
cycle native player deaths or test the unknown reporter stack. Existing 0.1.2 meal, reconnect
and retention evidence remains in the release bundle. No claim that the reporter's original
problem is resolved follows from these results. There is no new Workshop release.

The modified shared runner's ordinary multiplayer path also passed dinner-qualified-mp
on SERGBOOK.local, snapshot fe7a58567b5ea9b87e8e34500c7e0c81bc1658f0, tree
c10d6921bc7d5087bb87213d132e1fcb8d63fec2, receipt 20261104T201736-cd3b01557153,
127.319 seconds, exit 0, cleanup true. Two actual clients completed both food rounds,
Beth restarted/rejoined, world/stats agreed and no duplicate reward occurred. All three
client PIDs passed native visibility/focus guards and the owned-PID OS audit. A subsequent
change only clarified the memory fixture's ceiling comment. No runtime file changed.
