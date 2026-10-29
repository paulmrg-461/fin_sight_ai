import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/link_launcher.dart';

/// Brand links for the developer profile.
class SocialLinks extends StatelessWidget {
  const SocialLinks({super.key, this.launcher = const UrlLinkLauncher()});

  final LinkLauncher launcher;

  static const List<({String label, String url, String? asset, IconData? icon})>
  links = [
    (
      label: 'GitHub',
      url: 'https://github.com/paulmrg-461',
      asset: 'assets/social/github.svg',
      icon: null,
    ),
    (
      label: 'LinkedIn',
      url: 'https://www.linkedin.com/in/paul-realpe-631b17a6/',
      asset: 'assets/social/linkedin.svg',
      icon: null,
    ),
    (
      label: 'Facebook',
      url: 'https://www.facebook.com/devpaul.co/',
      asset: 'assets/social/facebook1.svg',
      icon: null,
    ),
    (
      label: 'X',
      url: 'https://twitter.com/devpaul_co',
      asset: 'assets/social/twitter.svg',
      icon: null,
    ),
    (
      label: 'Instagram',
      url: 'https://www.instagram.com/devpaul_co/',
      asset: 'assets/social/instagram1.svg',
      icon: null,
    ),
    (
      label: 'devpaul.pro',
      url: 'https://devpaul.pro',
      asset: null,
      icon: Icons.language_rounded,
    ),
  ];

  Future<void> _open(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final failure = context.l10n.developerLinkFailed;
    final opened = await launcher.open(url);
    if (!opened) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(failure)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final link in links)
          Tooltip(
            message: link.label,
            child: Semantics(
              button: true,
              label: link.label,
              child: InkWell(
                onTap: () => _open(context, link.url),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Center(
                    child: link.asset != null
                        ? SvgPicture.asset(link.asset!, width: 34, height: 34)
                        : Icon(
                            link.icon,
                            size: 26,
                            color: theme.colorScheme.primary,
                          ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
