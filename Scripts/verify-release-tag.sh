#!/usr/bin/env bash
set -euo pipefail

tag=${1:?usage: verify-release-tag.sh <prefire-vX.Y.Z>}
fingerprint=${PREFIRE_RELEASE_SIGNING_FINGERPRINT:?PREFIRE_RELEASE_SIGNING_FINGERPRINT is required}

if [[ ! "$tag" =~ ^prefire-v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "release tag must be prefire-vX.Y.Z" >&2
    exit 1
fi

status=$(git verify-tag --raw "$tag" 2>&1) || {
    printf '%s\n' "$status" >&2
    exit 1
}
printf '%s\n' "$status"

if ! grep -Fq "VALIDSIG $fingerprint" <<<"$status"; then
    echo "tag $tag was not signed by the configured release fingerprint" >&2
    exit 1
fi
