import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/theme_controller.dart';

/// Home screen with shortcuts to every feature.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Scaffold(
          appBar: AppBar(
            title: const Text('FinSight AI'),
            actions: [
              IconButton(
                onPressed: themeController.toggle,
                tooltip: isDark
                    ? 'Switch to light mode'
                    : 'Switch to dark mode',
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Your money, clearly.',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Offline-first tracking with AI-powered insights.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              _DashboardTile(
                icon: Icons.swap_vert,
                title: 'Transactions',
                subtitle: 'Track income and expenses',
                onTap: () => context.goNamed(AppRoutes.transactionsName),
              ),
              _DashboardTile(
                icon: Icons.account_balance_outlined,
                title: 'Debts',
                subtitle: 'Track balances and payoff dates',
                onTap: () => context.goNamed(AppRoutes.debtsName),
              ),
              _DashboardTile(
                icon: Icons.document_scanner_outlined,
                title: 'Scan receipts',
                subtitle: 'Capture expenses from a photo',
                onTap: () => context.goNamed(AppRoutes.ocrName),
              ),
              _DashboardTile(
                icon: Icons.auto_awesome_outlined,
                title: 'AI coach',
                subtitle: 'Get personalized budget guidance',
                onTap: () => context.goNamed(AppRoutes.aiCoachName),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
