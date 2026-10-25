import 'package:fin_sight_ai/core/l10n/l10n.dart';
import 'package:fin_sight_ai/features/categories/domain/entities/category_entity.dart';
import 'package:fin_sight_ai/features/categories/domain/usecases/category_usecases.dart';
import 'package:fin_sight_ai/features/categories/presentation/bloc/category_bloc.dart';
import 'package:fin_sight_ai/features/categories/presentation/bloc/category_state.dart';
import 'package:fin_sight_ai/features/categories/presentation/widgets/category_dropdown.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryCatalog extends Mock implements GetCategoryCatalogUseCase {}

class MockAddCategory extends Mock implements AddCategoryUseCase {}

class MockRenameCategory extends Mock implements RenameCategoryUseCase {}

class MockSetArchived extends Mock implements SetCategoryArchivedUseCase {}

void main() {
  final createdAt = DateTime.utc(2026, 10, 1);
  final groceries = CategoryEntity(
    id: 'cat-1',
    name: 'Groceries',
    createdAt: createdAt,
  );

  late CategoryBloc categoryBloc;

  setUpAll(() {
    registerFallbackValue(const GetCategoriesParams(includeArchived: false));
  });

  setUp(() {
    categoryBloc = CategoryBloc(
      MockCategoryCatalog(),
      MockAddCategory(),
      MockRenameCategory(),
      MockSetArchived(),
    )..emit(CategoryLoaded([groceries]));
  });

  tearDown(() async {
    await categoryBloc.close();
  });

  Widget buildDropdown({required String? value}) {
    return BlocProvider<CategoryBloc>.value(
      value: categoryBloc,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Form(
            child: CategoryDropdown(value: value, onChanged: (_) {}),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the selected catalog category', (tester) async {
    await tester.pumpWidget(buildDropdown(value: 'Groceries'));

    expect(find.text('Groceries'), findsOneWidget);
  });

  testWidgets('keeps a category that is no longer in the catalog selectable', (
    tester,
  ) async {
    await tester.pumpWidget(buildDropdown(value: 'Food'));

    expect(find.text('Food'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    expect(find.text('Food'), findsWidgets);
    expect(find.text('Groceries'), findsOneWidget);
  });
}
