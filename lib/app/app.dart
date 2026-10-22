import 'package:material_ui/material_ui.dart';

/// Root widget and app-level theme. Feature UI lives inside each feature's
/// `presentation` layer.
class FinSightApp extends StatelessWidget {
  const FinSightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinSight AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006C4C)),
        useMaterial3: true,
      ),
      home: const _FoundationHome(),
    );
  }
}

class _FoundationHome extends StatelessWidget {
  const _FoundationHome();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('FinSight AI')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 56,
              color: theme.colorScheme.primary,
              semanticLabel: 'FinSight AI wallet',
            ),
            const SizedBox(height: 16),
            Text('Foundation ready', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Clean Architecture, functional error handling, and offline-first '
              'persistence are wired. The transactions feature slice is live.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
