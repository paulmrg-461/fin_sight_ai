import 'package:fin_sight_ai/core/currency/app_currency.dart';
import 'package:fin_sight_ai/core/currency/currency_usecases.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_bloc.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_state.dart';
import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/l10n/l10n.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/features/receivables/domain/entities/receivable_entity.dart';
import 'package:fin_sight_ai/features/receivables/domain/repositories/receivable_repository.dart';
import 'package:fin_sight_ai/features/receivables/domain/usecases/add_receivable_usecase.dart';
import 'package:fin_sight_ai/features/receivables/domain/usecases/delete_receivable_usecase.dart';
import 'package:fin_sight_ai/features/receivables/domain/usecases/get_receivables_usecase.dart';
import 'package:fin_sight_ai/features/receivables/domain/usecases/make_receivable_payment_usecase.dart';
import 'package:fin_sight_ai/features/receivables/presentation/bloc/receivable_bloc.dart';
import 'package:fin_sight_ai/features/receivables/presentation/screens/receivable_list_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class MockGetCurrency extends Mock implements GetCurrencyUseCase {}

class MockSetCurrency extends Mock implements SetCurrencyUseCase {}

class _FakeReceivableRepository implements ReceivableRepository {
  final List<ReceivableEntity> items = [];
  bool failReads = false;

  @override
  ResultFuture<ReceivableEntity> addReceivable(
    ReceivableEntity receivable,
  ) async {
    items.add(receivable);
    return Right(receivable);
  }

  @override
  ResultFuture<ReceivableEntity> updateReceivable(
    ReceivableEntity receivable,
  ) async {
    final index = items.indexWhere((item) => item.id == receivable.id);
    if (index < 0) {
      return const Left(
        ValidationFailure(
          'Receivable not found.',
          code: 'receivable_not_found',
        ),
      );
    }
    items[index] = receivable;
    return Right(receivable);
  }

  @override
  ResultFuture<ReceivableEntity> makePayment(
    String receivableId,
    ReceivablePayment payment,
  ) async {
    final index = items.indexWhere((item) => item.id == receivableId);
    if (index < 0) {
      return const Left(
        ValidationFailure(
          'Receivable not found.',
          code: 'receivable_not_found',
        ),
      );
    }
    final existing = items[index];
    if (existing.isPaid) {
      return const Left(
        ValidationFailure(
          'This receivable is already paid.',
          code: 'receivable_already_paid',
        ),
      );
    }
    final applied = payment.amount > existing.remainingAmount
        ? existing.remainingAmount
        : payment.amount;
    final remaining = existing.remainingAmount - applied;
    final settled = remaining <= 0.004;
    final updated = existing.copyWith(
      remainingAmount: settled ? 0 : remaining,
      status: settled ? ReceivableStatus.paid : ReceivableStatus.active,
      paymentHistory: [
        ...existing.paymentHistory,
        payment.copyWith(amount: applied),
      ],
    );
    items[index] = updated;
    return Right(updated);
  }

  @override
  ResultFuture<List<ReceivableEntity>> getReceivables() async {
    if (failReads) {
      return const Left(
        CacheFailure('Unable to load receivables.', code: 'cache_read_failed'),
      );
    }
    return Right(List<ReceivableEntity>.unmodifiable(items));
  }

  @override
  ResultFuture<void> deleteReceivable(String id) async {
    items.removeWhere((item) => item.id == id);
    return const Right(null);
  }
}

