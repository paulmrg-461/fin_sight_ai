import 'package:fin_sight_ai/features/ai_coach/data/prompts/prompt_templates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PromptTemplates', () {
    test('insight prompt requests a JSON array with a fixed schema', () {
      expect(PromptTemplates.insights, contains('JSON array'));
      expect(PromptTemplates.insights, contains('"type"'));
      expect(PromptTemplates.insights, contains('"content"'));
      expect(PromptTemplates.insights, contains('relatedTransactionId'));
    });

    test('spending analysis prompt requests a JSON object', () {
      expect(PromptTemplates.spendingAnalysis, contains('JSON object'));
      expect(PromptTemplates.spendingAnalysis, contains('spending'));
    });

    test('savings prompt asks for a measurable idea', () {
      expect(PromptTemplates.savingsSuggestions, contains('save money'));
      expect(PromptTemplates.savingsSuggestions, contains('measurable'));
    });

    test('budget optimization references a budgeting rule', () {
      expect(PromptTemplates.budgetOptimization, contains('50/30/20'));
    });

    test('debt payoff proposes avalanche or snowball', () {
      expect(PromptTemplates.debtPayoff, contains('avalanche'));
      expect(PromptTemplates.debtPayoff, contains('snowball'));
      expect(PromptTemplates.debtPayoff, contains('highest-interest'));
    });

    test('every prompt forbids markdown or extra prose', () {
      for (final prompt in [
        PromptTemplates.spendingAnalysis,
        PromptTemplates.savingsSuggestions,
        PromptTemplates.budgetOptimization,
        PromptTemplates.debtPayoff,
      ]) {
        expect(prompt, contains('JSON object'));
      }
    });
  });
}
