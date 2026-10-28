import 'package:material_ui/material_ui.dart';

import '../../../../app/branding/app_logo.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinish});

  final Future<void> Function() onFinish;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == 2) {
      widget.onFinish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final pages = [
      _Page(
        icon: Icons.account_balance_wallet_outlined,
        title: l10n.onboardingWelcomeTitle,
        body: l10n.onboardingWelcomeBody,
      ),
      _Page(
        icon: Icons.lock_outline_rounded,
        title: l10n.onboardingOfflineTitle,
        body: l10n.onboardingOfflineBody,
      ),
      _Page(
        icon: Icons.rocket_launch_outlined,
        title: l10n.onboardingStartTitle,
        body: l10n.onboardingStartBody,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onFinish,
                child: Text(l10n.onboardingSkip),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) => setState(() => _page = index),
                children: [
                  for (final page in pages)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AppLogo(size: 64, showWordmark: false),
                          const SizedBox(height: 32),
                          Icon(
                            page.icon,
                            size: 44,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            page.title,
                            style: theme.textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            page.body,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < pages.length; index++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _page ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _page
                          ? AppColors.emerald
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(
                    _page == 2 ? l10n.onboardingFinish : l10n.onboardingNext,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page {
  const _Page({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;
}
