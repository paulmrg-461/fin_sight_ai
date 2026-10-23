import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../bloc/ai_coach_bloc.dart';
import '../bloc/ai_coach_event.dart';
import '../bloc/ai_coach_state.dart';
import '../widgets/insight_card.dart';

/// Chat-style coaching surface driven by Groq insights.
class AiCoachScreen extends StatelessWidget {
  const AiCoachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI coach')),
      body: BlocBuilder<AiCoachBloc, AiCoachState>(
        builder: (context, state) {
          return switch (state) {
            AiCoachInitial() || AiCoachEmpty() => _CoachEmpty(
              onStart: () =>
                  context.read<AiCoachBloc>().add(const LoadInsights()),
            ),
            AiCoachLoading() => const _CoachLoading(),
            AiCoachFailure(:final message) => _CoachError(
              message: message,
              onRetry: () =>
                  context.read<AiCoachBloc>().add(const LoadInsights()),
            ),
            AiCoachLoaded(:final insights) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              children: [
                Text(
                  'Your financial coach',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Insights are generated from your recent activity and are '
                  'not financial advice.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                for (final insight in insights) InsightCard(insight: insight),
              ],
            ),
          };
        },
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () =>
                    context.read<AiCoachBloc>().add(const AnalyzeSpending()),
                icon: const Icon(Icons.insights_outlined),
                label: const Text('Analyze spending'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    context.read<AiCoachBloc>().add(const GetSuggestions()),
                icon: const Icon(Icons.savings_outlined),
                label: const Text('Savings tips'),
              ),
              TextButton.icon(
                onPressed: () =>
                    context.read<AiCoachBloc>().add(const LoadInsights()),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoachLoading extends StatelessWidget {
  const _CoachLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Thinking about your finances…'),
        ],
      ),
    );
  }
}

class _CoachEmpty extends StatelessWidget {
  const _CoachEmpty({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text('Your coach is ready', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Ask for spending analysis or personalized savings suggestions.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Get insights'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachError extends StatelessWidget {
  const _CoachError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
