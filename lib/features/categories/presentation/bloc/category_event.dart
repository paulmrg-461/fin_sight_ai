import 'package:equatable/equatable.dart';

sealed class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => const [];
}

final class LoadCategories extends CategoryEvent {
  const LoadCategories();
}

final class AddCategory extends CategoryEvent {
  const AddCategory(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

final class RenameCategory extends CategoryEvent {
  const RenameCategory({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

final class SetCategoryArchived extends CategoryEvent {
  const SetCategoryArchived({required this.id, required this.archived});

  final String id;
  final bool archived;

  @override
  List<Object?> get props => [id, archived];
}
