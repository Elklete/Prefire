#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"

locks=(
    Package.resolved
    Example/Package.resolved
    Example/PreFireExample.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
    PrefireSnapshotTests/Package.resolved
)
for lock in "${locks[@]}"; do
    test -f "$lock" || { echo "missing lockfile: $lock" >&2; exit 1; }
    jq -e '
      .version >= 2 and
      ([.pins[] |
        (.kind == "remoteSourceControl") and
        ((.state.revision | type) == "string") and
        (.state.revision | test("^[0-9a-f]{40}$")) and
        ((.state.version | type) == "string") and
        (.state.version | length > 0)
      ] | all)
    ' "$lock" >/dev/null || {
        echo "non-immutable or malformed pin in $lock" >&2
        exit 1
    }
done

if rg -n '\.package\([^\n]*\b(from:|branch:|revision:)' --glob 'Package.swift' .; then
    echo "manifests must use exact versions (local fixture paths are the only exception)" >&2
    exit 1
fi

swift package resolve
git diff --exit-code -- Package.resolved
echo "Lockfiles are immutable and root resolution is reproducible."
