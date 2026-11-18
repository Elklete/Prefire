#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

version_file="Sources/PrefireGeneratorTool/Commands/Version/Version.swift"
version="$(sed -n 's/.*static let value: String = "\([^"]*\)".*/\1/p' "$version_file")"

if [[ -z "$version" ]]; then
    echo "Could not read the generator version from $version_file" >&2
    exit 1
fi

bundle="${BUNDLE_PATH:-Binaries/PrefireBinary.artifactbundle}"
metadata="$bundle/info.json"
relative_binary_path="prefire-$version-macos/bin/prefire"
binary="$bundle/$relative_binary_path"

if [[ ! -f "$metadata" ]]; then
    echo "Bundled generator metadata is missing: $metadata" >&2
    exit 1
fi

if [[ ! -x "$binary" ]]; then
    echo "Bundled generator is missing or is not executable: $binary" >&2
    exit 1
fi

if ! jq -e --arg version "$version" --arg path "$relative_binary_path" '
    .schemaVersion == "1.0"
    and (.artifacts | keys | sort == ["PrefireBinary"])
    and .artifacts.PrefireBinary.type == "executable"
    and .artifacts.PrefireBinary.version == $version
    and (.artifacts.PrefireBinary.variants | length == 1)
    and .artifacts.PrefireBinary.variants[0].path == $path
    and ((.artifacts.PrefireBinary.variants[0].supportedTriples | sort) == ["arm64-apple-macosx", "x86_64-apple-macosx"])
' "$metadata" >/dev/null; then
    echo "Bundled generator metadata does not describe the expected universal macOS artifact." >&2
    exit 1
fi

architectures="$(/usr/bin/lipo -archs "$binary" | tr ' ' '\n' | sort | paste -sd ' ' -)"
if [[ "$architectures" != "arm64 x86_64" ]]; then
    echo "Bundled generator must contain exactly arm64 and x86_64 slices, found: $architectures" >&2
    exit 1
fi

actual_version="$("$binary" --version)"
if [[ "$actual_version" != "$version" ]]; then
    echo "Bundled generator version is '$actual_version', expected '$version'" >&2
    exit 1
fi

echo "Validated bundled Prefire generator $version ($architectures)."
