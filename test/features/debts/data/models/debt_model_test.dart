import 'dart:convert';

import 'package:fin_sight_ai/features/debts/data/models/debt_model.dart';
import 'package:fin_sight_ai/features/debts/domain/entities/debt_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final dueDate = DateTime.utc(2026, 12, 1);
  final paidAt = DateTime.utc(2026, 10, 1);

  DebtModel buildModel() {
    return DebtModel(
      id: 'debt-1',
      creditorName: 'Bank',
      totalAmount: 1000,
      remainingAmount: 600,
      interestRate: 12.5,
      minimumPayment: 100,
      dueDate: dueDate,
      paymentHistory: [PaymentRecord(id: 'p-1', amount: 100, paidAt: paidAt)],
    );
  }

  group('DebtModel', () {
    test('maps every field from an entity', () {
      final entity = DebtEntity(
        id: 'debt-9',
        creditorName: 'Card',
        totalAmount: 500,
        remainingAmount: 250,
        interestRate: 24,
        minimumPayment: 50,
        dueDate: dueDate,
        status: DebtStatus.active,
        paymentHistory: [PaymentRecord(id: 'p-2', amount: 250, paidAt: paidAt)],
      );

      final model = DebtModel.fromEntity(entity);

      expect(model.id, entity.id);
      expect(model.creditorName, entity.creditorName);
      expect(model.totalAmount, entity.totalAmount);
      expect(model.remainingAmount, entity.remainingAmount);
      expect(model.interestRate, entity.interestRate);
      expect(model.minimumPayment, entity.minimumPayment);
      expect(model.dueDate, entity.dueDate);
      expect(model.status, entity.status);
      expect(model.paymentHistory, entity.paymentHistory);
    });

    test('maps back to an entity', () {
      final model = buildModel();

      final entity = model.toEntity();

      expect(entity, isA<DebtEntity>());
      expect(entity.id, model.id);
      expect(entity.paymentHistory, model.paymentHistory);
      expect(entity.status, DebtStatus.active);
    });

    test('serializes ISO dates and status by name', () {
      final json = buildModel().toJson();

      expect(json['dueDate'], '2026-12-01T00:00:00.000Z');
      expect(json['status'], 'active');
      final history = json['paymentHistory'] as List<dynamic>;
      expect(
        (history.single as Map<String, dynamic>)['paidAt'],
        '2026-10-01T00:00:00.000Z',
      );
    });

    test('round-trips through real JSON encoding', () {
      final model = buildModel();

      final decoded = jsonDecode(jsonEncode(model.toJson()));
      final restored = DebtModel.fromJson(decoded as Map<String, dynamic>);

      expect(restored.toEntity(), model.toEntity());
    });

    test('defaults a missing payment history to an empty list', () {
      final json = buildModel().toJson()..remove('paymentHistory');

      expect(DebtModel.fromJson(json).paymentHistory, isEmpty);
    });

    test('round-trips a soft-delete tombstone', () {
      final model = DebtModel.fromEntity(
        buildModel().copyWith(deletedAt: dueDate),
      );

      final restored = DebtModel.fromJson(model.toJson());

      expect(restored.deletedAt, dueDate);
      expect(restored.isDeleted, isTrue);
    });

    test('throws FormatException for an invalid id', () {
      expect(
        () => DebtModel.fromJson(<String, dynamic>{'id': ''}),
        throwsFormatException,
      );
    });

    test('throws FormatException for invalid amounts', () {
      expect(
        () => DebtModel.fromJson(<String, dynamic>{
          'id': 'debt-1',
          'creditorName': 'Bank',
          'totalAmount': 'ten',
        }),
        throwsFormatException,
      );
    });

    test('throws FormatException for an unknown status', () {
      final json = buildModel().toJson()..['status'] = 'archived';

      expect(() => DebtModel.fromJson(json), throwsFormatException);
    });

    test('throws FormatException for an invalid payment entry', () {
      final json = buildModel().toJson()
        ..['paymentHistory'] = [
          <String, dynamic>{'id': 'p-1'},
        ];

      expect(() => DebtModel.fromJson(json), throwsFormatException);
    });

    test('throws FormatException for a malformed due date', () {
      final json = buildModel().toJson()..['dueDate'] = 'not-a-date';

      expect(() => DebtModel.fromJson(json), throwsFormatException);
    });
  });
}
