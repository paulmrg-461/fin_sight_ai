import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';

/// FinSight brand mark, with an optional wordmark.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 32,
    this.showWordmark = false,
    this.wordmarkStyle,
  });

  final double size;
  final bool showWordmark;
  final TextStyle? wordmarkStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mark = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/branding/logo_mark_512.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: context.l10n.appName,
      ),
    );

    if (!showWordmark) {
      return mark;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: size * 0.3),
        Flexible(
          child: Text(
            context.l10n.appName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                wordmarkStyle ??
                theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
          ),
        ),
      ],
    );
  }
}
