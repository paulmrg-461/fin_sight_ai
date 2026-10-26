import 'package:fin_sight_ai/core/currency/app_currency.dart';
import 'package:fin_sight_ai/core/currency/currency_usecases.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_bloc.dart';
import 'package:fin_sight_ai/core/currency/presentation/bloc/currency_state.dart';
import 'package:fin_sight_ai/core/l10n/l10n.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/features/categories/domain/entities/category_entity.dart';
import 'package:fin_sight_ai/features/categories/domain/usecases/category_usecases.dart';
import 'package:fin_sight_ai/features/categories/presentation/bloc/category_bloc.dart';
import 'package:fin_sight_ai/features/categories/presentation/bloc/category_state.dart';
import 'package:fin_sight_ai/features/scheduled_payments/domain/entities/scheduled_payment_entity.dart';
import 'package:fin_sight_ai/features/scheduled_payments/domain/entities/committed_cashflow.dart';
import 'package:fin_sight_ai/features/scheduled_payments/domain/usecases/committed_cashflow_usecase.dart';
import 'package:fin_sight_ai/features/scheduled_payments/domain/usecases/scheduled_payment_usecases.dart';
import 'package:fin_sight_ai/features/scheduled_payments/presentation/bloc/scheduled_payment_bloc.dart';
import 'package:fin_sight_ai/features/scheduled_payments/presentation/widgets/scheduled_payment_card.dart';
import 'package:fin_sight_ai/features/scheduled_payments/presentation/widgets/scheduled_payment_form.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fin_sight_ai/features/wallets/domain/usecases/wallet_usecases.dart';
import 'package:fin_sight_ai/features/wallets/presentation/bloc/wallet_bloc.dart';
import 'package:fin_sight_ai/features/wallets/presentation/bloc/wallet_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class MockGetCurrency extends Mock implements GetCurrencyUseCase {}

class MockSetCurrency extends Mock implements SetCurrencyUseCase {}

class MockGetCategories extends Mock implements GetCategoryCatalogUseCase {}

class MockAddCategory extends Mock implements AddCategoryUseCase {}

class MockRenameCategory extends Mock implements RenameCategoryUseCase {}

class MockSetArchived extends Mock implements SetCategoryArchivedUseCase {}

class MockGetBalances extends Mock implements GetWalletBalancesUseCase {}

class MockSetBalance extends Mock implements SetWalletBalanceUseCase {}

class MockTransfer extends Mock implements TransferBetweenWalletsUseCase {}

class MockGetPayments extends Mock implements GetScheduledPaymentsUseCase {}

class MockAddPayment extends Mock implements AddScheduledPaymentUseCase {}

class MockSetActive extends Mock implements SetScheduledPaymentActiveUseCase {}

class MockDeletePayment extends Mock implements DeleteScheduledPaymentUseCase {}

class MockPayNow extends Mock implements PayScheduledPaymentUseCase {}

class MockProcessDue extends Mock
    implements ProcessDueScheduledPaymentsUseCase {}

class MockGetCommitted extends Mock implements GetCommittedCashflowUseCase {}

