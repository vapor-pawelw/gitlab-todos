#!/usr/bin/env bash
# Syncs Project.swift's CFBundleShortVersionString and CFBundleVersion from a
# git tag and renames the CHANGELOG's Unreleased section to the tagged version.
#
# Usage:
#   scripts/sync-version-from-tag.sh v0.2.0
#
# - CFBundleShortVersionString: stripped-v semver (e.g. "0.2.0")
# - CFBundleVersion: incremented monotonically by walking existing tags
# - CHANGELOG.md: `## Unreleased` renamed to `## 0.2.0 - <today>` and a fresh
#   `## Unreleased` stub opened above it.
#
# Does NOT create commits or tags. The caller is expected to review + commit.

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "usage: $0 vX.Y.Z" >&2
    exit 1
fi

TAG="$1"
if [[ ! "${TAG}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    echo "error: tag must match vX.Y.Z (got: ${TAG})" >&2
    exit 1
fi
VERSION="${TAG#v}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

PROJECT_FILE="Project.swift"
CHANGELOG_FILE="CHANGELOG.md"

if [[ ! -f "${PROJECT_FILE}" ]] || [[ ! -f "${CHANGELOG_FILE}" ]]; then
    echo "error: must run from the repo root" >&2
    exit 1
fi

# Derive a monotonic CFBundleVersion by counting reachable semver tags + 1.
TAG_COUNT="$(git tag --list 'v[0-9]*.[0-9]*.[0-9]*' | wc -l | tr -d ' ')"
BUILD_NUMBER="$((TAG_COUNT + 1))"

echo "==> Setting CFBundleShortVersionString to ${VERSION}"
/usr/bin/sed -i '' -E \
    "s|(\"CFBundleShortVersionString\": \.string\()\"[^\"]+\"(\))|\1\"${VERSION}\"\2|" \
    "${PROJECT_FILE}"

echo "==> Setting CFBundleVersion to ${BUILD_NUMBER}"
/usr/bin/sed -i '' -E \
    "s|(\"CFBundleVersion\": \.string\()\"[^\"]+\"(\))|\1\"${BUILD_NUMBER}\"\2|" \
    "${PROJECT_FILE}"

echo "==> Renaming CHANGELOG Unreleased section to ${VERSION}"
TODAY="$(date -u +%Y-%m-%d)"
TMP_FILE="$(mktemp)"
awk -v version="${VERSION}" -v today="${TODAY}" '
    BEGIN { replaced = 0 }
    /^## Unreleased$/ && replaced == 0 {
        print "## Unreleased"
        print ""
        print "## " version " - " today
        replaced = 1
        next
    }
    { print }
' "${CHANGELOG_FILE}" > "${TMP_FILE}"
mv "${TMP_FILE}" "${CHANGELOG_FILE}"

echo
echo "==> Done. Review with:"
echo "    git diff ${PROJECT_FILE} ${CHANGELOG_FILE}"
echo
echo "    Then commit and tag:"
echo "    git commit -am 'Release ${VERSION}'"
echo "    git tag ${TAG}"
