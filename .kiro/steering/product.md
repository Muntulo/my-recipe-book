# My Recipe Book — Product & Architecture Guidance

Always-on steering for work in this repo. Keep implementation aligned with the
product vision below.

## What this app is

A native SwiftUI + SwiftData recipe manager for iPad and iPhone that feels like a
beautiful physical cookbook: large typography, book-like reading layout,
optimized for iPad landscape. Platform priority: iPadOS first, iPhone adaptive,
Android much later.

## Core principle: offline-first and private

- Phases 1 and 2 run **entirely on-device**. No network calls, no backend, no
  telemetry that ships recipe data off the device.
- On-device OCR uses Apple's Vision framework. Manual entry and OCR are the only
  import paths in the free/offline product.
- Do NOT introduce cloud dependencies, remote APIs, or accounts into Phase 1/2
  features. Anything that leaves the device is a Phase 3 premium concern.

## Roadmap (scope guardrails)

- **Phase 1 (MVP, offline):** Recipe CRUD, OCR import, manual entry, iPad reading view.
- **Phase 2 (offline, complete the cookbook):** Cook Mode, serving scaling,
  measurement conversion (metric ↔ US/imperial), nutrition/calorie calculation,
  grocery lists, search/filters, tags, favorites & ratings. All on-device.
- **Phase 3 (premium, cloud-powered):** AWS sync, social & video import from
  PUBLIC Instagram/TikTok/YouTube/Pinterest/web, web scraper, export, meal
  planner. Requires a backend; this is the paid tier.

When asked to build a feature, confirm which phase it belongs to. Do not pull
Phase 3 cloud work into the offline build unless explicitly asked.

## Monetization (high level)

Free = everything on-device. Premium = cloud-powered features (sync, social/video
grabs, meal planner). Free users get a small taste of social grabs (3 total).
Social/video import only ever touches PUBLIC content. Detailed strategy lives in
the gitignored `monetization.md` at the repo root — do not commit that file or
copy its contents into tracked files.

## Git discipline (STRICT — agents have drifted on this)

- **Never create git commits or branches unless the task prompt explicitly asks for it.** Default behavior is to leave all changes UNCOMMITTED in the working tree for the user to review. A prior workflow committed without being asked — do not repeat this.
- **Never push.** Pushing is always a human decision made by the orchestrator/user, never by a workflow step.
- Do not run `git add`/`git commit`/`git branch`/`git rebase`/`git reset` as part of implementing a feature. Verification is done by building (`xcodebuild`) and tracing, not by committing.
- If you believe a commit is warranted, STOP and ask via your status channel rather than committing unilaterally.
- Never stage or commit `monetization.md` (gitignored), `.agents/` artifacts, or `*.xcuserstate`.

## Code conventions

- SwiftUI for all UI; SwiftData `@Model` types for persistence.
- Keep reusable parsing/conversion/calculation logic in
  `MyRecipeBook/MyRecipeBook/Utilities/` or `Services/`, not inline in views.
- The Xcode project uses file-system-synchronized groups
  (`PBXFileSystemSynchronizedRootGroup`): new `.swift` files dropped into the
  source folders are picked up automatically — do NOT hand-edit
  `project.pbxproj` to add file references.
- Numeric/locale formatting should be deterministic (pin `en_US_POSIX` where a
  stable decimal format is needed).
- Match the existing Swift style in neighboring files. Build with `xcodebuild`
  against an iOS Simulator destination to verify changes compile.