void main() {
  final createdAt = DateTime.utc(2026, 10, 1);
  final salary = CategoryEntity(
    id: 'salary',
    name: 'Salary',
    createdAt: createdAt,
  );
  final food = CategoryEntity(id: 'food', name: 'Food', createdAt: createdAt);

  final income = ScheduledPaymentEntity(
    id: 'pay-2',
    name: 'Salary',
    amount: 3000,
    type: TransactionType.income,
    category: 'Salary',
    frequency: PaymentFrequency.monthly,
    nextDueDate: DateTime(2026, 10, 25),
    dayOfMonth: 25,
    createdAt: DateTime.utc(2026, 10, 1),
  );

  late CurrencyBloc currencyBloc;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(AppCurrency.cop);
    registerFallbackValue(
      AddScheduledPaymentParams(
        name: 'Salary',
        amount: 1,
        category: 'Salary',
        nextDueDate: DateTime(2026),
      ),
    );
    registerFallbackValue(
      const SetScheduledPaymentActiveParams(id: 'id', isActive: true),
    );
    registerFallbackValue(
      CommittedCashflowParams(from: DateTime(2026, 10, 1), days: 30),
    );
  });

  setUp(() {
    currencyBloc = CurrencyBloc(MockGetCurrency(), MockSetCurrency())
      ..emit(const CurrencyLoaded(AppCurrency.cop));
  });

  tearDown(() async {
    await currencyBloc.close();
  });

  Widget wrap(
    Widget child, {
    List<BlocProvider<dynamic>> providers = const [],
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CurrencyBloc>.value(value: currencyBloc),
        ...providers,
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  Future<void> pumpAndSettle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('renders income cards with a signed primary amount', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        ScheduledPaymentCard(
          payment: income,
          onPayNow: () {},
          onToggleActive: () {},
          onDelete: () {},
        ),
      ),
    );
    await pumpAndSettle(tester);

    final amountFinder = find.text(
      MoneyFormatter.signed(income.amount, AppCurrency.cop),
    );
    expect(amountFinder, findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Salary • Monthly'), findsOneWidget);

    final amountText = tester.widget<Text>(amountFinder);
    final context = tester.element(amountFinder);
    expect(amountText.style?.color, Theme.of(context).colorScheme.primary);
  });

  testWidgets('keeps expense cards unsigned without an income label', (
    tester,
  ) async {
    final expense = income.copyWith(
      id: 'pay-1',
      name: 'Rent',
      amount: 800,
      type: TransactionType.expense,
      category: 'Rent',
    );

    await tester.pumpWidget(
      wrap(
        ScheduledPaymentCard(
          payment: expense,
          onPayNow: () {},
          onToggleActive: () {},
          onDelete: () {},
        ),
      ),
    );
    await pumpAndSettle(tester);

    expect(
      find.text(MoneyFormatter.format(expense.amount, AppCurrency.cop)),
      findsOneWidget,
    );
    expect(find.text('Income'), findsNothing);
    expect(find.text('Rent • Monthly'), findsOneWidget);
  });

  testWidgets('saves a salary schedule and defaults the category', (
    tester,
  ) async {
    final categoryBloc = CategoryBloc(
      MockGetCategories(),
      MockAddCategory(),
      MockRenameCategory(),
      MockSetArchived(),
    )..emit(CategoryLoaded([food, salary]));
    addTearDown(categoryBloc.close);

    final walletBloc = WalletBloc(
      MockGetBalances(),
      MockSetBalance(),
      MockTransfer(),
    )..emit(const WalletLoaded([]));
    addTearDown(walletBloc.close);

    final addPayment = MockAddPayment();
    when(() => addPayment(any())).thenAnswer((_) async => Right(income));
    final processDue = MockProcessDue();
    when(() => processDue(any()))
        .thenAnswer((_) async => const Right(ScheduledPaymentRun()));
    final getPayments = MockGetPayments();
    when(() => getPayments(any())).thenAnswer((_) async => Right([income]));
    final getCommitted = MockGetCommitted();
    when(() => getCommitted(any())).thenAnswer(
      (_) async => Right(
        CommittedCashflow(
          start: DateTime(2026, 10, 1),
          end: DateTime(2026, 10, 31),
          payments: const [],
        ),
      ),
    );
    final scheduledBloc = ScheduledPaymentBloc(
      getPayments,
      addPayment,
      MockSetActive(),
      MockDeletePayment(),
      MockPayNow(),
      processDue,
      getCommitted,
    );
    addTearDown(scheduledBloc.close);

    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: ScheduledPaymentForm()),
                ),
              ),
              child: const Text('Open form'),
            ),
          ),
        ),
        providers: [
          BlocProvider<CategoryBloc>.value(value: categoryBloc),
          BlocProvider<WalletBloc>.value(value: walletBloc),
          BlocProvider<ScheduledPaymentBloc>.value(value: scheduledBloc),
        ],
      ),
    );

    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Monthly salary');
    await tester.enterText(fields.at(1), '3000');
    await tester.tap(find.text('Income'));
    await tester.pump();

    expect(find.text('Salary'), findsWidgets);

    final save = find.widgetWithText(FilledButton, 'Add payment');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    final params =
        verify(() => addPayment(captureAny())).captured.single
            as AddScheduledPaymentParams;
    expect(params.name, 'Monthly salary');
    expect(params.amount, 3000);
    expect(params.type, TransactionType.income);
    expect(params.category, 'Salary');
    expect(find.text('Open form'), findsOneWidget);
  });
}
