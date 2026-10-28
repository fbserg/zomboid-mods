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
