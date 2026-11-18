#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

version_file="Sources/PrefireGeneratorTool/Commands/Version/Version.swift"
version="$(sed -n 's/.*static let value: String = "\([^"]*\)".*/\1/p' "$version_file")"

if [[ -z "$version" ]]; then
    echo "Could not read the generator version from $version_file" >&2
    exit 1
fi

bundle="Binaries/PrefireBinary.artifactbundle"
bundle_parent="$(dirname "$bundle")"
relative_binary_path="prefire-$version-macos/bin/prefire"

mkdir -p "$bundle_parent"
stage_directory="$(mktemp -d "$bundle_parent/.prefire-bundle.XXXXXX")"
stage_bundle="$stage_directory/PrefireBinary.artifactbundle"
bootstrap_bundle=false

cleanup() {
    rm -rf "$stage_directory"
    if [[ "$bootstrap_bundle" == true ]]; then
        rm -rf "$bundle"
    fi
}
trap cleanup EXIT

# SwiftPM validates every binary target while loading this package, including when it only
# builds the independent `prefire` product. A clean checkout has no bundle yet, so give the
# manifest a temporary local macOS executable. It is never executed and is always replaced by
# the validated source-built generator below.
if [[ ! -d "$bundle" ]]; then
    mkdir -p "$bundle/$(dirname "$relative_binary_path")"
    cp /usr/bin/true "$bundle/$relative_binary_path"
    chmod 755 "$bundle/$relative_binary_path"
    jq -n --arg version "$version" --arg path "$relative_binary_path" '
        {
            schemaVersion: "1.0",
            artifacts: {
                PrefireBinary: {
                    type: "executable",
                    version: $version,
                    variants: [{
                        path: $path,
                        supportedTriples: ["arm64-apple-macosx", "x86_64-apple-macosx"]
                    }]
                }
            }
        }
    ' > "$bundle/info.json"
    bootstrap_bundle=true
fi

swift build -c release --arch arm64 --arch x86_64 --product prefire
build_directory="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)"
built_binary="$build_directory/prefire"

if [[ ! -x "$built_binary" ]]; then
    echo "Could not find the universal source-built generator at $built_binary" >&2
    exit 1
fi

mkdir -p "$stage_bundle/$(dirname "$relative_binary_path")"
cp "$built_binary" "$stage_bundle/$relative_binary_path"
chmod 755 "$stage_bundle/$relative_binary_path"

jq -n --arg version "$version" --arg path "$relative_binary_path" '
    {
        schemaVersion: "1.0",
        artifacts: {
            PrefireBinary: {
                type: "executable",
                version: $version,
                variants: [{
                    path: $path,
                    supportedTriples: ["arm64-apple-macosx", "x86_64-apple-macosx"]
                }]
            }
        }
    }
' > "$stage_bundle/info.json"

BUNDLE_PATH="$stage_bundle" Scripts/verify-bundled-generator.sh

rm -rf "$bundle"
mv "$stage_bundle" "$bundle"
bootstrap_bundle=false

echo "Updated $bundle from root source version $version."
