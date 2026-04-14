# Building GitLab To-Dos from source

## Requirements

- macOS 14+
- Xcode 16+ (Swift 6 toolchain)
- [mise](https://mise.jdx.dev) — `brew install mise`
- [glab](https://gitlab.com/gitlab-org/cli) — `brew install glab`, then run `glab auth login`

## First-time setup

From the repo root:

```bash
mise install           # installs the pinned Tuist version from mise.toml
tuist generate         # generates GitLabTodos.xcodeproj
open GitLabTodos.xcworkspace
```

`GitLabTodos.xcodeproj` is generated — it is intentionally git-ignored. Re-run `tuist generate` whenever `Project.swift`, `Sources/**`, `Resources/**`, or `Tests/**` change in a way that affects the project graph (new files, new targets, new resources).

## Running

Build and run the `GitLabTodos` scheme from Xcode. The app has `LSUIElement = true` and will appear as a menu bar item only — no Dock icon, no main window.

## Command-line build

```bash
tuist generate --no-open
xcodebuild \
  -project GitLabTodos.xcodeproj \
  -scheme GitLabTodos \
  -configuration Debug \
  -destination "platform=macOS" \
  build
```

The built `.app` bundle lives under the Xcode DerivedData path printed at the end of the build.

## Running tests

```bash
xcodebuild \
  -project GitLabTodos.xcodeproj \
  -scheme GitLabTodos \
  -destination "platform=macOS" \
  test
```

Tests are written with Swift Testing (`import Testing`).

## Release builds

A release build script lives at `scripts/build-release.sh` (once added). It invokes `xcodebuild archive`, exports the unsigned `.app`, and packages it into a DMG and a ZIP under `release/`. Releases are tag-driven: `git tag v0.1.0 && git push --tags` triggers the release workflow.
