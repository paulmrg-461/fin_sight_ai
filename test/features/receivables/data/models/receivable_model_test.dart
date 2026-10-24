import 'dart:convert';

import 'package:fin_sight_ai/features/receivables/data/models/receivable_model.dart';
import 'package:fin_sight_ai/features/receivables/domain/entities/receivable_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final dateLent = DateTime.utc(2026, 10, 1);
  final dueDate = DateTime.utc(2026, 12, 1);
  final paidAt = DateTime.utc(2026, 10, 15);
  final createdAt = DateTime.utc(2026, 10, 1, 9);
  final updatedAt = DateTime.utc(2026, 10, 2, 9);

  ReceivableModel buildModel() {
    return ReceivableModel(
      id: 'receivable-1',
      debtorName: 'Ana',
      totalAmount: 1000,
      remainingAmount: 600,
      dateLent: dateLent,
      dueDate: dueDate,
      notes: 'Lunch loan',
      status: ReceivableStatus.active,
      paymentHistory: [
        ReceivablePayment(id: 'p-1', amount: 400, paidAt: paidAt, note: 'Cash'),
      ],
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  group('ReceivableModel', () {
    test('maps every field from an entity', () {
      final entity = ReceivableEntity(
        id: 'receivable-9',
        debtorName: 'Luis',
        totalAmount: 500,
        remainingAmount: 250,
        dateLent: dateLent,
        dueDate: dueDate,
        notes: 'Taxi',
        status: ReceivableStatus.active,
        paymentHistory: [
          ReceivablePayment(id: 'p-2', amount: 250, paidAt: paidAt),
        ],
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final model = ReceivableModel.fromEntity(entity);

      expect(model.id, entity.id);
      expect(model.debtorName, entity.debtorName);
      expect(model.totalAmount, entity.totalAmount);
      expect(model.remainingAmount, entity.remainingAmount);
      expect(model.dateLent, entity.dateLent);
      expect(model.dueDate, entity.dueDate);
      expect(model.notes, entity.notes);
      expect(model.status, entity.status);
      expect(model.paymentHistory, entity.paymentHistory);
      expect(model.createdAt, entity.createdAt);
      expect(model.updatedAt, entity.updatedAt);
    });

    test('maps back to an entity', () {
      final model = buildModel();

      final entity = model.toEntity();

      expect(entity, isA<ReceivableEntity>());
      expect(entity.id, model.id);
      expect(entity.paymentHistory, model.paymentHistory);
      expect(entity.status, ReceivableStatus.active);
    });

    test('serializes ISO dates and status by name', () {
      final json = buildModel().toJson();

      expect(json['dateLent'], '2026-10-01T00:00:00.000Z');
      expect(json['dueDate'], '2026-12-01T00:00:00.000Z');
      expect(json['createdAt'], '2026-10-01T09:00:00.000Z');
      expect(json['updatedAt'], '2026-10-02T09:00:00.000Z');
      expect(json['status'], 'active');
      final history = json['paymentHistory'] as List<dynamic>;
      expect(
        (history.single as Map<String, dynamic>)['paidAt'],
        '2026-10-15T00:00:00.000Z',
      );
      expect((history.single as Map<String, dynamic>)['note'], 'Cash');
    });

    test('round-trips through real JSON encoding', () {
      final model = buildModel();

      final decoded = jsonDecode(jsonEncode(model.toJson()));
      final restored = ReceivableModel.fromJson(
        decoded as Map<String, dynamic>,
      );

      expect(restored.toEntity(), model.toEntity());
    });

    test('round-trips without an optional due date', () {
      final model = ReceivableModel.fromEntity(
        buildModel().copyWith(dueDate: null),
      );

      final restored = ReceivableModel.fromJson(model.toJson());

      expect(restored.dueDate, isNull);
    });

    test(
      'defaults legacy fields for records written before the audit data',
      () {
        final legacyJson = <String, dynamic>{
          'id': 'receivable-1',
          'debtorName': 'Ana',
          'totalAmount': 1000,
          'remainingAmount': 600,
          'dateLent': '2026-10-01T00:00:00.000Z',
        };

        final model = ReceivableModel.fromJson(legacyJson);

        expect(model.notes, isEmpty);
        expect(model.dueDate, isNull);
        expect(model.status, ReceivableStatus.active);
        expect(model.paymentHistory, isEmpty);
        expect(model.createdAt, dateLent);
        expect(model.updatedAt, dateLent);
      },
    );

    test('derives a paid legacy status from the remaining amount', () {
      final legacyJson = <String, dynamic>{
        'id': 'receivable-1',
        'debtorName': 'Ana',
        'totalAmount': 1000,
        'remainingAmount': 0,
        'dateLent': '2026-10-01T00:00:00.000Z',
      };

      expect(
        ReceivableModel.fromJson(legacyJson).status,
        ReceivableStatus.paid,
      );
    });

    test('tolerates a missing payment history list', () {
      final json = buildModel().toJson()..remove('paymentHistory');

      expect(ReceivableModel.fromJson(json).paymentHistory, isEmpty);
    });

    test('throws FormatException for an invalid id', () {
      expect(
        () => ReceivableModel.fromJson(<String, dynamic>{'id': ''}),
        throwsFormatException,
      );
    });

    test('throws FormatException for an empty debtor name', () {
      final json = buildModel().toJson()..['debtorName'] = '  ';

      expect(() => ReceivableModel.fromJson(json), throwsFormatException);
    });

    test('throws FormatException for invalid amounts', () {
      final json = buildModel().toJson()..['totalAmount'] = 'ten';

      expect(() => ReceivableModel.fromJson(json), throwsFormatException);
    });

    test('throws FormatException for an unknown status', () {
      final json = buildModel().toJson()..['status'] = 'archived';

      expect(() => ReceivableModel.fromJson(json), throwsFormatException);
    });

    test('throws FormatException for a malformed date lent', () {
      final json = buildModel().toJson()..['dateLent'] = 'not-a-date';

      expect(() => ReceivableModel.fromJson(json), throwsFormatException);
    });

    test('throws FormatException for a malformed due date', () {
      final json = buildModel().toJson()..['dueDate'] = 'not-a-date';

      expect(() => ReceivableModel.fromJson(json), throwsFormatException);
    });

    test('throws FormatException for an invalid payment entry', () {
      final json = buildModel().toJson()
        ..['paymentHistory'] = [
          <String, dynamic>{'id': 'p-1'},
        ];

      expect(() => ReceivableModel.fromJson(json), throwsFormatException);
    });

    test('throws FormatException when history is not a list', () {
      final json = buildModel().toJson()..['paymentHistory'] = 'history';

      expect(() => ReceivableModel.fromJson(json), throwsFormatException);
    });
  });
}
