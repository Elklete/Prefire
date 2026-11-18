# Contributing to Prefire

Contributions are welcome! To propose a change:

1. Fork the repository
2. Create a feature branch
3. Submit a Pull Request

## Development setup

Run `make` to list the development tasks. The ones you need most:

```bash
make build      # Build Prefire for the iOS Simulator
make package-validate # Check the pinned source graph and reject generator artifacts
make test       # Run the Prefire macOS and generator tests
make integration # Build the source-backed plugin integration fixture
make test-ios   # Run the Prefire library tests on an iPhone simulator
make cli        # Build the source-backed prefire executable
```

CI runs the same commands, see [.github/workflows/swift.yml](.github/workflows/swift.yml).

The [Example](Example) project shows Prefire in an Xcode app with a snapshot test target.

## Internal architecture

- `PrefireCore` — AST + preview parsing, caching, logic
- `PrefireGenerator` — handles stencil templating + snapshot generation
- `PrefireCacheManager` — unifies caching for `Types` and `Previews`
- `PrefireTestsPlugin` / `PrefirePlaybookPlugin` — SPM/Xcode integrations
- `PrefireGeneratorTool` — source-built CLI target, exposed as the `prefire` executable

Generated code comes from [Stencil templates](Documentation/Templates.md).
