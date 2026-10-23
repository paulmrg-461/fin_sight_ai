import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/category_usecases.dart';
import 'category_event.dart';
import 'category_state.dart';

@injectable
class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  CategoryBloc(
    this._getCategories,
    this._addCategory,
    this._renameCategory,
    this._setArchived,
  ) : super(const CategoryInitial()) {
    on<LoadCategories>(_onLoad);
    on<AddCategory>(_onAdd);
    on<RenameCategory>(_onRename);
    on<SetCategoryArchived>(_onArchive);
  }

  final GetCategoryCatalogUseCase _getCategories;
  final AddCategoryUseCase _addCategory;
  final RenameCategoryUseCase _renameCategory;
  final SetCategoryArchivedUseCase _setArchived;

  Future<void> _onLoad(
    LoadCategories event,
    Emitter<CategoryState> emit,
  ) async {
    emit(const CategoryLoading());
    await _reload(emit);
  }

  Future<void> _onAdd(AddCategory event, Emitter<CategoryState> emit) async {
    final result = await _addCategory(event.name);
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      await _reload(emit, error: failure.message);
      return;
    }
    await _reload(emit);
  }

  Future<void> _onRename(
    RenameCategory event,
    Emitter<CategoryState> emit,
  ) async {
    final result = await _renameCategory(
      RenameCategoryParams(id: event.id, name: event.name),
    );
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      await _reload(emit, error: failure.message);
      return;
    }
    await _reload(emit);
  }

  Future<void> _onArchive(
    SetCategoryArchived event,
    Emitter<CategoryState> emit,
  ) async {
    final result = await _setArchived(
      SetCategoryArchivedParams(id: event.id, archived: event.archived),
    );
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      await _reload(emit, error: failure.message);
      return;
    }
    await _reload(emit);
  }

  Future<void> _reload(Emitter<CategoryState> emit, {String? error}) async {
    final result = await _getCategories(
      const GetCategoriesParams(includeArchived: true),
    );
    result.fold(
      (failure) => emit(CategoryFailure(failure.message)),
      (categories) => categories.isEmpty
          ? emit(CategoryEmpty(error: error))
          : emit(CategoryLoaded(categories, error: error)),
    );
  }
}
