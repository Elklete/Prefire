# Prefire

Prefire is a private, source-built Swift package for generating SwiftUI preview
playbooks and snapshot tests. This fork's v1 distribution contains only:

- `Prefire` — the public Swift library;
- `PrefireTestsPlugin` — generated snapshot-test sources; and
- `PrefirePlaybookPlugin` — generated preview-model sources.

There is no published CLI, binary target, artifact bundle, MCP server, render
mode, or board feature. Both plugins compile their internal `prefire` generator
from this repository's root package graph as a SwiftPM build-tool dependency.
Generated files and generator caches are confined to the SwiftPM/Xcode plugin
work directory; do not disable plugin sandboxing.

## Requirements

The supported baseline is Xcode 26.5 / Swift 6.3.2. The dependency graph is
locked in the root `Package.resolved`; resolve it with `swift package resolve`.

## Use

Add the `Prefire` package at a reviewed immutable fork tag or commit, then add
the appropriate plugin to the app or test target. The plugin discovers source
files supplied by SwiftPM/Xcode and writes generated Swift only to its work
directory. Optional `.prefire.yml` settings are limited to generation options;
template paths, output paths, source redirection, render settings, and build
launch settings are deliberately rejected.

For development:

```sh
make resolve
make build
make test
make test-plugins
make audit
```

See [the security record](SECURITY.md) and
[configuration reference](Documentation/Configuration.md).
