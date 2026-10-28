import 'package:material_ui/material_ui.dart';

/// Rounded, animated progress bar with a subtle brand gradient.
///
/// Replaces the default `LinearProgressIndicator` across the app so every
/// module shares the same track height, cap radius, and fill animation.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.color,
    this.semanticsLabel,
    this.semanticsValue,
  });

  final double value;
  final double height;
  final Color? color;
  final String? semanticsLabel;
  final String? semanticsValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fill = color ?? theme.colorScheme.primary;
    final target = value.isFinite ? value.clamp(0.0, 1.0) : 0.0;

    Widget bar = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, animated, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              height: height,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(height),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: animated,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(height),
                    gradient: LinearGradient(
                      colors: [fill.withValues(alpha: 0.72), fill],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: fill.withValues(alpha: 0.28),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (semanticsLabel == null) {
      return bar;
    }

    return Semantics(
      label: semanticsLabel,
      value: semanticsValue,
      child: ExcludeSemantics(child: bar),
    );
  }
}
