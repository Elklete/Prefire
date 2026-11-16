# Prefire 6.6.0 source-hardening audit

Audit date: 2026-11-16  
Fork branch: `codex/harden-6.6.0-source`  
Upstream release: `6.6.0` / `c49c1ae65378e48e6a8dad9993a770c8c47f8452`

## Baseline and scope

The upstream release tag was fetched directly from `BarredEwe/Prefire`; its
release page identifies tag `6.6.0` and commit `c49c1ae`. The original root
package was a binary-wrapper package and had **no** `Package.resolved`. The
actual source generator graph was therefore audited from
`PrefireExecutable/Package.resolved` at the pinned tag, rather than from an
older cache. That nested manifest and lockfile are removed in this fork.

Initial checkout was the expected `github.com/Elklete/Prefire` fork on clean
`main` (`c020027…`). No Elklete file, dependency, submodule, or manifest was
changed. The optional read-only sibling comparison is recorded below.

## Inventory and removal decision

At the chosen tag, the tracked distribution surfaces included one universal
Mach-O executable at
`Binaries/PrefireBinary.artifactbundle/prefire-6.6.0-macos/bin/prefire`, its
`.artifactbundle` metadata, a binary wrapper target, nested executable package,
CLI/MCP/board/render source paths, MCP registry files, two GitHub workflows,
and a Makefile that built and published archives. The tree also included source
templates and snapshot/example fixture manifests.

This fork removes the artifact bundle, all binary-target/wrapper code, the
entire nested `PrefireExecutable` graph, public CLI, MCP registry/package,
board and render code, render-only fixture, and Claude/MCP marketplace metadata.
The root manifest now exposes exactly `Prefire`, `PrefireTestsPlugin`, and
`PrefirePlaybookPlugin`; its package-internal `PrefireGeneratorTool` executable
runs the `prefire` command and has no declared product. The two plugins use
source-built build commands and declare
their deterministic generated Swift outputs. `Scripts/verify-tracked-artifacts.sh`
is the release gate for Mach-O/ELF files, `.artifactbundle`, `.xcframework`,
`.dylib`, and `binaryTarget` declarations.

Retained generated-code templates are source files under `Sources/PrefireCore`.
No generated Swift, cache, artifact bundle, dylib, XCFramework, or bundled CLI
is tracked. The retained shell scripts are the three reviewable release/audit
scripts in `Scripts/`; the Makefile is a source build/test convenience file.

## Dependency SBOM and review

The full machine-readable inventory is
[`SBOM-6.6.0.cdx.json`](SBOM-6.6.0.cdx.json). All source-control locations,
versions, and 40-character revisions below come from the checked-in lockfiles.
There are no branch pins, personal forks, or unknown origins.

| Component | Origin and immutable revision | License | Maintenance / advisory review |
| --- | --- | --- | --- |
| swift-argument-parser 1.2.3 | apple, `8f4d2753f0e4778c76d5f05ad16c74f707390531` | Apache-2.0 | upstream project; OSV clear |
| swift-syntax 600.0.1 | swiftlang, `0687f71944021d616d34d922343dcef086855920` | Apache-2.0 | upstream project; OSV clear |
| PathKit 1.0.1 | kylef, `3bfd2737b700b9a36565a8c94f4ad2b050a5e574` | MIT | community dependency; OSV clear |
| Stencil 0.15.1 | stencilproject, `4f222ac85d673f35df29962fc4c36ccfdaf9da5b` | MIT | upstream project; OSV clear |
| StencilSwiftKit 2.10.1 | SwiftGen, `20e2de5322c83df005939d9d9300fab130b49f97` | MIT | upstream project; OSV clear |
| swift-snapshot-testing 1.19.6 | pointfreeco, `28e5de025e3fd98991791bfbf83023ab3708da03` | MIT | upstream project; OSV clear |
| Komondor 1.1.3 | shibapm, `90b087b1e39069684b1ff4bf915c2aae594f2d60` | MIT | transitive; OSV clear |
| PackageConfig 1.1.3 | shibapm, `58523193c26fb821ed1720dcd8a21009055c7cdb` | MIT | transitive; OSV clear |
| ShellOut 2.3.0 | JohnSundell, `e1577acf2b6e90086d01a6d5e2b8efdaae033568` | MIT | transitive; OSV clear |
| Spectre 0.10.1 | kylef, `26cc5e9ae0947092c7139ef7ba612e34646086c7` | MIT | transitive; OSV clear |
| swift-custom-dump 1.7.3 | pointfreeco, `4fb9e7cbb4b8f5a7354005db39447f570d6b3e19` | MIT | transitive; OSV clear |
| XCTestDynamicOverlay 1.13.1 | pointfreeco, `d9308ad679143c26a30dec52daefe82f54af2b82` | MIT | transitive; OSV clear |
| AccessibilitySnapshot 0.13.1 | cashapp, `7a1d34aea8966c10b5002e17df954a171d6c3149` | MIT | fixture-only; OSV clear |
| ios-snapshot-test-case 8.0.0 | uber, `7b10770333a961be6e5a41c9ce04b8c6d3990126` | MIT | fixture transitive; OSV clear |

