# GitLabTodos — Agent Guide

System prompt for Claude Code (and other agents) working on **GitLab To-Dos**, a macOS menu-bar app that surfaces the user's GitLab to-do inbox via the `glab` CLI.

This file captures decisions, conventions and constraints that are *not* derivable from reading the code. Keep it terse and up to date — only record patterns that prevent bugs or help future agents make the right judgement calls.

---

## Tech foundation

- **Language:** Swift 6 (`SWIFT_VERSION = 6.0`), SwiftUI only — no AppKit except for small bridges (`NSWorkspace.open`, `NSImage`, `NSApplication.terminate`).
- **Minimum OS:** macOS 14.0. This unlocks `@Observable`, `MenuBarExtra(style: .window)`, `SMAppService.mainApp`, string-catalog symbol generation. Do **not** raise or lower this without discussing — raising it breaks users, lowering it costs us `@Observable`.
- **Project generator:** [Tuist](https://tuist.dev) 4.x, pinned via `mise.toml`. The Xcode project is generated — never commit `GitLabTodos.xcodeproj` or edit it by hand.
- **No external SPM dependencies.** Everything ships in-tree.
- **No App Sandbox.** The app shells out to `glab` via `Process`, which sandbox blocks. Matches the reference architecture.
- **Bundle ID / display name:** `com.vaporpw.GitLabTodos` / "GitLab To-Dos". Xcode target is `GitLabTodos` (no dashes, Swift identifiers).

## Project generation workflow

Install the toolchain once:

```bash
brew install mise          # if not already installed
mise install               # reads mise.toml, installs tuist
```

Then, after pulling a change that touches `Project.swift`, resources, sources, or localization files:

```bash
tuist generate --no-open
```

This regenerates `GitLabTodos.xcodeproj`. Open it with `xed .` or `open GitLabTodos.xcworkspace`.

Do **not** run `tuist generate` automatically from scripts the user didn't ask for — it's intentionally a manual step so the user knows when the project graph changes. Editor errors like "No such module 'ProjectDescription'" or "No such module 'Testing'" in `Project.swift` / `Tests/**` are SourceKit false positives from running outside an xcodeproj context; they disappear after `tuist generate` + opening the workspace.

### Verifying a change builds

From the repo root, after generating:

```bash
xcodebuild \
  -project GitLabTodos.xcodeproj \
  -scheme GitLabTodos \
  -configuration Debug \
  -destination "platform=macOS" \
  build
```

Per the user's build-artifact rule, **delete the generated xcodeproj / derived data as soon as the build has been validated** — leaving it lying around causes stale-schema confusion on the next agent's turn. Only keep build output when the user explicitly asked for a runnable binary.

### Running tests

```bash
xcodebuild \
  -project GitLabTodos.xcodeproj \
  -scheme GitLabTodos \
  -destination "platform=macOS" \
  test
```

Tests use **Swift Testing** (`import Testing`, `@Suite`, `@Test`, `#expect`). Do not mix in XCTest — pick one framework per file.

## File layout

```
Project.swift              # Tuist project definition
Tuist.swift                # Tuist global config (root, NOT Tuist/Config.swift)
mise.toml                  # pins Tuist version
Sources/
  GitLabTodosApp.swift     # @main App + scenes
  Model/                   # Todo, ActionName, TargetType, GlabError, RefreshInterval
  Services/                # GlabService, TodoMonitorService, NotificationService,
                           # SettingsManager, LaunchAtLoginService, AvatarCache,
                           # OnboardingDetector, UpdateService
  Views/                   # TodoListView, TodoRowView, TodoBadgeView, etc.
  Utilities/               # ProcessRunner, RelativeTimeFormatter, Logger
Resources/
  Assets.xcassets/
  Menu.xcstrings           # dropdown chrome
  Actions.xcstrings        # per-action-name verbs
  Settings.xcstrings
  Onboarding.xcstrings
  Notifications.xcstrings
  Localizable.xcstrings    # generic only (save, cancel, ok, quit, …)
Tests/
  *Tests.swift             # Swift Testing
  Fixtures/                # JSON payloads captured from `glab api`
```

## Localization

- Use **per-feature `.xcstrings`** catalogs. Do not dump feature strings into `Localizable.xcstrings`.
- `Localizable.xcstrings` is for truly generic keys whose name fits any caller (`common.save`, `common.cancel`, `common.ok`). Never reuse a key named after a different feature.
- In SwiftUI: `Text("menu.header.title", tableName: "Menu")`. In non-`Text` contexts: `String(localized: "notifications.single.title", table: "Notifications")`.
- `defaultLocalization: "en"`. No other languages are shipped in v1, but the infrastructure is in place.
- `STRING_CATALOG_GENERATE_SYMBOLS = YES` is on, so xcstrings entries become generated Swift symbols. Prefer those when you want compile-time safety.

## Settings / persistence

`SettingsManager` is `@Observable`, wraps `UserDefaults`, and uses **explicit `save()`** after every mutation. Do NOT migrate to property-wrapper reactive persistence — the reference architecture deliberately keeps writes explicit so we can batch them around mutation sequences and avoid accidental I/O on every SwiftUI recomputation.

Keys currently persisted live in `SettingsManager.swift` — read that file to get the authoritative list rather than mirroring it here.

## glab integration

- All calls are shell-outs to `glab` via `ProcessRunner` (wraps `Process`).
- **Never** use `nil` environment or full inheritance on the `Process`. Construct `environment` explicitly, always including `PATH` and `HOME`. `HOME` is mandatory because `glab` reads credentials from `~/.config/glab-cli/config.yml`.
- Pagination uses `glab api --paginate` so we don't hand-roll page walking.
- Host is always `glab`'s default. We do **not** expose a host picker. We *do* cache the resolved host (`glab config get host`, with fallback to parsing the first `target_url`) to build "Open in browser" links correctly on self-hosted instances.
- **Snooze is not implemented.** GitLab's REST API has no snooze endpoint (the web UI uses a GraphQL mutation). Do not add a local-only snooze unless the user asks — they explicitly declined it because it would diverge from the web UI.
- **Comment excerpts for mentioned/directly_addressed todos are not displayed.** The REST `body` field equals the target title, not the inline comment. Getting the comment would require per-todo note fetches. Accepted tradeoff.

## Error handling philosophy

Errors from `glab` are mapped into a typed `GlabError` enum with a localized `userMessageKey`. The dropdown shows a non-destructive red banner and keeps the previous to-do list clickable — **never clear `allTodos` on error**. A stale list is more useful than an empty one while the user fixes their auth.

## Commit discipline

- Commit messages in **English**. Never add `Co-Authored-By:` lines.
- Split large features into multiple commits by concern for easy MR splitting: models → services → views → wiring.
- Each commit should build and, where possible, be independently testable.
- Ship localization keys and feature flags **alongside** the code that uses them, not upfront.

## Changelog discipline

Every user-facing change merged to `main` must be evaluated for `CHANGELOG.md` inclusion. Add the entry at commit time, under `## Unreleased`. At release time, the `Unreleased` section gets renamed to `<version> - <date>` and a new `Unreleased` stub is opened. The UpdateService (once built) surfaces the latest version's section as a "What's New" window on upgrade.

## Self-learning

If a future agent discovers a constraint, decision or gotcha that isn't already in this file — and that *isn't* readily derivable from reading the code — add it here. Do not add discoverable implementation detail. Keep the signal-to-noise ratio high.
