import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/clock.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_local_data_source.dart';
import '../models/category_model.dart';

/// Local-first category catalog with one-time localized defaults.
class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(
    this._localDataSource, {
    this.uuid = const Uuid(),
    this.clock = const Clock(),
    this.languageCode,
  });

  static const List<String> _defaultsEn = [
    'Salary',
    'Freelance',
    'Rent',
    'Mortgage',
    'Loans',
    'Subscriptions',
    'Phone',
    'Utilities',
    'Groceries',
    'Dining',
    'Transport',
    'Health',
    'Insurance',
    'Education',
    'Entertainment',
    'Shopping',
    'Travel',
    'Other',
  ];

  static const List<String> _defaultsEs = [
    'Salario',
    'Freelance',
    'Arriendo',
    'Hipoteca',
    'Créditos',
    'Suscripciones',
    'Plan celular',
    'Servicios',
    'Mercado',
    'Restaurantes',
    'Transporte',
    'Salud',
    'Seguros',
    'Educación',
    'Entretenimiento',
    'Compras',
    'Viajes',
    'Otros',
  ];

  final CategoryLocalDataSource _localDataSource;
  final Uuid uuid;
  final Clock clock;
  final String? languageCode;

  @override
  ResultFuture<List<CategoryEntity>> getCategories({
    bool includeArchived = false,
  }) async {
    try {
      final models = await _ensureSeeded();
      final visible = includeArchived
          ? models
          : models.where((category) => !category.isArchived);
      final sorted = visible.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return Right(sorted.map((model) => model.toEntity()).toList());
    } on CacheException catch (exception) {
      return Left(CacheFailure(exception.message, code: exception.code));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to read local categories.',
          code: 'category_read_failed',
        ),
      );
    }
  }

  @override
  ResultFuture<CategoryEntity> addCategory(String name) async {
    try {
      final models = await _ensureSeeded();
      final trimmed = name.trim();
      if (_isDuplicate(models, trimmed)) {
        return const Left(
          ValidationFailure(
            'A category with that name already exists.',
            code: 'duplicate_category',
          ),
        );
      }

      final now = clock.now();
      final model = CategoryModel(
        id: uuid.v4(),
        name: trimmed,
        createdAt: now,
        updatedAt: now,
      );
      await _localDataSource.saveCategory(model);
      return Right(model.toEntity());
    } on CacheException catch (exception) {
      return Left(CacheFailure(exception.message, code: exception.code));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to save the category locally.',
          code: 'category_write_failed',
        ),
      );
    }
  }

  @override
  ResultFuture<CategoryEntity> renameCategory(String id, String name) async {
    try {
      final models = await _ensureSeeded();
      final existing = _findById(models, id);
      if (existing == null) {
        return const Left(
          ValidationFailure('Category not found.', code: 'category_not_found'),
        );
      }

      final trimmed = name.trim();
      if (_isDuplicate(models, trimmed, ignoreId: id)) {
        return const Left(
          ValidationFailure(
            'A category with that name already exists.',
            code: 'duplicate_category',
          ),
        );
      }

      final updated = existing.copyWith(name: trimmed, updatedAt: clock.now());
      await _localDataSource.saveCategory(updated);
      return Right(updated.toEntity());
    } on CacheException catch (exception) {
      return Left(CacheFailure(exception.message, code: exception.code));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to rename the category.',
          code: 'category_write_failed',
        ),
      );
    }
  }

  @override
  ResultFuture<CategoryEntity> setArchived(String id, bool archived) async {
    try {
      final models = await _ensureSeeded();
      final existing = _findById(models, id);
      if (existing == null) {
        return const Left(
          ValidationFailure('Category not found.', code: 'category_not_found'),
        );
      }

      final updated = existing.copyWith(
        isArchived: archived,
        updatedAt: clock.now(),
      );
      await _localDataSource.saveCategory(updated);
      return Right(updated.toEntity());
    } on CacheException catch (exception) {
      return Left(CacheFailure(exception.message, code: exception.code));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to update the category.',
          code: 'category_write_failed',
        ),
      );
    }
  }

  Future<List<CategoryModel>> _ensureSeeded() async {
    final existing = await _localDataSource.getCategories();
    if (existing.isNotEmpty) {
      return existing;
    }

    final now = clock.now();
    final code = (languageCode ?? _deviceLanguage).toLowerCase();
    final names = code.startsWith('es') ? _defaultsEs : _defaultsEn;
    final seeded = <CategoryModel>[];
    for (var index = 0; index < names.length; index++) {
      final model = CategoryModel(
        id: 'category-default-$index',
        name: names[index],
        createdAt: now,
      );
      await _localDataSource.saveCategory(model);
      seeded.add(model);
    }
    return seeded;
  }

  bool _isDuplicate(
    List<CategoryModel> categories,
    String name, {
    String? ignoreId,
  }) {
    final normalized = name.toLowerCase();
    return categories.any(
      (category) =>
          category.id != ignoreId &&
          category.name.trim().toLowerCase() == normalized,
    );
  }

  CategoryModel? _findById(List<CategoryModel> categories, String id) {
    for (final category in categories) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }

  String get _deviceLanguage {
    try {
      return Platform.localeName.split(RegExp('[_-]')).first;
    } catch (_) {
      return 'en';
    }
  }
}
