# Contributing

This is a private source-only fork. Make changes on a reviewed branch, keep the
root `Package.swift` and `Package.resolved` as the sole production build graph,
and run:

```sh
make resolve build test test-plugins audit
```

Do not add binary targets, artifact bundles, executable release assets, plugin
sandbox workarounds, mutable package pins, or a public `prefire` executable
product. Dependency or generator-boundary changes also require updating
`Documentation/Security/AUDIT-6.6.0.md` and the SBOM.
