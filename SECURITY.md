# Security policy and release baseline

## Supported source baseline

This private fork begins from upstream Prefire `6.6.0`, resolved to commit
`c49c1ae65378e48e6a8dad9993a770c8c47f8452` on 2026-11-16. The hardening branch
is `codex/harden-6.6.0-source`; the supported toolchain is Xcode 26.5 / Swift
6.3.2. See [the audit record](Documentation/Security/AUDIT-6.6.0.md) and
[SBOM](Documentation/Security/SBOM-6.6.0.cdx.json).

The root `Package.swift` and `Package.resolved` are the only production build
graph. The `Example` and `PrefireSnapshotTests` manifests are test fixtures;
they are pinned and audited but never distributed as a package product.

## Reporting and boundaries

Report vulnerabilities privately to the fork maintainers. Do not include
credentials, private source, or generated snapshots in an issue.

This fork ships only the `Prefire` library and its two build-tool plugins. It
does not ship a CLI product, artifact bundle, binary target, MCP server, board,
or render service. The internal generator is source-built by SwiftPM and may
write only under the plugin work directory.

## Release policy

Releases use protected `prefire-vX.Y.Z` tags signed by the configured release
GPG fingerprint. The release workflow imports only the matching public key,
verifies the tag, runs every source/security gate, and publishes GitHub's source
archive plus an SBOM. It does not attach an executable, binary bundle, or MCP
asset. Repository rules must require review and protect the release-tag pattern.
