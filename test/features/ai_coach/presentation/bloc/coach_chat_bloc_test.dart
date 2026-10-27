import 'package:bloc_test/bloc_test.dart';
import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/entities/coach_message.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/repositories/coach_chat_store.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/usecases/ask_coach_usecase.dart';
import 'package:fin_sight_ai/features/ai_coach/presentation/bloc/coach_chat_bloc.dart';
import 'package:fin_sight_ai/features/ai_coach/presentation/bloc/coach_chat_event.dart';
import 'package:fin_sight_ai/features/ai_coach/presentation/bloc/coach_chat_state.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/get_debts_usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAskCoach extends Mock implements AskCoachUseCase {}

class MockGetTransactions extends Mock implements GetTransactionsUseCase {}

class MockGetDebts extends Mock implements GetDebtsUseCase {}

class InMemoryChatStore implements CoachChatStore {
  final List<CoachMessage> messages = [];

  @override
  Future<List<CoachMessage>> read() async =>
      List<CoachMessage>.unmodifiable(messages);

  @override
  Future<void> append(CoachMessage message) async => messages.add(message);

  @override
  Future<void> clear() async => messages.clear();
}

void main() {
  late MockAskCoach askCoach;
  late MockGetTransactions getTransactions;
  late MockGetDebts getDebts;
  late InMemoryChatStore store;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const AskCoachParams(question: 'q', context: 'c'));
  });

  setUp(() {
    askCoach = MockAskCoach();
    getTransactions = MockGetTransactions();
    getDebts = MockGetDebts();
    store = InMemoryChatStore();
    when(() => getTransactions(any())).thenAnswer((_) async => const Right([]));
    when(() => getDebts(any())).thenAnswer((_) async => const Right([]));
  });

  CoachChatBloc buildBloc() =>
      CoachChatBloc(askCoach, getTransactions, getDebts, store);

  group('CoachChatBloc', () {
    test('initial state is CoachChatInitial', () {
      expect(buildBloc().state, const CoachChatInitial());
    });

    blocTest<CoachChatBloc, CoachChatState>(
      'loads the saved conversation',
      setUp: () {
        store.messages.add(
          CoachMessage(
            id: 'm-1',
            role: CoachRole.user,
            content: 'Hi',
            createdAt: DateTime.utc(2026, 10, 27),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadCoachChat()),
      expect: () => [
        const CoachChatLoading(),
        isA<CoachChatLoaded>().having(
          (state) => state.messages,
          'messages',
          hasLength(1),
        ),
      ],
    );

    blocTest<CoachChatBloc, CoachChatState>(
      'sends a question and stores both turns',
      setUp: () {
        when(() => askCoach(any()))
            .thenAnswer((_) async => const Right('Pay the card first.'));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const SendCoachMessage(text: 'What first?', languageCode: 'en'),
      ),
      expect: () => [
        isA<CoachChatLoaded>()
            .having((state) => state.messages, 'messages', hasLength(1))
            .having((state) => state.sending, 'sending', isTrue),
        isA<CoachChatLoaded>()
            .having((state) => state.messages, 'messages', hasLength(2))
            .having((state) => state.sending, 'sending', isFalse),
      ],
      verify: (_) {
        expect(store.messages, hasLength(2));
        expect(store.messages.first.role, CoachRole.user);
        expect(store.messages.last.content, 'Pay the card first.');
        final params =
            verify(() => askCoach(captureAny())).captured.single
                as AskCoachParams;
        expect(params.question, 'What first?');
        expect(params.context, contains('Write the response in English.'));
      },
    );

    blocTest<CoachChatBloc, CoachChatState>(
      'keeps the question and reports send failures',
      setUp: () {
        when(() => askCoach(any()))
            .thenAnswer((_) async => const Left(ServerFailure('Offline.')));
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const SendCoachMessage(text: 'Help', languageCode: 'en')),
      expect: () => [
        isA<CoachChatLoaded>().having(
          (state) => state.messages,
          'messages',
          hasLength(1),
        ),
        isA<CoachChatLoaded>()
            .having((state) => state.messages, 'messages', hasLength(1))
            .having((state) => state.error, 'error', 'Offline.'),
      ],
    );

    blocTest<CoachChatBloc, CoachChatState>(
      'clears the conversation',
      setUp: () {
        store.messages.add(
          CoachMessage(
            id: 'm-1',
            role: CoachRole.user,
            content: 'Hi',
            createdAt: DateTime.utc(2026, 10, 27),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const ClearCoachChat()),
      expect: () => [const CoachChatLoaded([])],
      verify: (_) => expect(store.messages, isEmpty),
    );
  });
}
