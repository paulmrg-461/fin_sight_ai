import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/ai_coach_repository.dart';

/// Input for [AskCoachUseCase].
class AskCoachParams {
  const AskCoachParams({required this.question, required this.context});

  final String question;
  final String context;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AskCoachParams &&
          other.question == question &&
          other.context == context;

  @override
  int get hashCode => Object.hash(question, context);
}

/// Answers a free-form finance question with the user's context.
@lazySingleton
class AskCoachUseCase implements UseCase<String, AskCoachParams> {
  const AskCoachUseCase(this._repository);

  static const int maxQuestionLength = 500;

  final AiCoachRepository _repository;

  @override
  Future<Result<String>> call(AskCoachParams params) async {
    final question = params.question.trim();
    if (question.isEmpty) {
      return const Left(
        ValidationFailure(
          'Write a question for the coach.',
          code: 'empty_question',
        ),
      );
    }
    if (question.length > maxQuestionLength) {
      return const Left(
        ValidationFailure(
          'Questions must be 500 characters or fewer.',
          code: 'question_too_long',
        ),
      );
    }
    return _repository.askCoach(question, params.context);
  }
}
