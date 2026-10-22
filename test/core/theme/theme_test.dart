import 'package:fin_sight_ai/core/theme/app_colors.dart';
import 'package:fin_sight_ai/core/theme/app_theme.dart';
import 'package:fin_sight_ai/core/theme/theme_controller.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    test('light theme uses the emerald primary and light canvas', () {
      final theme = AppTheme.light;

      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, AppColors.emerald);
      expect(theme.scaffoldBackgroundColor, AppColors.lightBackground);
    });

    test('dark theme uses the emerald primary and #0F172A canvas', () {
      final theme = AppTheme.dark;

      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, AppColors.emerald);
      expect(theme.scaffoldBackgroundColor, const Color(0xFF0F172A));
    });

    test('themes use Material 3', () {
      expect(AppTheme.light.useMaterial3, isTrue);
      expect(AppTheme.dark.useMaterial3, isTrue);
    });
  });

  group('ThemeController', () {
    test('starts in system mode', () {
      final controller = ThemeController();

      expect(controller.themeMode, ThemeMode.system);
      expect(controller.isDark, isFalse);
    });

    test('toggle switches from system to dark and notifies listeners', () {
      final controller = ThemeController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.toggle();

      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.isDark, isTrue);
      expect(notifications, 1);
      controller.dispose();
    });

    test('toggle switches dark back to light', () {
      final controller = ThemeController()..setMode(ThemeMode.dark);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.toggle();

      expect(controller.themeMode, ThemeMode.light);
      expect(notifications, 1);
      controller.dispose();
    });

    test('setting the current mode does not notify', () {
      final controller = ThemeController()..setMode(ThemeMode.dark);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.setMode(ThemeMode.dark);

      expect(notifications, 0);
      controller.dispose();
    });
  });
}
