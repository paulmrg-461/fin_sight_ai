# Spec: expense categories

## Objective

Give every income/expense a managed category and let the user create, rename, archive, and restore categories.

## Model

`CategoryEntity`:

| Field | Type | Notes |
| --- | --- | --- |
| `id` | `String` | UUID v4, or `category-default-N` for seeded rows |
| `name` | `String` | Trimmed, 1–60 characters, unique case-insensitively |
| `isArchived` | `bool` | Archived categories stay in history but are hidden from pickers |
| `createdAt` | `DateTime` | Creation timestamp |
| `updatedAt` | `DateTime?` | Last local change |

Categories are **shared** between income and expenses. Transactions and budgets continue to store the
category name, so existing records remain valid and synchronized.

## Defaults

Seeded once, on the first read, from the device language (`Platform.localeName`):

- English: Salary, Freelance, Rent, Mortgage, Loans, Subscriptions, Phone, Utilities, Groceries, Dining,
  Transport, Health, Insurance, Education, Entertainment, Shopping, Travel, Other.
- Spanish: Salario, Freelance, Arriendo, Hipoteca, Créditos, Suscripciones, Plan celular, Servicios,
  Mercado, Restaurantes, Transporte, Salud, Seguros, Educación, Entretenimiento, Compras, Viajes, Otros.

Seeding is idempotent: defaults are only written when the box is empty. Archived categories count as
existing, so the seed never resurrects them.

## Use cases

- `GetCategoriesUseCase` — returns every category ordered by name.
- `AddCategoryUseCase` — validates name; rejects duplicates and overlong names.
- `RenameCategoryUseCase` — validates id, name, and duplicates (excluding itself).
- `SetCategoryArchivedUseCase` — archives or restores a category.

## Persistence

- Hive `categories` box, JSON maps, through `CategoryLocalDataSource`.
- Repository maps `CacheException` to `CacheFailure`; validation errors use `ValidationFailure`.
- Categories are **local-only** in this slice; syncing them is a documented follow-up.

## Presentation

- `CategoryBloc` with loading/loaded/empty/failure states; loaded states may carry an `error` banner
  while keeping the current list.
- `/categories` screen: add, rename, archive/restore, and a “show archived” toggle.
- Reached from Settings and from the transaction/payment forms.
- Transaction form and scheduled-payment form use a category dropdown of non-archived categories plus
  an inline “new category” action.
- Budget suggestions keep working from transaction history; the catalog is the source for pickers.

## Localization

All UI copy comes from ARB (`categoriesTitle`, `addCategory`, `newCategory`, `categoryName`,
`categoryNameRequired`, `categoryExists`, `renameCategory`, `archiveCategory`,
`archiveCategoryQuestion`, `archiveCategoryBody`, `archived`, `showArchived`, `restoreCategory`,
`noCategories`, `noCategoriesBody`, `manageCategories`, `categoriesDescription`).

## Tests

- Entity equality/copy.
- Hive data source round-trip and corrupted-row handling.
- Default seeding (EN/ES), duplicate rejection, rename, archive/restore, not-found errors.
- BLoC transitions and failure banner.
- Widget flow for add/rename/archive.
- Coverage ≥ 90% for domain and data.
