# Installation

Consume this private fork only at a reviewed immutable tag or commit. Add the
`Prefire` library product and either `PrefireTestsPlugin` or
`PrefirePlaybookPlugin` to the relevant SwiftPM/Xcode target.

SwiftPM builds the generator executable from source for each build-tool plugin.
The executable is internal to the package and is not a product to install or
run. Do not use `--disable-sandbox` or Xcode's equivalent: generated Swift and
caches belong in the plugin work directory.
