import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/failure_text.dart';
import '../../../../core/l10n/l10n.dart';
import '../bloc/ai_coach_bloc.dart';
import '../bloc/ai_coach_event.dart';
import '../../domain/entities/insight_history_entry.dart';
import '../bloc/ai_coach_state.dart';
import '../widgets/insight_card.dart';

/// Chat-style coaching surface driven by Groq insights.
class AiCoachScreen extends StatelessWidget {
  const AiCoachScreen({super.key});

  String _languageCode(BuildContext context) =>
      Localizations.localeOf(context).languageCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.aiCoach)),
      body: BlocBuilder<AiCoachBloc, AiCoachState>(
        builder: (context, state) {
          return switch (state) {
            AiCoachInitial() || AiCoachEmpty() => _CoachEmpty(
              onStart: () => context.read<AiCoachBloc>().add(
                LoadInsights(languageCode: _languageCode(context)),
              ),
            ),
            AiCoachLoading() => const _CoachLoading(),
            AiCoachFailure(:final message) => _CoachError(
              message: context.failureText(message),
              onRetry: () => context.read<AiCoachBloc>().add(
                LoadInsights(languageCode: _languageCode(context)),
              ),
            ),
            AiCoachLoaded(:final insights, :final fromCache, :final history) =>
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                children: [
                  Text(
                    context.l10n.yourFinancialCoach,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.insightsDisclaimer,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (fromCache) ...[
                    const SizedBox(height: 12),
                    _CachedBanner(),
                  ],
                  const SizedBox(height: 16),
                  for (final insight in insights) InsightCard(insight: insight),
                  if (history.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _HistorySection(history: history),
                  ],
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
                onPressed: () => context.read<AiCoachBloc>().add(
                  AnalyzeSpending(languageCode: _languageCode(context)),
                ),
                icon: const Icon(Icons.insights_outlined),
                label: Text(context.l10n.analyzeSpending),
              ),
              OutlinedButton.icon(
                onPressed: () => context.read<AiCoachBloc>().add(
                  GetSuggestions(languageCode: _languageCode(context)),
                ),
                icon: const Icon(Icons.savings_outlined),
                label: Text(context.l10n.savingsTips),
              ),
              TextButton.icon(
                onPressed: () => context.read<AiCoachBloc>().add(
                  LoadInsights(languageCode: _languageCode(context)),
                ),
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.refresh),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.history});

  final List<InsightHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final localizations = MaterialLocalizations.of(context);

    String labelFor(InsightHistoryKind kind) => switch (kind) {
      InsightHistoryKind.insights => l10n.insightsLabel,
      InsightHistoryKind.analysis => l10n.analyzeSpending,
      InsightHistoryKind.suggestions => l10n.savingsTips,
    };

    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        leading: Icon(Icons.history_rounded, color: theme.colorScheme.primary),
        title: Text(l10n.insightHistory),
        subtitle: Text(
          localizations.formatDecimal(history.length),
          style: theme.textTheme.bodySmall,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          for (final entry in history)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${localizations.formatMediumDate(entry.createdAt)} · '
                    '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(entry.createdAt))} · ${labelFor(entry.kind)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  for (final insight in entry.insights)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        insight.content,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CachedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 18,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.savedInsights,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachLoading extends StatelessWidget {
  const _CoachLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(context.l10n.thinking),
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
            Text(context.l10n.coachReady, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              context.l10n.coachReadyBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.auto_awesome),
              label: Text(context.l10n.getInsights),
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
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
