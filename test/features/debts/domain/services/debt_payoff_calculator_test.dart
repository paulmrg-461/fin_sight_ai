import 'package:fin_sight_ai/features/debts/domain/services/debt_payoff_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final from = DateTime.utc(2026, 1, 15, 10);

  group('DebtPayoffCalculator', () {
    test('returns the current date when the balance is zero', () {
      final payoff = DebtPayoffCalculator.calculatePayoffDate(
        remainingAmount: 0,
        annualInterestRate: 24,
        monthlyPayment: 100,
        from: from,
      );

      expect(payoff, from);
    });

    test('treats a negative balance as already settled', () {
      final payoff = DebtPayoffCalculator.calculatePayoffDate(
        remainingAmount: -50,
        annualInterestRate: 24,
        monthlyPayment: 100,
        from: from,
      );

      expect(payoff, from);
    });

    test('returns null when the payment is zero or negative', () {
      expect(
        DebtPayoffCalculator.calculatePayoffDate(
          remainingAmount: 1000,
          annualInterestRate: 12,
          monthlyPayment: 0,
          from: from,
        ),
        isNull,
      );
      expect(
        DebtPayoffCalculator.calculatePayoffDate(
          remainingAmount: 1000,
          annualInterestRate: 12,
          monthlyPayment: -10,
          from: from,
        ),
        isNull,
      );
    });

    test('returns null when the payment does not cover monthly interest', () {
      final payoff = DebtPayoffCalculator.calculatePayoffDate(
        remainingAmount: 1000,
        annualInterestRate: 24,
        monthlyPayment: 15,
        from: from,
      );

      expect(payoff, isNull);
    });

    test('handles a zero-interest debt as simple division', () {
      final payoff = DebtPayoffCalculator.calculatePayoffDate(
        remainingAmount: 1000,
        annualInterestRate: 0,
        monthlyPayment: 100,
        from: from,
      );

      expect(payoff, DateTime.utc(2026, 11, 15, 10));
    });

    test('compounds monthly interest', () {
      final payoff = DebtPayoffCalculator.calculatePayoffDate(
        remainingAmount: 300,
        annualInterestRate: 12,
        monthlyPayment: 100,
        from: from,
      );

      // 1% monthly interest: 300 -> 203 -> 105.03 -> 6.08 -> paid in month 4.
      expect(payoff, DateTime.utc(2026, 5, 15, 10));
    });

    test('rolls over year boundaries', () {
      final december = DateTime.utc(2026, 12, 15, 10);
      final payoff = DebtPayoffCalculator.calculatePayoffDate(
        remainingAmount: 300,
        annualInterestRate: 12,
        monthlyPayment: 100,
        from: december,
      );

      expect(payoff, DateTime.utc(2027, 4, 15, 10));
    });

    test('rejects a negative interest rate', () {
      final payoff = DebtPayoffCalculator.calculatePayoffDate(
        remainingAmount: 1000,
        annualInterestRate: -5,
        monthlyPayment: 100,
        from: from,
      );

      expect(payoff, isNull);
    });

    test('handles a non-finite payment', () {
      final payoff = DebtPayoffCalculator.calculatePayoffDate(
        remainingAmount: 1000,
        annualInterestRate: 12,
        monthlyPayment: double.nan,
        from: from,
      );

      expect(payoff, isNull);
    });
  });
}
