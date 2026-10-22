import 'package:injectable/injectable.dart';
import 'package:material_ui/material_ui.dart';

/// Owns the active [ThemeMode] and notifies the app shell when it changes.
@lazySingleton
class ThemeController extends ChangeNotifier {
  ThemeController() : _themeMode = ThemeMode.system;

  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == ThemeMode.dark;

  /// Switches between light and dark. `system` is treated as light on toggle.
  void toggle() => setMode(isDark ? ThemeMode.light : ThemeMode.dark);

  void setMode(ThemeMode mode) {
    if (_themeMode == mode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
  }
}
