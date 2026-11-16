import Prefire
import SwiftUI

/// Intentionally small consumer source. The integration target proves that both plugins are
/// built from the root-package `prefire` executable and compile their generated output.
public enum Fixture {
    public static let name = "plugin-integration"
}

// The tests plugin is configured to exclude macros in this fixture, which keeps
// the integration check free of a committed image baseline. The playbook plugin
// still generates and compiles its source from this declaration.
#Preview("Plugin fixture") {
    Text("Plugin fixture")
}
