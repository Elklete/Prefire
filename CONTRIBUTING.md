# Contributing to Prefire

Contributions are welcome! To propose a change:

1. Fork the repository
2. Create a feature branch
3. Submit a Pull Request

## Development setup

Run `make` to list the development tasks. The ones you need most:

```bash
make build      # Build Prefire for the iOS Simulator
make package-validate # Check the trimmed source graph and bundled generator
make test       # Run the Prefire macOS and generator tests
make integration # Build the bundled-generator plugin integration fixture
make test-ios   # Run the Prefire library tests on an iPhone simulator
make cli        # Build the source-backed prefire executable
make binary     # Rebuild and validate the universal bundled macOS generator
```

CI runs the same commands, see [.github/workflows/swift.yml](.github/workflows/swift.yml).

The [Example](Example) project shows Prefire in an Xcode app with a snapshot test target.

## Internal architecture

- `PrefireCore` — AST + preview parsing, caching, logic
- `PrefireGenerator` — handles stencil templating + snapshot generation
- `PrefireCacheManager` — unifies caching for `Types` and `Previews`
- `PrefireTestsPlugin` / `PrefirePlaybookPlugin` — SPM/Xcode integrations
- `PrefireGeneratorTool` — source-built CLI target, exposed as the `prefire` executable; it also builds `PrefireBinary.artifactbundle`

Generated code comes from [Stencil templates](Documentation/Templates.md).
`PrefireTemplateSupport` supplies the pinned PathKit, Stencil and
StencilSwiftKit production sources used by the generator. It intentionally has
no external package dependencies; see its `UPSTREAM.md` before updating those
vendored sources. The bundled macOS generator is rebuilt from this root source
graph with `make binary`.
