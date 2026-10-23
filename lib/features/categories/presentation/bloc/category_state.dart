import 'package:equatable/equatable.dart';

import '../../domain/entities/category_entity.dart';

sealed class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object?> get props => const [];
}

final class CategoryInitial extends CategoryState {
  const CategoryInitial();
}

final class CategoryLoading extends CategoryState {
  const CategoryLoading();
}

final class CategoryLoaded extends CategoryState {
  const CategoryLoaded(this.categories, {this.error});

  final List<CategoryEntity> categories;

  /// Non-fatal action error shown above the list (e.g. duplicate name).
  final String? error;

  @override
  List<Object?> get props => [categories, error];
}

final class CategoryEmpty extends CategoryState {
  const CategoryEmpty({this.error});

  final String? error;

  @override
  List<Object?> get props => [error];
}

final class CategoryFailure extends CategoryState {
  const CategoryFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
