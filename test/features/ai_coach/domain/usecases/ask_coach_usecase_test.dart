import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/repositories/ai_coach_repository.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/usecases/ask_coach_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAiCoachRepository extends Mock implements AiCoachRepository {}

void main() {
  late MockAiCoachRepository repository;
  late AskCoachUseCase useCase;

  setUp(() {
    repository = MockAiCoachRepository();
    useCase = AskCoachUseCase(repository);
  });

  test('params compare by value', () {
    expect(
      const AskCoachParams(question: 'q', context: 'c'),
      const AskCoachParams(question: 'q', context: 'c'),
    );
    expect(
      const AskCoachParams(question: 'q', context: 'c').hashCode,
      const AskCoachParams(question: 'q', context: 'c').hashCode,
    );
    expect(
      const AskCoachParams(question: 'q', context: 'c'),
      isNot(const AskCoachParams(question: 'q', context: 'd')),
    );
  });

  test('trims the question and returns the answer', () async {
    when(() => repository.askCoach('How?', 'context'))
        .thenAnswer((_) async => const Right('Pay the card first.'));

    final result = await useCase(
      const AskCoachParams(question: '  How?  ', context: 'context'),
    );

    expect(result.getOrElse((_) => ''), 'Pay the card first.');
  });

  test('rejects empty and overlong questions', () async {
    final empty = await useCase(
      const AskCoachParams(question: '   ', context: ''),
    );
    final long = await useCase(
      AskCoachParams(question: 'x' * 501, context: ''),
    );

    expect(
      empty.fold((failure) => failure.code, (_) => null),
      'empty_question',
    );
    expect(
      long.fold((failure) => failure.code, (_) => null),
      'question_too_long',
    );
    verifyNever(() => repository.askCoach(any(), any()));
  });

  test('propagates repository failures', () async {
    when(() => repository.askCoach(any(), any()))
        .thenAnswer((_) async => const Left(ServerFailure('Offline.')));

    final result = await useCase(
      const AskCoachParams(question: 'Help', context: ''),
    );

    expect(result.fold((failure) => failure.message, (_) => null), 'Offline.');
  });
}
