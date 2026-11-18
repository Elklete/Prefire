#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

for forbidden in "Prefire""Binary" "Prefire""CLI" "Prefire""Executable" "PREFIRE_""BINARY_PATH" "artifact""bundle" "Bin""aries/"; do
    matches="$(git grep -n -I -F -- "$forbidden" -- ':!Scripts/verify-source-only.sh' || true)"
    if [[ -n "$matches" ]]; then
        echo "Source-only validation found forbidden generator wiring: $forbidden" >&2
        echo "$matches" >&2
        exit 1
    fi
done

while IFS= read -r path; do
    [[ -e "$path" ]] || continue
    case "$path" in
        Bin""aries/*|*.artifact""bundle|*.artifact""bundle/*)
            echo "Source-only validation found a tracked generator artifact: $path" >&2
            exit 1
            ;;
    esac
done < <(git ls-files -co --exclude-standard)
