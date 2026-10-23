import 'package:bloc_test/bloc_test.dart';
import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/features/wallets/domain/entities/wallet_entity.dart';
import 'package:fin_sight_ai/features/wallets/domain/usecases/wallet_usecases.dart';
import 'package:fin_sight_ai/features/wallets/presentation/bloc/wallet_bloc.dart';
import 'package:fin_sight_ai/features/wallets/presentation/bloc/wallet_event.dart';
import 'package:fin_sight_ai/features/wallets/presentation/bloc/wallet_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetBalances extends Mock implements GetWalletBalancesUseCase {}

class MockSetBalance extends Mock implements SetWalletBalanceUseCase {}

class MockTransfer extends Mock implements TransferBetweenWalletsUseCase {}

void main() {
  late MockGetBalances getBalances;
  late MockSetBalance setBalance;
  late MockTransfer transfer;

  const bank = WalletEntity(
    id: 'bank',
    name: 'Bank',
    type: WalletType.bank,
    openingBalance: 0,
  );
  final balances = [WalletBalance(wallet: bank, balance: 100)];

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      const SetWalletBalanceParams(walletId: 'bank', target: 1),
    );
    registerFallbackValue(
      TransferBetweenWalletsParams(
        fromWalletId: 'bank',
        toWalletId: 'cash',
        amount: 1,
        date: DateTime(2026),
      ),
    );
  });

  setUp(() {
    getBalances = MockGetBalances();
    setBalance = MockSetBalance();
    transfer = MockTransfer();
    when(() => getBalances(any())).thenAnswer((_) async => Right(balances));
  });

  WalletBloc buildBloc() => WalletBloc(getBalances, setBalance, transfer);

  blocTest<WalletBloc, WalletState>(
    'loads balances',
    build: buildBloc,
    act: (bloc) => bloc.add(const LoadWallets()),
    expect: () => [const WalletLoading(), WalletLoaded(balances)],
  );

  blocTest<WalletBloc, WalletState>(
    'sets a balance and reloads',
    setUp: () {
      when(() => setBalance(any()))
          .thenAnswer((_) async => Right(balances.first));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const SetBalance(walletId: 'bank', target: 100)),
    expect: () => [const WalletLoading(), WalletLoaded(balances)],
  );

  blocTest<WalletBloc, WalletState>(
    'transfers and reloads',
    setUp: () {
      when(() => transfer(any())).thenAnswer(
        (_) async => Right(
          WalletTransferEntity(
            id: 't-1',
            fromWalletId: 'bank',
            toWalletId: 'cash',
            amount: 10,
            date: DateTime(2026),
          ),
        ),
      );
    },
    build: buildBloc,
    act: (bloc) => bloc.add(
      const TransferMoney(fromWalletId: 'bank', toWalletId: 'cash', amount: 10),
    ),
    expect: () => [const WalletLoading(), WalletLoaded(balances)],
  );

  blocTest<WalletBloc, WalletState>(
    'surfaces failures',
    setUp: () {
      when(() => getBalances(any()))
          .thenAnswer((_) async => const Left(CacheFailure('Store down.')));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const LoadWallets()),
    expect: () => [const WalletLoading(), const WalletFailure('Store down.')],
  );
}
