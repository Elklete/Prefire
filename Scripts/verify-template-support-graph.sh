#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

expected_identities=$'prefiretemplatesupport\nswift-argument-parser\nswift-syntax'
expected_support_location="https://github.com/Elklete/PrefireTemplateSupport.git"
expected_support_version="1.0.0"

validate_lockfile() {
    local lockfile="$1"

    if [[ ! -f "$lockfile" ]]; then
        echo "Resolved package graph is missing: $lockfile" >&2
        exit 1
    fi

    local identities
    identities="$(jq -r '.pins[].identity' "$lockfile" | sort)"
    if [[ "$identities" != "$expected_identities" ]]; then
        echo "Unexpected resolved package graph in $lockfile:" >&2
        printf '%s\n' "$identities" >&2
        echo "Expected only:" >&2
        printf '%s\n' "$expected_identities" >&2
        exit 1
    fi

    if ! jq -e \
        --arg location "$expected_support_location" \
        --arg version "$expected_support_version" '
            .pins[]
            | select(.identity == "prefiretemplatesupport")
            | .location == $location and .state.version == $version
        ' "$lockfile" >/dev/null; then
        echo "PrefireTemplateSupport must resolve from $expected_support_location at $expected_support_version." >&2
        exit 1
    fi
}

validate_lockfile "Package.resolved"
validate_lockfile "Fixtures/PluginIntegration/Package.resolved"

echo "Validated trimmed template-support dependency graph."
