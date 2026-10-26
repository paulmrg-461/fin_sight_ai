import 'package:material_ui/material_ui.dart';

/// Runs non-critical startup work after the first frame.
///
/// The dashboard paints while these tasks run, so a large local ledger never
/// blocks the first render. Tasks run sequentially in the order given.
class StartupLoader {
  const StartupLoader();

  void afterFirstFrame(List<Future<void> Function()> tasks) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (final task in tasks) {
        await task();
      }
    });
  }
}
