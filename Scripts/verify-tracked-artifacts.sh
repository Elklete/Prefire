#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"

status=0
while IFS= read -r -d '' path; do
    case "$path" in
        *.artifactbundle|*.artifactbundle/*|*.xcframework|*.xcframework/*|*.dylib)
            echo "forbidden tracked binary delivery path: $path" >&2
            status=1
            ;;
        *)
            if test -f "$path"; then
                kind=$(file -b "$path")
                case "$kind" in
                    *Mach-O*|*ELF*)
                        echo "forbidden tracked executable artifact: $path ($kind)" >&2
                        status=1
                        ;;
                esac
            fi
            ;;
    esac
done < <(git ls-files -z)

if git grep -nE 'binaryTarget[[:space:]]*\(' -- '*Package.swift'; then
    echo "binaryTarget declarations are forbidden" >&2
    status=1
fi

if (( status != 0 )); then
    exit "$status"
fi

echo "No tracked executable artifact, artifact bundle, XCFramework, dylib, or binary target found."