void main() {
  final dateLent = DateTime.utc(2026, 10, 1);
  final createdAt = DateTime.utc(2026, 10, 1, 9);

  ReceivableEntity buildReceivable({double remaining = 1000}) {
    return ReceivableEntity(
      id: 'receivable-1',
      debtorName: 'Ana',
      totalAmount: 1000,
      remainingAmount: remaining,
      dateLent: dateLent,
      dueDate: DateTime.utc(2026, 12, 1),
      notes: 'Lunch loan',
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  ReceivableBloc buildBloc(ReceivableRepository repository) {
    return ReceivableBloc(
      GetReceivablesUseCase(repository),
      AddReceivableUseCase(repository),
      MakeReceivablePaymentUseCase(repository),
      DeleteReceivableUseCase(repository),
    );
  }

  Widget wrap(ReceivableBloc bloc, {Locale locale = const Locale('en')}) {
    final currencyBloc = CurrencyBloc(MockGetCurrency(), MockSetCurrency())
      ..emit(const CurrencyLoaded(AppCurrency.cop));
    addTearDown(currencyBloc.close);

    return MultiBlocProvider(
      providers: [
        BlocProvider<ReceivableBloc>.value(value: bloc),
        BlocProvider<CurrencyBloc>.value(value: currencyBloc),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ReceivableListScreen(),
      ),
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    ReceivableBloc bloc, {
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(wrap(bloc, locale: locale));
    await tester.pump();
    await tester.pumpAndSettle();
  }

  String money(double amount) => MoneyFormatter.format(amount, AppCurrency.cop);

  testWidgets('shows the empty state when nothing has been lent', (
    tester,
  ) async {
    final repository = _FakeReceivableRepository();
    final bloc = buildBloc(repository);
    addTearDown(bloc.close);

    await pumpScreen(tester, bloc);

    expect(find.text('No money lent yet'), findsOneWidget);
    expect(find.byKey(const ValueKey('receivable-add')), findsOneWidget);
  });

  testWidgets('shows a localized empty state in Spanish', (tester) async {
    final repository = _FakeReceivableRepository();
    final bloc = buildBloc(repository);
    addTearDown(bloc.close);

    await pumpScreen(tester, bloc, locale: const Locale('es'));

    expect(find.text('Aún no has prestado dinero'), findsOneWidget);
    expect(find.text('Añadir dinero prestado'), findsWidgets);
  });

  testWidgets('adds a receivable and shows its balance', (tester) async {
    final repository = _FakeReceivableRepository();
    final bloc = buildBloc(repository);
    addTearDown(bloc.close);

    await pumpScreen(tester, bloc);
    await tester.tap(find.byKey(const ValueKey('receivable-add')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('receivable-debtor-field')),
      'Ana',
    );
    await tester.enterText(
      find.byKey(const ValueKey('receivable-amount-field')),
      '1000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('receivable-notes-field')),
      'Lunch loan',
    );
    final save = find.byKey(const ValueKey('receivable-save'));
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.text('Ana'), findsOneWidget);
    expect(find.text(money(1000)), findsWidgets);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(repository.items.single.notes, 'Lunch loan');
    expect(repository.items.single.remainingAmount, 1000);
  });

  testWidgets('records a partial payment and updates the remaining amount', (
    tester,
  ) async {
    final repository = _FakeReceivableRepository()
      ..items.add(buildReceivable());
    final bloc = buildBloc(repository);
    addTearDown(bloc.close);

    await pumpScreen(tester, bloc);
    await tester.tap(find.widgetWithText(TextButton, 'Add payment'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('receivable-payment-amount-field')),
      '400',
    );
    await tester.tap(find.byKey(const ValueKey('receivable-payment-submit')));
    await tester.pumpAndSettle();

    expect(find.text(money(600)), findsWidgets);
    expect(repository.items.single.remainingAmount, 600);
    expect(repository.items.single.paymentHistory, hasLength(1));
    expect(repository.items.single.paymentHistory.single.amount, 400);
  });

  testWidgets('validates that a payment cannot exceed the remaining amount', (
    tester,
  ) async {
    final repository = _FakeReceivableRepository()
      ..items.add(buildReceivable(remaining: 250));
    final bloc = buildBloc(repository);
    addTearDown(bloc.close);

    await pumpScreen(tester, bloc);
    await tester.tap(find.widgetWithText(TextButton, 'Add payment'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('receivable-payment-amount-field')),
      '300',
    );
    await tester.tap(find.byKey(const ValueKey('receivable-payment-submit')));
    await tester.pumpAndSettle();

    expect(
      find.text('Payment cannot exceed the remaining amount.'),
      findsOneWidget,
    );
    expect(repository.items.single.remainingAmount, 250);
  });

  testWidgets('opens the detail screen with dates and payment history', (
    tester,
  ) async {
    final repository = _FakeReceivableRepository()
      ..items.add(buildReceivable());
    final bloc = buildBloc(repository);
    addTearDown(bloc.close);

    await pumpScreen(tester, bloc);
    await tester.tap(find.text('Ana'));
    await tester.pumpAndSettle();

    expect(find.text('Receivable details'), findsOneWidget);
    expect(find.text('Lunch loan'), findsOneWidget);
    expect(find.text('01/10/2026'), findsOneWidget);
    expect(find.text('No payments received yet.'), findsOneWidget);
    expect(find.byKey(const ValueKey('receivable-detail-pay')), findsOneWidget);
  });

  testWidgets('deletes a receivable after confirmation', (tester) async {
    final repository = _FakeReceivableRepository()
      ..items.add(buildReceivable());
    final bloc = buildBloc(repository);
    addTearDown(bloc.close);

    await pumpScreen(tester, bloc);
    await tester.tap(
      find.byKey(const ValueKey('receivable-delete-receivable-1')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Delete receivable?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('No money lent yet'), findsOneWidget);
    expect(repository.items, isEmpty);
  });

  testWidgets('shows an error state and retries', (tester) async {
    final repository = _FakeReceivableRepository()..failReads = true;
    final bloc = buildBloc(repository);
    addTearDown(bloc.close);

    await pumpScreen(tester, bloc);
    expect(find.text('Unable to load receivables.'), findsOneWidget);

    repository.failReads = false;
    repository.items.add(buildReceivable());
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Ana'), findsOneWidget);
  });
}
