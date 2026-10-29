import 'package:package_info_plus/package_info_plus.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/link_launcher.dart';
import '../../../../core/widgets/app_layout.dart';
import '../widgets/social_links.dart';

/// "About the developer" page: brand, bio, links, and legal notice.
class DeveloperInfoScreen extends StatelessWidget {
  const DeveloperInfoScreen({
    super.key,
    this.launcher = const UrlLinkLauncher(),
    this.versionLoader,
  });

  final LinkLauncher launcher;
  final Future<String> Function()? versionLoader;

  static const String website = 'https://devpaul.pro';

  Future<String> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.buildNumber.isEmpty
          ? info.version
          : '${info.version}+${info.buildNumber}';
    } catch (_) {
      return '1.0.0';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.developerTitle)),
      body: AppContent(
        maxWidth: 760,
        padding: EdgeInsets.zero,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            BrandGradientCard(
              child: Column(
                children: [
                  Container(
                    width: 108,
                    height: 108,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.45),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 22,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        'assets/branding/devpaul_logo.jpeg',
                        fit: BoxFit.cover,
                        semanticLabel: 'DevPaul',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'DevPaul',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.developerRole,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FutureBuilder<String>(
                    future: (versionLoader ?? _loadVersion)(),
                    builder: (context, snapshot) {
                      final version = snapshot.data ?? '…';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          l10n.developerVersion(version),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.person_outline_rounded,
              title: l10n.developerAbout,
              child: Text(
                l10n.developerBio,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.alternate_email_rounded,
              title: l10n.developerFindMe,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SocialLinks(launcher: launcher),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: () => launcher.open(website),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: Text(l10n.developerVisitSite),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                l10n.developerRights(DateTime.now().year),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    size: 19,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
