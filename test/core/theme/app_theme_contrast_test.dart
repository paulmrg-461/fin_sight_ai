import 'package:fin_sight_ai/core/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

double _ratio(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  for (final (name, theme) in [
    ('light', AppTheme.light),
    ('dark', AppTheme.dark),
  ]) {
    final scheme = theme.colorScheme;

    test('$name theme keeps readable text contrast', () {
      final pairs = <(String, Color, Color)>[
        ('onSurface/surface', scheme.onSurface, scheme.surface),
        ('onSurfaceVariant/surface', scheme.onSurfaceVariant, scheme.surface),
        (
          'onSurfaceVariant/surfaceContainerLow',
          scheme.onSurfaceVariant,
          scheme.surfaceContainerLow,
        ),
        ('onPrimary/primary', scheme.onPrimary, scheme.primary),
        (
          'onPrimaryContainer/primaryContainer',
          scheme.onPrimaryContainer,
          scheme.primaryContainer,
        ),
        ('onError/error', scheme.onError, scheme.error),
        ('error/surface', scheme.error, scheme.surface),
      ];

      for (final (label, foreground, background) in pairs) {
        expect(
          _ratio(foreground, background),
          greaterThanOrEqualTo(4.5),
          reason: '$name $label falls below WCAG AA for normal text.',
        );
      }
    });
  }
}