The `Example` fixture deliberately remains on SnapshotTesting 1.15.4
(`5b0c434778f2c1a4c9b5ebdb8682b28e84dd69bd`) and SwiftSyntax 510.0.0
(`08a2f0a9a30e0f705f79c9cfaca1f68b71bdc775`); the iOS snapshot fixture uses
SwiftSyntax 604.0.0 (`050f1a346fbbac0ca2cfb15a95274f7bd1cf0ccf`). They are
fixture-only, exact-pinned in their committed locks, and included in the SBOM.

On 2026-11-16, OSV Scanner (image digest
`sha256:a70ffffc2bfd33482953e5d6b64c6fcdb30239717a07b0f0d3ab2859ce3e4cde`)
scanned all four lockfiles (including the example Xcode workspace lock) and
reported **No issues found**. Consequently this
review has no unresolved applicable High/Critical advisory. CI repeats SBOM and
advisory scanning on every change and release. All identified package licenses
are permissive and compatible with the repository's MIT license; no conflict is
known.

## Manual boundary review

- **Process execution:** retained generator and plugins invoke no `Process`,
  shell, package manager, simulator, or network command. The build plugins pass
  argument arrays to the source-built tool; they do not construct a shell line.
- **Filesystem:** the tool receives source/config paths from the host and
  validates output/cache paths against the plugin work directory, resolving
  symlinks before write. It does not search the user home or current working
  directory for configuration.
- **Environment/config:** generator configuration is parsed as data from the
  explicit target path and does not expand environment variables. Redirecting
  paths, arbitrary templates, render/launch controls, and build arguments are
  rejected; module names and plain-text values are validated before code
  generation. The public iOS VoiceOver helper reads `IPHONE_SIMULATOR_ROOT`
  only to locate the platform's `libAccessibility.dylib`; it does not run a
  subprocess or use that value for generator output.
- **Cache/generated Swift:** cache is under the plugin work directory. Templates
  are embedded source, user-derived strings are escaped, and `SwiftParser`
  parses generated output before it is written. Unit tests cover preview-name,
  source/config, template-path, module/shell-argument, and outside-work-dir
  injection attempts.

## Read-only Elklete comparison

`/Users/kanewickman/Developer/elklete` was accessible read-only. Its Swift
package manifests/locks live at `Seed`, `iOS/Core`, and `iOS/ElkleteUI`; none
references Prefire in its manifests or lockfiles at audit time. The comparison
is informational only: no modification, dependency insertion, or submodule was
performed there. If that sibling path is unavailable in a future audit, record
the comparison as unavailable instead of inferring a result.

## Required gates

`make audit` validates pins and checks tracked artifacts. CI then performs a
clean source build, unit tests, plugin integration build, lock validation, SBOM
and High/Critical advisory scan, secret scan, and CodeQL. Release tags are
protected and signature-verified before their source archive and SBOM are
published.
