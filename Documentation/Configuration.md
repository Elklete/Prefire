# Configuration

Place an optional `.prefire.yml` beside the participating target. The plugins
read only the explicit target/config paths provided by SwiftPM or Xcode.

Supported `test_configuration` options are generation choices such as `target`,
`device`, `required_os`, `snapshot_devices`, `imports`, `testable_imports`,
`preview_default_enabled`, `draw_hierarchy_in_key_window_default_enabled`,
`snapshot_wait_for_idle`, `snapshot_wait_timeout`, `full_page_snapshots`, and
`voiceover_snapshots`. `playbook_configuration` supports
`preview_default_enabled`, `imports`, and `testable_imports`.

The source-only generator rejects `template_file_path`, `test_file_path`,
`test_target_path`, `sources`, `output_dir`, project/workspace/scheme/
destination settings, direct launch/derived-data settings, render settings, and
`xcodebuild_args`. It also requires grouped test output, which gives the plugin
a deterministic declared output file.
