import 'package:material_ui/material_ui.dart';

/// Small rounded percentage badge used by progress-oriented cards.
class AppPercentPill extends StatelessWidget {
  const AppPercentPill({super.key, required this.percent, this.color});

  final int percent;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fill = color ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: fill.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fill.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$percent%',
        style: theme.textTheme.labelSmall?.copyWith(
          color: fill,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
